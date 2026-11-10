# Water & Light study

This pass implements two complementary ideas: a controllable holographic
research overlay and stronger cues that the player moves through water.
All effects are original code; no additional subscription or runtime service.

## Holographic research layer

Use SCAN LAYER in the specimen viewer to add an expanded mesh shell with cyan
rim light, fine contour bands, and a slow scanning sweep. It shares the original
geometry and follows the plume animation. Natural appearance remains the default.
The label identifies the shell as instrument visualization, not biological glow.
The effect emphasizes existing structure; it does not add anatomical information.
The first implementation is limited to the inspection viewer so it can be judged
before applying it throughout the habitat.

True bioluminescence should be authored separately for documented organisms and
behaviors. Extremophiles are not universally luminous, and this tubeworm does
not naturally produce the scan layer's cyan contours.

## Water feel

- A spatially varying current field carries neutrally buoyant swimmers and
  suspended particles; the vent region has a small illustrative upwelling.
- Swim thrust competes with linear and speed-dependent quadratic drag based on
  velocity relative to the water. Releasing input produces a short coast;
  reversing direction actively brakes. Small integration steps stabilize the
  force model across frame rates.
- Nearby marine snow is world-anchored and advected by currents. It wraps at the
  edge of the viewing volume rather than translating with the camera.
- Swimming near the seabed lifts a local sediment trail. Vent plumes and snow
  now draw after the underwater screen pass, so transparency remains visible.
- Small camera settling/roll, restrained speed-related field-of-view changes,
  and slight optical disturbance near the mixing zone add sensory cues.
- Optional sound includes a quiet synthesized wash that increases with swimming.
  No third-party recordings or automatic audio playback are used.
- SWAY OFF removes camera roll, turn settling, field-of-view movement, and
  shimmer, while retaining currents, drag, and particles. The preference saves
  locally in comfort.cfg.

This is a lightweight fluid-force and visual model, not a Navier–Stokes solver
or validated oceanographic simulation. Neutral buoyancy is assumed; no ballast
system or physical swimmer mass is simulated. The current and heat-mixing cues
are artistic approximations, not measurements from the represented habitat.
More detailed local fluid simulations can be evaluated for specific effects.

The feel and sustained performance still need assessment on the physical iPad.
