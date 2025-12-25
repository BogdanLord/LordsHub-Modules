-- dj_tab_mining.lua
-- Auto Mining + Smart Index Farm + Goblin Cave Auto-Detection

return function(Window, Rayfield, Utils)
   local MiningTab = Window:CreateTab("⛏️ Mining", nil)
   
   MiningTab:CreateSection("Configuration")
   
   local Players = game:GetService("Players")
   local LocalPlayer = Players.LocalPlayer
   local RunService = game:GetService("RunService")
   
   local miningEnabled = false
   local indexFarmEnabled = false
   local selectedRockTypes = {"Boulder"}
   local selectedLocation = "All"
   local selectedIndexAreas = {"All Areas"}
   local miningConnection = nil
   local indexFarmConnection = nil
   local noclipConnection = nil
   local flyConnection = nil
   local currentTargetRock = nil
   local isMovingToRock = false
   local flySpeed = 60
   local bodyVelocity = nil
   local bodyGyro = nil
   local characterAddedConnection = nil
   local rockStartTime = 0
   local ROCK_TIMEOUT = 360
   local currentRockTypeIndex = 1
   local lastIndexCheck = 0
   local INDEX_CHECK_INTERVAL = 5
   local cachedUnlockedItems = {}
   local cachedLockedItems = {}
   local availableIndexAreas = {"All Areas"}
   local totalDamageDone = 0
   local currentTargetOre = nil
   local currentPickaxePower = 4
   local currentPickaxeName = "Unknown"
   local rockNotFoundCount = 0
   local MAX_ROCK_NOT_FOUND = 10
   local shouldStopMining = false
   local wasAutoStarted = false
   local statusLabel = nil
   local atRockPosition = false
   
   -- 🎰 GOBLIN CAVE AUTO-DETECTION (BASED ON ACTUAL SIZE: 203x1x362)
   local goblinCaveExists = false
   local goblinCaveUnlocked = false
   local GOBLIN_CAVE_BOUNDS = {
      -- Basierend auf Size 203.464, 1, 362.453 mit Sicherheitspuffer
      Min = Vector3.new(40, 15, -410),   -- X buffer ~100, Z buffer ~180
      Max = Vector3.new(260, 75, -20)    -- X buffer ~100, Z buffer ~180
   }
   
   -- PICKAXE DATA
   local PickaxeData = {
      ["Stone Pickaxe"] = {MinePower = 4, Ore = "Stone"},
      ["Bronze Pickaxe"] = {MinePower = 7, Ore = "Copper"},
      ["Iron Pickaxe"] = {MinePower = 10, Ore = "Iron"},
      ["Gold Pickaxe"] = {MinePower = 16, Ore = "Gold"},
      ["Stonewake's Pickaxe"] = {MinePower = 33, Ore = "Stone"},
      ["Platinum Pickaxe"] = {MinePower = 24, Ore = "Platinum"},
      ["Arcane Pickaxe"] = {MinePower = 115, Ore = "Starite"},
      ["Cobalt Pickaxe"] = {MinePower = 40, Ore = "Cobalt"},
      ["Titanium Pickaxe"] = {MinePower = 55, Ore = "Titanium"},
      ["Uranium Pickaxe"] = {MinePower = 67, Ore = "Uranium"},
      ["Mythril Pickaxe"] = {MinePower = 80, Ore = "Mythril"},
      ["Lightite Pickaxe"] = {MinePower = 100, Ore = "Lightite"},
      ["Magma Pickaxe"] = {MinePower = 135, Ore = "Magmaite"},
      ["Demonic Pickaxe"] = {MinePower = 180, Ore = "Demonite"}
   }
   
   -- ROCK DATA
   local RockData = {
      Pebble = {Ores = {"Stone", "Sand Stone", "Copper", "Iron", "Poopite"}, Health = 14, RequiredDamage = 4, LuckBoost = 0},
      Rock = {Ores = {"Sand Stone", "Copper", "Iron", "Tin", "Silver", "Poopite", "Bananite", "Cardboardite", "Mushroomite"}, Health = 45, RequiredDamage = 7, LuckBoost = 0.5},
      Boulder = {Ores = {"Copper", "Iron", "Tin", "Silver", "Gold", "Platinum", "Poopite", "Bananite", "Cardboardite", "Mushroomite", "Aite"}, Health = 100, RequiredDamage = 13, LuckBoost = 1},
      ["Lucky Block"] = {Ores = {"Fichillium", "Fichilliugeromoriteite"}, Health = 10000, RequiredDamage = 1, LuckBoost = 100},
      ["Basalt Rock"] = {Ores = {"Silver", "Gold", "Platinum", "Cobalt", "Titanium", "Lapis Lazuli", "Eye Ore"}, Health = 250, RequiredDamage = 16, LuckBoost = 5},
      ["Basalt Core"] = {Ores = {"Cobalt", "Titanium", "Lapis Lazuli", "Quartz", "Amethyst", "Topaz", "Diamond", "Sapphire", "Cuprite", "Emerald", "Eye Ore"}, Health = 750, RequiredDamage = 39, LuckBoost = 7},
      ["Basalt Vein"] = {Ores = {"Quartz", "Amethyst", "Topaz", "Diamond", "Sapphire", "Cuprite", "Emerald", "Ruby", "Rivalite", "Uranium", "Mythril", "Eye Ore", "Lightite"}, Health = 2750, RequiredDamage = 78, LuckBoost = 8},
      ["Volcanic Rock"] = {Ores = {"Volcanic Rock", "Topaz", "Cuprite", "Rivalite", "Obsidian", "Eye Ore", "Fireite", "Magmaite", "Demonite", "Darkryte"}, Health = 4500, RequiredDamage = 100, LuckBoost = 8},
      ["Earth Crystal"] = {Ores = {"Blue Crystal", "Crimson Crystal", "Green Crystal", "Magenta Crystal", "Orange Crystal", "Rainbow Crystal", "Arcane Crystal"}, Health = 5005, RequiredDamage = 78, LuckBoost = 10},
      ["Cyan Crystal"] = {Ores = {"Blue Crystal", "Crimson Crystal", "Green Crystal", "Magenta Crystal", "Orange Crystal", "Rainbow Crystal", "Arcane Crystal"}, Health = 5005, RequiredDamage = 78, LuckBoost = 5},
      ["Crimson Crystal"] = {Ores = {"Blue Crystal", "Crimson Crystal", "Green Crystal", "Magenta Crystal", "Orange Crystal", "Rainbow Crystal", "Arcane Crystal"}, Health = 5005, RequiredDamage = 78, LuckBoost = 5},
      ["Violet Crystal"] = {Ores = {"Blue Crystal", "Crimson Crystal", "Green Crystal", "Magenta Crystal", "Orange Crystal", "Rainbow Crystal", "Arcane Crystal"}, Health = 5335, RequiredDamage = 78, LuckBoost = 5},
      ["Light Crystal"] = {Ores = {"Blue Crystal", "Crimson Crystal", "Green Crystal", "Magenta Crystal", "Orange Crystal", "Rainbow Crystal", "Arcane Crystal"}, Health = 5005, RequiredDamage = 78, LuckBoost = 5}
   }
   
   local rockLocations = {"All", "Island1CaveDeep", "Island1CaveMid", "Island1CaveStart", "Roof", "Island2CaveDanger1", "Island2CaveDanger2", "Island2CaveDanger3", "Island2CaveDanger4", "Island2CaveDangerClosed", "Island2CaveDeep", "Island2CaveLavaClosed", "Island2CaveMid", "Island2CaveStart", "Island2GoblinCave", "Island2VolcanicDepths"}
   local rockTypes = {"Rock", "Boulder", "Pebble", "Lucky Block", "Light Crystal", "Volcanic Rock", "Basalt Core", "Basalt Rock", "Basalt Vein", "Violet Crystal", "Earth Crystal", "Cyan Crystal", "Crimson Crystal"}
   
   -- 🔍 GOBLIN CAVE DETECTION
   local function detectGoblinCave()
      local workspace = game:GetService("Workspace")
      local debris = workspace:FindFirstChild("Debris")
      
      if debris then
         local regions = debris:FindFirstChild("Regions")
         if regions and regions:FindFirstChild("Goblin Cave") then
            return true
         end
         
         local mobSpawns = debris:FindFirstChild("MobSpawns")
         if mobSpawns and mobSpawns:FindFirstChild("GoblinCave") then
            return true
         end
      end
      
      local rocksFolder = workspace:FindFirstChild("Rocks")
      if rocksFolder and rocksFolder:FindFirstChild("Island2GoblinCave") then
         return true
      end
      
      local living = workspace:FindFirstChild("Living")
      if living then
         for _, entity in pairs(living:GetChildren()) do
            if entity.Name:lower():find("goblin") then
               return true
            end
         end
      end
      
      return false
   end
   
   -- 🎰 GOBLIN CAVE FUNCTIONS
   local function isInGoblinCave(position)
      return position.X >= GOBLIN_CAVE_BOUNDS.Min.X and position.X <= GOBLIN_CAVE_BOUNDS.Max.X
         and position.Y >= GOBLIN_CAVE_BOUNDS.Min.Y and position.Y <= GOBLIN_CAVE_BOUNDS.Max.Y
         and position.Z >= GOBLIN_CAVE_BOUNDS.Min.Z and position.Z <= GOBLIN_CAVE_BOUNDS.Max.Z
   end
   
   local function pathIntersectsGoblinCave(startPos, endPos)
      if not goblinCaveExists or goblinCaveUnlocked then
         return false
      end
      
      -- Check 15 points along the path for better detection
      for i = 0, 14 do
         local t = i / 14
         local checkPoint = startPos:Lerp(endPos, t)
         if isInGoblinCave(checkPoint) then
            return true
         end
      end
      
      return false
   end
   
   local function getBypassWaypoint(currentPos, targetPos)
      if not goblinCaveExists or goblinCaveUnlocked then
         return targetPos
      end
      
      -- Check if path intersects goblin cave
      if not pathIntersectsGoblinCave(currentPos, targetPos) then
         return targetPos
      end
      
      -- Calculate bypass waypoint FAR ABOVE the cave
      local bypassY = GOBLIN_CAVE_BOUNDS.Max.Y + 60  -- Deutlich höher
      local waypointPos = Vector3.new(
         (currentPos.X + targetPos.X) / 2,
         bypassY,
         GOBLIN_CAVE_BOUNDS.Min.Z - 100  -- Noch weiter weg
      )
      
      return waypointPos
   end
   
   -- Detect Goblin Cave on startup (silent mode)
   task.spawn(function()
      task.wait(2)
      goblinCaveExists = detectGoblinCave()
   end)
   
   -- UPDATE STATUS LABEL
   local function updateStatusLabel(text)
      if statusLabel then
         statusLabel:Set(text)
      end
   end
   
   -- CHECK IF ROCK EXISTS ON MAP
   local function isRockAvailable(rockType)
      local rocksFolder = workspace:FindFirstChild("Rocks")
      if not rocksFolder then return false end
      for _, locationFolder in pairs(rocksFolder:GetChildren()) do
         for _, child in pairs(locationFolder:GetChildren()) do
            if child.Name == "SpawnLocation" and child:FindFirstChild(rockType) then
               return true
            end
         end
      end
      return false
   end
   
   -- PICKAXE DETECTION (silent mode)
   local function detectPlayerPickaxe()
      local success = pcall(function()
         local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
         if not playerGui then return end
         local backpackGui = playerGui:FindFirstChild("BackpackGui")
         if not backpackGui then return end
         local backpack = backpackGui:FindFirstChild("Backpack")
         if not backpack then return end
         local hotbar = backpack:FindFirstChild("Hotbar")
         if not hotbar then return end
         
         for _, slot in pairs(hotbar:GetChildren()) do
            local frame = slot:FindFirstChild("Frame")
            if frame then
               local viewportFrame = frame:FindFirstChild("ViewportFrame")
               if viewportFrame then
                  for _, obj in pairs(viewportFrame:GetChildren()) do
                     if obj.Name:find("Pickaxe") then
                        local pickaxeName = obj.Name
                        local pickaxeInfo = PickaxeData[pickaxeName]
                        if pickaxeInfo then
                           currentPickaxePower = pickaxeInfo.MinePower
                           currentPickaxeName = pickaxeName
                           return
                        else
                           currentPickaxeName = pickaxeName
                           currentPickaxePower = 4
                           return
                        end
                     end
                  end
               end
            end
         end
      end)
      if not success then
         currentPickaxePower = 4
         currentPickaxeName = "Unknown"
      end
   end
   
   -- SMART ROCK SELECTION
   local function getBestRockForOre(oreName, checkAvailability)
      local candidates = {}
      for rockType, data in pairs(RockData) do
         for _, ore in pairs(data.Ores) do
            if ore == oreName then
               local canMine = currentPickaxePower >= data.RequiredDamage
               local available = not checkAvailability or isRockAvailable(rockType)
               table.insert(candidates, {rock = rockType, luckBoost = data.LuckBoost, requiredDamage = data.RequiredDamage, health = data.Health, canMine = canMine, available = available})
               break
            end
         end
      end
      if #candidates == 0 then return nil end
      local viable = {}
      for _, cand in pairs(candidates) do
         if cand.canMine and cand.available then table.insert(viable, cand) end
      end
      if #viable == 0 and not checkAvailability then
         for _, cand in pairs(candidates) do
            if cand.canMine then table.insert(viable, cand) end
         end
      end
      if #viable == 0 then
         table.sort(candidates, function(a, b) return a.requiredDamage < b.requiredDamage end)
         local easiest = candidates[1]
         if checkAvailability and not easiest.available then
            updateStatusLabel("⚠️ Rock not on map: " .. easiest.rock)
            return nil, easiest.requiredDamage, "not_available"
         end
         updateStatusLabel("❌ Not enough pickaxe power (need " .. easiest.requiredDamage .. ")")
         return nil, easiest.requiredDamage, "too_weak"
      end
      table.sort(viable, function(a, b) return a.luckBoost > b.luckBoost end)
      local best = viable[1]
      updateStatusLabel("✅ Mining: " .. best.rock)
      return best.rock, best.requiredDamage, "success"
   end
   
   -- INDEX SYSTEM
   local function getIndexGUI()
      local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
      if not playerGui then return nil end
      local menu = playerGui:FindFirstChild("Menu")
      if not menu then return nil end
      local frame = menu:FindFirstChild("Frame")
      if not frame then return nil end
      local frame2 = frame:FindFirstChild("Frame")
      if not frame2 then return nil end
      local menus = frame2:FindFirstChild("Menus")
      if not menus then return nil end
      return menus:FindFirstChild("Index")
   end
   
   local function getOresPage()
      local indexGUI = getIndexGUI()
      if not indexGUI then return nil end
      local pages = indexGUI:FindFirstChild("Pages")
      if not pages then return nil end
      return pages:FindFirstChild("Ores")
   end
   
   local function getAvailableIndexAreas()
      local oresPage = getOresPage()
      if not oresPage then return {"All Areas"} end
      local areas = {"All Areas"}
      for _, child in pairs(oresPage:GetChildren()) do
         if child:IsA("Frame") and not child.Name:find("List") and child.Name ~= "UIListLayout" and child.Name ~= "UIGridLayout" then
            table.insert(areas, child.Name)
         end
      end
      return areas
   end
   
   local function isItemUnlocked(itemFrame)
      if not itemFrame then return false end
      local main = itemFrame:FindFirstChild("Main")
      if not main then return false end
      local itemName = main:FindFirstChild("ItemName")
      if not itemName or not itemName:IsA("TextLabel") then return false end
      return itemName.Text ~= "?"
   end
   
   local function isAreaSelected(areaName)
      for _, selected in pairs(selectedIndexAreas) do
         if selected == "All Areas" or selected == areaName then return true end
      end
      return false
   end
   
   local function detectIndexItems(silent)
      local oresPage = getOresPage()
      if not oresPage then return {}, {} end
      local unlockedItems, lockedItems = {}, {}
      for _, areaFrame in pairs(oresPage:GetChildren()) do
         if areaFrame:IsA("Frame") and not areaFrame.Name:find("List") then
            if isAreaSelected(areaFrame.Name) then
               local areaList = oresPage:FindFirstChild(areaFrame.Name .. " List")
               if areaList then
                  for _, oreFrame in pairs(areaList:GetChildren()) do
                     if oreFrame:IsA("Frame") and oreFrame.Name ~= "UIListLayout" and oreFrame.Name ~= "UIGridLayout" then
                        if isItemUnlocked(oreFrame) then
                           table.insert(unlockedItems, {area = areaFrame.Name, ore = oreFrame.Name})
                        else
                           table.insert(lockedItems, {area = areaFrame.Name, ore = oreFrame.Name})
                        end
                     end
                  end
               end
            end
         end
      end
      return unlockedItems, lockedItems
   end
   
   local function getNextMineableOre(lockedList)
      for _, item in pairs(lockedList) do
         local bestRock, reqDamage, status = getBestRockForOre(item.ore, true)
         if status == "success" and bestRock then
            return item, bestRock
         end
      end
      if #lockedList > 0 then
         updateStatusLabel("❌ No mineable ores available")
         if Rayfield then
            Rayfield:Notify({Title = "No Mineable Ores!", Content = "Need stronger pickaxe or rocks unavailable", Duration = 5})
         end
      end
      return nil, nil
   end
   
   local function checkForNewUnlocks()
      local newUnlocked, newLocked = detectIndexItems(true)
      local newlyUnlocked = {}
      for _, newItem in pairs(newUnlocked) do
         for _, oldLocked in pairs(cachedLockedItems) do
            if oldLocked.ore == newItem.ore and oldLocked.area == newItem.area then
               table.insert(newlyUnlocked, newItem)
               break
            end
         end
      end
      cachedUnlockedItems, cachedLockedItems = newUnlocked, newLocked
      if #newlyUnlocked > 0 then
         updateStatusLabel("🎉 Unlocked: " .. newlyUnlocked[1].ore)
         shouldStopMining = true
         task.wait(2)
         shouldStopMining = false
         if Rayfield then Rayfield:Notify({Title = "Progress!", Content = "Unlocked: " .. newlyUnlocked[1].ore, Duration = 3}) end
         if #newLocked > 0 then
            local nextItem, bestRock = getNextMineableOre(newLocked)
            if bestRock and nextItem then
               currentTargetOre = nextItem.ore
               selectedRockTypes = {bestRock}
               rockNotFoundCount = 0
            end
         end
      end
      return newUnlocked, newLocked
   end
   
   local function startIndexFarm()
      if indexFarmConnection then indexFarmConnection:Disconnect() end
      detectPlayerPickaxe()
      if Rayfield then Rayfield:Notify({Title = "Index Farm", Content = "Pickaxe: " .. currentPickaxeName .. " (" .. currentPickaxePower .. ")", Duration = 4}) end
      local unlocked, locked = detectIndexItems(false)
      cachedUnlockedItems, cachedLockedItems = unlocked, locked
      if #locked == 0 then
         updateStatusLabel("✅ Index complete!")
         if Rayfield then Rayfield:Notify({Title = "Complete!", Content = "All unlocked!", Duration = 5}) end
         indexFarmEnabled = false
         return
      end
      local firstItem, bestRock = getNextMineableOre(locked)
      if not bestRock then indexFarmEnabled = false; return end
      currentTargetOre, selectedRockTypes = firstItem.ore, {bestRock}
      rockNotFoundCount = 0
      if Rayfield then Rayfield:Notify({Title = "Farming", Content = bestRock .. " for " .. firstItem.ore, Duration = 4}) end
      lastIndexCheck = tick()
      indexFarmConnection = RunService.Heartbeat:Connect(function()
         if not indexFarmEnabled then return end
         if tick() - lastIndexCheck >= INDEX_CHECK_INTERVAL then
            lastIndexCheck = tick()
            local _, locked = checkForNewUnlocks()
            if #locked == 0 then
               updateStatusLabel("✅ Index complete!")
               if Rayfield then Rayfield:Notify({Title = "Complete!", Content = "All unlocked!", Duration = 5}) end
               indexFarmEnabled = false
            end
         end
      end)
   end
   
   local function stopIndexFarm()
      if indexFarmConnection then indexFarmConnection:Disconnect(); indexFarmConnection = nil end
      cachedUnlockedItems, cachedLockedItems, currentTargetOre = {}, {}, nil
      rockNotFoundCount = 0
      updateStatusLabel("Idle")
   end
   
   -- MINING FUNCTIONS
   local function findNextRock(locationFilter)
      if #selectedRockTypes == 0 then return nil end
      local rocksFolder = workspace:FindFirstChild("Rocks")
      if not rocksFolder then return nil end
      local locationsToSearch = locationFilter == "All" and {unpack(rockLocations, 2)} or {locationFilter}
      for i = 1, #selectedRockTypes do
         local index = ((currentRockTypeIndex - 1 + i - 1) % #selectedRockTypes) + 1
         for _, locationName in ipairs(locationsToSearch) do
            local locationFolder = rocksFolder:FindFirstChild(locationName)
            if locationFolder then
               for _, child in pairs(locationFolder:GetChildren()) do
                  if child.Name == "SpawnLocation" then
                     local rock = child:FindFirstChild(selectedRockTypes[index])
                     if rock then 
                        currentRockTypeIndex = index
                        rockNotFoundCount = 0
                        return rock 
                     end
                  end
               end
            end
         end
      end
      if indexFarmEnabled then
         rockNotFoundCount = rockNotFoundCount + 1
         if rockNotFoundCount >= MAX_ROCK_NOT_FOUND then
            rockNotFoundCount = 0
            local _, locked = detectIndexItems(true)
            if #locked > 0 then
               local nextLocked = {}
               for _, item in pairs(locked) do
                  if item.ore ~= currentTargetOre then table.insert(nextLocked, item) end
               end
               if #nextLocked > 0 then
                  local nextItem, bestRock = getNextMineableOre(nextLocked)
                  if bestRock and nextItem then
                     currentTargetOre, selectedRockTypes = nextItem.ore, {bestRock}
                     if Rayfield then Rayfield:Notify({Title = "Rock Not Found", Content = "Switched to " .. nextItem.ore, Duration = 4}) end
                  end
               end
            end
         end
      end
      return nil
   end
   
   local function enableNoclip()
      if noclipConnection then return end
      noclipConnection = RunService.Stepped:Connect(function()
         if not miningEnabled then return end
         local character = LocalPlayer.Character
         if character then
            for _, part in pairs(character:GetDescendants()) do
               if part:IsA("BasePart") then part.CanCollide = false end
            end
         end
      end)
   end
   
   local function disableNoclip()
      if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
      local character = LocalPlayer.Character
      if character then
         for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
         end
      end
   end
   
   local function setupFlyBodies()
      local character = LocalPlayer.Character
      if not character then return false end
      local hrp = character:FindFirstChild("HumanoidRootPart")
      if not hrp then return false end
      for _, obj in pairs(hrp:GetChildren()) do
         if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then obj:Destroy() end
      end
      bodyVelocity = Instance.new("BodyVelocity")
      bodyVelocity.Velocity = Vector3.new(0, 0, 0)
      bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
      bodyVelocity.Parent = hrp
      bodyGyro = Instance.new("BodyGyro")
      bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
      bodyGyro.P = 9e4
      bodyGyro.Parent = hrp
      return true
   end
   
   local function enableFly()
      if flyConnection then return end
      if not setupFlyBodies() then task.wait(0.5); setupFlyBodies() end
      flyConnection = RunService.Heartbeat:Connect(function()
         if not miningEnabled or not bodyVelocity or not bodyGyro then return end
         local char = LocalPlayer.Character
         if not char then return end
         local hrp = char:FindFirstChild("HumanoidRootPart")
         if not hrp then return end
         if isMovingToRock and currentTargetRock then
            local hitbox = currentTargetRock:FindFirstChild("Hitbox")
            -- FLY BELOW THE ROCK (Y-5.5) to stay in hitbox range
            local targetPos = (hitbox and hitbox:IsA("BasePart")) and hitbox.Position - Vector3.new(0, 5.5, 0) or nil
            if not targetPos then
               local rockPart = currentTargetRock.PrimaryPart or currentTargetRock:FindFirstChildWhichIsA("BasePart")
               if rockPart then targetPos = rockPart.Position - Vector3.new(0, 5.5, 0) end
            end
            if targetPos then
               local waypointPos = getBypassWaypoint(hrp.Position, targetPos)
               local direction = (waypointPos - hrp.Position).Unit
               local distance = (waypointPos - hrp.Position).Magnitude
               if distance > 2 then
                  bodyVelocity.Velocity = direction * math.min(distance * 2, math.min(flySpeed, 60))
                  bodyGyro.CFrame = CFrame.new(hrp.Position, waypointPos)
                  atRockPosition = false
               else
                  -- STOP MOVEMENT when at rock
                  bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                  isMovingToRock = false
                  atRockPosition = true
               end
            end
         else
            -- Keep stationary when not moving
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
         end
      end)
   end
   
   local function disableFly()
      if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
      if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
      if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
      atRockPosition = false
   end
   
   local function moveToRock(rock)
      if not rock then return false end
      if rock ~= currentTargetRock then
         rockStartTime = tick()
         if indexFarmEnabled and currentTargetRock then
            local rockData = RockData[currentTargetRock.Name]
            if rockData then totalDamageDone = totalDamageDone + rockData.Health end
         end
      end
      currentTargetRock, isMovingToRock, atRockPosition = rock, true, false
      return true
   end
   
   local function activateMiningTool()
      if not miningEnabled or shouldStopMining then return end
      task.spawn(function()
         pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Shared", 1):WaitForChild("Packages", 1):WaitForChild("Knit", 1):WaitForChild("Services", 1):WaitForChild("ToolService", 1):WaitForChild("RF", 1):WaitForChild("ToolActivated", 1):InvokeServer("Pickaxe")
         end)
      end)
   end
   
   local function isRockValid(rock)
      return rock and rock.Parent and (tick() - rockStartTime <= ROCK_TIMEOUT)
   end
   
   local function startMining()
      if miningConnection then miningConnection:Disconnect() end
      enableNoclip()
      task.wait(0.1)
      enableFly()
      if Rayfield then Rayfield:Notify({Title = "Mining", Content = "Mining: " .. table.concat(selectedRockTypes, ", "), Duration = 3}) end
      local searchTick = 0
      local newRock = findNextRock(selectedLocation)
      if newRock then moveToRock(newRock) end
      miningConnection = RunService.Heartbeat:Connect(function()
         if not miningEnabled then return end
         searchTick = searchTick + 1
         if not isRockValid(currentTargetRock) or searchTick >= 60 then
            searchTick = 0
            local rock = findNextRock(selectedLocation)
            if rock and rock ~= currentTargetRock then moveToRock(rock) end
         end
         activateMiningTool()
      end)
   end
   
   local function stopMining()
      if miningConnection then miningConnection:Disconnect(); miningConnection = nil end
      disableNoclip()
      disableFly()
      currentTargetRock, isMovingToRock, rockStartTime, currentRockTypeIndex = nil, false, 0, 1
      rockNotFoundCount = 0
      shouldStopMining = false
      atRockPosition = false
   end
   
   local function setupRespawnHandler()
      if characterAddedConnection then characterAddedConnection:Disconnect() end
      characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
         if miningEnabled then
            task.wait(1); disableFly(); task.wait(0.5); enableNoclip(); task.wait(0.1); enableFly()
            currentTargetRock, isMovingToRock, atRockPosition = nil, false, false
            local newRock = findNextRock(selectedLocation)
            if newRock then moveToRock(newRock) end
         end
      end)
   end
   
   setupRespawnHandler()
   task.spawn(function() task.wait(2); availableIndexAreas = getAvailableIndexAreas() end)
   
   -- UI
   MiningTab:CreateDropdown({Name = "Location", Options = rockLocations, CurrentOption = {"All"}, MultipleOptions = false, Flag = "MiningLocation", Callback = function(Options) selectedLocation = Options[1] or "All" end})
   MiningTab:CreateDropdown({Name = "Rock Types (Multi-Select)", Options = rockTypes, CurrentOption = {"Boulder"}, MultipleOptions = true, Flag = "MiningRockTypes", Callback = function(Options) if not indexFarmEnabled then selectedRockTypes = (#Options == 0) and {"Boulder"} or Options; currentRockTypeIndex = 1 end end})
   MiningTab:CreateSlider({Name = "Fly Speed", Range = {30, 60}, Increment = 5, Suffix = "Speed", CurrentValue = 60, Flag = "MiningFlySpeed", Callback = function(Value) flySpeed = Value end})
   
   MiningTab:CreateSection("🎰 Goblin Cave")
   MiningTab:CreateToggle({Name = "🎰 Goblin Cave Unlocked?", CurrentValue = false, Flag = "GoblinCaveUnlocked", Callback = function(value) goblinCaveUnlocked = value end})
   MiningTab:CreateLabel("This feature evades the goblin cave to make auto farm better. If you have unlocked the goblin cave activate this.")
   
   MiningTab:CreateSection("Control")
   MiningTab:CreateToggle({Name = "Auto Mining", CurrentValue = false, Flag = "AutoMining", Callback = function(enabled) miningEnabled = enabled; if enabled then startMining() else stopMining() end end})
   MiningTab:CreateSection("Mining Index")
   local indexAreasDropdown = MiningTab:CreateDropdown({Name = "Index Areas", Options = availableIndexAreas, CurrentOption = {"All Areas"}, MultipleOptions = true, Flag = "IndexAreas", Callback = function(Options) selectedIndexAreas = (#Options == 0) and {"All Areas"} or Options end})
   MiningTab:CreateButton({Name = "🔄 Refresh Areas", Callback = function() availableIndexAreas = getAvailableIndexAreas(); indexAreasDropdown:Refresh(availableIndexAreas, true); if Rayfield then Rayfield:Notify({Title = "Refreshed", Content = "Found " .. (#availableIndexAreas - 1) .. " areas", Duration = 3}) end end})
   
   MiningTab:CreateToggle({
      Name = "Auto Finish Mining Index", 
      CurrentValue = false, 
      Flag = "AutoFinishMiningIndex", 
      Callback = function(enabled) 
         indexFarmEnabled = enabled
         if enabled then 
            startIndexFarm()
            if not miningEnabled then 
               miningEnabled = true
               wasAutoStarted = true
               startMining()
            end 
         else 
            stopIndexFarm()
            if wasAutoStarted and miningEnabled then
               miningEnabled = false
               stopMining()
               wasAutoStarted = false
            end
         end 
      end
   })
   
   MiningTab:CreateSection("Status")
   statusLabel = MiningTab:CreateLabel("Idle")
   
   MiningTab:CreateParagraph({Title = "🎯 Smart Index", Content = "Auto pickaxe detection\nBest rock selection\nAuto-switch if not found\nStops mining on unlock"})
   MiningTab:CreateParagraph({Title = "⛏️ Features", Content = "13 Rocks | 14 Pickaxes\n17 Locations\nGoblin Cave Auto-Detect"})
   
   print("[MINING] ✅ Ready!")
   
   game:GetService("Players").PlayerRemoving:Connect(function(player)
      if player == LocalPlayer then stopMining(); stopIndexFarm(); if characterAddedConnection then characterAddedConnection:Disconnect() end end
   end)
end
