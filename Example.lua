--============================================================================
-- ASTRAL UI — OFFICIAL SHOWCASE & REFERENCE
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

local Window = Library:CreateWindow({
    Title = "Astral UI",
    Subtitle = "Development Showcase",
    TitleAlignment = "Left",
    Icon = "AstralIcon",
    Footer = "Astral UI • github.com/inCythe/AstralDev",
    FooterLeft = "Build 2.0-dev",
    FooterRight = "Luau Client",
    Size = UDim2.fromOffset(800, 560),
    Center = true,
    Resizable = true,
    MinSize = Vector2.new(640, 440),
    MaxSize = Vector2.new(1200, 850),
    Gradient = true,
    CornerRadius = 8,
})

--============================================================================
-- TAB 1: GENERAL (Basic controls, toggles, steppers, sliders)
--============================================================================
local GeneralTab = Window:AddTab({ Name = "General", Icon = "layout-grid" })

local ToggleSection = GeneralTab:AddSection({
    Side = 1,
    Name = "Toggles & Checkboxes",
    Icon = "check-square",
    IconStyle = "Tile",
    Subtext = "Interactive state switches",
})

local MasterToggle = ToggleSection:AddToggle("MasterFeature", {
    Text = "Master Switch",
    Subtext = "Toggles core subsystem on or off",
    Default = true,
    Icon = "power",
    Callback = function(Value)
        Library:Notify({
            Title = "Master Switch",
            Description = Value and "Features enabled" or "Features disabled",
            Time = 1.5,
        })
    end,
})

ToggleSection:AddToggle("AutoFarm", {
    Text = "Auto Routine",
    Subtext = "Simulates scheduled background task",
    Default = false,
    Icon = "refresh-cw",
    Callback = function(Value)
        Library:Notify({
            Title = "Auto Routine",
            Description = Value and "Routine started" or "Routine paused",
            Time = 1.5,
        })
    end,
})

ToggleSection:AddCheckbox("SilentMode", {
    Text = "Silent Execution",
    Default = true,
    Callback = function(Value)
        print("[Astral] Silent mode:", Value)
    end,
})

ToggleSection:AddCheckbox("DebugLogs", {
    Text = "Verbose Debug Logging",
    Default = false,
})

local ButtonSection = GeneralTab:AddSection({
    Side = 1,
    Name = "Action Buttons",
    Icon = "mouse-pointer",
})

ButtonSection:AddButton({
    Text = "Send Info Notification",
    Func = function()
        Library:Notify({
            Title = "System Notice",
            Description = "This is a standard informational notification.",
            Time = 2.5,
            Icon = "info",
        })
    end,
})

ButtonSection:AddButton({
    Text = "Toggle Master Switch",
    Func = function()
        MasterToggle:SetValue(not MasterToggle.Value)
    end,
})

-- Right column of General Tab
local SliderSection = GeneralTab:AddSection({
    Side = 2,
    Name = "Sliders & Values",
    Icon = "sliders",
    IconStyle = "Tile",
    Subtext = "Numeric adjustments with vertical icon centering",
})

local WalkspeedSlider = SliderSection:AddSlider("WalkSpeed", {
    Text = "Movement Speed",
    Subtext = "Adjust player velocity multiplier",
    Icon = "zap",
    Default = 16,
    Min = 16,
    Max = 150,
    Rounding = 0,
    Suffix = " studs/s",
    Callback = function(Value)
        print("[Astral] WalkSpeed set to:", Value)
    end,
})

local FOVSlider = SliderSection:AddSlider("FieldOfView", {
    Text = "Field of View",
    Subtext = "Camera viewport angle",
    Icon = "eye",
    Default = 70,
    Min = 60,
    Max = 120,
    Rounding = 0,
    Suffix = " deg",
    Callback = function(Value)
        local Cam = workspace.CurrentCamera
        if Cam then
            Cam.FieldOfView = Value
        end
    end,
})

local StepperSection = GeneralTab:AddSection({
    Side = 2,
    Name = "Numeric Steppers",
    Icon = "layers",
})

local ItemStepper = StepperSection:AddStepper("BatchCount", {
    Text = "Batch Amount",
    Subtext = "Items processed per execution tick",
    Icon = "box",
    Default = 5,
    Min = 1,
    Max = 50,
    Increment = 1,
    Callback = function(Value)
        Library:Notify({
            Title = "Batch Updated",
            Description = "New batch size: " .. tostring(Value),
            Time = 1.5,
        })
    end,
})

StepperSection:AddButton({
    Text = "Reset Batch to 5",
    Func = function()
        ItemStepper:SetValue(5)
    end,
})

--============================================================================
-- TAB 2: DROPDOWNS & SELECTION
--============================================================================
local DropdownTab = Window:AddTab({ Name = "Dropdowns", Icon = "list" })

local StandardDDSection = DropdownTab:AddSection({
    Side = 1,
    Name = "Single & Settings Dropdowns",
    Icon = "list-ordered",
})

StandardDDSection:AddDropdown("GameDifficulty", {
    Text = "Difficulty Level",
    Values = { "Casual", "Normal", "Veteran", "Nightmare" },
    Default = "Normal",
    Callback = function(Value)
        Library:Notify({
            Title = "Difficulty Changed",
            Description = "Set to " .. tostring(Value),
            Time = 1.5,
        })
    end,
})

-- Dropdown with :AddSettings() working properly with right-side gear
local SettingsDD = StandardDDSection:AddDropdown("TargetPriority", {
    Text = "Target Priority",
    Values = { "Closest", "Lowest Health", "Highest Threat", "Random" },
    Default = "Closest",
})
local DDSettings = SettingsDD:AddSettings()
DDSettings:AddToggle("IncludeNPCs", {
    Text = "Include NPC Targets",
    Default = true,
    Callback = function(Val)
        Library:Notify({
            Title = "Target Setting",
            Description = "NPC Targets: " .. (Val and "ON" or "OFF"),
            Time = 1.5,
        })
    end,
})
DDSettings:AddToggle("WallCheck", {
    Text = "Line of Sight Check",
    Default = true,
})
DDSettings:AddSlider("MaxDistance", {
    Text = "Max Range",
    Default = 250,
    Min = 50,
    Max = 1000,
    Suffix = " studs",
})

local MultiDDSection = DropdownTab:AddSection({
    Side = 2,
    Name = "Searchable & Multi Dropdown",
    Icon = "search",
    IconStyle = "Tile",
    Subtext = "Full height search bar with prominent All / Clear buttons",
})

local RolesDropdown = MultiDDSection:AddDropdown("SelectedRoles", {
    Text = "Target Hitboxes",
    Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" },
    Multi = true,
    Searchable = true,
    Default = { "Head", "Torso" },
    Callback = function(Values)
        local Selected = {}
        for Key, Bool in pairs(Values) do
            if Bool then table.insert(Selected, Key) end
        end
        print("[Astral] Selected Hitboxes:", table.concat(Selected, ", "))
    end,
})

local RegionDropdown = MultiDDSection:AddDropdown("RegionSearch", {
    Text = "Server Region",
    Values = { "US-East", "US-West", "EU-Central", "EU-West", "Asia-East", "Asia-Southeast", "Australia" },
    Searchable = true,
    Default = "US-East",
    Callback = function(Value)
        Library:Notify({
            Title = "Server Region",
            Description = "Selected region: " .. tostring(Value),
            Time = 1.5,
        })
    end,
})

--============================================================================
-- TAB 3: ROWS & COMBINATIONS (Presets, IconButtons, Mixed Widths)
--============================================================================
local RowsTab = Window:AddTab({ Name = "Rows & Combos", Icon = "columns" })

local PresetSection = RowsTab:AddSection({
    Side = 1,
    Name = "Interactive Preset Manager",
    Icon = "sliders-horizontal",
    IconStyle = "Tile",
    Subtext = "Fully functional [+], [pencil], and [trash] preset actions",
})

-- Preset state storage
local PresetList = { "Default Profile", "Rage Mode", "Legit Play" }
local CurrentPreset = PresetList[1]

local PresetRow = PresetSection:AddRow()
local PresetDD = PresetRow:AddDropdown("ActivePreset", {
    Values = PresetList,
    Default = 1,
    Callback = function(Val)
        CurrentPreset = Val
        print("[Astral] Switched preset to:", Val)
    end,
})

-- [pencil] Rename preset
PresetRow:AddIconButton({
    Icon = "pencil",
    Tooltip = "Rename selected preset",
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
            Description = "Renamed to: " .. Renamed,
            Time = 2,
            Icon = "edit",
        })
    end,
})

-- [trash-2] Delete preset
PresetRow:AddIconButton({
    Icon = "trash-2",
    Tooltip = "Delete current preset",
    Risky = true,
    Func = function()
        if #PresetList <= 1 then
            Library:Notify({
                Title = "Cannot Delete",
                Description = "At least one preset must remain active.",
                Time = 2,
                Icon = "alert-circle",
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
            Title = "Preset Deleted",
            Description = "Deleted: " .. Old,
            Time = 2,
            Icon = "trash",
        })
    end,
})

-- [+] Add new preset
PresetRow:AddIconButton({
    Icon = "plus",
    Tooltip = "Create new preset",
    Func = function()
        local NewName = "Preset " .. (#PresetList + 1)
        table.insert(PresetList, NewName)
        CurrentPreset = NewName
        PresetDD:SetValues(PresetList)
        PresetDD:SetValue(NewName)
        Library:Notify({
            Title = "Preset Created",
            Description = "Created and selected: " .. NewName,
            Time = 2,
            Icon = "check",
        })
    end,
})

PresetSection:AddDivider("Row Width Modes")

local WidthRow = PresetSection:AddRow()
WidthRow:AddButton({ Text = "Fill (x1)" })
WidthRow:AddButton({ Text = "Fill (x2)", Weight = 2 })
WidthRow:AddButton({ Text = "100px", Width = 100 })

local AutoRow = PresetSection:AddRow()
AutoRow:AddIconButton({ Icon = "plus", Text = "Auto", Width = "Auto" })
AutoRow:AddIconButton({ Icon = "check", Text = "Confirm", Width = "Auto" })
AutoRow:AddDropdown("AutoFillDD", { Values = { "Takes remaining space", "Responsive item" }, Default = 1 })

local IconButtonSection = RowsTab:AddSection({
    Side = 2,
    Name = "IconButton Showcase",
    Icon = "mouse-pointer-2",
    Subtext = "Icon-only & Icon+Text with proper horizontal layout",
})

local ShowcasedBtn = IconButtonSection:AddIconButton("ShowcaseAction", {
    Icon = "settings",
    Text = "Settings Action",
    Tooltip = "Click to execute action",
    Func = function()
        Library:Notify({
            Title = "IconButton Clicked",
            Description = "Clean horizontal alignment inside button!",
            Time = 2,
        })
    end,
})

IconButtonSection:AddIconButton({
    Icon = "lock",
    Text = "Disabled State",
    Disabled = true,
    DisabledTooltip = "Feature currently locked",
})

IconButtonSection:AddButton({
    Text = "Toggle Button Disable State",
    Func = function()
        ShowcasedBtn:SetDisabled(not ShowcasedBtn.Disabled)
    end,
})

IconButtonSection:AddButton({
    Text = "Change Button Icon",
    Func = function()
        local Icons = { "zap", "shield", "star", "settings" }
        local RandomIcon = Icons[math.random(1, #Icons)]
        ShowcasedBtn:SetIcon(RandomIcon)
        ShowcasedBtn:SetText("Mode: " .. RandomIcon)
    end,
})

--============================================================================
-- TAB 4: DATA & TABLES
--============================================================================
local DataTab = Window:AddTab({ Name = "Data & Tables", Icon = "table" })

local TableSection = DataTab:AddSection({
    Side = 1,
    Name = "Session Statistics Table",
    Icon = "bar-chart-2",
    IconStyle = "Tile",
    Subtext = "Accurate header alignment and column spacing",
})

local SessionTable = TableSection:AddTable("StatsTable", {
    Text = "Match Overview",
    Subtext = "Click any row to view details",
    Columns = {
        { Name = "Metric", Width = "Auto" },
        { Name = "Score", Align = "Right", Width = 65 },
        { Name = "Evaluation", Weight = 2 },
    },
    Rows = {
        { "Eliminations", 24, { Text = "MVP performance", Color = Color3.fromRGB(100, 255, 120) } },
        { "Deaths", 4, { Text = "Low casualties", Color = Color3.fromRGB(255, 160, 100) } },
        { "Assists", 18, { Text = "High team synergy", Icon = "user-check" } },
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

TableSection:AddButton({
    Text = "Add Random Stat Row",
    Func = function()
        local Metrics = { "Revives", "Headshots", "Damage Dealt", "Accuracy", "Heals" }
        local Pick = Metrics[math.random(1, #Metrics)]
        SessionTable:AddRow({ Pick, math.random(10, 500), "Logged event" })
    end,
})

TableSection:AddButton({
    Text = "Sort by Score (Descending)",
    Func = function()
        SessionTable:Sort(2, true)
    end,
})

TableSection:AddButton({
    Text = "Clear & Reset Stats",
    Func = function()
        SessionTable:SetRows({
            { "Eliminations", 0, "Fresh session" },
            { "Deaths", 0, "No deaths" },
            { "Assists", 0, "Ready" },
        })
    end,
})

local PrioritySection = DataTab:AddSection({
    Side = 2,
    Name = "Execution Priority List",
    Icon = "list-ordered",
    Subtext = "Draggable priority reordering",
})

local PriorityList = PrioritySection:AddPriorityList("TaskOrder", {
    Text = "Routine Hierarchy",
    Items = {
        { Id = "aimbot", Name = "Target Acquisition", Value = "Priority 1" },
        { Id = "wallcheck", Name = "Raycast Occlusion", Value = "Priority 2" },
        { Id = "esp", Name = "Viewport Overlay", Value = "Priority 3" },
        { Id = "misc", Name = "Telemetry Ping", Value = "Priority 4" },
    },
    Callback = function(Order)
        print("[Astral] Reordered priority list:", table.concat(Order, " -> "))
    end,
})

--============================================================================
-- TAB 5: DIALOGS & OVERLAYS
--============================================================================
local OverlayTab = Window:AddTab({ Name = "Overlays", Icon = "app-window" })

local DialogSection = OverlayTab:AddSection({
    Side = 1,
    Name = "Solid Confirmation Dialog",
    Icon = "alert-triangle",
    IconStyle = "Tile",
    Subtext = "Opaque modal with backdrop scrim",
})

DialogSection:AddButton({
    Text = "Open Confirmation Dialog",
    Func = function()
        local Dialog = Window:AddDialog("ConfirmReset", {
            Title = "Reset Configuration?",
            Description = "Are you sure you want to reset all active settings back to their default values? This action cannot be reversed.",
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
                    Description = "Configuration restored to defaults.",
                    Time = 2,
                    Icon = "check-circle",
                })
            end,
        })
    end,
})

DialogSection:AddButton({
    Text = "Trigger Multi-Action Modal",
    Func = function()
        local Dialog = Window:AddDialog("ActionModal", {
            Title = "Save Preset",
            Description = "Choose how you would like to save the current workspace profile.",
            AutoDismiss = true,
        })
        Dialog:AddFooterButton("Cloud", {
            Text = "Save to Cloud",
            Callback = function()
                Library:Notify({ Title = "Cloud Sync", Description = "Synced to cloud.", Time = 2 })
            end,
        })
        Dialog:AddFooterButton("Local", {
            Text = "Save Locally",
            Callback = function()
                Library:Notify({ Title = "Local Save", Description = "Written to disk.", Time = 2 })
            end,
        })
    end,
})

local DraggableSection = OverlayTab:AddSection({
    Side = 2,
    Name = "Draggable Floating Window",
    Icon = "move",
})

DraggableSection:AddButton({
    Text = "Spawn Mini Window",
    Func = function()
        local _Holder, _Raw, MenuContainer = Library:AddDraggableMenu("Quick Actions")
        MenuContainer:AddLabel({ Text = "Independent floating panel" })
        MenuContainer:AddToggle("MiniFastHeal", { Text = "Rapid Regen", Default = true })
        MenuContainer:AddSlider("MiniBoost", { Text = "Boost Factor", Default = 50, Min = 0, Max = 100 })
        MenuContainer:AddButton({
            Text = "Ping Server",
            Func = function()
                Library:Notify({ Title = "Ping", Description = "Latency: 28ms", Time = 1.5 })
            end,
        })
    end,
})

--============================================================================
-- TAB 6: SETTINGS & THEMES
--============================================================================
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local ThemeSection = SettingsTab:AddSection({
    Side = 1,
    Name = "Visual Customization",
    Icon = "palette",
    IconStyle = "Tile",
    Subtext = "Consistent panel transparency & smooth gradient blending",
})

-- Transparency control
ThemeSection:AddSlider("UiTransparency", {
    Text = "Window Transparency",
    Subtext = "Consistent across TopBar, Sidebar, and Sections",
    Default = 0,
    Min = 0,
    Max = 0.75,
    Rounding = 2,
    Callback = function(Val)
        Library:SetWindowTransparency(Val)
    end,
})

ThemeSection:AddToggle("GradientToggle", {
    Text = "Smooth Ambient Gradient",
    Subtext = "Subtle dark slate blue undertone",
    Default = true,
    Callback = function(Val)
        Library:SetGradientsEnabled(Val)
    end,
})

ThemeSection:AddSlider("GradientAngle", {
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

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

-- Print loaded build info
print("[Astral] Showcase loaded cleanly • Build:", Library.BuildId or Library.VERSION or "Dev")
