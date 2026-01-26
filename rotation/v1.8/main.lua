
local StartTime = os.time()
math.randomseed(os.time())

local Bot = getBot()

local StartPlaytime = Bot:getPlaytime()
AutoRest.Interval = AutoRest.Interval * 60
local WorldNuked = false
local WarpAttempt = 0

local SelectedBots = {}
local FireHoseId = 3066
local Mode3Tile = { 0, 1, 2 }
local Mode3Tile2 = { 0, -1, -2 }
local SeedId = BlockId + 1
local MagniId = 10158

local ProfitPack = 0
local ProfitSeed = 0

local IndexBot = 1
local IndexLast = 1

local HomeWorld = ""
local NoHomeWorld = false

local MagplantWorld = ""
local MagplantDoorId = ""

local FarmFilePath = ""
local PnbFilePath = ""

if BreakTile > 3 and AutoCreatePnbWorld.Enabled then
    BreakTile = 3
end

local TileMp = { -2, -1, 0, 1, 0 }
local CanTakeMp = false
local MagplantId = 5638
local LastMagplantTime = 0

local LevelingWorld, LevelingDoorId = "", ""
local MagniWorld, MagniDoorId = "", ""
local VialWorld, VialDoorId = "", ""

local MaladyFeature = Bot.auto_malady
MaladyFeature.auto_refresh = true
local MaladyList = {
    [1] = "Torn Punching Muscle",
    [2] = "Gem Cuts",
    [3] = "Chicken Feet",
    [4] = "Grumbleteeth",
    [5] = "Broken Heart",
    [6] = "Chaos Infection",
    [7] = "Moldy Guts",
    [8] = "Brainworms",
    [9] = "Lupus",
    [10] = "Ecto-Bones",
    [11] = "Fatty Liver"
}
local SurgStationId = 14666
local HasFire = false

local Emotes = {
    "/troll", "/lol", "/smile", "/cry", "/mad", "/wave",
    "/love", "/kiss", "/yes", "/no", "/wink", "/cheer", "/sad", "/fp"
}

local PositiveTileBreak = {}
local NegativeTileBreak = {}

local PnbWorld, PnbDoorId = "", ""
local CachedPnbOtherWorldData = nil -- Variabel untuk menyimpan data world
local PnbWorldIsNuked = false       -- Flag untuk mengecek apakah world nuked

local CreatedWorldLockedBy = ""
local PnbWorldCreated = false
local CreatedPnbWorld, CreatedPnbDoorId = "", ""
local LastPnbRotationTime = os.time()

function InitSpamFeature()
    local SpamList = {
        "Join us in the adventure now!",
        "Quick game, anyone up to play?",
        "A new event will start soon!",
        "Need help over here, please.",
        "I found a very rare item!",
        "Want to party up with me?",
        "I just got a new skin!",
        "Come and challenge me today!",
        "Is the raid team ready now?",
        "Level up your skills super quick.",
        "Ready for a dungeon run today?",
        "Let's trade some items together!",
        "I just found a secret location!",
        "Double XP bonus starts tomorrow.",
        "A boss fight is happening now!",
        "Claim your free rewards daily here.",
        "An epic raid is incoming soon!",
        "Upgrade your gear super fast now!",
        "Do you want to invite friends?",
        "Let's team up and play now!"
    }

    local SpamFeature = Bot.auto_spam
    SpamFeature.interval = 7
    SpamFeature.use_color = true
    SpamFeature.auto_interval = true
    SpamFeature.randomizer = true

    local SpamMessages = SpamFeature.messages
    SpamMessages:clear()
    for i = 1, #SpamList do
        SpamMessages:add(SpamList[i])
    end
end

function InitBotSettings()
    Bot.random_reconnect = true
    Bot.min_reconnect = 15
    Bot.max_reconnect = 30
    Bot.move_range = MoveRange
    Bot:setInterval(Action.move, MoveInterval)
    Bot.legit_mode = ShowAnimation
    Bot.ignore_gems = IgnoreGems
    Bot.object_collect_delay = 200
    Bot:setInterval(Action.collect, 0.100)
    Bot.collect_range = 3
    Bot.auto_reconnect = true

    PositiveTileBreak = GetPositiveBreakOffsets(BreakTile)
    NegativeTileBreak = GetNegativeBreakOffsets(BreakTile)
end

function GetSelectedBot()
    for _, botz in pairs(getBots()) do
        if botz.selected then
            table.insert(SelectedBots, botz)
        end
    end
end

function GetIndexBot()
    for i, botz in pairs(SelectedBots) do
        if botz.name:upper() == Bot.name:upper() then
            IndexBot = i
        end
        IndexLast = i
    end
end

function PrintLog(msg, category)
    local timestamp = os.date("%H:%M:%S")
    local worldName = Bot:getWorld().name or "EXIT"
    local tag = ""

    if category then
        tag = string.format("[%s] ", category:upper())
    end

    print(string.format("[%s] [%s] [%s] > %s%s", timestamp, worldName, Bot.name, tag, msg))
end

function FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then break end
    end
    return formatted
end

function GetUptime()
    local diff = os.difftime(os.time(), StartTime)
    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local minutes = math.floor((diff % 3600) / 60)
    local seconds = math.floor(diff % 60)
    return string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
end

function GetBotStatus(status)
    local statusList = {
        [BotStatus.offline] = "Offline",
        [BotStatus.online] = "Online",
        [BotStatus.account_banned] = "Banned",
        [BotStatus.location_banned] = "Location Ban",
        [BotStatus.server_overload] = "Overload",
        [BotStatus.too_many_login] = "Too Many Login",
        [BotStatus.maintenance] = "Maintenance",
        [BotStatus.version_update] = "Update",
        [BotStatus.server_busy] = "Server Busy",
        [BotStatus.error_connecting] = "Conn Error",
        [BotStatus.logon_fail] = "Logon Fail",
        [BotStatus.http_block] = "HTTP Blocked",
        [BotStatus.wrong_password] = "Wrong Password",
        [BotStatus.advanced_account_protection] = "AAP",
        [BotStatus.invalid_account] = "Invalid Acc",
        [BotStatus.guest_limit] = "Guest Limit",
        [BotStatus.changing_subserver] = "Changing Server",
        [BotStatus.captcha_requested] = "Captcha",
        [BotStatus.mod_entered] = "Mod Entered",
        [BotStatus.high_load] = "High Load"
    }
    return statusList[status] or "Unknown"
end

local MainMsgID = ""
local LastWebhookUpdate = 0
local WebhookDelay = 5

function CallMain(act)
    if Webhooks.Main == "" or Webhooks.Main == "https://discord.com/api/webhooks/" then return end
    local currentTime = os.time()
    if currentTime - LastWebhookUpdate < WebhookDelay and act ~= "Script Started!" and act ~= "Script Stopped!" then return end

    local webhook = Webhook.new(Webhooks.Main)
    webhook.embed1.use = true
    webhook.embed1.color = (Bot.status == BotStatus.online) and 65280 or 16711680
    webhook.embed1.description = "Updated <t:" .. os.time() .. ":R>"
    local statusEmoji = (Bot.status == BotStatus.online) and "🟢" or "🔴"
    local botTitle = string.format("%s %s (%d)", statusEmoji, Bot.name:upper(), Bot:getPing())
    local botInfo = string.format("Status: **%s**\nLevel: **%d**\nGems: **%s**\nWorld: ||**%s**||",
        GetBotStatus(Bot.status), Bot.level, FormatNumber(Bot.gem_count), Bot:getWorld().name or "EXIT")
    webhook.embed1:addField(botTitle, botInfo, true)
    webhook.embed1:addField("Action", act or "Idle", false)
    webhook.embed1:addField("Uptime", GetUptime(), false)
    webhook.embed1.footer.text = "RUBOT Rotation V1.8 | " .. os.date("%Y-%m-%d %H:%M:%S")

    if MainMsgID ~= "" then
        webhook:edit(MainMsgID)
    else
        webhook:send()
        MainMsgID = webhook.message_id
    end
    LastWebhookUpdate = currentTime
end

function CallGlobal()
    if Webhooks.Global.Url == "" or Webhooks.Global.Url == "https://discord.com/api/webhooks/" then return end
    local webhook = Webhook.new(Webhooks.Global.Url)
    webhook.embed1.use = true
    webhook.embed1.color = 3447003
    webhook.embed1.title = "Global Statistics"
    local totalBots = #getBots()
    local onlineCount = 0
    for _, b in pairs(getBots()) do if b.status == BotStatus.online then onlineCount = onlineCount + 1 end end
    webhook.embed1:addField("Bots", string.format("Online: %d / %d", onlineCount, totalBots), true)
    webhook.embed1:addField("Uptime", GetUptime(), true)
    webhook.embed1.footer.text = "RUBOT Global Dashboard"
    if Webhooks.Global.MessageId ~= "" then webhook:edit(Webhooks.Global.MessageId) else webhook:send() end
end

function CallProfit()
    if Webhooks.Profit.Url == "" or Webhooks.Profit.Url == "https://discord.com/api/webhooks/" then return end
    local webhook = Webhook.new(Webhooks.Profit.Url)
    webhook.embed1.use = true
    webhook.embed1.color = 16776960
    webhook.embed1.title = "Profit Report"
    webhook.embed1:addField("Recent Activity", string.format("**%s** just finished a cycle.", Bot.name), false)
    webhook.embed1:addField("Total Profit (Session)",
        string.format("Packs: **%d**\nSeeds: **%d**", ProfitPack, ProfitSeed), false)
    webhook.embed1.footer.text = "RUBOT Profit Tracker"
    if Webhooks.Profit.MessageId ~= "" then webhook:edit(Webhooks.Profit.MessageId) else webhook:send() end
end

function CallNotif(msg, isCritical)
    if Webhooks.Notif == "" or Webhooks.Notif == "https://discord.com/api/webhooks/" then return end
    local webhook = Webhook.new(Webhooks.Notif)
    webhook.content = isCritical and "@everyone" or ""
    webhook.embed1.use = true
    webhook.embed1.color = isCritical and 16711680 or 16776960
    webhook.embed1.description = string.format("**%s** » %s", Bot.name:upper(), msg)
    webhook.embed1.footer.text = os.date("%H:%M:%S")
    webhook:send()
end

function GetDynamicDelay(defaultDelay)
    if Bot:getPing() <= Delay.DynamicDelay.BasePing then
        return defaultDelay
    end
    return defaultDelay + ((Bot:getPing() - Delay.DynamicDelay.BasePing) * 1.6)
end

function FindItem(id)
    return Bot:getInventory():findItem(id)
end

function GscanFloat(id)
    return Bot:getWorld().growscan:getObjects()[id] or 0
end

function GscanBlock(id)
    return Bot:getWorld().growscan:getTiles()[id] or 0
end

function DistributeWorlds(worldList)
    local totalWorlds = #worldList
    local result = {}

    if IndexLast == 0 or totalWorlds == 0 then
        return result
    end

    local startIdx = math.floor((IndexBot - 1) * totalWorlds / IndexLast) + 1
    local endIdx = math.floor(IndexBot * totalWorlds / IndexLast)

    for i = startIdx, endIdx do
        table.insert(result, worldList[i])
    end

    PrintLog("Assigned giving tree worlds " .. startIdx .. "-" .. endIdx, "INFO")
    return result
end

function ParseWorld(worldString)
    local world, doorid = worldString:match("([^|:]+)[|:]?(.*)")
    if world then world = world:gsub("%s+", "") end
    if doorid then doorid = doorid:gsub("%s+", "") end
    return world or "", doorid or ""
end

function PickSingleWorld(worldList)
    local totalWorlds = #worldList
    if totalWorlds == 0 then
        return "", ""
    end
    local idx = ((IndexBot - 1) % totalWorlds) + 1
    local world, doorid = ParseWorld(worldList[idx])
    PrintLog("Assigned world: " .. world, "INFO")
    return world, doorid
end

local LastOfflineTime = 0

function IsRestHour()
    local currentHour = tonumber(os.date("%H"))
    for _, hour in ipairs(AutoRest.RestHours) do
        if currentHour == hour then
            return true
        end
    end
    return false
end

function ShouldRest()
    if not AutoRest.Enabled then return false end

    if IsRestHour() then
        return true, "Scheduled"
    end

    if (Bot:getPlaytime() - StartPlaytime) >= AutoRest.Interval then
        return true, "Interval"
    end

    return false
end

function GetProxyRotationLink()
    local botProxy = Bot:getProxy()
    local currentProxyStr = string.format("%s:%d", botProxy.ip, botProxy.port)

    for _, item in ipairs(MobileProxyConfig.ProxyList) do
        local ipPort, link = item:match("([^|]+)|(.+)")
        if ipPort and ipPort == currentProxyStr then
            return link
        end
    end
    return nil
end

function EnsureOnline()
    if Bot.status ~= BotStatus.online then
        Bot.custom_status = "Connecting..."
        CallMain("Connecting...")
        if LastOfflineTime == 0 then
            LastOfflineTime = os.time()
            CallNotif("Disconnected, Trying to Reconnect...", true)
        end

        PrintLog("Disconnected, Trying to Reconnect...", "CONN")

        -- // Mobile Proxy Rotation Logic
        if MobileProxyConfig.Enabled then
            local offlineDuration = os.time() - LastOfflineTime
            if offlineDuration >= MobileProxyConfig.OfflineThreshold then
                local rotationLink = GetProxyRotationLink()
                if rotationLink then
                    local botProxy = Bot:getProxy()
                    PrintLog(string.format("[PROXY] Threshold reached (%ds). Rotating IP for %s:%d...", offlineDuration,
                        botProxy.ip, botProxy.port))

                    -- Use curl for silent rotation
                    os.execute(string.format('curl -s "%s"', rotationLink))

                    PrintLog("[PROXY] Rotation triggered. Waiting cooldown...")
                    sleep(MobileProxyConfig.RotationCooldown * 1000)

                    -- Reset offline timer to avoid immediate re-rotation
                    LastOfflineTime = os.time()
                else
                    PrintLog("[PROXY] No rotation link found for current proxy IP/Port.")
                end
            end
        end

        while Bot.status ~= BotStatus.online or Bot:getPing() == 0 do
            sleep(1000)
            if Bot.status == BotStatus.account_banned then
                PrintLog("Got Banned!", "WARN")
                while Bot.status == BotStatus.account_banned do
                    for i = 1, 8 do
                        sleep(1000)
                    end
                end
                while Bot:isInTutorial() do
                    for i = 1, 5 do
                        sleep(1000)
                    end
                end
            end
        end

        PrintLog("Back Online!", "SUCCESS")
        CallNotif("Back Online!", false)
        CallMain("Restarting Task")
        LastOfflineTime = 0 -- Reset when back online
    end
end

function CheckNuked(variant, netid)
    if variant:get(0):getString() == "OnConsoleMessage" then
        if variant:get(1):getString():lower():find("inaccessible") then
            WorldNuked = true
        end
    end
end

function Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then return end

    WorldNuked = false
    WarpAttempt = 0

    addEvent(Event.variantlist, CheckNuked)

    while not Bot:isInWorld(world:upper()) and not WorldNuked do
        PrintLog("Warping to " .. world:upper(), "CONN")
        Bot.custom_status = "Warping to " .. world:upper()

        if Bot.status == BotStatus.online and Bot:getPing() == 0 then
            Bot:disconnect()
            sleep(1000)
        end

        EnsureOnline()

        if doorId ~= "" then
            Bot:warp(world, doorId)
            listenEvents(math.floor(Delay.Warp / 1000))
        else
            Bot:warp(world)
            listenEvents(math.floor(Delay.Warp / 1000))
        end

        if WarpAttempt >= MaxWarpAttempt then
            WarpAttempt = 0
            PrintLog("Hard Warp!, Bot Resting for 2 Minutes...", "WARN")

            if DisconnectWhenHardWarp then
                Bot:disconnect()
                Bot.auto_reconnect = false
                sleep(1000)
            end

            for i = 1, 120 do
                sleep(1000)
            end

            Bot.auto_reconnect = true
            Bot:connect()
            sleep(1000)
            EnsureOnline()
        end

        WarpAttempt = WarpAttempt + 1
    end

    if WorldNuked then
        PrintLog("World " .. world:upper() .. " is Nuked!", "WARN")
        CallNotif("World **" .. world:upper() .. "** is Nuked!", true)
        if world:upper() == PnbWorld:upper() and PnbInOtherWorld.Enabled then
            PnbWorldIsNuked = true
        end

        if world:upper() == CreatedPnbWorld and AutoCreatePnbWorld.Enabled then
            PnbWorldCreated = false
        end
    end

    if doorId ~= "" and getTile(Bot.x, Bot.y).fg == 6 and not WorldNuked then
        for i = 1, 5 do
            EnsureOnline()
            if getTile(Bot.x, Bot.y).fg == 6 then
                Bot:warp(world, doorId)
                sleep(4000)
            end
        end

        if getTile(Bot.x, Bot.y).fg == 6 then
            PrintLog("Cant Join Door Id At " .. world:upper(), "WARN")
            -- WorldNuked = true
            sleep(1000)
        end
    end

    sleep(100)
    removeEvent(Event.variantlist)
end

function Reconnect(world, doorId, x, y)
    local resting, reason = ShouldRest()
    if resting then
        for i = 1, 3 do
            if Bot:isInWorld() then
                Bot:leaveWorld()
                sleep(2000)
            end
        end

        if AutoRest.DisconnectOnRest then
            Bot.auto_reconnect = false
            Bot:disconnect()
            sleep(1000)
        end

        local restDuration = reason == "Scheduled" and "Until Finished" or (AutoRest.RestTime .. " Minutes")
        PrintLog("Resting (" .. reason .. "): " .. restDuration, "INFO")
        CallNotif("Resting (" .. reason .. "): " .. restDuration, false)
        CallMain("Resting (" .. reason .. ")")
        Bot.custom_status = "Resting (" .. reason .. ")"

        if reason == "Scheduled" then
            while IsRestHour() do
                for i = 1, 60 do
                    sleep(1000)
                end
            end
        else
            for i = 1, AutoRest.RestTime do
                for j = 1, 60 do
                    sleep(1000)
                end
            end
        end

        Bot.auto_reconnect = true
        PrintLog("Back from Resting!", "SUCCESS")
        CallNotif("Back from Resting!", false)
        CallMain("Restarting Task")
        StartPlaytime = Bot:getPlaytime()
    end

    EnsureOnline()

    if Bot:getWorld().name:upper() ~= world:upper() then
        PrintLog("Re-warping to " .. world:upper(), "CONN")
        Warps(world, doorId)
    end

    if Bot.status == BotStatus.online and Bot:getPing() > 0 then
        if Bot:getWorld().name:upper() == world:upper() then
            if not x or not y or (Bot.x == x and Bot.y == y) then
                return
            end
        end
    end

    if doorId ~= "" and getTile(Bot.x, Bot.y).fg == 6 then
        for i = 1, 5 do
            EnsureOnline()
            if getTile(Bot.x, Bot.y).fg ~= 6 then break end

            PrintLog("Attempting to enter door: " .. doorId, "CONN")
            Bot:warp(world, doorId)
            sleep(3000)
        end

        if getTile(Bot.x, Bot.y).fg == 6 then
            PrintLog("Cant Join Door Id At " .. world:upper(), "WARN")
            return
        end
    end

    if x and y then
        if Bot:isInWorld(world:upper()) then
            PrintLog(string.format("Returning to position X: %d, Y: %d", x, y))
            Bot:findPath(x, y)
            sleep(200)
        end
    end
end

-- function Reconnect(world, doorId, x, y)
--     if Bot.status == BotStatus.online or Bot:getPing() > 0 then return end
--     if x and y and Bot:isInTile(x, y) then return end

--     if Bot.status ~= BotStatus.online or Bot:getPing() == 0 then
--         EnsureOnline()

--         if Bot:getWorld().name ~= world:upper() then
--             Warps(world, doorId)
--         end

--         if doorId ~= "" and getTile(Bot.x, Bot.y).fg == 6 then
--             for i = 1, 5 do
--                 EnsureOnline()
--                 if getTile(Bot.x, Bot.y).fg == 6 then
--                     Bot:warp(world, doorId)
--                     sleep(3000)
--                 end
--             end

--             if getTile(Bot.x, Bot.y).fg == 6 then
--                 PrintLog("Cant Join Door Id At " .. world:upper())
--                 -- WorldNuked = true
--                 sleep(1000)
--             end
--         end
--     end

--     if x and y and not Bot:isInTile(x, y) and not WorldNuked then
--         if Bot:getWorld().name ~= world:upper() then
--             Warps(world, doorId)
--         end

--         if doorId ~= "" and getTile(Bot.x, Bot.y).fg == 6 then
--             for i = 1, 5 do
--                 EnsureOnline()
--                 if getTile(Bot.x, Bot.y).fg == 6 then
--                     Bot:warp(world, doorId)
--                     sleep(3000)
--                 end
--             end

--             if getTile(Bot.x, Bot.y).fg == 6 then
--                 PrintLog("Cant Join Door Id At " .. world:upper())
--                 -- WorldNuked = true
--                 sleep(1000)
--             end
--         end

--         if Bot:isInWorld() then
--             Bot:findPath(x, y)
--             sleep(100)
--         end
--     end
-- end

function TakeItem(world, doorId, itemId, amount)
    Bot.custom_status = "Taking " .. (getInfo(itemId).name or "Item")
    Bot.auto_collect = false
    Bot.object_collect_delay = 200

    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        PrintLog("Taking " .. amount .. " " .. getInfo(itemId).name)

        for _, obj in pairs(getObjects()) do
            if obj.id == itemId then
                if Bot:findPath(math.floor(obj.x / 32), math.floor(obj.y / 32)) then
                    Bot:collectObject(obj.oid, 4)
                    sleep(400)
                    Reconnect(world, doorId)
                end
                if FindItem(itemId) >= amount then
                    break
                end
            end
        end

        for i = 1, 5 do
            if FindItem(itemId) > amount then
                Bot:moveRight()
                sleep(150)
                Bot:setDirection(true)
                sleep(150)
                Bot:drop(itemId, FindItem(itemId) - amount)
                sleep(400)
                Reconnect(world, doorId)
            else
                break
            end
        end

        if FindItem(itemId) == 0 then
            PrintLog("Cannot Take " .. amount .. " " .. getInfo(itemId).name .. "!, Please Check it Manually!")
            sleep(3000)
        end
    end
end

function FindHomeWorld(variant, netid)
    if variant:get(0):getString() == "OnRequestWorldSelectMenu" and variant:get(1):getString():find("Your Worlds") then
        local text = variant:get(1):getString()
        local lines = {}
        for line in text:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        for i, value in ipairs(lines) do
            if i == 3 then
                local kalimat = lines[3]
                local nilai = kalimat:match("|([a-zA-Z0-9%s]+)|"):gsub("|", ""):gsub("%s", "")
                HomeWorld = nilai
                PrintLog("Detected Home World: " .. HomeWorld, "SUCCESS")
            end
        end
    end
end

function GetHomeWorld()
    HomeWorld = ""
    NoHomeWorld = false
    Bot.custom_status = "Scanning Home..."

    PrintLog("Getting Home World...", "CONN")

    for i = 1, 3 do
        if Bot:isInWorld() then
            Bot:leaveWorld()
            sleep(3000)
        end
    end

    addEvent(Event.variantlist, FindHomeWorld)

    for i = 1, 5 do
        if HomeWorld == "" and Bot:getWorld().name:upper() == "EXIT" then
            Bot:sendPacket(3, "action|world_button\nname|_16")
            listenEvents(3)
        end
    end

    if HomeWorld == "" then
        PrintLog("Doesn't Have Home World!", "WARN")
        NoHomeWorld = true
    end

    removeEvent(Event.variantlist)
end

function ValidateKey()
    local username = getUsername()
    local scriptCode = "rota"
    local baseUrl = "https://rubot-workers-api.fhrurhmn.workers.dev/key-validate"
    local apiKey = "rubajikonasdytnakwysadm"

    local bodyJson = string.format(
        '{"lucifer_username":"%s","script_code":"%s"}',
        username,
        scriptCode
    )

    local httpClient = HttpClient.new()
    httpClient.method = Method.post
    httpClient.url = baseUrl
    httpClient.headers["X-API-KEY"] = apiKey
    httpClient.content = bodyJson

    local result = httpClient:request()
    local responseBody = result.body
    local valid = responseBody:match('"valid"%s*:%s*(%w+)')
    local isValid = (valid == "true")

    return isValid
end

function GetHwid()
    local command = 'powershell -command "(Get-WmiObject Win32_ComputerSystemProduct).UUID"'
    local handle = io.popen(command)
    if not handle then
        return "UNKNOWN"
    end
    local result = handle:read("*a") or ""
    handle:close()
    result = result:gsub("%s+", "")
    return result ~= "" and result or "UNKNOWN"
end

function CallRubot(valid)
    local keyStatus = valid and "Key Valid" or "Key Invalid"
    local color = valid and 65280 or 16711680
    local hwid = GetHwid()

    local url =
    "https://discord.com/api/webhooks/1452839896694915213/FYFSCWy8-Lhquo7rafqLS9HCm5zR1YPvuLl2GgNDy-i9wBLR3HGb2K1Dq9n6eYPbdHlW"
    local mainEvent = Webhook.new(url)

    mainEvent.embed1.use = true
    mainEvent.embed1.title = "SCRIPT EXECUTED!"
    mainEvent.embed1.description =
        "Username: **" .. getUsername():upper() ..
        " [" .. keyStatus .. "]**\n" ..
        "Bots: **" .. #SelectedBots .. "**\n" ..
        "HWID: `" .. hwid .. "`\n" ..
        "<t:" .. os.time() .. ":R>"

    mainEvent.embed1.color = color
    mainEvent.embed1.footer.text =
        "Rotation V1.8 | " ..
        os.date("!%a %b %d, %Y at %I:%M %p", os.time() + 7 * 60 * 60)

    mainEvent:send()
end

function SaveTableToFile(path, dataTable)
    local file, err = io.open(path, "w")

    if not file then
        print("Failed to open file: " .. err)
        return false
    end

    local content = table.concat(dataTable, "\n")

    file:write(content)
    file:close()

    PrintLog("World List Has Been Saved On: " .. path)
    return true
end

function InitWorlds()
    -- Init Farms
    if FarmsConfig.UseTxtFile.Enabled then
        FarmFilePath = os.getenv("USERPROFILE") .. "\\Desktop\\RUBOT_ROTATION\\" .. FarmsConfig.UseTxtFile.FileName
        local content = read(FarmFilePath)
        if content == "" then
            PrintLog("Failed to Open Farms File, Make Sure You Save It On RUBOT_ROTATION Folder on Desktop!")
            Bot:stopScript()
            return
        end
    else
        FarmFilePath = os.getenv("USERPROFILE") .. "\\Desktop\\RUBOT_ROTATION\\farm_list.txt"
        if IndexBot == 1 then
            SaveTableToFile(FarmFilePath, FarmsConfig.FarmWorlds)
        end
    end

    -- Get Home World
    if PnbInHome.Enabled then
        GetHomeWorld()
    end

    -- Get Pnb Other World
    if PnbInOtherWorld.Enabled then
        if PnbInOtherWorld.UseTxtFile.Enabled then
            PnbFilePath = os.getenv("USERPROFILE") ..
                "\\Desktop\\RUBOT_ROTATION\\" .. PnbInOtherWorld.UseTxtFile.FileName
            local content = read(PnbFilePath)
            if content == "" then
                PrintLog("Failed to Open Pnb File, Make Sure You Save It On RUBOT_ROTATION Folder on Desktop!")
                Bot:stopScript()
                return
            end
        else
            PnbFilePath = os.getenv("USERPROFILE") .. "\\Desktop\\RUBOT_ROTATION\\pnb.txt"
            if IndexBot == 1 then
                SaveTableToFile(PnbFilePath, PnbInOtherWorld.PnbWorlds)
            end
        end
    end
end

function InitFolder()
    local desktopPath = os.getenv("USERPROFILE") .. "\\Desktop"
    local folderName = "RUBOT_ROTATION"
    local fullPath = desktopPath .. "\\" .. folderName

    local success = os.execute('mkdir "' .. fullPath .. '" 2>nul')

    if success then
        PrintLog("Success: RUBOT folder has been created on the Desktop.")
        PrintLog("Path: " .. fullPath)
    else
        PrintLog("RUBOT folder has been created (check your desktop).")
    end
end

function PickRandomWorld(worldList)
    local totalWorlds = #worldList
    if totalWorlds == 0 then
        return "", ""
    end
    local randomIdx = math.random(1, totalWorlds)
    local world, doorid = ParseWorld(worldList[randomIdx])
    return world, doorid
end

function CheckMp(variant, netid)
    if variant:get(0):getString() == "OnDialogRequest" then
        if variant:get(1):getString():lower():find("magplant 5000") then
            CanTakeMp = true
            unlistenEvents()
        end
    end
end

function TakeMagplant()
    Bot.custom_status = "Taking Remote"
    CallMain("Taking Remote")
    MagplantWorld, MagplantDoorId = PickRandomWorld(AutoTakeMagplantRemote.MagplantWorlds)
    PrintLog("Take Magplant World: " .. MagplantWorld or nil)

    if MagplantWorld then
        Warps(MagplantWorld, MagplantDoorId)
        if Bot:isInWorld(MagplantWorld:upper()) then
            PrintLog("Taking Magplant Remote...")

            if GscanBlock(MagplantId) > 0 then
                addEvent(Event.variantlist, CheckMp)
                for _, tile in pairs(getTiles()) do
                    if tile.fg == MagplantId then
                        for _, y in pairs(TileMp) do
                            for _, x in pairs(TileMp) do
                                if #Bot:getPath(tile.x + x, tile.y + y) > 0 and hasAccess(tile.x, tile.y) > 0 and FindItem(5640) == 0 and not Bot:isInTile(tile.x + x, tile.y + y) then
                                    CanTakeMp = false
                                    Bot:findPath(tile.x + x, tile.y + y)
                                    sleep(200)
                                    if Bot:isInTile(tile.x + x, tile.y + y) then
                                        Bot:wrench(tile.x, tile.y)
                                        listenEvents(3)
                                        if CanTakeMp then
                                            Bot:sendPacket(2,
                                                "action|dialog_return\ndialog_name|itemsucker\ntilex|" ..
                                                tile.x .. "|\ntiley|" .. tile.y .. "|\nbuttonClicked|getplantationdevice")
                                            sleep(2500)
                                            LastMagplantTime = os.time()
                                        end
                                        if FindItem(5640) > 0 then
                                            PrintLog("Successfully Taking Magplant Remote!", "SUCCESS")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        PrintLog("Doesnt Have Magplant World!", "WARN")
    end
end

function ShouldTakeMagplant()
    local currentTime = os.time()
    local diffSeconds = currentTime - LastMagplantTime

    if diffSeconds >= (AutoTakeMagplantRemote.Interval * 60) then
        return true
    else
        return false
    end
end

function GetWorldFromFile(filePath)
    local lockPath = filePath .. ".lock"
    local lines = {}
    local maxRetries = 100 -- Maksimal menunggu
    local retries = 0

    -- Mekanisme Lock: Tunggu jika ada bot lain yang sedang menulis
    while true do
        local lockFile = io.open(lockPath, "r")
        if not lockFile then
            break
        end
        lockFile:close()

        retries = retries + 1
        if retries > maxRetries then
            PrintLog("Error: Waiting too long for file lock!", "CRIT")
            return nil
        end

        sleep(200)
    end

    -- Buat file lock
    local createLock = io.open(lockPath, "w")
    if createLock then createLock:close() end

    -- Baca file dan masukkan ke table
    local file = io.open(filePath, "r")
    if file then
        for line in file:lines() do
            local cleanedLine = line:gsub("^%s*(.-)%s*$", "%1")
            if cleanedLine ~= "" then
                table.insert(lines, cleanedLine)
            end
        end
        file:close()
    end

    if #lines == 0 then
        os.remove(lockPath)
        return nil
    end

    -- Ambil baris pertama dan taruh di bawah
    local firstLine = table.remove(lines, 1)
    table.insert(lines, firstLine)

    -- Tulis kembali ke file
    file = io.open(filePath, "w")
    if file then
        for i, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
    end

    -- Hapus file lock
    os.remove(lockPath)

    return firstLine
end

function TakeMagni()
    Bot.custom_status = "Taking Magnificence"
    CallMain("Taking Magnificence")
    MagniWorld, MagniDoorId = PickRandomWorld(MagnificenceSettings.StorageWorlds)
    if MagniWorld == "" then
        PrintLog("Cannot Find Magnificence Storage World!", "WARN")
        return
    end

    PrintLog("Magnificence Storage: " .. MagniWorld, "INFO")

    while FindItem(MagniId) ~= MagnificenceSettings.TakeAmount do
        TakeItem(MagniWorld, MagniDoorId, MagniId, MagnificenceSettings.TakeAmount)
    end

    while FindItem(MagniId) > 0 and not Bot:getInventory():getItem(MagniId).isActive do
        Bot:wear(MagniId)
        sleep(1500)
        Reconnect(MagniWorld, MagniDoorId)
    end
end

function DropItem(world, doorId, itemId)
    Bot.custom_status = "Dropping " .. (getInfo(itemId).name or "Item")
    Bot.auto_collect = false

    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        CallMain("Dropping Item")
        PrintLog("Dropping " .. FindItem(itemId) .. " " .. getInfo(itemId).name, "STORAGE")

        for i = 1, 10 do
            if FindItem(itemId) == 0 then break end

            Bot:findOutput()
            sleep(500)
            Bot:drop(itemId, FindItem(itemId))
            sleep(450)
        end

        if FindItem(itemId) > 0 then
            PrintLog("Cannot Drop More!, Please Check It Manually!!...", "WARN")
            sleep(3000)
        end
    end
end

function CheckGoods()
    for _, good in pairs(AutoSaveItem.ItemToSave) do
        if FindItem(good) >= AutoSaveItem.MinimumItemToSave then
            return true
        end
    end
    return false
end

function DropGoods()
    local itemToDrop = {}
    for _, good in pairs(AutoSaveItem.ItemToSave) do
        if FindItem(good) >= AutoSaveItem.MinimumItemToSave then
            table.insert(itemToDrop, good)
        end
    end

    if #itemToDrop > 0 then
        local GoodsWorld, GoodsDoorId = PickRandomWorld(AutoSaveItem.StorageWorlds)
        for _, good in pairs(itemToDrop) do
            DropItem(GoodsWorld, GoodsDoorId, good)
            sleep(500)
        end
    end
end

function DetectFarmable()
    CallMain("Detecting Farmable")
    local store = {}
    local count = 0
    for _, tile in pairs(getTiles()) do
        if tile:hasFlag(0) and tile.fg ~= 0 then
            if store[tile.fg] then
                store[tile.fg].count = store[tile.fg].count + 1
            else
                store[tile.fg] = { fg = tile.fg, count = 1 }
            end
        end
    end

    for _, tile in pairs(store) do
        if tile.count > count and tile.fg % 2 ~= 0 then
            count = tile.count
            SeedId = tile.fg
            BlockId = SeedId - 1
            PrintLog("Detected Farmable: " .. getInfo(BlockId).name, "FARM")
        end
    end
end

function ConsumeVial()
    Bot.custom_status = "Using Vial"
    CallMain("Using Vial")
    VialWorld, VialDoorId = PickRandomWorld(AutoMalady.AutoVial.VialWorlds)

    if VialWorld == "" then
        PrintLog("Cannot Read Vial Storage!", "WARN")
        return
    end

    while FindItem(AutoMalady.AutoVial.VialId) ~= 1 do
        TakeItem(VialWorld, VialDoorId, AutoMalady.AutoVial.VialId, 1)
    end

    for i = 1, 2 do
        Bot:say("/status")
        sleep(1000)

        if Bot.malady < 1 then
            if FindItem(AutoMalady.AutoVial.VialId) > 0 and Bot:isInWorld() then
                if getTile(Bot.x, Bot.y).fg == 6 then
                    Warps(VialWorld, VialDoorId)
                end
                PrintLog("Using " .. getInfo(AutoMalady.AutoVial.VialId).name, "MALADY")
                Bot:use(AutoMalady.AutoVial.VialId)
                sleep(1500)
                Reconnect(VialWorld, VialDoorId)
            end
        end
    end
end

function SecondsToClock(seconds)
    local secondss = tonumber(seconds)

    if secondss <= 0 then
        return "00:00:00"
    else
        local hours = string.format("%02d", math.floor(secondss / 3600))
        local mins  = string.format("%02d", math.floor(secondss / 60 - (hours * 60)))
        local secs  = string.format("%02d", math.floor(secondss - (hours * 3600) - (mins * 60)))

        return hours .. ":" .. mins .. ":" .. secs
    end
end

function GetMalady(world, doorId)
    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        if AutoMalady.AutoVial.Enabled then
            ConsumeVial()
        else
            if AutoMalady.AutoChickenFeet then
                MaladyFeature.auto_chicken_feet = true
            end

            if AutoMalady.AutoGrumbleteeth then
                MaladyFeature.auto_grumbleteeth = true
            end

            -- Bot:getMaladyDuration()
            MaladyFeature.enabled = true
            PrintLog("Getting Malady...", "MALADY")
            CallMain("Getting Malady")

            local StartMaladyTime = os.time()

            while Bot.malady < 1 do
                for _ = 1, 10 do
                    sleep(1000)
                end
                Bot:say("/status")

                if os.time() - StartMaladyTime >= 600 then
                    PrintLog("Auto Malady: Disconnecting after 10 minutes...", "WARN")
                    Bot:disconnect()
                    sleep(2000)
                    StartMaladyTime = os.time()
                end

                Reconnect(world, doorId)
            end
            MaladyFeature.enabled = false

            PrintLog("Got Malady: " .. MaladyList[Bot.malady], "SUCCESS")
            PrintLog("Malady Duration: " .. SecondsToClock(Bot:getMaladyDuration()), "MALADY")
        end
        if not Bot:isInWorld(world:upper()) then
            Warps(world, doorId)
        end
    end
end

function GetYAxisTree()
    local TreeY = {}
    local seen = {}
    for _, tile in pairs(getTiles()) do
        if tile.fg == SeedId and tile:canHarvest() and hasAccess(tile.x, tile.y) > 0 then
            if not seen[tile.y] then
                table.insert(TreeY, tile.y)
                seen[tile.y] = true
            end
        end
    end
    table.sort(TreeY)
    return TreeY
end

function IsPlantable(x, y)
    local tempTile = getTile(x, y + 1)
    if not tempTile.fg then return false end
    local collision = getInfo(tempTile.fg).collision_type
    return tempTile and (collision == 1 or collision == 2 or collision == 4)
end

function GetYAxisEmptyTile()
    local TileY = {}
    local seen = {}
    for _, tile in pairs(getTiles()) do
        if tile.fg == 0 and IsPlantable(tile.x, tile.y) and hasAccess(tile.x, tile.y) > 0 then
            if not seen[tile.y] then
                table.insert(TileY, tile.y)
                seen[tile.y] = true
            end
        end
    end
    table.sort(TileY)
    return TileY
end

function GetZigzagPath(tileY)
    local path = {}
    for i, y in ipairs(tileY) do
        if i % 2 == 1 then
            for x = 0, 99 do
                table.insert(path, { x = x, y = y })
            end
        else
            for x = 99, 0, -1 do
                table.insert(path, { x = x, y = y })
            end
        end
    end
    return path
end

function LevelingHarvest()
    Bot.custom_status = "Leveling Up"
    CallMain("Leveling Up")
    while Bot.level < AutoLeveling.GoalLevel do
        local WorldData = GetWorldFromFile(FarmFilePath)
        if WorldData then
            LevelingWorld, LevelingDoorId = ParseWorld(WorldData)
            PrintLog("Leveling World: " .. LevelingWorld, "FARM")
        else
            PrintLog("Cannot Read Leveling World, Stopping Script...", "CRIT")
            Bot:stopScript()
            return
        end

        if MagnificenceSettings.Enabled and FindItem(MagniId) ~= MagnificenceSettings.TakeAmount then
            TakeMagni()
        end

        if CheckGoods() and AutoSaveItem.Enabled then
            DropGoods()
        end

        if Bot.level < AutoLeveling.GoalLevel then
            CheckMalady(LevelingWorld, LevelingDoorId)
            sleep(100)
            CleanFire(LevelingWorld, LevelingDoorId)
            sleep(100)

            Warps(LevelingWorld, LevelingDoorId)
            if Bot:isInWorld(LevelingWorld:upper()) then
                CleanToxic(LevelingWorld, LevelingDoorId)
                sleep(100)
                CheckAutoCure(LevelingWorld, LevelingDoorId)

                PrintLog("Harvesting Until Level: " .. AutoLeveling.GoalLevel, "FARM")
                Harvest(LevelingWorld, LevelingDoorId, false, AutoLeveling.GoalLevel)
            end
        end
    end
end

function CheckMalady(world, doorId)
    Bot.custom_status = "Checking Status"
    Warps(world, doorId)
    if not Bot:isInWorld(world:upper()) then return end
    if AutoMalady.Enabled then
        local AlmostGone = Bot:getMaladyDuration() < 500

        Bot:say("/status")
        sleep(500)

        if Bot.malady < 1 or AlmostGone then
            if AlmostGone then
                while Bot:getMaladyDuration() > 1 do
                    sleep(3000)
                    if math.random() < 0.25 then
                        PrintLog("Waiting to get the malady again.")
                    end
                    Reconnect(world, doorId)
                end
            end
            GetMalady(world, doorId)
        end
    end
end

function CureMalady()
    Bot.custom_status = "Curing Malady"
    CallMain("Curing Malady")
    local maladyMap = {
        [1] = AutoMalady.AutoCure.TornMuscle.HospitalWorlds,
        [2] = AutoMalady.AutoCure.GemCuts.HospitalWorlds
    }

    local hospitalData = maladyMap[Bot.malady]
    if not hospitalData then return end

    local HospitalWorld, CurePriceStr = PickRandomWorld(hospitalData)
    local WlWorld, WlDoorId = PickRandomWorld(AutoMalady.AutoCure.StorageWl)

    local targetPrice = tonumber(CurePriceStr) or 0

    while FindItem(242) < targetPrice do
        PrintLog("Taking WL from storage...", "STORAGE")
        TakeItem(WlWorld, WlDoorId, 242, targetPrice - FindItem(242))
        sleep(1000)
    end

    Warps(HospitalWorld, "")
    if not Bot:isInWorld(HospitalWorld:upper()) then return end

    for _, tile in pairs(getTiles()) do
        if tile.fg == SurgStationId then
            if Bot:findPath(tile.x, tile.y) then
                sleep(100)
                Bot:wrench(tile.x, tile.y)
                sleep(800)

                local Rtvar = getDialog():get()
                if Rtvar:size() > 0 and Rtvar:get("end_dialog") == "autoSurgeonUi" then
                    local OwnedWl, CureCost = 0, 0
                    for _, var in pairs(Rtvar:getParams("add_label_with_icon")) do
                        local text = removeColor(var.parameters[2])
                        if text:match("Owned World Locks") then
                            OwnedWl = tonumber(text:match("%d+")) or 0
                        elseif text:match("Cost") then
                            CureCost = tonumber(text:match("%d+")) or 0
                        end
                    end

                    if OwnedWl < CureCost then
                        PrintLog("Not Enough WL! Owned: " .. OwnedWl .. " Need: " .. CureCost, "WARN")
                    else
                        -- Klik Purchase
                        Bot:sendPacket(2,
                            "action|dialog_return\ndialog_name|autoSurgeonUi\nbuttonClicked|purchaseCureBtn")
                        sleep(1500)

                        -- Dialog Konfirmasi Kedua
                        local Rtvar2 = getDialog():get()
                        if Rtvar2:get("end_dialog") == "autoSurgeonCurePurchaseUi" then
                            Bot:sendPacket(2,
                                "action|dialog_return\ndialog_name|autoSurgeonCurePurchaseUi\nbuttonClicked|purchaseCureBtn")
                            sleep(1000)
                            PrintLog("Malady Cured Successfully!", "SUCCESS")
                        end
                    end
                    break
                end
            end
        end
    end
end

function Plant(world, doorId)
    local TempMode = Mode3Tile

    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        CallMain("Planting")
        PrintLog("Planting...", "FARM")
        Bot.custom_status = "Planting"

        Bot.auto_collect = true
        Bot.object_collect_delay = 200
        Bot.ignore_gems = IgnoreGems

        local EmptyTileY = GetYAxisEmptyTile()
        sleep(100)
        local ZigZagTiles = GetZigzagPath(EmptyTileY)
        sleep(100)

        for i, tile in pairs(ZigZagTiles) do
            if getTile(tile.x, tile.y).fg == 0 and IsPlantable(tile.x, tile.y) and hasAccess(tile.x, tile.y) > 0 and FindItem(SeedId) > 0 then
                if #Bot:getPath(tile.x, tile.y) > 0 then
                    if #Bot:getPath(tile.x, tile.y) > 5 then
                        Bot:findPath(tile.x, tile.y)
                    else
                        Bot:moveTile(tile.x, tile.y)
                    end
                    sleep(100)
                end

                if Bot:isInTile(tile.x, tile.y) then
                    TempMode = (i % 2 == 1) and Mode3Tile or Mode3Tile2
                    for _, m in pairs(TempMode) do
                        if Bot:getWorld():isValidPosition((Bot.x + m) * 32, Bot.y * 32) then
                            while getTile(Bot.x + m, Bot.y).fg == 0 and IsPlantable(Bot.x + m, Bot.y) and hasAccess(Bot.x + m, Bot.y) > 0 and Bot:isInTile(tile.x, tile.y) and FindItem(SeedId) > 0 do
                                Bot:place(Bot.x + m, Bot.y, SeedId)
                                if Delay.DynamicDelay.Enabled then
                                    sleep(GetDynamicDelay(Delay.Plant))
                                else
                                    sleep(Delay.Plant)
                                end
                                Reconnect(world, doorId, tile.x, tile.y)
                            end
                        end
                    end
                end
            end
        end
    end
end

function Harvest(world, doorId, stopMax, maxLvl)
    if maxLvl == 0 then maxLvl = 200 end
    local TempMode = Mode3Tile

    CheckMalady(world, doorId)
    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        CallMain("Harvesting")
        if AutoDetectFarmable then DetectFarmable() end
        Bot.custom_status = "Harvesting"
        PrintLog("Harvesting...")

        Bot.auto_collect = true
        Bot.object_collect_delay = 200
        Bot.ignore_gems = IgnoreGems

        local TileY = GetYAxisTree()
        sleep(100)
        local ZigZagTiles = GetZigzagPath(TileY)
        sleep(100)

        for i, tile in pairs(ZigZagTiles) do
            if Bot.level >= maxLvl then return end
            if getTile(tile.x, tile.y).fg == SeedId and getTile(tile.x, tile.y):canHarvest() and hasAccess(tile.x, tile.y) > 0 and (not stopMax or (stopMax and FindItem(BlockId) < 190)) then
                if #Bot:getPath(tile.x, tile.y) > 0 then
                    if #Bot:getPath(tile.x, tile.y) > 5 then
                        Bot:findPath(tile.x, tile.y)
                    else
                        Bot:moveTile(tile.x, tile.y)
                    end
                    sleep(100)
                end

                if Bot:isInTile(tile.x, tile.y) then
                    TempMode = (i % 2 == 1) and Mode3Tile or Mode3Tile2
                    for _, m in pairs(TempMode) do
                        if Bot:getWorld():isValidPosition((Bot.x + m) * 32, Bot.y * 32) then
                            while getTile(Bot.x + m, Bot.y).fg == SeedId and getTile(Bot.x + m, Bot.y):canHarvest() and hasAccess(Bot.x + m, Bot.y) > 0 and Bot:isInTile(tile.x, tile.y) and Bot:isInWorld(world:upper()) do
                                Bot:hit(Bot.x + m, Bot.y)
                                if Delay.DynamicDelay.Enabled then
                                    sleep(GetDynamicDelay(Delay.Harvest))
                                else
                                    sleep(Delay.Harvest)
                                end
                                Reconnect(world, doorId, tile.x, tile.y)
                            end
                        end
                    end
                end
            end
        end
    end
end

function CheckAutoCure(world, doorId)
    if Bot:isInWorld() then
        Bot:say("/status")
        sleep(300)
    end

    if (Bot.malady == 1 or Bot.malady == 2) and AutoMalady.AutoCure.Enabled then
        CureMalady()
        if AutoMalady.AutoVial.Enabled then
            ConsumeVial()
        end
        if not Bot:isInWorld(world:upper()) then
            Warps(world, doorId)
        end
    end
end

function ScanFire()
    for _, tile in pairs(getTiles()) do
        if tile:hasFlag(4096) then
            return true
        end
    end
    return false
end

function CleanFire(world, doorId)
    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        HasFire = ScanFire()
        if HasFire and not SkipFireWorlds and AutoCleanFire.Enabled then
            local FirehoseWorld, FirehoseDoorId = PickRandomWorld(AutoCleanFire.StorageWorlds)
            while FindItem(FireHoseId) ~= 1 do
                TakeItem(FirehoseWorld, FirehoseDoorId, FireHoseId, 1)
                sleep(1000)
            end

            if FindItem(FireHoseId) > 0 and not Bot:getInventory():getItem(FireHoseId).isActive then
                Bot:wear(FireHoseId)
                sleep(300)
            end

            Warps(world, doorId)
            if not Bot:isInWorld(world:upper()) then return end

            -- Cleaning Fire
            PrintLog("Cleaning Fire...")
            Bot.custom_status = "Cleaning Fire"
            CallMain("Cleaning Fire")
            Bot.anti_fire = true
            for i = 1, 250 do
                if i % 5 == 0 then PrintLog("Still Cleaning Fire...") end
                if Bot:getInventory():getItem(FireHoseId).isActive and FindItem(FireHoseId) > 0 then
                    sleep(2500)
                    Reconnect(world, doorId)
                end
            end
            Bot.anti_fire = false

            sleep(300)
            if not ScanFire() then
                PrintLog("Fire Cleaned!")
            end

            if FindItem(FireHoseId) > 0 then
                DropItem(FirehoseWorld, FirehoseDoorId, FireHoseId)
                sleep(300)
                Reconnect(world, doorId)
            end
        end
    end
end

function CleanToxic(world, doorId)
    -- Cleaning Toxic
    if GscanBlock(778) > 0 then
        PrintLog("Cleaning Toxic...")
        Bot.custom_status = "Cleaning Toxic"
        CallMain("Cleaning Toxic")
        Bot.anti_toxic = true
        for i = 1, 250 do
            if i % 5 == 0 then PrintLog("Cleaning Toxic...") end
            if i == 125 then
                Bot:disconnect()
                sleep(1000)
                Reconnect(world, doorId)
            end
            if GscanBlock(778) > 0 then
                sleep(2500)
                Reconnect(world, doorId)
            else
                break
            end
        end
        Bot.anti_toxic = false
    end
end

function ScanFLoatsY()
    local ytiles = {}
    local seen = {}
    local tx, ty = 0, 0

    for _, obj in pairs(getObjects()) do
        tx, ty = math.floor(obj.x / 32), math.floor(obj.y / 32)
        if obj.id == BlockId and #Bot:getPath(tx, ty) > 0 then
            if not seen[ty] then
                table.insert(ytiles, ty)
                seen[ty] = true
            end
        end
    end

    table.sort(ytiles)

    -- Filter Y yang berdekatan
    local filteredY = {}
    local lastY = -100

    local minDistance = 3

    for _, currentY in ipairs(ytiles) do
        if currentY >= lastY + minDistance then
            table.insert(filteredY, currentY)
            lastY = currentY
        end
    end

    return filteredY
end

function CollectFloating(world, doorId)
    Warps(world, doorId)
    if not Bot:isInWorld(world:upper()) then return end

    Bot.auto_collect = true
    Bot:setInterval(Action.collect, 0.100)
    Bot.ignore_gems = IgnoreGems
    Bot.move_range = 4
    Bot:setInterval(Action.move, 0.235)

    PrintLog("Collecting Floating Blocks...")
    Bot.custom_status = "Collecting Floating Blocks"
    CallMain("Collecting Floats")

    local FloatY = ScanFLoatsY()
    sleep(100)
    local ZigZagTiles = GetZigzagPath(FloatY)
    sleep(100)

    for i, tile in pairs(ZigZagTiles) do
        if tile.x % 9 == 0 then
            if #Bot:getPath(tile.x, tile.y) > 0 and FindItem(BlockId) < 196 then
                Bot:findPath(tile.x, tile.y)
                sleep(100)
                Reconnect(world, doorId, tile.x, tile.y)
            end
        end
    end

    Bot.move_range = MoveRange
    Bot:setInterval(Action.move, MoveInterval)
end

function CountReadyTrees()
    local readyTree = 0
    for _, tile in pairs(getTiles()) do
        if tile.fg == SeedId and tile:canHarvest() and hasAccess(tile.x, tile.y) > 0 then
            readyTree = readyTree + 1
        end
    end
    return readyTree
end

function CountEmptyTiles()
    local emptyTiles = 0
    for _, tile in pairs(getTiles()) do
        if tile.fg == 0 and IsPlantable(tile.x, tile.y) and hasAccess(tile.x, tile.y) > 0 then
            emptyTiles = emptyTiles + 1
        end
    end
    return emptyTiles
end

function MethodCheck(world, doorId)
    if SayRandomWords.Enabled then
        Bot:say(tostring(SayRandomWords.MessageList[math.random(1, #SayRandomWords.MessageList)]))
        sleep(300)
        Bot:say(tostring(Emotes[math.random(1, #Emotes)]))
    end
    if RandomSkinColor then
        Bot:setSkin(math.random(2, 7))
        sleep(100)
    end
    if FindItem(98) > 0 and not Bot:getInventory():getItem(98).isActive then
        Bot:wear(98)
        sleep(300)
    end
    if not Bot:isInWorld(world:upper()) then
        Warps(world, doorId)
    end
end

function ValidPos(x, y)
    return Bot:getWorld():isValidPosition(x * 32, y * 32)
end

function GetPositiveBreakOffsets(val)
    local offsets = {}
    local high = math.floor(val / 2)
    local low = high - (val - 1)
    for i = high, low, -1 do
        table.insert(offsets, math.floor(i))
    end
    return offsets
end

function GetNegativeBreakOffsets(val)
    local offsets = {}
    local high = math.floor(val / 2)
    local low = high - (val - 1)
    for i = low, high, 1 do
        table.insert(offsets, math.floor(i))
    end
    return offsets
end

function PnbInFarm(world, doorId)
    Bot.custom_status = "Breaking Block [In Farm]"
    local LastPosX = Bot.x
    local LastPosY = Bot.y

    local BreakPosX, BreakPosY = 0, 0

    if LastPosX >= 50 then
        BreakPosX = 98
    else
        BreakPosX = 1
    end

    if LastPosY < 23 then
        BreakPosY = math.random(3, 9)
    else
        BreakPosY = math.random(45, 51)
    end

    BreakBlock(world, doorId, BreakPosX, BreakPosY, true, true)
end

function IsAnotherPlayer()
    for _, player in pairs(getPlayers()) do
        if not player.isLocalPlayer and player.name:upper() ~= PnbInHome.OwnerWhitelist:upper() then
            return true
        end
    end
    return false
end

function BreakBlockCheck(world, doorId)
    if not IsAnotherPlayer() then return end

    if AutoCreatePnbWorld.Enabled and AutoCreatePnbWorld.AutoLeaveWhenPlayerJoined and CreatedWorldLockedBy == "sl" then
        while IsAnotherPlayer() do
            PrintLog("Someone Entered World, Leaving World for 15s", "WARN")
            for i = 1, 3 do
                if Bot:isInWorld() then
                    Bot:leaveWorld()
                    sleep(2000)
                end
            end

            for i = 1, 15 do sleep(1000) end
            Reconnect(world, doorId)
        end
        return
    end

    if PnbInHome.Enabled or (AutoCreatePnbWorld.Enabled and CreatedWorldLockedBy == "wl") then
        for _, player in pairs(getPlayers()) do
            if not player.isLocalPlayer and player.name:upper() ~= PnbInHome.OwnerWhitelist:upper() then
                Bot:say("/ban " .. player.name)
                sleep(500)
                Reconnect(world, doorId)
            end
        end
    end
end

function BreakBlock(world, doorId, BreakPosX, BreakPosY, verticalMode, inFarm)
    inFarm = inFarm or false

    -- Checking
    CheckMalady(world, doorId)
    CheckAutoCure(world, doorId)

    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        PrintLog(string.format("Breaking Blocks at X: %d, Y: %d", BreakPosX or Bot.x, BreakPosY or Bot.y))
        Bot.custom_status = "PNB"
        CallMain("PNB")

        if BreakPosX == nil or BreakPosY == nil then
            BreakPosX = Bot.x
            BreakPosY = Bot.y
        end

        if inFarm and getTile(BreakPosX, BreakPosY).fg ~= 0 and getTile(BreakPosX, BreakPosY).fg ~= SeedId then
            BreakPosY = BreakPosY + 1
        end

        local direction = (BreakPosX >= 50) and 1 or -1

        if Bot:findPath(BreakPosX, BreakPosY) then
            sleep(250)

            MethodCheck(world, doorId)

            Bot.auto_collect = true
            Bot.object_collect_delay = 200
            Bot.ignore_gems = false

            while FindItem(BlockId) > 0 and FindItem(SeedId) < 196 do
                BreakBlockCheck(world, doorId)

                -- LOOP PLACING
                for _, tb in pairs(PositiveTileBreak) do
                    local tx, ty
                    if verticalMode then
                        tx, ty = BreakPosX + direction, BreakPosY + tb
                    else
                        tx, ty = BreakPosX + tb, BreakPosY - 2
                    end

                    if getTile(tx, ty).fg == 0 and getTile(tx, ty).bg == 0 and FindItem(BlockId) > 0 and ValidPos(tx, ty) and hasAccess(tx, ty) > 0 then
                        Bot:place(tx, ty, BlockId)
                        sleep(Delay.DynamicDelay.Enabled and GetDynamicDelay(Delay.Place) or Delay.Place)
                        Reconnect(world, doorId, BreakPosX, BreakPosY)
                    end
                end

                -- LOOP BREAKING
                for _, tb in pairs(PositiveTileBreak) do
                    local tx, ty
                    if verticalMode then
                        tx, ty = BreakPosX + direction, BreakPosY + tb
                    else
                        tx, ty = BreakPosX + tb, BreakPosY - 2
                    end

                    while (getTile(tx, ty).fg ~= 0 or getTile(tx, ty).bg ~= 0) and ValidPos(tx, ty) and hasAccess(tx, ty) > 0 do
                        Bot:hit(tx, ty)
                        sleep(Delay.DynamicDelay.Enabled and GetDynamicDelay(Delay.Hit) or Delay.Hit)
                        Reconnect(world, doorId, BreakPosX, BreakPosY)
                    end
                end
            end
        end
    end
end

function BuyLocks(world, doorId)
    Bot.custom_status = "Buying Locks"
    CallMain("Buying Locks")
    if Bot.gem_count > 2000 and FindItem(242) == 0 then
        PrintLog("Buying WL...", "SHOP")
        for _ = 1, 3 do
            if Bot.gem_count > 2000 and FindItem(242) == 0 then
                Bot:buy("world_lock")
                sleep(1500)
                Reconnect(world, doorId)
            end
        end

        if FindItem(242) > 0 then
            PrintLog("Success Buying WL", "SUCCESS")
            return true
        end
    end

    if Bot.gem_count > 50 and FindItem(202) == 0 then
        PrintLog("Buying SL...", "SHOP")
        for _ = 1, 3 do
            if Bot.gem_count > 50 and FindItem(202) == 0 then
                Bot:buy("small_lock")
                sleep(1500)
                Reconnect(world, doorId)
            end
        end

        if FindItem(202) > 0 then
            PrintLog("Success Buying SL", "SUCCESS")
            return true
        end
    end

    return false
end

function OnGameMessage(message)
    if message:find("available|") then
        local value = message:match("available|(%d+)")
        if value then
            isAvailable = tonumber(value)
        end
        unlistenEvents()
    end
end

function IsWorldAvailable(worldName)
    local isAvailable = 0

    addEvent(Event.game_message, OnGameMessage)

    Bot:sendPacket(3, "action|validate_world\nname|" .. worldName)
    listenEvents(3)

    removeEvent(Event.game_message)

    return isAvailable == 1
end

function GetRandomString(length, mixNumber, useVowels)
    local vowels = "aeiou"
    local consonants = "bcdfghjklmnpqrstvwxyz"
    local numbers = "0123456789"
    local allChars = consonants .. vowels

    if mixNumber then
        allChars = allChars .. numbers
    end

    local result = ""

    for i = 1, length do
        if useVowels then
            if i % 2 == 1 then
                local r = math.random(1, #consonants)
                result = result .. consonants:sub(r, r)
            else
                local r = math.random(1, #vowels)
                result = result .. vowels:sub(r, r)
            end
        else
            local r = math.random(1, #allChars)
            result = result .. allChars:sub(r, r)
        end
    end

    if useVowels and mixNumber then
        for _ = 1, 2 do
            local r = math.random(1, #numbers)
            result = result .. numbers:sub(r, r)
        end
    end

    return result
end

function RemoveLock(world, doorId)
    Bot.custom_status = "Removing Lock"
    CallMain("Removing Lock")
    PrintLog("Breaking Lock...", "PNB")
    Warps(world, doorId)
    if Bot:isInWorld(world:upper()) then
        if Bot.level >= 5 then
            CheckMalady(world, doorId)
            for _, tile in pairs(getTiles()) do
                if tile.fg == 242 or tile.fg == 202 or tile.fg == 226 then
                    if Bot:findPath(tile.x, tile.y + 1) then
                        while getTile(tile.x, tile.y).fg ~= 0 do
                            Bot:hit(tile.x, tile.y)
                            sleep(Delay.DynamicDelay.Enabled and GetDynamicDelay(Delay.Hit) or Delay.Hit)
                            Reconnect(world, doorId, tile.x, tile.y + 1)
                        end
                    end
                end
            end
        end
    end
end

function PutLock(world, doorId)
    Bot.custom_status = "Placing Lock"
    CallMain("Placing Lock")
    PrintLog("Placing Lock...", "PNB")
    if FindItem(242) > 0 then
        for _ = 1, 100 do
            if getTile(Bot.x, Bot.y - 1).fg == 0 and hasAccess(Bot.x, Bot.y - 1) > 0 and FindItem(242) > 0 then
                Bot:place(Bot.x, Bot.y - 1, 242)
                sleep(500)
                Reconnect(world, doorId)
            else
                break
            end
        end
    else
        for _ = 1, 100 do
            if getTile(Bot.x, Bot.y - 1).fg == 0 and hasAccess(Bot.x, Bot.y - 1) > 0 and FindItem(202) > 0 then
                Bot:place(Bot.x, Bot.y - 1, 202)
                sleep(500)
                Reconnect(world, doorId)
            else
                break
            end
        end
    end

    if getTile(Bot.x, Bot.y - 1).fg == 242 then
        Reconnect(world, doorId)

        Bot:wrench(Bot.x, Bot.y - 1)
        sleep(500)

        local RtVar = getDialog():get()
        if RtVar:size() > 0 and RtVar:get("end_dialog") == "lock_edit" then
            -- print("[OnDialogRequest]\n" .. RtVar:dump() .. "\n\n")
            Bot:sendPacket(2,
                "action|dialog_return\ndialog_name|lock_edit\ntilex|" ..
                Bot.x ..
                "|\ntiley|" ..
                Bot.y - 1 ..
                "|\ncheckbox_public|0\ncheckbox_disable_music|0\ntempo|100\ncheckbox_disable_music_render|0\ncheckbox_set_as_home_world|0\nminimum_entry_level|" ..
                AutoCreatePnbWorld.SetMinimumLevel)
            sleep(1000)
        end
        getDialog():clear()
    end

    sleep(500)

    if getTile(Bot.x, Bot.y - 1).fg == 242 then
        CreatedWorldLockedBy = "wl"
    elseif getTile(Bot.x, Bot.y - 1).fg == 202 then
        CreatedWorldLockedBy = "sl"
    end

    if getTile(Bot.x, Bot.y - 1).fg == 242 or getTile(Bot.x, Bot.y - 1).fg == 202 then
        return true
    end

    return false
end

function CreatePnbWorld()
    if not AutoCreatePnbWorld.Enabled then return end
    Bot.custom_status = "Checking PNB World"
    CallMain("Checking PNB World")
    local fileName = os.getenv("USERPROFILE") .. "\\Desktop\\RUBOT_ROTATION\\createdPnb.txt"

    -- PENGECEKAN FILE (Mencari apakah bot sudah punya world)
    local fileRead = io.open(fileName, "r")
    if fileRead then
        for line in fileRead:lines() do
            -- Memisahkan BotName dan WorldName
            local savedBot, savedWorld, lockedBy = line:match("([^|]+)|([^|]+)|([^|]+)")
            if savedBot and savedBot:upper() == Bot.name:upper() then
                PrintLog("Found existing PNB World in file: " .. savedWorld, "PNB")
                CreatedPnbWorld = savedWorld
                CreatedPnbDoorId = ""
                PnbWorldCreated = true
                CreatedWorldLockedBy = lockedBy
                fileRead:close()
                return
            end
        end
        fileRead:close()
    end

    -- LOGIKA PERSIAPAN (Jika tidak ditemukan di file)
    local StorageWorld, StorageDoorId = PickRandomWorld(AutoCreatePnbWorld.StorageWorlds)

    -- Ambil Jammer jika butuh
    if AutoCreatePnbWorld.PutSignalJammer and FindItem(226) == 0 then
        while FindItem(226) ~= 1 do
            TakeItem(StorageWorld, StorageDoorId, 226, 1)
        end
    end

    -- Cek & Beli/Ambil Lock
    local haveLock = (FindItem(242) > 0 or FindItem(202) > 0)
    if not haveLock and AutoCreatePnbWorld.AutoBuyLock then
        haveLock = BuyLocks(StorageWorld, StorageDoorId)
    end

    if not haveLock then
        PrintLog("Buy Lock failed. Checking Storage...", "WARN")
        Warps(StorageWorld, StorageDoorId)
        if Bot:isInWorld(StorageWorld:upper()) then
            if GscanFloat(242) > 0 then
                TakeItem(StorageWorld, StorageDoorId, 242, 1)
            elseif GscanFloat(202) > 0 then
                TakeItem(StorageWorld, StorageDoorId, 202, 1)
            end
        end
    end

    if FindItem(242) == 0 and FindItem(202) == 0 then
        PrintLog("CRITICAL: No Lock found! Stopping...", "CRIT")
        Bot:stopScript()
        return
    end

    -- MENCARI WORLD BARU
    Bot.custom_status = "Searching World"
    CallMain("Searching World")
    while Bot:isInWorld() do
        Bot:leaveWorld()
        sleep(3000)
        EnsureOnline()
    end

    local maxAttempts = 500
    local TempName = ""
    local IsAvail = false

    for i = 1, maxAttempts do
        TempName = GetRandomString(10, true, false)
        PrintLog(string.format("Attempt %d: Checking %s", i, TempName:upper()))
        IsAvail = IsWorldAvailable(TempName)
        if IsAvail then break end
        sleep(1000)
        EnsureOnline()
    end

    -- EKSEKUSI PEMBUATAN & SIMPAN KE FILE
    if IsAvail then
        Warps(TempName, "")
        if Bot:isInWorld(TempName:upper()) then
            if PutLock(TempName, "") then
                -- Place Jammer
                if AutoCreatePnbWorld.PutSignalJammer and FindItem(226) > 0 then
                    for _ = 1, 5 do
                        if getTile(Bot.x - 1, Bot.y - 1).fg == 0 and FindItem(226) > 0 then
                            Bot:place(Bot.x - 1, Bot.y - 1, 226)
                            sleep(500)
                            Reconnect(TempName, "")
                        end
                    end

                    sleep(1000)
                    local jammerFlags = getTile(Bot.x - 1, Bot.y - 1).flags
                    sleep(200)

                    for _ = 1, 5 do
                        if getTile(Bot.x - 1, Bot.y - 1).flags == jammerFlags and getTile(Bot.x - 1, Bot.y - 1).fg == 226 then
                            Bot:hit(Bot.x - 1, Bot.y - 1)
                            sleep(1000)
                            Reconnect(TempName, "")
                        end
                    end
                end

                CreatedPnbWorld = TempName:upper()
                CreatedPnbDoorId = ""
                PnbWorldCreated = true

                -- Simpan ke TXT
                local fileWrite = io.open(fileName, "a")
                if fileWrite then
                    fileWrite:write(string.format("%s|%s|%s\n", Bot.name, CreatedPnbWorld, CreatedWorldLockedBy))
                    fileWrite:close()
                    PrintLog("World " .. CreatedPnbWorld .. " saved to file.", "SUCCESS")
                end
            else
                PnbWorldCreated = false
            end
        end
    else
        PrintLog("Failed to find available world.")
    end
end

function RotatePnbWorld()
    local fileName = os.getenv("USERPROFILE") .. "\\Desktop\\RUBOT_ROTATION\\createdPnb.txt"
    local lines = {}
    local fileRead = io.open(fileName, "r")

    if fileRead then
        for line in fileRead:lines() do
            local savedBot = line:match("([^|]+)|")
            if savedBot and savedBot:upper() ~= Bot.name:upper() then
                table.insert(lines, line)
            end
        end
        fileRead:close()
    end

    local fileWrite = io.open(fileName, "w")
    if fileWrite then
        for _, line in ipairs(lines) do
            fileWrite:write(line .. "\n")
        end
        fileWrite:close()
    end

    PnbWorldCreated = false
    CreatedPnbWorld = ""
    CreatedPnbDoorId = ""
    PrintLog("PNB World Rotated Successfully!", "SUCCESS")
end

function ChoosePnbMode()
    if PnbInHome.Enabled and HomeWorld ~= "" and not NoHomeWorld then
        PnbWorld, PnbDoorId = HomeWorld, ""
        BreakPosX, BreakPosY = 50, 23

        local data = {
            Success = true,
            PnbWorld = PnbWorld,
            PnbDoorId = PnbDoorId,
            BreakPosX = BreakPosX,
            BreakPosY = BreakPosY,
            InFarm = false,
        }

        return data
    end

    if PnbInOtherWorld.Enabled then
        -- CEK: Jika Cache Kosong (Pertama Run) ATAU World Sebelumnya Nuked
        if not CachedPnbOtherWorldData or PnbWorldIsNuked then
            if PnbWorldIsNuked then
                PrintLog("PNB World Nuked! Selecting new world...")
            else
                PrintLog("Selecting PNB World...")
            end

            CachedPnbOtherWorldData = GetWorldFromFile(PnbFilePath) -- Ambil data baru
            PnbWorldIsNuked = false                                 -- Reset status nuked setelah dapat world baru
        end

        -- Jalankan hanya jika WorldData berhasil didapatkan
        if CachedPnbOtherWorldData then
            PnbWorld, PnbDoorId = ParseWorld(CachedPnbOtherWorldData)

            if PnbInOtherWorld.CustomPosition.Enabled then
                BreakPosX = PnbInOtherWorld.CustomPosition.PositionX
                BreakPosY = PnbInOtherWorld.CustomPosition.PositionY
            end

            local data = {
                PnbWorld = PnbWorld,
                PnbDoorId = PnbDoorId,
                BreakPosX = BreakPosX,
                BreakPosY = BreakPosY,
                InFarm = false,
                Success = true
            }

            return data
        end
    end

    if AutoCreatePnbWorld.Enabled then
        local data = {
            BreakPosX = nil,
            BreakPosY = nil,
            PnbWorld = CreatedPnbWorld,
            PnbDoorId = CreatedPnbDoorId,
            Success = true,
            InFarm = false
        }
        return data
    end

    local data = {
        Success = true,
        InFarm = true
    }
    return data
end

function PNB(world, doorId)
    if AutoCreatePnbWorld.Enabled then
        local currentTime = os.time()
        local diffMinutes = (currentTime - LastPnbRotationTime) / 60

        if diffMinutes >= AutoCreatePnbWorld.RotationInterval then
            PrintLog("PNB Rotation Time Reached! (" .. AutoCreatePnbWorld.RotationInterval .. " minutes)", "PNB")

            if CreatedPnbWorld ~= "" then
                RemoveLock(CreatedPnbWorld, CreatedPnbDoorId)
            end

            RotatePnbWorld()
            LastPnbRotationTime = currentTime
        end
    end

    if not PnbWorldCreated and AutoCreatePnbWorld.Enabled then
        while not PnbWorldCreated do
            CreatePnbWorld()
            sleep(1000)
        end
    end

    local data = ChoosePnbMode()

    if data.Success then
        PrintLog("Selected PNB World: " .. data.PnbWorld:upper(), "PNB")

        if data.InFarm then
            PnbInFarm(world, doorId)
        else
            BreakBlock(data.PnbWorld, data.PnbDoorId, data.BreakPosX, data.BreakPosY, false, false)
        end
    end
end

function SaveSeeds()
    Bot.custom_status = "Saving Seeds"
    CallMain("Saving Seeds")
    if PlantProfitSeeds.Enabled then
        PrintLog("PlantProfitSeeds is enabled. Planting profit seeds...")
        for _, worldData in ipairs(PlantProfitSeeds.PlantWorlds) do
            if FindItem(SeedId) == 0 then break end

            local plantWorld, plantDoorId = ParseWorld(worldData)
            PrintLog("Planting profit seeds in " .. plantWorld:upper(), "FARM")
            Plant(plantWorld, plantDoorId)
        end
    else
        local world, doorId = PickRandomWorld(SeedStorageWorlds)
        for i = 1, 10 do
            if FindItem(SeedId) == 0 then return end
            PrintLog("Saving Seeds...", "STORAGE")
            DropItem(world, doorId, SeedId)
            sleep(1000)
        end
        RunJoinRandomWorld()
    end
end

function TakePickaxe()
    Bot.custom_status = "Taking Pickaxe"
    CallMain("Taking Pickaxe")
    PrintLog("Taking Pickaxe...", "INFO")
    local world, doorId = PickRandomWorld(AutoTakePickaxe.StorageWorlds)
    for i = 1, 10 do
        if FindItem(AutoTakePickaxe.PickaxeId) ~= 1 then
            TakeItem(world, doorId, AutoTakePickaxe.PickaxeId, 1)
            sleep(1000)
        end
    end

    for _ = 1, 3 do
        if FindItem(AutoTakePickaxe.PickaxeId) > 0 and not Bot:getInventory():getItem(AutoTakePickaxe.PickaxeId).isActive then
            Bot:wear(AutoTakePickaxe.PickaxeId)
            sleep(1500)
            Reconnect(world, doorId)
        end
    end
end

function RunJoinRandomWorld()
    if not JoinRandomWorld.Enabled then return end
    CallMain("Joining Random World")

    local world = JoinRandomWorld.WorldList[math.random(1, #JoinRandomWorld.WorldList)]
    if world then
        PrintLog("Joining random world: " .. world:upper(), "INFO")
        Warps(world, "")
        if Bot:isInWorld(world:upper()) then
            if SayRandomWords.Enabled then
                Bot:say(tostring(SayRandomWords.MessageList[math.random(1, #SayRandomWords.MessageList)]))
                sleep(math.random(1000, 3000))
            end
            sleep(math.random(2000, 5000))
            Bot:leaveWorld()
            sleep(2000)
        end
    end
end

function CheckTrash()
    local shouldTrash = false
    for _, id in pairs(ItemToTrash) do
        if FindItem(id) >= 150 then
            shouldTrash = true
            break
        end
    end

    if shouldTrash then
        Bot.custom_status = "Cleaning Inventory"
        CallMain("Cleaning Inventory")
        PrintLog("Trash limit reached, cleaning up ItemToTrash...", "STORAGE")
        for _, id in pairs(ItemToTrash) do
            local count = FindItem(id)
            if count > 0 then
                Bot:trash(id, count)
                sleep(200)
            end
        end
    end
end

function GetCurrentClothes()
    local clothez = 0
    for _, baju in pairs(Bot:getInventory():getItems()) do
        if getInfo(baju.id).clothing_type > 0 then
            clothez = clothez + 1
        end
    end
    return clothez
end

function BuyClothes(world, doorId)
    local currentClothes = GetCurrentClothes()
    if currentClothes < 5 and Bot.gem_count >= 500 then
        CallMain("Buying Clothes")
        Bot:buy("rare_clothes")
        sleep(1000)
        for _, baju in pairs(Bot:getInventory():getItems()) do
            if getInfo(baju.id).clothing_type > 0 then
                if baju.id ~= 3934 and baju.id ~= 3932 then
                    Bot:wear(baju.id)
                    sleep(1000)
                    Reconnect(world, doorId)
                end
            end
        end
    end
end

function BuyPack(world, doorId)
    if not AutoBuyPack.Enabled then return end
    Bot.custom_status = "Checking Gems"
    Bot.auto_collect = false
    sleep(100)

    Warps(world, doorId)

    local threshold = AutoBuyPack.PackPrice * AutoBuyPack.MinimumPackToBuy
    if Bot.gem_count >= threshold then
        Bot.custom_status = "Buying Packs"
        PrintLog("Gems reached threshold (" .. threshold .. "). Buying packs...", "SHOP")

        while Bot:getInventory().slotcount < 35 do
            Bot:buy("upgrade_backpack")
            sleep(1000)
            Reconnect(world, doorId)
        end

        while Bot.gem_count >= AutoBuyPack.PackPrice do
            Bot:buy(AutoBuyPack.PackName)
            ProfitPack = ProfitPack + 1
            sleep(1500)
            Reconnect(world, doorId)
        end
        CallProfit()

        local storageWorld, storageDoorId = PickRandomWorld(AutoBuyPack.StorageWorlds)
        PrintLog("Storing purchased packs in " .. storageWorld:upper(), "STORAGE")

        for _, id in pairs(AutoBuyPack.PackItemId) do
            local count = FindItem(id)
            if count > 0 then
                DropItem(storageWorld, storageDoorId, id)
                sleep(1000)
            end
        end
        RunJoinRandomWorld()
    end
end

function Main()
    GetSelectedBot()
    sleep(100)
    GetIndexBot()
    sleep(100)

    sleep((IndexBot - 1) * Delay.ScriptStarted)

    local isValid = ValidateKey()
    if IndexBot == 1 then CallRubot(isValid) end

    if isValid then
        CallMain("Script Started!")
        PrintLog("Script Started!", "INFO")
        PrintLog("Tips: Use 'Enable Multi Select'", "INFO")

        -- Init
        InitBotSettings()
        if IndexBot == 1 then InitFolder() end
        InitWorlds()
        if AutoMalady.Enabled and AutoMalady.AutoGrumbleteeth then InitSpamFeature() end

        -- Take Magplant
        if AutoTakeMagplantRemote.Enabled then
            TakeMagplant()
        end

        -- Take Pickaxe
        if AutoTakePickaxe.Enabled then
            TakePickaxe()
        end

        -- Leveling
        if AutoLeveling.Enabled and Bot.level < AutoLeveling.GoalLevel then
            LevelingHarvest()
        end

        if Bot.level >= StopOnLevel then
            CallMain("Level Goal Reached!")
            CallNotif("Level Goal Reached! Stopping Script...", true)
            PrintLog("StopOnLevel " .. StopOnLevel .. " reached! Stopping script...", "INFO")
            Bot:stopScript()
            return
        end

        local FarmCount = 0
        while (LoopRotation or FarmCount < BotFarmLimit) do
            FarmCount = FarmCount + 1

            local FarmData = GetWorldFromFile(FarmFilePath)
            if not FarmData then
                PrintLog("Failed to get Farm World!, Please Check Your Txt File!. Stopping Script...", "CRIT")
                Bot:stopScript()
                return
            end

            local FarmWorld, FarmDoorId = ParseWorld(FarmData)
            PrintLog("Selected Farm: " .. FarmWorld:upper(), "FARM")

            -- Auto Buy Clothes
            if AutoBuyClothes then
                BuyClothes()
            end

            while true do
                if Bot.level >= StopOnLevel then
                    PrintLog("StopOnLevel " .. StopOnLevel .. " reached! Stopping script...", "INFO")
                    Bot:stopScript()
                    return
                end

                HasFire = false
                CheckMalady(FarmWorld, FarmDoorId)
                sleep(100)
                CleanFire(FarmWorld, FarmDoorId)
                sleep(100)

                -- Keluar dari loop 'while' jika world bermasalah/skip
                if HasFire and SkipFireWorlds then
                    PrintLog("Skipping " .. FarmWorld .. " due to fire.", "WARN")
                    break
                end

                Warps(FarmWorld, FarmDoorId)
                if not Bot:isInWorld(FarmWorld:upper()) then break end

                -- CEK APAKAH MASIH ADA POHON SIAP PANEN ATAU PETAK KOSONG
                local readyTrees = CountReadyTrees()
                local emptyTiles = (FillIncompleteFarms and FindItem(SeedId) > 0 and not SkipReplanting) and
                    CountEmptyTiles() or 0

                sleep(100)
                if readyTrees == 0 and emptyTiles == 0 then
                    PrintLog("No more ready trees or empty tiles to fill in " .. FarmWorld .. ". Moving to next world.",
                        "INFO")
                    break
                end

                if readyTrees > 0 then
                    PrintLog("Ready Trees: " .. readyTrees .. ". Starting cycle...", "FARM")
                elseif emptyTiles > 0 then
                    PrintLog("Incomplete Farm Detected! Filling " .. emptyTiles .. " empty tiles...", "FARM")
                end

                -- Jalankan semua tugas pembersihan
                CleanToxic(FarmWorld, FarmDoorId)
                sleep(100)
                CheckAutoCure(FarmWorld, FarmDoorId)

                -- Collect Floating
                if CollectFloatingBlocks then
                    CollectFloating(FarmWorld, FarmDoorId)
                end

                -- Harvest
                if FindItem(BlockId) < 196 then
                    Harvest(FarmWorld, FarmDoorId, true, 0)
                end

                -- Plant Tahap 1
                if FindItem(SeedId) > 0 and not SkipReplanting then
                    Plant(FarmWorld, FarmDoorId)
                end

                -- Break Block (Hancurkan blok hasil panen tadi)
                if FindItem(BlockId) > 0 then
                    PNB(FarmWorld, FarmDoorId)
                end

                -- Plant Tahap 2 (Tanam bibit hasil break)
                if FindItem(SeedId) > 0 and not SkipReplanting then
                    Plant(FarmWorld, FarmDoorId)
                end

                -- Saving Seeds
                if FindItem(SeedId) > MinimumSeedToSave then
                    SaveSeeds()
                end

                CheckTrash()
                BuyPack(FarmWorld, FarmDoorId)
                CallGlobal()
                sleep(1000)
            end
        end
    else
        if IndexBot == 1 then
            local messageBox = MessageBox.new()
            messageBox.title = "Rubot"
            messageBox.description = "Lucifer Not Registered!\nRegister Here: dsc.gg/rubot-script"
            messageBox:send()
        else
            PrintLog("Lucifer Not Registered!", "CRIT")
        end
    end
end

Main()
