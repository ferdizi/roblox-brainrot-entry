# BRAINROT BAZAAR v2

[![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ferdizi/roblox-brainrot-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ferdizi/roblox-brainrot-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A make.fun **roblox-brainrot-01** entry: a 3D Steal-a-Brainrot-style game built by an AI agent,
played in Roblox's 3D world. You run a base on a bright neon night-market street. A golden
conveyor belt brings absurd meme characters past the shop — buy one (hold E near it, click it,
or tap its row in the belt list), and it waddles home to a pedestal on your base and earns
money every second. Climb the rarity ladder, chase Gula Aren / Gosong / Glitch / Pelangi
mutations, and outrun the giant Brainrot Wave — a hot-pink goo wall that sweeps the street
every ~90 seconds. Rebirth for a permanent +50% income per rebirth. No stealing: the wave
is the one and only threat.

## The cast (25 original characters — Gadiel's roster)

| Brainrot | Rarity | $/s | Belt cost |
|---|---|---|---|
| Sandalo Pepino | Common | 2 | $20 |
| Kerupuko Dudu | Common | 4 | $40 |
| Bantalo Zzz | Common | 6 | $60 |
| Soggy Toastino | Common | 8 | $80 |
| Bonk Pigeon | Common | 10 | $100 |
| Gorengo Splash | Rare | 15 | $150 |
| Cilokko Bambino | Rare | 18 | $180 |
| Sendokini Spin | Rare | 24 | $240 |
| Professor Pickles | Rare | 30 | $300 |
| Disco Dumpling | Rare | 40 | $400 |
| Tahuro Turbino | Epic | 60 | $600 |
| Kopiccino Zoomzoom | Epic | 85 | $850 |
| Bakwanto Gladiatore | Epic | 110 | $1,100 |
| Sir Crustacio | Epic | 130 | $1,300 |
| Madame Flamingatto | Epic | 150 | $1,500 |
| Sambalo Dragonelli | Legendary | 300 | $3,000 |
| Nasgorini Crocodilo | Legendary | 420 | $4,200 |
| Odongo Bombardiro | Legendary | 500 | $5,000 |
| King Kebab | Legendary | 550 | $5,500 |
| The Great Gazpacho | Legendary | 600 | $6,000 |
| Rendangzilla Mamma | Mythic | 1,500 | $15,000 |
| Ojeklo Turbo-Turbo | Mythic | 2,200 | $22,000 |
| Glorpo the Ghost Burger | Mythic | 2,500 | $25,000 |
| Tuyul Cosmico | Secret | 8,000 | $80,000 |
| Pocongo Disco-Ninja | Secret | 12,000 | $120,000 |

Mutations multiply the rate, each with a different visual: **Gula Aren x1.5** (golden sugar
glaze), **Gosong x2** (charred black + ember glow), **Glitch x3** (flickering purple/cyan,
only rolls while a wave warning is live), **Pelangi x5** (rainbow cycling colours). Secret
characters glow rainbow. Mythic and Secret are the biggest, brightest, and carry the
most lights and effects. A Mythic or Secret rolling on the belt fires a server-wide
announcement banner with a sound.

## The loop

1. **Buy** — hold E near a brainrot walking the belt (ProximityPrompt), click it, or
   tap its row in the belt list. It walks to a free pedestal on your base and starts
   paying $/second, with a floating "+$" popup every tick.
2. **Earn** — income ticks server-side every second; the HUD shows cash, $/s and slots.
   A richest-players leaderboard sits on the left edge. A **Golden Rush** pays 2x income
   for 30 seconds every ~2.5 minutes.
3. **Survive** — every ~90s a wave warning sounds (10s, siren + red banner + countdown),
   then a giant goo wall sweeps the street, washing away un-bought brainrots. Caught in
   the open, you are thrown back and lose 10% of your cash. Hide in your base or on the
   safe plaza, under the giant glowing Pocongo Disco-Ninja statue. The camera shakes
   while the wave passes.
4. **Progress** — upgrades (extra slots, walk speed, faster conveyor, Golden Touch +10%
   income per level), rebirths (+50% income each), a BrainrotDex (25 entries), a rarity
   legend, and a Quest Board with six goals and cash rewards. Progress saves with a
   DataStore (money, rebirths, upgrades, Dex, quests, owned brainrots).

## The world

A BRIGHT neon night market, not a bare field: warm-cream ground, a red-carpet street
with pink/cyan neon edges, a golden conveyor with neon rails, six bright market-stall
bases (three north, three south) with awnings, neon signs and glowing pedestals, eight
stalls, a "BRAINROT BAZAAR" arch, string lights, banners, lanterns, steam and confetti,
a skyline, the wave's silhouette waiting at the west end, and the giant Pocongo
Disco-Ninja statue on the safe plaza. Bright golden-hour lighting (Ambient 0.7,
Brightness 3, Atmosphere + Bloom + ColorCorrection) makes the neon pop and every
character read from across the street. Every brainrot bobs, bounces or spins, and
rarer ones glow. The camera is the DEFAULT Roblox camera — the spawn faces the belt,
so the first view is already the good one, and zoom + orbit keep working.

## Controls

- Move: WASD / arrow keys (default Roblox controls)
- **E** hold to buy a belt brainrot (ProximityPrompt)
- **R** rebirth · **U** upgrades · **B** BrainrotDex · **C** quests
- Click a belt brainrot to buy it.

## How it is built

- `default.project.json` — the Rojo project. The 3D night market (street, stall-bases,
  arch, plaza, statue, decor) is built in code by `src/server/WorldBuilder.luau` at startup.
- `src/shared/Config.luau` — the cast, rarities, mutations, wave and rush timings.
- `src/server/State.luau` — the single state store (money, brainrots, leaderboard).
- `src/server/DataStore.luau` — pcall-wrapped save/load (money, rebirths, upgrades,
  Dex, quests, owned brainrots).
- `src/server/BrainrotServer.luau` — belt spawning, buying, income tick, rebirth,
  idle animation, mutation/rarity colour cycling.
- `src/server/WaveServer.luau` — the wave cycle, the goo wall, and the Golden Rush.
- `src/client/` — `Game.client.luau` bootstrap, `Ui.luau` HUD (money, wave, belt,
  quests, tutorial), `Announce.client.luau` (mythic banner, leaderboard, screen
  shake), `Input.luau` keys.
- `main.ts` (Node 22, standard library only) hands the entry in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`.

Build it:

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## ⚠️ Status — Studio steps still needed

The place is already published as Public **Brainrot Bazaar** (place_id 131988583337739,
universe_id 10777954476) with the play code in its description. Before submitting, the
account owner must play-test this v2 build in Roblox Studio, take 4 real screenshots
of the running game, replace `screenshots/` (currently the v1 AI images), and upload
**1-start.jpg** as the first Roblox thumbnail. See **STUDIO_GUIDE.md** for the exact
steps. `docs/preview-concept.png` is a concept illustration only — it is NOT a Studio
capture and must never go into `screenshots/`.
