-- [[ LORDS HUB - DEBUG LOADER ]] --
-- Această versiune forțează re-descărcarea fișierelor (ignoră cache-ul)

local GAME_NAME = "The Forge"
-- Link-ul STANDARD (fără refs/heads)
local REPO_BASE = "https://raw.githubusercontent.com/BogdanLord/LordsHub-Modules/main/" 

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Lord's Hub - DEBUG MODE",
   LoadingTitle = "Debugging...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local Utils = {}
function Utils.log(msg) 
    print("[DEBUG] " .. msg)
    Rayfield:Notify({Title = "Debug", Content = msg, Duration = 2})
end

local function LoadForceFresh(fileName)
    -- TRUC: Adăugăm timpul curent la link ca să păcălim Roblox să nu folosească cache-ul
    local url = REPO_BASE .. fileName .. "?t=" .. tostring(os.time())
    
    print("------------------------------------------------")
    print("1. Încerc conectarea la: " .. url)
    
    local success, response = pcall(function() return game:HttpGet(url, true) end)
    
    if not success then
        warn("❌ EROARE REȚEA: Nu pot accesa GitHub!")
        return
    end

    print("2. Fișier descărcat! Mărime: " .. #response .. " caractere")
    print("3. Previzualizare cod (Primele linii):")
    print(string.sub(response, 1, 150)) -- Vedem primele 150 caractere în consolă
    
    -- Verificăm dacă am descărcat HTML din greșeală
    if string.find(response, "<!DOCTYPE html>") then
        warn("❌ CRITIC: Link-ul returnează un SITE, nu un script LUA!")
        Rayfield:Notify({Title = "Eroare", Content = "Link greșit (HTML detectat)", Duration = 5})
        return
    end

    local func, err = loadstring(response)
    if not func then
        warn("❌ EROARE SINTAXĂ: Codul din " .. fileName .. " este scris greșit!")
        warn("Detalii eroare: " .. tostring(err))
        Rayfield:Notify({Title = "Syntax Error", Content = "Vezi consola F9!", Duration = 5})
        return
    end

    print("4. Executare modul...")
    local ok, runErr = pcall(func, Window, Rayfield, Utils)
    
    if ok then
        print("✅ SUCCES: Tab-ul ar trebui să fie vizibil!")
        Rayfield:Notify({Title = "Succes", Content = "Modul încărcat!", Duration = 3})
    else
        warn("❌ EROARE RUNTIME: " .. tostring(runErr))
    end
end

-- Încărcăm mine.lua
LoadForceFresh("mine.lua")
