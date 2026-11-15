--!strict
-- Rainbow Rush: the server's single source of truth for points. Scores live
-- here and nowhere else: the client only displays what this service sends.

local Players = game:GetService("Players")

export type ScoreEntry = {
	Name: string,
	Points: number,
}

export type ScoreService = {
	Scores: { [Player]: number },
	ScoreRemote: RemoteEvent,
}

local ScoreService = {}

function ScoreService.new(scoreRemote: RemoteEvent): ScoreService
	local service: ScoreService = {
		Scores = {},
		ScoreRemote = scoreRemote,
	}

	local function setupPlayer(player: Player)
		service.Scores[player] = 0
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		local points = Instance.new("IntValue")
		points.Name = "Points"
		points.Value = 0
		points.Parent = leaderstats
		leaderstats.Parent = player
	end

	local function removePlayer(player: Player)
		service.Scores[player] = nil
	end

	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(removePlayer)

	return service
end

local function broadcastScores(service: ScoreService)
	local snapshot: { [string]: number } = {}
	for player, points in service.Scores do
		snapshot[player.Name] = points
	end
	service.ScoreRemote:FireAllClients(snapshot)
end

-- Adds points for one player and tells every client. Server-only: no remote
-- ever lets a client add its own points.
function ScoreService.addPoints(service: ScoreService, player: Player, amount: number)
	local current = service.Scores[player]
	if current == nil then
		return
	end
	local next = current + amount
	service.Scores[player] = next
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local points = leaderstats:FindFirstChild("Points") :: IntValue?
		if points then
			points.Value = next
		end
	end
	broadcastScores(service)
end

function ScoreService.getPoints(service: ScoreService, player: Player): number
	return service.Scores[player] or 0
end

-- The top `count` players by points, best first.
function ScoreService.topPlayers(service: ScoreService, count: number): { ScoreEntry }
	local entries: { ScoreEntry } = {}
	for player, points in service.Scores do
		table.insert(entries, { Name = player.Name, Points = points })
	end
	table.sort(entries, function(a: ScoreEntry, b: ScoreEntry): boolean
		return a.Points > b.Points
	end)
	local top: { ScoreEntry } = {}
	for i = 1, math.min(count, #entries) do
		table.insert(top, entries[i])
	end
	return top
end

return ScoreService
