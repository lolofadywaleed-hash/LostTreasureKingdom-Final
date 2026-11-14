# Lost Treasure Kingdom — Full Overhaul Plan

## Approved direction
- Genre: 3D anime-inspired adventure.
- World: open-world direction, expanded in connected regions rather than a single fenced arena.
- Priority: visual quality first, while preserving stable gameplay systems.
- Platform target: Android/mobile first; Godot 4.3 compatibility and mobile performance are mandatory.

## Non-negotiable safeguards
- Work on this branch first; do not replace the repository or overwrite main.
- Preserve player movement, camera, touch input, combat, health, enemies, collectibles, chest interaction, character selection, and Android export until each replacement has passed tests.
- No fake claims about AAA quality, full open world, or completed assets.
- Every milestone must pass GDScript parsing, scene smoke tests, Android export, and an on-device visual/performance check before merging to main.

## Full transformation workstreams

### 1. Visual identity and presentation
- Establish a consistent anime-fantasy art direction: cinematic color palette, readable silhouettes, detailed materials, coherent scale, lighting, fog, atmosphere, and VFX.
- Replace placeholder-looking UI with a unified title/menu, hero-selection presentation, HUD, pause/settings, and feedback states.
- Keep UI legible on landscape Android screens and different aspect ratios.

### 2. Heroes and animation
- Audit every existing character image/model and its license/source before use.
- Correct hero identity keys and names (Louay, AlSayed, Fady); selection must load the selected hero's own visual scene, not the same fixed model for every choice.
- Use rigged models with verified idle, walk, run, jump, attack, hit, and victory animations where available.
- Keep gameplay collision and movement independent from render rigs.

### 3. World and environment
- Replace CSG placeholder castle, terrain props, trees, rocks, and landmarks with cohesive production-ready meshes/materials.
- Build a polished starting region with a landmark, readable paths, exploration points, treasure spaces, enemy encounter spaces, and distant vistas.
- Add connected regions and controlled streaming/activation progressively; remove invisible arena walls only when navigation, boundaries, and performance are ready.
- Add mobile-friendly environment detail, foliage variation, decals, particles, ambient sound hooks, and day/night only where performance allows.

### 4. Gameplay and exploration
- Preserve and improve touch joystick, camera drag, attack, jump, skill, dodge, and interaction controls.
- Add clear objectives, treasure discovery, enemy encounters, boss progression, rewards, and save/checkpoint structure.
- Ensure combat feedback, health/damage readability, hit reactions, and mobile UI scaling.

### 5. Technical quality and Android delivery
- Profile frame time, memory, draw calls, texture sizes, and loading on Android.
- Prefer LOD, MultiMesh, occlusion/frustum culling, compressed textures, and region-based loading where appropriate.
- Keep package identity stable unless a deliberate migration is planned.
- Produce a verified APK artifact for every release candidate.

## Milestone order
1. Repository and asset audit (models, textures, animations, licenses, scene references, broken paths).
2. Hero selection and character visual pipeline correction.
3. New visual foundation and first-region environment replacement.
4. Main menu, hero-select, HUD, pause/settings visual redesign.
5. Combat animation/VFX/audio feedback and exploration loop.
6. Connected region architecture and open-world expansion.
7. Android performance pass, regression tests, and release candidate.

## Known issues to resolve during audit
- Character selection currently uses internal keys Lolo, AlSayed, and Fady; project naming should consistently use Louay, AlSayed, and Fady.
- Character selection stores a selected hero, but the main player currently loads a fixed Louay model path; per-hero model routing is required.
- KnightVisual is configured with hide_old_visual = false in the main scene and its animation driver is disabled in player startup; animation ownership must be consolidated to avoid conflicts.
- The starting region still uses CSG primitives for the castle and some props and has perimeter collision walls; it is not yet a seamless open world.
- Verify the root-level knight_visual.gd reference and every scene/script path during the audit.
- Verify Android package name and export configuration before changing release identity.

## Definition of done
A milestone is complete only when its actual assets/code are committed on this branch, tests pass, the Android APK exports successfully, and its behavior is checked on a real phone. The plan itself is not evidence that these transformations have already been implemented.