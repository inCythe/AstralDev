--============================================================================
-- ASTRAL UI — QUICK REFERENCE EXAMPLE
--============================================================================

-- Load the Astral UI library.
local Library
local SaveManager
local ThemeManager

local AstralFolder = (typeof(script) == "Instance" and script.Parent and script.Parent:FindFirstChild("Astral") and script.Parent)
    or game:GetService("ReplicatedStorage"):FindFirstChild("Astral")

if AstralFolder and AstralFolder:FindFirstChild("Astral") then
    Library = require(AstralFolder:WaitForChild("Astral"))
    SaveManager = require(AstralFolder:WaitForChild("Addons"):WaitForChild("SaveManager"))
    ThemeManager = require(AstralFolder:WaitForChild("Addons"):WaitForChild("ThemeManager"))
else
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/Astral.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/SaveManager.lua"))()
    ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/Astral/refs/heads/main/addons/ThemeManager.lua"))()
end

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

--// Build stamp: proves which Astral.lua actually loaded (HttpGet can serve
--// a cached copy). Printed + shown in the window footer below. \\--
local AstralBuild = tostring((Library and (Library.BuildId or Library.VERSION)) or "unknown")
print("[Astral] loaded build:", AstralBuild)

-- NOTE: SetLibrary MUST be called before Library:CreateWindow (below), not
-- after. CreateWindow decides synchronously, before it returns, whether to
-- auto-show the window -- it only skips that if Library.DeferAutoShowTo is
-- already set at that exact moment. Calling SetLibrary after CreateWindow
-- is too late and can cause a visible flash of default/unloaded values.
-- This also means: if AutoShow ends up false from a loaded config, the
-- window itself stays hidden, but a bubble toggled on in that same config
-- is still created and shown -- bubble visibility is independent of window
-- visibility.

--============================================================================
-- WINDOW
--============================================================================
-- Library:CreateWindow(Info) -> Window
--   Title, Subtitle, Icon    Header text (Subtitle sits under it, smaller and lighter) and icon
--   Footer                    Footer text (middle); FooterLeft / FooterRight fill the other slots
--   Transparency, Gradient   Window see-through amount (0-0.85) and the background gradient on/off
--   Size, Center             UDim2 size, whether to center on screen
--   Resizable                Lets the user drag-resize the window
--   ToggleKeybind             Enum.KeyCode that shows/hides the window
--   NotifySide                "Left" | "Right" — which side notifications slide in from
--   DPIScale                  1-10 UI scale, 5 = 100% (see the Display section below)
--   SidebarWidth, EnableSidebarResize, SidebarCompacted
--   SingleInstance            Destroys any previous Astral window before creating this one
--============================================================================
local Window = Library:CreateWindow({
    Title            = "Astral UI — Reference",
    Subtitle         = "Quick Reference",
    TitleAlignment   = "Center",     -- "Left" | "Center" | "Right": where the title block sits and how the title aligns
    SubtitleAlignment = nil,         -- same options; nil follows TitleAlignment
    Icon             = "AstralIcon",
    Footer           = "RightControl toggles the UI",
    FooterLeft       = "Astral",
    FooterRight      = "Reference build",
    Size             = UDim2.fromOffset(940, 620),
    Center           = true,
    Resizable        = true,
    ToggleKeybind    = Enum.KeyCode.RightControl,
    NotifySide       = "Right",
    DPIScale         = 5,
    TitleSize        = 15,
    SidebarWidth     = 210,
    EnableSidebarResize = true,
    SidebarCompacted = false,
    Transparency     = 0,            -- 0-0.85: see-through amount for the window, pages, elements and overlays
    Gradient         = true,         -- gradient background across everything; false = flat colors
    GradientRotation = 45,
    PopOutBoxes      = true,         -- pop-out button on every section header
    TabButtonsStyle  = { Gap = 2, Padding = 0, CornerRadius = 0, Indicator = false, IndicatorWidth = 3, IndicatorHeight = 18 },
    SingleInstance   = true,
    AutoShow         = true,
})

--============================================================================
-- TAB SECTIONS  (Window:AddTabSection)
--   Name, Open   Sidebar group header text, and whether it starts expanded
--============================================================================
local ElementsSection = Window:AddTabSection({ Name = "Elements",  Open = true })
local LayoutSection   = Window:AddTabSection({ Name = "Layout",    Open = true })
local AdvancedSection = Window:AddTabSection({ Name = "Advanced",  Open = false })
local ShowcaseSection = Window:AddTabSection({ Name = "Showcase",  Open = false })
local SettingsSection = Window:AddTabSection({ Name = "Settings",  Open = false })

--============================================================================
-- TABS  (TabSection:AddTab)
--   Name, Icon, Description   Sidebar label, Lucide icon, and the one-line
--                              blurb shown at the top of the window when the
--                              tab is active.
--============================================================================
local FormTab      = ElementsSection:AddTab({ Name = "Form Controls", Icon = "sliders-horizontal", Description = "Toggles, sliders, dropdowns, inputs" })
local DisplayTab    = ElementsSection:AddTab({ Name = "Display",       Icon = "type",               Description = "Labels, rich text, progress bars, media" })
local ActionsTab    = ElementsSection:AddTab({ Name = "Actions",       Icon = "mouse-pointer-2",     Description = "Buttons, key pickers, color pickers" })

local LayoutsTab    = LayoutSection:AddTab({ Name = "Sections",       Icon = "columns-2",  Description = "Full-width vs. two-column layout" })
local NestedTab     = LayoutSection:AddTab({ Name = "Nested & Groups",Icon = "git-branch", Description = "Sub-sections, section groups, conditionals" })

local DialogsTab    = AdvancedSection:AddTab({ Name = "Dialogs",   Icon = "message-square",      Description = "Modal popups and confirmations" })
local OverlaysTab   = AdvancedSection:AddTab({ Name = "Overlays",  Icon = "picture-in-picture-2", Description = "Draggable overlays, context menus, and the overlay manager" })

local RowsTab       = ShowcaseSection:AddTab({ Name = "Rows & Combos",  Icon = "layout-dashboard", Description = "Dropdown + icon buttons, row widths" })
local RichTab       = ShowcaseSection:AddTab({ Name = "Icons & Subtext", Icon = "info",             Description = "Icons, subtext, section options" })
local DataTab       = ShowcaseSection:AddTab({ Name = "Data",           Icon = "columns-2",        Description = "Stepper, table, priority list" })
local DropdownTab   = ShowcaseSection:AddTab({ Name = "Dropdowns",      Icon = "list",             Description = "Layouts, multi-select, search" })
local WindowTab     = ShowcaseSection:AddTab({ Name = "Window & Overlays", Icon = "settings",      Description = "Tab groups, window API, notifications" })
local SettingsTab   = SettingsSection:AddTab({ Name = "Settings", Icon = "settings", Description = "UI scale, theme, and saved configs" })

--============================================================================
-- FORM CONTROLS TAB — Toggle, Checkbox, Slider, Dropdown, Input
--============================================================================
-- Section:AddToggle(Idx, Info) -> Toggle
--   Text, Default, Callback, Changed (alias of Callback), Risky, Disabled,
--   Visible, Tooltip, DisabledTooltip
-- Methods: SetValue, SetText, SetDisabled, SetVisible, OnChanged
-- Addons (attach after creation): Toggle:AddKeyPicker / Toggle:AddColorPicker / Toggle:AddSettings
--
-- Sections: the arrow button in a section header pops it out into a floating
-- panel (Section:SetPoppedOut). Section:SetMaxHeight(n) makes tall sections
-- scroll; SectionGroup:SetMaxHeight(n) does the same for tabbed groups.
local ToggleSection = FormTab:AddLeftSection("Toggle — every method")

local BasicToggle = ToggleSection:AddToggle("BasicToggle", {
    Text = "Basic Toggle",
    Default = false,
    Callback = function(Value)
        Library:Notify({ Title = "Toggle", Description = Value and "ON" or "OFF", Time = 1.5 })
    end,
})
-- OnChanged: attach an ADDITIONAL listener alongside Callback (both fire)
BasicToggle:OnChanged(function(Value)
    print({ Event = "BasicToggle", Value = Value })
end)

-- AddSettings: a gear button that expands a panel holding any normal elements
-- (also works on Label, Button, Input and Dropdown).
local BasicToggleSettings = BasicToggle:AddSettings()
BasicToggleSettings:AddSlider("BasicToggleStrength", {
    Text = "Strength",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
})
BasicToggleSettings:AddToggle("BasicToggleAnnounce", {
    Text = "Announce changes",
    Default = false,
})

-- ====================== Element combinations ======================
-- Rows put several controls on one line, icons/subtext decorate elements and sections,
-- and there are steppers, tables and priority lists.
local ComboSection = FormTab:AddSection({
    Side = 2,
    Name = "Combinations",
    Subtext = "Rows, steppers, tables, priority lists",
    Icon = "layout-dashboard",
    IconStyle = "Tile",
})

-- A dropdown with square icon buttons next to it. Width is "Fill" (default, shares the free space),
-- "Auto" (fits its content) or a number of pixels.
local PresetRow = ComboSection:AddRow()
PresetRow:AddDropdown("PresetList", { Values = { "Preset 1", "Preset 2" }, Default = 1 })
PresetRow:AddIconButton({ Icon = "pencil", Tooltip = "Rename", Func = function() print("rename") end })
PresetRow:AddIconButton({ Icon = "trash-2", Tooltip = "Delete", Func = function() print("delete") end })
PresetRow:AddIconButton({ Icon = "plus", Tooltip = "New preset", Func = function() print("new") end })

-- Icon + subtext on an element (IconStyle = "Tile" gives the accent icon tile).
ComboSection:AddToggle("AdvancedLanes", {
    Text = "Advanced Lanes",
    Subtext = "% of the path, per lane",
    Icon = "git-branch",
    IconStyle = "Tile",
})

-- +/- stepper with increments, defaults and text for special values.
ComboSection:AddStepper("StepAmount", { Text = "Amount", Icon = "layers", Default = 1, Min = 1, Max = 10 })
ComboSection:AddStepper("StepUpgrade", {
    Text = "Upgrade to",
    Icon = "chevrons-up",
    Default = 3,
    Min = 0,
    Max = 5,
    ValueTexts = { [5] = "Max", [0] = "Default" },
})

-- Label and selection box share a line by default. BoxSide = "Left" flips them, Layout = "Stacked" stacks them.
ComboSection:AddDropdown("ComboDifficulty", { Text = "Difficulty", Values = { "Easy", "Normal", "Hard" }, Default = "Hard" })
ComboSection:AddDropdown("ComboTargets", {
    Text = "Targets",
    Values = { "Head", "Torso", "Arms", "Legs" },
    Multi = true,
    Searchable = true, -- opens first; the search field only types once you click it
    Default = { "Head" },
})

-- Table for showing data.
local StatsTable = ComboSection:AddTable("StatsTable", {
    Text = "Session stats",
    Columns = { "Name", { Name = "Value", Align = "Right", Width = 70 } },
    Rows = { { "Kills", 12 }, { "Deaths", 3 }, { "Assists", 7 } },
    Selectable = true,
})
StatsTable:OnChanged(function(Index, Row)
    print("selected", Index, Row and Row[1])
end)

-- Priority list: each item can be moved up or down; the order is a list of ids.
local RunOrder = ComboSection:AddPriorityList("RunOrder", {
    Text = "Run order",
    Items = {
        { Id = "daily", Name = "Daily Challenge", Value = "Off" },
        { Id = "challenge", Name = "Challenge", Value = "Off" },
        { Id = "raid", Name = "Raid", Value = "Off" },
    },
})
RunOrder:OnChanged(function(Order)
    print("order:", table.concat(Order, ", "))
end)

-- Risky = true, combined with a Tooltip
ToggleSection:AddToggle("RiskyToggle", {
    Text = "Risky Toggle",
    Default = false,
    Risky = true,
    Tooltip = "Risky = true colors the label red",
})

-- Disabled = true at creation, with a DisabledTooltip explaining why
ToggleSection:AddToggle("DisabledToggle", {
    Text = "Disabled Toggle",
    Default = true,
    Disabled = true,
    DisabledTooltip = "Enabled via SetDisabled(false) by the button below",
})

ToggleSection:AddButton({
    Text = "SetValue (Basic Toggle)",
    Func = function()
        BasicToggle:SetValue(not BasicToggle.Value)
    end,
})
ToggleSection:AddButton({
    Text = "SetText (Basic Toggle)",
    Func = function()
        BasicToggle:SetText(BasicToggle.Value and "Now ON" or "Now OFF")
    end,
})
ToggleSection:AddButton({
    Text = "SetDisabled (Disabled Toggle)",
    Func = function()
        local T = Library.Toggles.DisabledToggle
        T:SetDisabled(not T.Disabled)
    end,
})
ToggleSection:AddButton({
    Text = "SetVisible (Basic Toggle)",
    Func = function()
        BasicToggle:SetVisible(not BasicToggle.Visible)
    end,
})

-- Section:AddCheckbox(Idx, Info) -> identical Info/API to AddToggle,
-- just rendered as a square checkbox instead of a pill switch.
-- Library:SetForceCheckbox(true) makes every AddToggle-created toggle
-- render as a checkbox, live, including ones already on screen.
local CheckboxSection = FormTab:AddRightSection("Checkbox variant")

CheckboxSection:AddCheckbox("BasicCheckbox", {
    Text = "Checkbox Style",
    Default = false,
    Callback = function(Value) print({ Event = "BasicCheckbox", Value = Value }) end,
})
CheckboxSection:AddCheckbox("RiskyCheckbox", {
    Text = "Risky Checkbox",
    Default = false,
    Risky = true,
})
CheckboxSection:AddToggle("ForceCheckboxGlobal", {
    Text = "Force ALL toggles to render as checkboxes",
    Default = false,
    Tooltip = "Calls Library:SetForceCheckbox -- live-updates every AddToggle toggle immediately",
    Callback = function(Value)
        Library:SetForceCheckbox(Value)
    end,
})

-- Section:AddSlider(Idx, Info) -> Slider
--   Text, Default, Min, Max, Rounding, Prefix, Suffix
--   Compact, HideMax, Editable, EditableStyle ("Pencil" | "ValueBox")
--   FormatDisplayValue(Slider, Value) -> string
-- Methods: SetValue, SetMin, SetMax, SetText, SetPrefix, SetSuffix,
--          SetDisabled, SetVisible, OnChanged
local SliderSection = FormTab:AddLeftSection("Slider — every method")

local SpeedSlider = SliderSection:AddSlider("SpeedSlider", {
    Text = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = " studs/s",
})
SpeedSlider:OnChanged(function(Value)
    print({ Event = "SpeedSlider", Value = Value })
end)

SliderSection:AddButton({
    Text = "SetMin (10)",
    Func = function()
        SpeedSlider:SetMin(10)
    end,
})
SliderSection:AddButton({
    Text = "SetMax (200)",
    Func = function()
        SpeedSlider:SetMax(200)
    end,
})
SliderSection:AddButton({
    Text = "SetValue (120)",
    Func = function()
        SpeedSlider:SetValue(120)
    end,
})
SliderSection:AddButton({
    Text = "SetPrefix (~)",
    Func = function()
        SpeedSlider:SetPrefix("~")
    end,
})
SliderSection:AddButton({
    Text = "SetSuffix (pts)",
    Func = function()
        SpeedSlider:SetSuffix(" pts")
    end,
})
SliderSection:AddButton({
    Text = "SetText (Rescaled Slider)",
    Func = function()
        SpeedSlider:SetText("Rescaled Slider")
    end,
})
SliderSection:AddButton({
    Text = "SetDisabled toggle",
    Func = function()
        SpeedSlider:SetDisabled(not SpeedSlider.Disabled)
    end,
})

-- Combination: Editable + EditableStyle "Pencil" (icon reveals a value box)
SliderSection:AddSlider("PencilSlider", {
    Text = "Editable (Pencil style)",
    Default = 50,
    Min = 0,
    Max = 100,
    Editable = true,
    EditableStyle = "Pencil",
})

-- Combination: Editable + EditableStyle "ValueBox" (always-visible box)
SliderSection:AddSlider("ValueBoxSlider", {
    Text = "Editable (ValueBox style)",
    Default = 25,
    Min = 0,
    Max = 100,
    Editable = true,
    EditableStyle = "ValueBox",
})

-- Combination: Compact + HideMax (single-row, value-only display)
SliderSection:AddSlider("CompactSlider", {
    Text = "Compact Slider",
    Default = 40,
    Min = 0,
    Max = 100,
    Compact = true,
    HideMax = true,
})

-- Combination: Rounding for decimals + FormatDisplayValue custom text
SliderSection:AddSlider("DecimalSlider", {
    Text = "Decimal Slider (2 places)",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
})
SliderSection:AddSlider("CustomFormatSlider", {
    Text = "Custom Format",
    Default = 50,
    Min = 0,
    Max = 100,
    FormatDisplayValue = function(Slider, Value)
        return string.format("Lvl %d / %d", Value, Slider.Max)
    end,
})

-- Section:AddDropdown(Idx, Info) -> Dropdown
--   Text, Values, DisabledValues, ValueImages, Default, Multi, AllowNull,
--   Searchable, MaxVisibleDropdownItems, FormatDisplayValue, FormatListValue,
--   SpecialType ("Player"|"Team"), ExcludeLocalPlayer, EnablePlayerImages
-- Methods: SetValue, SetSelectedValue, DeselectValue, ClearSelectedValues,
--          SetValues, AddValues, SetDisabledValues, AddDisabledValues,
--          SetValueImages, AddValueImages, SetText, SetDisabled, SetVisible,
--          OnChanged, GetActiveValues
local DropdownSection = FormTab:AddRightSection("Dropdown — single-select")

-- Basic single-select
local ModeDropdown = DropdownSection:AddDropdown("ModeDropdown", {
    Text = "Select Mode",
    Values = { "Option A", "Option B", "Option C" },
    Default = "Option A",
    Callback = function(Value) print({ Event = "ModeDropdown", Value = Value }) end,
})
ModeDropdown:OnChanged(function(Value)
    print({ Event = "ModeDropdown", Value = Value })
end)

-- Combination: AllowNull (can deselect the last item) + DisabledValues
DropdownSection:AddDropdown("NullableDropdown", {
    Text = "Nullable + Disabled Value",
    Values = { "Enabled", "Disabled Choice" },
    Default = nil,
    AllowNull = true,
    DisabledValues = { "Disabled Choice" },
})

-- Combination: Searchable single-select (filter box, no All/Clear buttons)
DropdownSection:AddDropdown("SearchableSingle", {
    Text = "Search a Country",
    Values = { "United States", "United Kingdom", "Canada", "Australia", "Germany", "France", "Japan" },
    Default = "United States",
    Searchable = true,
})

DropdownSection:AddButton({
    Text = "SetValue (Option B)",
    Func = function()
        ModeDropdown:SetValue("Option B")
    end,
})
DropdownSection:AddButton({
    Text = "SetText (Renamed Dropdown)",
    Func = function()
        ModeDropdown:SetText("Renamed Dropdown")
    end,
})
DropdownSection:AddButton({
    Text = "SetDisabled toggle",
    Func = function()
        -- ModeDropdown starts enabled (Disabled defaults to false), so a
        -- button that only ever calls SetDisabled(false) would be a no-op
        -- with nothing to show. Toggling off the current state actually
        -- demonstrates both the disabled and re-enabled look.
        ModeDropdown:SetDisabled(not ModeDropdown.Disabled)
    end,
})
DropdownSection:AddButton({
    Text = "AddValues -> Option D, E",
    Func = function()
        ModeDropdown:AddValues({ "Option D", "Option E" })
    end,
})
DropdownSection:AddButton({
    Text = "SetValues -> replace list",
    Func = function()
        ModeDropdown:SetValues({ "Fresh A", "Fresh B", "Fresh C" })
    end,
})
DropdownSection:AddButton({
    Text = "AddDisabledValues -> Fresh B",
    Func = function()
        ModeDropdown:AddDisabledValues({ "Fresh B" })
    end,
})

-- Combination: Multi + Searchable (adds All/Clear buttons for bulk-select)
-- + MaxVisibleDropdownItems to cap the list height before it scrolls
local RolesDropdown = FormTab:AddLeftSection("Dropdown — multi-select"):AddDropdown("RolesDropdown", {
    Text = "Search & Select Roles",
    Values = { "Admin", "Moderator", "Editor", "Viewer", "Contributor", "Reviewer", "Support", "Analyst" },
    Default = { "Admin", "Analyst" },
    Multi = true,
    Searchable = true,
    MaxVisibleDropdownItems = 6,
    Callback = function(Value) print({ Event = "RolesDropdown", Value = Value }) end,
})

-- GetActiveValues, SetSelectedValue, DeselectValue, ClearSelectedValues
local MultiControls = FormTab:AddRightSection("Multi-select methods")
MultiControls:AddButton({
    Text = "GetActiveValues -> Notify",
    Func = function()
        local Active = RolesDropdown:GetActiveValues()
        local Names = {}
        for Key in pairs(Active) do table.insert(Names, Key) end
        Library:Notify({ Title = "Selected Roles", Description = #Names > 0 and table.concat(Names, ", ") or "(none)", Time = 2.5 })
    end,
})
MultiControls:AddButton({
    Text = "SetSelectedValue('Editor')",
    Func = function()
        RolesDropdown:SetSelectedValue("Editor")
    end,
})
MultiControls:AddButton({
    Text = "DeselectValue('Admin')",
    Func = function()
        RolesDropdown:DeselectValue("Admin")
    end,
})
MultiControls:AddButton({
    Text = "ClearSelectedValues()",
    Func = function()
        RolesDropdown:ClearSelectedValues()
    end,
})

-- Section:AddInput(Idx, Info) -> Input
--   Text (label above box), Default, Placeholder, Finished, Numeric,
--   ClearTextOnFocus, ClearTextOnBlur, AllowEmpty, EmptyReset,
--   Validate / VerifyValue (VerifyValue forces Finished = true)
-- Methods: SetValue, SetText, SetDisabled, SetVisible, OnChanged
local InputSection = FormTab:AddLeftSection("Input — every method")

local NameInput = InputSection:AddInput("NameInput", {
    Text = "Your Name",
    Placeholder = "Type here...",
    Default = "",
})
NameInput:OnChanged(function(Value)
    print({ Event = "NameInput", Value = Value })
end)

InputSection:AddButton({
    Text = "SetValue (Astral)",
    Func = function()
        NameInput:SetValue("Astral")
    end,
})
InputSection:AddButton({
    Text = "SetText (Renamed Label)",
    Func = function()
        NameInput:SetText("Renamed Label")
    end,
})
InputSection:AddButton({
    Text = "SetDisabled toggle",
    Func = function()
        -- Same fix as ModeDropdown above -- NameInput starts enabled, so
        -- hardcoding SetDisabled(false) never actually disables anything.
        -- Toggle instead so the button visibly does something every click.
        NameInput:SetDisabled(not NameInput.Disabled)
    end,
})

-- Combination: Numeric + Finished (only fires on Enter, not every keystroke)
InputSection:AddInput("NumericInput", {
    Text = "Numeric Only (fires on Enter)",
    Placeholder = "123",
    Numeric = true,
    Finished = true,
    Callback = function(Value) print({ Event = "NumericInput", Value = Value }) end,
})

-- Combination: AllowEmpty = false + EmptyReset (falls back when cleared)
InputSection:AddInput("EmptyResetInput", {
    Text = "Falls Back When Empty",
    Placeholder = "Clear me and press Enter",
    Default = "DefaultValue",
    AllowEmpty = false,
    EmptyReset = "---",
})

-- Combination: Validate (reject bad text) — 3-20 alphanumeric chars
local ValidatedSection = FormTab:AddRightSection("Input — validation")
ValidatedSection:AddInput("ValidatedInput", {
    Text = "Username (3-20 chars)",
    Placeholder = "letters/numbers only",
    Default = "",
    Validate = function(Text)
        return #Text >= 3 and #Text <= 20 and Text:match("^%w+$")
    end,
})

-- Combination: Numeric + VerifyValue (auto-forces Finished = true)
ValidatedSection:AddInput("VerifiedInput", {
    Text = "Even Numbers Only",
    Placeholder = "Enter an even number",
    Default = "",
    Numeric = true,
    VerifyValue = function(Value)
        local Number = tonumber(Value)
        return Number ~= nil and Number % 2 == 0
    end,
})


--============================================================================
-- DISPLAY TAB — Divider, Label, rich text, ProgressBar, Image, Video, Viewport
--============================================================================
-- Section:AddDivider() / AddDivider("Text") / AddDivider({ Text, Margin, MarginTop, MarginBottom })
-- Returns Divider.Holder (root Frame) and Divider.Text
local DividerSection = DisplayTab:AddLeftSection("Divider")
DividerSection:AddLabel("Above the divider")
DividerSection:AddDivider("Labelled Divider")
DividerSection:AddLabel("Below the labelled divider")
DividerSection:AddDivider()
DividerSection:AddLabel("Below a plain (unlabelled) divider")
DividerSection:AddDivider({ Text = "Custom Margins", MarginTop = 8, MarginBottom = 8 })

-- Section:AddLabel(Text) or AddLabel({ Text, DoesWrap, Size, Visible })
-- Methods: SetText, SetVisible
-- Addons (non-wrapping labels only): Label:AddKeyPicker / Label:AddColorPicker
-- Rich text: <b>, <i>, <u>, <font color="rgb(r,g,b)">, <font face="...">
local LabelSection = DisplayTab:AddRightSection("Label — every method")

local CounterLabel = LabelSection:AddLabel("Counter: <font color=\"rgb(66,135,245)\">0</font>")
LabelSection:AddLabel({
    Text = "<b>Bold</b> · <i>Italic</i> · <u>Underline</u> · " ..
           "<font color=\"rgb(120,220,120)\">Colored</font> · " ..
           "<font face=\"RobotoMono\">Monospace</font>",
    DoesWrap = true,
    Size = 13,
})

local Count = 0
LabelSection:AddButton({
    Text = "SetText (increment counter)",
    Func = function()
        Count += 1
        CounterLabel:SetText(string.format("Counter: <font color=\"rgb(66,135,245)\">%d</font>", Count))
    end,
})
LabelSection:AddButton({
    Text = "SetVisible toggle",
    Func = function()
        CounterLabel:SetVisible(not CounterLabel.Visible)
    end,
})

-- Section:AddProgressBar(Idx, Info) -> ProgressBar (read-only; value only
-- changes via :SetValue -- cannot be dragged/edited by the user)
--   Text, Value, Min, Max, Rounding, Prefix, Suffix, Compact, HideMax
-- Methods: SetValue, SetMin, SetMax, SetText, SetPrefix, SetSuffix,
--          SetDisabled, SetVisible, OnChanged
local ProgressSection = DisplayTab:AddLeftSection("ProgressBar — every method")

local HealthBar = ProgressSection:AddProgressBar("HealthBar", {
    Text = "Health",
    Value = 100,
    Min = 0,
    Max = 100,
    Suffix = " HP",
})
HealthBar:OnChanged(function(Value)
    print({ Event = "HealthBar", Value = Value })
end)

ProgressSection:AddButton({
    Text = "SetValue (-25 HP)",
    Func = function()
        HealthBar:SetValue(math.max(0, HealthBar.Value - 25))
    end,
})
ProgressSection:AddButton({
    Text = "SetMax (200)",
    Func = function()
        HealthBar:SetMax(200)
    end,
})
ProgressSection:AddButton({
    Text = "SetPrefix (Shielded:)",
    Func = function()
        HealthBar:SetPrefix("Shielded: ")
    end,
})
ProgressSection:AddButton({
    Text = "SetSuffix (HP)",
    Func = function()
        HealthBar:SetSuffix(" HP")
    end,
})
ProgressSection:AddButton({
    Text = "SetText (Health Rescaled)",
    Func = function()
        HealthBar:SetText("Health (Rescaled)")
    end,
})
ProgressSection:AddButton({
    Text = "SetDisabled toggle",
    Func = function()
        HealthBar:SetDisabled(not HealthBar.Disabled)
    end,
})

-- Combination: Compact + HideMax (single-row, value-only display)
ProgressSection:AddProgressBar("CompactBar", {
    Text = "Compact Progress",
    Value = 60,
    Min = 0,
    Max = 100,
    Compact = true,
    HideMax = true,
})

-- Section:AddImage(Idx, Info) -> Image
--   Image (asset id / url / Lucide icon name), Color, Transparency,
--   BackgroundTransparency, RectOffset, RectSize, ScaleType, Height
-- Methods: SetImage, SetColor, SetTransparency, SetRectOffset,
--          SetRectSize, SetScaleType, SetHeight, SetVisible
local ImageSection = DisplayTab:AddRightSection("Image — every method")

local DemoImage = ImageSection:AddImage("DemoImage", {
    Image = "sparkles",
    Height = 90,
    ScaleType = Enum.ScaleType.Fit,
})
ImageSection:AddButton({
    Text = "SetImage (star)",
    Func = function()
        DemoImage:SetImage("star")
        task.delay(1.5, function()
            DemoImage:SetImage("sparkles")
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetColor (gold)",
    Func = function()
        DemoImage:SetColor(Color3.fromRGB(255, 200, 80))
        task.delay(1.5, function()
            DemoImage:SetColor(Color3.new(1, 1, 1))
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetTransparency (0.15)",
    Func = function()
        DemoImage:SetTransparency(0.15)
        task.delay(1.5, function()
            DemoImage:SetTransparency(0)
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetScaleType (Stretch)",
    Func = function()
        DemoImage:SetScaleType(Enum.ScaleType.Stretch)
        task.delay(1.5, function()
            DemoImage:SetScaleType(Enum.ScaleType.Fit)
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetHeight (130)",
    Func = function()
        DemoImage:SetHeight(130)
        task.delay(1.5, function()
            DemoImage:SetHeight(90)
        end)
    end,
})
ImageSection:AddButton({
    Text = "SetVisible toggle",
    Func = function()
        DemoImage:SetVisible(not DemoImage.Visible)
    end,
})

-- Section:AddVideo(Idx, Info) -> Video (VideoFrame for Roblox video assets)
--   Video, Looped, Playing, Volume, Height, Visible
-- Methods: SetVideo, SetLooped, SetVolume, SetPlaying, Play, Pause, SetHeight, SetVisible
local VideoSection = DisplayTab:AddLeftSection("Video — every method")
VideoSection:AddLabel({
    Text = "Provide a real rbxassetid:// video asset to see playback; this demo just showcases the method calls.",
    DoesWrap = true,
})
local DemoVideo = VideoSection:AddVideo("DemoVideo", {
    Video = "rbxassetid://0",
    Looped = false,
    Playing = false,
    Volume = 0.5,
    Height = 100,
})
VideoSection:AddButton({
    Text = "Play() / Pause()",
    Func = function()
        if DemoVideo.Playing then
            DemoVideo:Pause()
        else
            DemoVideo:Play()
        end
    end,
})
VideoSection:AddButton({
    Text = "SetLooped(true)",
    Func = function()
        DemoVideo:SetLooped(true)
    end,
})
VideoSection:AddButton({
    Text = "SetVolume (1.0)",
    Func = function()
        DemoVideo:SetVolume(1)
    end,
})

-- Section:AddViewport(Idx, Info) -> Viewport (embeds a live 3D ViewportFrame)
--   Object (BasePart/Model), Camera, Clone, AutoFocus, Interactive, Height
-- Methods: SetObject, SetCamera, SetInteractive, SetHeight, SetVisible, Focus
local ViewportSection = DisplayTab:AddRightSection("3D Viewport — every method")

local DemoModel = Instance.new("Model")
local DemoPart = Instance.new("Part")
DemoPart.Size = Vector3.new(3, 3, 3)
DemoPart.Anchored = true
DemoPart.Color = Color3.fromRGB(66, 135, 245)
DemoPart.Parent = DemoModel

local DemoViewport = ViewportSection:AddViewport("DemoViewport", {
    Object = DemoModel,
    Height = 130,
    Interactive = true,
    AutoFocus = true,
})
ViewportSection:AddButton({
    Text = "SetObject (swap model) + Focus()",
    Func = function()
        local NewModel = Instance.new("Model")
        local NewPart = Instance.new("Part")
        NewPart.Shape = Enum.PartType.Ball
        NewPart.Size = Vector3.new(4, 4, 4)
        NewPart.Anchored = true
        NewPart.Color = Color3.fromRGB(245, 66, 135)
        NewPart.Parent = NewModel

        DemoViewport:SetObject(NewModel)
        DemoViewport:Focus()
    end,
})
ViewportSection:AddButton({
    Text = "SetInteractive toggle",
    Func = function()
        DemoViewport:SetInteractive(not DemoViewport.Interactive)
    end,
})
ViewportSection:AddButton({
    Text = "SetHeight(180)",
    Func = function()
        DemoViewport:SetHeight(180)
    end,
})

-- Section:AddUIPassthrough(Idx, Info) -> embeds any GuiBase2d you built
-- yourself directly inside a section, at a fixed height.
--   Instance (required), Height, Visible
-- Methods: SetInstance, SetHeight, SetVisible
local PassthroughSection = DisplayTab:AddLeftSection("UI Passthrough")
local CustomFrame = Instance.new("TextLabel")
CustomFrame.Size = UDim2.new(1, 0, 1, 0)
CustomFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
CustomFrame.Text = "I'm a raw Instance()"
CustomFrame.TextColor3 = Color3.new(1, 1, 1)
CustomFrame.Font = Enum.Font.GothamMedium
CustomFrame.TextSize = 13
local Passthrough = PassthroughSection:AddUIPassthrough("CustomPass", {
    Instance = CustomFrame,
    Height = 36,
})
PassthroughSection:AddButton({
    Text = "SetHeight(60)",
    Func = function()
        Passthrough:SetHeight(60)
    end,
})
PassthroughSection:AddButton({
    Text = "SetVisible toggle",
    Func = function()
        Passthrough:SetVisible(not Passthrough.Visible)
    end,
})

--============================================================================
-- ACTIONS TAB — Button, sub-button, KeyPicker, ColorPicker
--============================================================================
-- Section:AddButton(Info) -> Button
--   Text, Func, DoubleClick, Risky, Disabled, Visible, Tooltip,
--   DisabledTooltip, Idx (optional, registers in Library.Buttons)
--   Shorthand: Section:AddButton("Label", function() end)
-- Methods: SetText, SetDisabled, SetVisible
-- Button:AddButton(Info) attaches a secondary sub-button to its right.
local ButtonSection = ActionsTab:AddLeftSection("Button — every method")

local MainButton = ButtonSection:AddButton({
    Text = "Click Me",
    Func = function()
        Library:Notify({ Title = "Clicked", Description = "Button fired.", Time = 2 })
    end,
})
-- Sub-button: a secondary action displayed inline to the right
MainButton:AddButton({
    Text = "Sub",
    Func = function()
        Library:Notify({ Title = "Sub-Button", Description = "Secondary action fired.", Time = 2 })
    end,
})

-- Shorthand form: AddButton("Label", function)
ButtonSection:AddButton("Shorthand Button", function()
    print({ Event = "ShorthandButton", Clicked = true })
end)

ButtonSection:AddButton({
    Text = "SetText (Renamed!)",
    Func = function()
        MainButton:SetText("Renamed!")
        task.delay(1, function()
            MainButton:SetText("Click Me")
        end)
    end,
})
ButtonSection:AddButton({
    Text = "SetDisabled toggle (Main Button)",
    Func = function()
        MainButton:SetDisabled(not MainButton.Disabled)
    end,
})
ButtonSection:AddButton({
    Text = "SetVisible toggle (Sub Button)",
    Func = function()
        local Sub = MainButton.SubButton
        if Sub then
            Sub:SetVisible(not Sub.Visible)
        end
    end,
})

-- Combination: DoubleClick + Risky (requires a confirming second click,
-- colored red as a visual warning for a destructive action)
ButtonSection:AddButton({
    Text = "Confirm to Delete",
    DoubleClick = true,
    Risky = true,
    Tooltip = "Click twice within 0.5s to confirm",
    Func = function()
        Library:Notify({ Title = "Deleted", Description = "Double-click confirmed.", Time = 2, Icon = "trash-2" })
    end,
})

-- Combination: Disabled + DisabledTooltip, re-enabled via SetDisabled
local DisabledDemo
DisabledDemo = ButtonSection:AddButton({
    Text = "Disable Myself",
    Tooltip = "Click to disable this button for 2 seconds",
    DisabledTooltip = "Currently disabled — wait a moment",
    Func = function()
        DisabledDemo:SetDisabled(true)
        DisabledDemo:SetText("Disabled...")
        task.delay(2, function()
            DisabledDemo:SetDisabled(false)
            DisabledDemo:SetText("Disable Myself")
        end)
    end,
})

-- KeyPicker attaches to a Toggle or Label:
--   Toggle:AddKeyPicker(Idx, Info) / Label:AddKeyPicker(Idx, Info)
--   Text, Default, DefaultModifiers, Mode ("Always"|"Toggle"|"Hold"|"Press"),
--   Modes, SyncToggleState, Blacklisted/Whitelisted (+Modifiers),
--   Callback(State), ChangedCallback(KeyCode, Modifiers), Clicked(State)
-- Methods: SetValue({Key,Mode,Modifiers}), GetState, SetText, OnChanged, OnClick
local KeySection = ActionsTab:AddRightSection("Key Picker — every mode")

local BoundToggle = KeySection:AddToggle("BoundToggle", {
    Text = "Keybound Toggle",
    Default = false,
})
-- SyncToggleState = true is required for Toggle/Hold modes to actually
-- flip the parent toggle's Value -- without it the key still fires
-- Callback but never calls Toggle:SetValue() under the hood.
local BoundKey = BoundToggle:AddKeyPicker("BoundToggleKey", {
    Text = "Toggle Keybind",
    Default = "F1",
    Mode = "Toggle",
    Modes = { "Toggle", "Hold", "Always" },
    SyncToggleState = true,
})
BoundKey:OnChanged(function(KeyCode, Modifiers)
    print({ Event = "BoundToggleKey", KeyCode = KeyCode, Modifiers = Modifiers })
end)

-- Mode = "Hold" on a mouse button, with SyncToggleState again
local HoldToggle = KeySection:AddToggle("HoldToggle", {
    Text = "Hold-to-Enable (MB2)",
    Default = false,
})
local HoldKey = HoldToggle:AddKeyPicker("HoldToggleKey", {
    Text = "Hold Keybind",
    Default = "MB2",
    Mode = "Hold",
    SyncToggleState = true,
})
HoldKey:OnChanged(function(KeyCode, Modifiers)
    print({ Event = "HoldToggleKey", KeyCode = KeyCode, Modifiers = Modifiers })
end)

-- Mode = "Press" with DefaultModifiers, attached to a Label (fires once
-- per press, doesn't hold a toggle state)
local PressLabel = KeySection:AddLabel("Modifier Combo (Ctrl+Shift, Press mode)")
PressLabel:AddKeyPicker("PressKey", {
    Text = "Ctrl+Shift Combo",
    Default = "F3",
    DefaultModifiers = { "LCtrl", "LShift" },
    Mode = "Press",
    Callback = function(State)
        print({ Event = "PressKey", State = State })
    end,
})

KeySection:AddButton({
    Text = "GetState() -> Notify",
    Func = function()
        Library:Notify({ Title = "Toggle Keybind State", Description = tostring(BoundKey:GetState()), Time = 2 })
    end,
})
KeySection:AddButton({
    Text = "SetValue({Key='F5'})",
    Func = function()
        BoundKey:SetValue({ Key = "F5" })
    end,
})

-- Every KeyPicker created above (BoundToggleKey, HoldToggleKey, PressKey)
-- auto-registers a row in the floating Keybinds panel, rendered as
-- "[Key] Text (Mode)" using each picker's own Text field. Library.KeybindFrame
-- is the panel itself; Library.KeybindContainer holds its entries.

-- ColorPicker attaches to a Toggle or Label:
--   Toggle:AddColorPicker(Idx, Info) / Label:AddColorPicker(Idx, Info)
--   Default (Color3), Transparency (0-1, adds an alpha slider), Title
-- Methods: SetValue(HSV table or Color3, Transparency?), SetValueRGB(Color3, Transparency?), OnChanged
local ColorSection = ActionsTab:AddLeftSection("Color Picker — every method")

local ColorLabel = ColorSection:AddLabel("Accent Color (no alpha)")
local AccentPicker = ColorLabel:AddColorPicker("AccentColor", {
    Default = Color3.fromRGB(66, 135, 245),
    Title = "Pick a Color",
})
AccentPicker:OnChanged(function(Color)
    print({ Event = "AccentColor", Color = Color })
end)

-- Combination: attached to a Toggle instead of a Label, with Transparency
-- enabled (adds an alpha slider to the popup)
local GlowToggle = ColorSection:AddToggle("GlowToggle", {
    Text = "Glow Color (with alpha)",
    Default = true,
})
local GlowPicker = GlowToggle:AddColorPicker("GlowColor", {
    Default = Color3.fromRGB(120, 220, 120),
    Transparency = 0.25,
    Title = "Glow Color",
})

ColorSection:AddButton({
    Text = "SetValueRGB (set to red)",
    Func = function()
        AccentPicker:SetValueRGB(Color3.fromRGB(255, 80, 80))
    end,
})
ColorSection:AddButton({
    Text = "SetValue with HSV table",
    Func = function()
        AccentPicker:SetValue({ 0.6, 1, 1 }) -- {Hue, Sat, Vib}
    end,
})
ColorSection:AddButton({
    Text = "SetValueRGB + Transparency on Glow",
    Func = function()
        GlowPicker:SetValueRGB(Color3.fromRGB(255, 220, 80), 0.5)
    end,
})


--============================================================================
-- SECTIONS TAB — full-width vs. two-column layout
--
--   Tab:AddSection({ Side = 1|2|nil })     Side = 1 -> left column
--   Tab:AddLeftSection(Name, Icon)         Side = 2 -> right column
--   Tab:AddRightSection(Name, Icon)        Side omitted -> full-width row
--
-- Sections render in the exact order you call these, top to bottom. A
-- Side=1 and a Side=2 call sitting next to each other share one row; any
-- full-width call always starts a fresh row. Mix and match freely.
--============================================================================
LayoutsTab:AddSection({
    Name = "Full-Width Row",
    IconName = "maximize",
}):AddLabel({
    Text = "This section has no Side set, so it spans the whole tab width.",
    DoesWrap = true,
})

local Left = LayoutsTab:AddLeftSection("Left Column")
Left:AddToggle("LeftToggle", { Text = "Left-side Toggle", Default = true })

local Right = LayoutsTab:AddRightSection("Right Column")
Right:AddToggle("RightToggle", { Text = "Right-side Toggle", Default = false })

LayoutsTab:AddSection({
    Name = "Back to Full-Width",
    IconName = "maximize",
}):AddLabel("A plain AddSection call always starts a new full-width row, even after a two-column row.")

local LeftB = LayoutsTab:AddLeftSection("Left Again")
LeftB:AddSlider("LeftSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

local RightB = LayoutsTab:AddRightSection("Right Again")
RightB:AddSlider("RightSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

--============================================================================
-- NESTED & GROUPS TAB — AddSubSection, AddSectionGroup, ConditionalGroup
--============================================================================
-- Section:AddSubSection(Info | Name, Icon) -> nested section, same element
-- methods as a regular Section. DefaultOpen controls initial state; Side
-- lets sub-sections alternate full-width/two-column the same way top-
-- level sections do.
local Parent = NestedTab:AddSection("Sub-Sections")

local SubA = Parent:AddSubSection({ Name = "Nested (open)", IconName = "chevron-down", DefaultOpen = true })
SubA:AddToggle("SubToggleA", { Text = "Nested Toggle", Default = false })

local SubB = Parent:AddSubSection({ Name = "Nested (closed)", IconName = "chevron-right", DefaultOpen = false })
SubB:AddLabel("Click the header above to expand this.")

-- Tab:AddSectionGroup({ Side }) -> Group with Group:AddTab(Name, Icon) pages
-- IMPORTANT: this is called on the Tab itself (like AddSection), NOT on
-- a Section object -- a section box has no AddSectionGroup method.
-- Shorthand: Tab:AddLeftSectionGroup(Name) / Tab:AddRightSectionGroup(Name)
-- Each page behaves like a Section. The first page added is shown first;
-- clicking a tab at the top of the box switches pages.
local GroupBox = NestedTab:AddSectionGroup({ Name = "DemoGroup" })
local PageOne = GroupBox:AddTab("Page One", "list")
local PageTwo = GroupBox:AddTab("Page Two", "settings")
PageOne:AddLabel("Content for Page One.")
PageTwo:AddLabel("Content for Page Two.")

-- Section:AddConditionalGroup() -> shows/hides a block of elements based
-- on other elements' values via :SetupDependencies({ {Element, Value}, ... })
local CondParent = NestedTab:AddSection("Conditional Group")
local Driver = CondParent:AddToggle("ShowExtra", { Text = "Show Extra Options", Default = false })

local ExtraGroup = CondParent:AddConditionalGroup()
ExtraGroup:AddSlider("ExtraSlider", { Text = "Only visible when ShowExtra is ON", Default = 50, Min = 0, Max = 100 })
ExtraGroup:SetupDependencies({
    { Driver, true },
})

-- Sub-sections can also alternate into a two-column layout inside a
-- single parent section, the same way Tab:AddLeftSection/AddRightSection
-- do at the top level -- just pass Side = 1 (left) or Side = 2 (right)
-- in the Info table. Two consecutive Side sub-sections share a row;
-- a sub-section without Side goes back to full width on its own row.
local TwoColParent = NestedTab:AddSection("Two-Column Nested Sub-Sections")

local SubLeft = TwoColParent:AddSubSection({ Name = "Movement", IconName = "footprints", Side = 1 })
SubLeft:AddToggle("SubSpeedToggle", { Text = "Speed Boost", Default = false })
SubLeft:AddSlider("SubSpeedAmount", { Text = "Amount", Default = 20, Min = 0, Max = 100 })

local SubRight = TwoColParent:AddSubSection({ Name = "Combat", IconName = "swords", Side = 2 })
SubRight:AddToggle("SubAimToggle", { Text = "Aim Assist", Default = false })
SubRight:AddSlider("SubAimStrength", { Text = "Strength", Default = 50, Min = 0, Max = 100 })

-- Back to full width after a two-column row -- this alternation (full ->
-- two-column -> full -> two-column) is tracked automatically per parent
-- section, same as it is for top-level tabs.
local SubFull = TwoColParent:AddSubSection({ Name = "Notes", IconName = "sticky-note" })
SubFull:AddLabel({ Text = "Full-width sub-section after a two-column row.", DoesWrap = true })

-- SectionGroup pages (Tab:AddSectionGroup) can nest two-column
-- sub-sections too, since each page behaves exactly like a Section.
local NestedGroupBox = NestedTab:AddSectionGroup({ Name = "Group + Nested Columns" })
local GroupPage = NestedGroupBox:AddTab("Loadout", "package")
local GPLeft = GroupPage:AddSubSection({ Name = "Primary", Side = 1 })
GPLeft:AddDropdown("PrimaryWeapon", { Text = "Weapon", Values = { "Rifle", "SMG", "Shotgun" }, Default = "Rifle" })
local GPRight = GroupPage:AddSubSection({ Name = "Secondary", Side = 2 })
GPRight:AddDropdown("SecondaryWeapon", { Text = "Weapon", Values = { "Pistol", "Knife" }, Default = "Pistol" })

--============================================================================
-- DIALOGS TAB — Window:AddDialog
--============================================================================
-- Window:AddDialog(Idx, Info) -> Dialog. A modal popup with a title,
-- description, optional body elements (same AddXxx methods as a
-- Section), and footer buttons.
-- Methods: SetTitle, SetDescription, SetButtonsAlignment, Dismiss,
--          AddFooterButton, RemoveFooterButton, SetButtonDisabled, SetButtonOrder
local Section = DialogsTab:AddSection("Modal Dialog")

Section:AddButton({
    Text = "Open Confirm Dialog",
    Func = function()
        Window:AddDialog("ConfirmDialog", {
            Title = "Delete Config?",
            Description = "This action cannot be undone.",
            Icon = "trash-2",
            AutoDismiss = true,
            OutsideClickDismiss = true,
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1 },
                Confirm = {
                    Title = "Delete",
                    Variant = "Destructive",
                    Order = 2,
                    Callback = function()
                        Library:Notify({ Title = "Deleted", Time = 2, Icon = "trash-2" })
                    end,
                },
            },
        })
    end,
})

-- Declared here (not `local` inside the button's Func) so the Save
-- FooterButton's Callback below -- created in the same closure -- can
-- see the Input reference each time the dialog is reopened.
local ConfigNameInput

Section:AddButton({
    Text = "Open Dialog with Body Elements",
    Func = function()
        local Dialog = Window:AddDialog("InputDialog", {
            Title = "Save Config",
            Description = "Give this config a name.",
            Icon = "save",
            FooterButtons = {
                Save = {
                    Title = "Save",
                    Variant = "Primary",
                    Order = 1,
                    -- A FooterButton Callback is invoked as Callback(Dialog)
                    -- -- it does NOT receive the body element's value. This
                    -- previously read `Value` as if it were a parameter,
                    -- which is always nil, so the notification showed
                    -- "Saved: nil" no matter what was typed. Body elements
                    -- keep their own state (like any other Input/Slider/
                    -- Dropdown), so read ConfigName.Value directly instead.
                    Callback = function()
                        local Name = ConfigNameInput.Value
                        if Name == nil or Name == "" then
                            Name = "(unnamed)"
                        end
                        Library:Notify({ Title = "Saved", Description = "Config name: " .. Name, Time = 2 })
                    end,
                },
            },
        })
        -- Keep a reference to the Input so the footer Callback above can
        -- read its current value -- you can also always reach it later via
        -- Library.Options["ConfigName"].Value from anywhere in the script.
        ConfigNameInput = Dialog:AddInput("ConfigName", { Text = "Config Name", Placeholder = "MyConfig" })
    end,
})

-- Buttons can start disabled and get re-enabled once some condition is
-- met (SetButtonDisabled), and WaitTime on a footer button shows a
-- countdown progress bar under it before it becomes clickable -- handy
-- for "hold on before you can confirm" style dialogs.
local Section2 = DialogsTab:AddSection("More Dialog Types")

Section2:AddButton({
    Text = "Open Validated-Input Dialog",
    Func = function()
        local NameInput -- filled in after AddInput below; read from the
                         -- Save Callback further down (Callback(Dialog)
                         -- never receives the typed value directly)

        local Dialog = Window:AddDialog("ValidatedDialog", {
            Title = "Rename Config",
            Description = "Save is disabled until you type a name.",
            Icon = "pencil",
            AutoDismiss = false,
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(D) D:Dismiss() end },
                Save = {
                    Title = "Save",
                    Variant = "Primary",
                    Order = 2,
                    Callback = function(D)
                        -- Read the value from the Input reference (or
                        -- equivalently Library.Options["RenameInput"].Value)
                        -- -- NOT from a Callback parameter, which is nil here.
                        Library:Notify({ Title = "Config Renamed", Description = "New name: " .. NameInput.Value, Time = 2 })
                        D:Dismiss()
                    end,
                },
            },
        })
        Dialog:SetButtonDisabled("Save", true)

        NameInput = Dialog:AddInput("RenameInput", { Text = "New Name", Placeholder = "Type to enable Save..." })
        NameInput:OnChanged(function(Value)
            Dialog:SetButtonDisabled("Save", Value == "" or Value == nil)
        end)
    end,
})

Section2:AddButton({
    Text = "Open Timed-Confirm Dialog (WaitTime)",
    Func = function()
        Window:AddDialog("TimedDialog", {
            Title = "Reset All Settings?",
            Description = "The confirm button unlocks after a short delay so you can't misclick.",
            Icon = "alert-triangle",
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1 },
                Confirm = {
                    Title = "Reset",
                    Variant = "Destructive",
                    Order = 2,
                    WaitTime = 3,
                    Callback = function()
                        Library:Notify({ Title = "Settings Reset", Time = 2, Icon = "rotate-ccw" })
                    end,
                },
            },
        })
    end,
})

Section2:AddButton({
    Text = "Open Info Dialog (no footer buttons)",
    Func = function()
        -- FooterButtons can be omitted entirely -- the divider/button row
        -- auto-hides and OutsideClickDismiss (default true) lets the user
        -- close it by clicking outside, like a plain toast-style modal.
        Window:AddDialog("InfoDialog", {
            Title = "Did You Know?",
            Description = "Click anywhere outside this dialog to close it -- no button needed.",
            Icon = "info",
        })
    end,
})

-- ButtonsAlignment accepts "Left" | "Center" | "Right" and can be set either
-- up-front via the ButtonsAlignment prop, or live afterwards via
-- Dialog:SetButtonsAlignment(...). Three separate buttons below so each
-- alignment can actually be seen (setting it up-front and then immediately
-- overriding it live, as in a single combined demo, would only ever show
-- the last value applied).

Section2:AddButton({
    Text = "Open Left-Aligned Buttons Dialog",
    Func = function()
        Window:AddDialog("AlignDialogLeft", {
            Title = "Buttons Alignment -- Left",
            Description = "ButtonsAlignment = \"Left\" pins the footer row to the left edge of the dialog.",
            ButtonsAlignment = "Left",
            FooterButtons = {
                Reset = { Title = "Reset", Variant = "Secondary", Order = 1 },
                Ok = { Title = "Got it", Variant = "Primary", Order = 2 },
            },
        })
    end,
})

Section2:AddButton({
    Text = "Open Center-Aligned Buttons Dialog",
    Func = function()
        local Dialog = Window:AddDialog("AlignDialogCenter", {
            Title = "Buttons Alignment -- Center",
            Description = "ButtonsAlignment = \"Center\" centers the footer row. This one also demonstrates SetButtonOrder -- Reset was added first but is reordered after Got it.",
            ButtonsAlignment = "Center",
            FooterButtons = {
                Reset = { Title = "Reset", Variant = "Secondary", Order = 1 },
                Ok = { Title = "Got it", Variant = "Primary", Order = 2 },
            },
        })
        -- Per-button order can be changed live, after the dialog is already open:
        Dialog:SetButtonOrder("Reset", 3) -- swap Reset to appear after Got it
    end,
})

Section2:AddButton({
    Text = "Open Right-Aligned Buttons Dialog",
    Func = function()
        Window:AddDialog("AlignDialogRight", {
            Title = "Buttons Alignment -- Right",
            Description = "ButtonsAlignment = \"Right\" pushes the footer row to the right edge -- the common default for dialog buttons.",
            ButtonsAlignment = "Right",
            FooterButtons = {
                Reset = { Title = "Reset", Variant = "Secondary", Order = 1 },
                Ok = { Title = "Got it", Variant = "Primary", Order = 2 },
            },
        })
    end,
})

Section2:AddButton({
    Text = "Open Multi-Step Dialog",
    Func = function()
        local Dialog = Window:AddDialog("MultiStepDialog", {
            Title = "Step 1 of 2",
            Description = "Pick a name, then confirm on the next step.",
            Icon = "arrow-right",
            AutoDismiss = false,
            FooterButtons = {
                Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(D) D:Dismiss() end },
                Next = {
                    Title = "Next",
                    Variant = "Primary",
                    Order = 2,
                    Callback = function(D)
                        D:SetTitle("Step 2 of 2")
                        D:SetDescription("Confirm the change below.")
                        D:RemoveFooterButton("Next")
                        D:AddFooterButton("Confirm", {
                            Title = "Confirm",
                            Variant = "Primary",
                            Order = 2,
                            Callback = function(D2)
                                Library:Notify({ Title = "Multi-Step Dialog", Description = "Completed!", Time = 2 })
                                D2:Dismiss()
                            end,
                        })
                    end,
                },
            },
        })
    end,
})

Section2:AddButton({
    Text = "Open Loading-Style Dialog (WaitTime + Icon)",
    Func = function()
        Window:AddDialog("LoadingDialog", {
            Title = "Applying Changes",
            Description = "This closes itself once the wait finishes.",
            Icon = "loader",
            OutsideClickDismiss = false,
            FooterButtons = {
                Working = {
                    Title = "Please Wait...",
                    Variant = "Secondary",
                    Order = 1,
                    WaitTime = 2,
                    Callback = function(D)
                        Library:Notify({ Title = "Changes Applied", Time = 2, Icon = "circle-check" })
                        D:Dismiss()
                    end,
                },
            },
        })
    end,
})


--============================================================================
-- OVERLAYS TAB — Draggable overlays, the Context Menu primitive, and the
-- central Overlay Manager (toggle/remove overlays in bulk)
--============================================================================
-- Library:AddDraggableLabel(Text) / Library:AddDraggableButton(Text, Func)
-- Library:AddDraggableToggle(Text, Default, Callback)
-- Library:AddDraggableProgress(Text, Default, Max)
-- Floating panels that live outside the main window. Every one of these
-- (plus AddDraggableMenu and AddContextMenu below) is automatically added
-- to Library.Overlays -- see the "Overlay Manager" section further down
-- for the bulk toggle/remove API.
local OverlaySection = OverlaysTab:AddLeftSection("Draggable Overlays")

OverlaySection:AddButton({
    Text = "Spawn Draggable Label",
    Func = function()
        Library:AddDraggableLabel("Drag me around")
    end,
})
OverlaySection:AddButton({
    Text = "Spawn Draggable Button",
    Func = function()
        Library:AddDraggableButton("Click me", function()
            Library:Notify({ Title = "Draggable Button", Description = "Clicked!", Time = 2 })
        end)
    end,
})
OverlaySection:AddButton({
    Text = "Spawn Draggable Toggle",
    Func = function()
        Library:AddDraggableToggle("Auto Farm", false, function(Value)
            Library:Notify({ Title = "Draggable Toggle", Description = "Auto Farm: " .. tostring(Value), Time = 2 })
        end)
    end,
})
OverlaySection:AddButton({
    Text = "Spawn Draggable Progress",
    Func = function()
        local Progress = Library:AddDraggableProgress("Loading...", 0, 100)
        local Value = 0
        task.spawn(function()
            while Value < 100 and Progress:IsVisible() do
                Value += math.random(5, 15)
                Progress:SetValue(Value)
                task.wait(0.5)
            end
        end)
    end,
})

-- --------------------------------------------------------------
-- Overlay Manager: every draggable label/button/toggle/progress/
-- menu, and every context menu, is automatically registered in a
-- single central registry the moment it's created -- no manual
-- bookkeeping needed on your end. Use this to build a "Toggle UI
-- Elements" style panel, a cleanup routine, or a settings option
-- that hides/shows/removes overlays in bulk.
--
--   Library:GetOverlays(Type?)          -> array of overlay tables
--                                           (Type filters e.g. "DraggableLabel")
--   Library:GetOverlay(Id)              -> single overlay table, or nil
--   Overlay:SetVisible(bool) / :IsVisible() / :Remove()
--   Library:SetOverlayVisible(Id, bool) / :ToggleOverlay(Id) / :RemoveOverlay(Id)
--   Library:SetAllOverlaysVisible(bool, Type?)
--   Library:RemoveAllOverlays(Type?)
--
-- Every overlay table also carries .Id, .OverlayType, and .OverlayName
-- so you can build a list UI (like below) without tracking anything
-- yourself.
-- --------------------------------------------------------------
local ManagerSection = OverlaysTab:AddLeftSection("Overlay Manager")

ManagerSection:AddLabel({
    Text = "Spawn a few overlays above, then manage them here.",
    DoesWrap = true,
})

ManagerSection:AddButton({
    Text = "List Active Overlays",
    Func = function()
        local Overlays = Library:GetOverlays()
        if #Overlays == 0 then
            Library:Notify({ Title = "Overlay Manager", Description = "No overlays are currently active.", Time = 2 })
            return
        end

        local Lines = {}
        for _, Overlay in Overlays do
            table.insert(Lines, string.format("#%d  %s  (%s)", Overlay.Id, Overlay.OverlayName, Overlay.OverlayType))
        end

        Window:AddDialog("OverlayListDialog", {
            Title = string.format("Active Overlays (%d)", #Overlays),
            Description = table.concat(Lines, "\n"),
            Icon = "picture-in-picture-2",
            FooterButtons = {
                Ok = { Title = "Close", Variant = "Secondary", Order = 1 },
            },
        })
    end,
})

ManagerSection:AddButton({
    Text = "Hide All Overlays",
    Func = function()
        Library:SetAllOverlaysVisible(false)
        Library:Notify({ Title = "Overlay Manager", Description = "All overlays hidden.", Time = 2 })
    end,
})
ManagerSection:AddButton({
    Text = "Show All Overlays",
    Func = function()
        Library:SetAllOverlaysVisible(true)
        Library:Notify({ Title = "Overlay Manager", Description = "All overlays shown.", Time = 2 })
    end,
})
ManagerSection:AddButton({
    Text = "Remove Newest Overlay",
    Func = function()
        local Overlays = Library:GetOverlays()
        local Newest = Overlays[#Overlays]
        if not Newest then
            Library:Notify({ Title = "Overlay Manager", Description = "Nothing to remove.", Time = 2 })
            return
        end
        local Name = Newest.OverlayName
        Library:RemoveOverlay(Newest.Id)
        Library:Notify({ Title = "Overlay Manager", Description = "Removed " .. Name, Time = 2 })
    end,
})
ManagerSection:AddButton({
    Text = "Remove All Overlays",
    Risky = true,
    Func = function()
        Library:RemoveAllOverlays()
        Library:Notify({ Title = "Overlay Manager", Description = "All overlays removed.", Time = 2 })
    end,
})

-- --------------------------------------------------------------
-- Context Menu: the low-level positioned-popup primitive used
-- internally by dropdowns and color pickers. Anchor it to any
-- GuiObject and put whatever content you want inside Menu.Menu.
--
--   Library:AddContextMenu(Holder, Size, Offset, List, ActiveCallback, IgnoreCornerRadius)
--     Holder   GuiObject the menu is anchored to
--     Size     UDim2 (or a function returning one)
--     Offset   {x, y} pixel offset from Holder's position (or a function)
--     List     nil = plain Frame, 1 = auto-sizing list, 2 = scrollable list
--   Returns a Menu table: Menu:Open() / :Close() / :Toggle() / :SetSize(UDim2)
--   Only one context menu is open globally at a time.
-- --------------------------------------------------------------
local ContextSection = OverlaysTab:AddRightSection("Context Menu (Advanced)")

ContextSection:AddLabel({
    Text = "Right-click the box below to open a custom context menu (or long-press it on mobile, where there's no right mouse button to click).",
    DoesWrap = true,
})

local Anchor = Instance.new("TextButton")
Anchor.Size = UDim2.new(1, 0, 0, 36)
Anchor.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
Anchor.Text = "Right-Click Me"
Anchor.TextColor3 = Color3.new(1, 1, 1)
Anchor.Font = Enum.Font.GothamMedium
Anchor.TextSize = 14
Anchor.AutoButtonColor = false
ContextSection:AddUIPassthrough("ContextAnchor", { Instance = Anchor, Height = 40 })

local RightClickMenu = Library:AddContextMenu(
    Anchor,
    UDim2.fromOffset(180, 90),
    { 0, 6 },
    nil,
    function(Active) end,
    false
)

local MenuLabel = Instance.new("TextLabel")
MenuLabel.BackgroundTransparency = 1
MenuLabel.Size = UDim2.fromScale(1, 1)
MenuLabel.Text = "Custom context menu\ncontent goes here"
MenuLabel.TextColor3 = Color3.new(1, 1, 1)
MenuLabel.TextSize = 13
MenuLabel.Font = Enum.Font.Gotham
MenuLabel.ZIndex = RightClickMenu.Menu.ZIndex -- match the menu's own ZIndex; needed for correct render order
MenuLabel.Parent = RightClickMenu.Menu

Anchor.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightClickMenu:Toggle()
    end
end)

-- Mobile substitute: there's no right mouse button on a touch screen, so
-- MouseButton2 above never fires there. Library:AddLongPressAsRightClick
-- hooks Roblox's native TouchLongPress gesture and calls the same Toggle,
-- so a long-press opens this exact menu on phones/tablets too.
Library:AddLongPressAsRightClick(Anchor, function()
    RightClickMenu:Toggle()
end)

-- Toggle Bubble: floating chat-head style toggle that opens/closes the
-- window. Shown automatically on mobile, or force it on/off yourself:
--   CreateWindow-time: Bubble = true, BubbleSide, BubbleIcon, BubbleColor,
--                      BubbleIconColor, BubbleSize
--   Runtime:           Library:ToggleBubble() / (true) / (false)
local BubbleSection = OverlaysTab:AddLeftSection("Toggle Bubble")
BubbleSection:AddToggle("BubbleToggle", {
    Text = "Enable Floating Bubble",
    Default = true,
    Callback = function(Value)
        Library:ToggleBubble(Value)
    end,
})

-- --------------------------------------------------------------
-- Keybind Frame: the library automatically builds ONE draggable
-- panel (Library.KeybindFrame) the moment CreateWindow runs, and
-- every AddKeyPicker with Mode = "Toggle" registers a row into it
-- (showing "[Key] Label (Toggle)" plus its own on/off state) whenever
-- that keybind is actively toggled on. It's hidden by default until
-- the first such row appears, and it obeys ShowToggleFrameInKeybinds
-- like any other keybind row.
--
-- It's a plain Frame under the hood (Library.KeybindFrame.Visible),
-- so it's also just as easy to show/hide by hand -- e.g. if you want
-- an explicit "show my active keybinds" switch instead of relying on
-- it auto-appearing, or want to hide it entirely for a cleaner overlay
-- layout. This toggle does exactly that.
-- --------------------------------------------------------------
local KeybindFrameSection = OverlaysTab:AddRightSection("Keybind Frame")

KeybindFrameSection:AddLabel({
    Text = "Add a Toggle-mode key picker (Actions tab) to see rows appear here automatically.",
    DoesWrap = true,
})

KeybindFrameSection:AddToggle("ShowKeybindFrameToggle", {
    Text = "Show Keybind Frame",
    Default = false,
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end,
})

-- --------------------------------------------------------------
-- Draggable Menu: a full floating panel with its own title bar
-- (drag from the title to move it) and a content container you fill
-- with normal Add* element calls -- effectively a second, independent
-- mini-window that lives outside the main Window entirely.
--
--   Library:AddDraggableMenu(Name) -> Holder, RawContainer, Container
--     Holder        the whole panel (title bar + body), draggable by title
--     RawContainer  the raw content Frame Instance (rarely needed directly)
--     Container     element-friendly wrapper -- use THIS for AddButton/
--                   AddToggle/etc., same methods as any normal Section
-- --------------------------------------------------------------
local DraggableMenuSection = OverlaysTab:AddRightSection("Draggable Menu (Full Panel)")
DraggableMenuSection:AddButton({
    Text = "Spawn Draggable Menu",
    Func = function()
        local _MenuHolder, _RawContainer, MenuContainer = Library:AddDraggableMenu("Quick Actions")

        -- No need to build your own close button -- every draggable menu
        -- already has minimize (-) and close (x) buttons built into its
        -- title bar, styled to match the main window's own controls.
        MenuContainer:AddButton({
            Text = "Notify Me",
            Func = function()
                Library:Notify({ Title = "Hello from a draggable menu", Time = 2 })
            end,
        })
        MenuContainer:AddToggle("DragMenuToggle", { Text = "Some Setting", Default = false })
        MenuContainer:AddSlider("DragMenuSlider", { Text = "Some Value", Default = 25, Min = 0, Max = 100 })

        -- AddUIPassthrough still works normally inside a draggable menu
        -- for embedding your own raw Instances -- ZIndex is now handled
        -- automatically (see the note in Astral.lua's AddUIPassthrough),
        -- so this renders correctly above the menu's own background
        -- without needing any manual ZIndex bookkeeping.
        local CustomLabel = Instance.new("TextLabel")
        CustomLabel.BackgroundTransparency = 1
        CustomLabel.Text = "I'm a passthrough Instance, correctly layered"
        CustomLabel.TextColor3 = Color3.new(1, 1, 1)
        CustomLabel.TextWrapped = true
        CustomLabel.Font = Enum.Font.Gotham
        CustomLabel.TextSize = 12
        MenuContainer:AddUIPassthrough("DragMenuNote", { Instance = CustomLabel, Height = 30 })
    end,
})

-- --------------------------------------------------------------
-- Context Menu, List mode: pass List = 1 (auto-sizing) or List = 2
-- (fixed-size + scrollbar) as the 4th argument to get a UIListLayout
-- pre-built inside Menu.Menu, exactly like the dropdown/color-picker
-- popups use internally. Good for a right-click actions menu with a
-- variable number of rows.
-- --------------------------------------------------------------
local ListMenuSection = OverlaysTab:AddRightSection("Context Menu (List Mode)")
ListMenuSection:AddLabel({ Text = "Right-click below for a list-style menu.", DoesWrap = true })

local ListAnchor = Instance.new("TextButton")
ListAnchor.Size = UDim2.new(1, 0, 0, 36)
ListAnchor.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
ListAnchor.Text = "Right-Click For Actions"
ListAnchor.TextColor3 = Color3.new(1, 1, 1)
ListAnchor.Font = Enum.Font.GothamMedium
ListAnchor.TextSize = 14
ListAnchor.AutoButtonColor = false
ListMenuSection:AddUIPassthrough("ListMenuAnchor", { Instance = ListAnchor, Height = 40 })

local ListMenu = Library:AddContextMenu(
    ListAnchor,
    UDim2.fromOffset(160, 0),
    { 0, 6 },
    1 -- List = 1: auto-sizing vertical list
)
ListMenu.List.Padding = UDim.new(0, 2)

local function AddListMenuRow(Text, Func)
    local Row = Instance.new("TextButton")
    Row.Size = UDim2.new(1, 0, 0, 24)
    Row.BackgroundTransparency = 1
    Row.Text = Text
    Row.TextColor3 = Color3.new(1, 1, 1)
    Row.TextSize = 13
    Row.Font = Enum.Font.Gotham
    Row.ZIndex = ListMenu.Menu.ZIndex
    Row.Parent = ListMenu.Menu
    Row.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func)
        ListMenu:Close()
    end)
end
AddListMenuRow("Rename", function() Library:Notify({ Title = "Rename clicked", Time = 1.5 }) end)
AddListMenuRow("Duplicate", function() Library:Notify({ Title = "Duplicate clicked", Time = 1.5 }) end)
AddListMenuRow("Delete", function() Library:Notify({ Title = "Delete clicked", Time = 1.5 }) end)

ListAnchor.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        ListMenu:Toggle()
    end
end)

--============================================================================
-- SHOWCASE: every newer element, option and method
--============================================================================

-- ---------------------------------------------------------------------------
-- Rows & combinations
-- ---------------------------------------------------------------------------
local PresetSection = RowsTab:AddSection({
    Side = 1,
    Name = "Dropdown + icon buttons",
    Subtext = "Section:AddRow() puts controls on one line",
    Icon = "layout-dashboard",
    IconStyle = "Tile",
})

-- Row item sizing: Width = "Fill" (default, shares the free space), "Auto" (fits its content), or pixels.
-- Weight changes how much of the free space a Fill item takes.
local PresetRow = PresetSection:AddRow()
local PresetDropdown = PresetRow:AddDropdown("Show_Preset", { Values = { "Preset 1", "Preset 2", "Preset 3" }, Default = 1 })
PresetRow:AddIconButton({ Icon = "pencil", Tooltip = "Rename", Func = function() Library:Notify("Rename preset") end })
PresetRow:AddIconButton({ Icon = "trash-2", Tooltip = "Delete", Risky = true, Func = function() Library:Notify("Delete preset") end })
PresetRow:AddIconButton({ Icon = "plus", Tooltip = "New preset", Func = function() Library:Notify("New preset") end })

PresetSection:AddDivider("Width modes")

local WidthRow = PresetSection:AddRow()
WidthRow:AddButton({ Text = "Fill (x1)" })
WidthRow:AddButton({ Text = "Fill (x2)", Weight = 2 })
WidthRow:AddButton({ Text = "120px", Width = 120 })

local AutoRow = PresetSection:AddRow()
AutoRow:AddIconButton({ Icon = "plus", Text = "Auto", Width = "Auto" })
AutoRow:AddIconButton({ Icon = "x", Text = "Auto too", Width = "Auto" })
AutoRow:AddDropdown("Show_AutoRowDD", { Values = { "Takes the rest", "Of the row" }, Default = 1 })

local MixedRow = PresetSection:AddRow()
MixedRow:AddInput("Show_RowInput", { Placeholder = "Input fills", Width = "Fill" })
MixedRow:AddIconButton({ Icon = "search", Tooltip = "Search" })

local StepRow = PresetSection:AddRow()
StepRow:AddStepper("Show_RowStep", { Text = "Stepper in a row", Min = 0, Max = 20, Default = 5 })

local IconButtonSection = RowsTab:AddSection({ Side = 2, Name = "IconButton", Icon = "mouse-pointer-2" })
local Showcased = IconButtonSection:AddIconButton("Show_IconButton", { Icon = "settings", Text = "Icon + text", Tooltip = "Hover me", Func = function() Library:Notify("IconButton clicked") end })
IconButtonSection:AddIconButton({ Icon = "plus", DisabledTooltip = "Disabled", Disabled = true })
IconButtonSection:AddButton({ Text = "IconButton:SetText('Renamed')", Func = function() Showcased:SetText("Renamed") end })
IconButtonSection:AddButton({ Text = "IconButton:SetIcon('x')", Func = function() Showcased:SetIcon("x") end })
IconButtonSection:AddButton({ Text = "IconButton:SetDisabled(true / false)", Func = function() Showcased:SetDisabled(not Showcased.Disabled) end })
IconButtonSection:AddButton({ Text = "IconButton:SetVisible(false) for 1s", Func = function()
    Showcased:SetVisible(false)
    task.delay(1, function() Showcased:SetVisible(true) end)
end })

local RowMethodsSection = RowsTab:AddSection({ Side = 2, Name = "Row methods", Icon = "git-branch" })
RowMethodsSection:AddButton({ Text = "Row:SetItemWidth(dropdown, 200)", Func = function() PresetRow:SetItemWidth(PresetDropdown, 200) end })
RowMethodsSection:AddButton({ Text = "Row:SetItemWidth(dropdown, 'Fill')", Func = function() PresetRow:SetItemWidth(PresetDropdown, "Fill") end })
RowMethodsSection:AddButton({ Text = "Row:SetVisible(false) for 1s", Func = function()
    WidthRow:SetVisible(false)
    task.delay(1, function() WidthRow:SetVisible(true) end)
end })
RowMethodsSection:AddLabel({ Text = "Rows accept AddDropdown, AddIconButton, AddButton, AddInput, AddLabel, AddStepper, AddToggle, AddCheckbox and AddSlider.", DoesWrap = true })

-- ---------------------------------------------------------------------------
-- Icons and subtext on every element
-- ---------------------------------------------------------------------------
local RichSection = RichTab:AddSection({
    Side = 1,
    Name = "Icons and subtext",
    Subtext = "Icon, Subtext, IconStyle, IconColor, IconBackground",
    Icon = "info",
    IconStyle = "Tile",
})

-- A Lucide icon name, an asset id / picture, or an icon table all work as Icon.
RichSection:AddToggle("Show_RichTile", { Text = "Advanced Lanes", Subtext = "% of the path, per lane", Icon = "git-branch", IconStyle = "Tile" })
RichSection:AddToggle("Show_RichInline", { Text = "Inline icon", Subtext = "Small icon, default style", Icon = "key" })
RichSection:AddToggle("Show_RichColor", { Text = "Colored icon", Icon = "settings", IconColor = Color3.fromRGB(255, 120, 120) })
RichSection:AddToggle("Show_RichBare", { Text = "Tile without a background", Icon = "settings", IconStyle = "Tile", IconBackground = false })
RichSection:AddCheckbox("Show_RichCheck", { Text = "Checkbox with subtext", Subtext = "Subtext wraps onto more lines when it is long enough to need them.", Icon = "check" })
local RichLabel = RichSection:AddLabel({ Text = "Label", Subtext = "A label with an icon tile and subtext", Icon = "message-square", IconStyle = "Tile" })
RichSection:AddInput("Show_RichInput", { Text = "Input", Subtext = "Subtext sits tight under the title", Icon = "type", Placeholder = "Type here..." })
RichSection:AddSlider("Show_RichSlider", { Text = "Slider", Subtext = "Also supports icons", Icon = "sliders-horizontal", Min = 0, Max = 100, Default = 40, Rounding = 0 })
RichSection:AddStepper("Show_RichStepper", { Text = "Stepper", Subtext = "With +/- buttons", Icon = "layers", Min = 0, Max = 10, Default = 3 })
RichSection:AddDropdown("Show_RichDropdown", { Text = "Dropdown", Subtext = "Subtext does not leave a gap below the box", Icon = "list", Values = { "One", "Two", "Three" }, Default = 1 })
RichSection:AddButton({ Text = "Label:SetSubtext / SetIcon", Func = function()
    RichLabel:SetSubtext("Changed at " .. os.date("%H:%M:%S"))
    RichLabel:SetIcon("key")
end })

local SectionOptions = RichTab:AddSection({ Side = 2, Name = "Section options", Subtext = "MaxHeight scrolls, PopOut docks", Icon = "columns-2", IconStyle = "Tile", MaxHeight = 150 })
for Index = 1, 8 do
    SectionOptions:AddLabel("Scrolling row " .. Index)
end

local MethodSection = RichTab:AddSection({ Side = 2, Name = "Section methods", Icon = "settings" })
MethodSection:AddButton({ Text = "Section:SetPoppedOut(true)", Func = function() SectionOptions:SetPoppedOut(true) end })
MethodSection:AddButton({ Text = "Section:SetPoppedOut(false)", Func = function() SectionOptions:SetPoppedOut(false) end })
MethodSection:AddButton({ Text = "Section:TogglePoppedOut()", Func = function() SectionOptions:TogglePoppedOut() end })
MethodSection:AddButton({ Text = "Section:SetPopOutWidth(320)", Func = function() SectionOptions:SetPopOutWidth(320) end })
MethodSection:AddButton({ Text = "Section:SetMaxPopOutHeight(160)", Func = function() SectionOptions:SetMaxPopOutHeight(160) end })
MethodSection:AddButton({ Text = "Section:SetMaxHeight(80)", Func = function() SectionOptions:SetMaxHeight(80) end })
MethodSection:AddButton({ Text = "Section:SetMaxHeight(nil)", Func = function() SectionOptions:SetMaxHeight(nil) end })
MethodSection:AddLabel({ Text = "Set PopOut = false on a section (or PopOutBoxes = false on the window) to remove the pop-out button.", DoesWrap = true })

local NoPopSection = RichTab:AddSection({ Side = 1, Name = "PopOut = false", PopOut = false, Icon = "x" })
NoPopSection:AddLabel("This section has no pop-out button.")

-- ---------------------------------------------------------------------------
-- Data: stepper, table, priority list
-- ---------------------------------------------------------------------------
local StepperSection = DataTab:AddSection({ Side = 1, Name = "Stepper", Icon = "layers" })
local AmountStepper = StepperSection:AddStepper("Show_Amount", {
    Text = "Amount", Icon = "layers", Default = 1, Min = 1, Max = 10, Increment = 1,
    Callback = function(Value) print("Amount:", Value) end,
})
local UpgradeStepper = StepperSection:AddStepper("Show_Upgrade", {
    Text = "Upgrade to", Icon = "chevrons-up", Default = 3, Min = 0, Max = 5,
    ValueTexts = { [5] = "Max", [0] = "Default" }, -- text for specific values
})
StepperSection:AddStepper("Show_Percent", { Text = "Percent", Default = 50, Min = 0, Max = 100, Increment = 5, Suffix = "%", Holdable = true })
StepperSection:AddStepper("Show_Decimal", { Text = "Decimals", Default = 1, Min = 0, Max = 2, Increment = 0.25, Rounding = 2, Prefix = "x" })
StepperSection:AddStepper("Show_Format", {
    Text = "Custom format", Default = 90, Min = 0, Max = 360, Increment = 15,
    Format = function(Value) return Value .. " deg" end, ValueWidth = 70,
})
StepperSection:AddButton({ Text = "Stepper:Increase() / Decrease()", Func = function()
    AmountStepper:Increase()
    UpgradeStepper:Decrease()
end })
StepperSection:AddButton({ Text = "Stepper:SetValue(7)  :Reset()", Func = function()
    AmountStepper:SetValue(7)
    task.delay(1, function() AmountStepper:Reset() end)
end })
StepperSection:AddButton({ Text = "Stepper:SetMax(5)  :SetIncrement(2)", Func = function()
    AmountStepper:SetMax(5)
    AmountStepper:SetIncrement(2)
end })
StepperSection:AddButton({ Text = "Stepper:SetDisabled(true / false)", Func = function() AmountStepper:SetDisabled(not AmountStepper.Disabled) end })

local TableSection = DataTab:AddSection({ Side = 2, Name = "Table", Icon = "columns-2" })
local StatsTable = TableSection:AddTable("Show_Stats", {
    Text = "Session stats",
    Subtext = "Click a row to select it",
    Columns = {
        { Name = "Name", Width = "Auto" },                          -- fits its content
        { Name = "Value", Align = "Right", Width = 60 },            -- fixed pixels
        { Name = "Note", Weight = 2 },                              -- takes the rest
    },
    Rows = {
        { "Kills", 12, "this session" },
        { "Deaths", 3, { Text = "ouch", Color = Color3.fromRGB(255, 110, 110) } },
        { "Assists", 7, { Text = "teamwork", Icon = "user" } },
    },
    Selectable = true,
    MaxHeight = 110,
    Callback = function(Index, Row) print("selected row", Index, Row and Row[1]) end,
})
local CenteredTable = TableSection:AddTable("Show_Centered", {
    Text = "Centered data",
    Columns = { "Item", "Qty", "Price" },
    Rows = { { "Sword", 1, "$10" }, { "Shield", 2, "$25" } },
    Align = "Center",           -- every column centered (also per column: Align = "Right")
    HeaderAlign = "Center",
    Striped = true,
})
TableSection:AddTable("Show_Keyed", {
    Columns = { { Name = "Player", Key = "name" }, { Name = "Score", Key = "score", Align = "Right" } },
    Rows = { { name = "Alice", score = 120 }, { name = "Bob", score = 95 } },
    Header = true, Striped = false, EmptyText = "Nobody here",
})
TableSection:AddButton({ Text = "Table:AddRow / RemoveRow", Func = function()
    StatsTable:AddRow({ "Extra " .. #StatsTable:GetRows() + 1, math.random(1, 50), "added" })
    if #StatsTable:GetRows() > 6 then StatsTable:RemoveRow(1) end
end })
TableSection:AddButton({ Text = "Table:Sort(2, descending)", Func = function() StatsTable:Sort(2, true) end })
TableSection:AddButton({ Text = "Table:UpdateCell(1, 2, 99)", Func = function() StatsTable:UpdateCell(1, 2, 99) end })
TableSection:AddButton({ Text = "Table:SetSelected(2)", Func = function() StatsTable:SetSelected(2) end })
TableSection:AddButton({ Text = "Table:SetAlign('Center')", Func = function() StatsTable:SetAlign("Center") end })
TableSection:AddButton({ Text = "Table:SetRows / Clear", Func = function()
    StatsTable:Clear()
    task.delay(1, function() StatsTable:SetRows({ { "A", 1, "x" }, { "B", 2, "y" } }) end)
end })
TableSection:AddButton({ Text = "Table:SetMaxHeight(60)", Func = function() StatsTable:SetMaxHeight(60) end })

local PrioritySection = DataTab:AddSection({ Side = 1, Name = "Priority list", Icon = "git-branch" })
local RunOrder = PrioritySection:AddPriorityList("Show_RunOrder", {
    Text = "Run order",
    Subtext = "Use the arrows to move an item",
    Items = {
        { Id = "daily", Name = "Daily Challenge", Value = "Off" },
        { Id = "challenge", Name = "Challenge", Value = "Off", Icon = "crosshair" },
        { Id = "raid", Name = "Raid", Value = "On" },
        { Id = "locked", Name = "Locked item", Value = "n/a", Disabled = true },
        "Portals",   -- a plain string works too
    },
    Callback = function(Order, MovedId, From, To) print("order:", table.concat(Order, ", ")) end,
})
PrioritySection:AddButton({ Text = "PriorityList:Move('raid', 1)", Func = function() RunOrder:Move("raid", 1) end })
PrioritySection:AddButton({ Text = "PriorityList:MoveUp / MoveDown", Func = function()
    RunOrder:MoveUp("challenge")
    RunOrder:MoveDown(1)
end })
PrioritySection:AddButton({ Text = "PriorityList:SetOrder({...})", Func = function() RunOrder:SetOrder({ "raid", "challenge", "daily" }) end })
PrioritySection:AddButton({ Text = "PriorityList:SetValue('daily', 'Auto')", Func = function() RunOrder:SetValue("daily", "Auto") end })
PrioritySection:AddButton({ Text = "PriorityList:SetItemDisabled('raid', true / false)", Func = function()
    local Index = RunOrder:GetIndex("raid")
    RunOrder:SetItemDisabled("raid", not (RunOrder.Items[Index] and RunOrder.Items[Index].Disabled))
end })
PrioritySection:AddButton({ Text = "PriorityList:GetOrder() -> notify", Func = function() Library:Notify(table.concat(RunOrder:GetOrder(), ", ")) end })
PrioritySection:AddButton({ Text = "PriorityList:SetItems({...})", Func = function() RunOrder:SetItems({ "One", "Two", "Three" }) end })

-- ---------------------------------------------------------------------------
-- Dropdown layouts and search
-- ---------------------------------------------------------------------------
local DropdownSection = DropdownTab:AddSection({ Side = 1, Name = "Layouts", Icon = "list" })
DropdownSection:AddDropdown("Show_DDInline", { Text = "Inline (default)", Values = { "Easy", "Normal", "Hard" }, Default = "Hard" })
DropdownSection:AddDropdown("Show_DDLeft", { Text = "Box on the left", Values = { "A", "B", "C" }, Default = 1, BoxSide = "Left" })
DropdownSection:AddDropdown("Show_DDWidth", { Text = "BoxWidth = 0.35", Values = { "A", "B", "C" }, Default = 1, BoxWidth = 0.35 })
DropdownSection:AddDropdown("Show_DDPixels", { Text = "BoxWidth = 110px", Values = { "A", "B", "C" }, Default = 1, BoxWidth = 110 })
DropdownSection:AddDropdown("Show_DDStacked", { Text = "Stacked (old look)", Values = { "A", "B", "C" }, Default = 1, Layout = "Stacked" })
DropdownSection:AddDropdown("Show_DDSub", { Text = "With subtext", Subtext = "The box stays attached to its list", Icon = "list", Values = { "A", "B", "C" }, Default = 1 })
DropdownSection:AddDropdown("Show_DDGear", { Text = "With settings", Values = { "A", "B" }, Default = 1 }):AddSettings():AddToggle("Show_DDGearToggle", { Text = "Setting inside the gear" })

local MultiSection = DropdownTab:AddSection({ Side = 2, Name = "Multi and search", Icon = "search" })
local TargetDropdown = MultiSection:AddDropdown("Show_DDMulti", {
    Text = "Targets", Values = { "Head", "Torso", "Arms", "Legs", "Feet" }, Multi = true, Default = { "Head" },
    -- Multi: the open list gets a top row with a count and  All | Clear
})
MultiSection:AddDropdown("Show_DDSearch", {
    Text = "Searchable", Values = { "Apple", "Banana", "Cherry", "Grape", "Mango", "Orange" }, Searchable = true, Default = "Apple",
    -- opening never focuses the search field; click it to type
})
MultiSection:AddDropdown("Show_DDBoth", {
    Text = "Multi + search", Values = { "Red", "Green", "Blue", "Yellow", "Purple" }, Multi = true, Searchable = true, Default = { "Red", "Blue" },
})
MultiSection:AddButton({ Text = "Dropdown:SetValue({ Head = true, Legs = true })", Func = function() TargetDropdown:SetValue({ Head = true, Legs = true }) end })
MultiSection:AddButton({ Text = "Dropdown:SetValues({...})", Func = function() TargetDropdown:SetValues({ "Head", "Neck", "Chest" }) end })

local RowDropdownSection = DropdownTab:AddSection({ Side = 2, Name = "Dropdown in a row", Icon = "layout-dashboard" })
local LabeledRow = RowDropdownSection:AddRow()
LabeledRow:AddDropdown("Show_RowLabeled", { Text = "Inline in a row", Values = { "A", "B" }, Default = 1 })
LabeledRow:AddIconButton({ Icon = "settings" })

-- ---------------------------------------------------------------------------
-- Tab groups, window API, overlays, notifications
-- ---------------------------------------------------------------------------
local GroupBoxA = WindowTab:AddSectionGroup({ Side = 1 })           -- plain outline (default)
local GroupBoxAPage1 = GroupBoxA:AddTab("Plain", "list")
GroupBoxAPage1:AddLabel("Segmented tab bar with an accent pill.")
GroupBoxA:AddTab("Second", "settings"):AddLabel("Second page")

local GroupBoxB = WindowTab:AddSectionGroup({ Side = 1, AccentBorder = true, MaxHeight = 90 })   -- accent border + scrolling pages
local GroupBoxBPage = GroupBoxB:AddTab("Accent", "key")
for Index = 1, 6 do
    GroupBoxBPage:AddLabel("Page row " .. Index)
end
GroupBoxB:AddTab("Other", "settings"):AddLabel("Other page")
GroupBoxB:SetMaxHeight(110)

local WindowApi = WindowTab:AddSection({ Side = 2, Name = "Window API", Subtext = "Title, subtitle, footer, transparency", Icon = "settings", IconStyle = "Tile" })
local Alignments = { "Left", "Center", "Right" }
local AlignmentIndex = 2
WindowApi:AddButton({ Text = "Window:SetTitleAlignment (cycle)", Func = function()
    AlignmentIndex = AlignmentIndex % #Alignments + 1
    Window:SetTitleAlignment(Alignments[AlignmentIndex])
end })
WindowApi:AddButton({ Text = "Window:SetSubtitleAlignment (cycle)", Func = function()
    AlignmentIndex = AlignmentIndex % #Alignments + 1
    Window:SetSubtitleAlignment(Alignments[AlignmentIndex])
end })
WindowApi:AddButton({ Text = "Window:SetSubtitle / SetSubtitleSize", Func = function()
    Window:SetSubtitle("Changed at " .. os.date("%H:%M:%S"))
    Window:SetSubtitleSize(11)
end })
WindowApi:AddButton({ Text = "Window:SetTitleColor / SetSubtitleColor", Func = function()
    Window:SetTitleColor(Color3.fromRGB(255, 200, 80))
    Window:SetSubtitleColor(Color3.fromRGB(160, 200, 255))
    task.delay(2, function()
        Window:SetTitleColor(nil)
        Window:SetSubtitleColor(nil)
    end)
end })
WindowApi:AddButton({ Text = "Window:AddFooterItem('Left' / 'Right')", Func = function()
    Window:AddFooterItem("Left", { Text = "clickable", Callback = function() Library:Notify("Footer item clicked") end })
    Window:AddFooterItem("Right", "plain text")
end })
WindowApi:AddButton({ Text = "Window:ClearFooter()", Func = function() Window:ClearFooter() end })
WindowApi:AddButton({ Text = "Window:SetFooterLeft / SetFooterRight", Func = function()
    Window:SetFooterLeft("left text")
    Window:SetFooterRight("right text")
end })
WindowApi:AddSlider("Show_WinTransparency", { Text = "Window:SetTransparency", Min = 0, Max = 85, Default = 0, Rounding = 0, Suffix = "%",
    Callback = function(Value) Window:SetTransparency(Value / 100) end })
WindowApi:AddToggle("Show_WinGradient", { Text = "Window:SetGradient", Default = true, Callback = function(Value) Window:SetGradient(Value) end })

local OverlayApi = WindowTab:AddSection({ Side = 2, Name = "Overlays and notifications", Icon = "picture-in-picture-2" })
OverlayApi:AddButton({ Text = "Library:SetWatermark + SetWatermarkVisibility", Func = function()
    Library:SetWatermark("Astral | showcase")
    Library:SetWatermarkVisibility(true)
end })
OverlayApi:AddButton({ Text = "Notify (Closable + Callback)", Func = function()
    Library:Notify({
        Title = "Closable", Description = "Click the X or wait", Time = 6, Closable = true,
        Callback = function(Reason) print("notification closed:", Reason) end,
    })
end })
OverlayApi:AddButton({ Text = "Library:UpdateNotificationPositions()", Func = function() Library:UpdateNotificationPositions() end })
OverlayApi:AddButton({ Text = "Library:CreateIcon / ApplyIcon", Func = function()
    local Icon = Library:CreateIcon("key", { Size = UDim2.fromOffset(16, 16) })
    Library:ApplyIcon(Icon, "settings")
    Icon:Destroy()
end })
OverlayApi:AddLabel({ Text = "Overlays (draggable menus, labels, notifications, context menus and popped-out sections) follow the window transparency and gradient.", DoesWrap = true })

-- A custom tab is an empty tab you fill yourself: parent your own GuiObjects to CustomTab.Container.
local CustomTab = ShowcaseSection:AddCustomTab({ Name = "Custom", Icon = "layout-dashboard", Description = "Your own GUI" })
local CustomNote = Instance.new("TextLabel")
CustomNote.BackgroundTransparency = 1
CustomNote.Size = UDim2.fromScale(1, 1)
CustomNote.Text = "AddCustomTab: parent your own GuiObjects to Tab.Container"
CustomNote.TextColor3 = Color3.new(1, 1, 1)
CustomNote.TextSize = 14
CustomNote.Parent = CustomTab.Container

--============================================================================
-- SETTINGS TAB — UI Scale, Theme Manager, Save Manager
--============================================================================

SaveManager:IgnoreThemeSettings()

-- UI Scale lives above Theme/Config on purpose: it's the setting most
-- likely to need adjusting first (e.g. on a small or high-DPI screen)
-- before the rest of the settings tab is even comfortable to read.
--
-- Astral auto-computes DPIScale from the screen/viewport size, and keeps
-- recalculating it live as the viewport changes (window resize, device
-- rotation, split screen) -- so on a small phone the whole UI scales down
-- to fit rather than getting pixel-clamped into a cramped box. Dragging
-- this slider takes over as a manual override (Library.AutoDPIScale
-- becomes false) so the choice sticks instead of being overwritten by the
-- next auto-resize; the button underneath returns to automatic sizing.
--
-- DPI 5 is the neutral/default value. Library:SetDPIScale(Value: number
-- 1-10) rescales the entire UI -- window, sidebar, dropdowns,
-- notifications, overlays, and any active loading screen -- everything
-- registered in Library.Scales.
local DisplaySection = SettingsTab:AddSection({ Name = "Display", IconName = "sliders-horizontal" })
DisplaySection:AddSlider("UIScaleSlider", {
    Text = "UI Scale",
    Default = Library:CalculateAutoDPIScale(1),
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        Library.AutoDPIScale = false
        Library:SetDPIScale(Value)
    end,
})
DisplaySection:AddButton({
    Text = "Reset to Automatic Scaling",
    Func = function()
        Library.AutoDPIScale = true
        local AutoValue = Library:CalculateAutoDPIScale()
        Library:SetDPIScale(AutoValue)
        Library.Options.UIScaleSlider:SetValue(Library:CalculateAutoDPIScale(1))
        Library:Notify({ Title = "Display", Description = "UI Scale now follows your screen size automatically.", Time = 3 })
    end,
})

-- ThemeManager: color scheme presets + custom color editing.
ThemeManager:ApplyToTab(SettingsTab)

-- SaveManager: pick or create a config (Global or Per-User). Changes are
-- saved automatically and the selected config loads on the next launch.
-- BuildConfigSection loads it and shows the window automatically once the
-- config is ready. If no config exists one is created, falling back to each
-- element's own defaults (including KeyPicker DefaultKey/DefaultMode/
-- DefaultModifiers).
SaveManager:BuildConfigSection(SettingsTab)

local WindowSection = SettingsTab:AddRightSection("Window", "app-window")
WindowSection:AddToggle("AutoHideUI", {
    Text = "Auto Hide UI",
    Tooltip = "When enabled, the UI stays hidden on startup until opened manually.",
    Default = false,
    Callback = function(Value)
        Library.AutoShow = not Value
    end,
})
-- With AutoHideUI on (AutoShow = false) and the BubbleToggle above also on,
-- reopening the script hides the main window on load but still shows the
-- floating bubble -- click the bubble or press ToggleKeybind to open it.

-- Notify is safe to queue up before the window is shown -- it's stored and
-- gets displayed once the notification holder actually renders.
Library:Notify({
    Title = "Astral UI Loaded",
    Description = "Reference example ready — explore each tab.",
    Time = 4,
    Icon = "circle-check",
    IconColor = Color3.fromRGB(120, 220, 120),
})

return {
    Window = Window,
    Library = Library,
    SaveManager = SaveManager,
    ThemeManager = ThemeManager,
}
