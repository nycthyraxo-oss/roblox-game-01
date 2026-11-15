// Rainbow Rush — make.fun roblox-game-01 entry (Node 22, standard library only).
//
// The game is the Rojo project in this directory. Build the place first:
//   rojo build default.project.json --output game.rbxl
// Then this program hands the entry in: it copies game.rbxl, PLAY.json, src/
// and screenshots/ beside this file to /output and writes /output/dossier.json,
// the summary the judge reads, with the vendored make.fun library.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

function fail(message: string): never {
  console.error(`main.ts: ${message}`);
  process.exit(1);
}

// The place file is the game itself: refuse to hand in an entry without it,
// instead of copying a stale or missing one.
const placePath = join(here, 'game.rbxl');
if (!existsSync(placePath)) {
  fail('game.rbxl is missing — run: rojo build default.project.json --output game.rbxl');
}

mkdirSync(out, { recursive: true });
copyFileSync(placePath, join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true });

const shotsDir = join(here, 'screenshots');
const shots = existsSync(shotsDir) ? readdirSync(shotsDir).filter((name) => !name.startsWith('.')) : [];
if (shots.length === 0) {
  fail('screenshots/ holds no image — take 3 or 4 screenshots in Roblox Studio first (see STUDIO-STEPS.md)');
}
mkdirSync(join(out, 'screenshots'), { recursive: true });
cpSync(shotsDir, join(out, 'screenshots'), { recursive: true });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the
// bytes; the others refuse an entry the scorer would refuse (more than 4
// screenshots or one over 256 KiB; a place of more than 500000 instances,
// whose scripts' sources come to over 8 MiB or whose scripts' paths come to
// over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);

console.log(`main.ts: wrote ${join(out, 'game.rbxl')}, src/, ${shots.length} screenshot(s), PLAY.json and dossier.json`);
