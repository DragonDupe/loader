--====================================================--
--  LOADER  |  yang perlu diedit hanya bagian KONFIGURASI
--  Daftar game ada di Worker Cloudflare (file worker.js)
--====================================================--

-- KONFIGURASI
local WORKER       = "https://keyroblox.bonahabiburrrrahman.workers.dev/scriptroblox"
local GET_KEY_LINK = "https://www.robloxscript.zone.id/p/free-key.html"
local TITLE        = "Masukkan Key"
local FILE         = "script_key.txt"
-- AKHIR KONFIGURASI

local MESSAGES = {
    badkey = "Key salah / kedaluwarsa",
    nogame = "Game ini belum didukung",
    error  = "Gagal terhubung atau script error",
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Hasil: "ok" | "badkey" | "nogame" | "error"
local function run(key)
    local url = WORKER
        .. "?key=" .. HttpService:UrlEncode(key)
        .. "&place=" .. tostring(game.PlaceId)
        .. "&game=" .. tostring(game.GameId)

    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        -- sebagian executor melempar error untuk kode 403 (key salah)
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
        warn("loadstring gagal:", err)
        return "error"
    end

    pcall(writefile, FILE, key)
    if getgenv then getgenv().ScriptKey = key end
    task.spawn(fn)
    return "ok"
end

-- Coba key tersimpan dulu
local startMsg = ""
if isfile and isfile(FILE) then
    local result = run(readfile(FILE))
    if result == "ok" then return end
    if result == "badkey" then pcall(delfile, FILE) end
    if result == "nogame" then startMsg = MESSAGES.nogame end
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

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(300, 224)
frame.Position = UDim2.new(0.5, -150, 0.5, -112)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = TITLE
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -30, 0, 36)
box.Position = UDim2.fromOffset(15, 46)
box.PlaceholderText = "Key hari ini..."
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.ClearTextOnFocus = false
Instance.new("UICorner", box)

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -30, 0, 36)
btn.Position = UDim2.fromOffset(15, 92)
btn.Text = "Cek Key"
btn.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
Instance.new("UICorner", btn)

local copyBtn = Instance.new("TextButton", frame)
copyBtn.Size = UDim2.new(1, -30, 0, 32)
copyBtn.Position = UDim2.fromOffset(15, 136)
copyBtn.Text = "Copy Link Get Key"
copyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
copyBtn.TextColor3 = Color3.new(1, 1, 1)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 44)
status.Position = UDim2.fromOffset(10, 174)
status.BackgroundTransparency = 1
status.Text = startMsg
status.TextColor3 = Color3.fromRGB(255, 90, 90)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true

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
            setStatus("Link disalin! Buka di browser untuk ambil key.", true)
            return
        end
    end
    -- cadangan kalau executor tidak mendukung clipboard
    box.Text = GET_KEY_LINK
    setStatus("Salin link dari kotak, lalu hapus isinya sebelum input key.", false)
end)

local busy = false
btn.MouseButton1Click:Connect(function()
    if busy then return end
    local input = box.Text:gsub("%s+", "")
    if input == "" then
        setStatus("Key belum diisi", false)
        return
    end
    busy = true
    status.TextColor3 = Color3.new(1, 1, 1)
    status.Text = "Mengecek..."
    local result = run(input)
    if result == "ok" then
        gui:Destroy()
    else
        setStatus(MESSAGES[result] or MESSAGES.error, false)
    end
    busy = false
end)
