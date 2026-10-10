"""Persistent JSON-lines client for a named, existing MATLAB session."""
import io
import json
from pathlib import Path
import sys


def emit(kind, text=""):
    print(json.dumps({"type": kind, "text": text}), flush=True)


class Output(io.StringIO):
    # MATLAB accepts StringIO-compatible streams; send chunks immediately.
    def write(self, text):
        emit("output", text)
        return len(text)


def serve(requests, connect):
    engine = None
    for line in requests:
        try:
            request = json.loads(line)
            if engine is None:
                engine = connect()
            if "help" in request:
                text = engine.help(request["help"], nargout=1)
                emit("help", text)
            else:
                engine.eval(request["code"], nargout=0, stdout=Output(), stderr=Output())
                emit("done")
        except Exception as error:
            emit("error", str(error))
            # Reconnect on the next request, including after a desktop restart.
            engine = None


def main():
    root, name = sys.argv[1:3]
    bundled = Path(root) / "extern/engines/python/dist"
    if bundled.is_dir():
        sys.path.insert(0, str(bundled))
    try:
        import matlab.engine
    except Exception as error:
        emit("error", f"MATLAB Engine unavailable for {sys.executable}: {error}")
        return 1

    def connect():
        if name not in matlab.engine.find_matlab():
            raise RuntimeError(
                f"In your MATLAB Command Window, run: matlab.engine.shareEngine('{name}')"
            )
        return matlab.engine.connect_matlab(name)

    serve(sys.stdin, connect)
    return 0


if __name__ == "__main__":
    sys.exit(main())
