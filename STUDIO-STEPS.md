# STUDIO-STEPS.md — finishing Rainbow Rush in Roblox Studio

The code portion is done and the place file is already built
(`game.rbxl`, built with Rojo from `src/` on Linux). What is left needs
Roblox Studio on a Windows or Mac PC, and the Roblox account that will own
the experience. Follow these steps in order. Nothing here needs a terminal
except step 8, and that one is optional.

**Time needed:** about 20–30 minutes, plus whatever Roblox asks for the
age check / content questions on first publish.

## 0. Before you start

- Install **Roblox Studio** from https://create.roblox.com/ if it is not
  installed yet, and sign in with the account that will publish the game
  (the account must be at least 2 days old and past its age check — an
  account made after this bounty opened cannot publish before it closes).
- Get this repository onto the PC (clone it, or download it as a ZIP and
  extract it). You need at least `game.rbxl`, `src/`, `screenshots/` and
  `PLAY.json` from it.

## 1. Open the place

In Roblox Studio: **File → Open from File…** and pick `game.rbxl`.

You should see a bright arena: a 5×5 grid of glowing colored pads over an
orange lava sea, a white lobby platform behind it with a "RAINBOW RUSH"
sign, a rainbow arch, clouds, pillars, trees and a gold/silver/bronze
podium on the far side.

## 2. Play-test it

1. Click **Play** (the ▶ button at the top, or F5). You spawn in the lobby.
   A "RAINBOW RUSH" panel shows how to play and counts down to the round.
2. When the round starts you are teleported onto a colored pad. The top
   banner calls a color (for example "STAND ON — Blue") with a draining
   timer bar. Run to a blue pad before the timer ends.
3. Watch the wrong pads sink into the lava. If you are on one, you fall in
   and see "You fell in the lava!" — you wait in the lobby for the next
   round. If you survive, you see "+10 Survived!". Touch a golden star for
   "+5 ★ Star!".
4. After about 75 seconds the results screen shows the winner and the top
   three stand on the podium under confetti. Then a new round begins.
5. **Multiplayer test (recommended):** use the **Test** tab → **Clients
   and Servers** → start 1 server and 2 players. Both players should see
   the same called color, the same sinking pads and the same leaderboard.
6. Open **View → Output** and check for red errors. If anything errors,
   copy the exact error text and send it to the agent — do not edit the
   scripts yourself unless you also copy the new text back (see step 7).

## 3. Publish as a Public experience

1. **File → Publish to Roblox As…** → **Create New Experience**.
   Name it **Rainbow Rush**.
2. Fill in the description (one or two sentences about matching colors and
   dodging lava) and pick a genre. Roblox refuses a name or description
   that reads as a web address.
3. Answer Roblox's content questions. If it asks one question about
   age-restricted content, answering **No** ends the questionnaire there.
4. Go to the **Creator Dashboard** (https://create.roblox.com/dashboard),
   open the experience, and set it to **Public**. Only the account owner
   can do this. If Roblox asks for the age check first, complete it
   (facial age estimation or a government ID) — this is a one-time step
   for the account.
5. **Optional but recommended:** on the Creator Dashboard, under the
   experience's start place, upload a thumbnail and an icon. make.fun's
   Feed shows the thumbnail beside your entry.

## 4. Take 3–4 screenshots (start, play, end)

These are what the AI judge sees, so make them count:

1. **Start (cover — this one is shown largest):** in Play mode, stand in
   the lobby during the countdown so the "RAINBOW RUSH" panel and the
   colorful arena behind it are both visible.
2. **Play:** mid-round, standing on a pad of the called color, with the
   target banner and timer visible at the top and other pads sinking.
3. **End:** the results screen, or the winners standing on the podium
   under the confetti.
4. (Optional) A fourth shot: a wide view of the whole arena from above
   (move the camera in Studio's viewport before pressing Play, or use the
   Play camera).

Take them with Studio's screenshot button or Windows **Snipping Tool**.
Each file must be a PNG or JPEG, **at most 256 KiB**, long side at most
1280 px and short side at least 360 px. If a capture is bigger, scale it
down or re-encode it (for example with Paint: resize to 1280 px wide, save
as JPEG quality 80).

Save them in the repository's `screenshots/` folder as:

```
screenshots/1-start.png   (the cover — first by name)
screenshots/2-play.png
screenshots/3-end.png
screenshots/4-arena.png   (optional)
```

Delete any placeholder already in that folder. Never ship a screenshot
of a different game, a blank image, or an edited/composited one.

## 5. Fill in PLAY.json

Open the published game on roblox.com. The URL looks like:

```
https://www.roblox.com/games/1234567890/Rainbow-Rush
```

The number after `/games/` is the **place_id**. The **universe_id** is
shown in the Creator Dashboard URL for the experience
(`.../dashboard/creations/experiences/<universe_id>/...`), or on the
experience's "Configure" page.

Edit `PLAY.json` in the repository to:

```json
{"place_id": 1234567890, "universe_id": 123456789, "url": "https://www.roblox.com/games/1234567890/Rainbow-Rush"}
```

(Use your real numbers and the real URL.)

## 6. If you changed a script in Studio

**Do not run `rojo build` over a place saved from Studio** — it would
overwrite your Studio edits. Instead:

- If you edited a script in Studio, copy its full new text and send it to
  the agent. The agent updates the matching file under `src/` and rebuilds
  `game.rbxl` with Rojo.
- If you did **not** edit any script, the `game.rbxl` already in the
  repository stays valid, even after publishing. Publishing does not
  change the file.

If you only moved parts around in Studio (not scripts), tell the agent
what moved — the map is built by `src/server/MapBuilder.luau`, so a
Studio-only move would be lost on the next Rojo build.

## 7. Hand back to the agent

Tell the agent: screenshots are in place, `PLAY.json` is filled in, and
whether any script changed. The agent then runs the program, the local
check, the transcript bundle and the submission.

## Checklist

- [ ] Place opens in Studio, no red errors in Output
- [ ] Play-test passed (round starts, pads sink, stars pay, results show)
- [ ] Multiplayer test passed (2 players see the same game)
- [ ] Published as a **Public** experience
- [ ] Thumbnail / icon uploaded (optional)
- [ ] 3–4 screenshots in `screenshots/`, each ≤ 256 KiB
- [ ] `PLAY.json` filled with the real place_id, universe_id and URL
- [ ] No script changed in Studio, or the new text sent to the agent
