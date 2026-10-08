--[[ aqx modules part 3 ]]

local A=getgenv().aqx
assert(A and A.Modules2Loaded,"aqx modules2 not loaded")
local Players=A.Players local RS=A.RS local RunSvc=A.RunSvc local UIS=A.UIS
local Lighting=A.Lighting local LP=A.LP local notify=A.notify local TP=A.TP

-- COLOR PRESETS
A.VisualColorPresets={["White"]=Color3.fromRGB(255,255,255),["Black"]=Color3.fromRGB(0,0,0),
    ["Red"]=Color3.fromRGB(255,0,0),["Green"]=Color3.fromRGB(0,255,0),
    ["Blue"]=Color3.fromRGB(0,120,255),["Purple"]=Color3.fromRGB(143,0,255),
    ["Pink"]=Color3.fromRGB(255,80,180),["Cyan"]=Color3.fromRGB(0,255,255),
    ["Yellow"]=Color3.fromRGB(255,255,0),["Orange"]=Color3.fromRGB(255,140,0),
    ["Lime"]=Color3.fromRGB(130,255,0),["Gray"]=Color3.fromRGB(120,120,120)}
A.VisualColorNames={}
for n in pairs(A.VisualColorPresets) do table.insert(A.VisualColorNames,n) end
table.sort(A.VisualColorNames)

A.WorldVisuals={SaturationEnabled=false,SaturationValue=1,StretchEnabled=false,
    StretchValue=0.7,FogColorEnabled=false,FogColor=Color3.fromRGB(255,255,255),
    AmbientEnabled=false,AmbientColor=Color3.fromRGB(255,255,255),
    FieldOfViewEnabled=false,FieldOfViewValue=70,Fullbright=false}
local WV=A.WorldVisuals

A.ESPFlags={Enabled=false,RenderDistance=1400,TeamColor=true,Boxes=true,BoxType="Corner",
    BoxColor=Color3.fromRGB(255,140,0),BoxFill=false,BoxFillColor=Color3.fromRGB(255,255,255),
    Healthbar=true,HealthbarNumber=false,HealthbarThickness=3,Name=true,Distance=true,Weapon=false,
    FriendMarker=true,FriendColor=Color3.fromRGB(0,255,0),TextSize=14,
    TextColor=Color3.fromRGB(245,245,245),Snaplines=false,SnaplineColor=Color3.fromRGB(255,140,0),
    Chams=false,ChamsColor=Color3.fromRGB(255,140,0),Skeleton=false,
    SkeletonColor=Color3.fromRGB(255,255,255),LookTracers=false,LookTracerColor=Color3.fromRGB(0,255,255)}
local EF=A.ESPFlags

local HAS_DRAWING=(type(Drawing)=="table" and type(Drawing.new)=="function")
local function createDrawing(cls,props)
    if not HAS_DRAWING then return {Visible=false,Remove=function() end} end
    local ok,o=pcall(Drawing.new,cls)
    if not ok or not o then return {Visible=false,Remove=function() end} end
    for k,v in pairs(props or {}) do pcall(function() o[k]=v end) end
    return o
end

local ESPObjects={}
local HighlightObjects={}
local ESPFriendCache={}
local SkeletonPairs={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}

local function isFriend(p)
    if not p or p==LP then return false end
    if ESPFriendCache[p]==nil then
        local ok,f=pcall(function() return LP:IsFriendsWith(p.UserId) end)
        ESPFriendCache[p]=ok and f==true or false
    end
    return ESPFriendCache[p]
end
local function createESP(p)
    if p==LP or ESPObjects[p] then return end
    local box={}
    for _,n in ipairs({"Top","Bottom","Left","Right","TopLeft","TopRight","BottomLeft","BottomRight"}) do
        box[n]=createDrawing("Line",{Visible=false,Thickness=1.6,Color=EF.BoxColor})
    end
    local sk={}
    for i=1,#SkeletonPairs do sk[i]=createDrawing("Line",{Visible=false,Thickness=1,Color=EF.SkeletonColor}) end
    ESPObjects[p]={Box=box,
        Fill=createDrawing("Square",{Visible=false,Filled=true,Transparency=0.85,Color=EF.BoxFillColor}),
        HealthOutline=createDrawing("Square",{Visible=false,Filled=false,Color=Color3.fromRGB(0,0,0),Thickness=1}),
        HealthFill=createDrawing("Square",{Visible=false,Filled=true,Color=Color3.fromRGB(0,255,0)}),
        HealthText=createDrawing("Text",{Visible=false,Center=true,Outline=true,Size=EF.TextSize,Color=Color3.fromRGB(255,255,255)}),
        Name=createDrawing("Text",{Visible=false,Center=true,Outline=true,Size=EF.TextSize,Color=EF.TextColor}),
        FriendTag=createDrawing("Text",{Visible=false,Center=true,Outline=true,Size=EF.TextSize,Color=EF.FriendColor,Text="(F)"}),
        Distance=createDrawing("Text",{Visible=false,Center=true,Outline=true,Size=EF.TextSize,Color=EF.TextColor}),
        Weapon=createDrawing("Text",{Visible=false,Center=true,Outline=true,Size=EF.TextSize,Color=EF.TextColor}),
        Snapline=createDrawing("Line",{Visible=false,Thickness=1.2,Color=EF.SnaplineColor}),
        LookTracer=createDrawing("Line",{Visible=false,Thickness=1,Color=EF.LookTracerColor}),
        Skeleton=sk}
end
local function hideESPObj(o)
    if not o then return end
    if o.Box then for _,l in pairs(o.Box) do l.Visible=false end end
    if o.Skeleton then for _,l in ipairs(o.Skeleton) do l.Visible=false end end
    for _,k in ipairs({"Fill","HealthOutline","HealthFill","HealthText","Name","FriendTag","Distance","Weapon","Snapline","LookTracer"}) do
        if o[k] then o[k].Visible=false end
    end
end
local function removeESP(p)
    local o=ESPObjects[p]
    if o then
        if o.Box then for _,l in pairs(o.Box) do pcall(function() l:Remove() end) end end
        if o.Skeleton then for _,l in ipairs(o.Skeleton) do pcall(function() l:Remove() end) end end
        for _,k in ipairs({"Fill","HealthOutline","HealthFill","HealthText","Name","FriendTag","Distance","Weapon","Snapline","LookTracer"}) do
            if o[k] then pcall(function() o[k]:Remove() end) end
        end
        ESPObjects[p]=nil
    end
    if HighlightObjects[p] then pcall(function() HighlightObjects[p]:Destroy() end) HighlightObjects[p]=nil end
    ESPFriendCache[p]=nil
end
local function espColor(p,def)
    if EF.TeamColor and p.Team and LP.Team and p.Team==LP.Team then return Color3.fromRGB(0,120,255) end
    return def
end
local function updLine(l,f,t,c) if not l then return end l.From=f l.To=t l.Color=c l.Visible=true end
for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local _espHidden=false
local function hideESPForPlayer(p)
    hideESPObj(ESPObjects[p])
    if HighlightObjects[p] then HighlightObjects[p].Enabled=false end
end
local function updateESP(p,cam)
    if p==LP then hideESPForPlayer(p) return end
    createESP(p)
    local o=ESPObjects[p] local ch=p.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local r=ch and ch:FindFirstChild("HumanoidRootPart")
    if not (o and ch and h and r and h.Health>0) then hideESPForPlayer(p) return end
    local lr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local d=lr and (r.Position-lr.Position).Magnitude or (r.Position-cam.CFrame.Position).Magnitude
    if d>EF.RenderDistance then hideESPForPlayer(p) return end
    local rp,onS=cam:WorldToViewportPoint(r.Position)
    if not onS or rp.Z<=0 then hideESPForPlayer(p) return end
    local sz=ch:GetExtentsSize()
    local tp=cam:WorldToViewportPoint((r.CFrame*CFrame.new(0,sz.Y/2,0)).Position)
    local bt=cam:WorldToViewportPoint((r.CFrame*CFrame.new(0,-sz.Y/2,0)).Position)
    if tp.Z<=0 or bt.Z<=0 then hideESPForPlayer(p) return end
    local ht=math.max(math.abs(bt.Y-tp.Y),2)
    local wd=math.max(ht*0.58,2)
    local x,y=tp.X-wd/2,tp.Y
    local bc=espColor(p,EF.BoxColor) local tc=EF.TextColor
    if EF.BoxFill then
        o.Fill.Position=Vector2.new(x,y) o.Fill.Size=Vector2.new(wd,ht)
        o.Fill.Color=EF.BoxFillColor o.Fill.Transparency=0.85 o.Fill.Visible=true
    else o.Fill.Visible=false end
    if EF.Boxes then
        local tl,tr=Vector2.new(x,y),Vector2.new(x+wd,y)
        local bl,br=Vector2.new(x,y+ht),Vector2.new(x+wd,y+ht)
        local co=math.min(wd,ht)*0.28
        if EF.BoxType=="Full" then
            updLine(o.Box.Top,tl,tr,bc) updLine(o.Box.Bottom,bl,br,bc)
            updLine(o.Box.Left,tl,bl,bc) updLine(o.Box.Right,tr,br,bc)
            o.Box.TopLeft.Visible=false o.Box.TopRight.Visible=false
            o.Box.BottomLeft.Visible=false o.Box.BottomRight.Visible=false
        else
            o.Box.Top.Visible=false o.Box.Bottom.Visible=false
            o.Box.Left.Visible=false o.Box.Right.Visible=false
            updLine(o.Box.TopLeft,tl,tl+Vector2.new(co,0),bc)
            updLine(o.Box.Left,tl,tl+Vector2.new(0,co),bc)
            updLine(o.Box.TopRight,tr,tr-Vector2.new(co,0),bc)
            updLine(o.Box.Right,tr,tr+Vector2.new(0,co),bc)
            updLine(o.Box.BottomLeft,bl,bl+Vector2.new(co,0),bc)
            updLine(o.Box.Bottom,bl,bl-Vector2.new(0,co),bc)
            updLine(o.Box.BottomRight,br,br-Vector2.new(co,0),bc)
            updLine(o.Box.Top,br,br-Vector2.new(0,co),bc)
        end
    else
        for _,l in pairs(o.Box) do l.Visible=false end
    end
    if EF.Healthbar then
        local pc=math.clamp(h.Health/math.max(h.MaxHealth,1),0,1)
        local bh=ht*pc
        o.HealthOutline.Position=Vector2.new(x-7,y)
        o.HealthOutline.Size=Vector2.new(EF.HealthbarThickness+2,ht)
        o.HealthOutline.Visible=true
        o.HealthFill.Position=Vector2.new(x-6,y+ht-bh)
        o.HealthFill.Size=Vector2.new(EF.HealthbarThickness,bh)
        o.HealthFill.Color=Color3.fromRGB(255-(255*pc),255*pc,0)
        o.HealthFill.Visible=true
        if EF.HealthbarNumber then
            o.HealthText.Text=tostring(math.floor(h.Health))
            o.HealthText.Position=Vector2.new(x-12,y+ht-bh)
            o.HealthText.Size=EF.TextSize o.HealthText.Visible=true
        else o.HealthText.Visible=false end
    else
        o.HealthOutline.Visible=false o.HealthFill.Visible=false o.HealthText.Visible=false
    end
    local bo=2
    if EF.Name then
        o.Name.Text=p.DisplayName~=p.Name and (p.DisplayName.." (@"..p.Name..")") or p.Name
        o.Name.Position=Vector2.new(x+wd/2,y-EF.TextSize-2)
        o.Name.Size=EF.TextSize o.Name.Color=tc o.Name.Visible=true
        if EF.FriendMarker and isFriend(p) then
            local nw=(#tostring(o.Name.Text)*EF.TextSize*0.28)
            o.FriendTag.Text="(F)"
            o.FriendTag.Position=Vector2.new((x+wd/2)-nw-10,y-EF.TextSize-2)
            o.FriendTag.Size=EF.TextSize o.FriendTag.Color=EF.FriendColor o.FriendTag.Visible=true
        else o.FriendTag.Visible=false end
    else o.Name.Visible=false o.FriendTag.Visible=false end
    if EF.Distance then
        o.Distance.Text=tostring(math.floor(d)).."m"
        o.Distance.Position=Vector2.new(x+wd/2,y+ht+bo)
        o.Distance.Size=EF.TextSize o.Distance.Color=tc o.Distance.Visible=true
        bo=bo+EF.TextSize+1
    else o.Distance.Visible=false end
    if EF.Weapon then
        local tool=ch:FindFirstChildOfClass("Tool")
        o.Weapon.Text=tool and ("["..tool.Name.."]") or "[None]"
        o.Weapon.Position=Vector2.new(x+wd/2,y+ht+bo)
        o.Weapon.Size=EF.TextSize o.Weapon.Color=tc o.Weapon.Visible=true
    else o.Weapon.Visible=false end
    if EF.Snaplines then
        o.Snapline.From=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
        o.Snapline.To=Vector2.new(rp.X,rp.Y)
        o.Snapline.Color=espColor(p,EF.SnaplineColor) o.Snapline.Visible=true
    else o.Snapline.Visible=false end
    if EF.LookTracers and ch:FindFirstChild("Head") then
        local hd=ch.Head
        local p1,o1=cam:WorldToViewportPoint(hd.Position)
        local p2,o2=cam:WorldToViewportPoint(hd.Position+hd.CFrame.LookVector*10)
        if o1 and o2 and p1.Z>0 and p2.Z>0 then
            o.LookTracer.From=Vector2.new(p1.X,p1.Y) o.LookTracer.To=Vector2.new(p2.X,p2.Y)
            o.LookTracer.Color=EF.LookTracerColor o.LookTracer.Visible=true
        else o.LookTracer.Visible=false end
    else o.LookTracer.Visible=false end
    if EF.Skeleton then
        for i,pr in ipairs(SkeletonPairs) do
            local a2,b2=ch:FindFirstChild(pr[1]),ch:FindFirstChild(pr[2])
            if a2 and b2 and o.Skeleton[i] then
                local pa,oa=cam:WorldToViewportPoint(a2.Position)
                local pb,ob=cam:WorldToViewportPoint(b2.Position)
                if oa and ob and pa.Z>0 and pb.Z>0 then
                    o.Skeleton[i].From=Vector2.new(pa.X,pa.Y) o.Skeleton[i].To=Vector2.new(pb.X,pb.Y)
                    o.Skeleton[i].Color=EF.SkeletonColor o.Skeleton[i].Visible=true
                else o.Skeleton[i].Visible=false end
            elseif o.Skeleton[i] then o.Skeleton[i].Visible=false end
        end
    else
        for _,l in ipairs(o.Skeleton) do l.Visible=false end
    end
    if EF.Chams then
        local h2=HighlightObjects[p]
        if not h2 or not h2.Parent then
            h2=Instance.new("Highlight") h2.Name="aqxESPHighlight"
            h2.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            h2.Parent=A.CoreGui or A.PG
            HighlightObjects[p]=h2
        end
        h2.Adornee=ch h2.FillColor=espColor(p,EF.ChamsColor)
        h2.OutlineColor=Color3.fromRGB(255,255,255)
        h2.FillTransparency=0.55 h2.OutlineTransparency=0.1 h2.Enabled=true
    elseif HighlightObjects[p] then HighlightObjects[p].Enabled=false end
end
RunSvc.RenderStepped:Connect(function()
    if not HAS_DRAWING then return end
    if not EF.Enabled then
        if not _espHidden then
            _espHidden=true
            for _,p in ipairs(Players:GetPlayers()) do hideESPForPlayer(p) end
        end
        return
    end
    _espHidden=false
    local cam=workspace.CurrentCamera if not cam then return end
    for _,p in ipairs(Players:GetPlayers()) do
        local ok=pcall(updateESP,p,cam)
        if not ok then hideESPForPlayer(p) end
    end
end)

-- HITBOX
A.HitboxVisuals={Enabled=false,Part="Head",Multiplier=5,Transparency=0.45,
    Material="ForceField",Type="Ball",CanCollide=false,Massless=true,
    TeamCheck=false,Color=Color3.fromRGB(55,235,120)}
local HV=A.HitboxVisuals
local CandidateParts={"Head","HumanoidRootPart","UpperTorso","LowerTorso",
    "LeftUpperArm","LeftLowerArm","RightUpperArm","RightLowerArm",
    "LeftUpperLeg","LeftLowerLeg","RightUpperLeg","RightLowerLeg"}
local DefaultPlayerSettings={}
local HitboxWorkerBound={}
local function capPS(p)
    if not p or not p:IsA("BasePart") then return nil end
    return {Size=p.Size,Transparency=p.Transparency,CanCollide=p.CanCollide,
        CanQuery=p.CanQuery,CanTouch=p.CanTouch,Massless=p.Massless,
        Material=p.Material,Color=p.Color}
end
local function saveDPS(p)
    if not p or p==LP or not p.Character then return end
    local ch=p.Character
    if not ch:FindFirstChildOfClass("Humanoid") then return end
    local cur=DefaultPlayerSettings[p]
    if cur and cur.Character==ch then return end
    local s={Character=ch,Parts={}}
    for _,pn in ipairs(CandidateParts) do
        local pt=ch:FindFirstChild(pn)
        if pt and pt:IsA("BasePart") then s.Parts[pn]=capPS(pt) end
    end
    DefaultPlayerSettings[p]=s
end
local function restPS(pt,st)
    if not pt or not st then return end
    for i,v in pairs(st) do pcall(function() pt[i]=v end) end
end
local function restDPS(p)
    local s=DefaultPlayerSettings[p] local ch=p and p.Character
    if not s or not ch or s.Character~=ch then return end
    for pn,st in pairs(s.Parts) do
        local pt=ch:FindFirstChild(pn)
        if pt then restPS(pt,st) end
    end
end
local function applyHit(pt)
    if not pt or not pt:IsA("BasePart") then return end
    pt.Size=Vector3.new(HV.Multiplier,HV.Multiplier,HV.Multiplier)
    pt.Transparency=HV.Transparency
    pt.Material=Enum.Material[HV.Material] or Enum.Material.ForceField
    pt.Color=HV.Color pt.CanCollide=HV.CanCollide
    pt.CanQuery=true pt.CanTouch=false pt.Massless=HV.Massless
    pcall(function()
        if pt:IsA("Part") and Enum.PartType[HV.Type] then pt.Shape=Enum.PartType[HV.Type] end
    end)
end
local function connectHit(p)
    if not p or p==LP or HitboxWorkerBound[p] then return end
    HitboxWorkerBound[p]=true
    task.spawn(function()
        while p and p.Parent do
            task.wait(0.25)
            local ch=p.Character if not ch then continue end
            local h=ch:FindFirstChildOfClass("Humanoid") if not h then continue end
            saveDPS(p)
            local s=DefaultPlayerSettings[p]
            local sameT=HV.TeamCheck and LP.Team~=nil and p.Team==LP.Team
            if not HV.Enabled or h.Health<=0 or h.Sit or sameT or not s or s.Character~=ch then
                restDPS(p) continue
            end
            restDPS(p)
            local sel=ch:FindFirstChild(HV.Part) or ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
            if sel and sel:IsA("BasePart") then applyHit(sel) end
        end
        HitboxWorkerBound[p]=nil DefaultPlayerSettings[p]=nil
    end)
end
for _,p in ipairs(Players:GetPlayers()) do connectHit(p) end
Players.PlayerAdded:Connect(connectHit)
Players.PlayerRemoving:Connect(function(p)
    HitboxWorkerBound[p]=nil DefaultPlayerSettings[p]=nil
end)

-- WORLD VISUALS
local VCC=Lighting:FindFirstChild("aqxColorCorrection")
if not VCC then
    VCC=Instance.new("ColorCorrectionEffect") VCC.Name="aqxColorCorrection" VCC.Parent=Lighting
end
local OW={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,
    FogColor=Lighting.FogColor,GlobalShadows=Lighting.GlobalShadows,
    OutdoorAmbient=Lighting.OutdoorAmbient,Ambient=Lighting.Ambient,
    FieldOfView=workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    Saturation=VCC.Saturation,TintColor=VCC.TintColor}
local WR={Fog=false,Fov=false,Fullbright=false,Ambient=false,Saturation=false}
RunSvc:BindToRenderStep("aqxWorldVisuals",Enum.RenderPriority.Camera.Value,function()
    if not (WV.StretchEnabled or WV.FieldOfViewEnabled or WV.SaturationEnabled or WV.AmbientEnabled
        or WV.FogColorEnabled or WV.Fullbright)
    and WR.Fov and WR.Saturation and WR.Ambient and WR.Fog and WR.Fullbright then return end
    local cam=workspace.CurrentCamera if not cam then return end
    if WV.StretchEnabled then
        cam.CFrame=cam.CFrame*CFrame.new(0,0,0,1,0,0,0,WV.StretchValue,0,0,0,1)
    end
    if WV.FieldOfViewEnabled then WR.Fov=false cam.FieldOfView=WV.FieldOfViewValue
    elseif not WR.Fov then WR.Fov=true cam.FieldOfView=OW.FieldOfView or 70 end
    if WV.SaturationEnabled then WR.Saturation=false VCC.Saturation=WV.SaturationValue
    elseif not WR.Saturation then WR.Saturation=true VCC.Saturation=OW.Saturation or 0 end
    if WV.AmbientEnabled then
        WR.Ambient=false VCC.TintColor=WV.AmbientColor
        Lighting.Ambient=WV.AmbientColor Lighting.OutdoorAmbient=WV.AmbientColor
    elseif not WR.Ambient then
        WR.Ambient=true VCC.TintColor=OW.TintColor or Color3.new(1,1,1)
        Lighting.Ambient=OW.Ambient Lighting.OutdoorAmbient=OW.OutdoorAmbient
    end
    if WV.FogColorEnabled then WR.Fog=false Lighting.FogColor=WV.FogColor
    elseif not WR.Fog then WR.Fog=true Lighting.FogColor=OW.FogColor end
    if WV.Fullbright then
        WR.Fullbright=false
        Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=100000
        Lighting.GlobalShadows=false Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
    elseif not WR.Fullbright then
        WR.Fullbright=true
        Lighting.Brightness=OW.Brightness Lighting.ClockTime=OW.ClockTime
        Lighting.FogEnd=OW.FogEnd Lighting.GlobalShadows=OW.GlobalShadows
        Lighting.OutdoorAmbient=OW.OutdoorAmbient
    end
end)

-- HEAD TAG
A.MiamiHeadTagSettings={Enabled=true,Text="aqx",Size=32,Height=3.4,Style="Taco Green",
    Font="GothamBlack",Color="Gold",Rainbow=false,Pulse=true,Speed=8}
local HTS=A.MiamiHeadTagSettings
task.spawn(function()
    local Pals={["Taco Wave"]={Color3.fromRGB(255,198,48),Color3.fromRGB(255,236,143),Color3.fromRGB(255,155,40)},
        ["Taco Green"]={Color3.fromRGB(255,198,48),Color3.fromRGB(255,236,143),Color3.fromRGB(255,198,48)},
        ["Fire"]={Color3.fromRGB(255,30,0),Color3.fromRGB(255,225,0),Color3.fromRGB(255,80,0)},
        ["Ice"]={Color3.fromRGB(0,125,255),Color3.fromRGB(245,255,255),Color3.fromRGB(0,255,235)},
        ["Toxic"]={Color3.fromRGB(40,255,0),Color3.fromRGB(220,255,0),Color3.fromRGB(0,145,55)},
        ["Royal"]={Color3.fromRGB(115,0,255),Color3.fromRGB(255,210,45),Color3.fromRGB(220,0,255)}}
    local Fonts={GothamBlack=Enum.Font.GothamBlack,GothamBold=Enum.Font.GothamBold,
        Arcade=Enum.Font.Arcade,SciFi=Enum.Font.SciFi,Cartoon=Enum.Font.Cartoon,Code=Enum.Font.Code}
    local HTC={Gold=Color3.fromRGB(55,235,120),White=Color3.fromRGB(255,255,255),
        Orange=Color3.fromRGB(255,138,45),Red=Color3.fromRGB(255,70,76),
        Green=Color3.fromRGB(56,232,130),Blue=Color3.fromRGB(70,151,255),
        Purple=Color3.fromRGB(172,100,255),Pink=Color3.fromRGB(255,105,185),
        Cyan=Color3.fromRGB(54,236,255)}
    local function destroyTag(ch)
        local hd=ch and ch:FindFirstChild("Head")
        local t=hd and hd:FindFirstChild("aqx_HeadTag")
        if t then t:Destroy() end
    end
    local function attachTag(ch)
        if not HTS.Enabled then destroyTag(ch) return end
        pcall(function()
            local hd=ch and ch:WaitForChild("Head",5)
            if not hd then return end
            destroyTag(ch)
            local bb=Instance.new("BillboardGui")
            bb.Name="aqx_HeadTag" bb.Parent=hd bb.Adornee=hd
            bb.Size=UDim2.fromOffset(480,70)
            bb.StudsOffset=Vector3.new(0,HTS.Height or 3.4,0)
            bb.AlwaysOnTop=true bb.MaxDistance=700 bb.LightInfluence=0
            local lb=Instance.new("TextLabel")
            lb.BackgroundTransparency=1 lb.Size=UDim2.fromScale(1,1)
            lb.TextXAlignment=Enum.TextXAlignment.Center
            lb.TextYAlignment=Enum.TextYAlignment.Center
            lb.TextStrokeColor3=Color3.fromRGB(0,0,0) lb.TextStrokeTransparency=0.08
            lb.Parent=bb
            local gr=Instance.new("UIGradient") gr.Parent=lb
            local tv=0
            while lb.Parent do
                local cur=HTS
                local txt=tostring(cur.Text or "aqx")
                local sz=tonumber(cur.Size) or 32
                local sp=tonumber(cur.Speed) or 8
                local sty=cur.Style or "Taco Green"
                tv=tv+0.003*sp
                local seq
                local sc=HTC[cur.Color or "Gold"]
                if cur.Rainbow or sty=="Rainbow Wave" then
                    local hue=tv%1
                    seq=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromHSV(hue,1,1)),
                        ColorSequenceKeypoint.new(0.5,Color3.fromHSV((hue+0.25)%1,1,1)),
                        ColorSequenceKeypoint.new(1,Color3.fromHSV((hue+0.5)%1,1,1))}
                elseif sc and cur.Color~="Use Animation" then
                    local hl=sc:Lerp(Color3.fromRGB(255,255,255),0.30)
                    seq=ColorSequence.new{ColorSequenceKeypoint.new(0,sc),
                        ColorSequenceKeypoint.new(0.5,hl),ColorSequenceKeypoint.new(1,sc)}
                else
                    local cs=Pals[sty] or Pals["Taco Green"]
                    seq=ColorSequence.new{ColorSequenceKeypoint.new(0,cs[1]),
                        ColorSequenceKeypoint.new(0.5,cs[2]),ColorSequenceKeypoint.new(1,cs[3])}
                end
                lb.Text=txt lb.TextSize=sz
                lb.Font=Fonts[cur.Font or "GothamBlack"] or Enum.Font.GothamBlack
                bb.StudsOffset=Vector3.new(0,tonumber(cur.Height) or 3.4,0)
                bb.Size=UDim2.fromOffset(math.clamp(#txt*sz*0.66+50,300,700),sz+38)
                gr.Color=seq
                gr.Offset=Vector2.new(math.sin(tv*math.pi*2)*0.48,0)
                gr.Rotation=math.sin(tv*math.pi)*18
                if cur.Pulse then lb.TextSize=sz+math.sin(tv*math.pi*2)*1.5 end
                task.wait(0.03)
            end
        end)
    end
    A.attachHeadTag=attachTag
    A.destroyHeadTag=destroyTag
    if LP.Character then task.defer(attachTag,LP.Character) end
    LP.CharacterAdded:Connect(attachTag)
end)

-- TELEPORTS
A.teleportLocations={
    ["Car Dealer"]=CFrame.new(-409.63,253.41,-1230.14),
    ["New Laundry"]=CFrame.new(-1216.24,253.88,-3969.89),
    ["New Deli"]=CFrame.new(-1388.31,268.14,-3897.86),
    ["New Seller"]=CFrame.new(-965.27,260.19,-4244.83),
    ["New Bank"]=CFrame.new(-1217.30,253.88,-3635.04),
    ["Market"]=CFrame.new(-405.17,334.31,-562.63),
    ["New Penthouse"]=CFrame.new(-1488.06,476.30,-3747.01),
    ["Backpack"]=CFrame.new(-725.64,253.92,-684.30),
    ["Studio"]=CFrame.new(93408.45,14484.90,570.14),
    ["Dripstore"]=CFrame.new(67462.32,10489.21,549.60),
    ["Exotic"]=CFrame.new(-1519.52,272.15,-983.73),
    ["RPT"]=CFrame.new(-1744.10,236.95,-596.03),
    ["Random House"]=CFrame.new(-1228.93,261.04,-3758.50),
    ["Gunshop"]=CFrame.new(92960.12,122098.50,17253.95),
    ["Dollar General"]=CFrame.new(-413.66,253.82,-1055.57),
    ["Hospital"]=CFrame.new(-1587.46,254.27,18.42),
    ["Mansion"]=CFrame.new(-789.10,253.57,1380.76),
    ["Bank"]=CFrame.new(-226.225845,283.809570,-1217.750977),
    ["Money Wash"]=CFrame.new(-1006.000000,254.000000,-701.000000),
    ["Pawn Shop"]=CFrame.new(-1049.643100,253.536700,-814.269700),
    ["Bank Vault"]=CFrame.new(-217.568359,373.798492,-1216.209473),
    ["Mr Money Man"]=CFrame.new(-1008.066200,262.114100,55.133600),
    ["Construction Site"]=CFrame.new(-1731.830700,370.812300,-1176.838700),
    ["Prison"]=CFrame.new(-1135.046400,254.716000,-3330.995400),
    ["Ice Box"]=CFrame.new(-215.140700,283.515400,-1258.691000)}
A.teleportNames={}
for n in pairs(A.teleportLocations) do table.insert(A.teleportNames,n) end
table.sort(A.teleportNames)

A.TeleportToCookPot=function()
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local pos=hrp and hrp.Position or Vector3.zero
    local pot,best=nil,math.huge
    local function chk(p)
        if p and p:IsA("BasePart") then
            local d=(p.Position-pos).Magnitude
            if d<best then best,pot=d,p end
        end
    end
    if workspace:FindFirstChild("CookingPots") then
        for _,v in pairs(workspace.CookingPots:GetChildren()) do
            if v:IsA("Model") then
                chk(v:FindFirstChild("CookPart") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart"))
            end
        end
    end
    if pot then TP(pot.CFrame+Vector3.new(0,1.5,0)) notify("Teleport","Teleported to Cook Pot!")
    else TP(CFrame.new(-198.89,283.85,-1170.45)) notify("Teleport","Fallback CookPot.") end
end

-- QUICK BUY
local function qbFindPrompt(o)
    if not o then return nil end
    if o:IsA("ProximityPrompt") then return o end
    for _,c in ipairs(o:GetChildren()) do
        local f=qbFindPrompt(c) if f then return f end
    end
end
local function qbGetCF(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o.CFrame end
    if o:IsA("Model") then
        if o.PrimaryPart then return o.PrimaryPart.CFrame end
        local p=o:FindFirstChildWhichIsA("BasePart",true)
        if p then return p.CFrame end
        local ok,pv=pcall(function() return o:GetPivot() end)
        if ok then return pv end
    end
    local par=o.Parent
    if par and par:IsA("BasePart") then return par.CFrame end
    if par and par:IsA("Model") then
        if par.PrimaryPart then return par.PrimaryPart.CFrame end
        local p=par:FindFirstChildWhichIsA("BasePart",true)
        if p then return p.CFrame end
    end
end
A.qbDoBuy=function(item,cat)
    if not item then return false,"No item" end
    local c=LP.Character or LP.CharacterAdded:Wait()
    local hrp=c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart",5)
    if not hrp then return false,"No HRP" end
    if cat=="OTHER" or cat=="BAGS" then
        local io=workspace:FindFirstChild("GUNS") and workspace.GUNS:FindFirstChild(item) or nil
        if not io and cat=="BAGS" then io=workspace:FindFirstChild(item,true) end
        if not io then return false,"Item not found: "..tostring(item) end
        local pr=qbFindPrompt(io)
        local cf=qbGetCF(pr and pr.Parent or io)
        if not pr or not cf then return false,"Prompt not found" end
        local oc=hrp.CFrame local hd=pr.HoldDuration
        pcall(function()
            TP(cf) task.wait(0.35) pr.HoldDuration=0
            fireproximityprompt(pr) task.wait(0.2)
            pr.HoldDuration=hd TP(oc)
        end)
        return true
    elseif cat=="EXOTIC" then
        pcall(function() RS:WaitForChild("ExoticShopRemote"):InvokeServer(item) end) return true
    elseif cat=="MAIN SHOP" then
        pcall(function() RS:WaitForChild("ShopRemote"):InvokeServer(item) end) return true
    end
    return false,"Unknown category"
end

A.Modules3Loaded=true
print("[aqx] modules3 loaded")
