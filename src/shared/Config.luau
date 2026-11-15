--!strict
-- Rainbow Rush: shared tuning. One place for every number the game runs on,
-- so the server and the client never disagree about a color, a timer or a score.

export type PadColor = {
	Name: string,
	Color: Color3,
}

local Config = {}

-- The six colors of the game. Bright, saturated, readable at a glance even
-- when the judge's screenshot sheet scales the game down.
Config.COLORS = {
	{ Name = "Red", Color = Color3.fromRGB(255, 70, 70) },
	{ Name = "Orange", Color = Color3.fromRGB(255, 165, 0) },
	{ Name = "Yellow", Color = Color3.fromRGB(255, 235, 59) },
	{ Name = "Green", Color = Color3.fromRGB(80, 220, 100) },
	{ Name = "Blue", Color = Color3.fromRGB(80, 160, 255) },
	{ Name = "Purple", Color = Color3.fromRGB(190, 120, 255) },
} :: { PadColor }

-- Arena geometry (studs).
Config.GRID_SIZE = 5 -- 5x5 pads
Config.PAD_SIZE = 9
Config.PAD_HEIGHT = 2
Config.PAD_GAP = 11 -- center-to-center spacing
Config.PAD_TOP_Y = 0 -- top face of the pads
Config.LAVA_Y = -10 -- top face of the lava sea
Config.LAVA_SIZE = 220
Config.LOBBY_CENTER = Vector3.new(0, 0, -52)
Config.LOBBY_SIZE = Vector3.new(40, 2, 24)
Config.PODIUM_CENTER = Vector3.new(0, 0, 52)

-- Round timing (seconds).
Config.LOBBY_TIME = 12 -- waiting room before a round starts
Config.ANNOUNCE_TIME = 3 -- target color shown, pads still safe
Config.MOVE_TIME = 6 -- time to reach a pad of the target color
Config.SINK_TIME = 3 -- wrong pads stay sunk in the lava
Config.ROUND_TIME = 75 -- a round ends after this long at most
Config.RESULTS_TIME = 12 -- winner screen before the next lobby

-- Scoring.
Config.SURVIVAL_POINTS = 10 -- surviving one color call
Config.STAR_POINTS = 5 -- collecting one bonus star
Config.MAX_STARS_PER_CALL = 3
Config.STAR_TOUCH_COOLDOWN = 1 -- seconds per player per star
Config.STAR_REACH = 12 -- max studs between player and star for a valid collect

-- Elimination.
Config.FALL_KILL_Y = -6 -- below this height a player is out, lava or not

return Config
