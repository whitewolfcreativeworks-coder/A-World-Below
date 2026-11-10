#!/usr/bin/env python3
"""Install official, checksum-verified Linux Godot and Web templates locally."""
import hashlib
import os
from pathlib import Path
import stat
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(os.environ.get("AWB_TOOLS_DIR", ROOT / ".tools")).resolve()
VERSION = "4.6.3"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable"
EDITOR = f"Godot_v{VERSION}-stable_linux.x86_64.zip"
TEMPLATES = f"Godot_v{VERSION}-stable_export_templates.tpz"
TEMPLATE_SHA256 = "3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8"
EDITOR_BINARY_SHA256 = "f64d4ed19fc9df9440321653fcc80df8c6e365ba7b6de0a29e2cfa9fa71bfeb3"


def digest(path, algorithm="sha256"):
    h = hashlib.new(algorithm)
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def download(name):
    target = TOOLS / name
    if not target.exists():
        print(f"Downloading official {name}", flush=True)
        temp = target.with_suffix(target.suffix + ".partial")
        with urllib.request.urlopen(f"{BASE}/{name}", timeout=180) as response, temp.open("wb") as out:
            while chunk := response.read(1024 * 1024):
                out.write(chunk)
        temp.replace(target)
    return target


def main():
    TOOLS.mkdir(exist_ok=True)
    sums = urllib.request.urlopen(f"{BASE}/SHA512-SUMS.txt", timeout=60).read().decode()
    expected = {line.split()[-1].lstrip("*"): line.split()[0] for line in sums.splitlines() if line.strip()}
    for name in (EDITOR, TEMPLATES):
        path = download(name)
        if name not in expected or digest(path, "sha512") != expected[name]:
            raise SystemExit(f"Official release checksum mismatch: {name}. Remove cached file and retry.")
    if digest(TOOLS / TEMPLATES) != TEMPLATE_SHA256:
        raise SystemExit("Pinned template SHA-256 mismatch")
    with zipfile.ZipFile(TOOLS / EDITOR) as archive:
        name = f"Godot_v{VERSION}-stable_linux.x86_64"
        binary = TOOLS / "godot"
        binary.write_bytes(archive.read(name))
        binary.chmod(binary.stat().st_mode | stat.S_IXUSR)
    if digest(binary) != EDITOR_BINARY_SHA256:
        raise SystemExit("Pinned editor SHA-256 mismatch")
    data = TOOLS / "data"
    destination = data / "godot" / "export_templates" / f"{VERSION}.stable"
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(TOOLS / TEMPLATES) as archive:
        for name in archive.namelist():
            if "/web_" in name or name.endswith("version.txt"):
                (destination / Path(name).name).write_bytes(archive.read(name))
    print(f"Ready: {binary}\nSet XDG_DATA_HOME={data} when exporting.")
    if os.environ.get("GITHUB_ENV"):
        with open(os.environ["GITHUB_ENV"], "a") as env:
            env.write(f"XDG_DATA_HOME={data}\n")
        with open(os.environ["GITHUB_PATH"], "a") as paths:
            paths.write(f"{TOOLS}\n")


if __name__ == "__main__":
    main()
