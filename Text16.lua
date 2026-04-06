local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuración: "Sheriff" o "All"
--getgenv().TARGET = "Sheriff"

local function findKnife()
    local char = LocalPlayer.Character
    if not char then return nil end

    if char:FindFirstChild("Knife") then
        return char.Knife
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local knife = bp:FindFirstChild("Knife")
        if knife then
            return knife
        end
    end

    return nil
end

local function equipAndActivateKnife()
    local knife = findKnife()
    if not knife then return end

    local char = LocalPlayer.Character
    if not char then return end

    -- Desequipar otras tools
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool ~= knife then
            LocalPlayer.Character.Humanoid:UnequipTools()
        end
    end

    -- Equipar Knife
    LocalPlayer.Character.Humanoid:EquipTool(knife)
    task.wait(0.5) -- Espera a que la Knife esté equipada

    -- Simular activación de la herramienta (click)
    knife:Activate()

    -- Determinar targets
    local targets = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("RightLowerArm") then
            local role
            if plr.Character:FindFirstChild("Gun") or plr.Backpack:FindFirstChild("Gun") then
                role = "Sheriff"
            else
                role = "Innocent"
            end

            if getgenv().TARGET == "Sheriff" and role == "Sheriff" then
                table.insert(targets, plr)
            elseif getgenv().TARGET == "All" then
                table.insert(targets, plr)
            end
        end
    end

    -- Fire HandleTouched al mismo tiempo
    for _, plr in ipairs(targets) do
        if knife.Events and knife.Events:FindFirstChild("HandleTouched") then
            knife.Events.HandleTouched:FireServer(plr.Character.RightLowerArm)
        end
    end
end

equipAndActivateKnife()
