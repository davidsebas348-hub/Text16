local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local HitboxSize = 6
local DistanceInFront = 2
local KillDuration = 2

-- ESTADOS
local KillEnabled = false
local ActiveKillPlayers = {}
local OriginalCFrames = {}
local OriginalSizes = {}
local TargetPlayer = nil

-- =====================
-- FUNCIONES AUXILIARES
-- =====================
local function HasKnife()
    return (LocalPlayer.Backpack:FindFirstChild("Knife") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife"))) ~= nil
end

local function EquipKnife()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local knife = LocalPlayer.Backpack:FindFirstChild("Knife") 
        or character:FindFirstChild("Knife")

    if knife then
        humanoid:EquipTool(knife)
        knife:Activate() -- Activa la tool sin simular click
    end
end

local function ShowMessage(text)
    local msg = Instance.new("TextLabel")
    msg.Parent = game.CoreGui
    msg.Size = UDim2.new(0, 300, 0, 50)
    msg.Position = UDim2.new(0.5, -150, 0.2, 0)
    msg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    msg.TextColor3 = Color3.fromRGB(255,0,0)
    msg.Text = text
    msg.Font = Enum.Font.SourceSansBold
    msg.TextSize = 20
    msg.TextScaled = true
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,10)
    corner.Parent = msg
    task.delay(2,function() msg:Destroy() end)
end

local function SaveOriginalState(player)
    if not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        OriginalCFrames[player] = root.CFrame
        OriginalSizes[player] = root.Size
    end
end

local function RestoreOriginalState(player)
    if not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if root and OriginalCFrames[player] and OriginalSizes[player] then
        root.CFrame = OriginalCFrames[player]
        root.Size = OriginalSizes[player]
    end
end

local function ApplyHitboxToPlayers(players)
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    local FrontCFrame = MyRoot.CFrame * CFrame.new(0,0,-DistanceInFront)
    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            root.CFrame = FrontCFrame
            root.Size = Vector3.new(HitboxSize,HitboxSize,HitboxSize)
            root.Transparency = 0.8
            root.BrickColor = BrickColor.new("Really red")
            root.Material = Enum.Material.Neon
            root.CanCollide = false
        end
    end
end

-- =====================
-- GUI
-- =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255,0,0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = "MURDER GUI"
Title.TextColor3 = Color3.fromRGB(255,0,0)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 24

-- Lista de jugadores
local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Parent = MainFrame
PlayerListFrame.Size = UDim2.new(1,-20,0,200)
PlayerListFrame.Position = UDim2.new(0,10,0,50)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.CanvasSize = UDim2.new(0,0,0,0)
PlayerListFrame.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = PlayerListFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0,5)

-- =====================
-- BOTONES 2x2
-- =====================
local function CreateButton(parent,text,xPos,yPos)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(0, 130,0,35)
    btn.Position = UDim2.new(0, 10 + xPos*140, 0, 270 + yPos*50)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50,0,0)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = btn
    return btn
end

local KillAllButton = CreateButton(MainFrame,"Kill All",0,0)
local KillSheriffButton = CreateButton(MainFrame,"Kill Sheriff",1,0)
local KillTargetButton = CreateButton(MainFrame,"Kill Target",0,1)
local KillRandomButton = CreateButton(MainFrame,"Kill Random",1,1)

-- =====================
-- LISTA DINÁMICA
-- =====================
local function UpdatePlayerList()
    for _,child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Parent = PlayerListFrame
            btn.Size = UDim2.new(1,0,0,30)
            btn.Text = plr.Name
            btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0,5)
            corner.Parent = btn
            btn.MouseButton1Click:Connect(function()
                TargetPlayer = plr
            end)
        end
    end
    PlayerListFrame.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y)
end
UpdatePlayerList()
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)

-- =====================
-- FUNCIONES DE KILL
-- =====================
local function StartKill(players)
    if not HasKnife() then
        ShowMessage("NO TIENES LA TOOL KNIFE O NO ERES MURDER")
        return
    end
    EquipKnife()
    ActiveKillPlayers = {}
    for _,plr in ipairs(players) do
        table.insert(ActiveKillPlayers,plr)
        SaveOriginalState(plr)
    end
    KillEnabled = true
    local startTime = tick()
    while tick() - startTime < KillDuration do
        ApplyHitboxToPlayers(ActiveKillPlayers)
        task.wait()
    end
    for _,plr in ipairs(ActiveKillPlayers) do RestoreOriginalState(plr) end
    ActiveKillPlayers = {}
    KillEnabled = false
end

-- Botones
KillAllButton.MouseButton1Click:Connect(function()
    local list = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list,plr) end
    end
    StartKill(list)
end)

KillSheriffButton.MouseButton1Click:Connect(function()
    local list = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun"))) then
            table.insert(list,plr)
        end
    end
    StartKill(list)
end)

KillTargetButton.MouseButton1Click:Connect(function()
    if TargetPlayer then
        StartKill({TargetPlayer})
        TargetPlayer = nil
    end
end)

KillRandomButton.MouseButton1Click:Connect(function()
    local list = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list,plr) end
    end
    if #list > 0 then
        local rand = list[math.random(1,#list)]
        StartKill({rand})
    end
end)

-- =====================
-- Loop global para mantener hitbox (opcional)
-- =====================
RunService.RenderStepped:Connect(function()
    if KillEnabled then
        return
    end
end)

-- =====================
-- BOTÓN MINIMIZAR (SOLO TÍTULO Y BOTÓN)
-- =====================
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Parent = MainFrame
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -35, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 20
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,5)
corner.Parent = MinimizeButton

local IsMinimized = false
local OriginalSize = MainFrame.Size

MinimizeButton.MouseButton1Click:Connect(function()
    if not IsMinimized then
        -- Minimizar: solo mostrar título y botón
        MainFrame.Size = UDim2.new(0, 300, 0, 40)
        for _,child in ipairs(MainFrame:GetChildren()) do
            if child ~= Title and child ~= MinimizeButton then
                child.Visible = false
            end
        end
        IsMinimized = true
    else
        -- Restaurar tamaño original
        MainFrame.Size = OriginalSize
        for _,child in ipairs(MainFrame:GetChildren()) do
            if child ~= MinimizeButton then
                child.Visible = true
            end
        end
        IsMinimized = false
    end
end)
