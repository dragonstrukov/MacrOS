--[[
    MacrOS UI
    ===================================================================
    Reusable Roblox UI library — the "pasta" interface from ui.txt,
    turned into a real library with a tab system.

    Load it:
        local Lib = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/dragonstrukov/MacrOS/refs/heads/main/lib/macros-ui.lua"
        ))()

    Build a window:
        local Window = Lib:CreateWindow({ Title = "MacrOS", Icon = "ship" })
        local Tab    = Window:CreateTab({ Title = "Combat", Icon = "zap" })
        local Card   = Tab:CreateSection({ Title = "Fighting" })

        Card:CreateToggle({ Title = "Aimbot", Desc = "helps to focus", Callback = print })

    The library returns its own table, so it can be re-exported, cached on
    disk, or embedded into another script.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Lib = {}
Lib.Name = "MacrOS UI"
Lib.Version = "1.0.0"

--------------------------------------------------------------------------------
-- small helpers
--------------------------------------------------------------------------------

local function make(className, props)
    local inst = Instance.new(className)
    if props then
        for key, value in pairs(props) do
            inst[key] = value
        end
    end
    return inst
end

local function round(n)
    return math.floor(n + 0.5)
end

local function copyTable(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = value
    end
    return out
end

local function clampNumber(value, minValue, maxValue)
    return math.clamp(tonumber(value) or minValue, minValue, maxValue)
end

local function indexOf(list, value)
    for index = 1, #list do
        if list[index] == value then
            return index
        end
    end
    return nil
end

-- Resolves the GUI host the same way ui.txt does: the executor's own layer
-- first, CoreGui as the fallback so the menu survives respawns.
local function resolveParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end
    return CoreGui
end

--------------------------------------------------------------------------------
-- themes  (live — every painted instance is registered and re-coloured on switch)
--------------------------------------------------------------------------------

Lib.Themes = {
    Pasta = {
        Name = "Pasta",
        Background = Color3.fromRGB(12, 9, 11),
        CardBg = Color3.fromRGB(18, 13, 16),
        PillBg = Color3.fromRGB(16, 12, 14),
        SidebarActive = Color3.fromRGB(27, 16, 19),
        Border = Color3.fromRGB(36, 24, 28),
        BorderActive = Color3.fromRGB(90, 36, 42),
        Accent = Color3.fromRGB(246, 92, 82),
        AccentSoft = Color3.fromRGB(255, 165, 155),
        TextPrimary = Color3.fromRGB(235, 235, 235),
        TextMuted = Color3.fromRGB(120, 110, 115),
        TextDim = Color3.fromRGB(72, 64, 68),
        Divider = Color3.fromRGB(48, 36, 40),
        BadgeBg = Color3.fromRGB(25, 18, 22),
        ToggleOff = Color3.fromRGB(36, 28, 32),
        KnobOff = Color3.fromRGB(78, 68, 73),
        KnobOn = Color3.fromRGB(255, 255, 255),
        VersionBg = Color3.fromRGB(70, 90, 180),
        VersionText = Color3.fromRGB(220, 225, 245),
        PopupBg = Color3.fromRGB(24, 18, 20),
    },
    Midnight = {
        Name = "Midnight",
        Background = Color3.fromRGB(10, 12, 18),
        CardBg = Color3.fromRGB(16, 19, 27),
        PillBg = Color3.fromRGB(14, 17, 24),
        SidebarActive = Color3.fromRGB(23, 28, 40),
        Border = Color3.fromRGB(32, 38, 54),
        BorderActive = Color3.fromRGB(60, 110, 190),
        Accent = Color3.fromRGB(88, 152, 255),
        AccentSoft = Color3.fromRGB(170, 200, 255),
        TextPrimary = Color3.fromRGB(232, 236, 245),
        TextMuted = Color3.fromRGB(116, 126, 148),
        TextDim = Color3.fromRGB(68, 76, 94),
        Divider = Color3.fromRGB(44, 51, 68),
        BadgeBg = Color3.fromRGB(22, 26, 36),
        ToggleOff = Color3.fromRGB(38, 44, 60),
        KnobOff = Color3.fromRGB(84, 94, 116),
        KnobOn = Color3.fromRGB(255, 255, 255),
        VersionBg = Color3.fromRGB(60, 92, 170),
        VersionText = Color3.fromRGB(222, 230, 248),
        PopupBg = Color3.fromRGB(22, 26, 36),
    },
    Frost = {
        Name = "Frost",
        Background = Color3.fromRGB(236, 240, 246),
        CardBg = Color3.fromRGB(255, 255, 255),
        PillBg = Color3.fromRGB(245, 247, 252),
        SidebarActive = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(214, 220, 232),
        BorderActive = Color3.fromRGB(120, 155, 220),
        Accent = Color3.fromRGB(66, 133, 244),
        AccentSoft = Color3.fromRGB(150, 190, 255),
        TextPrimary = Color3.fromRGB(28, 33, 44),
        TextMuted = Color3.fromRGB(110, 120, 138),
        TextDim = Color3.fromRGB(155, 164, 180),
        Divider = Color3.fromRGB(226, 231, 240),
        BadgeBg = Color3.fromRGB(242, 245, 250),
        ToggleOff = Color3.fromRGB(206, 213, 226),
        KnobOff = Color3.fromRGB(140, 150, 168),
        KnobOn = Color3.fromRGB(255, 255, 255),
        VersionBg = Color3.fromRGB(96, 128, 200),
        VersionText = Color3.fromRGB(240, 244, 255),
        PopupBg = Color3.fromRGB(250, 251, 254),
    },
    Toxic = {
        Name = "Toxic",
        Background = Color3.fromRGB(10, 14, 10),
        CardBg = Color3.fromRGB(15, 21, 15),
        PillBg = Color3.fromRGB(13, 18, 13),
        SidebarActive = Color3.fromRGB(21, 32, 21),
        Border = Color3.fromRGB(28, 44, 28),
        BorderActive = Color3.fromRGB(48, 120, 52),
        Accent = Color3.fromRGB(126, 232, 84),
        AccentSoft = Color3.fromRGB(198, 255, 178),
        TextPrimary = Color3.fromRGB(232, 240, 230),
        TextMuted = Color3.fromRGB(112, 130, 110),
        TextDim = Color3.fromRGB(66, 80, 64),
        Divider = Color3.fromRGB(38, 54, 38),
        BadgeBg = Color3.fromRGB(19, 26, 19),
        ToggleOff = Color3.fromRGB(34, 48, 34),
        KnobOff = Color3.fromRGB(80, 96, 78),
        KnobOn = Color3.fromRGB(255, 255, 255),
        VersionBg = Color3.fromRGB(56, 104, 140),
        VersionText = Color3.fromRGB(220, 240, 252),
        PopupBg = Color3.fromRGB(19, 26, 19),
    },
}

local ThemeOrder = { "Pasta", "Midnight", "Frost", "Toxic" }
local Theme = Lib.Themes.Pasta
Lib.Theme = Theme

--------------------------------------------------------------------------------
-- paint registry — lets SetTheme recolour a live menu instead of a rebuild
--------------------------------------------------------------------------------

local paintRegistry = setmetatable({}, { __mode = "k" })

local function paint(inst, key, prop)
    if not inst or not inst.Parent then
        return
    end
    local value = Theme[key]
    if value == nil then
        inst[prop] = value
        return
    end
    inst[prop] = value
    paintRegistry[inst] = { Key = key, Prop = prop }
end

local function applyTheme()
    for inst, info in pairs(paintRegistry) do
        if inst.Parent then
            local value = Theme[info.Key]
            if value ~= nil then
                inst[info.Prop] = value
            end
        else
            paintRegistry[inst] = nil
        end
    end
end

function Lib:GetThemes()
    local names = {}
    for _, name in ipairs(ThemeOrder) do
        names[#names + 1] = name
    end
    return names, names
end

function Lib:SetTheme(name)
    local chosen = Lib.Themes[name]
    if not chosen then
        return false
    end
    Theme = chosen
    Lib.Theme = Theme
    applyTheme()
    return true
end

--------------------------------------------------------------------------------
-- icons
--------------------------------------------------------------------------------

-- Monochrome vector set shipped with the original ui.txt.
Lib.Icons = {
    Search = "rbxassetid://7733911828",
    Chevron = "rbxassetid://7733717447",
    Menu = "rbxassetid://7733993211",
    Combat = "rbxassetid://7734053426",
    Movement = "rbxassetid://7733799901",
    Visuals = "rbxassetid://7733774602",
    Player = "rbxassetid://7733954760",
    Misc = "rbxassetid://7734056411",
    Presets = "rbxassetid://7733964719",
    AutoBuy = "rbxassetid://7733942651",
    Accounts = "rbxassetid://7733765307",
    User = "rbxassetid://7733954760",
    Chart = "rbxassetid://7733749837",
    Clock = "rbxassetid://7733734762",
    Compass = "rbxassetid://7733720755",
    Signal = "rbxassetid://7734058495",
    Radar = "rbxassetid://7734053426",
    Speed = "rbxassetid://7733799901",
}

-- Lucide names used by the script (aimbot / eye / zap / ghost / cog / ...).
Lib.Lucide = {
    ["activity"] = "rbxassetid://94212016861936",
    ["alert-triangle"] = "rbxassetid://125920361880643",
    ["balloon"] = "rbxassetid://97489111621526",
    ["blocks"] = "rbxassetid://72212693357737",
    ["book"] = "rbxassetid://125383279695672",
    ["bot"] = "rbxassetid://80451686744860",
    ["box"] = "rbxassetid://101768155599700",
    ["check"] = "rbxassetid://93898873302694",
    ["chevron-down"] = "rbxassetid://134243273101015",
    ["chevron-right"] = "rbxassetid://92473583511724",
    ["chevron-up"] = "rbxassetid://122444883127455",
    ["circle"] = "rbxassetid://130359823580534",
    ["circle-check"] = "rbxassetid://85262178816537",
    ["clipboard"] = "rbxassetid://89601995828423",
    ["clipboard-paste"] = "rbxassetid://74382068849983",
    ["clock"] = "rbxassetid://121808839832144",
    ["cloud"] = "rbxassetid://121226497050352",
    ["cog"] = "rbxassetid://116544501716299",
    ["coins"] = "rbxassetid://116510979641930",
    ["copy"] = "rbxassetid://78979572434545",
    ["crown"] = "rbxassetid://127843403295538",
    ["download"] = "rbxassetid://134814648082393",
    ["ellipsis-vertical"] = "rbxassetid://117978708573781",
    ["ethernet-port"] = "rbxassetid://75391715149314",
    ["eye"] = "rbxassetid://100033680381365",
    ["eye-off"] = "rbxassetid://135928786788378",
    ["flask-conical"] = "rbxassetid://128406680901165",
    ["folder-open"] = "rbxassetid://76018996254888",
    ["gauge"] = "rbxassetid://110273524101447",
    ["gem"] = "rbxassetid://112904952151156",
    ["ghost"] = "rbxassetid://113822048130017",
    ["gift"] = "rbxassetid://109855212076373",
    ["grip"] = "rbxassetid://109058783556768",
    ["hammer"] = "rbxassetid://83545120140895",
    ["hand"] = "rbxassetid://130703864968637",
    ["house"] = "rbxassetid://98755624629571",
    ["image"] = "rbxassetid://112751259236831",
    ["infinity"] = "rbxassetid://98083086936965",
    ["info"] = "rbxassetid://124560466474914",
    ["keyboard"] = "rbxassetid://121474456068237",
    ["languages"] = "rbxassetid://90816903776498",
    ["layers"] = "rbxassetid://81973586053257",
    ["list-checks"] = "rbxassetid://99809353635593",
    ["loader-circle"] = "rbxassetid://116535712789945",
    ["lock"] = "rbxassetid://134724289526879",
    ["log-out"] = "rbxassetid://84895399304975",
    ["map-pin"] = "rbxassetid://84279202219901",
    ["menu"] = "rbxassetid://77021539815611",
    ["message-circle"] = "rbxassetid://127255077587058",
    ["message-square"] = "rbxassetid://83881670383280",
    ["minus"] = "rbxassetid://118026365011536",
    ["monitor"] = "rbxassetid://72664649203050",
    ["move"] = "rbxassetid://116138709011735",
    ["package"] = "rbxassetid://97261141732706",
    ["palette"] = "rbxassetid://86350350950064",
    ["pause"] = "rbxassetid://74873705394436",
    ["play"] = "rbxassetid://135609604299893",
    ["plus"] = "rbxassetid://111774323017047",
    ["power"] = "rbxassetid://96479131758775",
    ["refresh-cw"] = "rbxassetid://138133190015277",
    ["repeat"] = "rbxassetid://121886242955173",
    ["rotate-ccw"] = "rbxassetid://110116685948665",
    ["rotate-cw"] = "rbxassetid://84183336178654",
    ["save"] = "rbxassetid://126116963775616",
    ["scroll-text"] = "rbxassetid://97321022666868",
    ["search"] = "rbxassetid://121018724060431",
    ["send"] = "rbxassetid://127751956873796",
    ["settings"] = "rbxassetid://80758916183665",
    ["shapes"] = "rbxassetid://129989433311409",
    ["ship"] = "rbxassetid://83995100553930",
    ["shopping-bag"] = "rbxassetid://71885477293226",
    ["shopping-cart"] = "rbxassetid://128420521375441",
    ["shuffle"] = "rbxassetid://132382786975101",
    ["skull"] = "rbxassetid://137726256442333",
    ["square"] = "rbxassetid://86304921356806",
    ["store"] = "rbxassetid://90338129673705",
    ["tag"] = "rbxassetid://129104970103940",
    ["trash-2"] = "rbxassetid://109843431391323",
    ["triangle-alert"] = "rbxassetid://125920361880643",
    ["type"] = "rbxassetid://133543553793564",
    ["user"] = "rbxassetid://81589895647169",
    ["users"] = "rbxassetid://115398113982385",
    ["webhook"] = "rbxassetid://112812457747322",
    ["wind"] = "rbxassetid://114551690399915",
    ["wrench"] = "rbxassetid://112148279212860",
    ["x"] = "rbxassetid://110786993356448",
    ["zap"] = "rbxassetid://130551565616516",
}

-- Accepts a lucide name, an "rbxassetid://" url or nil.
function Lib:GetIcon(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if name:sub(1, 13) == "rbxassetid://" then
        return name
    end
    if Lib.Icons[name] then
        return Lib.Icons[name]
    end
    return Lib.Lucide[name]
end

--------------------------------------------------------------------------------
-- popups (dropdown / colour / slider edit) — one open at a time per screen gui
--------------------------------------------------------------------------------

local PopupManager = {}
PopupManager.__index = PopupManager

function PopupManager.new(gui)
    return setmetatable({ Gui = gui, Items = {} }, PopupManager)
end

function PopupManager:closeAll(except)
    for _, popup in ipairs(self.Items) do
        if popup ~= except and popup.Parent then
            popup:Destroy()
        end
    end
    if except then
        self.Items = { except }
    else
        self.Items = {}
    end
end

function PopupManager:track(popup)
    self.Items[#self.Items + 1] = popup
    popup.Destroying:Connect(function()
        local index = indexOf(self.Items, popup)
        if index then
            table.remove(self.Items, index)
        end
    end)
end

-- Clicking anywhere outside an open popup closes it.
function PopupManager:bindDismiss()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if #self.Items == 0 then
            return
        end

        local mouse = UserInputService:GetMouseLocation()
        for _, popup in ipairs(self.Items) do
            if popup.Parent then
                local position = popup.AbsolutePosition
                local size = popup.AbsoluteSize
                local inside = mouse.X >= position.X
                    and mouse.X <= position.X + size.X
                    and mouse.Y >= position.Y
                    and mouse.Y <= position.Y + size.Y
                if inside then
                    return
                end
            end
        end

        self:closeAll()
    end)
end

--------------------------------------------------------------------------------
-- drag helper — shared by the window and every slider
--------------------------------------------------------------------------------

-- onDelta(delta, startValue) — delta is measured from the press point, so it
-- stays correct even when the thing being dragged moves during the drag.
local function makeDraggable(handle, onDelta, onStart, onEnd)
    local dragging = false
    local origin, startValue

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            origin = input.Position
            startValue = onStart and onStart() or nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            onDelta(input.Position - origin, startValue)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            startValue = nil
            if onEnd then
                onEnd()
            end
        end
    end)

    return function()
        dragging = false
    end
end

--------------------------------------------------------------------------------
-- element base — every widget returned to the user shares this shape
--------------------------------------------------------------------------------

local Element = {}
Element.__index = Element

local function newElement(kind, window)
    return setmetatable({
        Kind = kind,
        _window = window,
        Visible = true,
        _destroyed = false,
    }, Element)
end

function Element:SetVisible(state)
    self.Visible = state ~= false
    if self._frame then
        self._frame.Visible = self.Visible
    end
    return self
end

function Element:GetVisible()
    return self.Visible
end

function Element:SetTitle(title)
    self.Title = title
    if self._titleLabel then
        self._titleLabel.Text = tostring(title)
    end
    return self
end

function Element:SetDesc(desc)
    self.Desc = desc
    if self._descLabel then
        self._descLabel.Text = tostring(desc)
        self._descLabel.Visible = desc ~= nil
    end
    return self
end

function Element:Destroy()
    self._destroyed = true
    if self._frame then
        self._frame:Destroy()
    end
    if self._searchable and self._window then
        local index = indexOf(self._window._rows, self)
        if index then
            table.remove(self._window._rows, index)
        end
    end
    return self
end

--------------------------------------------------------------------------------
-- shared widget internals
--------------------------------------------------------------------------------

local function roundCorners(inst, radius)
    local corner = make("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
    corner.Parent = inst
    return corner
end

local function addStroke(inst, key, thickness, transparency)
    local stroke = make("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    stroke.Parent = inst
    paint(stroke, key or "Border", "Color")
    return stroke
end

-- A row = title (+ optional description) with a widget pinned to the right.
local function makeRow(parent, element, title, desc, height, searchable)
    local row = make("Frame", {
        Name = tostring(title),
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        LayoutOrder = element._order,
    })
    row.Parent = parent
    element._frame = row

    local textWidth = desc and 30 or 40

    local textColumn = make("Frame", {
        Size = UDim2.new(1, -textWidth, 1, 0),
        BackgroundTransparency = 1,
    })
    textColumn.Parent = row
    element._textColumn = textColumn

    local titleLabel = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = tostring(title or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    titleLabel.Parent = textColumn
    paint(titleLabel, "TextPrimary", "TextColor3")
    element._titleLabel = titleLabel

    if desc then
        local descLabel = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = tostring(desc),
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        descLabel.Parent = textColumn
        paint(descLabel, "TextMuted", "TextColor3")
        element._descLabel = descLabel
    end

    if searchable ~= false and element._window then
        element._searchable = true
        element._searchText = (tostring(title or "") .. " " .. tostring(desc or "")):lower()
        table.insert(element._window._rows, element)
    end

    return row
end

--------------------------------------------------------------------------------
-- components
--------------------------------------------------------------------------------

local Components = {}

-- TOGGLE ----------------------------------------------------------------------
function Components.Toggle(parent, order, config)
    config = config or {}
    local element = newElement("Toggle", config._window)
    element._order = order
    element.Default = config.Default == true
    element.Title = config.Title

    local row = makeRow(parent, element, config.Title, config.Desc, config.Desc and 30 or 21)

    local switch = make("TextButton", {
        Size = UDim2.new(0, 32, 0, 16),
        Position = UDim2.new(1, -32, 0.5, -8),
        Text = "",
        AutoButtonColor = false,
    })
    switch.Parent = row
    roundCorners(switch, 8)
    paint(switch, element.Default and "Accent" or "ToggleOff", "BackgroundColor3")
    element._switch = switch

    local knob = make("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = element.Default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BorderSizePixel = 0,
    })
    knob.Parent = switch
    roundCorners(knob, 6)
    paint(knob, element.Default and "KnobOn" or "KnobOff", "BackgroundColor3")
    element._knob = knob

    local value = element.Default

    local function apply(next, fire)
        value = next
        TweenService:Create(switch, Element.TweenFast, {
            BackgroundColor3 = Theme[value and "Accent" or "ToggleOff"],
        }):Play()
        TweenService:Create(knob, Element.TweenFast, {
            BackgroundColor3 = Theme[value and "KnobOn" or "KnobOff"],
            Position = value and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        }):Play()
        paint(switch, value and "Accent" or "ToggleOff", "BackgroundColor3")
        paint(knob, value and "KnobOn" or "KnobOff", "BackgroundColor3")
        if fire and config.Callback then
            config.Callback(value)
        end
    end

    function element:SetValue(next, fire)
        apply(next == true, fire ~= false)
        return element
    end

    function element:GetValue()
        return value
    end

    switch.MouseButton1Click:Connect(function()
        apply(not value, true)
    end)

    element._apply = apply
    return element
end

-- BUTTON ----------------------------------------------------------------------
function Components.Button(parent, order, config)
    config = config or {}
    local element = newElement("Button", config._window)
    element._order = order
    element.Title = config.Title

    local width = config.Width
    local widthScale, widthOffset = 1, 0
    if type(width) == "table" then
        widthScale, widthOffset = width[1], width[2]
    elseif type(width) == "number" then
        widthScale, widthOffset = 0, width
    end

    local button = make("TextButton", {
        Size = UDim2.new(widthScale, widthOffset, 0, 22),
        Text = tostring(config.Title or ""),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 10.5,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Theme.Accent,
    })
    button.Parent = parent
    roundCorners(button, 5)
    paint(button, "Accent", "BackgroundColor3")
    element._frame = button
    element._button = button

    button.MouseButton1Click:Connect(function()
        if config.Callback then
            config.Callback(button)
        end
    end)

    return element
end

-- INPUT -----------------------------------------------------------------------
function Components.Input(parent, order, config)
    config = config or {}
    local element = newElement("Input", config._window)
    element._order = order
    element.Title = config.Title
    element.Default = config.Default or ""
    element.Placeholder = config.Placeholder or ""

    local row = makeRow(parent, element, config.Title, config.Desc, 35)

    local box = make("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 17),
        BackgroundColor3 = Theme.BadgeBg,
        BorderSizePixel = 0,
    })
    box.Parent = row
    roundCorners(box, 4)
    addStroke(box, "Border", 0.8)
    paint(box, "BadgeBg", "BackgroundColor3")

    local boxInput = make("TextBox", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(element.Default),
        PlaceholderText = element.Placeholder,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })
    boxInput.Parent = box
    paint(boxInput, "TextPrimary", "TextColor3")
    paint(boxInput, "TextDim", "PlaceholderColor3")
    element._box = boxInput

    boxInput.FocusLost:Connect(function(enterPressed)
        local next = boxInput.Text
        if next == element.Default then
            return
        end
        element.Default = next
        if config.Callback then
            config.Callback(next, enterPressed)
        end
    end)

    function element:SetValue(next, fire)
        element.Default = tostring(next)
        boxInput.Text = element.Default
        if fire and config.Callback then
            config.Callback(element.Default)
        end
        return element
    end

    function element:GetValue()
        return boxInput.Text
    end

    return element
end

-- SLIDER ----------------------------------------------------------------------
function Components.Slider(parent, order, config)
    config = config or {}
    local element = newElement("Slider", config._window)
    element._order = order
    element.Title = config.Title

    local minValue = tonumber(config.Min) or 0
    local maxValue = tonumber(config.Max) or 100
    local decimals = tonumber(config.Decimals) or 0
    local step = tonumber(config.Step) or 0
    local defaultValue = tonumber(config.Default) or minValue

    if maxValue <= minValue then
        maxValue = minValue + 1
    end

    local row = makeRow(parent, element, config.Title, config.Desc, 35)

    local header = make("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
    })
    header.Parent = row

    local titleLabel = make("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    titleLabel.Parent = header
    paint(titleLabel, "TextPrimary", "TextColor3")
    element._titleLabel = titleLabel

    local valueButton = make("TextButton", {
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        Text = string.format("%." .. decimals .. "f", defaultValue),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        AutoButtonColor = false,
    })
    valueButton.Parent = header
    paint(valueButton, "Accent", "TextColor3")
    element._valueButton = valueButton

    local track = make("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
    })
    track.Parent = row
    roundCorners(track, 3)
    paint(track, "ToggleOff", "BackgroundColor3")

    local fill = make("Frame", {
        Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    })
    fill.Parent = track
    roundCorners(fill, 3)
    paint(fill, "Accent", "BackgroundColor3")

    local value = defaultValue

    local function quantise(number)
        if step > 0 then
            number = minValue + math.floor((number - minValue) / step + 0.5) * step
        end
        return math.clamp(number, minValue, maxValue)
    end

    local function apply(next, fire)
        value = quantise(next)
        fill.Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0)
        valueButton.Text = string.format("%." .. decimals .. "f", value)
        if fire and config.Callback then
            config.Callback(value)
        end
    end

    local function updateFromX(x)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        apply(minValue + (maxValue - minValue) * ratio, true)
    end

    makeDraggable(track, function(delta)
        updateFromX(track.AbsolutePosition.X + delta.X)
    end)

    -- click the number to type an exact value
    valueButton.MouseButton1Click:Connect(function()
        local gui = config._window._gui
        if not gui then
            return
        end
        config._window._popups:closeAll()

        local box = make("Frame", {
            Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.fromOffset(
                valueButton.AbsolutePosition.X + valueButton.AbsoluteSize.X - 60,
                valueButton.AbsolutePosition.Y - 2
            ),
            BackgroundColor3 = Theme.PopupBg,
            BorderSizePixel = 0,
            ZIndex = 100,
        })
        box.Parent = gui
        roundCorners(box, 4)
        addStroke(box, "Border", 0.8)
        paint(box, "PopupBg", "BackgroundColor3")

        local edit = make("TextBox", {
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(value),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
            ClearTextOnFocus = false,
            ZIndex = 101,
        })
        edit.Parent = box
        paint(edit, "Accent", "TextColor3")

        config._window._popups:track(box)
        edit:CaptureFocus()

        edit.FocusLost:Connect(function()
            local number = tonumber(edit.Text)
            if number then
                apply(number, true)
            end
            box:Destroy()
        end)
    end)

    function element:SetValue(next, fire)
        apply(tonumber(next) or minValue, fire ~= false)
        return element
    end

    function element:GetValue()
        return value
    end

    return element
end

-- KEYBIND ---------------------------------------------------------------------
function Components.Keybind(parent, order, config)
    config = config or {}
    local element = newElement("Keybind", config._window)
    element._order = order
    element.Title = config.Title

    local defaultKey = config.Default or "None"
    local value = defaultKey

    local row = makeRow(parent, element, config.Title, config.Desc, 21, false)
    element._titleLabel.Position = UDim2.new(0, 0, 0, 0)
    element._titleLabel.Size = UDim2.new(1, -120, 1, 0)

    local badge = make("TextButton", {
        Size = UDim2.new(0, 50, 0, 16),
        Position = UDim2.new(1, -72, 0.5, -8),
        BackgroundColor3 = Theme.BadgeBg,
        Text = tostring(defaultKey),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Theme.TextMuted,
    })
    badge.Parent = row
    roundCorners(badge, 3)
    addStroke(badge, "Border", 0.8)
    paint(badge, "BadgeBg", "BackgroundColor3")
    paint(badge, "TextMuted", "TextColor3")
    element._badge = badge

    local reset = make("ImageButton", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(1, -18, 0.5, -7),
        BackgroundTransparency = 1,
        Image = Lib.Lucide["rotate-cw"],
    })
    reset.Parent = row
    paint(reset, "TextDim", "ImageColor3")

    reset.MouseEnter:Connect(function()
        TweenService:Create(reset, Element.TweenFast, { ImageColor3 = Theme.Accent }):Play()
    end)
    reset.MouseLeave:Connect(function()
        TweenService:Create(reset, Element.TweenFast, { ImageColor3 = Theme.TextDim }):Play()
        paint(reset, "TextDim", "ImageColor3")
    end)

    local listener

    local function stopListening()
        if listener then
            listener:Disconnect()
            listener = nil
        end
    end

    local function setKey(next, fire)
        stopListening()
        value = next
        badge.Text = tostring(next)
        paint(badge, "TextMuted", "TextColor3")
        if fire and config.Callback then
            config.Callback(next)
        end
    end

    function element:SetValue(next, fire)
        setKey(next, fire ~= false)
        return element
    end

    function element:GetValue()
        return value
    end

    reset.MouseButton1Click:Connect(function()
        setKey("None", true)
    end)

    badge.MouseButton1Click:Connect(function()
        if listener then
            setKey(defaultKey, false)
            return
        end
        badge.Text = "..."
        paint(badge, "Accent", "TextColor3")
        listener = UserInputService.InputBegan:Connect(function(input, processed)
            if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            local key = input.KeyCode.Name
            setKey(key == "Escape" and "None" or key, true)
        end)
    end)

    return element
end

-- LABEL / DIVIDER / PARAGRAPH --------------------------------------------------
function Components.Label(parent, order, text)
    local element = newElement("Label", nil)
    element._order = order

    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 9.5,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    label.Parent = parent
    paint(label, "TextDim", "TextColor3")
    element._frame = label

    return element
end

function Components.Divider(parent, order)
    local element = newElement("Divider", nil)
    element._order = order

    local divider = make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
    })
    divider.Parent = parent
    paint(divider, "Divider", "BackgroundColor3")
    element._frame = divider

    return element
end

function Components.Paragraph(parent, order, config)
    config = config or {}
    local element = newElement("Paragraph", nil)
    element._order = order

    local column = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    column.Parent = parent
    element._frame = column

    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = column

    if config.Title then
        local title = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = tostring(config.Title),
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
        })
        title.Parent = column
        paint(title, "TextPrimary", "TextColor3")
        element._titleLabel = title
    end

    if config.Content or config.Desc then
        local content = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = tostring(config.Content or config.Desc),
            Font = Enum.Font.Gotham,
            TextSize = 9.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 1,
        })
        content.Parent = column
        paint(content, "TextMuted", "TextColor3")
        element._descLabel = content
    end

    return element
end

-- DROPDOWN --------------------------------------------------------------------
local function normaliseOptions(values)
    local options = {}
    for _, entry in ipairs(values or {}) do
        if type(entry) == "table" then
            options[#options + 1] = {
                Title = entry.Title or entry.Text or entry.Name or "",
                Value = entry.Value,
                Icon = entry.Icon,
                Desc = entry.Desc or entry.Description,
            }
        else
            options[#options + 1] = { Title = tostring(entry), Value = entry }
        end
    end
    return options
end

function Components.Dropdown(parent, order, config)
    config = config or {}
    local element = newElement("Dropdown", config._window)
    element._order = order
    element.Title = config.Title

    local options = normaliseOptions(config.Values)
    local multi = config.Multi == true
    local selected = {}
    local popup = nil

    local row = makeRow(parent, element, config.Title, config.Desc, 35)
    local rowHeight = config.Desc and 49 or 35
    row.Size = UDim2.new(1, 0, 0, rowHeight)
    if config.Desc then
        element._textColumn.Size = UDim2.new(1, -40, 0, 14)
    end

    local select = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, config.Desc and 31 or 17),
        BackgroundColor3 = Theme.BadgeBg,
        Text = "",
        AutoButtonColor = false,
    })
    select.Parent = row
    roundCorners(select, 4)
    addStroke(select, "Border", 0.8)
    paint(select, "BadgeBg", "BackgroundColor3")
    element._select = select

    local selectIcon = make("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 6, 0.5, -6),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
    })
    selectIcon.Parent = select
    paint(selectIcon, "TextMuted", "ImageColor3")

    local valueLabel = make("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    valueLabel.Parent = select
    paint(valueLabel, "TextPrimary", "TextColor3")
    element._valueLabel = valueLabel

    local arrow = make("ImageLabel", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -14, 0.5, -5),
        BackgroundTransparency = 1,
        Image = Lib.Icons.Chevron,
    })
    arrow.Parent = select
    paint(arrow, "TextMuted", "ImageColor3")

    local function firstTitle(index)
        local option = options[index]
        return option and option.Title or ""
    end

    local function iconFor(index)
        local option = options[index]
        return option and Lib:GetIcon(option.Icon)
    end

    local function refreshDisplay()
        local picks = {}
        for index = 1, #options do
            if selected[index] then
                picks[#picks + 1] = index
            end
        end
        if #picks == 0 then
            valueLabel.Text = multi and "None" or (firstTitle(1) ~= "" and firstTitle(1) or "-")
            selectIcon.Visible = false
            valueLabel.Position = UDim2.new(0, 6, 0, 0)
            return
        end

        local first = picks[1]
        valueLabel.Text = multi and (function()
            local names = {}
            for _, index in ipairs(picks) do
                names[#names + 1] = options[index].Title
            end
            return table.concat(names, ", ")
        end)() or options[first].Title

        local icon = iconFor(first)
        selectIcon.Image = icon or ""
        selectIcon.Visible = icon ~= nil
        valueLabel.Position = UDim2.new(0, icon and 22 or 6, 0, 0)
    end

    -- apply the configured default
    local default = config.Default
    if multi and type(default) == "table" then
        for _, wanted in ipairs(default) do
            for index, option in ipairs(options) do
                if wanted == index or wanted == option.Value or wanted == option.Title then
                    selected[index] = true
                end
            end
        end
    elseif default ~= nil then
        for index, option in ipairs(options) do
            if default == index or default == option.Value or default == option.Title then
                selected[index] = true
                break
            end
        end
    end

    local function fireCallback()
        if not config.Callback then
            return
        end
        if multi then
            local picked = {}
            for index = 1, #options do
                if selected[index] then
                    picked[#picked + 1] = {
                        Title = options[index].Title,
                        Value = options[index].Value,
                        Icon = options[index].Icon,
                    }
                end
            end
            config.Callback(picked)
        else
            for index = 1, #options do
                if selected[index] then
                    local option = options[index]
                    config.Callback(option.Value ~= nil and option.Value or option.Title, index)
                    return
                end
            end
            config.Callback(nil)
        end
    end

    refreshDisplay()

    local function closePopup()
        if popup and popup.Parent then
            popup:Destroy()
        end
        popup = nil
    end

    local function openPopup()
        local gui = config._window._gui
        if not gui then
            return
        end
        config._window._popups:closeAll()

        popup = make("Frame", {
            Size = UDim2.new(0, math.max(select.AbsoluteSize.X, 120), 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(
                select.AbsolutePosition.X,
                select.AbsolutePosition.Y + select.AbsoluteSize.Y + 2
            ),
            BackgroundColor3 = Theme.PopupBg,
            BorderSizePixel = 0,
            ZIndex = 100,
        })
        popup.Parent = gui
        roundCorners(popup, 4)
        addStroke(popup, "Border", 0.8)
        paint(popup, "PopupBg", "BackgroundColor3")

        local listLayout = make("UIListLayout", {
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        listLayout.Parent = popup

        local listPadding = make("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
        })
        listPadding.Parent = popup

        for index, option in ipairs(options) do
            local rowButton = make("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 101,
                LayoutOrder = index,
            })
            rowButton.Parent = popup

            local optionIcon
            if option.Icon then
                optionIcon = make("ImageLabel", {
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(0, 4, 0.5, -6),
                    BackgroundTransparency = 1,
                    ScaleType = Enum.ScaleType.Fit,
                    Image = Lib:GetIcon(option.Icon) or "",
                    ZIndex = 102,
                })
                optionIcon.Parent = rowButton
                paint(optionIcon, selected[index] and "Accent" or "TextMuted", "ImageColor3")
            end

            local optionLabel = make("TextLabel", {
                Size = UDim2.new(1, option.Icon and -22 or -6, 1, 0),
                Position = UDim2.new(0, option.Icon and 22 or 6, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(option.Title),
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 102,
            })
            optionLabel.Parent = rowButton
            paint(optionLabel, selected[index] and "Accent" or "TextPrimary", "TextColor3")

            rowButton.MouseEnter:Connect(function()
                TweenService:Create(optionLabel, Element.TweenFast, { TextColor3 = Theme.Accent }):Play()
                if optionIcon then
                    TweenService:Create(optionIcon, Element.TweenFast, { ImageColor3 = Theme.Accent }):Play()
                end
            end)
            rowButton.MouseLeave:Connect(function()
                TweenService:Create(optionLabel, Element.TweenFast, {
                    TextColor3 = Theme[selected[index] and "Accent" or "TextPrimary"],
                }):Play()
                if optionIcon then
                    TweenService:Create(optionIcon, Element.TweenFast, {
                        ImageColor3 = Theme[selected[index] and "Accent" or "TextMuted"],
                    }):Play()
                end
            end)

            rowButton.MouseButton1Click:Connect(function()
                if multi then
                    selected[index] = not selected[index]
                    paint(optionLabel, selected[index] and "Accent" or "TextPrimary", "TextColor3")
                    if optionIcon then
                        paint(optionIcon, selected[index] and "Accent" or "TextMuted", "ImageColor3")
                    end
                    refreshDisplay()
                    fireCallback()
                else
                    selected = { [index] = true }
                    refreshDisplay()
                    closePopup()
                    fireCallback()
                end
            end)
        end

        config._window._popups:track(popup)
    end

    select.MouseButton1Click:Connect(function()
        if popup and popup.Parent then
            closePopup()
        else
            openPopup()
        end
    end)

    function element:SetValue(next, fire)
        selected = {}
        if next == nil then
            refreshDisplay()
            return element
        end
        local wanted = type(next) == "table" and next or { next }
        for _, target in ipairs(wanted) do
            for index, option in ipairs(options) do
                if target == index or target == option.Value or target == option.Title then
                    selected[index] = true
                    break
                end
            end
        end
        refreshDisplay()
        if fire then
            fireCallback()
        end
        return element
    end

    function element:GetValue()
        local result = {}
        for index = 1, #options do
            if selected[index] then
                result[#result + 1] = options[index].Value ~= nil and options[index].Value or options[index].Title
            end
        end
        if multi then
            return result
        end
        return result[1]
    end

    function element:GetOptions()
        return options
    end

    function element:Refresh()
        refreshDisplay()
        return element
    end

    element.ClosePopup = closePopup
    return element
end

-- COLORPICKER -----------------------------------------------------------------
function Components.Colorpicker(parent, order, config)
    config = config or {}
    local element = newElement("Colorpicker", config._window)
    element._order = order
    element.Title = config.Title

    local color = config.Default or Theme.Accent
    local popup = nil

    local row = makeRow(parent, element, config.Title, config.Desc, 21)

    local preview = make("TextButton", {
        Size = UDim2.new(0, 50, 0, 16),
        Position = UDim2.new(1, -50, 0.5, -8),
        BackgroundColor3 = color,
        Text = "",
        AutoButtonColor = false,
    })
    preview.Parent = row
    roundCorners(preview, 3)
    addStroke(preview, "Border", 0.8)
    element._preview = preview

    local function setColor(next, fire)
        color = next
        preview.BackgroundColor3 = next
        if fire and config.Callback then
            config.Callback(next)
        end
    end

    function element:SetValue(next, fire)
        setColor(next, fire ~= false)
        return element
    end

    function element:GetValue()
        return color
    end

    preview.MouseButton1Click:Connect(function()
        if popup and popup.Parent then
            popup:Destroy()
            popup = nil
            return
        end

        local gui = config._window._gui
        if not gui then
            return
        end
        config._window._popups:closeAll()

        popup = make("Frame", {
            Size = UDim2.new(0, 200, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(
                preview.AbsolutePosition.X + preview.AbsoluteSize.X - 200,
                preview.AbsolutePosition.Y + preview.AbsoluteSize.Y + 4
            ),
            BackgroundColor3 = Theme.PopupBg,
            BorderSizePixel = 0,
            ZIndex = 100,
        })
        popup.Parent = gui
        roundCorners(popup, 6)
        addStroke(popup, "Border", 0.8)
        paint(popup, "PopupBg", "BackgroundColor3")

        local popupPadding = make("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        })
        popupPadding.Parent = popup

        local popupLayout = make("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        popupLayout.Parent = popup

        local hexBox
        local refreshers = {}

        local function refreshHex()
            if hexBox and hexBox.Parent then
                hexBox.Text = string.format(
                    "#%02X%02X%02X",
                    round(color.R * 255),
                    round(color.G * 255),
                    round(color.B * 255)
                )
            end
        end

        local function channelRow(name, channel)
            local rowFrame = make("Frame", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
            })
            rowFrame.Parent = popup

            local nameLabel = make("TextLabel", {
                Size = UDim2.new(0, 14, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamBold,
                TextSize = 9.5,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            nameLabel.Parent = rowFrame
            paint(nameLabel, "TextMuted", "TextColor3")

            local valueLabel = make("TextLabel", {
                Size = UDim2.new(0, 24, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 9.5,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            valueLabel.Parent = rowFrame
            paint(valueLabel, "Accent", "TextColor3")

            local track = make("Frame", {
                Size = UDim2.new(1, -46, 0, 5),
                Position = UDim2.new(0, 18, 0.5, -2.5),
                BackgroundColor3 = Theme.ToggleOff,
                BorderSizePixel = 0,
            })
            track.Parent = rowFrame
            roundCorners(track, 3)
            paint(track, "ToggleOff", "BackgroundColor3")

            local fill = make("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
            })
            fill.Parent = track
            roundCorners(fill, 3)
            paint(fill, "Accent", "BackgroundColor3")

            local function read()
                if channel == 1 then
                    return color.R
                elseif channel == 2 then
                    return color.G
                end
                return color.B
            end

            local function refresh()
                local value = read()
                fill.Size = UDim2.new(value, 0, 1, 0)
                valueLabel.Text = tostring(round(value * 255))
            end

            refresh()

            makeDraggable(track, function(delta)
                local ratio = math.clamp((track.AbsolutePosition.X + delta.X - track.AbsolutePosition.X)
                    / math.max(track.AbsoluteSize.X, 1), 0, 1)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                valueLabel.Text = tostring(round(ratio * 255))
                if channel == 1 then
                    setColor(Color3.new(ratio, color.G, color.B), true)
                elseif channel == 2 then
                    setColor(Color3.new(color.R, ratio, color.B), true)
                else
                    setColor(Color3.new(color.R, color.G, ratio), true)
                end
                refreshHex()
            end)

            return refresh
        end

        refreshers[1] = channelRow("R", 1)
        refreshers[2] = channelRow("G", 2)
        refreshers[3] = channelRow("B", 3)

        local hexRow = make("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
        })
        hexRow.Parent = popup

        local hexHolder = make("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Theme.BadgeBg,
            BorderSizePixel = 0,
        })
        hexHolder.Parent = hexRow
        roundCorners(hexHolder, 4)
        addStroke(hexHolder, "Border", 0.8)
        paint(hexHolder, "BadgeBg", "BackgroundColor3")

        hexBox = make("TextBox", {
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Text = string.format("#%02X%02X%02X", round(color.R * 255), round(color.G * 255), round(color.B * 255)),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        })
        hexBox.Parent = hexHolder
        paint(hexBox, "TextPrimary", "TextColor3")

        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("#", "")
            if #hex == 6 then
                local r = tonumber(hex:sub(1, 2), 16)
                local g = tonumber(hex:sub(3, 4), 16)
                local b = tonumber(hex:sub(5, 6), 16)
                if r and g and b then
                    setColor(Color3.fromRGB(r, g, b), true)
                    for _, refresh in ipairs(refreshers) do
                        refresh()
                    end
                end
            end
            refreshHex()
        end)

        local paletteRow = make("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
        })
        paletteRow.Parent = popup

        local paletteLayout = make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        paletteLayout.Parent = paletteRow

        local swatches = {
            Color3.fromRGB(246, 92, 82),
            Color3.fromRGB(255, 180, 0),
            Color3.fromRGB(80, 200, 120),
            Color3.fromRGB(80, 160, 255),
            Color3.fromRGB(180, 100, 255),
            Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(120, 120, 120),
            Color3.fromRGB(20, 20, 20),
        }

        for order, swatch in ipairs(swatches) do
            local button = make("TextButton", {
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = swatch,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = order,
            })
            button.Parent = paletteRow
            roundCorners(button, 3)
            addStroke(button, "Border", 0.8)
            button.MouseButton1Click:Connect(function()
                setColor(swatch, true)
                for _, refresh in ipairs(refreshers) do
                    refresh()
                end
                refreshHex()
            end)
        end

        config._window._popups:track(popup)
    end)

    return element
end

-- PROGRESSBAR -----------------------------------------------------------------
function Components.ProgressBar(parent, order, config)
    config = config or {}
    local element = newElement("ProgressBar", config._window)
    element._order = order
    element.Title = config.Title

    local value = math.clamp(tonumber(config.Default) or 0, 0, 1)

    local row = makeRow(parent, element, config.Title, config.Desc, 30)
    element._textColumn.Size = UDim2.new(1, -40, 1, 0)

    local valueLabel = make("TextLabel", {
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(round(value * 100)) .. "%",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    valueLabel.Parent = row
    paint(valueLabel, "Accent", "TextColor3")

    local track = make("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
    })
    track.Parent = row
    roundCorners(track, 4)
    paint(track, "ToggleOff", "BackgroundColor3")

    local fill = make("Frame", {
        Size = UDim2.new(value, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    })
    fill.Parent = track
    roundCorners(fill, 4)
    paint(fill, "Accent", "BackgroundColor3")

    local function apply(next, fire)
        value = math.clamp(tonumber(next) or 0, 0, 1)
        TweenService:Create(fill, Element.TweenFast, { Size = UDim2.new(value, 0, 1, 0) }):Play()
        valueLabel.Text = tostring(round(value * 100)) .. "%"
        if fire and config.Callback then
            config.Callback(value)
        end
    end

    if config.Interactive then
        makeDraggable(track, function(delta)
            local ratio = math.clamp(delta.X / math.max(track.AbsoluteSize.X, 1), 0, 1)
            apply(ratio, true)
        end)
    end

    function element:SetValue(next, fire)
        apply(next, fire ~= false)
        return element
    end

    function element:GetValue()
        return value
    end

    return element
end

Element.TweenFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Element.TweenSlow = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- containers — card (section), hstack / vstack
--------------------------------------------------------------------------------

local Container = {}
Container.__index = Container

local function attachComponent(container, factory, config)
    local order = container._nextOrder
    container._nextOrder = order + 1
    if type(config) == "table" then
        config = copyTable(config)
        config._window = container._window
    end
    local element = factory(container._body or container._frame, order, config)
    element._container = container
    return element
end

function Container:CreateToggle(config) return attachComponent(self, Components.Toggle, config) end
function Container:CreateButton(config) return attachComponent(self, Components.Button, config) end
function Container:CreateInput(config) return attachComponent(self, Components.Input, config) end
function Container:CreateSlider(config) return attachComponent(self, Components.Slider, config) end
function Container:CreateKeybind(config) return attachComponent(self, Components.Keybind, config) end
function Container:CreateDropdown(config) return attachComponent(self, Components.Dropdown, config) end
function Container:CreateColorpicker(config) return attachComponent(self, Components.Colorpicker, config) end
function Container:CreateProgressBar(config) return attachComponent(self, Components.ProgressBar, config) end
function Container:CreateLabel(text) return attachComponent(self, Components.Label, text) end
function Container:CreateDivider() return attachComponent(self, Components.Divider, {}) end
function Container:CreateParagraph(config) return attachComponent(self, Components.Paragraph, config) end

-- HStack / VStack return the same container shape, so any component can be
-- dropped straight into a row (WindUI's Section:HStack pattern).
function Container:CreateHStack(config)
    config = config or {}
    local order = self._nextOrder
    self._nextOrder = order + 1

    local stack = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
    })
    stack.Parent = self._body or self._frame

    local layout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, config.Padding or 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })
    layout.Parent = stack

    return setmetatable({
        _frame = stack,
        _body = stack,
        _window = self._window,
        _nextOrder = 0,
        Stack = stack,
        Horizontal = true,
    }, Container)
end

function Container:CreateVStack(config)
    config = config or {}
    local order = self._nextOrder
    self._nextOrder = order + 1

    local stack = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
    })
    stack.Parent = self._body or self._frame

    local layout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, config.Padding or 6),
    })
    layout.Parent = stack

    return setmetatable({
        _frame = stack,
        _body = stack,
        _window = self._window,
        _nextOrder = 0,
        Stack = stack,
        Horizontal = false,
    }, Container)
end

--------------------------------------------------------------------------------
-- tab
--------------------------------------------------------------------------------

local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(config)
    config = config or {}
    local order = self._cardCount
    self._cardCount = order + 1

    local column = config.Column or (order % 2 == 0 and 1 or 2)

    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.CardBg,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = order,
        ZIndex = 3,
    })
    card.Parent = self._columns[column]
    roundCorners(card, 8)
    addStroke(card, "Border", 0.8)
    paint(card, "CardBg", "BackgroundColor3")

    local outerLayout = make("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    outerLayout.Parent = card

    local outerPadding = make("UIPadding", {
        PaddingTop = UDim.new(0, 11),
        PaddingBottom = UDim.new(0, 13),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })
    outerPadding.Parent = card

    local header = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 0,
        ZIndex = 4,
    })
    header.Parent = card

    if config.Icon then
        local headerIcon = make("ImageLabel", {
            Size = UDim2.new(0, 13, 0, 13),
            Position = UDim2.new(0, 0, 0.5, -6.5),
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            Image = Lib:GetIcon(config.Icon) or "",
        })
        headerIcon.Parent = header
        paint(headerIcon, "Accent", "ImageColor3")

        local spacer = make("Frame", {
            Size = UDim2.new(0, 19, 1, 0),
            Position = UDim2.new(1, -19, 0, 0),
            BackgroundTransparency = 1,
        })
        spacer.Parent = header
    end

    local title = make("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(config.Icon and 19 or 0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    title.Parent = header
    paint(title, "TextPrimary", "TextColor3")

    local arrow = make("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(1, -12, 0.5, -6),
        BackgroundTransparency = 1,
        Image = Lib.Icons.Chevron,
        Rotation = 0,
    })
    arrow.Parent = header
    paint(arrow, "Accent", "ImageColor3")

    local body = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        ZIndex = 4,
    })
    body.Parent = card

    local bodyLayout = make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    bodyLayout.Parent = body

    local bodyPadding = make("UIPadding", { PaddingTop = UDim.new(0, 10) })
    bodyPadding.Parent = body

    local opened = config.Opened ~= false
    body.Visible = opened
    arrow.Rotation = opened and 0 or -90

    local section = setmetatable({
        _frame = card,
        _body = body,
        _window = self._window,
        _nextOrder = 0,
        Header = header,
        Title = config.Title,
        Tab = self,
    }, Container)

    section.SetTitle = function(self_, title_)
        section.Title = title_
        title.Text = tostring(title_)
    end

    section.SetOpen = function(self_, state)
        opened = state ~= false
        body.Visible = opened
        arrow.Rotation = opened and 0 or -90
    end

    section.IsOpen = function(self_)
        return opened
    end

    header.MouseButton1Click:Connect(function()
        opened = not opened
        body.Visible = opened
        arrow.Rotation = opened and 0 or -90
    end)

    self._window._sections[#self._window._sections + 1] = section
    return section
end

-- Free text directly in a column, without the card chrome.
function Tab:CreateParagraph(config)
    config = config or {}
    local order = self._cardCount
    self._cardCount = order + 1

    local column = self._columns[(config.Column or (order % 2 == 0 and 1 or 2))]

    local frame = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
        ZIndex = 3,
    })
    frame.Parent = column

    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = frame

    if config.Title then
        local title = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = tostring(config.Title),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
        })
        title.Parent = frame
        paint(title, "TextPrimary", "TextColor3")
    end

    if config.Content or config.Desc then
        local body = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = tostring(config.Content or config.Desc),
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 1,
        })
        body.Parent = frame
        paint(body, "TextMuted", "TextColor3")
    end

    return setmetatable({
        _frame = frame,
        _body = frame,
        _window = self._window,
        _nextOrder = 0,
        Tab = self,
    }, Container)
end

function Tab:Select()
    self._window:SelectTab(self)
    return self
end

function Tab:GetTitle()
    return self.Title
end

function Tab:SetTitle(title)
    self.Title = tostring(title)
    self._sidebarTitle.Text = self.Title
    return self
end

function Tab:GetVisible()
    return self._content.Visible
end

function Tab:SetLocked(state)
    self.Locked = state == true
    self._sidebarIcon.Image = self.Locked and (Lib.Lucide["lock"] or "") or (Lib:GetIcon(self.Icon) or "")
    return self
end

--------------------------------------------------------------------------------
-- window
--------------------------------------------------------------------------------

local Window = {}
Window.__index = Window

function Window:_setSidebarActive(tab)
    local previous = self._activeTab
    if previous == tab then
        return
    end

    if previous then
        previous._content.Visible = false
        TweenService:Create(previous._sidebarButton, Element.TweenFast, {
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(previous._sidebarStroke, Element.TweenFast, { Transparency = 1 }):Play()
        TweenService:Create(previous._sidebarIcon, Element.TweenFast, { ImageColor3 = Theme.TextMuted }):Play()
        TweenService:Create(previous._sidebarTitle, Element.TweenFast, { TextColor3 = Theme.TextMuted }):Play()
        paint(previous._sidebarIcon, "TextMuted", "ImageColor3")
        paint(previous._sidebarTitle, "TextMuted", "TextColor3")
    end

    tab._content.Visible = true
    TweenService:Create(tab._sidebarButton, Element.TweenFast, {
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.SidebarActive,
    }):Play()
    TweenService:Create(tab._sidebarStroke, Element.TweenFast, {
        Transparency = 0,
        Color = Theme.BorderActive,
    }):Play()
    TweenService:Create(tab._sidebarIcon, Element.TweenFast, { ImageColor3 = Theme.Accent }):Play()
    TweenService:Create(tab._sidebarTitle, Element.TweenFast, { TextColor3 = Theme.TextPrimary }):Play()
    paint(tab._sidebarIcon, "Accent", "ImageColor3")
    paint(tab._sidebarTitle, "TextPrimary", "TextColor3")

    self._activeTab = tab
end

function Window:SelectTab(tab)
    if not tab or tab.Locked then
        return self
    end
    self:_setSidebarActive(tab)
    return self
end

function Window:GetTabs()
    return self._tabs
end

function Window:CreateTabGroup(config)
    config = config or {}
    local order = self._sidebarCount
    self._sidebarCount = order + 1

    local header = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = order,
        BackgroundTransparency = 1,
        Text = "   " .. tostring(config.Title or ""):upper(),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    header.Parent = self._sidebar
    paint(header, "TextDim", "TextColor3")

    local group = {
        Title = config.Title,
        Icon = config.Icon,
        _window = self,
        _order = order,
    }

    function group:CreateTab(tabConfig)
        tabConfig = copyTable(tabConfig or {})
        tabConfig._group = self
        return self._window:CreateTab(tabConfig)
    end
    group.Tab = group.CreateTab

    self._groups[#self._groups + 1] = group
    return group
end

function Window:CreateTab(config)
    config = config or {}
    local window = self
    local order = self._sidebarCount
    self._sidebarCount = order + 1

    -- content area -------------------------------------------------------
    local content = make("Frame", {
        Name = tostring(config.Title or "Tab"),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
    })
    content.Parent = self._contentWrapper

    local backdrop = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 1,
    })
    backdrop.Parent = content
    roundCorners(backdrop, 8)
    paint(backdrop, "Background", "BackgroundColor3")

    local columns = {}
    for index = 1, 2 do
        local column = make("ScrollingFrame", {
            Size = UDim2.new(0.485, 0, 1, 0),
            Position = UDim2.new(index == 1 and 0 or 0.515, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ClipsDescendants = true,
            ZIndex = 2,
        })
        column.Parent = content

        local layout = make("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        layout.Parent = column

        local padding = make("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 24),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
        })
        padding.Parent = column

        local function syncCanvas()
            column.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
        task.defer(syncCanvas)

        columns[index] = { Frame = column, Layout = layout }
    end

    -- sidebar entry ------------------------------------------------------
    local button = make("TextButton", {
        Size = UDim2.new(1, -4, 0, 29),
        LayoutOrder = order,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    button.Parent = self._sidebar
    roundCorners(button, 6)

    local stroke = make("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Transparency = 1,
    })
    stroke.Parent = button
    paint(stroke, "Border", "Color")

    local icon = make("ImageLabel", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 9, 0.5, -7),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Image = config.Locked and (Lib.Lucide["lock"] or "") or (Lib:GetIcon(config.Icon) or ""),
    })
    icon.Parent = button
    paint(icon, "TextMuted", "ImageColor3")

    local title = make("TextLabel", {
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or "Tab"),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    title.Parent = button
    paint(title, "TextMuted", "TextColor3")

    local tab = setmetatable({
        Title = config.Title or "Tab",
        Icon = config.Icon,
        Locked = config.Locked == true,
        _window = window,
        _content = content,
        _columns = { columns[1].Frame, columns[2].Frame },
        _columnEntries = columns,
        _sidebarButton = button,
        _sidebarIcon = icon,
        _sidebarTitle = title,
        _sidebarStroke = stroke,
        _cardCount = 0,
        Sections = {},
    }, Tab)

    button.MouseEnter:Connect(function()
        if window._activeTab ~= tab then
            TweenService:Create(title, Element.TweenFast, { TextColor3 = Theme.TextPrimary }):Play()
            TweenService:Create(icon, Element.TweenFast, { ImageColor3 = Theme.TextPrimary }):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if window._activeTab ~= tab then
            TweenService:Create(title, Element.TweenFast, { TextColor3 = Theme.TextMuted }):Play()
            TweenService:Create(icon, Element.TweenFast, { ImageColor3 = Theme.TextMuted }):Play()
            paint(title, "TextMuted", "TextColor3")
            paint(icon, "TextMuted", "ImageColor3")
        end
    end)
    button.MouseButton1Click:Connect(function()
        if tab.Locked then
            Lib:Notify({
                Title = config.Title or "Locked",
                Desc = config.LockMessage or "This tab is not available yet.",
                Icon = "lock",
                Type = "Warning",
            })
            return
        end
        window:_setSidebarActive(tab)
    end)

    window._tabs[#window._tabs + 1] = tab

    if not window._activeTab and not tab.Locked then
        window:_setSidebarActive(tab)
    end

    return tab
end

function Window:_applySearch(query)
    query = query or ""
    local lowered = query:lower()
    local firstHit

    for _, element in ipairs(self._rows) do
        local matches = lowered == "" or string.find(element._searchText, lowered, 1, true) ~= nil
        element._frame.Visible = matches
        if matches and not firstHit and element._container and element._container.Tab then
            firstHit = element._container.Tab
        end
    end

    if lowered ~= "" and firstHit and self._activeTab ~= firstHit and not firstHit.Locked then
        self:_setSidebarActive(firstHit)
    end
end

function Window:Toggle(state)
    state = state == nil and not self._visible or state
    self._visible = state
    self._main.Visible = state
    return self
end

function Window:IsVisible()
    return self._visible
end

function Window:SetTitle(title)
    self._brandName.Text = tostring(title)
    return self
end

function Window:SetAuthor(author)
    self._brandDesc.Text = tostring(author)
    return self
end

function Window:SetVersion(version)
    self._brandVersion.Text = tostring(version)
    return self
end

function Window:SetLogo(assetId)
    if self._brandIcon then
        self._brandIcon.Image = assetId
        self._brandIcon.Visible = assetId ~= nil and assetId ~= ""
    end
    return self
end

function Window:SetToTheCenter()
    local camera = workspace.CurrentCamera
    if not camera then
        return self
    end
    local viewport = camera.ViewportSize
    local size = self._main.AbsoluteSize
    self._main.Position = UDim2.fromOffset(
        (viewport.X - size.X) / 2,
        (viewport.Y - size.Y) / 2
    )
    return self
end

-- Accepts either an Enum.KeyCode or its name ("LeftControl").
function Window:SetToggleKey(key)
    if type(key) == "string" then
        key = Enum.KeyCode[key]
    end
    if key == nil then
        return self
    end
    self._toggleKey = key
    self._menuIcon.Image = Lib:GetIcon("keyboard") or ""
    self._menuIcon.ImageColor3 = Theme.TextMuted
    paint(self._menuIcon, "TextMuted", "ImageColor3")
    return self
end

function Window:Notify(config)
    return Lib:Notify(config, self)
end

function Window:Dialog(config)
    return Lib:CreateDialog(config, self)
end

function Window:Tag(config)
    config = config or {}
    local order = self._tagCount
    self._tagCount = order + 1

    local pill = make("Frame", {
        Size = UDim2.new(0, 56, 0, 18),
        Position = UDim2.new(1, -70 - (self._tagCount - 1) * 60, 0.5, -9),
        BackgroundColor3 = Theme.BadgeBg,
        BorderSizePixel = 0,
        LayoutOrder = order,
    })
    pill.Parent = self._topBar
    roundCorners(pill, 9)
    addStroke(pill, "Border", 0.8)
    paint(pill, "BadgeBg", "BackgroundColor3")

    local tagIcon = make("ImageLabel", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 5, 0.5, -5),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Image = Lib:GetIcon(config.Icon or "tag") or "",
    })
    tagIcon.Parent = pill
    paint(tagIcon, "Accent", "ImageColor3")

    local tagLabel = make("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    tagLabel.Parent = pill
    paint(tagLabel, "TextMuted", "TextColor3")

    return {
        _frame = pill,
        Title = config.Title,
        SetTitle = function(_, value)
            tagLabel.Text = tostring(value)
        end,
        SetVisible = function(_, state)
            pill.Visible = state ~= false
        end,
        Destroy = function()
            pill:Destroy()
        end,
    }
end

function Window:EditOpenButton(config)
    config = config or {}
    self._menuButton.Enabled = config.Enabled ~= false
    self._menuOpenCallback = config.Callback
    return self
end

function Window:Destroy()
    self._gui:Destroy()
    return self
end

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

local NotificationTypes = {
    Success = { Icon = "circle-check", ColorKey = "Accent" },
    Error = { Icon = "triangle-alert", ColorKey = "Accent" },
    Warning = { Icon = "alert-triangle", ColorKey = "Accent" },
    Info = { Icon = "info", ColorKey = "Accent" },
}

function Lib:Notify(config, window)
    config = config or {}
    window = window or self._lastWindow
    if not window then
        return nil
    end

    local meta = NotificationTypes[config.Type or "Info"] or NotificationTypes.Info
    local duration = config.Duration or 3

    local holder = make("Frame", {
        Name = "MacrOSNotify",
        Size = UDim2.new(0, 300, 0, 44),
        Position = UDim2.new(1, -316, 1, -60 - window._notificationCount * 48),
        BackgroundColor3 = Theme.CardBg,
        BorderSizePixel = 0,
        ZIndex = 200,
    })
    holder.Parent = window._gui
    window._notificationCount = window._notificationCount + 1

    roundCorners(holder, 10)
    addStroke(holder, "Border", 1)
    paint(holder, "CardBg", "BackgroundColor3")

    local accent = make("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 6, 0, 8),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 201,
    })
    accent.Parent = holder
    roundCorners(accent, 2)
    paint(accent, meta.ColorKey, "BackgroundColor3")

    local icon = make("ImageLabel", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 16, 0.5, -8),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Image = Lib:GetIcon(config.Icon or meta.Icon) or "",
        ZIndex = 201,
    })
    icon.Parent = holder
    paint(icon, meta.ColorKey, "ImageColor3")

    local title = make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 16),
        Position = UDim2.new(0, 40, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 201,
    })
    title.Parent = holder
    paint(title, "TextPrimary", "TextColor3")

    local desc = make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 14),
        Position = UDim2.new(0, 40, 0, 23),
        BackgroundTransparency = 1,
        Text = tostring(config.Desc or ""),
        Font = Enum.Font.Gotham,
        TextSize = 9.5,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 201,
    })
    desc.Parent = holder
    paint(desc, "TextMuted", "TextColor3")

    holder.BackgroundTransparency = 1
    TweenService:Create(holder, Element.TweenFast, { BackgroundTransparency = 0 }):Play()

    local token = {}
    local finished = false

    local function close()
        if finished then
            return
        end
        finished = true
        local tween = TweenService:Create(holder, Element.TweenFast, {
            BackgroundTransparency = 1,
            Position = UDim2.new(holder.Position.X.Scale, holder.Position.X.Offset,
                holder.Position.Y.Scale, holder.Position.Y.Offset - 20),
        })
        tween:Play()
        tween.Completed:Connect(function()
            window._notificationCount = math.max(window._notificationCount - 1, 0)
            holder:Destroy()
        end)
    end

    token.Close = close
    token.SetTitle = function(_, value)
        title.Text = tostring(value)
    end
    token.SetDesc = function(_, value)
        desc.Text = tostring(value)
    end

    if duration > 0 then
        task.delay(duration, close)
    end

    if config.Callback then
        task.defer(config.Callback)
    end

    return token
end

--------------------------------------------------------------------------------
-- dialog
--------------------------------------------------------------------------------

function Lib:CreateDialog(config, window)
    config = config or {}
    window = window or self._lastWindow
    if not window then
        return nil
    end

    local overlay = make("Frame", {
        Name = "MacrOSDialog",
        Size = window._main.Size,
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = 300,
        Active = true,
    })
    overlay.Parent = window._main

    local box = make("Frame", {
        Size = UDim2.new(0, 320, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, -160, 0.5, -80),
        BackgroundColor3 = Theme.CardBg,
        BorderSizePixel = 0,
        ZIndex = 301,
    })
    box.Parent = overlay
    roundCorners(box, 10)
    addStroke(box, "Border", 1)
    paint(box, "CardBg", "BackgroundColor3")

    local padding = make("UIPadding", {
        PaddingTop = UDim.new(0, 16),
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
    })
    padding.Parent = box

    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = box

    local title = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = tostring(config.Title or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
    })
    title.Parent = box
    paint(title, "TextPrimary", "TextColor3")

    local content = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = tostring(config.Content or config.Desc or ""),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 1,
    })
    content.Parent = box
    paint(content, "TextMuted", "TextColor3")

    local actions = make("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    })
    actions.Parent = box

    local actionLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
    })
    actionLayout.Parent = actions

    local function close()
        overlay:Destroy()
        if config.OnClose then
            config.OnClose()
        end
    end

    local function makeAction(text, isPrimary, onClick)
        local button = make("TextButton", {
            Size = UDim2.new(0, 96, 0, 24),
            BackgroundColor3 = isPrimary and Theme.Accent or Theme.BadgeBg,
            Text = text,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            TextSize = 10.5,
            TextColor3 = isPrimary and Color3.fromRGB(255, 255, 255) or Theme.TextMuted,
        })
        button.Parent = actions
        roundCorners(button, 5)
        addStroke(button, "Border", 0.8)
        paint(button, isPrimary and "Accent" or "BadgeBg", "BackgroundColor3")
        paint(button, isPrimary and "KnobOn" or "TextMuted", "TextColor3")
        button.MouseButton1Click:Connect(function()
            close()
            if onClick then
                onClick()
            end
        end)
        return button
    end

    if config.CancelText ~= false then
        makeAction(config.CancelText or "Cancel", false, function()
            if config.Callback then
                config.Callback(false)
            end
        end)
    end
    makeAction(config.ConfirmText or "Confirm", true, function()
        if config.Callback then
            config.Callback(true)
        end
    end)

    return {
        Close = close,
        SetContent = function(_, value)
            content.Text = tostring(value)
        end,
    }
end

--------------------------------------------------------------------------------
-- HUD watermark
--------------------------------------------------------------------------------

function Lib:CreateHUD(config, window)
    config = config or {}
    window = window or self._lastWindow
    if not window then
        return nil
    end

    local container = make("Frame", {
        Name = "MacrOSHUD",
        Size = UDim2.new(0, 600, 0, 50),
        Position = UDim2.new(0, 16, 0, 48),
        BackgroundTransparency = 1,
    })
    container.Parent = window._gui

    local vertical = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })
    vertical.Parent = container

    local function hudRow(name, order)
        local row = make("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            LayoutOrder = order,
        })
        row.Parent = container

        local horizontal = make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5),
        })
        horizontal.Parent = row

        return row
    end

    local topRow = hudRow("TopRow", 1)
    local bottomRow = hudRow("BottomRow", 2)

    local function pill(parent, order)
        local frame = make("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Theme.PillBg,
            BorderSizePixel = 0,
            LayoutOrder = order,
        })
        frame.Parent = parent
        roundCorners(frame, 5)
        addStroke(frame, "Border", 1)
        paint(frame, "PillBg", "BackgroundColor3")

        make("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
        }).Parent = frame

        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 5),
        }).Parent = frame

        return frame
    end

    local function divider(parent, order)
        local frame = make("Frame", {
            Size = UDim2.new(0, 1, 0, 10),
            BackgroundColor3 = Theme.Divider,
            BorderSizePixel = 0,
            LayoutOrder = order,
        })
        frame.Parent = parent
        paint(frame, "Divider", "BackgroundColor3")
        return frame
    end

    local function text(parent, value, muted, order)
        local label = make("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = value,
            Font = Enum.Font.GothamMedium,
            TextSize = 10.5,
            LayoutOrder = order,
        })
        label.Parent = parent
        paint(label, muted and "TextMuted" or "TextPrimary", "TextColor3")
        return label
    end

    local function smallIcon(parent, iconId, order)
        local icon = make("ImageLabel", {
            Size = UDim2.new(0, 11, 0, 11),
            BackgroundTransparency = 1,
            Image = iconId,
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = order,
        })
        icon.Parent = parent
        paint(icon, "Accent", "ImageColor3")
        return icon
    end

    local brandPill = pill(topRow, 1)
    local logoWrap = make("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    })
    logoWrap.Parent = brandPill

    local glow = make("ImageLabel", {
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
    })
    glow.Parent = logoWrap
    paint(glow, "Accent", "ImageColor3")

    local logo = make("ImageLabel", {
        Size = UDim2.new(1.35, 0, 1.35, 0),
        Position = UDim2.new(-0.175, 0, -0.175, 0),
        BackgroundTransparency = 1,
        Image = config.Logo or "",
        ScaleType = Enum.ScaleType.Fit,
    })
    logo.Parent = logoWrap
    logo.Visible = config.Logo ~= nil and config.Logo ~= ""

    local brandText = text(brandPill, config.Brand or "MacrOS", false, 3)
    divider(brandPill, 2)
    brandText.LayoutOrder = 3

    local gradient = make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Theme.AccentSoft),
            ColorSequenceKeypoint.new(1.0, Theme.Accent),
        }),
    })
    gradient.Parent = brandText

    local userPill = pill(topRow, 2)
    smallIcon(userPill, Lib.Icons.User, 1)
    text(userPill, string.lower(LocalPlayer.Name), false, 2)
    divider(userPill, 3)
    smallIcon(userPill, Lib.Icons.Chart, 4)
    local fpsLabel = text(userPill, "0 Fps", false, 5)
    divider(userPill, 6)
    smallIcon(userPill, Lib.Icons.Clock, 7)
    local timeLabel = text(userPill, "00:00:00", false, 8)

    local posPill = pill(bottomRow, 1)
    smallIcon(posPill, Lib.Icons.Compass, 1)
    divider(posPill, 2)
    local posLabel = text(posPill, "0, 0, 0", false, 3)

    local pingPill = pill(bottomRow, 2)
    smallIcon(pingPill, Lib.Icons.Signal, 1)
    divider(pingPill, 2)
    local pingLabel = text(pingPill, "0 Ping", false, 3)

    local tickPill = pill(bottomRow, 3)
    smallIcon(tickPill, Lib.Icons.Radar, 1)
    divider(tickPill, 2)
    local tickLabel = text(tickPill, "20.0 Ticks", false, 3)

    local speedPill = pill(bottomRow, 4)
    smallIcon(speedPill, Lib.Icons.Speed, 1)
    divider(speedPill, 2)
    local speedLabel = text(speedPill, "0.0 Bps", false, 3)

    local frames, lastFpsCheck = 0, os.clock()
    local lastPosition = Vector3.zero
    local lastPositionTime = os.clock()

    local connection
    connection = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()

        if now - lastFpsCheck >= 1 then
            fpsLabel.Text = string.format("%d Fps", frames)
            frames = 0
            lastFpsCheck = now
        end

        timeLabel.Text = os.date("%H:%M:%S")

        local okPing, ping = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if okPing and ping then
            pingLabel.Text = string.format("%d Ping", math.floor(ping))
        end

        local tickRate = workspace:GetPropertyChangedSignal("Gravity")
        if tickRate then
            local okTick, rate = pcall(function()
                return workspace.TickRate or 60
            end)
            if okTick and rate then
                tickLabel.Text = string.format("%.1f Ticks", rate)
            end
        end

        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local position = rootPart.Position
            posLabel.Text = string.format("%d, %d, %d",
                math.floor(position.X), math.floor(position.Y), math.floor(position.Z))

            local deltaTime = now - lastPositionTime
            if deltaTime >= 0.1 then
                local distance = (Vector3.new(position.X, 0, position.Z)
                    - Vector3.new(lastPosition.X, 0, lastPosition.Z)).Magnitude
                speedLabel.Text = string.format("%.1f Bps", distance / deltaTime)
                lastPosition = position
                lastPositionTime = now
            end
        else
            posLabel.Text = "0, 0, 0"
            speedLabel.Text = "0.0 Bps"
        end
    end)

    return {
        _frame = container,
        SetVisible = function(_, state)
            container.Visible = state ~= false
        end,
        SetFps = function(_, value)
            fpsLabel.Text = tostring(value)
        end,
        SetPing = function(_, value)
            pingLabel.Text = tostring(value)
        end,
        Destroy = function()
            if connection then
                connection:Disconnect()
            end
            container:Destroy()
        end,
    }
end

--------------------------------------------------------------------------------
-- CreateWindow
--------------------------------------------------------------------------------

function Lib:CreateWindow(config)
    config = config or {}
    local window = setmetatable({
        _tabs = {},
        _groups = {},
        _sections = {},
        _rows = {},
        _sidebarCount = 0,
        _tagCount = 0,
        _notificationCount = 0,
        _activeTab = nil,
        _visible = true,
    }, Window)

    local title = config.Title or "MacrOS"
    local author = config.Author or ""
    local version = config.Version or Lib.Version
    local folderName = config.Folder or title

    local parent = config.Parent or resolveParent()

    local gui = make("ScreenGui", {
        Name = folderName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = config.IgnoreGuiInset == true,
    })
    gui.Parent = parent
    window._gui = gui
    window._popups = PopupManager.new(gui)
    window._popups:bindDismiss()

    -- main frame ---------------------------------------------------------
    local size = config.Size or UDim2.fromOffset(790, 490)
    local main = make("Frame", {
        Name = "MainFrame",
        Size = size,
        Position = config.Position or UDim2.new(0.5, -395, 0.5, -245),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
    })
    main.Parent = gui
    roundCorners(main, 12)
    addStroke(main, "Border", 1.2)
    paint(main, "Background", "BackgroundColor3")
    window._main = main

    if config.Translucent then
        main.BackgroundTransparency = 0.85
    end

    if config.Scale then
        local scale = make("UIScale", { Scale = config.Scale })
        scale.Parent = main
    end

    local minSize = config.MinSize or Vector2.new(500, 320)
    local maxSize = config.MaxSize or Vector2.new(1200, 900)
    window._minSize = minSize
    window._maxSize = maxSize

    -- top bar ------------------------------------------------------------
    local topBar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        Active = true,
    })
    topBar.Parent = main
    window._topBar = topBar

    makeDraggable(topBar, function(delta, startPos)
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end, function()
        return main.Position
    end)

    -- brand --------------------------------------------------------------
    local brandBlock = make("Frame", {
        Name = "BrandBlock",
        Size = UDim2.new(0, 240, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
    })
    brandBlock.Parent = topBar

    local brandLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
    })
    brandLayout.Parent = brandBlock

    local brandIcon = make("ImageLabel", {
        Name = "BrandIcon",
        Size = UDim2.new(0, 34, 0, 34),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Image = config.Logo or "",
        ScaleType = Enum.ScaleType.Fit,
    })
    brandIcon.Parent = brandBlock
    brandIcon.Visible = config.Logo ~= nil and config.Logo ~= ""
    window._brandIcon = brandIcon

    local brandColumn = make("Frame", {
        Name = "BrandTextCol",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    })
    brandColumn.Parent = brandBlock

    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }).Parent = brandColumn

    local brandName = make("TextLabel", {
        Name = "BrandName",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
    })
    brandName.Parent = brandColumn
    window._brandName = brandName

    local brandDesc = make("TextLabel", {
        Name = "BrandDesc",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 13),
        BackgroundTransparency = 1,
        Text = author,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
    })
    brandDesc.Parent = brandColumn
    paint(brandDesc, "TextDim", "TextColor3")
    window._brandDesc = brandDesc

    local brandVersion = make("TextLabel", {
        Name = "BrandVersion",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 38, 0, 20),
        BackgroundColor3 = Theme.VersionBg,
        Text = version,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Theme.VersionText,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 3,
    })
    brandVersion.Parent = brandBlock
    roundCorners(brandVersion, 10)
    paint(brandVersion, "VersionBg", "BackgroundColor3")
    paint(brandVersion, "VersionText", "TextColor3")
    window._brandVersion = brandVersion

    -- search -------------------------------------------------------------
    local searchBox = make("Frame", {
        Name = "SearchBox",
        Size = UDim2.new(0, 250, 0, 26),
        Position = UDim2.new(0, 265, 0, 15),
        BackgroundColor3 = Theme.CardBg,
        BorderSizePixel = 0,
    })
    searchBox.Parent = topBar
    roundCorners(searchBox, 6)
    addStroke(searchBox, "Border", 0.8)
    paint(searchBox, "CardBg", "BackgroundColor3")

    local searchIcon = make("ImageLabel", {
        Name = "SearchIcon",
        Size = UDim2.new(0, 13, 0, 13),
        Position = UDim2.new(0, 9, 0.5, -6.5),
        BackgroundTransparency = 1,
        Image = Lib.Icons.Search,
    })
    searchIcon.Parent = searchBox
    paint(searchIcon, "TextMuted", "ImageColor3")

    local searchInput = make("TextBox", {
        Name = "SearchInput",
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = "Search something",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })
    searchInput.Parent = searchBox
    paint(searchInput, "TextPrimary", "TextColor3")
    paint(searchInput, "TextMuted", "PlaceholderColor3")

    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        window:_applySearch(searchInput.Text)
    end)
    window._searchInput = searchInput

    -- menu button --------------------------------------------------------
    local menuButton = make("ImageButton", {
        Size = UDim2.new(0, 17, 0, 17),
        Position = UDim2.new(1, -32, 0.5, -8.5),
        BackgroundTransparency = 1,
        Image = Lib:GetIcon("keyboard") or Lib.Icons.Menu,
    })
    menuButton.Parent = topBar
    paint(menuButton, "TextMuted", "ImageColor3")
    window._menuButton = menuButton
    window._menuIcon = menuButton

    menuButton.MouseEnter:Connect(function()
        TweenService:Create(menuButton, Element.TweenFast, { ImageColor3 = Theme.TextPrimary }):Play()
    end)
    menuButton.MouseLeave:Connect(function()
        TweenService:Create(menuButton, Element.TweenFast, { ImageColor3 = Theme.TextMuted }):Play()
        paint(menuButton, "TextMuted", "ImageColor3")
    end)

    menuButton.MouseButton1Click:Connect(function()
        if window._menuOpenCallback then
            window._menuOpenCallback()
        else
            window:Toggle()
        end
    end)

    -- sidebar ------------------------------------------------------------
    local sidebar = make("Frame", {
        Size = UDim2.new(0, 155, 1, -58),
        Position = UDim2.new(0, 14, 0, 54),
        BackgroundTransparency = 1,
    })
    sidebar.Parent = main

    make("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = sidebar
    window._sidebar = sidebar

    -- content ------------------------------------------------------------
    local contentWrapper = make("Frame", {
        Size = UDim2.new(1, -195, 1, -62),
        Position = UDim2.new(0, 182, 0, 54),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })
    contentWrapper.Parent = main
    window._contentWrapper = contentWrapper

    -- footer -------------------------------------------------------------
    local footer = make("Frame", {
        Size = UDim2.new(0, 160, 0, 28),
        Position = UDim2.new(0, 18, 1, -38),
        BackgroundTransparency = 1,
    })
    footer.Parent = main

    local userLabel = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 13),
        BackgroundTransparency = 1,
        Text = string.lower(LocalPlayer.Name),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    userLabel.Parent = footer
    paint(userLabel, "TextMuted", "TextColor3")

    local subLabel = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 11),
        Position = UDim2.new(0, 0, 0, 13),
        BackgroundTransparency = 1,
        Text = config.Footer or "MacrOS",
        Font = Enum.Font.Gotham,
        TextSize = 7.5,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    subLabel.Parent = footer
    paint(subLabel, "TextDim", "TextColor3")

    -- resize handle ------------------------------------------------------
    if config.Resizable ~= false then
        local handle = make("TextButton", {
            Name = "ResizeHandle",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -18, 1, -18),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 10,
        })
        handle.Parent = main
        window._resizeHandle = handle

        local function gripLine(xOffset, yOffset, length)
            local line = make("Frame", {
                Size = UDim2.new(0, length, 0, 1),
                Position = UDim2.new(1, xOffset, 1, yOffset),
                AnchorPoint = Vector2.new(1, 1),
                BorderSizePixel = 0,
                ZIndex = 11,
            })
            line.Parent = handle
            roundCorners(line, 1)
            paint(line, "TextDim", "BackgroundColor3")
            return line
        end

        local grip1 = gripLine(-4, -4, 14)
        local grip2 = gripLine(-4, -8, 8)

        handle.MouseEnter:Connect(function()
            grip1.BackgroundColor3 = Theme.Accent
            grip2.BackgroundColor3 = Theme.Accent
        end)
        handle.MouseLeave:Connect(function()
            grip1.BackgroundColor3 = Theme.TextDim
            grip2.BackgroundColor3 = Theme.TextDim
        end)

        makeDraggable(handle, function(delta, origin)
            local width = math.clamp(origin.X.Offset + delta.X, minSize.X, maxSize.X)
            local height = math.clamp(origin.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
            main.Size = UDim2.new(0, width, 0, height)
        end, function()
            return main.Size
        end)
    end

    -- toggle key ---------------------------------------------------------
    window._toggleKey = config.ToggleKey or Enum.KeyCode.LeftControl
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == window._toggleKey then
            window:Toggle()
        end
    end)

    if config.Theme then
        self:SetTheme(config.Theme)
    end

    if config.HUD then
        window.HUD = self:CreateHUD(config.HUD, window)
    end

    self._lastWindow = window
    return window
end

--------------------------------------------------------------------------------
-- WindUI-compatible aliases — lets an existing menu keep its call sites
-- (Window:Section{...}:Tab{...} instead of Window:CreateTabGroup{...}:CreateTab{...})
--------------------------------------------------------------------------------

Window.Section = Window.CreateTabGroup

return Lib