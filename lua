local RepStorage :ReplicatedStorage = game:GetService("ReplicatedStorage")
local SyncWater :RemoteEvent = RepStorage:WaitForChild("Events"):WaitForChild("RemoteEvents"):WaitForChild("SyncWater")


local Terrain = game:GetService("Workspace"):WaitForChild("Terrain")

local WaterHeightCalculator = require(RepStorage:WaitForChild("ReplicatedModules"):WaitForChild("WaterHeightCalculator"))

local runService :RunService = game:GetService("RunService")
--
local calculatedShipsFolder = game:GetService("Workspace"):WaitForChild("CalculatedShips")
--

local function getAverageHeight(sentModel :Model)
	local AverageHeight = (sentModel.Port.Attachment.CFrame.Position.Y + sentModel.Starboard.Attachment.CFrame.Position.Y) / 2

	return AverageHeight
end

local function getPitch(sentModel)
	local bowPart = sentModel.SystemModel.Bow
	local sternPart = sentModel.SystemModel.Stern

	local bowHeight = WaterHeightCalculator.calcWaterHeightOffset(bowPart.Position.X,bowPart.Position.Z)
	local sternHeight = WaterHeightCalculator.calcWaterHeightOffset(sternPart.Position.X,sternPart.Position.Z)

	local Deg = math.deg(math.acos((Vector3.new(bowPart.Position.x,bowHeight,bowPart.Position.Z)-Vector3.new(sternPart.Position.x,sternHeight,sternPart.Position.Z)).Unit:Dot(Vector3.new(0,1,0)))) -90

	return Deg
end

local function getRoll(sentModel)
	local starboardPart = sentModel.SystemModel.Starboard
	local portPart = sentModel.SystemModel.Port

	local starboardHeight = WaterHeightCalculator.calcWaterHeightOffset(starboardPart.Position.X,starboardPart.Position.Z)
	local portHeight = WaterHeightCalculator.calcWaterHeightOffset(portPart.Position.X,portPart.Position.Z)

	local Deg = math.deg(math.acos((Vector3.new(starboardPart.Position.x,starboardHeight,starboardPart.Position.Z)-Vector3.new(portPart.Position.x,portHeight,portPart.Position.Z)).Unit:Dot(Vector3.new(0,1,0)))) -90

	return Deg
end



local function SetCFrames(weld :ManualWeld, Height, ship :Model)
	local pitch = getPitch(ship)
	local roll = getRoll(ship)
	local x,y,z = weld.C0:ToOrientation()
	weld.C0 = CFrame.new(0,-Height,0) * CFrame.fromOrientation(math.rad(pitch),math.rad(90),math.rad(roll))
	

end

task.wait(3)

if game:GetService("Workspace"):WaitForChild("ServerConfiguration"):WaitForChild("FirstJoiner").Value == game.Players.LocalPlayer then Terrain.WaterWaveSpeed = 20 end

local CDtick = tick()

runService.RenderStepped:Connect(function()

	if tick() - CDtick > .01 then CDtick = tick()

		for _,ship :Model in pairs(calculatedShipsFolder:GetChildren()) do
			
			local systemModel = ship.SystemModel

			for _,part in pairs(systemModel:GetChildren()) do
				if part:IsA("BasePart") and part:FindFirstChildWhichIsA("Attachment") then

					local WaterSize = WaterHeightCalculator.calcWaterHeightOffset(part.Position.X,part.Position.Z)

					part.Attachment.CFrame = CFrame.new(0,WaterSize,0)
				end
			end

			local Height = getAverageHeight(systemModel)

			if Height then			
				for _,object in pairs(ship.BoatModel:GetDescendants()) do
					if object:IsA("BasePart") and object:FindFirstChildWhichIsA("ManualWeld") then
						SetCFrames(object.Weld,Height,ship)
					end
				end
			end



		end

	end

end)
























