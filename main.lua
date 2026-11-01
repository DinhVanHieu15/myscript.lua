-- ====================================================================
-- AUTO FARM & WORKOUT SCRIPT (ROBLOX STUDIO - CLIENT LOCALSCRIPT)
-- Vị trí đặt: StarterPlayer -> StarterPlayerScripts (hoặc StarterGui)
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- --------------------------------------------------------------------
-- 1. CẤU HÌNH TỌA ĐỘ VÀ THIẾT LẬP
-- --------------------------------------------------------------------
local Settings = {
    AutoFarm = false,
    AutoWorkout = false,
    ThrowPowerMax = 20,       -- Lực ném tối đa
    BackpackCapacity = 20,    -- Giới hạn balo (ví dụ: 20)
    
    -- Tọa độ vị trí (thay thế bằng Vector3 thực tế của map bạn):
    PosOrangeLine = Vector3.new(0, 5, 50),     -- Vạch ném
    PosWorkout = Vector3.new(15, 5, -20),      -- Cột cày sức mạnh
    PosSellShop = Vector3.new(-30, 5, 10),     -- Quầy bán / Shop NPC
}

-- --------------------------------------------------------------------
-- 2. HỖ TRỢ XỬ LÝ NHÂN VẬT & TƯƠNG TÁC
-- --------------------------------------------------------------------

-- Kiểm tra nhân vật còn sống hay không
local function GetCharacterParts()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hum.Health > 0 and hrp then
        return char, hrp
    end
    return nil, nil
end

-- Dịch chuyển an toàn (triệt tiêu quán tính rơi)
local function TeleportTo(vectorPos)
    local _, hrp = GetCharacterParts()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(vectorPos + Vector3.new(0, 3, 0))
        task.wait(0.3)
    end
end

-- Hàm bấm chuột ảo vào tâm của Button UI an toàn (không bị lỗi :Fire())
local function ClickGuiButton(buttonInstance)
    if not buttonInstance or not buttonInstance:IsA("GuiButton") then return end
    local absPos = buttonInstance.AbsolutePosition
    local absSize = buttonInstance.AbsoluteSize
    local centerX = absPos.X + (absSize.X / 2)
    local centerY = absPos.Y + (absSize.Y / 2)

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    end)
end

-- Quét UI đọc số lượng hiện có trong Balo (Tìm nhãn kiểu "15/20")
local function GetCurrentPetCount()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return 0 end
    
    for _, item in ipairs(playerGui:GetDescendants()) do
        if item:IsA("TextLabel") and item.Visible and item.Text ~= "" then
            local current, total = string.match(item.Text, "(%d+)%s*/%s*(%d+)")
            if current and total then
                local num = tonumber(current)
                if num then return num end
            end
        end
    end
    return 0
end

-- Chống AFK (Treo máy quá 20 phút không bị Roblox ngắt kết nối)
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end)

-- --------------------------------------------------------------------
-- 3. CÁC HÀM GAMEPLAY LOGIC
-- --------------------------------------------------------------------

-- Trang bị Pet tốt nhất
local function EquipBestPets()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("GuiButton") and gui.Visible then
            if gui.Name == "BestEquip" or (gui:IsA("TextButton") and string.find(gui.Text, "Trang bị tốt nhất")) then
                ClickGuiButton(gui)
                break
            end
        end
    end
    task.wait(0.4)
end

-- Bán tất cả vật phẩm ở Shop
local function SellAll()
    TeleportTo(Settings.PosSellShop)
    task.wait(0.6)
    
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, btn in ipairs(playerGui:GetDescendants()) do
            if btn:IsA("GuiButton") and btn.Visible then
                if string.find(btn.Name, "Sell") or (btn:IsA("TextButton") and string.find(btn.Text, "Bán")) then
                    ClickGuiButton(btn)
                    break
                end
            end
        end
    end
    task.wait(0.8)
end

-- Thực hiện ném lực tối đa
local function ExecuteMaxThrow()
    -- Cách 1: Ưu tiên bắt RemoteEvent nếu có trong game
    local remotes = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    local throwEvent = remotes and (remotes:FindFirstChild("ThrowPower") or remotes:FindFirstChild("Throw"))
    
    if throwEvent and throwEvent:IsA("RemoteEvent") then
        throwEvent:FireServer(Settings.ThrowPowerMax)
    else
        -- Cách 2: Mô phỏng nhấp chuột giữa màn hình
        local viewportSize = Workspace.CurrentCamera.ViewportSize
        VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 1)
    end
end

-- Thu thập quái (spam click thu thập nhanh)
local function HandleCatching(isDuplicate)
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    if isDuplicate then
        for _ = 1, 10 do
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.04)
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            task.wait(0.04)
        end
    else
        task.wait(2.2)
    end
end

-- --------------------------------------------------------------------
-- 4. TẠO GIAO DIỆN (UI + KÉO THẢ MƯỢT MÀ)
-- --------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmHub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Icon tròn thu gọn
local ToggleIcon = Instance.new("ImageButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Size = UDim2.new(0, 48, 0, 48)
ToggleIcon.Position = UDim2.new(0.03, 0, 0.45, 0)
ToggleIcon.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
ToggleIcon.Image = "rbxassetid://6031280882" -- Icon Setting
ToggleIcon.Parent = ScreenGui

local UICornerIcon = Instance.new("UICorner")
UICornerIcon.CornerRadius = UDim.new(1, 0)
UICornerIcon.Parent = ToggleIcon

-- Kéo thả Icon không bị lỗi Deprecated
local isDragging = false
local dragStart, startPos

ToggleIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = ToggleIcon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleIcon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Menu cài đặt
local MainFrame = Instance.new("Frame")
MainFrame.Name = "SettingFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 210)
MainFrame.Position = UDim2.new(0.03, 60, 0.45, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UICornerFrame = Instance.new("UICorner")
UICornerFrame.CornerRadius = UDim.new(0, 10)
UICornerFrame.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.Text = "AUTO FARM HUB"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

-- Nút Auto Farm
local BtnFarm = Instance.new("TextButton")
BtnFarm.Size = UDim2.new(0.88, 0, 0, 36)
BtnFarm.Position = UDim2.new(0.06, 0, 0.22, 0)
BtnFarm.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
BtnFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnFarm.Font = Enum.Font.SourceSansBold
BtnFarm.TextSize = 14
BtnFarm.Text = "Auto Farm: TẮT"
BtnFarm.Parent = MainFrame
Instance.new("UICorner", BtnFarm).CornerRadius = UDim.new(0, 6)

-- Nút Auto Cột Sức Mạnh
local BtnWorkout = Instance.new("TextButton")
BtnWorkout.Size = UDim2.new(0.88, 0, 0, 36)
BtnWorkout.Position = UDim2.new(0.06, 0, 0.45, 0)
BtnWorkout.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
BtnWorkout.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnWorkout.Font = Enum.Font.SourceSansBold
BtnWorkout.TextSize = 14
BtnWorkout.Text = "Cột Sức Mạnh: TẮT"
BtnWorkout.Parent = MainFrame
Instance.new("UICorner", BtnWorkout).CornerRadius = UDim.new(0, 6)

-- Nút Bán Nhanh
local BtnQuickSell = Instance.new("TextButton")
BtnQuickSell.Size = UDim2.new(0.88, 0, 0, 36)
BtnQuickSell.Position = UDim2.new(0.06, 0, 0.68, 0)
BtnQuickSell.BackgroundColor3 = Color3.fromRGB(220, 140, 30)
BtnQuickSell.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnQuickSell.Font = Enum.Font.SourceSansBold
BtnQuickSell.TextSize = 14
BtnQuickSell.Text = "Bán Tất Cả Balo"
BtnQuickSell.Parent = MainFrame
Instance.new("UICorner", BtnQuickSell).CornerRadius = UDim.new(0, 6)

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- --------------------------------------------------------------------
-- 5. BẮT SỰ KIỆN NÚT BẤM
-- --------------------------------------------------------------------
BtnFarm.MouseButton1Click:Connect(function()
    Settings.AutoFarm = not Settings.AutoFarm
    if Settings.AutoFarm then
        Settings.AutoWorkout = false
        BtnWorkout.Text = "Cột Sức Mạnh: TẮT"
        BtnWorkout.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        
        BtnFarm.Text = "Auto Farm: BẬT"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(40, 170, 70)
    else
        BtnFarm.Text = "Auto Farm: TẮT"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

BtnWorkout.MouseButton1Click:Connect(function()
    Settings.AutoWorkout = not Settings.AutoWorkout
    if Settings.AutoWorkout then
        Settings.AutoFarm = false
        BtnFarm.Text = "Auto Farm: TẮT"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        
        BtnWorkout.Text = "Cột Sức Mạnh: BẬT"
        BtnWorkout.BackgroundColor3 = Color3.fromRGB(40, 170, 70)
    else
        BtnWorkout.Text = "Cột Sức Mạnh: TẮT"
        BtnWorkout.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    end
end)

BtnQuickSell.MouseButton1Click:Connect(function()
    SellAll()
end)

-- --------------------------------------------------------------------
-- 6. VÒNG LẶP CHÍNH (MAIN LOOP)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.2)
        local _, hrp = GetCharacterParts()

        if hrp then
            if Settings.AutoFarm then
                -- 1. Kiểm tra Balo
                local currentCount = GetCurrentPetCount()
                if currentCount >= Settings.BackpackCapacity then
                    SellAll()
                else
                    -- 2. Ra vạch ném
                    if (hrp.Position - Settings.PosOrangeLine).Magnitude > 6 then
                        TeleportTo(Settings.PosOrangeLine)
                        task.wait(0.4)
                    end
                    
                    -- 3. Ném lực tối đa
                    ExecuteMaxThrow()
                    task.wait(0.8)
                    
                    -- 4. Thu thập & kéo về
                    HandleCatching(true)
                    
                    -- 5. Trang bị tốt nhất
                    EquipBestPets()
                end
                
            elseif Settings.AutoWorkout then
                -- 1. Chỉ dịch chuyển nếu đang ở xa cột tập
                if (hrp.Position - Settings.PosWorkout).Magnitude > 6 then
                    TeleportTo(Settings.PosWorkout)
                    task.wait(0.4)
                end
                
                -- 2. Tương tác tập luyện
                local viewportSize = Workspace.CurrentCamera.ViewportSize
                VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 1)
                task.wait(0.3)
            end
        end
    end
end)
