--!strict
-- Rainbow Rush: the round state machine. One loop, one state at a time:
-- lobby -> color calls -> results -> lobby again. Every point, every
-- elimination and every phase change is decided here, on the server.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapBuilder = require(script.Parent.MapBuilder)
local PadService = require(script.Parent.PadService)
local ScoreService = require(script.Parent.ScoreService)

export type RoundService = {
	Map: MapBuilder.GameMap,
	Pads: PadService.PadService,
	Scores: ScoreService.ScoreService,
	RoundRemote: RemoteEvent,
	ResultsRemote: RemoteEvent,
	Phase: string,
	TargetColor: string,
	Alive: { [Player]: boolean },
	RoundStartScores: { [Player]: number },
	PadByPart: { [Part]: MapBuilder.Pad },
	Running: boolean,
}

local RoundService = {}

function RoundService.new(
	gameMap: MapBuilder.GameMap,
	pads: PadService.PadService,
	scores: ScoreService.ScoreService,
	roundRemote: RemoteEvent,
	resultsRemote: RemoteEvent
): RoundService
	local padByPart: { [Part]: MapBuilder.Pad } = {}
	for _, pad in gameMap.Pads do
		padByPart[pad.Part] = pad
	end
	local service: RoundService = {
		Map = gameMap,
		Pads = pads,
		Scores = scores,
		RoundRemote = roundRemote,
		ResultsRemote = resultsRemote,
		Phase = "lobby",
		TargetColor = "",
		Alive = {},
		RoundStartScores = {},
		PadByPart = padByPart,
		Running = true,
	}

	-- Lava kills anyone who touches it, but only while they are alive in a
	-- round. A touch is checked against the alive set, never trusted alone.
	gameMap.Lava.Touched:Connect(function(hit: BasePart)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and service.Alive[player] then
			RoundService.eliminatePlayer(service, player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		service.Alive[player] = nil
		service.RoundStartScores[player] = nil
	end)

	return service
end

-- How many players are still standing in this round.
local function countAlive(service: RoundService): number
	local count = 0
	for _, alive in service.Alive do
		if alive then
			count += 1
		end
	end
	return count
end

-- A player is out for this round: no more points, and their character falls.
-- They respawn in the lobby and wait for the next round.
function RoundService.eliminatePlayer(service: RoundService, player: Player)
	if not service.Alive[player] then
		return
	end
	service.Alive[player] = false
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
	service.RoundRemote:FireClient(player, "eliminated", "", 0)
end

-- Picks a target color that is not the one just called, so two calls in a
-- row never ask for the same color.
local function pickTargetColor(previous: string): string
	local options: { string } = {}
	for _, colorInfo in Config.COLORS do
		if colorInfo.Name ~= previous then
			table.insert(options, colorInfo.Name)
		end
	end
	return options[math.random(1, #options)]
end

local function teleportToLobby(service: RoundService, player: Player)
	local character = player.Character
	if not character then
		return
	end
	character:PivotTo(service.Map.SpawnLocation.CFrame + Vector3.new(0, 3, 0))
end

local function teleportToRandomPad(service: RoundService, player: Player)
	local character = player.Character
	if not character then
		return
	end
	local pad = service.Map.Pads[math.random(1, #service.Map.Pads)]
	character:PivotTo(pad.HomeCFrame + Vector3.new(0, 4.5, 0))
end

-- The pad directly under a player's feet, found by a short raycast down.
-- A player with no pad under them is over lava or between pads.
local function padUnderPlayer(service: RoundService, player: Player): MapBuilder.Pad?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local padParts: { Part } = {}
	for _, pad in service.Map.Pads do
		table.insert(padParts, pad.Part)
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = padParts
	params.FilterType = Enum.RaycastFilterType.Include
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -25, 0), params)
	if not hit or not hit.Instance then
		return nil
	end
	return service.PadByPart[hit.Instance :: Part]
end

-- Everyone still standing on a pad of the target color earns survival points.
local function awardSurvivalPoints(service: RoundService, targetColor: string)
	for player, alive in service.Alive do
		if alive then
			local pad = padUnderPlayer(service, player)
			if pad and pad.ColorName == targetColor then
				ScoreService.addPoints(service.Scores, player, Config.SURVIVAL_POINTS)
			end
		end
	end
end

-- A burst of colored confetti over the podium for the results screen.
local function celebrateWinners(service: RoundService)
	local anchor = Instance.new("Part")
	anchor.Name = "ConfettiAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(Config.PODIUM_CENTER + Vector3.new(0, 14, 0))
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Parent = Workspace
	local colors = {
		Color3.fromRGB(255, 70, 70),
		Color3.fromRGB(255, 235, 59),
		Color3.fromRGB(80, 220, 100),
		Color3.fromRGB(80, 160, 255),
	}
	for _, color in colors do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(color)
		emitter.Rate = 120
		emitter.Lifetime = NumberRange.new(1.5, 2.5)
		emitter.Speed = NumberRange.new(15, 30)
		emitter.SpreadAngle = Vector2.new(90, 90)
		emitter.Size = NumberSequence.new(0.7)
		emitter.Parent = anchor
	end
	Debris:AddItem(anchor, Config.RESULTS_TIME)
end

local function lobbyPhase(service: RoundService)
	service.Phase = "lobby"
	service.TargetColor = ""
	service.RoundRemote:FireAllClients("lobby", "", Config.LOBBY_TIME)
	for _, player in Players:GetPlayers() do
		teleportToLobby(service, player)
	end
	task.wait(Config.LOBBY_TIME)
end

local function playRound(service: RoundService)
	service.Phase = "playing"
	for _, player in Players:GetPlayers() do
		service.RoundStartScores[player] = ScoreService.getPoints(service.Scores, player)
		if player.Character then
			service.Alive[player] = true
			teleportToRandomPad(service, player)
		else
			service.Alive[player] = false
		end
	end
	service.RoundRemote:FireAllClients("start", "", 0)

	local roundEnd = os.clock() + Config.ROUND_TIME
	local previousColor = ""
	-- One player alone still plays the full round (stars and survival
	-- points); the round only stops early when nobody is left standing.
	while os.clock() < roundEnd and countAlive(service) >= 1 do
		local target = pickTargetColor(previousColor)
		previousColor = target
		service.TargetColor = target

		service.RoundRemote:FireAllClients("announce", target, Config.ANNOUNCE_TIME)
		PadService.spawnStars(
			service.Pads,
			target,
			Config.MAX_STARS_PER_CALL,
			function(player: Player): boolean
				return service.Alive[player] == true
			end,
			function(player: Player)
				ScoreService.addPoints(service.Scores, player, Config.STAR_POINTS)
			end
		)
		task.wait(Config.ANNOUNCE_TIME)

		service.RoundRemote:FireAllClients("move", target, Config.MOVE_TIME)
		task.wait(Config.MOVE_TIME)

		service.RoundRemote:FireAllClients("resolve", target, Config.SINK_TIME)
		PadService.sinkWrongColorPads(service.Pads, target)
		awardSurvivalPoints(service, target)
		task.wait(Config.SINK_TIME)

		PadService.raiseAllPads(service.Pads)
		PadService.clearStars(service.Pads)
	end
end

local function resultsPhase(service: RoundService)
	service.Phase = "results"
	PadService.clearStars(service.Pads)
	PadService.raiseAllPads(service.Pads)

	-- The round's winner gained the most points during this round; total
	-- points break a tie, then the name, so the result is deterministic.
	type Standing = { Name: string, Points: number, Gained: number }
	local standings: { Standing } = {}
	for player, startPoints in service.RoundStartScores do
		local gained = ScoreService.getPoints(service.Scores, player) - startPoints
		table.insert(standings, {
			Name = player.Name,
			Points = ScoreService.getPoints(service.Scores, player),
			Gained = gained,
		})
	end
	table.sort(standings, function(a: Standing, b: Standing): boolean
		if a.Gained ~= b.Gained then
			return a.Gained > b.Gained
		elseif a.Points ~= b.Points then
			return a.Points > b.Points
		else
			return a.Name < b.Name
		end
	end)

	local top: { ScoreService.ScoreEntry } = {}
	for i = 1, math.min(3, #standings) do
		table.insert(top, { Name = standings[i].Name, Points = standings[i].Gained })
	end
	local winnerName = if #standings > 0 then standings[1].Name else "Nobody"
	service.ResultsRemote:FireAllClients(winnerName, top)
	celebrateWinners(service)

	-- The top three stand on the podium while the results show.
	for i = 1, math.min(3, #standings) do
		local player = Players:FindFirstChild(standings[i].Name) :: Player?
		if player and player.Character then
			player.Character:PivotTo(service.Map.PodiumSpots[i])
		end
	end
	task.wait(Config.RESULTS_TIME)

	for _, player in Players:GetPlayers() do
		teleportToLobby(service, player)
	end
	service.Alive = {}
	service.RoundStartScores = {}
end

-- The endless loop: lobby, round, results. Started once by MainServer.
function RoundService.start(service: RoundService)
	task.spawn(function()
		-- A slow safety net: anyone who slips through a gap and falls below
		-- the arena is out, even if the lava never touched them.
		task.spawn(function()
			while service.Running do
				task.wait(0.5)
				for player, alive in service.Alive do
					if alive then
						local character = player.Character
						if character then
							local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
							if root and root.Position.Y < Config.FALL_KILL_Y then
								RoundService.eliminatePlayer(service, player)
							end
						end
					end
				end
			end
		end)

		while service.Running do
			lobbyPhase(service)
			if #Players:GetPlayers() == 0 then
				task.wait(2)
			else
				playRound(service)
				resultsPhase(service)
			end
		end
	end)
end

return RoundService
