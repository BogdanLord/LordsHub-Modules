-- [[ DEBUG TEST ]] --
return function(Window, Rayfield, Utils)
    print("DEBUG: 1. Modulul a pornit execuția.")
    
    -- Verificăm dacă Window există
    print("DEBUG: 2. Variabila Window este: " .. tostring(Window))
    
    -- Încercăm să creăm tab-ul într-un pcall ca să prindem eroarea Rayfield
    local success, result = pcall(function()
        -- FOLOSIM UN ID VALID PENTRU IMAGINE (4483362458), NU nil!
        return Window:CreateTab("Tab De Test", 4483362458)
    end)
    
    if success then
        print("DEBUG: 3. Tab creat cu succes! Obiectul este: " .. tostring(result))
        
        -- Adăugăm un buton ca să fim siguri
        result:CreateButton({
            Name = "Daca vezi asta, merge!",
            Callback = function() print("Click!") end
        })
        
        Rayfield:Notify({Title = "Test", Content = "Tab-ul ar trebui să fie vizibil!", Duration = 5})
    else
        warn("DEBUG: 3. CRITIC - Rayfield nu a putut crea tab-ul!")
        warn("Eroare: " .. tostring(result))
    end
end
