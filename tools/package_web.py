#!/usr/bin/env python3
"""Include notices in the distributable Web folder and create a portable ZIP."""
from pathlib import Path
import shutil
import zipfile

root = Path(__file__).resolve().parents[1]
web = root / "build/web"
if not (web / "index.html").exists():
    raise SystemExit("Export the Web preset before packaging.")
shutil.copytree(root / "LICENSES", web / "LICENSES", dirs_exist_ok=True)
provenance = root / "assets/materials/provenance.json"
if provenance.exists():
    shutil.copy2(provenance, web / "LICENSES/PolyHaven-provenance.json")
for name in ("LICENSE", "THIRD_PARTY_NOTICES.md"):
    shutil.copy2(root / name, web / name)
for path in web.rglob("*.import"):
    path.unlink()
archive = root / "build/A-World-Below-web.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
    for path in sorted(web.rglob("*")):
        if path.is_file():
            bundle.write(path, path.relative_to(web))
print(f"Packaged {archive.name}: {archive.stat().st_size / 1024 / 1024:.1f} MiB")
