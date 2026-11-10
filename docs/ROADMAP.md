# Development roadmap

## First Descent — current foundation

Swimming, generated terrain streaming, three animated animal groups, scanning,
fragment gathering, capsule expansion, local saving, and Web export. Initial
forms are procedural and intentionally simple.

## Atmosphere and fidelity

1. Test landscape play on the owner's physical iPad: multitouch, memory, Safari
   audio, orientation, and restoring saves.
2. Create original Blender rigs and animations, checked against observations.
3. Add underwater absorption/scattering shading, sediment particles, current
   fields, spatial sound, and quality options.
4. Expand navigation, village interiors, reduced motion, and text/input options.

## Deeper habitats and ecology

Species depth/geographic constraints; vent/seeps/whale-fall communities; abyssal
and hadal terrain; extremophile microbes; sampling; persistent research stations;
terrain variety and caves. Evaluate Zylann Voxel Tools (MIT) if caves need fully
volumetric terrain, with an integration/performance experiment first.

## Optional offline effects

Blender/Mantaflow for baked effects. Evaluate OpenFOAM only for a specific offline
need; assess GPL obligations before embedding solver code. Full-ocean real-time
CFD is not a goal.

## Delivery

Choose free static hosting for an iPad play link when requested. Keep hosting
separate from repository visibility. Native builds later. No store release,
repository-setting change, paid hosting, or paid API activation in this prototype.
