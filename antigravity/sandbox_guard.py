import ast
import sys

# Denylist of modules that are strictly forbidden.
# We block these to prevent OS interaction, process creation, and network access.
FORBIDDEN_MODULES = {
    "os", "sys", "subprocess", "shutil", "pty", "socket", "pathlib",
    "importlib", "builtins", "posix", "nt", "pickle", "marshal", "shelve",
    "dbm", "sqlite3", "tkinter", "http", "urllib", "ftplib", "poplib",
    "imaplib", "nntplib", "smtplib", "telnetlib", "xmlrpc", "multiprocessing",
    "threading", "concurrent", "asyncio", "signal", "tempfile", "glob",
    "fnmatch", "linecache", "traceback", "gc", "inspect", "site", "venv",
}

# Denylist of built-in functions that are dangerous.
FORBIDDEN_BUILTINS = {
    "eval", "exec", "open", "compile", "__import__", "input", "exit", "quit",
    "help", "dir", "vars", "globals", "locals", "breakpoint", "memoryview",
}

class SecurityViolation(Exception):
    pass

class SandboxGuard(ast.NodeVisitor):
    def visit_Import(self, node):
        for alias in node.names:
            self._check_module(alias.name)
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.module:
            self._check_module(node.module)
        self.generic_visit(node)

    def visit_Call(self, node):
        # Block calling dangerous builtins like eval(), exec(), open()
        if isinstance(node.func, ast.Name):
            if node.func.id in FORBIDDEN_BUILTINS:
                raise SecurityViolation(f"Call to forbidden function: '{node.func.id}'")
        # Block calling attributes like __import__ on objects if possible (harder to track types statically)
        # But we can block obvious cases like builtins.__import__
        if isinstance(node.func, ast.Attribute):
            if node.func.attr == "__import__":
                 raise SecurityViolation("Call to forbidden attribute: '__import__'")
        self.generic_visit(node)

    def visit_Attribute(self, node):
        # Block access to suspicious attributes that might bypass checks
        if node.attr.startswith("__") and node.attr.endswith("__"):
            # We might want to be careful here. dunder methods are common.
            # But direct access to __builtins__, __globals__, etc is bad.
            if node.attr in {"__builtins__", "__globals__", "__subclasses__", "__bases__", "__loader__", "__spec__"}:
                raise SecurityViolation(f"Access to forbidden attribute: '{node.attr}'")
        self.generic_visit(node)

    def _check_module(self, module_name: str):
        if not module_name:
            return
        base_module = module_name.split(".")[0]
        if base_module in FORBIDDEN_MODULES:
            raise SecurityViolation(f"Import of forbidden module: '{base_module}'")

def check_code(code: str) -> None:
    """
    Parses the code into an AST and runs the SandboxGuard visitor.
    Raises SecurityViolation if malicious patterns are found.
    Raises SyntaxError if code is invalid.
    """
    try:
        tree = ast.parse(code)
    except SyntaxError as e:
        # We let the caller handle SyntaxError or wrap it.
        # But usually SyntaxError is fine to propagate as is (400 Bad Request in App).
        raise
    
    guard = SandboxGuard()
    guard.visit(tree)
