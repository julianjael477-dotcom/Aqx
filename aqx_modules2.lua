--[[ aqx modules part 2 ]]

local A=getgenv().aqx
assert(A and A.Modules1Loaded,"aqx modules1 not loaded")
local Players=A.Players local RS=A.RS local RunSvc=A.RunSvc local UIS=A.UIS
local StarterGui=A.StarterGui local LP=A.LP local BP=A.BP
local PromptSvc=A.PromptSvc local notify=A.notify local TP=A.TP

A.AutoGrabMoney=false A.AutoStealLootbags=false A.AutoPickupBags=false
A.DisableBloodEffects=false A.BypassLockedCars=false A.FasterRespawn=false
A.RespawnWhereYouDied=false A.RespawnDeathCFrame=nil A.KeepToolsOnDeath=false
A.AutoFOnLowHealth=false A.NoCameraBob=false A.AntiJumpCooldownEnabled=false
A.AntiJumpDisabledScripts={} A.DumpsterRunning=false A.ConstructionRunning=false

-- RESPAWN WHERE DIED
local RDC={}
local function clearRDC() for _,c in ipairs(RDC) do pcall(function() c:Disconnect() end) end RDC={} end
local function captureDC(ch)
    if not A.RespawnWhereYouDied or not ch then return end
    local r=ch:FindFirstChild("HumanoidRootPart")
    if r then A.RespawnDeathCFrame=r.CFrame end
end
local function bindRDC(ch)
    clearRDC() if not ch then return end
    local h=ch:WaitForChild("Humanoid",10) local r=ch:WaitForChild("HumanoidRootPart",10)
    if not h or not r then return end
    local cap=false
    table.insert(RDC,h.HealthChanged:Connect(function(hp)
        if hp<=0 and not cap then cap=true captureDC(ch) end
    end))
    table.insert(RDC,h.Died:Connect(function()
        if not cap then cap=true captureDC(ch) end
    end))
end
if LP.Character then task.defer(bindRDC,LP.Character) end
LP.CharacterAdded:Connect(function(ch)
    local ret=A.RespawnWhereYouDied and A.RespawnDeathCFrame or nil
    bindRDC(ch) if not ret then return end
    task.spawn(function()
        local r=ch:WaitForChild("HumanoidRootPart",10)
        local h=ch:WaitForChild("Humanoid",10)
        if not r or not h or not A.RespawnWhereYouDied then return end
        task.wait(0.8)
        local ok=pcall(function() TP(ret) end)
        if not ok and r.Parent then r.CFrame=ret end
        if r.Parent then r.CFrame=ret r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero end
        A.RespawnDeathCFrame=nil
        notify("Respawn","Returned to death position.")
    end)
end)

-- ANTI JUMP CD
A.SetAntiJumpCooldownEnabled=function(state)
    A.AntiJumpCooldownEnabled=state
    local function proc(cont)
        if not cont then return end
        for _,o in ipairs(cont:GetDescendants()) do
            if o:IsA("LocalScript") then
                local nm=o.Name:lower() local pth=o:GetFullName():lower()
                local isJ=(nm:find("jump") and (nm:find("debounce") or nm:find("cooldown")))
                    or pth:find("jumpdebounce",1,true) or pth:find("jumpcooldown",1,true)
                if isJ then
                    if state then
                        if A.AntiJumpDisabledScripts[o]==nil then A.AntiJumpDisabledScripts[o]=o.Enabled end
                        o.Enabled=false
                    elseif A.AntiJumpDisabledScripts[o]~=nil then
                        o.Enabled=A.AntiJumpDisabledScripts[o] A.AntiJumpDisabledScripts[o]=nil
                    end
                end
            end
        end
    end
    proc(LP:FindFirstChild("PlayerGui")) proc(LP.Character)
    if not state then
        for so,prev in pairs(A.AntiJumpDisabledScripts) do
            pcall(function() if so and so.Parent then so.Enabled=prev end end)
            A.AntiJumpDisabledScripts[so]=nil
        end
    end
end

-- ANTI CAR FLING
A.AntiCarFlingEnabled=false
local ACFConn=nil
local ACFSaved={}
local ACFProtected={}
local function restoreACFPart(p)
    local s=ACFSaved[p]
    if s then
        pcall(function() if p and p.Parent then p.CanCollide=s.CanCollide p.CanTouch=s.CanTouch end end)
        ACFSaved[p]=nil
    end
end
local function protectFlingCar(car)
    if not car then return end
    ACFProtected[car]=os.clock()+1.25
    for _,p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") then
            if not ACFSaved[p] then ACFSaved[p]={CanCollide=p.CanCollide,CanTouch=p.CanTouch} end
            p.CanCollide=false p.CanTouch=false
        end
    end
end
local function getACFCars()
    local cars={}
    for _,fn in ipairs({"CivCars","PoliceCars","NPCCars","Cars","Vehicles"}) do
        local f=workspace:FindFirstChild(fn)
        if f then for _,c in ipairs(f:GetChildren()) do if c:IsA("Model") then table.insert(cars,c) end end end
    end
    return cars
end
A.StopAntiCarFling=function()
    A.AntiCarFlingEnabled=false
    if ACFConn then ACFConn:Disconnect() ACFConn=nil end
    for p in pairs(ACFSaved) do restoreACFPart(p) end
    table.clear(ACFProtected)
end
A.StartAntiCarFling=function()
    A.StopAntiCarFling() A.AntiCarFlingEnabled=true
    ACFConn=RunSvc.Heartbeat:Connect(function()
        if not A.AntiCarFlingEnabled then return end
        local c=LP.Character local h=c and c:FindFirstChildOfClass("Humanoid")
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if not h or not r or h.Health<=0 then return end
        local os2=h.SeatPart local oc=os2 and os2:FindFirstAncestorWhichIsA("Model")
        local df=false
        for _,car in ipairs(getACFCars()) do
            if car~=oc then
                local mp=car.PrimaryPart or car:FindFirstChild("DriveSeat",true) or car:FindFirstChildWhichIsA("BasePart",true)
                if mp then
                    local d=(mp.Position-r.Position).Magnitude
                    local ln=mp.AssemblyLinearVelocity.Magnitude
                    local sp=mp.AssemblyAngularVelocity.Magnitude
                    if d<=9 or (d<=28 and (ln>=90 or sp>=35)) then protectFlingCar(car) df=true end
                end
            end
        end
        if df then
            if h.Sit and not oc then h.Sit=false h.Jump=true h:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if r.AssemblyLinearVelocity.Magnitude>120 then r.AssemblyLinearVelocity=Vector3.zero end
            if r.AssemblyAngularVelocity.Magnitude>30 then r.AssemblyAngularVelocity=Vector3.zero end
        end
        local now=os.clock()
        for car,exp in pairs(ACFProtected) do
            if not car.Parent or now>=exp then
                ACFProtected[car]=nil
                for p in pairs(ACFSaved) do
                    if not p.Parent or p:IsDescendantOf(car) then restoreACFPart(p) end
                end
            end
        end
    end)
end

-- AUTOFARMS
local Pawn=RS:FindFirstChild("PawnRemote")
local BPRem=RS:FindFirstChild("BackpackRemote")
local InvRem=RS:FindFirstChild("Inventory")
A.PawnRemote=Pawn A.BackpackRemote=BPRem A.InventoryRemote=InvRem

local function fireAll()
    if not BP then return end
    for _,it in pairs(BP:GetChildren()) do pcall(function() if Pawn then Pawn:FireServer(it.Name) end end) end
end
if BP then
    BP.ChildAdded:Connect(function(ch)
        if A.DumpsterRunning then pcall(function() if Pawn then Pawn:FireServer(ch.Name) end end) end
    end)
end
A.startDumpsterAutofarm=function()
    if A.DumpsterRunning then return end
    A.DumpsterRunning=true
    task.spawn(function()
        while A.DumpsterRunning do
            local ds={}
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Part") and v.Name=="DumpsterPromt" then
                    local p=v:FindFirstChildWhichIsA("ProximityPrompt")
                    if p then table.insert(ds,{part=v,prompt=p}) end
                end
            end
            for _,e in ipairs(ds) do
                if not A.DumpsterRunning then break end
                if e.part and e.prompt and e.part:IsDescendantOf(workspace) then
                    TP(CFrame.new(e.part.Position+Vector3.new(0,3,0))) task.wait(0.6)
                    pcall(function() fireproximityprompt(e.prompt) end) task.wait(1)
                end
            end
            task.wait(2)
        end
    end)
    fireAll()
end
A.stopDumpsterAutofarm=function() A.DumpsterRunning=false end

A.startConstructionAutofarm=function()
    if A.ConstructionRunning then return end
    A.ConstructionRunning=true
    task.spawn(function()
        while A.ConstructionRunning do
            task.wait(1)
            pcall(function()
                if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
                local h=LP.Character:FindFirstChild("Humanoid")
                if not h or h.Health==0 then return end
                if not LP:GetAttribute("WorkingJob") then
                    TP(CFrame.new(-1729,371,-1171)) task.wait(0.4)
                    fireproximityprompt(workspace.ConstructionStuff["Start Job"].Prompt)
                    repeat task.wait() until LP:GetAttribute("WorkingJob") or not A.ConstructionRunning
                end
                if not LP.Backpack:FindFirstChild("PlyWood") and not LP.Character:FindFirstChild("PlyWood") then
                    TP(CFrame.new(-1728,371,-1178))
                    repeat task.wait() fireproximityprompt(workspace.ConstructionStuff["Grab Wood"].Prompt)
                    until LP.Backpack:FindFirstChild("PlyWood") or LP.Character:FindFirstChild("PlyWood")
                        or not A.ConstructionRunning
                end
                repeat task.wait() until LP.Backpack:FindFirstChild("PlyWood")
                    or LP.Character:FindFirstChild("PlyWood") or not A.ConstructionRunning
                if LP.Backpack:FindFirstChild("PlyWood") then
                    LP.Character.Humanoid:EquipTool(LP.Backpack:FindFirstChild("PlyWood"))
                end
                local tw
                for _,v in pairs(workspace.ConstructionStuff:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.ActionText=="Wall" then tw=v break end
                end
                if tw and tw.Parent then
                    TP(tw.Parent.CFrame+Vector3.new(0,3,0)) task.wait(0.4)
                    fireproximityprompt(tw) task.wait(1)
                end
            end)
        end
    end)
end
A.stopConstructionAutofarm=function() A.ConstructionRunning=false end

-- INSTANT PROMPTS
local pConn={}
local pAdded=nil
local function setupPrompt(p,e)
    if not p or not p:IsA("ProximityPrompt") then return end
    if e then p.HoldDuration=0 p.RequiresLineOfSight=false pConn[p]=true
    else p.HoldDuration=1 p.RequiresLineOfSight=true pConn[p]=nil end
end
A.refreshPrompts=function(e)
    for p in pairs(pConn) do pConn[p]=nil end
    for _,p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then setupPrompt(p,e) end
    end
    if pAdded then pAdded:Disconnect() pAdded=nil end
    if e then
        pAdded=workspace.DescendantAdded:Connect(function(d)
            if d:IsA("ProximityPrompt") then setupPrompt(d,true) end
        end)
    end
end

if PromptSvc then
    PromptSvc.PromptButtonHoldBegan:Connect(function(prompt,sp)
        if not (prompt and sp==LP and A.BypassLockedCars) then return end
        local ck=prompt.Parent
        while ck and ck.Parent do
            local s=ck:FindFirstChild("DriveSeat")
            if s and s:IsA("VehicleSeat") and LP.Character and LP.Character:FindFirstChild("Humanoid") then
                pcall(function() s:Sit(LP.Character.Humanoid) end) break
            end
            ck=ck.Parent
        end
    end)
end

-- LOOPS
task.spawn(function()
    while task.wait(0.1) do
        if A.FasterRespawn and LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid")
            if h and h:GetState()==Enum.HumanoidStateType.Dead then
                local lc=RS:FindFirstChild("LoadCharacter")
                if lc and lc:IsA("RemoteEvent") then pcall(function() lc:FireServer() end) end
            end
        end
    end
end)
RunSvc.RenderStepped:Connect(function()
    if A.NoCameraBob then
        local c=LP.Character local h=c and c:FindFirstChildOfClass("Humanoid")
        if h and h.CameraOffset.Magnitude>0 then h.CameraOffset=Vector3.zero end
    end
end)
task.spawn(function()
    while task.wait(0.1) do
        if A.AutoFOnLowHealth then
            local c=LP.Character local h=c and c:FindFirstChildOfClass("Humanoid")
            if h and h.Health>0 and h.Health<10 then
                pcall(function()
                    local VIM=game:GetService("VirtualInputManager")
                    VIM:SendKeyEvent(true,Enum.KeyCode.F,false,nil) task.wait(0.05)
                    VIM:SendKeyEvent(false,Enum.KeyCode.F,false,nil)
                end)
            end
        end
    end
end)
task.spawn(function()
    while task.wait(1) do
        if A.AutoGrabMoney then
            local d=workspace:FindFirstChild("Dollas")
            if d then
                for _,it in ipairs(d:GetChildren()) do
                    if not A.AutoGrabMoney then break end
                    if (it.Name=="DeadMoney" or it.Name=="Money") and it:IsA("BasePart") then
                        local pr=it:FindFirstChildWhichIsA("ProximityPrompt",true)
                        if pr and pr.Enabled then
                            local c=LP.Character or LP.CharacterAdded:Wait()
                            local r=c:FindFirstChild("HumanoidRootPart") if not r then break end
                            local o=r.CFrame
                            TP(it.CFrame+Vector3.new(0,2,0)) task.wait(0.3)
                            fireproximityprompt(pr) task.wait(0.3)
                            TP(o) task.wait(0.5)
                        end
                    end
                end
            end
        end
        if A.AutoPickupBags and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local st=workspace:FindFirstChild("Storage")
            if st then
                for _,v in next,st:GetChildren() do
                    if v:IsA("MeshPart") then
                        if v:FindFirstChild("PlayerName") and v.PlayerName.Value==LP.Name then break end
                        if (v.Position-LP.Character.HumanoidRootPart.Position).Magnitude<5 then
                            local p=v:FindFirstChild("stealprompt")
                            if p and p:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(p) end) end
                        end
                    end
                end
            end
        end
        if A.DisableBloodEffects and A.PG:FindFirstChild("BloodGui") then A.PG.BloodGui.Enabled=false end
    end
end)
task.spawn(function()
    while task.wait(1200) do
        if A.AntiAFKEnabled then
            pcall(function()
                local VU=game:GetService("VirtualUser")
                VU:CaptureController() VU:ClickButton2(Vector2.new())
            end)
        end
    end
end)
task.spawn(function()
    while task.wait(1) do
        if A.AutoStealLootbags then
            local st=workspace:FindFirstChild("Storage")
            if st then
                for _,it in ipairs(st:GetChildren()) do
                    if not A.AutoStealLootbags then break end
                    local pr=it:FindFirstChild("stealprompt",true)
                    if pr and pr:IsA("ProximityPrompt") and pr.Enabled then
                        local c=LP.Character or LP.CharacterAdded:Wait()
                        local r=c:FindFirstChild("HumanoidRootPart") if not r then break end
                        local o=r.CFrame
                        local tp=pr.Parent:IsA("BasePart") and pr.Parent or it:FindFirstChildWhichIsA("BasePart",true)
                        if not tp then break end
                        TP(tp.CFrame+Vector3.new(0,2,0)) task.wait(0.3)
                        fireproximityprompt(pr) task.wait(0.3)
                        TP(o) task.wait(0.5)
                    end
                end
            end
        end
    end
end)

-- SAFE / DUPE
A.dupeBlacklist={["Fists"]=true,["Fist"]=true,["Phone"]=true,["Car Keys"]=true,
    ["Car keys"]=true,["Bandage"]=true,["762s"]=true,["556s"]=true,
    ["Extended"]=true,["T shirt"]=true,["Combat"]=true,["Weight"]=true,
    ["Shiesty"]=true,["Lemonade"]=true}
local BL=A.dupeBlacklist

A.ShowBigAlert=function(msg)
    local cg=(gethui and gethui()) or A.CoreGui or A.PG
    local sg=A.new("ScreenGui",{Name="aqxAlert_"..tostring(math.random(10000,99999)),
        IgnoreGuiInset=true,DisplayOrder=99999},cg)
    local t=A.new("TextLabel",{Size=UDim2.new(1,0,0,100),Position=UDim2.new(0,0,0.2,0),
        BackgroundTransparency=1,Text=msg,TextColor3=Color3.fromRGB(255,50,50),
        Font=Enum.Font.GothamBlack,TextSize=40,TextStrokeTransparency=0,
        TextStrokeColor3=Color3.new(0,0,0),TextTransparency=1},sg)
    task.spawn(function()
        for _=1,10 do t.TextTransparency=t.TextTransparency-0.1 task.wait(0.03) end
        task.wait(2)
        for _=1,10 do
            t.TextTransparency=t.TextTransparency+0.1
            t.Position=t.Position-UDim2.new(0,0,0.01,0) task.wait(0.03)
        end
        sg:Destroy()
    end)
end

A.SilentBypassTeleport=function(cf)
    local c=LP.Character local r=c and c:FindFirstChild("HumanoidRootPart")
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if not r then return end
    if h then pcall(function() h:ChangeState(0) end) end
    local sw=tick()
    repeat task.wait() until not LP:GetAttribute("LastACPos") or (tick()-sw>1)
    r.CFrame=cf r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
    task.wait(0.5)
    if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
end

A.GetActiveSafe=function()
    local function isMine(o)
        if not o then return false end
        if o:IsA("ObjectValue") then return o.Value==LP end
        local v=tostring(o.Value or "")
        return v==LP.Name or v==LP.DisplayName
    end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o.Name:lower()=="owner" and (o:IsA("StringValue") or o:IsA("ObjectValue")) and isMine(o) then
            local anc=o.Parent
            while anc and anc~=workspace do
                local sf=anc:FindFirstChild("Safe",true)
                if sf then
                    local sp
                    if sf:IsA("BasePart") then sp=sf
                    else sp=sf:FindFirstChild("Union",true) or sf:FindFirstChildWhichIsA("BasePart",true) end
                    return sf,nil,sp and sp.CFrame or nil
                end
                anc=anc.Parent
            end
        end
    end
    return nil,nil,nil
end

A.GetSafeItems=function()
    local items={}
    local id=LP:FindFirstChild("InvData")
    if id then for _,c in ipairs(id:GetChildren()) do table.insert(items,c.Name) end end
    table.sort(items) return items
end
A.GetLockedTools=function()
    local t={}
    if BP then
        for _,x in pairs(BP:GetChildren()) do
            if x:IsA("Tool") and not BL[x.Name] then table.insert(t,x.Name) end
        end
    end
    return t
end
A.FirePromptsInArea=function(range,nf)
    local c=LP.Character local r=c and c:FindFirstChild("HumanoidRootPart")
    if not r then return 0 end
    local fired=0 local fl=nf and tostring(nf):lower() or nil
    for _,p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Enabled then
            local par=p.Parent
            local pt=par and (par:IsA("BasePart") and par or par:FindFirstChildWhichIsA("BasePart",true))
            local pp=pt and pt.Position
            if pp and (pp-r.Position).Magnitude<range then
                local txt=(tostring(p.Name).." "..tostring(p.ActionText).." "..tostring(p.ObjectText)):lower()
                local anc=par
                for _=1,5 do
                    if not anc then break end
                    txt=txt.." "..tostring(anc.Name):lower() anc=anc.Parent
                end
                if not fl or txt:find(fl,1,true) then
                    pcall(function()
                        p.HoldDuration=0 p.RequiresLineOfSight=false
                        fireproximityprompt(p)
                    end)
                    fired=fired+1
                end
            end
        end
    end
    return fired
end
A.OpenOwnedSafe=function(sf,scf)
    if not sf or not scf then return false,"Safe not found" end
    A.SilentBypassTeleport(scf*CFrame.new(0,2,0)) task.wait(0.45)
    local fired=0
    for _,p in ipairs(sf:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Enabled then
            local ok=pcall(function()
                p.HoldDuration=0 p.RequiresLineOfSight=false
                fireproximityprompt(p)
            end)
            if ok then fired=fired+1 end
        end
    end
    if fired==0 then fired=A.FirePromptsInArea(18,"safe") end
    if fired==0 then fired=A.FirePromptsInArea(7) end
    return fired>0,fired>0 and nil or "No safe prompt"
end
A.TakeFromSafe=function(n)
    local sf,_,scf=A.GetActiveSafe()
    if not sf or not scf then A.ShowBigAlert("You must own a house to dupe!") return false end
    local c=LP.Character local r=c and c:FindFirstChild("HumanoidRootPart")
    if not r then return false end
    local o=r.CFrame local ok=false
    pcall(function()
        A.SilentBypassTeleport(scf*CFrame.new(0,2,0)) task.wait(0.3)
        if A.InventoryRemote then A.InventoryRemote:FireServer("Change",n,"Inv",sf) end
        task.wait(0.5) A.SilentBypassTeleport(o) task.wait(0.5) ok=true
    end)
    return ok
end
A.SafeDupeOnce=function(n,ret)
    local sf,_,scf=A.GetActiveSafe()
    if not sf or not scf then A.ShowBigAlert("You must own a house to dupe!") return false end
    pcall(function()
        A.SilentBypassTeleport(scf*CFrame.new(0,2,0)) task.wait(0.3)
        if A.BackpackRemote then task.spawn(function() A.BackpackRemote:InvokeServer("Store",n) end) end
        if A.InventoryRemote then task.spawn(function() A.InventoryRemote:FireServer("Change",n,"Backpack",sf) end) end
        task.wait(0.6) A.SilentBypassTeleport(ret) task.wait(1.2)
        if A.BackpackRemote then A.BackpackRemote:InvokeServer("Grab",n) end
        task.wait(0.5)
    end)
    return true
end

A.autoDupeActive=false A.dupeCounter=0 A.selectedDupeItem=nil
A.DoDupe=function(speed)
    local c=LP.Character local r=c and c:FindFirstChild("HumanoidRootPart")
    if not r then notify("Dupe","No character!") return end
    local orig=r.CFrame A.autoDupeActive=true
    notify("Dupe","Starting safe dupe...")
    local locked=A.GetLockedTools()
    if not A.selectedDupeItem or A.selectedDupeItem=="None" then
        if #locked==0 then A.autoDupeActive=false notify("Dupe","No tools.") return end
    end
    task.spawn(function()
        local sf,_,scf=A.GetActiveSafe()
        if not sf then A.ShowBigAlert("You must own a house to dupe!") A.autoDupeActive=false return end
        if scf then
            notify("Dupe","Opening Safe...")
            A.SilentBypassTeleport(scf*CFrame.new(0,2,0)) task.wait(0.7)
            A.FirePromptsInArea(15,"Safe")
        end
        notify("Dupe","Returning...")
        A.SilentBypassTeleport(orig) task.wait(0.5)
        local i=1
        while A.autoDupeActive and (speed==math.huge or i<=speed) do
            local item=A.selectedDupeItem
            if not item or item=="None" then item=locked[((i-1)%#locked)+1] end
            A.SafeDupeOnce(item,orig)
            A.dupeCounter=A.dupeCounter+1 task.wait(0.2) i=i+1
        end
        A.autoDupeActive=false
        notify("Dupe","Stopped. Total: "..A.dupeCounter)
    end)
end
A.SafeTP=function()
    local c=LP.Character local r=c and c:FindFirstChild("HumanoidRootPart")
    if not r then notify("Safe TP","No character!") return end
    notify("Safe TP","Finding your owned safe...")
    task.spawn(function()
        local ok,err=pcall(function()
            local sf,_,scf=A.GetActiveSafe()
            if not sf or not scf then
                A.ShowBigAlert("Could not find your owned house safe!")
                notify("Safe TP","Owned safe not found.") return
            end
            local o,r2=A.OpenOwnedSafe(sf,scf)
            if o then notify("Safe TP","Safe prompt fired.") else notify("Safe TP",tostring(r2 or "Failed")) end
        end)
        if not ok then notify("Safe TP Error",tostring(err)) end
    end)
end
local autoDropOn=false
A.ToggleAutoDrop=function(state)
    local dr=RS:FindFirstChild("DropItemRemote")
    autoDropOn=state
    notify("Auto Drop",state and "Started" or "Stopped")
    if state then
        task.spawn(function()
            while autoDropOn do
                local bp=BP local ch=LP.Character
                if not bp or not ch then task.wait(0.5)
                else
                    local found=false
                    for _,it in ipairs(bp:GetChildren()) do
                        if not autoDropOn then break end
                        if it:IsA("Tool") and not BL[it.Name] then
                            found=true
                            local h=ch:FindFirstChildOfClass("Humanoid")
                            if h then
                                h:EquipTool(it)
                                local dt=tick()
                                repeat
                                    if dr then
                                        pcall(function() dr:FireServer(it.Name) end)
                                        pcall(function() dr:FireServer(it) end)
                                        pcall(function() dr:FireServer() end)
                                    end
                                    task.wait(0.2)
                                until not it:IsDescendantOf(ch) or not autoDropOn or (tick()-dt>3)
                                task.wait(0.1)
                            end
                        end
                    end
                    if not found then task.wait(1) end
                end
                task.wait(0.1)
            end
        end)
    end
end

-- EMOTES
A.MianiEmotes={["CSnoop"]=86123328011397,["Air Cycle"]=94324173536622,
    ["Assumptions"]=91294374426630,["Basketball Headspin"]=92854797386719,
    ["Beat Da Koto Nai"]=93497729736287,["Biblically Accurate"]=109873544976020,
    ["Billy Bounce"]=137501135905857,["Bird"]=85513310484654,
    ["Caramelldansen"]=88315693621494,["Chinese Dance"]=131758838511368,
    ["Classic Walk"]=107806791584829,["Cute Stomach Lay"]=80754582835479,
    ["Da Hood Dance"]=108171959207138,["Fake Death"]=88130117312312,
    ["Fight Stance"]=116763940575803,["Float"]=89523370947906,
    ["Lay Float"]=77840765435893,["Floppin Fish"]=79075971527754,
    ["Flying"]=138433137191760,["Flying Legs"]=130932988394284,
    ["Fropper"]=116039975531632,["Fumo Flush"]=107217181254431,
    ["Shoulder Taps"]=85422671683973,["Helicopter"]=95301257497525,
    ["Helicopter 2"]=91257498644328,["Jackhammer"]=91423662648449,
    ["Jojo Pose"]=120629563851640,["Laced"]=135611169366768,["Buddha"]=86872878957632,
    ["Monstermash"]=137883764619555,["Oh Who Is You"]=81389876138766,
    ["Parrot"]=101810746304426,["Push Up"]=115703320436202,["Rizz Backup"]=131205329995035,
    ["Shot"]=102691551292124,["Slickback"]=74288964113793,["Soda Pop"]=105459130960429,
    ["Take The L"]=78653596566468,["The Worm"]=90333292347820,
    ["Spider Man Hang"]=128616254665784,["Weird Boy"]=87025086742503,
    ["Xavier"]=90802740360125,["Dougie"]=126035888065434,["BACKFLIP"]=15693621070}
A.MianiEmoteNames={}
for n in pairs(A.MianiEmotes) do table.insert(A.MianiEmoteNames,n) end
table.sort(A.MianiEmoteNames)
A.MianiSelectedEmoteName="Take The L" A.MianiCurrentEmoteTrack=nil
A.MianiEmoteAnimCache={} A.MianiEmoteSettings={Loop=true}

local function emoAnim()
    local c=LP.Character or LP.CharacterAdded:Wait()
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if not h then return nil end
    local a=h:FindFirstChildOfClass("Animator")
    if not a then a=Instance.new("Animator") a.Parent=h end
    return a
end
A.MianiStopAllTracks=function()
    local a=emoAnim()
    if a then for _,t in ipairs(a:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0.1) end) end end
    A.MianiCurrentEmoteTrack=nil
end
A.MianiPlayEmoteById=function(id,name)
    id=tonumber(id) if not id then return end
    local a=emoAnim() if not a then return end
    A.MianiStopAllTracks()
    local an=A.MianiEmoteAnimCache[id]
    if not an then
        an=Instance.new("Animation") an.AnimationId="rbxassetid://"..tostring(id)
        A.MianiEmoteAnimCache[id]=an
    end
    local ok,tr=pcall(function()
        local t=a:LoadAnimation(an)
        t.Priority=Enum.AnimationPriority.Action
        t.Looped=A.MianiEmoteSettings.Loop
        t:Play(0.1) return t
    end)
    if ok and tr then A.MianiCurrentEmoteTrack=tr notify("Emotes","Playing: "..tostring(name or id)) end
end

-- OUTFITS
A.applyOutfit=function(name,ins)
    pcall(function() RS.ClothShopRemote:FireServer("Reset Data") end) task.wait(0.2)
    for _,i in ipairs(ins) do
        pcall(function() RS.ClothShopRemote:FireServer(i[1],i[2],i[3]) end) task.wait(0.1)
    end
    notify("Outfit","Applied "..name)
end
A.ApplyDripstoreClothing=function(cat,item)
    if not cat or not item then return end
    if not LP:FindFirstChild(cat) then return end
    pcall(function()
        if not LP[cat]:FindFirstChild(item) then
            RS.ClothShopRemote:FireServer("Buy",cat,item) task.wait(0.05)
        end
        RS.ClothShopRemote:FireServer("Wear",cat,item)
    end)
end
A.RandomClothes={Shirts={
    "Black AMiri 22","Blu C Amiri Hoodie","TankTop Wit Blue B","TankTop Wit RedFlag",
    "TankTok Wit Black","Purple B Puffer","Green Varsity","ChromeHeart Blue","PastalBlue Jacket",
    "Grey Hoodie Wit Red","Balmain Hoodie","White Balmain Hoodie","Black PalmAngel Jacket",
    "Blu Moncler","White Polo Vest","White Tatted T shirt","Red B Jacket","Grey Amiri Hoodie",
    "Bzz Blue Hoodie","Xunners Yankee W Tattoo","Amiri Varsity Jacket","Tan Mechanic X",
    "Black Tatted T Shirt","Amiri Star Hoodie","Tatted Tank To[","Amiri Halloween Shirt",
    "Moncler Tatted Open Shirt","Spiderman","Brown Glo hartt Work","Navy Blue & Red Sp5der Beluga Hoodie",
    "Black Sp5der Jeffery Hoodie","Yellow Spider Supreme Zip Up Jacket","Black Amiri Denim Love Jacket",
    "Black Bapestar sweater","Zipped Moncler Black","Black Chrome Heart Zip Up","Polo Black Moncler + Tats",
    "White Tank Top W/ Shirt on shoulder","Red Zipped Jacket","Y2K Brown & Tan STARS Varsity",
    "Yellow & White Striped Lightning Track Suit","Black & Blue LA Designer Hoodie White Shirt",
    "Pink Y2K","Pink Bape","Moose Grey Hoodie","Purple and Yellow GHOP Hoodie",
    "Black & White Designer Baseball Jersey","Blue and White Chicago OBLOCK Shirt W Tatts",
    "Bathing Ape Bape Camo","White and Black Sniper Gang Superstar Shirt",
    "Red and White Designer Graphic Shirt W Tatts","Tan Brown Graphic Y2K Pullover Hoodie",
    "Grey & Red Designer 99 Denim Jean Jacket","black open jacket w/ purple",
    "Opened Black Zipper Jacket W Tats","Amiri Jean Jacket","BlueTech","WhiteTankTop",
    "BluePalm Jacket","Blue ChromeHeart Jersey","Blue Chrome Hearts Hoodiey","Blue Sp5der Hoodie",
    "Green Sp5der Hoodie","Red Sp5der Sweats","Bandi T Cardi","Black Amiri Star","Blue Hellstar"},
Pants={
    "Black Ripped Jeans","Y2K Khaki pants","Black amiri jeans w jeezy","Hard Jeans LV",
    "Balmain Grey Jeans Wit/ PSD's Jordan 11s","Amiri Jeans w Red Thunder",
    "Y2K Brown & Tan STARS Sweat Joggers","Purple Brand Jeans x Lavins",
    "Black & Tan Y2K Designer Graphic Joggers","Red And Black Checkered CheckMate Joggers",
    "Red Designer Denim Jeans Drip Designer","Grey & Yellow Designer Denim Jeans W Belt",
    "Violet Valk Purple Designer Denim Jeanss","Black and White Designer Denim Jeans",
    "Black PURPLE Brand Jeans w/ Balenciaga Runners","Grey Jeans W/ Red Jz",
    "Ripped Black Jeans w White Thunder 4s","BJeans w White Black Cat 4s","Grey Jean W Dior Runners",
    "ReddyPants","RedTech","BlueTechPants","GreenTechPants1","WhiteTechPants","BluePalmAngels",
    "BluePalm Jacket","Blue Sp5der Sweats","Green Sp5der Sweats","Red Sp5der Sweats",
    "Blue Sp5der Sweats","Sweats Wit Black AF1","Shorts W Dunks","Amiri Jeans x Grey b22",
    "Spiderman","Saint Sinner Jeans","Grey Purple Jeans","Amiri Jean x Retro 13 x LV",
    "Tan Mechanic Pants Black AF1","BabyBlue Nikes","Black PalmAngels","WhiteJeans",
    "White Jeans w AF1","Grey Sweats W Red","Amiri Blue Jeans","Blue Offwhites wit GreyJeams",
    "Black Amiri Jeans B22","Green Ripped Jeans","BlackJeans W Purple LV Flags","Black B Shorts",
    "Red B Shorts","Blu B Shorts","White AF1 BJeans","Amiri Jeans x Grey b22","Pink Bapesta Jeans"}}
A.OutfitSwapDelay=0.2 A.FlashOutfits=false A.FlashOutfitLoopRunning=false

A.Modules2Loaded=true
print("[aqx] modules2 loaded")
