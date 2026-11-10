# Real biological imagery and reusable models

Use real scientific references and appropriately licensed existing assets before
building each organism from scratch. This is a sourcing plan; no new biological
photographs or third-party creature models have been imported by this document.

## Sources

| Source | Useful material | Commercial game use |
| --- | --- | --- |
| [NOAA Ocean Exploration](https://oceanexplorer.noaa.gov/about/media-kit/) | ROV images and video: anatomy, habitat, coloration, movement | NOAA-created public-domain material is useful; check captions for third-party copyright exceptions and retain the requested credit. |
| [Smithsonian 3D](https://3d.si.edu/) and [Open Access](https://www.si.edu/openaccess) | Downloadable specimen scans, including some marine organisms | Select explicitly CC0 assets. Availability of a catalog record does not mean a downloadable 3D model exists. Preserved specimens may need substantial adaptation for living animals. |
| [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Extremophiles) | Photographs and microscopy from many institutions | Check each file. CC0 and CC BY are useful; retain author, source, license and modifications. Other licenses need separate assessment. |
| [FathomNet](https://www.fathomnet.org/datause) | Annotated underwater imagery and identification reference | Do not bulk-import image assets. Some image licenses restrict commercial reuse or derivatives; permission for commercial machine-learning training does not grant game-texture rights. |

A concrete microscopy example is the [chimney microbial morphotypes image](https://commons.wikimedia.org/wiki/File:Confocal_laser_scanning_microscopy_images_showing_different_microbial_morphotyes_in_chimney_samples.webp),
licensed CC BY 4.0. Credit Aurélien Lecoeuvre, Bénédicte Ménez, Mathilde Cannat,
Valérie Chavagnac and Emmanuelle Gérard; retain its linked primary paper.
Microscope staining/autofluorescence must not be presented as natural visible
bioluminescence, and morphology alone does not identify a species.

## Asset workflow

1. Identify the organism, habitat and depth using scientific records. Deep-sea
   animals and extremophilic microbes are distinct groups, not interchangeable.
2. Look for a commercially reusable textured scan or an anatomically suitable
   model. Check both the model and its texture rights, including redistribution
   in this public source repository.
3. If needed, use multiple licensed photo angles to paint textures onto a model
   in Blender. One image cannot supply unseen anatomy or a full 360-degree skin.
   Flatten ROV lighting and shadows where possible before applying game lighting.
4. Retopologize, create detail maps and lower-detail variants, rig and animate.
   Validate silhouette, scale and motion against references before integration.
5. Test one detailed organism in the 3D inspector and on an iPad before expanding
   the collection. Transparent/translucent bodies need materials as well as skins.
6. Use image-based sprites or simple animated meshes for suitable distant life.
   Show real microscopy in the lab as labeled observations rather than implying
   it is a navigable, naturally glowing 3D creature.

For every imported file record its canonical URL, creator, exact license/version,
download date, original filename, changes, species confidence and depth reference.
Preserve these credits with exports. A freely downloadable file is not necessarily
licensed for a commercial game or public redistribution.
