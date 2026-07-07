# Audio Asset Manifest

`AudioManager.gd` currently generates short placeholder tones at runtime, so the project has feedback without external audio files.

## Planned Replacement Slots

- `ui_click.wav`
- `card_play.wav`
- `turn_end.wav`
- `reward.wav`
- `map_select.wav`
- `campfire.wav`
- `shop.wav`
- `save.wav`
- `error.wav`
- `combat_hit.wav`
- `block_gain.wav`
- `enemy_die.wav`
- `boss_phase.wav`

## Rules

- Keep event names stable.
- Replace generated tones by mapping event IDs to imported audio streams in `AudioManager.gd`.
- UI sounds should stay short and quiet; combat sounds can be layered later.
