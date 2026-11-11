# Signals of Life

This pass adds four original 32-second looping soundtrack cues, a compact left-side Music button that opens a floating control card,
a combined heading compass and fictional
short-range life sonar, denser rocky scenery, representative cold-water coral
and sponge colonies, pale microbial mat forms, and 48 animated crustacean forms.
The soundtrack starts after the player's entry gesture; browser autoplay rules
still apply. SOUND OFF mutes both the soundtrack and water wash. The music volume
slider affects only the soundtrack. Settings currently reset on page reload.

Sonar covers 110 m in three dimensions. The top of the dial is the direction of
travel, cardinal directions rotate, green dots mark animal/specimen/colony
positions, small marks indicate significant vertical separation, and a gold
square marks home (clamped to the dial edge when outside range). It is a game
instrument, not a simulation of a real device that can identify microbes.

The new habitat is a deterministic compact study area around the existing
vent garden, with corals and sponges outside the immediate hot-vent area.
Additional rocks follow the existing seeded chunk generator. It does not yet
provide biological communities throughout the infinite terrain. Coral, sponge,
mat and crustacean shapes are authored representatives, not species scans.
Coral colonies and moving forms use shared instanced meshes to limit draw calls.

LIFE CATALOG separates six habitat/adaptation groups and marks current assets
versus future research candidates. It includes an actual CC BY 4.0 confocal
micrograph of Old City chimney microbes with author, source, license and imaging
interpretation visible in the game. Exact download/checksum metadata lives in
assets/science/provenance.json and is included with packaged Web notices.
The primary paper takes precedence over the Commons location description.

No photographic skins have been wrapped onto the animal models in this pass.
The existing Riftia anatomy remains an authored model; the real microscopic
image is a labeled scientific observation, not a 360-degree texture or evidence
of natural visible glow. Future specimen assets follow BIOLOGICAL_ASSETS.md.

Validation: Godot tests cover heading projection, contact inclusion, ambient
startup, soundtrack selection/looping/mute, animation/pause, catalog imagery and
sidebar clearance. Existing village, specimen, water and independent multitouch
checks remain required. Browser touch/screenshots complement these checks;
physical iPad Safari performance and listening remain user validation steps.

The soundtrack controls now collapse to one 112 × 44 Music button beneath the
sonar. Tapping it opens a small card with on/off, a volume slider and a touch-
scrollable track list. Close (or tap Music again) returns to swimming; the game
pauses while this card is open. LIFE CATALOG is available inside the journal.
