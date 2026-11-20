# BRAINROT BAZAAR

[![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ferdizi/roblox-brainrot-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ferdizi/roblox-brainrot-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A make.fun **roblox-brainrot-01** entry: a 3D Steal-a-Brainrot-style game built by an AI agent,
played in Roblox's 3D world. You run a base on a neon night-market street. A conveyor
belt brings absurd meme characters past the shop — buy one (hold E near it, click it,
or tap its row in the belt list), and it waddles home to a pedestal on your base and
earns money every second. Climb the rarity ladder, chase Gold / Diamond / Rainbow /
Glitch mutations, steal from other players' bases (or lock your own shut), and outrun
the giant Brainrot Wave — a hot-pink goo wall that sweeps the street every ~90 seconds.
Rebirth for a permanent +50% income per rebirth.

## The cast (original — no borrowed characters)

| Brainrot | Rarity | $/s | Belt cost |
|---|---|---|---|
| Soggy Toastino | Common | 2 | $20 |
| Bonk Pigeon | Common | 4 | $40 |
| Captain Noodlebeard | Rare | 12 | $120 |
| Lil Wobblecone | Rare | 18 | $180 |
| Sir Crustacio | Epic | 60 | $600 |
| Madame Flamingatto | Epic | 85 | $850 |
| Turbo Tungtung Toaster-Jr | Legendary | 300 | $3,000 |
| Duchess Cactoona | Legendary | 420 | $4,200 |
| Glorpo the Ghost Burger | Mythic | 1,500 | $15,000 |
| Baron Vroomvroom | Mythic | 2,200 | $22,000 |
| The Great Brainrot Blobfather | Secret | 12,000 | $120,000 |

Mutations multiply the rate: Gold x1.5, Diamond x2, Rainbow x3, Glitch x4 (Glitch only
rolls while a wave warning is live). A Mythic or Secret rolling on the belt fires a
server-wide announcement banner with a sound.

## The loop

1. **Buy** — hold E near a brainrot walking the belt (ProximityPrompt), click it, or
   tap its row in the belt list. It walks to a free pedestal on your base and starts
   paying $/second, with a floating "+$" popup every tick.
2. **Earn** — income ticks server-side every second; the HUD shows cash, $/s and slots.
   Upgrade buttons show the next level's price; the lock button shows locked / cooldown seconds.
   A richest-players leaderboard sits on the left edge.
3. **Steal** — click a brainrot on someone else's base, carry it home on foot.
   The victim can **slap** (F) to knock it out of your hands. **Lock** your base (L)
   for 30s to block stealing entirely (90s cooldown).
4. **Survive** — every ~90s a wave warning sounds (10s, siren + red banner + countdown),
   then a giant goo wall sweeps the street, washing away un-bought brainrots. Caught in
   the open, you are thrown back and lose 10% of your cash. Hide in your base or on the
   safe plaza. The camera shakes while the wave passes.
5. **Progress** — upgrades (extra slots, walk speed, slap power, longer lock, faster
   conveyor), rebirths (+50% income each), a BrainrotDex, a rarity legend, and a
   Contract Board with cash rewards.

## The world

A neon night market, not a bare field: an asphalt street with pink/cyan neon edges,
six market-stall bases (three north, three south) with awnings, neon signs and glowing
pedestals, eight stalls, a "BRAINROT BAZAAR" arch, string lights, banners, lanterns,
steam and confetti, a skyline, and the wave's silhouette waiting at the west end.
Night lighting (deep purple/blue sky, Atmosphere + Bloom + ColorCorrection) makes the
hot-pink and cyan neon pop. Every brainrot bobs, bounces or spins, and rarer ones glow.

## Controls

- Move: WASD / arrow keys (default Roblox controls)
- **E** hold to buy a belt brainrot (ProximityPrompt)
- **L** lock base · **F** slap · **R** rebirth · **U** upgrades · **B** BrainrotDex · **C** contracts
- Click a belt brainrot to buy it; click a base brainrot to try to steal it.

## How it is built

- `default.project.json` — the Rojo project. The 3D night market (street, stall-bases,
  arch, plaza, decor) is built in code by `src/server/WorldBuilder.luau` at startup.
- `src/shared/Config.luau` — the cast, rarities, mutations, wave and steal timings.
- `src/server/State.luau` — the single state store (money, brainrots, locks, leaderboard).
- `src/server/BrainrotServer.luau` — belt spawning, buying, income tick, rebirth, idle animation.
- `src/server/StealServer.luau` — stealing, carrying, slapping, locking.
- `src/server/WaveServer.luau` — the wave cycle and the goo wall.
- `src/client/` — `Game.client.luau` bootstrap, `Ui.luau` HUD, `Announce.client.luau`
  (mythic banner, leaderboard, screen shake), `Input.luau` keys.
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
