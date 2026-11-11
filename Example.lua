--============================================================================
-- ASTRAL UI -- FULL FEATURE REFERENCE
--============================================================================
-- Every element, every option, every method and the useful combinations.
-- Tabs: Form Controls, Choices, Display, Actions | Sections, Nested |
--       Dialogs, Overlays, Notifications, Custom | Window
--============================================================================

local AstralFolder = (typeof(script) == "Instance" and script.Parent and script.Parent:FindFirstChild("Astral") and script.Parent)
    or game:GetService("ReplicatedStorage"):FindFirstChild("Astral")

local Library, SaveManager, ThemeManager
if AstralFolder and AstralFolder:FindFirstChild("Astral") then
    Library      = require(AstralFolder:WaitForChild("Astral"))
    SaveManager  = require(AstralFolder:WaitForChild("Addons"):WaitForChild("SaveManager"))
    ThemeManager = require(AstralFolder:WaitForChild("Addons"):WaitForChild("ThemeManager"))
else
    Library      = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/Astral.lua"))()
    SaveManager  = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/SaveManager.lua"))()
    ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/ThemeManager.lua"))()
end

-- Which Astral is running? If this says GitHub, local edits to Astral.lua are NOT being used.
local AstralSource = (AstralFolder and AstralFolder:FindFirstChild("Astral")) and "local ModuleScript" or "GitHub main"
print("[Astral] loaded from:", AstralSource)

-- SetLibrary must run BEFORE CreateWindow (see "Avoiding the Flash of Default Values").
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

local Toggles, Options = Library.Toggles, Library.Options

local function Say(Title, Description, Time)
    Library:Notify({ Title = Title, Description = Description, Time = Time or 2 })
end

--============================================================================
-- WINDOW
--============================================================================
local Window = Library:CreateWindow({
    Title             = "Astral UI",
    Subtitle          = "Reference build",
    TitleAlignment    = "Center",
    Icon              = "AstralIcon",
    Footer            = "RightControl toggles the UI",
    FooterLeft        = "Astral",
    FooterRight       = "v2",
    Size              = UDim2.fromOffset(940, 620),
    Center            = true,
    Resizable         = true,
    ToggleKeybind     = Enum.KeyCode.RightControl,
    NotifySide        = "Right",
    DPIScale          = 5,
    TitleSize         = 15,
    SidebarWidth      = 210,
    EnableSidebarResize = true,
    SidebarCompacted  = false,
    TabButtonsStyle   = { Gap = 2, Indicator = true },
    Transparency      = 0,
    Gradient          = true,
    GradientRotation  = 45,
    PopOutBoxes       = true,
    Bubble            = true,
    BubbleIcon        = "menu",
    DiscordLink       = "https://discord.gg/astral",
    SingleInstance    = true,
    AutoShow          = true,
})

--============================================================================
-- TAB SECTIONS & TABS
--============================================================================
local Elements = Window:AddTabSection({ Name = "Elements", Icon = "layout-grid", Open = true })
local Layout   = Window:AddTabSection({ Name = "Layout",   Icon = "layout-dashboard", Open = true })
local Advanced = Window:AddTabSection({ Name = "Advanced", Icon = "wrench", Open = false })
local Settings = Window:AddTabSection({ Name = "Settings", Icon = "settings", Open = false })

local FormTab    = Elements:AddTab({ Name = "Form Controls", Icon = "sliders-horizontal", Description = "Toggles, checkboxes, sliders, inputs" })
local ChoiceTab  = Elements:AddTab({ Name = "Choices",       Icon = "list-checks",       Description = "Steppers and every dropdown variant" })
local DispTab    = Elements:AddTab({ Name = "Display",       Icon = "type",              Description = "Labels, progress, tables, lists, media" })
local ActTab     = Elements:AddTab({ Name = "Actions",       Icon = "mouse-pointer-2",   Description = "Buttons, rows, key pickers, color pickers" })

local SectionsTab = Layout:AddTab({ Name = "Sections", Icon = "columns-2", Description = "Section options, columns, tab groups" })
local NestedTab   = Layout:AddTab({ Name = "Nested",   Icon = "git-branch", Description = "Sub-sections and conditionals" })

local DialogTab   = Advanced:AddTab({ Name = "Dialogs",       Icon = "message-square",       Description = "Modal popups and confirmations" })
local OverlayTab  = Advanced:AddTab({ Name = "Overlays",      Icon = "picture-in-picture-2", Description = "Draggable overlays, menus, tooltips" })
local NotifyTab   = Advanced:AddTab({ Name = "Notifications", Icon = "bell",                 Description = "Toasts, steps and callbacks" })
local CustomTab   = Advanced:AddCustomTab({ Name = "Custom",  Icon = "layout-dashboard",     Description = "Your own GUI inside a tab" })
local KeyTab      = Window:AddKeyTab({ Name = "Key",        Icon = "key" })

local SettingsTab = Settings:AddTab({ Name = "Settings", Icon = "settings", Description = "UI, themes, and configs" })

--============================================================================
-- FORM CONTROLS  -  toggles / checkboxes / sliders / inputs
--============================================================================
local ToggleSec = FormTab:AddLeftSection("Toggles", "toggle-left")

local BasicToggle = ToggleSec:AddToggle("BasicToggle", {
    Text = "Basic Toggle",
    Default = false,
    Tooltip = "Callback and Changed both fire on every change",
    Callback = function(Value) Say("Toggle", Value and "ON" or "OFF", 1.5) end,
    Changed = function(Value) print("BasicToggle changed ->", Value) end,
})
BasicToggle:OnChanged(function(Value) print("BasicToggle OnChanged ->", Value) end)

-- Settings panel (gear) on a toggle
assert(BasicToggle.AddSettings, "Toggle:AddSettings is missing: you are running an outdated Astral (" .. AstralSource .. ")")
local ToggleGear = BasicToggle:AddSettings()
ToggleGear:AddSlider("BasicToggleStrength", { Text = "Strength", Default = 50, Min = 0, Max = 100 })
ToggleGear:AddToggle("BasicToggleAnnounce", { Text = "Announce changes", Default = false })

ToggleSec:AddToggle("RiskyToggle", { Text = "Risky Toggle", Default = false, Risky = true, Tooltip = "Risky = red label" })
ToggleSec:AddToggle("QuietToggle", { Text = "Default ON, FireDefault = false", Default = true, FireDefault = false })

ToggleSec:AddToggle("DisabledToggle", {
    Text = "Disabled Toggle", Default = true, Disabled = true,
    DisabledTooltip = "Enable it with the button below",
})
ToggleSec:AddButton({ Text = "Enable / disable the toggle above", Func = function()
    Toggles.DisabledToggle:SetDisabled(not Toggles.DisabledToggle.Disabled)
end })

-- Icons and subtext
local StyledToggle = ToggleSec:AddToggle("InlineIconToggle", {
    Text = "Inline icon + subtext", Subtext = "Small icon next to the title",
    Icon = "shield", Default = true,
})
ToggleSec:AddToggle("TileIconToggle", {
    Text = "Tile icon + subtext", Subtext = "Accent icon tile (IconStyle = \"Tile\")",
    Icon = "git-branch", IconStyle = "Tile", Default = false,
})
ToggleSec:AddToggle("BareTileToggle", {
    Text = "Tile without background", Subtext = "IconBackground = false",
    Icon = "sparkles", IconStyle = "Tile", IconBackground = false, IconColor = Color3.fromRGB(255, 200, 80),
})

-- Toggle methods
ToggleSec:AddDivider("Methods")
local MethodRow = ToggleSec:AddRow({ Gap = 6, Height = 21 })
MethodRow:AddButton({ Text = "SetValue", Func = function() BasicToggle:SetValue(not BasicToggle.Value) end })
MethodRow:AddButton({ Text = "SetText", Func = function() BasicToggle:SetText("Renamed " .. math.random(1, 99)) end })
MethodRow:AddButton({ Text = "RunChanged", Func = function() BasicToggle:RunChanged() end })
local MethodRow2 = ToggleSec:AddRow({ Gap = 6, Height = 21 })
MethodRow2:AddButton({ Text = "SetSubtext", Func = function() StyledToggle:SetSubtext("Updated " .. os.date("%X")) end })
MethodRow2:AddButton({ Text = "SetIcon", Func = function() StyledToggle:SetIcon(math.random() > 0.5 and "star" or "shield") end })
MethodRow2:AddButton({ Text = "SetVisible", Func = function()
    Toggles.RiskyToggle:SetVisible(false)
    task.delay(1.5, function() Toggles.RiskyToggle:SetVisible(true) end)
end })

-- Checkboxes
local CheckSec = FormTab:AddRightSection("Checkboxes", "square-check")
local BasicCheckbox = CheckSec:AddCheckbox("BasicCheckbox", { Text = "Checkbox style", Default = false })
CheckSec:AddCheckbox("RiskyCheckbox", { Text = "Risky checkbox", Default = false, Risky = true })
CheckSec:AddCheckbox("DisabledCheckbox", { Text = "Disabled checkbox", Default = true, Disabled = true, DisabledTooltip = "Disabled" })
CheckSec:AddCheckbox("IconCheckbox", { Text = "Checkbox with icon", Subtext = "And a subtext line", Icon = "bell", Default = true })
CheckSec:AddCheckbox("TileCheckbox", { Text = "Tile checkbox", Icon = "palette", IconStyle = "Tile" })
BasicCheckbox:AddSettings():AddToggle("CheckboxGearToggle", { Text = "Setting inside gear", Default = true })

CheckSec:AddToggle("ForceCheckboxGlobal", {
    Text = "Force ALL toggles to render as checkboxes",
    Default = false,
    Callback = function(Value) Library:SetForceCheckbox(Value) end,
})

-- Sliders
local SliderSec = FormTab:AddLeftSection("Sliders", "sliders-horizontal")
local SpeedSlider = SliderSec:AddSlider("SpeedSlider", {
    Text = "Speed", Default = 16, Min = 0, Max = 100, Rounding = 0, Suffix = " studs/s",
    Callback = function(Value) print("Speed", Value) end,
})
SliderSec:AddSlider("PrefixSlider",    { Text = "Prefix + suffix", Default = 25, Min = 0, Max = 100, Prefix = "~", Suffix = "%" })
SliderSec:AddSlider("PencilSlider",    { Text = "Pencil style",   Default = 50, Min = 0, Max = 100, Editable = true, EditableStyle = "Pencil" })
SliderSec:AddSlider("ValueBoxSlider",  { Text = "ValueBox style", Default = 25, Min = 0, Max = 100, Editable = true, EditableStyle = "ValueBox" })
SliderSec:AddSlider("ReadOnlySlider",  { Text = "Not editable",   Default = 40, Min = 0, Max = 100, Editable = false, AllowRightClickInput = false })
SliderSec:AddSlider("CompactSlider",   { Text = "Compact",        Default = 40, Min = 0, Max = 100, Compact = true, HideMax = true })
SliderSec:AddSlider("DecimalSlider",   { Text = "2-decimal",      Default = 0.5, Min = 0, Max = 1, Rounding = 2 })
SliderSec:AddSlider("NegativeSlider",  { Text = "Negative range", Default = 0, Min = -50, Max = 50 })
SliderSec:AddSlider("CustomFormatSlider", {
    Text = "Custom format", Default = 50, Min = 0, Max = 100,
    FormatDisplayValue = function(Slider, Value) return string.format("Lv %d/%d", Value, Slider.Max) end,
})
SliderSec:AddSlider("IconSlider", {
    Text = "Icon + subtext", Subtext = "Inline icon on a slider", Icon = "gauge",
    Default = 70, Min = 0, Max = 100,
})
SliderSec:AddSlider("DisabledSlider", { Text = "Disabled", Default = 30, Min = 0, Max = 100, Disabled = true, DisabledTooltip = "Disabled" })

-- Settings gear on sliders (both value styles)
SliderSec:AddSlider("GearSlider", { Text = "With settings", Default = 50, Min = 0, Max = 100 })
    :AddSettings():AddToggle("GearSliderToggle", { Text = "Setting inside gear", Default = false })
SliderSec:AddSlider("GearValueBoxSlider", { Text = "Settings + ValueBox", Default = 50, Min = 0, Max = 100, Editable = true, EditableStyle = "ValueBox" })
    :AddSettings():AddSlider("GearInnerSlider", { Text = "Inner slider", Default = 10, Min = 0, Max = 20 })

SliderSec:AddDivider("Methods")
local SliderRow = SliderSec:AddRow({ Gap = 6, Height = 21 })
SliderRow:AddButton({ Text = "SetValue 80", Func = function() SpeedSlider:SetValue(80) end })
SliderRow:AddButton({ Text = "SetMax 200", Func = function() SpeedSlider:SetMax(200) end })
SliderRow:AddButton({ Text = "SetMin 10", Func = function() SpeedSlider:SetMin(10) end })
local SliderRow2 = SliderSec:AddRow({ Gap = 6, Height = 21 })
SliderRow2:AddButton({ Text = "SetText", Func = function() SpeedSlider:SetText("Renamed") end })
SliderRow2:AddButton({ Text = "SetPrefix", Func = function() SpeedSlider:SetPrefix(">") end })
SliderRow2:AddButton({ Text = "SetSuffix", Func = function() SpeedSlider:SetSuffix(" u") end })

-- Inputs
local InputSec = FormTab:AddRightSection("Inputs", "text-cursor-input")
local NameInput = InputSec:AddInput("NameInput", {
    Text = "Your Name", Placeholder = "Type here...",
    Callback = function(Value) print("Name ->", Value) end,
})
InputSec:AddInput("FinishedInput", { Text = "Fires on Enter (Finished)", Finished = true, Placeholder = "Press enter" })
InputSec:AddInput("NumericInput",    { Text = "Numeric", Numeric = true, Finished = true, Placeholder = "123" })
InputSec:AddInput("KeepTextInput",   { Text = "Keeps text on focus", ClearTextOnFocus = false, Default = "Edit me" })
InputSec:AddInput("BlurClearInput",  { Text = "Clears on blur", ClearTextOnBlur = true, Placeholder = "Disappears" })
InputSec:AddInput("EmptyResetInput", { Text = "Falls back when empty", Default = "DefaultValue", AllowEmpty = false, EmptyReset = "---" })
InputSec:AddInput("IconInput", { Text = "Icon + subtext", Subtext = "Inline icon on an input", Icon = "search", Placeholder = "Search..." })
InputSec:AddInput("DisabledInput", { Text = "Disabled", Default = "Locked", Disabled = true, DisabledTooltip = "Disabled" })
InputSec:AddInput("VerifiedInput", {
    Text = "Username (3-20 letters/digits)", Placeholder = "VerifyValue must return true",
    VerifyValue = function(Text) return #Text >= 3 and #Text <= 20 and Text:match("^%w+$") ~= nil end,
})
InputSec:AddInput("EvenInput", {
    Text = "Even numbers only", Numeric = true,
    VerifyValue = function(Value) local N = tonumber(Value); return N ~= nil and N % 2 == 0 end,
})
InputSec:AddInput("GearInput", { Text = "With settings", Placeholder = "Gear next to the box" })
    :AddSettings():AddToggle("InputGearToggle", { Text = "Setting inside gear", Default = false })

InputSec:AddDivider("Methods")
local InputRow = InputSec:AddRow({ Gap = 6, Height = 21 })
InputRow:AddButton({ Text = "SetValue", Func = function() NameInput:SetValue("Astral") end })
InputRow:AddButton({ Text = "SetText (label)", Func = function() NameInput:SetText("Renamed label") end })

--============================================================================
-- CHOICES  -  steppers and dropdowns
--============================================================================
local StepSec = ChoiceTab:AddLeftSection("Steppers", "plus")
local BasicStepper = StepSec:AddStepper("BasicStepper", {
    Text = "Amount", Default = 3, Min = 1, Max = 10, Increment = 1,
    Callback = function(Value) print("Amount ->", Value) end,
})
BasicStepper:OnChanged(function(Value) print("Stepper OnChanged ->", Value) end)

StepSec:AddStepper("StepIconStepper", {
    Text = "Icon + subtext", Subtext = "Inline icon on a stepper", Icon = "layers",
    Default = 2, Min = 0, Max = 5,
})
StepSec:AddStepper("PrefixStepper", { Text = "Prefix + suffix", Default = 50, Min = 0, Max = 100, Increment = 5, Prefix = "$", Suffix = "k" })
StepSec:AddStepper("DecimalStepper", { Text = "Decimal step", Default = 0.5, Min = 0, Max = 2, Increment = 0.25, Rounding = 2 })
StepSec:AddStepper("ValueTextStepper", {
    Text = "Value texts", Default = 1, Min = 0, Max = 10,
    ValueTexts = { [0] = "Off", [10] = "Max" },
})
StepSec:AddStepper("FormatStepper", {
    Text = "Custom format", Default = 90, Min = 0, Max = 360, Increment = 15,
    Format = function(Value) return Value .. "°" end, ValueWidth = 56,
})
StepSec:AddStepper("SlowStepper", { Text = "Not holdable", Default = 5, Min = 0, Max = 100, Holdable = false })
StepSec:AddStepper("HoldStepper", { Text = "Holdable (default)", Default = 50, Min = 0, Max = 1000, Increment = 1, Holdable = true })
StepSec:AddStepper("DisabledStepper", { Text = "Disabled", Default = 4, Min = 0, Max = 8, Disabled = true, DisabledTooltip = "Disabled" })
StepSec:AddStepper("GearStepper", { Text = "With settings", Default = 2, Min = 0, Max = 9 })
    :AddSettings():AddToggle("StepperGearToggle", { Text = "Setting inside gear", Default = true })

StepSec:AddDivider("Methods")
local StepRow = StepSec:AddRow({ Gap = 6, Height = 21 })
StepRow:AddButton({ Text = "Increase", Func = function() BasicStepper:Increase() end })
StepRow:AddButton({ Text = "Decrease", Func = function() BasicStepper:Decrease() end })
StepRow:AddButton({ Text = "Reset", Func = function() BasicStepper:Reset() end })
local StepRow2 = StepSec:AddRow({ Gap = 6, Height = 21 })
StepRow2:AddButton({ Text = "SetValue 7", Func = function() BasicStepper:SetValue(7) end })
StepRow2:AddButton({ Text = "SetMax 20", Func = function() BasicStepper:SetMax(20) end })
StepRow2:AddButton({ Text = "SetIncrement 2", Func = function() BasicStepper:SetIncrement(2) end })

-- Dropdowns: single select, layouts and options
local DropSec = ChoiceTab:AddRightSection("Dropdowns", "chevrons-up-down")
local ModeDrop = DropSec:AddDropdown("ModeDropdown", {
    Text = "Select Mode", Values = { "Option A", "Option B", "Option C" }, Default = "Option A",
})
ModeDrop:OnChanged(function(Value) print("ModeDropdown ->", Value) end)

DropSec:AddDropdown("StackedDropdown", {
    Text = "Layout = Stacked", Values = { "Easy", "Normal", "Hard" }, Default = "Normal", Layout = "Stacked",
})
DropSec:AddDropdown("BoxLeftDropdown", {
    Text = "BoxSide = Left", Values = { "Easy", "Normal", "Hard" }, Default = "Easy", BoxSide = "Left",
})
DropSec:AddDropdown("WideBoxDropdown", {
    Text = "BoxWidth = 0.7", Values = { "Short", "Medium", "Long" }, Default = "Short", BoxWidth = 0.7,
})
DropSec:AddDropdown("PixelBoxDropdown", {
    Text = "BoxWidth = 120px", Values = { "Short", "Medium", "Long" }, Default = "Medium", BoxWidth = 120,
})
DropSec:AddDropdown("IconDropdown", {
    Text = "Icon + subtext", Subtext = "Inline icon on a dropdown", Icon = "swords",
    Values = { "Sword", "Shield", "Bow" }, Default = "Sword",
    ValueImages = { Sword = "swords", Shield = "shield", Bow = "target" },
})
DropSec:AddDropdown("NullableDropdown", {
    Text = "AllowNull + disabled values", Values = { "Enabled", "Disabled Choice", "Also Enabled" },
    Default = nil, AllowNull = true, DisabledValues = { "Disabled Choice" },
})
DropSec:AddDropdown("KeepOrderDropdown", {
    Text = "KeepDisabledValuePosition", Values = { "One", "Two (disabled)", "Three" }, Default = "One",
    DisabledValues = { "Two (disabled)" }, KeepDisabledValuePosition = true,
})
DropSec:AddDropdown("SearchableSingle", {
    Text = "Searchable", Values = { "Apple", "Banana", "Cherry", "Grape", "Mango", "Orange", "Peach", "Pear", "Plum" },
    Default = "Apple", Searchable = true, MaxVisibleDropdownItems = 5,
})
DropSec:AddDropdown("FormattedDropdown", {
    Text = "Formatted", Values = { "low", "mid", "high" }, Default = "mid",
    FormatDisplayValue = function(Value) return "Quality: " .. Value:upper() end,
    FormatListValue = function(Value) return "• " .. Value end,
})
DropSec:AddDropdown("DisabledDropdown", { Text = "Disabled", Values = { "A", "B" }, Default = "A", Disabled = true, DisabledTooltip = "Disabled" })
DropSec:AddDropdown("DropGearDemo", { Text = "With settings", Values = { "A", "B", "C" }, Default = "A" })
    :AddSettings():AddToggle("DropGearToggle", { Text = "Setting inside gear", Default = true })

-- Multi-select: opening the list shows the "All | Clear" row (and the search field when Searchable)
local MultiSec = ChoiceTab:AddLeftSection("Multi-select", "list-checks")
local RoleValues = { "Admin", "Moderator", "Editor", "Viewer", "Contributor", "Reviewer", "Support", "Analyst" }
local RolesDrop = MultiSec:AddDropdown("RolesDropdown", {
    Text = "Roles (All | Clear + search)", Values = RoleValues,
    Default = { "Admin", "Analyst" }, Multi = true, Searchable = true, MaxVisibleDropdownItems = 6,
})
MultiSec:AddDropdown("MultiPlain", {
    Text = "Multi (All | Clear only)", Values = { "Red", "Green", "Blue", "Yellow" },
    Default = { "Red" }, Multi = true,
})
MultiSec:AddDropdown("MultiDrag", {
    Text = "Multi + DragSelect", Values = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
    Default = { "Mon", "Tue" }, Multi = true, DragSelect = true,
})
MultiSec:AddDropdown("MultiStacked", {
    Text = "Multi, stacked + icon", Icon = "tag", Layout = "Stacked",
    Values = { "Alpha", "Beta", "Gamma", "Delta" }, Default = { "Beta" }, Multi = true,
})
MultiSec:AddDropdown("MultiGear", {
    Text = "Multi with settings", Values = { "One", "Two", "Three" }, Default = { "One" }, Multi = true,
}):AddSettings():AddToggle("MultiGearToggle", { Text = "Setting inside gear", Default = false })

MultiSec:AddDivider("Methods")
local MultiRow = MultiSec:AddRow({ Gap = 6, Height = 21 })
MultiRow:AddButton({ Text = "Get active", Func = function()
    local Names = {}
    for Key in pairs(RolesDrop:GetActiveValues()) do table.insert(Names, Key) end
    Say("Roles", #Names > 0 and table.concat(Names, ", ") or "(none)", 2.5)
end })
MultiRow:AddButton({ Text = "Count", Func = function() Say("Roles", tostring(RolesDrop:GetActiveValues(true)) .. " selected") end })
MultiRow:AddButton({ Text = "Clear", Func = function() RolesDrop:ClearSelectedValues() end })
local MultiRow2 = MultiSec:AddRow({ Gap = 6, Height = 21 })
MultiRow2:AddButton({ Text = "Select Editor", Func = function() RolesDrop:SetSelectedValue("Editor") end })
MultiRow2:AddButton({ Text = "Deselect Admin", Func = function() RolesDrop:DeselectValue("Admin") end })
local MultiRow3 = MultiSec:AddRow({ Gap = 6, Height = 21 })
MultiRow3:AddButton({ Text = "SetValues", Func = function() RolesDrop:SetValues({ "Admin", "Owner", "Guest" }) end })
MultiRow3:AddButton({ Text = "AddValues", Func = function() RolesDrop:AddValues({ "Intern" }) end })
MultiRow3:AddButton({ Text = "Restore", Func = function() RolesDrop:SetValues(RoleValues) end })
local MultiRow4 = MultiSec:AddRow({ Gap = 6, Height = 21 })
MultiRow4:AddButton({ Text = "Disable Viewer", Func = function() RolesDrop:SetDisabledValues({ "Viewer" }) end })
MultiRow4:AddButton({ Text = "Enable all", Func = function() RolesDrop:SetDisabledValues({}) end })
MultiRow4:AddButton({ Text = "SetText", Func = function() RolesDrop:SetText("Renamed roles") end })

-- Special types
local SpecialSec = ChoiceTab:AddRightSection("Players and teams", "users")
SpecialSec:AddDropdown("PlayerDropdown", {
    Text = "Player", SpecialType = "Player", ExcludeLocalPlayer = false, EnablePlayerImages = true, Searchable = true,
})
SpecialSec:AddDropdown("OtherPlayersDropdown", {
    Text = "Other players (multi)", SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true,
})
SpecialSec:AddDropdown("TeamDropdown", { Text = "Team", SpecialType = "Team" })

--============================================================================
-- DISPLAY  -  dividers, labels, progress, table, priority list, media
--============================================================================
local DivSec = DispTab:AddLeftSection("Dividers", "separator-horizontal")
DivSec:AddLabel("Above the divider")
DivSec:AddDivider("Labelled")
DivSec:AddDivider()
DivSec:AddDivider({ Text = "Custom margins", MarginTop = 8, MarginBottom = 8 })
DivSec:AddLabel("Below the dividers")

local LabelSec = DispTab:AddRightSection("Labels", "tag")
local CounterLabel = LabelSec:AddLabel('Counter: <font color="rgb(66,135,245)">0</font>')
LabelSec:AddLabel({
    Text = "<b>Bold</b> · <i>Italic</i> · <u>Underline</u> · <font color=\"rgb(120,220,120)\">Colored</font>",
    DoesWrap = true, Size = 13,
})
LabelSec:AddLabel({
    Text = "A long wrapping label: it wraps onto several lines when the section is narrow, and keeps its natural height.",
    DoesWrap = true,
})
local IconLabel = LabelSec:AddLabel({ Text = "Icon + subtext", Subtext = "Inline icon on a label", Icon = "info" })
LabelSec:AddLabel({ Text = "Tile label", Subtext = "IconStyle = \"Tile\"", Icon = "sparkles", IconStyle = "Tile" })
local GearLabel = LabelSec:AddLabel("Label with settings")
GearLabel:AddSettings():AddToggle("LabelGearToggle", { Text = "Setting inside gear", Default = false })

local Count = 0
local LabelRow = LabelSec:AddRow({ Gap = 6, Height = 21 })
LabelRow:AddButton({ Text = "Increment", Func = function()
    Count += 1
    CounterLabel:SetText(string.format('Counter: <font color="rgb(66,135,245)">%d</font>', Count))
end })
LabelRow:AddButton({ Text = "SetSubtext", Func = function() IconLabel:SetSubtext("Updated " .. os.date("%X")) end })
LabelRow:AddButton({ Text = "SetIcon", Func = function() IconLabel:SetIcon(math.random() > 0.5 and "star" or "info") end })

-- Progress bars
local ProgSec = DispTab:AddLeftSection("Progress", "loader")
local HealthBar = ProgSec:AddProgressBar("HealthBar", { Text = "Health", Value = 100, Min = 0, Max = 100, Suffix = " HP" })
ProgSec:AddProgressBar("CompactBar", { Text = "Compact", Value = 60, Min = 0, Max = 100, Compact = true, HideMax = true })
ProgSec:AddProgressBar("PrefixBar", { Text = "Prefix + decimals", Value = 0.42, Min = 0, Max = 1, Rounding = 2, Prefix = "~" })
ProgSec:AddProgressBar("DisabledBar", { Text = "Disabled", Value = 30, Min = 0, Max = 100, Disabled = true })
local ProgRow = ProgSec:AddRow({ Gap = 6, Height = 21 })
ProgRow:AddButton({ Text = "Damage", Func = function() HealthBar:SetValue(math.max(0, HealthBar.Value - 25)) end })
ProgRow:AddButton({ Text = "Heal", Func = function() HealthBar:SetValue(100) end })
ProgRow:AddButton({ Text = "SetText", Func = function() HealthBar:SetText("Shield") end })

-- Table
local TableSec = DispTab:AddRightSection("Table", "table")
local Stats = TableSec:AddTable("Stats", {
    Text = "Session stats", Subtext = "Click a row to select it",
    Columns = { "Name", { Name = "Value", Align = "Right", Width = 70 }, { Name = "Tag", Width = "Auto" } },
    Rows = {
        { "Kills", 12, "pvp" },
        { "Deaths", 3, { Text = "bad", Color = Color3.fromRGB(255, 90, 90), Icon = "x" } },
        { "Assists", 7, "team" },
        { "Coins", 1450, { Text = "rich", Color = Color3.fromRGB(255, 200, 80), Icon = "coins" } },
    },
    Header = true, Striped = true, RowHeight = 22, MaxHeight = 120,
    Selectable = true, EmptyText = "No data",
    Callback = function(Index, Row) Say("Table", "Selected row " .. tostring(Index), 1.5) end,
})
local TableRow = TableSec:AddRow({ Gap = 6, Height = 21 })
TableRow:AddButton({ Text = "AddRow", Func = function() Stats:AddRow({ "New", math.random(1, 99), "tmp" }) end })
TableRow:AddButton({ Text = "RemoveRow", Func = function() Stats:RemoveRow(#Stats:GetRows()) end })
TableRow:AddButton({ Text = "Clear", Func = function() Stats:Clear() end })
local TableRow2 = TableSec:AddRow({ Gap = 6, Height = 21 })
TableRow2:AddButton({ Text = "Sort Value", Func = function() Stats:Sort(2, true) end })
TableRow2:AddButton({ Text = "UpdateCell", Func = function() Stats:UpdateCell(1, 2, math.random(1, 99)) end })
TableRow2:AddButton({ Text = "Center", Func = function() Stats:SetAlign("Center") end })

TableSec:AddTable("EmptyTable", { Text = "Empty table", Columns = { "A", "B" }, Rows = {}, EmptyText = "Nothing to show yet", Header = true })

-- Priority list
local ListSec = DispTab:AddLeftSection("Priority list", "arrow-up-down")
local Order = ListSec:AddPriorityList("RunOrder", {
    Text = "Run order", Subtext = "Use the arrows to reorder",
    Items = {
        { Id = "daily", Name = "Daily Challenge", Value = "Off" },
        { Id = "raid", Name = "Raid", Value = "On", Icon = "swords" },
        { Id = "event", Name = "Event", Value = "Off", Disabled = true },
        "Challenge",
    },
    ShowIndex = true, ShowValue = true, RowHeight = 34,
    Callback = function(NewOrder, MovedId, From, To) print("Order:", table.concat(NewOrder, ", "), MovedId, From, To) end,
})
local OrderRow = ListSec:AddRow({ Gap = 6, Height = 21 })
OrderRow:AddButton({ Text = "Move up", Func = function() Order:MoveUp("raid") end })
OrderRow:AddButton({ Text = "Set value", Func = function() Order:SetValue("daily", "On") end })
OrderRow:AddButton({ Text = "Reverse", Func = function()
    local Current = Order:GetOrder()
    local Reversed = {}
    for Index = #Current, 1, -1 do table.insert(Reversed, Current[Index]) end
    Order:SetOrder(Reversed)
end })

-- Image / Viewport / Video
local ImageSec = DispTab:AddRightSection("Media", "image")
local DemoImage = ImageSec:AddImage("DemoImage", { Image = "sparkles", Height = 90, ScaleType = Enum.ScaleType.Fit })
local ImageRow = ImageSec:AddRow({ Gap = 6, Height = 21 })
ImageRow:AddButton({ Text = "SetImage", Func = function()
    DemoImage:SetImage("star")
    task.delay(1.5, function() DemoImage:SetImage("sparkles") end)
end })
ImageRow:AddButton({ Text = "SetColor", Func = function() DemoImage:SetColor(Color3.fromRGB(255, 120, 120)) end })
ImageRow:AddButton({ Text = "SetHeight", Func = function() DemoImage:SetHeight(math.random(60, 120)) end })

local DemoModel = Instance.new("Model")
local DemoPart = Instance.new("Part")
DemoPart.Size = Vector3.new(3, 3, 3)
DemoPart.Anchored = true
DemoPart.Color = Color3.fromRGB(66, 135, 245)
DemoPart.Parent = DemoModel
local DemoViewport = ImageSec:AddViewport("DemoViewport", { Object = DemoModel, Height = 130, Interactive = true, AutoFocus = true })
ImageSec:AddButton({ Text = "Focus viewport", Func = function() DemoViewport:Focus() end })

local VideoSec = DispTab:AddLeftSection("Video", "video")
VideoSec:AddLabel({ Text = "Provide a real rbxassetid:// video asset to see playback.", DoesWrap = true })
local DemoVideo = VideoSec:AddVideo("DemoVideo", { Video = "rbxassetid://0", Height = 100 })
VideoSec:AddButton({ Text = "Play / Pause", Func = function()
    if DemoVideo.Playing then DemoVideo:Pause() else DemoVideo:Play() end
end })

-- Rich text: every text field renders markup (<b> <i> <u> <s> <font color/size>), including titles,
-- subtext, tooltips, dropdown values, table cells, list names, notifications, dialogs and the footer.
local RichSec = DispTab:AddRightSection('<font color="rgb(66,135,245)">Rich</font> <b>text</b> <i>everywhere</i>', "highlighter")
RichSec:AddLabel('<b>Bold</b> <i>italic</i> <u>underline</u> <s>strike</s> <font color="rgb(120,220,120)">color</font> <font size="16">size</font>')
RichSec:AddToggle("RichToggle", {
    Text = '<b>Toggle</b> with <font color="rgb(255,200,80)">color</font>',
    Subtext = '<i>Subtext</i> supports <b>markup</b> too',
    Icon = "bold", Tooltip = '<b>Tooltip</b> with <font color="rgb(120,220,120)">markup</font>',
})
RichSec:AddSlider("RichSlider", {
    Text = '<font color="rgb(255,120,120)">Health</font> slider', Default = 60, Min = 0, Max = 100,
    Suffix = ' <font color="rgb(255,200,80)">HP</font>',
})
RichSec:AddStepper("RichStepper", { Text = '<b>Stepper</b> <i>label</i>', Default = 3, Min = 0, Max = 9, Suffix = '<font color="rgb(120,220,120)">x</font>' })

local RarityColors = { Common = "170,170,170", Rare = "80,160,255", Epic = "190,110,255" }
RichSec:AddDropdown("RichDropdown", {
    Text = '<b>Rarity</b> dropdown', Values = { "Common", "Rare", "Epic" }, Default = "Rare",
    FormatDisplayValue = function(Value) return string.format('<font color="rgb(%s)">%s</font>', RarityColors[Value] or "255,255,255", Value) end,
    FormatListValue = function(Value) return string.format('<font color="rgb(%s)"><b>%s</b></font>', RarityColors[Value] or "255,255,255", Value) end,
})
RichSec:AddInput("RichInput", { Text = '<b>Input</b> <font color="rgb(120,220,120)">label</font>', Placeholder = "Typed text stays plain" })
RichSec:AddDivider('<font color="rgb(66,135,245)">Divider</font> text')
RichSec:AddTable("RichTable", {
    Text = '<b>Table</b> title', Subtext = '<i>cells and headers too</i>',
    Columns = { "<b>Item</b>", { Name = '<font color="rgb(255,200,80)">Price</font>', Align = "Right", Width = 70 } },
    Rows = {
        { '<font color="rgb(120,220,120)">Potion</font>', "<b>25</b>" },
        { "<i>Elixir</i>", '<font color="rgb(255,120,120)">80</font>' },
    },
    Header = true, Striped = true,
})
RichSec:AddPriorityList("RichList", {
    Text = '<b>Priority</b> <i>list</i>',
    Items = {
        { Id = "a", Name = '<font color="rgb(255,120,120)">Urgent</font> task', Value = "<b>On</b>" },
        { Id = "b", Name = "<i>Normal</i> task", Value = "Off" },
    },
})
RichSec:AddButton({
    Text = '<b>Notify</b> with <font color="rgb(120,220,120)">markup</font>',
    Tooltip = '<b>Rich</b> button tooltip',
    Func = function()
        Library:Notify({
            Title = '<font color="rgb(120,220,120)"><b>Rich</b></font> title',
            Description = 'Description with <i>italic</i> and <font color="rgb(255,200,80)">color</font>', Time = 4,
        })
    end,
})
RichSec:AddButton({
    Text = '<b>Dialog</b> with <font color="rgb(255,200,80)">markup</font>',
    Func = function()
        Window:AddDialog("RichDialog", {
            Title = '<font color="rgb(66,135,245)">Rich</font> <b>dialog</b>',
            Description = 'Titles and descriptions support <i>markup</i>, <u>underline</u> and <font color="rgb(255,120,120)">color</font>.',
            FooterButtons = { Confirm = { Title = "<b>Nice</b>", Variant = "Primary" } },
        })
    end,
})
RichSec:AddButton({
    Text = "Add a rich footer item",
    Func = function() Window:AddFooterItem("Right", '<font color="rgb(120,220,120)">rich</font> <b>footer</b>') end,
})

--============================================================================
-- ACTIONS  -  buttons, rows, icon buttons, key pickers, color pickers
--============================================================================
local BtnSec = ActTab:AddLeftSection("Buttons", "mouse-pointer-click")
local MainButton = BtnSec:AddButton({
    Text = "Click Me", Tooltip = "A normal button",
    Func = function() Say("Clicked", nil, 2) end,
})
MainButton:AddButton({ Text = "Sub", Func = function() Say("Sub clicked", nil, 2) end })

BtnSec:AddButton("Shorthand button", function() print("shorthand") end)
BtnSec:AddButton({ Text = "With icon", Icon = "download", Func = function() Say("Icon button", nil, 1.5) end })
BtnSec:AddButton({
    Text = "Double-click to delete", DoubleClick = true, Risky = true, Icon = "trash-2",
    Func = function() Library:Notify({ Title = "Deleted", Time = 2, Icon = "trash-2" }) end,
})
local DisabledButton = BtnSec:AddButton({ Text = "Disabled button", Disabled = true, DisabledTooltip = "Enable with the button below", Func = function() end })
BtnSec:AddButton({ Text = "Enable / disable the button above", Func = function() DisabledButton:SetDisabled(not DisabledButton.Disabled) end })
local GearButton = BtnSec:AddButton({ Text = "Button with settings", Func = function() Say("Button", "Clicked", 1.5) end })
GearButton:AddSettings():AddToggle("ButtonGearToggle", { Text = "Setting inside gear", Default = false })
local ShiftingButton
ShiftingButton = BtnSec:AddButton({ Text = "Changing button", Func = function()
    ShiftingButton:SetText("Clicked " .. os.date("%X"))
    ShiftingButton:SetIcon("check")
end })

-- Rows: several controls on one line, each with Width / Weight
local RowSec = ActTab:AddRightSection("Rows and icon buttons", "rows-3")
local PresetRow = RowSec:AddRow({ Gap = 6, Height = 21 })
PresetRow:AddDropdown("PresetDropdown", { Values = { "Preset 1", "Preset 2", "Preset 3" }, Default = 1 })
PresetRow:AddIconButton({ Icon = "pencil", Tooltip = "Rename", Func = function() Say("Row", "Rename", 1) end })
PresetRow:AddIconButton({ Icon = "trash-2", Tooltip = "Delete", Risky = true, Func = function() Say("Row", "Delete", 1) end })
PresetRow:AddIconButton({ Icon = "plus", Tooltip = "New", Func = function() Say("Row", "New", 1) end })

local FillRow = RowSec:AddRow({ Gap = 6, Height = 21 })
FillRow:AddInput("RowInput", { Placeholder = "Fill (weight 2)", Weight = 2 })
FillRow:AddButton({ Text = "Go", Width = 50, Func = function() Say("Row", "Go (fixed 50px)", 1) end })
FillRow:AddButton({ Text = "Auto width", Width = "Auto", Func = function() Say("Row", "Auto width", 1) end })

local ControlRow = RowSec:AddRow({ Gap = 8, Height = 21 })
ControlRow:AddToggle("RowToggle", { Text = "Toggle", Width = "Auto" })
ControlRow:AddCheckbox("RowCheckbox", { Text = "Check", Width = "Auto" })
ControlRow:AddStepper("RowStepper", { Default = 3, Min = 0, Max = 9 })

local SliderInRow = RowSec:AddRow({ Gap = 6, Height = 21 })
SliderInRow:AddSlider("RowSlider", { Default = 40, Min = 0, Max = 100, Compact = true, Weight = 2 })
SliderInRow:AddLabel({ Text = "label", Width = "Auto" })
SliderInRow:AddIconButton({ Icon = "rotate-ccw", Tooltip = "Reset", Func = function() Options.RowSlider:SetValue(40) end })

RowSec:AddDivider("Standalone icon buttons")
local WideIconButton = RowSec:AddIconButton({ Icon = "plus", Text = "Wide icon button", Func = function() Say("IconButton", "Clicked", 1) end })
RowSec:AddIconButton({ Icon = "settings", Size = 26, IconSize = 16, Tooltip = "Bigger square", Func = function() end })
RowSec:AddIconButton({ Icon = "ban", Text = "Disabled", Disabled = true, DisabledTooltip = "Disabled", Func = function() end })
local IconButtonRow = RowSec:AddRow({ Gap = 6, Height = 21 })
IconButtonRow:AddButton({ Text = "SetText", Func = function() WideIconButton:SetText("Renamed " .. math.random(1, 9)) end })
IconButtonRow:AddButton({ Text = "SetIcon", Func = function() WideIconButton:SetIcon("star") end })
IconButtonRow:AddButton({ Text = "SetTooltip", Func = function() WideIconButton:SetTooltip("New tooltip") end })

-- Key pickers: on toggles and labels, every mode
local KeySec = ActTab:AddLeftSection("Key pickers", "keyboard")
local BoundToggle = KeySec:AddToggle("BoundToggle", { Text = "Keybound toggle (sync)" })
local BoundKey = BoundToggle:AddKeyPicker("BoundToggleKey", {
    Text = "Toggle: sync key", Default = "F1", Mode = "Toggle",
    Modes = { "Toggle", "Hold", "Always" }, SyncToggleState = true,
    Callback = function(State) print("Toggle key state ->", State) end,
})
BoundKey:OnChanged(function(KeyCode, Modifiers) print("key changed", KeyCode, Modifiers) end)
BoundKey:OnClick(function(State) print("key clicked", State) end)

KeySec:AddLabel("Hold mode"):AddKeyPicker("HoldKey", {
    Text = "Hold: sprint", Default = "LeftShift", Mode = "Hold", Modes = { "Hold", "Toggle" },
    Callback = function(State) print("Hold ->", State) end,
})
KeySec:AddLabel("Press mode with modifiers"):AddKeyPicker("PressKey", {
    Text = "Press: Ctrl+Shift+F3", Default = "F3", DefaultModifiers = { "LCtrl", "LShift" }, Mode = "Press",
    Clicked = function() Say("Key", "Pressed", 1) end,
})
KeySec:AddLabel("Always mode"):AddKeyPicker("AlwaysKey", { Text = "Always: passive", Default = "None", Mode = "Always" })
KeySec:AddLabel("Blacklisted and whitelisted"):AddKeyPicker("RestrictedKey", {
    Text = "Restricted keys", Default = "Q", Mode = "Toggle",
    Whitelisted = { "Q", "E", "R", "F" }, Blacklisted = { "Escape" },
})
local KeyRow = KeySec:AddRow({ Gap = 6, Height = 21 })
KeyRow:AddButton({ Text = "SetValue", Func = function() BoundKey:SetValue({ Key = "F", Mode = "Toggle", Modifiers = { "LShift" } }) end })
KeyRow:AddButton({ Text = "GetState", Func = function() Say("Key", tostring(BoundKey:GetState()), 1.5) end })
KeyRow:AddButton({ Text = "Hide in menu", Func = function() Options.AlwaysKey:SetMenuVisibility(false) end })

-- Color pickers
local ColorSec = ActTab:AddRightSection("Color pickers", "palette")
local AccentLabel = ColorSec:AddLabel("Accent color")
local AccentPicker = AccentLabel:AddColorPicker("AccentColor", {
    Default = Color3.fromRGB(66, 135, 245), Title = "Pick a color",
    Callback = function(Color) print("Accent ->", Color) end,
})
AccentPicker:OnChanged(function(Color) print("Accent OnChanged ->", Color) end)

local GlowToggle = ColorSec:AddToggle("GlowToggle", { Text = "Glow (with alpha)" })
local GlowPicker = GlowToggle:AddColorPicker("GlowColor", {
    Default = Color3.fromRGB(120, 220, 120), Transparency = 0.25, Title = "Glow color",
})
ColorSec:AddLabel("Fixed size picker"):AddColorPicker("FixedColor", { Default = Color3.fromRGB(255, 120, 80), Resizable = false })

-- Two addons on one element: a color picker AND a key picker
local DoubleToggle = ColorSec:AddToggle("DoubleAddonToggle", { Text = "Color + key on one toggle" })
DoubleToggle:AddColorPicker("DoubleColor", { Default = Color3.fromRGB(180, 120, 255) })
DoubleToggle:AddKeyPicker("DoubleKey", { Text = "Color + key toggle", Default = "None", Mode = "Toggle" })

local ColorRow = ColorSec:AddRow({ Gap = 6, Height = 21 })
ColorRow:AddButton({ Text = "Set red", Func = function() AccentPicker:SetValueRGB(Color3.fromRGB(255, 80, 80)) end })
ColorRow:AddButton({ Text = "Set HSV", Func = function() AccentPicker:SetValue({ 0.6, 0.8, 1 }) end })
ColorRow:AddButton({ Text = "RunChanged", Func = function() AccentPicker:RunChanged() end })

--============================================================================
-- SECTIONS  -  section options, columns, tab groups
--============================================================================
local FullSection = SectionsTab:AddSection({
    Name = "Full-Width", IconName = "maximize", Subtext = "No Side set: spans the whole tab", IconStyle = "Tile",
})
FullSection:AddLabel({ Text = "Sections can show an icon (inline or tile) and a subtext line under the title.", DoesWrap = true })

local LayoutLeft = SectionsTab:AddLeftSection("Left Column", "panel-left")
LayoutLeft:AddToggle("LeftToggle", { Text = "Left toggle", Default = true })
LayoutLeft:AddSlider("LeftSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

local LayoutRight = SectionsTab:AddRightSection("Right Column", "panel-right")
LayoutRight:AddToggle("RightToggle", { Text = "Right toggle" })
LayoutRight:AddSlider("RightSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

-- Max height: taller content scrolls inside the section
local ScrollSection = SectionsTab:AddLeftSection({ Name = "MaxHeight = 110", Side = 1, IconName = "scroll", MaxHeight = 110 })
for Index = 1, 8 do
    ScrollSection:AddLabel("Scrolling row " .. Index)
end
local HeightRow = ScrollSection:AddRow({ Gap = 6, Height = 21 })
HeightRow:AddButton({ Text = "SetMaxHeight 200", Func = function() ScrollSection:SetMaxHeight(200) end })
HeightRow:AddButton({ Text = "No limit", Func = function() ScrollSection:SetMaxHeight(nil) end })

-- Pop-out: the arrow on the header floats the section into a draggable panel
local PopSection = SectionsTab:AddRightSection({
    Name = "Pop-out options", Side = 2, IconName = "external-link", PopOut = true, PopOutWidth = 300, MaxPopOutHeight = 260,
})
PopSection:AddToggle("PopToggle", { Text = "Lives in the panel while popped out", Default = true })
PopSection:AddSlider("PopSlider", { Text = "Value", Default = 20, Min = 0, Max = 100 })
local PopRow = PopSection:AddRow({ Gap = 6, Height = 21 })
PopRow:AddButton({ Text = "Pop out", Func = function() PopSection:SetPoppedOut(true) end })
PopRow:AddButton({ Text = "Dock", Func = function() PopSection:SetPoppedOut(false) end })
PopRow:AddButton({ Text = "Toggle", Func = function() PopSection:TogglePoppedOut() end })
local PopRow2 = PopSection:AddRow({ Gap = 6, Height = 21 })
PopRow2:AddButton({ Text = "IsPoppedOut?", Func = function() Say("Pop-out", tostring(PopSection:IsPoppedOut()), 1.5) end })
PopRow2:AddButton({ Text = "Width 360", Func = function() PopSection:SetPopOutWidth(360) end })
PopRow2:AddButton({ Text = "Max height 180", Func = function() PopSection:SetMaxPopOutHeight(180) end })

local NoPopSection = SectionsTab:AddLeftSection({ Name = "PopOut = false", Side = 1, IconName = "lock", PopOut = false })
NoPopSection:AddLabel({ Text = "This section has no pop-out button on its header.", DoesWrap = true })

-- Tab groups (tabbed boxes) with pages
local Group = SectionsTab:AddRightSectionGroup("Tab group")
local PageOne = Group:AddTab("Page One", "list")
PageOne:AddToggle("GroupToggle", { Text = "Toggle on page one", Default = true })
PageOne:AddSlider("GroupSlider", { Text = "Slider on page one", Default = 30, Min = 0, Max = 100 })
local PageTwo = Group:AddTab("Page Two", "settings")
PageTwo:AddDropdown("GroupDropdown", { Text = "Dropdown on page two", Values = { "A", "B", "C" }, Default = "B" })
PageTwo:AddButton({ Text = "Button on page two", Func = function() Say("Group", "Page two button", 1.5) end })
local PageThree = Group:AddTab("Page Three")
PageThree:AddLabel("A page without an icon")

local AccentGroup = SectionsTab:AddSectionGroup({ Name = "Accent border group", AccentBorder = true, MaxHeight = 140 })
AccentGroup:AddTab("First", "star"):AddLabel("AccentBorder = true and MaxHeight = 140")
local Overflow = AccentGroup:AddTab("Overflow", "arrow-down")
for Index = 1, 8 do Overflow:AddLabel("Row " .. Index) end

--============================================================================
-- NESTED  -  sub-sections and conditionals
--============================================================================
local Parent = NestedTab:AddSection("Sub-sections", "folder-tree")
local SubA = Parent:AddSubSection({ Name = "Nested (open)", IconName = "folder-open", DefaultOpen = true })
SubA:AddToggle("SubToggleA", { Text = "Nested toggle" })
SubA:AddSlider("SubSliderA", { Text = "Nested slider", Default = 20, Min = 0, Max = 100 })

local SubB = Parent:AddSubSection({ Name = "Nested (closed)", IconName = "folder", DefaultOpen = false })
SubB:AddLabel("Click the header above to fold it.")

local SubLeft = Parent:AddSubSection({ Name = "Left sub-section", IconName = "panel-left", Side = 1 })
SubLeft:AddToggle("SubLeftToggle", { Text = "Left" })
local SubRight = Parent:AddSubSection({ Name = "Right sub-section", IconName = "panel-right", Side = 2 })
SubRight:AddToggle("SubRightToggle", { Text = "Right" })

Parent:AddSubSection("Shorthand form", "zap"):AddLabel("AddSubSection(name, icon)")

-- Conditional group: shown only when every dependency matches
local CondParent = NestedTab:AddSection("Conditional group", "git-fork")
local Driver = CondParent:AddToggle("ShowExtra", { Text = "Show extra options", Default = false })
local ModeDriver = CondParent:AddDropdown("CondMode", { Text = "Mode", Values = { "Simple", "Advanced" }, Default = "Simple" })
local ExtraGroup = CondParent:AddConditionalGroup()
ExtraGroup:AddSlider("ExtraSlider", { Text = "Needs toggle ON and Advanced", Default = 50, Min = 0, Max = 100 })
ExtraGroup:AddButton({ Text = "Extra button", Func = function() Say("Conditional", "Visible", 1) end })
ExtraGroup:SetupDependencies({ { Driver, true }, { ModeDriver, "Advanced" } })

-- Conditional section: a whole box that appears and disappears
local CondSection = CondParent:AddConditionalSection()
CondSection:AddLabel({ Text = "A whole section that is only visible while the toggle above is ON.", DoesWrap = true })
CondSection:AddToggle("CondSectionToggle", { Text = "Inside the conditional section" })
CondSection:SetupDependencies({ { Driver, true } })

--============================================================================
-- CUSTOM TAB / KEY TAB
--============================================================================
local CustomFrame = Instance.new("Frame")
CustomFrame.BackgroundTransparency = 1
CustomFrame.Size = UDim2.fromScale(1, 1)
CustomFrame.Parent = CustomTab.Container

local CustomLabel = Instance.new("TextLabel")
CustomLabel.BackgroundTransparency = 1
CustomLabel.AnchorPoint = Vector2.new(0.5, 0.5)
CustomLabel.Position = UDim2.fromScale(0.5, 0.45)
CustomLabel.Size = UDim2.fromOffset(320, 40)
CustomLabel.FontFace = Library.Scheme.Font
CustomLabel.Text = "Anything you parent to Tab.Container shows up here."
CustomLabel.TextColor3 = Library.Scheme.FontColor
CustomLabel.TextSize = 14
CustomLabel.TextWrapped = true
CustomLabel.Parent = CustomFrame

KeyTab:AddLabel("Enter your key below")
KeyTab:AddKeyBox(function(Key)
    if Key == "astral" then
        Say("Key accepted", "Access granted", 3)
    else
        Say("Wrong key", "Try \"astral\"", 3)
    end
end)

--============================================================================
-- DIALOGS
--============================================================================
local DialogSec = DialogTab:AddLeftSection("Modal dialogs", "message-square")

DialogSec:AddButton({ Text = "Confirm dialog", Func = function()
    Window:AddDialog("ConfirmDialog", {
        Title = "Delete config?", Description = "This cannot be undone.", Icon = "trash-2",
        FooterButtons = {
            Cancel  = { Title = "Cancel", Variant = "Secondary", Order = 1 },
            Confirm = { Title = "Delete", Variant = "Destructive", Order = 2,
                Callback = function() Say("Deleted", nil, 2) end },
        },
    })
end })

DialogSec:AddButton({ Text = "All button variants", Func = function()
    local Dialog
    Dialog = Window:AddDialog("VariantsDialog", {
        Title = "Button variants", Description = "Primary, Secondary, Destructive and Ghost, with a body.",
        AutoDismiss = true, OutsideClickDismiss = true,
        FooterButtons = {
            Cancel    = { Title = "Cancel", Variant = "Ghost", Order = 1 },
            Secondary = { Title = "Secondary", Variant = "Secondary", Order = 2, Callback = function() print("Secondary") end },
            Delete    = { Title = "Delete", Variant = "Destructive", Order = 3, Callback = function() print("Delete") end },
            Confirm   = { Title = "Confirm", Variant = "Primary", Order = 4, WaitTime = 3, Callback = function() print("Confirm") end },
        },
    })
    Dialog:AddToggle("DisableSecondary", {
        Text = "Disable the Secondary button", Default = false,
        Callback = function(Value) Dialog:SetButtonDisabled("Secondary", Value) end,
    })
    Dialog:AddToggle("SwapDeleteOrder", {
        Text = "Send Delete to the right", Default = false,
        Callback = function(Value) Dialog:SetButtonOrder("Delete", Value and 5 or 3) end,
    })
    Dialog:AddInput("DialogTypeInput", { Text = "Type something:", Callback = function(Value) print("Typed:", Value) end })
end })

DialogSec:AddButton({ Text = "Dialog with a form body", Func = function()
    local Name, Mode, Amount
    local Dialog = Window:AddDialog("FormDialog", {
        Title = "Save config", Description = "Give it a name.", Icon = "save",
        ButtonsAlignment = "Center",
        FooterButtons = {
            Save = { Title = "Save", Variant = "Primary", Order = 1, WaitTime = 2,
                Callback = function() Say("Saved", Name.Value .. " / " .. tostring(Mode.Value) .. " / " .. Amount.Value, 2.5) end },
        },
    })
    Name = Dialog:AddInput("DialogName", { Text = "Config name", Placeholder = "MyConfig" })
    Mode = Dialog:AddDropdown("DialogMode", { Text = "Mode", Values = { "Legit", "Rage" }, Default = "Legit" })
    Amount = Dialog:AddSlider("DialogAmount", { Text = "Amount", Default = 5, Min = 0, Max = 10 })
end })

DialogSec:AddButton({ Text = "Multi-step dialog", Func = function()
    Window:AddDialog("MultiStepDialog", {
        Title = "Step 1 of 2", Description = "Pick a name, then confirm.", Icon = "arrow-right",
        AutoDismiss = false,
        FooterButtons = {
            Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(D) D:Dismiss() end },
            Next = {
                Title = "Next", Variant = "Primary", Order = 2,
                Callback = function(D)
                    D:SetTitle("Step 2 of 2")
                    D:SetDescription("Confirm the change.")
                    D:RemoveFooterButton("Next")
                    D:AddFooterButton("Confirm", {
                        Title = "Confirm", Variant = "Primary", Order = 2,
                        Callback = function(D2) Say("Completed", nil, 2); D2:Dismiss() end,
                    })
                end,
            },
        },
    })
end })

local DialogSec2 = DialogTab:AddRightSection("More dialogs", "layers")
DialogSec2:AddButton({ Text = "Empty dialog (one button)", Func = function()
    Window:AddDialog("EmptyDialog", {
        Title = "Empty dialog", Description = "No body elements, so the padding stays normal.",
        FooterButtons = { Confirm = { Title = "Okay", Variant = "Primary" } },
    })
end })
DialogSec2:AddButton({ Text = "Must use a button (no outside click)", Func = function()
    Window:AddDialog("StrictDialog", {
        Title = "Read this", Description = "Clicking outside does not dismiss this one.",
        OutsideClickDismiss = false, AutoDismiss = true,
        TitleColor = Color3.fromRGB(255, 200, 80), DescriptionColor = Color3.fromRGB(200, 200, 200), Icon = "circle-alert",
        FooterButtons = { Confirm = { Title = "Understood", Variant = "Primary", WaitTime = 2 } },
    })
end })
DialogSec2:AddButton({ Text = "Alignment: left / center / right", Func = function()
    local Dialog = Window:AddDialog("AlignDialog", {
        Title = "Alignment", Description = "Change where the footer buttons sit.",
        ButtonsAlignment = "Left",
        FooterButtons = { Close = { Title = "Close", Variant = "Secondary" }, Ok = { Title = "OK", Variant = "Primary" } },
    })
    Dialog:AddDropdown("AlignChoice", {
        Text = "ButtonsAlignment", Values = { "Left", "Center", "Right" }, Default = "Left",
        Callback = function(Value) Dialog:SetButtonsAlignment(Value) end,
    })
end })
DialogSec2:AddLabel({ Text = "Dialogs follow the window transparency and gradient: change them on the Settings tab.", DoesWrap = true })

--============================================================================
-- OVERLAYS
--============================================================================
local OverlaySec = OverlayTab:AddLeftSection("Draggable overlays", "layers")

OverlaySec:AddButton({ Text = "Spawn label", Func = function() Library:AddDraggableLabel("Drag me") end })
OverlaySec:AddButton({ Text = "Spawn label with icon (right)", Func = function() Library:AddDraggableLabel("Pinned", "pin", "right") end })
OverlaySec:AddButton({ Text = "Spawn button", Func = function()
    Library:AddDraggableButton("Click me", function() Say("Clicked", nil, 2) end)
end })
OverlaySec:AddButton({ Text = "Spawn image button", Func = function()
    Library:AddDraggableImageButton("menu", 24, function() Say("Image button", nil, 1.5) end)
end })
OverlaySec:AddButton({ Text = "Spawn toggle", Func = function()
    Library:AddDraggableToggle("Auto Farm", false, function(Value) print("toggle", Value) end)
end })
OverlaySec:AddButton({ Text = "Spawn progress", Func = function()
    local Progress = Library:AddDraggableProgress("Loading...", 0, 100)
    task.spawn(function()
        local Value = 0
        while Value < 100 and Progress:IsVisible() do
            Value += 10
            Progress:SetValue(Value)
            task.wait(0.5)
        end
        Progress:SetText("Done")
    end)
end })

OverlaySec:AddDivider("Overlay manager")
OverlaySec:AddButton({ Text = "List overlays", Func = function()
    local Overlays = Library:GetOverlays()
    if #Overlays == 0 then
        Say("Overlays", "None active", 2)
        return
    end
    local Lines = {}
    for _, Overlay in Overlays do
        table.insert(Lines, string.format("#%d  %s  (%s)", Overlay.Id, Overlay.OverlayName, Overlay.OverlayType))
    end
    Window:AddDialog("OverlayList", {
        Title = string.format("Active overlays (%d)", #Overlays),
        Description = table.concat(Lines, "\n"),
    })
end })
OverlaySec:AddButton({ Text = "Toggle the newest overlay", Func = function()
    local Overlays = Library:GetOverlays()
    local Newest = Overlays[#Overlays]
    if Newest then Library:ToggleOverlay(Newest.Id) end
end })
OverlaySec:AddButton({ Text = "Hide / show all toggles", Func = function() Library:SetAllOverlaysVisible(false, "DraggableToggle") end })
OverlaySec:AddButton({ Text = "Hide all overlays", Func = function() Library:SetAllOverlaysVisible(false) end })
OverlaySec:AddButton({ Text = "Show all overlays", Func = function() Library:SetAllOverlaysVisible(true) end })
OverlaySec:AddButton({ Text = "Remove all overlays", Risky = true, Func = function() Library:RemoveAllOverlays() end })

-- Context menu: styled with the library font so it matches the rest of the UI
local CtxSec = OverlayTab:AddRightSection("Context menu and menus", "menu")
local CtxAnchor = Instance.new("TextButton")
CtxAnchor.Size = UDim2.new(1, 0, 0, 30)
CtxAnchor.BackgroundColor3 = Library.Scheme.MainColor
CtxAnchor.FontFace = Library.Scheme.Font
CtxAnchor.Text = "Right-click (or long-press) me"
CtxAnchor.TextColor3 = Library.Scheme.FontColor
CtxAnchor.TextSize = 12
CtxAnchor.AutoButtonColor = false
CtxSec:AddUIPassthrough("CtxAnchor", { Instance = CtxAnchor, Height = 34 })

local CtxMenu = Library:AddContextMenu(CtxAnchor, UDim2.fromOffset(150, 0), { 0, 6 }, 1)
CtxMenu.List.Padding = UDim.new(0, 2)
for _, Name in { "Rename", "Duplicate", "Delete" } do
    local Row = Instance.new("TextButton")
    Row.BackgroundTransparency = 1
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.FontFace = Library.Scheme.Font
    Row.Text = Name
    Row.TextColor3 = Library.Scheme.FontColor
    Row.TextSize = 12
    Row.TextXAlignment = Enum.TextXAlignment.Left
    Row.ZIndex = CtxMenu.Menu.ZIndex
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.Parent = Row
    Row.Parent = CtxMenu.Menu
    Row.MouseButton1Click:Connect(function()
        Say(Name, "clicked", 1.5)
        CtxMenu:Close()
    end)
end
CtxAnchor.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then CtxMenu:Toggle() end
end)
Library:AddLongPressAsRightClick(CtxAnchor, function() CtxMenu:Toggle() end)

-- Tooltip and focus highlight on custom instances
local TooltipButton = Instance.new("TextButton")
TooltipButton.BackgroundColor3 = Library.Scheme.MainColor
TooltipButton.FontFace = Library.Scheme.Font
TooltipButton.Text = "Hover me (custom tooltip)"
TooltipButton.TextColor3 = Library.Scheme.FontColor
TooltipButton.TextSize = 12
TooltipButton.AutoButtonColor = false
CtxSec:AddUIPassthrough("TooltipButton", { Instance = TooltipButton, Height = 26 })
Library:AddTooltip("Shown normally", "Shown while disabled", TooltipButton)

local FocusBox = Instance.new("TextBox")
FocusBox.BackgroundColor3 = Library.Scheme.MainColor
FocusBox.FontFace = Library.Scheme.Font
FocusBox.PlaceholderText = "Focus me (accent highlight)"
FocusBox.Text = ""
FocusBox.TextColor3 = Library.Scheme.FontColor
FocusBox.TextSize = 12
CtxSec:AddUIPassthrough("FocusBox", { Instance = FocusBox, Height = 26 })
Library:AddFocusHighlight(FocusBox)

-- Draggable menu
local MenuRow = CtxSec:AddRow({ Gap = 6, Height = 21 })
MenuRow:AddButton({ Text = "Spawn draggable menu", Func = function()
    local _, _, MenuContainer = Library:AddDraggableMenu("Quick Actions")
    MenuContainer:AddButton({ Text = "Notify", Func = function() Say("Hi", nil, 2) end })
    MenuContainer:AddToggle("QuickToggle", { Text = "Setting", Default = false })
    MenuContainer:AddSlider("QuickSlider", { Text = "Value", Default = 25, Min = 0, Max = 100 })
    MenuContainer:AddButton({ Text = "Collapse", Func = function() MenuContainer:ToggleCollapsed() end })
    MenuContainer:AddButton({ Text = "Close", Risky = true, Func = function() MenuContainer:Remove() end })
end })

-- Bubble, watermark, keybinds panel, custom cursor
CtxSec:AddToggle("BubbleToggle", { Text = "Floating bubble", Default = true, Callback = function(Value) Library:ToggleBubble(Value) end })
CtxSec:AddToggle("WatermarkToggle", {
    Text = "Watermark", Default = false,
    Callback = function(Value)
        Library:SetWatermark("Astral UI")
        Library:SetWatermarkVisibility(Value)
    end,
})
CtxSec:AddToggle("KeybindsPanelToggle", { Text = "Keybinds panel", Default = false, Callback = function(Value) Library.KeybindFrame.Visible = Value end })
CtxSec:AddToggle("KeybindVisibilityControl", {
    Text = "Keybinds: per-key visibility", Default = false,
    Callback = function(Value) Library.KeybindMenu:SetVisibilityControl(Value) end,
})
CtxSec:AddToggle("CustomCursorToggle", { Text = "Custom cursor", Default = false, Callback = function(Value) Library.ShowCustomCursor = Value end })

--============================================================================
-- NOTIFICATIONS
--============================================================================
local NotifySec = NotifyTab:AddLeftSection("Toasts", "bell")
NotifySec:AddButton({ Text = "Basic", Func = function() Library:Notify({ Title = "Success", Description = "Action completed", Time = 4 }) end })
NotifySec:AddButton({ Text = "Shorthand", Func = function() Library:Notify("Something happened", 3) end })
NotifySec:AddButton({ Text = "Icon + colors", Func = function()
    Library:Notify({
        Title = "Heads up", TitleColor = Color3.fromRGB(255, 200, 80),
        Description = "Custom colors and icon", DescriptionColor = Color3.fromRGB(200, 200, 200),
        Icon = "circle-check", IconColor = Color3.fromRGB(120, 220, 120), Time = 4,
    })
end })
NotifySec:AddButton({ Text = "Big icon", Func = function()
    Library:Notify({ Title = "Big icon", Description = "BigIcon replaces the small one", BigIcon = "sparkles", Time = 4 })
end })
NotifySec:AddButton({ Text = "Title only", Func = function() Library:Notify({ Title = "Just a title", Time = 3 }) end })
NotifySec:AddButton({ Text = "Description only", Func = function() Library:Notify({ Description = "Just a description", Time = 3 }) end })

local NotifySec2 = NotifyTab:AddRightSection("Steps, persistence, callbacks", "list-ordered")
NotifySec2:AddButton({ Text = "Steps (updates over time)", Func = function()
    local Notif = Library:Notify({ Title = "Working", Description = "Step 1 of 4", Steps = 4, Time = 8 })
    task.spawn(function()
        for Step = 2, 4 do
            task.wait(1)
            Notif:ChangeStep(Step)
            Notif:ChangeDescription("Step " .. Step .. " of 4")
        end
        task.wait(0.5)
        Notif:ChangeTitle("Finished")
    end)
end })
NotifySec2:AddButton({ Text = "Persist + closable", Func = function()
    Library:Notify({ Title = "Stays until closed", Description = "Persist = true, Closable = true", Persist = true, Closable = true })
end })
NotifySec2:AddButton({ Text = "Callback reason", Func = function()
    Library:Notify({
        Title = "Dismiss me", Description = "The callback reports why it closed", Time = 4, Closable = true,
        Callback = function(Reason) Say("Closed", "Reason: " .. tostring(Reason), 2) end,
    })
end })
NotifySec2:AddButton({ Text = "Destroy from script", Func = function()
    local Notif = Library:Notify({ Title = "Going away", Description = "Destroyed after one second", Persist = true })
    task.delay(1, function() Notif:Destroy() end)
end })
NotifySec2:AddDropdown("NotifySideDropdown", {
    Text = "NotifySide", Values = { "Left", "Right" }, Default = "Right",
    Callback = function(Value) Library:SetNotifySide(Value) end,
})

--============================================================================
-- SETTINGS  -  display, theme, configs, window options
--============================================================================

-- This single line builds the Top UI section, Bottom-Left Themes, and Bottom-Right Configs
Library:BuildAllSettings(SettingsTab, ThemeManager, SaveManager)

--============================================================================
-- STARTUP NOTIFICATION
--============================================================================
Library:Notify({
    Title = "Astral UI Loaded",
    Description = "Reference build ready. Explore each tab.",
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
