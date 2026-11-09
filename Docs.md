# Astral Documentation

A comprehensive, modern Roblox UI library documentation.

## Table of Contents

- [1. Getting Started](#1-getting-started)
- [2. Installation & Loading](#2-installation--loading)
- [3. UI Structure](#3-ui-structure)
  - [Tabs](#tabs)
  - [Tabboxes](#tabboxes)
  - [Groupboxes & Sections](#groupboxes--sections)
- [4. UI Elements](#4-ui-elements)
  - [Labels](#labels)
  - [Buttons](#buttons)
  - [Toggles](#toggles)
  - [Checkboxes](#checkboxes)
  - [Sliders & Progress Bars](#sliders--progress-bars)
  - [Inputs](#inputs)
  - [Dropdowns](#dropdowns)
  - [Keybinds](#keybinds)
  - [Color Pickers](#color-pickers)
  - [Dividers](#dividers)
  - [Images](#images)
  - [Videos](#videos)
  - [Viewports](#viewports)
  - [UI Passthrough](#ui-passthrough)
- [5. Core Systems & Overlays](#5-core-systems--overlays)
  - [Notifications](#notifications)
  - [Dialogs](#dialogs)
  - [Overlays & Draggable Panels](#overlays--draggable-panels)
  - [Loading Screens](#loading-screens)
  - [Keybind Menu](#keybind-menu)
  - [Utility & Helper Methods](#utility--helper-methods)
- [6. Addons](#6-addons)
  - [SaveManager](#savemanager)
  - [ThemeManager](#thememanager)
- [7. Icon Reference](#7-icon-reference)
- [8. Advanced Utilities & Mobile Support](#8-advanced-utilities--mobile-support)
- [9. Contributing](#9-contributing)

---

## Getting Started

Getting Started with Astral

---

### Setup & Loading

The library is loaded via `loadstring` or by requiring the module directly:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/Astral.lua"))()
```

Once loaded, `Library` is also stored in `getgenv().Library` for global access. On re-execution, any existing Astral `ScreenGui` is automatically destroyed or cleanly unloaded before the new instance is created.

> Elements are stored in the Library object, not as global variables:
> - `Library.Toggles` -- All toggle/checkbox elements
> - `Library.Buttons` -- All button elements
> - `Library.Options` -- All input, slider, dropdown, and other option elements
> - `Library.Labels` -- All label elements

```lua
Library.Toggles.MyToggle:SetState(true)
```

---

### Example Script

A comprehensive example demonstrating all UI features, rich text formatting, and advanced functionality is available at `Example.lua` in the repository:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/Example.lua"))()
```

The example includes:

- All element types with various configurations
- Rich text formatting throughout the UI
- Addons (SaveManager, ThemeManager) integration
- Advanced features: conditional groups, keybinds, color pickers
- Dialogs, notifications, loading screens
- Dropdown methods: `SetSelectedValue`, `DeselectValue`, `ClearSelectedValues`
- Auto-deselect behavior when values are removed from dropdowns

---

## Installation

How to load Astral, its addons, and required dependencies.

---

### Loading the Library

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/Astral.lua"))()
```

`Library` is also stored in `getgenv().Library` for global access. On re-execution, any existing Astral `ScreenGui` is automatically destroyed or cleanly unloaded before the new instance is created.

---

### Loading Addons

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/ThemeManager.lua"))()

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
```

See [SaveManager](#savemanager) and [ThemeManager](#thememanager) for full setup details.

---

### Icon Dependency

Astral is dependent on a few icons to be able to be displayed properly. Make sure the icon module in use provides icons named `check`, `chevron-up`, `move-diagonal-2`, `key`, `search`, and `move`. See [Utility -> Icons](#utility--helper-methods) for the full custom icon registry reference.

---

## Structuring

Understand how Astral's Library, Window, Tab, and Section objects fit together.

---

### Library Object

The root `Library` table contains global state and utility methods.

#### Key Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Library.Toggled` | boolean | `false` | Whether the main window is visible |
| `Library.ToggleKeybind` | KeyCode | `RightControl` | Keybind to show/hide the window |
| `Library.NotifySide` | string | `"Right"` | Side for notifications (`"Left"` or `"Right"`) |
| `Library.ShowCustomCursor` | boolean | `false` | Show the library's crosshair custom cursor |
| `Library.ForceCheckbox` | boolean | `false` | Read-only reflection of the last value passed to `Library:SetForceCheckbox`. Use `Library:SetForceCheckbox(true/false)` instead of setting this directly -- it also flips every already-created `AddToggle` toggle live |
| `Library.IsMobile` | boolean | auto | Whether the local device is mobile |
| `Library.NotifyOnError` | boolean | `false` | Show a notification when a callback errors |
| `Library.DPIScale` | number | `1` | Current global scale factor set via `Library:SetDPIScale` (percentage / 100) |
| `Library.AutoDPIScale` | boolean | `true` | Whether the UI scale follows the screen size automatically. While on, the window is capped to fit the viewport with 5% margins on each side |
| `Library.ShowToggleFrameInKeybinds` | boolean | `true` | Show the toggle checkbox in the keybind list |
| `Library.HighlightSearchResults` | boolean | `true` | Tint the matching substring of search results with the accent colour |
| `Library.WaitForIconsOnLoad` | boolean | `true` | Wait for icons to load before creating windows/loading screens |
| `Library.Animations` | table | all `false` | `ToggleWindow` (window fade) and `TabSwitch` (swipe transition) animations; see `Window:SetAnimations` |
| `Library.TabTransitionInfo` | TweenInfo | `0.22s Quad Out` | Timing for the tab-switch swipe |
| `Library.TabSwipeOffset` | number | `26` | Swipe distance in pixels for tab transitions |
| `Library.TabSwipeFrom` | string | `"bottom"` | Swipe direction (`"left"`/`"right"`/`"top"`/`"bottom"`/`"auto"`) |
| `Library.IsPicking` | boolean | `false` | Whether any KeyPicker is currently capturing a bind |
| `Library.Window` | Window? | `nil` | The window created by `CreateWindow` |
| `Library.KeybindMenu` | table? | `nil` | The keybind menu object (collapse + visibility settings) |
| `Library.Scheme` | table | -- | The active color scheme |
| `Library.Toggles` | table | -- | All registered toggles, keyed by their `Idx` |
| `Library.Options` | table | -- | All registered options (inputs, sliders, dropdowns, etc.) keyed by `Idx` |
| `Library.Labels` | table | -- | All registered labels |
| `Library.Buttons` | table | -- | All registered buttons |

---

### Creating a Window

```lua
local Window = Library:CreateWindow({
    Title        = "My Script",
    Subtitle     = nil,            -- small, light text under the title
    TitleAlignment = "Center",     -- "Left" | "Center" | "Right": where the title block sits and how the title aligns
    SubtitleAlignment = nil,       -- same options; nil follows TitleAlignment
    SubtitleSize = 12,
    SubtitleTransparency = 0.45,
    TitleColor   = nil,            -- Color3, nil = theme font color
    SubtitleColor = nil,
    Footer       = "v1.0.0",       -- middle of the footer
    FooterLeft   = nil,            -- text on the left of the footer
    FooterRight  = nil,            -- text on the right of the footer
    FooterSize   = 14,
    PopOutBoxes  = true,           -- pop-out button on every section header
    TabButtonsStyle = {
        Gap = 2,                   -- space between sidebar tab buttons
        Padding = 0,               -- extra space around the tab list
        CornerRadius = 0,          -- rounds tab buttons
        Indicator = false,         -- accent bar on the left of the active tab
        IndicatorWidth = 3,
        IndicatorHeight = 18,
    },
    Transparency = 0,              -- 0 (opaque) to 0.85
    Gradient     = true,           -- gradient across the whole window
    GradientColor = nil,           -- end color; nil = derived from the theme
    GradientRotation = 45,
    Icon         = nil,
    IconSize     = UDim2.fromOffset(30, 30),
    Size         = UDim2.fromOffset(720, 600),
    Position     = UDim2.fromOffset(6, 6),
    Center       = true,
    AutoShow     = true,
    Resizable    = true,
    AlwaysOnTop  = false,
    CornerRadius = 6,
    Font         = Enum.Font.GothamMedium,
    TitleSize    = 20,
    DPIScale     = 5,
    ToggleKeybind = Enum.KeyCode.RightControl,
    SearchbarSize = UDim2.fromScale(1, 1),
    DisableSearch = false,
    HighlightSearchResults = true,
    NotifySide = "Right",
    ShowCustomCursor = false,
    BackgroundImage = nil,
    SidebarCompacted = false,
    CompactSidebarTooltips = true,
    SidebarWidth = nil,
    MinContainerWidth = 256,
    EnableSidebarResize = true,
    Bubble = nil,
    BubbleSide = "Right",
    BubbleIcon = "menu",
    BubbleIconColor = nil,
    BubbleColor = nil,
    BubbleSize = UDim2.fromOffset(50, 50),
    BubbleCornerRadius = 25,
    BubblePadding = 12,
    UnlockMouseWhileOpen = true,
    DiscordLink = nil,
    DiscordAction = "open",
    SingleInstance = true,
    WaitForIconsOnLoad = nil,
    Snapping = false,
    SnapDistance = 28,
    SnapMargin = 8,
    SnapAvoidCoreGui = true,
    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Dropdown = false,
        KeyPicker = false,
    },
    TabTransitionTime = 0.22,
    TabSwipeOffset = 26,
    TabSwipeFrom = "bottom",
})
```

All fields are optional and fall back to sensible defaults. The window automatically opens on startup by default (`AutoShow = true`); set `AutoShow = false` to keep it hidden until toggled with the `ToggleKeybind` (default `RightControl`) or menu bubble.

> **`AutoShow = false` with `Bubble = true`:** if no config manager is attached (no `SetLibrary` call), setting `AutoShow = false` while also enabling `Bubble` still correctly hides the main window on startup **and** still creates and shows the floating bubble -- bubble creation is decoupled from the window's own auto-show/hide decision, so you don't lose access to the menu just because the window itself starts hidden.

> **Using SaveManager?** `SaveManager:SetLibrary(Library)` **must** be called *before* `Library:CreateWindow(...)`. `CreateWindow` decides synchronously, before it returns, whether to auto-show the window -- and it only skips that auto-show if `Library.DeferAutoShowTo` is already set at that exact moment. Calling `SetLibrary` after `CreateWindow` is too late: the window (and bubble, if enabled) may have already flashed default/unloaded values. See [Avoiding the "Flash of Default Values" on Startup](#avoiding-the-flash-of-default-values-on-startup) for the required setup order.
>
> `Library.AutoShow` is now set from `WindowInfo.AutoShow` inside `CreateWindow`, so `SaveManager:RevealAfterLoad` (which reads `Library.AutoShow` to decide whether to reveal the window/bubble once the saved config finishes loading) correctly sees whatever value you passed to `CreateWindow`, instead of always falling back to its own default.

The window has **Minimize** (`-`) and **Close** (`x`) buttons in the top-right. Minimize hides the window. Close hides and then calls `Library:Unload()`.

Prop

Type

`Title?`string

`Footer?`string

`Icon?`string

`Size?`UDim2

`Center?`boolean

`AutoShow?`boolean

`Resizable?`boolean

`AlwaysOnTop?`boolean

`CornerRadius?`number

`DPIScale?`number

`ToggleKeybind?`Enum.KeyCode

`NotifySide?`"Left" \| "Right"

`Bubble?`boolean

`SingleInstance?`boolean

---

### Window Methods

Methods on the `Window` object returned from `Library:CreateWindow`.

```lua
Window:ChangeTitle(title: string)
Window:SetTitleSize(size: number)
Window:SetTitleColor(Color: Color3?)
Window:SetSubtitle(subtitle: string?)
Window:SetSubtitleSize(size: number)
Window:SetSubtitleTransparency(Transparency: number)
Window:SetSubtitleColor(Color: Color3?)
Window:SetTitleAlignment(Alignment: "Left" | "Center" | "Right")
Window:SetSubtitleAlignment(Alignment: "Left" | "Center" | "Right" | nil)
Window:RefreshTitleSize()
Window:SetFooter(footer: string)                -- middle slot
Window:SetFooterLeft(text: string)
Window:SetFooterRight(text: string)
Window:AddFooterItem(Side: "Left" | "Middle" | "Right", Info: string | FooterItemInfo): FooterItem
Window:ClearFooter(Side: string?)
Window:SetTransparency(Value: number)           -- 0 to 0.85
Window:SetGradient(Enabled: boolean)
Window:SetCornerRadius(Radius: number)
Window:SetAlwaysOnTop(Enabled: boolean)
Window:SetSnapping(Enabled: boolean, Distance: number?, Margin: number?, AvoidCoreGui: boolean?)
Window:SetAnimations(Animations: { [string]: boolean }?, TabTransitionTime: number?, TabSwipeOffset: number?, TabSwipeFrom: string?)

Window:GetSidebarWidth(): number
Window:SetSidebarWidth(Width: number)
Window:IsSidebarCompacted(): boolean
Window:SetCompact(State: boolean)

Window:ShowTabInfo(Name: string, Description: string)
Window:HideTabInfo()

Window:SetBackgroundImage(Image: string)
```

`MinContainerWidth` (default `256`) is the minimum width the content area keeps when the sidebar is resized or the window is shrunk to a small viewport. `SetBackgroundImage` accepts custom icons and `http(s)` URLs (downloaded and cached), and works even when no image was set at creation. `SetSnapping` magnets the window to screen edges/center while dragging (with accent guide lines); `SetAnimations` toggles the window fade and tab-switch swipe at runtime.

#### Toggle Bubble

A floating, draggable "chat-head" style button that shows/hides the window and magnets to the nearest screen edge when dragged. By default it only appears on mobile (`Bubble = nil`), but it can be forced on or off for any platform.

```lua
local Window = Library:CreateWindow({
    Bubble           = true,
    BubbleSide       = "Right",
    BubbleIcon       = "menu",
    BubbleIconColor  = nil,
    BubbleColor      = nil,
    BubbleSize       = UDim2.fromOffset(50, 50),
    BubbleCornerRadius = 25,
    BubblePadding    = 12,
})
```

Tapping the bubble toggles the window; dragging it releases and animates a snap to whichever edge it's closest to.

---

### Tabs

Tabs, tab sections, and the Key Tab variant.

---

#### Adding a Tab

```lua
local Tab = Window:AddTab({
    Name        = "Main",
    Icon        = "home",
    Description = "Main tab",
    Tooltip     = nil,
    Order       = nil,
})

-- Shorthand (name only, no icon):
local Tab = Window:AddTab("Main")

-- With icon:
local Tab = Window:AddTab("Main", "home")
```

Tabs appear in the left sidebar. The first added tab is shown automatically. Only one tab is active at a time. `Order` controls sidebar position (defaults to creation order); `Tooltip` shows a hover tooltip on the tab button.

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Tab name or config table | string \| table | nil |
| 2 | Icon name (shorthand form only) | string? | nil |

##### Methods

```lua
Tab:Show()
Tab:Hide()
Tab:SetVisible(Visible: boolean)
Tab:SetOrder(NewOrder: number)
Tab:SetTooltip(Text: string?)
```

---

#### Collapsible Tab Sections

Tab sections group tab buttons in the sidebar under a collapsible header.

```lua
local Section = Window:AddTabSection({
    Name = "Combat",
    Icon = "swords",
    Open = true,
})

local Tab = Section:AddTab({
    Name = "Aimbot",
    Icon = "crosshair",
})
```

Clicking the section header toggles the group open/closed. When the sidebar is compact, the header label is hidden and the chevron is centered.

Prop

Type

`Name?`string

`Icon?`string

`Open?`boolean

---

#### Icons and Subtext

Most elements and sections can show an icon (a Lucide name, an asset id, or a picture) and a smaller, thinner line of subtext under the title.

```lua
Section:AddToggle("Lanes", {
    Text = "Advanced Lanes",
    Subtext = "% of the path, per lane",
    Icon = "git-branch",
    IconStyle = "Tile",      -- "Inline" (default, small icon) or "Tile" (accent icon tile)
    IconColor = nil,         -- tint for named icons; pictures keep their own colors
    IconBackground = nil,    -- Tile only: nil = accent gradient, false = bare icon, "Main", or a Color3
})
```

| Element | Icon | Subtext | IconStyle "Tile" |
| --- | --- | --- | --- |
| Toggle, Checkbox, Label | yes | yes | yes |
| Input, Slider, Dropdown (inline), Stepper | yes | yes | inline only |
| Table, PriorityList | | yes (title area) | |
| Section | yes (`Icon` or `IconName`) | yes | yes |

Subtext is thin, sits tight under the title and wraps onto more lines when it is long. Setters: `Toggle:SetSubtext`, `Toggle:SetIcon`, `Label:SetSubtext`, `Label:SetIcon`, and `:SetSubtext` on Input, Slider, Dropdown, Stepper, Table and PriorityList.

```lua
Tab:AddSection({
    Name = "Carrot (Ultra)",
    Subtext = "Amount 1 / Max",
    Icon = "rbxassetid://0",  -- a picture
    IconStyle = "Tile",
})
```

---

#### Rows (combining controls on one line)

`Section:AddRow()` returns a row that accepts `AddDropdown`, `AddIconButton`, `AddButton`, `AddInput`, `AddLabel`, `AddStepper`, `AddToggle`, `AddCheckbox` and `AddSlider`. Each item takes `Width` and `Weight`:

- `Width = "Fill"` (default; items share the free space, `Weight` makes one take more)
- `Width = "Auto"` (the item's natural width: text width for buttons, labels and toggles, the square for icon buttons)
- `Width = 120` (pixels)

The row measures itself and splits the width in code, and re-splits when it is resized.

```lua
local Row = Section:AddRow({ Gap = 6, Height = 21 })
Row:AddDropdown("Preset", { Values = { "Preset 1", "Preset 2" }, Default = 1 })   -- no Text: just the box, fills the row
Row:AddIconButton({ Icon = "pencil", Tooltip = "Rename", Func = function() end })
Row:AddIconButton({ Icon = "trash-2", Tooltip = "Delete", Func = function() end })
Row:AddIconButton({ Icon = "plus", Tooltip = "New", Func = function() end })
```

`Row:SetItemWidth(Element, Width, Weight)` changes an item later, and `Row:SetVisible(bool)` hides the row.

**IconButton** (also usable on its own): `Section:AddIconButton(Idx?, Info)`

```lua
Section:AddIconButton({
    Icon = "plus", Text = "",   -- Text makes it a wide button with the label next to the icon
    Size = 21, IconSize = 14,
    Tooltip = nil, DisabledTooltip = nil,
    Risky = false, Disabled = false, Visible = true,
    Func = function() end,
})
-- IconButton:SetIcon / SetText / SetDisabled / SetVisible / SetTooltip
```

---

#### Stepper (+ / - buttons)

```lua
local Stepper = Section:AddStepper("Amount", {
    Text = "Amount", Subtext = nil, Icon = "layers",
    Default = 1, Min = 1, Max = 10, Increment = 1, Rounding = 0,
    Prefix = "", Suffix = "",
    ValueTexts = { [10] = "Max" },          -- text shown for specific values
    Format = nil,                           -- function(Value) -> string
    ValueWidth = 44,
    Holdable = true,                        -- hold a button to keep stepping (speeds up)
    Callback = function(Value) end,
})
-- Stepper.Value / Stepper.Default
-- Stepper:SetValue(n)  :Increase(amount?)  :Decrease(amount?)  :Reset()
-- Stepper:SetMin(n)  :SetMax(n)  :SetIncrement(n)  :SetValueTexts(t)  :SetText  :SetSubtext
-- Stepper:SetDisabled(bool)  :SetVisible(bool)  :OnChanged(fn)  :RunChanged()
```

The buttons dim at the limits.

---

#### Table

Read-only data display with an optional header, zebra rows, selection and sorting. Column widths are measured: a number is pixels, `"Auto"` fits the content, and `"Fill"` columns share what is left by `Weight`. A column's `Align` overrides the table's `Align`.

```lua
local Stats = Section:AddTable("Stats", {
    Text = "Session stats", Subtext = nil,
    Columns = { "Name", { Name = "Value", Align = "Right", Width = 70 }, { Name = "Tag", Width = "Auto" } },
    -- column: string, or { Name, Key, Width = "Fill" | "Auto" | pixels, Weight, Align = "Left" | "Center" | "Right" }
    Rows = { { "Kills", 12, "pvp" }, { "Deaths", 3, { Text = "bad", Color = Color3.new(1, 0.3, 0.3), Icon = "x" } } },
    -- rows are arrays by column order, or tables keyed by a column's Key; a cell can be { Text, Color, Icon }
    Header = true, Striped = true, RowHeight = 22,
    Align = "Left",         -- default alignment for every column: "Left" | "Center" | "Right"
    HeaderAlign = nil,      -- header alignment (nil follows each column)
    MaxHeight = 120,        -- taller tables scroll
    Selectable = true, EmptyText = "No data",
    Callback = function(Index, Row) end,
})
-- Stats:SetRows(rows)  :AddRow(row, position?)  :RemoveRow(i)  :Clear()  :GetRows()
-- Stats:SetColumns(cols)  :SetAlign("Center", headerAlign?)  :UpdateCell(row, column, value)
-- Stats:SetSelected(i or nil)  :GetSelected()  :Sort(column, descending?)
-- Stats:SetMaxHeight(n)  :SetText  :SetSubtext  :SetVisible  :OnChanged(fn)
```

---

#### Priority List

Ordered rows with an index badge, an optional status text, and up / down buttons. The order is a list of ids.

```lua
local Order = Section:AddPriorityList("RunOrder", {
    Text = "Run order",
    Items = {
        { Id = "daily", Name = "Daily Challenge", Value = "Off", Icon = nil, Disabled = false },
        "Challenge",   -- a plain string works too (id = name)
    },
    ShowIndex = true, ShowValue = true, RowHeight = 34,
    Callback = function(Order, MovedId, From, To) end,
})
-- Order:GetOrder()  :Move(idOrIndex, toIndex)  :MoveUp(idOrIndex)  :MoveDown(idOrIndex)
-- Order:SetOrder({ "raid", "daily" })  :SetItems(items)  :SetValue(id, "On")
-- Order:SetItemDisabled(id, bool)  :SetDisabled(bool)  :OnChanged(fn)  :RunChanged()
```

---

#### Dropdown layout and search

By default the label and the selection box share one line (box on the right). New options:

```lua
Section:AddDropdown("Mode", {
    Text = "Difficulty",
    Values = { "Easy", "Normal", "Hard" },
    Layout = "Inline",     -- "Inline" (default) or "Stacked" (label above the box, the old look)
    BoxSide = "Right",     -- Inline only: "Right" (default) or "Left" (box on the left of the label)
    BoxWidth = 0.5,        -- Inline only: 0-1 = share of the row, above 1 = pixels
    Subtext = nil, Icon = nil,
})
```

For multi-select and searchable dropdowns, opening the list shows a top row inside the list: the search field on the left (when `Searchable`) and `All | Clear` on the right (when `Multi`). Opening a dropdown never focuses the search; click the field to type. A dropdown with no `Text` is just the box, which is what you want inside a Row.

The selection box is bottom-aligned in its row, so with subtext the opened list still starts directly under the box. While the list is open the box, the search/All-Clear row and the list join into one shape: bottom corners of the box and search row are square, the list's top corners are square, and the search row's top corner on the side away from the box is square too (both top corners when the box fills the row). All dropdown parts use the same corner radius as the other controls.

---

#### Tab groups (tabbed boxes)

`Tab:AddSectionGroup` draws a segmented tab bar: a rounded track with the active tab as an accent pill, inside a card with the normal outline. Pass `AccentBorder = true` for an accent gradient border instead. `AddTab` and `SetMaxHeight` are unchanged.

---

#### Pop-out, Max Height and Settings

**Pop-out sections.** Every section header has a small arrow button that pops the section out into a floating, draggable panel (the same panel as `Library:AddDraggableMenu`). The original spot shows a placeholder; closing the panel (or clicking the placeholder) docks it back. Turn the button off with `PopOutBoxes = false` in `CreateWindow`, or `PopOut = false` on a single section.

```lua
local Section = Tab:AddLeftSection({
    Name = "Combat",
    PopOut = true,             -- default: follows CreateWindow's PopOutBoxes
    PopOutWidth = 300,         -- optional
    MaxPopOutHeight = 420,     -- optional, taller content scrolls
    MaxHeight = nil,           -- optional, see below
})

Section:SetPoppedOut(true)
Section:TogglePoppedOut()
Section:IsPoppedOut()
Section:SetPopOutWidth(320)
Section:SetMaxPopOutHeight(500)
```

Popped-out panels hide and show together with the main window.

**Max height.** `Section:SetMaxHeight(n)` limits how tall the section body gets; taller content scrolls inside it. Pass `nil` to remove the limit. Tabbed section groups have the same: `SectionGroup:SetMaxHeight(n)` (or `MaxHeight` in the group's info table).

**Settings (gear) menus.** `AddSettings` adds a gear button to an element. Clicking it expands a panel holding any normal elements. It works on Label, Toggle, Button (and sub-buttons), Input and Dropdown.

```lua
local Toggle = Section:AddToggle("Aimbot", { Text = "Aimbot" })
local Settings = Toggle:AddSettings({ Width = nil })   -- Width: optional fixed width, nil = full width

Settings:AddSlider("AimbotFov", { Text = "FOV", Default = 90, Min = 1, Max = 360, Rounding = 0 })
Settings:AddToggle("AimbotVisible", { Text = "Visible only" })

Settings:Open() / Settings:Close() / Settings:Toggle() / Settings:IsOpen()
Settings:SetWidth(240)
Settings:Destroy()
```

---

#### Custom Tab

```lua
local Tab = Window:AddCustomTab({ Name = "Custom", Icon = "layout-dashboard", Description = "Your own GUI" })
-- also available on tab sections: TabSection:AddCustomTab(...)

-- Tab.Container is an empty, full-size Frame: parent your own GuiObjects to it.
local MyFrame = Instance.new("Frame")
MyFrame.Size = UDim2.fromScale(1, 1)
MyFrame.Parent = Tab.Container
```

A custom tab looks and behaves like any other sidebar tab (icon, tooltip, order, search), but it has no sections.

---

#### Key Tab

A special tab variant intended for key-gated content (e.g., a whitelist key entry screen).

```lua
local KeyTab = Window:AddKeyTab({
    Name = "Key",
    Icon = "key",
})

KeyTab:AddKeyBox(function(Key)
    if Key == "my-secret-key" then
        -- grant access
    end
end)

KeyTab:AddLabel("Enter your key below")

KeyTab:AddLinkBox("Get Key", "https://example.com")
```

Key tabs use a centered, single-column scrolling layout. The searchbar is disabled while a key tab is active.

---

### Tabboxes

Tabboxes are the pages inside an `AddSectionGroup` tabbed section box.

---

#### Tabboxes

A Tabbox (referred to in the API as a *Section Group page*) is a section-like object returned from `Group:AddTab(...)` on an `AddSectionGroup` box. It supports all the same element methods (`AddToggle`, `AddInput`, `AddSlider`, `AddDropdown`, etc.) as a regular `Section`.

```lua
local Group = Tab:AddSectionGroup({ Name = "MyGroup" })

local Page = Group:AddTab("Page One", "icon-name")
local Page2 = Group:AddTab("Page Two")

Page:AddToggle("myToggle", { Text = "Enable", Default = false })
Page2:AddButton("Do Thing", function() end)
```

The first page added is shown by default. Clicking a tab button at the top of the box switches the active page. See [Groupboxes -> AddSectionGroup](#groupboxes--sections) for how to create the parent box.

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Page name | string | nil |
| 2 | Icon name | string? | nil |

---

### Groupboxes

Sections, section groups, subsections, and conditional visibility.

---

#### AddSection

A **tab** is filled with **sections** -- boxed panels that hold elements. Sections can span the full width of the tab, or sit side-by-side in a two-column layout, and you can freely alternate between the two down the page.

```lua
local Section = Tab:AddSection({
    Name     = "Settings",
    Side     = 1,
    IconName = "settings",
})

-- Convenience wrappers:
local LeftSection  = Tab:AddLeftSection("Settings")
local RightSection = Tab:AddRightSection("Settings", "settings")
```

- Omitting `Side` (or passing anything other than `1`/`2`) creates a **full-width** section.
- `Side = 1` places the section in the **left column**, `Side = 2` in the **right column** of a two-column row.

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Section config table | table | nil |

---

#### Layout & Alternation

Sections render in **exactly the order you call** `AddSection`/`AddLeftSection`/`AddRightSection`/`AddSectionGroup`, top to bottom. Full-width and two-column sections can be freely interleaved:

```lua
Tab:AddSection("Overview")               -- full-width, row 1

Tab:AddLeftSection("Combat")             -- \
Tab:AddRightSection("Visuals")           -- / two-column row, row 2

Tab:AddSection("Misc")                   -- full-width, row 3

Tab:AddLeftSection("Player")             -- \
Tab:AddRightSection("World")             -- / two-column row, row 4
```

This produces exactly what it reads as: **section -> two-column -> section -> two-column**, in call order, with no manual row/index bookkeeping required. Every consecutive pair of `Side = 1` / `Side = 2` calls shares one row; a call with no `Side` (or a switch back to full-width) always starts a fresh row.

Within a two-column row, left sections (`Side = 1`) stack top-to-bottom in the left column, and right sections (`Side = 2`) stack top-to-bottom in the right column, independent of each other.

The global searchbar/overlay lists matching sections and elements in this same visual order, so results always read top-to-bottom, left-to-right just like the tab itself.

Search uses fuzzy matching (so `enb` finds "Enable Feature"), covers element text, tooltips, and dropdown value lists, and scores every tab -- the view switches to the tab with the best match (staying put on ties). Matching a tab, section, or page name reveals everything inside it.

---

#### AddSectionGroup (Tabbed Section Box)

A section box with multiple sub-tabs at the top, sharing the same panel area. It participates in the same layout ordering and `Side` rules as `AddSection`.

```lua
local Group = Tab:AddSectionGroup({
    Name = "MyGroup",
    Side = 1,
})

-- Shorthand:
local Group = Tab:AddLeftSectionGroup("MyGroup")
local Group = Tab:AddRightSectionGroup("MyGroup")

-- Add pages to the group
local Page = Group:AddTab("Page One", "icon-name")
local Page2 = Group:AddTab("Page Two")

-- Page is a section-like object supporting all element methods
Page:AddToggle("myToggle", { Text = "Enable", Default = false })
```

The first page added is shown by default. Clicking a tab button at the top of the box switches the active page.

---

#### AddSubSection (Nested Sections)

Creates a nested section inside an existing section, allowing for hierarchical organization of elements. Subsections support the same alternation between full-width and two-column layouts as regular sections.

```lua
local SubSection = Section:AddSubSection({
    Name = "Advanced Settings",
    IconName = "settings",
    DefaultOpen = true,
    Side = nil,
})

-- Shorthand:
local SubSection = Section:AddSubSection("Advanced Settings", "settings")

SubSection:AddToggle("myToggle", { Text = "Enable Feature", Default = false })
SubSection:AddSlider("mySlider", { Text = "Value", Min = 0, Max = 100, Default = 50 })

-- Two-column subsections
Section:AddSubSection({ Name = "Left Column", Side = 1 })
Section:AddSubSection({ Name = "Right Column", Side = 2 })

-- Full-width subsection (alternation works)
Section:AddSubSection("Full Width Settings")
```

Sub-sections use a slightly smaller header and a subtly different background to indicate nesting. They support all the same element methods as regular sections. Clicking the header toggles the sub-section open/closed, and the parent section automatically resizes to accommodate.

**Layout Alternation:** Subsections automatically alternate between full-width and two-column layouts when you use the `Side` parameter, just like regular sections.

Prop

Type

`Name?`string

`IconName?`string

`DefaultOpen?`boolean

`Side?`1 \| 2

---

#### Conditional Groups & Sections

Show/hide a group of elements or an entire section based on the state of other elements.

##### ConditionalGroup

Inline group inside an existing section. Shown/hidden without affecting the section box.

```lua
local Group = Section:AddConditionalGroup()

Group:AddToggle("innerToggle", { Text = "Sub Option" })
Group:AddSlider("innerSlider", { Text = "Value", Min = 0, Max = 10 })

Group:SetupDependencies({
    { Toggles["myToggle"], true },
    { Options["myDropdown"], "Option A" },
})
```

##### ConditionalSection

A separate styled section box that appears/disappears, anchored to the parent section's column.

```lua
local CondSection = Section:AddConditionalSection()

CondSection:AddLabel("Only visible when condition is met")

CondSection:SetupDependencies({
    { Toggles["someToggle"], true },
})
```

##### Dependency Format

Each dependency entry is `{ Element, ExpectedValue }`:

- For `Toggle` elements: `ExpectedValue` is a `boolean`
- For `Dropdown` elements (single): `ExpectedValue` is the selected value
- For `Dropdown` elements (multi): `ExpectedValue` is a value that must be present in the selection

All listed dependencies must be satisfied simultaneously for the group/section to become visible.

---

## 4. UI Elements

---

### Labels

A text label element, supporting KeyPicker and ColorPicker addons.

---

#### Label

A text label. Supports addons (KeyPicker, ColorPicker) on non-wrapping labels.

```lua
local Label = Section:AddLabel("My Label")

-- With options:
local Label = Section:AddLabel({
    Text      = "My Label",
    DoesWrap  = false,
    Size      = 14,
    Visible   = true,
})

-- With an Idx for registry:
local Label = Section:AddLabel("myLabel", { Text = "Hello" })
```

Prop

Type

`Text?`string

`DoesWrap?`boolean

`Size?`number

`Visible?`boolean

---

#### Methods

```lua
Label:SetText(Text: string)
Label:SetVisible(Visible: boolean)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New text / visibility | string \| boolean | nil |

##### Addon Methods

Available on non-wrapping labels only.

```lua
Label:AddKeyPicker(Idx, Info)
Label:AddColorPicker(Idx, Info)
```

See [Keybinds](#keybinds) and [Color Pickers](#color-pickers) for the full addon reference.

Registered labels are stored in `Library.Labels`.

---

### Buttons

A clickable button, optionally with double-click confirmation and a sub-button.

---

#### Button

A clickable button. Supports an optional secondary sub-button next to it.

```lua
local Button = Section:AddButton({
    Text         = "Do Thing",
    Func         = function() end,
    DoubleClick  = false,
    Icon         = nil,
    Risky        = false,
    Disabled     = false,
    Visible      = true,
    Tooltip      = nil,
    DisabledTooltip = nil,
    Idx          = nil,
})

-- Shorthand:
Section:AddButton("Label", function() end)
```

`Icon` accepts any custom-icon format (asset id, URL, lucide name) and renders centered next to the label.

Prop

Type

`Text?`string

`Func?`function

`DoubleClick?`boolean

`Icon?`string

`Risky?`boolean

`Disabled?`boolean

`Visible?`boolean

`Tooltip?`string

`DisabledTooltip?`string

---

#### Methods

```lua
Button:SetText(Text: string)
Button:SetIcon(Icon: string?)
Button:SetDisabled(Disabled: boolean)
Button:SetVisible(Visible: boolean)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New value | string \| boolean | nil |

---

#### Sub-button

Call `:AddButton(...)` on a button object to attach a second button displayed inline to its right.

```lua
local Sub = Button:AddButton({
    Text = "Sub",
    Func = function() end,
})
```

Buttons are stored in `Library.Buttons` when an `Idx` is provided.

---

### Toggles

A boolean toggle rendered as a pill switch, with KeyPicker and ColorPicker addon support.

---

#### Toggle

A boolean toggle rendered as a pill switch or as a checkbox (if `Library:SetForceCheckbox(true)` was called, or `AddCheckbox` is called directly -- see [Checkboxes](#checkboxes)).

```lua
local Toggle = Section:AddToggle("myToggle", {
    Text     = "Enable Feature",
    Default  = false,
    FireDefault = true,
    Callback = function(Value) end,
    Changed  = function(Value) end,
    Risky    = false,
    Disabled = false,
    Visible  = true,
    Tooltip  = nil,
    DisabledTooltip = nil,
})
```

Prop

Type

`Text?`string

`Default?`boolean

`FireDefault?`boolean

`Risky?`boolean

`Disabled?`boolean

`Visible?`boolean

`Tooltip?`string

---

> **`Default` fires its callback on startup.** When a toggle is created with `Default = true`, its `Callback` and `Changed` run once after the rest of your UI has finished building, so the feature behind it is actually active without you having to call `SetValue(true)` yourself. It is deferred (`task.defer`) on purpose: the whole script has run by then, so toggles that reference elements created later still resolve correctly.
>
> The deferred call is skipped if something already applied the toggle in the meantime (for example `SaveManager:Load()`, which calls `SetValue` itself), so a saved config never results in a double-fire.
>
> Set `FireDefault = false` to opt out and keep the old behaviour of never firing the callback at construction.

---

#### Methods

```lua
Toggle:SetValue(Value: boolean)
Toggle:SetText(Text: string)
Toggle:SetDisabled(Disabled: boolean)
Toggle:SetVisible(Visible: boolean)
Toggle:OnChanged(Func: (Value: boolean) -> ())
Toggle:RunChanged()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New value / callback | boolean \| string \| function | nil |

##### Addon Methods

```lua
Toggle:AddKeyPicker(Idx, Info)
Toggle:AddColorPicker(Idx, Info)
```

See [Keybinds](#keybinds) and [Color Pickers](#color-pickers) for the full addon reference.

Registered in `Library.Toggles[Idx]`.

---

### Checkboxes

A checkbox-styled variant of Toggle.

---

#### Checkbox

`AddCheckbox` creates the same element as [`AddToggle`](#toggles), forced to render as a checkbox rather than a pill switch, regardless of `Library.ForceCheckbox`.

```lua
local Toggle = Section:AddCheckbox("myToggle", {
    Text     = "Enable Feature",
    Default  = false,
    Callback = function(Value) end,
})
```

Toggles created via `AddCheckbox` directly always stay checkboxes, unlike `AddToggle` toggles, which follow `Library.ForceCheckbox` / `Library:SetForceCheckbox`.

```lua
-- Force ALL AddToggle-created toggles to render as checkboxes too,
-- and live-update every one already on screen:
Library:SetForceCheckbox(true)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Enable checkbox styling globally | boolean | nil |

Checkboxes share every method and prop with [Toggles](#toggles). Registered in `Library.Toggles[Idx]`.

---

### Sliders

A horizontal drag slider, plus the read-only ProgressBar variant.

---

#### Slider

A horizontal drag slider with an optional editable value field.

```lua
local Slider = Section:AddSlider("mySlider", {
    Text     = "Speed",
    Default  = 50,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Prefix   = "",
    Suffix   = "",
    Compact  = false,
    HideMax  = false,
    Editable = true,
    EditableStyle = "ValueBox", -- "ValueBox" (default) or "Pencil"
    AllowRightClickInput = true,
    Callback = function(Value) end,
    Changed  = function(Value) end,
    Disabled = false,
    Visible  = true,
    Tooltip  = nil,
    DisabledTooltip = nil,
    FormatDisplayValue = nil,
})
```

Prop

Type

`Text?`string

`Default?`number

`Min?`number

`Max?`number

`Rounding?`number

`Editable?`boolean

`EditableStyle?`"Pencil" \| "ValueBox"

`AllowRightClickInput?`boolean

---

Right-clicking the bar (or double-tapping it on mobile) opens a text field to type an exact value.

#### Methods

```lua
Slider:SetValue(Value: number)
Slider:SetMin(Value: number)
Slider:SetMax(Value: number)
Slider:SetText(Text: string)
Slider:SetPrefix(Prefix: string)
Slider:SetSuffix(Suffix: string)
Slider:SetDisabled(Disabled: boolean)
Slider:SetVisible(Visible: boolean)
Slider:OnChanged(Func: (Value: number) -> ())
Slider:RunChanged()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New value | number \| string \| boolean \| function | nil |

Registered in `Library.Options[Idx]`.

---

#### ProgressBar

A read-only progress bar that displays a value visually as a filled bar. Unlike sliders, progress bars cannot be dragged or edited by the user -- the value can only be changed programmatically via `:SetValue()`.

```lua
local ProgressBar = Section:AddProgressBar("myProgressBar", {
    Text     = "Loading",
    Value    = 50,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Prefix   = "",
    Suffix   = "%",
    Compact  = false,
    HideMax  = false,
    Callback = function(Value) end,
    Changed  = function(Value) end,
    Disabled = false,
    Visible  = true,
})
```

##### Methods

```lua
ProgressBar:SetValue(Value: number)
ProgressBar:SetMin(Value: number)
ProgressBar:SetMax(Value: number)
ProgressBar:SetText(Text: string)
ProgressBar:SetPrefix(Prefix: string)
ProgressBar:SetSuffix(Suffix: string)
ProgressBar:SetDisabled(Disabled: boolean)
ProgressBar:SetVisible(Visible: boolean)
ProgressBar:OnChanged(Func: (Value: number) -> ())
```

Registered in `Library.Options[Idx]`.

---

### Inputs

A text input field with an optional label above it.

---

#### Input

```lua
local Input = Section:AddInput("myInput", {
    Text             = "Player Name",
    Default          = "",
    Placeholder      = "",
    Finished         = false,
    Numeric          = false,
    ClearTextOnFocus = true,
    ClearTextOnBlur  = false,
    AllowEmpty       = true,
    EmptyReset       = "---",
    Callback         = function(Value) end,
    Changed          = function(Value) end,
    VerifyValue      = nil,
    Disabled         = false,
    Visible          = true,
    Tooltip          = nil,
    DisabledTooltip  = nil,
})
```

> If `VerifyValue` is provided, `Finished` is forced to `true` automatically.

Prop

Type

`Text?`string

`Default?`string

`Placeholder?`string

`Finished?`boolean

`Numeric?`boolean

`AllowEmpty?`boolean

`EmptyReset?`string

`VerifyValue?`function

---

#### Methods

```lua
Input:SetValue(Text: string)
Input:SetText(Text: string)
Input:SetDisabled(Disabled: boolean)
Input:SetVisible(Visible: boolean)
Input:OnChanged(Func: (Value: string) -> ())
Input:RunChanged()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New value | string \| boolean \| function | nil |

> `SetText` changes the label above the box, not the box's content -- use `SetValue` for that.

Registered in `Library.Options[Idx]`.

---

### Dropdowns

A single or multi-select dropdown list, with search and special player/team types.

---

#### Dropdown

```lua
local Dropdown = Section:AddDropdown("myDropdown", {
    Text   = "Select Mode",
    Values = { "A", "B", "C" },
    DisabledValues = {},
    ValueImages    = {},
    Default        = nil,
    Multi          = false,
    AllowNull      = false,
    Searchable     = false,
    MaxVisibleDropdownItems = 8,
    KeepDisabledValuePosition = false,
    DragSelect     = false,
    FormatDisplayValue = nil,
    FormatListValue    = nil,

    SpecialType        = nil, -- "Player" or "Team"
    ExcludeLocalPlayer = false,
    EnablePlayerImages = false,

    Callback  = function(Value) end,
    Changed   = function(Value) end,
    Disabled  = false,
    Visible   = true,
    Tooltip   = nil,
    DisabledTooltip = nil,
})
```

Prop

Type

`Text?`string

`Values`{ string } \| { [any]: string }

`Multi?`boolean

`AllowNull?`boolean

`Searchable?`boolean

`DragSelect?`boolean

`KeepDisabledValuePosition?`boolean

`SpecialType?`"Player" \| "Team"

---

Large lists are virtualized (only visible rows exist), so 10,000+ values open without freezing. `Searchable` lists use fuzzy matching sorted by best match: opening the dropdown turns the button itself into the search field (autofocused; `Escape` closes), and an empty result shows a "No results" row. `Values` also accepts a dictionary `{ Key = "Display Label" }` — the key is the stored identity, the value is what renders; `DisabledValues` and `ValueImages` accept either keys or labels. `DragSelect` (multi, non-mobile) paints a selection by dragging across rows.

#### Methods

```lua
Dropdown:SetValue(Value)
Dropdown:SetSelectedValue(Value)
Dropdown:DeselectValue(Value)
Dropdown:ClearSelectedValues()
Dropdown:SetValues(Values: table)
Dropdown:AddValues(Values: table | string)
Dropdown:SetDisabledValues(Values: table)
Dropdown:AddDisabledValues(Values: table | string)
Dropdown:SetValueImages(Images: table)
Dropdown:AddValueImages(Images: table)
Dropdown:SetText(Text: string?)
Dropdown:SetDragSelect(Value: boolean)
Dropdown:SetDisabled(Disabled: boolean)
Dropdown:SetVisible(Visible: boolean)
Dropdown:OnChanged(Func: (Value) -> ())
Dropdown:RunChanged()
Dropdown:GetActiveValues(ReturnCount: boolean?): table | number
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Value / values / callback | any | nil |

For `Multi = true`, `Dropdown.Value` is a dictionary `{ [Value] = true }`. For single, it is the raw selected value or `nil`. `GetActiveValues(true)` returns the selection count (useful for the "at least one" `AllowNull` guard).

`SetValues` prunes selections that are no longer in the updated list and only fires callbacks when something actually changed.

Registered in `Library.Options[Idx]`.

---

### Keybinds

A bindable key addon supporting Always, Toggle, Hold, and Press modes.

---

#### KeyPicker

Addons attach to **Label** or **Toggle** elements and appear inline to the right of the element label. Call these on the element object *after* creating it.

```lua
Toggle:AddKeyPicker("myKey", {
    Text    = "KeyPicker",
    Default = "None",
    DefaultModifiers = {},

    Mode  = "Toggle",
    Modes = { "Always", "Toggle", "Hold" },

    SyncToggleState = false,

    Blacklisted          = {},
    BlacklistedModifiers = {},
    Whitelisted          = {},
    WhitelistedModifiers = {},

    Callback        = function(State: boolean) end,
    ChangedCallback = function(KeyCode, Modifiers) end,
    Changed         = function(KeyCode, Modifiers) end,
    Clicked         = function(State: boolean) end,
})
```

> Give each KeyPicker a distinct, descriptive `Text` -- the keybinds panel row is literally `[Key] Text (Mode)`, so leaving this as a generic placeholder on multiple pickers makes every row look identical.

**Supported special key names:** `"MB1"`, `"MB2"`, `"MB3"`

**Supported modifier names:** `"LAlt"`, `"RAlt"`, `"LCtrl"`, `"RCtrl"`, `"LShift"`, `"RShift"`, `"Tab"`, `"CapsLock"`

Prop

Type

`Text?`string

`Default?`string

`Mode?`"Always" \| "Toggle" \| "Hold" \| "Press"

`SyncToggleState?`boolean

---

#### Methods

```lua
KeyPicker:SetValue({ Key = "F", Mode = "Toggle", Modifiers = { "LShift" } })
-- Positional form also accepted: KeyPicker:SetValue({ Key, Mode, Modifiers })
KeyPicker:GetState(): boolean
KeyPicker:SetText(Text: string)
KeyPicker:SetMenuVisibility(Visible: boolean)
KeyPicker:OnChanged(Func)
KeyPicker:OnClick(Func)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Key config / text / callback | table \| string \| function | nil |

Left-click the key button to enter picking mode (shows `...`). Press the desired key or combo. Right-click to open the mode selector menu. The keybind also appears in the floating [Keybinds Panel](#keybind-menu). `SetMenuVisibility(false)` hides it from that panel (also persisted by SaveManager).

Setting a value on a disabled picker's parent still stores the value but skips callbacks.

Registered in `Library.Options[Idx]`.

---

### Color Pickers

An HSV color picker addon with optional alpha support.

---

#### ColorPicker

An HSV color picker panel with optional alpha (transparency) support. Attaches to a **Label** or **Toggle** element.

```lua
Toggle:AddColorPicker("myColor", {
    Default      = Color3.new(1, 1, 1),
    Transparency = nil, -- If a number (0-1) is provided, shows an alpha slider
    Title        = nil,
    Resizable    = true,
    Callback     = function(Color: Color3) end,
    Changed      = function(Color: Color3) end,
})
```

Prop

Type

`Default?`Color3

`Transparency?`number

`Title?`string

`Resizable?`boolean

---

#### Methods

```lua
ColorPicker:SetValue(HSV: {number, number, number} | Color3, Transparency?: number)
ColorPicker:SetValueRGB(Color: Color3, Transparency?: number)
ColorPicker:OnChanged(Func: (Color: Color3) -> ())
ColorPicker:RunChanged()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New color value | Color3 \| table \| function | nil |
| 2 | Transparency | number? | nil |

Left-click the color swatch to open the picker. Right-click for a context menu with **Copy color**, **Paste color**, **Copy Hex**, and **Copy RGB** options (clipboard options require `setclipboard`). Disabled parents lock the swatch, panel, and hex/RGB inputs.

The picker contains:

- A saturation/value map (140px on mobile, 200px otherwise; drag the grabber to resize when `Resizable`)
- A hue strip
- An optional alpha strip (if `Transparency` is set)
- Hex and RGB text inputs

**Layout:** the picker renders inline, as its own row directly beneath whichever Label or Toggle it's attached to -- it does not float above other content. Opening it inserts this row into the owning section and closes automatically on an outside click, exactly like every other addon/popup in the library. It behaves identically whether attached to a Label or a Toggle.

Registered in `Library.Options[Idx]`.

---

### Dividers

A horizontal rule, optionally labelled.

---

#### Divider

A horizontal rule optionally labelled, used to visually separate groups of elements.

```lua
Section:AddDivider()

-- With a text label
Section:AddDivider("Section Label")

-- With a table (full control)
Section:AddDivider({
    Text         = "Label",
    Margin       = 0,
    MarginTop    = 0,
    MarginBottom = 0,
})
```

Prop

Type

`Text?`string

`Margin?`number

`MarginTop?`number

`MarginBottom?`number

---

#### Returned Object

```lua
Divider.Holder    -- the root Frame
Divider.Text      -- string or nil
```

---

### Images

Embeds a static image using any supported icon format.

---

#### Image

```lua
local Image = Section:AddImage("myImage", {
    Image               = "rbxassetid://123456",
    Color               = Color3.new(1, 1, 1),
    Transparency        = 0,
    BackgroundTransparency = 0,
    RectOffset          = Vector2.zero,
    RectSize            = Vector2.zero,
    ScaleType           = Enum.ScaleType.Fit,
    Height              = 200,
    Visible             = true,
})
```

Prop

Type

`Image`string

`Color?`Color3

`Transparency?`number

`ScaleType?`Enum.ScaleType

`Height?`number

---

#### Methods

```lua
Image:SetImage(NewImage: string)
Image:SetColor(Color: Color3)
Image:SetTransparency(Transparency: number)
Image:SetRectOffset(RectOffset: Vector2)
Image:SetRectSize(RectSize: Vector2)
Image:SetScaleType(ScaleType: Enum.ScaleType)
Image:SetHeight(Height: number)
Image:SetVisible(Visible: boolean)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New value | string \| Color3 \| number \| Vector2 \| Enum.ScaleType \| boolean | nil |

Registered in `Library.Options[Idx]`.

---

### Videos

Embeds a VideoFrame for playing Roblox video assets.

---

#### Video

```lua
local Video = Section:AddVideo("myVideo", {
    Video   = "rbxassetid://123456",
    Looped  = false,
    Playing = false,
    Volume  = 1,
    Height  = 200,
    Visible = true,
})
```

Prop

Type

`Video`string

`Looped?`boolean

`Playing?`boolean

`Volume?`number

`Height?`number

---

#### Methods

```lua
Video:SetVideo(NewVideo: string)
Video:SetLooped(Looped: boolean)
Video:SetVolume(Volume: number)
Video:SetPlaying(Playing: boolean)
Video:Play()
Video:Pause()
Video:SetHeight(Height: number)
Video:SetVisible(Visible: boolean)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New value | string \| boolean \| number | nil |

Registered in `Library.Options[Idx]`.

---

### Viewports

Embeds a 3D ViewportFrame displaying a BasePart or Model.

---

#### Viewport

```lua
local Viewport = Section:AddViewport("myViewport", {
    Object      = someModel,
    Camera      = nil,
    Clone       = true,
    AutoFocus   = true,
    Interactive = false,
    Height      = 200,
    Visible     = true,
})
```

Prop

Type

`Object`BasePart \| Model

`Clone?`boolean

`AutoFocus?`boolean

`Interactive?`boolean

`Height?`number

---

#### Methods

```lua
Viewport:SetObject(Object: Instance, Clone: boolean?)
Viewport:SetCamera(Camera: Camera)
Viewport:SetCameraCFrame(NewCFrame: CFrame)
Viewport:GetCameraCFrame(): CFrame
Viewport:Rotate(Yaw: number, Pitch: number?)    -- degrees, orbits the object
Viewport:Zoom(Amount: number)
Viewport:LookAt(Target: Vector3?)               -- defaults to the object's pivot
Viewport:SetDistance(Distance: number)
Viewport:GetDistance(): number
Viewport:SetFieldOfView(FieldOfView: number)    -- clamped to 1-120
Viewport:SetInteractive(Interactive: boolean)
Viewport:SetHeight(Height: number)
Viewport:SetVisible(Visible: boolean)
Viewport:Focus()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New object / camera / value | Instance \| Camera \| boolean \| number | nil |

`Focus()` re-runs `AutoFocus` camera positioning.

Registered in `Library.Options[Idx]`.

---

### UI Passthrough

Embeds an arbitrary GuiBase2d instance directly inside a section at a fixed height.

---

#### UIPassthrough

```lua
local Pass = Section:AddUIPassthrough("myPass", {
    Instance = someFrame,
    Height   = 24,
    Visible  = true,
})
```

Prop

Type

`Instance`GuiBase2d

`Height?`number

`Visible?`boolean

---

#### Methods

```lua
Pass:SetInstance(Instance: GuiBase2d)
Pass:SetHeight(Height: number)
Pass:SetVisible(Visible: boolean)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New instance / height / visibility | GuiBase2d \| number \| boolean | nil |

**Sizing:** if the `Instance` you pass in is still at Roblox's own default size (i.e. you never set `.Size` on it yourself), it's automatically stretched to fill the passthrough's `Height`. If you did set a `.Size`, it's left untouched -- useful for a fixed-width element anchored to one side instead of filling the row. The passthrough's own holder always clips its contents, so oversized content can't bleed into whatever sits below it in the section.

**ZIndex:** any `GuiObject` you (or your own code, later) parent into the passthrough is automatically bumped to match its holder's `ZIndex` if it's lower. Since the whole UI uses `ZIndexBehavior.Global`, a plain `Instance.new(...)` with no explicit `ZIndex` defaults to `1` and loses against nearly everything else in the library -- without this, custom content could be correctly parented and positioned yet render invisibly underneath other UI. This applies automatically, including to whatever you pass to `SetInstance` later.

Registered in `Library.Options[Idx]`.

---

## 5. Core Systems & Overlays

---

### Notifications

Toast-style notifications that slide in from the side of the screen.

---

#### Notifications

```lua
local Notif = Library:Notify({
    Title       = "Success",
    TitleColor  = nil,
    Description = "Action completed",
    DescriptionColor = nil,
    Time        = 5,
    Icon        = nil,
    BigIcon     = nil,
    IconColor   = nil,
    SoundId     = nil,
    Volume      = 3,
    Steps       = nil,
    Persist     = false,
    Closable    = false,                        -- shows an X button
    Callback    = function(Reason) end,         -- "user" | "timer" | "script"
})

-- Shorthand (description + optional time + sound + volume):
Library:Notify("Something happened", 3)
```

Notifications slide in from the configured side (`Library.NotifySide`) and slide back out when dismissed. The timer bar drains over the `Time` duration.

Prop

Type

`Title?`string

`TitleColor?`Color3

`Description?`string

`DescriptionColor?`Color3

`Time?`number \| Instance

`Icon?`string

`BigIcon?`string

`IconColor?`Color3

`SoundId?`number \| string

`Volume?`number

`Steps?`number

`Persist?`boolean

> `Title` and `Description` are both optional -- omitting either leaves that line out of the notification entirely rather than rendering a placeholder.

---

#### Methods

###### ChangeTitle

```lua
Notif:ChangeTitle(Text: string)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New title text | string | nil |

###### ChangeDescription

```lua
Notif:ChangeDescription(Text: string)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New description text | string | nil |

###### ChangeStep

Advances the step progress bar.

```lua
Notif:ChangeStep(NewStep: number)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New step index | number | nil |

###### Destroy

Manually dismiss the notification.

```lua
Notif:Destroy()
```

---

### Dialogs

Modal overlays that demand user attention and block background interaction.

---

#### Dialogs

Dialogs overlay the user interface and dim out the background, demanding the user's attention. Only one dialog overlay is shown at a time per call; dialogs darken the background and **block interaction with the window behind them** -- clicks, drags, and typing on any element underneath the dialog are intercepted by the scrim and never reach the element.

Dialogs inherit methods from Sections, therefore you can call all standard Section methods (`AddToggle`, `AddInput`, `AddSlider`, `AddDropdown`, etc.) on the returned Dialog instance to build custom interactions directly into the Dialog.

```lua
local Dialog
Dialog = Window:AddDialog("DialogueIdx", {
    Title = "Test Dialog",
    Description = "This is a test dialog. Please confirm or cancel.",
    AutoDismiss = true,
    OutsideClickDismiss = true,
    FooterButtons = {
        Cancel = {
            Title = "Cancel",
            Variant = "Ghost",
            Order = 1,
            Callback = function()
                print("Cancelled the dialog.")
            end
        },
        Secondary = {
            Title = "Secondary",
            Variant = "Secondary",
            Order = 2,
            Callback = function()
                print("Secondary action.")
            end
        },
        Delete = {
            Title = "Delete",
            Variant = "Destructive",
            Order = 3,
            Callback = function()
                print("Deleted the asset.")
            end
        },
        Confirm = {
            Title = "Confirm",
            Variant = "Primary",
            WaitTime = 3, -- 3 seconds minimum wait
            Order = 4,
            Callback = function(self)
                print("Confirmed the dialog.")
            end
        }
    }
})

Dialog:AddToggle("DisableSecondary", {
    Text = "Disable Secondary Button",
    Default = false,
    Callback = function(value)
        Dialog:SetButtonDisabled("Secondary", value)
    end
})

Dialog:AddInput("InputTest", {
    Text = "Type something here:",
    Callback = function(value) print("Typed:", value) end
})

Dialog:AddToggle("SwapDeleteOrder", {
    Text = "Send Delete to Right",
    Default = false,
    Callback = function(value)
        Dialog:SetButtonOrder("Delete", value and 5 or 3)
    end
})
```

```lua
Window:AddDialog("EmptyDialogueIdx", {
    Title = "Empty Dialog",
    Description = "This dialog has no elements. The padding should be completely normal and singular.",
    AutoDismiss = true,
    OutsideClickDismiss = true,
    FooterButtons = {
        Confirm = {
            Title = "Okay",
            Variant = "Primary",
            Callback = function() end
        }
    }
})
```

Prop

Type

`Title?`string

`Description?`string

`AutoDismiss?`boolean

`OutsideClickDismiss?`boolean

`FooterButtons?`string mapped to DialogButtonInfo

`Icon?`string

`TitleColor?`Color3

`DescriptionColor?`Color3

`ButtonsAlignment?`"Left" \| "Center" \| "Right"

---

#### Background Blocking

The dark scrim behind the dialog is an interactive overlay, not just a visual dimmer -- it sits above every element in the window (`Library.DialogScrimZIndex`) and actively intercepts input, so nothing behind the dialog (buttons, toggles, sliders, dropdowns, draggable window elements) can be clicked, focused, or dragged while the dialog is open. The dialog's own content box renders on a higher band still (`Library.DialogContentZIndex`) so it stays fully interactive on top of its own scrim.

Only already-open **overlays** (draggable menus, the Keybinds panel, context menus) are exempt from the dim/block and remain interactive above the scrim, since those are expected to float above normal window content regardless of dialog state.

`Library.ActiveDialog` points to the most recently opened dialog while it's visible, and is checked internally to suppress tooltips and other hover affordances on the window behind the dialog for the same reason.

---

#### Custom Button Example

To configure custom footer buttons, specify a dictionary mapped to their properties in `FooterButtons`. You can natively assign a `WaitTime` to any button, and Astral will render an animated progress bar preventing interaction until the timer expires.

```lua
Confirm = {
    Title = "Confirm",
    Variant = "Primary", -- Optional (Primary, Secondary, Destructive, Ghost)
    WaitTime = 3, -- 3 seconds minimum before the button can be clicked
    Order = 4,
    Callback = function(self)
        print("Confirmed the dialog.")
    end
}
```

---

#### Methods

Dialogs inherit all methods from Sections. You may use `AddToggle`, `AddInput`, `AddDropdown`, and so forth directly on the Dialog instance itself. The methods below are unique to Dialogs.

###### SetTitle

Update the dialog title dynamically.

```lua
Dialog:SetTitle("New Title")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New title of the dialog | string | nil |

###### SetDescription

Refresh the descriptive text dynamically.

```lua
Dialog:SetDescription("New Description")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New description of the dialog | string | nil |

###### SetButtonsAlignment

```lua
Dialog:SetButtonsAlignment("Center")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Footer button alignment | "Left" \| "Center" \| "Right" | nil |

###### AddFooterButton

Programmatically inject a new footer button into the dialog.

```lua
Dialog:AddFooterButton("ExtraAction", {
    Title = "Do something else",
    Variant = "Secondary",
    Callback = function() end
})
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Dictionary Index Reference | string | nil |
| 2 | Dialog Button Configuration Table | DialogButtonInfo | nil |

###### RemoveFooterButton

Programmatically remove an existing footer button from the dialog.

```lua
Dialog:RemoveFooterButton("ExtraAction")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Dictionary Index Reference | string | nil |

###### SetButtonDisabled

Change the disabled state of a specific footer button dynamically.

```lua
Dialog:SetButtonDisabled("Confirm", true)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Dictionary Index Reference | string | nil |
| 2 | Whether the button should be disabled | boolean | nil |

###### SetButtonOrder

Change the display order index of a specific footer button dynamically.

```lua
Dialog:SetButtonOrder("Delete", 5)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Dictionary Index Reference | string | nil |
| 2 | New Layout Order | number | nil |

###### Dismiss

Explicitly close and destroy the dialog and all its visual child elements.

```lua
Dialog:Dismiss()
```

Registered in `Library.Dialogues[Idx]`.

---

### Overlays

Floating draggable panels that exist outside the main window.

---

#### Draggable Overlays

Floating panels that exist outside the main window. Useful for persistent mini-displays. Every overlay created through the methods below -- draggable labels, buttons, toggles, progress bars, menus, and context menus -- is automatically registered in a central registry (`Library.Overlays`) the moment it's created.

##### Draggable Label

```lua
-- Watermark: a draggable label overlay, hidden until shown
Library:SetWatermark("Astral | 60 fps")
Library:SetWatermarkVisibility(true)

-- Re-anchors the notification stack to the current NotifySide and re-measures every notification
Library:UpdateNotificationPositions()

-- Icons: a Lucide name, asset id / rbxassetid string, registered custom asset name, or an icon table
local Image = Library:CreateIcon("settings", { Size = UDim2.fromOffset(16, 16), Parent = SomeFrame })
local Button = Library:CreateIcon("x", { ImageColor3 = Color3.new(1, 1, 1) }, true)   -- true = ImageButton
Library:ApplyIcon(ExistingImageLabel, "rbxassetid://123456")

local LabelOverlay = Library:AddDraggableLabel("My Label")
local IconOverlay = Library:AddDraggableLabel("Pinned", "pin", "left")

LabelOverlay:SetText("New Text")
LabelOverlay:SetVisible(true)
LabelOverlay:SetIcon("star")
LabelOverlay:SetIconPosition("right") -- "left" or "right"
```

##### Draggable Button

```lua
local BtnOverlay = Library:AddDraggableButton("Click Me", function(self)
    -- self is the BtnOverlay table
end)

BtnOverlay:SetText("New Label")
```

##### Draggable Image Button

An icon-only floating button.

```lua
local ImgOverlay = Library:AddDraggableImageButton("menu", 24, function(self)
    -- self is the overlay table
end)

ImgOverlay:SetIcon("x")
ImgOverlay:SetIconSize(20)
```

##### Draggable Toggle

A floating on/off switch, useful for things like a persistent "Auto Farm" or "ESP" toggle that lives outside the main window.

```lua
local ToggleOverlay = Library:AddDraggableToggle("Auto Farm", false, function(Value)
    print("Auto Farm:", Value)
end)

ToggleOverlay:SetValue(true)
print(ToggleOverlay.Value)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Display text | string | nil |
| 2 | Default value | boolean? | nil |
| 3 | Callback fired on change | function | nil |

##### Draggable Progress

A floating progress/status bar. Handy for showing farm progress, a loading state, or any running total without needing the main window open.

```lua
local ProgressOverlay = Library:AddDraggableProgress("Loading...", 0, 100)

ProgressOverlay:SetValue(50)     -- clamps to [0, Max]
ProgressOverlay:SetText("Halfway there")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Display text | string | nil |
| 2 | Default value | number? | nil |
| 3 | Max value | number? | nil |

##### Draggable Menu

A titled floating panel with a title bar (minimize + close buttons, styled to match the main window's own controls) and a container that supports the full set of normal element methods.

```lua
local Holder, RawContainer, Container = Library:AddDraggableMenu("Menu Title")

Container:AddButton({ Text = "Click Me", Func = function() end })
Container:AddToggle("myToggle", { Text = "Some Setting", Default = false })
Container:AddSlider("mySlider", { Text = "Some Value", Default = 25, Min = 0, Max = 100 })

Container:AddUIPassthrough("myCustom", { Instance = someFrame, Height = 30 })
```

**Return values:**

- `Holder` -- the whole floating panel (title bar + body), the Instance you'd pass to `Library:MakeDraggable` or destroy directly.
- `RawContainer` -- the raw content `Frame` Instance. Rarely needed directly.
- `Container` -- the element-friendly wrapper. Use this one. Supports `AddButton`, `AddToggle`, `AddSlider`, `AddInput`, `AddDropdown`, `AddLabel`, addons, `AddUIPassthrough`, `AddDivider`, etc.

```lua
Container:SetCollapsed(true)      -- collapse (same as clicking minimize)
Container:ToggleCollapsed()       -- flip collapsed state
Container:IsCollapsed()           -- -> boolean
Container:Remove()                -- destroy the whole menu (same as clicking close)
```

**Sizing:** the panel's width is fixed at creation (auto-widened only if the title text needs more room) and its height grows automatically with content, capped at a maximum height so it can never grow to fill the screen.

---

#### Overlay Manager

Every overlay created via `AddDraggableLabel`, `AddDraggableButton`, `AddDraggableToggle`, `AddDraggableProgress`, `AddDraggableMenu`, or `AddContextMenu` is automatically added to `Library.Overlays`, keyed by a numeric `Id`.

Every overlay table carries three extra fields once registered:

| Field | Meaning |
| --- | --- |
| `Overlay.Id` | Unique numeric id, assigned in creation order |
| `Overlay.OverlayType` | `"DraggableLabel"`, `"DraggableButton"`, `"DraggableToggle"`, `"DraggableProgress"`, `"DraggableMenu"`, or `"ContextMenu"` |
| `Overlay.OverlayName` | The label/title text passed at creation, or an auto-generated fallback |

And every overlay table supports these methods, regardless of type:

```lua
Overlay:SetVisible(true)   -- show / hide without destroying
Overlay:IsVisible()        -- -> boolean
Overlay:Remove()           -- destroy and unregister
```

##### Library-level Methods

```lua
Library:GetOverlays()                     -- -> array of ALL overlay tables, in creation order
Library:GetOverlays("DraggableToggle")    -- -> array filtered to just that type
Library:GetOverlay(Id)                    -- -> single overlay table, or nil

Library:SetOverlayVisible(Id, true)
Library:ToggleOverlay(Id)
Library:RemoveOverlay(Id)

Library:SetAllOverlaysVisible(false)
Library:SetAllOverlaysVisible(true, "DraggableLabel")

Library:RemoveAllOverlays()
Library:RemoveAllOverlays("ContextMenu")
```

Example: build a simple management list from scratch, without keeping your own references around from the moment each overlay was created:

```lua
for _, Overlay in Library:GetOverlays() do
    print(("#%d  %s  (%s)  visible=%s"):format(
        Overlay.Id, Overlay.OverlayName, Overlay.OverlayType, tostring(Overlay:IsVisible())
    ))
end
```

---

### Loading

A standalone splash/loading window shown before the main UI.

---

#### Loading Screens

A separate standalone window (its own `ScreenGui`) shown before/instead of the main UI -- useful for a key-system or "initializing" splash screen. Only one loading screen can exist at a time.

```lua
local Loading = Library:CreateLoading({
    Title    = "Astral",
    Icon     = "AstralIcon",
    IconSize = UDim2.fromOffset(30, 30),

    LoadingIcon          = "LoadingIcon",
    LoadingIconColor     = nil,
    LoadingIconTweenTime = 1,

    CurrentStep = 0,
    TotalSteps  = 10,

    ShowSidebar      = false,
    AutoResizeHeight = false,

    WindowWidth  = 450,
    WindowHeight = 275,
    ContentWidth = 450,
    SidebarWidth = 250,

    AlwaysOnTop = false,
})
```

Creating a loading screen automatically hides the main window (`Library:Toggle(false)`) while it's active, and automatically re-shows the main window once the loading screen is destroyed.

Prop

Type

`Title?`string

`Icon?`string

`CurrentStep?`number

`TotalSteps?`number

`ShowSidebar?`boolean

`AutoResizeHeight?`boolean

`WindowWidth?`number

`WindowHeight?`number

`AlwaysOnTop?`boolean

---

#### Methods

###### SetMessage / SetDescription

```lua
Loading:SetMessage(Text: string)
Loading:SetDescription(Text: string)
```

###### SetLoadingIcon

```lua
Loading:SetLoadingIcon(Icon: string)
Loading:SetLoadingIconTweenTime(TweenTime: number)
Loading:SetLoadingIconColor(Color: Color3)
```

###### Progress

```lua
Loading:SetCurrentStep(Step: number)
Loading:SetTotalSteps(Steps: number)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | New step/total value | number | nil |

###### Sizing

```lua
Loading:SetWindowHeight(Height: number)
Loading:SetWindowWidth(Width: number)
Loading:SetContentWidth(Width: number)
Loading:SetSidebarWidth(Width: number)
```

###### ShowSidebarPage

```lua
Loading:ShowSidebarPage(Bool: boolean)
```

###### Error Page

Swaps the body for a centered error message + buttons.

```lua
Loading:ShowErrorPage(Enabled: boolean)
Loading:SetErrorMessage(Text: string)
Loading:SetErrorButtons({
    Retry = { Title = "Retry", Variant = "Primary", Callback = function(Loading) end },
})
```

###### Destroy

Also available as `Loading:Continue()` (alias).

```lua
Loading:Destroy()
Loading:SetAlwaysOnTop(Enabled: boolean)
```

`Library.ActiveLoading` references the active loading screen object; `Library:CreateLoading` returns the existing instance with a warning if one is already active rather than creating a second one.

---

### Keybind Menu

The floating panel that lists every registered KeyPicker.

---

#### Keybinds Panel

The floating Keybinds panel displays all registered keybinds. It can be toggled via the window's keybind or programmatically through `Library.KeybindFrame.Visible`. Each row is rendered as `[Key] Text (Mode)`, where `Text` is the KeyPicker's own `Text` field -- **not** the element's `Idx`.

Each entry shows:

- Current key binding
- The KeyPicker's `Text` label
- Mode (Toggle, Hold, Press, Always)
- Toggle checkbox (if enabled via `Library.ShowToggleFrameInKeybinds`)

Because the row's label comes from `Text`, distinct KeyPickers that all share the same `Text` (e.g. every picker left as `Text = "Key"`) will show up as identical-looking rows in the panel, differing only by their key/mode. Give each KeyPicker a unique, descriptive `Text` to keep the panel readable.

---

#### Menu Keybind

In Astral, there is a helper field that you can set that allows you to easily bind a [Keybind](#keybinds) to toggle the main window.

```lua
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

Library.ToggleKeybind = Options.MenuKeybind
```

Prop

Type

`Library.KeybindFrame`Frame

`Library.KeybindContainer`Frame

`Library.KeybindMenu`table

`Library.KeybindToggles`table

`Library.ShowToggleFrameInKeybinds?`boolean

---

##### Visibility Control

```lua
local Menu = Library.KeybindMenu

Menu:SetCollapsed(true)       -- collapse the panel
Menu:ToggleCollapsed()        -- flip collapsed state
Menu:IsCollapsed()            -- -> boolean
Menu:SetVisibilityControl(true) -- show the gear button + "Visible Keybinds" panel
Menu:SetSettingsOpen(true)    -- open the visibility panel
Menu:ToggleSettings()         -- flip the visibility panel
Menu:RefreshSettings()        -- rebuild the visibility rows
```

With visibility control enabled, a gear button appears on the Keybinds panel opening a "Visible Keybinds" panel where each keybind can be individually shown/hidden (via `KeyPicker:SetMenuVisibility`). Hidden entries persist through SaveManager.

### Utility

Utility methods and extra library features.

---

#### Custom Cursor

Enable the custom cursor to render the Astral-styled pointer at your mouse position -- handy for experiences that hide or replace Roblox's default cursor.

```lua
Library.ShowCustomCursor = true
```

These functions allow you to set your own image instead of the default custom cursor.

```lua
Library.Cursor:ChangeCrossColor(Color: Color3)
Library.Cursor:ResetCross()
Library.Cursor:ChangeIcon(ImageId: string)
Library.Cursor:ChangeIconColor(Color: Color3)
Library.Cursor:ChangeIconSize(Size: UDim2)
Library.Cursor:ResetIcon()
Library.Cursor:ResetCursor()
```

The older `Library:ChangeCursorIcon`, `Library:ChangeCursorIconSize`, and `Library:ResetCursorIcon` still work but are deprecated in favor of the `Library.Cursor` versions.

---

#### Icons

Icons originate from the [lucide icon pack](https://lucide.dev). You can change the icon library so long as you call it before creating any UI elements and it follows the expected return data.

```lua
Library:SetIconModule(module)
```

##### Custom Icon Registry

```lua
type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}
```

Astral is dependent on a few icons to be able to be displayed properly. Please make sure you have icons named:

- `check` (Toggles)
- `chevron-up` (Dropdowns)
- `move-diagonal-2` (Window resizing icon, bottom right of the window)
- `key` (Key Tab icon)
- `search` (Searchbar)
- `move` (Window movement icon, top right of the window)

##### Custom Asset Icons

If you'd like to use custom hosted images (like those on Github) with a Roblox Asset ID as a fallback, you can use the built-in ImageManager.

`GetCustomIcon` resolves, in order: (1) a *named* asset registered via `ImageManager.AddAsset` -- this covers the built-ins (`"AstralIcon"`, `"DiscordIcon"`, `"LoadingIcon"`, `"CheckIcon"`, `"TransparencyTexture"`, `"SaturationMap"`); (2) a raw `rbxasset://` / `rbxthumb://` / asset-URL string; (3) a Lucide icon name via `GetIcon`.

###### AddAsset

```lua
Library.ImageManager.AddAsset("astral_logo", 95816097006870, "https://example.com/icon.png")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Asset Name | string | nil |
| 2 | Roblox Asset ID | number | nil |
| 3 | Asset URL | string | nil |
| 4 | Force Redownload | boolean? | nil |

###### GetAsset

```lua
local AssetID = Library.ImageManager.GetAsset("astral_logo")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Asset Name | string | nil |

###### DownloadAsset

This runs automatically in `AddAsset`, so you don't need to call it separately (unless you want to redownload the asset image).

```lua
Library.ImageManager.DownloadAsset("astral_logo")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Asset Name | string | nil |
| 2 | Force Redownload | boolean? | nil |

> **Icon Loading:** the library automatically loads Lucide icons from the remote source on startup and caches them locally in `Astral/cache/LucideIcons.lua`. By default, `Library:CreateWindow()` and `Library:CreateLoading()` will wait up to 10 seconds for icons to load before proceeding. Disable this via `Library.WaitForIconsOnLoad = false`, or manually wait with `Library:WaitForIcons()`.

---

#### Lifecycle

##### OnUnload

Registers a callback that fires when the library is unloaded via `Library:Unload()`.

```lua
Library:OnUnload(function()
    print("Library was unloaded!")
end)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Callback to fire on unload | function | nil |

##### Unload

Disconnects all signals registered with `GiveSignal`, fires all `OnUnload` callbacks, destroys tooltips and the ScreenGui, and sets `Library.Unloaded = true`.

```lua
Library:Unload()
```

##### GiveSignal

Registers an `RBXScriptConnection` so it is automatically disconnected when `Library:Unload()` is called.

```lua
Library:GiveSignal(RunService.RenderStepped:Connect(function()
    -- your code
end))
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Connection to track | RBXScriptConnection | nil |

##### Toggle

Toggles the main window visibility. A convenience wrapper around `Window:Toggle()`.

```lua
Library:Toggle()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Force a specific state | boolean? | nil |

---

#### Theme & Registry

##### SetFont

```lua
Library:SetFont(Enum.Font.GothamMedium)
-- or
Library:SetFont(Font.fromEnum(Enum.Font.GothamMedium))
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | The font to apply | Font \| Enum.Font | nil |

##### SetNotifySide

```lua
Library:SetNotifySide("Left")
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Side to show notifications | "Left" \| "Right" | "Right" |

##### SetDPIScale

Sets the DPI scale for the entire library. The value is treated as a percentage (100 = normal).

```lua
Library:SetDPIScale(125) -- 125% scale
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | DPI scale percentage | number | 100 |

##### CalculateAutoDPIScale

Computes the DPIScale value (1-10) that best fits the current screen/viewport size.

```lua
local DPIValue = Library:CalculateAutoDPIScale()
local RoundedForSlider = Library:CalculateAutoDPIScale(1) -- e.g. 3.7
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Rounding digit count | number? | nil |

##### AddToRegistry

Registers a GuiObject so its properties are automatically updated when the theme changes.

```lua
Library:AddToRegistry(MyFrame, {
    BackgroundColor3 = "MainColor",
})
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | The GUI instance to track | GuiObject | nil |
| 2 | Property-to-scheme-key mapping | table | nil |

##### RemoveFromRegistry

```lua
Library:RemoveFromRegistry(MyFrame)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | The GUI instance to untrack | GuiObject | nil |

##### UpdateColorsUsingRegistry

Re-applies the current scheme to every registered instance. Called automatically when the theme changes.

```lua
Library:UpdateColorsUsingRegistry()
```

---

#### Color Helpers

##### GetBetterColor

```lua
local adjusted = Library:GetBetterColor(Color3.new(1, 0, 0), 0.1)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Base color | Color3 | nil |
| 2 | Value adjustment amount | number | nil |

##### GetLighterColor

```lua
local lighter = Library:GetLighterColor(Library.Scheme.MainColor)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Base color | Color3 | nil |

##### GetDarkerColor

```lua
local darker = Library:GetDarkerColor(Library.Scheme.MainColor)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Base color | Color3 | nil |

---

#### Misc Helpers

##### SafeCallback

Wraps a function call in error handling. If the call errors and `Library.NotifyOnError` is `true`, a notification is shown.

```lua
Library:SafeCallback(myFunction, arg1, arg2)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Function to call | function | nil |
| ... | Arguments to pass | any | nil |

##### GetTextBounds

```lua
local width, height = Library:GetTextBounds("Hello", Library.Scheme.Font, 14, 200)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Text to measure | string | nil |
| 2 | Font to use | Font | nil |
| 3 | Text size | number | nil |
| 4 | Max width constraint | number? | nil |

##### MouseIsOverFrame

```lua
local result = Library:MouseIsOverFrame(Frame, Mouse)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Frame to test | GuiObject | nil |
| 2 | Mouse position | Vector2 | nil |

##### Validate

Validates a table against a template (fills in missing keys).

```lua
Library:Validate(Table, Template)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Table to validate | table | nil |
| 2 | Template table | table | nil |

---

#### Properties

These are notable properties on the `Library` object that you can read or set:

Prop

Type

`Toggled?`boolean

`Unloaded?`boolean

`ForceCheckbox?`boolean

`NotifyOnError?`boolean

`IsMobile?`boolean

`Scheme?`Scheme

`AutoDPIScale?`boolean

`WaitForIconsOnLoad?`boolean

---

## 6. Addons

---

### SaveManager

Automatic configuration persistence for Toggles, Sliders, Dropdowns, and more.

---

#### Setup

SaveManager provides automatic configuration persistence: it always keeps an autosave watcher running in the background, so there's no separate "enable autosave" step or debounce configuration -- once you call `BuildConfigSection`, saving and loading are fully hands-off.

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/SaveManager.lua"))()

SaveManager:SetLibrary(Library)

-- Optional: Set custom folder (default: "AstralSettings")
SaveManager:SetFolder("MyScriptSettings")

-- Optional: Set subfolder for organization
SaveManager:SetSubFolder("profiles")

-- Optional: Ignore theme-related settings from saves (use when ThemeManager is also present)
SaveManager:IgnoreThemeSettings()
```

##### Key Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `SaveManager.Folder` | string | `"AstralSettings"` | Root folder for settings |
| `SaveManager.SubFolder` | string | `""` | Subfolder for organization |
| `SaveManager.Library` | Library | `nil` | Reference to the Astral library |
| `SaveManager.Ignore` | table | `{}` | Indexes to ignore during save/load |
| `SaveManager.CurrentConfig` | string? | `nil` | Name of the config currently loaded/active |
| `SaveManager.Scope` | `"Global"` \| `"Per-User"` | `"Global"` | Where configs are stored (see below) |
| `SaveManager.LoadingOrder` | table | `{}` | Element-type load order (used when `UseLoadingOrder` is on) |
| `SaveManager.UseLoadingOrder` | boolean | `false` | Sort loads by `LoadingOrder` |

---

#### Core Methods

```lua
SaveManager:Save(name: string): (success: boolean, error: string?)
SaveManager:Load(name: string): (success: boolean, error: string?)
SaveManager:Delete(name: string): (success: boolean, error: string?)
SaveManager:RefreshConfigList(): { string }
SaveManager:SetIgnoreIndexes(list: { string })
SaveManager:SetLoadingOrder(Enabled: boolean, Order: { string }?)
SaveManager:IgnoreThemeSettings()
SaveManager:ResetToDefaults()
SaveManager:EnsureStartupConfig(): (name: string)
SaveManager:StartAutoSaveWatcher()
SaveManager:SaveJSON(): (encoded: string?, success: boolean, error: string?)
SaveManager:LoadJSON(content: string): (success: boolean, error: string?)
SaveManager:CreateConfig(name: string): (success: boolean, error: string?)  -- new config from the current settings, then selects it
SaveManager:SelectConfig(name: string, silent: boolean?): boolean             -- saves the current config, loads another
SaveManager:SetScope(scope: "Global" | "Per-User"): (success: boolean, error: string?)
SaveManager:GetConfigFolder(scope: string?): string
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Config name | string | nil |

`SetLoadingOrder(true, { "Toggle", "Dropdown", "Slider" })` loads element types in the given order (everything else last). Loading fires each element's callbacks even when the saved value equals the current one. Keybind-menu state (visibility, position, collapsed, hidden entries) and collapsed-section states persist inside the config automatically. The names `"autoload"` and `"active"` are reserved.

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Config name | string | nil |

---

#### GUI Integration

```lua
SaveManager:BuildConfigSection(tab: Tab)
```

This creates a small "Configuration" section:

- **Config type**: `Global` (shared by every account, stored in `<Folder>/settings`) or `Per-User` (stored in `<Folder>/settings/users/<UserId>`)
- **Config file**: pick the config to use; selecting one loads it right away. The list refreshes itself, so there is no refresh button
- **Config name + Create config**: saves the current settings as a new config and switches to it

There are no save, load, overwrite or autoload options: changes are saved to the selected config automatically (detected within ~0.5s) and it is loaded again on the next launch. If a scope has no config yet, one is created for you (`<PlayerName>_Settings` for Global, `Default` for Per-User). The last scope and config you picked are remembered, and an older `autoload.txt` is still honored the first time.

`EnsureStartupConfig` runs as part of `BuildConfigSection`, so the player's own config (or a fresh default one) is loaded as soon as the config section itself is built.

---

#### Avoiding the "Flash of Default Values" on Startup

`SaveManager:Load()` can only set a value on a Toggle/Slider/etc. that **already exists** -- it looks elements up by name in `Library.Toggles`/`Library.Options`, which only get populated as your own `AddToggle`/`AddSlider`/etc. calls run. That means `Load()` runs after every element has been created. Astral builds the entire window cleanly off-screen, eliminating any default-value flashing or visual popping.

`SaveManager:Init` completes config loading and seamlessly reveals the UI:

```lua
-- 1. Attach SaveManager FIRST, before creating the window. This is required:
--    CreateWindow decides synchronously, before it returns, whether to
--    auto-show -- it only defers that if Library.DeferAutoShowTo is already
--    set. Calling SetLibrary after CreateWindow is too late.
SaveManager:SetLibrary(Library)

-- 2. Create the window (AutoShow defaults to true)
local Window = Library:CreateWindow({ Name = "My UI", AutoShow = true })

-- 3. Build every tab, section, and element for your ENTIRE UI here
local MainTab = Window:AddTab({ Name = "Main" })
-- ... AddToggle, AddSlider, etc. ...

local SettingsTab = Window:AddTab({ Name = "Settings" })
SaveManager:BuildConfigSection(SettingsTab)

-- 4. Load the config, THEN reveal the window (if AutoShow = true)
SaveManager:Init(Window)
```

`SaveManager:Init(Window)` re-runs `Load` against every element that now exists in the whole UI and then reveals the window if `AutoShow` is enabled. If `AutoShow = false`, the config is loaded silently and the UI remains hidden until the player presses the keybind or clicks the bubble -- **and if a `Bubble` toggle is saved as enabled in that config, the bubble is still created and shown even though the main window stays hidden.** SaveManager always routes the reveal through `Window:Toggle(...)` (never skips the call outright), which is also what triggers the bubble's first-time creation, so the bubble's on/off state from the loaded config is respected independently of whether the window itself is shown.

If you're also using a loading screen (`Library:CreateLoading`), `Window:Toggle(true)` is deferred while that loading screen is active and smoothly reveals the UI upon completion.

> **Note:** `SaveManager:SetLibrary` takes the `Library` object, not `Window`. Passing `Window` (e.g. `SaveManager:SetLibrary(Window)`) will not set up the auto-show deferral correctly -- always pass `Library`.
>
> **Ordering is strict, not just recommended.** If `SetLibrary` is called after `CreateWindow`, `Library.DeferAutoShowTo` is still `nil` at the moment `CreateWindow`'s internal auto-show check runs, so the window (and bubble, if enabled) may briefly auto-show with default/unloaded values before SaveManager's own load-and-reveal runs afterward -- a visible flash/flicker. `SaveManager:SetLibrary` now `warn()`s in the output if it detects this happened (i.e. if `Library.Toggled` is already `true` when `SetLibrary` runs), so misordered setup is easy to catch during testing.

---

#### Supported Element Types

SaveManager automatically handles the following element types:

- **Toggle**: Saves boolean state
- **Slider**: Saves numeric value
- **ProgressBar**: Saves numeric value
- **Dropdown**: Saves selected value
- **ColorPicker**: Saves color hex and transparency
- **KeyPicker**: Saves key, mode, and modifiers
- **Input**: Saves text content

---

#### Example Usage

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/SaveManager.lua"))()
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

local Tab = Window:AddTab({ Name = "Settings" })
SaveManager:BuildConfigSection(Tab)

SaveManager:Save("MyConfig")
SaveManager:Load("MyConfig")
```

**Autosave behavior:**

- A background watcher polls every ~0.5 seconds and compares a fingerprint of every registered Toggle/Option's value against its last known state
- On any change, it saves to whichever config is currently active (`SaveManager.CurrentConfig`)
- Saving is skipped entirely while a `Load()` is in progress, so applying saved values back onto the UI never gets mistaken for a user edit and re-saved

---

### ThemeManager

Built-in and custom theme management for the Astral color scheme.

---

#### Setup

ThemeManager provides comprehensive theme management with 18 built-in themes and support for custom theme creation, saving, and loading.

```lua
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/ThemeManager.lua"))()

ThemeManager:SetLibrary(Library)

-- Optional: Set custom folder (default: "AstralSettings")
ThemeManager:SetFolder("MyScriptSettings")

-- Optional: Set default theme before applying to tab
ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("ffffff"),
    MainColor = Color3.fromHex("191919"),
    AccentColor = Color3.fromHex("4287f5"),
    BackgroundColor = Color3.fromHex("0f0f0f"),
    OutlineColor = Color3.fromHex("282828"),
    FontFace = Enum.Font.Code
})
```

---

#### Built-in Themes

ThemeManager includes 18 pre-configured themes:

| Theme Name | Style |
| --- | --- |
| **Default** | Matches Astral's built-in scheme exactly |
| **BBot** | Purple accent |
| **Fatality** | Pink/purple accent |
| **Jester** | Red accent |
| **Mint** | Green accent |
| **Tokyo Night** | Purple/night theme |
| **Ubuntu** | Orange accent |
| **Quartz** | Blue/cyan theme |
| **Nord** | Nordic color scheme |
| **Dracula** | Dracula theme |
| **Monokai** | Monokai theme |
| **Gruvbox** | Gruvbox theme |
| **Solarized** | Solarized theme |
| **Catppuccin** | Catppuccin theme |
| **One Dark** | One Dark theme |
| **Cyberpunk** | Cyberpunk neon |
| **Oceanic Next** | Oceanic blue |
| **Material** | Material design |

---

#### Gradients and Transparency

Every built-in theme has a `GradientColor`. The window is painted with a gradient from the background color to the gradient color, so the whole UI has depth instead of a flat background. Themes (custom or imported) that don't define one get a gradient color derived from their accent color.

The theme section gets a **Gradient color** picker, a **Gradients** toggle (turn it off for a flat background) and a **Window transparency** slider (0-85%). The same controls exist in code:

```lua
Library:SetGradientsEnabled(false)
Library:SetWindowTransparency(0.2)       -- 0 = opaque, max 0.85
Library:SetGradientColor(Color3.fromHex("1b2540"))   -- nil = derived from the theme
Library:SetGradientRotation(45)          -- degrees

Window:SetTransparency(0.2)
Window:SetGradient(true)
```

The gradient and transparency cover the whole UI: the window, tab pages, sections, every control (including search boxes and inputs) and every overlay (draggable menus and labels, notifications, context menus, popped-out sections). Overlays get their own gradient and are fully opaque until you raise the transparency. Controls always let a little of the gradient show through while gradients are on.

Custom themes save their gradient color. The Gradients toggle and transparency slider are saved in your SaveManager config.

---

#### Key Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `ThemeManager.Folder` | string | `"AstralSettings"` | Root folder for themes |
| `ThemeManager.Library` | Library | `nil` | Reference to the Astral library |
| `ThemeManager.AppliedToTab` | boolean | `false` | Whether theme manager is applied to a tab |
| `ThemeManager.BuiltInThemes` | table | -- | Table of built-in themes |
| `ThemeManager.DefaultTheme` | string | `"Default"` | Default theme name |
| `ThemeManager.DefaultThemeName` | string? | `nil` | Theme saved as default (shown with a `(default)` suffix) |
| `ThemeManager.ContrastLabel` | Label? | `nil` | Live WCAG contrast readout label |

---

#### Core Methods

```lua
ThemeManager:ApplyTheme(themeName: string): (success: boolean, error: string?)
ThemeManager:ApplyThemeData(data: table): (success: boolean, error: string?)
ThemeManager:ThemeUpdate()
ThemeManager:GetCustomTheme(fileName: string): table?
ThemeManager:LoadDefault()
ThemeManager:SaveDefault(themeName: string): (success: boolean, error: string?)
ThemeManager:GetDefaultTheme(): (name: string, success: boolean, error: string?)
ThemeManager:DeleteDefaultTheme(): (success: boolean, error: string?)
ThemeManager:SetDefaultTheme(theme: table)
ThemeManager:SaveCustomTheme(fileName: string): (success: boolean, error: string?)
ThemeManager:Delete(themeName: string): (success: boolean, error: string?)
ThemeManager:ReloadCustomThemes(): { string }
ThemeManager:SaveJSON(): (encoded: string, success: boolean, error: string?)
ThemeManager:LoadJSON(content: string): (success: boolean, error: string?)
ThemeManager:GetContrastReport(): { Ratio: number, PairName: string, Passes: boolean }
ThemeManager:UpdateContrastWarning()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Theme name or theme table | string \| table | nil |

---

#### GUI Integration

```lua
-- Apply theme manager to a tab (creates full UI)
ThemeManager:ApplyToTab(tab: Tab)

-- Or create groupbox manually and apply
local groupbox = ThemeManager:CreateGroupBox(tab)
ThemeManager:ApplyToGroupbox(groupbox)

-- Or create theme manager UI in existing groupbox
ThemeManager:CreateThemeManager(groupbox: Section)
```

The GUI includes:

- Color pickers for all theme colors (Background, Main, Accent, Outline, Font)
- Live WCAG contrast readout (warns + notifies when text contrast drops below 4.5:1; saving a low-contrast theme asks for confirmation)
- Font face dropdown
- Background image input (custom icon or `http(s)` URL, also settable via `Library:SetBackgroundImage`)
- Built-in theme dropdown with instant preview (default theme marked `(default)`)
- Custom theme creation (name input + save button, overwrite asks first)
- Custom theme management (load, overwrite, delete, refresh -- destructive actions ask first)
- Default theme management (set/reset default with a live label)
- Theme JSON import/export (paste JSON to import, export copies to input + clipboard)
- Automatic theme update on color change

---

#### Theme Fields

Themes control the following color fields:

- **FontColor**: Text color
- **MainColor**: Primary UI element color
- **AccentColor**: Interactive element accent color
- **BackgroundColor**: Background color
- **OutlineColor**: Border/outline color
- **FontFace**: Font family
- **BackgroundImage**: Window background image (custom icon or URL, may be `""`)

---

#### Example Usage

```lua
-- Basic setup
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/ThemeManager.lua"))()
ThemeManager:SetLibrary(Library)

-- Add theme manager to a tab
local Tab = Window:AddTab({ Name = "Settings" })
ThemeManager:ApplyToTab(Tab)

-- Manual theme application
ThemeManager:ApplyTheme("Dracula")

-- Custom theme creation
ThemeManager:SaveCustomTheme("MyCustomTheme")

-- Set custom default theme
ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("ffffff"),
    MainColor = Color3.fromHex("1a1a2e"),
    AccentColor = Color3.fromHex("ff6b6b"),
    BackgroundColor = Color3.fromHex("0f0f1a"),
    OutlineColor = Color3.fromHex("2a2a3e"),
    FontFace = Enum.Font.Gotham
})
```

---

#### Integration with SaveManager

ThemeManager works seamlessly with SaveManager:

```lua
-- Set up both managers
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

-- Ignore theme settings in configs
SaveManager:IgnoreThemeSettings()

-- Theme settings will be managed separately by ThemeManager
-- Other settings will be saved/loaded by SaveManager
```

---

## Icon Reference

Icon name resolution rules for every `IconName` / `Icon` field across the library.

---

### Accepted Formats

Any `IconName` / `Icon` field across the library (tabs, sections, buttons, dialogs, notifications, etc.) accepts one of:

- A **Lucide icon name** from the [lucide.dev](https://lucide.dev) set, e.g. `"settings"`, `"crosshair"`, `"trash-2"`
- A **`rbxassetid://...`** string
- A raw **asset ID** number/string
- A full **asset URL**

Invalid or unrecognized names are handled gracefully (no icon is shown) rather than erroring.

```lua
Library:GetIcon(IconName)        -- Look up a Lucide icon directly
Library:GetCustomIcon(IconName)  -- Also resolves named built-in/custom assets, asset IDs, and URLs
Library:SetIconModule(module)    -- Swap in an external/custom Lucide module
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Icon name / asset id / url | string \| number | nil |

See [Utility -> Icons](#utility--helper-methods) for the full custom icon module type and the required built-in icon names.

---

## Advanced Utilities

Lower-level building blocks used internally by the library, exposed for advanced/custom UI work.

---

### Tooltips

Manually attach a hover tooltip to any `GuiObject`. Most elements already expose this via their `Tooltip`/`DisabledTooltip` fields -- use `AddTooltip` directly only when building custom UI.

```lua
local Tooltip = Library:AddTooltip("Shown normally", "Shown while disabled", SomeGuiObject)

Tooltip.Disabled = true   -- Switch to showing the disabled text
Tooltip:Destroy()         -- Disconnect and remove the tooltip
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | Text shown normally | string | nil |
| 2 | Text shown while disabled | string | nil |
| 3 | GuiObject to attach to | GuiObject | nil |

> Tooltips are automatically suppressed while a [Dialog](#dialogs) is open (`Library.ActiveDialog`), so a hover tooltip from an element behind the dialog can't appear on top of the modal.

---

### Focus Highlight

Attach an accent-coloured highlight to a text-entry field while it has focus. Every built-in text field already does this -- `AddInput`, the topbar search bar, a searchable dropdown's search bar, the color picker's hex/RGB boxes, editable sliders, and `AddKeyBox` -- so you only need this when building custom UI.

```lua
local Highlight = Library:AddFocusHighlight(SomeTextBox)

Library:AddFocusHighlight(SomeTextBox, SomeStroke, {
    Accent      = "AccentColor",  -- scheme key used while focused
    Color       = "OutlineColor", -- scheme key used while blurred
    Background  = true,           -- also lighten the background while focused
    BackgroundTarget = nil,       -- tint a different GuiObject (e.g. a parent Frame)
    BackgroundShift = 6,          -- brightness shift applied to the background
    Thickness   = nil,            -- resting stroke thickness (defaults to the stroke's own)
    Transparency = nil,           -- resting stroke transparency
    FocusedThickness = nil,       -- fixed 1px everywhere so all fields match (auto-divided by the UI scale so it stays one solid pixel on mobile)
    FocusedTransparency = nil,    -- defaults to 0
    Enabled     = true,           -- set false to skip attaching entirely
})
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | TextBox that drives the highlight via its `Focused`/`FocusLost` signals | TextBox | nil |
| 2 | Stroke to highlight. Defaults to the box's first `UIStroke`, or a new one if it has none | UIStroke? | nil |
| 3 | Options table, see above | { [string]: any }? | nil |

The highlight is theme-aware: the resting colours are read from `Library.Registry`, so a `ThemeManager` switch (even while a field is focused) restores the correct scheme colours instead of leaving a stale accent behind. States are tracked in `Library.FocusHighlights` and torn down by `Library:Unload()`.

---

### Context Menus

A low-level positioned popup/menu primitive (used internally for dropdowns, color pickers, and right-click menus). Useful when building fully custom elements.

```lua
local Menu = Library:AddContextMenu(
    HolderInstance,
    UDim2.fromOffset(200, 100),
    { 0, 30 },
    nil,
    function(Active) end,
    false
)

Menu:Open()
Menu:Close()
Menu:Toggle()
Menu:SetSize(UDim2.fromOffset(220, 120))
Menu:Remove()
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | GuiObject the menu is anchored to | GuiObject | nil |
| 2 | Size (UDim2 or function returning one) | UDim2 \| function | nil |
| 3 | Offset from the holder's position | {number, number} \| function | nil |
| 4 | List mode: nil (Frame), 1 (auto-size ScrollingFrame), 2 (scrollable list) | number? | nil |
| 5 | Callback fired on open/close | function? | nil |
| 6 | Ignore corner radius | boolean? | false |

Only one context menu can be open at a time globally -- opening a new one closes whichever was previously open. Like every other floating overlay, each context menu is registered in `Library.Overlays` on creation -- see [Overlay Manager](#overlays--draggable-panels) for bulk toggle/remove access (`OverlayType` is `"ContextMenu"`).

---

### Long Press as Right Click (Mobile)

`MouseButton2Click` (right click) has no equivalent on touch devices, which normally makes anything gated behind it -- context menus, the KeyPicker mode menu, the ColorPicker copy/paste menu, or any custom right-click handler you build -- unreachable on mobile. `Library:AddLongPressAsRightClick` wires up Roblox's native `TouchLongPress` gesture as a drop-in substitute.

```lua
-- Existing desktop right-click wiring, unchanged:
Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

-- Add the mobile equivalent alongside it:
Library:AddLongPressAsRightClick(Holder, ContextMenu.Toggle)
```

| Arg Idx | Argument Description | Type | Default |
| --- | --- | --- | --- |
| 1 | GuiObject to attach the gesture to | GuiObject | nil |
| 2 | Zero-argument function to call | function | nil |

- Internally connects `GuiObject.TouchLongPress` and calls `Func()` once per press (on `Enum.UserInputState.Begin`, not on every state update the gesture reports).
- Purely additive -- it doesn't touch or replace existing `MouseButton2Click` connections, so desktop behavior is identical.
- Returns the underlying `RBXScriptConnection` (already registered via `Library:GiveSignal`, so it's cleaned up automatically on `Library:Unload()`).
- Built into the library for the KeyPicker mode menu and the ColorPicker copy/paste menu -- both already open on long-press on mobile.

---

## Contributing

How to report issues or contribute to Astral.

---

### Reporting Issues

If you run into a bug or inconsistency, please open an issue on the repository with a minimal repro script (`Example.lua` is a good starting point to fork from).

### Suggesting Features

Feature requests are welcome. Please check the existing documentation first to confirm the behavior isn't already supported under a different method name.