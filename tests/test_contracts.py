import json
from datetime import datetime

import pytest
from antigravity.contracts import LucyAck, LucyInput, LucyOutput
from pydantic import ValidationError


def test_lucy_input_valid():
    raw = {
        "kind": "chat",
        "source": "user",
        "ts": "2023-10-27T10:00:00Z",
        "text": "Hello world"
    }
    obj = LucyInput(**raw)
    assert obj.kind == "chat"
    assert obj.text == "Hello world"


def test_lucy_input_invalid_missing_required():
    with pytest.raises(ValidationError):
        LucyInput(kind="chat")  # source and ts missing


def test_lucy_input_invalid_types():
    with pytest.raises(ValidationError):
        LucyInput(kind="chat", source="user", ts="not-a-date")


def test_lucy_output_valid():
    raw = {
        "ok": True,
        "correlation_id": "12345678",
        "status": "ok",
        "response_ts": "2023-10-27T10:00:01Z",
        "result": {"foo": "bar"}
    }
    obj = LucyOutput(**raw)
    assert obj.result["foo"] == "bar"


def test_lucy_output_invalid_result_missing():
    raw = {
        "ok": True,
        "correlation_id": "12345678",
        "status": "ok",
        "response_ts": "2023-10-27T10:00:01Z"
        # result missing
    }
    with pytest.raises(ValidationError) as exc:
        LucyOutput(**raw)
    assert "result is required when ok is True" in str(exc.value)


def test_lucy_ack_valid():
    raw = {
        "ok": True,
        "correlation_id": "12345678",
        "received_ts": "2023-10-27T10:00:02Z",
        "status": "accepted"
    }
    LucyAck(**raw)
