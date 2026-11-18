# STUDIO_GUIDE.md — Publish BRAINROT KRAKATOA (for Gadiel, on Windows/Mac)

You are the only one who can do these steps: they need Roblox Studio on your
computer and your Roblox account. Do them in order. Deadline: Fri 20 Nov 2026,
21:30 WIB.

## 0. What you need

- Roblox Studio installed (https://create.roblox.com) and signed in to a Roblox
  account that is at least 2 days old and past its age check.
- This repository cloned on your computer (`git clone https://github.com/ferdizi/roblox-brainrot-entry`).
- The `game.rbxl` in this repo is already built with Rojo from the Luau source.
  Open that file — do NOT rebuild it with Rojo on your machine unless you change `src/`.

## 1. Open and play-test

1. Open Roblox Studio → open `game.rbxl` from the cloned repo.
2. Press **Play** (F5). You should spawn near the shop pad on a sandy island:
   a volcano on the west end, a lagoon on the east, a belt running between them,
   8 bases in a ring, and brainrots walking the belt within a few seconds.
3. Click a brainrot on the belt to buy it — it should waddle to your base and your
   money should start ticking up in the top-right HUD.
4. Watch the top-centre banner: a tsunami warning comes about every 90 seconds.
5. Press **Stop** when you are happy it runs. If anything errors, check the Output
   window and tell the agent the exact error line.

## 2. Publish as a NEW Public experience

1. In Studio: **File → Publish to Roblox As…** → **Create new experience**.
2. Name it **BRAINROT KRAKATOA — Tsunami Steal**. (Do not reuse the Coin Rush place.)
3. Fill in a description and a genre when Roblox asks. **Important:** put your
   make.fun play code in the description. Get it with this command (from the kit
   folder, after signing in — the agent will run it for you at submit time):
   `node cli/makefun.mjs check --repo <your repository> --play-code 0`
   The code looks like `makefun-xxx-yyy-zzz`. Paste it as it stands. If Roblox
   refuses a description containing it, try play-code 1, 2 or 3 instead.
4. Answer Roblox's content questions (one question about age-restricted content
   — answer No — or the short questionnaire).
5. On the Creator Dashboard (https://create.roblox.com/dashboard/creations),
   open the experience → set it to **Public**. (It may show as Playtest/Private
   until the description, genre and questions are done.)
6. Find the two IDs:
   - **place_id**: the number in the play link `https://www.roblox.com/games/<place_id>/...`
   - **universe_id**: the number after `experiences/` in the experience's address
     on the Creator Dashboard (or `game.GameId` in Studio — NOT `game.PlaceId`).
7. Edit `PLAY.json` in the repo to:
   `{"url": "https://www.roblox.com/games/<place_id>/BRAINROT-KRAKATOA-Tsunami-Steal", "place_id": <place_id>, "universe_id": <universe_id>}`

## 3. Take the 4 screenshots (in Studio, game running)

Each must be 16:9 (1280x720 is ideal), each under 256 KiB (re-encode as JPEG or
scale down if a capture is bigger), short side at least 480 px. Keep HUD text
clear of the top-left corner (Roblox's own menu buttons sit there). Take each
shot while the game is running — if Studio loses focus the game can pause, so
use Studio's own screenshot (or the OS capture) while the play test is live.

1. **1-start.png** (the cover = your thumbnail): spawn view — island, belt with
   brainrots walking, volcano behind. Wide shot, brainrot labels readable.
2. **2-play.png**: mid-game — a bought brainrot on your base, money ticking in the
   HUD, belt list on the right.
3. **3-tsunami.png**: during a tsunami warning/wave — red banner, wave wall on the belt.
4. **4-win.png**: late game — several brainrots on the base, a rare/mythic one visible,
   rebirth or upgrades panel open if you can.

Replace the three starter files in `screenshots/` with these four. Names must sort
in this order (the first by name is the cover and the judge sees it largest).

## 4. Icon + thumbnail (Creator Dashboard)

1. On the Creator Dashboard, open the experience → Configurations → Places →
   pick the start place (marked with a star) → **Icon**: upload a square picture
   (512x512 is best) of the game.
2. **Thumbnails** (Experience Detail Page tab): upload **1-start.png** FIRST — it
   must be the same picture as one of the screenshots in the repo. Add the other
   screenshots after it if you like.
3. Wait until the experience's page on Roblox shows both the icon and the thumbnail.
   Roblox reviews each upload; the entry is refused while either is still in review
   or blocked, so upload early and check the page shows them before submitting.

## 5. Commit, push, tell the agent

```sh
git add PLAY.json screenshots/ game.rbxl
git commit -m "Publish: PLAY.json + 4 real Studio screenshots"
git push
```

Then tell the agent: the place is Public, the icon + thumbnail show on the page,
and the commit sha. The agent will run the kit check and, on your separate gas,
submit. **Do not submit before the thumbnail shows on the Roblox page.**
