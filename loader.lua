local scripts = {
    rotation = "https://raw.githubusercontent.com/ruijiecode/growtopia-script/refs/heads/main/rotation/v1/main.lua",
    create_world = "https://raw.githubusercontent.com/ruijiecode/growtopia-script/refs/heads/main/create-world/main.lua",
}

local function listKeys(t)
    local keys = {}
    for k, _ in pairs(t) do table.insert(keys, k) end
    return keys
end

local scriptName = ...
if not scriptName or type(scriptName) ~= "string" then
    print("[LOADER] Usage: load(res.body)(\"script_name\")")
    print("[LOADER] Available: " .. table.concat(listKeys(scripts), ", "))
    return
end

scriptName = scriptName:lower()
local url = scripts[scriptName]

if not url then
    print("[LOADER] Script \"" .. scriptName .. "\" not found!")
    print("[LOADER] Available: " .. table.concat(listKeys(scripts), ", "))
    return
end

print("[LOADER] Fetching: " .. scriptName)

local http = HttpClient.new()
http.method = Method.get
http.url = url
local res = http:request()

if res.error ~= 0 then
    print("[LOADER] HTTP error (" .. scriptName .. "): " .. res:getError())
    return
end

local fn, err = load(res.body)
if not fn then
    print("[LOADER] Load error (" .. scriptName .. "): " .. tostring(err))
    return
end

print("[LOADER] Running: " .. scriptName)
fn()
