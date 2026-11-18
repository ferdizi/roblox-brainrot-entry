# BRAINROT KRAKATOA — Tsunami Steal

[![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ferdizi/roblox-brainrot-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ferdizi/roblox-brainrot-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A make.fun **roblox-brainrot-01** entry: a 3D Steal-a-Brainrot-style game built by an AI agent,
played in Roblox's 3D world. Brainrots walk a belt across a volcanic island lagoon. Buy
one, and it waddles home to your base and earns money every second. Climb the rarity
ladder, chase Gold / Diamond / Rainbow / Storm mutations, steal from other players'
bases (or lock your own shut), and outrun the tsunami that sweeps the belt every
~90 seconds. Rebirth for a permanent +50% income per rebirth.

## The cast (original — no borrowed characters)

| Brainrot | Rarity | $/s | Belt cost |
|---|---|---|---|
| Kopi Kura-Kura | Common | 5 | $50 |
| Nasi Goreng Ninja | Rare | 15 | $150 |
| Bakso Blast | Epic | 40 | $400 |
| Durian Doom | Legendary | 120 | $1,200 |
| Es Teh Tsunami | Mythic | 350 | $3,500 |
| Krakatoa King | Secret | 1,000 | $10,000 |

Mutations multiply the rate: Gold x2, Diamond x5, Rainbow x10, Storm x8 (Storm only
rolls while a tsunami warning is live).

## The loop

1. **Buy** — click a brainrot walking the belt (or tap its row in the belt list).
   It walks to a free slot on your base and starts paying $/second.
2. **Earn** — income ticks server-side every second; the HUD shows cash, $/s and slots.
3. **Steal** — click a brainrot on someone else's base, carry it home on foot.
   The victim can **slap** (F) to knock it out of your hands. **Lock** your base (L)
   for 30s to block stealing entirely (90s cooldown).
4. **Survive** — every ~90s a tsunami warning sounds (10s), then a wave wall sweeps
   the belt, washing away un-bought brainrots. Caught in the open, you are thrown
   back and lose 10% of your cash. Hide in your base or on the safe hill.
5. **Progress** — upgrades (extra slots, walk speed, slap power, longer lock),
   rebirths (+50% income each), a BrainrotDex, and a Contract Board with cash rewards.

## Controls

- Move: WASD / arrow keys (default Roblox controls)
- **L** lock base · **F** slap · **R** rebirth · **U** upgrades · **B** BrainrotDex · **C** contracts
- Click a belt brainrot to buy it; click a base brainrot to try to steal it.

## How it is built

- `default.project.json` — the Rojo project. The 3D island (bases, belt, volcano,
  lagoon, safe hill) is built in code by `src/server/WorldBuilder.luau` at startup.
- `src/shared/Config.luau` — the cast, rarities, mutations, wave and steal timings.
- `src/server/State.luau` — the single state store (money, brainrots, locks).
- `src/server/BrainrotServer.luau` — belt spawning, buying, income tick, rebirth.
- `src/server/StealServer.luau` — stealing, carrying, slapping, locking.
- `src/server/WaveServer.luau` — the tsunami cycle and the wave wall.
- `src/client/` — `Game.client.luau` bootstrap, `Ui.luau` HUD, `Input.luau` keys.
- `main.ts` (Node 22, standard library only) hands the entry in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`.

Build it:

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## ⚠️ Status — Studio steps still needed

`PLAY.json` still has `place_id` / `universe_id` 0 and `screenshots/` still holds the
kit starter's captures. Before submitting, the account owner must publish this place
as a new Public experience in Roblox Studio, take 4 real screenshots of the running
game, replace `screenshots/`, and fill in `PLAY.json`. See **STUDIO_GUIDE.md** for the
exact steps. `docs/preview-concept.png` is a concept illustration only — it is NOT a
Studio capture and must never go into `screenshots/`.
