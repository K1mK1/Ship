local UIS :UserInputService = game:GetService("UserInputService")
local Players :Players = game:GetService("Players")
local RunService :RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")
local Camera :Camera = game:GetService("Workspace"):WaitForChild("Camera")

local Events = RepStorage:WaitForChild("Events")

local OurPlayer = Players.LocalPlayer

local MovementKeys = {
	Forward = {["Keys"] = {Enum.KeyCode.W,Enum.KeyCode.Up}, ["State"] = false, ["FirstInput"] = nil};
	Back = {["Keys"] = {Enum.KeyCode.S,Enum.KeyCode.Down}, ["State"] = false, ["FirstInput"] = nil};
	Right = {["Keys"] = {Enum.KeyCode.D,Enum.KeyCode.Right}, ["State"] = false, ["FirstInput"] = nil};
	Left = {["Keys"] = {Enum.KeyCode.A,Enum.KeyCode.Left}, ["State"] = false, ["FirstInput"] = nil};
}

repeat task.wait(.25) until OurPlayer.Character
local CurrentCharacter = OurPlayer.Character
local MaxSpeed
local accelerationSpeed
local CurrentAlignPosition :AlignPosition

local MovementDirection

local LeftButton,RightButton = false,false

local SittingPart
local CenterPart

local MovingWithBoat = false
local MouseMove = false

local SeatConnection

local UpdateTick = tick()
local RotationUpdateTime = .1

UIS.WindowFocusReleased:Connect(function()
	MovementKeys.Forward.State = false
	MovementKeys.Back.State = false
	MovementKeys.Right.State = false
	MovementKeys.Left.State = false
	LeftButton,RightButton = false,false
	MovingWithBoat = false
	MouseMove = false
end)

local function CreateAlignPosition(parentObject)
	local NewAlign = Instance.new("AlignPosition")
	NewAlign.Parent = parentObject
	NewAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
	NewAlign.ApplyAtCenterOfMass = true
	NewAlign.MaxForce = parentObject.AssemblyMass *100
	NewAlign.MaxVelocity = 0
	NewAlign.Responsiveness = 5

	local NewRot = Instance.new("AlignOrientation")
	NewRot.Parent = parentObject
	NewRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
	NewRot.MaxTorque = parentObject.AssemblyMass *1000
	NewRot.MaxAngularVelocity = parentObject.Parent:FindFirstChild("Settings") and parentObject.Parent.Settings.RotationSpeed.Value /100 or .5
	NewRot.Responsiveness = 5
	NewRot.Enabled = false

	local NewAttachment = Instance.new("Attachment")
	NewAttachment.Parent = parentObject

	NewAlign.Position = parentObject.Position
	NewAlign.Attachment0 = NewAttachment

	NewRot.CFrame = parentObject.CFrame
	NewRot.Attachment0 = NewAttachment

	AlignPosition = NewAlign

	return NewAlign
end

local function getCameraLook()
	local cameraDirection = Camera.CFrame.LookVector
	local rootPosition = CenterPart.Position or CurrentCharacter.HumanoidRootPart

	local horizontalDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit

	local newPosition = rootPosition + horizontalDirection * 100
	newPosition = Vector3.new(newPosition.X, rootPosition.Y, newPosition.Z)

	return newPosition
end

local function getCenterPartLook(state)
	local CenterCFrame :CFrame = CFrame.new(CenterPart.Position) * CFrame.fromOrientation(0,math.rad(CenterPart.Orientation.Y),0)

	local Distance = state and 1000000 or -1000000

	return (CenterCFrame + CenterCFrame.LookVector*Distance).Position - Vector3.new(0,10,0)
end

RunService.RenderStepped:Connect(function()
	
	if tick() - UpdateTick > RotationUpdateTime and SittingPart and CurrentAlignPosition and CurrentCharacter then
		UpdateTick = tick()

		local RootPart = SittingPart.Parent.HandlePart

		local Ignore = SittingPart.Parent

		local ray = Ray.new(RootPart.CFrame.Position,Vector3.new(0,-50,0))

		local Hit, Position, Normal, Material = game:GetService("Workspace"):FindPartOnRay(ray,Ignore)

		if Hit and Material == Enum.Material.Water then
						
			if MovingWithBoat then
				
				local RotPos = getCameraLook()
				local ForwardPos = getCenterPartLook(true)
				local BackPos = getCenterPartLook(false)

				if MouseMove then
					SittingPart.Parent.HandlePart.AlignOrientation.CFrame = CFrame.new(SittingPart.Parent.HandlePart.Position,RotPos)
				end

				if MovementDirection == "Forward" then
					CurrentAlignPosition.Position = ForwardPos
				elseif MovementDirection == "Back" then
					CurrentAlignPosition.Position = BackPos
				end

				if MovementKeys.Left.State and not MovementKeys.Right.State and not MouseMove then
					SittingPart.Parent.HandlePart.AlignOrientation.CFrame = SittingPart.Parent.HandlePart.CFrame * CFrame.Angles(0,45,0)
				elseif not MovementKeys.Left.State and MovementKeys.Right.State and not MouseMove then
					SittingPart.Parent.HandlePart.AlignOrientation.CFrame = SittingPart.Parent.HandlePart.CFrame * CFrame.Angles(0,-45,0)
				end
			end

			if MouseMove then
				SittingPart.Parent.HandlePart.AlignOrientation.Enabled = true
			else
				SittingPart.Parent.HandlePart.AlignOrientation.Enabled = false
			end

			if (MovementKeys.Right.State or MovementKeys.Left.State) and not MouseMove then
				SittingPart.Parent.HandlePart.AlignOrientation.Enabled = true
			elseif not MouseMove then
				SittingPart.Parent.HandlePart.AlignOrientation.Enabled = false
			end

			if MovementKeys.Forward.State and not MovementKeys.Back.State then --hızlanıyo
				if not MovementDirection then
					MovementDirection = "Forward"

				elseif MovementDirection == "Forward" then
					CurrentAlignPosition.MaxVelocity = math.clamp(CurrentAlignPosition.MaxVelocity+accelerationSpeed,0,MaxSpeed)

				elseif MovementDirection == "Back" then
					CurrentAlignPosition.MaxVelocity = math.clamp(CurrentAlignPosition.MaxVelocity-accelerationSpeed,0,MaxSpeed)

					if CurrentAlignPosition.MaxVelocity == 0 then
						MovementDirection = nil
					end
				end

			elseif not MovementKeys.Forward.State and MovementKeys.Back.State then -- yavaşlıyo
				if not MovementDirection then
					MovementDirection = "Back"

				elseif MovementDirection == "Back" then
					CurrentAlignPosition.MaxVelocity = math.clamp(CurrentAlignPosition.MaxVelocity+accelerationSpeed,0,MaxSpeed)

				elseif MovementDirection == "Forward" then
					CurrentAlignPosition.MaxVelocity = math.clamp(CurrentAlignPosition.MaxVelocity-accelerationSpeed,0,MaxSpeed)

					if CurrentAlignPosition.MaxVelocity == 0 then
						MovementDirection = nil
					end
				end
			elseif not MovementKeys.Forward.State and not MovementKeys.Back.State then
				CurrentAlignPosition.MaxVelocity = math.clamp(CurrentAlignPosition.MaxVelocity-accelerationSpeed/2,0,MaxSpeed)
			end

		end
		
	end

end)

local function SetKeys(Input :InputObject, State)
	local GetForward = table.find(MovementKeys.Forward.Keys,Input.KeyCode)
	local GetBack = table.find(MovementKeys.Back.Keys,Input.KeyCode)
	local GetRight = table.find(MovementKeys.Right.Keys,Input.KeyCode)
	local GetLeft = table.find(MovementKeys.Left.Keys,Input.KeyCode)

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		LeftButton = State
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
		RightButton = State
	end

	if RightButton or LeftButton then
		MouseMove = true
	elseif not RightButton and not LeftButton then
		MouseMove = false
	end

	if GetForward or Input.UserInputType == Enum.UserInputType.MouseButton1 then
		if MovementKeys.Forward.FirstInput == Input.KeyCode or not MovementKeys.Forward.FirstInput then --İLERİ
			MovementKeys.Forward.State = State and true or false
			MovementKeys.Forward.FirstInput = State and Input.KeyCode or nil
		end
	elseif GetBack or (Input.UserInputType == Enum.UserInputType.MouseButton2 and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter) then

		if MovementKeys.Back.FirstInput == Input.KeyCode or not MovementKeys.Back.FirstInput then --GERİ
			MovementKeys.Back.State = State and true or false
			MovementKeys.Back.FirstInput = State and Input.KeyCode or nil
		end

	elseif GetRight then	
		if MovementKeys.Right.FirstInput == Input.KeyCode or not MovementKeys.Right.FirstInput then --SAĞ
			MovementKeys.Right.State = State and true or false
			MovementKeys.Right.FirstInput = State and Input.KeyCode or nil
		end
	elseif GetLeft then	
		if MovementKeys.Left.FirstInput == Input.KeyCode or not MovementKeys.Left.FirstInput then --SOL
			MovementKeys.Left.State = State and true or false
			MovementKeys.Left.FirstInput = State and Input.KeyCode or nil
		end
	end

	if MovementKeys.Forward.State or MovementKeys.Back.State or MovementKeys.Right.State or MovementKeys.Left.State and SittingPart then
		MovingWithBoat = true
	else
		MovingWithBoat = false
	end

end

local function InputBegan(Input :InputObject ,Process)
	SetKeys(Input,true)
end

local function InputEnded(Input :InputObject ,Process)
	SetKeys(Input,false)
end

UIS.InputBegan:Connect(InputBegan)
UIS.InputEnded:Connect(InputEnded)

local RearFunction
local LastSeat
local RearUpdateTick = tick()

local function SeatFunction()
	if not CurrentCharacter then return end
	local Humanoid = CurrentCharacter:WaitForChild("Humanoid")

	if SeatConnection then SeatConnection = nil end
	SeatConnection = Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		local SeatPart = Humanoid.SeatPart

		SittingPart = Humanoid.SeatPart
		CenterPart = SittingPart
		MovingWithBoat = SittingPart and MovingWithBoat or false

		if SittingPart and SittingPart:GetAttribute("SeatType") == "Ship" then
			if SittingPart.Parent.HandlePart:FindFirstChildWhichIsA("AlignPosition") then
				CurrentAlignPosition = SittingPart.Parent.HandlePart:FindFirstChildWhichIsA("AlignPosition")
			else
				local NewAlign = CreateAlignPosition(SittingPart.Parent.HandlePart)
				CurrentAlignPosition = NewAlign
			end

			LastSeat = SeatPart.Parent.HandlePart:FindFirstChildWhichIsA("AlignPosition") and SeatPart or nil

			MaxSpeed = SittingPart.Parent:FindFirstChild("Settings") and SittingPart.Parent.Settings.MaxSpeed.Value or 25
			accelerationSpeed = SittingPart.Parent:FindFirstChild("Settings") and SittingPart.Parent.Settings.AccelerationSpeed.Value or .25
		else
			if RearFunction then RearFunction:Disconnect() end
			RearFunction = RunService.RenderStepped:Connect(function()
				if tick() - RearUpdateTick > RotationUpdateTime then
					RearUpdateTick = tick()

					if not LastSeat or LastSeat:FindFirstChild("SeatWeld") or LastSeat.Parent.HandlePart.AlignPosition.MaxVelocity == 0 then
						RearFunction:Disconnect()
					else
						LastSeat.Parent.HandlePart.AlignPosition.MaxVelocity = math.clamp(LastSeat.Parent.HandlePart.AlignPosition.MaxVelocity-accelerationSpeed/2,0,MaxSpeed)
					end

				end

			end)

			CurrentAlignPosition = nil
		end
	end)

end

SeatFunction()

OurPlayer.CharacterAdded:Connect(function(char)
	CurrentCharacter = char
	SeatFunction()
end)
