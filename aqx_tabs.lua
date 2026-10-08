--[[ aqx tabs — fully organized: Home, Player, Target, Vehicle, Money, Farm, Shop, Combat, Visuals, Safe, Teleport, Extra ]]

local A=getgenv().aqx
assert(A and A.Modules3Loaded,"aqx modules3 not loaded")
local Players=A.Players local RS=A.RS local LP=A.LP

-- ═══════════════════════════════════════════════════════════════
-- HOME
-- ═══════════════════════════════════════════════════════════════
local tHome=A.makeTab("Home")

local g=tHome:AddGroup("Head Tag")
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

local g=tHome:AddGroup("My Money")
local function valueToNumber(o)
    if not o then return nil end
    local ok,v=pcall(function() return o.Value end)
    if ok and tonumber(v) then return tonumber(v) end
end
local function findMoneyValue(c,names,recursive)
    if not c then return nil end
    local lk={} for _,n in ipairs(names) do lk[string.lower(n)]=true end
    for _,ch in ipairs(c:GetChildren()) do
        if lk[string.lower(ch.Name)] then
            local v=valueToNumber(ch) if v~=nil then return v end
        end
    end
    if recursive then
        for _,ch in ipairs(c:GetDescendants()) do
            if lk[string.lower(ch.Name)] then
                local v=valueToNumber(ch) if v~=nil then return v end
            end
        end
    end
end
local function getMyMoneyValues()
    local cN={"Money","Cash","Wallet","Bank","Coins"}
    local dN={"FilthyStack","FilthyMoney","DirtyMoney","DirtyCash","IllegalMoney","Dirty","Filthy"}
    local stored=LP:FindFirstChild("stored") or LP:FindFirstChild("Stored")
    local leader=LP:FindFirstChild("leaderstats") or LP:FindFirstChild("Leaderstats") or LP:FindFirstChild("stats")
    local clean=findMoneyValue(stored,{"Money"},false) or findMoneyValue(leader,cN,false)
        or findMoneyValue(LP,cN,false) or findMoneyValue(LP,cN,true)
    local dirty=findMoneyValue(stored,{"FilthyStack"},false) or findMoneyValue(stored,dN,false)
        or findMoneyValue(LP,dN,false) or findMoneyValue(LP,dN,true)
    return clean,dirty
end
local function getBankValue2()
    local stored=LP:FindFirstChild("stored")
    local leader=LP:FindFirstChild("leaderstats") or LP:FindFirstChild("stats")
    return findMoneyValue(stored,{"Bank"},false) or findMoneyValue(leader,{"Bank"},false)
        or findMoneyValue(LP,{"Bank"},true)
end
local function formatMoney(a)
    local f=tostring(math.floor(tonumber(a) or 0))
    while true do
        local nf,c=f:gsub("^(-?%d+)(%d%d%d)","%1,%2")
        f=nf if c==0 then break end
    end
    return "$"..f
end
local myClean=g:AddLabel("Clean: ...")
local myBank=g:AddLabel("Bank: ...")
local myDirty=g:AddLabel("Dirty: ...")
local myMade=g:AddLabel("Made: $0")
local myLost=g:AddLabel("Lost: $0")
getgenv().MoneyMadeTotal=0
getgenv().MoneyLostTotal=0
local lastClean=nil
task.spawn(function()
    while task.wait(0.3) do
        local c,d=getMyMoneyValues()
        local b=getBankValue2()
        if lastClean~=nil and c~=nil then
            local delta=c-lastClean
            if delta>0 then getgenv().MoneyMadeTotal=getgenv().MoneyMadeTotal+delta
            elseif delta<0 then getgenv().MoneyLostTotal=getgenv().MoneyLostTotal+(-delta) end
        end
        lastClean=c
        pcall(function()
            myClean:SetText("Clean: "..(c~=nil and formatMoney(c) or "..."))
            myBank:SetText("Bank: "..(b~=nil and formatMoney(b) or "..."))
            myDirty:SetText("Dirty: "..(d~=nil and formatMoney(d) or "..."))
            myMade:SetText("Made: "..formatMoney(getgenv().MoneyMadeTotal))
            myLost:SetText("Lost: "..formatMoney(getgenv().MoneyLostTotal))
        end)
    end
end)

local g=tHome:AddGroup("Menu")
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

-- ═══════════════════════════════════════════════════════════════
-- PLAYER
-- ═══════════════════════════════════════════════════════════════
local tPlayer=A.makeTab("Player")

local g=tPlayer:AddGroup("Local Player")
g:AddToggle("aqxFPSBoost",{Text="FPS Boost (Low Graphics)",Default=false,Callback=function(state)
    if state then
        for _,o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                pcall(function() o.Material=Enum.Material.Plastic o.CastShadow=false end)
            elseif o:IsA("Decal") or o:IsA("Texture") then
                pcall(function() o.Transparency=1 end)
            elseif o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam")
                or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("PostEffect") then
                pcall(function() o.Enabled=false end)
            end
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
g:AddToggle("aqxBypassCars",{Text="Bypass Locked Cars",Default=false,Callback=function(s) A.BypassLockedCars=s end})
g:AddToggle("aqxNoBlood",{Text="Disable Blood Effects",Default=false,Callback=function(s) A.DisableBloodEffects=s end})
g:AddToggle("aqxAntiFling",{Text="Anti Car Fling",Default=false,Callback=function(s)
    if s then A.StartAntiCarFling() else A.StopAntiCarFling() end
end})
g:AddToggle("aqxAntiJumpCD",{Text="Anti Jump Cooldown",Default=false,Callback=function(s)
    A.SetAntiJumpCooldownEnabled(s)
end})
g:AddToggle("aqxAntiAFK",{Text="Anti-AFK",Default=false,Callback=function(s) A.AntiAFKEnabled=s end})

local g=tPlayer:AddGroup("Movement")
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

local g=tPlayer:AddGroup("Interactions")
g:AddToggle("aqxStealLoot",{Text="Auto Steal Lootbags",Default=false,Callback=function(s) A.AutoStealLootbags=s end})
g:AddToggle("aqxPickupBags",{Text="Auto Pickup Bags",Default=false,Callback=function(s) A.AutoPickupBags=s end})
g:AddToggle("aqxAutoGrab",{Text="Auto Steal Dropped Cash",Default=false,Callback=function(s) A.AutoGrabMoney=s end})

local g=tPlayer:AddGroup("Respawn")
g:AddToggle("aqxFaster",{Text="Faster Respawn",Default=false,Callback=function(s) A.FasterRespawn=s end})
g:AddToggle("aqxRespawnWhere",{Text="Respawn Where You Died",Default=false,Callback=function(s) A.RespawnWhereYouDied=s end})
g:AddToggle("aqxKeepTools",{Text="Keep Tools On Death",Default=false,Callback=function(s) A.KeepToolsOnDeath=s end})
g:AddToggle("aqxAutoHelp",{Text="Auto Get Help",Default=false,Callback=function(s) A.AutoFOnLowHealth=s end})

-- ═══════════════════════════════════════════════════════════════
-- TARGET
-- ═══════════════════════════════════════════════════════════════
local tTarget=A.makeTab("Target")

local g=tTarget:AddGroup("Select Target")
local TPN=A.getTargetPlayerList()
A.TargetUtilities.SelectedPlayer=TPN[1] or ""
local tdd=g:AddDropdown("aqxTargetPlayer",{Text="Player",Values=TPN,
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

local g=tTarget:AddGroup("Actions")
g:AddToggle("aqxSpectate",{Text="Spectate Player",Default=false,Callback=function(s) A.TargetUtilities.SpectatePlayer=s end})
g:AddToggle("aqxBringNearest",{Text="Bring Nearest Player",Default=false,Callback=function(s) A.TargetUtilities.BringingNearestPlayer=s end})
g:AddToggle("aqxBringPlayer",{Text="Bring Player",Default=false,Callback=function(s) A.TargetUtilities.BringingPlayer=s end})
g:AddButton("Teleport To Player",function()
    local t=A.getSelectedTargetPlayer()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        A.TP(t.Character.HumanoidRootPart.CFrame*CFrame.new(3,0,0))
    else A.notify("Target","No valid target.") end
end)
g:AddButton("Car Fling Selected Player",A.CarFlingSelectedPlayer)

local g=tTarget:AddGroup("Auto Combat")
g:AddToggle("aqxAutoKill",{Text="Auto Kill Player - Gun",Default=false,Callback=function(s) A.TargetUtilities.AutoKill=s end})
g:AddToggle("aqxAutoRagdoll",{Text="Auto Ragdoll Player - Gun",Default=false,Callback=function(s) A.TargetUtilities.AutoRagdoll=s end})
g:AddButton("God Player - Hold Gun",function()
    local t=A.getSelectedTargetPlayer()
    if t then A.targetGunRemote(t.Name,"HumanoidRootPart",math.huge)
    else A.notify("Target","No valid target.") end
end)

-- ═══════════════════════════════════════════════════════════════
-- VEHICLE
-- ═══════════════════════════════════════════════════════════════
local tVeh=A.makeTab("Vehicle")

local g=tVeh:AddGroup("Car Fly")
g:AddToggle("aqxCarFly",{Text="Car Fly",Default=false,Callback=function(s)
    if s then A.StartCarFly() else A.StopCarFly() end
end})
g:AddSlider("aqxCarFlySpeed",{Text="Car Fly Speed",Min=20,Max=300,Default=120,Callback=function(v)
    A.Config.TheBronx.carflyspeed=v A.CarFly.Speed=v
end})

local g=tVeh:AddGroup("Vehicle Mods")
g:AddToggle("aqxVehSpeed",{Text="Vehicle Speed Boost",Default=false,Callback=function(s) A.VehicleModifications.SpeedEnabled=s end})
g:AddSlider("aqxVehSpeedVal",{Text="Speed Multiplier",Min=1,Max=25,Default=5,Callback=function(v) A.VehicleModifications.SpeedValue=v/1000 end})
g:AddToggle("aqxVehStop",{Text="Instant Stop (V)",Default=false,Callback=function(s) A.VehicleModifications.InstantStop=s end})

local g=tVeh:AddGroup("Utilities")
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

-- ═══════════════════════════════════════════════════════════════
-- MONEY
-- ═══════════════════════════════════════════════════════════════
local tMoney=A.makeTab("Money")

local g=tMoney:AddGroup("Money Generation")
g:AddButton("Inf Money (hold cupz)",function()
    A.notify("Inf Money","Triggered.")
    task.spawn(function() pcall(A.InfMoneyHoldCupz) end)
end)
g:AddButton("Generate Max Illegal Money",function()
    A.notify("Illegal Money","Generating...")
    task.spawn(function() pcall(A.GenerateMaxIllegalMoney) end)
end)
g:AddButton("Buy Ice-Fruit [ITEMS]",function()
    A.notify("Buy Items","Buying...") A.SetupInfiniteMoney()
end)
g:AddButton("Clean All Filthy Money",A.CleanAllFilthyMoney)
g:AddToggle("aqxDrop10k",{Text="Auto Drop 10k",Default=false,Callback=function(s) A.MoneyDropEnabled=s end})

local g=tMoney:AddGroup("Bank / ATM")
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

-- ═══════════════════════════════════════════════════════════════
-- FARM
-- ═══════════════════════════════════════════════════════════════
local tFarm=A.makeTab("Farm")

local g=tFarm:AddGroup("Autofarms")
local dumpFlag=false
g:AddButton("Dumpster Autofarm",function()
    if not dumpFlag then
        dumpFlag=true A.startDumpsterAutofarm() A.notify("Autofarm","Dumpster started.")
    else
        dumpFlag=false A.stopDumpsterAutofarm() A.notify("Autofarm","Dumpster stopped.")
    end
end)
local constFlag=false
g:AddButton("Construction Autofarm",function()
    if not constFlag then
        constFlag=true A.startConstructionAutofarm() A.notify("Autofarm","Construction started.")
    else
        constFlag=false A.stopConstructionAutofarm() A.notify("Autofarm","Construction stopped.")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SHOP
-- ═══════════════════════════════════════════════════════════════
local tShop=A.makeTab("Shop")

local function qb(name,item,cat)
    task.spawn(function()
        local ok,b,p=pcall(A.qbDoBuy,item,cat)
        if ok and b then A.notify("Shop",name.." purchased")
        else A.notify("Shop","Failed: "..tostring(ok and p or b)) end
    end)
end

local g=tShop:AddGroup("Quick Picks")
g:AddButton("BagElite",function() qb("BagElite","BagElite","BAGS") end)
g:AddButton("Shiesty",function() qb("Shiesty","Shiesty","MAIN") end)
g:AddButton("Lemonade",function() qb("Lemonade","Lemonade","EXOTIC") end)
g:AddButton("Bandage",function() qb("Bandage","Bandage","EXOTIC") end)

local g=tShop:AddGroup("Guns")
local selectedGun="Draco"
local gunOptions={
    ["Draco + 7.62"]={"Draco","7.62"},
    ["Clear Mag Drac + 7.62"]={"ClearMagDrac","7.62"},
    ["AR Pistol + 5.56"]={"ARPistol","5.56"},
    ["223 Tan + 5.56"]={"223Tan","5.56"},
    ["HP Browning + Ext"]={"HPBrowning Ext",".Extended"},
    ["Glock 17 + Ext"]={"Glock17",".Extended"},
    ["Glock 22 + Ext"]={"Glock22",".Extended"},
    ["Springfield XD + Ext"]={"SpringField XD",".Extended"},
}
local gunNames={}
for k in pairs(gunOptions) do table.insert(gunNames,k) end
table.sort(gunNames)
g:AddDropdown("aqxQuickGunSelect",{Text="Select Gun",Values=gunNames,Default=gunNames[1],
    Callback=function(v) selectedGun=tostring(v) end})
g:AddButton("Buy Selected Gun",function()
    local data=gunOptions[selectedGun]
    if not data then A.notify("Shop","Invalid gun") return end
    task.spawn(function()
        qb(selectedGun,data[1],"SHOP5")
        task.wait(0.15)
        qb(data[2],data[2],"EXOTIC")
    end)
end)

local g=tShop:AddGroup("Exotic")
local selectedExotic="FakeCard"
local exoticItems={"FakeCard","Ice-Fruit Bag","Ice-Fruit Cupz","FijiWater","FreshWater",
    "G26","Lemonade","Sledge Hammer","Screw","Bandage"}
g:AddDropdown("aqxQuickExoticSelect",{Text="Exotic Item",Values=exoticItems,Default="FakeCard",
    Callback=function(v) selectedExotic=tostring(v) end})
g:AddButton("Buy Selected Exotic",function() qb(selectedExotic,selectedExotic,"EXOTIC") end)

local g=tShop:AddGroup("Main Shop")
local selectedMain="Shiesty"
local mainShopItems={"Shiesty","BluGloves","WhiteGloves","BlackGloves","Water",
    "YelloCamoGloves","RedCamoGloves","PurpleCamoGloves","RawChicken","RawSteak","WhiteShiesty"}
g:AddDropdown("aqxQuickMainSelect",{Text="Main Shop Item",Values=mainShopItems,Default="Shiesty",
    Callback=function(v) selectedMain=tostring(v) end})
g:AddButton("Buy Selected Main Shop",function() qb(selectedMain,selectedMain,"MAIN") end)

local g=tShop:AddGroup("Ammo / Mags")
local selectedAmmo="Extended Mag"
local ammoOptions={
    ["Extended Mag"]=".Extended",
    ["Drum Mag"]=".Drum",
    ["10mm Ammo"]=".10mm",
    ["FN Mag"]=".FNMag",
    ["9mm Ammo"]="9mm",
    ["7.62 Ammo"]="7.62",
    ["5.56 Ammo"]="5.56",
}
local ammoNames={}
for k in pairs(ammoOptions) do table.insert(ammoNames,k) end
table.sort(ammoNames)
g:AddDropdown("aqxQuickAmmoSelect",{Text="Ammo / Mag",Values=ammoNames,Default=ammoNames[1],
    Callback=function(v) selectedAmmo=tostring(v) end})
g:AddButton("Buy Selected Ammo",function()
    local target=ammoOptions[selectedAmmo]
    if not target then A.notify("Shop","Invalid ammo") return end
    qb(selectedAmmo,target,"EXOTIC")
end)

local g=tShop:AddGroup("Bags")
local selectedBag="SmallBag"
local bagOptions={}
pcall(function()
    if RS:FindFirstChild("BACKPACK_HATS") and RS.BACKPACK_HATS:FindFirstChild("Accessories") then
        for _,item in ipairs(RS.BACKPACK_HATS.Accessories:GetChildren()) do
            table.insert(bagOptions,item.Name)
        end
    end
end)
if #bagOptions==0 then bagOptions={"SmallBag","MediumBag","LargeBag"} end
table.sort(bagOptions)
selectedBag=bagOptions[1]
g:AddDropdown("aqxQuickBagSelect",{Text="Bag",Values=bagOptions,Default=selectedBag,
    Callback=function(v) selectedBag=tostring(v) end})
g:AddButton("Buy Selected Bag",function() qb(selectedBag,selectedBag,"BAGS") end)

local g=tShop:AddGroup("World Items")
local selectedOther="Draco"
local otherOptions={}
pcall(function()
    local seen={}
    local src=workspace:FindFirstChild("GUNS")
    local source=src and src:GetChildren() or workspace:GetChildren()
    for _,item in ipairs(source) do
        if (item:IsA("Model") or item:IsA("Tool")) and item.Name~="Basketball"
        and item.Name~="Loader" and not seen[item.Name] then
            seen[item.Name]=true table.insert(otherOptions,item.Name)
        end
    end
    table.sort(otherOptions)
end)
if #otherOptions==0 then otherOptions={"Draco","Glock17","ARPistol"} end
selectedOther=otherOptions[1]
g:AddDropdown("aqxQuickOtherSelect",{Text="World Item",Values=otherOptions,Default=selectedOther,
    Callback=function(v) selectedOther=tostring(v) end})
g:AddButton("Buy Selected World Item",function() qb(selectedOther,selectedOther,"OTHER") end)

-- ═══════════════════════════════════════════════════════════════
-- COMBAT
-- ═══════════════════════════════════════════════════════════════
local tCombat=A.makeTab("Combat")

local g=tCombat:AddGroup("Weapon Modifications")
local function bindToggle(display,key,flag)
    g:AddToggle(flag,{Text=display,Default=false,Callback=function(s)
        A.WeaponMods[key]=s
        if key=="InfiniteDamage" then A.WeaponMods.DamageAmplified=s end
        pcall(A.applyAllWeaponMods)
    end})
end
bindToggle("Infinite Ammo","InfiniteAmmo","aqxInfAmmo")
bindToggle("Infinite Clips","InfiniteClips","aqxInfClips")
bindToggle("Infinite Damage","InfiniteDamage","aqxInfDmg")
bindToggle("Instant Reload","InstantReload","aqxInstReload")
bindToggle("Instant Equip","InstantEquip","aqxInstEquip")
bindToggle("80k Bullets","Bullets80k","aqx80k")
bindToggle("Fully Automatic","Automatic","aqxAuto")
bindToggle("Disable Jamming","DisableJamming","aqxNoJam")
bindToggle("Modify Recoil","ModifyRecoilValue","aqxRecoil")
bindToggle("Modify Spread","ModifySpreadValue","aqxSpread")
bindToggle("Modify Fire Rate","ModifyFireRate","aqxFireRate")
g:AddButton("Force 80k Bullets",A.force80k)

local g=tCombat:AddGroup("Weapon Settings")
g:AddSlider("aqxReloadSpd",{Text="Reload Speed",Min=0.01,Max=1,Default=0.2,
    Callback=function(v) A.WeaponMods.ReloadSpeed=v pcall(A.applyAllWeaponMods) end})
g:AddSlider("aqxEquipSpd",{Text="Equip Speed",Min=0.01,Max=1,Default=0.2,
    Callback=function(v) A.WeaponMods.EquipSpeed=v pcall(A.applyAllWeaponMods) end})

local g=tCombat:AddGroup("Gun Color")
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

-- ═══════════════════════════════════════════════════════════════
-- VISUALS
-- ═══════════════════════════════════════════════════════════════
local tVis=A.makeTab("Visuals")

local g=tVis:AddGroup("World")
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

local g=tVis:AddGroup("Player ESP")
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

local g=tVis:AddGroup("Hitbox")
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
g:AddToggle("aqxHitboxTeam",{Text="Skip Teammates",Default=false,Callback=function(v) A.HitboxVisuals.TeamCheck=v end})

-- ═══════════════════════════════════════════════════════════════
-- SAFE
-- ═══════════════════════════════════════════════════════════════
local tSafe=A.makeTab("Safe")

local g=tSafe:AddGroup("Safe")
local safeItems=A.GetSafeItems()
if #safeItems==0 then safeItems={"(empty - press Refresh)"} end
local selectedSafeItem=safeItems[1]
local safeDD=g:AddDropdown("aqxSafeItem",{Text="Select Safe Item",Values=safeItems,Default=selectedSafeItem,
    Callback=function(v) selectedSafeItem=tostring(v) end})
g:AddButton("Refresh Safe List",function()
    local items=A.GetSafeItems()
    if #items==0 then items={"(empty)"} end
    if safeDD then safeDD:SetValues(items) end
    selectedSafeItem=items[1]
    A.notify("Safe","Refreshed: "..#items.." items")
end)
local safeTakeAllActive=false
g:AddButton("Take All",function()
    if safeTakeAllActive then A.notify("Safe","Already running.") return end
    local items=A.GetSafeItems()
    if #items==0 then A.notify("Safe","Safe is empty.") return end
    safeTakeAllActive=true
    task.spawn(function()
        A.notify("Safe","Taking all "..#items.." items...")
        local taken=0
        for _,n in ipairs(items) do
            if not safeTakeAllActive then break end
            if A.TakeFromSafe(n) then taken=taken+1 end
            task.wait(0.5)
        end
        safeTakeAllActive=false
        A.notify("Safe","Took "..taken.."/"..#items)
    end)
end)
g:AddButton("Stop Take All",function()
    if safeTakeAllActive then safeTakeAllActive=false A.notify("Safe","Stop requested.")
    else A.notify("Safe","Not running.") end
end)

local g=tSafe:AddGroup("Safe Dupe")
local dupeItems=A.GetLockedTools()
table.insert(dupeItems,1,"None")
local dupeDD=g:AddDropdown("aqxDupeItem",{Text="Select Item",Values=dupeItems,Default="None",
    Callback=function(v)
        local pick=tostring(v)
        if pick=="None" or pick=="" then A.selectedDupeItem=nil else A.selectedDupeItem=pick end
    end})
g:AddButton("Refresh Items",function()
    local items=A.GetLockedTools()
    local l={"None"}
    for _,x in ipairs(items) do table.insert(l,x) end
    if dupeDD then dupeDD:SetValues(l) end
    A.selectedDupeItem=nil
    A.notify("Dupe","Refreshed: "..(#l-1).." tools")
end)
local customDupeAmount=1
g:AddSlider("aqxDupeAmt",{Text="Custom Dupe Amount",Min=1,Max=15,Default=1,
    Callback=function(v) customDupeAmount=math.clamp(math.floor(v),1,15) end})
g:AddButton("Run Custom Safe Dupe",function()
    if not A.autoDupeActive then A.DoDupe(customDupeAmount)
    else A.notify("Dupe","Already running!") end
end)
g:AddButton("Safe Dupe 15 Times",function()
    if not A.autoDupeActive then A.DoDupe(15)
    else A.notify("Dupe","Already running!") end
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

local g=tSafe:AddGroup("Info")
local safeStatusLbl=g:AddLabel("Safe Status: Ready")
local dupeCounterLbl=g:AddLabel("Total Duped: 0")
local dupeActiveLbl=g:AddLabel("Dupe: IDLE")
task.spawn(function()
    while task.wait(5) do
        local sf=A.GetActiveSafe()
        pcall(function() safeStatusLbl:SetText("Safe Status: "..(sf and "Found" or "Not Found")) end)
        pcall(function() dupeCounterLbl:SetText("Total Duped: "..A.dupeCounter) end)
        pcall(function() dupeActiveLbl:SetText("Dupe: "..(A.autoDupeActive and "RUNNING" or "IDLE")) end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- TELEPORT
-- ═══════════════════════════════════════════════════════════════
local tTp=A.makeTab("Teleport")

local g=tTp:AddGroup("Quick Teleport")
local selTP=A.teleportNames[1]
g:AddDropdown("aqxTpLoc",{Text="Location",Values=A.teleportNames,Default=selTP,
    Callback=function(v) selTP=tostring(v) end})
g:AddButton("Teleport",function()
    local cf3=A.teleportLocations[selTP]
    if cf3 then A.TP(cf3) A.notify("TP","Teleported to "..selTP) end
end)
g:AddButton("Dynamic Cook Pot",A.TeleportToCookPot)

local g=tTp:AddGroup("Shops")
local shops={"Car Dealer","Gunshop","Dripstore","Exotic","Backpack","Market",
    "Pawn Shop","Bank","New Bank","Money Wash","Dollar General","Ice Box"}
for _,name in ipairs(shops) do
    if A.teleportLocations[name] then
        g:AddButton(name,function()
            A.TP(A.teleportLocations[name])
            A.notify("TP",name,2)
        end)
    end
end

local g=tTp:AddGroup("Services")
local services={"Hospital","Prison","Studio","RPT","Construction Site",
    "Bank Vault","Mr Money Man","New Deli","New Laundry","New Seller"}
for _,name in ipairs(services) do
    if A.teleportLocations[name] then
        g:AddButton(name,function()
            A.TP(A.teleportLocations[name])
            A.notify("TP",name,2)
        end)
    end
end

local g=tTp:AddGroup("Houses")
local houses={"Mansion","New Penthouse","Random House"}
for _,name in ipairs(houses) do
    if A.teleportLocations[name] then
        g:AddButton(name,function()
            A.TP(A.teleportLocations[name])
            A.notify("TP",name,2)
        end)
    end
end

local g=tTp:AddGroup("Utility")
g:AddButton("Dynamic Cook Pot",A.TeleportToCookPot)
g:AddButton("Return to Spawn",function()
    local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        A.TP(spawn.CFrame)
        A.notify("TP","Returned to spawn",2)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EXTRA
-- ═══════════════════════════════════════════════════════════════
local tExtra=A.makeTab("Extra")

local g=tExtra:AddGroup("Emotes")
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

local g=tExtra:AddGroup("Quick Outfits")
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
g:AddButton("Blu Moncler Drip",function()
    A.applyOutfit("Blu Moncler Drip",{{"Buy","Shirts","Blu Moncler"},{"Wear","Shirts","Blu Moncler"},
        {"Buy","Pants","Amiri Blue Jeans"},{"Wear","Pants","Amiri Blue Jeans"},
        {"Buy","Shiestys","Shiesty"},{"Wear","Shiestys","Shiesty"}})
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

A.notify("aqx","Loaded. Tap the purple a to minimize.",4)
print("[aqx] tabs loaded")
