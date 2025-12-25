-- [[ DEBUG VERSION - mine.lua ]] --
return function(Window, Rayfield, Utils)
    -- Folosim un print ca să vedem în consolă (F9) dacă ajunge aici
    if Utils then Utils.log("Debug: Modulul a pornit!") end

    -- 1. Creăm Tab-ul cu o iconiță VALIDĂ (nu nil)
    -- Folosim ID-ul 4483362458 (Home Icon)
    local Tab = Window:CreateTab("Mining Test", 4483362458)

    -- 2. Creăm o secțiune
    Tab:CreateSection("Verificare")

    -- 3. Un buton simplu
    Tab:CreateButton({
        Name = "Daca vezi asta, merge!",
        Callback = function()
            print("Buton apasat!")
        end,
    })
    
    Tab:CreateLabel("Conexiunea GitHub -> Roblox este OK.")
end
