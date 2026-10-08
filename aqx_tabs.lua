--[[ aqx tabs — builds all tabs ]]

local A=getgenv().aqx
assert(A and A.Modules3Loaded,"aqx modules3 not loaded")
local Players=A.Players local RS=A.RS local LP=A.LP

-- PLAYER
local tp=A.makeTab("Player")

local g=tp:AddGroup("Local Player")
g:AddToggle("aqxFPSBoost",{Text="FPS Boost (Low Graphics)",Default=false,Callback=function(s)
    if s then
        for _,o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") then pcall(function() o.Material=Enum.Material.Plastic o.CastShadow=false end)
            elseif o:IsA("Decal") or o:IsA("Texture") then pcall(function() o.Transparency=1 end)
            elseif o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam")
                or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("PostEffect") then
                pcall(function() o.Enabled=false end) end
        end
        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
        A.notify("FPS Boost","Low graphics enabled.")
    else A.notify("FPS Boost","Reload to fully restore.") end
end})
g:AddToggle("aqxInfSleep",{Text="Infinite Sleep",Default=false,Callback=function(s)
    local sg=A.PG:FindFirstChild("SleepGui")
    local ss=sg and sg:FindFirstChild("Frame") and sg.Frame:FindFirstChild("sleep")
        and sg.Frame.sleep:FindFirstChild("SleepBar") and sg.Frame.sleep.SleepBar:FindFirstChild("sleepScript")
    if ss then ss.Enabled=not s end
end})
g:AddToggle("aqxInfHunger",{Text="Infinite Hunger",Default=false,Callback=function(s)
    local hg=A.PG:FindFirstChild("Hunger")
    local hs=hg and hg:FindFirstChild("Frame") and hg.Frame:FindFirstChild("Frame")
        and hg.Frame.Frame:FindFirstChild("Frame") and hg.Frame.Frame.Frame:FindFirstChild("HungerBarScript")
    if hs then hs.Enabled=not s end
end})
g:AddToggle("aqxInfStamina",{Text="Infinite Stamina",Default=false,Callback=function(s)
    local rg=A.PG:FindFirstChild("Run")
    local ss=rg and rg:FindFirstChild("Frame") and rg.Frame:FindFirstChild("Frame")
        and rg.Frame.Frame:FindFirstChild("Frame") and rg.Frame.Frame.Frame:FindFirstChild("StaminaBarScript")
    if ss then ss.Enabled=not s end
end})
g:AddToggle("aqxInstantInt",{Text="Instant Interaction",Default=false,Callback=function(s) A.refreshPrompts(s) end})
g:AddToggle("aqxStealLoot",{Text="Auto Steal Lootbags",Default=false,Callback=function(s) A.AutoStealLootbags=s end})
g:AddToggle("aqxPickupBags",{Text="Auto Pickup Bags",Default=false,Callback=function(s) A.AutoPickupBags=s end})
g:AddToggle("aqxNoBlood",{Text="Disable Blood Effects",Default=false,Callback=function(s) A.DisableBloodEffects=s end})
g:AddToggle("aqxBypassCars",{Text="Bypass Locked Cars",Default=false,Callback=function(s) A.BypassLockedCars=s end})
g:AddToggle("aqxAutoGrab",{Text="Auto Steal Dropped Cash",Default=false,Callback=function(s) A.AutoGrabMoney=s end})
g:AddToggle("aqxAntiFling",{Text="Anti Car Fling",Default=false,Callback=function(s)
    if s then A.StartAntiCarFling() else A.StopAntiCarFling() end
end})
g:AddToggle("aqxAntiJumpCD",{Text="Anti Jump Cooldown",Default=false,Callback=function(s)
    A.SetAntiJumpCooldownEnabled(s)
end})
g:AddToggle("aqxAntiAFK",{Text="Anti-AFK",Default=false,Callback=function(s) A.AntiAFKEnabled=s end})

local g=tp:AddGroup("Movement")
g:AddToggle("aqxNoBob",{Text="Disable Camera Bobbing",Default=false,Callback=function(s) A.NoCameraBob=s end})
g:AddToggle("aqxWalk",{Text="WalkSpeed",Default=false,Callback=function(s)
    if s then A.LuhjayyWalkStart() else A.LuhjayyWalkStop() end
end})
g:AddSlider("aqxWalkSpeed",{Text="Walk Speed",Min=16,Max=500,Default=16,Callback=function(v) A.LuhjayyWalk.Speed=v end})
g:AddToggle("aqxJumpBoost",{Text="Jump Boost",Default=false,Callback=function(s) A.updateJumpBoostState(s) end})
g:AddToggle("aqxInfJump",{Text="Infinite Jump",Default=false,Callback=function(s) A.InfJumpEnabled=s end})
g:AddToggle("aqxNoclip",{Text="Noclip",Default=false,Callback=function(s)
    A.NoclipEnabled=s if s then A.enableNoclip() else A.disableNoclip() end
end})
g:AddToggle("aqxFly",{Text="Fly",Default=false,Callback=function(s)
    if s then A.MiamiFlySetup() else A.MiamiFlyCleanup() end
end})
g:AddSlider("aqxFlySpeed",{Text="Fly Speed",Min=20,Max=300,Default=80,Callback=function(v)
    A.MiamiFlyData.Speed=v
end})

local g=tp:AddGroup("Misc")
g:AddToggle("aqxFaster",{Text="Faster Respawn",Default=false,Callback=function(s) A.FasterRespawn=s end})
g:AddToggle("aqxRespawnWhere",{Text="Respawn Where You Died",Default=false,Callback=function(s) A.RespawnWhereYouDied=s end})
g:AddToggle("aqxKeepTools",{Text="Keep Tools On Death",Default=false,Callback=function(s) A.KeepToolsOnDeath=s end})
g:AddToggle("aqxAutoHelp",{Text="Auto Get Help",Default=false,Callback=function(s) A.AutoFOnLowHealth=s end})

local g=tp:AddGroup("Money")
g:AddButton("Inf Money (hold cupz)",function()
    A.notify("Inf Money","Triggered.")
    task.spawn(function() pcall(A.InfMoneyHoldCupz) end)
end)
g:AddButton("Generate Max Illegal Money",function()
    A.notify("Illegal Money","Generating...")
    task.spawn(function() pcall(A.GenerateMaxIllegalMoney) end)
end)
g:AddButton("Teleport [COOK POT]",A.TeleportToCookPot)
g:AddButton("Buy Ice-Fruit [ITEMS]",function()
    A.notify("Buy Items","Buying...") A.SetupInfiniteMoney()
end)
g:AddButton("Clean All Filthy Money",A.CleanAllFilthyMoney)
g:AddToggle("aqxDrop10k",{Text="Auto Drop 10k",Default=false,Callback=function(s) A.MoneyDropEnabled=s end})

local g=tp:AddGroup("Quick Buy")
local function qb(name,item,cat)
    task.spawn(function()
        local ok,b,p=pcall(A.qbDoBuy,item,cat)
        if ok and b then A.notify("Quick Buy",name.." purchased")
        else A.notify("Quick Buy","Failed: "..tostring(ok and p or b)) end
    end)
end
g:AddButton("Buy BagElite",function() qb("BagElite","BagElite","BAGS") end)
g:AddButton("Buy Draco",function() qb("Draco","Draco","OTHER") end)
g:AddButton("Buy Shiesty",function() qb("Shiesty","Shiesty","MAIN SHOP") end)
g:AddButton("Buy Lemonade",function() qb("Lemonade","Lemonade","EXOTIC") end)
g:AddButton("Buy Bandage",function() qb("Bandage","Bandage","EXOTIC") end)

local g=tp:AddGroup("Bank / ATM")
g:AddInput("aqxWithdraw",{Text="Withdraw Amount",Placeholder="Max 90,000",Numeric=true,Callback=function(v)
    local a=tonumber(v)
    if a and a>0 and a<=90000 then
        pcall(function() RS.BankAction:FireServer("with",a) end)
        A.notify("Withdraw","Withdrew $"..a)
    end
end})
g:AddInput("aqxDeposit",{Text="Deposit Amount",Placeholder="Max 30,000",Numeric=true,Callback=function(v)
    local a=tonumber(v)
    if a and a>0 and a<=30000 then
        pcall(function() RS.BankAction:FireServer("depo",a) end)
        A.notify("Deposit","Deposited $"..a)
    end
end})

-- MAIN
local tm=A.makeTab("Main")
local g=tm:AddGroup("Target")
local TPN=A.getTargetPlayerList()
A.TargetUtilities.SelectedPlayer=TPN[1] or ""
local tdd=g:AddDropdown("aqxTargetPlayer",{Text="Select Player",Values=TPN,
    Default=A.TargetUtilities.SelectedPlayer,
    Callback=function(v) A.TargetUtilities.SelectedPlayer=tostring(v) end})
g:AddButton("Refresh Player List",function()
    TPN=A.getTargetPlayerList()
    if tdd then tdd:SetValues(TPN) end
    A.notify("Target","Refreshed: "..#TPN)
end)
g:AddButton("Pass to Nearest Player",function()
    pcall(function()
        RS.DropRemote:FireServer("Drop")
        A.notify("Pass","Passed to nearest.")
    end)
end)
g:AddToggle("aqxSpectate",{Text="Spectate Player",Default=false,Callback=function(s) A.TargetUtilities.SpectatePlayer=s end})
g:AddToggle("aqxBringNearest",{Text="Bring Nearest Player",Default=false,Callback=function(s) A.TargetUtilities.BringingNearestPlayer=s end})
g:AddToggle("aqxBringPlayer",{Text="Bring Player",Default=false,Callback=function(s) A.TargetUtilities.BringingPlayer=s end})
g:AddToggle("aqxAutoKill",{Text="Auto Kill Player - Gun",Default=false,Callback=function(s) A.TargetUtilities.AutoKill=s end})
g:AddButton("Car Fling Selected Player",A.CarFlingSelectedPlayer)
g:AddToggle("aqxAutoRagdoll",{Text="Auto Ragdoll Player - Gun",Default=false,Callback=function(s) A.TargetUtilities.AutoRagdoll=s end})
g:AddButton("Teleport To Player",function()
    local t=A.getSelectedTargetPlayer()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        A.TP(t.Character.HumanoidRootPart.CFrame*CFrame.new(3,0,0))
    else A.notify("Target","No valid target.") end
end)
g:AddButton("God Player - Hold Gun",function()
    local t=A.getSelectedTargetPlayer()
    if t then A.targetGunRemote(t.Name,"HumanoidRootPart",math.huge)
    else A.notify("Target","No valid target.") end
end)

local g=tm:AddGroup("Vehicle")
g:AddToggle("aqxCarFly",{Text="Car Fly",Default=false,Callback=function(s)
    if s then A.StartCarFly() else A.StopCarFly() end
end})
g:AddSlider("aqxCarFlySpeed",{Text="Car Fly Speed",Min=20,Max=300,Default=120,Callback=function(v)
    A.Config.TheBronx.carflyspeed=v A.CarFly.Speed=v
end})
g:AddToggle("aqxVehSpeed",{Text="Vehicle Speed Boost",Default=false,Callback=function(s) A.VehicleModifications.SpeedEnabled=s end})
g:AddSlider("aqxVehSpeedVal",{Text="Speed Multiplier",Min=1,Max=25,Default=5,Callback=function(v) A.VehicleModifications.SpeedValue=v/1000 end})
g:AddToggle("aqxVehStop",{Text="Instant Stop (V)",Default=false,Callback=function(s) A.VehicleModifications.InstantStop=s end})
g:AddButton("Bring Nearest Car",function()
    local c=LP.Character if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart") local h=c:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not h then return end
    local car=A.GetNearestCar(hrp)
    if not car then A.notify("Bring Car","No empty cars!") return end
    local s=car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat")
    if not s then return end
    if not car.PrimaryPart then pcall(function() car.PrimaryPart=car:FindFirstChildWhichIsA("BasePart") end) end
    if car.PrimaryPart then
        car:SetPrimaryPartCFrame(hrp.CFrame*CFrame.new(0,0,-6)*CFrame.Angles(0,math.rad(180),0))
    else
        s.CFrame=hrp.CFrame*CFrame.new(0,0,-6)*CFrame.Angles(0,math.rad(180),0)
    end
    task.wait(0.2) s:Sit(h)
    A.notify("Bring Car","Car brought!")
end)

-- FARM
local tf=A.makeTab("Farm")
local g=tf:AddGroup("Autofarms")
local df=false
g:AddButton("Dumpster Autofarm",function()
    if not df then df=true A.startDumpsterAutofarm() A.notify("Autofarm","Dumpster started.")
    else df=false A.stopDumpsterAutofarm() A.notify("Autofarm","Dumpster stopped.") end
end)
local cf2=false
g:AddButton("Construction Autofarm",function()
    if not cf2 then cf2=true A.startConstructionAutofarm() A.notify("Autofarm","Construction started.")
    else cf2=false A.stopConstructionAutofarm() A.notify("Autofarm","Construction stopped.") end
end)
local g=tf:AddGroup("Quick TPs")
local selTP=A.teleportNames[1]
g:AddDropdown("aqxTpLoc",{Text="Location",Values=A.teleportNames,Default=selTP,
    Callback=function(v) selTP=tostring(v) end})
g:AddButton("Teleport",function()
    local cf3=A.teleportLocations[selTP]
    if cf3 then A.TP(cf3) A.notify("TP","Teleported to "..selTP) end
end)
g:AddButton("Dynamic Cook Pot",A.TeleportToCookPot)

-- EXTRA
local te=A.makeTab("Extra")
local g=te:AddGroup("Emotes")
g:AddDropdown("aqxEmote",{Text="Select Emote",Values=A.MianiEmoteNames,Default="Take The L",
    Callback=function(v) if A.MianiEmotes[v] then A.MianiSelectedEmoteName=v end end})
g:AddButton("Play Selected Emote",function()
    local id=A.MianiEmotes[A.MianiSelectedEmoteName]
    if id then A.MianiPlayEmoteById(id,A.MianiSelectedEmoteName) end
end)
g:AddButton("Stop Emote",function() A.MianiStopAllTracks() A.notify("Emotes","Stopped") end)
g:AddToggle("aqxEmoteLoop",{Text="Loop Emote",Default=true,Callback=function(s)
    A.MianiEmoteSettings.Loop=s
    if A.MianiCurrentEmoteTrack then pcall(function() A.MianiCurrentEmoteTrack.Looped=s end) end
end})
local g=te:AddGroup("Quick Outfits")
g:AddButton("Spiderman",function()
    A.applyOutfit("Spiderman",{{"Buy","Shirts","Spiderman"},{"Wear","Shirts","Spiderman"},
        {"Buy","Pants","Spiderman"},{"Wear","Pants","Spiderman"},
        {"Buy","Shiestys","RedShiesty"},{"Wear","Shiestys","RedShiesty"}})
end)
g:AddButton("All Black",function()
    A.applyOutfit("All Black",{{"Buy","Shirts","Black"},{"Wear","Shirts","Black"},
        {"Buy","Pants","Black"},{"Wear","Pants","Black"},
        {"Buy","Shiestys","BlackShiesty"},{"Wear","Shiestys","BlackShiesty"}})
end)
g:AddToggle("aqxFlashOutfit",{Text="Flash Outfit",Default=false,Callback=function(v)
    A.FlashOutfits=v
    if v then
        A.notify("Outfit","Flash Outfit enabled")
        if A.FlashOutfitLoopRunning then return end
        A.FlashOutfitLoopRunning=true
        task.spawn(function()
            while A.FlashOutfits do
                task.wait(A.OutfitSwapDelay or 0.2)
                for cat,list in pairs(A.RandomClothes) do
                    if not A.FlashOutfits then break end
                    A.ApplyDripstoreClothing(cat,list[math.random(1,#list)])
                end
            end
            A.FlashOutfitLoopRunning=false
        end)
    else A.notify("Outfit","Flash Outfit disabled") end
end})
g:AddSlider("aqxOutfitSpeed",{Text="Flash Swap Delay",Default=0.2,Min=0.0005,Max=2.5,
    Callback=function(v) A.OutfitSwapDelay=v end})

-- GUN MODS
local tg=A.makeTab("Gun Mods")
local g=tg:AddGroup("Weapon Modifications")
local function bt(d,k,f)
    g:AddToggle(f,{Text=d,Default=false,Callback=function(s)
        A.WeaponMods[k]=s
        if k=="InfiniteDamage" then A.WeaponMods.DamageAmplified=s end
        pcall(A.applyAllWeaponMods)
    end})
end
bt("Infinite Ammo","InfiniteAmmo","aqxInfAmmo")
bt("Infinite Clips","InfiniteClips","aqxInfClips")
bt("Infinite Damage","InfiniteDamage","aqxInfDmg")
bt("Instant Reload","InstantReload","aqxInstReload")
bt("Instant Equip","InstantEquip","aqxInstEquip")
bt("80k Bullets","Bullets80k","aqx80k")
bt("Fully Automatic","Automatic","aqxAuto")
bt("Disable Jamming","DisableJamming","aqxNoJam")
bt("Modify Recoil Value","ModifyRecoilValue","aqxRecoil")
bt("Modify Spread Value","ModifySpreadValue","aqxSpread")
bt("Modify Fire Rate","ModifyFireRate","aqxFireRate")
g:AddButton("Force 80k Bullets",A.force80k)

local g=tg:AddGroup("Weapon Settings")
g:AddSlider("aqxReloadSpd",{Text="Reload Speed",Min=0.01,Max=1,Default=0.2,
    Callback=function(v) A.WeaponMods.ReloadSpeed=v pcall(A.applyAllWeaponMods) end})
g:AddSlider("aqxEquipSpd",{Text="Equip Speed",Min=0.01,Max=1,Default=0.2,
    Callback=function(v) A.WeaponMods.EquipSpeed=v pcall(A.applyAllWeaponMods) end})

local g=tg:AddGroup("Gun Color")
g:AddToggle("aqxGunColor",{Text="Enable Gun Color",Default=false,Callback=function(s)
    A.GunChams=s if not s then A.restoreGunColor() end
end})
g:AddToggle("aqxRainbowGun",{Text="Rainbow Gun Color",Default=false,Callback=function(s) A.RainbowGun=s end})
g:AddDropdown("aqxGunColorPick",{Text="Gun Color",
    Values={"Green","Purple","Red","Blue","Pink","Cyan","Yellow","White"},Default="Green",
    Callback=function(v)
        local cols={Green=Color3.fromRGB(0,200,0),Purple=Color3.fromRGB(143,0,255),
            Red=Color3.fromRGB(255,0,0),Blue=Color3.fromRGB(0,120,255),
            Pink=Color3.fromRGB(255,80,180),Cyan=Color3.fromRGB(0,255,255),
            Yellow=Color3.fromRGB(255,255,0),White=Color3.fromRGB(255,255,255)}
        A.GunChamsColor=cols[tostring(v)] or Color3.fromRGB(0,200,0)
    end})

-- VISUALS
local tv=A.makeTab("Visuals")
local g=tv:AddGroup("World")
g:AddToggle("aqxFullbright",{Text="Fullbright",Default=false,Callback=function(v) A.WorldVisuals.Fullbright=v end})
g:AddToggle("aqxSat",{Text="Enable Saturation",Default=false,Callback=function(v) A.WorldVisuals.SaturationEnabled=v end})
g:AddSlider("aqxSatVal",{Text="Saturation Value",Min=0,Max=200,Default=100,
    Callback=function(v) A.WorldVisuals.SaturationValue=v/100 end})
g:AddToggle("aqxFov",{Text="Enable FOV",Default=false,Callback=function(v) A.WorldVisuals.FieldOfViewEnabled=v end})
g:AddSlider("aqxFovVal",{Text="FOV Value",Min=30,Max=120,Default=70,
    Callback=function(v) A.WorldVisuals.FieldOfViewValue=v end})
g:AddToggle("aqxFog",{Text="Enable Fog Color",Default=false,Callback=function(v) A.WorldVisuals.FogColorEnabled=v end})
g:AddDropdown("aqxFogColor",{Text="Fog Color",Values=A.VisualColorNames,Default="White",
    Callback=function(v) A.WorldVisuals.FogColor=A.VisualColorPresets[tostring(v)] or Color3.fromRGB(255,255,255) end})
g:AddToggle("aqxAmbient",{Text="Enable Ambient Tint",Default=false,Callback=function(v) A.WorldVisuals.AmbientEnabled=v end})
g:AddDropdown("aqxAmbientColor",{Text="Ambient Color",Values=A.VisualColorNames,Default="White",
    Callback=function(v) A.WorldVisuals.AmbientColor=A.VisualColorPresets[tostring(v)] or Color3.fromRGB(255,255,255) end})

local g=tv:AddGroup("Player ESP")
g:AddToggle("aqxESP",{Text="ESP Enabled",Default=false,Callback=function(v) A.ESPFlags.Enabled=v end})
g:AddSlider("aqxESPDist",{Text="Render Distance",Min=50,Max=5000,Default=1400,
    Callback=function(v) A.ESPFlags.RenderDistance=v end})
g:AddToggle("aqxESPTeam",{Text="Team Color",Default=true,Callback=function(v) A.ESPFlags.TeamColor=v end})
g:AddToggle("aqxESPBoxes",{Text="Boxes",Default=true,Callback=function(v) A.ESPFlags.Boxes=v end})
g:AddDropdown("aqxESPBoxType",{Text="Box Type",Values={"Corner","Full"},Default="Corner",
    Callback=function(v) A.ESPFlags.BoxType=tostring(v) end})
g:AddDropdown("aqxESPBoxColor",{Text="Box Color",Values=A.VisualColorNames,Default="Orange",
    Callback=function(v) A.ESPFlags.BoxColor=A.VisualColorPresets[tostring(v)] or Color3.fromRGB(255,140,0) end})
g:AddToggle("aqxESPHealth",{Text="Healthbar",Default=true,Callback=function(v) A.ESPFlags.Healthbar=v end})
g:AddToggle("aqxESPChams",{Text="Chams",Default=false,Callback=function(v) A.ESPFlags.Chams=v end})
g:AddToggle("aqxESPName",{Text="Name",Default=true,Callback=function(v) A.ESPFlags.Name=v end})
g:AddToggle("aqxESPDist2",{Text="Distance",Default=true,Callback=function(v) A.ESPFlags.Distance=v end})
g:AddToggle("aqxESPWeapon",{Text="Weapon",Default=false,Callback=function(v) A.ESPFlags.Weapon=v end})
g:AddToggle("aqxESPSnap",{Text="Snaplines",Default=false,Callback=function(v) A.ESPFlags.Snaplines=v end})
g:AddToggle("aqxESPSkel",{Text="Skeleton",Default=false,Callback=function(v) A.ESPFlags.Skeleton=v end})

local g=tv:AddGroup("Hitbox")
g:AddToggle("aqxHitbox",{Text="Enable Hitbox",Default=false,Callback=function(v) A.HitboxVisuals.Enabled=v end})
g:AddDropdown("aqxHitboxPart",{Text="Part",
    Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm",
        "RightUpperArm","RightLowerArm","LeftUpperLeg","LeftLowerLeg","RightUpperLeg","RightLowerLeg"},
    Default="Head",Callback=function(v) A.HitboxVisuals.Part=tostring(v) end})
g:AddSlider("aqxHitboxMult",{Text="Multiplier",Min=1,Max=15,Default=5,
    Callback=function(v) A.HitboxVisuals.Multiplier=v end})
g:AddSlider("aqxHitboxTrans",{Text="Transparency",Min=0,Max=1,Default=0.45,
    Callback=function(v) A.HitboxVisuals.Transparency=v end})
g:AddDropdown("aqxHitboxType",{Text="Type",Values={"Block","Ball","Cylinder"},Default="Block",
    Callback=function(v) A.HitboxVisuals.Type=tostring(v) end})

-- SAFE
local ts=A.makeTab("Safe")
local g=ts:AddGroup("Safe")
local si=A.GetSafeItems()
if #si==0 then si={"(empty - press Refresh)"} end
local ssi=si[1]
local sdd=g:AddDropdown("aqxSafeItem",{Text="Select Safe Item",Values=si,Default=ssi,
    Callback=function(v) ssi=tostring(v) end})
g:AddButton("Refresh Safe List",function()
    local it=A.GetSafeItems()
    if #it==0 then it={"(empty)"} end
    if sdd then sdd:SetValues(it) end
    ssi=it[1] A.notify("Safe","Refreshed: "..#it)
end)
local ta=false
g:AddButton("Take All",function()
    if ta then A.notify("Safe","Already running.") return end
    local it=A.GetSafeItems()
    if #it==0 then A.notify("Safe","Safe is empty.") return end
    ta=true
    task.spawn(function()
        A.notify("Safe","Taking all "..#it.." items...")
        local tk=0
        for _,n in ipairs(it) do
            if not ta then break end
            if A.TakeFromSafe(n) then tk=tk+1 end
            task.wait(0.5)
        end
        ta=false A.notify("Safe","Took "..tk.."/"..#it)
    end)
end)
g:AddButton("Stop Take All",function()
    if ta then ta=false A.notify("Safe","Stop requested.") else A.notify("Safe","Not running.") end
end)

local g=ts:AddGroup("Safe Dupe")
local di=A.GetLockedTools()
table.insert(di,1,"None")
local ddd=g:AddDropdown("aqxDupeItem",{Text="Select Item",Values=di,Default="None",
    Callback=function(v)
        local p=tostring(v)
        if p=="None" or p=="" then A.selectedDupeItem=nil else A.selectedDupeItem=p end
    end})
g:AddButton("Refresh Items",function()
    local it=A.GetLockedTools()
    local l={"None"}
    for _,x in ipairs(it) do table.insert(l,x) end
    if ddd then ddd:SetValues(l) end
    A.selectedDupeItem=nil A.notify("Dupe","Refreshed: "..(#l-1).." tools")
end)
local cda=1
g:AddSlider("aqxDupeAmt",{Text="Custom Dupe Amount",Min=1,Max=15,Default=1,
    Callback=function(v) cda=math.clamp(math.floor(v),1,15) end})
g:AddButton("Run Custom Safe Dupe",function()
    if not A.autoDupeActive then A.DoDupe(cda) else A.notify("Dupe","Already running!") end
end)
g:AddButton("Safe Dupe 15 Times",function()
    if not A.autoDupeActive then A.DoDupe(15) else A.notify("Dupe","Already running!") end
end)
g:AddButton("Stop Safe Dupe",function()
    if A.autoDupeActive then A.autoDupeActive=false A.notify("Dupe","Stop requested.")
    else A.notify("Dupe","Not running.") end
end)
g:AddToggle("aqxAutoDupe",{Text="Auto Safe Dupe (Infinite)",Default=false,Callback=function(s)
    if s then if not A.autoDupeActive then A.DoDupe(math.huge) end
    else if A.autoDupeActive then A.autoDupeActive=false A.notify("Dupe","Stopped") end end
end})
g:AddButton("Safe TP",A.SafeTP)
g:AddToggle("aqxAutoDropTools",{Text="Auto Drop Tools",Default=false,Callback=function(s) A.ToggleAutoDrop(s) end})

local g=ts:AddGroup("Info")
local ssl=g:AddLabel("Safe Status: Ready")
local dcl=g:AddLabel("Total Duped: 0")
local dal=g:AddLabel("Dupe: IDLE")
task.spawn(function()
    while task.wait(5) do
        local sf=A.GetActiveSafe()
        pcall(function() ssl:SetText("Safe Status: "..(sf and "Found" or "Not Found")) end)
        pcall(function() dcl:SetText("Total Duped: "..A.dupeCounter) end)
        pcall(function() dal:SetText("Dupe: "..(A.autoDupeActive and "RUNNING" or "IDLE")) end)
    end
end)

-- SETTINGS
local tst=A.makeTab("Settings")
local g=tst:AddGroup("Head Tag")
local HTS=A.MiamiHeadTagSettings
g:AddToggle("aqxHeadTag",{Text="Enable Head Text",Default=true,Callback=function(v)
    HTS.Enabled=v
    if not v and LP.Character and A.destroyHeadTag then A.destroyHeadTag(LP.Character)
    elseif v and LP.Character and A.attachHeadTag then task.defer(A.attachHeadTag,LP.Character) end
end})
g:AddInput("aqxHeadText",{Text="Text",Default="aqx",Callback=function(v)
    HTS.Text=tostring(v)~="" and tostring(v) or "aqx"
end})
g:AddDropdown("aqxHeadStyle",{Text="Animation",
    Values={"Taco Green","Taco Wave","Rainbow Wave","Fire","Ice","Toxic","Royal"},
    Default="Taco Green",Callback=function(v) HTS.Style=tostring(v) end})
g:AddToggle("aqxHeadPulse",{Text="Text Pulse",Default=true,Callback=function(v) HTS.Pulse=v end})
g:AddSlider("aqxHeadSize",{Text="Text Size",Min=18,Max=52,Default=32,Callback=function(v) HTS.Size=v end})
g:AddSlider("aqxHeadHeight",{Text="Height",Min=2,Max=7,Default=3.4,Callback=function(v) HTS.Height=v end})

local g=tst:AddGroup("Menu")
g:AddButton("Unload UI",function()
    for _,fn in ipairs(A.UnloadCallbacks) do pcall(fn) end
    if A.Gui then A.Gui:Destroy() end
end)
g:AddButton("Rejoin Server",function()
    pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,game.JobId) end)
end)
g:AddButton("Server Hop",function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BENZZY420/SERVERHOP/refs/heads/main/SERVERHOP"))()
end)
g:AddButton("Copy Discord",function()
    if setclipboard then setclipboard("https://discord.gg/tacoscripts") end
    A.notify("Discord","Copied discord.gg/tacoscripts")
end)

task.delay(2,function() A.MiamiSuppressNotifications=false end)
A.notify("aqx","Loaded. Tap the purple a to minimize.",4)
print("[aqx] tabs loaded")
