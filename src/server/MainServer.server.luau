--!strict
-- Rainbow Rush: the server entry point. It creates the remotes, builds the
-- arena, wires the services together and starts the round loop. Nothing
-- else runs on the server: every game rule lives in the service modules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapBuilder = require(script.Parent.MapBuilder)
local PadService = require(script.Parent.PadService)
local RoundService = require(script.Parent.RoundService)
local ScoreService = require(script.Parent.ScoreService)

-- RemoteEvents live in ReplicatedStorage so both sides can find them.
-- The client never sends gameplay data: all three remotes are server-to-
-- client only, which keeps every point and every elimination server-owned.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local roundRemote = Instance.new("RemoteEvent")
roundRemote.Name = "RoundUpdate"
roundRemote.Parent = remotes

local scoreRemote = Instance.new("RemoteEvent")
scoreRemote.Name = "ScoreUpdate"
scoreRemote.Parent = remotes

local resultsRemote = Instance.new("RemoteEvent")
resultsRemote.Name = "ResultsEvent"
resultsRemote.Parent = remotes

local gameMap = MapBuilder.buildMap()
local pads = PadService.new(gameMap)
local scores = ScoreService.new(scoreRemote)
local rounds = RoundService.new(gameMap, pads, scores, roundRemote, resultsRemote)

RoundService.start(rounds)

print("Rainbow Rush server started: arena built, round loop running.")
