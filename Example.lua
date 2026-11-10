--============================================================================
-- ASTRAL UI — FULL FEATURE REFERENCE
--============================================================================
-- Every element, every method, every option. Organized by feature area.
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

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

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
    Transparency      = 0,
    Gradient          = true,
    GradientRotation  = 45,
    PopOutBoxes       = true,
    DiscordLink       = "https://discord.gg/astral",
    SingleInstance    = true,
    AutoShow          = true,
})

--============================================================================
-- SECTIONS & TABS
--============================================================================
local Elements = Window:AddTabSection({ Name = "Elements",  Open = true })
local Layout   = Window:AddTabSection({ Name = "Layout",    Open = true })
local Advanced = Window:AddTabSection({ Name = "Advanced",  Open = false })
local Settings = Window:AddTabSection({ Name = "Settings",  Open = false })

local FormTab  = Elements:AddTab({ Name = "Form Controls", Icon = "sliders-horizontal", Description = "Toggles, sliders, dropdowns, inputs" })
local DispTab  = Elements:AddTab({ Name = "Display",       Icon = "type",               Description = "Labels, rich text, progress bars, media" })
local ActTab   = Elements:AddTab({ Name = "Actions",       Icon = "mouse-pointer-2",    Description = "Buttons, key pickers, color pickers" })

local SectionsTab = Layout:AddTab({ Name = "Sections",     Icon = "columns-2",          Description = "Full-width vs. two-column layout" })
local NestedTab   = Layout:AddTab({ Name = "Nested",       Icon = "git-branch",         Description = "Sub-sections, section groups, conditionals" })

local DialogTab   = Advanced:AddTab({ Name = "Dialogs",    Icon = "message-square",     Description = "Modal popups and confirmations" })
local OverlayTab  = Advanced:AddTab({ Name = "Overlays",   Icon = "picture-in-picture-2", Description = "Draggable overlays, context menus" })

local SettingsTab = Settings:AddTab({ Name = "Settings",   Icon = "settings",           Description = "UI scale, theme, configs" })

--============================================================================
-- FORM CONTROLS
--============================================================================
local ToggleSec = FormTab:AddLeftSection("Toggles")
local BasicToggle = ToggleSec:AddToggle("BasicToggle", {
    Text = "Basic Toggle",
    Default = false,
    Callback = function(Value)
        Library:Notify({ Title = "Toggle", Description = Value and "ON" or "OFF", Time = 1.5 })
    end,
})
BasicToggle:OnChanged(function(Value) print("BasicToggle ->", Value) end)

-- Settings panel on a toggle
assert(BasicToggle.AddSettings, "Toggle:AddSettings is missing: you are running an outdated Astral (" .. AstralSource .. ")")
local ToggleGear = BasicToggle:AddSettings()
ToggleGear:AddSlider("BasicToggleStrength", { Text = "Strength", Default = 50, Min = 0, Max = 100 })
ToggleGear:AddToggle("BasicToggleAnnounce",  { Text = "Announce changes", Default = false })

ToggleSec:AddToggle("RiskyToggle", { Text = "Risky Toggle", Default = false, Risky = true,
    Tooltip = "Risky = red label" })

ToggleSec:AddToggle("DisabledToggle", {
    Text = "Disabled Toggle", Default = true, Disabled = true,
    DisabledTooltip = "Enable with the button below",
})

ToggleSec:AddButton({ Text = "Toggle DisabledToggle", Func = function()
    local T = Library.Toggles.DisabledToggle
    T:SetDisabled(not T.Disabled)
end })

local CheckSec = FormTab:AddRightSection("Checkboxes")
CheckSec:AddCheckbox("BasicCheckbox", { Text = "Checkbox style", Default = false })
CheckSec:AddCheckbox("RiskyCheckbox", { Text = "Risky checkbox", Default = false, Risky = true })
CheckSec:AddToggle("ForceCheckboxGlobal", {
    Text = "Force ALL toggles to render as checkboxes",
    Default = false,
    Callback = function(Value) Library:SetForceCheckbox(Value) end,
})

-- Sliders
local SliderSec = FormTab:AddLeftSection("Sliders")
local SpeedSlider = SliderSec:AddSlider("SpeedSlider", {
    Text = "Speed", Default = 16, Min = 0, Max = 100, Rounding = 0, Suffix = " studs/s",
})
SliderSec:AddSlider("PencilSlider",    { Text = "Pencil style",   Default = 50, Min = 0, Max = 100, Editable = true, EditableStyle = "Pencil" })
SliderSec:AddSlider("ValueBoxSlider",  { Text = "ValueBox style", Default = 25, Min = 0, Max = 100, Editable = true, EditableStyle = "ValueBox" })
SliderSec:AddSlider("CompactSlider",   { Text = "Compact",        Default = 40, Min = 0, Max = 100, Compact = true, HideMax = true })
SliderSec:AddSlider("DecimalSlider",   { Text = "2-decimal",      Default = 0.5, Min = 0, Max = 1, Rounding = 2 })
SliderSec:AddSlider("CustomFormatSlider", {
    Text = "Custom format", Default = 50, Min = 0, Max = 100,
    FormatDisplayValue = function(S, V) return string.format("Lv %d/%d", V, S.Max) end,
})

-- Settings on a slider
local SliderGear = SliderSec:AddSlider("GearSlider", {
    Text = "With settings", Default = 50, Min = 0, Max = 100,
}):AddSettings()
SliderGear:AddToggle("GearSliderToggle", { Text = "Setting inside gear", Default = false })

-- Dropdowns
local DropSec = FormTab:AddRightSection("Dropdowns")
local ModeDrop = DropSec:AddDropdown("ModeDropdown", {
    Text = "Select Mode",
    Values = { "Option A", "Option B", "Option C" },
    Default = "Option A",
})
ModeDrop:OnChanged(function(Value) print("ModeDropdown ->", Value) end)

DropSec:AddDropdown("NullableDropdown", {
    Text = "Nullable + Disabled", Values = { "Enabled", "Disabled Choice" },
    Default = nil, AllowNull = true, DisabledValues = { "Disabled Choice" },
})
DropSec:AddDropdown("SearchableSingle", {
    Text = "Searchable", Values = { "Apple", "Banana", "Cherry", "Grape", "Mango", "Orange" },
    Default = "Apple", Searchable = true,
})

-- Settings on a dropdown
local DropGear = DropSec:AddDropdown("DropGearDemo", {
    Text = "With settings", Values = { "A", "B", "C" }, Default = "A",
}):AddSettings()
DropGear:AddToggle("DropGearToggle", { Text = "Setting inside gear", Default = true })

local RolesSec = FormTab:AddLeftSection("Multi-select")
local RolesDrop = RolesSec:AddDropdown("RolesDropdown", {
    Text = "Roles",
    Values = { "Admin", "Moderator", "Editor", "Viewer", "Contributor", "Reviewer", "Support", "Analyst" },
    Default = { "Admin", "Analyst" },
    Multi = true, Searchable = true, MaxVisibleDropdownItems = 6,
})

RolesSec:AddButton({ Text = "Get active roles", Func = function()
    local Names = {}
    for Key in pairs(RolesDrop:GetActiveValues()) do table.insert(Names, Key) end
    Library:Notify({ Title = "Roles", Description = #Names > 0 and table.concat(Names, ", ") or "(none)", Time = 2.5 })
end })

-- Inputs
local InputSec = FormTab:AddRightSection("Inputs")
local NameInput = InputSec:AddInput("NameInput", { Text = "Your Name", Placeholder = "Type here..." })
InputSec:AddInput("NumericInput",    { Text = "Numeric",  Numeric = true, Finished = true, Placeholder = "123" })
InputSec:AddInput("EmptyResetInput", { Text = "Falls back when empty", Default = "DefaultValue", AllowEmpty = false, EmptyReset = "---" })

InputSec:AddInput("ValidatedInput", {
    Text = "Username (3-20 chars)",
    -- VerifyValue must return exactly `true` to accept the text (and forces Finished = true)
    VerifyValue = function(Text) return #Text >= 3 and #Text <= 20 and Text:match("^%w+$") ~= nil end,
})
InputSec:AddInput("VerifiedInput", {
    Text = "Even numbers only",
    Numeric = true,
    VerifyValue = function(V) local N = tonumber(V); return N ~= nil and N % 2 == 0 end,
})

--============================================================================
-- DISPLAY
--============================================================================
local DivSec = DispTab:AddLeftSection("Dividers")
DivSec:AddLabel("Above the divider")
DivSec:AddDivider("Labelled")
DivSec:AddDivider()
DivSec:AddDivider({ Text = "Custom margins", MarginTop = 8, MarginBottom = 8 })

local LabelSec = DispTab:AddRightSection("Labels")
local CounterLabel = LabelSec:AddLabel('Counter: <font color="rgb(66,135,245)">0</font>')
LabelSec:AddLabel({
    Text = "<b>Bold</b> · <i>Italic</i> · <u>Underline</u> · <font color=\"rgb(120,220,120)\">Colored</font>",
    DoesWrap = true, Size = 13,
})

local Count = 0
LabelSec:AddButton({ Text = "Increment counter", Func = function()
    Count += 1
    CounterLabel:SetText(string.format('Counter: <font color="rgb(66,135,245)">%d</font>', Count))
end })

-- Progress
local ProgSec = DispTab:AddLeftSection("Progress")
local HealthBar = ProgSec:AddProgressBar("HealthBar", { Text = "Health", Value = 100, Min = 0, Max = 100, Suffix = " HP" })
ProgSec:AddButton({ Text = "Deal 25 damage", Func = function()
    HealthBar:SetValue(math.max(0, HealthBar.Value - 25))
end })
ProgSec:AddProgressBar("CompactBar", { Text = "Compact", Value = 60, Min = 0, Max = 100, Compact = true, HideMax = true })

-- Image / Viewport
local ImageSec = DispTab:AddRightSection("Media")
local DemoImage = ImageSec:AddImage("DemoImage", { Image = "sparkles", Height = 90, ScaleType = Enum.ScaleType.Fit })
ImageSec:AddButton({ Text = "Cycle image", Func = function()
    DemoImage:SetImage("star")
    task.delay(1.5, function() DemoImage:SetImage("sparkles") end)
end })

local DemoModel = Instance.new("Model")
local DemoPart  = Instance.new("Part")
DemoPart.Size = Vector3.new(3, 3, 3); DemoPart.Anchored = true
DemoPart.Color = Color3.fromRGB(66, 135, 245); DemoPart.Parent = DemoModel
local DemoViewport = ImageSec:AddViewport("DemoViewport", { Object = DemoModel, Height = 130, Interactive = true, AutoFocus = true })
ImageSec:AddButton({ Text = "Focus viewport", Func = function() DemoViewport:Focus() end })

local VideoSec = DispTab:AddLeftSection("Video")
VideoSec:AddLabel({ Text = "Provide a real rbxassetid:// video asset to see playback.", DoesWrap = true })
local DemoVideo = VideoSec:AddVideo("DemoVideo", { Video = "rbxassetid://0", Height = 100 })
VideoSec:AddButton({ Text = "Play / Pause", Func = function()
    if DemoVideo.Playing then DemoVideo:Pause() else DemoVideo:Play() end
end })

--============================================================================
-- ACTIONS
--============================================================================
local BtnSec = ActTab:AddLeftSection("Buttons")
local MainButton = BtnSec:AddButton({
    Text = "Click Me",
    Func = function() Library:Notify({ Title = "Clicked", Time = 2 }) end,
})
MainButton:AddButton({ Text = "Sub", Func = function() Library:Notify({ Title = "Sub clicked", Time = 2 }) end })

BtnSec:AddButton("Shorthand button", function() print("shorthand") end)
BtnSec:AddButton({
    Text = "Double-click to delete", DoubleClick = true, Risky = true,
    Func = function() Library:Notify({ Title = "Deleted", Time = 2, Icon = "trash-2" }) end,
})

-- Key Picker
local KeySec = ActTab:AddRightSection("Key Pickers")
local BoundToggle = KeySec:AddToggle("BoundToggle", { Text = "Keybound toggle" })
local BoundKey = BoundToggle:AddKeyPicker("BoundToggleKey", {
    Text = "Toggle Key", Default = "F1", Mode = "Toggle",
    Modes = { "Toggle", "Hold", "Always" }, SyncToggleState = true,
})
BoundKey:OnChanged(function(KeyCode, Modifiers) print("key", KeyCode, Modifiers) end)

local PressLabel = KeySec:AddLabel("Modifier combo (Ctrl+Shift)")
PressLabel:AddKeyPicker("PressKey", {
    Text = "Ctrl+Shift", Default = "F3", DefaultModifiers = { "LCtrl", "LShift" },
    Mode = "Press",
})

-- Color Picker
local ColorSec = ActTab:AddLeftSection("Color Pickers")
local AccentLabel = ColorSec:AddLabel("Accent color")
local AccentPicker = AccentLabel:AddColorPicker("AccentColor", {
    Default = Color3.fromRGB(66, 135, 245), Title = "Pick a color",
})
ColorSec:AddButton({ Text = "Set to red", Func = function()
    AccentPicker:SetValueRGB(Color3.fromRGB(255, 80, 80))
end })

local GlowToggle = ColorSec:AddToggle("GlowToggle", { Text = "Glow (with alpha)" })
local GlowPicker = GlowToggle:AddColorPicker("GlowColor", {
    Default = Color3.fromRGB(120, 220, 120), Transparency = 0.25,
})

--============================================================================
-- SECTIONS LAYOUT
--============================================================================
SectionsTab:AddSection({ Name = "Full-Width", IconName = "maximize" }):AddLabel({
    Text = "No Side set -- this section spans the full tab width.", DoesWrap = true,
})

local LayoutLeft  = SectionsTab:AddLeftSection("Left Column")
LayoutLeft:AddToggle("LeftToggle", { Text = "Left toggle", Default = true })
LayoutLeft:AddSlider("LeftSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

local LayoutRight = SectionsTab:AddRightSection("Right Column")
LayoutRight:AddToggle("RightToggle", { Text = "Right toggle" })
LayoutRight:AddSlider("RightSlider", { Text = "Value", Default = 50, Min = 0, Max = 100 })

--============================================================================
-- NESTED & CONDITIONALS
--============================================================================
local Parent = NestedTab:AddSection("Sub-sections")
local SubA = Parent:AddSubSection({ Name = "Nested (open)", DefaultOpen = true })
SubA:AddToggle("SubToggleA", { Text = "Nested toggle" })

local SubB = Parent:AddSubSection({ Name = "Nested (closed)", DefaultOpen = false })
SubB:AddLabel("Click the header above.")

local GroupBox = NestedTab:AddSectionGroup({ Name = "Grouped tabs" })
GroupBox:AddTab("Page One", "list"):AddLabel("Content for Page One.")
GroupBox:AddTab("Page Two", "settings"):AddLabel("Content for Page Two.")

local CondParent = NestedTab:AddSection("Conditional Group")
local Driver = CondParent:AddToggle("ShowExtra", { Text = "Show extra options", Default = false })
local ExtraGroup = CondParent:AddConditionalGroup()
ExtraGroup:AddSlider("ExtraSlider", { Text = "Only visible when ShowExtra is ON", Default = 50, Min = 0, Max = 100 })
ExtraGroup:SetupDependencies({ { Driver, true } })

--============================================================================
-- DIALOGS
--============================================================================
local DialogSec = DialogTab:AddSection("Modal Dialogs")

DialogSec:AddButton({ Text = "Confirm Dialog", Func = function()
    Window:AddDialog("ConfirmDialog", {
        Title = "Delete Config?", Description = "This cannot be undone.",
        Icon = "trash-2",
        FooterButtons = {
            Cancel  = { Title = "Cancel", Variant = "Secondary", Order = 1 },
            Confirm = { Title = "Delete", Variant = "Destructive", Order = 2,
                Callback = function() Library:Notify({ Title = "Deleted", Time = 2 }) end },
        },
    })
end })

DialogSec:AddButton({ Text = "Dialog with body + WaitTime", Func = function()
    local Input
    local D = Window:AddDialog("InputDialog", {
        Title = "Save Config", Description = "Give it a name.", Icon = "save",
        FooterButtons = {
            Save = {
                Title = "Save", Variant = "Primary", Order = 1, WaitTime = 2,
                Callback = function()
                    Library:Notify({ Title = "Saved", Description = Input.Value, Time = 2 })
                end,
            },
        },
    })
    Input = D:AddInput("ConfigName", { Text = "Config Name", Placeholder = "MyConfig" })
end })

DialogSec:AddButton({ Text = "Multi-step dialog", Func = function()
    local D = Window:AddDialog("MultiStepDialog", {
        Title = "Step 1 of 2", Description = "Pick a name, then confirm.", Icon = "arrow-right",
        AutoDismiss = false,
        FooterButtons = {
            Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1, Callback = function(D) D:Dismiss() end },
            Next   = {
                Title = "Next", Variant = "Primary", Order = 2,
                Callback = function(D)
                    D:SetTitle("Step 2 of 2"); D:SetDescription("Confirm the change.")
                    D:RemoveFooterButton("Next")
                    D:AddFooterButton("Confirm", {
                        Title = "Confirm", Variant = "Primary", Order = 2,
                        Callback = function(D2)
                            Library:Notify({ Title = "Completed", Time = 2 })
                            D2:Dismiss()
                        end,
                    })
                end,
            },
        },
    })
end })

--============================================================================
-- OVERLAYS
--============================================================================
local OverlaySec = OverlayTab:AddLeftSection("Draggable Overlays")

OverlaySec:AddButton({ Text = "Spawn label", Func = function() Library:AddDraggableLabel("Drag me") end })
OverlaySec:AddButton({ Text = "Spawn button", Func = function()
    Library:AddDraggableButton("Click me", function() Library:Notify({ Title = "Clicked", Time = 2 }) end)
end })
OverlaySec:AddButton({ Text = "Spawn toggle", Func = function()
    Library:AddDraggableToggle("Auto Farm", false, function(Value) print("toggle", Value) end)
end })
OverlaySec:AddButton({ Text = "Spawn progress", Func = function()
    local Progress = Library:AddDraggableProgress("Loading...", 0, 100)
    task.spawn(function()
        local Value = 0
        while Value < 100 and Progress:IsVisible() do
            Value += 10; Progress:SetValue(Value); task.wait(0.5)
        end
    end)
end })

OverlaySec:AddButton({ Text = "List overlays", Func = function()
    local Overlays = Library:GetOverlays()
    if #Overlays == 0 then
        Library:Notify({ Title = "Overlays", Description = "None active", Time = 2 })
        return
    end
    local Lines = {}
    for _, O in Overlays do
        table.insert(Lines, string.format("#%d  %s  (%s)", O.Id, O.OverlayName, O.OverlayType))
    end
    Window:AddDialog("OverlayList", {
        Title = string.format("Active Overlays (%d)", #Overlays),
        Description = table.concat(Lines, "\n"),
    })
end })

OverlaySec:AddButton({ Text = "Hide all overlays", Func = function() Library:SetAllOverlaysVisible(false) end })
OverlaySec:AddButton({ Text = "Show all overlays", Func = function() Library:SetAllOverlaysVisible(true) end })
OverlaySec:AddButton({ Text = "Remove all overlays", Risky = true,
    Func = function() Library:RemoveAllOverlays() end })

-- Context menu
local CtxSec = OverlayTab:AddRightSection("Context Menu")
local CtxAnchor = Instance.new("TextButton")
CtxAnchor.Size = UDim2.new(1, 0, 0, 36)
CtxAnchor.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
CtxAnchor.Text = "Right-Click Me"
CtxAnchor.TextColor3 = Color3.new(1, 1, 1)
CtxAnchor.TextSize = 14
CtxSec:AddUIPassthrough("CtxAnchor", { Instance = CtxAnchor, Height = 40 })

local CtxMenu = Library:AddContextMenu(CtxAnchor, UDim2.fromOffset(160, 0), { 0, 6 }, 1)
CtxMenu.List.Padding = UDim.new(0, 2)
for _, Label in { "Rename", "Duplicate", "Delete" } do
    local Row = Instance.new("TextButton")
    Row.Size = UDim2.new(1, 0, 0, 24)
    Row.BackgroundTransparency = 1
    Row.Text = Label
    Row.TextColor3 = Color3.new(1, 1, 1)
    Row.TextSize = 13
    Row.ZIndex = CtxMenu.Menu.ZIndex
    Row.Parent = CtxMenu.Menu
    Row.MouseButton1Click:Connect(function()
        Library:Notify({ Title = Label .. " clicked", Time = 1.5 })
        CtxMenu:Close()
    end)
end
CtxAnchor.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then CtxMenu:Toggle() end
end)
Library:AddLongPressAsRightClick(CtxAnchor, function() CtxMenu:Toggle() end)

-- Draggable menu
CtxSec:AddButton({ Text = "Spawn draggable menu", Func = function()
    local _, _, MenuContainer = Library:AddDraggableMenu("Quick Actions")
    MenuContainer:AddButton({ Text = "Notify", Func = function() Library:Notify({ Title = "Hi", Time = 2 }) end })
    MenuContainer:AddToggle("QuickToggle", { Text = "Setting", Default = false })
    MenuContainer:AddSlider("QuickSlider", { Text = "Value", Default = 25, Min = 0, Max = 100 })
end })

-- Bubble
CtxSec:AddToggle("BubbleToggle", { Text = "Enable floating bubble", Default = true,
    Callback = function(Value) Library:ToggleBubble(Value) end })

-- Watermark
CtxSec:AddButton({ Text = "Show watermark", Func = function()
    Library:SetWatermark("Astral UI")
    Library:SetWatermarkVisibility(true)
end })

--============================================================================
-- SETTINGS
--============================================================================
local DisplaySection = SettingsTab:AddSection({ Name = "Display", IconName = "sliders-horizontal" })
DisplaySection:AddSlider("UIScaleSlider", {
    Text = "UI Scale", Default = Library:CalculateAutoDPIScale(1),
    Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value)
        Library.AutoDPIScale = false
        Library:SetDPIScale(Value)
    end,
})
DisplaySection:AddButton({ Text = "Reset to automatic scaling", Func = function()
    Library.AutoDPIScale = true
    Library:SetDPIScale(Library:CalculateAutoDPIScale())
    Library.Options.UIScaleSlider:SetValue(Library:CalculateAutoDPIScale(1))
    Library:Notify({ Title = "Display", Description = "UI Scale follows screen size automatically.", Time = 3 })
end })

-- Theme & Save managers
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local WindowSection = SettingsTab:AddRightSection("Window", "app-window")
WindowSection:AddToggle("AutoHideUI", {
    Text = "Auto Hide UI", Default = false,
    Tooltip = "When enabled, the UI stays hidden on startup until opened manually.",
    Callback = function(Value) Library.AutoShow = not Value end,
})
WindowSection:AddButton({ Text = "Open discord", Func = function()
    if setclipboard then
        setclipboard("https://discord.gg/astral")
        Library:Notify({ Title = "Discord", Description = "Invite copied to clipboard.", Icon = "copy", Time = 3 })
    end
end })
WindowSection:AddButton({ Text = "Add footer item (clickable)", Func = function()
    Window:AddFooterItem("Left", { Text = "clickable", Callback = function() Library:Notify("Footer item") end })
    Window:AddFooterItem("Right", "plain text")
end })
WindowSection:AddButton({ Text = "Clear footer items", Func = function() Window:ClearFooter() end })

--============================================================================
-- STARTUP NOTIFICATION
--============================================================================
Library:Notify({
    Title = "Astral UI Loaded",
    Description = "Reference build ready — explore each tab.",
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
