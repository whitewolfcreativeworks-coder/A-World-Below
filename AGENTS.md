# A World Below

Build a free, open-source, commercially usable 3D ocean exploration game.
Visual detail and close 3D examination of organisms are the core quality gate.
Focus on compact, impressive habitats before expanding the procedural world.
The design centers on extremophile research and technologies for the village.
The owner works on an iPad. Preserve touch controls and a single-threaded Web
export alongside the native Godot project. Do not add subscriptions, paid APIs,
hosted inference, analytics, or secrets. Ask before any paid service.

## Development

- Godot 4.6.3 standard edition, GDScript, Compatibility renderer.
- Run: `godot --path .`
- Import: `godot --headless --path . --editor --import --quit`
- Core checks: `godot --headless --path . --script tests/test_core.gd`
- Integration checks: `godot --headless --path . --script tests/test_expedition.gd`
- Specimen checks: `godot --headless --path . --script tests/test_specimen.gd`
- Export: `mkdir -p build/web && godot --headless --path . --export-release Web build/web/index.html`
- Serve web builds over HTTP(S); opening index.html as a local file does not work.
- Use separate XDG data/config directories for tests to avoid touching player saves.
- Keep generated engine caches and builds out of Git. No submodules needed.

## Project rules

- Procedural terrain uses a stable seed and world coordinates. Chunk load order
  must not change terrain, resource locations, or depletion records.
- Save discoveries, resources, and village state locally. Never reset saves
  silently. Version incompatible save migrations explicitly.
- Keep animal facts and sources in data/creatures.json, separate from rendering.
- Detailed specimen facts live in data/specimens.json. Preserve Blender sources
  in art-source/ and export GLB for Godot; keep the source directory .gdignore'd.
- Label fictional ecology, exaggerated scale, and artistic glow honestly.
- Check licenses at the exact version of every added library or asset. Record
  source, license, and redistribution obligations in THIRD_PARTY_NOTICES.md.
- Prefer permissive runtime code and CC0/CC BY assets with clear provenance.
  GPL tools may be used offline; assess separately before embedding GPL code.
- New external assets need explicit commercial and public-source redistribution rights.
- The owner's GitHub connection authorizes development; do not publish releases
  or change repository visibility/settings unless requested.
