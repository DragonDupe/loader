--====================================================--
--  LOADER  |  Only edit the CONFIG section
--  Game list is in Cloudflare Worker (worker.js)
--====================================================--

-- CONFIG
local WORKER       = "https://keyroblox.bonahabiburrrrahman.workers.dev/scriptroblox"
local GET_KEY_LINK = "https://www.robloxscript.zone.id/p/free-key.html"
local YOUTUBE_LINK = "https://www.youtube.com/dragondupe"
local TITLE        = "Enter Key"
local FILE         = "script_key.txt"
-- END CONFIG

-- DELETE SAVED KEY FILE BEFORE STARTING
if isfile and isfile(FILE) then
    pcall(delfile, FILE)
end

local MESSAGES = {
    badkey = "Invalid/expired key",
    nogame = "Game not supported yet",
    error  = "Connection failed or script error",
}

local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

-- Result: "ok" | "badkey" | "nogame" | "error"
local function run(key)
    local url = WORKER
        .. "?key=" .. HttpService:UrlEncode(key)
        .. "&place=" .. tostring(game.PlaceId)
        .. "&game=" .. tostring(game.GameId)

    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        if tostring(res):find("403") then
            return "badkey"
        end
        return "error"
    end

    if type(res) ~= "string" or #res == 0 then
        return "error"
    end
    if res == "Invalid key" then return "badkey" end
    if res == "Game not supported" then return "nogame" end
    if res == "Forbidden" or res == "Not found" then return "error" end

    local fn, err = loadstring(res)
    if not fn then
        return "error"
    end

    pcall(writefile, FILE, key)
    if getgenv then getgenv().ScriptKey = key end
    task.spawn(fn)
    return "ok"
end

-- PARENT
local parent
if gethui then
    parent = gethui()
else
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    parent = okCore and core or Players.LocalPlayer:WaitForChild("PlayerGui")
end

--====================================================--
--  NOTIFICATION (kanan bawah, gaya Mercury)
--====================================================--
local notifGui, notifHolder
local notifCount = 0

local function getHolder()
    if notifGui and notifGui.Parent then
        return notifHolder
    end

    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "KeySystemNotifs"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.DisplayOrder = 999
    notifGui.Parent = parent

    notifHolder = Instance.new("Frame")
    notifHolder.Name = "Holder"
    notifHolder.AnchorPoint = Vector2.new(1, 1)
    notifHolder.Position = UDim2.new(1, -15, 1, -15)
    notifHolder.Size = UDim2.new(0, 300, 1, -30)
    notifHolder.BackgroundTransparency = 1
    notifHolder.Parent = notifGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = notifHolder

    return notifHolder
end

local function notify(titleText, bodyText, duration, accent)
    duration = duration or 4
    accent = accent or Color3.fromRGB(70, 120, 255)

    local holder = getHolder()
    notifCount += 1

    -- wrapper (supaya layout tetap rapi saat card slide)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 66)
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder = notifCount
    wrapper.Parent = holder

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 1, 0)
    card.Position = UDim2.new(1, 20, 0, 0) -- mulai di luar layar (kanan)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    card.BorderSizePixel = 0
    card.Parent = wrapper
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(60, 60, 68)
    stroke.Thickness = 1

    -- aksen kiri
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -14)
    bar.Position = UDim2.fromOffset(7, 7)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.Parent = card
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(20, 8)
    t.Size = UDim2.new(1, -30, 0, 20)
    t.Text = titleText
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextTruncate = Enum.TextTruncate.AtEnd
    t.Parent = card

    local d = Instance.new("TextLabel")
    d.BackgroundTransparency = 1
    d.Position = UDim2.fromOffset(20, 28)
    d.Size = UDim2.new(1, -30, 0, 28)
    d.Text = bodyText
    d.TextColor3 = Color3.fromRGB(170, 170, 178)
    d.Font = Enum.Font.Gotham
    d.TextSize = 12
    d.TextWrapped = true
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.Parent = card

    -- progress bar waktu di bawah
    local timer = Instance.new("Frame")
    timer.Size = UDim2.new(1, -16, 0, 3)
    timer.Position = UDim2.new(0, 8, 1, -5)
    timer.BackgroundColor3 = accent
    timer.BorderSizePixel = 0
    timer.Parent = card
    Instance.new("UICorner", timer).CornerRadius = UDim.new(1, 0)

    -- animasi masuk
    TweenService:Create(
        card,
        TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }
    ):Play()

    TweenService:Create(
        timer,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 0, 3) }
    ):Play()

    -- animasi keluar
    task.delay(duration, function()
        local out = TweenService:Create(
            card,
            TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 20, 0, 0) }
        )
        out:Play()
        out.Completed:Wait()
        wrapper:Destroy()

        -- bersihkan holder kalau sudah kosong
        if notifGui and notifHolder then
            local left = 0
            for _, v in ipairs(notifHolder:GetChildren()) do
                if v:IsA("Frame") then left += 1 end
            end
            if left == 0 then
                notifGui:Destroy()
                notifGui, notifHolder = nil, nil
            end
        end
    end)
end

local GREEN = Color3.fromRGB(80, 200, 120)
local RED   = Color3.fromRGB(230, 70, 70)

--====================================================--
--  UI
--====================================================--
local gui = Instance.new("ScreenGui")
gui.Name = "KeySystem"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent

-- Main frame (lebih besar: 400 x 400), anchor di tengah
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(400, 400)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Active = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- DRAG SYSTEM (bisa digeser kemana aja, drag dari bagian frame yang kosong)
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

local dragConn = UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        local screen = gui.AbsoluteSize

        -- batasi supaya pusat frame tidak keluar dari layar
        local newX = math.clamp(startPos.X.Offset + delta.X, -screen.X * startPos.X.Scale, screen.X * (1 - startPos.X.Scale))
        local newY = math.clamp(startPos.Y.Offset + delta.Y, -screen.Y * startPos.Y.Scale, screen.Y * (1 - startPos.Y.Scale))

        frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    end
end)

local endConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

gui.Destroying:Connect(function()
    dragConn:Disconnect()
    endConn:Disconnect()
end)

-- Close button (merah, pojok kanan atas)
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 10)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- User info frame (lebar dikurangi supaya tidak nabrak tombol X)
-- kiri: 15px, kanan: sisakan 15 (gap) + 32 (X) + 10 (margin) = 57 -> pakai 62
local userFrame = Instance.new("Frame", frame)
userFrame.Size = UDim2.new(1, -77, 0, 54)
userFrame.Position = UDim2.fromOffset(15, 10)
userFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
userFrame.BorderSizePixel = 0
Instance.new("UICorner", userFrame).CornerRadius = UDim.new(0, 8)

-- Profile picture
local player = Players.LocalPlayer
local profileFrame = Instance.new("Frame", userFrame)
profileFrame.Size = UDim2.fromOffset(40, 40)
profileFrame.Position = UDim2.fromOffset(7, 7)
profileFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
profileFrame.BorderSizePixel = 0
Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(1, 0)

local profileImage = Instance.new("ImageLabel", profileFrame)
profileImage.Size = UDim2.new(1, -4, 1, -4)
profileImage.Position = UDim2.fromOffset(2, 2)
profileImage.BackgroundTransparency = 1
Instance.new("UICorner", profileImage).CornerRadius = UDim.new(1, 0)

local function loadProfilePicture()
    pcall(function()
        local content, isReady = Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size48x48
        )
        if isReady then
            profileImage.Image = content
        end
    end)
end
task.spawn(loadProfilePicture)

-- Welcome text (dipotong "..." kalau nama kepanjangan)
local welcomeText = Instance.new("TextLabel", userFrame)
welcomeText.Size = UDim2.new(1, -62, 1, 0)
welcomeText.Position = UDim2.fromOffset(55, 0)
welcomeText.BackgroundTransparency = 1
welcomeText.Text = "Welcome " .. player.Name
welcomeText.TextColor3 = Color3.new(1, 1, 1)
welcomeText.Font = Enum.Font.GothamBold
welcomeText.TextSize = 16
welcomeText.TextXAlignment = Enum.TextXAlignment.Left
welcomeText.TextTruncate = Enum.TextTruncate.AtEnd

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.fromOffset(0, 76)
title.BackgroundTransparency = 1
title.Text = TITLE
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

-- Key input box
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -30, 0, 40)
box.Position = UDim2.fromOffset(15, 114)
box.PlaceholderText = "Enter your key..."
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 15
box.ClearTextOnFocus = false
box.BorderSizePixel = 0
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

-- Check key button
local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -30, 0, 40)
btn.Position = UDim2.fromOffset(15, 164)
btn.Text = "Check Key"
btn.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.AutoButtonColor = false
btn.BorderSizePixel = 0
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

btn.MouseEnter:Connect(function()
    btn.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
end)
btn.MouseLeave:Connect(function()
    btn.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
end)

-- Copy get key link button
local copyBtn = Instance.new("TextButton", frame)
copyBtn.Size = UDim2.new(1, -30, 0, 36)
copyBtn.Position = UDim2.fromOffset(15, 214)
copyBtn.Text = "Copy Get Key Link"
copyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
copyBtn.TextColor3 = Color3.new(1, 1, 1)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 14
copyBtn.AutoButtonColor = false
copyBtn.BorderSizePixel = 0
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

copyBtn.MouseEnter:Connect(function()
    copyBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
end)
copyBtn.MouseLeave:Connect(function()
    copyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
end)

-- Copy YouTube link button
local ytBtn = Instance.new("TextButton", frame)
ytBtn.Size = UDim2.new(1, -30, 0, 36)
ytBtn.Position = UDim2.fromOffset(15, 258)
ytBtn.Text = "Copy YouTube Link"
ytBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
ytBtn.TextColor3 = Color3.new(1, 1, 1)
ytBtn.Font = Enum.Font.GothamBold
ytBtn.TextSize = 14
ytBtn.AutoButtonColor = false
ytBtn.BorderSizePixel = 0
Instance.new("UICorner", ytBtn).CornerRadius = UDim.new(0, 6)

ytBtn.MouseEnter:Connect(function()
    ytBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
end)
ytBtn.MouseLeave:Connect(function()
    ytBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
end)

-- Status label
local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 80)
status.Position = UDim2.fromOffset(10, 306)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 90, 90)
status.Font = Enum.Font.GothamBold
status.TextSize = 14
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center
status.TextYAlignment = Enum.TextYAlignment.Center

local function setStatus(text, good)
    status.Text = text
    if good then
        status.TextColor3 = Color3.fromRGB(120, 255, 140)
    else
        status.TextColor3 = Color3.fromRGB(255, 90, 90)
    end
end

copyBtn.MouseButton1Click:Connect(function()
    local copy = setclipboard or toclipboard
    if copy then
        local okCopy = pcall(copy, GET_KEY_LINK)
        if okCopy then
            setStatus("Link copied! Open in browser to get key.", true)
            notify("Get Key Link", "Link berhasil dicopy! Buka di browser untuk ambil key.", 4, GREEN)
            return
        end
    end
    box.Text = GET_KEY_LINK
    setStatus("Copy link from box, then clear it before entering key.", false)
    notify("Copy Gagal", "Executor tidak support clipboard. Copy manual dari kotak key.", 5, RED)
end)

ytBtn.MouseButton1Click:Connect(function()
    local copy = setclipboard or toclipboard
    if copy then
        local okCopy = pcall(copy, YOUTUBE_LINK)
        if okCopy then
            setStatus("YouTube link copied!", true)
            notify("YouTube Link", "Link YouTube berhasil dicopy!", 4, GREEN)
            return
        end
    end
    box.Text = YOUTUBE_LINK
    setStatus("Copy YouTube link from box.", false)
    notify("Copy Gagal", "Executor tidak support clipboard. Copy manual dari kotak key.", 5, RED)
end)

local busy = false
btn.MouseButton1Click:Connect(function()
    if busy then return end
    local input = box.Text:gsub("%s+", "")
    if input == "" then
        setStatus("Key not entered", false)
        return
    end
    busy = true
    status.TextColor3 = Color3.new(1, 1, 1)
    status.Text = "Checking..."
    local result = run(input)
    if result == "ok" then
        gui:Destroy()
    else
        setStatus(MESSAGES[result] or MESSAGES.error, false)
    end
    busy = false
end)
