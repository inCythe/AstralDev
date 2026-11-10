--============================================================================
-- ASTRAL UI — OFFICIAL IN-DEPTH SHOWCASE & COMPREHENSIVE REFERENCE
--============================================================================
-- This showcase demonstrates every component, layout mode, addon, and method
-- available in Astral UI, built in an organized, production-ready structure.
--============================================================================

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
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/Astral.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/SaveManager.lua"))()
    ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/addons/ThemeManager.lua"))()
end

-- NOTE: SetLibrary must be called before Library:CreateWindow
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

--============================================================================
-- MAIN WINDOW CREATION
--============================================================================
local Window = Library:CreateWindow({
    Title = "Astral UI",
    Subtitle = "Comprehensive Reference",
    TitleAlignment = "Left",
    Icon = "AstralIcon",
    Footer = "Astral UI • github.com/inCythe/AstralDev",
    FooterLeft = "Build 2.0-dev",
    FooterRight = "Luau Client",
    Size = UDim2.fromOffset(820, 580),
    Center = true,
    Resizable = true,
    MinSize = Vector2.new(660, 460),
    MaxSize = Vector2.new(1280, 880),
    Gradient = true,
    CornerRadius = 8,
})

--============================================================================
-- TAB 1: GENERAL CONTROLS (Toggles, Checkboxes, Buttons, Steppers, Sliders)
--============================================================================
local GeneralTab = Window:AddTab({ Name = "General", Icon = "layout-grid" })

-- Column 1: Toggles & Checkboxes
local ToggleSection = GeneralTab:AddSection({
    Side = 1,
    Name = "Toggles & Switches",
    Icon = "square-check",
    IconStyle = "Tile",
    Subtext = "Interactive boolean switches with addons",
})

local MasterToggle = ToggleSection:AddToggle("MasterFeature", {
    Text = "Master System Switch",
    Subtext = "Controls whether the core features are enabled",
    Default = true,
    Icon = "power",
    Callback = function(Value)
        Library:Notify({
            Title = "Master Switch",
            Description = Value and "Subsystem activated" or "Subsystem suspended",
            Time = 1.5,
            Icon = Value and "circle-check" or "circle-alert",
        })
    end,
})

-- Attach ColorPicker and KeyPicker to Toggle
MasterToggle:AddColorPicker("MasterColor", {
    Title = "System Accent",
    Default = Color3.fromRGB(66, 135, 245),
    Transparency = 0,
    Callback = function(Col)
        print("[Astral] MasterColor changed to:", Col)
    end,
})

MasterToggle:AddKeyPicker("MasterKeybind", {
    Default = "RightShift",
    Mode = "Toggle", -- "Toggle" | "Hold" | "Always"
    Text = "Master Toggle Key",
    SyncToggleState = true,
})

local AutoRoutineToggle = ToggleSection:AddToggle("AutoRoutine", {
    Text = "Automated Routine",
    Subtext = "Runs periodic updates in background thread",
    Default = false,
    Icon = "refresh-cw",
    Callback = function(Value)
        print("[Astral] AutoRoutine set to:", Value)
    end,
})

-- Toggle with expandable settings panel
local AutoRoutineSettings = AutoRoutineToggle:AddSettings()
AutoRoutineSettings:AddSlider("RoutineInterval", {
    Text = "Tick Interval",
    Default = 100,
    Min = 20,
    Max = 1000,
    Suffix = " ms",
})
AutoRoutineSettings:AddToggle("RoutineSafeMode", {
    Text = "Enable Crash Safeguard",
    Default = true,
})

ToggleSection:AddDivider("Checkboxes & Methods")

local SilentCheckbox = ToggleSection:AddCheckbox("SilentExecution", {
    Text = "Silent Execution Mode",
    Subtext = "Hides console logs and on-screen popups",
    Default = false,
})

local VerboseCheckbox = ToggleSection:AddCheckbox("VerboseLogging", {
    Text = "Verbose Debug Telemetry",
    Default = true,
})

local MethodRow = ToggleSection:AddRow()
MethodRow:AddButton({
    Text = "Toggle Silent",
    Func = function()
        SilentCheckbox:SetValue(not SilentCheckbox.Value)
    end,
})
MethodRow:AddButton({
    Text = "Lock Verbose",
    Func = function()
        VerboseCheckbox:SetDisabled(not VerboseCheckbox.Disabled)
    end,
})

-- Column 1: Buttons Showcase
local ButtonSection = GeneralTab:AddSection({
    Side = 1,
    Name = "Action Buttons",
    Icon = "mouse-pointer",
    Subtext = "Standard, risky, and dynamically modified buttons",
})

ButtonSection:AddButton({
    Text = "Dispatch Info Notification",
    Func = function()
        Library:Notify({
            Title = "Notification Dispatch",
            Description = "Standard operational message received successfully.",
            Time = 2.5,
            Icon = "info",
        })
    end,
})

ButtonSection:AddButton({
    Text = "Purge Cache (Risky Action)",
    Risky = true,
    Func = function()
        Library:Notify({
            Title = "Cache Purged",
            Description = "All volatile runtime cache was safely cleared.",
            Time = 2,
            Icon = "triangle-alert",
        })
    end,
})

-- Column 2: Sliders & Numeric Controls
local SliderSection = GeneralTab:AddSection({
    Side = 2,
    Name = "Precision Sliders",
    Icon = "sliders-horizontal",
    IconStyle = "Tile",
    Subtext = "Accurate drag-bars with editable numeric value boxes",
})

local SpeedSlider = SliderSection:AddSlider("PlayerVelocity", {
    Text = "Movement Velocity",
    Subtext = "Player walkspeed modifier in studs per second",
    Icon = "zap",
    Default = 24,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Suffix = " studs/s",
    Editable = true,
    EditableStyle = "ValueBox", -- Click-to-type number box
    Callback = function(Value)
        print("[Astral] Movement Velocity:", Value)
    end,
})

local AngleSlider = SliderSection:AddSlider("FieldOfView", {
    Text = "Camera Field of View",
    Subtext = "Perspective angle of current viewport camera",
    Icon = "eye",
    Default = 70,
    Min = 50,
    Max = 120,
    Rounding = 0,
    Suffix = "°",
    Callback = function(Value)
        local Cam = workspace.CurrentCamera
        if Cam then
            Cam.FieldOfView = Value
        end
    end,
})

local FloatSlider = SliderSection:AddSlider("SmoothFactor", {
    Text = "Smoothing Coefficient",
    Subtext = "Precision decimal interpolation damping",
    Default = 0.65,
    Min = 0.05,
    Max = 1.00,
    Rounding = 2,
    Callback = function(Value)
        print("[Astral] Smooth factor:", Value)
    end,
})

SliderSection:AddDivider("Slider Method Controls")

local SliderControlsRow = SliderSection:AddRow()
SliderControlsRow:AddButton({
    Text = "Set Max = 300",
    Func = function()
        SpeedSlider:SetMax(300)
    end,
})
SliderControlsRow:AddButton({
    Text = "Set Min = 20",
    Func = function()
        SpeedSlider:SetMin(20)
    end,
})
SliderControlsRow:AddButton({
    Text = "Reset = 24",
    Func = function()
        SpeedSlider:SetValue(24)
    end,
})

-- Column 2: Numeric Steppers
local StepperSection = GeneralTab:AddSection({
    Side = 2,
    Name = "Numeric Steppers",
    Icon = "layers",
    Subtext = "Click to type directly or click/hold +/- buttons",
})

local BatchStepper = StepperSection:AddStepper("BatchSize", {
    Text = "Processing Batch Size",
    Subtext = "Click the number to type, or hold +/- buttons",
    Icon = "box",
    Default = 10,
    Min = 1,
    Max = 100,
    Increment = 1,
    Callback = function(Value)
        print("[Astral] Batch size updated:", Value)
    end,
})

local IntervalStepper = StepperSection:AddStepper("TickDelay", {
    Text = "Thread Tick Interval",
    Subtext = "Custom value text formatting with step 5",
    Icon = "clock",
    Default = 25,
    Min = 5,
    Max = 100,
    Increment = 5,
    Format = "%s ms",
})

local StepperRow = StepperSection:AddRow()
StepperRow:AddButton({
    Text = "Set Batch = 50",
    Func = function()
        BatchStepper:SetValue(50)
    end,
})
StepperRow:AddButton({
    Text = "Toggle Lock",
    Func = function()
        BatchStepper:SetDisabled(not BatchStepper.Disabled)
    end,
})

--============================================================================
-- TAB 2: DROPDOWNS & SELECTION (Single, Multi, Searchable, Settings)
--============================================================================
local DropdownTab = Window:AddTab({ Name = "Dropdowns", Icon = "list" })

local StandardDDSection = DropdownTab:AddSection({
    Side = 1,
    Name = "Single & Attached Settings",
    Icon = "list-ordered",
    IconStyle = "Tile",
    Subtext = "Dropdowns with right-aligned settings gear",
})

StandardDDSection:AddDropdown("GameDifficulty", {
    Text = "Difficulty Level",
    Subtext = "Determines enemy AI aggression and health",
    Values = { "Casual", "Normal", "Veteran", "Nightmare" },
    Default = "Normal",
    Callback = function(Value)
        Library:Notify({
            Title = "Difficulty Changed",
            Description = "Difficulty set to: " .. tostring(Value),
            Time = 1.5,
            Icon = "swords",
        })
    end,
})

-- Dropdown with :AddSettings() - gear on right, opens panel directly beneath
local PriorityDD = StandardDDSection:AddDropdown("TargetPriority", {
    Text = "Target Selection Priority",
    Subtext = "Click the gear on the right to customize filters",
    Values = { "Closest", "Lowest Health", "Highest Threat", "Random" },
    Default = "Closest",
})

local PrioritySettings = PriorityDD:AddSettings()
PrioritySettings:AddToggle("IncludeNPCs", {
    Text = "Include Non-Player Characters",
    Default = true,
    Callback = function(Val)
        Library:Notify({
            Title = "Target Filter",
            Description = Val and "NPC targeting active" or "Players only",
            Time = 1.5,
            Icon = "target",
        })
    end,
})
PrioritySettings:AddToggle("CheckVisibility", {
    Text = "Require Direct Line of Sight",
    Default = true,
})
PrioritySettings:AddSlider("MaxEngageRange", {
    Text = "Max Engagement Distance",
    Default = 300,
    Min = 50,
    Max = 1000,
    Suffix = " studs",
})

-- Column 2: Searchable & Multi-Select Dropdowns
local MultiDDSection = DropdownTab:AddSection({
    Side = 2,
    Name = "Searchable & Multi-Selection",
    Icon = "search",
    IconStyle = "Tile",
    Subtext = "Search field with enlarged All & Clear quick actions",
})

local HitboxDropdown = MultiDDSection:AddDropdown("TargetHitboxes", {
    Text = "Targeted Hitbox Regions",
    Subtext = "Multiple selection with instant multi-toggle",
    Values = { "Head", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "HumanoidRootPart" },
    Multi = true,
    Searchable = true,
    Default = { "Head", "UpperTorso" },
    Callback = function(Values)
        local Selected = {}
        for Key, Bool in pairs(Values) do
            if Bool then table.insert(Selected, Key) end
        end
        print("[Astral] Selected Hitboxes:", table.concat(Selected, ", "))
    end,
})

local ServerRegionDropdown = MultiDDSection:AddDropdown("ServerRegion", {
    Text = "Matchmaking Server Region",
    Subtext = "Searchable single-select region routing",
    Values = { "US-East (N. Virginia)", "US-West (Oregon)", "EU-Central (Frankfurt)", "EU-West (London)", "Asia-East (Tokyo)", "Asia-Southeast (Singapore)", "Australia (Sydney)" },
    Searchable = true,
    Default = "US-East (N. Virginia)",
    Callback = function(Value)
        Library:Notify({
            Title = "Region Routing",
            Description = "Routed to: " .. tostring(Value),
            Time = 1.5,
            Icon = "globe",
        })
    end,
})

MultiDDSection:AddDivider("Dropdown API Methods")

local DDMethodRow = MultiDDSection:AddRow()
DDMethodRow:AddButton({
    Text = "Select Head Only",
    Func = function()
        HitboxDropdown:SetValue({ Head = true })
    end,
})
DDMethodRow:AddButton({
    Text = "Clear Selection",
    Func = function()
        HitboxDropdown:SetValue({})
    end,
})
DDMethodRow:AddButton({
    Text = "Toggle Lock",
    Func = function()
        HitboxDropdown:SetDisabled(not HitboxDropdown.Disabled)
    end,
})

--============================================================================
-- TAB 3: ROWS & COMBINATIONS (Presets, IconButtons, Flexible Widths)
--============================================================================
local RowsTab = Window:AddTab({ Name = "Rows & Combos", Icon = "columns-2" })

local PresetSection = RowsTab:AddSection({
    Side = 1,
    Name = "Interactive Preset Manager",
    Icon = "sliders-horizontal",
    IconStyle = "Tile",
    Subtext = "Functional [+], [pencil], and [trash] action buttons in a row",
})

-- Preset state storage
local PresetList = { "Default Profile", "Rage Mode", "Legit Play", "Exploration" }
local CurrentPreset = PresetList[1]

local PresetRow = PresetSection:AddRow()
local PresetDD = PresetRow:AddDropdown("ActivePreset", {
    Values = PresetList,
    Default = 1,
    Callback = function(Val)
        CurrentPreset = Val
        print("[Astral] Switched active profile to:", Val)
    end,
})

-- [square-pen] Rename preset
PresetRow:AddIconButton({
    Icon = "square-pen",
    Tooltip = "Rename selected profile",
    Func = function()
        if not CurrentPreset then return end
        local Renamed = CurrentPreset .. " (Edited)"
        for Idx, Item in ipairs(PresetList) do
            if Item == CurrentPreset then
                PresetList[Idx] = Renamed
                break
            end
        end
        CurrentPreset = Renamed
        PresetDD:SetValues(PresetList)
        PresetDD:SetValue(Renamed)
        Library:Notify({
            Title = "Preset Renamed",
            Description = "Updated profile title to: " .. Renamed,
            Time = 2,
            Icon = "square-pen",
        })
    end,
})

-- [trash-2] Delete preset
PresetRow:AddIconButton({
    Icon = "trash-2",
    Tooltip = "Delete current profile",
    Risky = true,
    Func = function()
        if #PresetList <= 1 then
            Library:Notify({
                Title = "Cannot Delete",
                Description = "At least one profile must remain available.",
                Time = 2,
                Icon = "circle-alert",
            })
            return
        end
        local Old = CurrentPreset
        for Idx, Item in ipairs(PresetList) do
            if Item == Old then
                table.remove(PresetList, Idx)
                break
            end
        end
        CurrentPreset = PresetList[1]
        PresetDD:SetValues(PresetList)
        PresetDD:SetValue(CurrentPreset)
        Library:Notify({
            Title = "Preset Removed",
            Description = "Deleted profile: " .. Old,
            Time = 2,
            Icon = "trash-2",
        })
    end,
})

-- [plus] Add new preset
PresetRow:AddIconButton({
    Icon = "plus",
    Tooltip = "Create new profile",
    Func = function()
        local NewName = "Profile " .. (#PresetList + 1)
        table.insert(PresetList, NewName)
        CurrentPreset = NewName
        PresetDD:SetValues(PresetList)
        PresetDD:SetValue(NewName)
        Library:Notify({
            Title = "Profile Created",
            Description = "Created and selected: " .. NewName,
            Time = 2,
            Icon = "circle-check",
        })
    end,
})

PresetSection:AddDivider("Row Layout Width Modes")

local WidthRow = PresetSection:AddRow()
WidthRow:AddButton({ Text = "Fill (x1)" })
WidthRow:AddButton({ Text = "Fill (x2)", Weight = 2 })
WidthRow:AddButton({ Text = "110px", Width = 110 })

local MixedRow = PresetSection:AddRow()
MixedRow:AddIconButton({ Icon = "plus", Text = "Auto Item", Width = "Auto" })
MixedRow:AddIconButton({ Icon = "circle-check", Text = "Done", Width = "Auto" })
MixedRow:AddDropdown("MixedDD", { Values = { "Takes remainder space", "Dynamic flex container" }, Default = 1 })

-- Column 2: IconButton Showcase
local IconButtonSection = RowsTab:AddSection({
    Side = 2,
    Name = "IconButton Showcase",
    Icon = "mouse-pointer-2",
    Subtext = "Icon-only & centered Icon + Text buttons",
})

local ActionIconButton = IconButtonSection:AddIconButton("MainActionBtn", {
    Icon = "settings",
    Text = "Settings Command",
    Tooltip = "Executes settings subroutine",
    Func = function()
        Library:Notify({
            Title = "IconButton Executed",
            Description = "Clean horizontal alignment inside button container!",
            Time = 2,
            Icon = "circle-check",
        })
    end,
})

IconButtonSection:AddIconButton({
    Icon = "lock",
    Text = "Locked Subroutine",
    Disabled = true,
    DisabledTooltip = "This command is currently locked by permissions.",
})

IconButtonSection:AddDivider("Dynamic Element Methods")

IconButtonSection:AddButton({
    Text = "Toggle Button Disable State",
    Func = function()
        ActionIconButton:SetDisabled(not ActionIconButton.Disabled)
    end,
})

IconButtonSection:AddButton({
    Text = "Cycle Button Icon & Text",
    Func = function()
        local Pool = {
            { Icon = "zap", Text = "Turbo Mode" },
            { Icon = "shield", Text = "Defense Matrix" },
            { Icon = "star", Text = "Favorite Action" },
            { Icon = "settings", Text = "Settings Command" },
        }
        local Pick = Pool[math.random(1, #Pool)]
        ActionIconButton:SetIcon(Pick.Icon)
        ActionIconButton:SetText(Pick.Text)
    end,
})

--============================================================================
-- TAB 4: DATA & TABLES (Data Tables, Priority Ordering, Inputs)
--============================================================================
local DataTab = Window:AddTab({ Name = "Data & Tables", Icon = "table" })

local TableSection = DataTab:AddSection({
    Side = 1,
    Name = "Session Statistics Table",
    Icon = "chart-column",
    IconStyle = "Tile",
    Subtext = "Clean column alignment, zero border bleed, row selection",
})

local SessionTable = TableSection:AddTable("StatsTable", {
    Text = "Match Overview",
    Subtext = "Click any row to inspect detail record",
    Columns = {
        { Name = "Metric", Width = "Auto" },
        { Name = "Score", Align = "Right", Width = 65 },
        { Name = "Evaluation", Weight = 2 },
    },
    Rows = {
        { "Eliminations", 24, { Text = "MVP performance", Color = Color3.fromRGB(100, 255, 120) } },
        { "Deaths", 4, { Text = "Low casualties", Color = Color3.fromRGB(255, 160, 100) } },
        { "Assists", 18, { Text = "High team synergy", Icon = "circle-check" } },
        { "Objective Time", 312, { Text = "Point captured", Icon = "clock" } },
    },
    Selectable = true,
    MaxHeight = 160,
    Callback = function(Index, Row)
        if Row then
            Library:Notify({
                Title = "Row Selected",
                Description = string.format("%s: %s (%s)", tostring(Row[1]), tostring(Row[2]), typeof(Row[3]) == "table" and Row[3].Text or tostring(Row[3])),
                Time = 2,
            })
        end
    end,
})

local TableActionRow = TableSection:AddRow()
TableActionRow:AddButton({
    Text = "Add Stat Row",
    Func = function()
        local Metrics = { "Revives", "Headshots", "Damage Dealt", "Accuracy", "Heals" }
        local Pick = Metrics[math.random(1, #Metrics)]
        SessionTable:AddRow({ Pick, math.random(10, 500), "Logged event" })
    end,
})
TableActionRow:AddButton({
    Text = "Sort Score (Desc)",
    Func = function()
        SessionTable:Sort(2, true)
    end,
})

TableSection:AddButton({
    Text = "Reset Table Rows",
    Func = function()
        SessionTable:SetRows({
            { "Eliminations", 0, "Fresh session" },
            { "Deaths", 0, "No deaths" },
            { "Assists", 0, "Ready" },
        })
    end,
})

-- Column 2: Reorderable Priority List & Text Inputs
local PrioritySection = DataTab:AddSection({
    Side = 2,
    Name = "Execution Priority List",
    Icon = "list-ordered",
    Subtext = "Draggable reordering hierarchy",
})

PrioritySection:AddPriorityList("TaskOrder", {
    Text = "Subsystem Execution Order",
    Items = {
        { Id = "aimbot", Name = "Target Acquisition", Value = "Priority 1" },
        { Id = "wallcheck", Name = "Raycast Occlusion", Value = "Priority 2" },
        { Id = "esp", Name = "Viewport Overlay", Value = "Priority 3" },
        { Id = "telemetry", Name = "Telemetry Ping", Value = "Priority 4" },
    },
    Callback = function(Order)
        print("[Astral] Reordered priority sequence:", table.concat(Order, " -> "))
    end,
})

local InputSection = DataTab:AddSection({
    Side = 2,
    Name = "Text Inputs",
    Icon = "type",
    Subtext = "Subtext alignment & validation",
})

InputSection:AddInput("TargetPlayerName", {
    Text = "Target Username",
    Subtext = "Subtext is tightly aligned with vertically centered icon",
    Icon = "user",
    Placeholder = "Enter player username...",
    Callback = function(Value)
        print("[Astral] Target username set to:", Value)
    end,
})

InputSection:AddInput("PortNumber", {
    Text = "Telemetry Port",
    Numeric = true,
    Placeholder = "e.g. 8080",
    Default = "8080",
})

--============================================================================
-- TAB 5: DIALOGS & OVERLAYS (Modals, Buttons, Draggable Floating Windows)
--============================================================================
local OverlayTab = Window:AddTab({ Name = "Overlays", Icon = "app-window" })

local DialogSection = OverlayTab:AddSection({
    Side = 1,
    Name = "Solid Confirmation Dialogs",
    Icon = "triangle-alert",
    IconStyle = "Tile",
    Subtext = "Opaque modals with functional action buttons",
})

DialogSection:AddButton({
    Text = "Open Confirmation Modal",
    Func = function()
        local Dialog = Window:AddDialog("ConfirmReset", {
            Title = "Reset Configuration Profile?",
            Description = "Are you sure you want to reset all active settings back to their defaults? This action cannot be undone.",
            AutoDismiss = false,
        })

        Dialog:AddFooterButton("Cancel", {
            Text = "Cancel",
            Callback = function()
                Dialog:Dismiss()
            end,
        })

        Dialog:AddFooterButton("Confirm", {
            Text = "Confirm Reset",
            Callback = function()
                Dialog:Dismiss()
                Library:Notify({
                    Title = "Settings Reset",
                    Description = "Configuration restored to initial defaults.",
                    Time = 2,
                    Icon = "circle-check",
                })
            end,
        })
    end,
})

DialogSection:AddButton({
    Text = "Open Save Profile Modal",
    Func = function()
        local Dialog = Window:AddDialog("SaveModal", {
            Title = "Save Profile",
            Description = "Choose how you would like to store your workspace configuration.",
            AutoDismiss = true,
        })
        Dialog:AddFooterButton("Cloud", {
            Text = "Save to Cloud",
            Callback = function()
                Library:Notify({
                    Title = "Cloud Storage",
                    Description = "Profile synced to remote storage.",
                    Time = 2,
                    Icon = "cloud",
                })
            end,
        })
        Dialog:AddFooterButton("Local", {
            Text = "Save to Disk",
            Callback = function()
                Library:Notify({
                    Title = "Local Storage",
                    Description = "Profile written to local file.",
                    Time = 2,
                    Icon = "hard-drive",
                })
            end,
        })
    end,
})

local DraggableSection = OverlayTab:AddSection({
    Side = 2,
    Name = "Draggable Floating Window",
    Icon = "move",
    Subtext = "Independent floating controls panel",
})

DraggableSection:AddButton({
    Text = "Spawn Quick Actions Mini Window",
    Func = function()
        local _Holder, _Raw, MenuContainer = Library:AddDraggableMenu("Quick Actions")
        MenuContainer:AddLabel({ Text = "Independent floating tool panel" })
        MenuContainer:AddToggle("MiniFastHeal", { Text = "Rapid Regen", Default = true })
        MenuContainer:AddSlider("MiniBoost", { Text = "Boost Factor", Default = 50, Min = 0, Max = 100 })
        MenuContainer:AddButton({
            Text = "Ping Server",
            Func = function()
                Library:Notify({ Title = "Ping", Description = "Roundtrip latency: 24ms", Time = 1.5, Icon = "zap" })
            end,
        })
    end,
})

--============================================================================
-- TAB 6: VISUAL SETTINGS & THEMES (ThemeManager, SaveManager, Transparency)
--============================================================================
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local VisualSection = SettingsTab:AddSection({
    Side = 1,
    Name = "Visual Customization",
    Icon = "palette",
    IconStyle = "Tile",
    Subtext = "Unified transparency, subtle dark slate blue gradient",
})

VisualSection:AddSlider("WindowTransparency", {
    Text = "Window Transparency",
    Subtext = "Synchronized across TopBar, Sidebar, and Sections",
    Default = 0,
    Min = 0,
    Max = 0.75,
    Rounding = 2,
    Callback = function(Val)
        Library:SetWindowTransparency(Val)
    end,
})

VisualSection:AddToggle("GradientToggle", {
    Text = "Smooth Ambient Gradient",
    Subtext = "Subtle dark slate blue undertone",
    Default = true,
    Callback = function(Val)
        Library:SetGradientsEnabled(Val)
    end,
})

VisualSection:AddSlider("GradientAngle", {
    Text = "Gradient Angle",
    Default = 45,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Suffix = "°",
    Callback = function(Val)
        Library.GradientRotation = Val
        Library:UpdateWindowStyle()
    end,
})

local DisplaySection = SettingsTab:AddSection({
    Side = 2,
    Name = "Display & Scaling",
    Icon = "sliders-horizontal",
    Subtext = "Responsive UI scaling",
})

DisplaySection:AddSlider("UIScaleSlider", {
    Text = "UI Scale Multiplier",
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
        Library:Notify({ Title = "Display", Description = "UI Scale now adapts to screen size automatically.", Time = 3 })
    end,
})

-- Apply ThemeManager & SaveManager to Settings Tab
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

-- Final notification confirming successful load
Library:Notify({
    Title = "Astral UI Loaded",
    Description = "Reference showcase ready • All elements operational.",
    Time = 3,
    Icon = "circle-check",
    IconColor = Color3.fromRGB(100, 255, 120),
})

print("[Astral] Comprehensive Showcase loaded successfully • Build:", Library.BuildId or Library.VERSION or "Dev")

return {
    Window = Window,
    Library = Library,
    SaveManager = SaveManager,
    ThemeManager = ThemeManager,
}
