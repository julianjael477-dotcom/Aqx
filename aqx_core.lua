--[[ aqx core — mobile-first, hide-on-circle, anti-cheat-safe teleport ]]

local function svc(n) local ok,s=pcall(function() return game:GetService(n) end) return ok and s or nil end
local Players=svc("Players") local RS=svc("ReplicatedStorage") local RunSvc=svc("RunService")
local UIS=svc("UserInputService") local StarterGui=svc("StarterGui") local Lighting=svc("Lighting")
local Tween=svc("TweenService") local Debris=svc("Debris") local CoreGui=svc("CoreGui")
local PromptSvc=svc("ProximityPromptService")
local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui",10)
local BP=LP:WaitForChild("Backpack",5)

getgenv().aqx = getgenv().aqx or {}
local A = getgenv().aqx
A.Players=Players A.RS=RS A.RunSvc=RunSvc A.UIS=UIS A.StarterGui=StarterGui
A.Lighting=Lighting A.Tween=Tween A.Debris=Debris A.CoreGui=CoreGui
A.PromptSvc=PromptSvc A.LP=LP A.PG=PG A.BP=BP
A.Flags={} A.Toggles={} A.Options={} A.UnloadCallbacks={}
A.SwimMethod=false A.MiamiSuppressNotifications=true A.MoneyDropEnabled=false

A.Theme = {
    Back=Color3.fromRGB(14,14,14), Panel=Color3.fromRGB(20,20,20),
    PanelSoft=Color3.fromRGB(26,26,26), Outline=Color3.fromRGB(38,38,38),
    Text=Color3.fromRGB(240,240,240), Muted=Color3.fromRGB(130,130,130),
    Accent=Color3.fromRGB(120,90,255), AccentSoft=Color3.fromRGB(170,150,255),
    ToggleOn=Color3.fromRGB(70,130,255),
}
local Theme = A.Theme

A.onUnload = function(fn) if type(fn)=="function" then table.insert(A.UnloadCallbacks,fn) end end
A.corner = function(inst,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=inst return c end
A.stroke = function(inst,color,t,tr)
    local s=Instance.new("UIStroke") s.Color=color or Theme.Outline s.Thickness=t or 1
    s.Transparency=tr or 0.2 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=inst return s
end
A.new = function(cls,props,p) local o=Instance.new(cls) for k,v in pairs(props or {}) do o[k]=v end if p then o.Parent=p end return o end
A.tween = function(inst,t,props,st,dir)
    local tw=Tween:Create(inst,TweenInfo.new(t or 0.2,st or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props)
    tw:Play() return tw
end
A.safe = function(fn,...) if type(fn)~="function" then return end local ok,err=pcall(fn,...) if not ok then warn("[aqx] "..tostring(err)) end end

-- notify
local toastHolder
A.notify = function(title,text,dur)
    if A.MiamiSuppressNotifications then return end
    title=tostring(title or "aqx") text=tostring(text or "") dur=tonumber(dur) or 3
    pcall(function() StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur}) end)
    if not toastHolder or not toastHolder.Parent then return end
    local card=A.new("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=Theme.Panel,
        BackgroundTransparency=0.05,BorderSizePixel=0,ClipsDescendants=true},toastHolder)
    A.corner(card,10) A.stroke(card,Theme.Accent,1,0.4)
    local acc=A.new("Frame",{Size=UDim2.fromOffset(3,40),Position=UDim2.fromOffset(8,8),
        BackgroundColor3=Theme.Accent,BorderSizePixel=0},card)
    A.corner(acc,999)
    A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,8),
        Size=UDim2.new(1,-26,0,16),Font=Enum.Font.GothamBold,Text=title,TextSize=11,
        TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left},card)
    A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,24),
        Size=UDim2.new(1,-26,0,22),Font=Enum.Font.Gotham,Text=text,TextSize=10,
        TextColor3=Theme.Muted,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top},card)
    A.tween(card,0.2,{Size=UDim2.new(1,0,0,50)})
    task.delay(dur,function()
        if card and card.Parent then
            A.tween(card,0.2,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1})
            Debris:AddItem(card,0.3)
        end
    end)
end

-- teleport — Jointhub-style anti-cheat bypass
A.Config = A.Config or {}
A.Config.Teleport = function(self,cf)
    local char=LP.Character
    if not char then return false end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or not cf then return false end

    -- freeze the humanoid into falling-down so AC stops tracking
    A.SwimMethod = true
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.FallingDown) end)
    task.wait(0.7)

    -- wait for LastACPos to clear, up to ~0.5s
    local n = 0
    repeat task.wait(0.05); n = n + 1
    until not LP:GetAttribute("LastACPos") or n > 10

    -- kill residual velocity
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    -- apply random tiny offset so repeated teleports don't trip position-delta checks
    local off = Vector3.new(math.random(-2,2), 0, math.random(-2,2))
    if typeof(cf) == "CFrame" then
        hrp.CFrame = cf + off
    elseif typeof(cf) == "Vector3" then
        hrp.CFrame = CFrame.new(cf) + off
    end

    -- hold falling-down another 0.3s so AC sees a "ragdolled" state not a jump
    task.delay(0.3, function()
        A.SwimMethod = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end)

    return true
end
A.TP = function(cf) A.Config:Teleport(cf) end

-- root ui — bigger base to match your first screenshot
local parent = (gethui and gethui()) or CoreGui or PG
for _,n in ipairs({"aqxUI","aqxToggle"}) do local o=parent:FindFirstChild(n) if o then o:Destroy() end end
local gui = A.new("ScreenGui",{Name="aqxUI",ResetOnSpawn=false,IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=9999},parent)
A.Gui = gui

-- BASE SIZE — this is what controls the window dimensions
-- adjust these two numbers to taste
local BASE_W = 500
local BASE_H = 440
local HDR_H  = 50
local TAB_H  = 34
local BODY_TOP = HDR_H + TAB_H

local main = A.new("Frame",{Name="Main",AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,BASE_W,0,BASE_H),
    BackgroundColor3=Theme.Back,BorderSizePixel=0,ClipsDescendants=true},gui)
A.Main = main
A.corner(main,12) A.stroke(main,Theme.Outline,1,0.1)

local header = A.new("Frame",{Size=UDim2.new(1,0,0,HDR_H),BackgroundColor3=Theme.Back,
    BorderSizePixel=0},main)
A.Header = header

A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(16,8),
    Size=UDim2.fromOffset(180,20),Font=Enum.Font.GothamBold,Text="aqx",TextSize=15,
    TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left},header)

local crumb = A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(16,28),
    Size=UDim2.fromOffset(220,13),Font=Enum.Font.Gotham,Text="Player",TextSize=10,
    TextColor3=Theme.Accent,TextXAlignment=Enum.TextXAlignment.Left},header)
A.Crumb = crumb

local chip = A.new("Frame",{Size=UDim2.fromOffset(120,36),Position=UDim2.new(1,-130,0,7),
    BackgroundTransparency=1},header)
local av = A.new("ImageLabel",{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-30,0,3),
    BackgroundColor3=Theme.PanelSoft,ScaleType=Enum.ScaleType.Crop,
    Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=100&h=100"},chip)
A.corner(av,999)
A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,4),
    Size=UDim2.fromOffset(84,14),Font=Enum.Font.GothamBold,Text=LP.DisplayName,
    TextSize=11,TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Right,
    TextTruncate=Enum.TextTruncate.AtEnd},chip)
A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,18),
    Size=UDim2.fromOffset(84,12),Font=Enum.Font.Gotham,Text="aqx",TextSize=9,
    TextColor3=Theme.Muted,TextXAlignment=Enum.TextXAlignment.Right},chip)

local tabStrip = A.new("ScrollingFrame",{Position=UDim2.fromOffset(0,HDR_H),
    Size=UDim2.new(1,0,0,TAB_H),BackgroundColor3=Theme.Panel,BorderSizePixel=0,
    ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),
    ScrollingDirection=Enum.ScrollingDirection.X},main)
A.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
    VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,4),
    SortOrder=Enum.SortOrder.LayoutOrder},tabStrip)
A.new("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},tabStrip)
A.TabStrip = tabStrip

local body = A.new("Frame",{Position=UDim2.fromOffset(0,BODY_TOP),
    Size=UDim2.new(1,0,1,-BODY_TOP),BackgroundColor3=Theme.Panel,
    BorderSizePixel=0,ClipsDescendants=true},main)
A.Body = body

-- components
local function mkRow(p,o) return A.new("Frame",{Size=UDim2.new(1,-16,0,28),
    BackgroundTransparency=1,LayoutOrder=o or 0},p) end

A.addToggle = function(p,label,flag,def,cb,o)
    local row=mkRow(p,o)
    A.new("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,-44,1,0),
        Font=Enum.Font.Gotham,Text=label,TextSize=12,TextColor3=Theme.Text,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    local on=def==true A.Flags[flag]=on
    local dot=A.new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
        Size=UDim2.fromOffset(12,12),BackgroundColor3=on and Theme.ToggleOn or Theme.Muted,
        BorderSizePixel=0},row)
    A.corner(dot,999)
    local hit=A.new("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="",AutoButtonColor=false},row)
    local c={Flag=flag,Value=on,
        SetValue=function(self,v)
            self.Value=v==true A.Flags[flag]=self.Value
            A.tween(dot,0.12,{BackgroundColor3=self.Value and Theme.ToggleOn or Theme.Muted})
            A.safe(cb,self.Value)
        end}
    A.Toggles[flag]=c
    hit.MouseButton1Click:Connect(function() c:SetValue(not c.Value) end)
    return c
end

A.addButton = function(p,label,cb,o)
    local b=A.new("TextButton",{Size=UDim2.new(1,-16,0,30),
        BackgroundColor3=Theme.PanelSoft,BorderSizePixel=0,Text="",
        AutoButtonColor=false,LayoutOrder=o or 0},p)
    A.corner(b,6) A.stroke(b,Theme.Outline,1,0.4)
    A.new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
        Font=Enum.Font.GothamMedium,Text=label,TextSize=12,TextColor3=Theme.Text,
        TextTruncate=Enum.TextTruncate.AtEnd},b)
    b.MouseButton1Click:Connect(function() A.safe(cb) end)
    return b
end

A.addSlider = function(p,label,mn,mx,def,cb,o)
    local row=A.new("Frame",{Size=UDim2.new(1,-16,0,40),BackgroundTransparency=1,
        LayoutOrder=o or 0},p)
    A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,0),
        Size=UDim2.new(0.55,0,0,14),Font=Enum.Font.Gotham,Text=label,TextSize=11,
        TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd},row)
    local val=A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0.55,0,0,0),
        Size=UDim2.new(0.45,0,0,14),Font=Enum.Font.Gotham,Text=tostring(def),
        TextSize=11,TextColor3=Theme.Muted,TextXAlignment=Enum.TextXAlignment.Right},row)
    local track=A.new("Frame",{Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,4),
        BackgroundColor3=Theme.Outline,BorderSizePixel=0},row)
    A.corner(track,999)
    local pct=(def-mn)/math.max(mx-mn,1)
    local fill=A.new("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=Theme.Accent,
        BorderSizePixel=0},track)
    A.corner(fill,999)
    local knob=A.new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(pct,0,0.5,0),Size=UDim2.fromOffset(14,14),
        BackgroundColor3=Theme.Accent,BorderSizePixel=0,ZIndex=3},track)
    A.corner(knob,999) A.stroke(knob,Theme.AccentSoft,1,0.3)
    local drag=false
    local function setX(x)
        local r=math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
        local v=mn+r*(mx-mn)
        val.Text=string.format("%.2f",v):gsub("%.?0+$","")
        A.tween(fill,0.05,{Size=UDim2.new(r,0,1,0)})
        A.tween(knob,0.05,{Position=UDim2.new(r,0,0.5,0)})
        A.safe(cb,v)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=true setX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then setX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

A.addDropdown = function(p,label,values,def,cb,o)
    local row=A.new("Frame",{Size=UDim2.new(1,-16,0,44),BackgroundTransparency=1,
        LayoutOrder=o or 0},p)
    A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,0),
        Size=UDim2.new(1,0,0,14),Font=Enum.Font.Gotham,Text=label,TextSize=11,
        TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left},row)
    local sel=A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,16),
        Size=UDim2.new(1,-30,0,22),Font=Enum.Font.GothamMedium,
        Text=tostring(def or values[1] or ""),TextSize=11,TextColor3=Theme.Accent,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
    A.new("TextLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,0,0,16),Size=UDim2.fromOffset(22,22),Font=Enum.Font.GothamBold,
        Text="v",TextSize=12,TextColor3=Theme.Muted,
        TextXAlignment=Enum.TextXAlignment.Right},row)
    local hit=A.new("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="",AutoButtonColor=false},row)
    local cur=def or values[1] local open=false local menu
    local function close() if menu then menu:Destroy() menu=nil end open=false end
    local function openMenu()
        if open then return end open=true
        local h=math.min(#values*26+8,200)
        menu=A.new("Frame",{Name="aqxDD",Position=UDim2.fromOffset(
            row.AbsolutePosition.X,row.AbsolutePosition.Y+row.AbsoluteSize.Y+2),
            Size=UDim2.fromOffset(row.AbsoluteSize.X,h),BackgroundColor3=Theme.Back,
            BorderSizePixel=0,ClipsDescendants=true,ZIndex=500},gui)
        A.corner(menu,6) A.stroke(menu,Theme.Accent,1,0.4)
        local list=A.new("ScrollingFrame",{Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,ScrollBarThickness=2,
            CanvasSize=UDim2.new(0,0,0,#values*26),BorderSizePixel=0,ZIndex=501},menu)
        A.new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},list)
        A.new("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)},list)
        for i,v in ipairs(values) do
            local opt=A.new("TextButton",{Size=UDim2.new(1,-8,0,24),
                Position=UDim2.fromOffset(4,0),
                BackgroundColor3=(tostring(v)==tostring(cur)) and Theme.PanelSoft or Theme.Back,
                BorderSizePixel=0,Text=tostring(v),Font=Enum.Font.Gotham,TextSize=11,
                TextColor3=Theme.Text,AutoButtonColor=false,LayoutOrder=i,ZIndex=502},list)
            A.corner(opt,5)
            opt.MouseButton1Click:Connect(function()
                cur=v sel.Text=tostring(v) close() A.safe(cb,v)
            end)
        end
    end
    hit.MouseButton1Click:Connect(function()
        if open then close() else openMenu() end
    end)
    UIS.InputBegan:Connect(function(i)
        if not open then return end
        if i.UserInputType~=Enum.UserInputType.MouseButton1
        and i.UserInputType~=Enum.UserInputType.Touch then return end
        task.defer(function()
            if not menu or not menu.Parent then return end
            local p2=i.Position local mp=menu.AbsolutePosition local ms=menu.AbsoluteSize
            local inside=p2.X>=mp.X and p2.X<=mp.X+ms.X and p2.Y>=mp.Y and p2.Y<=mp.Y+ms.Y
            local rp=row.AbsolutePosition local rs2=row.AbsoluteSize
            local onRow=p2.X>=rp.X and p2.X<=rp.X+rs2.X and p2.Y>=rp.Y and p2.Y<=rp.Y+rs2.Y
            if not inside and not onRow then close() end
        end)
    end)
    return {SetValue=function(self,v) cur=v sel.Text=tostring(v) end,
        SetValues=function(self,nv) values=nv
            if not table.find(values,cur) then cur=values[1] sel.Text=tostring(cur) end end,
        Value=cur}
end

A.addInput = function(p,label,def,ph,num,cb,o)
    local row=A.new("Frame",{Size=UDim2.new(1,-16,0,44),BackgroundTransparency=1,
        LayoutOrder=o or 0},p)
    A.new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,0),
        Size=UDim2.new(1,0,0,14),Font=Enum.Font.Gotham,Text=label,TextSize=11,
        TextColor3=Theme.Text,TextXAlignment=Enum.TextXAlignment.Left},row)
    local box=A.new("TextBox",{Position=UDim2.fromOffset(0,16),Size=UDim2.new(1,0,0,24),
        BackgroundColor3=Theme.Back,BorderSizePixel=0,Font=Enum.Font.Gotham,
        Text=def or "",PlaceholderText=ph or "",TextSize=11,TextColor3=Theme.Text,
        PlaceholderColor3=Theme.Muted,TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false},row)
    A.corner(box,5) A.stroke(box,Theme.Outline,1,0.4)
    A.new("UIPadding",{PaddingLeft=UDim.new(0,6)},box)
    box.FocusLost:Connect(function()
        local v=box.Text if num and tonumber(v)==nil then return end A.safe(cb,v)
    end)
end

A.addLabel = function(p,text,o)
    return A.new("TextLabel",{Size=UDim2.new(1,-16,0,18),BackgroundTransparency=1,
        Font=Enum.Font.Gotham,Text=text,TextSize=11,TextColor3=Theme.Muted,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=o or 0},p)
end

A.addDivider = function(p,o)
    return A.new("Frame",{Size=UDim2.new(1,-16,0,1),BackgroundColor3=Theme.Outline,
        BorderSizePixel=0,LayoutOrder=o or 0},p)
end

-- group/tab — toggles go directly into scroll
A.Tabs = {}
A.TabButtons = {}
A.ActiveTab = nil

A.makeTab = function(name)
    local scroll=A.new("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        ScrollBarThickness=3,ScrollBarImageColor3=Theme.Accent,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,BorderSizePixel=0},body)
    A.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
    A.new("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,12),
        PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},scroll)
    local tab={name=name,scroll=scroll,_order=0}
    function tab:AddGroup(title)
        self._order=self._order+1
        local hdrOrd=self._order*1000-500
        if title then
            A.new("TextLabel",{Size=UDim2.new(1,-16,0,20),BackgroundTransparency=1,
                Font=Enum.Font.GothamBold,Text=title,TextSize=12,TextColor3=Theme.Accent,
                TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=hdrOrd},scroll)
        end
        local counter=hdrOrd
        local function no() counter=counter+1 return counter end
        return {
            AddToggle=function(_,f,d) return A.addToggle(scroll,d.Text or f,f,d.Default,d.Callback,no()) end,
            AddButton=function(_,t,cb) A.addButton(scroll,t,cb,no()) end,
            AddSlider=function(_,f,d) return A.addSlider(scroll,d.Text or f,d.Min or 0,d.Max or 100,
                d.Default or 0,d.Callback,no()) end,
            AddDropdown=function(_,f,d)
                local c=A.addDropdown(scroll,d.Text or f,d.Values,d.Default,d.Callback,no())
                A.Options[f]=c return c end,
            AddInput=function(_,f,d) return A.addInput(scroll,d.Text or f,d.Default,d.Placeholder,
                d.Numeric,d.Callback,no()) end,
            AddLabel=function(_,t) return A.addLabel(scroll,t,no()) end,
            AddDivider=function(_) A.addDivider(scroll,no()) end,
        }
    end
    function tab:AddLabel(t) return A.addLabel(scroll,t,0) end
    A.Tabs[name]=tab
    local btn=A.new("TextButton",{Size=UDim2.fromOffset(#name*7+22,26),
        BackgroundColor3=Theme.PanelSoft,BackgroundTransparency=0.5,BorderSizePixel=0,
        Text=name,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=Theme.Muted,
        AutoButtonColor=false,LayoutOrder=#A.TabButtons+1},tabStrip)
    A.corner(btn,5)
    btn.MouseButton1Click:Connect(function()
        for _,t in pairs(A.Tabs) do t.scroll.Visible=false end
        for _,b in pairs(A.TabButtons) do
            A.tween(b,0.1,{BackgroundTransparency=0.5,TextColor3=Theme.Muted})
            local s=b:FindFirstChildOfClass("UIStroke") if s then s:Destroy() end
        end
        scroll.Visible=true
        A.tween(btn,0.1,{BackgroundTransparency=0,TextColor3=Theme.Text})
        A.stroke(btn,Theme.Accent,1,0.4)
        crumb.Text=name A.ActiveTab=name
    end)
    A.TabButtons[name]=btn
    if not A.ActiveTab then
        A.ActiveTab=name scroll.Visible=true
        A.tween(btn,0.1,{BackgroundTransparency=0,TextColor3=Theme.Text})
        A.stroke(btn,Theme.Accent,1,0.4)
        crumb.Text=name
    end
    return tab
end

-- ROUND PURPLE BUTTON — fully hides everything except itself
local sideBtn=A.new("TextButton",{Name="aqxToggle",AnchorPoint=Vector2.new(1,0.5),
    Size=UDim2.fromOffset(44,44),BackgroundColor3=Theme.Accent,Text="a",
    Font=Enum.Font.GothamBlack,TextSize=22,TextColor3=Color3.fromRGB(255,255,255),
    AutoButtonColor=false,ZIndex=200},gui)
A.corner(sideBtn,999) A.stroke(sideBtn,Theme.AccentSoft,2,0.2)
A.SideBtn=sideBtn

A.updateBtnPos=function()
    local p=main.Position local a=main.AnchorPoint local s=main.AbsoluteSize
    sideBtn.Position=UDim2.new(p.X.Scale,p.X.Offset-(a.X*s.X)-6,
        p.Y.Scale,p.Y.Offset-(a.Y*s.Y)+(s.Y*0.5))
end

A.Minimized=false
sideBtn.MouseButton1Click:Connect(function()
    A.Minimized = not A.Minimized
    if A.Minimized then
        -- hide the whole window; only sideBtn stays visible
        main.Visible = false
        sideBtn.Text = "+"
    else
        main.Visible = true
        sideBtn.Text = "a"
    end
    task.wait(0.05)
    A.updateBtnPos()
end)

do
    local dragging,dragI,start,startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true start=i.Position startPos=main.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    header.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then dragI=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==dragI and dragging then
            local d=i.Position-start
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                startPos.Y.Scale,startPos.Y.Offset+d.Y)
            A.updateBtnPos()
        end
    end)
end

A.fit=function()
    local cam=workspace.CurrentCamera
    local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
    local w=math.min(BASE_W,vp.X-40) local h=math.min(BASE_H,vp.Y-40)
    local sc=math.min(w/BASE_W,h/BASE_H)
    -- cap upscale so it never balloons on tablets
    sc=math.min(sc,1.2)
    main.Size=UDim2.fromOffset(BASE_W*sc,BASE_H*sc)
    task.wait(0.05) A.updateBtnPos()
end
A.fit()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(A.fit)
end
task.defer(A.updateBtnPos)

toastHolder=A.new("Frame",{Name="Toasts",AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,-10,0,10),Size=UDim2.fromOffset(210,300),
    BackgroundTransparency=1,ZIndex=20},gui)
A.new("UIListLayout",{Padding=UDim.new(0,5),
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
    SortOrder=Enum.SortOrder.LayoutOrder},toastHolder)

A.CoreLoaded = true
print("[aqx] core loaded")
