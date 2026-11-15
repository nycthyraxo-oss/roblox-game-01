--!strict
-- Rainbow Rush: owns the pad grid's motion and the bonus stars. Pads sink
-- when their color is wrong; stars appear on the right color and pay points
-- when a player touches them. The server decides everything here: the client
-- only ever sees the result.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapBuilder = require(script.Parent.MapBuilder)

local SINK_DEPTH = 12

export type PadService = {
	Map: MapBuilder.GameMap,
	Stars: { Part },
	StarTweens: { [Part]: Tween },
	StarConnections: { RBXScriptConnection },
	LastCollect: { [Player]: number },
}

local PadService = {}

function PadService.new(gameMap: MapBuilder.GameMap): PadService
	return {
		Map = gameMap,
		Stars = {},
		StarTweens = {},
		StarConnections = {},
		LastCollect = {},
	}
end

-- All pads currently showing this color.
function PadService.padsOfColor(service: PadService, colorName: string): { MapBuilder.Pad }
	local found: { MapBuilder.Pad } = {}
	for _, pad in service.Map.Pads do
		if pad.ColorName == colorName then
			table.insert(found, pad)
		end
	end
	return found
end

-- Drops every pad whose color is NOT the target into the lava. Players
-- standing on one fall with it; CanCollide goes off at once so nobody can
-- ride a sinking pad down and back up.
function PadService.sinkWrongColorPads(service: PadService, targetColor: string)
	for _, pad in service.Map.Pads do
		if pad.ColorName ~= targetColor and not pad.Sunk then
			pad.Sunk = true
			pad.Part.CanCollide = false
			local down = pad.HomeCFrame - Vector3.new(0, SINK_DEPTH, 0)
			local tween = TweenService:Create(
				pad.Part,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = down }
			)
			tween:Play()
		end
	end
end

-- Lifts every sunk pad back to its home position and makes it solid again.
function PadService.raiseAllPads(service: PadService)
	for _, pad in service.Map.Pads do
		if pad.Sunk then
			pad.Sunk = false
			local tween = TweenService:Create(
				pad.Part,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ CFrame = pad.HomeCFrame }
			)
			tween:Play()
			task.spawn(function()
				tween.Completed:Wait()
				pad.Part.CanCollide = true
			end)
		end
	end
end

local function destroyStar(service: PadService, star: Part)
	local tween = service.StarTweens[star]
	if tween then
		tween:Cancel()
		service.StarTweens[star] = nil
	end
	local index = table.find(service.Stars, star)
	if index then
		table.remove(service.Stars, index)
	end
	star:Destroy()
end

-- Removes every star on the field (a call is over, or a round ended).
function PadService.clearStars(service: PadService)
	for _, connection in service.StarConnections do
		connection:Disconnect()
	end
	table.clear(service.StarConnections)
	for _, star in service.Stars do
		local tween = service.StarTweens[star]
		if tween then
			tween:Cancel()
		end
		star:Destroy()
	end
	table.clear(service.Stars)
	table.clear(service.StarTweens)
end

-- Spawns up to `count` bonus stars on pads of the target color. A star pays
-- points only when the collecting player is alive in this round, is close
-- enough to have really touched it, and is not spamming the same star.
function PadService.spawnStars(
	service: PadService,
	targetColor: string,
	count: number,
	isPlayerAlive: (Player) -> boolean,
	onCollected: (Player) -> ()
)
	PadService.clearStars(service)
	local targets = PadService.padsOfColor(service, targetColor)
	if #targets == 0 then
		return
	end
	-- Shuffle the target pads so the stars land somewhere new each call.
	for i = #targets, 2, -1 do
		local j = math.random(1, i)
		targets[i], targets[j] = targets[j], targets[i]
	end
	local toSpawn = math.min(count, #targets)
	for i = 1, toSpawn do
		local pad = targets[i]
		local star = Instance.new("Part")
		star.Name = "BonusStar"
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.new(2.5, 2.5, 2.5)
		star.CFrame = pad.HomeCFrame + Vector3.new(0, 3, 0)
		star.Color = Color3.fromRGB(255, 235, 59)
		star.Material = Enum.Material.Neon
		star.Anchored = true
		star.CanCollide = false
		star.Parent = service.Map.StarsFolder
		table.insert(service.Stars, star)
		local bob = TweenService:Create(
			star,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = star.Position + Vector3.new(0, 0.75, 0) }
		)
		bob:Play()
		service.StarTweens[star] = bob

		local connection: RBXScriptConnection
		connection = star.Touched:Connect(function(hit: BasePart)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			if not isPlayerAlive(player) then
				return
			end
			local now = os.clock()
			local last = service.LastCollect[player] or 0
			if now - last < Config.STAR_TOUCH_COOLDOWN then
				return
			end
			local character = player.Character
			if not character then
				return
			end
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				return
			end
			if (root.Position - star.Position).Magnitude > Config.STAR_REACH then
				return
			end
			service.LastCollect[player] = now
			connection:Disconnect()
			destroyStar(service, star)
			onCollected(player)
		end)
		table.insert(service.StarConnections, connection)
	end
end

return PadService
