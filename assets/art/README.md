# Art Asset Manifest

This folder contains first-pass production SVG assets and stable replacement slots for `EmberCircuit`.

## Current First-Pass Assets

- `player_ember_exile.svg`: first playable character portrait.
- `player_arc_tinker.svg`: second playable character portrait for the multi-character pipeline.
- `player_pyre_ascetic.svg`: third playable character portrait for the burn/status-pollution pipeline.
- `enemy_*.svg`: per-enemy illustrated SVG slots for all configured normal, elite, and boss enemies.
- `card_attack_frame.svg`: attack card frame direction with warm slash motif.
- `card_skill_frame.svg`: skill card frame direction with cold shield motif.
- `card_power_frame.svg`: power card frame direction with circuit core motif.
- `cards/card_*.svg`: first-pass per-card illustrations for every configured card.
- `relics/relic_*.svg`: first-pass per-relic icons for every configured relic.
- `potions/potion_*.svg`: first-pass per-potion icons for every configured potion.
- `events/event_*.svg`: first-pass per-event illustrations for every configured event.
- `relic_placeholder.svg`: polished relic fallback icon.
- `potion_placeholder.svg`: polished potion fallback icon.
- `potion_placeholder.svg.import`: Godot import metadata for the potion icon.
- `battle_bg_chapter_one.svg`, `battle_bg_chapter_two.svg`, `battle_bg_chapter_three.svg`: first-pass chapter battle backgrounds.
- `event_default.svg`: polished event fallback illustration.
- `map_node_combat.svg`, `map_node_elite.svg`, `map_node_boss.svg`, `map_node_event.svg`, `map_node_shop.svg`, `map_node_campfire.svg`: first-pass map node icon set.

## Data-Driven Slots

- `data/config/art_assets.json` is the authoritative manifest for card art, relic icons, potion icons, event illustrations, chapter battle backgrounds, and card type frames.
- Each configured card has a `card_art_slots[]` entry with a current per-card `asset_path`, future `slot_path`, and design/replacement/implementation notes.
- Each configured relic has a `relic_icon_slots[]` entry with a current per-relic icon and future `assets/art/relics/relic_*.svg` replacement slot.
- Each configured potion has a `potion_icon_slots[]` entry with a current per-potion icon and future `assets/art/potions/potion_*.svg` replacement slot.
- Each configured event has an `event_art_slots[]` entry with a current per-event illustration and future `assets/art/events/event_*.svg` replacement slot.
- Each chapter has a `battle_background_slots[]` entry with a current background and future `assets/art/backgrounds/battle_bg_*.svg` replacement slot.
- `Main.gd` reads the manifest for hand cards, combat rewards, shop buttons, relic rewards, potion slots, event story panels, and battle backgrounds. The old hardcoded paths remain fallback only.

## Quality Gate

- First-screen SVG assets must not be flat color blocks. Use gradients, layered silhouettes, readable strokes, and controlled glow.
- Character portraits, card illustrations, card frames, battle backgrounds, event illustrations, relic icons, potion icons, and enemy sprites are checked by `tests/test_data_integrity.gd` for readable SVG source, gradient lighting, and minimum shape count.
- Fallback relic, potion, and event assets must remain polished, but configured slots should use item-specific assets through `slot_path`.

## Replacement Rules

- Keep filenames stable until data keys are migrated.
- Final card art should preserve readable name, cost, type, and description areas.
- Enemy art should export with transparent backgrounds.
- Boss art should be readable at 320 px width in combat.
- Battle backgrounds should keep the enemy card area readable and avoid high-contrast detail behind intent badges or HP text.
- Event illustrations should communicate place and decision pressure without covering event text or choice buttons.
- Map node icons should remain readable at 32 px and keep transparent-safe silhouettes.
- When replacing art, update `asset_path` to an imported Godot resource and keep `slot_path` stable as the intended final slot.
