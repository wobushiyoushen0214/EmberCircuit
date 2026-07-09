# VFX Asset Manifest

This folder contains replaceable placeholder VFX sprites for `EmberCircuit`.

## Current Placeholder Assets

- `vfx_attack_slash.svg`: attack card landing slash.
- `vfx_skill_guard.svg`: skill card guard pulse.
- `vfx_power_pulse.svg`: power card energy ring.
- `vfx_card_default.svg`: fallback card landing pulse.
- `vfx_enemy_hit.svg`: enemy hit impact burst.
- `vfx_player_hit.svg`: player hit danger burst.
- `vfx_enemy_defeated.svg`: enemy defeat burst.
- `vfx_phase_burst.svg`: boss phase transition burst.

## Replacement Rules

- Keep filenames stable while `data/config/vfx_profiles.json` references them.
- Final VFX sprites should have transparent backgrounds.
- Sprites should remain readable at 96 px and 192 px.
- Particle scene replacements can be added later through the same profile data.
