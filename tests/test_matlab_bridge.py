"""Protocol checks without requiring a running MATLAB desktop."""
import importlib.util
import io
import json
from pathlib import Path
import unittest


class BridgeTests(unittest.TestCase):
    def test_missing_session_is_reported_without_starting_matlab(self):
        bridge.serve(io.StringIO('{"code":"x=1"}\n'), lambda: (_ for _ in ()).throw(
            RuntimeError("Share NvimMatlab first")))
        self.assertEqual(self.events()[0]["type"], "error")
        self.assertIn("Share NvimMatlab", self.events()[0]["text"])

    def test_output_errors_and_subsequent_requests(self):
        class Engine:
            def eval(self, code, **options):
                if code == "bad":
                    raise RuntimeError("Undefined function")
                options["stdout"].write("hello\n")

        engine = Engine()
        bridge.serve(io.StringIO('\n'.join(json.dumps({"code": code})
                     for code in ["bad", "good", "good"]) + '\n'), lambda: engine)
        events = self.events()
        self.assertEqual([e["type"] for e in events],
                         ["error", "output", "done", "output", "done"])
        self.assertIn("Undefined function", events[0]["text"])
        self.assertEqual(events[1]["text"], "hello\n")

    def setUp(self):
        self.output = io.StringIO()
        self.original = bridge.sys.stdout
        bridge.sys.stdout = self.output

    def tearDown(self):
        bridge.sys.stdout = self.original

    def events(self):
        return [json.loads(line) for line in self.output.getvalue().splitlines()]


if __name__ == "__main__":
    spec = importlib.util.spec_from_file_location("bridge", Path(__file__).parents[1] / "scripts/matlab_bridge.py")
    bridge = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(bridge)
    unittest.main()
