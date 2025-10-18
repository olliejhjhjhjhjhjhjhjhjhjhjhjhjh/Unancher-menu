-- Ire's Unanchor Menu (Full Auto Setup Version)
-- Place this in StarterGui

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- // Create RemoteEvent (if missing)
local remote = ReplicatedStorage:FindFirstChild("AnchorControlEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AnchorControlEvent"
	remote.Parent = ReplicatedStorage
end

-- // Create ServerScript (if missing)
local existingServer = ServerScriptService:FindFirstChild("AnchorControlServer")
if not existingServer then
	local serverScript = Instance.new("Script")
	serverScript.Name = "AnchorControlServer"
	serverScript.Source = [[
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local remote = ReplicatedStorage:WaitForChild("AnchorControlEvent")

		remote.OnServerEvent:Connect(function(player, parts, anchored)
			for _, p in pairs(parts) do
				if typeof(p) == "Instance" and p:IsA("BasePart") then
					p.Anchored = anchored
				end
			end
		end)
	]]
	serverScript.Parent = ServerScriptService
end

-- // GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "IresUnanchorMenu"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 350)
frame.Position = UDim2.new(0.05, 0, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

-- Header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -40, 0, 40)
header.Position = UDim2.new(0, 10, 0, 0)
header.Text = "Ire's Unanchor Menu"
header.TextColor3 = Color3.fromRGB(255, 220, 50)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextScaled = true
header.Parent = frame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 220, 50)
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = frame

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 220, 50)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Parent = frame

-- Button container
local holder = Instance.new("Frame")
holder.Size = UDim2.new(1, -20, 1, -60)
holder.Position = UDim2.new(0, 10, 0, 50)
holder.BackgroundTransparency = 1
holder.Parent = frame

local layout = Instance.new("UIListLayout", holder)
layout.Padding = UDim.new(0, 8)

-- Utility
local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
	btn.AutoButtonColor = true
	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 8)
	btn.Parent = holder
	return btn
end

-- Buttons
local selectToggle = createButton("Toggle Select Mode (OFF)")
local multiselectToggle = createButton("Multi Select (OFF)")
local unanchorBtn = createButton("Unanchor Selected")
local anchorBtn = createButton("Anchor Selected")
local unanchorAllBtn = createButton("Unanchor All")
local anchorAllBtn = createButton("Anchor All")
local modeToggle = createButton("Mode: Client")

-- // Logic
local selecting = false
local multiselect = false
local selectedParts = {}
local serverMode = false

-- Highlights
local function highlight(part, on)
	if not part then return end
	local existing = part:FindFirstChild("IreHighlight")
	if on then
		if not existing then
			local hl = Instance.new("Highlight")
			hl.Name = "IreHighlight"
			hl.FillColor = Color3.fromRGB(255, 220, 50)
			hl.FillTransparency = 0.6
			hl.OutlineTransparency = 0
			hl.OutlineColor = Color3.fromRGB(255, 255, 150)
			hl.Parent = part
		end
	else
		if existing then
			existing:Destroy()
		end
	end
end

local function clearHighlights()
	for _, part in pairs(selectedParts) do
		highlight(part, false)
	end
	selectedParts = {}
end

-- Button connections
selectToggle.MouseButton1Click:Connect(function()
	selecting = not selecting
	selectToggle.Text = "Toggle Select Mode (" .. (selecting and "ON" or "OFF") .. ")"
	if not selecting then clearHighlights() end
end)

multiselectToggle.MouseButton1Click:Connect(function()
	multiselect = not multiselect
	multiselectToggle.Text = "Multi Select (" .. (multiselect and "ON" or "OFF") .. ")"
end)

modeToggle.MouseButton1Click:Connect(function()
	serverMode = not serverMode
	modeToggle.Text = "Mode: " .. (serverMode and "Server" or "Client")
end)

-- Click detection
mouse.Button1Down:Connect(function()
	if not selecting then return end
	local target = mouse.Target
	if target and target:IsA("BasePart") then
		if table.find(selectedParts, target) then
			-- Deselect
			highlight(target, false)
			table.remove(selectedParts, table.find(selectedParts, target))
		else
			if not multiselect then clearHighlights() end
			table.insert(selectedParts, target)
			highlight(target, true)
		end
	end
end)

-- Anchor/Unanchor Functions
local function setAnchored(parts, anchored)
	for _, part in pairs(parts) do
		part.Anchored = anchored
	end
end

local function serverSetAnchored(parts, anchored)
	if remote then
		remote:FireServer(parts, anchored)
	end
end

unanchorBtn.MouseButton1Click:Connect(function()
	if #selectedParts == 0 then return end
	if serverMode then serverSetAnchored(selectedParts, false)
	else setAnchored(selectedParts, false) end
end)

anchorBtn.MouseButton1Click:Connect(function()
	if #selectedParts == 0 then return end
	if serverMode then serverSetAnchored(selectedParts, true)
	else setAnchored(selectedParts, true) end
end)

unanchorAllBtn.MouseButton1Click:Connect(function()
	local allParts = workspace:GetDescendants()
	if serverMode then serverSetAnchored(allParts, false)
	else
		for _, v in pairs(allParts) do
			if v:IsA("BasePart") then v.Anchored = false end
		end
	end
end)

anchorAllBtn.MouseButton1Click:Connect(function()
	local allParts = workspace:GetDescendants()
	if serverMode then serverSetAnchored(allParts, true)
	else
		for _, v in pairs(allParts) do
			if v:IsA("BasePart") then v.Anchored = true end
		end
	end
end)

-- Minimize / Close
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	for _, child in pairs(holder:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = not minimized
		end
	end
	frame.Size = minimized and UDim2.new(0, 300, 0, 60) or UDim2.new(0, 300, 0, 350)
end)

closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- Toggle Menu with M
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		gui.Enabled = not gui.Enabled
	end
end)
