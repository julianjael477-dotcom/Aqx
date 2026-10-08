--[[ aqx modules part 1 — weapon, target, money, vehicle, movement ]]

local A=getgenv().aqx
assert(A and A.CoreLoaded,"aqx core not loaded")
local Players=A.Players local RS=A.RS local RunSvc=A.RunSvc local UIS=A.UIS
local StarterGui=A.StarterGui local LP=A.LP local BP=A.BP
local notify=A.notify local TP=A.TP

--------------------------------------------------------------------
-- WEAPON MODS
--------------------------------------------------------------------
A.WeaponMods = {InfiniteAmmo=false,InfiniteClips=false,Bullets80k=false,
    ModifyRecoilValue=false,ModifySpreadValue=false,DisableJamming=false,
    InstantReload=false,InstantEquip=false,ModifyFireRate=false,
    Automatic=false,DamageAmplified=false,SpoofAccuracy=false,
    InfiniteDamage=false,ReloadSpeed=0.2,EquipSpeed=0.2}
local WM=A.WeaponMods

local function getGunSet()
    local c=LP.Character if not c then return nil,nil end
    local t=c:FindFirstChildOfClass("Tool")
    if not t or not t:FindFirstChild("Setting") then return nil,nil end
    local ok,s=pcall(require,t.Setting)
    if ok and type(s)=="table" then return t,s end
end

A.applyAllWeaponMods = function()
    local tool,s=getGunSet() if not s then return end
    pcall(function()
        if WM.InfiniteAmmo then s.Ammo=99999 s.AmmoPerMag=99999 s.LimitedAmmoEnabled=false end
        if WM.InfiniteClips then s.Ammo=80000 s.AmmoPerMag=80000 s.LimitedAmmoEnabled=false end
        if WM.Bullets80k then
            s.Ammo=80000 s.AmmoPerMag=80000 s.LimitedAmmoEnabled=false
            local gl=tool:FindFirstChild("GunScript_Local")
            if gl and type(getsenv)=="function" then
                pcall(function()
                    local env=getsenv(gl)
                    if env and type(env.Reload)=="function" and type(debug)=="table"
                    and type(debug.setupvalue)=="function" then
                        debug.setupvalue(env.Reload,1,80000) debug.setupvalue(env.Reload,3,80000)
                    end
                end)
            end
        end
        if WM.ModifyRecoilValue then s.Recoil=0 s.CameraRecoilingEnabled=false end
        if WM.ModifySpreadValue then s.Spread=0 s.SpreadX=0 s.SpreadY=0 s.Accuracy=1 end
        if WM.DisableJamming then s.JamChance=0 end
        if WM.InstantReload then s.ReloadTime=WM.ReloadSpeed or 0.1 end
        if WM.InstantEquip then s.EquipTime=WM.EquipSpeed or 0.1 s.EquippingTime=WM.EquipSpeed or 0.1 end
        if WM.ModifyFireRate then s.FireRate=0 end
        if WM.Automatic then s.Auto=true end
        if WM.DamageAmplified or WM.InfiniteDamage then s.BaseDamage=1e9 end
        if WM.SpoofAccuracy then s.Accuracy=1 end
    end)
end

LP.CharacterAdded:Connect(function(c)
    c.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(A.applyAllWeaponMods) end end)
end)
if LP.Character then
    LP.Character.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(A.applyAllWeaponMods) end end)
end
task.spawn(function() while task.wait(0.25) do pcall(A.applyAllWeaponMods) end end)

A.force80k = function()
    local t=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
    if not t then notify("Gun Mods","Hold a gun first!") return end
    pcall(function()
        if t:FindFirstChild("Setting") then
            local c=require(t.Setting)
            if type(c)=="table" then c.Ammo=80000 c.AmmoPerMag=80000 c.LimitedAmmoEnabled=false end
        end
        local gl=t:FindFirstChild("GunScript_Local")
        if gl and type(getsenv)=="function" then
            local env=getsenv(gl)
            if env and type(env.Reload)=="function" and type(debug)=="table"
            and type(debug.setupvalue)=="function" then
                debug.setupvalue(env.Reload,1,80000) debug.setupvalue(env.Reload,3,80000)
            end
        end
    end)
    notify("Gun Mods","Forced 80k bullets.")
end

--------------------------------------------------------------------
-- GUN COLOR
--------------------------------------------------------------------
A.GunOriginalColors={}
A.GunChams=false
A.RainbowGun=false
A.GunChamsColor=Color3.fromRGB(0,200,0)

local function updGunColor()
    if not A.GunChams then return end
    local c=LP.Character local t=c and c:FindFirstChildOfClass("Tool")
    if not t then return end
    for _,v in pairs(t:GetDescendants()) do
        if v:IsA("BasePart") then
            if not A.GunOriginalColors[v] then A.GunOriginalColors[v]=v.Color end
            if A.RainbowGun then v.Color=Color3.fromHSV((tick()%5)/5,1,1)
            else v.Color=A.GunChamsColor or Color3.fromRGB(0,200,0) end
            v.Material=Enum.Material.Neon
        end
    end
end
A.restoreGunColor=function()
    for p,c in pairs(A.GunOriginalColors) do
        if p and p.Parent then p.Color=c p.Material=Enum.Material.Plastic end
    end
    A.GunOriginalColors={}
end
RunSvc.RenderStepped:Connect(function() pcall(updGunColor) end)

--------------------------------------------------------------------
-- TARGET
--------------------------------------------------------------------
A.TargetUtilities={SelectedPlayer=nil,SpectatePlayer=false,BringingPlayer=false,
    BringingNearestPlayer=false,AutoRagdoll=false,AutoKill=false,AutoKillMaxDistance=350}
local TU=A.TargetUtilities

A.getTargetPlayerList=function()
    local l={} for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(l,p.Name) end end
    table.sort(l) return l
end
A.getSelectedTargetPlayer=function()
    local s=TU.SelectedPlayer
    if type(s)=="string" and s~="" then return Players:FindFirstChild(s) end
end
local function validT(p)
    if not p or p==LP then return false end
    local c=p.Character if not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid") local r=c:FindFirstChild("HumanoidRootPart")
    return h and h.Health>0 and r~=nil
end
A.isValidTargetPlayer=validT
A.getNearestTargetPlayer=function()
    local lr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not lr then return nil end
    local n,nd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if validT(p) then
            local d=(p.Character.HumanoidRootPart.Position-lr.Position).Magnitude
            if d<nd then n,nd=p,d end
        end
    end
    return n
end
A.getTargetDistance=function(p)
    local lr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tr=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not lr or not tr then return math.huge end
    return (lr.Position-tr.Position).Magnitude
end

A.targetGunRemote=function(name,part,dmg)
    part=part or "Head" dmg=dmg or math.huge
    local t=Players:FindFirstChild(tostring(name))
    if not t or not t.Character or not t.Character:FindFirstChild(part) then return end
    if not t.Character:FindFirstChildOfClass("Humanoid") then return end
    local tool=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
    if not tool then notify("Target","Hold a gun/tool first.") return end
    pcall(function() if tool:FindFirstChild("Setting") then require(tool.Setting).Range=10000 end end)
    pcall(function()
        if RS:FindFirstChild("InflictTarget") then
            RS.InflictTarget:FireServer(tool,LP,t.Character.Humanoid,t.Character[part],dmg,
                {0,0,false,false},{false,5,3},t.Character[part],
                {false,{1930359546},1,1.5,1},t.Character[part].Position,
                Vector3.new(0,0,-1),true)
        end
    end)
end

local spectateReset=true
RunSvc:BindToRenderStep("aqxSpectate",Enum.RenderPriority.Camera.Value,function()
    local cam=workspace.CurrentCamera if not cam then return end
    if TU.SpectatePlayer then
        spectateReset=false
        local t=A.getSelectedTargetPlayer()
        local s=t and t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if not s and LP.Character then s=LP.Character:FindFirstChildOfClass("Humanoid") end
        if s then cam.CameraSubject=s end
    elseif not spectateReset and LP.Character then
        spectateReset=true
        local h=LP.Character:FindFirstChildOfClass("Humanoid")
        if h then cam.CameraSubject=h end
    end
end)

task.spawn(function()
    while task.wait() do
        if TU.BringingPlayer then
            local t=A.getSelectedTargetPlayer()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                t.Character.HumanoidRootPart.CFrame=LP.Character.HumanoidRootPart.CFrame+Vector3.new(2,0,0)
            end
        end
        if TU.BringingNearestPlayer then
            local t=A.getNearestTargetPlayer()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                t.Character.HumanoidRootPart.CFrame=LP.Character.HumanoidRootPart.CFrame+Vector3.new(2,0,0)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if TU.AutoRagdoll then
            local t=A.getSelectedTargetPlayer()
            if t and validT(t) and t.Character.Humanoid:GetState()~=Enum.HumanoidStateType.Physics then
                A.targetGunRemote(t.Name,"RightUpperLeg",0.01)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if TU.AutoKill then
            local t=A.getSelectedTargetPlayer()
            if t and validT(t) and A.getTargetDistance(t)<=(TU.AutoKillMaxDistance or 350) then
                local tool=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("GunScript_Local") then
                    A.targetGunRemote(t.Name,"Head",math.huge)
                end
            end
        end
    end
end)

--------------------------------------------------------------------
-- CAR FLING
--------------------------------------------------------------------
A.CarFlingRunning=false
local function getFlingCar()
    local c=LP.Character local r=c and c:FindFirstChild("HumanoidRootPart")
    if not r then return nil,nil end
    local nc,ns,nd=nil,nil,math.huge
    for _,fn in ipairs({"CivCars","PoliceCars","NPCCars","Cars","Vehicles"}) do
        local f=workspace:FindFirstChild(fn)
        if f then
            for _,car in ipairs(f:GetChildren()) do
                if car:IsA("Model") then
                    local seat=car:FindFirstChild("DriveSeat",true) or car:FindFirstChildWhichIsA("VehicleSeat",true)
                    if seat and not seat.Occupant then
                        local mp=car.PrimaryPart or (car:FindFirstChild("Body") and car.Body:FindFirstChild("#Weight",true))
                            or car:FindFirstChildWhichIsA("BasePart",true)
                        if mp then
                            local d=(mp.Position-r.Position).Magnitude
                            if d<nd then nd=d nc=car ns=seat end
                        end
                    end
                end
            end
        end
    end
    return nc,ns
end

A.CarFlingSelectedPlayer=function()
    if A.CarFlingRunning then notify("Car Fling","Already running.") return end
    local target=A.getSelectedTargetPlayer()
    if not target or not validT(target) then notify("Car Fling","Select a valid player first.") return end
    A.CarFlingRunning=true
    task.spawn(function()
        local c=LP.Character local root=c and c:FindFirstChild("HumanoidRootPart")
        local hum=c and c:FindFirstChildOfClass("Humanoid")
        local tr=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local ret=root and root.CFrame
        local car,seat local oS,oT,oC
        local function finish(m)
            if car then
                for _,p in ipairs(car:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p.AssemblyLinearVelocity=Vector3.zero p.AssemblyAngularVelocity=Vector3.zero end)
                    end
                end
            end
            if tr and tr.Parent and oS then
                pcall(function() tr.Size=oS tr.Transparency=oT tr.CanCollide=oC end)
            end
            if hum and hum.Parent then
                pcall(function() hum.Sit=false hum.Jump=true hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
            if root and root.Parent and ret then pcall(function() TP(ret) end) end
            A.CarFlingRunning=false if m then notify("Car Fling",m) end
        end
        local ok,err=pcall(function()
            if not root or not hum or not tr then finish("Not ready.") return end
            oS=tr.Size oT=tr.Transparency oC=tr.CanCollide
            pcall(function() tr.Size=Vector3.new(25,25,25) tr.Transparency=1 tr.CanCollide=false end)
            car,seat=getFlingCar()
            if not car or not seat then finish("No empty car.") return end
            if not car.PrimaryPart then
                car.PrimaryPart=(car:FindFirstChild("Body") and car.Body:FindFirstChild("#Weight",true))
                    or car:FindFirstChildWhichIsA("BasePart",true) or seat
            end
            if not car.PrimaryPart then finish("No usable part.") return end
            notify("Car Fling","Claiming car...")
            TP(seat.CFrame*CFrame.new(0,2,0)) task.wait(0.2)
            seat:Sit(hum) car:SetAttribute("Usable",true) task.wait(1)
            if hum.SeatPart~=seat then finish("Failed to sit.") return end
            notify("Car Fling","Flinging "..target.Name.."...")
            local sp=hum.SeatPart local st=os.clock()
            while os.clock()-st<1.5 do
                pcall(function()
                    hum.Sit=false hum.Jump=true hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    if sp then
                        for _,w in ipairs(sp:GetDescendants()) do
                            if w:IsA("Weld") or w:IsA("Motor6D") or w.Name=="SeatWeld" then w:Destroy() end
                        end
                    end
                end)
                if not hum.Sit and not hum.SeatPart then break end
                task.wait(0.02)
            end
            if root and root.Parent and ret then
                root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero root.CFrame=ret
            end
            local fs=os.clock()
            while os.clock()-fs<4 do
                if not car.Parent or not tr.Parent then break end
                pcall(function()
                    if car.PrimaryPart then car:SetPrimaryPartCFrame(tr.CFrame) else car:PivotTo(tr.CFrame) end
                end)
                for _,p in ipairs(car:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function()
                            p.AssemblyLinearVelocity=Vector3.new(0,20000,0)
                            p.AssemblyAngularVelocity=Vector3.zero
                        end)
                    end
                end
                task.wait(0.01)
            end
            finish(target.Name.." car-flung.")
        end)
        if not ok then finish("Error: "..tostring(err)) end
    end)
end

--------------------------------------------------------------------
-- MONEY
--------------------------------------------------------------------
local function goodCleaner()
    if not workspace:FindFirstChild("1# Map") then return nil end
    local ci
    for _,v in pairs(workspace["1# Map"]:GetChildren()) do if v:FindFirstChild("CounterM") then ci=v break end end
    if not ci then return nil end
    for _,v in pairs(ci:GetChildren()) do
        local cp=v:FindFirstChild("CashPrompt",true) local gp=v:FindFirstChild("GrabPrompt",true)
        if cp and cp.Enabled and cp.ObjectText=="Count Bread" and gp and not gp.Enabled then return v end
    end
end

A.CleanAllFilthyMoney=function()
    local P=LP
    if not P:FindFirstChild("stored") or not P.stored:FindFirstChild("FilthyStack")
    or P.stored.FilthyStack.Value==0 then notify("Money","No filthy cash!") return end
    if not P.Character or not P.Character:FindFirstChild("HumanoidRootPart") then return end
    local cl=goodCleaner()
    if not cl then notify("Money","No good cleaner.") return end
    pcall(function() TP(cl.WorldPivot or cl:GetPivot()) end) task.wait(0.4)
    pcall(function() fireproximityprompt(cl:FindFirstChild("CashPrompt",true)) end)
    local on=cl:FindFirstChild("On",true)
    if on then repeat task.wait() until on.Color==Color3.fromRGB(74,156,69) else task.wait(0.5) end
    task.wait(0.5)
    pcall(function() fireproximityprompt(cl:FindFirstChild("CashPrompt",true)) end) task.wait(0.25)
    pcall(function() TP(cl.WorldPivot or cl:GetPivot()) end) task.wait(0.4)
    repeat task.wait() until P.Backpack:FindFirstChild("MoneyReady")
    P.Character.Humanoid:EquipTool(P.Backpack["MoneyReady"])
    repeat task.wait(1) pcall(function() fireproximityprompt(cl:FindFirstChild("GrabPrompt",true)) end)
    until not P.Character:FindFirstChild("MoneyReady")
    repeat task.wait() until P.Backpack:FindFirstChild("BagOfMoney")
    pcall(function() TP(CFrame.new(-1217.30,253.88,-3635.04)) end) task.wait(0.4)
    if P.Backpack:FindFirstChild("BagOfMoney") then P.Character.Humanoid:EquipTool(P.Backpack["BagOfMoney"]) end
    task.wait(1)
    pcall(function()
        local a=workspace:FindFirstChild("ATMMoney")
        local p=a and a:FindFirstChild("Prompt",true)
        if p then fireproximityprompt(p) end
    end)
end

A.InfMoneyHoldCupz=function()
    local c=LP.Character or LP.CharacterAdded:Wait()
    local h=c:WaitForChild("HumanoidRootPart") local o=h.CFrame
    local s=workspace:FindFirstChild("IceFruit Sell")
    if not s then notify("Inf Money","IceFruit Sell not found.") return end
    local p=s:FindFirstChild("ProximityPrompt") if not p then return end
    p.HoldDuration=0 p.MaxActivationDistance=math.huge
    TP(s.CFrame) task.wait(1)
    for _=1,250 do task.spawn(function() pcall(function() fireproximityprompt(p,1) end) end) end
    task.wait(5) TP(o) task.wait(0.25)
end

A.SetupInfiniteMoney=function()
    for _,it in ipairs({"Ice-Fruit Bag","Ice-Fruit Cupz","FijiWater","FreshWater"}) do
        task.spawn(function()
            pcall(function() RS:WaitForChild("ExoticShopRemote"):InvokeServer(it) end)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MONEY GEN — verbatim valria juice flow
-- ═══════════════════════════════════════════════════════════════
A.GenerateMaxIllegalMoney=function()
    local P=LP

    local function hasIt(n)
        local c=P.Character
        if c then
            for _,t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and t.Name==n then return true end
            end
        end
        local bp=P:FindFirstChild("Backpack")
        if bp then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.Name==n then return true end
            end
        end
        return false
    end

    local function eqName(n)
        local c=P.Character if not c then return false end
        local h=c:FindFirstChildWhichIsA("Humanoid") if not h then return false end
        local held=c:FindFirstChildWhichIsA("Tool")
        if held and held.Name==n then return true end
        local bp=P:FindFirstChild("Backpack")
        if bp then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.Name==n then
                    pcall(function() h:EquipTool(t) end)
                    task.wait(0.3)
                    return true
                end
            end
        end
        return false
    end

    local function findCup()
        local c=P.Character
        if c then
            local h=c:FindFirstChildWhichIsA("Tool")
            if h and tostring(h.Name):lower():find("cupz") then return h end
        end
        local bp=P:FindFirstChild("Backpack")
        if bp then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and tostring(t.Name):lower():find("cupz") then return t end
            end
        end
        return nil
    end

    local function isFull(tool)
        if not tool then return false end
        local cp=tool:FindFirstChild("IceFruit Cup") or tool:FindFirstChildWhichIsA("BasePart",true)
        if not cp then return false end
        for _,d in ipairs(cp:GetDescendants()) do
            if d.Name:lower():find("punch") and d:IsA("BasePart") and d.Transparency<1 then
                return true
            end
        end
        return false
    end

    local function findFull()
        local c=P.Character
        if c then
            local h=c:FindFirstChildWhichIsA("Tool")
            if h and isFull(h) then return h end
        end
        local bp=P:FindFirstChild("Backpack")
        if bp then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and isFull(t) then return t end
            end
        end
        return nil
    end

    local function findStove()
        local cps=workspace:FindFirstChild("CookingPots") if not cps then return nil,nil end
        for _,v in ipairs(cps:GetChildren()) do
            if v:IsA("Model") then
                local pr=v:FindFirstChildWhichIsA("ProximityPrompt",true)
                if pr then return v,pr end
            end
        end
        return nil,nil
    end

    local function findSell()
        local s=workspace:FindFirstChild("IceFruit Sell") if not s then return nil,nil end
        return s,s:FindFirstChild("ProximityPrompt") or s:FindFirstChildWhichIsA("ProximityPrompt",true)
    end

    local function stoveBusy(cp)
        if not cp then return false end
        local steam=cp:FindFirstChild("Steam",true) if not steam then return false end
        local lui=steam:FindFirstChild("LoadUI",true)
        if lui then return lui.Enabled end
        return false
    end

    notify("Money","Starting juice flow...")

    local stove,prompt=findStove()
    if not stove then notify("Money","No CookingPots found.") return end
    local sell,sPrompt=findSell()
    if not sell then notify("Money","No IceFruit Sell found.") return end

    local origCF=P.Character and P.Character.HumanoidRootPart and P.Character.HumanoidRootPart.CFrame

    -- buy missing items
    local exo=RS:FindFirstChild("ExoticShopRemote",true)
    if exo then
        for _,name in ipairs({"FijiWater","FreshWater","Ice-Fruit Bag","Ice-Fruit Cupz"}) do
            if not hasIt(name) then
                pcall(function() exo:InvokeServer(name) end)
                task.wait(0.4)
            end
        end
    end
    notify("Money","Bought items.")

    -- tp to stove and anchor
    local cp=stove:FindFirstChild("CookPart") or stove.PrimaryPart
        or stove:FindFirstChildWhichIsA("BasePart",true)
    if not cp then notify("Money","Stove has no CookPart.") return end

    notify("Money","Going to stove...")
    TP(cp.CFrame+Vector3.new(0,2,0))
    task.wait(0.8)

    local c=P.Character
    local hrp=c and c:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored=true end
    task.wait(0.4)

    notify("Money","Turning stove on...")
    pcall(function() fireproximityprompt(prompt) end)
    task.wait(1.8)

    for _,name in ipairs({"FijiWater","FreshWater","Ice-Fruit Bag"}) do
        if eqName(name) then
            notify("Money","Adding "..name)
            task.wait(1)
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(3)
        else
            notify("Money","Missing "..name)
        end
    end

    if findCup() then
        notify("Money","Brewing...")
        local start=os.clock()
        local cap=360
        while (os.clock()-start)<cap do
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(0.5)
            if findFull() then
                notify("Money","Ready after "..math.floor(os.clock()-start).."s")
                break
            end
            if not stoveBusy(cp) then
                for _=1,10 do
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(0.3)
                    if findFull() then break end
                end
            end
        end
    end

    if hrp then hrp.Anchored=false end
    task.wait(0.3)

    local cup=findFull()
    if not cup then
        notify("Money","No brewed cup produced.")
        if origCF then pcall(function() TP(origCF) end) end
        return
    end

    local h2=P.Character and P.Character:FindFirstChildWhichIsA("Humanoid")
    if h2 and cup.Parent~=P.Character then
        pcall(function() h2:EquipTool(cup) end)
        task.wait(0.5)
    end

    local sellCF
    if sell:IsA("BasePart") then
        sellCF=sell.CFrame
    else
        local p=sell:FindFirstChildWhichIsA("BasePart",true)
        sellCF=p and p.CFrame
    end
    if not sellCF then
        notify("Money","Couldn't resolve seller position.")
        if origCF then pcall(function() TP(origCF) end) end
        return
    end

    notify("Money","Going to seller...")
    TP(sellCF+Vector3.new(0,2,0))
    task.wait(0.8)

    sPrompt.HoldDuration=0
    sPrompt.MaxActivationDistance=1000
    sPrompt.RequiresLineOfSight=false

    notify("Money","Burst selling 4000x...")
    for _=1,4000 do
        task.spawn(function() pcall(function() fireproximityprompt(sPrompt) end) end)
    end
    task.wait(8)

    if origCF then pcall(function() TP(origCF) end) end
    notify("Money","Done — money generated.")
end

local function dropAmt(a)
    local B=RS:FindFirstChild('BankProcessRemote',true)
    if not B then return false end
    local function send(...)
        if B.InvokeServer then return B:InvokeServer(...) elseif B.FireServer then return B:FireServer(...) end
    end
    for _,args in ipairs({{"Drop",tostring(a)},{"Drop",tonumber(a) or a}}) do
        local ok,r=pcall(send,table.unpack(args))
        if ok and r~=false then return true end
    end
end
task.spawn(function()
    while task.wait(0.3) do
        if A.MoneyDropEnabled then pcall(function() dropAmt(10000) end) end
    end
end)

--------------------------------------------------------------------
-- VEHICLE
--------------------------------------------------------------------
A.Config.TheBronx={carfly=false,carflyspeed=120}
A.CarFly={Enabled=false,Speed=120}
local CH,CS,CC,CR,CBV,CBG,LC
local function carCleanup()
    if CBV then CBV:Destroy() CBV=nil end
    if CBG then CBG:Destroy() CBG=nil end
end
local function carSetup()
    carCleanup()
    if not A.Config.TheBronx.carfly then return end
    local c=LP.Character if not c then return end
    CH=c:FindFirstChildWhichIsA("Humanoid") if not CH then return end
    CS=CH.SeatPart if not CS or not CS:IsA("VehicleSeat") then return end
    CC=CS.Parent if not CC then return end
    CR=CC.PrimaryPart if not CR then return end
    LC=CC
    for _,v in ipairs(CC:GetChildren()) do
        if v:IsA("BasePart") and not v.Name:lower():find("wheel") then v.CanCollide=false end
    end
    CBV=Instance.new("BodyVelocity") CBV.MaxForce=Vector3.new(1e9,1e9,1e9)
    CBV.Velocity=Vector3.zero CBV.Parent=CR
    CBG=Instance.new("BodyGyro") CBG.MaxTorque=Vector3.new(1e9,1e9,1e9)
    CBG.P=25000 CBG.D=1500 CBG.CFrame=CR.CFrame CBG.Parent=CR
end
A.StartCarFly=function()
    A.Config.TheBronx.carfly=true A.CarFly.Enabled=true
    carSetup() notify("Car Fly","Enabled - get in a vehicle!")
end
A.StopCarFly=function()
    A.Config.TheBronx.carfly=false A.CarFly.Enabled=false
    carCleanup() notify("Car Fly","Disabled")
end
task.spawn(function()
    while true do
        task.wait(0.2)
        local c=LP.Character if not c then continue end
        local h=c:FindFirstChildWhichIsA("Humanoid") if not h then continue end
        local s=h.SeatPart
        if s and s:IsA("VehicleSeat") then
            if s.Parent~=LC then carSetup() end
        else
            if LC then carCleanup() LC=nil end
        end
    end
end)
RunSvc.RenderStepped:Connect(function()
    if not A.Config.TheBronx.carfly then carCleanup() return end
    if not CH or CH.SeatPart~=CS then return end
    if not CR or not CBV or not CBG then carSetup() return end
    local sp=A.Config.TheBronx.carflyspeed or 120
    local cam=workspace.CurrentCamera
    local cl=cam.CFrame.LookVector local cr2=cam.CFrame.RightVector
    if not UIS.TouchEnabled then
        local m=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then m+=cl end
        if UIS:IsKeyDown(Enum.KeyCode.S) then m-=cl end
        if UIS:IsKeyDown(Enum.KeyCode.A) then m-=cr2 end
        if UIS:IsKeyDown(Enum.KeyCode.D) then m+=cr2 end
        if m.Magnitude>0 then CBV.Velocity=m.Unit*sp else CBV.Velocity=Vector3.zero end
    else
        CBG.CFrame=CFrame.lookAt(CR.Position,CR.Position+cl)
        local m=CH.MoveDirection
        local v=(m*sp)+(Vector3.new(0,cl.Y,0)*sp)
        if v.Magnitude>0 then CBV.Velocity=v else CBV.Velocity=Vector3.zero end
    end
end)

A.VehicleModifications={SpeedEnabled=false,SpeedValue=10/1000,BreakEnabled=false,
    BreakValue=50/1000,InstantStop=false}
local VM=A.VehicleModifications
task.spawn(function()
    while task.wait() do
        local c=LP.Character local h=c and c:FindFirstChildWhichIsA("Humanoid")
        local s=h and h.SeatPart
        if s and s:IsA("VehicleSeat") then
            if VM.SpeedEnabled and UIS:IsKeyDown(Enum.KeyCode.W) then
                s.AssemblyLinearVelocity=s.AssemblyLinearVelocity*Vector3.new(1+VM.SpeedValue,1,1+VM.SpeedValue)
            end
            if VM.BreakEnabled and UIS:IsKeyDown(Enum.KeyCode.S) then
                s.AssemblyLinearVelocity=s.AssemblyLinearVelocity*Vector3.new(1-VM.BreakValue,1,1-VM.BreakValue)
            end
            if VM.InstantStop and UIS:IsKeyDown(Enum.KeyCode.V) then
                s.AssemblyLinearVelocity=Vector3.zero s.AssemblyAngularVelocity=Vector3.zero
            end
        end
    end
end)

A.GetNearestCar=function(hrp)
    local cc=workspace:FindFirstChild("CivCars") if not cc then return nil end
    local nc,nd=nil,math.huge
    for _,car in ipairs(cc:GetChildren()) do
        if car:IsA("Model") then
            local s=car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat")
            if s and not s.Occupant then
                if not car.PrimaryPart then pcall(function() car.PrimaryPart=car:FindFirstChildWhichIsA("BasePart") end) end
                if car.PrimaryPart then
                    local d=(car.PrimaryPart.Position-hrp.Position).Magnitude
                    if d<nd then nd=d nc=car end
                end
            end
        end
    end
    return nc
end

--------------------------------------------------------------------
-- MOVEMENT
--------------------------------------------------------------------
A.LuhjayyWalk={Speed=16,BoostMultiplier=2,Enabled=false,Character=nil,Humanoid=nil,Root=nil,
    BodyGyro=nil,MovementConnection=nil,FreezeConnection=nil,AnimationTrack=nil}
local LW=A.LuhjayyWalk
LW.Animation=Instance.new("Animation")
LW.Animation.AnimationId="rbxassetid://130336142547434"
local function lwUpdate()
    LW.Character=LP.Character or LP.CharacterAdded:Wait()
    LW.Root=LW.Character:WaitForChild("HumanoidRootPart")
    LW.Humanoid=LW.Character:WaitForChild("Humanoid")
end
local function lwCleanup()
    if LW.MovementConnection then LW.MovementConnection:Disconnect() LW.MovementConnection=nil end
    if LW.FreezeConnection then LW.FreezeConnection:Disconnect() LW.FreezeConnection=nil end
    if LW.BodyGyro then LW.BodyGyro:Destroy() LW.BodyGyro=nil end
    if LW.AnimationTrack then pcall(function() LW.AnimationTrack:Stop() end) LW.AnimationTrack=nil end
end
local function lwSetupMove()
    local h=LW.Humanoid local r=LW.Root
    if not h or not r then return end
    local bg=Instance.new("BodyGyro")
    bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    bg.P=50000 bg.D=1000 bg.CFrame=r.CFrame bg.Parent=r
    LW.BodyGyro=bg
    LW.MovementConnection=RunSvc.RenderStepped:Connect(function()
        if not LW.Enabled or not r.Parent then return end
        local cam=workspace.CurrentCamera
        local dir=Vector3.zero local uk=false
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z) uk=true end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z) uk=true end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector uk=true end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector uk=true end
        if not uk then local m=h.MoveDirection dir=Vector3.new(m.X,0,m.Z) end
        local sp=LW.Speed
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then sp*=LW.BoostMultiplier end
        if dir.Magnitude>0 then dir=dir.Unit*sp end
        local cy=r.AssemblyLinearVelocity.Y
        local gy=math.clamp(cy,-100,-2)
        r.AssemblyLinearVelocity=Vector3.new(dir.X,gy,dir.Z)
        if dir.Magnitude>0 then
            local lk=dir.Unit
            bg.CFrame=CFrame.new(r.Position,r.Position+Vector3.new(lk.X,0,lk.Z))
        end
        r.RotVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
        if LW.AnimationTrack then
            if dir.Magnitude>0 then
                if not LW.AnimationTrack.IsPlaying then LW.AnimationTrack:Play() end
            elseif LW.AnimationTrack.IsPlaying then LW.AnimationTrack:Stop() end
        end
    end)
end
A.LuhjayyWalkStart=function()
    LW.Enabled=true lwUpdate() lwCleanup()
    local r,h=LW.Root,LW.Humanoid
    r.AssemblyLinearVelocity=Vector3.zero
    A.SwimMethod=true
    LW.FreezeConnection=RunSvc.RenderStepped:Connect(function()
        if LW.Enabled and r.Parent then
            if not A.SwimMethod then A.SwimMethod=true end
            r.AssemblyLinearVelocity=Vector3.zero
        end
    end)
    pcall(function()
        local a=h:FindFirstChildWhichIsA("Animator") or Instance.new("Animator",h)
        LW.AnimationTrack=a:LoadAnimation(LW.Animation) LW.AnimationTrack.Looped=true
    end)
    task.delay(3,function()
        if LW.FreezeConnection then LW.FreezeConnection:Disconnect() LW.FreezeConnection=nil end
        if LW.Enabled then lwSetupMove() end
    end)
end
A.LuhjayyWalkStop=function()
    LW.Enabled=false lwCleanup() A.SwimMethod=false
end
task.spawn(function()
    while task.wait() do
        if LW.Enabled then
            if not A.SwimMethod then A.SwimMethod=true end
            if LW.Humanoid then pcall(function() LW.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown) end) end
        end
    end
end)
LP.CharacterAdded:Connect(function()
    task.wait(1) lwUpdate() if LW.Enabled then A.LuhjayyWalkStart() end
end)

A.updateJumpBoostState=function(s)
    local c=LP.Character or LP.CharacterAdded:Wait()
    local h=c:FindFirstChildOfClass("Humanoid") if not h then return end
    h.JumpPower=s and ((h.JumpPower or 50)+50) or 50
end
A.InfJumpEnabled=false
UIS.JumpRequest:Connect(function()
    if A.InfJumpEnabled then
        local c=LP.Character local h=c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

A.NoclipEnabled=false
local noclipConn
A.enableNoclip=function()
    if noclipConn then return end
    noclipConn=RunSvc.Stepped:Connect(function()
        if not A.NoclipEnabled then return end
        local c=LP.Character
        if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
    end)
end
A.disableNoclip=function()
    if noclipConn then noclipConn:Disconnect() noclipConn=nil end
    local c=LP.Character
    if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
end

--------------------------------------------------------------------
-- FLY
--------------------------------------------------------------------
A.MiamiFlyData={Enabled=false,Connections={},Velocity=nil,Gyro=nil,Seat=nil,Weld=nil,
    Speed=80,Move={W=false,A=false,S=false,D=false,Space=false,Shift=false}}
A.MiamiFlyCleanup=function()
    local d=A.MiamiFlyData d.Enabled=false
    for _,c in ipairs(d.Connections or {}) do pcall(function() c:Disconnect() end) end
    d.Connections={}
    for _,it in ipairs({d.Velocity,d.Gyro,d.Weld,d.Seat}) do
        pcall(function() if it and it.Parent then it:Destroy() end end)
    end
    d.Velocity=nil d.Gyro=nil d.Weld=nil d.Seat=nil
    d.Move={W=false,A=false,S=false,D=false,Space=false,Shift=false}
    A.SwimMethod=false
    local c=LP.Character local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    if h then pcall(function() h.Sit=false h.PlatformStand=false h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero end) end
end
A.MiamiFlySetup=function()
    local d=A.MiamiFlyData A.MiamiFlyCleanup()
    local c=LP.Character or LP.CharacterAdded:Wait()
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    if not h or not r then notify("Fly","Not ready.") return end
    d.Enabled=true A.SwimMethod=true
    local seat=Instance.new("VehicleSeat") seat.Name="aqxFlySeat" seat.Anchored=false
    seat.CanCollide=false seat.Transparency=1 seat.Size=Vector3.new(2,1,2)
    seat.CFrame=r.CFrame*CFrame.new(0,-3,0) seat.Parent=workspace d.Seat=seat
    local weld=Instance.new("Weld") weld.Part0=seat weld.Part1=r weld.C0=CFrame.new(0,3,0)
    weld.Parent=seat d.Weld=weld
    pcall(function() seat:Sit(h) end)
    local v=Instance.new("BodyVelocity") v.MaxForce=Vector3.new(1e9,1e9,1e9)
    v.Velocity=Vector3.zero v.Parent=r d.Velocity=v
    local g=Instance.new("BodyGyro") g.MaxTorque=Vector3.new(1e9,1e9,1e9)
    g.P=50000 g.D=1000 g.CFrame=r.CFrame g.Parent=r d.Gyro=g
    table.insert(d.Connections,UIS.InputBegan:Connect(function(i,gp)
        if gp then return end local k=i.KeyCode
        if k==Enum.KeyCode.W then d.Move.W=true end
        if k==Enum.KeyCode.A then d.Move.A=true end
        if k==Enum.KeyCode.S then d.Move.S=true end
        if k==Enum.KeyCode.D then d.Move.D=true end
        if k==Enum.KeyCode.Space then d.Move.Space=true end
        if k==Enum.KeyCode.LeftShift then d.Move.Shift=true end
        if k==Enum.KeyCode.E then d.Speed=math.clamp((d.Speed or 80)+10,20,300) end
        if k==Enum.KeyCode.Q then d.Speed=math.clamp((d.Speed or 80)-10,20,300) end
    end))
    table.insert(d.Connections,UIS.InputEnded:Connect(function(i)
        local k=i.KeyCode
        if k==Enum.KeyCode.W then d.Move.W=false end
        if k==Enum.KeyCode.A then d.Move.A=false end
        if k==Enum.KeyCode.S then d.Move.S=false end
        if k==Enum.KeyCode.D then d.Move.D=false end
        if k==Enum.KeyCode.Space then d.Move.Space=false end
        if k==Enum.KeyCode.LeftShift then d.Move.Shift=false end
    end))
    table.insert(d.Connections,RunSvc.RenderStepped:Connect(function()
        if not d.Enabled or not d.Velocity or not d.Gyro then return end
        if not r or not r.Parent then A.MiamiFlyCleanup() return end
        A.SwimMethod=true
        local cam=workspace.CurrentCamera if not cam then return end
        d.Gyro.CFrame=cam.CFrame
        local dir=Vector3.zero
        if d.Move.W then dir+=cam.CFrame.LookVector end
        if d.Move.S then dir-=cam.CFrame.LookVector end
        if d.Move.A then dir-=cam.CFrame.RightVector end
        if d.Move.D then dir+=cam.CFrame.RightVector end
        if d.Move.Space then dir+=Vector3.new(0,1,0) end
        if d.Move.Shift then dir-=Vector3.new(0,1,0) end
        if UIS.TouchEnabled and h then dir+=h.MoveDirection end
        if dir.Magnitude>0 then d.Velocity.Velocity=dir.Unit*(d.Speed or 80)
        else d.Velocity.Velocity=Vector3.zero end
    end))
    notify("Fly","Enabled. WASD + Space/Shift, Q/E speed.",3)
end

A.Modules1Loaded=true
print("[aqx] modules1 loaded")
