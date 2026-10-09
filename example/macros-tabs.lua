--[[
    MacrOS — tab tree rebuilt on the new UI library
    ===================================================================
    This is the UI layer of script.txt, ported 1:1 onto lib/macros-ui.lua:

      WindUI:CreateWindow{...}   ->  Lib:CreateWindow{...}
      WindUI:Tab{...}            ->  Window:CreateTab{...}
      WindUI:Section{...}        ->  Window:CreateTabGroup{...}
      Section:Tab{...}           ->  group:CreateTab{...}
      Tab:Section{...}           ->  Tab:CreateSection{...}
      Section:Toggle{...}        ->  Section:CreateToggle{...}
      Section:Slider{...}        ->  Section:CreateSlider{...}
      ...                        ->  CreateInput / CreateDropdown /
                                     CreateColorpicker / CreateKeybind /
                                     CreateProgressBar / CreateButton /
                                     CreateHStack / CreateParagraph

    Every tab, section, icon and open/closed state below matches script.txt.
    The Callbacks are left as thin hooks: the game logic keeps living in the
    script, the UI only reports what the player pressed.

    Run it:  loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/dragonstrukov/MacrOS/refs/heads/main/example/macros-tabs.lua"
    ))()
--]]

local LIB_URL = "https://raw.githubusercontent.com/dragonstrukov/MacrOS/refs/heads/main/lib/macros-ui.lua"

local Lib = loadstring(game:HttpGet(LIB_URL))()

-- Where the real script would do `local WindUI = MacrOS.loadWindUI()`.
local Macro = { toggles = {}, sliders = {} }

local function bindToggle(section, title, desc, default)
    local element = section:CreateToggle({
        Title = title,
        Desc = desc,
        Default = default or false,
        Callback = function(value)
            Macro.toggles[title] = value
            -- the script hooks its feature here
        end,
    })
    return element
end

local function bindSlider(section, title, minValue, maxValue, default, decimals)
    local element = section:CreateSlider({
        Title = title,
        Min = minValue,
        Max = maxValue,
        Default = default,
        Decimals = decimals or 0,
        Callback = function(value)
            Macro.sliders[title] = value
        end,
    })
    return element
end

--------------------------------------------------------------------------------
-- window  (script.txt:2485)
--------------------------------------------------------------------------------

local Window = Lib:CreateWindow({
    Title = "MacrOS",
    Author = "Build A Boat For Treasure",
    Icon = "ship",
    Logo = "rbxassetid://139568612294283",

    Size = UDim2.fromOffset(640, 480),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(980, 720),

    ToggleKey = Enum.KeyCode.LeftControl,
    Resizable = true,
    Folder = "MacrOS",
})

Window:Tag({ Title = "v2.2", Icon = "tag" })

-- ==============================================================================
-- AutoBuild tab group  (script.txt:4778 + 9092-9097)
-- ==============================================================================
local AutoBuild = Window:CreateTabGroup({
    Title = "AutoBuild",
    Icon = "hammer",
})

local BuildTab = AutoBuild:CreateTab({ Title = "Build", Icon = "hammer", Locked = false })
local ShapeTab = AutoBuild:CreateTab({ Title = "Shape", Icon = "shapes", Locked = false })
local ImageTab = AutoBuild:CreateTab({ Title = "Image", Icon = "image", Locked = false })
local TextTab = AutoBuild:CreateTab({ Title = "Text", Icon = "type", Locked = false })
local CopyTab = AutoBuild:CreateTab({ Title = "Copy Base", Icon = "copy", Locked = false })
local SetTab = AutoBuild:CreateTab({ Title = "Build Settings", Icon = "settings", Locked = false })

-- ── Build ────────────────────────────────────────────────────────────────────
do
    local Share = BuildTab:CreateSection({ Title = "Preview | Build", Icon = "eye", Column = 1, Opened = true })

    local row = Share:CreateHStack({ Padding = 8 })
    row:CreateButton({ Title = "Preview", Width = 96 })
    row:CreateButton({ Title = "Build", Width = 96 })

    local axes = Share:CreateHStack({ Padding = 8 })
    bindSlider(axes, "X", -128, 128, 0)
    bindSlider(axes, "Y", -128, 128, 0)
    bindSlider(axes, "Z", -128, 128, 0)

    local status = BuildTab:CreateSection({ Title = "Status", Icon = "activity", Column = 2, Opened = true })
    local bar = status:CreateProgressBar({ Title = "Loading", Default = 0 })
    status:CreateParagraph({
        Title = "Blocks Needed",
        Content = "0 / 0",
    })
    Macro.buildProgress = bar
end

-- ── Shape ────────────────────────────────────────────────────────────────────
do
    local shapes = ShapeTab:CreateSection({ Title = "Shape Engine", Icon = "shapes", Column = 1, Opened = true })
    shapes:CreateDropdown({
        Title = "Shape",
        Values = {
            { Title = "Sphere", Icon = "circle" },
            { Title = "Cylinder", Icon = "loader-circle" },
            { Title = "Pyramid", Icon = "triangle-alert" },
            { Title = "Wedge", Icon = "move" },
            { Title = "Cube", Icon = "box" },
        },
        Default = 1,
    })
    bindSlider(shapes, "Radius", 1, 64, 16)
    bindSlider(shapes, "Bands", 1, 32, 8)

    local extras = ShapeTab:CreateSection({ Title = "Extras", Icon = "palette", Column = 2, Opened = true })
    bindToggle(extras, "Voxel Fill", "Fill the shape with blocks")
    bindToggle(extras, "Watertight", "Seal the round shapes")
end

-- ── Image ────────────────────────────────────────────────────────────────────
do
    local image = ImageTab:CreateSection({ Title = "Load Image", Icon = "image", Column = 1, Opened = true })
    image:CreateInput({
        Title = "Image URL",
        Placeholder = "https://...",
        Default = "",
    })
    local actions = image:CreateHStack({ Padding = 8 })
    actions:CreateButton({ Title = "Load", Width = 90 })
    actions:CreateButton({ Title = "Clear", Width = 90 })
end

-- ── Text ──────────────────────────────────────────────────────────────────────
do
    local text = TextTab:CreateSection({ Title = "Text", Icon = "type", Column = 1, Opened = true })
    text:CreateInput({ Title = "Content", Placeholder = "hello", Default = "" })
    bindSlider(text, "Size", 1, 100, 10)
    local colors = text:CreateHStack({ Padding = 8 })
    colors:CreateColorpicker({ Title = "Color", Default = Color3.fromRGB(246, 92, 82) })
end

-- ── Copy Base ─────────────────────────────────────────────────────────────────
do
    local copy = CopyTab:CreateSection({ Title = "Copy Base", Icon = "copy", Column = 1, Opened = true })
    copy:CreateInput({ Title = "Base64", Placeholder = "paste a build string", Default = "" })
    local row = copy:CreateHStack({ Padding = 8 })
    row:CreateButton({ Title = "Copy", Width = 90 })
    row:CreateButton({ Title = "Paste", Width = 90 })
end

-- ── Build Settings ───────────────────────────────────────────────────────────
do
    local files = SetTab:CreateSection({ Title = "Files", Icon = "folder-open", Column = 1, Opened = true })
    files:CreateDropdown({
        Title = "Saved Builds",
        Values = { "no builds yet" },
        Default = 1,
    })
    local row = files:CreateHStack({ Padding = 8 })
    row:CreateButton({ Title = "Delete", Width = 90 })
    row:CreateButton({ Title = "Reload", Width = 90 })

    local behaviour = SetTab:CreateSection({ Title = "Behaviour", Icon = "settings", Column = 2, Opened = true })
    bindSlider(behaviour, "Remote Window", 64, 512, 256)
    bindToggle(behaviour, "Local First", "Move locally before the server answers")
    behaviour:CreateColorpicker({ Title = "Highlight Color", Default = Color3.fromRGB(246, 92, 82) })
end

--------------------------------------------------------------------------------
-- Halloween  (script.txt:4008)
--------------------------------------------------------------------------------
local HalloweenOpen = true

local HalloweenTab = Window:CreateTab({
    Title = HalloweenOpen and "Halloween" or "Soon",
    Icon = "ghost",
    Locked = not HalloweenOpen,
    LockMessage = "Halloween drops later this season.",
})

do
    local farm = HalloweenTab:CreateSection({ Title = "Candy Farm", Icon = "gift", Column = 1, Opened = true })
    bindToggle(farm, "Auto Collect", "Grabs every candy that spawns")
    bindToggle(farm, "Auto Eat", "Keeps the bar full")

    local stats = HalloweenTab:CreateSection({ Title = "Session Stats", Icon = "chart", Column = 2, Opened = true })
    bindSlider(stats, "Candy Collected", 0, 10000, 0)
    bindSlider(stats, "Candy Eaten", 0, 10000, 0)

    local hop = HalloweenTab:CreateSection({ Title = "Server Hopping", Icon = "refresh-cw", Column = 1, Opened = false })
    hop:CreateHStack({ Padding = 8 }):CreateButton({ Title = "Hop", Width = 90 })
end

--------------------------------------------------------------------------------
-- Auto Farm  (script.txt:11020)
--------------------------------------------------------------------------------
local AutoFarmTab = Window:CreateTab({ Title = "Auto Farm", Icon = "coins", Locked = false })

do
    local farm = AutoFarmTab:CreateSection({ Title = "Farm", Icon = "bot", Column = 1, Opened = true })
    bindToggle(farm, "Farm Quests", nil, true)
    bindToggle(farm, "Auto Gems", nil, false)
    bindToggle(farm, "Auto Gold", nil, false)

    local webhook = AutoFarmTab:CreateSection({ Title = "Webhook", Icon = "webhook", Column = 2, Opened = false })
    webhook:CreateInput({ Title = "URL", Placeholder = "https://discord.com/...", Default = "" })
    bindToggle(webhook, "Send Drops", nil, true)
    webhook:CreateColorpicker({ Title = "Embed Color", Default = Color3.fromRGB(246, 92, 82) })
end

--------------------------------------------------------------------------------
-- Quests  (script.txt:11206)
--------------------------------------------------------------------------------
local QuestsTab = Window:CreateTab({ Title = "Quests", Icon = "scroll-text" })

do
    local special = QuestsTab:CreateSection({ Title = "Special", Icon = "infinity", Column = 1, Opened = false })
    bindToggle(special, "Thin Ice", "Skate over the thin ice quests")
    bindToggle(special, "The Box", "Picks the crate quest")
    bindToggle(special, "Find Me", "Runs the hide and seek quest")

    local auto = QuestsTab:CreateSection({ Title = "Auto Quests", Icon = "list-checks", Column = 2, Opened = false })
    auto:CreateDropdown({
        Title = "Order",
        Multi = true,
        Values = { "Cloud", "Target", "Ramp", "Find Me", "The Box", "Thin Ice" },
        Default = { "Cloud", "Target" },
    })
    bindToggle(auto, "Stop On Fail", nil, true)

    local single = QuestsTab:CreateSection({ Title = "Single Quests", Icon = "scroll-text", Column = 1, Opened = false })
    single:CreateDropdown({ Title = "Quest", Values = { "Cloud", "Target", "Ramp" }, Default = 1 })
    single:CreateHStack({ Padding = 8 }):CreateButton({ Title = "Run", Width = 90 })
end

--------------------------------------------------------------------------------
-- Shop  (script.txt:12432)
--------------------------------------------------------------------------------
local ShopTab = Window:CreateTab({ Title = "Shop", Icon = "store", Locked = false })

do
    local checkout = ShopTab:CreateSection({ Title = "Checkout", Icon = "shopping-cart", Column = 1, Opened = true })
    checkout:CreateDropdown({
        Title = "Basket",
        Multi = true,
        Values = {
            { Title = "Wood Block", Icon = "package" },
            { Title = "Smooth Wood Block", Icon = "package" },
            { Title = "Iron Block", Icon = "box" },
            { Title = "Gold Block", Icon = "coins" },
        },
        Default = {},
    })
    bindSlider(checkout, "Quantity", 1, 512, 1)
    checkout:CreateButton({ Title = "Buy Basket" })

    local catalog = ShopTab:CreateSection({ Title = "Catalog", Icon = "package", Column = 2, Opened = false })
    catalog:CreateParagraph({
        Title = "Categories",
        Content = "Chests, Blocks and Boats are filled in after the menu opens.",
    })
    local bar = catalog:CreateProgressBar({ Title = "Loading catalog", Default = 0 })
    Macro.catalogProgress = bar
end

--------------------------------------------------------------------------------
-- Visual  (script.txt:12860)
--------------------------------------------------------------------------------
local VisualTab = Window:CreateTab({ Title = "Visual", Icon = "eye", Locked = false })

do
    local items = VisualTab:CreateSection({ Title = "Give Items", Icon = "package", Column = 1, Opened = false })
    items:CreateDropdown({
        Title = "Item",
        Values = {
            { Title = "Wood Block", Icon = "package" },
            { Title = "Smooth Wood Block", Icon = "package" },
            { Title = "Iron Block", Icon = "box" },
        },
        Default = 1,
    })
    bindSlider(items, "Amount", 1, 100, 1)

    local gold = VisualTab:CreateSection({ Title = "Give Gold", Icon = "coins", Column = 2, Opened = false })
    bindSlider(gold, "Gold", 0, 1000000, 1000)

    local gift = VisualTab:CreateSection({ Title = "Gift", Icon = "gift", Column = 1, Opened = false })
    gift:CreateInput({ Title = "Username", Placeholder = "target", Default = "" })
    bindSlider(gift, "Amount", 1, 100, 1)

    local tag = VisualTab:CreateSection({ Title = "Tag", Icon = "tag", Column = 2, Opened = false })
    tag:CreateDropdown({
        Title = "Tag",
        Values = { "Guest", "VIP", "Mod", "Owner" },
        Default = 1,
    })
    bindToggle(tag, "Show Above Head", nil, true)

    local slot = VisualTab:CreateSection({ Title = "Slot", Icon = "ethernet-port", Column = 1, Opened = false })
    bindSlider(slot, "Slot", 1, 20, 1)
    bindToggle(slot, "Copy Slot", nil, false)
end

--------------------------------------------------------------------------------
-- Players  (script.txt:14591)
--------------------------------------------------------------------------------
local PlayersTab = Window:CreateTab({ Title = "Players", Icon = "users", Locked = false })

do
    local checker = PlayersTab:CreateSection({ Title = "Checker", Icon = "search", Column = 1, Opened = false })
    checker:CreateDropdown({ Title = "Player", Values = { "Nobody" }, Default = 1 })
    checker:CreateDropdown({ Title = "Part", Values = { "Head", "Torso", "Left Arm" }, Default = 1 })
    bindToggle(checker, "Copy Slots", nil, false)

    local spoofer = PlayersTab:CreateSection({ Title = "Spoofer", Icon = "gauge", Column = 2, Opened = false })
    bindSlider(spoofer, "Speed", 16, 200, 16)
    bindSlider(spoofer, "Jump", 50, 300, 50)
    bindToggle(spoofer, "Remove Hat", nil, false)
    spoofer:CreateColorpicker({ Title = "Nametag Color", Default = Color3.fromRGB(246, 92, 82) })
end

--------------------------------------------------------------------------------
-- Misc  (script.txt:15067)
--------------------------------------------------------------------------------
local MiscTab = Window:CreateTab({ Title = "Misc", Icon = "settings", Locked = false })

do
    local language = MiscTab:CreateSection({ Title = "Language", Icon = "languages", Column = 1, Opened = false })
    language:CreateDropdown({
        Title = "Language",
        Values = { "English", "Russian", "Chinese", "Japanese", "Vietnamese" },
        Default = 1,
    })

    local general = MiscTab:CreateSection({ Title = "General", Icon = "wrench", Column = 2, Opened = false })
    general:CreateButton({ Title = "Redeem All Codes", Desc = "Activates every known code" })
    bindToggle(general, "Anti AFK", nil, true)
    bindToggle(general, "Anti Ban", nil, true)

    local client = MiscTab:CreateSection({ Title = "Client", Icon = "monitor", Column = 1, Opened = false })
    bindToggle(client, "FPS Booster", nil, false)
    bindSlider(client, "Render Distance", 50, 500, 200)
    client:CreateHStack({ Padding = 8 }):CreateButton({ Title = "Rejoin", Width = 90 })

    local teleport = MiscTab:CreateSection({ Title = "Teleport To Place", Icon = "map-pin", Column = 2, Opened = false })
    teleport:CreateInput({ Title = "Place ID", Placeholder = "0000000", Default = "" })
    teleport:CreateButton({ Title = "Teleport" })

    local feedback = MiscTab:CreateSection({ Title = "Feedback", Icon = "message-square", Column = 1, Opened = false })
    feedback:CreateParagraph({ Title = "Discord", Content = "Paste the invite below to reach the crew." })
    feedback:CreateInput({ Title = "Invite", Placeholder = "discord.gg/...", Default = "" })

    local look = MiscTab:CreateSection({ Title = "Appearance", Icon = "palette", Column = 2, Opened = false })
    look:CreateDropdown({ Title = "Theme", Values = Lib:GetThemes(), Default = 1 })
    bindSlider(look, "UI Scale", 80, 140, 100)

    local settings = MiscTab:CreateSection({ Title = "Settings", Icon = "settings", Column = 1, Opened = false })
    settings:CreateKeybind({ Title = "Toggle UI", Default = "RightShift" })
    settings:CreateKeybind({ Title = "Panic", Default = "End" })
    settings:CreateKeybind({ Title = "Toggle Key", Default = "LeftControl" })
    settings:CreateHStack({ Padding = 8 }):CreateButton({ Title = "Center", Width = 90 })

    local icons = MiscTab:CreateSection({ Title = "3D Icons", Icon = "box", Column = 2, Opened = false })
    bindToggle(icons, "Flat Icons", "Render the icon pack as flat images", true)
    bindToggle(icons, "Cache On Disk", "Keeps the icon pack in MacrOS/cache", true)
end

--------------------------------------------------------------------------------
-- Credits  (script.txt:15485)
--------------------------------------------------------------------------------
local CreditsTab = Window:CreateTab({ Title = "Credits", Icon = "layers", Locked = false })

do
    local credits = CreditsTab:CreateSection({ Title = "Credits", Icon = "layers", Column = 1, Opened = true })
    credits:CreateParagraph({
        Title = "MacrOS",
        Content = "UI: MacrOS UI (lib/macros-ui.lua)\nIcons: Footagesus / Lucide",
    })

    local actions = CreditsTab:CreateSection({ Title = "Links", Icon = "send", Column = 2, Opened = true })
    actions:CreateButton({ Title = "Copy Webhook" })
    actions:CreateButton({ Title = "Join Discord" })
end

--------------------------------------------------------------------------------
-- finish
--------------------------------------------------------------------------------

-- The menu opens on Build, like script.txt does in MacrOS.finish.
BuildTab:Select()
Window:SetToTheCenter()

return {
    Library = Lib,
    Window = Window,
    Toggles = Macro.toggles,
    Sliders = Macro.sliders,
}