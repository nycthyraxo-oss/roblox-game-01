--!strict
-- Rainbow Rush: builds the whole arena at runtime from parts. Nothing is
-- hand-placed in Studio: the map is code, so the place file stays small and
-- the arena is identical on every server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

export type Pad = {
	Part: Part,
	ColorName: string,
	Color: Color3,
	GridX: number,
	GridZ: number,
	HomeCFrame: CFrame,
	Sunk: boolean,
}

export type GameMap = {
	Pads: { Pad },
	Lava: Part,
	SpawnLocation: SpawnLocation,
	PodiumSpots: { CFrame },
	StarsFolder: Folder,
}

local MapBuilder = {}

local function makePart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.Parent = parent
	return part
end

local function buildLavaSea(mapFolder: Folder): Part
	-- A glowing sea that kills anyone who touches it. It sits below the pads
	-- so a missed jump is always fatal, never a soft landing.
	local lava = makePart(
		"Lava",
		Vector3.new(Config.LAVA_SIZE, 2, Config.LAVA_SIZE),
		CFrame.new(0, Config.LAVA_Y - 1, 0),
		Color3.fromRGB(255, 80, 20),
		Enum.Material.Neon,
		mapFolder
	)
	lava.CanCollide = true
	return lava
end

local function buildPadGrid(mapFolder: Folder): { Pad }
	local padsFolder = Instance.new("Folder")
	padsFolder.Name = "Pads"
	padsFolder.Parent = mapFolder

	-- Every color appears at least four times so no call is unwinnable.
	local bag: { string } = {}
	for _, colorInfo in Config.COLORS do
		for _ = 1, 4 do
			table.insert(bag, colorInfo.Name)
		end
	end
	table.insert(bag, Config.COLORS[math.random(1, #Config.COLORS)].Name)

	-- Shuffle the bag so the grid is different every server.
	for i = #bag, 2, -1 do
		local j = math.random(1, i)
		bag[i], bag[j] = bag[j], bag[i]
	end

	local colorByName: { [string]: Color3 } = {}
	for _, colorInfo in Config.COLORS do
		colorByName[colorInfo.Name] = colorInfo.Color
	end

	local pads: { Pad } = {}
	local index = 1
	local halfSpan = (Config.GRID_SIZE - 1) * Config.PAD_GAP / 2
	for gx = 1, Config.GRID_SIZE do
		for gz = 1, Config.GRID_SIZE do
			local colorName = bag[index]
			index += 1
			local x = (gx - 1) * Config.PAD_GAP - halfSpan
			local z = (gz - 1) * Config.PAD_GAP - halfSpan
			local cframe = CFrame.new(x, Config.PAD_TOP_Y - Config.PAD_HEIGHT / 2, z)
			local part = makePart(
				"Pad_" .. colorName .. "_" .. tostring(gx) .. "_" .. tostring(gz),
				Vector3.new(Config.PAD_SIZE, Config.PAD_HEIGHT, Config.PAD_SIZE),
				cframe,
				colorByName[colorName],
				Enum.Material.Neon,
				padsFolder
			)
			table.insert(pads, {
				Part = part,
				ColorName = colorName,
				Color = colorByName[colorName],
				GridX = gx,
				GridZ = gz,
				HomeCFrame = cframe,
				Sunk = false,
			})
		end
	end
	return pads
end

local function buildLobby(mapFolder: Folder): SpawnLocation
	local lobby = makePart(
		"Lobby",
		Config.LOBBY_SIZE,
		CFrame.new(Config.LOBBY_CENTER.X, -1, Config.LOBBY_CENTER.Z),
		Color3.fromRGB(235, 235, 245),
		Enum.Material.SmoothPlastic,
		mapFolder
	)
	lobby.TopSurface = Enum.SurfaceType.Smooth

	-- The spawn point every player starts on.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(Config.LOBBY_CENTER.X, 0.5, Config.LOBBY_CENTER.Z)
	spawn.Color = Color3.fromRGB(120, 220, 130)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = mapFolder

	-- A welcome sign at the lobby's far edge, facing the players.
	local signPos = Vector3.new(0, 6, Config.LOBBY_CENTER.Z - Config.LOBBY_SIZE.Z / 2 + 1)
	local board = makePart(
		"WelcomeSign",
		Vector3.new(30, 9, 1),
		CFrame.lookAt(signPos, Vector3.new(0, 4, Config.LOBBY_CENTER.Z)),
		Color3.fromRGB(45, 45, 70),
		Enum.Material.SmoothPlastic,
		mapFolder
	)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = board
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.55)
	title.BackgroundTransparency = 1
	title.Text = "RAINBOW RUSH"
	title.TextColor3 = Color3.fromRGB(255, 235, 59)
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.Parent = surfaceGui
	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.fromScale(0, 0.55)
	subtitle.Size = UDim2.fromScale(1, 0.45)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Match the color - don't fall in the lava!"
	subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.SourceSansBold
	subtitle.Parent = surfaceGui

	return spawn
end

local function buildRainbowArch(mapFolder: Folder)
	-- Seven colored blocks arcing over the lobby walkway, one per rainbow color.
	local archColors = {
		Color3.fromRGB(255, 70, 70),
		Color3.fromRGB(255, 165, 0),
		Color3.fromRGB(255, 235, 59),
		Color3.fromRGB(80, 220, 100),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(120, 90, 230),
		Color3.fromRGB(190, 120, 255),
	}
	local center = Vector3.new(0, 0, Config.LOBBY_CENTER.Z + Config.LOBBY_SIZE.Z / 2 + 8)
	for i, color in archColors do
		local angle = math.pi * (i - 1) / (#archColors - 1) -- 0..pi
		local x = math.cos(angle) * 16
		local y = math.sin(angle) * 12 + 2
		local block = makePart(
			"Arch" .. tostring(i),
			Vector3.new(4, 4, 3),
			CFrame.new(center + Vector3.new(x, y, 0)) * CFrame.Angles(0, 0, angle - math.pi / 2),
			color,
			Enum.Material.Neon,
			mapFolder
		)
		block.CanCollide = false
	end
end

local function buildClouds(mapFolder: Folder)
	-- Soft white clouds drifting slowly across the sky.
	local spots = {
		Vector3.new(-45, 34, -30),
		Vector3.new(40, 38, -45),
		Vector3.new(55, 32, 25),
		Vector3.new(-55, 36, 35),
		Vector3.new(0, 42, -70),
	}
	for i, spot in spots do
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud" .. tostring(i)
		cloud.Shape = Enum.PartType.Ball
		cloud.Size = Vector3.new(18, 7, 12)
		cloud.CFrame = CFrame.new(spot)
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Material = Enum.Material.SmoothPlastic
		cloud.Transparency = 0.15
		cloud.Anchored = true
		cloud.CanCollide = false
		cloud.CanTouch = false
		cloud.CanQuery = false
		cloud.Parent = mapFolder
		local drift = TweenService:Create(
			cloud,
			TweenInfo.new(14 + i * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = spot + Vector3.new(14, 0, 0) }
		)
		drift:Play()
	end
end

local function buildCornerPillars(mapFolder: Folder)
	local corners = {
		Vector3.new(-36, 0, -36),
		Vector3.new(36, 0, -36),
		Vector3.new(-36, 0, 36),
		Vector3.new(36, 0, 36),
	}
	for i, corner in corners do
		makePart(
			"Pillar" .. tostring(i),
			Vector3.new(3, 16, 3),
			CFrame.new(corner.X, 8, corner.Z),
			Color3.fromRGB(200, 200, 215),
			Enum.Material.SmoothPlastic,
			mapFolder
		)
		local cap = Instance.new("Part")
		cap.Name = "PillarCap" .. tostring(i)
		cap.Shape = Enum.PartType.Ball
		cap.Size = Vector3.new(5, 5, 5)
		cap.CFrame = CFrame.new(corner.X, 17, corner.Z)
		cap.Color = Config.COLORS[((i - 1) % #Config.COLORS) + 1].Color
		cap.Material = Enum.Material.Neon
		cap.Anchored = true
		cap.CanCollide = false
		cap.Parent = mapFolder
	end
end

local function buildTrees(mapFolder: Folder)
	local spots = {
		Vector3.new(-48, 0, -52),
		Vector3.new(48, 0, -52),
		Vector3.new(-48, 0, 52),
		Vector3.new(48, 0, 52),
	}
	for i, spot in spots do
		makePart(
			"TreeTrunk" .. tostring(i),
			Vector3.new(2, 7, 2),
			CFrame.new(spot.X, 3.5, spot.Z),
			Color3.fromRGB(140, 95, 50),
			Enum.Material.SmoothPlastic,
			mapFolder
		)
		local leaves = Instance.new("Part")
		leaves.Name = "TreeTop" .. tostring(i)
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(9, 9, 9)
		leaves.CFrame = CFrame.new(spot.X, 10, spot.Z)
		leaves.Color = Color3.fromRGB(70, 200, 90)
		leaves.Material = Enum.Material.SmoothPlastic
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Parent = mapFolder
	end
end

local function buildPodium(mapFolder: Folder): { CFrame }
	-- Gold, silver and bronze steps for the top three players.
	local steps = {
		{ Name = "Podium1", Height = 7, Color = Color3.fromRGB(255, 215, 0), Label = "1", Offset = 0 },
		{ Name = "Podium2", Height = 5, Color = Color3.fromRGB(200, 200, 210), Label = "2", Offset = -7 },
		{ Name = "Podium3", Height = 3, Color = Color3.fromRGB(205, 130, 60), Label = "3", Offset = 7 },
	}
	local spots: { CFrame } = {}
	for _, step in steps do
		local pos = Config.PODIUM_CENTER + Vector3.new(step.Offset, 0, 0)
		local block = makePart(
			step.Name,
			Vector3.new(6, step.Height, 6),
			CFrame.new(pos.X, step.Height / 2, pos.Z),
			step.Color,
			Enum.Material.SmoothPlastic,
			mapFolder
		)
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.Parent = block
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = step.Label
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.Parent = surfaceGui
		-- Winners stand on top of their step, facing the arena.
		table.insert(spots, CFrame.lookAt(
			Vector3.new(pos.X, step.Height + 3, pos.Z),
			Vector3.new(pos.X, step.Height, 0)
		))
	end
	return spots
end

-- Builds the arena once at server start and hands back every handle the
-- round and pad services need.
function MapBuilder.buildMap(): GameMap
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "RainbowRushMap"
	mapFolder.Parent = Workspace

	local lava = buildLavaSea(mapFolder)
	local pads = buildPadGrid(mapFolder)
	local spawn = buildLobby(mapFolder)
	buildRainbowArch(mapFolder)
	buildClouds(mapFolder)
	buildCornerPillars(mapFolder)
	buildTrees(mapFolder)
	local podiumSpots = buildPodium(mapFolder)

	local starsFolder = Instance.new("Folder")
	starsFolder.Name = "Stars"
	starsFolder.Parent = mapFolder

	return {
		Pads = pads,
		Lava = lava,
		SpawnLocation = spawn,
		PodiumSpots = podiumSpots,
		StarsFolder = starsFolder,
	}
end

return MapBuilder
