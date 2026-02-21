import ast
import re
from typing import Set

class SecurityViolation(Exception):
    """Raised when the submitted code violates sandbox security policies."""
    pass

# Blocked modules that have dangerous side effects in a shared sandbox
BLOCKED_MODULES = {
    'os', 'subprocess', 'shutil', 'socket', 'pickle', 'marshal',
    'ctypes', 'importlib', 'pty', 'platform', 'multiprocessing',
    'threading', 'tempfile'
}

# Explicitly allowed built-ins
SAFE_BUILTINS = {
    'abs', 'all', 'any', 'ascii', 'bin', 'bool', 'bytearray', 'bytes',
    'callable', 'chr', 'complex', 'dict', 'dir', 'divmod', 'enumerate',
    'filter', 'float', 'format', 'frozenset', 'getattr', 'hasattr', 'hash',
    'hex', 'id', 'int', 'isinstance', 'issubclass', 'iter', 'len', 'list',
    'locals', 'map', 'max', 'min', 'next', 'object', 'oct', 'ord', 'pow',
    'print', 'range', 'repr', 'reversed', 'round', 'set', 'setattr', 'slice',
    'sorted', 'str', 'sum', 'tuple', 'type', 'vars', 'zip', '__build_class__',
    '__name__', '__doc__'
}

class SandboxGuard(ast.NodeVisitor):
    def __init__(self):
        self.violations = []

    def visit_Import(self, node):
        for name in node.names:
            if name.name.split('.')[0] in BLOCKED_MODULES:
                self.violations.append(f"Import of '{name.name}' is forbidden")
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.module and node.module.split('.')[0] in BLOCKED_MODULES:
            self.violations.append(f"Import from '{node.module}' is forbidden")
        self.generic_visit(node)

    def visit_Call(self, node):
        # Check for direct calls like eval() or exec()
        if isinstance(node.func, ast.Name):
            if node.func.id in {'eval', 'exec', 'open', 'compile', 'input'}:
                self.violations.append(f"Call to '{node.func.id}()' is forbidden")
        # Check for attribute calls like __subclasses__()
        elif isinstance(node.func, ast.Attribute):
            if node.func.attr.startswith('__') and node.func.attr.endswith('__'):
                self.violations.append(f"Call to magic method '{node.func.attr}' is forbidden")
        self.generic_visit(node)

    def visit_Attribute(self, node):
        # Block access to magic attributes that could lead to sandbox escapes
        if node.attr in {'__mro__', '__subclasses__', '__globals__', '__builtins__', '__code__', '__func__'}:
            self.violations.append(f"Access to magic attribute '{node.attr}' is forbidden")
        self.generic_visit(node)

def check_code(code: str) -> None:
    """
    Performs static analysis on the code to detect security violations.
    """
    if not code.strip():
        return

    try:
        tree = ast.parse(code)
    except SyntaxError as e:
        raise SecurityViolation(f"SyntaxError: {e}")

    guard = SandboxGuard()
    guard.visit(tree)

    if guard.violations:
        raise SecurityViolation("; ".join(guard.violations))
