# MacrOS

Cheat scripts for Roblox games, plus **MacrOS UI** — the in-game interface
that used to be WindUI, now a library in this repo.

```
loader.lua                  picks the right script for the game you are in
Build-A-Boat-For-Treasure/  Build A Boat For Treasure + private servers
Life-in-Prison/             Life in Prison
Untitled/                   anything else

lib/macros-ui.lua           the UI library (new look, tabs, no download)
lib/README.md               API reference
example/macros-tabs.lua     script.txt's tab tree on the new UI
```

---

## The UI

The menu used to pull WindUI from GitHub on every launch, which cost startup
time and broke whenever the release moved. The interface is now a single file
that lives in this repo:

```lua
local Lib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dragonstrukov/MacrOS/refs/heads/main/lib/macros-ui.lua"
))()

local Window = Lib:CreateWindow({ Title = "MacrOS", Author = "Build A Boat For Treasure", Icon = "ship" })

local Tab  = Window:CreateTab({ Title = "Auto Farm", Icon = "coins" })
local Card = Tab:CreateSection({ Title = "Farm", Icon = "bot" })

Card:CreateToggle({ Title = "Farm Quests", Default = true })
Card:CreateSlider({ Title = "Teleport Speed", Min = 1, Max = 100, Default = 50 })
```

What changed on top of a reskin:

* **Real tabs.** The sidebar entries switch content instead of only changing
  colour, and tabs can be grouped under a category header.
* **No download per launch.** One file, fetched once (or cached by your loader).
* **Live themes.** `Lib:SetTheme("Midnight")` recolours the open menu in
  place — no rebuild, no flicker.
* **Search** filters every row in every tab and jumps to the first hit.
* **Extra components** the old UI.txt mock-up had but WindUI did not expose:
  progress bars and multi-select dropdowns with per-option icons.
* **HUD watermark** (FPS, ping, position, speed, tick rate) as part of the
  library instead of copy-pasted into each script.

Full reference: [`lib/README.md`](lib/README.md).

## Migrating a script off WindUI

Call sites barely move:

```lua
-- before
local WindUI = MacrOS.loadWindUI()
local Window  = WindUI:CreateWindow({ ... })
local Tab     = Window:Tab({ Title = "Auto Farm", Icon = "coins" })
local Section = Tab:Section({ Title = "Farm", Icon = "bot" })
Section:Toggle({ Title = "Farm Quests", Callback = fn })

-- after
local Lib    = loadstring(game:HttpGet(LIB_URL))()
local Window = Lib:CreateWindow({ ... })
local Tab    = Window:CreateTab({ Title = "Auto Farm", Icon = "coins" })
local Section = Tab:CreateSection({ Title = "Farm", Icon = "bot" })
Section:CreateToggle({ Title = "Farm Quests", Callback = fn })
```

The element handles keep the same shape — `SetValue`, `GetValue`,
`SetVisible`, `Destroy` — so the game logic above the UI does not change.

`example/macros-tabs.lua` shows the complete `script.txt` menu rebuilt on the
new UI, tab for tab and section for section.

## Running a script

Paste `loader.lua` into your executor. It checks `game.PlaceId` and loads the
matching script from `main`.

## Disclaimer

These scripts are for private servers and for testing on accounts you own.
Using them in public servers will get you banned, and it is unfair to the
people playing with you.