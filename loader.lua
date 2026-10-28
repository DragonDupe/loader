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

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

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

-- UI
local parent
if gethui then
    parent = gethui()
else
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    parent = okCore and core or Players.LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "KeySystem"
gui.ResetOnSpawn = false
gui.Parent = parent

-- Main frame
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(350, 340)
frame.Position = UDim2.new(0.5, -175, 0.5, -170)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.Active = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- DRAG SYSTEM - COMPLETELY REWRITTEN
local dragging = false
local dragConnection
local startMousePos
local startFramePos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        startMousePos = input.Position
        startFramePos = frame.Position
        
        -- Kill old connection if exists
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
        
        -- Create new connection for smooth dragging
        dragConnection = UserInputService.InputChanged:Connect(function(newInput)
            if dragging and (newInput.UserInputType == Enum.UserInputType.MouseMovement or 
               newInput.UserInputType == Enum.UserInputType.Touch) then
                local delta = newInput.Position - startMousePos
                local newX = startFramePos.X.Offset + delta.X
                local newY = startFramePos.Y.Offset + delta.Y
                
                -- Clamp to screen bounds (allow some off-screen)
                newX = math.clamp(newX, -frame.AbsoluteSize.X + 50, gui.AbsoluteSize.X - 50)
                newY = math.clamp(newY, -frame.AbsoluteSize.Y + 50, gui.AbsoluteSize.Y - 50)
                
                frame.Position = UDim2.new(
                    startFramePos.X.Scale,
                    newX,
                    startFramePos.Y.Scale,
                    newY
                )
            end
        end)
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
    end
end)

-- Close button - RED COLOR, MOVED TO TOP RIGHT CORNER
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
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

-- User info frame - MOVED DOWN TO AVOID X BUTTON
local userFrame = Instance.new("Frame", frame)
userFrame.Size = UDim2.new(1, -60, 0, 50)
userFrame.Position = UDim2.fromOffset(15, 10)
userFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Instance.new("UICorner", userFrame).CornerRadius = UDim.new(0, 8)

-- Profile picture
local player = Players.LocalPlayer
local profileFrame = Instance.new("Frame", userFrame)
profileFrame.Size = UDim2.fromOffset(36, 36)
profileFrame.Position = UDim2.fromOffset(7, 7)
profileFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(1, 0)

local profileImage = Instance.new("ImageLabel", profileFrame)
profileImage.Size = UDim2.new(1, -4, 1, -4)
profileImage.Position = UDim2.fromOffset(2, 2)
profileImage.BackgroundTransparency = 1
Instance.new("UICorner", profileImage).CornerRadius = UDim.new(1, 0)

-- Load profile picture
local function loadProfilePicture()
    pcall(function()
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size48x48
        local userId = player.UserId
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then
            profileImage.Image = content
        end
    end)
end
task.spawn(loadProfilePicture)

-- Welcome text
local welcomeText = Instance.new("TextLabel", userFrame)
welcomeText.Size = UDim2.new(1, -60, 0, 50)
welcomeText.Position = UDim2.fromOffset(50, 0)
welcomeText.BackgroundTransparency = 1
welcomeText.Text = "Welcome " .. player.Name
welcomeText.TextColor3 = Color3.new(1, 1, 1)
welcomeText.Font = Enum.Font.GothamBold
welcomeText.TextSize = 16
welcomeText.TextXAlignment = Enum.TextXAlignment.Left

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.fromOffset(0, 65)
title.BackgroundTransparency = 1
title.Text = TITLE
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

-- Key input box
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -30, 0, 36)
box.Position = UDim2.fromOffset(15, 100)
box.PlaceholderText = "Enter your key..."
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.ClearTextOnFocus = false
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

-- Check key button
local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -30, 0, 36)
btn.Position = UDim2.fromOffset(15, 145)
btn.Text = "Check Key"
btn.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

btn.MouseEnter:Connect(function()
    btn.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
end)

btn.MouseLeave:Connect(function()
    btn.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
end)

-- Copy get key link button
local copyBtn = Instance.new("TextButton", frame)
copyBtn.Size = UDim2.new(1, -30, 0, 32)
copyBtn.Position = UDim2.fromOffset(15, 190)
copyBtn.Text = "Copy Get Key Link"
copyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
copyBtn.TextColor3 = Color3.new(1, 1, 1)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

copyBtn.MouseEnter:Connect(function()
    copyBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
end)

copyBtn.MouseLeave:Connect(function()
    copyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
end)

-- Copy YouTube link button
local ytBtn = Instance.new("TextButton", frame)
ytBtn.Size = UDim2.new(1, -30, 0, 32)
ytBtn.Position = UDim2.fromOffset(15, 230)
ytBtn.Text = "Copy YouTube Link"
ytBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
ytBtn.TextColor3 = Color3.new(1, 1, 1)
ytBtn.Font = Enum.Font.GothamBold
ytBtn.TextSize = 13
Instance.new("UICorner", ytBtn).CornerRadius = UDim.new(0, 6)

ytBtn.MouseEnter:Connect(function()
    ytBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
end)

ytBtn.MouseLeave:Connect(function()
    ytBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
end)

-- Status label
local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 60)
status.Position = UDim2.fromOffset(10, 270)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 90, 90)
status.Font = Enum.Font.GothamBold
status.TextSize = 13
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
            return
        end
    end
    box.Text = GET_KEY_LINK
    setStatus("Copy link from box, then clear it before entering key.", false)
end)

ytBtn.MouseButton1Click:Connect(function()
    local copy = setclipboard or toclipboard
    if copy then
        local okCopy = pcall(copy, YOUTUBE_LINK)
        if okCopy then
            setStatus("YouTube link copied!", true)
            return
        end
    end
    box.Text = YOUTUBE_LINK
    setStatus("Copy YouTube link from box.", false)
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
