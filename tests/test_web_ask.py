import os
import sys
import unittest
from unittest.mock import patch


REPO_ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, os.path.join(REPO_ROOT, "scripts"))


import molbot_direct_chat.web_ask as web_ask  # noqa: E402


class TestWebAsk(unittest.TestCase):
    def test_extract_preguntale(self) -> None:
        req = web_ask.extract_web_ask_request("Preguntale a Gemini: que hora es?")
        self.assertIsNotNone(req)
        site, prompt, followups = req  # type: ignore[misc]
        self.assertEqual(site, "gemini")
        self.assertEqual(prompt, "que hora es?")
        self.assertIsNone(followups)

    def test_extract_dialoga(self) -> None:
        req = web_ask.extract_web_ask_request("Dialoga con ChatGPT: explicame relatividad")
        self.assertIsNotNone(req)
        site, prompt, followups = req  # type: ignore[misc]
        self.assertEqual(site, "chatgpt")
        self.assertEqual(prompt, "explicame relatividad")
        self.assertIsInstance(followups, list)
        self.assertEqual(len(followups), 4)
        self.assertTrue(all(isinstance(x, str) and len(x) > 0 for x in followups))

    def test_gemini_api_models_parse(self) -> None:
        with patch.dict(os.environ, {"GEMINI_API_MODELS": "gemini-x, gemini-y,gemini-x"}, clear=False):
            models = web_ask._gemini_api_models()
        self.assertEqual(models, ["gemini-x", "gemini-y"])

    def test_run_gemini_api_missing_key(self) -> None:
        with patch.dict(os.environ, {"GEMINI_API_ENABLED": "1"}, clear=False):
            os.environ.pop("GEMINI_API_KEY", None)
            os.environ.pop("GOOGLE_API_KEY", None)
            out = web_ask._run_gemini_api("hola", timeout_ms=1000, followups=None)
        self.assertFalse(out.get("ok"))
        self.assertEqual(out.get("status"), "missing_api_key")


if __name__ == "__main__":
    unittest.main()
