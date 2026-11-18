// BRAINROT KRAKATOA — a make.fun roblox-brainrot-01 entry (Node 22, standard library only).
// A 3D Steal-a-Brainrot-style game: brainrots walk a belt across a volcanic island lagoon,
// players buy them onto their base, earn $/second, steal from each other under a lock,
// and outrun a tsunami every ~90 seconds. Rebirths, mutations, upgrades, a BrainrotDex
// and a Contract Board round out the loop. The game is this directory's Rojo project,
// built into game.rbxl with `rojo build default.project.json --output game.rbxl`.
//
// This program hands it in: it copies game.rbxl, src/, screenshots/ and PLAY.json from
// beside this file to /output and writes /output/dossier.json, the summary the judge
// reads, with the vendored make.fun library.
//
// ⚠️ BEFORE SUBMITTING: PLAY.json still has place_id/universe_id 0 and screenshots/
// still holds the kit starter's three captures. The account owner must publish this
// place as a NEW Public experience in Roblox Studio, take 4 real screenshots of the
// running game, replace screenshots/, and fill PLAY.json with the new place_id and
// universe_id. Until then the gate refuses this entry (that is the safety net).
// See STUDIO_GUIDE.md in this repository for the exact Studio steps.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters,
// digits, . _ and -: the grader fails an entry whose output holds any other, so a file
// such as .gitkeep or .DS_Store copied in fails it. So src/ and screenshots/ are
// copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

// Fail fast on a place the gate would refuse outright, instead of
// handing in a 0-byte or oversized game.rbxl and finding out at grade time.
const placePath = join(here, 'game.rbxl');
const placeBytes = statSync(placePath).size;
if (placeBytes === 0 || placeBytes > 32 * 1024 * 1024) {
  throw new Error(`game.rbxl is ${placeBytes} bytes — the gate takes a binary place of 1 byte to 32 MiB.`);
}
const shots = existsSync(join(here, 'screenshots')) ? readdirSync(join(here, 'screenshots')).filter((f) => !f.startsWith('.')) : [];
if (shots.length < 3 || shots.length > 4) {
  console.warn(`WARNING: screenshots/ holds ${shots.length} images — the gate takes 3 or 4.`);
}

// Make sure the output directory exists before the first copy lands in it.
mkdirSync(out, { recursive: true });

const play = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8')) as { place_id?: unknown; universe_id?: unknown };
if (play.place_id === 0 || play.universe_id === 0) {
  console.warn('WARNING: PLAY.json still has place_id/universe_id 0 — publish the experience and fill it in before submitting.');
}

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
