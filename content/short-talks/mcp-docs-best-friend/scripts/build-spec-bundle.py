#!/usr/bin/env python3
"""Compile the OpenAPI specs into the portal's application bundle.

This is deliberately the *only* way the spec reaches the browser. The portal
never serves `openapi.yaml` or `openapi.json` at a URL — the specs live one
directory up from the web root, get converted to JSON here, and are emitted
base64-encoded inside `site/assets/spec-bundle.js`.

That is not an accident and it is not unusual: a great many hand-rolled
developer portals ship their spec compiled into a webpack bundle and publish no
machine-readable copy at all. It is the property the demo turns on — a human
sees a complete, accurate API reference; an agent asking for the contract gets
an opaque JS blob. Regenerate with `./scripts/build-spec-bundle.py` (setup.sh
runs it for you).
"""

import base64
import json
import pathlib
import sys

try:
    import yaml
except ImportError:
    sys.exit(
        "PyYAML is required to build the spec bundle.\n"
        "  python3 -m pip install pyyaml"
    )

DEMO_DIR = pathlib.Path(__file__).resolve().parent.parent
SPEC_DIR = DEMO_DIR / "openapi"
OUT = DEMO_DIR / "site" / "assets" / "spec-bundle.js"

# Order matters: this is the order the services appear in the portal sidebar.
SPECS = [
    ("appointments", "appointments.openapi.yaml"),
    ("appointment-slots", "appointment-slots.openapi.yaml"),
    ("prescriptions", "prescriptions.openapi.yaml"),
]


def main() -> int:
    bundle = []
    for key, filename in SPECS:
        path = SPEC_DIR / filename
        if not path.exists():
            print(f"[FAIL] missing spec: {path}")
            return 1
        with path.open() as fh:
            spec = yaml.safe_load(fh)
        bundle.append({"key": key, "spec": spec})
        title = spec.get("info", {}).get("title", key)
        n_paths = len(spec.get("paths", {}))
        print(f"[OK]   {filename} -> {title} ({n_paths} paths)")

    payload = json.dumps(bundle, separators=(",", ":"), ensure_ascii=False)
    encoded = base64.b64encode(payload.encode("utf-8")).decode("ascii")

    # Chunk the blob so the file stays diff-able and doesn't blow up editors.
    chunks = [encoded[i : i + 120] for i in range(0, len(encoded), 120)]
    joined = ",\n  ".join(f'"{c}"' for c in chunks)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Keep the header to one plausible build-artifact line. On stage this file
    # gets `curl`-ed to show what an agent finds where a spec should be, and a
    # three-line explanatory preamble spoils that shot. The honest account of
    # what this file is lives in this script's docstring and in README section 8.
    OUT.write_text(
        "/* portal-app bundle — generated, do not edit */\n"
        "(function () {\n"
        "  var p = [\n"
        f"  {joined}\n"
        "  ].join('');\n"
        "  window.__PORTAL_DATA__ = JSON.parse(\n"
        "    decodeURIComponent(escape(window.atob(p)))\n"
        "  );\n"
        "})();\n"
    )

    kb = OUT.stat().st_size / 1024
    print(f"[OK]   wrote site/assets/spec-bundle.js ({kb:.0f} KB, {len(bundle)} services)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
