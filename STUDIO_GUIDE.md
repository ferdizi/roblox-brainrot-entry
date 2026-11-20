# STUDIO_GUIDE.md — Play-test + screenshots for Brainrot Bazaar v2 (for Gadiel)

You are the only one who can do these steps: they need Roblox Studio on your
computer and your Roblox account. The place is ALREADY published as Public
**Brainrot Bazaar** (place_id 131988583337739, universe_id 10777954476, play code
already in the description). Do them in order. Deadline: Fri 20 Nov 2026,
21:30 WIB — screenshots + submit reserve the last 40 minutes (from 20:50 WIB).

## 0. What you need

- Roblox Studio installed (https://create.roblox.com) and signed in as **gmbuyyy**.
- This repository cloned on your computer (`git clone https://github.com/ferdizi/roblox-brainrot-entry`)
  — or download the latest `game.rbxl` from the repo page.
- The `game.rbxl` in this repo is already built with Rojo from the Luau source.
  Open that file — do NOT rebuild it with Rojo on your machine unless you change `src/`.

## 1. Open and play-test (v2 — the rebuild)

1. Open Roblox Studio → open `game.rbxl` from the cloned repo.
2. Press **Play** (F5). You should spawn on a BRIGHT neon night-market street: a
   golden conveyor belt running down the middle, 6 bright market-stall bases
   (3 north, 3 south) with neon signs and glowing pedestals, a "BRAINROT BAZAAR"
   arch, string lights, a cyan safe plaza to the north with a giant glowing
   Pocongo Disco-Ninja statue, and brainrots walking the belt within a few
   seconds — BIG, BRIGHT bodies standing on it, not sunk into it. Each one bobs,
   bounces or spins, with a name tag and "$/s" label in its rarity colour.
   **Check zoom: scroll the mouse wheel — the camera must zoom in/out, and
   right-drag must orbit. If it doesn't, tell the agent immediately.**
3. Walk up to a brainrot on the belt and hold **E** to buy it (or click it, or tap
   its row in the belt list on the right) — it should waddle to a pedestal on your
   base, your money should start ticking up in the top-right HUD, and a floating
   "+$" popup should appear above it every second. The Upgrades panel (U) shows
   each upgrade's next price. The left edge shows the RARITY LEGEND and the
   RICHEST leaderboard. A "HOW TO PLAY" box appears at spawn — click GOT IT.
4. Watch the top-centre banner: a Brainrot Wave warning comes about every 90 seconds
   (10s, siren + countdown). Then a giant hot-pink goo wall sweeps the street and the
   camera shakes. (TOUR.json can jump straight to a warning for the 3-wave.png shot,
   via `WaveServer.skipToWarning` — reviewers only, it changes no money.)
5. Press **Stop** when you are happy it runs. If anything errors, check the Output
   window and tell the agent the exact error line. **Zero errors is the goal.**

## 2. Take the 4 screenshots (in Studio, game running)

Each must be 16:9 (1280x720 is ideal), each under 256 KiB (re-encode as JPEG or
scale down if a capture is bigger), short side at least 480 px. Keep HUD text
clear of the top-left corner (Roblox's own menu buttons sit there). Take each
shot while the game is running — if Studio loses focus the game can pause, so
use Studio's own screenshot (or the OS capture) while the play test is live.

1. **1-start.jpg** (the cover = your thumbnail): spawn view — bright night-market
   street, golden belt with brainrots walking, arch and neon signs behind. Wide shot,
   brainrot bodies + labels readable.
2. **2-play.jpg**: mid-game — a bought brainrot on a pedestal on your base, money
   ticking in the HUD, "+$" popup visible, belt list on the right.
3. **3-wave.jpg**: during a Brainrot Wave warning/wave — red banner, hot-pink goo
   wall sweeping the street.
4. **4-win.jpg**: late game — several brainrots of different rarities on the base,
   a Mythic/Secret one visible with its glow, rebirth or upgrades panel open if you can.

Replace the four files in `screenshots/` with these four. Names must sort in this
order (the first by name is the cover and the judge sees it largest).

## 3. Thumbnail (Creator Dashboard) — THIS IS WHAT GOT v1 REJECTED

1. On the Creator Dashboard, open the **Brainrot Bazaar** experience (the NEW one,
   place 131988583337739) → **Thumbnails** (Experience Detail Page tab).
2. Upload **1-start.jpg FIRST** — it must be the same picture as the first
   screenshot in the repo. Add the other screenshots after it if you like.
3. The icon (Blobfather) is already uploaded. Wait until the experience's page on
   Roblox shows BOTH the icon and the thumbnail. Roblox reviews each upload; the
   entry is refused while either is still in review or blocked, so upload early
   and check the page shows them before submitting.

## 4. Commit, push, tell the agent

```sh
git add game.rbxl screenshots/
git commit -m "v2: real Studio screenshots"
git push
```

Then tell the agent: the thumbnail shows on the Roblox page, and the commit sha.
The agent will run the kit check and, on your separate gas, submit. **Do not submit
before the thumbnail shows on the Roblox page.**
