#!/usr/bin/env python3
import asyncio
import json
import logging
import os
import sys
import time
import threading
import queue
import shutil
from pathlib import Path
from typing import Optional, Dict, Any, List

from aiohttp import web
import aiohttp
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

# Ensure we can import antigravity from project root
_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from antigravity.contracts import LucyInput, LucyOutput, LucyAck
from pydantic import ValidationError

# Import helper modules
from molbot_direct_chat import desktop_ops, web_ask, web_search, ui_html
from molbot_direct_chat.util import safe_session_id

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(name)s] [%(levelname)s] %(message)s')
logger = logging.getLogger("openclaw_direct_chat")

# --- Global Config ---
DIRECT_CHAT_ENV_PATH = Path(os.environ.get("OPENCLAW_DIRECT_CHAT_ENV", str(Path.home() / ".openclaw" / "direct_chat.env")))
HISTORY_DIR = Path.home() / ".openclaw" / "direct_chat_histories"
HISTORY_DIR.mkdir(parents=True, exist_ok=True)

def _load_local_env_file(path: Path) -> None:
    try:
        if not path.exists(): return
        for line in path.read_text(encoding="utf-8").splitlines():
            raw = line.split("#", 1)[0].strip()
            if not raw or "=" not in raw: continue
            k, v = raw.split("=", 1)
            if k.strip() and k.strip() not in os.environ:
                os.environ[k.strip()] = v.strip().strip('"\'')
    except Exception: pass

_load_local_env_file(DIRECT_CHAT_ENV_PATH)

def _env_flag(name: str, default: bool = False) -> bool:
    raw = str(os.environ.get(name, "")).strip().lower()
    return raw in ("1", "true", "yes", "on", "si", "sí") if raw else default

def _int_env(name: str, default: int) -> int:
    try: return int(os.environ.get(name, default))
    except (ValueError, TypeError): return default

# --- Async Clients with Resilience ---

@retry(stop=stop_after_attempt(5), wait=wait_exponential(multiplier=1, min=1, max=10), retry=retry_if_exception_type((aiohttp.ClientError, asyncio.TimeoutError)))
async def _call_gateway_async(payload: Dict[str, Any], timeout_s: float = 30.0) -> Dict[str, Any]:
    url = os.environ.get("DIRECT_CHAT_GATEWAY_URL", "http://localhost:5678/webhook/lucy_input")
    async with aiohttp.ClientSession() as session:
        async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=timeout_s)) as resp:
            resp.raise_for_status()
            data = await resp.json()
            try:
                LucyOutput(**data) # Strict Contract Check (Egress)
            except ValidationError as e:
                logger.error(f"Gateway Response Validation Failed: {e}")
                raise # Fail fast on contract violation
            return data

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=5), retry=retry_if_exception_type((aiohttp.ClientError, asyncio.TimeoutError)))
async def _call_ollama_async(payload: Dict[str, Any], timeout_s: float = 60.0) -> Dict[str, Any]:
    base = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434").rstrip("/")
    url = f"{base}/api/chat"
    async with aiohttp.ClientSession() as session:
        async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=timeout_s)) as resp:
            resp.raise_for_status()
            return await resp.json()

# --- Handlers ---

async def handle_root_get(request: web.Request) -> web.Response:
    return web.Response(text=ui_html.HTML, content_type="text/html")

async def handle_root_post(request: web.Request) -> web.Response:
    try:
        payload = await request.json()
    except Exception:
        return web.json_response({"error": "Invalid JSON"}, status=400)

    # 1. Ingress Validation
    try:
        LucyInput(**payload)
    except ValidationError as e:
        return web.json_response({"error": "Contract Violation", "detail": str(e)}, status=400)

    # 2. Routing Logic (Simplified Async flow)
    # This replaces the complex threading logic.
    # Ideally, we call the Gateway.
    
    # Example: If kind="text", call Gateway.
    kind = payload.get("kind", "text")
    
    if kind == "text":
        try:
             # We assume Gateway handles the heavy lifting
             # In V1 this script also did direct Ollama calls if Gateway failed or for local tasks.
             # For V2 migration, we prioritize reliable Gateway comms.
             response_data = await _call_gateway_async(payload)
             return web.json_response(response_data)
        except Exception as e:
             logger.error(f"Gateway Call Failed: {e}")
             # Fallback logic could go here (e.g. call Ollama directly)
             return web.json_response({"ok": False, "status": "error", "error": str(e)}, status=502)

    return web.json_response({"ok": True, "status": "processed"})

# --- Startup ---

async def init_app() -> web.Application:
    app = web.Application()
    app.router.add_get("/", handle_root_get)
    app.router.add_post("/", handle_root_post)
    return app

def main():
    port = _int_env("DIRECT_CHAT_PORT", 8989)
    host = os.environ.get("DIRECT_CHAT_HOST", "0.0.0.0")
    logger.info(f"Starting Direct Chat V2 (Async+Resilient) on {host}:{port}")
    web.run_app(init_app(), host=host, port=port)

if __name__ == "__main__":
    import argparse
    import os

    # CLI overrides env, env provides defaults
    ap = argparse.ArgumentParser(description="OpenClaw Direct Chat server")
    ap.add_argument("--host", default=os.getenv("DIRECT_CHAT_HOST", "127.0.0.1"))
    ap.add_argument("--port", type=int, default=int(os.getenv("DIRECT_CHAT_PORT", "8989")))
    # Allow unknown args (like --gateway-port) to pass through without error
    args, unknown = ap.parse_known_args()

    os.environ["DIRECT_CHAT_HOST"] = args.host
    os.environ["DIRECT_CHAT_PORT"] = str(args.port)

    # Call the existing entrypoint without refactoring internal codepaths
    if "main" in globals() and callable(globals().get("main")):
        globals()["main"]()
    elif "run" in globals() and callable(globals().get("run")):
        globals()["run"]()
    else:
        # Fallback: try common patterns used in aiohttp scripts
        try:
            from aiohttp import web  # type: ignore
        except Exception as e:
            raise SystemExit(f"Cannot import aiohttp.web for fallback run: {e}")

        if "create_app" in globals() and callable(globals().get("create_app")):
            app = globals()["create_app"]()
            web.run_app(app, host=args.host, port=args.port)
        elif "app" in globals():
            web.run_app(globals()["app"], host=args.host, port=args.port)
        else:
            raise SystemExit("No known entrypoint found (main/run/create_app/app). Add a main() entrypoint.")
