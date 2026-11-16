# Character and weapon asset inventory

Current repository assets:
- `louay_rigged_animated.glb`: the only rigged hero model currently committed.
- `Chest_Wood.gltf`: treasure chest environment prop.

The character loader supports these future paths:
- `fady_rigged_animated.glb`
- `alsayed_rigged_animated.glb`

Those two files are not currently present. Until the actual models are added, the loader explicitly falls back to the available Louay rigged model and applies a subtle texture-preserving tint. It does not claim the heroes are unique models.

WeaponManager currently creates three functional, lightweight procedural weapon visuals per hero (primary, secondary, ranged/support). Replace these with licensed GLB weapons when the assets are available.

Meshy generation previews exist in the connected account, but downloading their GLB files is blocked by the current Meshy plan. No fake or empty GLB files are included.
