import importlib.util
import sys
import os

def load_source(modname, filename):
    spec = importlib.util.spec_from_file_location(modname, filename)
    if spec is None:
        raise ImportError(f"Could not load source {filename}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[modname] = module
    spec.loader.exec_module(module)
    return module

try:
    mod = load_source("test_module", os.path.abspath("test_load.py"))
    print(f"Loaded: {mod}")
    print(f"Result: {mod.hello()}")
    print(f"In sys.modules: {'test_module' in sys.modules}")
except Exception as e:
    print(f"Error: {e}")
