import ast
import pytest
from antigravity.sandbox_guard import check_code, SecurityViolation

def test_safe_code():
    code = """
import math
import json
x = 1 + 1
print(x)
data = json.dumps({"a": 1})
    """
    check_code(code)

def test_block_import_os():
    code = "import os"
    with pytest.raises(SecurityViolation, match="Import of forbidden module: 'os'"):
        check_code(code)

def test_block_from_import_sys():
    code = "from sys import exit"
    with pytest.raises(SecurityViolation, match="Import of forbidden module: 'sys'"):
        check_code(code)

def test_block_subprocess_alias():
    code = "import subprocess as sp"
    with pytest.raises(SecurityViolation, match="Import of forbidden module: 'subprocess'"):
        check_code(code)

def test_block_eval():
    code = "eval('1+1')"
    with pytest.raises(SecurityViolation, match="Call to forbidden function: 'eval'"):
        check_code(code)

def test_block_exec():
    code = "exec('print(1)')"
    with pytest.raises(SecurityViolation, match="Call to forbidden function: 'exec'"):
        check_code(code)

def test_block_open():
    code = "f = open('/etc/passwd')"
    with pytest.raises(SecurityViolation, match="Call to forbidden function: 'open'"):
        check_code(code)

def test_block_dunder_builtins():
    code = "print(__builtins__)"
    with pytest.raises(SecurityViolation, match="Access to forbidden attribute: '__builtins__'"):
        check_code(code)

def test_block_dunder_import():
    code = "__import__('os')"
    with pytest.raises(SecurityViolation, match="Call to forbidden function: '__import__'"):
        check_code(code)

def test_syntax_error():
    code = "import os ("
    with pytest.raises(SyntaxError):
        check_code(code)
