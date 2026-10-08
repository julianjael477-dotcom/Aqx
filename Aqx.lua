--[[
    aqx — full port of Taco Scripts (THA BRONX 3)
    mobile-first | tap side button to minimize
]]

--------------------------------------------------------------------
-- services
--------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui         = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Lighting           = game:GetService("Lighting")
local CoreGui            = game:GetService("CoreGui")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")
local VirtualUser        = game:GetService("VirtualUser")
local VirtualInputManager= game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Backpack    = LocalPlayer:WaitForChild("Backpack", 5) or LocalPlayer:FindFirstChild("Backpack")

--------------------------------------------------------------------
-- theme
--------------------------------------------------------------------
local Theme = {
    Back       = Color3.fromRGB(14, 14, 14),
    Panel      = Color3.fromRGB(20, 20, 20),
    PanelSoft  = Color3.fromRGB(26, 26, 26),
    Outline    = Color3.fromRGB(38, 38, 38),
    Text       = Color3.fromRGB(240, 240, 240),
    Muted      = Color3.fromRGB(130, 130, 130),
    Accent     = Color3.fromRGB(120, 90, 255),
    AccentSoft = Color3.fromRGB(170, 150, 255),
    ToggleOn   = Color3.fromRGB(70, 130, 255),
}

--------------------------------------------------------------------
-- shared state (globals the source expects)
--------------------------------------------------------------------
getgenv().SwimMethod = false
getgenv().MiamiSuppressNotifications = true
getgenv().MoneyDropEnabled = false

local Flags   = {}
local Toggles = {}
local Options = {}
local _unloadCallbacks = {}

local function onUnload(fn)
    if type(fn) == "function" then table.insert(_unloadCallbacks, fn) end
end

--------------------------------------------------------------------
-- ui helpers
--------------------------------------------------------------------
local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = inst; return c
end
local function stroke(inst, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Outline; s.Thickness = thick or 1
    s.Transparency = trans or 0.2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst; return s
end
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function tween(inst, time, props, style, dir)
    local t = TweenService:Create(inst,
        TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end
local function safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[aqx] " .. tostring(err)) end
end

--------------------------------------------------------------------
-- notification (aqx toast + core gui)
--------------------------------------------------------------------
local toastHolder
local function notify(title, text, duration)
    if getgenv().MiamiSuppressNotifications then return end
    title = tostring(title or "aqx")
    text  = tostring(text or "")
    duration = tonumber(duration) or 3

    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = duration })
    end)

    if not toastHolder or not toastHolder.Parent then return end

    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, toastHolder)
    corner(card, 10)
    stroke(card, Theme.Accent, 1, 0.4)

    local accent = new("Frame", {
        Size = UDim2.fromOffset(3, 40), Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
    }, card)
    corner(accent, 999)

    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 8),
        Size = UDim2.new(1, -26, 0, 16), Font = Enum.Font.GothamBold,
        Text = title, TextSize = 12, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 24),
        Size = UDim2.new(1, -26, 0, 24), Font = Enum.Font.Gotham,
        Text = text, TextSize = 11, TextColor3 = Theme.Muted,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, card)

    tween(card, 0.2, { Size = UDim2.new(1, 0, 0, 52) })
    task.delay(duration, function()
        if card and card.Parent then
            tween(card, 0.2, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
            Debris:AddItem(card, 0.3)
        end
    end)
end

--------------------------------------------------------------------
-- Config:Teleport (used by nearly every module)
--------------------------------------------------------------------
Config = {}
function Config:Teleport(targetCFrame)
    local lp = Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or not hrp or not targetCFrame then return false end

    getgenv().SwimMethod = true
    hum:ChangeState(Enum.HumanoidStateType.FallingDown)

    local n = 1
    local waitStarted = os.clock()
    repeat task.wait(); n = n + 1
    until (n >= 40 and not lp:GetAttribute("LastACPos")) or (os.clock() - waitStarted >= 2.5)

    for _ = 1, 3 do
        if not hrp.Parent then break end
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait()
    end

    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    getgenv().SwimMethod = false
    return true
end

task.spawn(function()
    while task.wait() do
        if getgenv().SwimMethod then
            local c = Players.LocalPlayer.Character
            local h = c and c:FindFirstChildWhichIsA("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.FallingDown) end
        end
    end
end)

--------------------------------------------------------------------
-- ROOT UI (aqx shell)
--------------------------------------------------------------------
local parent = (gethui and gethui()) or CoreGui
for _, n in ipairs({"aqxUI", "aqxToggle"}) do
    local old = parent:FindFirstChild(n); if old then old:Destroy() end
end

local gui = new("ScreenGui", {
    Name = "aqxUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
}, parent)

local main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 720, 0, 500),
    BackgroundColor3 = Theme.Back, BorderSizePixel = 0, ClipsDescendants = true,
}, gui)
corner(main, 14); stroke(main, Theme.Outline, 1, 0.1)

-- header
local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Theme.Back, BorderSizePixel = 0,
}, main)

local titleLbl = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 10),
    Size = UDim2.fromOffset(200, 22), Font = Enum.Font.GothamBold,
    Text = "aqx", TextSize = 15, TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local crumbLbl = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 30),
    Size = UDim2.fromOffset(220, 14), Font = Enum.Font.Gotham,
    Text = "Player", TextSize = 10, TextColor3 = Theme.Accent,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local userChip = new("Frame", {
    Size = UDim2.fromOffset(140, 40), Position = UDim2.new(1, -150, 0, 7),
    BackgroundTransparency = 1,
}, header)
new("ImageLabel", {
    Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -34, 0, 3),
    BackgroundColor3 = Theme.PanelSoft,
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
    ScaleType = Enum.ScaleType.Crop,
}, userChip).Parent = userChip
corner(userChip:FindFirstChildOfClass("ImageLabel"), 999)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 4),
    Size = UDim2.fromOffset(100, 16), Font = Enum.Font.GothamBold,
    Text = LocalPlayer.DisplayName, TextSize = 12, TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Right,
}, userChip)
new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20),
    Size = UDim2.fromOffset(100, 14), Font = Enum.Font.Gotham,
    Text = "aqx", TextSize = 10, TextColor3 = Theme.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
}, userChip)

-- tab strip
local tabStrip = new("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 54),
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.X,
}, main)

local tabLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
}, tabStrip)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, tabStrip)

-- body
local body = new("Frame", {
    Position = UDim2.fromOffset(0, 92),
    Size = UDim2.new(1, 0, 1, -92),
    BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ClipsDescendants = true,
}, main)

--------------------------------------------------------------------
-- component library
--------------------------------------------------------------------
local function makeRow(parentFrame, order)
    local row = new("Frame", {
        Size = UDim2.new(1, -20, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
    }, parentFrame)
    return row
end

local function addToggle(parentFrame, labelText, flagKey, default, callback, order)
    local row = makeRow(parentFrame, order)
    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.Gotham, Text = labelText, TextSize = 13,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local on = default == true
    Flags[flagKey] = on

    local dot = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = on and Theme.ToggleOn or Theme.Muted,
        BorderSizePixel = 0,
    }, row)
    corner(dot, 999)

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false,
    }, row)

    local ctrl = {
        Flag = flagKey,
        Value = on,
        SetValue = function(self, v)
            self.Value = v == true
            Flags[flagKey] = self.Value
            tween(dot, 0.12, { BackgroundColor3 = self.Value and Theme.ToggleOn or Theme.Muted })
            safe(callback, self.Value)
        end,
        GetState = function(self) return self.Value end,
    }
    Toggles[flagKey] = ctrl

    hit.MouseButton1Click:Connect(function()
        ctrl:SetValue(not ctrl.Value)
    end)
    return ctrl
end

local function addButton(parentFrame, labelText, callback, order)
    local btn = new("TextButton", {
        Size = UDim2.new(1, -20, 0, 32),
        BackgroundColor3 = Theme.PanelSoft, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false, LayoutOrder = order or 0,
    }, parentFrame)
    corner(btn, 8); stroke(btn, Theme.Outline, 1, 0.4)

    new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamMedium, Text = labelText, TextSize = 13,
        TextColor3 = Theme.Text,
    }, btn)

    btn.MouseButton1Click:Connect(function()
        safe(callback)
    end)
    return btn
end

local function addSlider(parentFrame, labelText, min, max, default, callback, order)
    local row = new("Frame", {
        Size = UDim2.new(1, -20, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
    }, parentFrame)

    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0.5, 0, 0, 16), Font = Enum.Font.Gotham,
        Text = labelText, TextSize = 12, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local valLbl = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, 0, 0, 16), Font = Enum.Font.Gotham,
        Text = tostring(default), TextSize = 12, TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local track = new("Frame", {
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = Theme.Outline, BorderSizePixel = 0,
    }, row)
    corner(track, 999)

    local pct = (default - min) / math.max(max - min, 1)
    local fill = new("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
    }, track)
    corner(fill, 999)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(pct, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 3,
    }, track)
    corner(knob, 999); stroke(knob, Theme.AccentSoft, 1, 0.3)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local value = min + rel * (max - min)
        valLbl.Text = string.format("%.2f", value):gsub("%.?0+$", "")
        tween(fill, 0.05, { Size = UDim2.new(rel, 0, 1, 0) })
        tween(knob, 0.05, { Position = UDim2.new(rel, 0, 0.5, 0) })
        safe(callback, value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function addDropdown(parentFrame, labelText, values, default, callback, order)
    local row = new("Frame", {
        Size = UDim2.new(1, -20, 0, 46),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
    }, parentFrame)

    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham,
        Text = labelText, TextSize = 12, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local selLbl = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(1, -34, 0, 22), Font = Enum.Font.GothamMedium,
        Text = tostring(default or values[1] or ""), TextSize = 12,
        TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local arrow = new("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 18), Size = UDim2.fromOffset(24, 22),
        Font = Enum.Font.GothamBold, Text = "▾", TextSize = 14,
        TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false,
    }, row)

    local currentValue = default or values[1]
    local open = false
    local menu

    local function close()
        if menu then menu:Destroy(); menu = nil end
        open = false
    end

    hit.MouseButton1Click:Connect(function()
        if open then close(); return end
        open = true
        menu = new("Frame", {
            Position = UDim2.new(0, 0, 1, 4),
            Size = UDim2.new(1, 0, 0, math.min(#values * 28 + 8, 160)),
            BackgroundColor3 = Theme.Back, BorderSizePixel = 0,
            ClipsDescendants = true, ZIndex = 50,
        }, row)
        corner(menu, 8); stroke(menu, Theme.Accent, 1, 0.4)

        local list = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, #values * 28),
            BorderSizePixel = 0,
        }, menu)
        new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
        new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, list)

        for i, v in ipairs(values) do
            local opt = new("TextButton", {
                Size = UDim2.new(1, -8, 0, 26), Position = UDim2.fromOffset(4, 0),
                BackgroundColor3 = (tostring(v) == tostring(currentValue)) and Theme.PanelSoft or Theme.Back,
                BorderSizePixel = 0, Text = tostring(v), Font = Enum.Font.Gotham,
                TextSize = 12, TextColor3 = Theme.Text, AutoButtonColor = false,
                LayoutOrder = i,
            }, list)
            corner(opt, 6)
            opt.MouseButton1Click:Connect(function()
                currentValue = v
                selLbl.Text = tostring(v)
                close()
                safe(callback, v)
            end)
        end
    end)

    return {
        SetValue = function(self, v) currentValue = v; selLbl.Text = tostring(v) end,
        SetValues = function(self, newValues)
            values = newValues
            if not table.find(values, currentValue) then
                currentValue = values[1]
                selLbl.Text = tostring(currentValue)
            end
        end,
        Value = currentValue,
    }
end

local function addInput(parentFrame, labelText, default, placeholder, numeric, callback, order)
    local row = new("Frame", {
        Size = UDim2.new(1, -20, 0, 46),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
    }, parentFrame)

    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham,
        Text = labelText, TextSize = 12, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local box = new("TextBox", {
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Theme.Back, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, Text = default or "", PlaceholderText = placeholder or "",
        TextSize = 12, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    }, row)
    corner(box, 6); stroke(box, Theme.Outline, 1, 0.4)
    new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)

    box.FocusLost:Connect(function()
        local v = box.Text
        if numeric and tonumber(v) == nil then return end
        safe(callback, v)
    end)
end

local function addLabel(parentFrame, text, order)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham,
        Text = text, TextSize = 12, TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, LayoutOrder = order or 0,
    }, parentFrame)
    return lbl
end

local function addDivider(parentFrame, order)
    local d = new("Frame", {
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = Theme.Outline, BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parentFrame)
    return d
end

--------------------------------------------------------------------
-- group / tab builder
--------------------------------------------------------------------
local function newGroup(scroll, title)
    if title then
        new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 22),
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
            Text = title, TextSize = 13, TextColor3 = Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, scroll)
    end
    local list = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, scroll)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local order = 0
    local function nextOrder() order = order + 1; return order end

    return {
        AddToggle   = function(_, flag, data)
            return addToggle(list, data.Text or flag, flag, data.Default, data.Callback, nextOrder())
        end,
        AddButton   = function(_, text, cb) addButton(list, text, cb, nextOrder()) end,
        AddSlider   = function(_, flag, data)
            return addSlider(list, data.Text or flag, data.Min or 0, data.Max or 100, data.Default or 0,
                data.Callback, nextOrder())
        end,
        AddDropdown = function(_, flag, data)
            local ctrl = addDropdown(list, data.Text or flag, data.Values, data.Default, data.Callback, nextOrder())
            Options[flag] = ctrl
            return ctrl
        end,
        AddInput    = function(_, flag, data)
            return addInput(list, data.Text or flag, data.Default, data.Placeholder, data.Numeric, data.Callback, nextOrder())
        end,
        AddLabel    = function(_, text) return addLabel(list, text, nextOrder()) end,
        AddDivider  = function(_) addDivider(list, nextOrder()) end,
        _list = list,
    }
end

local tabs = {}
local tabButtons = {}
local activeTab

local function makeTab(name)
    local scroll = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        BorderSizePixel = 0,
    }, body)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    }, scroll)

    local tab = { name = name, scroll = scroll, _order = 0 }
    function tab:AddGroup(title)
        self._order = self._order + 1
        local g = newGroup(scroll, title)
        g._list.LayoutOrder = self._order
        return g
    end
    function tab:AddLabel(t) return addLabel(scroll, t, 0) end

    tabs[name] = tab

    -- tab button
    local btn = new("TextButton", {
        Size = UDim2.fromOffset(#name * 8 + 24, 28),
        BackgroundColor3 = Theme.PanelSoft, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Text = name, Font = Enum.Font.GothamMedium,
        TextSize = 12, TextColor3 = Theme.Muted, AutoButtonColor = false,
        LayoutOrder = #tabButtons + 1,
    }, tabStrip)
    corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.scroll.Visible = false end
        for _, b in pairs(tabButtons) do
            tween(b, 0.1, { BackgroundTransparency = 0.5, TextColor3 = Theme.Muted })
            local s = b:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end
        end
        scroll.Visible = true
        tween(btn, 0.1, { BackgroundTransparency = 0, TextColor3 = Theme.Text })
        stroke(btn, Theme.Accent, 1, 0.4)
        crumbLbl.Text = name
        activeTab = name
    end)
    tabButtons[name] = btn

    if not activeTab then
        activeTab = name
        scroll.Visible = true
        tween(btn, 0.1, { BackgroundTransparency = 0, TextColor3 = Theme.Text })
        stroke(btn, Theme.Accent, 1, 0.4)
        crumbLbl.Text = name
    end

    return tab
end

--------------------------------------------------------------------
-- minimize button
--------------------------------------------------------------------
local sideBtn = new("TextButton", {
    Name = "aqxToggle",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, -22, 0.5, 0),
    Size = UDim2.fromOffset(22, 60),
    BackgroundColor3 = Theme.Back,
    Text = "‹", Font = Enum.Font.GothamBold, TextSize = 16,
    TextColor3 = Theme.Accent, AutoButtonColor = false, ZIndex = 10,
}, main)
corner(sideBtn, 6); stroke(sideBtn, Theme.Outline, 1, 0.2)

local minimized = false
sideBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(main, 0.25, { Size = UDim2.new(0, 720, 0, 54) })
        tween(tabStrip, 0.15, { BackgroundTransparency = 1 })
        tween(body, 0.15, { BackgroundTransparency = 1 })
        sideBtn.Text = "›"
    else
        tween(main, 0.25, { Size = UDim2.new(0, 720, 0, 500) })
        tween(tabStrip, 0.15, { BackgroundTransparency = 0 })
        tween(body, 0.15, { BackgroundTransparency = 0 })
        sideBtn.Text = "‹"
    end
end)

-- drag
do
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                      startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- responsive
local function fit()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local w = math.min(720, vp.X - 30)
    local h = math.min(500, vp.Y - 60)
    local scale = math.min(w / 720, h / 500)
    main.Size = UDim2.fromOffset(720 * scale, (minimized and 54 or 500) * scale)
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

--------------------------------------------------------------------
-- toast holder (top-right)
--------------------------------------------------------------------
toastHolder = new("Frame", {
    Name = "Toasts",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -16, 0, 16),
    Size = UDim2.fromOffset(240, 400),
    BackgroundTransparency = 1,
    ZIndex = 20,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

--------------------------------------------------------------------
-- ================================================================
-- MODULES
-- ================================================================
--------------------------------------------------------------------

--------------------------------------------------------------------
-- WEAPON MODS
--------------------------------------------------------------------
WeaponMods = {
    InfiniteAmmo=false, InfiniteClips=false, Bullets80k=false,
    ModifyRecoilValue=false, ModifySpreadValue=false, DisableJamming=false,
    InstantReload=false, InstantEquip=false, ModifyFireRate=false,
    Automatic=false, DamageAmplified=false, SpoofAccuracy=false,
    InfiniteDamage=false,
    ReloadSpeed=0.2, EquipSpeed=0.2,
    FireRateSpeed=50, SpreadPercentage=50, RecoilPercentage=50,
}
GunOriginalColors = {}
GunChams = false
RainbowGun = false
GunChamsColor = Color3.fromRGB(0,200,0)

local function getEquippedGunSetting()
    local character = LocalPlayer.Character
    if not character then return nil, nil end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool:FindFirstChild("Setting") then return nil, nil end
    local ok, settings = pcall(require, tool.Setting)
    if ok and type(settings) == "table" then return tool, settings end
end

local function applyAllWeaponMods()
    local tool, settings = getEquippedGunSetting()
    if not settings then return end
    pcall(function()
        if WeaponMods.InfiniteAmmo then settings.Ammo=99999; settings.AmmoPerMag=99999; settings.LimitedAmmoEnabled=false end
        if WeaponMods.InfiniteClips then settings.Ammo=80000; settings.AmmoPerMag=80000; settings.LimitedAmmoEnabled=false end
        if WeaponMods.Bullets80k then
            settings.Ammo=80000; settings.AmmoPerMag=80000; settings.LimitedAmmoEnabled=false
            local gunLocal = tool:FindFirstChild("GunScript_Local")
            if gunLocal and type(getsenv) == "function" then
                pcall(function()
                    local env = getsenv(gunLocal)
                    if env and type(env.Reload) == "function" and type(debug.setupvalue) == "function" then
                        debug.setupvalue(env.Reload, 1, 80000); debug.setupvalue(env.Reload, 3, 80000)
                    end
                end)
            end
        end
        if WeaponMods.ModifyRecoilValue then settings.Recoil=0; settings.CameraRecoilingEnabled=false end
        if WeaponMods.ModifySpreadValue then settings.Spread=0; settings.SpreadX=0; settings.SpreadY=0; settings.Accuracy=1 end
        if WeaponMods.DisableJamming then settings.JamChance=0 end
        if WeaponMods.InstantReload then settings.ReloadTime = WeaponMods.ReloadSpeed or 0.1 end
        if WeaponMods.InstantEquip then settings.EquipTime = WeaponMods.EquipSpeed or 0.1; settings.EquippingTime = WeaponMods.EquipSpeed or 0.1 end
        if WeaponMods.ModifyFireRate then settings.FireRate = 0 end
        if WeaponMods.Automatic then settings.Auto = true end
        if (WeaponMods.DamageAmplified or WeaponMods.InfiniteDamage) then settings.BaseDamage = 1e9 end
        if WeaponMods.SpoofAccuracy then settings.Accuracy = 1 end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(c)
    c.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(applyAllWeaponMods) end end)
end)
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(applyAllWeaponMods) end end)
end
task.spawn(function() while task.wait(0.25) do pcall(applyAllWeaponMods) end end)

local function force80k()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then notify("Gun Mods","Hold a gun first!"); return end
    pcall(function()
        if tool:FindFirstChild("Setting") then
            local config = require(tool.Setting)
            if type(config) == "table" then
                config.Ammo=80000; config.AmmoPerMag=80000; config.LimitedAmmoEnabled=false
            end
        end
        local gunLocal = tool:FindFirstChild("GunScript_Local")
        if gunLocal and type(getsenv) == "function" then
            local env = getsenv(gunLocal)
            if env and type(env.Reload) == "function" and type(debug.setupvalue) == "function" then
                debug.setupvalue(env.Reload, 1, 80000); debug.setupvalue(env.Reload, 3, 80000)
            end
        end
    end)
    notify("Gun Mods","Forced 80k bullets on current gun.")
end

local function updateGunColor()
    if not GunChams then return end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, v in pairs(tool:GetDescendants()) do
        if v:IsA("BasePart") then
            if not GunOriginalColors[v] then GunOriginalColors[v] = v.Color end
            if RainbowGun then v.Color = Color3.fromHSV((tick() % 5) / 5, 1, 1)
            else v.Color = GunChamsColor or Color3.fromRGB(0,200,0) end
            v.Material = Enum.Material.Neon
        end
    end
end
local function restoreGunColor()
    for part, color in pairs(GunOriginalColors) do
        if part and part.Parent then part.Color=color; part.Material=Enum.Material.Plastic end
    end
    GunOriginalColors = {}
end
RunService.RenderStepped:Connect(function() pcall(updateGunColor) end)

--------------------------------------------------------------------
-- TARGET
--------------------------------------------------------------------
TargetUtilities = {
    SelectedPlayer = nil, SpectatePlayer = false,
    BringingPlayer = false, BringingNearestPlayer = false,
    AutoRagdoll = false, AutoKill = false, AutoKillMaxDistance = 350,
}
TargetPlayerNames = {}

local function getTargetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    table.sort(list); return list
end

local function getSelectedTargetPlayer()
    local sel = TargetUtilities.SelectedPlayer
    if type(sel) == "string" and sel ~= "" then return Players:FindFirstChild(sel) end
end

local function isValidTargetPlayer(p)
    if not p or p == LocalPlayer then return false end
    local c = p.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    return h and h.Health > 0 and r ~= nil
end

local function getNearestTargetPlayer()
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not lr then return nil end
    local n, nd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTargetPlayer(p) then
            local d = (p.Character.HumanoidRootPart.Position - lr.Position).Magnitude
            if d < nd then n, nd = p, d end
        end
    end
    return n
end

local function getTargetDistance(player)
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local tr = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not lr or not tr then return math.huge end
    return (lr.Position - tr.Position).Magnitude
end

CarFlingRunning = false
local function getCarFlingVehicle()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    local nearestCar, nearestSeat, nearestDistance = nil, nil, math.huge
    for _, folderName in ipairs({"CivCars", "PoliceCars", "NPCCars", "Cars", "Vehicles"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, car in ipairs(folder:GetChildren()) do
                if car:IsA("Model") then
                    local seat = car:FindFirstChild("DriveSeat", true)
                        or car:FindFirstChildWhichIsA("VehicleSeat", true)
                    if seat and not seat.Occupant then
                        local mainPart = car.PrimaryPart
                            or (car:FindFirstChild("Body") and car.Body:FindFirstChild("#Weight", true))
                            or car:FindFirstChildWhichIsA("BasePart", true)
                        if mainPart then
                            local d = (mainPart.Position - root.Position).Magnitude
                            if d < nearestDistance then
                                nearestDistance = d; nearestCar = car; nearestSeat = seat
                            end
                        end
                    end
                end
            end
        end
    end
    return nearestCar, nearestSeat
end

local function setCarFlingVelocity(car, velocity)
    if not car then return end
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.AssemblyLinearVelocity = velocity
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
end

local function CarFlingSelectedPlayer()
    if CarFlingRunning then notify("Car Fling", "A car fling is already running."); return end
    local target = getSelectedTargetPlayer()
    if not target or not isValidTargetPlayer(target) then
        notify("Car Fling", "Select a valid player first."); return
    end
    CarFlingRunning = true
    task.spawn(function()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local returnCF = root and root.CFrame
        local car, seat
        local oldSize, oldTransparency, oldCollide

        local function finish(message)
            if car then pcall(setCarFlingVelocity, car, Vector3.zero) end
            if targetRoot and targetRoot.Parent and oldSize then
                pcall(function()
                    targetRoot.Size = oldSize
                    targetRoot.Transparency = oldTransparency
                    targetRoot.CanCollide = oldCollide
                end)
            end
            if humanoid and humanoid.Parent then
                pcall(function()
                    humanoid.Sit = false; humanoid.Jump = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
            if root and root.Parent and returnCF then
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    Config:Teleport(returnCF)
                end)
            end
            getgenv().SwimMethod = false
            CarFlingRunning = false
            if message then notify("Car Fling", message) end
        end

        local ok, err = pcall(function()
            if not root or not humanoid or not targetRoot then
                finish("Character or target is not ready."); return
            end
            oldSize = targetRoot.Size
            oldTransparency = targetRoot.Transparency
            oldCollide = targetRoot.CanCollide
            pcall(function()
                targetRoot.Size = Vector3.new(25, 25, 25)
                targetRoot.Transparency = 1
                targetRoot.CanCollide = false
            end)
            car, seat = getCarFlingVehicle()
            if not car or not seat then finish("No empty car was found."); return end
            if not car.PrimaryPart then
                car.PrimaryPart = (car:FindFirstChild("Body") and car.Body:FindFirstChild("#Weight", true))
                    or car:FindFirstChildWhichIsA("BasePart", true) or seat
            end
            if not car.PrimaryPart then finish("The selected car has no usable main part."); return end

            notify("Car Fling", "Claiming an empty car...")
            Config:Teleport(seat.CFrame * CFrame.new(0, 2, 0))
            task.wait(0.2); seat:Sit(humanoid); car:SetAttribute("Usable", true); task.wait(1)
            if humanoid.SeatPart ~= seat then finish("Failed to sit in the car. Try again."); return end

            notify("Car Fling", "Flinging " .. target.Name .. "...")
            local seatPart = humanoid.SeatPart
            local unseatStart = os.clock()
            while os.clock() - unseatStart < 1.5 do
                pcall(function()
                    humanoid.Sit = false; humanoid.Jump = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    if seatPart then
                        for _, weld in ipairs(seatPart:GetDescendants()) do
                            if weld:IsA("Weld") or weld:IsA("Motor6D") or weld.Name == "SeatWeld" then
                                weld:Destroy()
                            end
                        end
                    end
                end)
                if not humanoid.Sit and not humanoid.SeatPart then break end
                task.wait(0.02)
            end

            getgenv().SwimMethod = true; task.wait(0.5)
            if root and root.Parent and returnCF then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = returnCF
            end
            getgenv().SwimMethod = false

            local flingStart = os.clock()
            while os.clock() - flingStart < 4 do
                if not car.Parent or not targetRoot.Parent then break end
                pcall(function()
                    if car.PrimaryPart then car:SetPrimaryPartCFrame(targetRoot.CFrame)
                    else car:PivotTo(targetRoot.CFrame) end
                end)
                setCarFlingVelocity(car, Vector3.new(0, 20000, 0))
                task.wait(0.01)
            end
            finish(target.Name .. " was car-flung.")
        end)
        if not ok then warn("[Car Fling] " .. tostring(err)); finish("Error: " .. tostring(err)) end
    end)
end

local function targetGunRemote(targetName, hitPart, damage)
    hitPart = hitPart or "Head"; damage = damage or math.huge
    local target = Players:FindFirstChild(tostring(targetName))
    if not target or not target.Character or not target.Character:FindFirstChild(hitPart) then return end
    if not target.Character:FindFirstChildOfClass("Humanoid") then return end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then notify("Target","Hold a gun/tool first."); return end
    pcall(function() if tool:FindFirstChild("Setting") then require(tool.Setting).Range = 10000 end end)
    pcall(function()
        if ReplicatedStorage:FindFirstChild("InflictTarget") then
            ReplicatedStorage.InflictTarget:FireServer(
                tool, LocalPlayer, target.Character.Humanoid,
                target.Character[hitPart], damage,
                {0,0,false,false}, {false,5,3}, target.Character[hitPart],
                {false,{1930359546},1,1.5,1}, target.Character[hitPart].Position,
                Vector3.new(0,0,-1), true
            )
        end
    end)
end

local spectateReset = true
RunService:BindToRenderStep("aqxSpectate", Enum.RenderPriority.Camera.Value, function()
    local cam = workspace.CurrentCamera; if not cam then return end
    if TargetUtilities.SpectatePlayer then
        spectateReset = false
        local t = getSelectedTargetPlayer()
        local s = t and t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if not s and LocalPlayer.Character then s = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
        if s then cam.CameraSubject = s end
    elseif not spectateReset and LocalPlayer.Character then
        spectateReset = true
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then cam.CameraSubject = h end
    end
end)

task.spawn(function()
    while task.wait() do
        if TargetUtilities.BringingPlayer then
            local t = getSelectedTargetPlayer()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                t.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
            end
        end
        if TargetUtilities.BringingNearestPlayer then
            local t = getNearestTargetPlayer()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                t.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if TargetUtilities.AutoRagdoll then
            local t = getSelectedTargetPlayer()
            if t and isValidTargetPlayer(t) and t.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
                targetGunRemote(t.Name, "RightUpperLeg", 0.01)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if TargetUtilities.AutoKill then
            local t = getSelectedTargetPlayer()
            if t and isValidTargetPlayer(t) and getTargetDistance(t) <= (TargetUtilities.AutoKillMaxDistance or 350) then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("GunScript_Local") then
                    targetGunRemote(t.Name, "Head", math.huge)
                end
            end
        end
    end
end)

--------------------------------------------------------------------
-- MONEY
--------------------------------------------------------------------
local function getGoodCleaner()
    if not workspace:FindFirstChild("1# Map") then return nil end
    local CounterInstance
    for _, V in pairs(workspace["1# Map"]:GetChildren()) do
        if V:FindFirstChild("CounterM") then CounterInstance = V; break end
    end
    if not CounterInstance then return nil end
    for _, v in pairs(CounterInstance:GetChildren()) do
        local cp = v:FindFirstChild("CashPrompt", true)
        local gp = v:FindFirstChild("GrabPrompt", true)
        if cp and cp.Enabled and cp.ObjectText == "Count Bread" and gp and not gp.Enabled then
            return v
        end
    end
end

local function CleanAllFilthyMoney()
    local Player = LocalPlayer
    if not Player:FindFirstChild("stored") or not Player.stored:FindFirstChild("FilthyStack")
    or Player.stored.FilthyStack.Value == 0 then
        notify("Money","You don't have any filthy cash!"); return
    end
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
    local Cleaner = getGoodCleaner()
    if not Cleaner then notify("Money","Couldn't find a good cleaner!"); return end
    pcall(function() Config:Teleport(Cleaner.WorldPivot or (Cleaner.CFrame or Cleaner:GetPivot())) end)
    task.wait(0.4)
    pcall(function() fireproximityprompt(Cleaner:FindFirstChild("CashPrompt", true)) end)
    local onObj = Cleaner:FindFirstChild("On", true)
    if onObj then repeat task.wait() until onObj.Color == Color3.fromRGB(74,156,69) else task.wait(0.5) end
    task.wait(0.5)
    pcall(function() fireproximityprompt(Cleaner:FindFirstChild("CashPrompt", true)) end)
    task.wait(0.25)
    pcall(function() Config:Teleport(Cleaner.WorldPivot or (Cleaner.CFrame or Cleaner:GetPivot())) end)
    task.wait(0.4)
    repeat task.wait() until Player.Backpack:FindFirstChild("MoneyReady")
    Player.Character.Humanoid:EquipTool(Player.Backpack["MoneyReady"])
    repeat task.wait(1) pcall(function() fireproximityprompt(Cleaner:FindFirstChild("GrabPrompt", true)) end)
    until not Player.Character:FindFirstChild("MoneyReady")
    repeat task.wait() until Player.Backpack:FindFirstChild("BagOfMoney")
    pcall(function() Config:Teleport(CFrame.new(-1217.30, 253.88, -3635.04)) end)
    task.wait(0.4)
    if Player.Backpack:FindFirstChild("BagOfMoney") then
        Player.Character.Humanoid:EquipTool(Player.Backpack["BagOfMoney"])
    end
    task.wait(1)
    pcall(function()
        local atm = workspace:FindFirstChild("ATMMoney")
        local prompt = atm and atm:FindFirstChild("Prompt", true)
        if prompt then fireproximityprompt(prompt) end
    end)
end

local function InfMoneyHoldCupz()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local origin = hrp.CFrame
    local sell = workspace:FindFirstChild("IceFruit Sell")
    if not sell then notify("Inf Money","IceFruit Sell not found."); return end
    local prompt = sell:FindFirstChild("ProximityPrompt"); if not prompt then return end
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = math.huge
    Config:Teleport(sell.CFrame); task.wait(1)
    for _ = 1, 250 do task.spawn(function() pcall(function() fireproximityprompt(prompt, 1) end) end) end
    task.wait(5)
    Config:Teleport(origin); task.wait(0.25)
    getgenv().SwimMethod = false
end

local function SetupInfiniteMoney()
    for _, item in ipairs({"Ice-Fruit Bag","Ice-Fruit Cupz","FijiWater","FreshWater"}) do
        task.spawn(function()
            pcall(function() ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(item) end)
        end)
    end
end

local function GenerateMaxIllegalMoney()
    local Player = LocalPlayer
    local function GetFruitCup()
        for _, container in ipairs({Player.Backpack, Player.Character}) do
            if container then
                for _, tool in pairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == "Ice-Fruit Cupz" then
                        local cupPart = tool:FindFirstChild("IceFruit Cup")
                        if cupPart and cupPart:FindFirstChild("IceFruit PunchMedium")
                        and cupPart["IceFruit PunchMedium"].Transparency ~= 1 then
                            return true, tool
                        end
                    end
                end
            end
        end
        return false, nil
    end
    local Found, Cup = GetFruitCup()
    local oldCFrame = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        and Player.Character.HumanoidRootPart.CFrame
    if Cup and Found and oldCFrame and workspace:FindFirstChild("IceFruit Sell") then
        if Cup.Parent == Player.Backpack then Player.Character.Humanoid:EquipTool(Cup); task.wait(1) end
        Config:Teleport(workspace["IceFruit Sell"].CFrame); task.wait(0.5)
        for _ = 1, 4000 do task.spawn(function()
            pcall(function() fireproximityprompt(workspace["IceFruit Sell"].ProximityPrompt) end)
        end) end
        Config:Teleport(oldCFrame); task.wait(8)
        return
    end
    local items = {"FijiWater","FreshWater","Ice-Fruit Bag","Ice-Fruit Cupz"}
    local stove
    if workspace:FindFirstChild("CookingPots") then
        for _, value in pairs(workspace.CookingPots:GetChildren()) do
            if value:IsA("Model") then
                local prompt = value:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.ActionText == "Turn On" and prompt.Enabled then stove = value; break end
            end
        end
    end
    for _, item in ipairs(items) do
        if not Player.Backpack:FindFirstChild(item) then
            pcall(function() ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(item) end)
            task.wait(1)
        end
    end
    for _, item in ipairs(items) do
        if not Player.Backpack:FindFirstChild(item) then
            notify("Money", "Need more cash / missing items."); return
        end
    end
    if not stove then notify("Money", "Could not find a cooking stove."); return end
    Config:Teleport(stove.CookPart.CFrame); task.wait(1)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
    Player.Character.HumanoidRootPart.Anchored = true; task.wait(1.5)
    pcall(function() fireproximityprompt(stove:FindFirstChildWhichIsA("ProximityPrompt", true)) end)
    task.wait(2)
    for _, item in ipairs({"FijiWater","FreshWater","Ice-Fruit Bag"}) do
        if Player.Backpack:FindFirstChild(item) then
            Player.Character.Humanoid:EquipTool(Player.Backpack[item]); task.wait(1)
            pcall(function() fireproximityprompt(stove:FindFirstChildWhichIsA("ProximityPrompt", true)) end)
            task.wait(3)
        end
    end
    pcall(function() repeat task.wait() until stove.CookPart.Steam.LoadUI.Enabled == false end)
    if not Player.Character:FindFirstChild("Ice-Fruit Cupz") and Player.Backpack:FindFirstChild("Ice-Fruit Cupz") then
        Player.Character.Humanoid:EquipTool(Player.Backpack["Ice-Fruit Cupz"]); task.wait(1)
    end
    task.wait(1)
    pcall(function() fireproximityprompt(stove:FindFirstChildWhichIsA("ProximityPrompt", true)) end)
    task.wait(3)
    Player.Character.HumanoidRootPart.Anchored = false
    if workspace:FindFirstChild("IceFruit Sell") then
        Config:Teleport(workspace["IceFruit Sell"].CFrame); task.wait(1)
        Player.Character.HumanoidRootPart.Anchored = true; task.wait(1.5)
        if not Player.Character:FindFirstChild("Ice-Fruit Cupz") and Player.Backpack:FindFirstChild("Ice-Fruit Cupz") then
            Player.Character.Humanoid:EquipTool(Player.Backpack["Ice-Fruit Cupz"]); task.wait(1)
        end
        workspace["IceFruit Sell"].ProximityPrompt.HoldDuration = 0
        for _ = 1, 4000 do task.spawn(function()
            pcall(function() fireproximityprompt(workspace["IceFruit Sell"].ProximityPrompt) end)
        end) end
    end
    Player.Character.HumanoidRootPart.Anchored = false
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
end

local function DropMoneyAmount(amount)
    local BankRemote = ReplicatedStorage:FindFirstChild('BankProcessRemote', true)
    if not BankRemote then return false end
    local function send(...)
        if BankRemote.InvokeServer then return BankRemote:InvokeServer(...)
        elseif BankRemote.FireServer then return BankRemote:FireServer(...) end
    end
    for _, args in ipairs({{"Drop",tostring(amount)},{"Drop",tonumber(amount) or amount}}) do
        local ok, r = pcall(send, table.unpack(args))
        if ok and r ~= false then return true end
    end
end
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().MoneyDropEnabled then pcall(function() DropMoneyAmount(10000) end) end
    end
end)

--------------------------------------------------------------------
-- VEHICLES
--------------------------------------------------------------------
Config.TheBronx = Config.TheBronx or { carfly = false, carflyspeed = 120 }
CarFly = { Enabled = false, Speed = 120 }
local LuhjayyCarHum, LuhjayyCarSeat, LuhjayyCar, LuhjayyCarRoot
local LuhjayyCarBV, LuhjayyCarBG, LuhjayyLastCar

local function LuhjayyCarFlyCleanup()
    if LuhjayyCarBV then LuhjayyCarBV:Destroy() LuhjayyCarBV = nil end
    if LuhjayyCarBG then LuhjayyCarBG:Destroy() LuhjayyCarBG = nil end
end

local function LuhjayyCarFlySetup()
    LuhjayyCarFlyCleanup()
    if not Config.TheBronx.carfly then return end
    local char = LocalPlayer.Character; if not char then return end
    LuhjayyCarHum = char:FindFirstChildWhichIsA("Humanoid"); if not LuhjayyCarHum then return end
    LuhjayyCarSeat = LuhjayyCarHum.SeatPart
    if not LuhjayyCarSeat or not LuhjayyCarSeat:IsA("VehicleSeat") then return end
    LuhjayyCar = LuhjayyCarSeat.Parent; if not LuhjayyCar then return end
    LuhjayyCarRoot = LuhjayyCar.PrimaryPart; if not LuhjayyCarRoot then return end
    LuhjayyLastCar = LuhjayyCar
    for _, v in ipairs(LuhjayyCar:GetChildren()) do
        if v:IsA("BasePart") and not v.Name:lower():find("wheel") then v.CanCollide = false end
    end
    LuhjayyCarBV = Instance.new("BodyVelocity")
    LuhjayyCarBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    LuhjayyCarBV.Velocity = Vector3.zero
    LuhjayyCarBV.Parent = LuhjayyCarRoot
    LuhjayyCarBG = Instance.new("BodyGyro")
    LuhjayyCarBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    LuhjayyCarBG.P = 25000; LuhjayyCarBG.D = 1500
    LuhjayyCarBG.CFrame = LuhjayyCarRoot.CFrame
    LuhjayyCarBG.Parent = LuhjayyCarRoot
end

local function StartCarFly()
    Config.TheBronx.carfly = true; CarFly.Enabled = true
    LuhjayyCarFlySetup()
    notify("Car Fly", "Car Fly enabled - get in a vehicle!")
end
local function StopCarFly()
    Config.TheBronx.carfly = false; CarFly.Enabled = false
    LuhjayyCarFlyCleanup()
    notify("Car Fly", "Car Fly disabled")
end

task.spawn(function()
    while true do
        task.wait(0.2)
        local char = LocalPlayer.Character; if not char then continue end
        local h = char:FindFirstChildWhichIsA("Humanoid"); if not h then continue end
        local currentSeat = h.SeatPart
        if currentSeat and currentSeat:IsA("VehicleSeat") then
            if currentSeat.Parent ~= LuhjayyLastCar then LuhjayyCarFlySetup() end
        else
            if LuhjayyLastCar then LuhjayyCarFlyCleanup(); LuhjayyLastCar = nil end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Config.TheBronx.carfly then LuhjayyCarFlyCleanup(); return end
    if not LuhjayyCarHum or LuhjayyCarHum.SeatPart ~= LuhjayyCarSeat then return end
    if not LuhjayyCarRoot or not LuhjayyCarBV or not LuhjayyCarBG then LuhjayyCarFlySetup(); return end
    local speed = Config.TheBronx.carflyspeed or 120
    local cam = workspace.CurrentCamera
    local camCF = cam.CFrame
    local camLook = camCF.LookVector
    local camRight = camCF.RightVector
    if not UserInputService.TouchEnabled then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            LuhjayyCarBG.CFrame = CFrame.lookAt(LuhjayyCarRoot.Position, LuhjayyCarRoot.Position + camLook)
        end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camRight end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camRight end
        if move.Magnitude > 0 then LuhjayyCarBV.Velocity = move.Unit * speed
        else LuhjayyCarBV.Velocity = Vector3.zero end
    else
        LuhjayyCarBG.CFrame = CFrame.lookAt(LuhjayyCarRoot.Position, LuhjayyCarRoot.Position + camLook)
        local move = LuhjayyCarHum.MoveDirection
        local vertical = camLook.Y
        local velocity = (move * speed) + (Vector3.new(0, vertical, 0) * speed)
        if velocity.Magnitude > 0 then LuhjayyCarBV.Velocity = velocity
        else LuhjayyCarBV.Velocity = Vector3.zero end
    end
end)

local function GetNearestCar(hrp)
    local CivCars = workspace:FindFirstChild("CivCars"); if not CivCars then return nil end
    local nearestCar, nearestDist = nil, math.huge
    for _, car in ipairs(CivCars:GetChildren()) do
        if car:IsA("Model") then
            local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat")
            if seat and not seat.Occupant then
                if not car.PrimaryPart then
                    pcall(function() car.PrimaryPart = car:FindFirstChildWhichIsA("BasePart") end)
                end
                if car.PrimaryPart then
                    local d = (car.PrimaryPart.Position - hrp.Position).Magnitude
                    if d < nearestDist then nearestDist, nearestCar = d, car end
                end
            end
        end
    end
    return nearestCar
end

VehicleModifications = {
    SpeedEnabled = false, SpeedValue = 10/1000,
    BreakEnabled = false, BreakValue = 50/1000,
    InstantStop = false,
}

task.spawn(function()
    while task.wait() do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local seat = hum and hum.SeatPart
        if seat and seat:IsA("VehicleSeat") then
            if VehicleModifications.SpeedEnabled and UserInputService:IsKeyDown(Enum.KeyCode.W) then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity *
                    Vector3.new(1+VehicleModifications.SpeedValue, 1, 1+VehicleModifications.SpeedValue)
            end
            if VehicleModifications.BreakEnabled and UserInputService:IsKeyDown(Enum.KeyCode.S) then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity *
                    Vector3.new(1-VehicleModifications.BreakValue, 1, 1-VehicleModifications.BreakValue)
            end
            if VehicleModifications.InstantStop and UserInputService:IsKeyDown(Enum.KeyCode.V) then
                seat.AssemblyLinearVelocity = Vector3.zero
                seat.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

--------------------------------------------------------------------
-- MOVEMENT (walk / fly / noclip / jump)
--------------------------------------------------------------------
LuhjayyWalk = LuhjayyWalk or {
    Speed = 16, BoostMultiplier = 2, Enabled = false,
    Character = nil, Humanoid = nil, Root = nil,
    BodyGyro = nil, MovementConnection = nil, FreezeConnection = nil, AnimationTrack = nil,
}
LuhjayyWalk.Animation = LuhjayyWalk.Animation or Instance.new("Animation")
LuhjayyWalk.Animation.AnimationId = "rbxassetid://130336142547434"

local function LuhjayyWalkUpdateCharacter()
    LuhjayyWalk.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    LuhjayyWalk.Root = LuhjayyWalk.Character:WaitForChild("HumanoidRootPart")
    LuhjayyWalk.Humanoid = LuhjayyWalk.Character:WaitForChild("Humanoid")
end

local function LuhjayyWalkCleanup()
    if LuhjayyWalk.MovementConnection then LuhjayyWalk.MovementConnection:Disconnect();LuhjayyWalk.MovementConnection=nil end
    if LuhjayyWalk.FreezeConnection then LuhjayyWalk.FreezeConnection:Disconnect();LuhjayyWalk.FreezeConnection=nil end
    if LuhjayyWalk.BodyGyro then LuhjayyWalk.BodyGyro:Destroy();LuhjayyWalk.BodyGyro=nil end
    if LuhjayyWalk.AnimationTrack then pcall(function()LuhjayyWalk.AnimationTrack:Stop()end);LuhjayyWalk.AnimationTrack=nil end
end

local function LuhjayyWalkSetupMovement()
    local humanoid=LuhjayyWalk.Humanoid
    local root=LuhjayyWalk.Root
    if not humanoid or not root then return end
    local bg=Instance.new("BodyGyro")
    bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    bg.P=50000; bg.D=1000; bg.CFrame=root.CFrame; bg.Parent=root
    LuhjayyWalk.BodyGyro=bg
    LuhjayyWalk.MovementConnection=RunService.RenderStepped:Connect(function()
        if not LuhjayyWalk.Enabled or not root.Parent then return end
        local camera=workspace.CurrentCamera
        local dir=Vector3.zero; local usingKeys=false
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z);usingKeys=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z);usingKeys=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=camera.CFrame.RightVector;usingKeys=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=camera.CFrame.RightVector;usingKeys=true end
        if not usingKeys then local md=humanoid.MoveDirection;dir=Vector3.new(md.X,0,md.Z) end
        local moveSpeed=LuhjayyWalk.Speed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveSpeed*=LuhjayyWalk.BoostMultiplier end
        if dir.Magnitude>0 then dir=dir.Unit*moveSpeed end
        local currentY=root.AssemblyLinearVelocity.Y
        local groundedY=math.clamp(currentY,-100,-2)
        root.AssemblyLinearVelocity=Vector3.new(dir.X,groundedY,dir.Z)
        if dir.Magnitude>0 then
            local look=dir.Unit
            bg.CFrame=CFrame.new(root.Position,root.Position+Vector3.new(look.X,0,look.Z))
        end
        root.RotVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
        if LuhjayyWalk.AnimationTrack then
            if dir.Magnitude>0 then
                if not LuhjayyWalk.AnimationTrack.IsPlaying then LuhjayyWalk.AnimationTrack:Play() end
            elseif LuhjayyWalk.AnimationTrack.IsPlaying then LuhjayyWalk.AnimationTrack:Stop() end
        end
    end)
end

local function LuhjayyWalkStart()
    LuhjayyWalk.Enabled=true
    LuhjayyWalkUpdateCharacter()
    LuhjayyWalkCleanup()
    local root,humanoid=LuhjayyWalk.Root,LuhjayyWalk.Humanoid
    root.AssemblyLinearVelocity=Vector3.zero
    getgenv().SwimMethod=true
    LuhjayyWalk.FreezeConnection=RunService.RenderStepped:Connect(function()
        if LuhjayyWalk.Enabled and root.Parent then
            if not getgenv().SwimMethod then getgenv().SwimMethod=true end
            root.AssemblyLinearVelocity=Vector3.zero
        end
    end)
    pcall(function()
        local animator=humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator",humanoid)
        LuhjayyWalk.AnimationTrack=animator:LoadAnimation(LuhjayyWalk.Animation)
        LuhjayyWalk.AnimationTrack.Looped=true
    end)
    task.delay(3,function()
        if LuhjayyWalk.FreezeConnection then LuhjayyWalk.FreezeConnection:Disconnect();LuhjayyWalk.FreezeConnection=nil end
        if LuhjayyWalk.Enabled then LuhjayyWalkSetupMovement() end
    end)
end

local function LuhjayyWalkStop()
    LuhjayyWalk.Enabled=false
    LuhjayyWalkCleanup()
    getgenv().SwimMethod=false
end

task.spawn(function()
    while task.wait() do
        if LuhjayyWalk.Enabled then
            if not getgenv().SwimMethod then getgenv().SwimMethod=true end
            if LuhjayyWalk.Humanoid then LuhjayyWalk.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown) end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    LuhjayyWalkUpdateCharacter()
    if LuhjayyWalk.Enabled then LuhjayyWalkStart() end
end)

local function updateJumpBoostState(s)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.JumpPower = s and ((hum.JumpPower or 50)+50) or 50
end

InfJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

NoclipEnabled = false
local noclipConnection
local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not NoclipEnabled then return end
        local ch = LocalPlayer.Character
        if ch then
            for _, p in pairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end
local function disableNoclip()
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection=nil end
    local ch = LocalPlayer.Character
    if ch then
        for _, p in pairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- fly
getgenv().MiamiFlyData = {
    Enabled = false, Connections = {}, Velocity = nil, Gyro = nil,
    Seat = nil, Weld = nil, Speed = 80,
    Move = {W=false, A=false, S=false, D=false, Space=false, Shift=false}
}
local function MiamiFlyCleanup()
    local data = getgenv().MiamiFlyData
    data.Enabled = false
    for _, c in ipairs(data.Connections or {}) do pcall(function() c:Disconnect() end) end
    data.Connections = {}
    for _, item in ipairs({data.Velocity, data.Gyro, data.Weld, data.Seat}) do
        pcall(function() if item and item.Parent then item:Destroy() end end)
    end
    data.Velocity=nil; data.Gyro=nil; data.Weld=nil; data.Seat=nil
    data.Move = {W=false, A=false, S=false, D=false, Space=false, Shift=false}
    getgenv().SwimMethod = false
    local character = LocalPlayer and LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid then
        pcall(function()
            humanoid.Sit=false; humanoid.PlatformStand=false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    if root then
        pcall(function()
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        end)
    end
end

local function MiamiFlySetup()
    local data = getgenv().MiamiFlyData
    MiamiFlyCleanup()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then notify("Fly","Character not ready."); return end
    data.Enabled = true; getgenv().SwimMethod = true
    local seat = Instance.new("VehicleSeat")
    seat.Name = "aqxFlySeat"; seat.Anchored=false; seat.CanCollide=false
    seat.Transparency=1; seat.Size=Vector3.new(2,1,2)
    seat.CFrame = root.CFrame * CFrame.new(0,-3,0)
    seat.Parent = workspace; data.Seat = seat
    local weld = Instance.new("Weld")
    weld.Part0 = seat; weld.Part1 = root; weld.C0 = CFrame.new(0,3,0)
    weld.Parent = seat; data.Weld = weld
    pcall(function() seat:Sit(humanoid) end)
    local v = Instance.new("BodyVelocity")
    v.MaxForce = Vector3.new(1e9,1e9,1e9); v.Velocity = Vector3.zero; v.Parent = root
    data.Velocity = v
    local g = Instance.new("BodyGyro")
    g.MaxTorque = Vector3.new(1e9,1e9,1e9); g.P=50000; g.D=1000
    g.CFrame = root.CFrame; g.Parent = root; data.Gyro = g
    table.insert(data.Connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        local k = input.KeyCode
        if k==Enum.KeyCode.W then data.Move.W=true end
        if k==Enum.KeyCode.A then data.Move.A=true end
        if k==Enum.KeyCode.S then data.Move.S=true end
        if k==Enum.KeyCode.D then data.Move.D=true end
        if k==Enum.KeyCode.Space then data.Move.Space=true end
        if k==Enum.KeyCode.LeftShift then data.Move.Shift=true end
        if k==Enum.KeyCode.E then data.Speed=math.clamp((data.Speed or 80)+10,20,300) end
        if k==Enum.KeyCode.Q then data.Speed=math.clamp((data.Speed or 80)-10,20,300) end
    end))
    table.insert(data.Connections, UserInputService.InputEnded:Connect(function(input)
        local k = input.KeyCode
        if k==Enum.KeyCode.W then data.Move.W=false end
        if k==Enum.KeyCode.A then data.Move.A=false end
        if k==Enum.KeyCode.S then data.Move.S=false end
        if k==Enum.KeyCode.D then data.Move.D=false end
        if k==Enum.KeyCode.Space then data.Move.Space=false end
        if k==Enum.KeyCode.LeftShift then data.Move.Shift=false end
    end))
    table.insert(data.Connections, RunService.RenderStepped:Connect(function()
        if not data.Enabled or not data.Velocity or not data.Gyro then return end
        if not root or not root.Parent then MiamiFlyCleanup() return end
        getgenv().SwimMethod = true
        local camera = workspace.CurrentCamera; if not camera then return end
        data.Gyro.CFrame = camera.CFrame
        local dir = Vector3.zero
        if data.Move.W then dir += camera.CFrame.LookVector end
        if data.Move.S then dir -= camera.CFrame.LookVector end
        if data.Move.A then dir -= camera.CFrame.RightVector end
        if data.Move.D then dir += camera.CFrame.RightVector end
        if data.Move.Space then dir += Vector3.new(0,1,0) end
        if data.Move.Shift then dir -= Vector3.new(0,1,0) end
        if UserInputService.TouchEnabled and humanoid then dir += humanoid.MoveDirection end
        if dir.Magnitude > 0 then data.Velocity.Velocity = dir.Unit * (data.Speed or 80)
        else data.Velocity.Velocity = Vector3.zero end
    end))
    notify("Fly","Fly enabled. WASD + Space/Shift, Q/E changes speed.", 3)
end

--------------------------------------------------------------------
-- MISC PLAYER TOGGLES
--------------------------------------------------------------------
AutoGrabMoney = false
AutoCleanMoney = false
StudioMoneyNotifyEnabled = false
StudioMoneyNotifyConnections = {}
dumpsterIsRunning = false
dumpsterTask = nil
constructionRunning = false
constructionThread = nil
AutoStealLootbags = false
AutoPickupBags = false
DisableBloodEffects = false
BypassLockedCars = false
NoKnockback = false
FasterRespawn = false
RespawnWhereYouDied = false
RespawnDeathCFrame = nil
RespawnDeathConnections = {}
KeepToolsOnDeath = false
AutoFOnLowHealth = false
NoCameraBob = false
AntiJumpCooldownEnabled = false
AntiJumpDisabledScripts = {}

local function ClearRespawnDeathConnections()
    for _, c in ipairs(RespawnDeathConnections) do pcall(function() c:Disconnect() end) end
    RespawnDeathConnections = {}
end

local function CaptureRespawnDeathPosition(character)
    if not RespawnWhereYouDied or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then RespawnDeathCFrame = root.CFrame end
end

local function BindRespawnWhereDiedCharacter(character)
    ClearRespawnDeathConnections()
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root then return end
    local captured = false
    table.insert(RespawnDeathConnections, humanoid.HealthChanged:Connect(function(h)
        if h <= 0 and not captured then captured = true; CaptureRespawnDeathPosition(character) end
    end))
    table.insert(RespawnDeathConnections, humanoid.Died:Connect(function()
        if not captured then captured = true; CaptureRespawnDeathPosition(character) end
    end))
end

local function SetRespawnWhereYouDied(state)
    RespawnWhereYouDied = state == true
    if not RespawnWhereYouDied then RespawnDeathCFrame = nil end
end

if LocalPlayer.Character then task.defer(BindRespawnWhereDiedCharacter, LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(character)
    local returnCFrame = RespawnWhereYouDied and RespawnDeathCFrame or nil
    BindRespawnWhereDiedCharacter(character)
    if not returnCFrame then return end
    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not root or not humanoid or not RespawnWhereYouDied then return end
        task.wait(0.8)
        local restored = pcall(function() Config:Teleport(returnCFrame) end)
        if not restored and root.Parent then root.CFrame = returnCFrame end
        if root.Parent then
            root.CFrame = returnCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        RespawnDeathCFrame = nil
        notify("Respawn","Returned to your death position.")
    end)
end)

onUnload(function()
    ClearRespawnDeathConnections()
end)

local function SetAntiJumpCooldownEnabled(state)
    AntiJumpCooldownEnabled = state
    local function process(container)
        if not container then return end
        for _, object in ipairs(container:GetDescendants()) do
            if object:IsA("LocalScript") then
                local name = object.Name:lower()
                local path = object:GetFullName():lower()
                local isJumpCooldown = (name:find("jump") and (name:find("debounce") or name:find("cooldown")))
                    or path:find("jumpdebounce",1,true) or path:find("jumpcooldown",1,true)
                if isJumpCooldown then
                    if state then
                        if AntiJumpDisabledScripts[object]==nil then AntiJumpDisabledScripts[object]=object.Enabled end
                        object.Enabled=false
                    elseif AntiJumpDisabledScripts[object]~=nil then
                        object.Enabled=AntiJumpDisabledScripts[object]
                        AntiJumpDisabledScripts[object]=nil
                    end
                end
            end
        end
    end
    process(LocalPlayer:FindFirstChild("PlayerGui"))
    process(LocalPlayer.Character)
    if not state then
        for so, prev in pairs(AntiJumpDisabledScripts) do
            pcall(function() if so and so.Parent then so.Enabled = prev end end)
            AntiJumpDisabledScripts[so]=nil
        end
    end
end

local LastForcedJump = 0
UserInputService.JumpRequest:Connect(function()
    if not AntiJumpCooldownEnabled or os.clock()-LastForcedJump < 0.08 then return end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return end
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    if not grounded then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        grounded = workspace:Raycast(root.Position, Vector3.new(0,-4.5,0), params) ~= nil
    end
    if not grounded then return end
    LastForcedJump = os.clock()
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    humanoid.Jump = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    local jumpVelocity = 50
    if humanoid.UseJumpPower then
        jumpVelocity = math.max(tonumber(humanoid.JumpPower) or 50, 50)
    else
        jumpVelocity = math.sqrt(2 * workspace.Gravity * math.max(tonumber(humanoid.JumpHeight) or 7.2, 7.2))
    end
    local v = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, jumpVelocity), v.Z)
end)

-- anti car fling
AntiCarFlingEnabled = false
AntiCarFlingConnection = nil
AntiCarFlingSavedParts = {}
AntiCarFlingProtectedCars = {}

local function RestoreAntiCarFlingPart(part)
    local saved = AntiCarFlingSavedParts[part]
    if saved then
        pcall(function()
            if part and part.Parent then
                part.CanCollide = saved.CanCollide
                part.CanTouch = saved.CanTouch
            end
        end)
        AntiCarFlingSavedParts[part]=nil
    end
end

local function ProtectFromFlingCar(car)
    if not car then return end
    AntiCarFlingProtectedCars[car] = os.clock() + 1.25
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            if not AntiCarFlingSavedParts[part] then
                AntiCarFlingSavedParts[part] = {CanCollide=part.CanCollide, CanTouch=part.CanTouch}
            end
            part.CanCollide = false; part.CanTouch = false
        end
    end
end

local function GetAntiFlingCars()
    local cars = {}
    for _, folderName in ipairs({"CivCars","PoliceCars","NPCCars","Cars","Vehicles"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, car in ipairs(folder:GetChildren()) do
                if car:IsA("Model") then table.insert(cars, car) end
            end
        end
    end
    return cars
end

local function StopAntiCarFling()
    AntiCarFlingEnabled = false
    if AntiCarFlingConnection then
        AntiCarFlingConnection:Disconnect(); AntiCarFlingConnection = nil
    end
    for part in pairs(AntiCarFlingSavedParts) do RestoreAntiCarFlingPart(part) end
    table.clear(AntiCarFlingProtectedCars)
end

local function StartAntiCarFling()
    StopAntiCarFling()
    AntiCarFlingEnabled = true
    AntiCarFlingConnection = RunService.Heartbeat:Connect(function()
        if not AntiCarFlingEnabled then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or humanoid.Health <= 0 then return end
        local occupiedSeat = humanoid.SeatPart
        local occupiedCar = occupiedSeat and occupiedSeat:FindFirstAncestorWhichIsA("Model")
        local detectedFling = false
        for _, car in ipairs(GetAntiFlingCars()) do
            if car ~= occupiedCar then
                local mainPart = car.PrimaryPart or car:FindFirstChild("DriveSeat", true)
                    or car:FindFirstChildWhichIsA("BasePart", true)
                if mainPart then
                    local d = (mainPart.Position - root.Position).Magnitude
                    local lin = mainPart.AssemblyLinearVelocity.Magnitude
                    local spin = mainPart.AssemblyAngularVelocity.Magnitude
                    if d <= 9 or (d <= 28 and (lin >= 90 or spin >= 35)) then
                        ProtectFromFlingCar(car); detectedFling = true
                    end
                end
            end
        end
        if detectedFling then
            if humanoid.Sit and not occupiedCar then
                humanoid.Sit = false; humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            if root.AssemblyLinearVelocity.Magnitude > 120 then root.AssemblyLinearVelocity = Vector3.zero end
            if root.AssemblyAngularVelocity.Magnitude > 30 then root.AssemblyAngularVelocity = Vector3.zero end
        end
        local now = os.clock()
        for car, exp in pairs(AntiCarFlingProtectedCars) do
            if not car.Parent or now >= exp then
                AntiCarFlingProtectedCars[car] = nil
                for part in pairs(AntiCarFlingSavedParts) do
                    if not part.Parent or part:IsDescendantOf(car) then RestoreAntiCarFlingPart(part) end
                end
            end
        end
    end)
end

-- autofarms
PawnRemote      = ReplicatedStorage:FindFirstChild("PawnRemote")
BackpackRemote  = ReplicatedStorage:FindFirstChild("BackpackRemote")
InventoryRemote = ReplicatedStorage:FindFirstChild("Inventory")

local function fireRemoteForAllBackpackItems()
    if not Backpack then return end
    for _, item in pairs(Backpack:GetChildren()) do
        pcall(function() if PawnRemote then PawnRemote:FireServer(item.Name) end end)
    end
end
if Backpack then
    Backpack.ChildAdded:Connect(function(child)
        if dumpsterIsRunning then
            pcall(function() if PawnRemote then PawnRemote:FireServer(child.Name) end end)
        end
    end)
end

local function startDumpsterAutofarm()
    if dumpsterTask then return end
    dumpsterIsRunning = true
    dumpsterTask = task.spawn(function()
        while dumpsterIsRunning do
            local dumpsters = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Part") and v.Name == "DumpsterPromt" then
                    local p = v:FindFirstChildWhichIsA("ProximityPrompt")
                    if p then table.insert(dumpsters, {part=v, prompt=p}) end
                end
            end
            for _, e in ipairs(dumpsters) do
                if not dumpsterIsRunning then break end
                if e.part and e.prompt and e.part:IsDescendantOf(workspace) then
                    Config:Teleport(CFrame.new(e.part.Position + Vector3.new(0,3,0)))
                    task.wait(0.6)
                    pcall(function() fireproximityprompt(e.prompt) end)
                    task.wait(1)
                end
            end
            task.wait(2)
        end
        dumpsterTask = nil
    end)
    fireRemoteForAllBackpackItems()
end
local function stopDumpsterAutofarm() dumpsterIsRunning = false end

local function startConstructionAutofarm()
    if constructionThread then return end
    constructionRunning = true
    constructionThread = task.spawn(function()
        while constructionRunning do
            task.wait(1)
            pcall(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                if not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character:FindFirstChild("Humanoid").Health == 0 then return end
                if not LocalPlayer:GetAttribute("WorkingJob") then
                    Config:Teleport(CFrame.new(-1729, 371, -1171)); task.wait(0.4)
                    fireproximityprompt(workspace.ConstructionStuff["Start Job"].Prompt)
                    repeat task.wait() until LocalPlayer:GetAttribute("WorkingJob") or not constructionRunning
                end
                if not LocalPlayer.Backpack:FindFirstChild("PlyWood") and not LocalPlayer.Character:FindFirstChild("PlyWood") then
                    Config:Teleport(CFrame.new(-1728, 371, -1178))
                    repeat task.wait() fireproximityprompt(workspace.ConstructionStuff["Grab Wood"].Prompt)
                    until LocalPlayer.Backpack:FindFirstChild("PlyWood")
                        or LocalPlayer.Character:FindFirstChild("PlyWood")
                        or not constructionRunning
                end
                repeat task.wait() until LocalPlayer.Backpack:FindFirstChild("PlyWood")
                    or LocalPlayer.Character:FindFirstChild("PlyWood")
                    or not constructionRunning
                if LocalPlayer.Backpack:FindFirstChild("PlyWood") then
                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("PlyWood"))
                end
                local targetWood
                for _, v in pairs(workspace.ConstructionStuff:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.ActionText == "Wall" then targetWood = v; break end
                end
                if targetWood and targetWood.Parent then
                    Config:Teleport(targetWood.Parent.CFrame + Vector3.new(0,3,0)); task.wait(0.4)
                    fireproximityprompt(targetWood); task.wait(1)
                end
            end)
        end
        constructionThread = nil
    end)
end
local function stopConstructionAutofarm()
    constructionRunning = false
    if constructionThread then task.cancel(constructionThread); constructionThread = nil end
end

-- instant interaction
promptConnections = {}
local promptAddedConnection
local function setupPrompt(p, enableInstant)
    if not p or not p:IsA("ProximityPrompt") then return end
    if enableInstant then
        p.HoldDuration = 0; p.RequiresLineOfSight = false
        promptConnections[p] = true
    else
        p.HoldDuration = 1; p.RequiresLineOfSight = true
        promptConnections[p] = nil
    end
end
local function refreshPrompts(enableInstant)
    for prompt in pairs(promptConnections) do promptConnections[prompt] = nil end
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then setupPrompt(p, enableInstant) end
    end
    if promptAddedConnection then promptAddedConnection:Disconnect(); promptAddedConnection = nil end
    if enableInstant then
        promptAddedConnection = workspace.DescendantAdded:Connect(function(d)
            if d:IsA("ProximityPrompt") then setupPrompt(d, true) end
        end)
    end
end

local function watchStudioPayPrompt(studioPayName)
    local sp = workspace:FindFirstChild("StudioPay"); if not sp then return end
    local mf = sp:FindFirstChild("Money"); if not mf then return end
    local part = mf:FindFirstChild(studioPayName); if not part then return end
    local prompt = part:FindFirstChild("Prompt")
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    local c = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not StudioMoneyNotifyEnabled then return end
        notify(prompt.Enabled and "Studio Money Restocked" or "Studio Money Stolen",
            prompt.Enabled and "Money in studio restocked." or "1 money in studio just got stolen!")
    end)
    table.insert(StudioMoneyNotifyConnections, c)
end
local function cleanupStudioMoneyNotify()
    for _, c in ipairs(StudioMoneyNotifyConnections) do
        if c and c.Disconnect then c:Disconnect() end
    end
    StudioMoneyNotifyConnections = {}
end

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, selfPlayer)
    if not (prompt and selfPlayer == LocalPlayer and BypassLockedCars) then return end
    local check = prompt.Parent
    while check and check.Parent do
        local seat = check:FindFirstChild("DriveSeat")
        if seat and seat:IsA("VehicleSeat") and LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("Humanoid") then
            pcall(function() seat:Sit(LocalPlayer.Character.Humanoid) end); break
        end
        check = check.Parent
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if FasterRespawn and LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        and LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
            local lc = ReplicatedStorage:FindFirstChild("LoadCharacter")
            if lc and lc:IsA("RemoteEvent") then pcall(function() lc:FireServer() end) end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if NoCameraBob then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.CameraOffset.Magnitude > 0 then hum.CameraOffset = Vector3.zero end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not AutoFOnLowHealth then break end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.Health < 10 then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil); task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
            end)
        end
    end
end)

--------------------------------------------------------------------
-- MISC LOOPS (dollas, storage, blood)
--------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if AutoGrabMoney then
            local d = workspace:FindFirstChild("Dollas")
            if d then
                for _, item in ipairs(d:GetChildren()) do
                    if not AutoGrabMoney then break end
                    if (item.Name=="DeadMoney" or item.Name=="Money") and item:IsA("BasePart") then
                        local pr = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if pr and pr.Enabled then
                            local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                            local root = ch:FindFirstChild("HumanoidRootPart"); if not root then break end
                            local old = root.CFrame
                            getgenv().SwimMethod = true; task.wait(0.3)
                            Config:Teleport(item.CFrame+Vector3.new(0,2,0)); task.wait(0.3)
                            fireproximityprompt(pr); task.wait(0.3)
                            Config:Teleport(old); task.wait(0.5)
                            getgenv().SwimMethod = false
                        end
                    end
                end
            end
        end
        if AutoPickupBags and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local st = workspace:FindFirstChild("Storage")
            if st then
                for _, v in next, st:GetChildren() do
                    if v:IsA("MeshPart") then
                        if v:FindFirstChild("PlayerName") and v.PlayerName.Value == LocalPlayer.Name then break end
                        if (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 5 then
                            local p = v:FindFirstChild("stealprompt")
                            if p and p:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(p) end) end
                        end
                    end
                end
            end
        end
        if DisableBloodEffects and LocalPlayer:FindFirstChild("PlayerGui")
        and LocalPlayer.PlayerGui:FindFirstChild("BloodGui") then
            LocalPlayer.PlayerGui.BloodGui.Enabled = false
        end
    end
end)

task.spawn(function()
    while task.wait(1200) do
        if getgenv().AntiAFKEnabled then
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if AutoStealLootbags then
            local st = workspace:FindFirstChild("Storage")
            if st then
                for _, item in ipairs(st:GetChildren()) do
                    if not AutoStealLootbags then break end
                    local pr = item:FindFirstChild("stealprompt", true)
                    if pr and pr:IsA("ProximityPrompt") and pr.Enabled then
                        local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local root = ch:FindFirstChild("HumanoidRootPart"); if not root then break end
                        local old = root.CFrame
                        getgenv().SwimMethod = true; task.wait(0.3)
                        local tp = pr.Parent:IsA("BasePart") and pr.Parent or item:FindFirstChildWhichIsA("BasePart", true)
                        if not tp then break end
                        Config:Teleport(tp.CFrame+Vector3.new(0,2,0)); task.wait(0.3)
                        fireproximityprompt(pr); task.wait(0.3)
                        Config:Teleport(old); task.wait(0.5)
                        getgenv().SwimMethod = false
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------
-- GUN COLOR + BULLET VISUALS + SPRAYPAINT
--------------------------------------------------------------------
local fireBallsEnabled = false
local function setBulletVisuals(t)
    if typeof(t) ~= "table" or not rawget(t, "BulletSpeed") then return end
    rawset(t, "BulletSpeed", 150)
    rawset(t, "DropGravity", 0.3)
    rawset(t, "BulletParticleEnaled", true)
    rawset(t, "BulletParticleColor", Color3.new(1,0,0))
    rawset(t, "BulletParticleSize", NumberSequence.new({
        NumberSequenceKeypoint.new(0, 9e9),
        NumberSequenceKeypoint.new(1, 1),
    }))
end

local FlashbangBulletsEnabled = false
local TornadoBulletsEnabled = false
local TornadoBulletSpeed = 250
local OrbFlashLastScan = 0
local OrbFlashConfigs = setmetatable({}, {__mode = "k"})
local OrbFlashOriginals = setmetatable({}, {__mode = "k"})
local OrbFlashKeys = {
    "BulletSpeed","DropGravity","BulletSize","BulletMeshScale","BulletTransparency",
    "BulletMeshEnabled","BulletMeshID","BulletTextureID","BulletLightEnabled",
    "BulletLightBrightness","BulletLightRange","BulletLightColor","MuzzleLightEnabled",
    "LightColor","LightBrightness","LightRange","LightShadows","MuzzleFlashEnabled","DisappearTime",
}

local function saveOrbFlashOriginals(config)
    if OrbFlashOriginals[config] then return end
    local saved = {values={}, exists={}}
    for _, key in ipairs(OrbFlashKeys) do
        local v = rawget(config, key)
        saved.exists[key] = v ~= nil
        saved.values[key] = v
    end
    OrbFlashOriginals[config] = saved
end

local function restoreOrbFlashConfig(config)
    local saved = OrbFlashOriginals[config]
    if not saved then return end
    for _, key in ipairs(OrbFlashKeys) do
        rawset(config, key, saved.exists[key] and saved.values[key] or nil)
    end
end

local function collectOrbFlashConfigs()
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return end
    local function add(config)
        if typeof(config) == "table" and rawget(config, "BulletSpeed") then
            OrbFlashConfigs[config] = true
            saveOrbFlashOriginals(config)
        end
    end
    for _, object in ipairs(objects) do
        if typeof(object) == "table" then
            pcall(function()
                add(object)
                add(rawget(object, 7))
                add(rawget(object, 8))
            end)
        end
    end
    OrbFlashLastScan = os.clock()
end

local function applyOrbFlashConfig(config)
    restoreOrbFlashConfig(config)
    if FlashbangBulletsEnabled then
        rawset(config, "BulletLightEnabled", true)
        rawset(config, "BulletLightBrightness", 9e9)
        rawset(config, "BulletLightRange", 99999)
        if rawget(config, "BulletLightColor") ~= nil then rawset(config, "BulletLightColor", Color3.new(1,1,1)) end
        rawset(config, "MuzzleLightEnabled", true)
        rawset(config, "LightColor", Color3.new(1,1,1))
        rawset(config, "LightBrightness", 999)
        rawset(config, "LightRange", 999)
        rawset(config, "LightShadows", true)
        rawset(config, "MuzzleFlashEnabled", true)
        rawset(config, "DisappearTime", 8)
    end
    if TornadoBulletsEnabled then
        rawset(config, "BulletSpeed", TornadoBulletSpeed)
        rawset(config, "DropGravity", 0)
        rawset(config, "BulletSize", Vector3.new(1,1,1))
        rawset(config, "BulletMeshScale", Vector3.new(1,1,1))
        rawset(config, "BulletTransparency", 0)
        rawset(config, "BulletMeshEnabled", true)
        rawset(config, "BulletMeshID", "rbxassetid://15775612843")
        rawset(config, "BulletTextureID", "rbxassetid://15775612843")
    end
end

local function applyAllOrbFlashConfigs()
    if os.clock() - OrbFlashLastScan >= 5 then collectOrbFlashConfigs() end
    for config in pairs(OrbFlashConfigs) do pcall(applyOrbFlashConfig, config) end
end

local function restoreAllOrbFlashConfigs()
    for config in pairs(OrbFlashConfigs) do pcall(restoreOrbFlashConfig, config) end
end

local function refreshOrbFlashState()
    collectOrbFlashConfigs()
    if FlashbangBulletsEnabled or TornadoBulletsEnabled then applyAllOrbFlashConfigs()
    else restoreAllOrbFlashConfigs() end
end

-- spraypaint
local SprayPaintImagePresets = { ["Taco Scripts"] = 93586114576894 }
local SprayPaintImageNames = {"Taco Scripts"}
local SelectedSprayPaintImage = "Taco Scripts"
local SPRAYPAINT_IMAGE_ID = SprayPaintImagePresets[SelectedSprayPaintImage]
local SPRAYPAINT_IMAGE = "rbxassetid://" .. tostring(SPRAYPAINT_IMAGE_ID)
local SprayPaintEnabled = false
local ManualSprayPaintEnabled = false
local AutoSprayPaintEnabled = false
local AutoSprayPaintWorkerRunning = false
local AutoSprayPaintDelay = 1
local SprayPaintHoleSize = 10
local SprayPaintVisibleTime = 18000
local SprayPaintSavedSettings = setmetatable({}, {__mode = "k"})

local function ApplySprayPaintSettings(config)
    if typeof(config) ~= "table" or not rawget(config, "BulletSpeed") then return end
    if not SprayPaintSavedSettings[config] then
        SprayPaintSavedSettings[config] = {
            rawget(config, "BulletHoleEnabled"),
            rawget(config, "BulletHoleTexture"),
            rawget(config, "BulletHoleVisibleTime"),
            rawget(config, "BulletHoleSize"),
            rawget(config, "BulletHoleTextureId"),
        }
    end
    rawset(config, "BulletHoleEnabled", true)
    rawset(config, "BulletHoleTexture", {SPRAYPAINT_IMAGE_ID})
    rawset(config, "BulletHoleTextureId", SPRAYPAINT_IMAGE)
    rawset(config, "BulletHoleVisibleTime", SprayPaintVisibleTime)
    rawset(config, "BulletHoleSize", SprayPaintHoleSize)
end

local function ScanSprayPaintSettings()
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return end
    for _, object in ipairs(objects) do
        if typeof(object) == "table" then
            pcall(function()
                ApplySprayPaintSettings(object)
                ApplySprayPaintSettings(rawget(object, 7))
                ApplySprayPaintSettings(rawget(object, 8))
            end)
        end
    end
end

local function RestoreSprayPaintSettings()
    for config, saved in pairs(SprayPaintSavedSettings) do
        pcall(function()
            rawset(config, "BulletHoleEnabled", saved[1])
            rawset(config, "BulletHoleTexture", saved[2])
            rawset(config, "BulletHoleVisibleTime", saved[3])
            rawset(config, "BulletHoleSize", saved[4])
            rawset(config, "BulletHoleTextureId", saved[5])
        end)
        SprayPaintSavedSettings[config] = nil
    end
end

local function GetAutoSprayPaintGun()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local tool = character and character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("GunScript_Local") then return tool end
    if backpack and character then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("GunScript_Local") then
                local hum = character:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(item) end); task.wait(0.15) end
                return item
            end
        end
    end
end

local function FireAutoSprayPaintGun(gun)
    if not gun or not gun.Parent then return false end
    local pos = UserInputService:GetMouseLocation()
    if type(mouse1click) == "function" then
        pcall(mouse1click)
    else
        local sent = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.035)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end)
        if not sent then pcall(function() gun:Activate() end) end
    end
    return true
end

local function StartAutoSprayPaintWorker()
    if AutoSprayPaintWorkerRunning then return end
    AutoSprayPaintWorkerRunning = true
    task.spawn(function()
        local lastGun
        while AutoSprayPaintEnabled do
            local gun = GetAutoSprayPaintGun()
            if gun and gun.Parent then
                if gun ~= lastGun then lastGun = gun; ScanSprayPaintSettings() end
                FireAutoSprayPaintGun(gun)
            else
                notify("Auto Spraypaint","No gun was found. Auto Spraypaint stopped.")
                AutoSprayPaintEnabled = false
                SprayPaintEnabled = ManualSprayPaintEnabled
                if not SprayPaintEnabled then RestoreSprayPaintSettings() end
                break
            end
            task.wait(math.max(AutoSprayPaintDelay, 0.08))
        end
        AutoSprayPaintWorkerRunning = false
    end)
end

--------------------------------------------------------------------
-- SAFE / DUPE
--------------------------------------------------------------------
dupeBlacklist = {
    ["Fists"]=true, ["Fist"]=true, ["Phone"]=true, ["Car Keys"]=true,
    ["Car keys"]=true, ["Bandage"]=true, ["762s"]=true, ["556s"]=true,
    ["Extended"]=true, ["T shirt"]=true, ["Combat"]=true, ["Weight"]=true,
    ["Shiesty"]=true, ["Lemonade"]=true,
}

local function ShowBigAlert(msg)
    local coreGui = (gethui and gethui()) or CoreGui
    local sg = new("ScreenGui", {
        Name = "aqxBigAlert_" .. tostring(math.random(10000, 99999)),
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 99999,
    }, coreGui)
    local txt = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 100), Position = UDim2.new(0, 0, 0.2, 0),
        BackgroundTransparency = 1, Text = msg, TextColor3 = Color3.fromRGB(255,50,50),
        Font = Enum.Font.GothamBlack, TextSize = 40, TextStrokeTransparency = 0,
        TextStrokeColor3 = Color3.new(0,0,0), TextTransparency = 1,
    }, sg)
    task.spawn(function()
        for _ = 1, 10 do txt.TextTransparency = txt.TextTransparency - 0.1; task.wait(0.03) end
        task.wait(2)
        for _ = 1, 10 do
            txt.TextTransparency = txt.TextTransparency + 0.1
            txt.Position = txt.Position - UDim2.new(0, 0, 0.01, 0); task.wait(0.03)
        end
        sg:Destroy()
    end)
end

local function SilentBypassTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum then hum:ChangeState(0) end
    local sWait = tick()
    repeat task.wait() until not LocalPlayer:GetAttribute("LastACPos") or (tick() - sWait > 1)
    root.CFrame = targetCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.5)
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function GetActiveSafe()
    local function isMine(owner)
        if not owner then return false end
        if owner:IsA("ObjectValue") then return owner.Value == LocalPlayer end
        local value = tostring(owner.Value or "")
        return value == LocalPlayer.Name or value == LocalPlayer.DisplayName
    end
    local function findOwnedHouseAndSafe()
        for _, owner in ipairs(workspace:GetDescendants()) do
            if owner.Name:lower() == "owner"
            and (owner:IsA("StringValue") or owner:IsA("ObjectValue"))
            and isMine(owner) then
                local ancestor = owner.Parent
                while ancestor and ancestor ~= workspace do
                    local safe = ancestor:FindFirstChild("Safe", true)
                    if safe then return ancestor, safe end
                    ancestor = ancestor.Parent
                end
            end
        end
        return nil, nil
    end
    local house, mySafe = findOwnedHouseAndSafe()
    if not mySafe then return nil, nil, nil end
    local safePart
    if mySafe:IsA("BasePart") then safePart = mySafe
    else safePart = mySafe:FindFirstChild("Union", true) or mySafe:FindFirstChildWhichIsA("BasePart", true) end
    local safeCF = safePart and safePart.CFrame or nil
    return mySafe, nil, safeCF
end

local function GetSafeItems()
    local items = {}
    local invData = LocalPlayer:FindFirstChild("InvData")
    if invData then for _, c in ipairs(invData:GetChildren()) do table.insert(items, c.Name) end end
    table.sort(items); return items
end

local function GetLockedTools()
    local tools = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") and not dupeBlacklist[t.Name] then table.insert(tools, t.Name) end
        end
    end
    return tools
end

local function FirePromptsInArea(range, nameFilter)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local fired = 0
    local filter = nameFilter and tostring(nameFilter):lower() or nil
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local parent = prompt.Parent
            local part = parent and (parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart", true))
            local pPos = part and part.Position
            if pPos and (pPos - root.Position).Magnitude < range then
                local text = (tostring(prompt.Name).." "..tostring(prompt.ActionText).." "..tostring(prompt.ObjectText)):lower()
                local ancestor = parent
                for _ = 1, 5 do
                    if not ancestor then break end
                    text = text .. " " .. tostring(ancestor.Name):lower()
                    ancestor = ancestor.Parent
                end
                if not filter or text:find(filter, 1, true) then
                    pcall(function()
                        prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false
                        fireproximityprompt(prompt)
                    end)
                    fired = fired + 1
                end
            end
        end
    end
    return fired
end

local function OpenOwnedSafe(SafeFolder, safeCF)
    if not SafeFolder or not safeCF then return false, "Safe or safe position was not found" end
    SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0))
    task.wait(0.45)
    local fired = 0
    for _, prompt in ipairs(SafeFolder:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local ok = pcall(function()
                prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false
                fireproximityprompt(prompt)
            end)
            if ok then fired = fired + 1 end
        end
    end
    if fired == 0 then fired = FirePromptsInArea(18, "safe") end
    if fired == 0 then fired = FirePromptsInArea(7) end
    return fired > 0, fired > 0 and nil or "No enabled safe prompt was found"
end

local function TakeFromSafe(itemName)
    local SafeFolder, _, safeCF = GetActiveSafe()
    if not SafeFolder or not safeCF then ShowBigAlert("You must own a house to dupe!"); return false end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local origLoc = root.CFrame
    local success = false
    pcall(function()
        SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0)); task.wait(0.3)
        InventoryRemote:FireServer("Change", itemName, "Inv", SafeFolder); task.wait(0.5)
        SilentBypassTeleport(origLoc); task.wait(0.5)
        success = true
    end)
    return success
end

local function SafeDupeOnce(itemName, returnCFrame)
    local SafeFolder, _, safeCF = GetActiveSafe()
    if not SafeFolder or not safeCF then ShowBigAlert("You must own a house to dupe!"); return false end
    pcall(function()
        SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0)); task.wait(0.3)
        task.spawn(function() BackpackRemote:InvokeServer("Store", itemName) end)
        task.spawn(function() InventoryRemote:FireServer("Change", itemName, "Backpack", SafeFolder) end)
        task.wait(0.6)
        SilentBypassTeleport(returnCFrame); task.wait(1.2)
        BackpackRemote:InvokeServer("Grab", itemName); task.wait(0.5)
    end)
    return true
end

autoDupeActive = false
dupeCounter = 0
selectedDupeItem = nil

local function DoDupe(targetSpeed)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then notify("Dupe","No character!"); return end
    local origLoc = root.CFrame
    autoDupeActive = true
    notify("Dupe","Starting safe dupe...")
    if not selectedDupeItem or selectedDupeItem == "None" or selectedDupeItem == "(All locked tools)" then
        local locked = GetLockedTools()
        if #locked == 0 then autoDupeActive = false; notify("Dupe","No tools in backpack."); return end
        task.spawn(function()
            local SafeFolder, _, safeCF = GetActiveSafe()
            if not SafeFolder then ShowBigAlert("You must own a house to dupe!"); autoDupeActive=false; return end
            if safeCF then
                notify("Dupe","Opening Safe...")
                SilentBypassTeleport(safeCF * CFrame.new(0,2,0)); task.wait(0.7)
                FirePromptsInArea(15, "Safe")
            end
            notify("Dupe","Returning...")
            SilentBypassTeleport(origLoc); task.wait(0.5)
            local i = 1
            while autoDupeActive and (targetSpeed == math.huge or i <= targetSpeed) do
                local idx = ((i-1) % #locked) + 1
                SafeDupeOnce(locked[idx], origLoc)
                dupeCounter = dupeCounter + 1; task.wait(0.2)
                i = i + 1
            end
            autoDupeActive = false
            notify("Dupe","Auto Dupe Stopped. Total: " .. dupeCounter)
        end)
    else
        task.spawn(function()
            notify("Dupe","Grabbing " .. selectedDupeItem .. "...")
            local brs = ReplicatedStorage:FindFirstChild("BackpackRemote")
            if brs then brs:InvokeServer("Grab", selectedDupeItem) end
            task.wait(0.5)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:UnequipTools() end
            task.wait(0.3)
            local SafeFolder, _, safeCF = GetActiveSafe()
            if not SafeFolder then ShowBigAlert("You must own a house to dupe!"); autoDupeActive=false; return end
            if safeCF then
                notify("Dupe","Opening Safe...")
                SilentBypassTeleport(safeCF * CFrame.new(0,2,0)); task.wait(0.7)
                FirePromptsInArea(15, "Safe")
            end
            notify("Dupe","Returning...")
            SilentBypassTeleport(origLoc); task.wait(0.5)
            local i = 1
            while autoDupeActive and (targetSpeed == math.huge or i <= targetSpeed) do
                SafeDupeOnce(selectedDupeItem, origLoc)
                dupeCounter = dupeCounter + 1; task.wait(0.2)
                i = i + 1
            end
            autoDupeActive = false
            notify("Dupe","Auto Dupe Stopped. Total: " .. dupeCounter)
        end)
    end
end

local function SafeTP()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then notify("Safe TP","No character!"); return end
    notify("Safe TP","Finding your owned safe...")
    task.spawn(function()
        local ok, err = pcall(function()
            local SafeFolder, _, safeCF = GetActiveSafe()
            if not SafeFolder or not safeCF then
                ShowBigAlert("Could not find your owned house safe!")
                notify("Safe TP","Owned safe not found. Check the Owner value.")
                return
            end
            local opened, reason = OpenOwnedSafe(SafeFolder, safeCF)
            if opened then notify("Safe TP","Safe prompt fired successfully.")
            else notify("Safe TP", tostring(reason or "Failed to open safe")) end
        end)
        if not ok then warn("[aqx SafeTP] " .. tostring(err)); notify("Safe TP Error", tostring(err)) end
    end)
end

local autoDropEnabled = false
local function ToggleAutoDrop(state)
    local dropRemote = ReplicatedStorage:FindFirstChild("DropItemRemote")
    autoDropEnabled = state
    notify("Auto Drop", state and "Started" or "Stopped")
    if state then
        task.spawn(function()
            while autoDropEnabled do
                local bp = LocalPlayer:FindFirstChild("Backpack")
                local ch = LocalPlayer.Character
                if not bp or not ch then task.wait(0.5)
                else
                    local found = false
                    for _, item in ipairs(bp:GetChildren()) do
                        if not autoDropEnabled then break end
                        if item:IsA("Tool") and not dupeBlacklist[item.Name] then
                            found = true
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:EquipTool(item)
                                local dt = tick()
                                repeat
                                    if dropRemote then
                                        pcall(function() dropRemote:FireServer(item.Name) end)
                                        pcall(function() dropRemote:FireServer(item) end)
                                        pcall(function() dropRemote:FireServer() end)
                                    end
                                    task.wait(0.2)
                                until not item:IsDescendantOf(ch) or not autoDropEnabled or (tick() - dt > 3)
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

--------------------------------------------------------------------
-- EMOTES
--------------------------------------------------------------------
MianiEmotes = {
    ["CSnoop"]=86123328011397, ["Air Cycle"]=94324173536622, ["Assumptions"]=91294374426630,
    ["Basketball Headspin"]=92854797386719, ["Beat Da Koto Nai"]=93497729736287,
    ["Biblically Accurate"]=109873544976020, ["Billy Bounce"]=137501135905857,
    ["Bird"]=85513310484654, ["Caramelldansen"]=88315693621494, ["Chinese Dance"]=131758838511368,
    ["Classic Walk"]=107806791584829, ["Cute Stomach Lay"]=80754582835479,
    ["Da Hood Dance"]=108171959207138, ["Fake Death"]=88130117312312, ["Fight Stance"]=116763940575803,
    ["Float"]=89523370947906, ["Lay Float"]=77840765435893, ["Floppin Fish"]=79075971527754,
    ["Flying"]=138433137191760, ["Flying Legs"]=130932988394284, ["Fropper"]=116039975531632,
    ["Fumo Flush"]=107217181254431, ["Shoulder Taps"]=85422671683973, ["Helicopter"]=95301257497525,
    ["Helicopter 2"]=91257498644328, ["Jackhammer"]=91423662648449, ["Jojo Pose"]=120629563851640,
    ["Laced"]=135611169366768, ["Buddha"]=86872878957632, ["Monstermash"]=137883764619555,
    ["Oh Who Is You"]=81389876138766, ["Parrot"]=101810746304426, ["Push Up"]=115703320436202,
    ["Rizz Backup"]=131205329995035, ["Shot"]=102691551292124, ["Slickback"]=74288964113793,
    ["Soda Pop"]=105459130960429, ["Take The L"]=78653596566468, ["The Worm"]=90333292347820,
    ["Spider Man Hang"]=128616254665784, ["Weird Boy"]=87025086742503, ["Xavier"]=90802740360125,
    ["Dougie"]=126035888065434, ["BACKFLIP"]=15693621070,
}
MianiEmoteNames = {}
for n in pairs(MianiEmotes) do table.insert(MianiEmoteNames, n) end
table.sort(MianiEmoteNames)
MianiSelectedEmoteName = "Take The L"
MianiCurrentEmoteTrack = nil
MianiEmoteAnimCache = {}
MianiEmoteSettings = { Loop = true }

local function MianiGetEmoteAnimator()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local a = hum:FindFirstChildOfClass("Animator")
    if not a then a = Instance.new("Animator"); a.Parent = hum end
    return a
end
local function MianiStopAllTracks()
    local a = MianiGetEmoteAnimator()
    if a then
        for _, t in ipairs(a:GetPlayingAnimationTracks()) do
            pcall(function() t:Stop(0.1) end)
        end
    end
    MianiCurrentEmoteTrack = nil
end
local function MianiPlayEmoteById(id, name)
    id = tonumber(id); if not id then return end
    local animator = MianiGetEmoteAnimator(); if not animator then return end
    MianiStopAllTracks()
    local anim = MianiEmoteAnimCache[id]
    if not anim then
        anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(id)
        MianiEmoteAnimCache[id] = anim
    end
    local ok, track = pcall(function()
        local t = animator:LoadAnimation(anim)
        t.Priority = Enum.AnimationPriority.Action
        t.Looped = MianiEmoteSettings.Loop
        t:Play(0.1)
        return t
    end)
    if ok and track then
        MianiCurrentEmoteTrack = track
        notify("Emotes","Playing: "..tostring(name or id))
    end
end

--------------------------------------------------------------------
-- OUTFITS
--------------------------------------------------------------------
local function applyOutfit(name, instructions)
    pcall(function() ReplicatedStorage.ClothShopRemote:FireServer("Reset Data") end)
    task.wait(0.2)
    for _, inst in ipairs(instructions) do
        pcall(function() ReplicatedStorage.ClothShopRemote:FireServer(inst[1], inst[2], inst[3]) end)
        task.wait(0.1)
    end
    notify("Outfit","Applied " .. name)
end

local function ApplyDripstoreClothing(category, itemName)
    if not category or not itemName then return end
    if not LocalPlayer:FindFirstChild(category) then return end
    pcall(function()
        if not LocalPlayer[category]:FindFirstChild(itemName) then
            ReplicatedStorage.ClothShopRemote:FireServer("Buy", category, itemName)
            task.wait(0.05)
        end
        ReplicatedStorage.ClothShopRemote:FireServer("Wear", category, itemName)
    end)
end

RandomClothes = {
    Shirts = {
        "Black AMiri 22","Blu C Amiri Hoodie","TankTop Wit Blue B","TankTop Wit RedFlag","TankTok Wit Black",
        "Purple B Puffer","Green Varsity","ChromeHeart Blue","PastalBlue Jacket","Grey Hoodie Wit Red",
        "Balmain Hoodie","White Balmain Hoodie","Black PalmAngel Jacket","Blu Moncler","White Polo Vest",
        "White Tatted T shirt","Red B Jacket","Grey Amiri Hoodie","Bzz Blue Hoodie","Xunners Yankee W Tattoo",
        "Amiri Varsity Jacket","Tan Mechanic X","Black Tatted T Shirt","Amiri Star Hoodie","Tatted Tank To[",
        "Amiri Halloween Shirt","Moncler Tatted Open Shirt","Spiderman","Brown Glo hartt Work",
        "Navy Blue & Red Sp5der Beluga Hoodie","Black Sp5der Jeffery Hoodie","Yellow Spider Supreme Zip Up Jacket",
        "Black Amiri Denim Love Jacket","Black Bapestar sweater","Zipped Moncler Black","Black Chrome Heart Zip Up",
        "Polo Black Moncler + Tats","White Tank Top W/ Shirt on shoulder","Red Zipped Jacket",
        "Y2K Brown & Tan STARS Varsity","Yellow & White Striped Lightning Track Suit",
        "Black & Blue LA Designer Hoodie White Shirt","Pink Y2K","Pink Bape","Moose Grey Hoodie",
        "Purple and Yellow GHOP Hoodie","Black & White Designer Baseball Jersey",
        "Blue and White Chicago OBLOCK Shirt W Tatts","Bathing Ape Bape Camo",
        "White and Black Sniper Gang Superstar Shirt","Red and White Designer Graphic Shirt W Tatts",
        "Tan Brown Graphic Y2K Pullover Hoodie","Grey & Red Designer 99 Denim Jean Jacket",
        "black open jacket w/ purple","Opened Black Zipper Jacket W Tats","Amiri Jean Jacket","BlueTech",
        "WhiteTankTop","BluePalm Jacket","Blue ChromeHeart Jersey","Blue Chrome Hearts Hoodiey",
        "Blue Sp5der Hoodie","Green Sp5der Hoodie","Red Sp5der Sweats","Bandi T Cardi","Black Amiri Star","Blue Hellstar",
    },
    Pants = {
        "Black Ripped Jeans","Y2K Khaki pants","Black amiri jeans w jeezy","Hard Jeans LV",
        "Balmain Grey Jeans Wit/ PSD's Jordan 11s","Amiri Jeans w Red Thunder","Y2K Brown & Tan STARS Sweat Joggers",
        "Purple Brand Jeans x Lavins","Black & Tan Y2K Designer Graphic Joggers",
        "Red And Black Checkered CheckMate Joggers","Red Designer Denim Jeans Drip Designer",
        "Grey & Yellow Designer Denim Jeans W Belt","Violet Valk Purple Designer Denim Jeanss",
        "Black and White Designer Denim Jeans","Black PURPLE Brand Jeans w/ Balenciaga Runners",
        "Grey Jeans W/ Red Jz","Ripped Black Jeans w White Thunder 4s","BJeans w White Black Cat 4s",
        "Grey Jean W Dior Runners","ReddyPants","RedTech","BlueTechPants","GreenTechPants1","WhiteTechPants",
        "BluePalmAngels","BluePalm Jacket","Blue Sp5der Sweats","Green Sp5der Sweats","Red Sp5der Sweats",
        "Blue Sp5der Sweats","Sweats Wit Black AF1","Shorts W Dunks","Amiri Jeans x Grey b22","Spiderman",
        "Saint Sinner Jeans","Grey Purple Jeans","Amiri Jean x Retro 13 x LV","Tan Mechanic Pants Black AF1",
        "BabyBlue Nikes","Black PalmAngels","WhiteJeans","White Jeans w AF1","Grey Sweats W Red",
        "Amiri Blue Jeans","Blue Offwhites wit GreyJeams","Black Amiri Jeans B22","Green Ripped Jeans",
        "BlackJeans W Purple LV Flags","Black B Shorts","Red B Shorts","Blu B Shorts","White AF1 BJeans",
        "Amiri Jeans x Grey b22","Pink Bapesta Jeans",
    },
}

getgenv().OutfitSwapDelay = 0.2
getgenv().FlashOutfits = false
local FlashOutfitLoopRunning = false

--------------------------------------------------------------------
-- VISUALS (world + ESP + hitbox)
--------------------------------------------------------------------
VisualColorPresets = {
    ["White"]=Color3.fromRGB(255,255,255), ["Black"]=Color3.fromRGB(0,0,0),
    ["Red"]=Color3.fromRGB(255,0,0), ["Green"]=Color3.fromRGB(0,255,0),
    ["Blue"]=Color3.fromRGB(0,120,255), ["Purple"]=Color3.fromRGB(143,0,255),
    ["Pink"]=Color3.fromRGB(255,80,180), ["Cyan"]=Color3.fromRGB(0,255,255),
    ["Yellow"]=Color3.fromRGB(255,255,0), ["Orange"]=Color3.fromRGB(255,140,0),
    ["Lime"]=Color3.fromRGB(130,255,0), ["Gray"]=Color3.fromRGB(120,120,120),
}
VisualColorNames = {}
for n in pairs(VisualColorPresets) do table.insert(VisualColorNames, n) end
table.sort(VisualColorNames)

WorldVisuals = {
    SaturationEnabled=false, SaturationValue=1,
    StretchEnabled=false, StretchValue=0.7,
    FogColorEnabled=false, FogColor=Color3.fromRGB(255,255,255),
    AmbientEnabled=false, AmbientColor=Color3.fromRGB(255,255,255),
    FieldOfViewEnabled=false, FieldOfViewValue=70,
    Fullbright=false,
}

ESPFlags = {
    Enabled=false, RenderDistance=1400, TeamColor=true,
    Boxes=true, BoxType="Corner", BoxColor=Color3.fromRGB(255,140,0),
    BoxFill=false, BoxFillColor=Color3.fromRGB(255,255,255),
    Healthbar=true, HealthbarNumber=false, HealthbarThickness=3,
    Name=true, Distance=true, Weapon=false,
    FriendMarker=true, FriendColor=Color3.fromRGB(0,255,0),
    TextSize=14, TextColor=Color3.fromRGB(245,245,245),
    Snaplines=false, SnaplineColor=Color3.fromRGB(255,140,0),
    Chams=false, ChamsColor=Color3.fromRGB(255,140,0),
    Skeleton=false, SkeletonColor=Color3.fromRGB(255,255,255),
    LookTracers=false, LookTracerColor=Color3.fromRGB(0,255,255),
}

local ESPObjects = {}
local HighlightObjects = {}
local ESPFriendCache = {}

local function createDrawing(className, props)
    if not Drawing or type(Drawing.new) ~= "function" then
        return {Visible=false, Remove=function() end}
    end
    local ok, obj = pcall(Drawing.new, className)
    if not ok or not obj then return {Visible=false, Remove=function() end} end
    for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    return obj
end

local function isESPUserFriend(target)
    if not target or target == LocalPlayer then return false end
    if ESPFriendCache[target] == nil then
        local ok, isFriend = pcall(function() return LocalPlayer:IsFriendsWith(target.UserId) end)
        ESPFriendCache[target] = ok and isFriend == true or false
    end
    return ESPFriendCache[target]
end

local SkeletonPairs = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

local function createESPObject(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local box = {}
    for _, n in ipairs({"Top","Bottom","Left","Right","TopLeft","TopRight","BottomLeft","BottomRight"}) do
        box[n] = createDrawing("Line", {Visible=false, Thickness=1.6, Color=ESPFlags.BoxColor})
    end
    local skeleton = {}
    for i = 1, #SkeletonPairs do
        skeleton[i] = createDrawing("Line", {Visible=false, Thickness=1, Color=ESPFlags.SkeletonColor})
    end
    ESPObjects[player] = {
        Box = box,
        Fill = createDrawing("Square", {Visible=false, Filled=true, Transparency=0.85, Color=ESPFlags.BoxFillColor}),
        HealthOutline = createDrawing("Square", {Visible=false, Filled=false, Color=Color3.fromRGB(0,0,0), Thickness=1}),
        HealthFill = createDrawing("Square", {Visible=false, Filled=true, Color=Color3.fromRGB(0,255,0)}),
        HealthText = createDrawing("Text", {Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=Color3.fromRGB(255,255,255)}),
        Name = createDrawing("Text", {Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.TextColor}),
        FriendTag = createDrawing("Text", {Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.FriendColor, Text="(F)"}),
        Distance = createDrawing("Text", {Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.TextColor}),
        Weapon = createDrawing("Text", {Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.TextColor}),
        Snapline = createDrawing("Line", {Visible=false, Thickness=1.2, Color=ESPFlags.SnaplineColor}),
        LookTracer = createDrawing("Line", {Visible=false, Thickness=1, Color=ESPFlags.LookTracerColor}),
        Skeleton = skeleton,
    }
end

local function hideESPObject(obj)
    if not obj then return end
    if obj.Box then for _, l in pairs(obj.Box) do l.Visible=false end end
    if obj.Skeleton then for _, l in ipairs(obj.Skeleton) do l.Visible=false end end
    for _, k in ipairs({"Fill","HealthOutline","HealthFill","HealthText","Name","FriendTag","Distance","Weapon","Snapline","LookTracer"}) do
        if obj[k] then obj[k].Visible=false end
    end
end

local function removeESPObject(player)
    local obj = ESPObjects[player]
    if obj then
        if obj.Box then for _, l in pairs(obj.Box) do pcall(function() l:Remove() end) end end
        if obj.Skeleton then for _, l in ipairs(obj.Skeleton) do pcall(function() l:Remove() end) end end
        for _, k in ipairs({"Fill","HealthOutline","HealthFill","HealthText","Name","FriendTag","Distance","Weapon","Snapline","LookTracer"}) do
            if obj[k] then pcall(function() obj[k]:Remove() end) end
        end
        ESPObjects[player] = nil
    end
    if HighlightObjects[player] then
        pcall(function() HighlightObjects[player]:Destroy() end)
        HighlightObjects[player] = nil
    end
    ESPFriendCache[player] = nil
end

local function getESPColor(player, def)
    if ESPFlags.TeamColor and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return Color3.fromRGB(0,120,255)
    end
    return def
end

local function updateLine(line, from, to, color)
    if not line then return end
    line.From=from; line.To=to; line.Color=color; line.Visible=true
end

for _, p in ipairs(Players:GetPlayers()) do createESPObject(p) end
Players.PlayerAdded:Connect(createESPObject)
Players.PlayerRemoving:Connect(removeESPObject)

local _espHiddenOnce = false
local function hideESPForPlayer(player)
    hideESPObject(ESPObjects[player])
    if HighlightObjects[player] then HighlightObjects[player].Enabled = false end
end

local function updateESPForPlayer(player, cam)
    if player == LocalPlayer then hideESPForPlayer(player); return end
    createESPObject(player)
    local obj = ESPObjects[player]
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (obj and char and hum and root and hum.Health > 0) then hideESPForPlayer(player); return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local distance = localRoot and (root.Position - localRoot.Position).Magnitude
        or (root.Position - cam.CFrame.Position).Magnitude
    if distance > ESPFlags.RenderDistance then hideESPForPlayer(player); return end
    local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
    if not onScreen or rootPos.Z <= 0 then hideESPForPlayer(player); return end
    local size = char:GetExtentsSize()
    local top = cam:WorldToViewportPoint((root.CFrame * CFrame.new(0, size.Y/2, 0)).Position)
    local bottom = cam:WorldToViewportPoint((root.CFrame * CFrame.new(0, -size.Y/2, 0)).Position)
    if top.Z <= 0 or bottom.Z <= 0 then hideESPForPlayer(player); return end
    local height = math.max(math.abs(bottom.Y - top.Y), 2)
    local width = math.max(height * 0.58, 2)
    local x, y = top.X - width/2, top.Y
    local boxColor = getESPColor(player, ESPFlags.BoxColor)
    local textColor = ESPFlags.TextColor

    if ESPFlags.BoxFill then
        obj.Fill.Position = Vector2.new(x, y)
        obj.Fill.Size = Vector2.new(width, height)
        obj.Fill.Color = ESPFlags.BoxFillColor
        obj.Fill.Transparency = 0.85
        obj.Fill.Visible = true
    else obj.Fill.Visible = false end

    if ESPFlags.Boxes then
        local tl, tr = Vector2.new(x, y), Vector2.new(x + width, y)
        local bl, br = Vector2.new(x, y + height), Vector2.new(x + width, y + height)
        local corner = math.min(width, height) * 0.28
        if ESPFlags.BoxType == "Full" then
            updateLine(obj.Box.Top, tl, tr, boxColor)
            updateLine(obj.Box.Bottom, bl, br, boxColor)
            updateLine(obj.Box.Left, tl, bl, boxColor)
            updateLine(obj.Box.Right, tr, br, boxColor)
            obj.Box.TopLeft.Visible=false; obj.Box.TopRight.Visible=false
            obj.Box.BottomLeft.Visible=false; obj.Box.BottomRight.Visible=false
        else
            obj.Box.Top.Visible=false; obj.Box.Bottom.Visible=false
            obj.Box.Left.Visible=false; obj.Box.Right.Visible=false
            updateLine(obj.Box.TopLeft, tl, tl + Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Left, tl, tl + Vector2.new(0, corner), boxColor)
            updateLine(obj.Box.TopRight, tr, tr - Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Right, tr, tr + Vector2.new(0, corner), boxColor)
            updateLine(obj.Box.BottomLeft, bl, bl + Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Bottom, bl, bl - Vector2.new(0, corner), boxColor)
            updateLine(obj.Box.BottomRight, br, br - Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Top, br, br - Vector2.new(0, corner), boxColor)
        end
    else
        for _, l in pairs(obj.Box) do l.Visible = false end
    end

    if ESPFlags.Healthbar then
        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bh = height * pct
        obj.HealthOutline.Position = Vector2.new(x - 7, y)
        obj.HealthOutline.Size = Vector2.new(ESPFlags.HealthbarThickness + 2, height)
        obj.HealthOutline.Visible = true
        obj.HealthFill.Position = Vector2.new(x - 6, y + height - bh)
        obj.HealthFill.Size = Vector2.new(ESPFlags.HealthbarThickness, bh)
        obj.HealthFill.Color = Color3.fromRGB(255 - (255 * pct), 255 * pct, 0)
        obj.HealthFill.Visible = true
        if ESPFlags.HealthbarNumber then
            obj.HealthText.Text = tostring(math.floor(hum.Health))
            obj.HealthText.Position = Vector2.new(x - 12, y + height - bh)
            obj.HealthText.Size = ESPFlags.TextSize
            obj.HealthText.Visible = true
        else obj.HealthText.Visible = false end
    else
        obj.HealthOutline.Visible=false; obj.HealthFill.Visible=false; obj.HealthText.Visible=false
    end

    local bottomOffset = 2
    if ESPFlags.Name then
        obj.Name.Text = player.DisplayName ~= player.Name and (player.DisplayName .. " (@" .. player.Name .. ")") or player.Name
        obj.Name.Position = Vector2.new(x + width/2, y - ESPFlags.TextSize - 2)
        obj.Name.Size = ESPFlags.TextSize
        obj.Name.Color = textColor
        obj.Name.Visible = true
        if ESPFlags.FriendMarker and isESPUserFriend(player) then
            local nameWidth = (#tostring(obj.Name.Text) * ESPFlags.TextSize * 0.28)
            pcall(function() if obj.Name.TextBounds then nameWidth = obj.Name.TextBounds.X / 2 end end)
            obj.FriendTag.Text = "(F)"
            obj.FriendTag.Position = Vector2.new((x + width/2) - nameWidth - 10, y - ESPFlags.TextSize - 2)
            obj.FriendTag.Size = ESPFlags.TextSize
            obj.FriendTag.Color = ESPFlags.FriendColor
            obj.FriendTag.Visible = true
        else obj.FriendTag.Visible = false end
    else obj.Name.Visible=false; obj.FriendTag.Visible=false end

    if ESPFlags.Distance then
        obj.Distance.Text = tostring(math.floor(distance)) .. "m"
        obj.Distance.Position = Vector2.new(x + width/2, y + height + bottomOffset)
        obj.Distance.Size = ESPFlags.TextSize
        obj.Distance.Color = textColor
        obj.Distance.Visible = true
        bottomOffset = bottomOffset + ESPFlags.TextSize + 1
    else obj.Distance.Visible = false end

    if ESPFlags.Weapon then
        local tool = char:FindFirstChildOfClass("Tool")
        obj.Weapon.Text = tool and ("[" .. tool.Name .. "]") or "[None]"
        obj.Weapon.Position = Vector2.new(x + width/2, y + height + bottomOffset)
        obj.Weapon.Size = ESPFlags.TextSize
        obj.Weapon.Color = textColor
        obj.Weapon.Visible = true
    else obj.Weapon.Visible = false end

    if ESPFlags.Snaplines then
        obj.Snapline.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
        obj.Snapline.To = Vector2.new(rootPos.X, rootPos.Y)
        obj.Snapline.Color = getESPColor(player, ESPFlags.SnaplineColor)
        obj.Snapline.Visible = true
    else obj.Snapline.Visible = false end

    if ESPFlags.LookTracers and char:FindFirstChild("Head") then
        local head = char.Head
        local p1, o1 = cam:WorldToViewportPoint(head.Position)
        local p2, o2 = cam:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 10)
        if o1 and o2 and p1.Z > 0 and p2.Z > 0 then
            obj.LookTracer.From = Vector2.new(p1.X, p1.Y)
            obj.LookTracer.To = Vector2.new(p2.X, p2.Y)
            obj.LookTracer.Color = ESPFlags.LookTracerColor
            obj.LookTracer.Visible = true
        else obj.LookTracer.Visible = false end
    else obj.LookTracer.Visible = false end

    if ESPFlags.Skeleton then
        for i, pair in ipairs(SkeletonPairs) do
            local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
            if a and b and obj.Skeleton[i] then
                local pa, oa = cam:WorldToViewportPoint(a.Position)
                local pb, ob = cam:WorldToViewportPoint(b.Position)
                if oa and ob and pa.Z > 0 and pb.Z > 0 then
                    obj.Skeleton[i].From = Vector2.new(pa.X, pa.Y)
                    obj.Skeleton[i].To = Vector2.new(pb.X, pb.Y)
                    obj.Skeleton[i].Color = ESPFlags.SkeletonColor
                    obj.Skeleton[i].Visible = true
                else obj.Skeleton[i].Visible = false end
            elseif obj.Skeleton[i] then obj.Skeleton[i].Visible = false end
        end
    else
        for _, l in ipairs(obj.Skeleton) do l.Visible = false end
    end

    if ESPFlags.Chams then
        local h = HighlightObjects[player]
        if not h or not h.Parent then
            h = Instance.new("Highlight")
            h.Name = "aqxESPHighlight"
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = CoreGui
            HighlightObjects[player] = h
        end
        h.Adornee = char
        h.FillColor = getESPColor(player, ESPFlags.ChamsColor)
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.FillTransparency = 0.55
        h.OutlineTransparency = 0.1
        h.Enabled = true
    elseif HighlightObjects[player] then
        HighlightObjects[player].Enabled = false
    end
end

RunService.RenderStepped:Connect(function()
    if not ESPFlags.Enabled then
        if not _espHiddenOnce then
            _espHiddenOnce = true
            for _, p in ipairs(Players:GetPlayers()) do hideESPForPlayer(p) end
        end
        return
    end
    _espHiddenOnce = false
    local cam = workspace.CurrentCamera
    if not cam then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local ok = pcall(updateESPForPlayer, p, cam)
        if not ok then hideESPForPlayer(p) end
    end
end)

-- hitbox expander
HitboxVisuals = {
    Enabled = false, Part = "Head", Multiplier = 5, Transparency = 0.45,
    Material = "ForceField", Type = "Ball", CanCollide = false,
    Massless = true, TeamCheck = false, Color = Color3.fromRGB(55, 235, 120),
}

do
    local CandidateParts = {
        "Head","HumanoidRootPart","UpperTorso","LowerTorso",
        "LeftUpperArm","LeftLowerArm","RightUpperArm","RightLowerArm",
        "LeftUpperLeg","LeftLowerLeg","RightUpperLeg","RightLowerLeg",
        "LeftHand","RightHand","LeftFoot","RightFoot",
    }
    local DefaultPlayerSettings = {}
    local HitboxWorkerBound = {}

    local function capturePartSettings(part)
        if not part or not part:IsA("BasePart") then return nil end
        local s = {
            Size=part.Size, Transparency=part.Transparency, CanCollide=part.CanCollide,
            CanQuery=part.CanQuery, CanTouch=part.CanTouch, Massless=part.Massless,
            Material=part.Material, Color=part.Color,
        }
        pcall(function() s.Shape = part.Shape end)
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then s.MeshId=mesh.MeshId; s.MeshScale=mesh.Scale end
        return s
    end

    local function saveDefaultPlayerSettings(player)
        if not player or player == LocalPlayer or not player.Character then return end
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local current = DefaultPlayerSettings[player]
        if current and current.Character == character then return end
        local saved = {Character=character, Parts={}}
        for _, partName in ipairs(CandidateParts) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then saved.Parts[partName] = capturePartSettings(part) end
        end
        DefaultPlayerSettings[player] = saved
    end

    local function restorePartSettings(part, settings)
        if not part or not settings then return end
        for index, value in pairs(settings) do
            if index ~= "MeshId" and index ~= "MeshScale" then
                pcall(function() part[index] = value end)
            end
        end
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            if settings.MeshId ~= nil then pcall(function() mesh.MeshId = settings.MeshId end) end
            if settings.MeshScale ~= nil then pcall(function() mesh.Scale = settings.MeshScale end) end
        end
    end

    local function restorePlayerSettings(player)
        local saved = DefaultPlayerSettings[player]
        local character = player and player.Character
        if not saved or not character or saved.Character ~= character then return end
        for partName, settings in pairs(saved.Parts) do
            local part = character:FindFirstChild(partName)
            if part then restorePartSettings(part, settings) end
        end
    end

    local function applyHitboxToPart(part)
        if not part or not part:IsA("BasePart") then return end
        part.Size = Vector3.new(HitboxVisuals.Multiplier, HitboxVisuals.Multiplier, HitboxVisuals.Multiplier)
        part.Transparency = HitboxVisuals.Transparency
        part.Material = Enum.Material[HitboxVisuals.Material] or Enum.Material.ForceField
        part.Color = HitboxVisuals.Color
        part.CanCollide = HitboxVisuals.CanCollide
        part.CanQuery = true; part.CanTouch = false; part.Massless = HitboxVisuals.Massless
        pcall(function()
            if part:IsA("Part") and Enum.PartType[HitboxVisuals.Type] then
                part.Shape = Enum.PartType[HitboxVisuals.Type]
            end
        end)
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            pcall(function() mesh.Scale = Vector3.new(HitboxVisuals.Multiplier, HitboxVisuals.Multiplier, HitboxVisuals.Multiplier) end)
        end
    end

    local function connectHitboxToPlayer(player)
        if not player or player == LocalPlayer or HitboxWorkerBound[player] then return end
        HitboxWorkerBound[player] = true
        task.spawn(function()
            while player and player.Parent do
                task.wait(0.25)
                local character = player.Character; if not character then continue end
                local humanoid = character:FindFirstChildOfClass("Humanoid"); if not humanoid then continue end
                saveDefaultPlayerSettings(player)
                local saved = DefaultPlayerSettings[player]
                local sameTeam = HitboxVisuals.TeamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
                if not HitboxVisuals.Enabled or humanoid.Health <= 0 or humanoid.Sit
                or sameTeam or not saved or saved.Character ~= character then
                    restorePlayerSettings(player); continue
                end
                restorePlayerSettings(player)
                local selectedPart = character:FindFirstChild(HitboxVisuals.Part)
                    or character:FindFirstChild("Head")
                    or character:FindFirstChild("HumanoidRootPart")
                if selectedPart and selectedPart:IsA("BasePart") then applyHitboxToPart(selectedPart) end
            end
            HitboxWorkerBound[player] = nil
            DefaultPlayerSettings[player] = nil
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do connectHitboxToPlayer(player) end
    Players.PlayerAdded:Connect(connectHitboxToPlayer)
    Players.PlayerRemoving:Connect(function(player)
        HitboxWorkerBound[player] = nil
        DefaultPlayerSettings[player] = nil
    end)
end

-- world visuals
local VisualColorCorrection = Lighting:FindFirstChild("aqxColorCorrection")
if not VisualColorCorrection then
    VisualColorCorrection = Instance.new("ColorCorrectionEffect")
    VisualColorCorrection.Name = "aqxColorCorrection"
    VisualColorCorrection.Parent = Lighting
end
local OriginalWorld = {
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd,
    FogColor=Lighting.FogColor, GlobalShadows=Lighting.GlobalShadows,
    OutdoorAmbient=Lighting.OutdoorAmbient, Ambient=Lighting.Ambient,
    FieldOfView=workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    Saturation=VisualColorCorrection.Saturation, TintColor=VisualColorCorrection.TintColor,
}
local WorldReset = {Fog=false, Fov=false, Fullbright=false, Ambient=false, Saturation=false}

RunService:BindToRenderStep("aqxWorldVisuals", Enum.RenderPriority.Camera.Value, function()
    if not (WorldVisuals.StretchEnabled or WorldVisuals.FieldOfViewEnabled
        or WorldVisuals.SaturationEnabled or WorldVisuals.AmbientEnabled
        or WorldVisuals.FogColorEnabled or WorldVisuals.Fullbright)
    and WorldReset.Fov and WorldReset.Saturation and WorldReset.Ambient
    and WorldReset.Fog and WorldReset.Fullbright then return end
    local cam = workspace.CurrentCamera; if not cam then return end
    if WorldVisuals.StretchEnabled then
        cam.CFrame = cam.CFrame * CFrame.new(0,0,0,1,0,0,0,WorldVisuals.StretchValue,0,0,0,1)
    end
    if WorldVisuals.FieldOfViewEnabled then WorldReset.Fov=false; cam.FieldOfView = WorldVisuals.FieldOfViewValue
    elseif not WorldReset.Fov then WorldReset.Fov=true; cam.FieldOfView = OriginalWorld.FieldOfView or 70 end
    if WorldVisuals.SaturationEnabled then WorldReset.Saturation=false; VisualColorCorrection.Saturation = WorldVisuals.SaturationValue
    elseif not WorldReset.Saturation then WorldReset.Saturation=true; VisualColorCorrection.Saturation = OriginalWorld.Saturation or 0 end
    if WorldVisuals.AmbientEnabled then
        WorldReset.Ambient=false        VisualColorCorrection.TintColor = WorldVisuals.AmbientColor
        Lighting.Ambient = WorldVisuals.AmbientColor
        Lighting.OutdoorAmbient = WorldVisuals.AmbientColor
    elseif not WorldReset.Ambient then
        WorldReset.Ambient=true
        VisualColorCorrection.TintColor = OriginalWorld.TintColor or Color3.new(1,1,1)
        Lighting.Ambient = OriginalWorld.Ambient
        Lighting.OutdoorAmbient = OriginalWorld.OutdoorAmbient
    end
    if WorldVisuals.FogColorEnabled then WorldReset.Fog=false; Lighting.FogColor = WorldVisuals.FogColor
    elseif not WorldReset.Fog then WorldReset.Fog=true; Lighting.FogColor = OriginalWorld.FogColor end
    if WorldVisuals.Fullbright then
        WorldReset.Fullbright=false
        Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000
        Lighting.GlobalShadows=false; Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
    elseif not WorldReset.Fullbright then
        WorldReset.Fullbright=true
        Lighting.Brightness=OriginalWorld.Brightness; Lighting.ClockTime=OriginalWorld.ClockTime
        Lighting.FogEnd=OriginalWorld.FogEnd; Lighting.GlobalShadows=OriginalWorld.GlobalShadows
        Lighting.OutdoorAmbient=OriginalWorld.OutdoorAmbient
    end
end)

-- sky
local TACO_SKY_ASSET = "rbxassetid://93586114576894"
SkyBackgroundPresets = { ["Taco Scripts"] = TACO_SKY_ASSET }
SkyBackgroundNames = {"Taco Scripts"}
local function clearAllSkies()
    pcall(function()
        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then sky:Destroy() end
        end
    end)
end
local function applyTacoSky(asset, displayName)
    asset = tostring(asset or TACO_SKY_ASSET)
    clearAllSkies()
    local sky = Instance.new("Sky")
    sky.Name = tostring(displayName or "aqx") .. " Sky"
    sky.SkyboxBk=asset; sky.SkyboxDn=asset; sky.SkyboxFt=asset
    sky.SkyboxLf=asset; sky.SkyboxRt=asset; sky.SkyboxUp=asset
    sky.CelestialBodiesShown = false
    sky.Parent = Lighting
    return sky
end
applyTacoSky(TACO_SKY_ASSET, "aqx")

--------------------------------------------------------------------
-- QUICK BUY / TELEPORTS
--------------------------------------------------------------------
teleportLocations = {
    ["🌮 Car Dealer"]    = CFrame.new(-409.63, 253.41, -1230.14),
    ["🌮 New Laundry"]   = CFrame.new(-1216.24, 253.88, -3969.89),
    ["🌮 New Deli"]      = CFrame.new(-1388.31, 268.14, -3897.86),
    ["🌮 New Seller"]    = CFrame.new(-965.27, 260.19, -4244.83),
    ["🌮 New Bank"]      = CFrame.new(-1217.30, 253.88, -3635.04),
    ["🌮 Market"]        = CFrame.new(-405.17, 334.31, -562.63),
    ["🌮 New Penthouse"] = CFrame.new(-1488.06, 476.30, -3747.01),
    ["🌮 Backpack"]      = CFrame.new(-725.64, 253.92, -684.30),
    ["🌮 Studio"]        = CFrame.new(93408.45, 14484.90, 570.14),
    ["🌮 Dripstore"]     = CFrame.new(67462.32, 10489.21, 549.60),
    ["🌮 Exotic"]        = CFrame.new(-1519.52, 272.15, -983.73),
    ["🌮 RPT"]           = CFrame.new(-1744.10, 236.95, -596.03),
    ["🌮 Random House"]  = CFrame.new(-1228.93, 261.04, -3758.50),
    ["🌮 Gunshop"]       = CFrame.new(92960.12, 122098.50, 17253.95),
    ["🌮 Dollar General"]= CFrame.new(-413.66, 253.82, -1055.57),
    ["🌮 Hospital"]      = CFrame.new(-1587.46, 254.27, 18.42),
    ["🌮 Mansion"]       = CFrame.new(-789.10, 253.57, 1380.76),
    ["🌮 Bank"] = CFrame.new(-226.225845, 283.809570, -1217.750977),
    ["🌮 Money Wash"] = CFrame.new(-1006.000000, 254.000000, -701.000000),
    ["🌮 Safe Items"] = CFrame.new(-939.000000, 254.000000, -556.000000),
    ["🌮 Pawn Shop"] = CFrame.new(-1049.643100, 253.536700, -814.269700),
    ["🌮 Bank Vault"] = CFrame.new(-217.568359, 373.798492, -1216.209473),
    ["🌮 Mr Money Man"] = CFrame.new(-1008.066200, 262.114100, 55.133600),
    ["🌮GunShop 1"] = CFrame.new(92959.867188, 122098.500000, 17244.462891),
    ["🌮GunShop 1 Lobby"] = CFrame.new(-1002.422400, 253.638200, -803.912500),
    ["🌮GunShop 2"] = CFrame.new(66195.445312, 123615.710938, 5750.282715),
    ["🌮GunShop 2 Lobby"] = CFrame.new(-224.381836, 283.803436, -794.717407),
    ["🌮GunShop 3"] = CFrame.new(60820.308600, 87609.148400, -351.474600),
    ["🌮GunShop 4"] = CFrame.new(72421.914062, 128855.820312, -1080.611084),
    ["🌮 Pent House"] = CFrame.new(-178.274719, 397.138306, -573.032227),
    ["🌮 Mini Mansion"] = CFrame.new(-791.518005, 256.794464, 1414.424805),
    ["🌮🌮 NYPDWarehouse"] = CFrame.new(-1585.000000, 268.000000, -3264.000000),
    ["🌮 Roof 3"] = CFrame.new(-1608.014404, 480.644623, -501.504547),
    ["🌮 Roof 4"] = CFrame.new(-209.993134, 433.217346, -1151.946045),
    ["🌮 Backpack Shop"] = CFrame.new(-703.000000, 254.000000, -720.000000),
    ["🌮⌚ Frozen Shop"] = CFrame.new(-216.314362, 284.031494, -1169.032471),
    ["🌮 Drip Shop"] = CFrame.new(67462.695300, 10489.035200, 549.589500),
    ["🌮 Chicken Wings"] = CFrame.new(-957.914200, 253.536700, -815.944200),
    ["🌮🌮🌮 Deli"] = CFrame.new(-755.811401, 254.692749, -687.118164),
    ["🌮 Dealership"] = CFrame.new(-401.993713, 253.414108, -1248.838013),
    ["🌮 Drip Store"] = CFrame.new(67462.000000, 10489.214844, 546.194153),
    ["🌮 Soda Warehouse"] = CFrame.new(-187.855042, 284.625214, -291.341919),
    ["🌮 Soda Supplies"] = CFrame.new(-403.099060, 254.203430, -580.043762),
    ["🌮 Soda Seller"] = CFrame.new(-1292.220093, 253.300446, -3003.048340),
    ["🌮 Exotic Dealer"] = CFrame.new(-1523.565430, 273.972992, -990.657532),
    ["🌮 Switch Seller"] = CFrame.new(-1446.216675, 256.059814, 2189.876221),
    ["🌮 Bank Tools"] = CFrame.new(-374.000000, 334.000000, -554.000000),
    ["🌮 Construction Site"] = CFrame.new(-1731.830700, 370.812300, -1176.838700),
    ["🌮 Prison"] = CFrame.new(-1135.046400, 254.716000, -3330.995400),
    ["🌮 McDonalds"] = CFrame.new(-423.000000, 254.000000, -953.000000),
    ["🌮 Ice Box"] = CFrame.new(-215.140700, 283.515400, -1258.691000),
    ["🌮 Hospital"] = CFrame.new(-1589.504150, 254.272232, 17.655523),
    ["🌮 MarGreens"] = CFrame.new(-381.207520, 254.453827, -385.665466),
    ["🌮 Feds Room"] = CFrame.new(-1441.790405, 255.036514, -3132.597412),
    ["🌮 ATM 1"] = CFrame.new(-1011.906616, 253.750900, -1153.734009),
    ["🌮 ATM 3"] = CFrame.new(-96.723564, 283.632935, -766.330933),
    ["🌮 House Rob Door 1"] = CFrame.new(-714.244019, 287.121429, -779.232971),
    ["🌮 House Rob Door 2"] = CFrame.new(-606.266907, 253.886765, -679.884460),
    ["🌮🌮 Studio Robbery"] = CFrame.new(93427.515625, 14484.905273, 566.670105),
    ["🌮 TrailerPark"] = CFrame.new(-1522.769043, 253.160950, 2344.959473),
    ["🌮 Woody's Hotel"] = CFrame.new(-1022.619629, 325.840057, -908.915710),
    ["6⃣0⃣0⃣ Block"] = CFrame.new(-990.680664, 253.707275, -281.321564),
    ["🌮 Off Map"] = CFrame.new(-1295.469360, 253.546860, -4077.484619),
}
teleportNames = {}
for n in pairs(teleportLocations) do table.insert(teleportNames, n) end
table.sort(teleportNames)

local function TeleportToCookPot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local pos = hrp and hrp.Position or Vector3.zero
    local pot, best = nil, math.huge
    local function check(p)
        if p and p:IsA("BasePart") then
            local d = (p.Position - pos).Magnitude
            if d < best then best, pot = d, p end
        end
    end
    if workspace:FindFirstChild("CookingPots") then
        for _, v in pairs(workspace.CookingPots:GetChildren()) do
            if v:IsA("Model") then
                check(v:FindFirstChild("CookPart") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart"))
            end
        end
    end
    if pot then
        Config:Teleport(pot.CFrame + Vector3.new(0,1.5,0))
        notify("Teleport","Teleported to nearest Cook Pot!")
    else
        Config:Teleport(CFrame.new(-198.89, 283.85, -1170.45))
        notify("Teleport","Fallback CookPot location.")
    end
end

local function qbFindPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") then return obj end
    for _, child in ipairs(obj:GetChildren()) do
        local found = qbFindPrompt(child)
        if found then return found end
    end
end

local function getObjectCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.CFrame end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.CFrame end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok then return pivot end
    end
    local parent = obj.Parent
    if parent and parent:IsA("BasePart") then return parent.CFrame end
    if parent and parent:IsA("Model") then
        if parent.PrimaryPart then return parent.PrimaryPart.CFrame end
        local part = parent:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
    end
end

local function qbDoBuy(itemName, category)
    if not itemName or itemName == "(no matches)" then return false, "No item selected" end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return false, "No HumanoidRootPart" end
    if category == "OTHER" or category == "BAGS" then
        local itemObject = workspace:FindFirstChild("GUNS") and workspace.GUNS:FindFirstChild(itemName) or nil
        if not itemObject and category == "BAGS" then itemObject = workspace:FindFirstChild(itemName, true) end
        if not itemObject then return false, "World item not found: " .. tostring(itemName) end
        local prompt = qbFindPrompt(itemObject)
        local targetCF = getObjectCFrame(prompt and prompt.Parent or itemObject)
        if not prompt or not targetCF then return false, "Prompt not found" end
        local originalCF = hrp.CFrame
        local holdDuration = prompt.HoldDuration
        pcall(function()
            Config:Teleport(targetCF); task.wait(0.35)
            prompt.HoldDuration = 0
            fireproximityprompt(prompt); task.wait(0.2)
            prompt.HoldDuration = holdDuration
            Config:Teleport(originalCF)
        end)
        return true
    elseif category == "EXOTIC" then
        ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(itemName)
        return true
    elseif category == "MAIN SHOP" then
        ReplicatedStorage:WaitForChild("ShopRemote"):InvokeServer(itemName)
        return true
    end
    return false, "Unknown category"
end

--------------------------------------------------------------------
-- ================================================================
-- TAB ASSEMBLY
-- ================================================================
--------------------------------------------------------------------

-- PLAYER ---------------------------------------------------------
local tabPlayer = makeTab("Player")

local g = tabPlayer:AddGroup("Local Player")
g:AddToggle("aqxFPSBoost", { Text = "FPS Boost (Low Graphics)", Default = false, Callback = function(state)
    if state then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                pcall(function() o.Material = Enum.Material.Plastic; o.Reflectance = 0; o.CastShadow = false end)
            elseif o:IsA("Decal") or o:IsA("Texture") then
                pcall(function() o.Transparency = 1 end)
            elseif o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam")
                or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("PostEffect") then
                pcall(function() o.Enabled = false end)
            end
        end
    else
        notify("FPS Boost", "Reload the game to fully restore visuals.")
    end
end })
g:AddToggle("aqxAntiFall", { Text = "Anti Fall Damage", Default = false, Callback = function(s)
    if s and LocalPlayer.Character then
        local f = LocalPlayer.Character:FindFirstChild("FallDamageRagdoll")
        if f then f:Destroy() end
    end
end })
g:AddToggle("aqxAntiJumpCD", { Text = "Anti Jump Cooldown", Default = false, Callback = function(s)
    SetAntiJumpCooldownEnabled(s)
end })
g:AddToggle("aqxInfSleep", { Text = "Infinite Sleep", Default = false, Callback = function(s)
    local sg = PlayerGui:FindFirstChild("SleepGui")
    local ss = sg and sg:FindFirstChild("Frame") and sg.Frame:FindFirstChild("sleep")
        and sg.Frame.sleep:FindFirstChild("SleepBar") and sg.Frame.sleep.SleepBar:FindFirstChild("sleepScript")
    if ss then ss.Enabled = not s end
end })
g:AddToggle("aqxInfHunger", { Text = "Infinite Hunger", Default = false, Callback = function(s)
    local hg = PlayerGui:FindFirstChild("Hunger")
    local hs = hg and hg:FindFirstChild("Frame") and hg.Frame:FindFirstChild("Frame")
        and hg.Frame.Frame:FindFirstChild("Frame") and hg.Frame.Frame.Frame:FindFirstChild("HungerBarScript")
    if hs then hs.Enabled = not s end
end })
g:AddToggle("aqxInfStamina", { Text = "Infinite Stamina", Default = false, Callback = function(s)
    local rg = PlayerGui:FindFirstChild("Run")
    local ss = rg and rg:FindFirstChild("Frame") and rg.Frame:FindFirstChild("Frame")
        and rg.Frame.Frame:FindFirstChild("Frame") and rg.Frame.Frame.Frame:FindFirstChild("StaminaBarScript")
    if ss then ss.Enabled = not s end
end })
g:AddToggle("aqxNoRent", { Text = "No Rent Pay", Default = false, Callback = function(s)
    notify("Rent", s and "Enabled" or "Disabled")
end })
g:AddToggle("aqxInstantInt", { Text = "Instant Interaction", Default = false, Callback = function(s) refreshPrompts(s) end })
g:AddToggle("aqxStudioNotify", { Text = "Studio Money Notify", Default = false, Callback = function(s)
    StudioMoneyNotifyEnabled = s; cleanupStudioMoneyNotify()
    if s then
        for _, n in ipairs({"StudioPay1","StudioPay2","StudioPay3"}) do watchStudioPayPrompt(n) end
    end
end })
g:AddToggle("aqxStealLoot", { Text = "Auto Steal Lootbags", Default = false, Callback = function(s) AutoStealLootbags = s end })
g:AddToggle("aqxPickupBags", { Text = "Auto Pickup Bags", Default = false, Callback = function(s) AutoPickupBags = s end })
g:AddToggle("aqxNoBlood", { Text = "Disable Blood Effects", Default = false, Callback = function(s) DisableBloodEffects = s end })
g:AddToggle("aqxBypassCars", { Text = "Bypass Locked Cars", Default = false, Callback = function(s) BypassLockedCars = s end })
g:AddToggle("aqxNoKnock", { Text = "No Knockback", Default = false, Callback = function(s) NoKnockback = s end })
g:AddToggle("aqxAntiFling", { Text = "Anti Car Fling", Default = false, Callback = function(s)
    if s then StartAntiCarFling() else StopAntiCarFling() end
end })
g:AddToggle("aqxAutoClean", { Text = "Auto Deposit Picked Cash", Default = false, Callback = function(s) AutoCleanMoney = s end })
g:AddToggle("aqxAutoGrab", { Text = "Auto Steal Dropped Cash", Default = false, Callback = function(s) AutoGrabMoney = s end })

local g = tabPlayer:AddGroup("Movement")
g:AddToggle("aqxNoBob", { Text = "Disable Camera Bobbing", Default = false, Callback = function(s) NoCameraBob = s end })
g:AddToggle("aqxWalk", { Text = "WalkSpeed", Default = false, Callback = function(s)
    if s then LuhjayyWalkStart() else LuhjayyWalkStop() end
end })
g:AddSlider("aqxWalkSpeed", { Text = "Walk Speed", Min = 16, Max = 500, Default = 16, Callback = function(v) LuhjayyWalk.Speed = v end })
g:AddToggle("aqxJumpBoost", { Text = "Jump Boost", Default = false, Callback = function(s) updateJumpBoostState(s) end })
g:AddToggle("aqxInfJump", { Text = "Infinite Jump", Default = false, Callback = function(s) InfJumpEnabled = s end })
g:AddToggle("aqxNoclip", { Text = "Noclip", Default = false, Callback = function(s)
    NoclipEnabled = s
    if s then enableNoclip() else disableNoclip() end
end })
g:AddToggle("aqxFly", { Text = "Fly", Default = false, Callback = function(s)
    if s then MiamiFlySetup() else MiamiFlyCleanup() end
end })
g:AddSlider("aqxFlySpeed", { Text = "Fly Speed", Min = 20, Max = 300, Default = 80, Callback = function(v)
    getgenv().MiamiFlyData.Speed = v
end })

local g = tabPlayer:AddGroup("Misc")
g:AddToggle("aqxFaster", { Text = "Faster Respawn", Default = false, Callback = function(s) FasterRespawn = s end })
g:AddToggle("aqxRespawnWhere", { Text = "Respawn Where You Died", Default = false, Callback = function(s) SetRespawnWhereYouDied(s) end })
g:AddToggle("aqxKeepTools", { Text = "Keep Tools On Death", Default = false, Callback = function(s) KeepToolsOnDeath = s end })
g:AddToggle("aqxAutoHelp", { Text = "Auto Get Help", Default = false, Callback = function(s) AutoFOnLowHealth = s end })
g:AddToggle("aqxAntiAFK", { Text = "Anti-AFK (20 min)", Default = false, Callback = function(s) getgenv().AntiAFKEnabled = s end })

local g = tabPlayer:AddGroup("Money")
g:AddButton("Manual [Inf Money]", function()
    notify("Inf Money", "Triggered.")
    task.spawn(function() pcall(InfMoneyHoldCupz) end)
end)
g:AddButton("Generate Max Illegal Money", function()
    notify("Illegal Money", "Generating max...")
    task.spawn(function() pcall(GenerateMaxIllegalMoney) end)
end)
g:AddButton("Teleport [COOK POT]", TeleportToCookPot)
g:AddButton("Buy Ice-Fruit [ITEMS]", function()
    notify("Buy Items", "Buying Ice-Fruit items...")
    SetupInfiniteMoney()
end)
g:AddButton("Clean All Filthy Money", CleanAllFilthyMoney)
g:AddToggle("aqxDrop10k", { Text = "Auto Drop 10k", Default = false, Callback = function(s) getgenv().MoneyDropEnabled = s end })

local g = tabPlayer:AddGroup("Quick Buy")
local function buyQuick(name, item, cat)
    task.spawn(function()
        local ok, bought, problem = pcall(qbDoBuy, item, cat)
        if ok and bought then notify("Quick Buy", name .. " purchased")
        else notify("Quick Buy", "Failed: " .. tostring(ok and problem or bought)) end
    end)
end
g:AddButton("Buy BagElite", function() buyQuick("BagElite", "BagElite", "BAGS") end)
g:AddButton("Buy Draco", function() buyQuick("Draco", "Draco", "OTHER") end)
g:AddButton("Buy Shiesty", function() buyQuick("Shiesty", "Shiesty", "MAIN SHOP") end)
g:AddButton("Buy Lemonade", function() buyQuick("Lemonade", "Lemonade", "EXOTIC") end)
g:AddButton("Buy Bandage", function() buyQuick("Bandage", "Bandage", "EXOTIC") end)

local g = tabPlayer:AddGroup("Bank / ATM")
local function getBankValue()
    local ok, v = pcall(function() return LocalPlayer.stored.Bank.Value end)
    if ok then return v end; return 0
end
local bankLbl = g:AddLabel("Bank: $" .. tostring(getBankValue()))
pcall(function()
    local stored = LocalPlayer:WaitForChild("stored", 5)
    if stored and stored:FindFirstChild("Bank") then
        stored.Bank:GetPropertyChangedSignal("Value"):Connect(function()
            pcall(function() bankLbl:SetText("Bank: $" .. tostring(stored.Bank.Value)) end)
        end)
    end
end)
g:AddInput("aqxWithdraw", { Text = "Withdraw Amount", Placeholder = "Max 90,000", Numeric = true, Callback = function(v)
    local a = tonumber(v)
    if a and a > 0 and a <= 90000 then
        pcall(function() ReplicatedStorage.BankAction:FireServer("with", a) end)
        notify("Withdraw", "Withdrew $" .. a)
    end
end })
g:AddInput("aqxDeposit", { Text = "Deposit Amount", Placeholder = "Max 30,000", Numeric = true, Callback = function(v)
    local a = tonumber(v)
    if a and a > 0 and a <= 30000 then
        pcall(function() ReplicatedStorage.BankAction:FireServer("depo", a) end)
        notify("Deposit", "Deposited $" .. a)
    end
end })
g:AddToggle("aqxAutoDepo", { Text = "Auto Deposit 30K", Default = false, Callback = function(v)
    if v then
        task.spawn(function()
            local BA = ReplicatedStorage:WaitForChild("BankAction")
            while Flags["aqxAutoDepo"] do
                pcall(function() BA:FireServer("depo", 30000) end); task.wait(3)
            end
        end)
    end
end })
g:AddToggle("aqxAutoWith", { Text = "Auto Withdraw 90K", Default = false, Callback = function(v)
    if v then
        task.spawn(function()
            local BA = ReplicatedStorage:WaitForChild("BankAction")
            while Flags["aqxAutoWith"] do
                pcall(function() BA:FireServer("with", 90000) end); task.wait(3)
            end
        end)
    end
end })

-- MAIN -----------------------------------------------------------
local tabMain = makeTab("Main")

local g = tabMain:AddGroup("Target")
TargetPlayerNames = getTargetPlayerList()
TargetUtilities.SelectedPlayer = TargetPlayerNames[1] or ""
local targetDD = g:AddDropdown("aqxTargetPlayer", {
    Text = "Select Player", Values = TargetPlayerNames, Default = TargetUtilities.SelectedPlayer,
    Callback = function(v) TargetUtilities.SelectedPlayer = tostring(v) end,
})
g:AddButton("Refresh Player List", function()
    TargetPlayerNames = getTargetPlayerList()
    if targetDD then targetDD:SetValues(TargetPlayerNames) end
    notify("Target", "Player list refreshed: " .. #TargetPlayerNames)
end)
g:AddButton("Pass to Nearest Player", function()
    pcall(function()
        ReplicatedStorage.DropRemote:FireServer("Drop")
        notify("Pass", "Passed to nearest player.")
    end)
end)
g:AddToggle("aqxAutoPass", { Text = "Auto Pass to Nearest (loop)", Default = false, Callback = function(v)
    if v and not getgenv()._aqxPassRunning then
        getgenv()._aqxPassRunning = true
        task.spawn(function()
            while Flags["aqxAutoPass"] do
                pcall(function() ReplicatedStorage.DropRemote:FireServer("Drop") end)
                task.wait(0.1)
            end
            getgenv()._aqxPassRunning = false
        end)
    end
end })
g:AddToggle("aqxAutoDropGuns", { Text = "Auto Drop Guns", Default = false, Callback = function(v)
    if v and not getgenv()._aqxDropRunning then
        getgenv()._aqxDropRunning = true
        task.spawn(function()
            while Flags["aqxAutoDropGuns"] do
                pcall(function()
                    local char = LocalPlayer.Character
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if char and bp then
                        for _, gun in ipairs(bp:GetChildren()) do
                            if gun:IsA("Tool") and gun:FindFirstChild("GunScript_Server") then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hum then hum:EquipTool(gun) end
                                local d = ReplicatedStorage:FindFirstChild("DropItemRemote")
                                if d then d:FireServer(gun) end
                                break
                            end
                        end
                    end
                end)
                task.wait(math.random(10,13)/10)
            end
            getgenv()._aqxDropRunning = false
        end)
    end
end })
g:AddToggle("aqxSpectate", { Text = "Spectate Player", Default = false, Callback = function(s) TargetUtilities.SpectatePlayer = s end })
g:AddToggle("aqxBringNearest", { Text = "Bring Nearest Player", Default = false, Callback = function(s) TargetUtilities.BringingNearestPlayer = s end })
g:AddToggle("aqxBringPlayer", { Text = "Bring Player", Default = false, Callback = function(s) TargetUtilities.BringingPlayer = s end })
g:AddToggle("aqxAutoKill", { Text = "Auto Kill Player - Gun", Default = false, Callback = function(s) TargetUtilities.AutoKill = s end })
g:AddButton("Car Fling Selected Player", CarFlingSelectedPlayer)
g:AddToggle("aqxAutoRagdoll", { Text = "Auto Ragdoll Player - Gun", Default = false, Callback = function(s) TargetUtilities.AutoRagdoll = s end })
g:AddButton("Teleport To Player", function()
    local t = getSelectedTargetPlayer()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        Config:Teleport(t.Character.HumanoidRootPart.CFrame * CFrame.new(3,0,0))
    else notify("Target", "No valid target selected.") end
end)
g:AddButton("God Player - Hold Gun", function()
    local t = getSelectedTargetPlayer()
    if t then targetGunRemote(t.Name, "HumanoidRootPart", math.huge)
    else notify("Target", "No valid target selected.") end
end)

local g = tabMain:AddGroup("Vehicle")
g:AddToggle("aqxCarFly", { Text = "Car Fly", Default = false, Callback = function(s)
    if s then StartCarFly() else StopCarFly() end
end })
g:AddSlider("aqxCarFlySpeed", { Text = "Car Fly Speed", Min = 20, Max = 300, Default = 120, Callback = function(v)
    Config.TheBronx.carflyspeed = v; CarFly.Speed = v
end })
g:AddToggle("aqxVehSpeed", { Text = "Vehicle Speed Boost", Default = false, Callback = function(s) VehicleModifications.SpeedEnabled = s end })
g:AddSlider("aqxVehSpeedVal", { Text = "Speed Multiplier", Min = 1, Max = 25, Default = 5, Callback = function(v) VehicleModifications.SpeedValue = v / 1000 end })
g:AddToggle("aqxVehBrake", { Text = "Vehicle Brakes", Default = false, Callback = function(s) VehicleModifications.BreakEnabled = s end })
g:AddSlider("aqxVehBrakeVal", { Text = "Brake Multiplier", Min = 10, Max = 300, Default = 50, Callback = function(v) VehicleModifications.BreakValue = v / 1000 end })
g:AddToggle("aqxVehStop", { Text = "Instant Stop (V)", Default = false, Callback = function(s) VehicleModifications.InstantStop = s end })
g:AddButton("Bring Nearest Car", function()
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end
    local car = GetNearestCar(hrp)
    if not car then notify("Bring Car", "No empty cars found nearby!") return end
    local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat")
    if not seat then return end
    if not car.PrimaryPart then pcall(function() car.PrimaryPart = car:FindFirstChildWhichIsA("BasePart") end) end
    if car.PrimaryPart then
        car:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0,0,-6) * CFrame.Angles(0, math.rad(180), 0))
    else
        seat.CFrame = hrp.CFrame * CFrame.new(0,0,-6) * CFrame.Angles(0, math.rad(180), 0)
    end
    task.wait(0.2); seat:Sit(hum)
    notify("Bring Car", "Car brought successfully!")
end)

-- FARM -----------------------------------------------------------
local tabFarm = makeTab("Farm")

local g = tabFarm:AddGroup("Autofarms")
local dumpFlag = false
g:AddButton("Dumpster Autofarm", function()
    if not dumpFlag then
        dumpFlag = true; startDumpsterAutofarm()
        notify("Autofarm","Dumpster started.")
    else
        dumpFlag = false; stopDumpsterAutofarm()
        notify("Autofarm","Dumpster stopped.")
    end
end)
g:AddButton("Studio Autofarm", function()
    getgenv().StudioPayFarm = not getgenv().StudioPayFarm
    notify("Autofarm","Studio "..(getgenv().StudioPayFarm and "started." or "stopped."))
end)
local constFlag = false
g:AddButton("Construction Autofarm", function()
    if not constFlag then
        constFlag = true; startConstructionAutofarm()
        notify("Autofarm","Construction started.")
    else
        constFlag = false; stopConstructionAutofarm()
        notify("Autofarm","Construction stopped.")
    end
end)

local g = tabFarm:AddGroup("Quick TPs")
local selectedTp = teleportNames[1]
g:AddDropdown("aqxTpLoc", { Text = "Location", Values = teleportNames, Default = selectedTp,
    Callback = function(v) selectedTp = tostring(v) end })
g:AddButton("Teleport", function()
    local cf = teleportLocations[selectedTp]
    if cf then Config:Teleport(cf); notify("TP", "Teleported to " .. selectedTp) end
end)
g:AddButton("Dynamic Cook Pot", TeleportToCookPot)

local g = tabFarm:AddGroup("House TPs")
local houseLookup = {}
local selectedHouseName = nil
local houseDD = g:AddDropdown("aqxHouseTp", { Text = "Select House", Values = {"No houses found"},
    Default = "No houses found", Callback = function(v) selectedHouseName = tostring(v) end })
local function refreshHouseList(showNote)
    table.clear(houseLookup)
    local values = {}
    local homeFolder = workspace:FindFirstChild("HomeDoorSS")
    if homeFolder then
        for _, house in ipairs(homeFolder:GetChildren()) do
            local owner = house:FindFirstChild("Owner")
            if owner and tostring(owner.Value) ~= "None" and tostring(owner.Value) ~= "" then
                local display = (tostring(owner.Value) == LocalPlayer.Name) and "My House"
                    or (tostring(owner.Value) .. "'s House")
                table.insert(values, display)
                houseLookup[display] = house
            end
        end
    end
    table.sort(values)
    if #values == 0 then values = {"No houses found"} end
    selectedHouseName = values[1]
    if houseDD and houseDD.SetValues then houseDD:SetValues(values) end
    if showNote then notify("House TPs", "Refreshed: " .. #values) end
end
g:AddButton("Refresh Houses", function() refreshHouseList(true) end)
g:AddButton("Teleport To House", function()
    if not selectedHouseName or selectedHouseName == "No houses found" then
        notify("House TPs", "No house selected."); return
    end
    local house = houseLookup[selectedHouseName]
    if not house then notify("House TPs", "House not found. Refresh."); return end
    local part = house.PrimaryPart or house:FindFirstChildWhichIsA("BasePart", true)
    if not part then notify("House TPs", "No valid house part."); return end
    Config:Teleport(part.CFrame + Vector3.new(0, 5, 0))
    notify("House TPs", "Teleported to " .. selectedHouseName, 2)
end)
refreshHouseList(false)

-- EXTRA ----------------------------------------------------------
local tabExtra = makeTab("Extra")

local g = tabExtra:AddGroup("Emotes")
g:AddDropdown("aqxEmote", { Text = "Select Emote", Values = MianiEmoteNames, Default = "Take The L",
    Callback = function(v) if MianiEmotes[v] then MianiSelectedEmoteName = v end end })
g:AddButton("Play Selected Emote", function()
    local id = MianiEmotes[MianiSelectedEmoteName]
    if id then MianiPlayEmoteById(id, MianiSelectedEmoteName) end
end)
g:AddButton("Stop Emote", function() MianiStopAllTracks(); notify("Emotes","Stopped emote") end)
g:AddToggle("aqxEmoteLoop", { Text = "Loop Emote", Default = true, Callback = function(s)
    MianiEmoteSettings.Loop = s
    if MianiCurrentEmoteTrack then pcall(function() MianiCurrentEmoteTrack.Looped = s end) end
end })

local g = tabExtra:AddGroup("Quick Outfits")
g:AddButton("Spiderman", function()
    applyOutfit("Spiderman", {{"Buy","Shirts","Spiderman"},{"Wear","Shirts","Spiderman"},
        {"Buy","Pants","Spiderman"},{"Wear","Pants","Spiderman"},
        {"Buy","Shiestys","RedShiesty"},{"Wear","Shiestys","RedShiesty"}})
end)
g:AddButton("All Black", function()
    applyOutfit("All Black", {{"Buy","Shirts","Black"},{"Wear","Shirts","Black"},
        {"Buy","Pants","Black"},{"Wear","Pants","Black"},
        {"Buy","Shiestys","BlackShiesty"},{"Wear","Shiestys","BlackShiesty"}})
end)
g:AddButton("Blu Moncler Drip", function()
    applyOutfit("Blu Moncler Drip", {{"Buy","Shirts","Blu Moncler"},{"Wear","Shirts","Blu Moncler"},
        {"Buy","Pants","Amiri Blue Jeans"},{"Wear","Pants","Amiri Blue Jeans"},
        {"Buy","Shiestys","Shiesty"},{"Wear","Shiestys","Shiesty"}})
end)
g:AddToggle("aqxFlashOutfit", { Text = "Flash Outfit", Default = false, Callback = function(v)
    getgenv().FlashOutfits = v
    if v then
        notify("Outfit", "Flash Outfit enabled")
        if FlashOutfitLoopRunning then return end
        FlashOutfitLoopRunning = true
        task.spawn(function()
            while getgenv().FlashOutfits do
                task.wait(getgenv().OutfitSwapDelay or 0.2)
                for category, list in pairs(RandomClothes) do
                    if not getgenv().FlashOutfits then break end
                    local item = list[math.random(1, #list)]
                    ApplyDripstoreClothing(category, item)
                end
            end
            FlashOutfitLoopRunning = false
        end)
    else notify("Outfit", "Flash Outfit disabled") end
end })
g:AddSlider("aqxOutfitSpeed", { Text = "Flash Swap Delay", Default = 0.2, Min = 0.0005, Max = 2.5,
    Callback = function(v) getgenv().OutfitSwapDelay = v end })

-- GUN MODS -------------------------------------------------------
local tabGun = makeTab("Gun Mods")

local g = tabGun:AddGroup("Weapon Modifications")
local function bindToggle(display, key, flag)
    g:AddToggle(flag, { Text = display, Default = false, Callback = function(s)
        WeaponMods[key] = s
        if key == "InfiniteDamage" then WeaponMods.DamageAmplified = s end
        pcall(applyAllWeaponMods)
    end })
end
bindToggle("Infinite Ammo", "InfiniteAmmo", "aqxInfAmmo")
bindToggle("Infinite Clips", "InfiniteClips", "aqxInfClips")
bindToggle("Infinite Damage", "InfiniteDamage", "aqxInfDmg")
bindToggle("Instant Reload", "InstantReload", "aqxInstReload")
bindToggle("Instant Equip", "InstantEquip", "aqxInstEquip")
bindToggle("80k Bullets", "Bullets80k", "aqx80k")
bindToggle("Fully Automatic", "Automatic", "aqxAuto")
bindToggle("Disable Jamming", "DisableJamming", "aqxNoJam")
bindToggle("Modify Recoil Value", "ModifyRecoilValue", "aqxRecoil")
bindToggle("Modify Spread Value", "ModifySpreadValue", "aqxSpread")
bindToggle("Modify Fire Rate", "ModifyFireRate", "aqxFireRate")
g:AddButton("Force 80k Bullets", force80k)

local g = tabGun:AddGroup("Weapon Settings")
g:AddSlider("aqxFireRatePct", { Text = "Fire-Rate Percentage", Min = 1, Max = 100, Default = 50,
    Callback = function(v) WeaponMods.FireRateSpeed = v end })
g:AddSlider("aqxSpreadPct", { Text = "Spread Percentage", Min = 1, Max = 100, Default = 50,
    Callback = function(v) WeaponMods.SpreadPercentage = v end })
g:AddSlider("aqxRecoilPct", { Text = "Recoil Percentage", Min = 1, Max = 100, Default = 50,
    Callback = function(v) WeaponMods.RecoilPercentage = v end })
g:AddSlider("aqxReloadSpd", { Text = "Reload Speed", Min = 0.01, Max = 1, Default = 0.2,
    Callback = function(v) WeaponMods.ReloadSpeed = v; pcall(applyAllWeaponMods) end })
g:AddSlider("aqxEquipSpd", { Text = "Equip Speed", Min = 0.01, Max = 1, Default = 0.2,
    Callback = function(v) WeaponMods.EquipSpeed = v; pcall(applyAllWeaponMods) end })

local g = tabGun:AddGroup("Gun Color")
g:AddToggle("aqxGunColor", { Text = "Enable Gun Color", Default = false, Callback = function(s)
    GunChams = s
    if not s then restoreGunColor() end
end })
g:AddToggle("aqxRainbowGun", { Text = "Rainbow Gun Color", Default = false, Callback = function(s) RainbowGun = s end })
g:AddDropdown("aqxGunColorPick", { Text = "Gun Color",
    Values = {"Green","Purple","Red","Blue","Pink","Cyan","Yellow","White"}, Default = "Green",
    Callback = function(v)
        local colors = {
            Green=Color3.fromRGB(0,200,0), Purple=Color3.fromRGB(143,0,255),
            Red=Color3.fromRGB(255,0,0), Blue=Color3.fromRGB(0,120,255),
            Pink=Color3.fromRGB(255,80,180), Cyan=Color3.fromRGB(0,255,255),
            Yellow=Color3.fromRGB(255,255,0), White=Color3.fromRGB(255,255,255),
        }
        GunChamsColor = colors[tostring(v)] or Color3.fromRGB(0,200,0)
    end })

local g = tabGun:AddGroup("Bullet Visuals")
g:AddToggle("aqxFireBullets", { Text = "Fire Bullets", Default = false, Callback = function(state)
    fireBallsEnabled = state
    if state then
        for _, v in getgc(true) do
            if typeof(v) == "table" then
                pcall(function()
                    setBulletVisuals(v)
                    setBulletVisuals(rawget(v, 7))
                    setBulletVisuals(rawget(v, 8))
                end)
            end
        end
        notify("Weapon Mods", "Fire Bullets enabled!")
    else notify("Weapon Mods", "Fire Bullets disabled (Re-equip gun to revert)!") end
end })
g:AddToggle("aqxFlashbang", { Text = "Flashbang Bullets", Default = false, Callback = function(state)
    FlashbangBulletsEnabled = state
    refreshOrbFlashState()
    notify("Weapon Mods", state and "Flashbang enabled!" or "Flashbang disabled!")
end })
g:AddToggle("aqxTornado", { Text = "Tornado Bullets", Default = false, Callback = function(state)
    TornadoBulletsEnabled = state
    refreshOrbFlashState()
    notify("Weapon Mods", state and "Tornado enabled!" or "Tornado disabled!")
end })
g:AddSlider("aqxTornadoSpd", { Text = "Tornado Speed", Min = 1, Max = 500, Default = 250,
    Callback = function(v) TornadoBulletSpeed = v; if TornadoBulletsEnabled then applyAllOrbFlashConfigs() end end })
task.spawn(function()
    while task.wait(0.1) do
        if FlashbangBulletsEnabled or TornadoBulletsEnabled then applyAllOrbFlashConfigs() end
    end
end)
onUnload(function()
    FlashbangBulletsEnabled = false; TornadoBulletsEnabled = false
    restoreAllOrbFlashConfigs()
end)

local g = tabGun:AddGroup("Spraypaint")
g:AddDropdown("aqxSprayImg", { Text = "Spraypaint Image", Values = SprayPaintImageNames, Default = "Taco Scripts",
    Callback = function(value)
        SelectedSprayPaintImage = tostring(value)
        SPRAYPAINT_IMAGE_ID = SprayPaintImagePresets[SelectedSprayPaintImage] or SprayPaintImagePresets["Taco Scripts"]
        SPRAYPAINT_IMAGE = "rbxassetid://" .. tostring(SPRAYPAINT_IMAGE_ID)
        if SprayPaintEnabled then ScanSprayPaintSettings() end
        notify("Spraypaint", "Selected " .. SelectedSprayPaintImage .. " image.")
    end })
g:AddToggle("aqxSprayManual", { Text = "Spraypaint", Default = false, Callback = function(state)
    ManualSprayPaintEnabled = state
    SprayPaintEnabled = ManualSprayPaintEnabled or AutoSprayPaintEnabled
    if SprayPaintEnabled then ScanSprayPaintSettings(); notify("Spraypaint","Enabled")
    else RestoreSprayPaintSettings(); notify("Spraypaint","Restored") end
end })
g:AddToggle("aqxSprayAuto", { Text = "Auto Spraypaint", Default = false, Callback = function(state)
    AutoSprayPaintEnabled = state
    SprayPaintEnabled = ManualSprayPaintEnabled or AutoSprayPaintEnabled
    if state then
        ScanSprayPaintSettings(); StartAutoSprayPaintWorker()
        notify("Auto Spraypaint","Enabled")
    elseif not SprayPaintEnabled then
        RestoreSprayPaintSettings()
        notify("Auto Spraypaint","Stopped")
    end
end })
g:AddSlider("aqxSprayDelay", { Text = "Auto Paint Delay", Min = 0.5, Max = 5, Default = 1,
    Callback = function(v) AutoSprayPaintDelay = v end })
g:AddSlider("aqxSpraySize", { Text = "Spray Size", Min = 2, Max = 100, Default = 10,
    Callback = function(v) SprayPaintHoleSize = v; if SprayPaintEnabled then ScanSprayPaintSettings() end end })
g:AddSlider("aqxSprayTime", { Text = "Visible Time", Min = 1, Max = 18000, Default = 18000,
    Callback = function(v) SprayPaintVisibleTime = v; if SprayPaintEnabled then ScanSprayPaintSettings() end end })
onUnload(function()
    AutoSprayPaintEnabled=false; ManualSprayPaintEnabled=false; SprayPaintEnabled=false
    RestoreSprayPaintSettings()
end)

-- VISUALS --------------------------------------------------------
local tabVisuals = makeTab("Visuals")

local g = tabVisuals:AddGroup("World")
g:AddToggle("aqxFullbright", { Text = "Fullbright", Default = false, Callback = function(v) WorldVisuals.Fullbright = v end })
g:AddToggle("aqxSat", { Text = "Enable Saturation", Default = false, Callback = function(v) WorldVisuals.SaturationEnabled = v end })
g:AddSlider("aqxSatVal", { Text = "Saturation Value", Min = 0, Max = 200, Default = 100,
    Callback = function(v) WorldVisuals.SaturationValue = v / 100 end })
g:AddToggle("aqxFov", { Text = "Enable FOV", Default = false, Callback = function(v) WorldVisuals.FieldOfViewEnabled = v end })
g:AddSlider("aqxFovVal", { Text = "FOV Value", Min = 30, Max = 120, Default = 70,
    Callback = function(v) WorldVisuals.FieldOfViewValue = v end })
g:AddToggle("aqxStretch", { Text = "Enable Stretch", Default = false, Callback = function(v) WorldVisuals.StretchEnabled = v end })
g:AddSlider("aqxStretchVal", { Text = "Stretch Value", Min = 0.1, Max = 2, Default = 0.7,
    Callback = function(v) WorldVisuals.StretchValue = v end })
g:AddToggle("aqxFog", { Text = "Enable Fog Color", Default = false, Callback = function(v) WorldVisuals.FogColorEnabled = v end })
g:AddDropdown("aqxFogColor", { Text = "Fog Color", Values = VisualColorNames, Default = "White",
    Callback = function(v) WorldVisuals.FogColor = VisualColorPresets[tostring(v)] or Color3.fromRGB(255,255,255) end })
g:AddToggle("aqxAmbient", { Text = "Enable Ambient Tint", Default = false, Callback = function(v) WorldVisuals.AmbientEnabled = v end })
g:AddDropdown("aqxAmbientColor", { Text = "Ambient Color", Values = VisualColorNames, Default = "White",
    Callback = function(v) WorldVisuals.AmbientColor = VisualColorPresets[tostring(v)] or Color3.fromRGB(255,255,255) end })

local g = tabVisuals:AddGroup("Player ESP")
g:AddToggle("aqxESP", { Text = "ESP Enabled", Default = false, Callback = function(v) ESPFlags.Enabled = v end })
g:AddSlider("aqxESPDist", { Text = "Render Distance", Min = 50, Max = 5000, Default = 1400,
    Callback = function(v) ESPFlags.RenderDistance = v end })
g:AddToggle("aqxESPTeam", { Text = "Team Color", Default = true, Callback = function(v) ESPFlags.TeamColor = v end })
g:AddToggle("aqxESPBoxes", { Text = "Boxes", Default = true, Callback = function(v) ESPFlags.Boxes = v end })
g:AddDropdown("aqxESPBoxType", { Text = "Box Type", Values = {"Corner","Full"}, Default = "Corner",
    Callback = function(v) ESPFlags.BoxType = tostring(v) end })
g:AddDropdown("aqxESPBoxColor", { Text = "Box Color", Values = VisualColorNames, Default = "Orange",
    Callback = function(v) ESPFlags.BoxColor = VisualColorPresets[tostring(v)] or Color3.fromRGB(255,140,0) end })
g:AddToggle("aqxESPBoxFill", { Text = "Box Fill", Default = false, Callback = function(v) ESPFlags.BoxFill = v end })
g:AddToggle("aqxESPHealth", { Text = "Healthbar", Default = true, Callback = function(v) ESPFlags.Healthbar = v end })
g:AddToggle("aqxESPHealthNum", { Text = "Healthbar Number", Default = false, Callback = function(v) ESPFlags.HealthbarNumber = v end })
g:AddSlider("aqxESPHealthThick", { Text = "Healthbar Thickness", Min = 1, Max = 10, Default = 3,
    Callback = function(v) ESPFlags.HealthbarThickness = v end })
g:AddToggle("aqxESPChams", { Text = "Chams", Default = false, Callback = function(v) ESPFlags.Chams = v end })
g:AddDropdown("aqxESPChamsColor", { Text = "Chams Color", Values = VisualColorNames, Default = "Orange",
    Callback = function(v) ESPFlags.ChamsColor = VisualColorPresets[tostring(v)] or Color3.fromRGB(255,140,0) end })
g:AddToggle("aqxESPName", { Text = "Name", Default = true, Callback = function(v) ESPFlags.Name = v end })
g:AddToggle("aqxESPFriend", { Text = "Friend Marker (F)", Default = true, Callback = function(v) ESPFlags.FriendMarker = v end })
g:AddToggle("aqxESPDist2", { Text = "Distance", Default = true, Callback = function(v) ESPFlags.Distance = v end })
g:AddToggle("aqxESPWeapon", { Text = "Weapon", Default = false, Callback = function(v) ESPFlags.Weapon = v end })
g:AddSlider("aqxESPTextSize", { Text = "Text Size", Min = 8, Max = 20, Default = 14,
    Callback = function(v) ESPFlags.TextSize = v end })
g:AddToggle("aqxESPSnap", { Text = "Snaplines", Default = false, Callback = function(v) ESPFlags.Snaplines = v end })
g:AddToggle("aqxESPSkel", { Text = "Skeleton", Default = false, Callback = function(v) ESPFlags.Skeleton = v end })
g:AddToggle("aqxESPTracer", { Text = "Look Tracers", Default = false, Callback = function(v) ESPFlags.LookTracers = v end })

local g = tabVisuals:AddGroup("Hitbox")
g:AddToggle("aqxHitbox", { Text = "Enable Hitbox", Default = false, Callback = function(v) HitboxVisuals.Enabled = v end })
g:AddDropdown("aqxHitboxPart", { Text = "Part",
    Values = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm",
        "RightUpperArm","RightLowerArm","LeftUpperLeg","LeftLowerLeg","RightUpperLeg","RightLowerLeg"},
    Default = "Head", Callback = function(v) HitboxVisuals.Part = tostring(v) end })
g:AddSlider("aqxHitboxMult", { Text = "Multiplier", Min = 1, Max = 15, Default = 5,
    Callback = function(v) HitboxVisuals.Multiplier = v end })
g:AddSlider("aqxHitboxTrans", { Text = "Transparency", Min = 0, Max = 1, Default = 0.45,
    Callback = function(v) HitboxVisuals.Transparency = v end })
g:AddDropdown("aqxHitboxMat", { Text = "Material", Values = {"ForceField","Neon","Plastic","SmoothPlastic","Glass"},
    Default = "ForceField", Callback = function(v) HitboxVisuals.Material = tostring(v) end })
g:AddDropdown("aqxHitboxType", { Text = "Type", Values = {"Block","Ball","Cylinder"}, Default = "Block",
    Callback = function(v) HitboxVisuals.Type = tostring(v) end })
g:AddToggle("aqxHitboxTeam", { Text = "Skip Teammates", Default = false, Callback = function(v) HitboxVisuals.TeamCheck = v end })

-- SAFE -----------------------------------------------------------
local tabSafe = makeTab("Safe")

local g = tabSafe:AddGroup("Safe")
local safeItems = GetSafeItems()
if #safeItems == 0 then safeItems = {"(empty - press Refresh)"} end
local selectedSafeItem = safeItems[1]
local safeDD = g:AddDropdown("aqxSafeItem", { Text = "Select Safe Item", Values = safeItems, Default = selectedSafeItem,
    Callback = function(v) selectedSafeItem = tostring(v) end })
g:AddButton("Refresh Safe List", function()
    local items = GetSafeItems()
    if #items == 0 then items = {"(empty)"} end
    if safeDD then safeDD:SetValues(items) end
    selectedSafeItem = items[1]
    notify("Safe", "Refreshed: " .. #items .. " items")
end)
local safeTakeAllActive = false
g:AddButton("Take All", function()
    if safeTakeAllActive then notify("Safe", "Take All already running."); return end
    local items = GetSafeItems()
    if #items == 0 then notify("Safe", "Safe is empty."); return end
    safeTakeAllActive = true
    task.spawn(function()
        notify("Safe", "Taking all " .. #items .. " items...")
        local taken = 0
        for _, n in ipairs(items) do
            if not safeTakeAllActive then break end
            if TakeFromSafe(n) then taken = taken + 1 end
            task.wait(0.5)
        end
        local stopped = not safeTakeAllActive
        safeTakeAllActive = false
        notify("Safe", stopped and ("Stopped after " .. taken) or ("Took " .. taken .. "/" .. #items))
    end)
end)
g:AddButton("Stop Take All", function()
    if safeTakeAllActive then safeTakeAllActive = false; notify("Safe", "Stop requested.")
    else notify("Safe", "Take All is not running.") end
end)

local g = tabSafe:AddGroup("Safe Dupe")
local dupeItems = GetLockedTools()
table.insert(dupeItems, 1, "None")
local dupeDD = g:AddDropdown("aqxDupeItem", { Text = "Select Item", Values = dupeItems, Default = "None",
    Callback = function(v)
        local pick = tostring(v)
        if pick == "None" or pick == "" then selectedDupeItem = nil
        else selectedDupeItem = pick end
    end })
g:AddButton("Refresh Items", function()
    local items = GetLockedTools()
    local list = {"None"}
    for _, t in ipairs(items) do table.insert(list, t) end
    if dupeDD then dupeDD:SetValues(list) end
    selectedDupeItem = nil
    notify("Dupe", "Refreshed: " .. (#list - 1) .. " tools")
end)
local customDupeAmount = 1
g:AddSlider("aqxDupeAmt", { Text = "Custom Dupe Amount", Min = 1, Max = 15, Default = 1,
    Callback = function(v) customDupeAmount = math.clamp(math.floor(v), 1, 15) end })
g:AddButton("Run Custom Safe Dupe", function()
    if not autoDupeActive then DoDupe(customDupeAmount)
    else notify("Dupe", "Dupe is currently running!") end
end)
g:AddButton("Safe Dupe 15 Times", function()
    if not autoDupeActive then DoDupe(15)
    else notify("Dupe", "Dupe is currently running!") end
end)
g:AddButton("Stop Safe Dupe", function()
    if autoDupeActive then autoDupeActive = false; notify("Dupe", "Stop requested.")
    else notify("Dupe", "No dupe process running.") end
end)
g:AddToggle("aqxAutoDupe", { Text = "Auto Safe Dupe (Infinite)", Default = false, Callback = function(state)
    if state then
        if not autoDupeActive then DoDupe(math.huge) end
    else
        if autoDupeActive then autoDupeActive = false; notify("Dupe", "Stopped") end
    end
end })
g:AddButton("Safe TP", SafeTP)
g:AddToggle("aqxAutoDropTools", { Text = "Auto Drop Tools", Default = false, Callback = function(s) ToggleAutoDrop(s) end })

local g = tabSafe:AddGroup("Info")
local safeStatusLbl = g:AddLabel("Safe Status: Ready")
local itemCountLbl = g:AddLabel("Items in Safe: ?")
local dupeCounterLbl = g:AddLabel("Total Duped: 0")
local dupeActiveLbl = g:AddLabel("Dupe: IDLE")
task.spawn(function()
    while task.wait(5) do
        local n = #GetSafeItems()
        pcall(function() itemCountLbl:SetText("Items in Safe: " .. n) end)
        local SafeFolder = GetActiveSafe()
        pcall(function() safeStatusLbl:SetText("Safe Status: " .. (SafeFolder and "Found" or "Not Found")) end)
        pcall(function() dupeCounterLbl:SetText("Total Duped: " .. dupeCounter) end)
        pcall(function() dupeActiveLbl:SetText("Dupe: " .. (autoDupeActive and "RUNNING" or "IDLE")) end)
    end
end)

-- SETTINGS -------------------------------------------------------
local tabSettings = makeTab("Settings")

local g = tabSettings:AddGroup("My Money")
local myClean = g:AddLabel("Clean Money: None")
local myBank = g:AddLabel("Bank: None")
local myDirty = g:AddLabel("Dirty Money: None")
local myMade = g:AddLabel("Money Made: $0")
local myLost = g:AddLabel("Money Lost: $0")

getgenv().MoneyMadeTotal = 0
getgenv().MoneyLostTotal = 0

local function valueToNumber(o)
    if not o then return nil end
    local ok, v = pcall(function() return o.Value end)
    if ok and tonumber(v) then return tonumber(v) end
end
local function findMoneyValue(c, names, recursive)
    if not c then return nil end
    local lk = {}
    for _, n in ipairs(names) do lk[string.lower(n)] = true end
    for _, ch in ipairs(c:GetChildren()) do
        if lk[string.lower(ch.Name)] then
            local v = valueToNumber(ch); if v ~= nil then return v end
        end
    end
    if recursive then
        for _, ch in ipairs(c:GetDescendants()) do
            if lk[string.lower(ch.Name)] then
                local v = valueToNumber(ch); if v ~= nil then return v end
            end
        end
    end
end
local function getMyMoneyValues()
    local cN = {"Money","Cash","Wallet","Bank","Coins"}
    local dN = {"FilthyStack","FilthyMoney","DirtyMoney","DirtyCash","IllegalMoney","Dirty","Filthy"}
    local stored = LocalPlayer:FindFirstChild("stored") or LocalPlayer:FindFirstChild("Stored")
    local leader = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Leaderstats")
        or LocalPlayer:FindFirstChild("stats")
    local clean = findMoneyValue(stored, {"Money"}, false) or findMoneyValue(leader, cN, false)
        or findMoneyValue(LocalPlayer, cN, false) or findMoneyValue(LocalPlayer, cN, true)
    local dirty = findMoneyValue(stored, {"FilthyStack"}, false) or findMoneyValue(stored, dN, false)
        or findMoneyValue(LocalPlayer, dN, false) or findMoneyValue(LocalPlayer, dN, true)
    return clean, dirty
end
local function getBankValue2()
    local stored = LocalPlayer:FindFirstChild("stored")
    local leader = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("stats")
    return findMoneyValue(stored, {"Bank"}, false) or findMoneyValue(leader, {"Bank"}, false)
        or findMoneyValue(LocalPlayer, {"Bank"}, true)
end
local function formatMoney(amount)
    local formatted = tostring(math.floor(tonumber(amount) or 0))
    while true do
        local newFormatted, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        formatted = newFormatted
        if count == 0 then break end
    end
    return "$" .. formatted
end

local lastClean = nil
task.spawn(function()
    while task.wait(0.3) do
        local c, d = getMyMoneyValues()
        local b = getBankValue2()
        if lastClean ~= nil and c ~= nil then
            local delta = c - lastClean
            if delta > 0 then getgenv().MoneyMadeTotal = getgenv().MoneyMadeTotal + delta
            elseif delta < 0 then getgenv().MoneyLostTotal = getgenv().MoneyLostTotal + (-delta) end
        end
        lastClean = c
        pcall(function()
            myClean:SetText("Clean Money: " .. (c ~= nil and formatMoney(c) or "None"))
            myBank:SetText("Bank: " .. (b ~= nil and formatMoney(b) or "None"))
            myDirty:SetText("Dirty Money: " .. (d ~= nil and formatMoney(d) or "None"))
            myMade:SetText("Money Made: " .. formatMoney(getgenv().MoneyMadeTotal))
            myLost:SetText("Money Lost: " .. formatMoney(getgenv().MoneyLostTotal))
        end)
    end
end)

local g = tabSettings:AddGroup("Head Tag")
getgenv().MiamiHeadTagSettings = {
    Enabled = true, Text = "discord.gg/tacoscripts", Size = 32, Height = 3.4,
    Style = "Taco Green", Font = "GothamBlack", Color = "Gold",
    Rainbow = false, Pulse = true, Speed = 8,
}
local HeadTagSettings = getgenv().MiamiHeadTagSettings

g:AddToggle("aqxHeadTag", { Text = "Enable Head Text", Default = true, Callback = function(v) HeadTagSettings.Enabled = v end })
g:AddInput("aqxHeadText", { Text = "Text", Default = HeadTagSettings.Text, Callback = function(v)
    HeadTagSettings.Text = tostring(v) ~= "" and tostring(v) or "discord.gg/tacoscripts"
end })
g:AddDropdown("aqxHeadStyle", { Text = "Animation",
    Values = {"Taco Green","Taco Wave","Rainbow Wave","Fire","Ice","Toxic","Royal"},
    Default = "Taco Green", Callback = function(v) HeadTagSettings.Style = tostring(v) end })
g:AddDropdown("aqxHeadFont", { Text = "Font",
    Values = {"GothamBlack","GothamBold","Arcade","SciFi","Cartoon","Code"},
    Default = "GothamBlack", Callback = function(v) HeadTagSettings.Font = tostring(v) end })
g:AddDropdown("aqxHeadColor", { Text = "Text Color",
    Values = {"Gold","White","Orange","Red","Green","Blue","Purple","Pink","Cyan","Use Animation"},
    Default = "Gold", Callback = function(v) HeadTagSettings.Color = tostring(v) end })
g:AddToggle("aqxHeadRainbow", { Text = "Rainbow Override", Default = false, Callback = function(v) HeadTagSettings.Rainbow = v end })
g:AddToggle("aqxHeadPulse", { Text = "Text Pulse", Default = true, Callback = function(v) HeadTagSettings.Pulse = v end })
g:AddSlider("aqxHeadSize", { Text = "Text Size", Min = 18, Max = 52, Default = 32,
    Callback = function(v) HeadTagSettings.Size = v end })
g:AddSlider("aqxHeadHeight", { Text = "Height", Min = 2, Max = 7, Default = 3.4,
    Callback = function(v) HeadTagSettings.Height = v end })
g:AddSlider("aqxHeadSpeed", { Text = "Movement Speed", Min = 1, Max = 20, Default = 8,
    Callback = function(v) HeadTagSettings.Speed = v end })

local g = tabSettings:AddGroup("Menu")
g:AddButton("Unload UI", function()
    for _, fn in ipairs(_unloadCallbacks) do pcall(fn) end
    gui:Destroy()
end)
g:AddButton("Rejoin Server", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
end)
g:AddButton("Server Hop", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BENZZY420/SERVERHOP/refs/heads/main/SERVERHOP"))()
end)
g:AddButton("Copy Discord", function()
    if setclipboard then setclipboard("https://discord.gg/tacoscripts") end
    notify("Discord", "Copied discord.gg/tacoscripts")
end)

--------------------------------------------------------------------
-- HEAD TAG LOOP
--------------------------------------------------------------------
task.spawn(function()
    local Palettes = {
        ["Taco Wave"] = {Color3.fromRGB(255,198,48), Color3.fromRGB(255,236,143), Color3.fromRGB(255,155,40)},
        ["Taco Green"] = {Color3.fromRGB(255,198,48), Color3.fromRGB(255,236,143), Color3.fromRGB(255,198,48)},
        ["Fire"] = {Color3.fromRGB(255,30,0), Color3.fromRGB(255,225,0), Color3.fromRGB(255,80,0)},
        ["Ice"] = {Color3.fromRGB(0,125,255), Color3.fromRGB(245,255,255), Color3.fromRGB(0,255,235)},
        ["Toxic"] = {Color3.fromRGB(40,255,0), Color3.fromRGB(220,255,0), Color3.fromRGB(0,145,55)},
        ["Royal"] = {Color3.fromRGB(115,0,255), Color3.fromRGB(255,210,45), Color3.fromRGB(220,0,255)},
    }
    local Fonts = {
        GothamBlack=Enum.Font.GothamBlack, GothamBold=Enum.Font.GothamBold,
        Arcade=Enum.Font.Arcade, SciFi=Enum.Font.SciFi, Cartoon=Enum.Font.Cartoon, Code=Enum.Font.Code,
    }
    local HeadTagColors = {
        Gold = Color3.fromRGB(55,235,120), White = Color3.fromRGB(255,255,255),
        Orange = Color3.fromRGB(255,138,45), Red = Color3.fromRGB(255,70,76),
        Green = Color3.fromRGB(56,232,130), Blue = Color3.fromRGB(70,151,255),
        Purple = Color3.fromRGB(172,100,255), Pink = Color3.fromRGB(255,105,185),
        Cyan = Color3.fromRGB(54,236,255),
    }
    local function destroyHeadTag(character)
        local head = character and character:FindFirstChild("Head")
        local tag = head and head:FindFirstChild("aqx_HeadTag")
        if tag then tag:Destroy() end
    end
    local function attachHeadTag(character)
        local settings = getgenv().MiamiHeadTagSettings or {}
        if not settings.Enabled then destroyHeadTag(character); return end
        pcall(function()
            local head = character and character:WaitForChild("Head", 5)
            if not head then return end
            destroyHeadTag(character)
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "aqx_HeadTag"
            billboard.Parent = head
            billboard.Adornee = head
            billboard.Size = UDim2.fromOffset(480, 70)
            billboard.StudsOffset = Vector3.new(0, settings.Height or 3.4, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 700
            billboard.LightInfluence = 0
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.fromScale(1, 1)
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
            label.TextStrokeTransparency = 0.08
            label.Parent = billboard
            local gradient = Instance.new("UIGradient")
            gradient.Parent = label
            local timeValue = 0
            while label.Parent do
                local current = getgenv().MiamiHeadTagSettings or {}
                local text = tostring(current.Text or "discord.gg/tacoscripts")
                local size = tonumber(current.Size) or 32
                local speed = tonumber(current.Speed) or 8
                local style = current.Style or "Taco Green"
                timeValue = timeValue + 0.003 * speed
                local sequence
                local selectedColor = HeadTagColors[current.Color or "Gold"]
                if current.Rainbow or style == "Rainbow Wave" then
                    local hue = timeValue % 1
                    sequence = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(hue,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue+0.25)%1,1,1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV((hue+0.5)%1,1,1)),
                    }
                elseif selectedColor and current.Color ~= "Use Animation" then
                    local highlight = selectedColor:Lerp(Color3.fromRGB(255,255,255), 0.30)
                    sequence = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, selectedColor),
                        ColorSequenceKeypoint.new(0.5, highlight),
                        ColorSequenceKeypoint.new(1, selectedColor),
                    }
                else
                    local colors = Palettes[style] or Palettes["Taco Green"]
                    sequence = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, colors[1]),
                        ColorSequenceKeypoint.new(0.5, colors[2]),
                        ColorSequenceKeypoint.new(1, colors[3]),
                    }
                end
                label.Text = text
                label.TextSize = size
                label.Font = Fonts[current.Font or "GothamBlack"] or Enum.Font.GothamBlack
                billboard.StudsOffset = Vector3.new(0, tonumber(current.Height) or 3.4, 0)
                billboard.Size = UDim2.fromOffset(math.clamp(#text * size * 0.66 + 50, 300, 700), size + 38)
                gradient.Color = sequence
                gradient.Offset = Vector2.new(math.sin(timeValue * math.pi * 2) * 0.48, 0)
                gradient.Rotation = math.sin(timeValue * math.pi) * 18
                if current.Pulse then
                    label.TextSize = size + math.sin(timeValue * math.pi * 2) * 1.5
                end
                task.wait(0.03)
            end
        end)
    end
    if LocalPlayer.Character then task.defer(attachHeadTag, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(attachHeadTag)
end)

--------------------------------------------------------------------
-- READY
--------------------------------------------------------------------
task.delay(2, function() getgenv().MiamiSuppressNotifications = false end)

notify("aqx", "Loaded. Tap the side button to minimize.", 4)
print("[aqx] loaded — full port")
