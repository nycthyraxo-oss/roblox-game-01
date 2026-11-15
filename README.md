# Rainbow Rush

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/nycthyraxo-oss/roblox-game-01/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/nycthyraxo-oss/roblox-game-01/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

A color-matching survival game for Roblox, built for the [make.fun](https://make.fun/bounty/roblox-game-01)
**roblox-game-01** bounty ("Make the best Roblox game", $250, top 20 share).

## The game

You spawn in a bright lobby above a sea of lava. In front of you floats a
5×5 grid of glowing pads in six colors: red, orange, yellow, green, blue
and purple.

Each round, a color is called. Run to a pad of that color before the timer
ends — every pad of another color sinks into the lava. Survive a call and
you earn 10 points; grab a golden star on a correct pad for 5 bonus points.
Fall in the lava and you are out until the next round. After 75 seconds the
round ends, the top three players stand on the winners' podium under a
confetti burst, and a new round begins.

- **Goal:** most points when the round ends.
- **Controls:** walk and jump (WASD / arrow keys + Space, or mobile joystick).
- **State on screen:** the called color (big swatch + name), a draining
  timer bar, your points, a top-5 leaderboard, and a results screen.
- **Depth:** color calls, sinking pads, bonus stars, lava elimination,
  rounds that loop with a fresh grid shuffle every server.

## Project layout

```
main.ts                  Entry point: copies the place, sources, screenshots
                         and PLAY.json to /output and writes dossier.json.
default.project.json     Rojo project (name rainbow-rush).
game.rbxl                The place, built with Rojo from src/ (see below).
PLAY.json                Link to the published Public place on Roblox.
LICENSE                  MIT.
screenshots/              3-4 screenshots (start / play / end), taken in
                         Roblox Studio — see STUDIO-STEPS.md.
src/
  shared/Config.luau     Every tuning number: colors, timings, points, sizes.
  server/MapBuilder.luau Builds the arena at runtime: lava sea, pad grid,
                         lobby, rainbow arch, clouds, pillars, trees, podium.
  server/PadService.luau Sinks and raises pads; spawns and validates stars.
  server/ScoreService.luau Server-owned points, leaderstats, top players.
  server/RoundService.luau The round state machine: lobby, calls, results.
  server/MainServer.server.luau
                         Entry point: remotes, services, round loop.
  client/HudClient.client.luau
                         All interface: lobby screen, target banner, timer,
                         score, leaderboard, elimination and results screens.
vendor/makefun-roblox.ts The kit's dossier library, unchanged.
STUDIO-STEPS.md          What to do in Roblox Studio on a PC (publish,
                         play-test, screenshots, PLAY.json).
```

## Architecture

The server owns everything that matters: points, pad states, round state
and eliminations. The client only displays what the server sends — all
three RemoteEvents (`RoundUpdate`, `ScoreUpdate`, `ResultsEvent`) are
server-to-client only, and star collection is validated server-side
(alive in this round, close enough to have really touched the star, and
not spamming). Scores live for the server's lifetime; there is no DataStore,
so nothing persists between servers by design.

## Build

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` needs `game.rbxl`, `PLAY.json`, `src/` and 3–4 screenshots in
`screenshots/` (each at most 256 KiB); it refuses to hand in an entry
without them. The place file is built from `src/` with Rojo — never run
`rojo build` over a place saved from Studio; see STUDIO-STEPS.md for the
two-way rule.

## License

MIT — see LICENSE.
