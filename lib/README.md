# MacrOS UI

The MacrOS interface as a reusable library — the "pasta" look from `ui.txt`
(dark rounded cards, red accent, two-column layout, sidebar with search),
plus a real **tab system**, which the original mock-up only hinted at.

It replaces WindUI: same call sites, new visuals, no external download on
every launch.

```
lib/macros-ui.lua     the whole library (one self-contained file)
example/macros-tabs.lua   script.txt's tab tree rebuilt on this UI
```

---

## Install

There is nothing to install. The file returns its own table:

```lua
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dragonstrukov/MacrOS/refs/heads/main/lib/macros-ui.lua"
))()

local Window = Lib:CreateWindow({
    Title  = "MacrOS",
    Author = "Build A Boat For Treasure",
    Icon   = "ship",
    Logo   = "rbxassetid://139568612294283",

    Size       = UDim2.fromOffset(790, 490),
    MinSize    = Vector2.new(500, 320),
    MaxSize    = Vector2.new(1200, 900),
    ToggleKey  = Enum.KeyCode.LeftControl,
    Resizable  = true,
    Folder     = "MacrOS",
})
```

The window already has: draggable title bar, bottom-right resize grip,
sidebar search, version badge, `Tag` pills and a toggle key.

---

## Tabs

```lua
local Tab = Window:CreateTab({
    Title  = "Auto Farm",
    Icon   = "coins",
    Locked = false,        -- renders a padlock and refuses to open
})
Tab:Select()              -- open it
Tab:SetTitle("Farming")   -- rename the sidebar entry
Tab:SetLocked(true)       -- lock / unlock later
```

Group tabs under a sidebar category (this is `Window:Section{...}` in WindUI):

```lua
local AutoBuild = Window:CreateTabGroup({ Title = "AutoBuild", Icon = "hammer" })

local BuildTab  = AutoBuild:CreateTab({ Title = "Build",         Icon = "hammer" })
local ShapeTab  = AutoBuild:CreateTab({ Title = "Shape",         Icon = "shapes" })
local ImageTab  = AutoBuild:CreateTab({ Title = "Image",         Icon = "image" })
local TextTab   = AutoBuild:CreateTab({ Title = "Text",          Icon = "type" })
local CopyTab   = AutoBuild:CreateTab({ Title = "Copy Base",     Icon = "copy" })
local SetTab    = AutoBuild:CreateTab({ Title = "Build Settings",Icon = "settings" })
```

`Window:Section{...}:Tab{...}` still works if you prefer the old spelling.

## Sections (the cards)

```lua
local Card = Tab:CreateSection({
    Title  = "Fighting",
    Icon   = "skull",
    Column = 1,        -- optional, 1 or 2 — omit it and cards alternate
    Opened = true,     -- false starts collapsed
})

Card:SetOpen(false)
Card.IsOpen()
```

## Components

Every component returns a handle, so you can read and write it later.

```lua
Card:CreateToggle({
    Title    = "Attack Aura",
    Desc     = "swings for you",
    Default  = false,
    Callback = function(value) print("aura", value) end,
})

Card:CreateSlider({
    Title    = "Sensitivity",
    Min      = 1,
    Max      = 100,
    Default  = 50,
    Step     = 1,       -- optional snap
    Decimals = 0,
    Callback = function(value) print("sens", value) end,
})

Card:CreateInput({
    Title       = "Username",
    Placeholder = "type here...",
    Default     = "",
    Callback    = function(text) print("user", text) end,
})

Card:CreateDropdown({
    Title   = "Mode",
    Values  = { "Legit", "Rage", "Silent" },   -- or { Title = "Legit", Icon = "eye" }
    Default = 1,                              -- index, value or title
    Multi   = false,                          -- true = multi-select
    Callback = function(value, index) print(value, index) end,
})

Card:CreateColorpicker({ Title = "Highlight Color", Default = Color3.fromRGB(246, 92, 82) })
Card:CreateProgressBar({ Title = "Loading", Default = 0.65, Interactive = true })
Card:CreateKeybind({ Title = "Panic", Default = "End" })
Card:CreateButton({ Title = "Save", Width = 90 })      -- width optional
Card:CreateLabel("VALUES")                            -- small caption
Card:CreateDivider()                                  -- hairline
Card:CreateParagraph({ Title = "Note", Content = "free text" })
Tab:CreateParagraph({ Title = "Combat", Content = "anything" })  -- outside a card
```

### Rows and columns

```lua
local row = Card:CreateHStack({ Padding = 8 })
row:CreateButton({ Title = "Save",  Width = 96 })
row:CreateButton({ Title = "Reset", Width = 96 })

local column = Card:CreateVStack({ Padding = 6 })
column:CreateToggle({ Title = "Nested" })
```

An `HStack` is itself a container, so any component can be dropped into it.

### Handles

| method | on | returns |
| --- | --- | --- |
| `SetValue(v, fire)` / `GetValue()` | toggle, slider, input, dropdown, colourpicker, progress bar, keybind | updates the widget, fires the callback |
| `SetTitle(t)` / `SetDesc(d)` | any labelled widget | updates the labels |
| `SetVisible(state)` / `GetVisible()` | any widget | shows / hides |
| `Destroy()` | any widget | removes it |
| `GetOptions()` / `Refresh()` | dropdown | reads / repaints |
| `SetOpen(state)` / `IsOpen()` | section card | collapses the body |

## Window

```lua
Window:Toggle()             -- show / hide (or Toggle(true|false))
Window:SetTitle("MacrOS NG")
Window:SetAuthor("Build A Boat For Treasure")
Window:SetVersion("v2.2")
Window:SetToTheCenter()
Window:SetToggleKey("LeftControl")     -- name or Enum.KeyCode
Window:SelectTab(CombatTab)
Window:GetTabs()
Window:Tag({ Title = "v2.2", Icon = "tag" })
Window:EditOpenButton({ Enabled = true, Callback = function() end })
Window:Destroy()
```

## Notifications and dialogs

```lua
Lib:Notify({
    Title    = "Saved",
    Desc     = "config written to disk",
    Icon     = "check",
    Type     = "Success",   -- Success | Error | Warning | Info
    Duration = 3,
})

Window:Dialog({
    Title      = "Confirm",
    Content    = "Rejoin the server?",
    ConfirmText = "Yes",
    CancelText = "No",
    Callback   = function(confirmed) end,
    OnClose    = function() end,
})
```

## HUD watermark

```lua
local hud = Lib:CreateHUD({ Brand = "pasta", Logo = "rbxassetid://139568612294283" }, Window)
hud:SetVisible(false)
hud.Destroy()
```

Shows brand, player, FPS, clock, position, ping, tick rate and walk speed —
the same pills as `ui.txt`.

## Themes

Four are bundled and switching is live: every painted instance is registered
and recoloured in place, so the open menu changes theme without a rebuild.

```lua
Lib:GetThemes()          -- { "Pasta", "Midnight", "Frost", "Toxic" }
Lib:SetTheme("Midnight")
```

`Lib.Theme` is the live table. Add your own:

```lua
Lib.Themes.Ocean = { Name = "Ocean", Background = Color3.fromRGB(8, 12, 24), /* ... */ }
Lib:SetTheme("Ocean")
```

## Icons

Any Lucide name from `Lib.Lucide` works, as does an `rbxassetid://` URL.

```lua
Lib:GetIcon("zap")                    -- lucide id
Lib:GetIcon("rbxassetid://12345")     -- passed through
Lib:GetIcon("does-not-exist")         -- nil
```

`Lib.Icons` holds the monochrome set used by the chrome (search, chevron,
menu, HUD glyphs). `Lib.Lucide` holds ~90 Lucide glyphs for tabs and sections.

---

## Coming from WindUI

| WindUI | MacrOS UI |
| --- | --- |
| `WindUI:CreateWindow{...}` | `Lib:CreateWindow{...}` |
| `Window:Tab{...}` | `Window:CreateTab{...}` |
| `Window:Section{...}:Tab{...}` | `Window:CreateTabGroup{...}:CreateTab{...}` |
| `Tab:Section{...}` | `Tab:CreateSection{...}` |
| `Section:Toggle{...}` | `Section:CreateToggle{...}` |
| `Section:Slider{...}` | `Section:CreateSlider{...}` |
| `Section:Input{...}` | `Section:CreateInput{...}` |
| `Section:Dropdown{...}` | `Section:CreateDropdown{...}` |
| `Section:Colorpicker{...}` | `Section:CreateColorpicker{...}` |
| `Section:Keybind{...}` | `Section:CreateKeybind{...}` |
| `Section:Paragraph{...}` | `Section:CreateParagraph{...}` |
| `Section:Divider()` | `Section:CreateDivider()` |
| `Section:HStack{...}` | `Section:CreateHStack{...}` |
| `WindUI:Notify{...}` | `Lib:Notify{...}` |
| `Window:Dialog{...}` | `Window:Dialog{...}` |
| `WindUI:GetThemes()` / `SetTheme(n)` | `Lib:GetThemes()` / `Lib:SetTheme(n)` |
| `element:SetValue(v)` / `GetValue()` | same |
| `element:Select()` (dropdown) | `element:SetValue(value)` |
| `Tab:Select()` | same |

`example/macros-tabs.lua` is the whole `script.txt` menu on this UI.