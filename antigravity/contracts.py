from __future__ import annotations

import enum
from datetime import datetime
from typing import Any, Dict, Literal, Optional

from pydantic import BaseModel, Field, constr, validator


class ContractStatus(str, enum.Enum):
    OK = "ok"
    ERROR = "error"
    PENDING = "pending"


class AckStatus(str, enum.Enum):
    ACCEPTED = "accepted"


class LucyInput(BaseModel):
    kind: constr(min_length=1, max_length=64)
    source: constr(min_length=1, max_length=128)
    ts: datetime
    text: Optional[constr(min_length=1, max_length=20000)] = None
    meta: Optional[Dict[str, Any]] = None
    correlation_id: Optional[constr(min_length=8, max_length=128)] = None

    class Config:
        extra = "forbid"


class LucyErrorDetail(BaseModel):
    message: constr(min_length=1)
    rc: Optional[int] = None
    stderr: Optional[str] = None
    stdout: Optional[str] = None
    stage: Optional[constr(min_length=1)] = None

    class Config:
        extra = "forbid"


class LucyOutput(BaseModel):
    version: Literal["lucy_output_v1"] = "lucy_output_v1"
    ok: bool
    correlation_id: constr(min_length=8, max_length=128)
    status: ContractStatus
    response_ts: datetime
    result: Optional[Dict[str, Any]] = None
    error: Optional[LucyErrorDetail] = None

    @validator("result")
    def validate_result(cls, v, values):
        if values.get("ok") is True and v is None:
            raise ValueError("result is required when ok is True")
        return v

    @validator("error")
    def validate_error(cls, v, values):
        if values.get("ok") is False and v is None:
            raise ValueError("error is required when ok is False")
        return v

    class Config:
        extra = "forbid"


class LucyAck(BaseModel):
    ok: bool
    correlation_id: constr(min_length=8, max_length=128)
    received_ts: datetime
    status: Literal["accepted"] = "accepted"
    next: Optional[constr(min_length=1, max_length=256)] = None
    reason: Optional[constr(min_length=1, max_length=512)] = None
    outbox_path: Optional[constr(min_length=1, max_length=256)] = None
    outbox_contract: Optional[Literal["lucy_output_v1"]] = None

    class Config:
        extra = "forbid"
