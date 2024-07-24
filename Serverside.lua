local Players = game:GetService("Players")
local physicsService = game:GetService("PhysicsService")

local RepStorage = game:GetService("ReplicatedStorage")
local Events = RepStorage:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")

local LastJoiners = {}

local FirstJoiner = Instance.new("ObjectValue")
FirstJoiner.Parent = game:GetService("Workspace"):WaitForChild("ServerConfiguration")
FirstJoiner.Name = "FirstJoiner"

local function NewChar(Char :Model)
	for _,part in pairs(Char:GetChildren()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Player"
		end
	end
end

local function PlayerJoined(plr :Player)
	LastJoiners[#LastJoiners+1] = plr
	
	FirstJoiner.Value = LastJoiners[1]
	
	if plr.Character then NewChar(plr.Character) end
	
	plr.CharacterAdded:Connect(function(char)
		NewChar(char)
	end)
end

local function PlayerRemoved(plr :Player)
	if table.find(LastJoiners,plr) then
		table.remove(LastJoiners,table.find(LastJoiners,plr))
		
		FirstJoiner.Value = LastJoiners[1]
	end
end

Players.PlayerAdded:Connect(PlayerJoined)
Players.PlayerRemoving:Connect(PlayerRemoved)

RemoteEvents:WaitForChild("SyncWater").OnServerEvent:Connect(function()
	RemoteEvents.SyncWater:FireAllClients()
end)
