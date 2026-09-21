# Shadowfetch Roulette architecture

Presentation-independent rules sit in `scripts/roulette/`. The 3D table, camera, and menus never compute payouts.

## Rules

- `RouletteTypes` — European wheel order, colors, payout table.
- `RouletteBet` — one placement: kind, covered pockets, integer stake.
- `BetCatalog` — every legal straight, split, street, corner, six-line, and outside template.
- `RouletteEngine` — bankroll, place/undo/clear/repeat, one `begin_spin` / `resolve` pair per round.

Stake leaves the bankroll when a chip is placed. A win returns stake plus odds. A second `resolve` on the same spin index is rejected.

## Persistence

`SettingsStore` reads and writes `settings.json` under the XDG config directory (`shadowfetch-roulette`). Corrupt or impossible values reset to defaults and are rewritten. Statistics live under the XDG data directory.

Override directories with `SHADOWFETCH_ROULETTE_CONFIG` and `SHADOWFETCH_ROULETTE_DATA` (used by tests).

## Presentation

`WheelView` builds a 37-pocket rotor and drives the ball to the pocket the engine already chose. `TableView` is felt, rail, and chip trays. `CinematicCamera` is a fast orbit, not a slow fly-through. `BettingLayout` is the full felt plus a catalog menu for every inside combination.

## Tests

`tests/test_roulette_engine.gd` checks every catalog template against every pocket, bankroll identities, limits, and 120,000 randomized multi-bet resolutions. `tests/test_settings_store.gd` covers persist and corrupt recovery.
