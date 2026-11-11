# A World Below: habitat mosaics

Status: research and design specification, 11 November 2026. The photo atlas and
machine-readable recipes are implemented; these recipes do not yet populate the
live procedural world. The current game remains the compact vent-garden study.

## Experience

Build the ocean as connected, varied habitats, using the owner's aquarium idea:
sculpt the terrain, establish water and chemical conditions, assemble compatible
communities, then create behavior and a reason to investigate. Each region needs
a distinctive silhouette, near-field texture, movement and discovery. Different
versions of a habitat should share ecological logic without repeating the same
arrangement of meshes.

Density must be composed. Many deep-sea backgrounds have sparse conspicuous
animals; vents, seeps, food falls and some hard-substrate communities can provide
concentrated life. Compress travel between interesting sites rather than turning
every sediment patch into an equally dense reef. Give quieter patches burrows,
tracks, small organisms and scan targets. These are hypotheses for playtesting:

- Small clue or observation every 20–45 seconds of ordinary swimming.
- A larger destination about 1–3 minutes away, with its first clues earlier.
- At least one readable route onward from a destination, plus optional branches.
- Reuse asset families but vary silhouettes, colony sizes, substrate, relief,
  composition, current direction, encounter type and the view on arrival.

The deep dark sea is not a planted tropical aquarium. Most true plants and algae
need light. Deep-sea corals and sponges are animals. Some ecosystems obtain food
through microbial chemosynthesis, and many depend on organic matter transported
from elsewhere. ROV/headlamp illumination reveals colors; ubiquitous neon glow
is not a substitute for anatomy or habitat structure.

## Reference collection

The [interactive photo atlas](habitat-atlas/index.html) contains nine recipes and
nine main images, plus a second cold-seep photograph. All ten local copies have
source URLs, credits, license references, changes and original/download checksums
in [provenance.json](habitat-atlas/provenance.json). Images are scientific
references, not completed environment art or ready-to-use terrain textures.

| Habitat | Recognizable visual structure | Natural process | Discovery scenario |
| --- | --- | --- | --- |
| Coral terraces | Layered hard outcrops, branching fans, smaller associates | Current supplies food to suitable attachment sites | Follow the current to a dense colony and survey its inhabitants |
| Sponge gardens | Cups and other forms across platforms and ledges | Suspension feeding; community varies with substrate and conditions | Compare exposed and sheltered colony edges |
| Canyon walls | Eroded layers, undercuts, terraces and debris | Erosion, gravity and currents shape surface and shelter | Search ledges and alcoves in three dimensions |
| Hydrothermal vents | Mineral chimneys, fluid plumes and clustered animals | Hydrothermal circulation transports heat and chemicals | Compare a mixing zone with a hotter outlet using instruments |
| Cold seeps | Carbonate crusts, mussel beds, mats and sometimes gas bubbles | Local fluid/gas supply supports chemical-energy pathways | Trace a gradient from shells to an active bed |
| Brine margins | Depression and a distinct density interface | Saline fluid accumulation in suitable geology | Sample the margin and compare salinity and oxygen |
| Abyssal nodule fields | Fine sediment with variable dark nodule coverage | Very slow mineral accumulation; patchy hard substrate | Find small attached life and sediment traces |
| Whale falls | Carcass or bones form a local focal point | An organic food pulse supports changing communities | Document one persistent decomposition stage |
| Hadal mosaics | Fine sediment, exposed rock and slope debris | Trench geology and sediment redistribution | Survey contrasting substrates under high pressure |

The NOAA vent photo is from the Marianas; it does not establish that Riftia belongs
there. The brine photo documents a small pool at 1,067 m, not a hadal lake. The
Java Trench study is our genuinely hadal visual reference; it documents varied
terrain and site-specific communities. Its suggested chemosynthetic deposits are
not confirmed hydrothermal vents. Baited lander images can concentrate scavengers:
never infer ordinary background animal density from bait-camera aggregations.

## Geography before population

Do not assign one independent random biome per 64 m chunk. Chunks are a loading
mechanism; ecological regions should extend across them. A proposed hierarchy:

1. **World profile:** seed, generation-schema version and fictional setting.
2. **Geological provinces:** continental margin, seamount, volcanic ridge,
   sedimentary margin, salt-bearing basin, abyssal basin and subduction trench.
3. **Continuous local fields:** seabed depth, slope, substrate, flow exposure,
   particulate food supply and sediment accumulation. These fields need their
   own stable seed domains so population changes cannot move mineral resources.
4. **Localized sources:** hydrothermal circulation, seep supply or brine supply,
   only in compatible provinces. Their influence decays across space.
5. **Habitat weights:** qualify recipes using the fields and blend eligible
   communities. Boundary zones retain recognizable mixtures and open gaps.
6. **Population:** choose organisms from taxon-specific depth, temperature,
   substrate, oxygen and regional rules; apply cluster patterns and budget limits.
7. **Encounters:** place eligible food falls, unusual specimens or research sites
   as persistent, uncommon overlays. They are not continent-sized biomes.

A province arrangement is fictional world design, not a reconstruction of a real
site. Combining references from different ocean basins requires explicit artistic
simplification. Do not imply that every featured species naturally co-occurs.

## Smooth arrivals

Choose regional anchors from stable, world-coordinate spatial sampling, then use
continuous field weights rather than chunk boundaries. Initial tuning proposals:

- Habitat-scale regions: roughly 150–400 m across, enlarged if swimming pace makes
  transitions feel rushed. These dimensions are gameplay choices, not field data.
- Transition belts: roughly 30–80 m, always wider than a visible loading seam.
- Biological clusters: several small patches around a larger focal structure.
- Landmark spacing: set by travel time along a swimmable path, not straight-line
  distance alone. Depth and walls can lengthen the actual route substantially.

Blend substrate texture and sediment cover first, then landform frequency and
colony composition. Change organisms only where their conditions become suitable.
Ambient lighting, fog and particles should respond gradually to conditions;
plumes remain attached to sources, not painted uniformly over a whole region.
A brine interface or cliff edge may be locally sharp even when regional blending
is gradual. Fade distant instance batches to prevent object popping.

The player should recognize an approach: isolated fans before a coral garden,
fractures and mineral staining before a vent, shell patches before a seep bed,
a slope and accumulating debris before a wall. Sonar and chemical readings should
support that trail without replacing what the player can see.

## Stable randomness and return journeys

Use a seed and world coordinates for every regional decision. Revisiting a place
must preserve its geology, discoveries, depletion records and encounter stage.
The visible neighborhood may stream out and back in without rerolling it. A new
world seed creates a new arrangement; an optional separate expedition mode could
reroll an expedition without relocating the permanent village. That mode is not
currently implemented or selected by this design.

The owner previously favored one persistent generated world. Interpret the latest
request for changing environments as spatial variation and recurrence while
traveling, rather than silently resetting visited places on every departure.

Preserve the current save's generation version. The current height model only
supports a shallow local depth range around the 1,400 m display offset; adding
real 6,000+ m progression requires deliberate vertical terrain design, navigation,
life-support pacing and save compatibility. Do not relabel a 1,400 m patch as hadal
or silently alter existing terrain/resource positions to fit this design.

## Recipe contract

[data/habitat_recipes.json](../data/habitat_recipes.json) is a versioned design
catalog. Each recipe contains eligible province and broad depth-zone labels,
reference evidence, recognizable structures, movement, arrival, scenario,
proposed research, placement constraints and variations. It is not a scientific
species database or an executable ecological simulation. Broad depth zones are
working design bands, not precise habitat or species distributions.

The next implementation should add numeric eligibility ranges only when supported
by taxon/site evidence, then expose field sampling through a pure generator API:

```
region_fields(seed, world_position) -> geology, depth, slope, substrate, flow, food
source_fields(seed, world_position, geology) -> heat, seep_flux, brine_flux
habitat_weights(fields, source_fields) -> eligible recipes + normalized weights
population(seed, stable_patch_id, fields, weights) -> persistent placements
```

Return the same answer regardless of chunk load order. Use independent hashes for
terrain, biology, decorative density and encounters. Changing decorative settings
must not alter collectible identities or the village. Neighbor samples must
produce compatible fields at shared borders.

## Build sequence and quality gates

1. Recompose the existing vent area against its real photo: irregular towers,
   distinct mixed-water colonies, mineral aprons and source-attached plumes.
2. Build a second detailed region, a cold seep with carbonate slabs, mussel beds
   and patchy mats. Make it visually distinct before expanding surface area.
3. Join them through a cooler hard-substrate corridor and a coral/sponge terrace.
   Verify the transition during ordinary swimming, including the return trip.
4. Add vertical canyon exploration and sediment/nodule background variation.
5. Add a rare persistent food-fall encounter and later a brine-margin region.
6. Design actual deeper progression, then develop a separately validated hadal
   study area using the trench reference.

For each region, compare a similar camera angle and scale with its photograph.
Match silhouette, spacing, substrate and organism arrangement before adding glow.
Inspect close-up organisms in natural view. Preserve headlamp lighting, current,
marine snow and comfortable two-thumb control. Every habitat needs an obvious
arrival, a small interaction, a focal discovery and a path onward.

On iPad use instanced background colonies and lower-detail distant organisms;
reserve detailed rigs and materials for close targets. Avoid adding a light per
animal, rebuilding all meshes per frame, or stacking many transparent layers.
Measure actual frame time, memory and touch responsiveness on the physical iPad.

Acceptance checks for the future runtime integration include stable revisits,
independence from load order, eligible organism placement, seam-free transitions,
no habitat reroll on turning around, reachable destinations, saved encounter
stages and unchanged older saves. Do not claim these guarantees until that runtime
implementation and testing are complete.
