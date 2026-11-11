local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end
local Mouse = LocalPlayer and cloneref(LocalPlayer:GetMouse()) or { Hit = CFrame.new(), Target = nil }

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

--// Forward declarations populated further down (animation system) \\--
local TransparencyCache = {}
local ActiveTabTweens = setmetatable({}, { __mode = "k" })

local BaseURL = "https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139119720835185,
        Path = "Astral/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
        BuiltIn = true,
    },

    SaturationMap = {
        RobloxId = 105123850473267,
        Path = "Astral/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
        BuiltIn = true,
    },

    LoadingIcon = {
        RobloxId = 134481797305372,
        Path = "Astral/assets/LoadingIcon.png",
        URL = BaseURL .. "assets/LoadingIcon.png",

        Id = nil,
        BuiltIn = true,
    },

    CheckIcon = {
        RobloxId = 121540767860106,
        Path = "Astral/assets/CheckIcon.png",
        URL = BaseURL .. "assets/CheckIcon.png",

        Id = nil,
        BuiltIn = true,
    },

    AstralIcon = {
        RobloxId = 80158178764553,
        Path = "Astral/assets/AstralIcon.png",
        URL = BaseURL .. "assets/AstralIcon.png",

        Id = nil,
        BuiltIn = true,
    },

    DiscordIcon = {
        RobloxId = 79452348456435,
        Path = "Astral/assets/DiscordIcon.png",
        URL = BaseURL .. "assets/DiscordIcon.png",

        Id = nil,
        BuiltIn = true,
    },
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in Segments do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(
        AssetName: string,
        RobloxAssetId: number,
        URL: string,
        ForceRedownload: boolean?
    )
        if CustomImageManagerAssets[AssetName] ~= nil then

            return
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Astral/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.IsBuiltIn(AssetName: string)
        local AssetData = CustomImageManagerAssets[AssetName]
        return AssetData ~= nil and AssetData.BuiltIn == true
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then

            if isfile and not isfile(AssetData.Path) then
                local Ok = CustomImageManager.DownloadAsset(AssetName)

                if not Ok or not isfile(AssetData.Path) then
                    return AssetID
                end
            end

            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID and NewID ~= "" then
                AssetID = NewID

                AssetData.Id = AssetID
            end

        end

        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then

            local ExistingOk = false
            pcall(function()
                local Content = readfile(AssetData.Path)

                local Sig = Content:sub(1, 4)
                ExistingOk = (Sig:sub(1,1) == "\x89" and Sig:sub(2,4) == "PNG")
                    or (Sig:sub(1,2) == "\xFF\xD8")
                    or (Sig:sub(1,4) == "RIFF")
                    or (Sig:sub(1,3) == "GIF")
            end)
            if ExistingOk then
                return true, nil
            end

            pcall(delfile, AssetData.Path)
            AssetData.Id = nil
        end

        AssetData.Id = nil

        local Content = nil
        local DownloadSuccess, DownloadError = pcall(function()
            Content = game:HttpGet(AssetData.URL)
        end)

        if not DownloadSuccess or not Content or Content == "" then
            return false, DownloadError or "empty response"
        end

        local Sig = Content:sub(1, 4)
        local IsValidImage = (Sig:sub(1,1) == "\x89" and Sig:sub(2,4) == "PNG")
            or (Sig:sub(1,2) == "\xFF\xD8")
            or (Sig:sub(1,4) == "RIFF")
            or (Sig:sub(1,3) == "GIF")

        if not IsValidImage then
            return false, "downloaded content is not a valid image (URL may be invalid)"
        end

        local WriteSuccess, WriteError = pcall(function()
            writefile(AssetData.Path, Content)
        end)

        if WriteSuccess and not isfile(AssetData.Path) then
            return false, "writefile completed but file was not found on disk"
        end

        return WriteSuccess, WriteError
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local Library = {
    BuildId = "elements-2",
    BuildDate = "2026-11-07",
    SearchVirtualized = true,

    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,
    Bubble = nil,

    SearchText = "",
    Searching = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},
    ConditionalGroups = {},

    ActiveTabChangedCallbacks = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindMenu = nil,
    KeybindToggles = {},

    Notifications = {},
    Dialogues = {},
    ActiveLoading = nil,
    ActiveDialog = nil,

    Overlays = {},
    OverlaysOrder = {},
    AllOverlays = {},
    OverlayIdCounter = 0,
    OverlayCascadeStep = 0,

    Corners = {},
    FocusHighlights = {},

    BaseZIndex = 999,
    BubbleZIndexOffset = 1,
    TooltipZIndexOffset = 3,
    DialogScrimZIndexOffset = 5,
    OverlayZIndexOffset = 6,

    OverlayZIndexSlotSize = 4,
    OverlayZIndexCounter = 0,

    OverlayFrontGeneration = 0,

    OverlayZIndexBudget = 40,
    SearchOverlayZIndexOffset = nil,
    DialogContentZIndexOffset = nil,
    CursorZIndexOffset = nil,

    ToggleKeybind = Enum.KeyCode.RightControl,
    OriginalMouseIconEnabled = UserInputService.MouseIconEnabled,
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    WindowAnimationInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabTransitionInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabSwipeOffset = 26,
    TabSwipeFrom = "bottom",
    PreviousTab = nil,

    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Dropdown = false,
        KeyPicker = false,
    },

    Toggled = false,
    Unloaded = false,
    IsPicking = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    TabSectionHeaders = {},

    NotifySide = "Right",
    ShowCustomCursor = false,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    WaitForIconsOnLoad = true,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 6,
    CornerRadiusDropdown = true,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(13, 13, 16),
        MainColor = Color3.fromRGB(21, 21, 25),
        AccentColor = Color3.fromRGB(66, 135, 245),
        OutlineColor = Color3.fromRGB(36, 36, 42),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        BackgroundImage = "",
        GradientColor = nil, --// optional: end color of the window gradient (derived from the accent when nil)

        RedColor = Color3.fromRGB(255, 64, 64),
        DestructiveColor = Color3.fromRGB(225, 60, 60),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),
    },

    Registry = {},
	Scales = {},
	ScalesOffset = {},
	DPIScaleCallbacks = {},
	AutoDPIScale = true,

    ImageManager = CustomImageManager,
    ShowCursorBinding = string.sub(tostring({}), 10),
}

Library.TooltipZIndex = Library.BaseZIndex + Library.TooltipZIndexOffset
Library.BubbleZIndex = Library.BaseZIndex + Library.BubbleZIndexOffset

Library.DialogScrimZIndex = Library.BaseZIndex + Library.DialogScrimZIndexOffset

Library.OverlayZIndex = Library.BaseZIndex + Library.OverlayZIndexOffset

local OverlayBandEnd = Library.OverlayZIndex + (Library.OverlayZIndexBudget * Library.OverlayZIndexSlotSize)

Library.SearchOverlayZIndexOffset = OverlayBandEnd - Library.BaseZIndex
Library.SearchOverlayZIndex = Library.BaseZIndex + Library.SearchOverlayZIndexOffset
local SearchOverlayBandEnd = Library.SearchOverlayZIndex + 2

Library.DialogContentZIndexOffset = (SearchOverlayBandEnd - Library.BaseZIndex)
Library.DialogContentZIndex = Library.BaseZIndex + Library.DialogContentZIndexOffset
local DialogContentBandEnd = Library.DialogContentZIndex + 4

Library.DialogZIndex = Library.DialogContentZIndex

Library.CursorZIndexOffset = (DialogContentBandEnd - Library.BaseZIndex) + 2
Library.CursorZIndex = Library.BaseZIndex + Library.CursorZIndexOffset

if RunService:IsStudio() then
    Library.IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
end

--// Every platform shares the same base size so the UI is a 1:1 copy of the
--// desktop layout everywhere; only the uniform scale changes to fit. \\--
Library.OriginalMinSize = Vector2.new(480, 360)

local Templates = {

    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        AlwaysOnTop = false,

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

        SearchbarSize = UDim2.fromScale(1, 1),
        CornerRadius = 6,
        NotifySide = "Right",
        ShowCustomCursor = false,
        Font = Enum.Font.GothamMedium,
        TitleSize = 20,
        TitleColor = nil,
        TitleAlignment = "Center", --// "Left" | "Center" | "Right": where the title block sits in the sidebar header and how the title aligns
        SubtitleAlignment = nil, --// same options; nil follows TitleAlignment
        Subtitle = nil,
        SubtitleSize = 12,
        SubtitleTransparency = 0.45,
        SubtitleColor = nil,
        FooterLeft = nil,
        FooterRight = nil,
        FooterSize = 14,
        PopOutBoxes = true, --// show a pop-out button on every section header
        TabButtonsStyle = {
            Gap = 2,
            Padding = 0, --// extra space around the whole tab list
            CornerRadius = 0,
            Indicator = false, --// accent bar on the left of the active tab
            IndicatorWidth = 3,
            IndicatorHeight = 18,
        },
        Transparency = 0,
        Gradient = true,
        GradientColor = nil,
        GradientRotation = 45,
        ToggleKeybind = Enum.KeyCode.RightControl,

        Bubble = nil,
        BubbleSide = "Right",
        BubbleIcon = "menu",
        BubbleIconColor = nil,
        BubbleColor = nil,
        BubbleSize = UDim2.fromOffset(50, 50),
        BubbleCornerRadius = 25,
        BubblePadding = 12,

        UnlockMouseWhileOpen = true,

        DPIScale = 5,

        EnableSidebarResize = true,
        SidebarWidth = nil,
        SidebarCompacted = false,
        CompactSidebarTooltips = true,
        MinContainerWidth = 256,

        DiscordLink = nil,
        DiscordAction = "open",

        SingleInstance = true,

        WaitForIconsOnLoad = nil,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        ButtonsAlignment = "Right",
        FooterButtons = {}
    },
    Loading = {
        Title = "Astral",
        Icon = "AstralIcon",
        IconSize = UDim2.fromOffset(30, 30),

        LoadingIcon = "LoadingIcon",
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,

        WindowWidth = 450,
        WindowHeight = 275,

        ContentWidth = 450,
        SidebarWidth = 250,

        AlwaysOnTop = false,

        DPIScale = nil,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,
        FireDefault = true,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",
        Editable = true,
        EditableStyle = "ValueBox",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,

        AllowRightClickInput = true,
    },
    Table = {
        Text = nil,
        Subtext = nil,

        Columns = {}, --// { "Name", "Value" } or { { Name = "Name", Width = "Fill" | "Auto" | pixels, Align = "Left" | "Center" | "Right", Weight = 1 } }
        Rows = {}, --// { { "Cell", "Cell" }, ... }; a cell can also be { Text = "", Color = Color3, Icon = "" }
        Header = true,
        Striped = true,
        RowHeight = 22,
        Align = "Left", --// default text alignment for every column: "Left" | "Center" | "Right"
        HeaderAlign = nil, --// header alignment; nil follows each column's alignment
        MaxHeight = nil, --// taller tables scroll
        Selectable = false,
        EmptyText = "No data",

        Callback = function() end,
        Changed = function() end,

        Visible = true,
    },
    PriorityList = {
        Text = nil,
        Subtext = nil,

        Items = {}, --// { "Name" } or { { Id = "a", Name = "Name", Value = "Off", Icon = "", Disabled = false } }
        ShowIndex = true,
        ShowValue = true,
        RowHeight = 34,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    IconButton = {
        Icon = "plus",
        Text = "",
        Size = 21, --// square size (width stays auto when Text is set)
        IconSize = 14,
        Func = nil,
        Callback = nil,
        Tooltip = nil,
        DisabledTooltip = nil,
        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Stepper = {
        Text = "Stepper",
        Subtext = nil,
        Icon = nil,
        IconColor = nil,

        Default = nil, --// starts at Min when nil
        Min = 0,
        Max = 100,
        Increment = 1,
        Rounding = 0,
        Prefix = "",
        Suffix = "",
        ValueTexts = nil, --// { [value] = "Text" }, e.g. { [100] = "Max" }
        Format = nil, --// function(Value): string
        ValueWidth = 44,
        Holdable = true, --// hold a button to keep stepping

        Tooltip = nil,
        DisabledTooltip = nil,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    ProgressBar = {
        Text = "Progress",
        Value = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",
        Compact = false,
        HideMax = false,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        ValueImages = {},

        Multi = false,
        DragSelect = false,
        MaxVisibleDropdownItems = 8,
        KeepDisabledValuePosition = false,

        Layout = "Inline", --// "Inline": label and box share a row. "Stacked": label above the box.
        BoxSide = "Right", --// Inline only: which side of the label the selection box sits on.
        BoxWidth = 0.5, --// Inline only: width of the box, 0-1 = fraction of the row, above 1 = pixels.

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    KeyPicker = {
        Text = "KeyPicker",

        Default = "None",
        DefaultModifiers = {},

        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},

        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Resizable = true,

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil

        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

--// Outline color for text drawn over fills: dark for light fonts, light for dark fonts. \\--
local function GetTextStrokeColor(): Color3
    local Color = Library.Scheme.FontColor
    return (Color.R * 0.299 + Color.G * 0.587 + Color.B * 0.114) > 0.5 and Library.Scheme.DarkColor or Library.Scheme.WhiteColor
end

local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

--// Window Snapping \\--
local function GetCoreGuiInset(): (Vector2, Vector2)
    local Success, TopLeft, BottomRight = pcall(function()
        return cloneref(game:GetService("GuiService")):GetGuiInset()
    end)

    if Success and TopLeft and BottomRight then
        return TopLeft, BottomRight
    end

    return Vector2.zero, Vector2.zero
end

local function GetSnapEdges(ElemSize: Vector2, ViewportSize: Vector2, Margin: number, AvoidCoreGui: boolean)
    local SafeMin, SafeMax = Vector2.zero, ViewportSize

    if AvoidCoreGui then
        local TopLeftInset, BottomRightInset = GetCoreGuiInset()
        SafeMin = TopLeftInset
        SafeMax = ViewportSize - BottomRightInset
    end

    local TargetsX = {
        LeftEdge = SafeMin.X + Margin,
        Center = SafeMin.X + (SafeMax.X - SafeMin.X - ElemSize.X) / 2,
        RightEdge = SafeMax.X - ElemSize.X - Margin,
    }
    local TargetsY = {
        TopEdge = SafeMin.Y + Margin,
        Center = SafeMin.Y + (SafeMax.Y - SafeMin.Y - ElemSize.Y) / 2,
        BottomEdge = SafeMax.Y - ElemSize.Y - Margin,
    }

    return TargetsX, TargetsY
end

local function GetClosestSnapTarget(Value: number, Targets: { [string]: number }, Distance: number): (number?, string?)
    local ClosestName, ClosestValue, ClosestDist = nil, nil, Distance

    for Name, Target in Targets do
        local Dist = math.abs(Value - Target)
        if Dist <= ClosestDist then
            ClosestDist = Dist
            ClosestName = Name
            ClosestValue = Target
        end
    end

    return ClosestValue, ClosestName
end

local function GetSnapGuideOffset(Name: string, SnappedValue: number, ElemDimension: number): number
    if Name == "RightEdge" or Name == "BottomEdge" then
        return SnappedValue + ElemDimension
    elseif Name == "Center" then
        return SnappedValue + ElemDimension / 2
    end

    return SnappedValue -- LeftEdge / TopEdge
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function IsSequentialArray(Table: { [any]: any })
    for Key in Table do
        if typeof(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
            return false
        end
    end

    return true
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
--// Fuzzy Search \\--
--// Lowercases ASCII plus Latin-1, Greek and Cyrillic capitals, which string.lower() leaves untouched. \\--
local function LowerText(Text: string): string
    return (Text:lower():gsub("[\195\206\208][\128-\191]", function(Char)
        local Code = utf8.codepoint(Char)
        if (Code >= 0xC0 and Code <= 0xDE and Code ~= 0xD7) or (Code >= 0x391 and Code <= 0x3AB) or (Code >= 0x410 and Code <= 0x42F) then
            return utf8.char(Code + 32)
        elseif Code >= 0x400 and Code <= 0x40F then
            return utf8.char(Code + 80)
        end

        return Char
    end))
end

local function FuzzyScore(Text: string, Search: string): (boolean, number)
    if Search == "" then
        return true, 0
    end
    if Text == "" then
        return false, 0
    end

    --// Fast path: literal substring match (also the best possible score) \\--
    local ExactIdx = Text:find(Search, 1, true)
    if ExactIdx then
        local PrevChar = ExactIdx > 1 and Text:sub(ExactIdx - 1, ExactIdx - 1) or ""
        local AtBoundary = ExactIdx == 1 or PrevChar:match("[%s%p_]") ~= nil

        return true, 1e5 - ExactIdx + (AtBoundary and 500 or 0) + (Search:len() * 5)
    end

    --// Fallback: fuzzy, in-order, non-consecutive character matching \\--
    --// Compare whole UTF-8 characters, not bytes, so non-English text matches correctly. \\--
    local TextChars, SearchChars = {}, {}
    for Char in Text:gmatch(utf8.charpattern) do
        table.insert(TextChars, Char)
    end
    for Char in Search:gmatch(utf8.charpattern) do
        table.insert(SearchChars, Char)
    end

    local TextLen, SearchLen = #TextChars, #SearchChars
    if SearchLen > TextLen then
        return false, 0
    end

    local SearchIdx = 1
    local Score = 0
    local RunLength = 0
    local LastMatchIdx = 0

    for TextIdx = 1, TextLen do
        if SearchIdx > SearchLen then
            break
        end

        if TextChars[TextIdx] == SearchChars[SearchIdx] then
            local PrevChar = TextIdx > 1 and TextChars[TextIdx - 1] or ""
            local AtBoundary = TextIdx == 1 or PrevChar:match("[%s%p_]") ~= nil

            RunLength = (LastMatchIdx == TextIdx - 1) and (RunLength + 1) or 1
            Score += 1 + (AtBoundary and 6 or 0) + math.min(RunLength - 1, 5) * 3

            LastMatchIdx = TextIdx
            SearchIdx += 1
        end
    end

    if SearchIdx <= SearchLen then
        return false, 0 --// Not every Search character was found, in order
    end

    Score -= (LastMatchIdx - SearchLen) * 0.05 --// Slightly favour tighter matches
    return true, Score
end

local function NormalizeSearch(Search: string): string
    return (Search:gsub("%s+", ""))
end

--// Lowered-text cache: every keystroke re-matches every element name, so
--// cache :lower() per string instead of reallocating it N times per
--// rebuild. Weak keys so renamed elements don't pin memory. \\--
local LowerTextCache = setmetatable({}, { __mode = "kv" })

local function LowerCached(Text: string): string
    local Cached = LowerTextCache[Text]
    if Cached then
        return Cached
    end
    local Lowered = LowerText(Text)
    LowerTextCache[Text] = Lowered
    return Lowered
end

local function TryFuzzyMatch(Text: any, Search: string): (boolean, number)
    if typeof(Text) ~= "string" or Text == "" then
        return false, 0
    end

    return FuzzyScore(LowerCached(Text), Search)
end

local function FuzzyMatchScore(Text: any, Search: string): number
    if typeof(Text) ~= "string" or Text == "" then
        return 0
    end

    local Normalized = NormalizeSearch(LowerCached(Text))
    local Matched, Score = FuzzyScore(Normalized, Search)
    if not Matched then
        return 0
    end

    if Normalized == Search then
        Score += 1000
    end

    return Score
end

local function MatchesSearch(ElementInfo, Search: string, ForceMatch: boolean?): boolean
    if not ElementInfo then
        return false
    end
    if ForceMatch then
        return true
    end

    if TryFuzzyMatch(ElementInfo.Text, Search) then
        return true
    end
    if TryFuzzyMatch(ElementInfo.Tooltip, Search) then
        return true
    end
    if TryFuzzyMatch(ElementInfo.DisabledTooltip, Search) then
        return true
    end

    --// Optional: search inside Dropdown value lists, so e.g. searching a specific option name reveals the Dropdown that contains it \\--
    if typeof(ElementInfo.Values) == "table" then
        local Checked = 0
        for Key, Value in ElementInfo.Values do
            Checked += 1
            if Checked > 200 then
                break
            end

            if TryFuzzyMatch(Value, Search) or (typeof(Value) ~= "string" and TryFuzzyMatch(tostring(Value), Search)) then
                return true
            end
            if typeof(Key) == "string" and TryFuzzyMatch(Key, Search) then
                return true
            end
        end
    end

    return false
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then

        return math.floor(Value + 0.5)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

function Library:UpdateConditionalGroups()
    for _, ConditionalGroup in Library.ConditionalGroups do
        ConditionalGroup:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

function Library:SetForceCheckbox(Value: boolean)
    Library.ForceCheckbox = Value

    for _, Toggle in Toggles do

        if typeof(Toggle) == "table" and Toggle.SetVariant and not Toggle.ExplicitCheckbox then
            Toggle:SetVariant(Value and "Checkbox" or "Switch")
        end
    end
end

local function CheckConditionalGroup(Box, Search, ForceVisible: boolean?)
    local VisibleElements = 0
    local BestScore = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then

            local Visible = false

            if MatchesSearch(ElementInfo, Search, ForceVisible) and ElementInfo.Visible then
                Visible = true
                BestScore = math.max(BestScore, FuzzyMatchScore(ElementInfo.Text, Search))
            else
                ElementInfo.Base.Visible = false
            end
            if MatchesSearch(ElementInfo.SubButton, Search, ForceVisible) and ElementInfo.SubButton.Visible then
                Visible = true
                BestScore = math.max(BestScore, FuzzyMatchScore(ElementInfo.SubButton.Text, Search))
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        if ElementInfo.Text and MatchesSearch(ElementInfo, Search, ForceVisible) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
            BestScore = math.max(BestScore, FuzzyMatchScore(ElementInfo.Text, Search))
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, ConditionalGroup in Box.ConditionalGroups do
        if not ConditionalGroup.Visible then
            continue
        end

        local GroupVisible, GroupScore = CheckConditionalGroup(ConditionalGroup, Search, ForceVisible)
        VisibleElements += GroupVisible
        if GroupScore > BestScore then
            BestScore = GroupScore
        end
    end

    if Box.Resize then
        Box:Resize()
    end

    Box.Holder.Visible = VisibleElements > 0
    return VisibleElements, BestScore
end

local function RestoreConditionalGroup(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, ConditionalGroup in Box.ConditionalGroups do
        if not ConditionalGroup.Visible then
            continue
        end

        RestoreConditionalGroup(ConditionalGroup)
    end

    if Box.SubSections then
        for _, SubSection in Box.SubSections do
            RestoreConditionalGroup(SubSection)
        end
    end
end

local function FilterBox(Box, Search, ForceVisible: boolean?)
    local VisibleElements = 0
    local BestScore = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then

            local Visible = false

            if MatchesSearch(ElementInfo, Search, ForceVisible) and ElementInfo.Visible then
                Visible = true
                BestScore = math.max(BestScore, FuzzyMatchScore(ElementInfo.Text, Search))
            else
                ElementInfo.Base.Visible = false
            end
            if MatchesSearch(ElementInfo.SubButton, Search, ForceVisible) and ElementInfo.SubButton.Visible then
                Visible = true
                BestScore = math.max(BestScore, FuzzyMatchScore(ElementInfo.SubButton.Text, Search))
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        if ElementInfo.Text and MatchesSearch(ElementInfo, Search, ForceVisible) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
            BestScore = math.max(BestScore, FuzzyMatchScore(ElementInfo.Text, Search))
        else
            ElementInfo.Holder.Visible = false
        end
    end

    if Box.ConditionalGroups then
        for _, ConditionalGroup in Box.ConditionalGroups do
            if not ConditionalGroup.Visible then
                continue
            end

            local GroupVisible, GroupScore = CheckConditionalGroup(ConditionalGroup, Search, ForceVisible)
            VisibleElements += GroupVisible
            if GroupScore > BestScore then
                BestScore = GroupScore
            end
        end
    end

    if Box.SubSections then
        for _, SubSection in Box.SubSections do
            local SubSectionMatches = ForceVisible or TryFuzzyMatch(SubSection.Name, Search)
            BestScore = math.max(BestScore, FuzzyMatchScore(SubSection.Name, Search))

            local SubVisible, SubScore = FilterBox(SubSection, Search, SubSectionMatches)
            VisibleElements += SubVisible
            if SubScore > BestScore then
                BestScore = SubScore
            end

            if SubVisible > 0 then
                SubSection:Resize()
            end
            SubSection.Holder.Visible = SubVisible > 0
        end
    end

    return VisibleElements, BestScore
end

local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return false, 0
    end

    local HasVisible = false
    local BestScore = 0

    --// If the Tab itself matches Search (by name/description), don't filter out its contents -- pull everything in the Tab along with it \\--
    local TabMatches = TryFuzzyMatch(Tab.Name, Search) or TryFuzzyMatch(Tab.Description, Search)
    BestScore = math.max(BestScore, FuzzyMatchScore(Tab.Name, Search), FuzzyMatchScore(Tab.Description, Search))

    for _, Section in Tab.Sections do
        --// Optional: matching the Section's own name reveals every element inside it, without needing each one to match too
        local SectionMatches = TabMatches or TryFuzzyMatch(Section.Name, Search)
        BestScore = math.max(BestScore, FuzzyMatchScore(Section.Name, Search))

        local VisibleElements, SectionScore = FilterBox(Section, Search, SectionMatches)
        BestScore = math.max(BestScore, SectionScore)

        if VisibleElements > 0 then
            Section:Resize()
            HasVisible = true
        end
        Section.BoxHolder.Visible = VisibleElements > 0
    end

    for _, SectionGroup in Tab.SectionGroups do
        local VisibleTabs = 0
        local VisibleElements = {}
        local SubTabScores = {}

        for _, SubTab in SectionGroup.Tabs do
            VisibleElements[SubTab] = 0

            --// Optional: matching a sub-tab's own name reveals every element inside it, without needing each one to match too
            local SubTabMatches = TabMatches or TryFuzzyMatch(SubTab.Name, Search)
            local SubScore = FuzzyMatchScore(SubTab.Name, Search)
            BestScore = math.max(BestScore, SubScore)

            local SubVisible, SubTabScore = FilterBox(SubTab, Search, SubTabMatches)
            VisibleElements[SubTab] = SubVisible
            SubScore = math.max(SubScore, SubTabScore)
            BestScore = math.max(BestScore, SubScore)
            SubTabScores[SubTab] = SubScore
        end

        local BestSubTab = nil
        local BestSubScore = -1

        for SubTab, Visible in VisibleElements do
            SubTab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1
                HasVisible = true

                local SubScore = SubTabScores[SubTab] or 0
                if SubScore > BestSubScore then
                    BestSubScore = SubScore
                    BestSubTab = SubTab
                end
            end
        end

        local ActiveSubTab = SectionGroup.ActiveTab
        local ActiveSubVisible = ActiveSubTab and (VisibleElements[ActiveSubTab] or 0) > 0
        local ActiveSubScore = ActiveSubTab and (SubTabScores[ActiveSubTab] or -1) or -1

        if ActiveSubVisible and ActiveSubScore >= BestSubScore then
            ActiveSubTab:Resize()
        elseif BestSubTab then
            BestSubTab:Show()
        end

        SectionGroup.BoxHolder.Visible = VisibleTabs > 0
    end

    return HasVisible, BestScore
end

local function RestoreBox(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    if Box.ConditionalGroups then
        for _, ConditionalGroup in Box.ConditionalGroups do
            if not ConditionalGroup.Visible then
                continue
            end

            RestoreConditionalGroup(ConditionalGroup)
        end
    end

    if Box.SubSections then
        for _, SubSection in Box.SubSections do
            RestoreConditionalGroup(SubSection)
            SubSection.Holder.Visible = true
        end
    end
end

local function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Section in Tab.Sections do
        RestoreBox(Section)

        Section:Resize()
        Section.BoxHolder.Visible = true
    end

    for _, SectionGroup in Tab.SectionGroups do
        for _, SubTab in SectionGroup.Tabs do
            RestoreBox(SubTab)

            SubTab.ButtonHolder.Visible = true
        end

        if SectionGroup.ActiveTab then
            SectionGroup.ActiveTab:Resize()
        end
        SectionGroup.BoxHolder.Visible = true
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToSearch = {}
    for _, Tab in Library.Tabs do
        if typeof(Tab) == "table" and not Tab.IsKeyTab then
            table.insert(TabsToSearch, Tab)
        end
    end

    for _, Tab in TabsToSearch do
        ResetTab(Tab)
    end

    local Search = NormalizeSearch(LowerText(SearchText))
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local BestTab = nil
    local BestScore = -1
    local ActiveScore = -1
    local ActiveHasVisible = false

    for _, Tab in TabsToSearch do
        local HasVisible, Score = ApplySearchToTab(Tab, Search)
        if not HasVisible then
            continue
        end

        if Tab == Library.ActiveTab then
            ActiveHasVisible = true
            ActiveScore = Score
        end
        if Score > BestScore then
            BestScore = Score
            BestTab = Tab
        end
    end

    local StayOnActive = ActiveHasVisible and ActiveScore >= BestScore
    if StayOnActive and Library.ActiveTab then
        Library.ActiveTab:RefreshSides()
    elseif BestTab then
        local SearchMarker = SearchText
        task.defer(function()
            if Library.SearchText ~= SearchMarker then
                return
            end

            if Library.ActiveTab ~= BestTab then
                BestTab:Show()
            elseif Library.ActiveTab then
                Library.ActiveTab:RefreshSides()
            end
        end)
    end

    Library.LastSearchTab = nil
end

function Library:AddToRegistry(Inst, Properties)

    local Existing = Library.Registry[Inst]
    if Existing then
        for Key, Value in Properties do
            Existing[Key] = Value
        end
    else
        Library.Registry[Inst] = Properties
    end

    if Properties.BackgroundColor3 ~= nil and Library.StyleClasses and Library.StyleClasses[Inst.ClassName] then
        Library:QueueStyle(Inst, "auto")
    end
end

function Library:RemoveFromRegistry(Inst)
    Library.Registry[Inst] = nil
end

function Library:RemoveRegistryProperty(Inst, Property)
    local Existing = Library.Registry[Inst]
    if Existing then
        Existing[Property] = nil
    end
end

--// Popped-out sections follow the main window's visibility. \\--
Library.PoppedSections = {} --// Section -> floating panel Frame

function Library:UpdatePoppedSections()
    for _, PanelHolder in Library.PoppedSections do
        if PanelHolder.Parent then
            PanelHolder.Visible = Library.Toggled ~= false
        end
    end
end

--// Window style: transparency + gradient. \\--
Library.WindowTransparency = 0
Library.GradientsEnabled = true
Library.GradientRotation = 45
Library.GradientPanelTransparency = 0.1 --// panels are 90% opaque
Library.StyleTargets = setmetatable({}, { __mode = "k" }) --// Instance -> "main" | "panel" | "card"
Library.StyleBase = setmetatable({}, { __mode = "k" }) --// Instance -> original BackgroundTransparency
Library.StylePending = {}
Library.StyleFlushQueued = false

function Library:GetGradientColors(): (Color3, Color3)
    local Scheme = Library.Scheme
    local Base = Scheme.BackgroundColor
    local Start = Library:GetBetterColor(Base, -1)

    local End = Scheme.GradientColor
    if typeof(End) == "Color3" then
        End = Base:Lerp(End, 0.28)
    else
        if Library.IsLightTheme then
            End = Base:Lerp(Scheme.AccentColor, 0.05)
        else
            local SubtleBlue = Color3.fromRGB(20, 26, 40)
            End = Base:Lerp(SubtleBlue, 0.25):Lerp(Scheme.AccentColor, 0.04)
        end
    end

    return Start, End
end

--// Frames whose descendants follow the window style: the main window plus every overlay
--// (draggable menus and labels, notifications, context menus, popped-out sections). \\--
Library.StyleRoots = setmetatable({}, { __mode = "k" })
Library.StyleGradients = setmetatable({}, { __mode = "k" }) --// overlay root -> UIGradient
Library.RootFill = setmetatable({}, { __mode = "k" }) --// overlay root -> its normal fill (registry value)
Library.GradientCardTransparency = 0.1 --// cards are 90% opaque
Library.StyleClasses = { Frame = true, ScrollingFrame = true, TextButton = true, TextBox = true, CanvasGroup = true }

function Library:GetStyleRoot(Inst: Instance): Instance?
    local Current = Inst
    while Current do
        if Library.StyleRoots[Current] then
            return Current
        end
        Current = Current.Parent
    end

    return nil
end

--// Which style a frame follows, judged from the color it is registered with:
--// BackgroundColor / DarkColor / computed colors = "panel", MainColor = "card". Anything else (accent
--// bars, outlines, lines) is left alone. \\--
function Library:ClassifyStyle(Inst: Instance): string?
    if Library.StyleTargets[Inst] == "solid" then
        return "solid"
    end

    if not Library.StyleClasses[Inst.ClassName] then
        return nil
    end

    local Registered = Library.Registry[Inst]
    local Fill = Registered and Registered.BackgroundColor3
    if Fill == nil then
        return nil
    end

    if typeof(Fill) == "function" then
        return "panel"
    elseif Fill == "MainColor" then
        return "card"
    elseif Fill == "BackgroundColor" or Fill == "DarkColor" then
        return "panel"
    end

    return nil
end

local function ApplyRootStyle(Frame: GuiObject, Base: number)
    local Gradient = Library.StyleGradients[Frame]
    local Transparency = Library.WindowTransparency

    local Fill = Library.RootFill[Frame] or "BackgroundColor"
    if Library.Registry[Frame] then
        Library.Registry[Frame].BackgroundColor3 = Fill
    end
    local BaseColor = typeof(Fill) == "function" and Fill() or GetSchemeValue(Fill) or Library.Scheme.BackgroundColor
    Frame.BackgroundColor3 = BaseColor
    Frame.BackgroundTransparency = 1 - (1 - Base) * (1 - Transparency)

    if Gradient then
        if Library.GradientsEnabled then
            local Tint = Library.IsLightTheme and Color3.fromRGB(240, 243, 250) or Color3.fromRGB(215, 225, 245)
            Gradient.Enabled = true
            Gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Tint)
            Gradient.Rotation = Library.GradientRotation
        else
            Gradient.Enabled = false
        end
    end
end

function Library:ApplyStyleTo(Inst: GuiObject, Mode: string?)
    if not Inst.Parent then
        return
    end

    local Base = Library.StyleBase[Inst]
    if not Library:GetStyleRoot(Inst) then
        --// Moved out of every styled area: put the original look back. \\--
        if Base ~= nil then
            Inst.BackgroundTransparency = Base
        end
        return
    end

    if Mode == nil or Mode == "auto" then
        Mode = Library:ClassifyStyle(Inst)
        if not Mode then
            return
        end
    end

    if Base == nil then
        Base = Inst.BackgroundTransparency
        Library.StyleBase[Inst] = Base
    end
    if Base >= 1 then
        return
    end

    local Transparency = Library.WindowTransparency
    local Gradients = Library.GradientsEnabled

    if Mode == "solid" then
        Inst.BackgroundTransparency = 0
    elseif Mode == "root" then
        ApplyRootStyle(Inst, Base)
    elseif Mode == "main" then
        --// The window's own fill is painted by the gradient overlay when gradients are on. \\--
        Inst.BackgroundTransparency = Gradients and 1 or Transparency
    elseif Mode == "panel" then
        local Show = Gradients and (1 - Library.GradientPanelTransparency) or 1
        Inst.BackgroundTransparency = 1 - (1 - Base) * Show * (1 - Transparency)
    else
        local Show = Gradients and (1 - Library.GradientCardTransparency) or 1
        Inst.BackgroundTransparency = 1 - (1 - Base) * Show * (1 - Transparency)
    end
end

function Library:UpdateWindowStyle()
    local Overlay = Library.GradientOverlay
    if Overlay and Overlay.Parent and Library.GradientObject then
        local Start, End = Library:GetGradientColors()
        Overlay.Visible = Library.GradientsEnabled
        Library.GradientObject.Color = ColorSequence.new(Start, End)
        Library.GradientObject.Rotation = Library.GradientRotation
        Library.GradientObject.Transparency = NumberSequence.new(Library.WindowTransparency)
    end

    for Inst, Mode in Library.StyleTargets do
        if Inst.Parent then
            Library:ApplyStyleTo(Inst, Mode)
        end
    end
end

function Library:QueueStyle(Inst: GuiObject, Mode: string?)
    Library.StyleTargets[Inst] = Mode or "auto"
    Library.StylePending[Inst] = true

    if Library.StyleFlushQueued then
        return
    end
    Library.StyleFlushQueued = true

    task.defer(function()
        Library.StyleFlushQueued = false

        local Pending = Library.StylePending
        Library.StylePending = {}

        for Inst, _ in Pending do
            local Mode = Library.StyleTargets[Inst]
            if Mode and Inst.Parent then
                Library:ApplyStyleTo(Inst, Mode)
            end
        end
    end)
end

--// Makes a frame an overlay root: it gets its own gradient, and everything inside it follows the
--// window transparency and gradient like the main window does. \\--
function Library:AddStyleRoot(Frame: GuiObject)
    if Library.StyleRoots[Frame] then
        return
    end

    Library.StyleRoots[Frame] = true

    local Registered = Library.Registry[Frame]
    Library.RootFill[Frame] = Registered and Registered.BackgroundColor3 or "BackgroundColor"
    --// (New is defined further down this file, so build the gradient directly.) \\--
    local Gradient = Instance.new("UIGradient")
    Gradient.Enabled = false
    Gradient.Parent = Frame
    Library.StyleGradients[Frame] = Gradient

    Library:QueueStyle(Frame, "root")
end

--// Picks up every registered frame that has not been looked at yet (frames that got their color
--// registered after they were created). \\--
function Library:RescanStyle()
    for Inst, Registered in Library.Registry do
        if Registered.BackgroundColor3 ~= nil and Library.StyleTargets[Inst] == nil and Library.StyleClasses[Inst.ClassName] then
            Library.StyleTargets[Inst] = "auto"
        end
    end
end

--// Value is 0 (opaque) to 0.85 (very see-through). \\--
function Library:SetWindowTransparency(Value: number)
    assert(typeof(Value) == "number", "Expected number for transparency got: " .. typeof(Value))

    Library.WindowTransparency = math.clamp(Value, 0, 0.85)
    Library:UpdateWindowStyle()
end

function Library:SetGradientsEnabled(Enabled: boolean)
    Library.GradientsEnabled = Enabled == true
    Library:UpdateWindowStyle()
end

function Library:SetGradientColor(Color: Color3?)
    assert(Color == nil or typeof(Color) == "Color3", "Expected Color3 or nil for gradient color")

    Library.Scheme.GradientColor = Color
    Library:UpdateWindowStyle()
end

function Library:SetGradientRotation(Rotation: number)
    assert(typeof(Rotation) == "number", "Expected number for rotation got: " .. typeof(Rotation))

    Library.GradientRotation = Rotation
    Library:UpdateWindowStyle()
end

function Library:UpdateColorsUsingRegistry()
    for Inst, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Inst[Property] = SchemeValue or Index()
            end
        end
    end

    if Library.FocusHighlights then
        for _, Highlight in Library.FocusHighlights do
            Highlight:Reapply()
        end
    end

    if Library.UpdateWindowStyle then
        Library:UpdateWindowStyle()
    end
end

function Library:CalculateAutoBaseScale(): number
    local Camera = workspace.CurrentCamera
    local ViewportSize: Vector2 = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        return 1
    end

    local WinWidth = (Library.MainFrame and Library.MainFrame.Size.X.Offset) or 720
    local WinHeight = (Library.MainFrame and Library.MainFrame.Size.Y.Offset) or 600

    --// Proportional margins: 5% of the viewport on every side. A fixed 36px
    --// gutter is 3% of a desktop screen but 10% of a phone, which is why the
    --// window filled the phone edge to edge while it looked inset on PC. \\--
    local MarginX = math.max(ViewportSize.X * 0.05, 12)
    local MarginY = math.max(ViewportSize.Y * 0.05, 12)
    local AvailableX = math.max(100, ViewportSize.X - MarginX * 2)
    local AvailableY = math.max(100, ViewportSize.Y - MarginY * 2)

    local ScaleX = AvailableX / WinWidth
    local ScaleY = AvailableY / WinHeight
    local FitScale = math.min(ScaleX, ScaleY)

    return math.clamp(FitScale, 0.25, 1)
end

function Library:CalculateAutoDPIScale(Rounding: number?): number
    local Value = 5
    if Rounding ~= nil then
        local Multiplier = 10 ^ math.max(math.floor(Rounding), 0)
        Value = math.floor(Value * Multiplier + 0.5) / Multiplier
    end
    return Value
end

function Library:SetDPIScale(DPIScale: number)
    DPIScale = math.clamp(tonumber(DPIScale) or 5, 1, 10)
    Library.UIScaleValue = DPIScale

    Library.BaseScale = Library:CalculateAutoBaseScale()

    local Multiplier = DPIScale / 5
    local ScaleFactor = Library.BaseScale * Multiplier

    --// In automatic mode the DPI multiplier can push the window past the
    --// screen (mobile reports higher values), so cap the *rendered* window
    --// scale at what actually fits with the margins above. Manual scaling
    --// (AutoDPIScale = false) keeps full control. \\--
    if Library.AutoDPIScale ~= false then
        local Camera = workspace.CurrentCamera
        local ViewportSize: Vector2 = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
        local WinWidth = (Library.MainFrame and Library.MainFrame.Size.X.Offset) or 0
        local WinHeight = (Library.MainFrame and Library.MainFrame.Size.Y.Offset) or 0

        if WinWidth > 0 and WinHeight > 0 and ViewportSize.X > 20 and ViewportSize.Y > 20 then
            local MarginX = math.max(ViewportSize.X * 0.05, 12)
            local MarginY = math.max(ViewportSize.Y * 0.05, 12)
            local FitScale = math.min(
                (ViewportSize.X - MarginX * 2) / WinWidth,
                (ViewportSize.Y - MarginY * 2) / WinHeight
            )
            local MainOffset = (Library.MainWindowScale and tonumber(Library.ScalesOffset[Library.MainWindowScale])) or 0
            local MaxScaleFactor = FitScale + MainOffset

            if ScaleFactor > MaxScaleFactor then
                ScaleFactor = MaxScaleFactor
            end
        end
    end

    Library.DPIValue = DPIScale
    Library.DPIScale = ScaleFactor

    Library.MinSize = Library.OriginalMinSize

	for _, UIScale in Library.Scales do
        UIScale.Scale = ScaleFactor - (tonumber(Library.ScalesOffset[UIScale]) or 0)
    end

    if Library.MainFrame and Library.CenterMainWindow then
        local MainScaleFactor = (Library.MainWindowScale and Library.MainWindowScale.Scale) or ScaleFactor
        local ScaledWidth = Library.MainFrame.Size.X.Offset * MainScaleFactor
        local ScaledHeight = Library.MainFrame.Size.Y.Offset * MainScaleFactor
        Library.MainFrame.Position = UDim2.new(0.5, -ScaledWidth / 2, 0.5, -ScaledHeight / 2)
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end

    for _, Callback in Library.DPIScaleCallbacks do
        Library:SafeCallback(Callback, ScaleFactor)
    end

    if Library.Bubble and Library.Bubble.Parent and Library.SnapBubbleToSide then
        local BubbleToSnap = Library.Bubble
        local SideToSnap = Library.BubbleSide or "Right"
        task.defer(function()
            if Library.Bubble == BubbleToSnap and BubbleToSnap.Parent then
                Library.SnapBubbleToSide(SideToSnap, true)
            end
        end)
    end
end

function Library:GiveDPIScaleCallback(Callback: (ScaleFactor: number) -> ())
    table.insert(Library.DPIScaleCallbacks, Callback)
    return Callback
end

function Library:GiveActiveTabChangedCallback(Callback: (Tab: any) -> ())
    table.insert(Library.ActiveTabChangedCallbacks, Callback)
    return Callback
end

function Library:FireActiveTabChanged(Tab)
    Library:UpdateTabIndicators()

    for _, Callback in Library.ActiveTabChangedCallbacks do
        Library:SafeCallback(Callback, Tab)
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection)
    if Connection and typeof(Connection) == "RBXScriptConnection" then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string" and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

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

local LUCIDE_SOURCE_URL = "https://raw.githubusercontent.com/inCythe/AstralDev/refs/heads/main/LucideIcons.lua"
local LUCIDE_CACHE_PATH = "Astral/cache/LucideIcons.lua"

local IconsLoaded = false
local Icons = {} :: { [string]: string }

local function HttpGetAny(Url: string): (boolean, string?)
    local Methods = {}

    --// Reading a missing member on an Instance raises instead of returning
    --// nil, so probe game.HttpGet behind a pcall: in Studio (and any
    --// non-executor host) the raw index aborted icon loading before the
    --// fallbacks below could run. \\--
    local HasGameHttpGet = false
    pcall(function()
        HasGameHttpGet = typeof(game.HttpGet) == "function"
    end)

    if HasGameHttpGet then
        table.insert(Methods, function()
            return game:HttpGet(Url)
        end)
    end

    if typeof(http_request) == "function" then
        table.insert(Methods, function()
            local Response = http_request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    if typeof(request) == "function" then
        table.insert(Methods, function()
            local Response = request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    if syn and typeof(syn.request) == "function" then
        table.insert(Methods, function()
            local Response = syn.request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    if typeof(fluxus_request) == "function" then
        table.insert(Methods, function()
            local Response = fluxus_request({ Url = Url, Method = "GET" })
            return Response and Response.Body
        end)
    end

    for _, Method in Methods do
        local Success, Result = pcall(Method)
        if Success and typeof(Result) == "string" and #Result > 0 then
            return true, Result
        end
    end

    return false, nil
end

local function LoadIconsFromCache(): boolean
    if not isfile or not readfile then
        return false
    end

    if not isfile(LUCIDE_CACHE_PATH) then
        return false
    end

    local Success, Content = pcall(readfile, LUCIDE_CACHE_PATH)
    if not Success or not Content or Content == "" then
        return false
    end

    if not Content:find("return {") or not Content:find("rbxassetid://") then
        return false
    end

    local CompileSuccess, Compiled = pcall(loadstring, Content)
    if not CompileSuccess or typeof(Compiled) ~= "function" then
        return false
    end

    local RunSuccess, Module = pcall(Compiled)
    if not RunSuccess or typeof(Module) ~= "table" then
        return false
    end

    Icons = Module :: { [string]: string }
    return true
end

local function SaveIconsToCache(Content: string): boolean
    if not writefile or not isfolder or not makefolder then
        return false
    end

    local CacheDir = LUCIDE_CACHE_PATH:sub(1, LUCIDE_CACHE_PATH:find("/[^/]*$") - 1)
    if not isfolder(CacheDir) then
        pcall(makefolder, CacheDir)
    end

    local Success, Error = pcall(writefile, LUCIDE_CACHE_PATH, Content)
    if not Success then
        return false
    end

    return true
end

local function FetchIconsWithRetry(): (boolean, { [string]: string }?)

    if LoadIconsFromCache() then
        return true, Icons
    end

    local Success, Result = HttpGetAny(LUCIDE_SOURCE_URL)
    if not Success or not Result or Result == "" then
        return false, nil
    end

    local CompileSuccess, Compiled = pcall(loadstring, Result)
    if not CompileSuccess or typeof(Compiled) ~= "function" then
        return false, nil
    end

    local RunSuccess, Module = pcall(Compiled)
    if not RunSuccess or typeof(Module) ~= "table" then
        return false, nil
    end

    pcall(SaveIconsToCache, Result)

    Icons = Module :: { [string]: string }
    return true, Icons
end

local FetchIcons = false
task.spawn(function()
    local Success, Result = FetchIconsWithRetry()
    if Success and Result then
        FetchIcons = true
        Icons = Result
    end
    IconsLoaded = true
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Url = Icons[IconName]
    if typeof(Url) ~= "string" or Url == "" then
        return
    end

    return {
        Url = Url,
        IconName = IconName,
        ImageRectOffset = Vector2.zero,
        ImageRectSize = Vector2.zero,
    }
end

function Library:WaitForIcons(Timeout: number?): boolean
    Timeout = Timeout or 10

    local StartTime = tick()

    while not IconsLoaded do
        if tick() - StartTime > Timeout then
            return false
        end
        task.wait(0.1)
    end

    return FetchIcons
end

function Library:AreIconsLoaded(): boolean
    return IconsLoaded and FetchIcons
end

local PendingIconInstances = {} :: { [Instance]: string }

function Library:RegisterIconInstance(Instance: Instance, IconName: string)
    if Library:AreIconsLoaded() then
        local Icon = Library:GetIcon(IconName)
        if Icon then
            (Instance :: any).Image = Icon.Url
            ;(Instance :: any).ImageRectOffset = Icon.ImageRectOffset
            ;(Instance :: any).ImageRectSize = Icon.ImageRectSize
        end
        return
    end

    PendingIconInstances[Instance] = IconName

    Instance.Destroying:Connect(function()
        PendingIconInstances[Instance] = nil
    end)
end

function Library:RefreshIcons()
    for Instance, IconName in pairs(PendingIconInstances) do
        if Instance and Instance.Parent then
            local Icon = Library:GetIcon(IconName)
            if Icon then
                (Instance :: any).Image = Icon.Url
                ;(Instance :: any).ImageRectOffset = Icon.ImageRectOffset
                ;(Instance :: any).ImageRectSize = Icon.ImageRectSize
            end
        end
    end
    table.clear(PendingIconInstances)
end

--// Shows an icon on an ImageLabel/ImageButton. Icon can be a Lucide name, an asset id / rbxassetid
--// string, a registered custom asset name, or an icon table ({ Url, ImageRectOffset, ImageRectSize }). \\--
function Library:ApplyIcon(Target: ImageLabel | ImageButton, Icon: any)
    local Parsed = Library:GetCustomIcon(Icon)
    if Parsed then
        Target.Image = Parsed.Url
        Target.ImageRectOffset = Parsed.ImageRectOffset or Vector2.zero
        Target.ImageRectSize = Parsed.ImageRectSize or Vector2.zero
    elseif typeof(Icon) == "string" then
        --// Lucide icons may not be loaded yet; they are filled in once they are. \\--
        Library:RegisterIconInstance(Target, Icon)
    end

    return Target
end

--// Deprecated alias kept for older scripts. \\--
function Library:ApplyLucideIcon(ImageGui: ImageLabel | ImageButton, Icon: any, Rotation: number?)
    if Rotation then
        ImageGui.Rotation = Rotation
    end

    return Library:ApplyIcon(ImageGui, Icon)
end

function Library:GetCustomIcon(IconName: string): any
    if not IconName then
        return nil
    end

    if typeof(IconName) == "table" and IconName.Url then
        return IconName
    end

    if tonumber(IconName) then
        IconName = string.format("rbxassetid://%s", tostring(IconName))
    end

    if CustomImageManagerAssets[IconName] ~= nil then
        local ResolvedUrl = CustomImageManager.GetAsset(IconName)
        if ResolvedUrl then
            return {
                Url = ResolvedUrl,
                ImageRectOffset = Vector2.zero,
                ImageRectSize = Vector2.zero,
                Custom = true,
                IsBuiltIn = CustomImageManager.IsBuiltIn(IconName),
            }
        end
    end

    local CustomIcon = IsValidCustomIcon(IconName)
    if CustomIcon then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end

    local LucideIcon = Library:GetIcon(IconName)
    if LucideIcon then
        return LucideIcon
    end

    return nil
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

local function FillInstance(Table: { [string]: any }, Inst: GuiObject)
    local ThemeProperties = Library.Registry[Inst] or {}

    for key, value in Table do
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end
        end

        Inst[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Inst] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local inst = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], inst)
    end
    FillInstance(Properties, inst)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            inst.ZIndex = Properties.Parent.ZIndex
        end)
    end

    --// Frames drawn with the main/background colors follow the window transparency + gradient. \\--
    local BackgroundIndex = Properties.BackgroundColor3
    if Library.StyleClasses[ClassName] and (
        typeof(BackgroundIndex) == "function"
        or BackgroundIndex == "BackgroundColor"
        or BackgroundIndex == "MainColor"
        or BackgroundIndex == "DarkColor"
    ) then
        Library:QueueStyle(inst, "auto")
    end

    return inst
end

function Library:CreateIcon(Icon: any, Properties: { [string]: any }?, IsButton: boolean?)
    local Merged = {
        BackgroundTransparency = 1,
        ImageColor3 = Color3.new(1, 1, 1),
        ScaleType = Enum.ScaleType.Fit,
    }
    if Properties then
        for Property, Value in Properties do
            Merged[Property] = Value
        end
    end

    return Library:ApplyIcon(New(IsButton and "ImageButton" or "ImageLabel", Merged), Icon)
end

--// Applies Window.TabButtonsStyle (corner radius + active indicator) to a sidebar tab button. \\--
function Library:StyleTabButton(TabButton: TextButton, ButtonPadding: UIPadding?)
    local Style = Library.TabButtonsStyle
    if not Style then
        return
    end

    if Style.CornerRadius > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Style.CornerRadius),
            Parent = TabButton,
        })
    end

    if Style.Indicator then
        local IsActive = Library.ActiveTab ~= nil and Library.ActiveTab.Button == TabButton
        local Indicator = New("Frame", {
            Name = "ActiveIndicator",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "AccentColor",
            BackgroundTransparency = IsActive and 0 or 1,
            Size = UDim2.fromOffset(Style.IndicatorWidth, Style.IndicatorHeight),
            Parent = TabButton,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Indicator,
        })

        --// The button has left padding, so offset the bar back to the button's edge. \\--
        local function Place()
            local Left = ButtonPadding and ButtonPadding.PaddingLeft.Offset or 0
            Indicator.Position = UDim2.new(0, 2 - Left, 0.5, 0)
        end
        Place()

        if ButtonPadding then
            ButtonPadding:GetPropertyChangedSignal("PaddingLeft"):Connect(Place)
        end
    end
end

--// ---- Shared building blocks for icons, subtext and accent fills ---- \\--

--// Thin variant of the UI font; used by subtext. \\--
function Library:GetThinFont(): Font
    local Base = Library.Scheme.Font
    return Font.new(Base.Family, Enum.FontWeight.Light, Base.Style)
end

--// Squares off individual corners of a rounded frame (UICorner can only round all four). A small patch with
--// the frame's own fill covers the rounded corner and two outline lines redraw the border over it.
--// Corners: any of "TL" "TR" "BL" "BR". Returns an object with :SetVisible(bool). \\--
function Library:SquareCorners(Frame: GuiObject, Corners: { string }, Radius: number?)
    local R = math.ceil(Radius or (Library.CornerRadius / 2)) + 1
    local Fill = Library.Registry[Frame] and Library.Registry[Frame].BackgroundColor3 or "MainColor"
    local Pieces = {}

    for _, Corner in Corners do
        local Left = Corner == "TL" or Corner == "BL"
        local Top = Corner == "TL" or Corner == "TR"
        local Anchor = Vector2.new(Left and 0 or 1, Top and 0 or 1)
        local Origin = UDim2.new(Left and 0 or 1, Left and -1 or 1, Top and 0 or 1, Top and -1 or 1)

        local Patch = New("Frame", {
            AnchorPoint = Anchor,
            BackgroundColor3 = Fill,
            Position = Origin,
            Size = UDim2.fromOffset(R + 1, R + 1),
            ZIndex = Frame.ZIndex + 1,
            Parent = Frame,
        })
        local Horizontal = New("Frame", {
            AnchorPoint = Anchor,
            BackgroundColor3 = "OutlineColor",
            Position = Origin,
            Size = UDim2.fromOffset(R + 1, 1),
            ZIndex = Frame.ZIndex + 2,
            Parent = Frame,
        })
        local Vertical = New("Frame", {
            AnchorPoint = Anchor,
            BackgroundColor3 = "OutlineColor",
            Position = Origin,
            Size = UDim2.fromOffset(1, R + 1),
            ZIndex = Frame.ZIndex + 2,
            Parent = Frame,
        })
        table.insert(Pieces, Patch)
        table.insert(Pieces, Horizontal)
        table.insert(Pieces, Vertical)
    end

    local Object = { Pieces = Pieces }
    function Object:SetVisible(Visible: boolean)
        for _, Piece in Pieces do
            Piece.Visible = Visible
        end
    end

    return Object
end

--// Accent fill: the accent color fading into a lighter accent. Used by icon tiles and active tabs. \\--
function Library:GetAccentSequence(): ColorSequence
    local Accent = Library.Scheme.AccentColor
    return ColorSequence.new(Accent, Accent:Lerp(Color3.new(1, 1, 1), 0.22))
end

function Library:ApplyAccentGradient(Inst: GuiObject, Rotation: number?): UIGradient
    return New("UIGradient", {
        Color = function()
            return Library:GetAccentSequence()
        end,
        Rotation = Rotation or 0,
        Parent = Inst,
    })
end

--// Height (px) a piece of subtext needs at the given width. Subtext wraps, so it can be several lines. \\--
function Library:GetSubtextHeight(Text: string, Width: number): number
    local _, Height = Library:GetTextBounds(Text, Library:GetThinFont(), 12, math.max(Width, 24))
    return math.ceil(Height)
end

--// Calls Callback now (deferred) and whenever the frame's width changes. \\--
function Library:BindWidth(Frame: GuiObject, Callback: () -> ())
    local LastWidth = -1
    local function Run()
        local Width = math.floor(Frame.AbsoluteSize.X)
        if Width == LastWidth then
            return
        end
        LastWidth = Width
        Callback()
    end

    Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(Run)
    task.defer(Callback)
end

--// Subtext label for vertical lists that size themselves: tight, thin, wraps onto more lines. \\--
function Library:CreateSubtext(Parent: Instance, Text: string, Props: { [string]: any }?)
    local Info = {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        FontFace = function()
            return Library:GetThinFont()
        end,
        Size = UDim2.new(1, 0, 0, 0),
        Text = Text,
        TextSize = 12,
        TextTransparency = 0.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = Parent,
    }
    if Props then
        for Key, Value in Props do
            Info[Key] = Value
        end
    end

    return New("TextLabel", Info)
end

local function IsPictureIcon(Icon: any): boolean
    if typeof(Icon) == "table" then
        return true
    end

    return typeof(Icon) == "string" and (Icon:find("rbxasset", 1, true) ~= nil or tonumber(Icon) ~= nil)
end

--// Square icon holder.
--// Info: Size (default 16), Background (nil | "Accent" | "Main" | Color3), IconColor, IconScale, Corner.
--// Pictures (asset ids / icon tables) keep their own colors; named icons are tinted. \\--
function Library:CreateIconTile(Parent: Instance, Icon: any, Info: { [string]: any }?)
    Info = Info or {}

    local Size = Info.Size or 16
    local Background = Info.Background
    local Tile = New("Frame", {
        BackgroundColor3 = typeof(Background) == "Color3" and Background or "MainColor",
        BackgroundTransparency = Background and 0 or 1,
        LayoutOrder = Info.LayoutOrder or 0,
        Size = UDim2.fromOffset(Size, Size),
        Parent = Parent,
    })

    if Background then
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Info.Corner or math.max(Library.CornerRadius / 2, 3)),
                Parent = Tile,
            })
        )

        if Background == "Accent" then
            Tile.BackgroundColor3 = Color3.new(1, 1, 1)
            Library.Registry[Tile].BackgroundColor3 = nil
            Library:ApplyAccentGradient(Tile, 45)
        elseif Background == "Main" then
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Tile,
            })
        end
    end

    local Picture = IsPictureIcon(Icon)
    local TintColor = Info.IconColor
    if TintColor == nil then
        TintColor = Background == "Accent" and Color3.new(1, 1, 1) or "FontColor"
    end

    local Image = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Picture and Color3.new(1, 1, 1) or TintColor,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(Info.IconScale or (Background and 0.56 or 1), Info.IconScale or (Background and 0.56 or 1)),
        Parent = Tile,
    })
    if Picture and Background then
        Image.Size = UDim2.fromScale(1, 1)
        New("UICorner", {
            CornerRadius = UDim.new(0, Info.Corner or math.max(Library.CornerRadius / 2, 3)),
            Parent = Image,
        })
    end
    Library:ApplyIcon(Image, Icon)

    return Tile, Image
end

function Library:UpdateTabIndicators()
    for _, Tab in Library.Tabs do
        local Indicator = Tab.Button and Tab.Button:FindFirstChild("ActiveIndicator")
        if Indicator then
            TweenService:Create(Indicator, Library.TweenInfo, {
                BackgroundTransparency = Tab == Library.ActiveTab and 0 or 1,
            }):Play()
        end
    end
end

function Library:NewTrackedScale(Parent: Instance, Offset: number?)
    local ScaleFactor = Library.DPIScale or 1
    local Scale = New("UIScale", {
        Scale = ScaleFactor - (Offset or 0),
        Parent = Parent,
    })
    table.insert(Library.Scales, Scale)
    if Offset then
        Library.ScalesOffset[Scale] = Offset
    end
    return Scale
end

function Library:FindScaledContainer(UI: Instance): GuiObject?

    local Current = UI and UI.Parent
    while Current and Current ~= game do
        if Current:IsA("GuiObject") and Current:FindFirstChildOfClass("UIScale") then
            return Current
        end
        Current = Current.Parent
    end
    return nil
end

--// Rendered scale of a UI element: the product of every ancestor UIScale.
--// Strokes and offsets inside that tree are multiplied by it, so 1px of source
--// ends up thinner than a pixel on mobile (~0.5) and needs compensating. \\--
function Library:GetUIScale(UI: Instance?): number
    local Total = 1
    local Current = UI and UI.Parent
    while Current and Current ~= game do
        if Current:IsA("GuiObject") then
            local UiScale = Current:FindFirstChildOfClass("UIScale")
            if UiScale then
                Total *= UiScale.Scale
            end
        end
        Current = Current.Parent
    end
    return math.max(Total, 0.0001)
end

local function SafeParentUI(UI: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        UI.Parent = DestinationParent
    end)

    if not (success and UI.Parent) then
        UI.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local function SetAlwaysOnTop(Gui: ScreenGui, Enabled: boolean)
    if not Gui then
        return
    end

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Gui, "OnTopOfCoreBlur", Enabled)
        elseif setscriptable then
            setscriptable(Gui, "OnTopOfCoreBlur", true)
            Gui.OnTopOfCoreBlur = Enabled
            setscriptable(Gui, "OnTopOfCoreBlur", false)
        end
    end)
end

do
    local GuiParent = gethui()
    local ExistingGui = GuiParent:FindFirstChild("Astral")
    if ExistingGui then

        if getgenv().Library and typeof(getgenv().Library.Unload) == "function" and not getgenv().Library.Unloaded then
            pcall(getgenv().Library.Unload, getgenv().Library)
        else

            pcall(function() ExistingGui:Destroy() end)
        end
    end
end

local ScreenGui = New("ScreenGui", {
    Name = "Astral",
    DisplayOrder = 998,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,

    IgnoreGuiInset = true,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Inst)
    Library:RemoveFromRegistry(Inst)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

local Cursor, CursorV, CursorCustomImage
do

    local CursorZIndex = Library.CursorZIndex
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = CursorZIndex,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = CursorZIndex - 1,
        Parent = Cursor,
    })

    CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = CursorZIndex,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = CursorZIndex - 1,
        Parent = CursorV,
    })

    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = CursorZIndex,
        Visible = false,
        Parent = ScreenGui
    })
end

local InnerCross = { Cursor, CursorV }
local CustomImageEnabled = false

local function RestoreMouseIcon()
    pcall(function()
        RunService:UnbindFromRenderStep(Library.ShowCursorBinding)
        RunService.RenderStepped:Wait()
    end)

    UserInputService.MouseIconEnabled = Library.OriginalMouseIconEnabled
    if Cursor then Cursor.Visible = false end
    if CursorV then CursorV.Visible = false end
    if CursorCustomImage then CursorCustomImage.Visible = false end
end

Library.Cursor = {}

function Library.Cursor:ResetCross()
    for _, Inner in InnerCross do
        Library.Registry[Inner].BackgroundColor3 = "WhiteColor"
        Inner.BackgroundColor3 = Library.Scheme.WhiteColor
    end
end

function Library.Cursor:ResetIcon()
    CustomImageEnabled = false
    Cursor.Visible = true
    CursorV.Visible = true
    CursorCustomImage.Visible = false
    CursorCustomImage.ImageColor3 = Color3.new(1, 1, 1)
    CursorCustomImage.Size = UDim2.fromOffset(20, 20)
end

function Library.Cursor:ResetCursor()
    Library.Cursor:ResetCross()
    Library.Cursor:ResetIcon()
end

function Library.Cursor:ChangeCrossColor(Color: Color3)
    assert(typeof(Color) == "Color3", "Color3 expected.")
    for _, Inner in InnerCross do
        Inner.BackgroundColor3 = Color
        Library.Registry[Inner].BackgroundColor3 = nil
    end
end

function Library.Cursor:ChangeIcon(ImageId: string)
    if not ImageId or ImageId == "" then
        Library.Cursor:ResetIcon()
        return
    end

    local Icon = Library:GetCustomIcon(ImageId)
    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

    Cursor.Visible = false
    CursorV.Visible = false
    CustomImageEnabled = true
    CursorCustomImage.Visible = true
    CursorCustomImage.Image = Icon.Url
    CursorCustomImage.ImageRectOffset = Icon.ImageRectOffset
    CursorCustomImage.ImageRectSize = Icon.ImageRectSize
end

function Library.Cursor:ChangeIconColor(Color: Color3)
    assert(typeof(Color) == "Color3", "Color3 expected.")
    CursorCustomImage.ImageColor3 = Color
end

function Library.Cursor:ChangeIconSize(Size: UDim2)
    assert(typeof(Size) == "UDim2", "UDim2 expected.")
    CursorCustomImage.Size = Size
end

local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),

        ZIndex = Library.TooltipZIndex + 1,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = NotificationArea,
        })
    )

    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        Parent = NotificationArea,
    })
end

function Library:ResetCursorIcon()
    warn("Astral:ResetCursorIcon is deprecated, please use Astral.Cursor:ResetIcon instead.")
    Library.Cursor:ResetIcon()
end

function Library:ChangeCursorIcon(ImageId: string)
    warn("Astral:ChangeCursorIcon is deprecated, please use Astral.Cursor:ChangeIcon instead.")
    Library.Cursor:ChangeIcon(ImageId)
end

function Library:ChangeCursorIconSize(Size: UDim2)
    warn("Astral:ChangeCursorIconSize is deprecated, please use Astral.Cursor:ChangeIconSize instead.")
    Library.Cursor:ChangeIconSize(Size)
end

function Library:ChangeCursorIconColor(Color: Color3)
    warn("Astral:ChangeCursorIconColor is deprecated, please use Astral.Cursor:ChangeIconColor instead.")
    Library.Cursor:ChangeIconColor(Color)
end

function Library:ChangeCursorCrossColor(Color: Color3)
    warn("Astral:ChangeCursorCrossColor is deprecated, please use Astral.Cursor:ChangeCrossColor instead.")
    Library.Cursor:ChangeCrossColor(Color)
end

function Library:ResetCursorCross()
    warn("Astral:ResetCursorCross is deprecated, please use Astral.Cursor:ResetCross instead.")
    Library.Cursor:ResetCross()
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetAccentShade(_Step: number): Color3
    return (Library.Scheme and Library.Scheme.AccentColor) or Color3.fromRGB(90, 160, 255)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)

        Library:Notify(Error)

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(
    UI: GuiObject,
    DragFrame: GuiObject,
    IgnoreToggled: boolean?,
    IsMainWindow: boolean?,
    SnapConfig: { Enabled: boolean, Distance: number?, Margin: number?, AvoidCoreGui: boolean? }?
)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed

    local SnapGuideX, SnapGuideY

    local function GetSnapGuides()
        if not SnapGuideX then
            SnapGuideX = New("Frame", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(0, 2, 1, 0),
                Visible = false,
                ZIndex = 10000,
                Parent = ScreenGui,
            })
        end

        if not SnapGuideY then
            SnapGuideY = New("Frame", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Visible = false,
                ZIndex = 10000,
                Parent = ScreenGui,
            })
        end

        return SnapGuideX, SnapGuideY
    end

    local function HideSnapGuides()
        if SnapGuideX then
            SnapGuideX.Visible = false
        end
        if SnapGuideY then
            SnapGuideY.Visible = false
        end
    end

    local function GetOwningScreenGui(): ScreenGui?
        return UI:FindFirstAncestorOfClass("ScreenGui")
    end

    --// Anything that is not the main window sits on top of it. Active makes the frame sink input so
    --// whatever is underneath (including the window's own drag bar) does not receive it. \\--
    if not IsMainWindow then
        DragFrame.Active = true
        UI.Active = true
    end

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        if IsMainWindow then
            Library.MainWindowWasMoved = true
        end

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            HideSnapGuides()
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        local OwningScreenGui = GetOwningScreenGui()

        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (OwningScreenGui and OwningScreenGui.Parent)
            or not UI.Visible
        then

            Dragging = false
            HideSnapGuides()
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            local NewX = FramePos.X.Offset + Delta.X
            local NewY = FramePos.Y.Offset + Delta.Y

            if SnapConfig and SnapConfig.Enabled then
                local ViewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
                local Distance = SnapConfig.Distance or 28
                local Margin = SnapConfig.Margin or 8

                local AbsX = FramePos.X.Scale * ViewportSize.X + NewX
                local AbsY = FramePos.Y.Scale * ViewportSize.Y + NewY

                local ElemSize = UI.AbsoluteSize
                local TargetsX, TargetsY = GetSnapEdges(ElemSize, ViewportSize, Margin, SnapConfig.AvoidCoreGui ~= false)
                local SnappedX, SnappedXName = GetClosestSnapTarget(AbsX, TargetsX, Distance)
                local SnappedY, SnappedYName = GetClosestSnapTarget(AbsY, TargetsY, Distance)

                if SnappedX then
                    NewX = SnappedX - FramePos.X.Scale * ViewportSize.X
                end
                if SnappedY then
                    NewY = SnappedY - FramePos.Y.Scale * ViewportSize.Y
                end

                local GuideX, GuideY = GetSnapGuides()
                GuideX.Visible = SnappedX ~= nil
                if SnappedX then
                    GuideX.Position = UDim2.fromOffset(GetSnapGuideOffset(SnappedXName, SnappedX, ElemSize.X), 0)
                end

                GuideY.Visible = SnappedY ~= nil
                if SnappedY then
                    GuideY.Position = UDim2.fromOffset(0, GetSnapGuideOffset(SnappedYName, SnappedY, ElemSize.Y))
                end
            end

            UI.Position =
                UDim2.new(FramePos.X.Scale, NewX, FramePos.Y.Scale, NewY)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

--// Custom scrollbars: native ones are always-on and theme-clashing, so every
--// ScrollingFrame gets a thin floating thumb instead. It reveals on scroll
--// (or hover), fades out after a short idle, and can be dragged.
--// Parented to the ScreenGui: children of a ScrollingFrame live in canvas
--// space, which would make the thumb scroll with the content. \\--
local CustomScrollbars = {}

--// Drawn above every library band (search rows sit at 12002), because ZIndex
--// is flattened per ScreenGui: children of the scrolled container would
--// otherwise paint over the thumb and hide it. \\--
local ScrollbarTrackZ, ScrollbarThumbZ = 13000, 13001

local function ScrollbarAncestorsVisible(Scroll: ScrollingFrame): boolean
    local Current: Instance? = Scroll
    while Current and not Current:IsA("ScreenGui") do
        if Current:IsA("GuiObject") and not Current.Visible then
            return false
        end
        Current = Current.Parent
    end
    return true
end

function Library:AddCustomScrollbar(Scroll: ScrollingFrame)
    if not Scroll or not Scroll:IsA("ScrollingFrame") then
        return
    end

    for _, Existing in ipairs(CustomScrollbars) do
        if Existing.Scroll == Scroll then
            return
        end
    end

    local Screen = Scroll:FindFirstAncestorOfClass("ScreenGui")
    if not Screen then
        return
    end

    --// Live in the same coordinate space as the scrolled UI, not in raw screen
    --// pixels: every window/menu is wrapped in a UIScale (mobile commonly runs
    --// at ~0.55), and a screen-space thumb would ignore that scale and drift
    --// away from the frame it belongs to. \\--
    local Scaled = Library:FindScaledContainer(Scroll)
    local Layer: Instance = Scaled or Screen

    local function LayerScale(): number
        local Total = 1
        local Current: Instance? = Scroll.Parent
        while Current and Current ~= Layer.Parent do
            if Current:IsA("GuiObject") or Current:IsA("ScreenGui") then
                local UiScale = Current:FindFirstChildOfClass("UIScale")
                if UiScale then
                    Total *= UiScale.Scale
                end
            end
            Current = Current.Parent
        end
        return math.max(Total, 0.0001)
    end

    Scroll.ScrollBarThickness = 0
    Scroll.ScrollBarImageTransparency = 1

    local Thumb = New("Frame", {
        Name = "AstralScrollbar",
        BackgroundColor3 = "FontColor",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(4, 0),
        Visible = false,
        ZIndex = ScrollbarThumbZ,
        Parent = Layer,
    })
    Library:AddToRegistry(Thumb, { BackgroundColor3 = "AccentColor" })
    --// Same corner radius as every other element (`CornerRadius / 2`), so the
    --// thumb reads as part of the UI instead of a capsule. \\--
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Thumb,
        })
    )

    --// Faint rounded trough behind the thumb. It fades in with the thumb, so
    --// the control reads as a scrollbar while it is active and disappears
    --// completely when idle. \\--
    local Track = New("Frame", {
        Name = "AstralScrollbarTrack",
        BackgroundColor3 = "AccentColor",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(2, 0),
        Visible = false,
        ZIndex = ScrollbarTrackZ,
        Parent = Layer,
    })
    Library:AddToRegistry(Track, { BackgroundColor3 = "AccentColor" })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Track,
        })
    )

    local State = {
        Scroll = Scroll,
        Thumb = Thumb,
        Track = Track,
        Layer = Layer,
        LayerScale = LayerScale,
        Hover = false,
        Dragging = false,
        LastCanvasY = Scroll.CanvasPosition.Y,
        IdleAt = os.clock(),
        HideToken = 0,
        Shown = false,
    }

    local function Reveal()
        State.IdleAt = os.clock()
        State.HideToken += 1
        if not State.Shown then
            State.Shown = true
            Thumb.Visible = true
            Track.Visible = true
            Thumb.BackgroundTransparency = 1
            Track.BackgroundTransparency = 1
        end
        --// Only fade in when actually faded: scrolling fires this every
        --// frame, and spawning a tween per frame would be wasteful. \\--
        if Thumb.BackgroundTransparency > 0.5 then
            TweenService:Create(Thumb, TweenInfo.new(0.15), { BackgroundTransparency = 0.4 }):Play()
        end
        if Track.BackgroundTransparency > 0.95 then
            TweenService:Create(Track, TweenInfo.new(0.15), { BackgroundTransparency = 0.94 }):Play()
        end
    end

    local function Conceal()
        if State.Hover or State.Dragging then
            return
        end

        State.IdleAt = os.clock()
        State.HideToken += 1
        local Token = State.HideToken
        TweenService:Create(Thumb, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(Track, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.delay(0.32, function()
            if Token == State.HideToken and not State.Hover and not State.Dragging then
                Thumb.Visible = false
                Track.Visible = false
                State.Shown = false
            end
        end)
    end

    Thumb.MouseEnter:Connect(function()
        State.Hover = true
        Reveal()
        TweenService:Create(Thumb, TweenInfo.new(0.12), { BackgroundTransparency = 0.2 }):Play()
    end)
    Thumb.MouseLeave:Connect(function()
        if State.Dragging then
            return
        end
        State.Hover = false
        State.IdleAt = os.clock()
        if State.Shown then
            TweenService:Create(Thumb, TweenInfo.new(0.18), { BackgroundTransparency = 0.4 }):Play()
        end
    end)

    Thumb.InputBegan:Connect(function(Input: InputObject)
        local IsTouch = Input.UserInputType == Enum.UserInputType.Touch
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and not IsTouch then
            return
        end

        State.Dragging = true
        State.Hover = true
        Reveal()

        TweenService:Create(Thumb, TweenInfo.new(0.12), { BackgroundTransparency = 0.1 }):Play()

        local StartY = Input.Position.Y
        local StartCanvas = Scroll.CanvasPosition.Y
        local ChangedConnection, EndedConnection

        ChangedConnection = UserInputService.InputChanged:Connect(function(MoveInput: InputObject)
            local Moving = MoveInput.UserInputType == Enum.UserInputType.MouseMovement
                or MoveInput.UserInputType == Enum.UserInputType.Touch
            if not Moving then
                return
            end

            --// CanvasPosition is in the scroll's own (unscaled) units, so the
            --// pointer delta is converted into the same space before mapping
            --// across the remaining track distance. \\--
            local LayerScale = State.LayerScale()
            local FrameH  = Scroll.AbsoluteSize.Y / LayerScale
            local Travel  = math.max(FrameH - 4 - Thumb.Size.Y.Offset, 1)
            local MaxScroll = math.max((Scroll.AbsoluteCanvasSize.Y - Scroll.AbsoluteSize.Y) / LayerScale, 1)
            local Delta = ((MoveInput.Position.Y - StartY) / LayerScale) * (MaxScroll / Travel)
            Scroll.CanvasPosition = Vector2.new(
                Scroll.CanvasPosition.X,
                math.clamp(StartCanvas + Delta, 0, MaxScroll)
            )
            State.IdleAt = os.clock()
        end)

        EndedConnection = UserInputService.InputEnded:Connect(function(EndInput: InputObject)
            local Released = EndInput.UserInputType == Enum.UserInputType.MouseButton1
                or EndInput.UserInputType == Enum.UserInputType.Touch
            if not Released then
                return
            end

            State.Dragging = false
            State.Hover = false
            State.IdleAt = os.clock()
            TweenService:Create(Thumb, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.4,
            }):Play()
            if ChangedConnection then
                ChangedConnection:Disconnect()
            end
            if EndedConnection then
                EndedConnection:Disconnect()
            end
        end)
    end)

    State.Reveal = Reveal
    State.Conceal = Conceal

    table.insert(CustomScrollbars, State)
end

do
    local function SyncScrollbar(State)
        local Scroll, Thumb, Track = State.Scroll, State.Thumb, State.Track
        if not Scroll.Parent then
            Thumb:Destroy()
            Track:Destroy()
            return false
        end

        local AbsPos, AbsSize = Scroll.AbsolutePosition, Scroll.AbsoluteSize
        local Canvas = Scroll.AbsoluteCanvasSize

        if not ScrollbarAncestorsVisible(Scroll) or AbsSize.Y < 8 or Canvas.Y <= AbsSize.Y + 1 then
            if Thumb.Visible then
                Thumb.Visible = false
                Track.Visible = false
                State.Shown = false
            end
            return true
        end

        --// Everything below is expressed in the layer's local (unscaled) units,
        --// so the UIScale on the window/menu applies to the scrollbar exactly
        --// like it applies to the elements next to it. \\--
        local Scale = State.LayerScale()
        local Layer = State.Layer
        local OriginX, OriginY = 0, 0
        if Layer and Layer:IsA("GuiObject") then
            local LayerPos = Layer.AbsolutePosition
            OriginX, OriginY = LayerPos.X, LayerPos.Y
        end

        local PosX = (AbsPos.X - OriginX) / Scale
        local PosY = (AbsPos.Y - OriginY) / Scale
        local SizeX = AbsSize.X / Scale
        local SizeY = AbsSize.Y / Scale
        local CanvasY = Canvas.Y / Scale
        local ScrollY = Scroll.CanvasPosition.Y

        local Pad = 2
        local Rail = math.max(SizeY - Pad * 2, 1)
        local ThumbHeight = math.clamp(SizeY * (SizeY / CanvasY), 24, Rail)
        local MaxScroll = math.max(CanvasY - SizeY, 1)
        local Progress = math.clamp(ScrollY / MaxScroll, 0, 1)

        local Width = (State.Hover or State.Dragging) and 6 or 4
        local Right = PosX + SizeX - Pad

        Track.Size = UDim2.fromOffset(2, Rail)
        Track.Position = UDim2.fromOffset(Right - 3, PosY + Pad)
        Track.ZIndex = ScrollbarTrackZ

        Thumb.Size = UDim2.fromOffset(Width, ThumbHeight)
        Thumb.Position = UDim2.fromOffset(
            Right - Width,
            PosY + Pad + Progress * (Rail - ThumbHeight)
        )
        Thumb.ZIndex = ScrollbarThumbZ

        if Scroll.CanvasPosition.Y ~= State.LastCanvasY then
            State.LastCanvasY = Scroll.CanvasPosition.Y
            State.Reveal()
        end

        if State.Shown and os.clock() - State.IdleAt > 1.6 then
            State.Conceal()
        end

        return true
    end

    Library:GiveSignal(RunService.Heartbeat:Connect(function()
        for Index = #CustomScrollbars, 1, -1 do
            local State = CustomScrollbars[Index]
            if not SyncScrollbar(State) then
                table.remove(CustomScrollbars, Index)
            end
        end
    end))
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1,
        Transparency = 0.2,
        ZIndex = 2,
        Parent = Frame,
    })
    local ShadowStroke = New("UIStroke", {
        Color = "DarkColor",
        Thickness = 1,
        Transparency = 0.5,
        ZIndex = 1,
        Parent = Frame,
    })
    return OutlineStroke, ShadowStroke
end

function Library:AddFocusHighlight(Box, Stroke: UIStroke?, Options: { [string]: any }?)
    if typeof(Box) ~= "Instance" or not Box:IsA("GuiObject") or not Box:IsA("TextBox") then
        return
    end

    Options = Options or {}

    if Options.Enabled == false then
        return
    end

    local AccentKey = Options.Accent or "AccentColor"
    local RestColorKey = Options.Color or "OutlineColor"

    Stroke = Stroke or Box:FindFirstChildOfClass("UIStroke")

    if not Stroke then
        Stroke = New("UIStroke", {
            Color = RestColorKey,
            Parent = Box,
        })
    end

    local StrokeRegistry = Library.Registry[Stroke]
    if typeof(StrokeRegistry) == "table" and typeof(StrokeRegistry.Color) == "string" then
        RestColorKey = StrokeRegistry.Color
    end

    --// Single thin solid accent ring on focus. No layered glow: extra
    --// strokes cost two instances + two tweens per field and read muddy. \\--

    local BackgroundTarget: GuiObject = Options.BackgroundTarget or Box
    local TintBackground = Options.Background ~= false and BackgroundTarget ~= nil

    local BoxRegistry = Library.Registry[BackgroundTarget]
    local RestBackgroundKey = typeof(BoxRegistry) == "table" and BoxRegistry.BackgroundColor3 or nil
    local InitialBackgroundColor = BackgroundTarget.BackgroundColor3

    local RestTransparency = Stroke.Transparency
    if Options.Transparency ~= nil then
        RestTransparency = Options.Transparency
    end

    local RestThickness = Stroke.Thickness
    if Options.Thickness ~= nil then
        RestThickness = Options.Thickness
    end

    local FocusedTransparency = 0
    if Options.FocusedTransparency ~= nil then
        FocusedTransparency = Options.FocusedTransparency
    end

    --// One shared ring width for every field: searchbar, textboxes,
    --// dropdown search, pickers. Fixed constant so focus looks identical
    --// everywhere regardless of each stroke's resting thickness. 2 reads as
    --// a deliberate border on phone screens, where 1 washed out. \\--
    local FocusedThickness = 2
    if Options.FocusedThickness ~= nil then
        FocusedThickness = Options.FocusedThickness
    end

    local BackgroundShift = 6
    if Options.BackgroundShift ~= nil then
        BackgroundShift = Options.BackgroundShift
    end

    local State = {
        Box = Box,
        Stroke = Stroke,
        BackgroundTarget = TintBackground and BackgroundTarget or nil,
        Focused = false,
        ZBoosted = false,

        RestColorKey = RestColorKey,
        AccentKey = AccentKey,

        RestBackgroundKey = RestBackgroundKey,
        InitialBackgroundColor = InitialBackgroundColor,

        RestTransparency = RestTransparency,
        RestThickness = RestThickness,
        FocusedTransparency = FocusedTransparency,
        FocusedThickness = FocusedThickness,
        BackgroundShift = BackgroundShift,
    }

    --// Lifts the highlighted field above its siblings while focused so the
    --// accent border is never covered by neighboring elements. \\--
    function State:SetZBoost(Boosted: boolean)
        if Boosted == self.ZBoosted then
            return
        end
        self.ZBoosted = Boosted

        local Targets = { self.Box }
        if self.BackgroundTarget and self.BackgroundTarget ~= self.Box then
            table.insert(Targets, self.BackgroundTarget)
        end

        for _, Target in Targets do
            pcall(function()
                if Boosted then
                    local Top = Target.ZIndex
                    local Parent = Target.Parent
                    if Parent then
                        for _, Sibling in Parent:GetChildren() do
                            if Sibling:IsA("GuiObject") and Sibling.ZIndex > Top then
                                Top = Sibling.ZIndex
                            end
                        end
                    end
                    Target:SetAttribute("AstralRestZIndex", Target.ZIndex)
                    Target.ZIndex = Top + 1
                else
                    local RestZ = Target:GetAttribute("AstralRestZIndex")
                    if typeof(RestZ) == "number" then
                        Target.ZIndex = RestZ
                    end
                end
            end)
        end
    end

    function State:ResolveRestColor()
        local Properties = Library.Registry[self.Stroke]
        local Key = typeof(Properties) == "table" and Properties.Color or nil
        return GetSchemeValue(Key or self.RestColorKey) or self.Stroke.Color
    end

    function State:ResolveAccentColor()
        return GetSchemeValue(self.AccentKey) or self.AccentKey
    end

    function State:ResolveRestBackground()
        if not self.BackgroundTarget then
            return nil
        end

        local Properties = Library.Registry[self.BackgroundTarget]
        local Key = typeof(Properties) == "table" and Properties.BackgroundColor3 or nil

        return GetSchemeValue(Key or self.RestBackgroundKey) or self.InitialBackgroundColor
    end

    function State:Reapply()
        if not self.Focused or not self.Stroke.Parent then
            return
        end

        self.Stroke.Color = self:ResolveAccentColor()
        self.Stroke.Transparency = self.FocusedTransparency
        self.Stroke.Thickness = self:ResolveFocusedThickness()

        if self.BackgroundTarget then
            self.BackgroundTarget.BackgroundColor3 = Library:GetBetterColor(self:ResolveRestBackground(), self.BackgroundShift)
        end
    end

    --// A 1px stroke on a 0.5-scaled mobile window renders as half a pixel, so
    --// the ring washes out (pale top edge) instead of reading as accent. Keep
    --// at least one rendered pixel while leaving desktop untouched. \\--
    function State:ResolveFocusedThickness(): number
        local Scale = Library:GetUIScale(self.Box)
        local Base = self.FocusedThickness
        if Scale >= 0.999 then
            return Base
        end

        --// `UIScale` multiplies the stroke, so divide to land on one device px.
        return math.max(Base / Scale, Base)
    end

    function State:Apply(Focused: boolean)
        self.Focused = Focused

        if not self.Stroke.Parent then
            return
        end

        if Focused then
            self:SetZBoost(true)
            TweenService:Create(self.Stroke, Library.TweenInfo, {
                Color = self:ResolveAccentColor(),
                Thickness = self:ResolveFocusedThickness(),
                Transparency = self.FocusedTransparency,
            }):Play()

            if self.BackgroundTarget then
                TweenService:Create(self.BackgroundTarget, Library.TweenInfo, {
                    BackgroundColor3 = Library:GetBetterColor(self:ResolveRestBackground(), self.BackgroundShift),
                }):Play()
            end
        else
            self:SetZBoost(false)
            TweenService:Create(self.Stroke, Library.TweenInfo, {
                Color = self:ResolveRestColor(),
                Thickness = self.RestThickness,
                Transparency = self.RestTransparency,
            }):Play()

            if self.BackgroundTarget then
                TweenService:Create(self.BackgroundTarget, Library.TweenInfo, {
                    BackgroundColor3 = self:ResolveRestBackground(),
                }):Play()
            end
        end
    end

    table.insert(Library.FocusHighlights, State)

    Library:GiveSignal(Box.Focused:Connect(function()
        State:Apply(true)
    end))
    Library:GiveSignal(Box.FocusLost:Connect(function()
        State:Apply(false)
    end))

    --// Mobile scale is applied/resolved after the widget exists, so the ring
    --// thickness has to be recomputed when the DPI scale changes. \\--
    if not Library.FocusHighlightScaleHooked then
        Library.FocusHighlightScaleHooked = true
        Library:GiveDPIScaleCallback(function()
            for _, Highlight in Library.FocusHighlights do
                if Highlight.Focused then
                    Highlight:Reapply()
                end
            end
        end)
    end

    return State
end

function Library:AddBlank(Frame: GuiObject, Size: UDim2)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = Size or UDim2.fromScale(0, 0),
        Parent = Frame,
    })
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    local Holder = New("Frame", {
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:GetNextOverlayPosition(): UDim2

    local Step = Library.OverlayCascadeStep
    Library.OverlayCascadeStep = (Step + 1) % 8
    local Offset = 6 + (Step * 18)
    return UDim2.fromOffset(Offset, Offset)
end

function Library:NextOverlayZIndex(): number

    local Slot = Library.OverlayZIndexCounter % Library.OverlayZIndexBudget
    Library.OverlayZIndexCounter += 1
    return Library.OverlayZIndex + (Slot * Library.OverlayZIndexSlotSize)
end

function Library:BringOverlayToFront(RootInstance: GuiObject, OldBaseZIndex: number, OldFrontGeneration: number?)

    if OldFrontGeneration ~= nil and OldFrontGeneration == Library.OverlayFrontGeneration then
        return OldBaseZIndex, OldFrontGeneration
    end

    local NewBaseZIndex = Library:NextOverlayZIndex()
    local Delta = NewBaseZIndex - OldBaseZIndex

    if Delta ~= 0 then
        RootInstance.ZIndex += Delta
        for _, Descendant in RootInstance:GetDescendants() do
            if Descendant:IsA("GuiObject") then
                Descendant.ZIndex += Delta
            end
        end
    end

    Library.OverlayFrontGeneration += 1
    return NewBaseZIndex, Library.OverlayFrontGeneration
end

function Library:RegisterOverlay(OverlayType: string, Name: string?, Table: { [any]: any })
    Library.OverlayIdCounter = Library.OverlayIdCounter + 1
    local Id = Library.OverlayIdCounter

    Table.Id = Id
    Table.OverlayType = OverlayType
    Table.OverlayName = Name or (OverlayType .. " #" .. Id)

    Library.AllOverlays[Id] = Table

    Library.Overlays[Id] = Table
    table.insert(Library.OverlaysOrder, Table)

    if not Table.SetVisible then
        function Table:SetVisible(Visible: boolean)
            local Root = Table.Holder or Table.Label or Table.Button or Table.Menu
            if Root then
                Root.Visible = Visible
            end
        end
    end

    local BaseSetVisible = Table.SetVisible
    function Table:SetVisible(Visible: boolean, ...)
        if Visible and Library.Overlays[Id] ~= Table and not Table.__Destroyed then
            Library.Overlays[Id] = Table
            table.insert(Library.OverlaysOrder, Table)
        end

        if Visible and not Table.__Destroyed then
            Library.AllOverlays[Id] = Table
        end
        return BaseSetVisible(Table, Visible, ...)
    end

    if not Table.IsVisible then
        function Table:IsVisible(): boolean
            local Root = Table.Holder or Table.Label or Table.Button or Table.Menu
            return Root ~= nil and Root.Visible or false
        end
    end

    if not Table.Remove then
        function Table:Remove()
            local Root = Table.Holder or Table.Label or Table.Button or Table.Menu
            if Root then
                Root.Visible = false
            end
        end
    end

    local BaseRemove = Table.Remove

    function Table:Remove()
        if Library.Overlays[Id] == Table then
            Library.Overlays[Id] = nil
        end

        for Index, Entry in Library.OverlaysOrder do
            if Entry == Table then
                table.remove(Library.OverlaysOrder, Index)
                break
            end
        end

        Library.AllOverlays[Id] = Table

        if Table.SetVisible then
            pcall(Table.SetVisible, Table, false)
        end
    end

    function Table:Destroy()
        if Table.__Destroyed then
            return
        end
        Table.__Destroyed = true

        if Table.Remove then
            pcall(Table.Remove, Table)
        end

        if Library.Overlays[Id] == Table then
            Library.Overlays[Id] = nil
        end
        for Index, Entry in Library.OverlaysOrder do
            if Entry == Table then
                table.remove(Library.OverlaysOrder, Index)
                break
            end
        end

        Library.AllOverlays[Id] = nil

        BaseRemove(Table)
    end

    Library.Overlays[Id] = Table
    table.insert(Library.OverlaysOrder, Table)

    return Table
end

function Library:GetOverlay(Id: number)

    return Library.Overlays[Id] or Library.AllOverlays[Id]
end

function Library:GetOverlays(OverlayType: string?)

    local Result = {}
    for Id, Overlay in Library.AllOverlays do
        if not OverlayType or Overlay.OverlayType == OverlayType then
            table.insert(Result, Overlay)
        end
    end
    return Result
end

function Library:SetOverlayVisible(Id: number, Visible: boolean)
    local Overlay = Library.Overlays[Id]
    if Overlay then
        Overlay:SetVisible(Visible)
    end
    return Overlay
end

function Library:ToggleOverlay(Id: number)
    local Overlay = Library.Overlays[Id]
    if Overlay then
        Overlay:SetVisible(not Overlay:IsVisible())
    end
    return Overlay
end

function Library:RemoveOverlay(Id: number)
    local Overlay = Library.Overlays[Id]
    if Overlay then
        Overlay:Remove()
    end
end

function Library:SetAllOverlaysVisible(Visible: boolean, OverlayType: string?)

    for Id, Overlay in Library.AllOverlays do
        if OverlayType and Overlay.OverlayType ~= OverlayType then
            continue
        end

        Overlay:SetVisible(Visible, true)
    end
end

function Library:RemoveAllOverlays(OverlayType: string?)

    for Id, Overlay in Library.AllOverlays do
        if OverlayType and Overlay.OverlayType ~= OverlayType then
            continue
        end
        Overlay:Remove()
    end
end

--// Watermark: a draggable label overlay (same look as every other overlay), hidden until shown. \\--
function Library:SetWatermark(Text: string)
    if not Library.WatermarkLabel then
        Library.WatermarkLabel = Library:AddDraggableLabel(Text)
        Library.WatermarkLabel:SetVisible(Library.WatermarkVisible == true)
    else
        Library.WatermarkLabel:SetText(Text)
    end

    return Library.WatermarkLabel
end

function Library:SetWatermarkVisibility(Visible: boolean)
    Library.WatermarkVisible = Visible == true

    if Library.WatermarkLabel then
        Library.WatermarkLabel:SetVisible(Library.WatermarkVisible)
    elseif Library.WatermarkVisible then
        Library:SetWatermark("")
    end
end

function Library:AddDraggableLabel(Text: string, Icon: string?, IconPosition: string?)
    local Table = {}

    local OwningScreenGui = ScreenGui
    local BaseZIndex = Library:NextOverlayZIndex()

    if typeof(IconPosition) ~= "string" then
        IconPosition = "left"
    end

    IconPosition = string.lower(IconPosition)
    assert(IconPosition == "left" or IconPosition == "right", "Icon Position needs to be either 'left' or 'right'.")

    local IconImage
    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = Library:GetNextOverlayPosition(),
        Text = Text,
        TextSize = 15,
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Label,
        })
    )
    local LabelPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = Label,
    })
    Library:NewTrackedScale(Label)
    Library:AddStyleRoot(Label)
    Library:AddOutline(Label)

    Library:MakeDraggable(Label, Label, true)

    Table.Label = Label

    function Table:SetText(Text: string)
        if not Label.Parent then
            return
        end
        Label.Text = Text
    end

    function Table:SetIcon(NewIcon: string)
        Icon = NewIcon

        local IsNotEmpty = Icon and Trim(tostring(Icon)) ~= ""
        if IsNotEmpty then
            local CustomIcon = Library:GetCustomIcon(Icon)
            assert(CustomIcon, "Icon must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            IconImage = IconImage or New("ImageLabel", {
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                Size = UDim2.fromOffset(16, 16),
                ZIndex = BaseZIndex + 1,
                Parent = Label,
            })

            IconImage.Image = CustomIcon.Url
            IconImage.ImageRectOffset = CustomIcon.ImageRectOffset
            IconImage.ImageRectSize = CustomIcon.ImageRectSize
        end

        if IconImage then
            IconImage.Visible = IsNotEmpty
        end
        Table:SetIconPosition(IconPosition)
    end

    function Table:SetIconPosition(NewPosition: string)
        IconPosition = string.lower(NewPosition)
        assert(IconPosition == "left" or IconPosition == "right", "Icon Position needs to be either 'left' or 'right'.")

        local IsNotEmpty = Icon and Trim(tostring(Icon)) ~= ""
        LabelPadding.PaddingLeft = UDim.new(0, (IsNotEmpty and IconPosition == "left") and 34 or 12)
        LabelPadding.PaddingRight = UDim.new(0, (IsNotEmpty and IconPosition == "right") and 34 or 12)

        if IconImage then
            if IconPosition == "left" then
                IconImage.AnchorPoint = Vector2.new(0, 0.5)
                IconImage.Position = UDim2.new(0, -22, 0.5, 0)
            else
                IconImage.AnchorPoint = Vector2.new(1, 0.5)
                IconImage.Position = UDim2.new(1, 22, 0.5, 0)
            end
        end
    end

    Table:SetIcon(Icon)

    function Table:SetVisible(Visible: boolean)
        if Label then
            Label.Visible = Visible
        end
    end

    function Table:IsVisible(): boolean
        return Label ~= nil and Label.Visible
    end

    function Table:Remove()
        if Label then
            Label.Visible = false
        end
    end

    Library:RegisterOverlay("DraggableLabel", Text, Table)

    return Table
end

function Library:AddDraggableButton(Text: string, Func, ExcludeScaling: boolean?)
    local Table = {}

    local OwningScreenGui = ScreenGui
    local BaseZIndex = Library:NextOverlayZIndex()

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = Library:GetNextOverlayPosition(),
        TextSize = 16,
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        Library:NewTrackedScale(Button)
    end
    Library:AddOutline(Button)

    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button

    function Table:SetText(Text: string)
        local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

        Button.Text = Text
        Button.Size = UDim2.fromOffset(X + 24, Y + 12)
    end
    Table:SetText(Text)

    function Table:SetVisible(Visible: boolean)
        if not Button.Parent then
            return
        end
        Button.Visible = Visible
    end

    function Table:IsVisible(): boolean
        return Button ~= nil and Button.Visible
    end

    function Table:Remove()
        if Button then
            Button.Visible = false
        end
    end

    Library:RegisterOverlay("DraggableButton", Text, Table)

    return Table
end

function Library:AddDraggableImageButton(Icon, IconSize, Func, ExcludeScaling: boolean?)
    local Table = {}

    if typeof(IconSize) == "function" then
        Func = IconSize
        IconSize = 24
    end
    IconSize = tonumber(IconSize) or 24

    local OwningScreenGui = ScreenGui
    local BaseZIndex = Library:NextOverlayZIndex()

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = Library:GetNextOverlayPosition(),
        Size = UDim2.fromOffset(IconSize + 12, IconSize + 12),
        Text = "",
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })

    local IconImage = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(IconSize, IconSize),
        ImageColor3 = "FontColor",
        ZIndex = BaseZIndex + 1,
        Parent = Button,
    })

    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        Library:NewTrackedScale(Button)
    end
    Library:AddOutline(Button)

    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button

    function Table:SetIcon(NewIcon: string)
        Icon = NewIcon or Icon

        local CustomIcon = Library:GetCustomIcon(Icon)
        assert(CustomIcon, "Icon must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        IconImage.Image = CustomIcon.Url
        IconImage.ImageRectOffset = CustomIcon.ImageRectOffset
        IconImage.ImageRectSize = CustomIcon.ImageRectSize
    end

    function Table:SetIconSize(NewSize: number)
        IconSize = NewSize
        IconImage.Size = UDim2.fromOffset(IconSize, IconSize)
        Button.Size = UDim2.fromOffset(IconSize + 12, IconSize + 12)
    end

    Table:SetIcon(Icon)

    function Table:SetVisible(Visible: boolean)
        if not Button.Parent then
            return
        end
        Button.Visible = Visible
    end

    function Table:IsVisible(): boolean
        return Button ~= nil and Button.Visible
    end

    function Table:Remove()
        if Button then
            Button.Visible = false
        end
    end

    Library:RegisterOverlay("DraggableImageButton", Icon, Table)

    return Table
end

function Library:AddDraggableToggle(Text: string, Default: boolean?, Callback)
    local Table = {}
    local OwningScreenGui = ScreenGui
    local BaseZIndex = Library:NextOverlayZIndex()

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = Library:GetNextOverlayPosition(),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6),
        Parent = Holder,
    })
    Library:NewTrackedScale(Holder)
    Library:AddStyleRoot(Holder)
    Library:AddOutline(Holder)

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text = Text,
        TextSize = 15,
        ZIndex = BaseZIndex + 1,
        Parent = Holder,
    })

    local Switch = New("TextButton", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.fromOffset(34, 18),
        Text = "",
        ZIndex = BaseZIndex + 1,
        Parent = Holder,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch }))
    Library:AddOutline(Switch)

    local Dot = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = "FontColor",
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        ZIndex = BaseZIndex + 2,
        Parent = Switch,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Dot }))

    Table.Value = Default == true

    local function Refresh()
        TweenService:Create(Dot, Library.TweenInfo, {
            Position = Table.Value and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        }):Play()
        TweenService:Create(Switch, Library.TweenInfo, {
            BackgroundColor3 = Table.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor,
        }):Play()
    end

    function Table:SetValue(Value: boolean)
        Table.Value = Value == true
        Refresh()
        Library:SafeCallback(Callback, Table.Value)
    end

    Switch.MouseButton1Click:Connect(function()
        Table:SetValue(not Table.Value)
    end)

    Library:MakeDraggable(Holder, Holder, true)
    Refresh()

    Table.Holder = Holder

    function Table:SetText(NewText: string)
        Label.Text = NewText
    end

    Library:RegisterOverlay("DraggableToggle", Text, Table)

    return Table
end

function Library:AddDraggableProgress(Text: string, Default: number?, Max: number?)
    local Table = {}
    local OwningScreenGui = ScreenGui
    local BaseZIndex = Library:NextOverlayZIndex()

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = Library:GetNextOverlayPosition(),
        Size = UDim2.fromOffset(180, 44),
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    Library:NewTrackedScale(Holder)
    Library:AddStyleRoot(Holder)
    Library:AddOutline(Holder)
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6),
        Parent = Holder,
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = BaseZIndex + 1,
        Parent = Holder,
    })

    local Track = New("Frame", {
        BackgroundColor3 = "MainColor",
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        ZIndex = BaseZIndex + 1,
        Parent = Holder,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track }))
    Library:AddOutline(Track)

    local Fill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(0, 1),
        ZIndex = BaseZIndex + 2,
        Parent = Track,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill }))

    Table.Value = Default or 0
    Table.Max = Max or 100

    function Table:SetValue(Value: number)
        Table.Value = math.clamp(Value, 0, Table.Max)
        TweenService:Create(Fill, Library.TweenInfo, {
            Size = UDim2.fromScale(Table.Value / Table.Max, 1),
        }):Play()
    end
    Table:SetValue(Table.Value)

    function Table:SetText(NewText: string)
        Label.Text = NewText
    end

    Library:MakeDraggable(Holder, Holder, true)

    Table.Holder = Holder

    Library:RegisterOverlay("DraggableProgress", Text, Table)

    return Table
end

local BaseSection = {}

function Library:AddDraggableMenu(Name: string, Width: number?)

    local OwningScreenGui = ScreenGui

    local MenuWidth = Width or 220

    local BaseZIndex = Library:NextOverlayZIndex()
    local ChromeZIndex = BaseZIndex + 1
    local ContainerZIndex = BaseZIndex + 2

    local FrontGeneration: number? = nil

    local ControlsWidth = 62
    local TitleTextWidth = select(1, Library:GetTextBounds(Name, Library.Scheme.Font, 15))
    local ResolvedWidth = math.max(MenuWidth, math.ceil(TitleTextWidth) + 12 + ControlsWidth)

    local MaxWidth = 480

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "BackgroundColor",
        Position = Library:GetNextOverlayPosition(),
        Size = UDim2.fromOffset(ResolvedWidth, 0),
        ZIndex = BaseZIndex,
        Parent = OwningScreenGui,
    })
    local SizeConstraint = New("UISizeConstraint", {

        MaxSize = Vector2.new(MaxWidth, 800),
        MinSize = Vector2.new(ResolvedWidth, 0),
        Parent = Holder,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    Library:NewTrackedScale(Holder)
    Library:AddStyleRoot(Holder)
    Library:AddOutline(Holder)

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Holder,
    })

    local LabelHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = 1,
        ZIndex = ChromeZIndex,
        Parent = Holder,
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = Name,
        TextSize = 15,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LabelHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, ControlsWidth),
        Parent = Label,
    })

    local ControlsHolder = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(46, 20),
        Parent = LabelHolder,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = ControlsHolder,
    })

    local function MakeTitleBarButton(IconName: string)
        local Btn = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(20, 20),
            Text = "",
            Parent = ControlsHolder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Btn }))
        Library:AddOutline(Btn)
        local Icon = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.35,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(11, 11),
            Parent = Btn,
        })

        Library:RegisterIconInstance(Icon, IconName)
        return Btn
    end

    local MinimizeBtn = MakeTitleBarButton("minus")
    MinimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(MinimizeBtn, Library.TweenInfo, { BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 12) }):Play()
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(MinimizeBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
    end)

    local CloseBtn = MakeTitleBarButton("x")
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
    end)

    local Separator = Library:MakeLine(LabelHolder, {
        Position = UDim2.fromOffset(0, 33),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Container = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = 2,
        ZIndex = ContainerZIndex,
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Container,
    })
    local ContainerPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Container,
    })

    local ResizeQueued = false
    local function RecalculateWidth()
        local ScaleFactor = math.max(Library.DPIScale or 1, 0.001)

        local WidestChildWidth = 0
        for _, Child in ipairs(Container:GetChildren()) do
            if Child:IsA("GuiObject") and Child.Visible then
                local LogicalWidth = Child.AbsoluteSize.X / ScaleFactor
                WidestChildWidth = math.max(WidestChildWidth, LogicalWidth)
            end
        end

        local ContentWidth = WidestChildWidth
            + ContainerPadding.PaddingLeft.Offset
            + ContainerPadding.PaddingRight.Offset

        local TargetWidth = math.clamp(math.max(ResolvedWidth, ContentWidth), ResolvedWidth, MaxWidth)

        SizeConstraint.MinSize = Vector2.new(TargetWidth, 0)
        Holder.Size = UDim2.fromOffset(TargetWidth, 0)
    end

    local function QueueResize()
        if ResizeQueued then
            return
        end
        ResizeQueued = true
        task.defer(function()
            ResizeQueued = false
            RecalculateWidth()
        end)
    end

    Container.ChildAdded:Connect(function(Child)
        QueueResize()
        if Child:IsA("GuiObject") then
            Child:GetPropertyChangedSignal("AbsoluteSize"):Connect(QueueResize)
            Child:GetPropertyChangedSignal("Visible"):Connect(QueueResize)
        end
    end)
    Container.ChildRemoved:Connect(QueueResize)

    local MenuCollapsed = false
    local function SetMenuCollapsed(Collapsed: boolean)
        MenuCollapsed = Collapsed
        Container.Visible = not MenuCollapsed

        Separator.Visible = not MenuCollapsed
    end
    MinimizeBtn.MouseButton1Click:Connect(function()
        SetMenuCollapsed(not MenuCollapsed)
    end)

    Library:MakeDraggable(Holder, LabelHolder, true)

    LabelHolder.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end
        BaseZIndex, FrontGeneration = Library:BringOverlayToFront(Holder, BaseZIndex, FrontGeneration)
    end)

    local ContainerObj = {
        Holder = Holder,
        Container = Container,
        Elements = {},
        ConditionalGroups = {},
    }
    function ContainerObj:Resize()
        RecalculateWidth()
    end

    function ContainerObj:SetCollapsed(Collapsed: boolean)
        SetMenuCollapsed(Collapsed)
    end
    function ContainerObj:ToggleCollapsed()
        SetMenuCollapsed(not MenuCollapsed)
    end
    function ContainerObj:IsCollapsed(): boolean
        return MenuCollapsed
    end
    function ContainerObj:Remove()
        if Holder then
            Holder.Visible = false
        end
    end
    function ContainerObj:SetVisible(Visible: boolean)
        if Holder then
            Holder.Visible = Visible
        end
        if Visible and Holder and Holder.Parent then

            BaseZIndex, FrontGeneration = Library:BringOverlayToFront(Holder, BaseZIndex, FrontGeneration)
        end
    end
    function ContainerObj:IsVisible(): boolean
        return Holder ~= nil and Holder.Visible
    end
    setmetatable(ContainerObj, BaseSection)

    Library:RegisterOverlay("DraggableMenu", Name, ContainerObj)

    CloseBtn.MouseButton1Click:Connect(function()
        ContainerObj:Remove()
    end)

    return Holder, Container, ContainerObj
end

function Library:AddLongPressAsRightClick(GuiObject: GuiObject, Func: () -> ())
    if not GuiObject or typeof(Func) ~= "function" then
        return
    end

    return Library:GiveSignal(GuiObject.TouchLongPress:Connect(function(_, State)

        if State == Enum.UserInputState.Begin then
            Func()
        end
    end))
end

local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?,
    IgnoreCornerRadius: boolean?
)
    local Menu

    local BaseZIndex = Library:NextOverlayZIndex()

    local ScaledContainer = Library:FindScaledContainer(Holder)
    local ParentGui = ScaledContainer
    if not ParentGui then
        ParentGui = Holder:FindFirstAncestorOfClass("ScreenGui")
        if not ParentGui or (ParentGui ~= ScreenGui and not (Library.ActiveLoading and ParentGui == Library.ActiveLoading.ScreenGui)) then
            ParentGui = (Library.ActiveLoading and Library.ActiveLoading.ScreenGui) or ScreenGui
        end
    end

    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = BaseZIndex,
            Parent = ParentGui,
        })
        Library:AddCustomScrollbar(Menu)
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = BaseZIndex,
            Parent = ParentGui,
        })
    end

    local MenuIsInScaledContainer = ScaledContainer ~= nil
    if not MenuIsInScaledContainer then
        Library:NewTrackedScale(Menu)
    end

    New("UIStroke", {
        Color = "OutlineColor",
        Parent = Menu,
    })
    Library:AddStyleRoot(Menu)

    if IgnoreCornerRadius ~= true then
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            })
        )
    end

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
    }

    local Removed = false

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    local function ComputeMenuPosition(): UDim2
        local RawOffset = typeof(Offset) == "function" and Offset() or Offset

        if not MenuIsInScaledContainer then

            return UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + RawOffset[1]),
                math.floor(Holder.AbsolutePosition.Y + RawOffset[2])
            )
        end

        local ScaleFactor = math.max(Library.DPIScale or 1, 0.0001)
        local ContainerAbsPos = ScaledContainer.AbsolutePosition
        local RelativeX = (Holder.AbsolutePosition.X - ContainerAbsPos.X) / ScaleFactor
        local RelativeY = (Holder.AbsolutePosition.Y - ContainerAbsPos.Y) / ScaleFactor

        return UDim2.fromOffset(
            math.floor(RelativeX + RawOffset[1]),
            math.floor(RelativeY + RawOffset[2])
        )
    end

    function Table:Open(Force: boolean?)
        if CurrentMenu == Table then
            return
        elseif CurrentMenu and not Force then
            CurrentMenu:Close()
        end

        if Table.Id and Library.Overlays[Table.Id] ~= Table then
            Library.Overlays[Table.Id] = Table
            table.insert(Library.OverlaysOrder, Table)
        end

        if not Force then
            CurrentMenu = Table
        end
        Table.Active = true

        Menu.Position = ComputeMenuPosition()
        Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            Menu.Position = ComputeMenuPosition()
        end)
    end

    function Table:Close()
        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end

        if not Table.Active then
            return
        end
        Menu.Visible = false

        Table.Active = false
        if CurrentMenu == Table then
            CurrentMenu = nil
        end
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    function Table:SetVisible(Visible: boolean, Force: boolean?)
        if Visible then
            Table:Open(Force)
        else
            Table:Close()
        end
    end

    function Table:IsVisible(): boolean
        return Table.Active and Menu ~= nil and Menu.Visible
    end

    function Table:Remove()
        if Removed then
            return
        end

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end

        if CurrentMenu == Table then
            Menu.Visible = false
            Table.Active = false
            CurrentMenu = nil
            if typeof(ActiveCallback) == "function" then
                Library:SafeCallback(ActiveCallback, false)
            end
        end

        Menu.Visible = false
    end

    Library:RegisterOverlay("ContextMenu", nil, Table)

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "BackgroundColor",
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = Library.TooltipZIndex,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 2),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 2),
    Parent = TooltipLabel,
})

local FallbackTooltipScale = New("UIScale", {
    Parent = TooltipLabel,
})
table.insert(Library.Scales, FallbackTooltipScale)
New("UIStroke", {
    Color = "OutlineColor",
    Parent = TooltipLabel,
})
table.insert(
    Library.Corners,
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
        Parent = TooltipLabel,
    })
)
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, _ = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8)
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or Library.ActiveDialog
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        local ScaledContainer = Library:FindScaledContainer(HoverInstance)

        local ParentGui = HoverInstance:FindFirstAncestorOfClass("ScreenGui")
        if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
            ParentGui = ScreenGui
        end

        if ScaledContainer then
            TooltipLabel.Parent = ScaledContainer
            FallbackTooltipScale.Parent = nil
        else
            TooltipLabel.Parent = ParentGui
            FallbackTooltipScale.Parent = TooltipLabel
        end

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            (Library.Toggled or Library.ActiveLoading)
            and not Library.ActiveDialog
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            local OffsetX = Mouse.X + (Library.ShowCustomCursor and 8 or 14)
            local OffsetY = Mouse.Y + (Library.ShowCustomCursor and 8 or 12)

            if ScaledContainer then

                local ScaleInst = ScaledContainer:FindFirstChildOfClass("UIScale")
                local Factor = (ScaleInst and ScaleInst.Scale ~= 0) and ScaleInst.Scale or 1
                local ContainerOrigin = ScaledContainer.AbsolutePosition

                TooltipLabel.Position = UDim2.fromOffset(
                    (OffsetX - ContainerOrigin.X) / Factor,
                    (OffsetY - ContainerOrigin.Y) / Factor
                )
            else
                TooltipLabel.Position = UDim2.fromOffset(OffsetX, OffsetY)
            end

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipTable)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    Library.AutoDPIScaleConnection = nil

    table.clear(Library.FocusHighlights)
    table.clear(TransparencyCache)
    table.clear(ActiveTabTweens)

    pcall(function()
        RunService:UnbindFromRenderStep(Library.ShowCursorBinding)
    end)
    RestoreMouseIcon()

    if Library.KeybindMenu and Library.KeybindMenu.SettingsFrame then
        pcall(function()
            Library.KeybindMenu.SettingsFrame:Destroy()
        end)
        Library.KeybindMenu.SettingsFrame = nil
        Library.KeybindMenu.SettingsContainer = nil
        Library.KeybindMenu.SettingsOpen = false
    end
    Library.KeybindMenu = nil
    Library.KeybindFrame = nil
    Library.KeybindContainer = nil
    table.clear(Library.KeybindToggles)

    Library.ActiveTab = nil
    Library.PreviousTab = nil
    Library.Searching = false
    Library.LastSearchTab = nil

    for _, Tab in Library.Tabs do
        if typeof(Tab) ~= "table" then
            continue
        end

        pcall(function()
            if Tab.TooltipTable then
                Tab.TooltipTable:Destroy()
                Tab.TooltipTable = nil
            end
        end)
        pcall(function()
            if Tab.Button then
                Tab.Button:Destroy()
            end
        end)
        pcall(function()
            if Tab.Container then
                Tab.Container:Destroy()
            end
        end)
    end
    table.clear(Library.Tabs)
    table.clear(Library.TabButtons)

    table.clear(Toggles)
    table.clear(Options)
    table.clear(Buttons)
    table.clear(Labels)

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end
    table.clear(Tooltips)

    for _, Callback in Library.UnloadSignals do
        Library:SafeCallback(Callback)
    end

    Library.Unloaded = true

    if Library.ActiveLoading then
        Library.ActiveLoading:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")
local EditIcon = Library:GetIcon("pencil")

if not Library:AreIconsLoaded() then
    task.spawn(function()
        Library:WaitForIcons()

        CheckIcon = Library:GetIcon("check")
        ArrowIcon = Library:GetIcon("chevron-up")
        ResizeIcon = Library:GetIcon("move-diagonal-2")
        KeyIcon = Library:GetIcon("key")
        MoveIcon = Library:GetIcon("move")
        EditIcon = Library:GetIcon("pencil")

        if Library.RefreshIcons then
            Library:RefreshIcons()
        end
    end)
end

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
    EditIcon = Library:GetIcon("pencil")
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default,
            Modifiers = Info.DefaultModifiers,
            DisplayValue = Info.Default,

            Blacklisted = Info.Blacklisted,
            BlacklistedModifiers = Info.BlacklistedModifiers,
            Whitelisted = Info.Whitelisted,
            WhitelistedModifiers = Info.WhitelistedModifiers,

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        KeyPicker.Mode = Info.Mode

        local Picking = false

        local function SetPickingState(State: boolean)
            Picking = State
            Library.IsPicking = State
        end

        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

        local PickerGapTrim = -1
        local Picker = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "MainColor",
            Position = UDim2.new(1, -PickerGapTrim, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Text = KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Picker,
        })

        Picker.MouseEnter:Connect(function()
            if ParentObj.Disabled then
                return
            end

            TweenService:Create(Picker, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
        end)
        Picker.MouseLeave:Connect(function()
            if ParentObj.Disabled then
                return
            end

            TweenService:Create(Picker, Library.TweenInfo, {
                TextTransparency = 0.4,
            }):Play()
        end)

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Picker,
            })
        )

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,
            })

            local Checkbox = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Checkbox,
                })
            )
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })
            Library:RegisterIconInstance(CheckImage, "check")

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                Label.Text = Text
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
                KeyPicker:Update()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, nil, true)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in Info.Modes do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            function ModeButton:Select()
                for _, OtherButton in ModeButtons do
                    if OtherButton ~= ModeButton then
                        OtherButton:Deselect()
                    end
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
                if KeyPicker.Update then
                    KeyPicker:Update()
                end
            end

            function ModeButton:Deselect()

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local X, Y = Library:GetTextBounds(
                PickerText or KeyPicker.DisplayValue,
                Picker.FontFace,
                Picker.TextSize,
                ToggleLabel.AbsoluteSize.X
            )
            Picker.Text = PickerText or KeyPicker.DisplayValue
            Picker.Size = UDim2.fromOffset((X + 9), (Y + 4))
        end

        function KeyPicker:Update()
            local Disabled = ParentObj.Disabled == true

            if Disabled and Picking then
                SetPickingState(false)
            end

            KeyPicker:Display()

            Picker.Active = not Disabled
            Picker.TextTransparency = Disabled and 0.8 or 0.4

            if Disabled and KeyPicker.Menu and KeyPicker.Menu.Active then
                KeyPicker.Menu:Close()
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if Info.NoUI then
                return
            end

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(KeyPicker.MenuVisible ~= false)
                KeybindsToggle:Display(State)
            end
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if Picking or ParentObj.Disabled then
                return
            end

            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)

            local Key = Data.Key ~= nil and Data.Key or Data[1]
            local Mode = Data.Mode ~= nil and Data.Mode or Data[2]
            local Modifiers = Data.Modifiers ~= nil and Data.Modifiers or Data[3]

            Mode = Mode or KeyPicker.Mode

            local IsKeyValid, KeyCode = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Update()

            if not ParentObj.Disabled then
                local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
                Library:SafeCallback(KeyPicker.ChangedCallback, KeyCode, NewModifiers)
                Library:SafeCallback(KeyPicker.Changed, KeyCode, NewModifiers)
            end
        end

        KeyPicker:SetValue({
            Key = Info.Default,
            Mode = Info.Mode,
            Modifiers = Info.DefaultModifiers,
        })

        function KeyPicker:SetText(Text)
            KeyPicker.Text = Text
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()

            local KeybindMenu = Library.KeybindMenu
            if KeybindMenu and KeybindMenu.SettingsOpen then
                KeybindMenu:RefreshSettings()
            end
        end

        function KeyPicker:SetMenuVisibility(Visible: boolean)
            assert(typeof(Visible) == "boolean", "Visible must be a boolean")

            KeyPicker.MenuVisible = Visible
            KeyPicker:Update()

            local KeybindMenu = Library.KeybindMenu
            if KeybindMenu and KeybindMenu.SettingsOpen then
                KeybindMenu:RefreshSettings()
            end
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking or Library.IsPicking or ParentObj.Disabled then
                return
            end

            SetPickingState(true)

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29, 18)

            local Input
            local ActiveModifiers = {}

            local GetInput = nil; GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() ~= nil then
                    return true
                end

                if Input.KeyCode == Enum.KeyCode.Escape then
                    return false
                end

                local IsMod = IsModifierInput(Input)
                local KeyName
                if SpecialKeysInput[Input.UserInputType] ~= nil then
                    KeyName = SpecialKeysInput[Input.UserInputType]
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    if IsMod then
                        KeyName = ModifiersInput[Input.KeyCode]
                    else
                        KeyName = Input.KeyCode.Name
                    end
                end

                if KeyName then
                    if IsMod then
                        if KeyPicker.WhitelistedModifiers and #KeyPicker.WhitelistedModifiers > 0 and not table.find(KeyPicker.WhitelistedModifiers, KeyName) then
                            return GetInput()
                        end

                        if KeyPicker.BlacklistedModifiers and table.find(KeyPicker.BlacklistedModifiers, KeyName) then
                            return GetInput()
                        end
                    else
                        if KeyPicker.Whitelisted and #KeyPicker.Whitelisted > 0 and not table.find(KeyPicker.Whitelisted, KeyName) then
                            return GetInput()
                        end

                        if KeyPicker.Blacklisted and table.find(KeyPicker.Blacklisted, KeyName) then
                            return GetInput()
                        end
                    end
                end

                return false
            end

            repeat
                task.wait()

                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29, 18)

                if GetInput() then
                    SetPickingState(false)
                    KeyPicker:Update()
                    return
                end

                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then

                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                if GetInput() then
                                    StopLoop = true
                                    break
                                end

                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break
                                end
                            end
                        end
                    until false

                    if StopLoop then
                        SetPickingState(false)
                        KeyPicker:Update()
                        return
                    end
                end

                break
            until false

            local Key = "Unknown"
            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType]
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
            end

            ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

            KeyPicker.Toggled = false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            repeat
                task.wait()
            until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
            SetPickingState(false)
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:AddLongPressAsRightClick(Picker, MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            local IsMouseButton = Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.MouseButton2
                or Input.UserInputType == Enum.UserInputType.MouseButton3

            if
                ParentObj.Disabled
                or KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or Library.IsPicking
                or UserInputService:GetFocusedTextBox()
                or (IsMouseButton and Library.Toggled)
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function()
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        KeyPicker.Holder = Picker

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.DefaultKey = Info.Default or "None"
        KeyPicker.DefaultModifiers = table.clone(Info.DefaultModifiers or {})
        KeyPicker.DefaultMode = Info.Mode
        KeyPicker.Default = KeyPicker.DefaultKey

        Options[Idx] = KeyPicker

        return KeyPicker
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,

            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local SwatchGapTrim = -1
        local Holder = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = ColorPicker.Value,
            ClipsDescendants = true,
            Position = UDim2.new(1, -SwatchGapTrim, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Holder,
            })
        )

        local HolderBackground = New("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        local HolderColor = New("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BackgroundTransparency = ColorPicker.Transparency,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = HolderBackground,
        })

        local HolderStroke = New("UIStroke", {
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Thickness = 1,
            Parent = Holder,
        })

        local SectionContainer = ParentObj.Container

        local ColorPanelOpen = false

        local InlinePanel = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = SectionContainer,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = InlinePanel,
            })
        )
        Library:AddOutline(InlinePanel)
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            Parent = InlinePanel,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = InlinePanel,
        })

        local function ResizeOwner()
            if ParentObj.Section then
                ParentObj.Section:Resize()
            elseif type(ParentObj.Resize) == "function" then
                ParentObj:Resize()
            end
        end

        local function OpenColorPanel()
            if ColorPanelOpen then return end
            ColorPanelOpen = true
            InlinePanel.Visible = true
            ResizeOwner()
        end
        local function CloseColorPanel()
            if not ColorPanelOpen then return end
            ColorPanelOpen = false
            InlinePanel.Visible = false
            ResizeOwner()
        end

        local OutsideClickConn
        local function StartWatchingOutsideClicks()
            if OutsideClickConn then return end
            OutsideClickConn = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if GameProcessed then return end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                if not ColorPanelOpen then return end

                local MousePos = UserInputService:GetMouseLocation()
                local PanelPos, PanelSize = InlinePanel.AbsolutePosition, InlinePanel.AbsoluteSize
                local WithinPanel = MousePos.X >= PanelPos.X and MousePos.X <= PanelPos.X + PanelSize.X
                    and MousePos.Y >= PanelPos.Y and MousePos.Y <= PanelPos.Y + PanelSize.Y

                local HolderPos, HolderSize = Holder.AbsolutePosition, Holder.AbsoluteSize
                local WithinSwatch = MousePos.X >= HolderPos.X and MousePos.X <= HolderPos.X + HolderSize.X
                    and MousePos.Y >= HolderPos.Y and MousePos.Y <= HolderPos.Y + HolderSize.Y

                if not WithinPanel and not WithinSwatch then
                    CloseColorPanel()
                end
            end)
        end
        StartWatchingOutsideClicks()

        local ColorMenu = {}
        function ColorMenu:Toggle()
            if ColorPanelOpen then CloseColorPanel() else OpenColorPanel() end
        end
        function ColorMenu:Close() CloseColorPanel() end
        function ColorMenu:Open() OpenColorPanel() end
        ColorPicker.ColorMenu = ColorMenu

        local HasTitle = typeof(ColorPicker.Title) == "string"
        if HasTitle then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = ColorPicker.Title,
                TextColor3 = "FontColor",
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = InlinePanel,
            })
        end

        local MapSize = Library.IsMobile and 140 or 200
        ColorPicker.MapSize = MapSize

        local ColorHolder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, MapSize),
            Parent = InlinePanel,
        })
        local ColorHolderList = New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.new(1, 0, 1, 0),
            Parent = ColorHolder,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Fill,
            Parent = SatVipMap,
        })

        do
            local InitialImage = SatVipMap.Image
            if InitialImage:sub(1, 13) == "rbxassetid://" then
                task.spawn(function()
                    for _ = 1, 60 do
                        task.wait(0.5)
                        if not SatVipMap or not SatVipMap.Parent then break end
                        local ResolvedId = CustomImageManager.GetAsset("SaturationMap")
                        if ResolvedId and ResolvedId:sub(1, 13) ~= "rbxassetid://" then
                            SatVipMap.Image = ResolvedId
                            break
                        end
                    end
                end)
            end
        end

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "DarkColor",
            Parent = SatVibCursor,
        })

        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, MapSize),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            BorderColor3 = "DarkColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Image = "",
                Size = UDim2.fromOffset(16, MapSize),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                BorderColor3 = "DarkColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = InlinePanel,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "BackgroundColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextColor3 = "FontColor",
            TextSize = 14,
            Parent = InfoHolder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = HueBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HueBox,
            })
        )

        Library:AddFocusHighlight(HueBox)

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "BackgroundColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextColor3 = "FontColor",
            TextSize = 14,
            Parent = InfoHolder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = RgbBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = RgbBox,
            })
        )

        Library:AddFocusHighlight(RgbBox)

        if Info.Resizable then
            local ResizeGrabber = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = "",
                Parent = InlinePanel,
            })
            local ResizeGrabberIcon = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 1),
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                ImageTransparency = 0.5,
                Position = UDim2.fromScale(1, 1),
                Size = UDim2.fromOffset(12, 12),
                Parent = ResizeGrabber,
            })
            if ResizeIcon then
                ResizeGrabberIcon.Image = ResizeIcon.Url
                ResizeGrabberIcon.ImageRectOffset = ResizeIcon.ImageRectOffset
                ResizeGrabberIcon.ImageRectSize = ResizeIcon.ImageRectSize
            end

            ResizeGrabber.InputBegan:Connect(function(Input: InputObject)
                if not IsClickInput(Input) or ParentObj.Disabled then
                    return
                end

                local StartY = Mouse.Y
                local StartSize = ColorPicker.MapSize

                while IsDragInput(Input) do
                    local NewSize = math.clamp(math.floor(StartSize + (Mouse.Y - StartY) + 0.5), 140, 400)

                    if NewSize ~= ColorPicker.MapSize then
                        ColorPicker.MapSize = NewSize
                        ColorHolder.Size = UDim2.new(1, 0, 0, NewSize)
                        HueSelector.Size = UDim2.fromOffset(16, NewSize)

                        if TransparencySelector then
                            TransparencySelector.Size = UDim2.fromOffset(16, NewSize)
                        end

                        ResizeOwner()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        ContextMenu.List.Padding = UDim.new(0, 6)
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, Library.TweenInfo, {
                        BackgroundTransparency = 0.85,
                    }):Play()
                end)
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, Library.TweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                end)
                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end
            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)

                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            Holder.BackgroundColor3 = ColorPicker.Value
            HolderStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
            HolderColor.BackgroundColor3 = ColorPicker.Value
            HolderColor.BackgroundTransparency = ColorPicker.Transparency

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            local Disabled = ParentObj.Disabled == true
            Holder.Active = not Disabled

            if Disabled then
                if ColorPanelOpen then
                    CloseColorPanel()
                end

                if ContextMenu.Active then
                    ContextMenu:Close()
                end
            end

            ColorPicker:RunChanged()
        end

        function ColorPicker:RunChanged()
            if ParentObj.Disabled then
                return
            end

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        Holder.MouseButton1Click:Connect(function()
            if ParentObj.Disabled then
                return
            end

            ColorMenu:Toggle()
        end)
        Holder.MouseButton2Click:Connect(function()
            if ParentObj.Disabled then
                return
            end

            ContextMenu.Toggle()
        end)

        Library:AddLongPressAsRightClick(Holder, ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) and not ParentObj.Disabled do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) and not ParentObj.Disabled do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) and not ParentObj.Disabled do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter or ParentObj.Disabled then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter or ParentObj.Disabled then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        ColorPicker.Holder = Holder

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return ColorPicker
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

do
    local Funcs = {}

    --// Adds a small gear button to an element. Clicking it expands an inline panel (styled like the color
    --// picker's) that can hold any normal elements: Settings:AddToggle / AddSlider / AddDropdown / ... \\--
    function Funcs:AddSettings(Info)
        local ParentObj = self
        if ParentObj.Destroyed then
            return nil
        end
        if ParentObj.Settings and not ParentObj.Settings.Destroyed then
            return ParentObj.Settings
        end

        Info = typeof(Info) == "table" and Info or {}

        local OwnerSection = ParentObj.Section
        local PanelParent = ParentObj.Container
        assert(OwnerSection and PanelParent, "AddSettings is not supported on this element")

        local Settings = {
            Destroyed = false,
            Opened = false,
            Width = typeof(Info.Width) == "number" and Info.Width or nil,

            Elements = {},
            ConditionalGroups = {},

            Type = "Settings",
            Parent = ParentObj,
        }

        local ElementType = ParentObj.Type
        local IsForButton = ElementType == "Button" or ElementType == "SubButton"

        local Gear = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(18, 18),
            Text = "",
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Gear,
            })
        )
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Gear,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            PaddingTop = UDim.new(0, 3),
            Parent = Gear,
        })

        local Icon = New("ImageLabel", {
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Size = UDim2.fromScale(1, 1),
            Parent = Gear,
        })
        Library:RegisterIconInstance(Icon, "settings")

        if IsForButton then
            New("UIFlexItem", {
                FlexMode = Enum.UIFlexMode.None,
                Parent = Gear,
            })

            Gear.LayoutOrder = (ParentObj.Base.LayoutOrder or 0) + 1
            Gear.Size = UDim2.new(0, 21, 1, 0)
            Gear.Parent = ParentObj.Base.Parent
        elseif ElementType == "Input" then
            local Box = ParentObj.Holder:FindFirstChildWhichIsA("TextBox")
            if Box then
                Box.Size = UDim2.new(1, -27, 0, 21)
            end

            Gear.AnchorPoint = Vector2.new(1, 1)
            Gear.Position = UDim2.fromScale(1, 1)
            Gear.Size = UDim2.fromOffset(21, 21)
            Gear.Parent = ParentObj.Holder
        elseif ElementType == "Dropdown" then
            --// ReserveRight frees the right edge of the row; the gear sits in it. \\--
            ParentObj:ReserveRight(27)
            Gear.AnchorPoint = Vector2.new(1, 1)
            Gear.Position = UDim2.new(1, 0, 1, 0)
            Gear.Size = UDim2.fromOffset(21, 21)
            Gear.ZIndex = (ParentObj.TopRow and ParentObj.TopRow.ZIndex or 1) + 2
            Gear.Parent = ParentObj.TopRow
        elseif ElementType == "Toggle" and ParentObj.ReserveRight and ParentObj.Holder then
            --// Very right edge of the row; the switch / checkbox and any addons move left of it. \\--
            ParentObj:ReserveRight(24)
            Gear.AnchorPoint = Vector2.new(1, 0.5)
            Gear.Position = UDim2.fromScale(1, 0.5)
            Gear.Size = UDim2.fromOffset(18, 18)
            Gear.Parent = ParentObj.Holder
        elseif ElementType == "Stepper" and ParentObj.Controls and ParentObj.LabelBlock then
            --// Very right edge; ReserveRight moves the +/- controls left of it. \\--
            ParentObj:ReserveRight(27)
            Gear.AnchorPoint = Vector2.new(1, 0.5)
            Gear.Position = UDim2.fromScale(1, 0.5)
            Gear.Size = UDim2.fromOffset(21, 21)
            Gear.Parent = ParentObj.Holder
        elseif ElementType == "Slider" and ParentObj.Holder then
            --// Very right edge of the slider's top row; the inline value box moves left of it. \\--
            ParentObj:ReserveRight(27)
            Gear.AnchorPoint = Vector2.new(1, 0.5)
            Gear.Position = UDim2.new(1, 0, 0, (ParentObj.TopRowHeight or 14) / 2)
            Gear.Size = UDim2.fromOffset(21, 21)
            Gear.Parent = ParentObj.Holder
        else
            local Label = ParentObj.TextLabel
            if not Label and ParentObj.Holder then
                Label = ParentObj.Holder:FindFirstChildWhichIsA("TextLabel")
            end

            if Label then
                Gear.AnchorPoint = Vector2.new(1, 0.5)
                Gear.Position = UDim2.new(1, -4, 0.5, 0)
                Gear.ZIndex = Label.ZIndex + 2
                Gear.Parent = Label
            elseif ParentObj.Holder then
                Gear.AnchorPoint = Vector2.new(1, 0)
                Gear.Position = UDim2.new(1, 0, 0, 0)
                Gear.Parent = ParentObj.Holder
            end
        end

        local ParentHolder = ParentObj.Holder or ParentObj.Base or (ParentObj.TextLabel and ParentObj.TextLabel.Parent)
        --// The gear (and its icon, created before the gear had a parent) must sit above the row:
        --// ZIndexBehavior is Global, so an icon left at ZIndex 1 is hidden behind every other element. \\--
        do
            local BaseZ = Gear.Parent and Gear.Parent.ZIndex or Library.BaseZIndex
            if Gear.ZIndex <= BaseZ then
                Gear.ZIndex = BaseZ + 2
            end
            Icon.ZIndex = Gear.ZIndex + 1
        end

        --// Share the owner's LayoutOrder. Section children default to 0 and sort by creation order, so
        --// the panel lands directly under its owner (an order of +1 would sink it to the section's end). \\--
        local TargetOrder = 0
        do
            local Anchor = ParentHolder
            while Anchor and Anchor.Parent ~= PanelParent do
                Anchor = Anchor.Parent
            end
            if Anchor and Anchor:IsA("GuiObject") then
                TargetOrder = Anchor.LayoutOrder
            end
        end
        local Panel = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            LayoutOrder = TargetOrder,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = PanelParent,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Panel,
            })
        )
        Library:AddOutline(Panel)
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            Parent = Panel,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = Panel,
        })

        Settings.Gear = Gear
        Settings.Holder = Panel
        Settings.Container = Panel
        Settings.Section = OwnerSection

        local function ApplyWidth()
            if Settings.Width then
                Panel.Size = UDim2.new(0, Settings.Width, 0, 0)
            else
                Panel.Size = UDim2.new(1, 0, 0, 0)
            end
        end
        ApplyWidth()

        --// Elements inside the panel call Section:Resize(), which resizes the owning section. \\--
        function Settings:Resize()
            if OwnerSection and type(OwnerSection.Resize) == "function" then
                OwnerSection:Resize()
            end
        end

        function Settings:SetWidth(Width: number?)
            assert(Width == nil or (typeof(Width) == "number" and Width >= 0), "Width must be a number >= 0 or nil")

            Settings.Width = Width
            ApplyWidth()
            Settings:Resize()
        end

        local function SetOpen(Open: boolean)
            if Settings.Opened == Open then
                return
            end

            Settings.Opened = Open
            Panel.Visible = Open
            TweenService:Create(Icon, Library.TweenInfo, {
                ImageTransparency = Open and 0 or (ParentObj.Disabled and 0.8 or 0.5),
            }):Play()

            Settings:Resize()
        end

        function Settings:Open()
            if ParentObj.Disabled then
                return
            end
            SetOpen(true)
        end

        function Settings:Close()
            SetOpen(false)
        end

        function Settings:Toggle()
            if Settings.Opened then
                SetOpen(false)
            elseif not ParentObj.Disabled then
                SetOpen(true)
            end
        end

        function Settings:IsOpen(): boolean
            return Settings.Opened
        end

        function Settings:Update()
            local Disabled = ParentObj.Disabled == true

            Gear.Active = not Disabled
            Icon.ImageTransparency = Disabled and 0.8 or (Settings.Opened and 0 or 0.5)

            if Disabled then
                SetOpen(false)
            end
        end

        function Settings:Destroy()
            if Settings.Destroyed then
                return
            end
            Settings.Destroyed = true

            for _, Element in Settings.Elements do
                if type(Element) == "table" and type(Element.Destroy) == "function" then
                    pcall(Element.Destroy, Element)
                end
            end

            Library:RemoveFromRegistry(Gear)
            Gear:Destroy()
            Panel:Destroy()

            ParentObj.Settings = nil
            if ParentObj.Addons then
                local Index = table.find(ParentObj.Addons, Settings)
                if Index then
                    table.remove(ParentObj.Addons, Index)
                end
            end

            Settings:Resize()
        end

        Gear.MouseButton1Click:Connect(function()
            Settings:Toggle()
        end)

        Gear.MouseEnter:Connect(function()
            if not Settings.Opened and not ParentObj.Disabled then
                TweenService:Create(Icon, Library.TweenInfo, { ImageTransparency = 0.15 }):Play()
            end
        end)
        Gear.MouseLeave:Connect(function()
            if not Settings.Opened then
                Icon.ImageTransparency = ParentObj.Disabled and 0.8 or 0.5
            end
        end)

        setmetatable(Settings, BaseSection)

        ParentObj.Settings = Settings
        if ParentObj.Addons then
            table.insert(ParentObj.Addons, Settings)
        end
        Settings:Update()

        return Settings
    end

    --// Labels and toggles get their addon functions from BaseAddons, so expose AddSettings there too. \\--
    BaseAddons.__index.AddSettings = Funcs.AddSettings

    function Funcs:AddDivider(...)
        local Params = select(1, ...)
        local Text
        local MarginTop = 0
        local MarginBottom = 0

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 0
            MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local ExtraTop = 6

        local Section = self
        local Container = Section.Container

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14 + MarginTop + MarginBottom),
            Parent = Container,
        })

        local InnerHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingTop = UDim.new(0, MarginTop + ExtraTop),
            PaddingBottom = UDim.new(0, MarginBottom),
            Parent = Holder,
        })

        if Text then
            local TextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Text = Text,
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = InnerHolder,
            })

            local X, _ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            local SizeX = X // 2 + 10

            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
        else
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = InnerHolder,
            })
        end

        Section:Resize()

        local Divider = {
            Holder = Holder,
            Text = Text,
            MarginTop = MarginTop,
            MarginBottom = MarginBottom,
            Type = "Divider",
        }

        table.insert(Section.Elements, Divider)
        return Divider
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil

            --// Optional icon (name or picture) and subtext. \\--
            Data.Icon = Params.Icon
            Data.IconStyle = Params.IconStyle
            Data.IconColor = Params.IconColor
            Data.IconBackground = Params.IconBackground
            Data.Subtext = Params.Subtext
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Section = self
        local Container = Section.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local HasSubtext = typeof(Data.Subtext) == "string" and Data.Subtext ~= ""
        local DecorTile = Data.IconStyle == "Tile"
        local Decorated = (Data.Icon ~= nil or HasSubtext) and not Data.DoesWrap
        local IconSize = DecorTile and (HasSubtext and 32 or 24) or 16
        local DecorOffset = (Decorated and Data.Icon) and (IconSize + (DecorTile and 10 or 6)) or 0
        local MinRow = (Data.Icon and DecorTile) and (HasSubtext and 32 or 24) or 18
        local RowHeight = MinRow

        local Wrapper
        if Decorated then
            Wrapper = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, RowHeight),
                Parent = Container,
            })
        end

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = Decorated and UDim2.fromOffset(DecorOffset, 0) or UDim2.new(),
            Size = Decorated and UDim2.new(1, -DecorOffset, 0, HasSubtext and 16 or RowHeight) or UDim2.new(1, 0, 0, 18),
            Text = Label.Text,
            TextSize = Data.Size,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Section.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Wrapper or Container,
        })

        local SubtextLabel, IconImage
        if Decorated then
            if Data.Icon then
                local Tile
                Tile, IconImage = Library:CreateIconTile(Wrapper, Data.Icon, {
                    Size = IconSize,
                    Background = DecorTile and (Data.IconBackground == nil and "Accent" or Data.IconBackground or nil) or nil,
                    IconColor = Data.IconColor,
                })
                Tile.AnchorPoint = Vector2.new(0, 0.5)
                Tile.Position = UDim2.fromScale(0, 0.5)
            end

            if HasSubtext then
                SubtextLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    FontFace = function()
                        return Library:GetThinFont()
                    end,
                    Position = UDim2.fromOffset(DecorOffset, 16),
                    Size = UDim2.new(1, -DecorOffset, 0, 14),
                    Text = Data.Subtext,
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Parent = Wrapper,
                })

                local function UpdateSubtextHeight()
                    local Width = (Wrapper.AbsoluteSize.X / Library.DPIScale) - DecorOffset
                    local SubHeight = Library:GetSubtextHeight(SubtextLabel.Text, Width)
                    SubtextLabel.Size = UDim2.new(1, -DecorOffset, 0, SubHeight)
                    Wrapper.Size = UDim2.new(1, 0, 0, math.max(MinRow, 16 + SubHeight))
                    Section:Resize()
                end
                Library:BindWidth(Wrapper, UpdateSubtextHeight)
                Label.UpdateSubtextHeight = UpdateSubtextHeight
            end
        end

        function Label:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
                if Label.UpdateSubtextHeight then
                    Label.UpdateSubtextHeight()
                end
            end
        end

        function Label:SetIcon(Icon: any)
            if IconImage then
                Library:ApplyIcon(IconImage, Icon)
            end
        end

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            if Wrapper then
                Wrapper.Visible = Label.Visible
            end
            Section:Resize()
        end

        --// Re-measures a wrapping label (e.g. after the font changed). \\--
        function Label:RefreshWrap()
            if not Label.DoesWrap then
                return
            end

            task.spawn(function()
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                Section:Resize()
            end)
        end

        function Label:SetText(Text: string)
            task.spawn(function()
                Label.Text = Text
                TextLabel.Text = Text

                if Label.DoesWrap then
                    local _, Y =
                        Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
                end

                Section:Resize()
            end)
        end

        if Label.DoesWrap then
            task.spawn(function()
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                local Last = TextLabel.AbsoluteSize
                TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if TextLabel.AbsoluteSize == Last then
                        return
                    end

                    local _, Y =
                        Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                    TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)

                    Last = TextLabel.AbsoluteSize
                    Section:Resize()
                end)
            end)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        Section:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
            Label.AddSettings = Funcs.AddSettings
        end

        Label.Holder = TextLabel
        Label.RowHolder = Wrapper or TextLabel
        Label.Section = Section
        table.insert(Section.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function Funcs:AddButton(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick
                Info.Icon = Params.Icon

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Section = self
        local Container = Section.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,
            Icon = Info.Icon,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Base = nil,
            Stroke = nil,
            Content = nil,
            Label = nil,
            IconImage = nil,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function ApplyButtonIcon(Button, IconName)
            local Content = Button.Content
            if not Content then
                return
            end

            local ParsedIcon = IconName and Library:GetCustomIcon(IconName) or nil
            if ParsedIcon then
                local ColorKey = Button.Risky and "RedColor" or (ParsedIcon.Custom and "WhiteColor" or "FontColor")

                if not Button.IconImage then
                    Button.IconImage = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        ImageColor3 = ColorKey,
                        LayoutOrder = 0,
                        Size = UDim2.fromOffset(14, 14),
                        Parent = Content,
                    })
                else
                    Button.IconImage.ImageColor3 = Library.Scheme[ColorKey]
                    Library.Registry[Button.IconImage].ImageColor3 = ColorKey
                end

                Button.IconImage.Image = ParsedIcon.Url
                Button.IconImage.ImageRectOffset = ParsedIcon.ImageRectOffset
                Button.IconImage.ImageRectSize = ParsedIcon.ImageRectSize
                Button.IconImage.ImageTransparency = Button.Disabled and 0.8 or 0.4
                Button.IconImage.Visible = true
            elseif Button.IconImage then
                Button.IconImage.Visible = false
            end
        end

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Visible = Button.Visible,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Base,
                })
            )

            local Content = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 16),
                Parent = Base,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = Content,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Content,
            })

            Button.Content = Content
            Button.Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.fromOffset(0, 16),
                Text = Button.Text,
                TextSize = 14,
                TextTransparency = Button.Disabled and 0.8 or 0.4,
                Parent = Content,
            })

            if Button.Risky then
                Button.Label.TextColor3 = Library.Scheme.RedColor
                Library.Registry[Button.Label].TextColor3 = "RedColor"
            end

            ApplyButtonIcon(Button, Button.Icon)

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Label, Library.TweenInfo, {
                    TextTransparency = 0,
                })
                Button.Tween:Play()

                if Button.IconImage and Button.IconImage.Visible then
                    TweenService:Create(Button.IconImage, Library.TweenInfo, {
                        ImageTransparency = 0,
                    }):Play()
                end
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Label, Library.TweenInfo, {
                    TextTransparency = 0.4,
                })
                Button.Tween:Play()

                if Button.IconImage and Button.IconImage.Visible then
                    TweenService:Create(Button.IconImage, Library.TweenInfo, {
                        ImageTransparency = 0.4,
                    }):Play()
                end
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    local IconWasVisible = false
                    if Button.IconImage then
                        IconWasVisible = Button.IconImage.Visible
                        Button.IconImage.Visible = false
                    end

                    Button.Label.Text = "Are you sure?"
                    Button.Label.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Label].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 1.5)

                    Button.Label.Text = Button.Text
                    Button.Label.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[Button.Label].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                    if Button.IconImage then
                        Button.IconImage.Visible = IconWasVisible
                    end

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait()
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,
                Icon = Info.Icon,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Base = nil,
                Stroke = nil,
                Content = nil,
                Label = nil,
                IconImage = nil,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)

            SubButton.Holder = SubButton.Base
            SubButton.Section = Section
            SubButton.Container = Container
            SubButton.AddSettings = Funcs.AddSettings
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Label.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                if SubButton.IconImage and SubButton.IconImage.Visible then
                    SubButton.IconImage.ImageTransparency = SubButton.Disabled and 0.8 or 0.4
                end

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Section:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Label.Text = Text
            end

            function SubButton:SetIcon(Icon: string?)
                SubButton.Icon = Icon
                ApplyButtonIcon(SubButton, Icon)
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Label.TextColor3 = Library.Scheme.RedColor
                Library.Registry[SubButton.Label].TextColor3 = "RedColor"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Label.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            if Button.IconImage and Button.IconImage.Visible then
                Button.IconImage.ImageTransparency = Button.Disabled and 0.8 or 0.4
            end

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Section:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Label.Text = Text
        end

        function Button:SetIcon(Icon: string?)
            Button.Icon = Icon
            ApplyButtonIcon(Button, Icon)
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Button.Label].TextColor3 = "RedColor"
        end

        Button:UpdateColors()
        Section:Resize()

        Button.Holder = Holder
        Button.Section = Section
        Button.Container = Container
        Button.AddSettings = Funcs.AddSettings
        table.insert(Section.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    local function BuildSwitchVisual(Button: GuiObject)
        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(32, 18),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        local function Display(Toggle)
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            if Library.Registry[Switch] then
                Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            end
            if Library.Registry[SwitchStroke] then
                Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"
            end

            if Toggle.Disabled then
                Toggle.TextLabel.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                if Library.Registry[Ball] then
                    Library.Registry[Ball].BackgroundColor3 = function()
                        return Library:GetDarkerColor(Library.Scheme.FontColor)
                    end
                end

                return
            end

            TweenService:Create(Toggle.TextLabel, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            if Library.Registry[Ball] then
                Library.Registry[Ball].BackgroundColor3 = "FontColor"
            end
        end

        return Switch, Display
    end

    local function BuildCheckboxVisual(Button: GuiObject)
        local Checkbox = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(18, 18),
            Parent = Button,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
        )

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })
        Library:RegisterIconInstance(CheckImage, "check")

        local function Display(Toggle)
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Toggle.TextLabel.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Toggle.TextLabel, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
        end

        return Checkbox, Display
    end

    local function ConstructToggle(Section, Container, Info, InitialVariant: string, ExplicitCheckbox: boolean?)
        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            FireDefault = Info.FireDefault,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            DefaultApplied = false,

            Variant = InitialVariant,

            ExplicitCheckbox = ExplicitCheckbox or false,
            Type = "Toggle",
        }

        --// Optional Icon (name or picture) and Subtext. IconStyle "Tile" gives a larger icon tile. \\--
        local DecorIcon = Info.Icon
        local DecorTile = Info.IconStyle == "Tile"
        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""
        local MinRow = (DecorIcon and DecorTile) and (HasSubtext and 32 or 24) or 18
        local IconSize = DecorTile and (HasSubtext and 32 or 24) or 16
        local DecorOffset = DecorIcon and (IconSize + (DecorTile and 10 or 6)) or 0

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, MinRow),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        Toggle.TextLabel = Label

        local IconHolder, IconImage
        if DecorIcon then
            IconHolder, IconImage = Library:CreateIconTile(Button, DecorIcon, {
                Size = IconSize,
                Background = DecorTile and (Info.IconBackground == nil and "Accent" or Info.IconBackground or nil) or nil,
                IconColor = Info.IconColor,
            })
            IconHolder.AnchorPoint = Vector2.new(0, 0.5)
        end

        local SubtextLabel
        if HasSubtext then
            SubtextLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetThinFont()
                end,
                Text = Info.Subtext,
                TextSize = 12,
                TextTransparency = 0.5,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = Button,
            })
            Toggle.SubtextLabel = SubtextLabel
        end

        local Visual: GuiObject
        local DisplayImpl: (Toggle: any) -> ()

        local TextOffset, TextRightPad = 0, 0
        local ReservedRight = 0 --// space kept free on the right (settings gear)

        --// Title on top, subtext tight underneath (wrapping onto more lines when needed). \\--
        local function UpdateRowHeight()
            local Width = (Button.AbsoluteSize.X / Library.DPIScale) - (TextOffset + TextRightPad)

            if HasSubtext then
                local SubHeight = Library:GetSubtextHeight(SubtextLabel.Text, Width)
                SubtextLabel.Position = UDim2.fromOffset(TextOffset, 16)
                SubtextLabel.Size = UDim2.new(1, -(TextOffset + TextRightPad), 0, SubHeight)
                Label.Position = UDim2.fromOffset(TextOffset, 0)
                Label.Size = UDim2.new(1, -(TextOffset + TextRightPad), 0, 16)

                local Wanted = math.max(MinRow, 16 + SubHeight)
                if Button.Size.Y.Offset ~= Wanted then
                    Button.Size = UDim2.new(1, 0, 0, Wanted)
                    Section:Resize()
                end
            else
                Label.Position = UDim2.fromOffset(TextOffset, 0)
                Label.Size = UDim2.new(1, -(TextOffset + TextRightPad), 1, 0)
            end
        end

        local function ApplyVariantLayout()
            local Base = Toggle.Variant == "Checkbox" and 26 or 0
            TextRightPad = (Toggle.Variant == "Checkbox" and 0 or 40) + ReservedRight
            TextOffset = Base + DecorOffset

            if IconHolder then
                IconHolder.Position = UDim2.new(0, Base, 0.5, 0)
            end

            UpdateRowHeight()
        end

        if HasSubtext then
            Library:BindWidth(Button, UpdateRowHeight)
        end

        function Toggle:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
                UpdateRowHeight()
            end
        end

        function Toggle:SetIcon(Icon: any)
            if IconImage then
                Library:ApplyIcon(IconImage, Icon)
            end
        end

        function Toggle:SetVariant(Variant: string)
            assert(Variant == "Switch" or Variant == "Checkbox", "Variant must be 'Switch' or 'Checkbox'.")

            if Toggle.Variant == Variant and Visual then
                return
            end

            Toggle.Variant = Variant

            if Visual then
                Visual:Destroy()
                Visual = nil
            end

            ApplyVariantLayout()

            if Variant == "Checkbox" then
                Visual, DisplayImpl = BuildCheckboxVisual(Button)
            else
                Visual, DisplayImpl = BuildSwitchVisual(Button)
            end

            if Visual and Variant ~= "Checkbox" and ReservedRight > 0 then
                Visual.Position = UDim2.new(1, -ReservedRight, 0.5, 0)
            end

            Toggle:Display()
        end

        --// Keeps the right edge free for the settings gear: text shrinks, switch moves left. \\--
        function Toggle:ReserveRight(Amount: number)
            ReservedRight += Amount
            ApplyVariantLayout()

            if Visual and Toggle.Variant ~= "Checkbox" then
                Visual.Position = UDim2.new(1, -ReservedRight, 0.5, 0)
            end
        end

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if DisplayImpl then
                DisplayImpl(Toggle)
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:RunChanged()
            if Toggle.Disabled then
                return
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.DefaultApplied = true

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateConditionalGroups()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                elseif Addon.Type == "ColorPicker" and Addon.Update then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Section:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        ApplyVariantLayout()
        if InitialVariant == "Checkbox" then
            Visual, DisplayImpl = BuildCheckboxVisual(Button)
        else
            Visual, DisplayImpl = BuildSwitchVisual(Button)
        end

        Toggle:Display()
        Section:Resize()

        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        --// Direct field, so Toggle:AddSettings() doesn't depend on the BaseAddons.__index lookup. \\--
        Toggle.AddSettings = Funcs.AddSettings

        Toggle.Holder = Button
        Toggle.Section = Section
        table.insert(Section.Elements, Toggle)

        Toggle.Default = Toggle.Value

        if Toggle.FireDefault and Toggle.Value == true then
            local DeferredToggle = Toggle

            task.defer(function()
                if Library.Unloaded or DeferredToggle.Disabled then
                    return
                end

                if DeferredToggle.DefaultApplied or DeferredToggle.Value ~= DeferredToggle.Default then
                    return
                end

                DeferredToggle.DefaultApplied = true

                Library:UpdateConditionalGroups()
                Library:SafeCallback(DeferredToggle.Callback, DeferredToggle.Value)
                Library:SafeCallback(DeferredToggle.Changed, DeferredToggle.Value)
            end)
        end

        return Toggle
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Section = self
        local Container = Section.Container

        local Toggle = ConstructToggle(Section, Container, Info, "Checkbox", true)
        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Section = self
        local Container = Section.Container

        local Toggle = ConstructToggle(Section, Container, Info, Library.ForceCheckbox and "Checkbox" or "Switch")
        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        if typeof(Info) == "table" and (typeof(Info.VerifyValue) == "function" and Info.Finished ~= true) then
            Info.Finished = true
        end

        Info = Library:Validate(Info, Templates.Input)

        local Section = self
        local Container = Section.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            ClearTextOnBlur = Info.ClearTextOnBlur,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,
            VerifyValue = Info.VerifyValue,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""
        local IconOffset = Info.Icon and 22 or 0

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 39),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(IconOffset, 0),
            Size = UDim2.new(1, -IconOffset, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local IconTile
        if Info.Icon then
            IconTile = Library:CreateIconTile(Holder, Info.Icon, { Size = 14, IconColor = Info.IconColor })
            IconTile.AnchorPoint = Vector2.new(0, 0.5)
            IconTile.Position = UDim2.fromOffset(0, (14 + (HasSubtext and 14 or 0)) / 2)
        end

        local SubtextLabel
        if HasSubtext then
            SubtextLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetThinFont()
                end,
                Position = UDim2.fromOffset(IconOffset, 14),
                Size = UDim2.new(1, -IconOffset, 0, 14),
                Text = Info.Subtext,
                TextSize = 12,
                TextTransparency = 0.5,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = Holder,
            })
        end

        local function UpdateSubtextHeight()
            if not SubtextLabel then
                return
            end

            local Width = (Holder.AbsoluteSize.X / Library.DPIScale) - IconOffset
            local SubHeight = Library:GetSubtextHeight(SubtextLabel.Text, Width)
            SubtextLabel.Size = UDim2.new(1, -IconOffset, 0, SubHeight)
            Holder.Size = UDim2.new(1, 0, 0, 39 + SubHeight)
            if IconTile then
                IconTile.Position = UDim2.fromOffset(0, (14 + SubHeight) / 2)
            end
            Section:Resize()
        end
        if SubtextLabel then
            Library:BindWidth(Holder, UpdateSubtextHeight)
        end

        function Input:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
                UpdateSubtextHeight()
            end
        end

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Box,
        })

        Library:AddFocusHighlight(Box)

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Box,
            })
        )

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:RunChanged()
            if Input.Disabled then
                return
            end

            Library:SafeCallback(Input.Callback, Input.Value)
            Library:SafeCallback(Input.Changed, Input.Value)
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            if typeof(Info.VerifyValue) == "function" and (Text ~= Input.EmptyReset and Info.VerifyValue(Text) ~= true) then
                Text = Input.EmptyReset
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Section:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            Box.FocusLost:Connect(function(Enter)

                if not Enter and Input.ClearTextOnBlur then
                    Box.Text = Input.Value
                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then return end

                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Section:Resize()

        Input.Holder = Holder
        Input.Section = Section
        Input.Container = Container
        Input.AddSettings = Funcs.AddSettings
        table.insert(Section.Elements, Input)

        Input.Default = Input.Value
        if typeof(Info.VerifyValue) == "function" and (Input.Default ~= Input.EmptyReset and Info.VerifyValue(Input.Default) ~= true) then
            Input:SetValue(Input.EmptyReset)
            Input.Default = Input.EmptyReset
        end

        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

        local Section = self
        local Container = Section.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,
            Editable = Info.Editable,
            EditableStyle = Info.EditableStyle or "ValueBox",

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local IsValueBoxStyle = Slider.Editable and Slider.EditableStyle == "ValueBox"

        local ValueBoxHeight = 21
        local TopRowHeight = IsValueBoxStyle and math.max(14, ValueBoxHeight) or 14
        local VerticalGap = IsValueBoxStyle and 6 or 4

        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= "" and not Info.Compact
        local IconOffset = (Info.Icon and not Info.Compact) and 22 or 0

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or (TopRowHeight + VerticalGap + 15)),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        local InlineValueBox
        if not Info.Compact then

            local ValueBoxWidth = 56
            local ValueBoxGap = 8

            local LabelWidth = (Slider.Editable and Slider.EditableStyle == "ValueBox")
                and UDim2.new(1, -(ValueBoxWidth + ValueBoxGap + IconOffset), 0, TopRowHeight)
                or  UDim2.new(1, -IconOffset, 0, 14)

            local IconTile
            local function CenterSliderIcon(SubHeight)
                if IconTile then
                    local LabelH = HasSubtext and 16 or TopRowHeight
                    local TotalH = HasSubtext and (LabelH + (SubHeight or 14)) or TopRowHeight
                    IconTile.AnchorPoint = Vector2.new(0, 0.5)
                    IconTile.Position = UDim2.fromOffset(0, TotalH / 2)
                end
            end

            if Info.Icon then
                IconTile = Library:CreateIconTile(Holder, Info.Icon, { Size = 14, IconColor = Info.IconColor })
                CenterSliderIcon(14)
            end

            if HasSubtext then
                local SubtextTop = 16
                local SliderSubtext = New("TextLabel", {
                    BackgroundTransparency = 1,
                    FontFace = function()
                        return Library:GetThinFont()
                    end,
                    Position = UDim2.fromOffset(IconOffset, SubtextTop),
                    Size = UDim2.new(1, -IconOffset, 0, 14),
                    Text = Info.Subtext,
                    TextSize = 12,
                    TextTransparency = 0.5,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Parent = Holder,
                })

                local function UpdateSubtextHeight()
                    local Width = (Holder.AbsoluteSize.X / Library.DPIScale) - IconOffset
                    local SubHeight = Library:GetSubtextHeight(SliderSubtext.Text, Width)
                    SliderSubtext.Size = UDim2.new(1, -IconOffset, 0, SubHeight)
                    Holder.Size = UDim2.new(1, 0, 0, TopRowHeight + VerticalGap + 15 + math.max(SubHeight - (TopRowHeight - SubtextTop), 0))
                    CenterSliderIcon(SubHeight)
                    Section:Resize()
                end
                Library:BindWidth(Holder, UpdateSubtextHeight)

                function Slider:SetSubtext(Text: string)
                    SliderSubtext.Text = Text
                    UpdateSubtextHeight()
                end
            end

            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(IconOffset, 0),
                Size = LabelWidth,
                Text = Slider.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = HasSubtext and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
                Parent = Holder,
            })

            if Slider.Editable and Slider.EditableStyle == "ValueBox" then
                InlineValueBox = New("TextBox", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = "MainColor",
                    ClearTextOnFocus = true,

                    Position = UDim2.new(1, 0, 0, TopRowHeight / 2),
                    Size = UDim2.fromOffset(ValueBoxWidth, ValueBoxHeight),
                    Text = tostring(Slider.Value),
                    TextSize = 12,
                    TextEditable = not Slider.Disabled,
                    Parent = Holder,
                })
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = InlineValueBox,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = InlineValueBox,
                    })
                )
                Library:AddToRegistry(InlineValueBox, { BackgroundColor3 = "MainColor" })
                Library:AddFocusHighlight(InlineValueBox)
            end
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 15),
            Text = "",
            Parent = Holder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = Bar.ZIndex + 1,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = GetTextStrokeColor,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local InputTextBox
        local InputTextBoxStroke
        if Info.AllowRightClickInput then
            InputTextBox = New("TextBox", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                ZIndex = Bar.ZIndex + 3,
                Visible = false,
                ClearTextOnFocus = false,
                Parent = Bar,
            })
            InputTextBoxStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = InputTextBox,
            })
            Library:AddFocusHighlight(InputTextBox, InputTextBoxStroke, {
                Background = false,
            })
        end

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            ZIndex = Bar.ZIndex,
            Parent = Bar,
        })

        local EditButton, ValueBox
        if Slider.Editable and Slider.EditableStyle ~= "ValueBox" then

            EditButton = New("ImageButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = EditIcon and EditIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = EditIcon and EditIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = EditIcon and EditIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.4,
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(12, 12),
                Parent = Bar,
            })
            Library:AddToRegistry(EditButton, { ImageColor3 = "FontColor" })
            Library:RegisterIconInstance(EditButton, "pencil")

            ValueBox = New("TextBox", {
                BackgroundColor3 = "MainColor",
                ClearTextOnFocus = true,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextEditable = not Slider.Disabled,
                Visible = false,
                Parent = Bar,
            })
            New("UIStroke", {
                Color = "AccentColor",
                Parent = ValueBox,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = ValueBox,
                })
            )
            Library:AddFocusHighlight(ValueBox, nil, {
                Color = "AccentColor",
                BackgroundShift = 8,
            })
        end

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Bar,
            })
        )

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Fill,
            })
        )

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            if Info.AllowRightClickInput then
                InputTextBox.TextTransparency = Slider.Disabled and 0.8 or 0
            end

            if EditButton then
                EditButton.ImageTransparency = Slider.Disabled and 0.8 or 0.4
            end

            if InlineValueBox then
                InlineValueBox.TextTransparency = Slider.Disabled and 0.8 or 0
                Library.Registry[InlineValueBox].BackgroundColor3 = "MainColor"
            end

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s/%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.fromScale(X, 1)

            if InlineValueBox and not InlineValueBox:IsFocused() then
                InlineValueBox.Text = tostring(Slider.Value)
            end
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:RunChanged()
            if Slider.Disabled then
                return
            end

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            if EditButton then
                EditButton.Active = not Slider.Disabled
            end
            if ValueBox then
                ValueBox.TextEditable = not Slider.Disabled
            end
            if InlineValueBox then
                InlineValueBox.TextEditable = not Slider.Disabled
            end
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Section:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        if Info.AllowRightClickInput then
            local LastValidText = ""
            InputTextBox:GetPropertyChangedSignal("Text"):Connect(function()
                local Text = InputTextBox.Text
                local AsNum = tonumber(Text)

                if #tostring(Text) > 0 and not AsNum and Text ~= "-" then
                    InputTextBox.Text = LastValidText
                else
                    if Slider.Rounding == 0 and Text:find("%.") then
                        InputTextBox.Text = LastValidText
                        return
                    end

                    local DecimalPos = Text:find("%.")
                    if DecimalPos and Slider.Rounding > 0 then
                        local Decimals = #Text - DecimalPos
                        if Decimals > Slider.Rounding then
                            InputTextBox.Text = LastValidText
                            return
                        end
                    end

                    LastValidText = Text

                    if AsNum then
                        if AsNum > Slider.Max then
                            InputTextBox.Text = tostring(Slider.Max)
                        elseif AsNum < Slider.Min then
                            InputTextBox.Text = tostring(Slider.Min)
                        end
                    end
                end
            end)

            InputTextBox.FocusLost:Connect(function()
                InputTextBox.Visible = false
                DisplayLabel.Visible = true

                local Num = tonumber(InputTextBox.Text)
                if not Num then
                    return
                end

                Num = Round(Num, Slider.Rounding)
                Slider:SetValue(Num)
            end)

            InputTextBox.Focused:Connect(function()
                if Slider.Disabled then
                    return
                end

                Library.Registry[InputTextBoxStroke].Color = "AccentColor"
                TweenService:Create(InputTextBoxStroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end)

            InputTextBox.FocusLost:Connect(function()
                if Slider.Disabled then
                    return
                end

                Library.Registry[InputTextBoxStroke].Color = "DarkColor"
                TweenService:Create(InputTextBoxStroke, Library.TweenInfo, {
                    Color = Library.Scheme.DarkColor,
                }):Play()
            end)
        end

        local LastTap = 0
        Bar.InputBegan:Connect(function(Input: InputObject)
            local ValidInput = IsClickInput(Input) or Input.UserInputType == Enum.UserInputType.MouseButton2
            if not ValidInput or Slider.Disabled then
                return
            end

            if Info.AllowRightClickInput then
                local IsRightClick = Input.UserInputType == Enum.UserInputType.MouseButton2
                local IsDoubleTap = false

                if Library.IsMobile and Input.UserInputType == Enum.UserInputType.Touch then
                    if tick() - LastTap < 0.3 then
                        IsDoubleTap = true
                    end

                    LastTap = tick()
                end

                if IsRightClick or IsDoubleTap then
                    InputTextBox.Text = tostring(Slider.Value)
                    InputTextBox.Visible = true
                    DisplayLabel.Visible = false

                    task.spawn(InputTextBox.CaptureFocus, InputTextBox)
                    return
                end
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = false
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = false
            end

            local StartMouseX = Mouse.X
            local StartBarX = Bar.AbsolutePosition.X
            local StartBarWidth = math.max(Bar.AbsoluteSize.X, 1)
            local StartScale = math.clamp((StartMouseX - StartBarX) / StartBarWidth, 0, 1)

            while IsDragInput(Input) do

                local CurrentBarX = Bar.AbsolutePosition.X
                local CurrentBarWidth = math.max(Bar.AbsoluteSize.X, 1)
                if CurrentBarX ~= StartBarX or CurrentBarWidth ~= StartBarWidth then
                    StartScale = math.clamp((Slider.Value - Slider.Min) / math.max(Slider.Max - Slider.Min, 1e-6), 0, 1)
                    StartBarX = CurrentBarX
                    StartBarWidth = CurrentBarWidth
                    StartMouseX = Mouse.X
                end

                local DeltaX = Mouse.X - StartMouseX
                local Scale = math.clamp(StartScale + (DeltaX / StartBarWidth), 0, 1)

                local OldValue = Slider.Value
                local NewValue = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                if NewValue ~= OldValue then
                    Slider.Value = NewValue
                    Slider:Display()
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = true
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = true
            end
        end)

        if EditButton and ValueBox then
            local function EnterEditMode()
                if Slider.Disabled then
                    return
                end

                DisplayLabel.Visible = false
                EditButton.Visible = false
                ValueBox.Text = tostring(Slider.Value)
                ValueBox.Visible = true
                ValueBox:CaptureFocus()
            end

            local function ExitEditMode(Commit: boolean)
                if Commit then
                    Slider:SetValue(ValueBox.Text)
                end

                ValueBox.Visible = false
                DisplayLabel.Visible = true
                EditButton.Visible = true
            end

            EditButton.MouseButton1Click:Connect(EnterEditMode)

            ValueBox.FocusLost:Connect(function(Enter)
                ExitEditMode(Enter)
            end)
        end

        if InlineValueBox then
            InlineValueBox.FocusLost:Connect(function(Enter)
                if Enter then
                    Slider:SetValue(InlineValueBox.Text)
                end

                InlineValueBox.Text = tostring(Slider.Value)
            end)
        end

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Section:Resize()

        Slider.Holder = Holder
        Slider.Section = Section
        Slider.Container = Container
        Slider.TextLabel = SliderLabel
        Slider.InlineValueBox = InlineValueBox
        Slider.TopRowHeight = TopRowHeight
        Slider.AddSettings = Funcs.AddSettings

        --// Shrinks the label so its text doesn't run under the settings gear. \\--
        function Slider:ReserveRight(Amount: number)
            Slider.ReservedRight = (Slider.ReservedRight or 0) + Amount

            if InlineValueBox then
                InlineValueBox.Position = UDim2.new(1, -Slider.ReservedRight, 0, TopRowHeight / 2)
            end

            if SliderLabel and SliderLabel.Parent then
                local Size = SliderLabel.Size
                SliderLabel.Size = UDim2.new(Size.X.Scale, Size.X.Offset - Amount, Size.Y.Scale, Size.Y.Offset)
            end
        end

        table.insert(Section.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        return Slider
    end

    --// Button that shows an icon (and optionally text). Square by default, so it lines up with a
    --// dropdown or input in a Row. \\--
    function Funcs:AddIconButton(...)
        local First, Second = select(1, ...), select(2, ...)
        local Params = typeof(First) == "table" and First or (typeof(Second) == "table" and Second or {})
        local Idx = typeof(First) == "string" and First or nil

        local Info = Library:Validate(Params, Templates.IconButton)

        local Section = self
        local Container = Section.Container

        local IconButton = {
            Icon = Info.Icon,
            Text = Info.Text,
            Func = Info.Func or Info.Callback or function() end,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "IconButton",
        }

        local HasText = typeof(Info.Text) == "string" and Info.Text ~= ""
        local Base = New("TextButton", {
            Active = not IconButton.Disabled,
            AutomaticSize = HasText and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(HasText and 0 or Info.Size, Info.Size),
            Text = "",
            Visible = IconButton.Visible,
            Parent = Container,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Base,
            })
        )
        local Stroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Base,
        })

        local ContentLayout = New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = Base,
        })
        if HasText then
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Base,
            })
        end

        local IconImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            ImageColor3 = IconButton.Risky and "RedColor" or "FontColor",
            ImageTransparency = 0.4,
            LayoutOrder = 1,
            Size = UDim2.fromOffset(Info.IconSize, Info.IconSize),
            Parent = Base,
        })
        Library:ApplyIcon(IconImage, IconButton.Icon)

        local TextLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Size = UDim2.fromOffset(0, 16),
            Text = Info.Text,
            TextColor3 = IconButton.Risky and "RedColor" or "FontColor",
            TextSize = 14,
            TextTransparency = 0.4,
            Visible = HasText,
            Parent = Base,
        })

        local function Paint(Hover: boolean)
            local Dim = IconButton.Disabled and 0.8 or (Hover and 0 or 0.4)
            TweenService:Create(IconImage, Library.TweenInfo, { ImageTransparency = Dim }):Play()
            TweenService:Create(TextLabel, Library.TweenInfo, { TextTransparency = Dim }):Play()
            Stroke.Transparency = IconButton.Disabled and 0.5 or 0
        end

        Base.MouseEnter:Connect(function()
            if not IconButton.Disabled then
                Paint(true)
            end
        end)
        Base.MouseLeave:Connect(function()
            Paint(false)
        end)
        Base.MouseButton1Click:Connect(function()
            if IconButton.Disabled then
                return
            end

            Library:SafeCallback(IconButton.Func)
        end)

        function IconButton:SetIcon(Icon: any)
            IconButton.Icon = Icon
            Library:ApplyIcon(IconImage, Icon)
        end

        function IconButton:SetText(Text: string)
            IconButton.Text = Text
            TextLabel.Text = Text
            TextLabel.Visible = Text ~= ""
        end

        function IconButton:SetDisabled(Disabled: boolean)
            IconButton.Disabled = Disabled
            Base.Active = not Disabled
            Paint(false)

            if IconButton.TooltipTable then
                IconButton.TooltipTable.Disabled = Disabled
            end
        end

        function IconButton:SetVisible(Visible: boolean)
            IconButton.Visible = Visible
            Base.Visible = Visible
            Section:Resize()
        end

        function IconButton:SetTooltip(Tooltip: string)
            IconButton.Tooltip = Tooltip
            if IconButton.TooltipTable then
                IconButton.TooltipTable.Text = Tooltip
            elseif typeof(Tooltip) == "string" then
                IconButton.TooltipTable = Library:AddTooltip(Tooltip, IconButton.DisabledTooltip, Base)
                IconButton.TooltipTable.Disabled = IconButton.Disabled
            end
        end

        if typeof(IconButton.Tooltip) == "string" or typeof(IconButton.DisabledTooltip) == "string" then
            IconButton.TooltipTable = Library:AddTooltip(IconButton.Tooltip, IconButton.DisabledTooltip, Base)
            IconButton.TooltipTable.Disabled = IconButton.Disabled
        end

        Paint(false)
        Section:Resize()

        IconButton.Base = Base
        IconButton.Holder = Base
        IconButton.RowHolder = Base
        IconButton.Section = Section
        table.insert(Section.Elements, IconButton)

        if Idx then
            Options[Idx] = IconButton
        end

        return IconButton
    end

    --// A horizontal line of controls. Items are added with the normal Add functions
    --// (Row:AddDropdown, Row:AddIconButton, Row:AddButton, Row:AddInput, ...) and sized with
    --// Width = "Fill" (shares the free space, default), "Auto" (fits its content) or a pixel number.
    --// Weight changes how much of the free space a Fill item takes. \\--
    function Funcs:AddRow(Info)
        Info = typeof(Info) == "table" and Info or {}

        local Section = self
        local Container = Section.Container
        local Gap = Info.Gap or 6

        local RowFrame = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height or 21),
            Visible = Info.Visible ~= false,
            Parent = Container,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, Gap),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Parent = RowFrame,
        })

        local Row = {
            Container = RowFrame,
            Holder = RowFrame,
            Section = Section,

            Items = {},
            Elements = {},
            ConditionalGroups = {},

            Visible = Info.Visible ~= false,
            Type = "Row",
        }

        function Row:Resize()
            Section:Resize()
        end

        function Row:SetVisible(Visible: boolean)
            Row.Visible = Visible
            RowFrame.Visible = Visible
            Section:Resize()
        end

        --// Width an element wants when it is set to "Auto" (nil means it cannot size itself, so it fills). \\--
        local function NaturalWidth(Element): number?
            if Element.Type == "IconButton" then
                local HasText = typeof(Element.Text) == "string" and Element.Text ~= ""
                if HasText then
                    local TextWidth = Library:GetTextBounds(Element.Text, Library.Scheme.Font, 14, 400)
                    local IconSize = 14
                    return math.ceil(TextWidth) + IconSize + 22
                else
                    return 21
                end
            end

            local Text = Element.Text
            if typeof(Text) ~= "string" then
                return nil
            end

            local Width = Library:GetTextBounds(Text, Library.Scheme.Font, 14, 400)
            if Element.Type == "Button" or Element.Type == "SubButton" then
                return math.ceil(Width) + 24
            elseif Element.Type == "Label" then
                return math.ceil(Width) + 4
            elseif Element.Type == "Toggle" or Element.Type == "Checkbox" then
                return math.ceil(Width) + 50
            end

            return nil
        end

        --// Shares the row out: pixel items keep their width, Auto items take their natural width and Fill
        --// items split what is left by Weight. \\\\--
        function Row:Layout()
            if Library.Unloaded then
                return
            end

            local Total = RowFrame.AbsoluteSize.X / Library.DPIScale
            local Used, Weights, Count = 0, 0, 0

            for _, Item in Row.Items do
                local Holder = Item.Element.RowHolder or Item.Element.Holder
                if Holder and Holder.Visible then
                    Count += 1
                    if typeof(Item.Width) == "number" then
                        Item.Pixels = Item.Width
                        Used += Item.Width
                    elseif Item.Width == "Auto" and NaturalWidth(Item.Element) then
                        Item.Pixels = NaturalWidth(Item.Element)
                        Used += Item.Pixels
                    else
                        Item.Pixels = nil
                        Weights += Item.Weight or 1
                    end
                end
            end

            local Free = math.max(Total - Used - math.max(Count - 1, 0) * Gap, 0)
            for _, Item in Row.Items do
                local Holder = Item.Element.RowHolder or Item.Element.Holder
                if Holder and Holder.Visible then
                    local Width = Item.Pixels or (Weights > 0 and math.floor(Free * (Item.Weight or 1) / Weights) or 0)
                    local SizeY = Holder.Size.Y
                    Holder.AutomaticSize = Holder.AutomaticSize == Enum.AutomaticSize.XY and Enum.AutomaticSize.Y
                        or (Holder.AutomaticSize == Enum.AutomaticSize.X and Enum.AutomaticSize.None or Holder.AutomaticSize)
                    Holder.Size = UDim2.new(0, Width, SizeY.Scale, SizeY.Offset)
                end
            end
        end

        local LayoutQueued = false
        local function QueueLayout()
            if LayoutQueued then
                return
            end
            LayoutQueued = true
            task.defer(function()
                LayoutQueued = false
                Row:Layout()
            end)
        end
        RowFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(QueueLayout)

        --// Width: "Fill" | "Auto" | number (pixels). Weight: relative share for Fill items. \\\\--
        function Row:SetItemWidth(Element, Width: any, Weight: number?)
            for _, Item in Row.Items do
                if Item.Element == Element then
                    Item.Width = Width
                    Item.Weight = Weight or Item.Weight or 1
                    Row:Layout()
                    return
                end
            end
        end

        local WidthDefaults = { IconButton = "Auto" }
        for _, Name in { "AddDropdown", "AddIconButton", "AddButton", "AddInput", "AddLabel", "AddStepper", "AddToggle", "AddCheckbox", "AddSlider" } do
            local Add = Funcs[Name]
            if Add then
                Row[Name] = function(self, ...)
                    local Element = Add(self, ...)

                    local ElementInfo
                    for Index = 1, select("#", ...) do
                        local Arg = select(Index, ...)
                        if typeof(Arg) == "table" then
                            ElementInfo = Arg
                            break
                        end
                    end

                    local Width = ElementInfo and ElementInfo.Width
                    if Width == nil then
                        Width = WidthDefaults[Element.Type] or "Fill"
                    end

                    local Holder = Element.RowHolder or Element.Holder
                    if Holder then
                        Holder.LayoutOrder = #Row.Items + 1
                        if Holder.Name == "Frame" or true then
                            local Watch = Width == "Auto"
                            if Watch then
                                Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(QueueLayout)
                            end
                        end
                    end

                    table.insert(Row.Items, { Element = Element, Width = Width, Weight = ElementInfo and ElementInfo.Weight or 1 })
                    Row:Layout()
                    QueueLayout()

                    return Element
                end
            end
        end

        setmetatable(Row, BaseSection)

        Section:Resize()
        table.insert(Section.Elements, Row)

        return Row
    end

    function Funcs:AddStepper(Idx, Info)
        Info = Library:Validate(Info, Templates.Stepper)

        local Section = self
        local Container = Section.Container

        local Stepper = {
            Text = Info.Text,
            Value = nil,

            Min = Info.Min,
            Max = Info.Max,
            Increment = Info.Increment,
            Rounding = Info.Rounding,
            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            ValueTexts = Info.ValueTexts,
            Format = Info.Format,
            Holdable = Info.Holdable,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Stepper",
        }

        local function Normalize(Value: number): number
            local Factor = 10 ^ Stepper.Rounding
            return math.clamp(math.round(Value * Factor) / Factor, Stepper.Min, Stepper.Max)
        end
        Stepper.Value = Normalize(Info.Default ~= nil and Info.Default or Stepper.Min)

        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""
        local ControlsWidth = Info.ValueWidth + 50 --// 21 + 4 + value + 4 + 21

        local Holder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Visible = Stepper.Visible,
            Parent = Container,
        })

        --// Label side: icon + title + subtext, leaving room for the buttons on the right. \\\\--
        local LabelBlock = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -(ControlsWidth + 8), 0, 0),
            Parent = Holder,
        })

        local IconOffset = 0
        if Info.Icon then
            local IconTile = Library:CreateIconTile(LabelBlock, Info.Icon, { Size = 16, IconColor = Info.IconColor })
            IconTile.AnchorPoint = Vector2.new(0, 0.5)
            IconTile.Position = UDim2.new(0, 0, 0.5, 0)
            IconOffset = 22
        end

        local TextStack = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(IconOffset, 0),
            Size = UDim2.new(1, -IconOffset, 0, 0),
            Parent = LabelBlock,
        })
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TextStack,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, HasSubtext and 17 or 21),
            Text = Stepper.Text,
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TextStack,
        })
        local SubtextLabel
        if HasSubtext then
            SubtextLabel = Library:CreateSubtext(TextStack, Info.Subtext, { LayoutOrder = 1 })
        end

        --// Buttons: a fixed-size block on the right, vertically centered. \\\\--
        local Controls = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(ControlsWidth, 21),
            Parent = Holder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = Controls,
        })

        local function MakeStepButton(IconName: string, Order: number)
            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                LayoutOrder = Order,
                Size = UDim2.fromOffset(21, 21),
                Text = "",
                Parent = Controls,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
            )
            local ButtonStroke = New("UIStroke", {
                Color = "OutlineColor",
                Parent = Button,
            })
            local Icon = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                ImageTransparency = 0.4,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(12, 12),
                Parent = Button,
            })
            Library:ApplyIcon(Icon, IconName)
            return Button, Icon, ButtonStroke
        end

        local MinusButton, MinusIcon, MinusStroke = MakeStepButton("minus", 1)
        local ValueLabel = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            LayoutOrder = 2,
            Size = UDim2.fromOffset(Info.ValueWidth, 21),
            Text = "",
            TextColor3 = "FontColor",
            TextSize = 14,
            TextEditable = not Stepper.Disabled,
            Parent = Controls,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = ValueLabel,
            })
        )
        local ValueLabelStroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = 1,
            Parent = ValueLabel,
        })

        ValueLabel.Focused:Connect(function()
            if Stepper.Disabled then
                ValueLabel:ReleaseFocus()
                return
            end
            ValueLabel.Text = tostring(Stepper.Value)
            ValueLabel.BackgroundTransparency = 0.7
            ValueLabelStroke.Transparency = 0.3
        end)

        ValueLabel.FocusLost:Connect(function(Enter)
            ValueLabel.BackgroundTransparency = 1
            ValueLabelStroke.Transparency = 1
            if Stepper.Disabled then
                Stepper:Display()
                return
            end
            local Raw = ValueLabel.Text
            local Num = tonumber(Raw)
            if Num then
                Stepper:SetValue(Num)
            else
                Stepper:Display()
            end
        end)

        local PlusButton, PlusIcon, PlusStroke = MakeStepButton("plus", 3)

        function Stepper:GetText(): string
            local Text = Stepper.ValueTexts and Stepper.ValueTexts[Stepper.Value]
            if Text ~= nil then
                return tostring(Text)
            end

            if typeof(Stepper.Format) == "function" then
                local Ok, Result = pcall(Stepper.Format, Stepper.Value)
                if Ok then
                    return tostring(Result)
                end
            end

            local Factor = 10 ^ Stepper.Rounding
            local Number = math.round(Stepper.Value * Factor) / Factor
            return Stepper.Prefix .. tostring(Number) .. Stepper.Suffix
        end

        function Stepper:Display()
            if Library.Unloaded then
                return
            end

            if not ValueLabel:IsFocused() then
                ValueLabel.Text = Stepper:GetText()
            end
            ValueLabel.TextTransparency = Stepper.Disabled and 0.8 or 0
            ValueLabel.TextEditable = not Stepper.Disabled
            Label.TextTransparency = Stepper.Disabled and 0.8 or 0

            local CanDecrease = not Stepper.Disabled and Stepper.Value > Stepper.Min
            local CanIncrease = not Stepper.Disabled and Stepper.Value < Stepper.Max
            MinusButton.Active = CanDecrease
            PlusButton.Active = CanIncrease
            MinusIcon.ImageTransparency = CanDecrease and 0.4 or 0.8
            PlusIcon.ImageTransparency = CanIncrease and 0.4 or 0.8
            MinusStroke.Transparency = CanDecrease and 0 or 0.5
            PlusStroke.Transparency = CanIncrease and 0 or 0.5
        end

        function Stepper:UpdateColors()
            Stepper:Display()
        end

        function Stepper:OnChanged(Func)
            Stepper.Changed = Func
        end

        function Stepper:RunChanged()
            if Stepper.Disabled then
                return
            end

            Library:SafeCallback(Stepper.Callback, Stepper.Value)
            Library:SafeCallback(Stepper.Changed, Stepper.Value)
        end

        function Stepper:SetValue(Value: number)
            if Stepper.Disabled or typeof(Value) ~= "number" then
                return
            end

            Value = Normalize(Value)
            if Value == Stepper.Value then
                return
            end

            Stepper.Value = Value
            Stepper:Display()

            Library:UpdateConditionalGroups()
            Library:SafeCallback(Stepper.Callback, Stepper.Value)
            Library:SafeCallback(Stepper.Changed, Stepper.Value)
        end

        function Stepper:Increase(Amount: number?)
            Stepper:SetValue(Stepper.Value + (Amount or Stepper.Increment))
        end

        function Stepper:Decrease(Amount: number?)
            Stepper:SetValue(Stepper.Value - (Amount or Stepper.Increment))
        end

        function Stepper:Reset()
            Stepper:SetValue(Stepper.Default)
        end

        function Stepper:SetMin(Min: number)
            Stepper.Min = Min
            Stepper.Max = math.max(Stepper.Max, Min)
            Stepper.Value = Normalize(Stepper.Value)
            Stepper:Display()
        end

        function Stepper:SetMax(Max: number)
            Stepper.Max = Max
            Stepper.Min = math.min(Stepper.Min, Max)
            Stepper.Value = Normalize(Stepper.Value)
            Stepper:Display()
        end

        function Stepper:SetIncrement(Increment: number)
            assert(typeof(Increment) == "number" and Increment > 0, "Increment must be a positive number")
            Stepper.Increment = Increment
        end

        function Stepper:SetValueTexts(ValueTexts: { [number]: string }?)
            Stepper.ValueTexts = ValueTexts
            Stepper:Display()
        end

        function Stepper:SetText(Text: string)
            Stepper.Text = Text
            Label.Text = Text
        end

        function Stepper:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
            end
        end

        Stepper.RowHolder = Holder

        function Stepper:SetDisabled(Disabled: boolean)
            Stepper.Disabled = Disabled

            if Stepper.TooltipTable then
                Stepper.TooltipTable.Disabled = Disabled
            end

            Stepper:Display()
        end

        function Stepper:SetVisible(Visible: boolean)
            Stepper.Visible = Visible
            Holder.Visible = Visible
            Section:Resize()
        end

        --// Click steps once. Holding keeps stepping: slowly at first, then faster. \\--
        local function BindStep(Button: TextButton, Direction: number)
            local Token = 0

            Button.MouseButton1Down:Connect(function()
                if Stepper.Disabled or not Button.Active then
                    return
                end

                Token += 1
                local Mine = Token
                Stepper:SetValue(Stepper.Value + Direction * Stepper.Increment)

                if not Stepper.Holdable then
                    return
                end

                task.spawn(function()
                    local Started = os.clock()
                    task.wait(0.4)

                    while Token == Mine and not Library.Unloaded and Button.Active do
                        local Held = os.clock() - Started
                        local Multiplier = Held > 2 and 5 or (Held > 1 and 2 or 1)
                        Stepper:SetValue(Stepper.Value + Direction * Stepper.Increment * Multiplier)
                        task.wait(0.07)
                    end
                end)
            end)

            local function Stop()
                Token += 1
            end
            Button.MouseButton1Up:Connect(Stop)
            Button.MouseLeave:Connect(Stop)
        end
        BindStep(MinusButton, -1)
        BindStep(PlusButton, 1)

        if typeof(Stepper.Tooltip) == "string" or typeof(Stepper.DisabledTooltip) == "string" then
            Stepper.TooltipTable = Library:AddTooltip(Stepper.Tooltip, Stepper.DisabledTooltip, Holder)
            Stepper.TooltipTable.Disabled = Stepper.Disabled
        end

        Stepper:Display()
        Section:Resize()

        Stepper.Holder = Holder
        Stepper.Section = Section
        Stepper.Container = Container
        Stepper.TextLabel = Label
        Stepper.Controls = Controls
        Stepper.LabelBlock = LabelBlock
        Stepper.ControlsWidth = ControlsWidth
        Stepper.AddSettings = Funcs.AddSettings

        --// Shrinks the label area so the settings gear has room without overlapping the controls. \\--
        function Stepper:ReserveRight(Amount: number)
            Stepper.ReservedRight = (Stepper.ReservedRight or 0) + Amount

            local Size = LabelBlock.Size
            LabelBlock.Size = UDim2.new(Size.X.Scale, Size.X.Offset - Amount, Size.Y.Scale, Size.Y.Offset)
            Controls.Position = UDim2.new(1, -Stepper.ReservedRight, 0.5, 0)
        end

        table.insert(Section.Elements, Stepper)

        Stepper.Default = Stepper.Value

        if Idx then
            Options[Idx] = Stepper
        end

        return Stepper
    end

    --// Read-only table for showing data: columns, rows, optional header, zebra rows, selection and sorting.
    --// Column widths are measured: pixel columns keep their size, Auto columns fit their content and Fill
    --// columns share what is left. \\--
    function Funcs:AddTable(Idx, Info)
        Info = Library:Validate(Info, Templates.Table)

        local Section = self
        local Container = Section.Container

        local Table = {
            Text = Info.Text,
            Columns = {},
            Rows = {},

            Header = Info.Header,
            Striped = Info.Striped,
            RowHeight = Info.RowHeight,
            MaxHeight = Info.MaxHeight,
            Selectable = Info.Selectable,
            EmptyText = Info.EmptyText,
            Align = Info.Align,
            HeaderAlign = Info.HeaderAlign,
            Selected = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Visible = Info.Visible,

            Type = "Table",
        }

        local HasTitle = typeof(Info.Text) == "string" and Info.Text ~= ""
        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""

        local Holder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = Table.Visible,
            Parent = Container,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Holder,
        })

        local TitleLabel, SubtextLabel
        if HasTitle or HasSubtext then
            local Head = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = Holder,
            })
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Head,
            })
            if HasTitle then
                TitleLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, HasSubtext and 17 or 18),
                    Text = Info.Text,
                    TextSize = 14,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Head,
                })
            end
            if HasSubtext then
                SubtextLabel = Library:CreateSubtext(Head, Info.Subtext, { LayoutOrder = 1 })
            end
        end

        local Card = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "MainColor",
            ClipsDescendants = true,
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = Holder,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Card,
            })
        )
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Card,
        })
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Card,
        })

        local HeaderRow = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            ClipsDescendants = true,
            LayoutOrder = 0,
            Size = UDim2.new(1, 0, 0, 22),
            Visible = Table.Header,
            Parent = Card,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HeaderRow,
            })
        )
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = HeaderRow,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = HeaderRow,
        })

        local HeaderLine = Library:MakeLine(Card, {
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 1),
        })
        HeaderLine.Visible = Table.Header

        local Body = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            LayoutOrder = 2,
            ScrollBarImageColor3 = "AccentColor",
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = Card,
        })
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Body,
        })

        local EmptyLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Size = UDim2.new(1, 0, 0, 26),
            Text = Table.EmptyText,
            TextSize = 13,
            TextTransparency = 0.5,
            Visible = false,
            Parent = Card,
        })

        local HeaderCells = {}
        local RowFrames = {}
        local RowCells = {}
        local Widths = {}

        local AlignMap = {
            Left = Enum.TextXAlignment.Left,
            Center = Enum.TextXAlignment.Center,
            Right = Enum.TextXAlignment.Right,
        }

        local function NormalizeColumn(Column: any)
            if typeof(Column) == "string" then
                Column = { Name = Column }
            end

            local Align = Column.Align or Table.Align
            return {
                Name = Column.Name or "",
                Key = Column.Key,
                Width = Column.Width or "Fill",
                Weight = Column.Weight or 1,
                Align = Align,
                HeaderAlign = Column.HeaderAlign or Table.HeaderAlign or Align,
            }
        end

        local function CellValue(RowData: any, Column: any, Index: number)
            if typeof(RowData) ~= "table" then
                return RowData
            end

            if Column.Key ~= nil and RowData[Column.Key] ~= nil then
                return RowData[Column.Key]
            end

            return RowData[Index]
        end

        local function CellText(Value: any): string
            if typeof(Value) == "table" then
                return tostring(Value.Text or "")
            end

            return Value ~= nil and tostring(Value) or ""
        end

        local MeasureCache = {}
        local function Measure(Text: string, Size: number): number
            local Key = Size .. "|" .. Text
            if MeasureCache[Key] == nil then
                MeasureCache[Key] = math.ceil((Library:GetTextBounds(Text, Library.Scheme.Font, Size, 600)))
            end

            return MeasureCache[Key]
        end

        --// Works out every column's pixel width for the current table width. \\--
        local function ComputeWidths()
            local CardWidth = Card.AbsoluteSize.X > 0 and (Card.AbsoluteSize.X / Library.DPIScale)
                or (Section.Container and Section.Container.AbsoluteSize.X > 0 and (Section.Container.AbsoluteSize.X / Library.DPIScale) or 260)
            local Inner = math.max(CardWidth - 16, 40)
            local Used, Weights = 0, 0
            local Result = {}
            local FillIndices = {}

            for Index, Column in Table.Columns do
                if typeof(Column.Width) == "number" then
                    Result[Index] = Column.Width
                    Used += Column.Width
                elseif Column.Width == "Auto" then
                    local Best = Measure(Column.Name, 12)
                    for _, RowData in Table.Rows do
                        Best = math.max(Best, Measure(CellText(CellValue(RowData, Column, Index)), 13))
                    end
                    local Width = Best + 16
                    Result[Index] = Width
                    Used += Width
                else
                    table.insert(FillIndices, Index)
                    Weights += Column.Weight
                end
            end

            local Free = math.max(Inner - Used, 0)
            local Allocated = Used
            for i, Index in ipairs(FillIndices) do
                local Column = Table.Columns[Index]
                if i == #FillIndices then
                    local Remaining = math.max(Inner - Allocated, 20)
                    Result[Index] = Remaining
                    Allocated += Remaining
                else
                    local MinWidth = math.max(Measure(Column.Name, 12) + 16, 20)
                    local Share = math.floor(Free * Column.Weight / math.max(Weights, 1))
                    local Width = math.max(Share, MinWidth)
                    Result[Index] = Width
                    Allocated += Width
                end
            end

            if Allocated > Inner and #Table.Columns > 0 then
                local Overflow = Allocated - Inner
                for Index = #Table.Columns, 1, -1 do
                    if Result[Index] and Result[Index] > 30 then
                        local Sub = math.min(Result[Index] - 24, Overflow)
                        Result[Index] -= Sub
                        Overflow -= Sub
                        if Overflow <= 0 then break end
                    end
                end
            end

            return Result
        end

        local function ApplyWidths()
            Widths = ComputeWidths()

            for Index, Cell in HeaderCells do
                Cell.Size = UDim2.new(0, Widths[Index] or 0, 1, 0)
            end
            for _, Cells in RowCells do
                for Index, Cell in Cells do
                    Cell.Size = UDim2.new(0, Widths[Index] or 0, 1, 0)
                end
            end
        end

        local function MakeCell(Row: Frame, Column: any, Value: any, Index: number, IsHeader: boolean)
            local Text, Color, Icon = "", nil, nil
            if typeof(Value) == "table" then
                Text, Color, Icon = tostring(Value.Text or ""), Value.Color, Value.Icon
            elseif Value ~= nil then
                Text = tostring(Value)
            end

            local Cell = New("Frame", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = Index,
                Size = UDim2.new(0, Widths[Index] or 0, 1, 0),
                Parent = Row,
            })

            local Offset = 0
            if Icon and not IsHeader then
                local Tile = Library:CreateIconTile(Cell, Icon, { Size = 12, IconColor = Color })
                Tile.AnchorPoint = Vector2.new(0, 0.5)
                Tile.Position = UDim2.fromScale(0, 0.5)
                Offset = 18
            end

            local PadH = 4
            local Props = {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(Offset + PadH, 0),
                Size = UDim2.new(1, -(Offset + PadH * 2), 1, 0),
                Text = Text,
                TextSize = IsHeader and 12 or 13,
                TextTransparency = IsHeader and 0.4 or 0.15,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = AlignMap[IsHeader and Column.HeaderAlign or Column.Align] or Enum.TextXAlignment.Left,
                Parent = Cell,
            }
            if typeof(Color) == "Color3" then
                Props.TextColor3 = Color
            end
            New("TextLabel", Props)

            return Cell
        end

        local function Rebuild()
            if Library.Unloaded then
                return
            end

            for _, Cell in HeaderCells do
                Cell:Destroy()
            end
            for _, Frame in RowFrames do
                Frame:Destroy()
            end
            table.clear(HeaderCells)
            table.clear(RowFrames)
            table.clear(RowCells)

            Widths = ComputeWidths()

            HeaderRow.Visible = Table.Header
            HeaderLine.Visible = Table.Header

            for Index, Column in Table.Columns do
                HeaderCells[Index] = MakeCell(HeaderRow, Column, Column.Name, Index, true)
            end

            for RowIndex, RowData in Table.Rows do
                local Row = New("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = "BackgroundColor",
                    BackgroundTransparency = (Table.Striped and RowIndex % 2 == 0) and 0.55 or 1,
                    LayoutOrder = RowIndex,
                    Size = UDim2.new(1, 0, 0, Table.RowHeight),
                    Text = "",
                    Active = Table.Selectable,
                    Parent = Body,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Parent = Row,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    Parent = Row,
                })

                local Cells = {}
                for Index, Column in Table.Columns do
                    Cells[Index] = MakeCell(Row, Column, CellValue(RowData, Column, Index), Index, false)
                end
                RowCells[RowIndex] = Cells

                if Table.Selected == RowIndex then
                    Library.Registry[Row].BackgroundColor3 = "AccentColor"
                    Row.BackgroundColor3 = Library.Scheme.AccentColor
                    Row.BackgroundTransparency = 0.8
                end

                if Table.Selectable then
                    Row.MouseButton1Click:Connect(function()
                        Table:SetSelected(Table.Selected ~= RowIndex and RowIndex or nil)
                    end)
                end

                RowFrames[RowIndex] = Row
            end

            --// Explicit body height: rows * RowHeight, capped at MaxHeight (then it scrolls). \\--
            local Content = #Table.Rows * Table.RowHeight
            Body.CanvasSize = UDim2.fromOffset(0, Content)
            Body.Size = UDim2.new(1, 0, 0, Table.MaxHeight and math.min(Content, Table.MaxHeight) or Content)

            EmptyLabel.Visible = #Table.Rows == 0
            Body.Visible = #Table.Rows > 0
            Section:Resize()
        end

        Library:BindWidth(Card, function()
            ApplyWidths()
        end)

        for _, Column in Info.Columns do
            table.insert(Table.Columns, NormalizeColumn(Column))
        end
        for _, RowData in Info.Rows do
            table.insert(Table.Rows, RowData)
        end

        function Table:SetColumns(Columns)
            table.clear(Table.Columns)
            for _, Column in Columns do
                table.insert(Table.Columns, NormalizeColumn(Column))
            end
            Rebuild()
        end

        function Table:SetAlign(Align: string, HeaderAlign: string?)
            assert(AlignMap[Align], "Align must be Left, Center or Right")

            Table.Align = Align
            Table.HeaderAlign = HeaderAlign
            for _, Column in Table.Columns do
                Column.Align = Align
                Column.HeaderAlign = HeaderAlign or Align
            end
            Rebuild()
        end

        function Table:SetRows(Rows)
            table.clear(Table.Rows)
            for _, RowData in Rows do
                table.insert(Table.Rows, RowData)
            end
            Table.Selected = nil
            Rebuild()
        end

        function Table:AddRow(RowData, Position: number?)
            table.insert(Table.Rows, Position or (#Table.Rows + 1), RowData)
            Rebuild()
        end

        function Table:RemoveRow(Position: number)
            if Table.Rows[Position] == nil then
                return
            end

            table.remove(Table.Rows, Position)
            if Table.Selected == Position then
                Table.Selected = nil
            elseif Table.Selected and Table.Selected > Position then
                Table.Selected -= 1
            end
            Rebuild()
        end

        function Table:Clear()
            table.clear(Table.Rows)
            Table.Selected = nil
            Rebuild()
        end

        function Table:GetRows()
            return Table.Rows
        end

        function Table:UpdateCell(RowIndex: number, ColumnIndex: number, Value: any)
            local RowData = Table.Rows[RowIndex]
            if typeof(RowData) ~= "table" then
                return
            end

            local Column = Table.Columns[ColumnIndex]
            if Column and Column.Key ~= nil then
                RowData[Column.Key] = Value
            else
                RowData[ColumnIndex] = Value
            end
            Rebuild()
        end

        function Table:SetSelected(RowIndex: number?)
            if not Table.Selectable and RowIndex ~= nil then
                return
            end

            Table.Selected = RowIndex
            Rebuild()

            Library:SafeCallback(Table.Callback, RowIndex, RowIndex and Table.Rows[RowIndex] or nil)
            Library:SafeCallback(Table.Changed, RowIndex, RowIndex and Table.Rows[RowIndex] or nil)
        end

        function Table:GetSelected()
            return Table.Selected, Table.Selected and Table.Rows[Table.Selected] or nil
        end

        function Table:OnChanged(Func)
            Table.Changed = Func
        end

        --// Sorts by a column. Numbers compare as numbers, everything else as text. \\--
        function Table:Sort(ColumnIndex: number, Descending: boolean?)
            local Column = Table.Columns[ColumnIndex]
            if not Column then
                return
            end

            local function Key(RowData)
                local Value = CellValue(RowData, Column, ColumnIndex)
                if typeof(Value) == "table" then
                    Value = Value.Text
                end

                return tonumber(Value) or tostring(Value or ""):lower()
            end

            table.sort(Table.Rows, function(A, B)
                local KeyA, KeyB = Key(A), Key(B)
                if typeof(KeyA) ~= typeof(KeyB) then
                    KeyA, KeyB = tostring(KeyA), tostring(KeyB)
                end

                if Descending then
                    return KeyA > KeyB
                end
                return KeyA < KeyB
            end)

            Table.Selected = nil
            Rebuild()
        end

        function Table:SetMaxHeight(Height: number?)
            Table.MaxHeight = Height
            Rebuild()
        end

        function Table:SetText(Text: string)
            Table.Text = Text
            if TitleLabel then
                TitleLabel.Text = Text
            end
        end

        function Table:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
            end
        end

        function Table:SetVisible(Visible: boolean)
            Table.Visible = Visible
            Holder.Visible = Visible
            Section:Resize()
        end

        Rebuild()

        Table.Holder = Holder
        Table.Section = Section
        table.insert(Section.Elements, Table)

        if Idx then
            Options[Idx] = Table
        end

        return Table
    end

    --// Ordered list where each item can be moved up or down, e.g. for priorities. The order is
    --// returned as a list of item ids. \\--
    function Funcs:AddPriorityList(Idx, Info)
        Info = Library:Validate(Info, Templates.PriorityList)

        local Section = self
        local Container = Section.Container

        local PriorityList = {
            Text = Info.Text,
            Items = {},

            ShowIndex = Info.ShowIndex,
            ShowValue = Info.ShowValue,
            RowHeight = Info.RowHeight,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "PriorityList",
        }

        local HasTitle = typeof(Info.Text) == "string" and Info.Text ~= ""
        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""

        local Holder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = PriorityList.Visible,
            Parent = Container,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Holder,
        })

        local TitleLabel, SubtextLabel
        if HasTitle then
            TitleLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Text = Info.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end
        if HasSubtext then
            SubtextLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = function()
                    return Library:GetThinFont()
                end,
                LayoutOrder = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Text = Info.Subtext,
                TextSize = 12,
                TextTransparency = 0.5,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = Holder,
            })
        end

        local List = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = Holder,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = List,
        })

        local function NormalizeItem(Item: any)
            if typeof(Item) == "string" then
                return { Id = Item, Name = Item, Value = "", Disabled = false }
            end

            return {
                Id = Item.Id ~= nil and Item.Id or Item.Name,
                Name = Item.Name or tostring(Item.Id),
                Value = Item.Value or "",
                Icon = Item.Icon,
                Disabled = Item.Disabled == true,
            }
        end

        local RowFrames = {}

        local function Fire(Moved: any?, From: number?, To: number?)
            local Order = PriorityList:GetOrder()
            Library:UpdateConditionalGroups()
            Library:SafeCallback(PriorityList.Callback, Order, Moved, From, To)
            Library:SafeCallback(PriorityList.Changed, Order, Moved, From, To)
        end

        local function Render()
            if Library.Unloaded then
                return
            end

            for _, Frame in RowFrames do
                Frame:Destroy()
            end
            table.clear(RowFrames)

            for Index, Item in PriorityList.Items do
                local Row = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    LayoutOrder = Index,
                    Size = UDim2.new(1, 0, 0, PriorityList.RowHeight),
                    Parent = List,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = Row,
                    })
                )
                New("UIStroke", {
                    Color = "OutlineColor",
                    Transparency = 0.3,
                    Parent = Row,
                })

                local TextOffset = 8
                if PriorityList.ShowIndex then
                    local Badge = New("Frame", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = "BackgroundColor",
                        Position = UDim2.new(0, 6, 0.5, 0),
                        Size = UDim2.fromOffset(24, 24),
                        Parent = Row,
                    })
                    table.insert(
                        Library.Corners,
                        New("UICorner", {
                            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                            Parent = Badge,
                        })
                    )
                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Text = tostring(Index),
                        TextColor3 = "AccentColor",
                        TextSize = 13,
                        Parent = Badge,
                    })
                    TextOffset = 38
                end

                if Item.Icon then
                    local Tile = Library:CreateIconTile(Row, Item.Icon, { Size = 16 })
                    Tile.AnchorPoint = Vector2.new(0, 0.5)
                    Tile.Position = UDim2.new(0, TextOffset, 0.5, 0)
                    TextOffset += 24
                end

                --// Up / down segmented group on the right. \\--
                local Group = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.new(1, -6, 0.5, 0),
                    Size = UDim2.fromOffset(44, 20),
                    Parent = Row,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = Group,
                    })
                )
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = Group,
                })
                Library:MakeLine(Group, {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(1, 10),
                })

                local function MakeMove(IconName: string, Side: number, Direction: number)
                    local CanMove = not PriorityList.Disabled
                        and not Item.Disabled
                        and PriorityList.Items[Index + Direction] ~= nil
                        and not PriorityList.Items[Index + Direction].Disabled

                    local Button = New("TextButton", {
                        Active = CanMove,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(Side * 0.5, 0),
                        Size = UDim2.fromScale(0.5, 1),
                        Text = "",
                        Parent = Group,
                    })
                    local Icon = New("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        ImageColor3 = "FontColor",
                        ImageTransparency = CanMove and 0.35 or 0.8,
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(11, 11),
                        Parent = Button,
                    })
                    Library:ApplyIcon(Icon, IconName)

                    if CanMove then
                        Button.MouseEnter:Connect(function()
                            TweenService:Create(Icon, Library.TweenInfo, { ImageTransparency = 0 }):Play()
                        end)
                        Button.MouseLeave:Connect(function()
                            TweenService:Create(Icon, Library.TweenInfo, { ImageTransparency = 0.35 }):Play()
                        end)
                        Button.MouseButton1Click:Connect(function()
                            PriorityList:Move(Index, Index + Direction)
                        end)
                    end
                end
                MakeMove("chevron-up", 0, -1)
                MakeMove("chevron-down", 1, 1)

                local RightReserve = 58
                if PriorityList.ShowValue and Item.Value ~= "" then
                    local ValueLabel = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -RightReserve, 0.5, 0),
                        Size = UDim2.fromOffset(70, 16),
                        Text = tostring(Item.Value),
                        TextSize = 13,
                        TextTransparency = 0.5,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Parent = Row,
                    })
                    RightReserve += 78
                    ValueLabel.TextTransparency = Item.Disabled and 0.8 or 0.5
                end

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(TextOffset, 0),
                    Size = UDim2.new(1, -(TextOffset + RightReserve + 4), 1, 0),
                    Text = Item.Name,
                    TextSize = 14,
                    TextTransparency = (Item.Disabled or PriorityList.Disabled) and 0.7 or 0.1,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                RowFrames[Index] = Row
            end

            Section:Resize()
        end

        function PriorityList:GetOrder()
            local Order = {}
            for _, Item in PriorityList.Items do
                table.insert(Order, Item.Id)
            end

            return Order
        end

        function PriorityList:GetIndex(Id: any): number?
            for Index, Item in PriorityList.Items do
                if Item.Id == Id then
                    return Index
                end
            end

            return nil
        end

        --// Move the item at From to position To (indexes or ids). \\--
        function PriorityList:Move(From: any, To: number)
            local FromIndex = typeof(From) == "number" and From or PriorityList:GetIndex(From)
            if not FromIndex or not PriorityList.Items[FromIndex] or not PriorityList.Items[To] or FromIndex == To then
                return
            end
            if PriorityList.Disabled then
                return
            end

            local Item = table.remove(PriorityList.Items, FromIndex)
            table.insert(PriorityList.Items, To, Item)

            Render()
            Fire(Item.Id, FromIndex, To)
        end

        function PriorityList:MoveUp(IdOrIndex: any)
            local Index = typeof(IdOrIndex) == "number" and IdOrIndex or PriorityList:GetIndex(IdOrIndex)
            if Index then
                PriorityList:Move(Index, Index - 1)
            end
        end

        function PriorityList:MoveDown(IdOrIndex: any)
            local Index = typeof(IdOrIndex) == "number" and IdOrIndex or PriorityList:GetIndex(IdOrIndex)
            if Index then
                PriorityList:Move(Index, Index + 1)
            end
        end

        function PriorityList:SetItems(Items)
            table.clear(PriorityList.Items)
            for _, Item in Items do
                table.insert(PriorityList.Items, NormalizeItem(Item))
            end

            Render()
        end

        --// Reorders the list to match a list of ids; ids not mentioned keep their relative order at the end. \\--
        function PriorityList:SetOrder(Order)
            local Sorted, Used = {}, {}
            for _, Id in Order do
                local Index = PriorityList:GetIndex(Id)
                if Index and not Used[Id] then
                    Used[Id] = true
                    table.insert(Sorted, PriorityList.Items[Index])
                end
            end
            for _, Item in PriorityList.Items do
                if not Used[Item.Id] then
                    table.insert(Sorted, Item)
                end
            end

            PriorityList.Items = Sorted
            Render()
            Fire()
        end

        function PriorityList:SetValue(Id: any, Value: any)
            local Index = PriorityList:GetIndex(Id)
            if Index then
                PriorityList.Items[Index].Value = tostring(Value)
                Render()
            end
        end

        function PriorityList:SetItemDisabled(Id: any, Disabled: boolean)
            local Index = PriorityList:GetIndex(Id)
            if Index then
                PriorityList.Items[Index].Disabled = Disabled
                Render()
            end
        end

        function PriorityList:SetDisabled(Disabled: boolean)
            PriorityList.Disabled = Disabled
            Render()
        end

        function PriorityList:OnChanged(Func)
            PriorityList.Changed = Func
        end

        function PriorityList:RunChanged()
            Fire()
        end

        function PriorityList:SetText(Text: string)
            PriorityList.Text = Text
            if TitleLabel then
                TitleLabel.Text = Text
            end
        end

        function PriorityList:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
            end
        end

        function PriorityList:SetVisible(Visible: boolean)
            PriorityList.Visible = Visible
            Holder.Visible = Visible
            Section:Resize()
        end

        for _, Item in Info.Items do
            table.insert(PriorityList.Items, NormalizeItem(Item))
        end
        Render()

        PriorityList.Holder = Holder
        PriorityList.Section = Section
        table.insert(Section.Elements, PriorityList)

        if Idx then
            Options[Idx] = PriorityList
        end

        return PriorityList
    end

    function Funcs:AddProgressBar(Idx, Info)
        Info = Library:Validate(Info, Templates.ProgressBar)

        local Section = self
        local Container = Section.Container

        local ProgressBar = {
            Text = Info.Text,
            Value = Info.Value,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "ProgressBar",
        }

        local VerticalGap = 6
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or (14 + VerticalGap + 15)),
            Visible = ProgressBar.Visible,
            Parent = Container,
        })

        local ProgressBarLabel
        if not Info.Compact then
            ProgressBarLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = ProgressBar.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("Frame", {
            Active = false,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 15),
            Parent = Holder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = Bar.ZIndex + 1,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = GetTextStrokeColor,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0, 1),
            ZIndex = Bar.ZIndex,
            Parent = Bar,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Bar,
            })
        )

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Fill,
            })
        )

        function ProgressBar:UpdateColors()
            if Library.Unloaded then
                return
            end

            if ProgressBarLabel then
                ProgressBarLabel.TextTransparency = ProgressBar.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = ProgressBar.Disabled and 0.8 or 0

            Fill.BackgroundColor3 = ProgressBar.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = ProgressBar.Disabled and "OutlineColor" or "AccentColor"
        end

        function ProgressBar:Display()
            if Library.Unloaded then
                return
            end

            if Info.Compact then
                DisplayLabel.Text = string.format("%s: %s%s%s", ProgressBar.Text, ProgressBar.Prefix, ProgressBar.Value, ProgressBar.Suffix)
            elseif Info.HideMax then
                DisplayLabel.Text = string.format("%s%s%s", ProgressBar.Prefix, ProgressBar.Value, ProgressBar.Suffix)
            else
                DisplayLabel.Text = string.format(
                    "%s%s/%s%s",
                    ProgressBar.Prefix,
                    ProgressBar.Value,
                    ProgressBar.Max,
                    ProgressBar.Suffix
                )
            end

            local X = (ProgressBar.Value - ProgressBar.Min) / (ProgressBar.Max - ProgressBar.Min)
            Fill.Size = UDim2.fromScale(math.clamp(X, 0, 1), 1)
        end

        function ProgressBar:OnChanged(Func)
            ProgressBar.Changed = Func
        end

        function ProgressBar:SetMax(Value)
            assert(Value > ProgressBar.Min, "Max value cannot be less than the current min value.")

            ProgressBar:SetValue(math.clamp(ProgressBar.Value, ProgressBar.Min, Value))
            ProgressBar.Max = Value
            ProgressBar:Display()
        end

        function ProgressBar:SetMin(Value)
            assert(Value < ProgressBar.Max, "Min value cannot be greater than the current max value.")

            ProgressBar:SetValue(math.clamp(ProgressBar.Value, Value, ProgressBar.Max))
            ProgressBar.Min = Value
            ProgressBar:Display()
        end

        function ProgressBar:SetValue(Str)
            if ProgressBar.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == ProgressBar.Value then
                return
            end

            Num = math.clamp(Num, ProgressBar.Min, ProgressBar.Max)

            ProgressBar.Value = Num
            ProgressBar:Display()

            Library:SafeCallback(ProgressBar.Callback, ProgressBar.Value)
            Library:SafeCallback(ProgressBar.Changed, ProgressBar.Value)
        end

        function ProgressBar:SetDisabled(Disabled: boolean)
            ProgressBar.Disabled = Disabled
            ProgressBar:UpdateColors()
        end

        function ProgressBar:SetVisible(Visible: boolean)
            ProgressBar.Visible = Visible

            Holder.Visible = ProgressBar.Visible
            Section:Resize()
        end

        function ProgressBar:SetText(Text: string)
            ProgressBar.Text = Text
            if ProgressBarLabel then
                ProgressBarLabel.Text = Text
                return
            end
            ProgressBar:Display()
        end

        function ProgressBar:SetPrefix(Prefix: string)
            ProgressBar.Prefix = Prefix
            ProgressBar:Display()
        end

        function ProgressBar:SetSuffix(Suffix: string)
            ProgressBar.Suffix = Suffix
            ProgressBar:Display()
        end

        ProgressBar:UpdateColors()
        ProgressBar:Display()
        Section:Resize()

        ProgressBar.Holder = Holder
        table.insert(Section.Elements, ProgressBar)

        ProgressBar.Default = ProgressBar.Value

        Options[Idx] = ProgressBar

        return ProgressBar
    end

    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)

        local Section = self
        local Container = Section.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,

            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            ValueImages = Info.ValueImages,

            Multi = Info.Multi,
            DragSelect = Info.Multi and not Library.IsMobile and Info.DragSelect == true,
            KeepDisabledValuePosition = Info.KeepDisabledValuePosition == true,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,
            EnablePlayerImages = Info.EnablePlayerImages,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local IsInline = Info.Layout ~= "Stacked"
        local BoxOnLeft = IsInline and Info.BoxSide == "Left"
        local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""
        local LabelHeight = (not IsInline and Dropdown.Text) and 20 or 0

        local Holder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = Dropdown.Visible,
            Parent = Container,
        })
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Holder,
        })

        Dropdown.Holder = Holder
        Dropdown.Section = Section
        Dropdown.Container = Container
        Dropdown.AddSettings = Funcs.AddSettings

        --// Top row: the selection box plus (inline) the label. Everything is placed with explicit sizes
        --// rather than a flex layout, so the box is exactly BoxWidth and nothing gets stretched. The box
        --// sits on the bottom edge, so an opened list always starts right under it, even when subtext
        --// makes the label side taller. \\--
        local DropdownBoxHeight = 21
        local TopRow = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, DropdownBoxHeight),
            Parent = Holder,
        })
        Dropdown.TopRow = TopRow
        Dropdown.ReservedRight = 0

        --// Forward declarations: ReserveRight is defined before these are created, so without these
        --// it would read (nil) globals and silently do nothing. \\--
        local DisplayContainer
        local HasInlineLabel

        --// Frees space on the right edge of the row (used by the settings gear). The inline label
        --// block always shrinks; a right-anchored box shifts left, a left-anchored/stacked box shrinks. \\--
        function Dropdown:ReserveRight(Amount: number)
            Dropdown.ReservedRight = (Dropdown.ReservedRight or 0) + Amount
            if not DisplayContainer then
                return
            end

            if HasInlineLabel then
                if not BoxOnLeft then
                    DisplayContainer.Position = UDim2.new(1, -Dropdown.ReservedRight, 1, 0)
                end

                local LabelBlock = Dropdown.LabelBlock
                if LabelBlock then
                    local Size = LabelBlock.Size
                    LabelBlock.Size = UDim2.new(Size.X.Scale, Size.X.Offset - Amount, Size.Y.Scale, Size.Y.Offset)
                end
            else
                local Size = DisplayContainer.Size
                DisplayContainer.Size = UDim2.new(Size.X.Scale, Size.X.Offset - Amount, Size.Y.Scale, Size.Y.Offset)
            end
        end

        local Label
        local SubtextLabel
        HasInlineLabel = IsInline and Dropdown.Text ~= nil

        local BoxWidth = tonumber(Info.BoxWidth) or 0.5
        local BoxIsScale = BoxWidth <= 1
        local BoxSize = UDim2.new(1, 0, 0, DropdownBoxHeight)
        if HasInlineLabel then
            BoxSize = BoxIsScale and UDim2.new(BoxWidth, -4, 0, DropdownBoxHeight) or UDim2.fromOffset(BoxWidth, DropdownBoxHeight)

            local LabelSize = BoxIsScale and UDim2.new(1 - BoxWidth, -4, 0, 0) or UDim2.new(1, -(BoxWidth + 8), 0, 0)
            local LabelPosition
            if BoxOnLeft then
                LabelPosition = BoxIsScale and UDim2.new(BoxWidth, 4, 0, 0) or UDim2.fromOffset(BoxWidth + 8, 0)
            else
                LabelPosition = UDim2.fromOffset(0, 0)
            end

            local LabelBlock = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Position = LabelPosition,
                Size = LabelSize,
                Parent = TopRow,
            })
            Dropdown.LabelBlock = LabelBlock

            local IconOffset = 0
            if Info.Icon then
                local IconTile = Library:CreateIconTile(LabelBlock, Info.Icon, {
                    Size = 16,
                    IconColor = Info.IconColor,
                })
                IconTile.AnchorPoint = Vector2.new(0, 0.5)
                IconTile.Position = UDim2.new(0, 0, 0.5, 0)
                Dropdown.IconTile = IconTile
                IconOffset = 22
            end

            local TextStack = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(IconOffset, 0),
                Size = UDim2.new(1, -IconOffset, 0, 0),
                Parent = LabelBlock,
            })
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextStack,
            })

            Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, HasSubtext and 17 or 21),
                Text = Dropdown.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = BoxOnLeft and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
                Parent = TextStack,
            })

            if HasSubtext then
                SubtextLabel = Library:CreateSubtext(TextStack, Info.Subtext, { LayoutOrder = 1 })
                if SubtextLabel then
                    SubtextLabel.TextXAlignment = BoxOnLeft and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
                end
            end
        else
            Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, LabelHeight),
                Text = Dropdown.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not not Info.Text,
                Parent = Holder,
            })
        end

        function Dropdown:SetSubtext(Text: string)
            if SubtextLabel then
                SubtextLabel.Text = Text
            end
        end

        local MenuTable --// assigned further down; the search box handler needs it in scope
        DisplayContainer = New("TextButton", {
            AnchorPoint = Vector2.new(BoxOnLeft and 0 or (HasInlineLabel and 1 or 0), 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.new(BoxOnLeft and 0 or (HasInlineLabel and 1 or 0), BoxOnLeft and 0 or -(Dropdown.ReservedRight or 0), 1, 0),
            Size = BoxSize,
            Text = "",
            TextTransparency = 1,
            Parent = TopRow,
        })
        Dropdown.DisplayContainer = DisplayContainer

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = DisplayContainer,
        })

        local DisplayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = DisplayContainer,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = DisplayContainer,
            })
        )

        local DisplayImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-4, 3),
            Size = UDim2.fromOffset(16, 16),
            Image = "",
            ImageTransparency = 1,
            Parent = DisplayContainer,
        })

        local DisplayButton = New("TextButton", {
            Active = not Dropdown.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 21),
            Text = "---",
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = DisplayContainer,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(16, 16),
            --// Above the search box: opening the dropdown swaps in a TextBox
            --// that otherwise draws over the chevron on narrow widths. \\--
            ZIndex = (DisplayContainer.ZIndex or 1) + 10,
            Parent = DisplayContainer,
        })
        Library:RegisterIconInstance(ArrowImage, "chevron-up")

        local SearchBox
        local ActionRow
        local ActionHolder
        local CountLabel
        --// Forward declaration: the All/Clear buttons below reference the row
        --// pool, which is only filled further down. Without this they would
        --// resolve Pool as a nil global and error on click. \\--
        local Pool = {}

        --// Search and All/Clear live on their own inline row that appears at the top of the
        --// opened list. Opening the dropdown never focuses the search; click the field to type. \\--
        if Info.Searchable == true or Info.Multi == true then
            ActionHolder = New("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, DropdownBoxHeight),
                Visible = false,
                Parent = Holder,
            })
            ActionRow = New("Frame", {
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, DropdownBoxHeight),
                Parent = ActionHolder,
            })
            local ActionStroke = New("UIStroke", {
                Color = "OutlineColor",
                Parent = ActionRow,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = ActionRow,
                })
            )
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = ActionRow,
            })

            local ClusterReserve = Info.Multi and 108 or 0

            if Info.Searchable then
                local SearchIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    ImageColor3 = "FontColor",
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = ActionRow,
                })
                Library:RegisterIconInstance(SearchIcon, "search")

                SearchBox = New("TextBox", {
                    BackgroundTransparency = 1,
                    ClearTextOnFocus = false,
                    PlaceholderText = "Search...",
                    Position = UDim2.fromOffset(20, 0),
                    Size = UDim2.new(1, -(20 + ClusterReserve), 1, 0),
                    Text = "",
                    TextSize = 13,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ActionRow,
                })

                Library:AddFocusHighlight(SearchBox, ActionStroke, {
                    BackgroundTarget = ActionRow,
                    BackgroundShift = 6,
                })

                SearchBox.InputBegan:Connect(function(Input: InputObject)
                    if Input.KeyCode == Enum.KeyCode.Escape then
                        MenuTable:Close()
                    end
                end)
            else
                CountLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -ClusterReserve, 1, 0),
                    Text = "0 selected",
                    TextSize = 12,
                    TextTransparency = 0.45,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ActionRow,
                })
            end

            if Info.Multi then
                local Cluster = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(1, 0.5),
                    Size = UDim2.fromOffset(0, 20),
                    Parent = ActionRow,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Parent = Cluster,
                })

                local function MakeActionBtn(BtnText, Order, Callback)
                    local Btn = New("TextButton", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = "BackgroundColor",
                        BackgroundTransparency = 0,
                        LayoutOrder = Order,
                        Size = UDim2.fromOffset(42, 20),
                        Text = BtnText,
                        TextColor3 = "FontColor",
                        TextSize = 12,
                        TextTransparency = 0.35,
                        Parent = Cluster,
                    })
                    table.insert(
                        Library.Corners,
                        New("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                            Parent = Btn,
                        })
                    )
                    New("UIStroke", {
                        Color = "OutlineColor",
                        Parent = Btn,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                        Parent = Btn,
                    })
                    Btn.MouseEnter:Connect(function()
                        TweenService:Create(Btn, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end)
                    Btn.MouseLeave:Connect(function()
                        TweenService:Create(Btn, Library.TweenInfo, { TextTransparency = 0.35 }):Play()
                    end)
                    Btn.MouseButton1Click:Connect(Callback)
                    return Btn
                end

                MakeActionBtn("All", 1, function()
                    local IsDictionary = not IsSequentialArray(Dropdown.Values)
                    for Key, RawValue in Dropdown.Values do
                        local Value = IsDictionary and Key or RawValue
                        local IsDisabled = table.find(Dropdown.DisabledValues, Value) ~= nil
                            or (RawValue ~= nil and RawValue ~= Value and table.find(Dropdown.DisabledValues, RawValue) ~= nil)
                        if not IsDisabled then
                            Dropdown.Value[Value] = true
                        end
                    end
                    Dropdown:Display()
                    for _, Btn in Pool do Btn:UpdateButton() end
                    Library:UpdateConditionalGroups()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end)

                New("Frame", {
                    BackgroundColor3 = "OutlineColor",
                    LayoutOrder = 2,
                    Size = UDim2.fromOffset(1, 11),
                    Parent = Cluster,
                })

                MakeActionBtn("Clear", 3, function()
                    table.clear(Dropdown.Value)
                    Dropdown:Display()
                    for _, Btn in Pool do Btn:UpdateButton() end
                    Library:UpdateConditionalGroups()
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end)
            end
        end

        local GetValueImage = function(Value, RawValue)
            if not Value then
                return nil
            end

            local ValueImage = nil
            if Dropdown.SpecialType == "Player" and Dropdown.EnablePlayerImages == true then
                local PlayerValue = Value
                if typeof(PlayerValue) ~= "Instance" and RawValue ~= nil then
                    PlayerValue = RawValue
                end

                if typeof(PlayerValue) == "Instance" and PlayerValue:IsA("Player") then
                    ValueImage = { Url = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=48&h=48", tostring(PlayerValue.UserId)) }
                end
            end

            if Dropdown.ValueImages then
                local IconRef = Dropdown.ValueImages[Value]
                if IconRef == nil and RawValue ~= nil then
                    IconRef = Dropdown.ValueImages[RawValue]
                end

                if IconRef then
                    ValueImage = Library:GetCustomIcon(IconRef)
                end
            end

            return ValueImage
        end

        --// The list sits in a shell that draws its border and corners. The wrapper is one pixel shorter than
        --// the shell and the shell starts one pixel up, so its border lands on the border above it. \\--
        local ListWrap = New("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Holder,
        })
        local ListShell = New("Frame", {
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 1, 1),
            Parent = ListWrap,
        })
        New("UIStroke", { Color = "OutlineColor", Parent = ListShell })
        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = ListShell,
        }))

        local InlineList = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = 3,
            Size = UDim2.fromScale(1, 1),
            Parent = ListShell,
        })
        Library:AddToRegistry(InlineList, { ScrollBarImageColor3 = "OutlineColor" })
        Library:AddCustomScrollbar(InlineList)

        local function SetListHeight(Height: number)
            ListWrap.Size = UDim2.new(1, 0, 0, math.max(Height - 1, 0))
        end

        local DropdownOpen = false

        local EmptyLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -16, 0, 21),
            Text = "No results",
            TextSize = 13,
            TextTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = false,
            Parent = InlineList,
        })

        MenuTable = {
            Active = false,
            Menu = InlineList,
            List = nil,
        }
        Dropdown.Menu = MenuTable

        local function SetDropdownOpen(Active)
            DropdownOpen = Active
            MenuTable.Active = Active
            ListWrap.Visible = Active
            ArrowImage.Visible = true
            ArrowImage.ImageTransparency = Active and 0 or 0.5
            ArrowImage.Rotation = Active and 180 or 0
            if SearchBox and not Active then
                SearchBox.Text = ""
                if UserInputService:GetFocusedTextBox() == SearchBox then
                    SearchBox:ReleaseFocus()
                end
            end
            if ActionHolder then
                ActionHolder.Visible = Active
            end
            Dropdown:UpdateColors()
            Section:Resize()
        end

        function MenuTable:Open()  SetDropdownOpen(true)  end
        function MenuTable:Close() SetDropdownOpen(false) end
        function MenuTable:Toggle()
            SetDropdownOpen(not DropdownOpen)
        end
        function MenuTable:SetSize(SizeFunc)

            local S = typeof(SizeFunc) == "function" and SizeFunc() or SizeFunc
            SetListHeight(S.Y.Offset)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayButton.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayImage.ImageTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""
            local ValueImage = nil
            local IsDictionary = not IsSequentialArray(Dropdown.Values)

            if Info.Multi then
                for Key, RawValue in Dropdown.Values do
                    local Value = IsDictionary and Key or RawValue

                    if Dropdown.Value[Value] then
                        if not ValueImage then
                            ValueImage = GetValueImage(Value, RawValue)
                        end

                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(RawValue)) or tostring(RawValue))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                local DisplayValue = Dropdown.Value
                if IsDictionary and Dropdown.Value ~= nil then
                    DisplayValue = Dropdown.Values[Dropdown.Value]
                end

                ValueImage = GetValueImage(Dropdown.Value, DisplayValue)
                Str = DisplayValue and tostring(DisplayValue) or ""

                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            DisplayButton.Text = (Str == "" and "---" or Str)

            if CountLabel then
                local Count = 0
                for _ in Dropdown.Value do
                    Count += 1
                end
                CountLabel.Text = Count .. " selected"
            end

            if ValueImage then
                DisplayImage.Image = ValueImage.Url
                DisplayImage.ImageRectOffset = ValueImage.ImageRectOffset or Vector2.zero
                DisplayImage.ImageRectSize = ValueImage.ImageRectSize or Vector2.zero
                DisplayImage.ImageTransparency = 0
            else
                DisplayImage.Image = ""
                DisplayImage.ImageTransparency = 1
            end

            DisplayButton.Size = ValueImage and UDim2.new(1, -24, 0, 21) or UDim2.new(1, -16, 0, 21)
            DisplayButton.Position = ValueImage and UDim2.fromOffset(14, 0) or UDim2.fromOffset(0, 0)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        --// Forward-declared: RecalculateListSize is defined before the
        --// entries table is filled, and also runs arg-less from
        --// SetDPIScale (which fires on mobile scale init). Without this,
        --// #FilteredEntries below reads a nil global and errors. \\--
        local FilteredEntries = {}
        ItemHeight = 21

        function Dropdown:RecalculateListSize(Count)
            local ItemCount = Count or #FilteredEntries
            --// Defensive defaults: this also runs from SetDPIScale with no
            --// args, so never assume the template values are present. \\--
            local RowHeight = ItemHeight or 21
            local MaxVisible = tonumber(Info.MaxVisibleDropdownItems) or 8
            local Y = math.clamp(ItemCount * RowHeight, 0, MaxVisible * RowHeight)
            if ItemCount == 0 then
                Y = RowHeight
            end

            InlineList.CanvasSize = UDim2.fromOffset(0, ItemCount * RowHeight)
            SetListHeight(Y)
            Section:Resize()
        end

        function Dropdown:GetActiveValues(ReturnCount)
            local Table = {}

            if Info.Multi then
                for Value, _ in Dropdown.Value do
                    table.insert(Table, Value)
                end
            else
                if Dropdown.Value then
                    table.insert(Table, Dropdown.Value)
                end
            end

            return ReturnCount == true and GetTableSize(Table) or Table
        end

        local ItemHeight = 21
        local PoolSize = math.max(1, (tonumber(Info.MaxVisibleDropdownItems) or 8) + 2)
        --// FilteredEntries forward-declared above RecalculateListSize; do
        --// not redeclare here (a second local would shadow it). \\--

        local function RecomputeFilteredEntries()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local IsDictionary = not IsSequentialArray(Values)

            --// Fuzzy-match dropdown values the same way the sidebar search
            --// does, so e.g. "clr" can find "Clear Inventory" in a list \\--
            local SearchQuery = SearchBox and NormalizeSearch(LowerText(SearchBox.Text)) or ""
            local IsSearching = SearchQuery ~= ""

            local EnabledList, DisabledList = {}, {}
            local Pending = {}

            for Key, RawValue in Values do
                local Value = IsDictionary and Key or RawValue

                local FormattedValue = tostring(Info.FormatListValue and Info.FormatListValue(RawValue) or RawValue)

                local MatchScore = 0
                if IsSearching then
                    local Matched, Score = FuzzyScore(LowerText(FormattedValue), SearchQuery)
                    if not Matched then
                        continue
                    end
                    MatchScore = Score
                end

                local IsDisabled = table.find(DisabledValues, Value) ~= nil
                    or (RawValue ~= nil and RawValue ~= Value and table.find(DisabledValues, RawValue) ~= nil)

                table.insert(Pending, {
                    Value = Value,
                    RawValue = RawValue,
                    FormattedValue = FormattedValue,
                    IsDisabled = IsDisabled,
                    ValueImage = GetValueImage(Value, RawValue),
                    SortKey = Key,
                    MatchScore = MatchScore,
                    Order = #Pending + 1,
                })
            end

            if IsSearching then
                --// Best matches first; ties fall back to original order \\--
                table.sort(Pending, function(A, B)
                    if A.MatchScore ~= B.MatchScore then
                        return A.MatchScore > B.MatchScore
                    end
                    return A.Order < B.Order
                end)
            elseif not IsDictionary then
                table.sort(Pending, function(A, B)
                    return A.SortKey < B.SortKey
                end)
            end

            table.clear(FilteredEntries)

            if Dropdown.KeepDisabledValuePosition then
                for _, Entry in Pending do
                    table.insert(FilteredEntries, Entry)
                end
                return
            end

            for _, Entry in Pending do
                if Entry.IsDisabled then
                    table.insert(DisabledList, Entry)
                else
                    table.insert(EnabledList, Entry)
                end
            end

            for _, Entry in EnabledList do
                table.insert(FilteredEntries, Entry)
            end
            for _, Entry in DisabledList do
                table.insert(FilteredEntries, Entry)
            end
        end

        local function GetFirstVisibleIndex()
            local Total = #FilteredEntries
            if Total <= PoolSize then
                return 1
            end

            local MaxFirst = Total - PoolSize + 1
            local DpiScale = tonumber(Library.DPIScale) or 1
            if DpiScale == 0 then DpiScale = 1 end
            local ScrollY = InlineList.CanvasPosition.Y / DpiScale
            local Index = math.floor(ScrollY / ItemHeight) + 1
            return math.clamp(Index, 1, MaxFirst)
        end

        function Dropdown:RefreshPool()
            local Total = #FilteredEntries
            local First = GetFirstVisibleIndex()

            EmptyLabel.Visible = Total == 0

            for SlotIndex, Row in Pool do
                local DataIndex = First + SlotIndex - 1
                local Entry = FilteredEntries[DataIndex]

                Row.Entry = Entry
                Row.Index = Entry and DataIndex or nil
                Row.DataIndex = DataIndex

                if not Entry then
                    Row.Container.Visible = false
                    continue
                end

                Row.Container.Visible = true
                Row.Container.Position = UDim2.fromOffset(0, (DataIndex - 1) * ItemHeight)

                Row.Button.Text = Entry.FormattedValue

                if Entry.ValueImage then
                    Row.Image.Visible = true
                    Row.Image.Image = Entry.ValueImage.Url
                    Row.Image.ImageRectOffset = Entry.ValueImage.ImageRectOffset
                    Row.Image.ImageRectSize = Entry.ValueImage.ImageRectSize
                    Row.Button.Size = UDim2.new(1, -18, 0, ItemHeight)
                    Row.Button.Position = UDim2.fromOffset(18, 0)
                else
                    Row.Image.Visible = false
                    Row.Button.Size = UDim2.new(1, 0, 0, ItemHeight)
                    Row.Button.Position = UDim2.fromOffset(0, 0)
                end

                Row:UpdateButton()
            end
        end

        function Dropdown:RunChanged()
            if Dropdown.Disabled then
                return
            end

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end

        local DragSelecting = false
        local DragStartIndex = nil
        local DragPrevMin = nil
        local DragPrevMax = nil
        local DragLastIndex = nil
        local DragInitialValues = {}
        local DragInputEndedConn = nil
        local DragInputChangedConn = nil

        local function StopDragSelect()
            DragSelecting = false
            DragStartIndex = nil
            DragPrevMin = nil
            DragPrevMax = nil
            DragLastIndex = nil
            table.clear(DragInitialValues)

            if DragInputEndedConn then
                DragInputEndedConn:Disconnect()
                DragInputEndedConn = nil
            end

            if DragInputChangedConn then
                DragInputChangedConn:Disconnect()
                DragInputChangedConn = nil
            end
        end

        local DragActiveCount = 0

        local function ApplyDragIndex(Index, InRange)
            local Entry = FilteredEntries[Index]
            if not Entry or Entry.IsDisabled then
                return
            end

            local Try = DragInitialValues[Entry.Value]
            if InRange then
                Try = not Try
            end

            local WantActive = Try and true or false
            local IsActive = Dropdown.Value[Entry.Value] and true or false
            if WantActive == IsActive then
                return
            end

            if not WantActive and DragActiveCount == 1 and not Info.AllowNull then
                return
            end

            Dropdown.Value[Entry.Value] = WantActive and true or nil
            DragActiveCount += WantActive and 1 or -1
        end

        local function ApplyDragRange(From, To, InRange)
            for Index = From, To do
                ApplyDragIndex(Index, InRange)
            end
        end

        local function UpdateDrag(CurrentIndex)
            if CurrentIndex == nil or CurrentIndex == DragLastIndex then
                return
            end

            DragLastIndex = CurrentIndex

            local Min = math.min(DragStartIndex, CurrentIndex)
            local Max = math.max(DragStartIndex, CurrentIndex)
            DragActiveCount = Dropdown:GetActiveValues(true)

            if DragPrevMin == nil then
                ApplyDragRange(Min, Max, true)
            else
                if DragPrevMin < Min then
                    ApplyDragRange(DragPrevMin, Min - 1, false)
                end
                if DragPrevMax > Max then
                    ApplyDragRange(Max + 1, DragPrevMax, false)
                end
                if Min < DragPrevMin then
                    ApplyDragRange(Min, DragPrevMin - 1, true)
                end
                if Max > DragPrevMax then
                    ApplyDragRange(DragPrevMax + 1, Max, true)
                end
            end

            DragPrevMin = Min
            DragPrevMax = Max

            for _, OtherRow in Pool do
                OtherRow:UpdateButton()
            end
        end

        local function CreatePoolRow()
            local Row = {
                Entry = nil,
                Index = nil,
                DataIndex = 0,
            }

            local Container = New("Frame", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Visible = false,
                Parent = InlineList,
            })

            Library:AddToRegistry(Container, {
                BackgroundColor3 = Info.Multi and function()
                    local Base = Library.Scheme.AccentColor
                    local H, S, V = Base:ToHSV()
                    if Row.DataIndex % 2 == 1 then
                        return Color3.fromHSV(H, S, math.min(1, V + 0.12))
                    else
                        return Color3.fromHSV(H, S, math.max(0, V - 0.10))
                    end
                end or "AccentColor",
            })

            local Image = New("ImageLabel", {
                BackgroundTransparency = 1,
                ImageTransparency = 0.5,
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.fromOffset(4, 3),
                Visible = false,
                Parent = Container,
            })

            local Button = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Button,
            })

            Row.Container = Container
            Row.Image = Image
            Row.Button = Button

            function Row:UpdateButton()
                local Entry = Row.Entry
                if not Entry then
                    return
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Entry.Value]
                else
                    Selected = Dropdown.Value == Entry.Value
                end

                Row.Selected = Selected and true or false

                if Info.Multi and Selected then
                    local Base = Library.Scheme.AccentColor
                    local H, S, V = Base:ToHSV()
                    Container.BackgroundColor3 = Row.DataIndex % 2 == 1
                        and Color3.fromHSV(H, S, math.min(1, V + 0.12))
                        or Color3.fromHSV(H, S, math.max(0, V - 0.10))
                elseif not Info.Multi then
                    Container.BackgroundColor3 = Library.Scheme.AccentColor
                end
                Container.BackgroundTransparency = Entry.IsDisabled and 1 or Selected and 0.75 or 1
                Button.TextTransparency = Entry.IsDisabled and 0.8 or Selected and 0 or 0.4

                if Entry.ValueImage then
                    Image.ImageTransparency = Entry.IsDisabled and 0.8 or Selected and 0 or 0.4
                end
            end

            Button.MouseButton1Click:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled or DragSelecting then
                    return
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Entry.Value]
                else
                    Selected = Dropdown.Value == Entry.Value
                end

                local Try = not Selected
                if not (Dropdown:GetActiveValues(true) == 1 and not Try and not Info.AllowNull) then
                    Selected = Try
                    if Info.Multi then
                        Dropdown.Value[Entry.Value] = Selected and true or nil
                    else
                        Dropdown.Value = Selected and Entry.Value or nil
                    end

                    for _, OtherRow in Pool do
                        OtherRow:UpdateButton()
                    end
                end

                Row:UpdateButton()
                Dropdown:Display()

                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end)

            Button.MouseEnter:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if Row.Selected then
                    return
                end

                TweenService:Create(Container, Library.TweenInfo, {
                    BackgroundTransparency = 0.85,
                }):Play()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0.25,
                }):Play()

                if Entry.ValueImage then
                    TweenService:Create(Image, Library.TweenInfo, {
                        ImageTransparency = 0.25,
                    }):Play()
                end
            end)

            Button.MouseLeave:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if Row.Selected then
                    return
                end

                TweenService:Create(Container, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                }):Play()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0.5,
                }):Play()

                if Entry.ValueImage then
                    TweenService:Create(Image, Library.TweenInfo, {
                        ImageTransparency = 0.5,
                    }):Play()
                end
            end)

            Button.InputBegan:Connect(function(StartInput)
                if not (Info.Multi and Dropdown.DragSelect and not Library.IsMobile) then
                    return
                end

                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if not IsMouseInput(StartInput) then
                    return
                end

                DragSelecting = true
                DragStartIndex = Row.Index
                table.clear(DragInitialValues)

                for _, FilteredEntry in FilteredEntries do
                    DragInitialValues[FilteredEntry.Value] = Dropdown.Value[FilteredEntry.Value]
                end

                UpdateDrag(Row.Index)

                if DragInputEndedConn then DragInputEndedConn:Disconnect() end
                if DragInputChangedConn then DragInputChangedConn:Disconnect() end

                DragInputChangedConn = Library:GiveSignal(UserInputService.InputChanged:Connect(function(ChangeInput)
                    if ChangeInput.UserInputType ~= Enum.UserInputType.MouseMovement and ChangeInput ~= StartInput then
                        return
                    end

                    local Pos = ChangeInput.Position
                    for _, OtherRow in Pool do
                        if OtherRow.Entry and Library:MouseIsOverFrame(OtherRow.Button, Pos) then
                            UpdateDrag(OtherRow.Index)
                            break
                        end
                    end
                end))

                DragInputEndedConn = Library:GiveSignal(UserInputService.InputEnded:Connect(function(EndInput)
                    if EndInput ~= StartInput and not (IsMouseInput(EndInput) and EndInput.UserInputType == StartInput.UserInputType) then
                        return
                    end

                    Dropdown:Display()
                    Library:UpdateConditionalGroups()
                    Dropdown:RunChanged()

                    StopDragSelect()
                end))
            end)

            return Row
        end

        function Dropdown:BuildDropdownList()
            StopDragSelect()

            RecomputeFilteredEntries()

            InlineList.CanvasPosition = Vector2.new(0, 0)

            Dropdown:RefreshPool()
            Dropdown:RecalculateListSize(#FilteredEntries)
        end

        for _ = 1, PoolSize do
            table.insert(Pool, CreatePoolRow())
        end

        Library:GiveSignal(InlineList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            Dropdown:RefreshPool()
        end))

        local function ValueExists(Val)
            if IsSequentialArray(Dropdown.Values) then
                for _, Existing in Dropdown.Values do
                    if Existing == Val then
                        return true
                    end
                end

                return false
            end

            return Dropdown.Values[Val] ~= nil
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                if typeof(Value) == "string" then
                    Value = if Value == "" then {} else { [Value] = true }
                end

                local Table = {}

                for Val, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and ValueExists(Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if ValueExists(Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:Display()
            for _, Button in Pool do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
            end

            Dropdown:RunChanged()
        end

        function Dropdown:SetSelectedValue(Value)
            if not ValueExists(Value) then
                return
            end

            if Info.Multi then
                Dropdown.Value[Value] = true
            else
                Dropdown.Value = Value
            end

            Dropdown:Display()
            for _, Button in Pool do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:DeselectValue(Value)
            if Info.Multi then
                Dropdown.Value[Value] = nil
            else
                if Dropdown.Value == Value then
                    if Info.AllowNull then
                        Dropdown.Value = nil
                    else
                        return
                    end
                end
            end

            Dropdown:Display()
            for _, Button in Pool do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:ClearSelectedValues()
            if Info.Multi then
                table.clear(Dropdown.Value)
            else
                if Info.AllowNull then
                    Dropdown.Value = nil
                else
                    return
                end
            end

            Dropdown:Display()
            for _, Button in Pool do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values

            local Changed = false
            if Info.Multi then
                for Val in Dropdown.Value do
                    if not ValueExists(Val) then
                        Dropdown.Value[Val] = nil
                        Changed = true
                    end
                end

            elseif Dropdown.Value ~= nil and not ValueExists(Dropdown.Value) then
                Dropdown.Value = nil
                Changed = true
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
            for _, Button in Pool do
                Button:UpdateButton()
            end

            if Changed and not Dropdown.Disabled then
                Library:UpdateConditionalGroups()
            end

            if Changed then
                Dropdown:RunChanged()
            end
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) ~= "table" and typeof(Values) ~= "string" then
                return
            end

            local IsDictionary = not IsSequentialArray(Dropdown.Values)
            if IsDictionary then
                if typeof(Values) == "string" then
                    Dropdown.Values[Values] = Values

                elseif IsSequentialArray(Values) then
                    for _, Val in Values do
                        Dropdown.Values[Val] = Val
                    end

                else
                    for Key, Val in Values do
                        Dropdown.Values[Key] = Val
                    end
                end
            else
                if typeof(Values) == "table" then
                    for _, Val in Values do
                        table.insert(Dropdown.Values, Val)
                    end
                else
                    table.insert(Dropdown.Values, Values)
                end
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in DisabledValues do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end

            Dropdown.ValueImages = ValueImages
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end

            for key, val in ValueImages do
                Dropdown.ValueImages[key] = val
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            DisplayButton.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Section:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Label.Size = UDim2.new(1, 0, 0, Text and 18 or 0)
            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        function Dropdown:SetDragSelect(Value: boolean)
            if not Info.Multi or Library.IsMobile then
                Value = false
            end

            Dropdown.DragSelect = Value == true
            Dropdown:BuildDropdownList()
        end

        local ToggleDropdown = function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end

        DisplayContainer.MouseButton1Click:Connect(ToggleDropdown)
        DisplayButton.MouseButton1Click:Connect(ToggleDropdown)

        if SearchBox then
            SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
        end

        local Defaults = (function()
            local Resolved = {}
            local Default = Info.Default
            if Default == nil then
                return Resolved
            end

            local IsDictionary = not IsSequentialArray(Dropdown.Values)
            local function ResolveOne(Candidate)
                if IsDictionary then
                    return Dropdown.Values[Candidate] ~= nil and Candidate or nil
                end

                for _, Existing in Dropdown.Values do
                    if Existing == Candidate then
                        return Existing
                    end
                end

                return nil
            end

            local DefaultType = typeof(Default)
            if DefaultType == "string" then
                local Value = ResolveOne(Default)
                if Value ~= nil then
                    table.insert(Resolved, Value)
                end

            elseif DefaultType == "table" then
                for _, Candidate in Default do
                    local Value = ResolveOne(Candidate)
                    if Value ~= nil then
                        table.insert(Resolved, Value)
                    end
                end

            elseif Dropdown.Values[Default] ~= nil then
                table.insert(Resolved, IsDictionary and Default or Dropdown.Values[Default])
            end

            return Resolved
        end)()

        for _, SelectValue in Defaults do
            if Info.Multi then
                Dropdown.Value[SelectValue] = true
            else
                Dropdown.Value = SelectValue
                break
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, DisplayContainer)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Section:Resize()

        Dropdown.Holder = Holder
        table.insert(Section.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Section = self
        local Container = Section.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local ViewportCamera = if not Info.Camera then Instance.new("Camera") else Info.Camera
        if not Info.Camera then
            ViewportCamera.Name = "ViewportCamera"
        end

        local Viewport = {
            Object = ViewportObject,
            Camera = ViewportCamera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 1.5
            local ModelPosition = Viewport.Object:GetPivot().Position

            ViewportCamera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, 0, CameraDistance), ModelPosition)
        end

        local function GetPivotPosition(): Vector3
            return Viewport.Object:GetPivot().Position
        end

        --// Yaw / Pitch are radians; the camera orbits the object's pivot. \\--
        local function OrbitCamera(Yaw: number, Pitch: number)
            local Position = GetPivotPosition()
            local Camera = ViewportCamera

            local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), Yaw)
            Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

            local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, Pitch)
            local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

            if PitchedCFrame.UpVector.Y > 0.1 then
                Camera.CFrame = PitchedCFrame
            end
        end

        local function ZoomCamera(Amount: number)
            ViewportCamera.CFrame += ViewportCamera.CFrame.LookVector * Amount
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = ViewportCamera,
            Active = Viewport.Interactive,
        })

        if not Info.Camera then
            ViewportCamera.Parent = ViewportFrame
        end

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Section.Tab.Sides do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Section.Tab.Sides do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = ViewportCamera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                ViewportCamera.CFrame += ViewportCamera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                ViewportCamera.CFrame += ViewportCamera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        pcall(function()
            Viewport.Object.Parent = ViewportFrame
        end)
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object and Viewport.Object ~= Object then
                pcall(function()
                    Viewport.Object:Destroy()
                end)
            end

            Viewport.Object = Object
            pcall(function()
                Viewport.Object.Parent = ViewportFrame
            end)

            Section:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            ViewportCamera = Camera
            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetCameraCFrame(NewCFrame: CFrame)
            assert(typeof(NewCFrame) == "CFrame", "CFrame must be a valid CFrame.")

            ViewportCamera.CFrame = NewCFrame
        end

        function Viewport:GetCameraCFrame(): CFrame
            return ViewportCamera.CFrame
        end

        --// Yaw / Pitch in degrees. \\--
        function Viewport:Rotate(Yaw: number, Pitch: number?)
            if not Viewport.Object then
                return
            end

            OrbitCamera(math.rad(Yaw or 0), math.rad(Pitch or 0))
        end

        function Viewport:Zoom(Amount: number)
            assert(typeof(Amount) == "number", "Amount must be a number.")

            ZoomCamera(Amount)
        end

        function Viewport:LookAt(Target: Vector3?)
            if not Target and not Viewport.Object then
                return
            end

            ViewportCamera.CFrame = CFrame.lookAt(ViewportCamera.CFrame.Position, Target or GetPivotPosition())
        end

        function Viewport:SetDistance(Distance: number)
            assert(typeof(Distance) == "number" and Distance > 0, "Distance must be greater than 0.")
            if not Viewport.Object then
                return
            end

            local Position = GetPivotPosition()
            local Offset = ViewportCamera.CFrame.Position - Position
            local Direction = Offset.Magnitude > 0 and Offset.Unit or -ViewportCamera.CFrame.LookVector

            ViewportCamera.CFrame = CFrame.lookAt(Position + Direction * Distance, Position)
        end

        function Viewport:GetDistance(): number
            if not Viewport.Object then
                return 0
            end

            return (ViewportCamera.CFrame.Position - GetPivotPosition()).Magnitude
        end

        function Viewport:SetFieldOfView(FieldOfView: number)
            assert(typeof(FieldOfView) == "number", "FieldOfView must be a number.")

            ViewportCamera.FieldOfView = math.clamp(FieldOfView, 1, 120)
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Section:Resize()
        end

        Section:Resize()

        Viewport.Holder = Holder
        table.insert(Section.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Section = self
        local Container = Section.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            ClipsDescendants = true,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Box,
            })
        )

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Section:Resize()
        end

        Section:Resize()

        Image.Holder = Holder
        table.insert(Section.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Section = self
        local Container = Section.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Section:Resize()
        end

        Section:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Section.Elements, Video)

        Options[Idx] = Video

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Section = self
        local Container = Section.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,

            Parent = Container,
        })

        pcall(function()
            local CurrentSize = Passthrough.Instance.Size
            if CurrentSize.X.Offset == 0 and CurrentSize.X.Scale == 0
                or CurrentSize.Y.Offset == 0 and CurrentSize.Y.Scale == 0 then
                Passthrough.Instance.Size = UDim2.new(1, 0, 1, 0)
                Passthrough.Instance.Position = UDim2.new(0, 0, 0, 0)
            end
        end)

        local PassthroughZIndex = Holder.ZIndex + 1
        Passthrough.Instance.ZIndex = PassthroughZIndex
        for _, Descendant in Passthrough.Instance:GetDescendants() do
            if Descendant:IsA("GuiObject") then
                Descendant.ZIndex = PassthroughZIndex
            end
        end

        pcall(function()
            Passthrough.Instance.Parent = Holder
        end)

        Section:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Section:Resize()
        end

        function Passthrough:SetInstance(NewInstance: Instance)
            assert(NewInstance, "Instance must be provided.")
            assert(
                typeof(NewInstance) == "Instance" and NewInstance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = NewInstance
            pcall(function()
                local CurrentSize = Passthrough.Instance.Size
                if CurrentSize.X.Offset == 0 and CurrentSize.X.Scale == 0
                    or CurrentSize.Y.Offset == 0 and CurrentSize.Y.Scale == 0 then
                    Passthrough.Instance.Size = UDim2.new(1, 0, 1, 0)
                    Passthrough.Instance.Position = UDim2.new(0, 0, 0, 0)
                end
            end)

            local PassthroughZIndex = Holder.ZIndex + 1
            Passthrough.Instance.ZIndex = PassthroughZIndex
            for _, Descendant in Passthrough.Instance:GetDescendants() do
                if Descendant:IsA("GuiObject") then
                    Descendant.ZIndex = PassthroughZIndex
                end
            end

            pcall(function()
                Passthrough.Instance.Parent = Holder
            end)
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Section:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Section.Elements, Passthrough)

        Options[Idx] = Passthrough

        return Passthrough
    end

    function Funcs:AddConditionalGroup()
        local Section = self
        local Container = Section.Container

        local ConditionalGroupContainer
        local ConditionalGroupList

        do
            ConditionalGroupContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            ConditionalGroupList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = ConditionalGroupContainer,
            })
        end

        local ConditionalGroup = {
            Visible = false,
            Dependencies = {},

            Holder = ConditionalGroupContainer,
            Container = ConditionalGroupContainer,

            Elements = {},
            ConditionalGroups = {},
            SubSections = {},
        }

        function ConditionalGroup:Resize()
            ConditionalGroupContainer.Size = UDim2.new(1, 0, 0, ConditionalGroupList.AbsoluteContentSize.Y / Library.DPIScale)
            Section:Resize()
        end

        function ConditionalGroup:Update(CancelSearch)
            for _, Dependency in ConditionalGroup.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    ConditionalGroupContainer.Visible = false
                    ConditionalGroup.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            ConditionalGroupContainer.Visible = false
                            ConditionalGroup.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            ConditionalGroupContainer.Visible = false
                            ConditionalGroup.Visible = false
                            return
                        end
                    end
                end
            end

            ConditionalGroup.Visible = true
            ConditionalGroupContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    ConditionalGroup:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        ConditionalGroupList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not ConditionalGroup.Visible then
                return
            end

            ConditionalGroup:Resize()
        end)

        function ConditionalGroup:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            ConditionalGroup.Dependencies = Dependencies
            ConditionalGroup:Update()
        end

        ConditionalGroupContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            ConditionalGroup:Resize()
        end)

        setmetatable(ConditionalGroup, BaseSection)

        table.insert(Section.ConditionalGroups, ConditionalGroup)
        table.insert(Library.ConditionalGroups, ConditionalGroup)

        return ConditionalGroup
    end

    function Funcs:AddConditionalSection()
        local Section = self
        local Tab = Section.Tab
        local BoxHolder = Section.BoxHolder

        local ConditionalSectionContainer
        local ConditionalSectionList

        do
            ConditionalSectionContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = ConditionalSectionContainer,
                })
            )
            Library:AddOutline(ConditionalSectionContainer)

            ConditionalSectionList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = ConditionalSectionContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                Parent = ConditionalSectionContainer,
            })
        end

        local ConditionalSection = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = ConditionalSectionContainer,
            Container = ConditionalSectionContainer,

            Tab = Tab,
            Elements = {},
            ConditionalGroups = {},
            SubSections = {},
        }

        function ConditionalSection:Resize()
            ConditionalSectionContainer.Size = UDim2.new(1, 0, 0, (ConditionalSectionList.AbsoluteContentSize.Y / Library.DPIScale) + 24)
        end

        function ConditionalSection:Update(CancelSearch)
            for _, Dependency in ConditionalSection.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    ConditionalSectionContainer.Visible = false
                    ConditionalSection.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            ConditionalSectionContainer.Visible = false
                            ConditionalSection.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            ConditionalSectionContainer.Visible = false
                            ConditionalSection.Visible = false
                            return
                        end
                    end
                end
            end

            ConditionalSection.Visible = true
            if not Library.Searching then
                ConditionalSectionContainer.Visible = true
                ConditionalSection:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function ConditionalSection:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            ConditionalSection.Dependencies = Dependencies
            ConditionalSection:Update()
        end

        setmetatable(ConditionalSection, BaseSection)

        table.insert(Tab.ConditionalSections, ConditionalSection)
        table.insert(Library.ConditionalGroups, ConditionalSection)

        return ConditionalSection
    end

    function Funcs:AddSubSection(NameOrInfo, IconName)
        local Section = self
        local Container = Section.Container

        local Info
        if typeof(NameOrInfo) == "table" then
            Info = NameOrInfo
        else
            Info = { Name = NameOrInfo, IconName = IconName }
        end

        if not Section.SubSectionLayout then
            Section.SubSectionLayout = {
                CurrentLayoutMode = nil,
                CurrentColumnsRow = nil,
                CurrentColumnLeft = nil,
                CurrentColumnRight = nil,
                NextOrder = 0,
            }
        end

        local SubSectionLayout = Section.SubSectionLayout

        local function GetSubSectionParent(Side)
            local RequestedMode = (Side == 1 or Side == 2) and "two-column" or nil

            local NeedNewRow = SubSectionLayout.CurrentLayoutMode ~= RequestedMode

            if NeedNewRow then
                SubSectionLayout.CurrentLayoutMode = RequestedMode

                if RequestedMode == "two-column" then

                    SubSectionLayout.CurrentColumnsRow = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        LayoutOrder = SubSectionLayout.NextOrder,
                        Size = UDim2.new(1, 0, 0, 0),
                        Parent = Container,
                    })

                    SubSectionLayout.CurrentColumnLeft = New("Frame", {
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.5, -3, 0, 0),
                        Parent = SubSectionLayout.CurrentColumnsRow,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = SubSectionLayout.CurrentColumnLeft,
                    })

                    SubSectionLayout.CurrentColumnRight = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.new(0.5, -3, 0, 0),
                        Parent = SubSectionLayout.CurrentColumnsRow,
                    })
                    New("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = SubSectionLayout.CurrentColumnRight,
                    })

                    SubSectionLayout.NextOrder = SubSectionLayout.NextOrder + 1
                else

                    SubSectionLayout.NextOrder = SubSectionLayout.NextOrder + 1
                end
            end

            if RequestedMode == "two-column" then
                return Side == 1 and SubSectionLayout.CurrentColumnLeft or SubSectionLayout.CurrentColumnRight
            else
                local Order = SubSectionLayout.NextOrder - 1
                return Container, Order
            end
        end

        local SubSectionParent, SubSectionOrder = GetSubSectionParent(Info.Side)

        local SubSectionHolder
        local SubSectionLabel
        local SubSectionContainer
        local SubSectionList
        local SubSectionSeparatorLine

        do
            SubSectionHolder = New("Frame", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 0.3,
                Size = UDim2.new(1, 0, 0, 0),
                LayoutOrder = SubSectionOrder or 0,
                Parent = SubSectionParent,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = SubSectionHolder,
                })
            )
            Library:AddOutline(SubSectionHolder)

            SubSectionSeparatorLine = Library:MakeLine(SubSectionHolder, {
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, 0, 0, 1),
            })

            local BoxIcon = Library:GetCustomIcon(Info.IconName)
            if BoxIcon then
                New("ImageLabel", {
                    Image = BoxIcon.Url,
                    ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = BoxIcon.ImageRectOffset,
                    ImageRectSize = BoxIcon.ImageRectSize,
                    Position = UDim2.fromOffset(11, 4),
                    Size = UDim2.fromOffset(18, 18),
                    Parent = SubSectionHolder,
                })
            end

            SubSectionHeaderBtn = New("TextButton", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 28),
                Text = "",
                Parent = SubSectionHolder,
            })

            SubSectionLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(BoxIcon and 23 or 3, 0),
                Size = UDim2.new(1, -(BoxIcon and 23 or 3) - 24, 0, 28),
                Text = Info.Name,
                TextSize = 13,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SubSectionHeaderBtn,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = SubSectionLabel,
            })

            local SubSectionFoldOpen = Info.DefaultOpen ~= false
            local SectionChevronDown = Library:GetIcon("chevron-down")
            local SectionChevronRight = Library:GetIcon("chevron-right")
            local SubSectionArrow = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(10, 10),
                ImageColor3 = "FontColor",
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Image = SubSectionFoldOpen
                    and (SectionChevronDown and SectionChevronDown.Url or "")
                    or (SectionChevronRight and SectionChevronRight.Url or ""),
                ImageRectOffset = SubSectionFoldOpen
                    and (SectionChevronDown and SectionChevronDown.ImageRectOffset or Vector2.zero)
                    or (SectionChevronRight and SectionChevronRight.ImageRectOffset or Vector2.zero),
                ImageRectSize = SubSectionFoldOpen
                    and (SectionChevronDown and SectionChevronDown.ImageRectSize or Vector2.zero)
                    or (SectionChevronRight and SectionChevronRight.ImageRectSize or Vector2.zero),
                Parent = SubSectionHeaderBtn,
            })
            Library:AddToRegistry(SubSectionArrow, { ImageColor3 = "FontColor" })

            SubSectionContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BackgroundTransparency = 0.5,
                Position = UDim2.fromOffset(0, 29),
                Size = UDim2.new(1, 0, 1, -29),
                Visible = SubSectionFoldOpen,
                Parent = SubSectionHolder,
            })
            SubSectionSeparatorLine.Visible = SubSectionFoldOpen

            SubSectionList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = SubSectionContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                Parent = SubSectionContainer,
            })
        end

        local SubSection = {
            Holder = SubSectionHolder,

            HeaderHolder = SubSectionHeaderBtn,
            Container = SubSectionContainer,

            Tab = Section.Tab,
            ConditionalGroups = {},
            SubSections = {},
            Elements = {},

            Name = Info.Name,
            ParentSection = Section,
            Folded = not (Info.DefaultOpen ~= false),
            Side = Info.Side,
        }

        function SubSection:Resize()
            if SubSection.Folded then
                SubSectionHolder.Size = UDim2.new(1, 0, 0, 28)
            else
                SubSectionHolder.Size = UDim2.new(1, 0, 0, (SubSectionList.AbsoluteContentSize.Y / Library.DPIScale) + 48)
            end
            Section:Resize()
        end

        do
            local SectionChevronDown = Library:GetIcon("chevron-down")
            local SectionChevronRight = Library:GetIcon("chevron-right")
            local function SetSectionArrowIcon(Arrow, Open)
                local Icon = Open and SectionChevronDown or SectionChevronRight
                if Icon then
                    Arrow.Image = Icon.Url
                    Arrow.ImageRectOffset = Icon.ImageRectOffset
                    Arrow.ImageRectSize = Icon.ImageRectSize
                end
            end

            local HeaderBtn = SubSectionHolder:FindFirstChildWhichIsA("TextButton")
            local Arrow = HeaderBtn and HeaderBtn:FindFirstChildWhichIsA("ImageLabel")

            function SubSection:SetFolded(Folded)
                if SubSection.Folded == Folded then return end
                SubSection.Folded = Folded
                SubSectionContainer.Visible = not SubSection.Folded
                SubSectionSeparatorLine.Visible = not SubSection.Folded
                if Arrow then
                    SetSectionArrowIcon(Arrow, not SubSection.Folded)
                end
                SubSection:Resize()
            end

            if HeaderBtn then
                HeaderBtn.MouseButton1Click:Connect(function()
                    SubSection:SetFolded(not SubSection.Folded)
                end)
            end
        end

        setmetatable(SubSection, BaseSection)

        SubSection:Resize()

        if not Section.SubSections then
            Section.SubSections = {}
        end
        table.insert(Section.SubSections, SubSection)

        return SubSection
    end

    BaseSection.__index = Funcs
    BaseSection.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()

    for _, Label in Labels do
        if typeof(Label) == "table" and Label.DoesWrap and Label.RefreshWrap then
            Label:RefreshWrap()
        end
    end

    if Library.Window and Library.Window.RefreshTitleSize then
        Library.Window:RefreshTitleSize()
    end
end

function Library:SetBackgroundImage(Image: string)
    assert(typeof(Image) == "string", "Expected string got " .. typeof(Image))

    Library.Scheme.BackgroundImage = Image
    if Library.Window and Library.Window.SetBackgroundImage then
        Library.Window:SetBackgroundImage(Image)
    end

    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

--// Re-anchors the notification stack to the current side and re-measures every notification. \\--
function Library:UpdateNotificationPositions()
    Library:SetNotifySide(Library.NotifySide or "Right")

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = Info.Title ~= nil and tostring(Info.Title) or nil
        Data.TitleColor = Info.TitleColor
        Data.Description = Info.Description ~= nil and tostring(Info.Description) or nil
        Data.DescriptionColor = Info.DescriptionColor
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist
        Data.Callback = typeof(Info.Callback) == "function" and Info.Callback or nil --// called with the close reason: "user", "timer" or "script"
        Data.Closable = Info.Closable == true
        Data.Icon = Info.Icon
        Data.BigIcon = Info.BigIcon
        Data.IconColor = Info.IconColor
        Data.Volume = tonumber(Info.Volume) or 3
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
        Data.Volume = select(4, ...) or 3
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            if DeleteConnection then
                pcall(function()
                    DeleteConnection:Disconnect()
                end)
                DeleteConnection = nil
            end
        end)
    end

    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,
    })

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),

        ZIndex = FakeBackground.ZIndex + 1,
        Parent = FakeBackground,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    Library:AddOutline(Holder)
    Library:AddStyleRoot(Holder)

    --// Content lives in its own frame so the optional close button can float in the corner. \\--
    local ContentHolder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = ContentHolder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = ContentHolder,
    })

    local CloseButton
    if Data.Closable then
        CloseButton = New("ImageButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Position = UDim2.new(1, -8, 0, 8),
            Size = UDim2.fromOffset(14, 14),
            ZIndex = Holder.ZIndex + 3,
            Parent = Holder,
        })
        Library:RegisterIconInstance(CloseButton, "x")

        CloseButton.MouseEnter:Connect(function()
            TweenService:Create(CloseButton, Library.TweenInfo, { ImageTransparency = 0 }):Play()
        end)
        CloseButton.MouseLeave:Connect(function()
            TweenService:Create(CloseButton, Library.TweenInfo, { ImageTransparency = 0.5 }):Play()
        end)
    end

    local ContentContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1, 0),
        Parent = ContentHolder,
    })

    if Data.BigIcon then
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = ContentContainer,
        })
    end

    local BigIconLabel
    if Data.BigIcon then
        local ParsedIcon = Library:GetCustomIcon(Data.BigIcon)
        if ParsedIcon then
            BigIconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24, 24),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "AccentColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = ContentContainer,
            })
        end
    end

    local TextContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
        Parent = ContentContainer,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TextContainer,
    })

    local TitleContainer
    if Data.Title then
        TitleContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Parent = TextContainer,
        })
    end

    local IconLabel
    if Data.Icon and TitleContainer then
        local ParsedIcon = Library:GetCustomIcon(Data.Icon)
        if ParsedIcon then
            IconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 1),
                Size = UDim2.fromOffset(15, 15),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or "FontColor",
                ImageRectOffset = ParsedIcon.ImageRectOffset,
                ImageRectSize = ParsedIcon.ImageRectSize,
                Parent = TitleContainer,
            })
        end
    end

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, (Data.Icon and 21 or 0), 0.5, 0),
            Size = UDim2.fromScale(0, 0),
            Text = Data.Title,
            TextColor3 = Data.TitleColor or "FontColor",
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Parent = TitleContainer,
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Text = Data.Description,
            TextColor3 = Data.DescriptionColor or "FontColor",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    function Data:Resize()
        local ExtraWidth = BigIconLabel and 32 or 0
        local IconWidth = IconLabel and 21 or 0

        if Title then
            local X, Y =
                Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth - IconWidth - (Data.Closable and 20 or 0))
            Title.Size = UDim2.fromOffset(X, Y)
            TitleX = X + IconWidth
            TitleContainer.Size = UDim2.fromOffset(TitleX, math.max(Y, IconLabel and 16 or 0))
        end

        if Desc then
            local X, Y =
                Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth)
            Desc.Size = UDim2.fromOffset(X, Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24 + ExtraWidth, 0)
    end

    function Data:ChangeTitle(Text)
        if Title then
            Data.Title = tostring(Text)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(Text)
        if Desc then
            Data.Description = tostring(Text)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy(Reason: string?)
        if Data.Destroyed then
            return
        end

        Data.Destroyed = true

        if Data.Callback then
            pcall(Data.Callback, Reason or "script")
        end

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end

        if DeleteConnection and DeleteConnection.Connected then
            pcall(function()
                DeleteConnection:Disconnect()
            end)
        end

        TweenService
            :Create(Holder, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
            })
            :Play()

        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = ContentHolder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = string.format("rbxassetid://%d", SoundId)
        end

        pcall(function()
            local Sound = New("Sound", {
                SoundId = SoundId,
                Volume = tonumber(Data.Volume) or 3,
                PlayOnRemove = true,
                Parent = SoundService,
            })
            Sound:Destroy()
        end)
    end

    Library.Notifications[FakeBackground] = Data

    FakeBackground.Visible = true
    TweenService:Create(Holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy("timer")
        end
    end)

    if CloseButton then
        CloseButton.MouseButton1Click:Connect(function()
            Data:Destroy("user")
        end)
    end

    return Data
end

--// Animations \\--
function Library:PlayTabAnimation(Tab, Showing: boolean, OnComplete: (() -> ())?)
    if type(Tab) ~= "table" or not Tab.Container then
        if OnComplete then
            OnComplete()
        end

        return
    end

    local TabContainer = Tab.Container :: Frame
    local Existing = ActiveTabTweens[TabContainer]
    if Existing then
        StopTween(Existing, true)
        ActiveTabTweens[TabContainer] = nil
    end

    local BaseZIndex = TabContainer.ZIndex
    if not (Library.Animations and Library.Animations.TabSwitch) then
        TabContainer.Visible = Showing
        TabContainer.Position = UDim2.fromScale(0, 0)
        TabContainer.ZIndex = BaseZIndex

        if OnComplete then
            OnComplete()
        end

        return
    end

    if Showing then
        local TransitionInfo = Library.TabTransitionInfo or TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local Offset = Library.TabSwipeOffset or 26
        local SwipeFrom = string.lower(Library.TabSwipeFrom or "bottom")
        local StartPosition
        local StartingPositions = {
            Left = UDim2.fromOffset(-Offset, 0),
            Right = UDim2.fromOffset(Offset, 0),
            Top = UDim2.fromOffset(0, -Offset),
            Bottom = UDim2.fromOffset(0, Offset),
        }

        if SwipeFrom == "auto" and Library.PreviousTab then
            local CurrentOrder = Tab.Button and Tab.Button.LayoutOrder
            local PreviousOrder = Library.PreviousTab.Button and Library.PreviousTab.Button.LayoutOrder
            if CurrentOrder and PreviousOrder then
                StartPosition = CurrentOrder > PreviousOrder and StartingPositions.Top or StartingPositions.Bottom
            else
                StartPosition = StartingPositions.Bottom
            end
        elseif SwipeFrom == "left" then
            StartPosition = StartingPositions.Left
        elseif SwipeFrom == "top" then
            StartPosition = StartingPositions.Top
        elseif SwipeFrom == "right" then
            StartPosition = StartingPositions.Right
        else -- bottom (Default)
            StartPosition = StartingPositions.Bottom
        end

        TabContainer.ZIndex = BaseZIndex + 1
        TabContainer.Position = StartPosition
        TabContainer.Visible = true

        local Tween = TweenService:Create(TabContainer, TransitionInfo, {
            Position = UDim2.fromScale(0, 0)
        })

        ActiveTabTweens[TabContainer] = Tween
        Tween:Play()

        local Connection; Connection = Tween.Completed:Connect(function(PlaybackState)
            if Connection then
                Connection:Disconnect()
            end

            if ActiveTabTweens[TabContainer] == Tween then
                ActiveTabTweens[TabContainer] = nil
            end

            if PlaybackState == Enum.PlaybackState.Cancelled then
                return
            end

            TabContainer.ZIndex = BaseZIndex
            if OnComplete then
                OnComplete()
            end
        end)
    else
        TabContainer.Visible = false
        TabContainer.Position = UDim2.fromScale(0, 0)
        TabContainer.ZIndex = BaseZIndex

        if OnComplete then
            OnComplete()
        end
    end
end

function Library:CreateWindow(WindowInfo)
    local ExplicitDPIScale = typeof(WindowInfo) == "table" and WindowInfo.DPIScale or nil
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)

    local ShouldWait = WindowInfo.WaitForIconsOnLoad
    if ShouldWait == nil then
        ShouldWait = Library.WaitForIconsOnLoad
    end
    if ShouldWait ~= false then
        Library:WaitForIcons(10)
    end

    if WindowInfo.SingleInstance ~= false then
        local GuiParent = gethui()
        local GuiName = "Astral_" .. tostring(WindowInfo.Title)
        for _, Child in GuiParent:GetChildren() do
            if Child:IsA("ScreenGui") and Child.Name == GuiName then

                local Unloaded = false
                if getgenv and typeof(getgenv) == "function" then
                    local env = getgenv()
                    for _, v in env do
                        if type(v) == "table" and typeof(v.Unload) == "function"
                            and not v.Unloaded and v.ScreenGui == Child then
                            pcall(v.Unload, v)
                            Unloaded = true
                            break
                        end
                    end
                end
                if not Unloaded then
                    pcall(function() Child:Destroy() end)
                end
                break
            end
        end
    end
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.OriginalMinSize =
        Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Vector2.new(math.min(WindowInfo.MinContainerWidth, MaxX), Library.OriginalMinSize.Y)

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )

    local BaseWindowSize = Vector2.new(WindowInfo.Size.X.Offset, WindowInfo.Size.Y.Offset)
    Library.BaseWindowSize = BaseWindowSize

    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end
    WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)

    if ScreenGui then
        ScreenGui.Name = "Astral_" .. tostring(WindowInfo.Title)
    end
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.TabButtonsStyle = WindowInfo.TabButtonsStyle
    Library.WindowTransparency = math.clamp(tonumber(WindowInfo.Transparency) or 0, 0, 0.85)
    Library.GradientsEnabled = WindowInfo.Gradient ~= false
    Library.GradientRotation = tonumber(WindowInfo.GradientRotation) or 45
    if typeof(WindowInfo.GradientColor) == "Color3" then
        Library.Scheme.GradientColor = WindowInfo.GradientColor
    end
    Library.ToggleKeybind = WindowInfo.ToggleKeybind

    Library.Animations = WindowInfo.Animations
    Library.TabTransitionInfo = TweenInfo.new(
        math.max(0, WindowInfo.TabTransitionTime or 0.22),
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    Library.TabSwipeOffset = math.max(1, WindowInfo.TabSwipeOffset or 26)
    Library.TabSwipeFrom = WindowInfo.TabSwipeFrom or "bottom"

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local DividerLine
    local TitleHolder
    local WindowTitle
    local WindowSubtitle
    local TitleTextHolder
    local WindowIcon
    local RightWrapper
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local Sidebar
    local BackgroundImage
    local BottomBackground
    local FooterLabel
    local FooterLeftSlot
    local FooterMiddleSlot
    local FooterRightSlot
    local DiscordBtn
    local DiscordBtnHeight
    local MainWindowScale

    local InitialLeftWidth = WindowInfo.SidebarWidth or math.ceil(WindowInfo.Size.X.Offset * 0.22)
    local IsCompact = WindowInfo.SidebarCompacted
    local CompactTooltips = WindowInfo.CompactSidebarTooltips ~= false
    local LastExpandedWidth = InitialLeftWidth

    --// Sizes the title + subtitle stack to fit the sidebar header. Called on
    --// creation, when either text/size changes and when the sidebar resizes. \\--
    local function LayoutTitleText(AreaWidth: number?)
        if not (WindowTitle and TitleTextHolder) then
            return
        end

        local IconWidth = (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6) or 0
        local MaxWidth = math.max((AreaWidth or InitialLeftWidth) - 24, 20) - IconWidth
        local TitleSize = WindowInfo.TitleSize or 20

        local TitleX = Library:GetTextBounds(WindowTitle.Text, Library.Scheme.Font, TitleSize, MaxWidth)
        WindowTitle.Size = UDim2.fromOffset(math.min(TitleX, MaxWidth), TitleSize + 2)

        local HolderX = math.min(TitleX, MaxWidth)
        local SubtitleX = 0
        if WindowSubtitle then
            local HasSubtitle = WindowSubtitle.Text ~= ""
            WindowSubtitle.Visible = HasSubtitle

            if HasSubtitle then
                local SubtitleSize = WindowInfo.SubtitleSize or 12
                SubtitleX = Library:GetTextBounds(WindowSubtitle.Text, Library.Scheme.Font, SubtitleSize, MaxWidth)
                SubtitleX = math.min(SubtitleX, MaxWidth)
                WindowSubtitle.Size = UDim2.fromOffset(SubtitleX, SubtitleSize + 2)
                HolderX = math.max(HolderX, SubtitleX)
            end
        end

        --// Both lines span the block, so their alignment decides where the text sits. \\--
        WindowTitle.Size = UDim2.fromOffset(HolderX, TitleSize + 2)
        if WindowSubtitle and WindowSubtitle.Text ~= "" then
            WindowSubtitle.Size = UDim2.fromOffset(HolderX, (WindowInfo.SubtitleSize or 12) + 2)
        end
        TitleTextHolder.Size = UDim2.new(0, HolderX, 1, 0)

        local XAlign = { Left = Enum.TextXAlignment.Left, Center = Enum.TextXAlignment.Center, Right = Enum.TextXAlignment.Right }
        local TitleAlign = WindowInfo.TitleAlignment or "Center"
        WindowTitle.TextXAlignment = XAlign[TitleAlign] or Enum.TextXAlignment.Center
        if WindowSubtitle then
            WindowSubtitle.TextXAlignment = XAlign[WindowInfo.SubtitleAlignment or TitleAlign] or Enum.TextXAlignment.Center
        end

        --// Place the whole block (icon + text) in the header. \\--
        local Width = AreaWidth or InitialLeftWidth
        if TitleAlign == "Left" then
            TitleHolder.AnchorPoint = Vector2.new(0, 0)
            TitleHolder.Position = UDim2.new(0, 12, 0, 0)
        elseif TitleAlign == "Right" then
            TitleHolder.AnchorPoint = Vector2.new(1, 0)
            TitleHolder.Position = UDim2.new(0, Width - 12, 0, 0)
        else
            TitleHolder.AnchorPoint = Vector2.new(0.5, 0)
            TitleHolder.Position = UDim2.new(0, Width / 2, 0, 0)
        end
    end

    do
        Library.KeybindFrame, Library.KeybindContainer, Library.KeybindMenu = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        local SettingsHolder, SettingsContainer = Library:AddDraggableMenu("Visible Keybinds")
        SettingsHolder.Visible = false

        local Menu = Library.KeybindMenu
        Menu.VisibilityControl = false
        Menu.SettingsOpen = false
        Menu.SettingsFrame = SettingsHolder
        Menu.SettingsContainer = SettingsContainer

        local SettingsGear = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "MainColor",
            Position = UDim2.new(1, -62, 0, 7),
            Size = UDim2.fromOffset(20, 20),
            Text = "",
            Visible = false,
            ZIndex = Library.KeybindFrame.ZIndex + 1,
            Parent = Library.KeybindFrame,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 5), Parent = SettingsGear }))
        Library:AddOutline(SettingsGear)
        local SettingsGearIcon = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 0.35,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(11, 11),
            Parent = SettingsGear,
        })
        do
            local GearIcon = Library:GetIcon("settings")
            if GearIcon then
                SettingsGearIcon.Image = GearIcon.Url
                SettingsGearIcon.ImageRectOffset = GearIcon.ImageRectOffset
                SettingsGearIcon.ImageRectSize = GearIcon.ImageRectSize
            end
        end
        Library:RegisterIconInstance(SettingsGearIcon, "settings")

        function Menu:RefreshSettings()
            for _, Child in SettingsContainer:GetChildren() do
                if Child:IsA("GuiObject") and not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
                    Child:Destroy()
                end
            end

            for Idx, Option in Options do
                if Option.Type ~= "KeyPicker" or Option.NoUI == true then
                    continue
                end

                local Holder = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Text = "",
                    Parent = SettingsContainer,
                })

                local Visible = Option.MenuVisible ~= false
                New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(22, 0),
                    Size = UDim2.fromScale(0, 1),
                    Text = ("[%s] %s (%s)"):format(
                        Option.DisplayValue or Option.Value or "None",
                        Option.Text or tostring(Idx),
                        Option.Mode or "Toggle"
                    ),
                    TextSize = 14,
                    TextTransparency = Visible and 0 or 0.5,
                    Parent = Holder,
                })

                local Checkbox = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = Holder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = Checkbox,
                    })
                )
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = Checkbox,
                })

                local CheckImage = New("ImageLabel", {
                    Image = CheckIcon and CheckIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = Visible and 0 or 1,
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Checkbox,
                })
                Library:RegisterIconInstance(CheckImage, "check")

                Holder.MouseButton1Click:Connect(function()
                    local Picker = Options[Idx]
                    if not (Picker and Picker.Type == "KeyPicker" and Picker.SetMenuVisibility) then
                        return
                    end

                    Picker:SetMenuVisibility(Picker.MenuVisible == false)
                end)
            end
        end

        function Menu:SetSettingsOpen(Open: boolean)
            Open = Open == true
            if Open and not Menu.VisibilityControl then
                return
            end

            Menu.SettingsOpen = Open
            SettingsHolder.Visible = Open

            if Open then
                Menu:RefreshSettings()

                local Offset = Library.KeybindFrame.AbsolutePosition + Library.KeybindFrame.AbsoluteSize + Vector2.new(8, 0)
                SettingsHolder.Position = UDim2.fromOffset(Offset.X, Offset.Y)
            end
        end

        function Menu:ToggleSettings()
            Menu:SetSettingsOpen(not Menu.SettingsOpen)
        end

        function Menu:SetVisibilityControl(Enabled: boolean)
            Enabled = Enabled == true
            Menu.VisibilityControl = Enabled
            SettingsGear.Visible = Enabled

            if not Enabled then
                Menu:SetSettingsOpen(false)
            end
        end

        SettingsGear.MouseButton1Click:Connect(function()
            Menu:ToggleSettings()
        end)

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,

            ZIndex = Library.BaseZIndex,
            Parent = ScreenGui,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = MainFrame,
            })
        )
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = MainFrame,
            })
        )
        MainWindowScale = MainFrame:FindFirstChildOfClass("UIScale")
        Library.MainFrame = MainFrame

        --// Gradient overlay: sits right above the window background and below all content. \\--
        Library.GradientOverlay = New("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Name = "GradientOverlay",
            Size = UDim2.fromScale(1, 1),
            Visible = Library.GradientsEnabled,
            Parent = MainFrame,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = Library.GradientOverlay,
            })
        )
        Library.GradientObject = New("UIGradient", {
            Parent = Library.GradientOverlay,
        })
        Library.StyleTargets[MainFrame] = "main"
        Library.StyleRoots[MainFrame] = true
        Library.MainWindowScale = MainWindowScale
        Library.CenterMainWindow = WindowInfo.Center and true or false

        do
            if ExplicitDPIScale ~= nil then
                --// An explicit DPIScale is only the starting multiplier; the
                --// window still has to fit the screen, so keep auto-fitting on
                --// until the user drags the scale slider (which clears it). \\--
                Library.AutoDPIScale = true
                Library.BaseScale = 1
                Library:SetDPIScale(ExplicitDPIScale)
            else
                Library.AutoDPIScale = true
                Library.BaseScale = Library:CalculateAutoBaseScale()
                Library:SetDPIScale(5)

                task.defer(function()
                    if Library.AutoDPIScale then
                        Library.BaseScale = Library:CalculateAutoBaseScale()
                        Library:SetDPIScale(Library.UIScaleValue or 5)
                    end
                end)
            end
        end

        if not Library.AutoDPIScaleConnection then
            local Camera = workspace.CurrentCamera
            local function OnViewportChanged()
                if not Library.AutoDPIScale then
                    return
                end
                Library.BaseScale = Library:CalculateAutoBaseScale()
                Library:SetDPIScale(Library.UIScaleValue or 5)
            end

            local function BindCamera(Cam: Camera?)
                if Library.AutoDPIScaleConnection then
                    Library.AutoDPIScaleConnection:Disconnect()
                    Library.AutoDPIScaleConnection = nil
                end
                if Cam then
                    local Connection = Cam:GetPropertyChangedSignal("ViewportSize"):Connect(OnViewportChanged)
                    Library.AutoDPIScaleConnection = Connection
                    Library:GiveSignal(Connection)
                end
            end

            BindCamera(Camera)
            Library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                BindCamera(workspace.CurrentCamera)
                OnViewportChanged()
            end))
        end
        Library:AddOutline(MainFrame)
        Library:MakeLine(MainFrame, {
            Position = UDim2.fromOffset(0, 48),
            Size = UDim2.new(1, 0, 0, 1),
        })

        DividerLine = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.fromOffset(InitialLeftWidth, 0),
            Size = UDim2.new(0, 1, 1, -20),
            ZIndex = MainFrame.ZIndex + 1,
            Parent = MainFrame,
        })

        BackgroundImage = New("ImageLabel", {
            Image = WindowInfo.BackgroundImage or "",
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            ScaleType = Enum.ScaleType.Stretch,

            ZIndex = MainFrame.ZIndex + 1,
            BackgroundTransparency = 1,
            ImageTransparency = 0.75,
            Visible = WindowInfo.BackgroundImage ~= nil and WindowInfo.BackgroundImage ~= "",
            Parent = MainFrame,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BackgroundImage,
            })
        )

        --// The top bar fill is made of pieces that never overlap, so a semi-transparent window shows one even
        --// colour: a clipped cap whose top corners are rounded, and a flat body underneath it. \\--
        local TopCap = New("Frame", {
            Name = "TopBackgroundCap",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(1, 0, 0, WindowInfo.CornerRadius),
            ZIndex = MainFrame.ZIndex,
            Parent = MainFrame,
        })
        local TopBackground = New("Frame", {
            Name = "TopBackground",
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(1, 0, 0, WindowInfo.CornerRadius * 2),
            ZIndex = MainFrame.ZIndex,
            Parent = TopCap,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = TopBackground,
            })
        )
        local TopFlatBottom = New("Frame", {
            Name = "TopFlatBottom",
            BackgroundColor3 = "BackgroundColor",
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, WindowInfo.CornerRadius),
            Size = UDim2.new(1, 0, 0, 48 - WindowInfo.CornerRadius),
            ZIndex = MainFrame.ZIndex,
            Parent = MainFrame,
        })
        Library.StyleTargets[TopBackground] = "panel"
        Library.StyleTargets[TopFlatBottom] = "panel"

        Library.LayoutTopBar = function(Radius: number)
            TopCap.Size = UDim2.new(1, 0, 0, Radius)
            TopBackground.Size = UDim2.new(1, 0, 0, Radius * 2)
            TopFlatBottom.Position = UDim2.fromOffset(0, Radius)
            TopFlatBottom.Size = UDim2.new(1, 0, 0, 48 - Radius)
        end

        local TopBar = New("Frame", {
            Name = "TopBar",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        local WindowSnapConfig = {
            Enabled = WindowInfo.Snapping,
            Distance = WindowInfo.SnapDistance,
            Margin = WindowInfo.SnapMargin,
            AvoidCoreGui = WindowInfo.SnapAvoidCoreGui,
        }
        Library:MakeDraggable(MainFrame, TopBar, false, true, WindowSnapConfig)

        TitleHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0, InitialLeftWidth / 2, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })

        if WindowInfo.Icon then
            local Icon = Library:GetCustomIcon(WindowInfo.Icon)
            if Icon then
                WindowIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    Size = WindowInfo.IconSize,
                    Parent = TitleHolder,
                })
                Library:AddToRegistry(WindowIcon, { ImageColor3 = "AccentColor" })
            else
                WindowIcon = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = WindowInfo.IconSize,
                    Text = WindowInfo.Title:sub(1, 1),
                    TextScaled = true,
                    Visible = false,
                    Parent = TitleHolder,
                })
            end
        else
            WindowIcon = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = WindowInfo.IconSize,
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Visible = false,
                Parent = TitleHolder,
            })
        end

        TitleTextHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            Parent = TitleHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),
            Parent = TitleTextHolder,
        })

        local TitleProps = {
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Text = WindowInfo.Title,
            TextSize = WindowInfo.TitleSize or 20,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = TitleTextHolder,
        }
        if typeof(WindowInfo.TitleColor) == "Color3" then
            TitleProps.TextColor3 = WindowInfo.TitleColor
        end
        WindowTitle = New("TextLabel", TitleProps)

        --// Subtitle: sits under the title, smaller and in a lighter font weight. \\--
        local SubtitleProps = {
            BackgroundTransparency = 1,
            FontFace = function()
                local Base = Library.Scheme.Font
                return Font.new(Base.Family, Enum.FontWeight.Light, Base.Style)
            end,
            LayoutOrder = 2,
            Text = WindowInfo.Subtitle or "",
            TextSize = WindowInfo.SubtitleSize or 12,
            TextTransparency = WindowInfo.SubtitleTransparency or 0.45,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Visible = false,
            Parent = TitleTextHolder,
        }
        if typeof(WindowInfo.SubtitleColor) == "Color3" then
            SubtitleProps.TextColor3 = WindowInfo.SubtitleColor
        end
        WindowSubtitle = New("TextLabel", SubtitleProps)

        LayoutTitleText(InitialLeftWidth)

        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -82, 0.5, 0),
            Size = UDim2.new(1, -InitialLeftWidth - 90 - 1, 1, -22),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 0),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 16),
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            Parent = CurrentTabInfo,
        })

        SearchBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            PlaceholderText = "Search",
            Size = UDim2.fromScale(0.5, 1),
            TextSize = 13,
            TextScaled = false,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = SearchBox,
            })
        )
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = SearchBox,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchBox,
        })

        Library:AddFocusHighlight(SearchBox)

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = SearchBox,
            })
        end

        do
            local ControlsHolder = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(60, 26),
                Parent = TopBar,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = ControlsHolder,
            })

            local MinimizeIcon = Library:GetIcon("minus")
            local CloseIcon = Library:GetIcon("x")

            local MinBtn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(26, 26),
                Text = "",
                Parent = ControlsHolder,
            })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinBtn }))
            Library:AddOutline(MinBtn)
            if MinimizeIcon then
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = MinimizeIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = MinimizeIcon.ImageRectOffset,
                    ImageRectSize = MinimizeIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = MinBtn,
                })
            end
            MinBtn.MouseEnter:Connect(function()
                TweenService:Create(MinBtn, Library.TweenInfo, { BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 12) }):Play()
            end)
            MinBtn.MouseLeave:Connect(function()
                TweenService:Create(MinBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
            end)
            MinBtn.MouseButton1Click:Connect(function()
                Library:Toggle(false)
            end)

            local CloseBtn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(26, 26),
                Text = "",
                Parent = ControlsHolder,
            })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn }))
            Library:AddOutline(CloseBtn)
            if CloseIcon then
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = CloseIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = CloseIcon.ImageRectOffset,
                    ImageRectSize = CloseIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = CloseBtn,
                })
            end
            CloseBtn.MouseEnter:Connect(function()
                TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
            end)
            CloseBtn.MouseLeave:Connect(function()
                TweenService:Create(CloseBtn, Library.TweenInfo, { BackgroundColor3 = Library.Scheme.MainColor }):Play()
            end)
            CloseBtn.MouseButton1Click:Connect(function()
                Library:Toggle(false)
                Library:Unload()
            end)
        end

        BottomBackground = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, math.max(20, WindowInfo.CornerRadius * 2)),
            Parent = MainFrame
        })
        Library:MakeLine(MainFrame, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -20),
            Size = UDim2.new(1, 0, 0, 1),
        })

        Library.StyleTargets[BottomBackground] = "panel"

        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Parent = MainFrame,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BottomBackground,
            })
        )

        --// Footer slots: Left / Middle / Right. The Footer text lives in the middle
        --// slot (as before); extra items can be added to any slot. \\--
        local RightFooterInset = (WindowInfo.Resizable and 20 or 0) + 8

        local function MakeFooterSlot(Anchor: number, Position: UDim2, Alignment: Enum.HorizontalAlignment)
            local Slot = New("Frame", {
                AnchorPoint = Vector2.new(Anchor, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Position = Position,
                Size = UDim2.new(0, 0, 1, 0),
                Parent = BottomBar,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Alignment,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = Slot,
            })
            return Slot
        end

        FooterLeftSlot = MakeFooterSlot(0, UDim2.new(0, 10, 0, 0), Enum.HorizontalAlignment.Left)
        FooterMiddleSlot = MakeFooterSlot(0.5, UDim2.new(0.5, 0, 0, 0), Enum.HorizontalAlignment.Center)
        FooterRightSlot = MakeFooterSlot(1, UDim2.new(1, -RightFooterInset, 0, 0), Enum.HorizontalAlignment.Right)

        FooterLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Size = UDim2.new(0, 0, 1, 0),
            Text = WindowInfo.Footer,
            TextSize = WindowInfo.FooterSize or 14,
            TextTransparency = 0.5,
            Parent = FooterMiddleSlot,
        })

        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -WindowInfo.CornerRadius / 4, 0, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                for _, Tab in Library.Tabs do
                    Tab:Resize(true)
                end
            end)
        end

        local ResizeImage = New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })
        Library:RegisterIconInstance(ResizeImage, "move-diagonal-2")

        Sidebar = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromOffset(0, 48),
            Size = UDim2.new(0, InitialLeftWidth, 1, -68),
            Parent = MainFrame,
        })
        Library.StyleTargets[Sidebar] = "panel"
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Sidebar,
        })

        DiscordBtnHeight = (WindowInfo.DiscordLink and typeof(WindowInfo.DiscordLink) == "string") and 36 or 0
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromScale(0, 0),
            LayoutOrder = 1,
            ScrollBarThickness = 0,
            Size = UDim2.new(1, 0, 1, -DiscordBtnHeight),
            Parent = Sidebar,
        })
        -- Library:AddCustomScrollbar(Tabs)
        local TabsLayout = New("UIListLayout", {
            Padding = UDim.new(0, WindowInfo.TabButtonsStyle.Gap),
            Parent = Tabs,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6 + WindowInfo.TabButtonsStyle.Padding),
            PaddingBottom = UDim.new(0, 6 + WindowInfo.TabButtonsStyle.Padding),
            PaddingLeft = UDim.new(0, 4 + WindowInfo.TabButtonsStyle.Padding),
            PaddingRight = UDim.new(0, 4 + WindowInfo.TabButtonsStyle.Padding),
            Parent = Tabs,
        })

        if DiscordBtnHeight > 0 then
            local HttpService = cloneref(game:GetService("HttpService"))
            local DiscordUrl = WindowInfo.DiscordLink
            local DiscordAction = WindowInfo.DiscordAction or "open"
            local DiscordInvite = DiscordUrl:match("discord%.gg/([^/%?]+)")
            local DiscordM = (syn and syn.request) or (http and http.request) or (rawget(_G, "http_request")) or (rawget(_G, "request"))

            local function DoDiscordAction()
                local Opened = false
                if DiscordAction == "open" and DiscordM and DiscordInvite then
                    pcall(function()
                        DiscordM({
                            Url = "http://127.0.0.1:6463/rpc?v=1",
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Origin"] = "https://discord.com",
                            },
                            Body = HttpService:JSONEncode({
                                cmd = "INVITE_BROWSER",
                                nonce = HttpService:GenerateGUID(false),
                                args = { code = DiscordInvite },
                            }),
                        })
                        Opened = true
                    end)
                end
                if not Opened and setclipboard then
                    setclipboard(tostring(DiscordUrl))
                    Library:Notify({ Title = "Discord", Description = "Invite link copied to clipboard.", Icon = "copy", Time = 3 })
                end
            end

            New("Frame", {
                BackgroundColor3 = "OutlineColor",
                BorderSizePixel = 0,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 1),
                Parent = Sidebar,
            })

            DiscordBtn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 3,
                Size = UDim2.new(1, 0, 0, DiscordBtnHeight - 1),
                Text = "",
                Parent = Sidebar,
            })

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                Parent = DiscordBtn,
            })

            local DiscordImgLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = CustomImageManager.GetAsset("DiscordIcon") or "",
                ImageColor3 = "AccentColor",
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromOffset(18, 18),
                Visible = not IsCompact,
                Parent = DiscordBtn,
            })

            local DiscordTextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                Text = "Discord",
                TextSize = 16,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Center,
                Visible = not IsCompact,
                Parent = DiscordBtn,
            })

            local DiscordCompactIcon = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = CustomImageManager.GetAsset("DiscordIcon") or "",
                ImageColor3 = "AccentColor",
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                Visible = IsCompact,
                Parent = DiscordBtn,
            })

            task.defer(function()
                DiscordTextLabel.Visible = not IsCompact
                DiscordImgLabel.Visible = not IsCompact
                DiscordCompactIcon.Visible = IsCompact

                local Resolved = CustomImageManager.GetAsset("DiscordIcon")
                if Resolved and DiscordImgLabel and DiscordImgLabel.Parent then
                    DiscordImgLabel.Image = Resolved
                end
                if Resolved and DiscordCompactIcon and DiscordCompactIcon.Parent then
                    DiscordCompactIcon.Image = Resolved
                end
            end)

            DiscordBtn.MouseButton1Click:Connect(DoDiscordAction)

            DiscordBtn.MouseEnter:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 0.85,
                }):Play()
                TweenService:Create(DiscordImgLabel, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
                TweenService:Create(DiscordTextLabel, Library.TweenInfo, {
                    TextTransparency = 0,
                }):Play()
                TweenService:Create(DiscordCompactIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end)
            DiscordBtn.MouseLeave:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                }):Play()
                TweenService:Create(DiscordImgLabel, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
                TweenService:Create(DiscordTextLabel, Library.TweenInfo, {
                    TextTransparency = 0.5,
                }):Play()
                TweenService:Create(DiscordCompactIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end)
            DiscordBtn.MouseButton1Down:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 0.7,
                }):Play()
            end)
            DiscordBtn.MouseButton1Up:Connect(function()
                TweenService:Create(DiscordBtn, Library.TweenInfo, {
                    BackgroundTransparency = 0.85,
                }):Play()
            end)
        end

        Container = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.new(1, 0, 0, 49),
            Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -70),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })
    end

    local Window = {}

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title

        LayoutTitleText(Window:GetSidebarWidth())
    end

    --// 0 = opaque, up to 0.85. Same as Library:SetWindowTransparency. \\--
    function Window:SetTransparency(Value: number)
        WindowInfo.Transparency = Value
        Library:SetWindowTransparency(Value)
    end

    function Window:SetGradient(Enabled: boolean)
        WindowInfo.Gradient = Enabled == true
        Library:SetGradientsEnabled(Enabled)
    end

    --// Re-measures the title and subtitle (called after the font changes). \\--
    function Window:RefreshTitleSize()
        LayoutTitleText(Window:GetSidebarWidth())
    end

    --// "Left" | "Center" | "Right". \\--
    function Window:SetTitleAlignment(Alignment: string)
        assert(Alignment == "Left" or Alignment == "Center" or Alignment == "Right", "Alignment must be Left, Center or Right")

        WindowInfo.TitleAlignment = Alignment
        LayoutTitleText(Window:GetSidebarWidth())
    end

    --// Pass nil to follow the title's alignment. \\--
    function Window:SetSubtitleAlignment(Alignment: string?)
        assert(Alignment == nil or Alignment == "Left" or Alignment == "Center" or Alignment == "Right", "Alignment must be Left, Center, Right or nil")

        WindowInfo.SubtitleAlignment = Alignment
        LayoutTitleText(Window:GetSidebarWidth())
    end

    function Window:SetSubtitle(subtitle: string?)
        subtitle = subtitle or ""
        assert(typeof(subtitle) == "string", "Expected string for subtitle got: " .. typeof(subtitle))

        WindowSubtitle.Text = subtitle
        WindowInfo.Subtitle = subtitle

        LayoutTitleText(Window:GetSidebarWidth())
    end

    function Window:SetSubtitleSize(size: number)
        assert(typeof(size) == "number", "Expected number for size got: " .. typeof(size))

        WindowInfo.SubtitleSize = size
        WindowSubtitle.TextSize = size

        LayoutTitleText(Window:GetSidebarWidth())
    end

    function Window:SetSubtitleTransparency(Transparency: number)
        assert(typeof(Transparency) == "number", "Expected number for transparency got: " .. typeof(Transparency))

        WindowInfo.SubtitleTransparency = Transparency
        WindowSubtitle.TextTransparency = Transparency
    end

    --// Pass nil to go back to the theme's font color. \\--
    function Window:SetTitleColor(Color: Color3?)
        WindowInfo.TitleColor = Color
        if Color then
            Library:RemoveRegistryProperty(WindowTitle, "TextColor3")
            WindowTitle.TextColor3 = Color
        else
            Library:AddToRegistry(WindowTitle, { TextColor3 = "FontColor" })
            WindowTitle.TextColor3 = Library.Scheme.FontColor
        end
    end

    function Window:SetSubtitleColor(Color: Color3?)
        WindowInfo.SubtitleColor = Color
        if Color then
            Library:RemoveRegistryProperty(WindowSubtitle, "TextColor3")
            WindowSubtitle.TextColor3 = Color
        else
            Library:AddToRegistry(WindowSubtitle, { TextColor3 = "FontColor" })
            WindowSubtitle.TextColor3 = Library.Scheme.FontColor
        end
    end

    function Window:SetTitleSize(size)
        assert(typeof(size) == "number", "Expected number for size got: " .. typeof(size))

        WindowInfo.TitleSize = size
        WindowTitle.TextSize = size

        LayoutTitleText(Window:GetSidebarWidth())
    end

    function Window:SetBackgroundImage(Image: string)
        assert(typeof(Image) == "string", "Expected string for Image got: " .. typeof(Image))

        local ValidImage = false

            if typeof(Image) == "string" then
                local BackgroundIcon = Library:GetCustomIcon(Image)

                if BackgroundIcon then
                    ValidImage = true

                    BackgroundImage.Image = BackgroundIcon.Url
                    BackgroundImage.ImageRectOffset = BackgroundIcon.ImageRectOffset
                    BackgroundImage.ImageRectSize = BackgroundIcon.ImageRectSize
                elseif Image:match("http://") or Image:match("https://") then
                    local RawFileName = Image:match("(.+)%..+$")
                    local _, Domain = Image:match("^(https?://)([^/]+)");

                    if RawFileName and Domain then
                        local Extention = string.sub(Image, #RawFileName + 1, #Image)
                        local FileNamePos = RawFileName:gsub("\\", "/"):find("/[^/]*$")
                        local FileName = FileNamePos and Image:sub(FileNamePos + 1) or nil

                        if FileName then
                            ValidImage = true

                            local AssetName = Domain .. FileName
                            if #AssetName > 255 then
                                local NewLength = 255 - #Domain - #Extention
                                if NewLength < 0 then
                                    AssetName = Domain .. Extention
                                else
                                    AssetName = Domain .. string.sub(FileName:sub(1, #FileName - #Extention), 1, NewLength) .. Extention
                                end
                            end

                            if CustomImageManagerAssets[FileName] == nil then
                                CustomImageManager.AddAsset(FileName, 0, Image)
                            else
                                CustomImageManager.DownloadAsset(FileName, true)
                            end

                            BackgroundImage.Image = CustomImageManager.GetAsset(FileName)
                            BackgroundImage.ImageRectOffset = Vector2.zero
                            BackgroundImage.ImageRectSize = Vector2.zero
                        end
                    end
                end
            end

            if not ValidImage then
                BackgroundImage.Image = ""
                BackgroundImage.ImageRectOffset = Vector2.zero
                BackgroundImage.ImageRectSize = Vector2.zero
            end

            BackgroundImage.Visible = ValidImage

            WindowInfo.BackgroundImage = Image
        end

    function Window:SetFooter(footer: string)
        assert(typeof(footer) == "string", "Expected string for footer got: " .. typeof(footer))

        FooterLabel.Text = footer
        WindowInfo.Footer = footer
    end

    --// Footer items. Side: "Left" | "Middle" (or "Center") | "Right".
    --// Info: a string, or { Text, Size, Transparency, Color, Order, Visible, Callback }.
    --// Providing a Callback turns the item into a clickable button. \\--
    local FooterItems = {}

    function Window:AddFooterItem(Side: string, Info)
        if typeof(Info) == "string" then
            Info = { Text = Info }
        end
        Info = typeof(Info) == "table" and Info or {}

        local SideKey = string.lower(tostring(Side or "middle"))
        local Slot = FooterMiddleSlot
        if SideKey == "left" then
            Slot = FooterLeftSlot
        elseif SideKey == "right" then
            Slot = FooterRightSlot
        end

        local Props = {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            LayoutOrder = Info.Order or (#FooterItems + 1),
            Size = UDim2.new(0, 0, 1, 0),
            Text = Info.Text or "",
            TextSize = Info.Size or WindowInfo.FooterSize or 14,
            TextTransparency = Info.Transparency or 0.5,
            Visible = Info.Visible ~= false,
            Parent = Slot,
        }
        if typeof(Info.Color) == "Color3" then
            Props.TextColor3 = Info.Color
        end

        local Item = New(Info.Callback and "TextButton" or "TextLabel", Props)
        if Info.Callback then
            Item.MouseButton1Click:Connect(function()
                Library:SafeCallback(Info.Callback, Item)
            end)
        end

        local FooterItem = { Instance = Item, Side = SideKey, Info = Info }
        table.insert(FooterItems, FooterItem)

        function FooterItem:SetText(Text: string)
            Item.Text = Text
        end

        function FooterItem:SetVisible(Visible: boolean)
            Item.Visible = Visible
        end

        function FooterItem:SetTextSize(Size: number)
            Item.TextSize = Size
        end

        function FooterItem:SetTransparency(Transparency: number)
            Item.TextTransparency = Transparency
        end

        function FooterItem:Destroy()
            local Index = table.find(FooterItems, FooterItem)
            if Index then
                table.remove(FooterItems, Index)
            end
            Library:RemoveFromRegistry(Item)
            Item:Destroy()
        end

        return FooterItem
    end

    function Window:ClearFooter(Side: string?)
        local SideKey = Side and string.lower(tostring(Side)) or nil
        for Idx = #FooterItems, 1, -1 do
            local FooterItem = FooterItems[Idx]
            if SideKey == nil or FooterItem.Side == SideKey then
                FooterItem:Destroy()
            end
        end
    end

    local FooterLeftItem
    function Window:SetFooterLeft(Text: string)
        assert(typeof(Text) == "string", "Expected string for footer got: " .. typeof(Text))
        if FooterLeftItem and FooterLeftItem.Instance.Parent then
            FooterLeftItem:SetText(Text)
        else
            FooterLeftItem = Window:AddFooterItem("Left", Text)
        end
        WindowInfo.FooterLeft = Text
    end

    local FooterRightItem
    function Window:SetFooterRight(Text: string)
        assert(typeof(Text) == "string", "Expected string for footer got: " .. typeof(Text))
        if FooterRightItem and FooterRightItem.Instance.Parent then
            FooterRightItem:SetText(Text)
        else
            FooterRightItem = Window:AddFooterItem("Right", Text)
        end
        WindowInfo.FooterRight = Text
    end

    if WindowInfo.FooterLeft then
        Window:SetFooterLeft(WindowInfo.FooterLeft)
    end
    if WindowInfo.FooterRight then
        Window:SetFooterRight(WindowInfo.FooterRight)
    end

    function Window:SetAlwaysOnTop(Enabled: boolean)
        WindowInfo.AlwaysOnTop = Enabled == true
        SetAlwaysOnTop(Library.ScreenGui, WindowInfo.AlwaysOnTop)
    end

    function Window:SetSnapping(Enabled: boolean, Distance: number?, Margin: number?, AvoidCoreGui: boolean?)
        WindowInfo.Snapping = Enabled == true
        WindowSnapConfig.Enabled = WindowInfo.Snapping

        if Distance then
            WindowInfo.SnapDistance = Distance
            WindowSnapConfig.Distance = Distance
        end

        if Margin then
            WindowInfo.SnapMargin = Margin
            WindowSnapConfig.Margin = Margin
        end

        if AvoidCoreGui ~= nil then
            WindowInfo.SnapAvoidCoreGui = AvoidCoreGui == true
            WindowSnapConfig.AvoidCoreGui = WindowInfo.SnapAvoidCoreGui
        end
    end

    function Window:SetAnimations(Animations: { [string]: boolean }?, TabTransitionTime: number?, TabSwipeOffset: number?, TabSwipeFrom: string?)
        if typeof(Animations) == "table" then
            WindowInfo.Animations = Animations
            Library.Animations = Animations
        end

        if typeof(TabTransitionTime) == "number" then
            local TransitionInfo = TweenInfo.new(
                math.max(0, TabTransitionTime or 0.22),
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )

            WindowInfo.TabTransitionInfo = TransitionInfo
            Library.TabTransitionInfo = TransitionInfo
        end

        if typeof(TabSwipeOffset) == "number" then
            local ClampedOffset = math.max(1, TabSwipeOffset)

            WindowInfo.TabSwipeOffset = ClampedOffset
            Library.TabSwipeOffset = ClampedOffset
        end

        if typeof(TabSwipeFrom) == "string" then
            local LoweredFrom = string.lower(TabSwipeFrom)

            WindowInfo.TabSwipeFrom = LoweredFrom
            Library.TabSwipeFrom = LoweredFrom
        end
    end

    function Window:SetCornerRadius(Radius: number)
        assert(typeof(Radius) == "number", "Expected number for Radius got: " .. typeof(Radius))
        Radius = math.min(Radius, 20)

        for _, UICorner in Library.Corners do
            if UICorner.CornerRadius.Offset == Library.CornerRadius / 2 then
                UICorner.CornerRadius = UDim.new(0, Radius / 2)
            else
                UICorner.CornerRadius = UDim.new(0, Radius)
            end
        end

        Library.CornerRadius = Radius
        WindowInfo.CornerRadius = Radius

        if Library.LayoutTopBar then
            Library.LayoutTopBar(Radius)
        end

        ResizeButton.Position = UDim2.new(1, -Radius / 4, 0, 0)
        BottomBackground.Size = UDim2.new(1, 0, 0, math.max(20, Radius * 2))

        for _, Tab in Library.Tabs do
            if Tab.IsKeyTab then
                continue
            end

            for _, SectionGroup in Tab.SectionGroups do
                SectionGroup:UpdateCorners()
            end
        end
    end

    local CompactWidth = 48

    local function ApplyCompact()
        IsCompact = Window:GetSidebarWidth() <= CompactWidth

        TitleTextHolder.Visible = not IsCompact
        if not WindowInfo.Icon then
            WindowIcon.Visible = IsCompact
        end

        for _, Button in Library.TabButtons do
            Button.Label.Visible = not IsCompact

            if IsCompact then

                Button.IconSlot.AnchorPoint = Vector2.new(0.5, 0.5)
                Button.IconSlot.Position = UDim2.fromScale(0.5, 0.5)
                Button.IconSlot.Size = UDim2.new(0, 20, 1, 0)
                Button.IconSlot.SizeConstraint = Enum.SizeConstraint.RelativeYY
                Button.Padding.PaddingLeft = UDim.new(0, 4)
            else

                Button.IconSlot.AnchorPoint = Vector2.new(0, 0.5)
                Button.IconSlot.Position = UDim2.new(0, 0, 0.5, 0)
                Button.IconSlot.Size = UDim2.new(0, 20, 1, 0)
                Button.IconSlot.SizeConstraint = Enum.SizeConstraint.RelativeYY
                Button.Padding.PaddingLeft = UDim.new(0, 20)
            end

            if Button.Icon then
                Button.FirstLetter.Visible = false
            else
                Button.FirstLetter.Visible = IsCompact
            end

            if Button.Tooltip then
                Button.Tooltip.Disabled = not IsCompact
            end
        end

        if DiscordBtn then
            local DiscordImgLabelObj = DiscordBtn:FindFirstChildWhichIsA("ImageLabel")
            local AllImgLabels = {}
            for _, Child in DiscordBtn:GetChildren() do
                if Child:IsA("ImageLabel") then
                    table.insert(AllImgLabels, Child)
                end
            end
            local AllTextLabels = {}
            for _, Child in DiscordBtn:GetChildren() do
                if Child:IsA("TextLabel") then
                    table.insert(AllTextLabels, Child)
                end
            end

            if AllTextLabels[1] then AllTextLabels[1].Visible = not IsCompact end
            if AllImgLabels[1] then AllImgLabels[1].Visible = not IsCompact end
            if AllImgLabels[2] then AllImgLabels[2].Visible = IsCompact end
        end

        for _, Header in Library.TabSectionHeaders do
            Header.Label.Visible = not IsCompact
            if IsCompact then
                Header.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
                Header.Arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
            else
                Header.Arrow.AnchorPoint = Vector2.new(1, 0.5)
                Header.Arrow.Position = UDim2.new(1, -2, 0.5, 0)
            end

            if Header.IndentPaddings then
                for _, Pad in Header.IndentPaddings do
                    Pad.PaddingLeft = UDim.new(0, IsCompact and 0 or 6)
                end
            end

            if Header.Separator then
                Header.Separator.Visible = IsCompact and Header.GetHasFollower() and Header.GetIsOpen()
            end

            if Header.Tooltip then
                Header.Tooltip.Disabled = not IsCompact
            end
        end
    end

    function Window:IsSidebarCompacted()
        return IsCompact
    end

    function Window:SetCompact(State)
        Window:SetSidebarWidth(State and CompactWidth or LastExpandedWidth)
    end

    function Window:GetSidebarWidth()
        return Sidebar.Size.X.Offset
    end

    local SidebarGrabberRef = nil

    function Window:SetSidebarWidth(Width)
        Width = math.clamp(Width, CompactWidth, MainFrame.Size.X.Offset - WindowInfo.MinContainerWidth - 1)

        DividerLine.Position = UDim2.fromOffset(Width, 0)

        if SidebarGrabberRef and SidebarGrabberRef.Parent then
            SidebarGrabberRef.Position = UDim2.fromOffset(Width, 0)
        end

        RightWrapper.Size = UDim2.new(1, -Width - 90 - 1, 1, -16)
        Sidebar.Size = UDim2.new(0, Width, 1, -70)
        Container.Size = UDim2.new(1, -Width - 1, 1, -70)

        LayoutTitleText(Width)

        ApplyCompact()
        if not IsCompact then
            LastExpandedWidth = Width
        end
    end

    function Window:ShowTabInfo(Name, Description)
        CurrentTabLabel.Text = Name
        CurrentTabDescription.Text = Description

        CurrentTabInfo.Visible = true
    end
    function Window:HideTabInfo()
        CurrentTabInfo.Visible = false
    end

    local LastSectionSeparator = nil

    --// A custom tab is a normal sidebar tab whose content area is left empty for you to fill:
    --// parent your own GuiObjects to Tab.Container (also available as Tab.CustomContainer). \\--
    local function ConvertToCustomTab(Tab)
        for _, Side in Tab.Sides do
            Side.Visible = false
        end

        Tab.IsCustomTab = true
        Tab.CustomContainer = Tab.Container

        return Tab
    end

    function Window:AddTabSection(Info)
        local SectionName = typeof(Info) == "table" and (Info.Name or "Section") or tostring(Info)
        local DefaultOpen = not (typeof(Info) == "table" and Info.Open == false) --// "x and false or true" always yielded true \\--
        local SectionIcon = typeof(Info) == "table" and Library:GetCustomIcon(Info.Icon) or nil

        local IsOpen = DefaultOpen

        if LastSectionSeparator then
            LastSectionSeparator.Show()
        end

        local GroupHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = Tabs,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 1),
            Parent = GroupHolder,
        })

        local HeaderBtn = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            Text = "",
            Parent = GroupHolder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = HeaderBtn }))

        local HeaderContent = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = HeaderBtn,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 8),
            Parent = HeaderContent,
        })

        if SectionIcon then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = SectionIcon.Url,
                ImageColor3 = SectionIcon.Custom and "WhiteColor" or "AccentColor",
                ImageRectOffset = SectionIcon.ImageRectOffset,
                ImageRectSize = SectionIcon.ImageRectSize,
                ImageTransparency = 0.3,
                Position = UDim2.fromOffset(0, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(0, 10, 0.5, 0),
                Parent = HeaderContent,
            })
        end

        local HeaderLabel = New("TextLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, SectionIcon and 24 or 0, 0.5, 0),
            Size = UDim2.new(1, -(SectionIcon and 40 or 16), 0, 14),
            Text = SectionName:upper(),
            TextSize = 10,
            TextTransparency = 0.4,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = HeaderContent,
        })

        local ChevronDownIcon = Library:GetIcon("chevron-down")
        local ChevronRightIcon = Library:GetIcon("chevron-right")
        local ArrowImg = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -2, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Fit,
            Image = IsOpen
                and (ChevronDownIcon and ChevronDownIcon.Url or "")
                or (ChevronRightIcon and ChevronRightIcon.Url or ""),
            ImageRectOffset = IsOpen
                and (ChevronDownIcon and ChevronDownIcon.ImageRectOffset or Vector2.zero)
                or (ChevronRightIcon and ChevronRightIcon.ImageRectOffset or Vector2.zero),
            ImageRectSize = IsOpen
                and (ChevronDownIcon and ChevronDownIcon.ImageRectSize or Vector2.zero)
                or (ChevronRightIcon and ChevronRightIcon.ImageRectSize or Vector2.zero),
            Parent = HeaderContent,
        })
        Library:AddToRegistry(ArrowImg, { ImageColor3 = "FontColor" })

        local function ApplySectionCompact(compact)
            HeaderLabel.Visible = not compact
            if compact then
                ArrowImg.AnchorPoint = Vector2.new(0.5, 0.5)
                ArrowImg.Position = UDim2.new(0.5, 0, 0.5, 0)
            else
                ArrowImg.AnchorPoint = Vector2.new(1, 0.5)
                ArrowImg.Position = UDim2.new(1, -2, 0.5, 0)
            end
        end

        ApplySectionCompact(IsCompact)

        local ChildrenHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = IsOpen,
            Parent = GroupHolder,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 1),
            Parent = ChildrenHolder,
        })

        local function UpdateArrow()
            local Icon = IsOpen and ChevronDownIcon or ChevronRightIcon
            if Icon then
                ArrowImg.Image = Icon.Url
                ArrowImg.ImageRectOffset = Icon.ImageRectOffset
                ArrowImg.ImageRectSize = Icon.ImageRectSize
            end
        end

        local SectionSeparator = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            Parent = GroupHolder,
        })
        Library:AddToRegistry(SectionSeparator, { BackgroundColor3 = "OutlineColor" })

        local HasFollower = false

        LastSectionSeparator = {
            Show = function()
                HasFollower = true
                SectionSeparator.Visible = IsCompact and IsOpen
            end,
        }

        HeaderBtn.MouseButton1Click:Connect(function()
            IsOpen = not IsOpen
            ChildrenHolder.Visible = IsOpen
            UpdateArrow()
            if HasFollower then
                SectionSeparator.Visible = IsCompact and IsOpen
            end
        end)

        local IndentPaddings = {}
        local SectionTabButtonRefs = {}

        local SectionTooltip = CompactTooltips and Library:AddTooltip(SectionName, nil, HeaderBtn) or nil
        if SectionTooltip then
            SectionTooltip.Disabled = not IsCompact
        end

        table.insert(Library.TabSectionHeaders, {
            Label = HeaderLabel,
            Arrow = ArrowImg,
            IndentPaddings = IndentPaddings,
            SectionTabButtonRefs = SectionTabButtonRefs,
            Separator = SectionSeparator,
            Tooltip = SectionTooltip,
            GetHasFollower = function() return HasFollower end,
            GetIsOpen = function() return IsOpen end,
        })

        local SectionGroup = {}

        function SectionGroup:AddTab(...)
            local IndentFrame = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = ChildrenHolder,
            })
            local IndentPad = New("UIPadding", {
                PaddingLeft = UDim.new(0, IsCompact and 0 or 6),
                Parent = IndentFrame,
            })
            table.insert(IndentPaddings, IndentPad)
            New("UIListLayout", {
                Padding = UDim.new(0, 1),
                Parent = IndentFrame,
            })

            local PrevCount = #Library.TabButtons
            local Tab = Window:AddTab(..., IndentFrame)
            for i = PrevCount + 1, #Library.TabButtons do
                Library.TabButtons[i].InSection = true
                table.insert(SectionTabButtonRefs, Library.TabButtons[i])
            end

            return Tab
        end

        function SectionGroup:AddCustomTab(...)
            return ConvertToCustomTab(SectionGroup:AddTab(...))
        end

        return SectionGroup
    end

    function Window:AddTab(InfoOrName, IconOrTabParent, Description, TabParent)
        local Name = nil
        local Icon = nil
        local Tooltip = nil
        local Order = nil

        if select("#", InfoOrName) == 0 then

            Name = "Tab"
        elseif typeof(InfoOrName) == "table" then
            local Info = InfoOrName
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
            Tooltip = Info.Tooltip
            Order = Info.Order

            if typeof(IconOrTabParent) == "Instance" then
                TabParent = IconOrTabParent
            end
        else
            Name = InfoOrName
            if typeof(IconOrTabParent) == "Instance" then
                TabParent = IconOrTabParent
            else
                Icon = IconOrTabParent
            end
        end

        if not tonumber(Order) then
            Order = #Tabs:GetChildren()
        end

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer
        local TabScroll
        local ColumnsRow
        local ColumnLeft
        local ColumnRight
        local ColumnFull
        local GetSectionParent
        local NextOrder = 0

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Text = "",
                LayoutOrder = Order,
                Parent = TabParent or Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, IsCompact and 4 or 20),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = TabButton,
            })
            Library:StyleTabButton(TabButton, ButtonPadding)

            local IconSlot = New("Frame", {
                AnchorPoint = IsCompact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 20, 1, 0),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(20, 20),
                    Parent = IconSlot,
                })
            end

            local FirstLetterLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Text = Name:sub(1, 1):upper(),
                TextSize = 14,
                TextTransparency = 0.5,
                Visible = not Icon and IsCompact,
                Parent = IconSlot,
            })

            TabLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 28, 0.5, 0),
                Size = UDim2.new(1, -28, 0, 18),
                Text = Name,
                TextSize = 14,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            local TabTooltip = CompactTooltips and Library:AddTooltip(Name, nil, TabButton) or nil
            if TabTooltip then TabTooltip.Disabled = not IsCompact end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
                IconSlot = IconSlot,
                FirstLetter = FirstLetterLabel,
                Tooltip = TabTooltip,
            })

            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            TabScroll = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Parent = TabContainer,
            })
            Library:AddCustomScrollbar(TabScroll)
            local TabScrollList = New("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabScroll,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabScroll,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabScroll,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 2147483646,
                    Parent = TabScroll,
                })
            end

            ColumnFull = TabScroll

            local CurrentLayoutMode = nil
            local CurrentColumnsRow = nil
            local CurrentColumnLeft = nil
            local CurrentColumnRight = nil

            GetSectionParent = function(Side)
                local RequestedMode = (Side == 1 or Side == 2) and "two-column" or nil

                local NeedNewRow = CurrentLayoutMode ~= RequestedMode

                if NeedNewRow then
                    CurrentLayoutMode = RequestedMode

                    if RequestedMode == "two-column" then

                        CurrentColumnsRow = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            LayoutOrder = NextOrder,
                            Size = UDim2.new(1, 0, 0, 0),
                            Parent = TabScroll,
                        })

                        CurrentColumnLeft = New("Frame", {
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0.5, -3, 0, 0),
                            Parent = CurrentColumnsRow,
                        })
                        New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Parent = CurrentColumnLeft,
                        })

                        CurrentColumnRight = New("Frame", {
                            AnchorPoint = Vector2.new(1, 0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromScale(1, 0),
                            Size = UDim2.new(0.5, -3, 0, 0),
                            Parent = CurrentColumnsRow,
                        })
                        New("UIListLayout", {
                            Padding = UDim.new(0, 2),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Parent = CurrentColumnRight,
                        })

                        NextOrder = NextOrder + 1
                    else

                        NextOrder = NextOrder + 1
                    end
                end

                if RequestedMode == "two-column" then
                    return Side == 1 and CurrentColumnLeft or CurrentColumnRight
                else
                    local Order = NextOrder - 1
                    return ColumnFull, Order
                end
            end
        end

        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        local WarningBox
        local WarningBoxOutline
        local WarningBoxShadowOutline
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.new(1, -5, 0, 0),
                Parent = WarningBoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = WarningBox,
                })
            )
            WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = WarningBox,
            })
            Library:AddCustomScrollbar(WarningBoxScrollingFrame)
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 50, 50),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })

            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Color3.fromRGB(169, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })

            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = GetTextStrokeColor,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        local Tab = {
            Sections = {},
            SectionCount = 0,
            SectionGroups = {},
            ConditionalSections = {},
            Name = Name,
            Description = Description,
            Tooltip = Tooltip,
            TooltipTable = nil,
            Order = Order,
            Container = TabContainer,
            Button = TabButton,
            Sides = {
                TabScroll,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },
        }

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean" then
                Tab.WarningBox.IsNormal = Info.IsNormal
            end
            if typeof(Info.LockSize) == "boolean" then
                Tab.WarningBox.LockSize = Info.LockSize
            end
            if typeof(Info.Visible) == "boolean" then
                Tab.WarningBox.Visible = Info.Visible
            end
            if typeof(Info.Title) == "string" then
                Tab.WarningBox.Title = Info.Title
            end
            if typeof(Info.Text) == "string" then
                Tab.WarningBox.Text = Info.Text
            end

            WarningBoxHolder.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                or Color3.fromRGB(127, 0, 0)

            WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor
                or Color3.fromRGB(85, 0, 0)
            WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(255, 50, 50)

            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                or Color3.fromRGB(255, 50, 50)
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or Color3.fromRGB(169, 0, 0)

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningBoxShadowOutline] then
                Library:AddToRegistry(WarningBoxShadowOutline, {})
            end
            if not Library.Registry[WarningBoxOutline] then
                Library:AddToRegistry(WarningBoxOutline, {})
            end
            if not Library.Registry[WarningTitle] then
                Library:AddToRegistry(WarningTitle, {})
            end
            if not Library.Registry[WarningStroke] then
                Library:AddToRegistry(WarningStroke, {})
            end

            Library.Registry[WarningBox].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
            end

            Library.Registry[WarningBoxShadowOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
            end

            Library.Registry[WarningBoxOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningTitle].TextColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningStroke].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
            end
        end

        function Tab:RefreshSides()
            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            for _, Side in Tab.Sides do
                Side.Position = UDim2.new(0, 0, 0, Offset)
                Side.Size = UDim2.new(1, 0, 1, -Offset)
            end
        end

        function Tab:Resize(ResizeWarningBox: boolean?)
            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
            end

            Tab:RefreshSides()
        end

        function Tab:AddSection(NameOrInfo, IconName)
            local Info
            if typeof(NameOrInfo) == "table" then
                Info = NameOrInfo
            else
                Info = { Name = NameOrInfo, IconName = IconName }
            end

            local SectionParent, SectionOrder = GetSectionParent(Info.Side)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = SectionOrder or 0,
                Size = UDim2.fromScale(1, 0),
                Parent = SectionParent,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                Parent = BoxHolder,
            })

            local SectionHolder
            local SectionLabel

            local SectionContainer
            local SectionList
            local SectionSeparatorLine

            local IconSource = Info.IconName or Info.Icon
            local HasSubtext = typeof(Info.Subtext) == "string" and Info.Subtext ~= ""
            local IsTile = Info.IconStyle == "Tile" and IconSource ~= nil
            local HeaderHeight = (HasSubtext or IsTile) and 46 or 34
            local IconOffset = IsTile and 36 or 24

            local PopOutButton
            local CanPopOut
            if Info.PopOut ~= nil then
                CanPopOut = Info.PopOut == true
            else
                CanPopOut = WindowInfo.PopOutBoxes ~= false
            end

            do
                SectionHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = SectionHolder,
                    })
                )
                Library:AddOutline(SectionHolder)

                SectionSeparatorLine = Library:MakeLine(SectionHolder, {
                    Position = UDim2.fromOffset(0, HeaderHeight),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = (not IsTile) and Library:GetCustomIcon(IconSource) or nil
                if IsTile then
                    local TileHolder = Library:CreateIconTile(SectionHolder, IconSource, {
                        Size = 30,
                        Background = Info.IconBackground == nil and "Accent" or Info.IconBackground or nil,
                        IconColor = Info.IconColor,
                    })
                    TileHolder.Position = UDim2.fromOffset(8, (HeaderHeight - 30) / 2)
                end
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(6, 6),
                        Size = UDim2.fromOffset(22, 22),
                        Parent = SectionHolder,
                    })
                end

                local SectionHeaderBtn = New("TextButton", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, HeaderHeight),
                    Text = "",
                    Parent = SectionHolder,
                })

                SectionLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset((BoxIcon or IsTile) and IconOffset or 0, HasSubtext and 5 or 0),
                    Size = UDim2.new(1, -((BoxIcon or IsTile) and IconOffset or 0) - 28 - (CanPopOut and 24 or 0), 0, HasSubtext and 21 or HeaderHeight),
                    Text = Info.Name,
                    TextSize = 15,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SectionHeaderBtn,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    Parent = SectionLabel,
                })

                if HasSubtext then
                    local SectionSubtext = New("TextLabel", {
                        BackgroundTransparency = 1,
                        FontFace = function()
                            return Library:GetThinFont()
                        end,
                        Position = UDim2.fromOffset((BoxIcon or IsTile) and IconOffset or 0, 25),
                        Size = UDim2.new(1, -((BoxIcon or IsTile) and IconOffset or 0) - 28 - (CanPopOut and 24 or 0), 0, 15),
                        Text = Info.Subtext,
                        TextSize = 12,
                        TextTransparency = 0.5,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = SectionHeaderBtn,
                    })
                    New("UIPadding", {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        Parent = SectionSubtext,
                    })
                end

                local SectionFoldOpen = Info.DefaultOpen ~= false
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")
                local SectionArrow = New("ImageLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    ImageColor3 = "FontColor",
                    ImageTransparency = 0.5,
                    ScaleType = Enum.ScaleType.Fit,
                    Image = SectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.Url or "")
                        or (SectionChevronRight and SectionChevronRight.Url or ""),
                    ImageRectOffset = SectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.ImageRectOffset or Vector2.zero)
                        or (SectionChevronRight and SectionChevronRight.ImageRectOffset or Vector2.zero),
                    ImageRectSize = SectionFoldOpen
                        and (SectionChevronDown and SectionChevronDown.ImageRectSize or Vector2.zero)
                        or (SectionChevronRight and SectionChevronRight.ImageRectSize or Vector2.zero),
                    Parent = SectionHeaderBtn,
                })
                Library:AddToRegistry(SectionArrow, { ImageColor3 = "FontColor" })

                if CanPopOut then
                    PopOutButton = New("ImageButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        ImageColor3 = "FontColor",
                        ImageTransparency = 0.55,
                        Position = UDim2.new(1, -30, 0.5, 0),
                        Size = UDim2.fromOffset(14, 14),
                        Parent = SectionHeaderBtn,
                    })
                    Library:RegisterIconInstance(PopOutButton, "square-arrow-out-up-right")

                    PopOutButton.MouseEnter:Connect(function()
                        TweenService:Create(PopOutButton, Library.TweenInfo, { ImageTransparency = 0 }):Play()
                    end)
                    PopOutButton.MouseLeave:Connect(function()
                        TweenService:Create(PopOutButton, Library.TweenInfo, { ImageTransparency = 0.55 }):Play()
                    end)
                end

                SectionContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, HeaderHeight + 1),
                    Size = UDim2.new(1, 0, 1, -(HeaderHeight + 1)),
                    Visible = SectionFoldOpen,
                    Parent = SectionHolder,
                })
                SectionSeparatorLine.Visible = SectionFoldOpen

                SectionList = New("UIListLayout", {
                    Padding = UDim.new(0, 10),
                    Parent = SectionContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 10),
                    Parent = SectionContainer,
                })
            end

            Tab.SectionCount += 1

            local Section = {
                BoxHolder = BoxHolder,
                Holder = SectionHolder,
                Container = SectionContainer,

                Tab = Tab,
                Name = Info.Name,
                ConditionalGroups = {},
                SubSections = {},
                Elements = {},

                Side = Info.Side or 1,
                Order = Tab.SectionCount,

                Folded = not (Info.DefaultOpen ~= false),

                SubSectionLayout = {
                    CurrentLayoutMode = nil,
                    CurrentColumnsRow = nil,
                    CurrentColumnLeft = nil,
                    CurrentColumnRight = nil,
                    NextOrder = 0,
                },
            }

            Section.MaxHeight = typeof(Info.MaxHeight) == "number" and Info.MaxHeight or nil
            Section.MaxPopOutHeight = typeof(Info.MaxPopOutHeight) == "number" and Info.MaxPopOutHeight or 420
            Section.PopOutWidth = typeof(Info.PopOutWidth) == "number" and Info.PopOutWidth or nil
            Section.PoppedOut = false

            local BodyScroll --// scrolling body, only exists while MaxHeight is set
            local PopScroll --// scrolling body inside the floating panel
            local PopMenu
            local PopPlaceholder
            local PopHeightConn

            function Section:Resize()
                SectionSeparatorLine.Visible = not Section.Folded and not Section.PoppedOut

                if Section.PoppedOut then
                    SectionHolder.Size = UDim2.new(1, 0, 0, HeaderHeight + 28)
                elseif Section.Folded then
                    SectionHolder.Size = UDim2.new(1, 0, 0, HeaderHeight)
                else
                    local Body = (SectionList.AbsoluteContentSize.Y / Library.DPIScale) + 20
                    if Section.MaxHeight then
                        Body = math.min(Body, Section.MaxHeight)
                    end

                    SectionHolder.Size = UDim2.new(1, 0, 0, Body + HeaderHeight)
                end
            end

            --// Puts the content frame where it belongs for the current state (inline, scrolling, or popped out). \\--
            local function ShiftZIndex(Delta: number)
                if Delta == 0 then
                    return
                end

                SectionContainer.ZIndex += Delta
                for _, Desc in SectionContainer:GetDescendants() do
                    if Desc:IsA("GuiObject") then
                        Desc.ZIndex += Delta
                    end
                end
            end

            local function PlaceContainer()
                if Section.PoppedOut and PopScroll then
                    local Delta = PopScroll.ZIndex - SectionContainer.ZIndex
                    SectionContainer.Position = UDim2.new()
                    SectionContainer.Size = UDim2.new(1, 0, 0, 0)
                    SectionContainer.AutomaticSize = Enum.AutomaticSize.Y
                    SectionContainer.Visible = true
                    SectionContainer.Parent = PopScroll
                    ShiftZIndex(Delta)
                    return
                end

                if Section.MaxHeight then
                    if not BodyScroll then
                        BodyScroll = New("ScrollingFrame", {
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            CanvasSize = UDim2.new(),
                            Position = UDim2.fromOffset(0, HeaderHeight + 1),
                            ScrollBarImageColor3 = "AccentColor",
                            ScrollBarThickness = 3,
                            ScrollingDirection = Enum.ScrollingDirection.Y,
                            Size = UDim2.new(1, 0, 1, -(HeaderHeight + 1)),
                            Parent = SectionHolder,
                        })
                    end

                    SectionContainer.Position = UDim2.new()
                    SectionContainer.Size = UDim2.new(1, 0, 0, 0)
                    SectionContainer.AutomaticSize = Enum.AutomaticSize.Y
                    SectionContainer.Visible = not Section.Folded
                    SectionContainer.Parent = BodyScroll
                    return
                end

                SectionContainer.Position = UDim2.fromOffset(0, HeaderHeight + 1)
                SectionContainer.Size = UDim2.new(1, 0, 1, -(HeaderHeight + 1))
                SectionContainer.AutomaticSize = Enum.AutomaticSize.None
                SectionContainer.Visible = not Section.Folded
                SectionContainer.Parent = SectionHolder

                if BodyScroll then
                    BodyScroll:Destroy()
                    BodyScroll = nil
                end
            end

            --// Limits how tall the section body gets; taller content scrolls. Pass nil to remove the limit. \\--
            function Section:SetMaxHeight(Height: number?)
                assert(Height == nil or (typeof(Height) == "number" and Height > 0), "MaxHeight must be a positive number or nil")

                Section.MaxHeight = Height
                if not Section.PoppedOut then
                    PlaceContainer()
                end
                Section:Resize()
            end

            function Section:RefreshPopOutPlaceholder()
                if PopPlaceholder then
                    PopPlaceholder.Text = string.format("%s is popped out. Click here to dock it.", Section.Name)
                end
            end

            function Section:SetPopOutWidth(Width: number)
                assert(typeof(Width) == "number" and Width > 0, "Width must be a positive number")

                Section.PopOutWidth = Width
                if Section.PoppedOut and PopMenu and PopMenu.Holder then
                    PopMenu.Holder.Size = UDim2.fromOffset(Width, 0)
                end
            end

            function Section:SetMaxPopOutHeight(Height: number)
                assert(typeof(Height) == "number" and Height > 0, "Height must be a positive number")

                Section.MaxPopOutHeight = Height
                if PopScroll then
                    local Content = (SectionList.AbsoluteContentSize.Y / Library.DPIScale) + 20
                    PopScroll.Size = UDim2.new(1, 0, 0, math.min(Content, Height))
                end
            end

            function Section:IsPoppedOut(): boolean
                return Section.PoppedOut
            end

            --// Pops the section out into a floating, draggable panel (built on AddDraggableMenu so it matches
            --// the other overlays). Closing the panel docks the section back where it was. \\--
            function Section:SetPoppedOut(Popped: boolean)
                Popped = Popped == true
                if Section.PoppedOut == Popped then
                    return
                end

                if Popped then
                    Section.PoppedOut = true

                    local Width = Section.PopOutWidth
                        or math.clamp(math.floor(SectionHolder.AbsoluteSize.X / Library.DPIScale), 240, 480)

                    local MenuHolder, MenuContainer, MenuObj = Library:AddDraggableMenu(Section.Name, Width)
                    PopMenu = MenuObj

                    --// The section container already has its own padding. \\--
                    local MenuPadding = MenuContainer:FindFirstChildOfClass("UIPadding")
                    if MenuPadding then
                        MenuPadding.PaddingTop = UDim.new(0, 0)
                        MenuPadding.PaddingBottom = UDim.new(0, 0)
                        MenuPadding.PaddingLeft = UDim.new(0, 0)
                        MenuPadding.PaddingRight = UDim.new(0, 0)
                    end

                    --// The scroll body is sized explicitly (content height, capped at MaxPopOutHeight);
                    --// an automatic-size scrolling frame is not reliable. \\--
                    PopScroll = New("ScrollingFrame", {
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        CanvasSize = UDim2.new(),
                        ScrollBarImageColor3 = "AccentColor",
                        ScrollBarThickness = 3,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        Size = UDim2.new(1, 0, 0, 40),
                        Parent = MenuContainer,
                    })

                    local function UpdatePopHeight()
                        if not PopScroll or not PopScroll.Parent then
                            return
                        end
                        local Content = (SectionList.AbsoluteContentSize.Y / Library.DPIScale) + 20
                        PopScroll.Size = UDim2.new(1, 0, 0, math.min(Content, Section.MaxPopOutHeight))
                    end
                    PopHeightConn = SectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdatePopHeight)
                    UpdatePopHeight()

                    --// Minimizing the panel hides its container; keep the scroll body in step. \\--
                    MenuContainer:GetPropertyChangedSignal("Visible"):Connect(function()
                        if PopScroll then
                            PopScroll.Visible = MenuContainer.Visible
                        end
                    end)

                    --// The X button docks the section instead of just hiding the panel. \\--
                    function MenuObj:Remove()
                        if Section.PoppedOut then
                            Section:SetPoppedOut(false)
                        end
                    end

                    Library.PoppedSections[Section] = MenuHolder
                    MenuHolder.Visible = Library.Toggled ~= false

                    PopPlaceholder = New("TextButton", {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(0, HeaderHeight + 1),
                        Size = UDim2.new(1, 0, 0, 26),
                        Text = "",
                        TextSize = 13,
                        TextTransparency = 0.5,
                        Parent = SectionHolder,
                    })
                    Section:RefreshPopOutPlaceholder()
                    PopPlaceholder.MouseButton1Click:Connect(function()
                        Section:SetPoppedOut(false)
                    end)

                    PlaceContainer()
                    Section:Resize()
                else
                    Section.PoppedOut = false

                    if PopScroll then
                        local Delta = SectionContainer.ZIndex - SectionHolder.ZIndex
                        ShiftZIndex(-Delta)
                    end

                    PlaceContainer()

                    local Menu = PopMenu
                    PopMenu = nil
                    PopScroll = nil
                    if PopHeightConn then
                        PopHeightConn:Disconnect()
                        PopHeightConn = nil
                    end
                    Library.PoppedSections[Section] = nil

                    if PopPlaceholder then
                        PopPlaceholder:Destroy()
                        PopPlaceholder = nil
                    end

                    if Menu then
                        local MenuHolder = Menu.Holder
                        pcall(Menu.Destroy, Menu)
                        if MenuHolder then
                            MenuHolder:Destroy()
                        end
                    end

                    Section:Resize()
                end
            end

            function Section:TogglePoppedOut()
                Section:SetPoppedOut(not Section.PoppedOut)
            end

            if PopOutButton then
                PopOutButton.MouseButton1Click:Connect(function()
                    Section:TogglePoppedOut()
                end)
            end

            do
                local SectionChevronDown = Library:GetIcon("chevron-down")
                local SectionChevronRight = Library:GetIcon("chevron-right")

                local function SetSectionArrowIcon(Arrow, Open)
                    local Icon = Open and SectionChevronDown or SectionChevronRight
                    if Icon then
                        Arrow.Image = Icon.Url
                        Arrow.ImageRectOffset = Icon.ImageRectOffset
                        Arrow.ImageRectSize = Icon.ImageRectSize
                    end
                end

                local HeaderBtn = SectionHolder:FindFirstChildWhichIsA("TextButton")
                local Arrow = HeaderBtn and HeaderBtn:FindFirstChildWhichIsA("ImageLabel")

                function Section:SetFolded(Folded)
                    if Section.Folded == Folded then return end
                    if Section.PoppedOut then return end
                    Section.Folded = Folded
                    SectionContainer.Visible = not Section.Folded
                    SectionSeparatorLine.Visible = not Section.Folded
                    if Arrow then
                        SetSectionArrowIcon(Arrow, not Section.Folded)
                    end
                    Section:Resize()
                end

                if HeaderBtn then
                    HeaderBtn.MouseButton1Click:Connect(function()
                        if Section.PoppedOut then
                            Section:SetPoppedOut(false)
                        else
                            Section:SetFolded(not Section.Folded)
                        end
                    end)
                end
            end

            setmetatable(Section, BaseSection)

            if Section.MaxHeight then
                PlaceContainer()
            end

            Section:Resize()
            Tab.Sections[Info.Name] = Section

            return Section
        end

        function Tab:AddLeftSection(Name, IconName)
            return Tab:AddSection({ Side = 1, Name = Name, IconName = IconName })
        end

        function Tab:AddRightSection(Name, IconName)
            return Tab:AddSection({ Side = 2, Name = Name, IconName = IconName })
        end

        function Tab:AddSectionGroup(NameOrInfo)
            local Info
            if typeof(NameOrInfo) == "table" then
                Info = NameOrInfo
            else
                Info = { Name = NameOrInfo }
            end

            local SectionParent, SectionOrder = GetSectionParent(Info.Side)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = SectionOrder or 0,
                Size = UDim2.fromScale(1, 0),
                Parent = SectionParent,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local SectionGroupHolder
            local SectionGroupButtons
            local BarHeight = 42 --// tab bar (30) + its 6px margins

            do
                SectionGroupHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = SectionGroupHolder,
                    })
                )
                local OutlineStroke = Library:AddOutline(SectionGroupHolder)

                --// Accent border (set AccentBorder = false for the plain outline). \\--
                if Info.AccentBorder == true then
                    Library.Registry[OutlineStroke].Color = nil
                    OutlineStroke.Color = Color3.new(1, 1, 1)
                    OutlineStroke.Transparency = 0.35
                    Library:ApplyAccentGradient(OutlineStroke, 45)
                end

                --// Segmented tab bar: a rounded track with the active tab as an accent pill. \\--
                SectionGroupButtons = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Position = UDim2.fromOffset(6, 6),
                    Size = UDim2.new(1, -12, 0, 30),
                    Parent = SectionGroupHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = SectionGroupButtons,
                    })
                )
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = SectionGroupButtons,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 3),
                    PaddingRight = UDim.new(0, 3),
                    PaddingTop = UDim.new(0, 3),
                    Parent = SectionGroupButtons,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDim.new(0, 3),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Parent = SectionGroupButtons,
                })
            end

            local TotalButtons, TotalTabs = 0, 1
            local SectionGroup = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = SectionGroupHolder,
                Tabs = {},

                MaxHeight = typeof(Info.MaxHeight) == "number" and Info.MaxHeight or nil,
            }

            --// Limits how tall the tab content gets; taller content scrolls. nil removes the limit. \\--
            function SectionGroup:SetMaxHeight(Height: number?)
                assert(Height == nil or (typeof(Height) == "number" and Height > 0), "MaxHeight must be a positive number or nil")

                SectionGroup.MaxHeight = Height
                for _, Page in SectionGroup.Tabs do
                    Page:ApplyMaxHeight()
                    Page:Resize()
                end
            end

            function SectionGroup:UpdateCorners()
                for _, Page in SectionGroup.Tabs do
                    Page:UpdateCorners()
                end
            end

            function SectionGroup:AddTab(Name, IconName)
                local TabIndex = TotalTabs

                TotalButtons = TotalButtons + 1
                TotalTabs = TotalTabs + 1

                local BoxIcon = Library:GetCustomIcon(IconName)

                local Button = New("TextButton", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 1,
                    LayoutOrder = TabIndex,
                    Size = UDim2.new(0, 0, 1, 0),
                    Text = "",
                    Parent = SectionGroupButtons,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, math.max(WindowInfo.CornerRadius - 2, 2)),
                    Parent = Button,
                })
                Library:ApplyAccentGradient(Button, 0)

                local ButtonContent = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 16),
                    Parent = Button,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = ButtonContent,
                })

                local ButtonIcon
                if BoxIcon then
                    ButtonIcon = New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "FontColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromOffset(16, 16),
                        Parent = ButtonContent,
                    })
                end

                local ButtonLabel = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 16),
                    Text = Name,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    Parent = ButtonContent,
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, BarHeight),
                    Size = UDim2.new(1, 0, 1, -BarHeight),
                    Visible = false,
                    Parent = SectionGroupHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 8),
                    Parent = Container,
                })

                local Scroll --// scrolling wrapper, only exists while a MaxHeight is set

                local function SetPageVisible(Visible: boolean)
                    if Scroll then
                        Scroll.Visible = Visible
                        Container.Visible = true
                    else
                        Container.Visible = Visible
                    end
                end

                local Page = {
                    ButtonHolder = Button,
                    Container = Container,

                    Tab = Tab,
                    Name = Name,
                    Elements = {},
                    ConditionalGroups = {},
                    SubSections = {},

                    Order = TabIndex,
                }

                function Page:Show()
                    if SectionGroup.ActiveTab then
                        SectionGroup.ActiveTab:Hide()
                    end

                    TweenService:Create(Button, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()

                    ButtonLabel.TextTransparency = 0
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0
                    end

                    SetPageVisible(true)

                    SectionGroup.ActiveTab = Page
                    Page:Resize()
                end

                function Page:Hide()
                    TweenService:Create(Button, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()

                    ButtonLabel.TextTransparency = 0.5
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0.5
                    end
                    SetPageVisible(false)

                    SectionGroup.ActiveTab = nil
                end

                Button.MouseEnter:Connect(function()
                    if SectionGroup.ActiveTab ~= Page then
                        TweenService:Create(ButtonLabel, Library.TweenInfo, { TextTransparency = 0.2 }):Play()
                    end
                end)
                Button.MouseLeave:Connect(function()
                    if SectionGroup.ActiveTab ~= Page then
                        TweenService:Create(ButtonLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    end
                end)

                function Page:Resize()
                    if SectionGroup.ActiveTab ~= Page then
                        return
                    end

                    local Body = (List.AbsoluteContentSize.Y / Library.DPIScale) + 16
                    if SectionGroup.MaxHeight then
                        Body = math.min(Body, SectionGroup.MaxHeight)
                    end

                    SectionGroupHolder.Size = UDim2.new(1, 0, 0, Body + BarHeight)
                end

                function Page:ApplyMaxHeight()
                    if SectionGroup.MaxHeight and not Scroll then
                        local WasVisible = Container.Visible

                        Scroll = New("ScrollingFrame", {
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            CanvasSize = UDim2.new(),
                            Position = UDim2.fromOffset(0, BarHeight),
                            ScrollBarImageColor3 = "AccentColor",
                            ScrollBarThickness = 3,
                            ScrollingDirection = Enum.ScrollingDirection.Y,
                            Size = UDim2.new(1, 0, 1, -BarHeight),
                            Visible = WasVisible,
                            Parent = SectionGroupHolder,
                        })

                        Container.Position = UDim2.new()
                        Container.Size = UDim2.new(1, 0, 0, 0)
                        Container.AutomaticSize = Enum.AutomaticSize.Y
                        Container.Visible = true
                        Container.Parent = Scroll
                    elseif not SectionGroup.MaxHeight and Scroll then
                        local WasVisible = Scroll.Visible

                        Container.Position = UDim2.fromOffset(0, BarHeight)
                        Container.Size = UDim2.new(1, 0, 1, -BarHeight)
                        Container.AutomaticSize = Enum.AutomaticSize.None
                        Container.Visible = WasVisible
                        Container.Parent = SectionGroupHolder

                        Scroll:Destroy()
                        Scroll = nil
                    end
                end

                --// Kept so older scripts calling it keep working; pills round themselves. \\--
                function Page:UpdateCorners() end

                if not SectionGroup.ActiveTab then
                    Page:Show()
                end

                Button.MouseButton1Click:Connect(Page.Show)

                setmetatable(Page, BaseSection)

                SectionGroup.Tabs[Name] = Page
                SectionGroup:UpdateCorners()

                if SectionGroup.MaxHeight then
                    Page:ApplyMaxHeight()
                    Page:Resize()
                end

                return Page
            end

            if Info.Name then
                Tab.SectionGroups[Info.Name] = SectionGroup
            else
                table.insert(Tab.SectionGroups, SectionGroup)
            end

            return SectionGroup
        end

        function Tab:AddLeftSectionGroup(Name)
            return Tab:AddSectionGroup({ Side = 1, Name = Name })
        end

        function Tab:AddRightSectionGroup(Name)
            return Tab:AddSectionGroup({ Side = 2, Name = Name })
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            Library:PlayTabAnimation(Tab, true)
            Tab:RefreshSides()

            Library.ActiveTab = Tab
            Library:FireActiveTabChanged(Tab)

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end

            Library:PlayTabAnimation(Tab, false)
            Window:HideTabInfo()

            Library.PreviousTab = Tab
            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        function Tab:SetOrder(NewOrder: number)
            Order = NewOrder
            TabButton.LayoutOrder = Order
        end

        function Tab:SetTooltip(Text: string?)
            Tab.Tooltip = Text

            if Tab.TooltipTable then
                Tab.TooltipTable:Destroy()
                Tab.TooltipTable = nil
            end

            if typeof(Text) == "string" then
                Tab.TooltipTable = Library:AddTooltip(Text, nil, TabButton)
            end
        end

        if typeof(Tooltip) == "string" then
            Tab.TooltipTable = Library:AddTooltip(Tooltip, nil, TabButton)
        end

        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddCustomTab(...)
        return ConvertToCustomTab(Window:AddTab(...))
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local KeyTabOrder = #Tabs:GetChildren()

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                LayoutOrder = KeyTabOrder,
                Parent = Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, IsCompact and 4 or 20),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = TabButton,
            })
            Library:StyleTabButton(TabButton, ButtonPadding)

            local IconSlot = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 20, 1, 0),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(20, 20),
                    Parent = IconSlot,
                })
            end

            local FirstLetterLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Text = Name:sub(1, 1):upper(),
                TextSize = 14,
                TextTransparency = 0.5,
                Visible = not Icon and IsCompact,
                Parent = IconSlot,
            })

            TabLabel = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 28, 0.5, 0),
                Size = UDim2.new(1, -28, 0, 18),
                Text = Name,
                TextSize = 14,
                TextTransparency = 0.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            local TabTooltip = CompactTooltips and Library:AddTooltip(Name, nil, TabButton) or nil
            if TabTooltip then TabTooltip.Disabled = not IsCompact end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
                IconSlot = IconSlot,
                FirstLetter = FirstLetterLabel,
                Tooltip = TabTooltip,
            })

            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageColor3 = "OutlineColor",
                ScrollBarThickness = 3,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            Library:AddToRegistry(TabContainer, { ScrollBarImageColor3 = "OutlineColor" })
            Library:AddCustomScrollbar(TabContainer)
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        local Tab = {
            Elements = {},
            Description = Description,
            Tooltip = nil,
            TooltipTable = nil,
            Order = KeyTabOrder,
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Box,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Box,
                })
            )

            Library:AddFocusHighlight(Box)

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                TextTransparency = 0.4,
                Parent = Holder,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Button,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
            )

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0,
                }):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0.4,
                }):Play()
            end)
            Button.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Callback(Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end
        function Tab:UpdateCorners() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            Library:PlayTabAnimation(Tab, true)

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab
            Library:FireActiveTabChanged(Tab)

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end

            Library:PlayTabAnimation(Tab, false)

            Window:HideTabInfo()

            Library.PreviousTab = Tab
            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        function Tab:SetOrder(NewOrder: number)
            Tab.Order = NewOrder
            TabButton.LayoutOrder = Tab.Order
        end

        function Tab:SetTooltip(Text: string?)
            Tab.Tooltip = Text

            if Tab.TooltipTable then
                Tab.TooltipTable:Destroy()
                Tab.TooltipTable = nil
            end

            if typeof(Text) == "string" then
                Tab.TooltipTable = Library:AddTooltip(Text, nil, TabButton)
            end
        end

        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        Tab.Button = TabButton
        setmetatable(Tab, BaseSection)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddDialog(Idx, Info)
        Info = Library:Validate(Info, Templates.Dialog)

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",

            Active = true,

            ZIndex = Library.DialogScrimZIndex,
            Visible = true,
            Parent = MainFrame,
        })
        TweenService:Create(DialogOverlay, Library.TweenInfo, {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "BackgroundColor",
            BackgroundTransparency = 0,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,

            ZIndex = Library.DialogContentZIndex + 1,
            Parent = DialogOverlay,
        })
        Library.StyleTargets[DialogFrame] = "solid"
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = DialogFrame,
            })
        )
        Library:AddOutline(DialogFrame)

        local InnerContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = DialogFrame,
        })
        local DialogScale = New("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, Library.TweenInfo, {
            Scale = 1
        }):Play()
        local _InnerPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 10),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 4),
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = HeaderContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        if Info.Icon then
            local ParsedIcon = Library:GetCustomIcon(Info.Icon)
            if ParsedIcon then
                local IconImg = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    Image = ParsedIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    LayoutOrder = 1,
                    ZIndex = Library.DialogContentZIndex + 2,
                    Parent = TitleRow,
                })
                if Info.TitleColor then
                    IconImg.ImageColor3 = Info.TitleColor
                end
            end
        end

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = TitleRow,
        })
        if Info.TitleColor then
            TitleLabel.TextColor3 = Info.TitleColor
        end

        local DescriptionLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = HeaderContainer,
        })
        if Info.DescriptionColor then
            DescriptionLabel.TextColor3 = Info.DescriptionColor
        end

        DialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 0),
            Parent = DialogContainer,
        })

        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = InnerContainer,
        })

        local AlignMap = {
            Left = Enum.HorizontalAlignment.Left,
            Center = Enum.HorizontalAlignment.Center,
            Right = Enum.HorizontalAlignment.Right,
        }
        local ButtonsHorizontalAlignment = AlignMap[Info.ButtonsAlignment] or Enum.HorizontalAlignment.Right

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = Library.DialogContentZIndex + 2,
            Parent = InnerContainer,
        })
        local ButtonsLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = ButtonsHorizontalAlignment,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 0),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Elements = {},
            Container = DialogContainer,
            OutsideClickDismiss = Info.OutsideClickDismiss,
        }

        function Dialog:Resize()
            local MaxWidth = MainFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in FooterButtonsList do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8) + 30
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)

            local _DescX, DescY = Library:GetTextBounds(DescriptionLabel.Text, Library.Scheme.Font, 14, TargetWidth - 30)
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in DialogContainer:GetChildren() do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end
            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons
        end

        DialogContainer.ChildAdded:Connect(function(Child)
            task.defer(function()
                if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
                    DialogContainer.Visible = true
                end
            end)
        end)

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:SetButtonsAlignment(Alignment)
            if AlignMap[Alignment] then
                ButtonsLayout.HorizontalAlignment = AlignMap[Alignment]
            end
        end

        function Dialog:Dismiss()
            Library.ActiveDialog = nil
            local CloseTween = TweenService:Create(DialogScale, Library.TweenInfo, { Scale = 0.95 })
            TweenService:Create(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            CloseTween:Play()

            task.delay(Library.TweenInfo.Time, function()
                DialogOverlay:Destroy()
            end)
            Library.Dialogues[Idx] = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
                Dialog:Resize()
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0

            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = Library.DialogContentZIndex + 2,
                Parent = ButtonsHolder,
            })

            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"

            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                ClipsDescendants = true,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = Library.DialogContentZIndex + 2,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = TextBtn
                })
            )

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]

            local ProgressBar
            if WaitTime > 0 then

                TextBtn.BackgroundColor3 = Library:GetDarkerColor(ActiveColor)

                ProgressBar = New("Frame", {
                    BackgroundColor3 = ActiveColor,
                    BorderSizePixel = 0,
                    Position = UDim2.fromScale(0, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = TextBtn.ZIndex,
                    Parent = TextBtn,
                })

                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius),
                        Parent = ProgressBar,
                    })
                )
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Text or ButtonInfo.Title or tostring(ButtonIdx),
                TextColor3 = TextColor,
                TextSize = 14,
                ZIndex = (ProgressBar and ProgressBar.ZIndex or TextBtn.ZIndex) + 1,
                Parent = TextBtn,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = BtnLabel,
            })

            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end
                end
            }

            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 1, 0)
                }):Play()

                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)
                    if ProgressBar then

                        TextBtn.BackgroundColor3 = ActiveColor
                        TweenService:Create(ProgressBar, Library.TweenInfo, {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
            Dialog:Resize()
        end

        local InitialButtons = Info.Buttons or Info.FooterButtons or {}
        for BIdx, BInfo in InitialButtons do
            if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
            Dialog:AddFooterButton(BIdx, BInfo)
        end

        setmetatable(Dialog, BaseSection)
        Library.Dialogues[Idx] = Dialog

        Dialog:Resize()

        Library.ActiveDialog = Dialog
        return Dialog
    end

    local GuiProperties = { "BackgroundTransparency" }
    local ImageProperties = { "BackgroundTransparency", "ImageTransparency" }
    local TextProperties = { "BackgroundTransparency", "TextTransparency" }
    local StrokeProperties = { "Transparency" }

    local function FadeInstance(Desc, Properties)
        local Cache = TransparencyCache[Desc]
        if not Cache then
            Cache = {}
            TransparencyCache[Desc] = Cache
        end

        for _, Prop in Properties do
            if not Library.Toggled then
                Cache[Prop] = Desc[Prop]
            end

            if Cache[Prop] ~= nil and Cache[Prop] ~= 1 then
                TweenService:Create(Desc, Library.WindowAnimationInfo, {
                    [Prop] = Library.Toggled and Cache[Prop] or 1,
                }):Play()
            end
        end
    end

    local Fading = false

    function Window:Toggle(Value: boolean?)
        if Fading then
            return
        end

        if Library.ActiveLoading then
            if Value == true then
                return
            end

            if not Library.Toggled then
                return
            end
        end

        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        Library:UpdatePoppedSections()

        if Library.Animations and Library.Animations.ToggleWindow == true then
            local FadeTime = Library.WindowAnimationInfo.Time
            Fading = true

            if Library.Toggled then
                MainFrame.Visible = true
            end

            if Library.Toggled then
                FadeInstance(MainFrame, { "BackgroundTransparency" })
                task.wait(FadeTime / 2)
            else
                task.delay(FadeTime / 2, FadeInstance, MainFrame, { "BackgroundTransparency" })
            end

            for _, Instance in MainFrame:GetDescendants() do
                if Instance.Name == "TopBar" and Instance.Parent == MainFrame then
                    continue
                end

                if Instance:IsA("GuiObject") then
                    local ClassName = Instance.ClassName
                    if ClassName == "ImageLabel" or ClassName == "ImageButton" then
                        FadeInstance(Instance, ImageProperties)
                    elseif ClassName == "TextLabel" or ClassName == "TextBox" or ClassName == "TextButton" then
                        FadeInstance(Instance, TextProperties)
                    else
                        FadeInstance(Instance, GuiProperties)
                    end
                elseif Instance.ClassName == "UIStroke" then
                    FadeInstance(Instance, StrokeProperties)
                end
            end

            task.delay(FadeTime, function()
                MainFrame.Visible = Library.Toggled
                Fading = false
            end)
        else
            MainFrame.Visible = Library.Toggled
        end

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            Library.OriginalMouseIconEnabled = UserInputService.MouseIconEnabled

            pcall(function()
                RunService:UnbindFromRenderStep(Library.ShowCursorBinding)
            end)
            RunService:BindToRenderStep(Library.ShowCursorBinding, Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor and not CustomImageEnabled
                CursorV.Visible = Library.ShowCustomCursor and not CustomImageEnabled

                CursorCustomImage.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                CursorCustomImage.Visible = Library.ShowCustomCursor and CustomImageEnabled

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    RestoreMouseIcon()
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false

            for _, Option in Library.Options do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    function Library:Toggle(Value: boolean?)

        if Library.BubbleWantedOnStart and not Library.Bubble and Library.ToggleBubble then
            Library:ToggleBubble(true)
        end

        return Window:Toggle(Value)
    end

    if WindowInfo.EnableSidebarResize then
        local MinWidth = 128
        local Threshold = (MinWidth + CompactWidth) * 0.5
        local StartPos, StartWidth
        local Dragging = false
        local Changed

        local SidebarGrabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(Window:GetSidebarWidth(), 0),
            Size = UDim2.new(0, 8, 1, -21),
            Text = "",
            ZIndex = DividerLine.ZIndex + 1,
            Parent = MainFrame,
        })
        SidebarGrabberRef = SidebarGrabber
        SidebarGrabber.MouseEnter:Connect(function()
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
        end)
        SidebarGrabber.MouseLeave:Connect(function()
            if Dragging then
                return
            end
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            }):Play()
        end)

        SidebarGrabber.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) then
                return
            end

            Library.CantDragForced = true

            StartPos = Input.Position
            StartWidth = Window:GetSidebarWidth()
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Library.CantDragForced = false
                TweenService:Create(DividerLine, Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                }):Play()

                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end

                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local Width = StartWidth + Delta.X

                if Width > Threshold then
                    Window:SetSidebarWidth(math.max(Width, MinWidth))
                else
                    Window:SetSidebarWidth(CompactWidth)
                end
            end
        end))
    end
    if WindowInfo.SidebarCompacted then
        task.spawn(function()
            Window:SetSidebarWidth(CompactWidth)
        end)
    end

    Library.AutoShow = WindowInfo.AutoShow

    do
        local BubbleEnabled = WindowInfo.Bubble
        if BubbleEnabled == nil then
            BubbleEnabled = Library.IsMobile
        end
        Library.BubbleWantedOnStart = BubbleEnabled
    end

    do

        local function CreateBubble()
            local BubbleSizeInfo = WindowInfo.BubbleSize
            local BaseWidth, BaseHeight = BubbleSizeInfo.X.Offset, BubbleSizeInfo.Y.Offset
            local Padding = WindowInfo.BubblePadding
            local StartSide = (WindowInfo.BubbleSide == "Left") and "Left" or "Right"

            local ScaleFactor = math.max(Library.DPIScale or 1, 0.001)
            local Width, Height = BaseWidth, BaseHeight
            local RenderedWidth, RenderedHeight = BaseWidth * ScaleFactor, BaseHeight * ScaleFactor

            local Bubble = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = WindowInfo.BubbleColor or "MainColor",
                BorderSizePixel = 0,
                Text = "",
                Size = BubbleSizeInfo,
                Position = UDim2.new(
                    StartSide == "Right" and 1 or 0,
                    StartSide == "Right" and -RenderedWidth or 0,
                    0.5, -RenderedHeight / 2
                ),
                ZIndex = Library.BubbleZIndex,
                Parent = ScreenGui,
            })
            Library:AddToRegistry(Bubble, { BackgroundColor3 = WindowInfo.BubbleColor or "MainColor" })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.BubbleCornerRadius),
                    Parent = Bubble,
                })
            )

            local BubbleScale = New("UIScale", {
                Scale = math.max(Library.DPIScale or 1, 0.001),
                Parent = Bubble,
            })
            table.insert(Library.Scales, BubbleScale)
            Library.Bubble = Bubble
            Library.BubbleScale = BubbleScale

            Library:AddOutline(Bubble)

            local IconSize = UDim2.fromOffset(
                math.max(Width - Padding * 2, 4),
                math.max(Height - Padding * 2, 4)
            )
            local CustomIcon = WindowInfo.BubbleIcon and Library:GetCustomIcon(WindowInfo.BubbleIcon)

            if CustomIcon then
                local BubbleIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = CustomIcon.Url,
                    ImageColor3 = WindowInfo.BubbleIconColor or "AccentColor",
                    ImageRectOffset = CustomIcon.ImageRectOffset,
                    ImageRectSize = CustomIcon.ImageRectSize,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = IconSize,
                    ZIndex = Library.BubbleZIndex + 1,
                    Parent = Bubble,
                })
                Library:AddToRegistry(BubbleIcon, { ImageColor3 = WindowInfo.BubbleIconColor or "AccentColor" })
            else
                local BubbleLabel = New("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = IconSize,
                    Text = WindowInfo.Title:sub(1, 1),
                    TextColor3 = WindowInfo.BubbleIconColor or "AccentColor",
                    TextScaled = true,
                    ZIndex = Library.BubbleZIndex + 1,
                    Parent = Bubble,
                })
                Library:AddToRegistry(BubbleLabel, { TextColor3 = WindowInfo.BubbleIconColor or "AccentColor" })
            end

            local SnapTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

            if Library.BubbleRelativeY == nil then
                Library.BubbleRelativeY = 0.5
            end

            local function GetAvailableY(RenderedHeight: number): number
                local ScreenSize = ScreenGui.AbsoluteSize
                return math.max(0, ScreenSize.Y - RenderedHeight)
            end

            local function SnapToSide(ToSide: string, PreserveRelativeY: boolean?)

                local RenderedHeight = Bubble.AbsoluteSize.Y
                local RenderedWidth = Bubble.AbsoluteSize.X
                local AvailableY = GetAvailableY(RenderedHeight)

                local ClampedY
                if PreserveRelativeY then

                    ClampedY = AvailableY * math.clamp(Library.BubbleRelativeY, 0, 1)
                else
                    local Y = Bubble.AbsolutePosition.Y
                    ClampedY = math.clamp(Y, 0, AvailableY)
                    Library.BubbleRelativeY = (AvailableY > 0) and (ClampedY / AvailableY) or 0.5
                end

                local TargetPos
                if ToSide == "Right" then
                    TargetPos = UDim2.new(1, -RenderedWidth, 0, ClampedY)
                else
                    TargetPos = UDim2.new(0, 0, 0, ClampedY)
                end

                Library.BubbleSide = ToSide
                TweenService:Create(Bubble, SnapTweenInfo, { Position = TargetPos }):Play()
            end

            Library.SnapBubbleToSide = SnapToSide
            Library.BubbleSide = StartSide

            local StartInputPos, StartPos
            local Dragging = false
            local Moved = false
            local Changed

            Bubble.InputBegan:Connect(function(Input: InputObject)
                if not IsClickInput(Input) then
                    return
                end

                StartInputPos = Input.Position
                StartPos = Bubble.Position
                Dragging = true
                Moved = false

                Changed = Input.Changed:Connect(function()
                    if Input.UserInputState ~= Enum.UserInputState.End then
                        return
                    end

                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    if Moved then
                        local ScreenSize = ScreenGui.AbsoluteSize
                        local CenterX = Bubble.AbsolutePosition.X + (Bubble.AbsoluteSize.X / 2)

                        SnapToSide(CenterX < (ScreenSize.X / 2) and "Left" or "Right")
                    else
                        Library:Toggle()
                    end
                end)
            end)

            Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
                if not (ScreenGui and ScreenGui.Parent) then
                    Dragging = false
                    if Changed and Changed.Connected then
                        Changed:Disconnect()
                        Changed = nil
                    end

                    return
                end

                if Dragging and IsHoverInput(Input) then
                    local Delta = Input.Position - StartInputPos

                    if not Moved and Delta.Magnitude > 5 then
                        Moved = true
                    end

                    Bubble.Position = UDim2.new(
                        StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                        StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                    )
                end
            end))

            Library.Bubble = Bubble
            return Bubble
        end

        function Library:ToggleBubble(Value: boolean?)
            if Value == nil then
                Value = not (Library.Bubble ~= nil and Library.Bubble.Visible)
            end

            if Value then
                if Library.Bubble then
                    Library.Bubble.Visible = true
                else

                    if Library.AutoDPIScale then
                        Library.BaseScale = Library:CalculateAutoBaseScale()
                    end
                    Library:SetDPIScale(Library.UIScaleValue or 5)

                    CreateBubble()
                end
            else
                if Library.Bubble then
                    Library.Bubble.Visible = false
                end
            end

            return Value
        end

    end

    if WindowInfo.AutoShow and not Library.ActiveLoading and not Library.DeferAutoShowTo then
        task.spawn(Library.Toggle)
    end

    Window:SetAlwaysOnTop(WindowInfo.AlwaysOnTop)

    if not WindowInfo.AutoShow and not Library.DeferAutoShowTo
        and Library.BubbleWantedOnStart and not Library.Bubble and Library.ToggleBubble then
        task.spawn(function()
            Library:ToggleBubble(true)
        end)
    end

    do

        local SearchOverlay = New("Frame", {
            BackgroundColor3 = "MainColor",
            BorderSizePixel = 0,
            Size = UDim2.new(0, 300, 0, 400),
            Visible = false,
            Active = true, --// swallow clicks so they don't reach elements underneath \\--
            ZIndex = Library.SearchOverlayZIndex,

            Parent = MainFrame,
        })
        Library:AddToRegistry(SearchOverlay, { BackgroundColor3 = "MainColor" })
        Library:AddStyleRoot(SearchOverlay)

        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = SearchOverlay,
        })

        local OverlayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchOverlay,
        })
        Library:AddToRegistry(OverlayStroke, { Color = "OutlineColor" })

        local ScrollFrame = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromScale(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = "OutlineColor",
            ZIndex = Library.SearchOverlayZIndex + 1,
            Parent = SearchOverlay,
        })
        Library:AddToRegistry(ScrollFrame, { ScrollBarImageColor3 = "OutlineColor" })
        Library:AddCustomScrollbar(ScrollFrame)

        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = ScrollFrame,
        })

        New("UIPadding", {
            PaddingTop    = UDim.new(0, 0),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft   = UDim.new(0, 6),
            PaddingRight  = UDim.new(0, 6),
            Parent = ScrollFrame,
        })

        New("UIListLayout", {
            Padding   = UDim.new(0, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent    = ScrollFrame,
        })

        local CloseOverlay

        local function NavigateTo(Tab, Section, ElementInfo, TargetSubSection)
            if CloseOverlay then CloseOverlay() end
            SearchBox.Text = ""
            SearchBox:ReleaseFocus()

            if Tab and Tab.Show then
                Tab:Show()
            end

            if Section and Section.Show and not Section.BoxHolder then
                Section:Show()
            end

            task.spawn(function()
                task.wait()

                if Section and Section.SetFolded and Section.Folded then
                    Section:SetFolded(false)
                    task.wait()
                end

                local function UnfoldSubSections(Box)
                    if not Box or not Box.SubSections then return end
                    for _, SubSection in Box.SubSections do
                        if SubSection.SetFolded and SubSection.Folded then
                            SubSection:SetFolded(false)
                        end
                        UnfoldSubSections(SubSection)
                    end
                end
                if ElementInfo or TargetSubSection then
                    UnfoldSubSections(Section)
                    task.wait()
                end

                local ScrollTarget = (ElementInfo and ElementInfo.Holder)
                    or (TargetSubSection and (TargetSubSection.HeaderHolder or TargetSubSection.Holder))
                    or (Section and Section.BoxHolder)
                    or (Section and Section.Container)
                local IsPreciseTarget = (ElementInfo and ElementInfo.Holder) or (TargetSubSection and TargetSubSection.Holder)
                if ScrollTarget then
                    local Col = ScrollTarget.Parent

                    while Col and not Col:IsA("ScrollingFrame") do
                        Col = Col.Parent
                    end
                    if Col and Col:IsA("ScrollingFrame") then
                        local RelY = ScrollTarget.AbsolutePosition.Y - Col.AbsolutePosition.Y + Col.CanvasPosition.Y

                        local FullCenterOffset = Col.AbsoluteSize.Y / 2 - ScrollTarget.AbsoluteSize.Y / 2
                        local TargetOffset = IsPreciseTarget and math.min(FullCenterOffset, RelY) or 10
                        Col.CanvasPosition = Vector2.new(0, math.max(0, RelY - TargetOffset))
                    end
                end

                task.wait()
                task.wait()

                local function FlashTarget(TargetInst, ExpandX, ExpandY)
                    if not (TargetInst and TargetInst.Parent) then return end

                    --// The ring is built in the window's scaled space, so the true
                    --// rendered scale matters. Prefer the measured ratio over the
                    --// UIScale bookkeeping: on mobile the two can disagree, which
                    --// shifted/scaled the ring away from the element. \\--
                    local function EffectiveScale(): number
                        local UiScale = MainFrame:FindFirstChildOfClass("UIScale") or Library.MainWindowScale
                        local Scale = (UiScale and UiScale.Scale) or Library.DPIScale or 1

                        local SizeX = MainFrame.Size.X
                        if SizeX.Scale == 0 and SizeX.Offset > 0 then
                            local Measured = MainFrame.AbsoluteSize.X / SizeX.Offset
                            if Measured > 0 then
                                Scale = Measured
                            end
                        end

                        return math.max(Scale, 0.0001)
                    end

                    local MainScaleFactor = EffectiveScale()
                    local Scroller = TargetInst:FindFirstAncestorOfClass("ScrollingFrame")

                    --// Window-space frame, re-anchored on scroll. Parenting the
                    --// flash inside the ScrollingFrame was clipped away in
                    --// practice, and window clamping already keeps tall targets
                    --// inside MainFrame. \\--
                    local function Compute()
                        local AbsPos     = TargetInst.AbsolutePosition
                        local AbsSize    = TargetInst.AbsoluteSize
                        local MainAbsPos = MainFrame.AbsolutePosition
                        local MainAbsSize = MainFrame.AbsoluteSize

                        --// Convert to the window's units first, then expand. Doing
                        --// the expansion in screen pixels made the ring grow out of
                        --// proportion whenever the UI is scaled (mobile ~0.5-0.8). \\--
                        local RelX  = (AbsPos.X - MainAbsPos.X) / MainScaleFactor - ExpandX
                        local RelY  = (AbsPos.Y - MainAbsPos.Y) / MainScaleFactor - ExpandY
                        local SizeX = AbsSize.X / MainScaleFactor + ExpandX * 2
                        local SizeY = AbsSize.Y / MainScaleFactor + ExpandY * 2

                        --// Snap the ring to whole device pixels. A half-pixel edge
                        --// antialiases into a washed-out line (the "pale top border"
                        --// seen on phones), while the other edges look solid. \\--
                        local DevX0 = math.floor(MainAbsPos.X + RelX * MainScaleFactor + 0.5)
                        local DevY0 = math.floor(MainAbsPos.Y + RelY * MainScaleFactor + 0.5)
                        local DevX1 = math.floor(MainAbsPos.X + (RelX + SizeX) * MainScaleFactor + 0.5)
                        local DevY1 = math.floor(MainAbsPos.Y + (RelY + SizeY) * MainScaleFactor + 0.5)
                        RelX  = (DevX0 - MainAbsPos.X) / MainScaleFactor
                        RelY  = (DevY0 - MainAbsPos.Y) / MainScaleFactor
                        SizeX = (DevX1 - DevX0) / MainScaleFactor
                        SizeY = (DevY1 - DevY0) / MainScaleFactor

                        local MaxX = MainAbsSize.X / MainScaleFactor
                        local MaxY = MainAbsSize.Y / MainScaleFactor
                        local ClampX0 = math.max(RelX, 0)
                        local ClampY0 = math.max(RelY, 0)
                        local ClampX1 = math.min(RelX + SizeX, MaxX)
                        local ClampY1 = math.min(RelY + SizeY, MaxY)
                        if ClampX1 - ClampX0 < 4 or ClampY1 - ClampY0 < 4 then
                            return nil
                        end

                        return ClampX0, ClampY0, ClampX1 - ClampX0, ClampY1 - ClampY0
                    end

                    local RelX, RelY, SizeX, SizeY = Compute()
                    if not RelX then return end

                    local FlashOutline = New("Frame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(RelX, RelY),
                        Size = UDim2.fromOffset(SizeX, SizeY),
                        ClipsDescendants = true,

                        --// Above every content/overlay-menu band, but one below the
                        --// search overlay so the ring never paints over it. \\--
                        ZIndex = (Library.SearchOverlayZIndex or Library.TooltipZIndex) - 1,
                        Parent = MainFrame,
                    })
                    local FlashStroke = New("UIStroke", {
                        Color = Library.Scheme and Library.Scheme.AccentColor or Color3.fromRGB(100, 180, 255),
                        --// Keep the ring readable on scaled UIs: 2px of source
                        --// thickness, never less than 2 rendered pixels. \\--
                        Thickness = math.max(2 / MainScaleFactor, 2),
                        Transparency = 0,
                        Parent = FlashOutline,
                    })
                    New("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = FlashOutline,
                    })

                    local ScrollConnection
                    if Scroller then
                        ScrollConnection = Scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                            if not (FlashOutline.Parent and TargetInst.Parent) then
                                return
                            end

                            --// Hide once the element leaves the visible window;
                            --// otherwise recompute so the outline travels with
                            --// the content instead of staying behind. \\--
                            local Pos, Size = TargetInst.AbsolutePosition, TargetInst.AbsoluteSize
                            local SPos, SSize = Scroller.AbsolutePosition, Scroller.AbsoluteSize
                            local InView = Pos.X + Size.X > SPos.X and Pos.X < SPos.X + SSize.X
                                and Pos.Y + Size.Y > SPos.Y and Pos.Y < SPos.Y + SSize.Y

                            local X, Y, W, H = Compute()
                            if not InView or not X then
                                FlashOutline.Visible = false
                                return
                            end

                            FlashOutline.Position = UDim2.fromOffset(X, Y)
                            FlashOutline.Size = UDim2.fromOffset(W, H)
                            FlashOutline.Visible = true
                        end)
                        Library:GiveSignal(ScrollConnection)
                    end

                    task.delay(0.8, function()
                        if FlashStroke and FlashStroke.Parent then
                            TweenService:Create(FlashStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Transparency = 1,
                            }):Play()
                            task.delay(0.55, function()
                                if ScrollConnection then
                                    ScrollConnection:Disconnect()
                                end
                                if FlashOutline and FlashOutline.Parent then
                                    FlashOutline:Destroy()
                                end
                            end)
                        end
                    end)
                end

                if ElementInfo and ElementInfo.Holder and ElementInfo.Holder.Parent then
                    local IsButton   = ElementInfo.Type == "Button" or ElementInfo.Type == "SubButton"
                    local TargetInst = (IsButton and ElementInfo.Base) or ElementInfo.Holder

                    local ExpandX    = IsButton and 0 or 10
                    local ExpandY    = IsButton and 0 or 4
                    FlashTarget(TargetInst, ExpandX, ExpandY)
                elseif TargetSubSection and TargetSubSection.HeaderHolder and TargetSubSection.HeaderHolder.Parent then

                    FlashTarget(TargetSubSection.HeaderHolder, 0, 0)
                elseif TargetSubSection and TargetSubSection.Holder and TargetSubSection.Holder.Parent then
                    FlashTarget(TargetSubSection.Holder, 0, 0)
                elseif Section and Section.BoxHolder and Section.BoxHolder.Parent then
                    FlashTarget(Section.BoxHolder, 0, -8)
                elseif Section and Section.Container and Section.Container.Parent then
                    FlashTarget(Section.Container, 0, -8)
                end
            end)
        end

        local RowH   = 24
        local Indent = 16

        local function CollectElements(Box, Search, SectionMatches, Filtering, Out, Depth)
            Depth = Depth or 1

            for _, Info in Box.Elements do
                if Info.Type == "Divider" then continue end
                local EText = Info.Text
                if not EText or not Info.Visible then continue end

                if not Filtering or SectionMatches or TryFuzzyMatch(EText, Search) then
                    table.insert(Out, { Text = EText, Info = Info, ElType = Info.Type, Depth = Depth })
                end

                if Info.SubButton and Info.SubButton.Text and Info.SubButton.Visible then
                    local SubText = Info.SubButton.Text
                    if not Filtering or SectionMatches or TryFuzzyMatch(SubText, Search) then

                        table.insert(Out, { Text = SubText, Info = Info.SubButton, ElType = "SubButton", Depth = Depth })
                    end
                end
            end

            if Box.ConditionalGroups then
                for _, ConditionalGroup in Box.ConditionalGroups do
                    if not ConditionalGroup.Visible then
                        continue
                    end

                    CollectElements(ConditionalGroup, Search, SectionMatches, Filtering, Out, Depth)
                end
            end

            if Box.SubSections then

                for _, SubSection in Box.SubSections do
                    local SubMatches = SectionMatches or (Filtering and SubSection.Name and TryFuzzyMatch(SubSection.Name, Search))
                    local SubOut = {}
                    CollectElements(SubSection, Search, SubMatches, Filtering, SubOut, Depth + 1)

                    if SubMatches or #SubOut > 0 then
                        table.insert(Out, {
                            Text        = SubSection.Name or "SubSection",
                            IsSubSection = true,
                            SubSection  = SubSection,
                            Depth       = Depth,
                        })
                        for _, SubEntry in SubOut do
                            table.insert(Out, SubEntry)
                        end
                    end
                end
            end
        end

        --// Rebuild-scoped caches: fonts + accent hex are identical for every
        --// row, so compute once per rebuild instead of per row. \\--
        local RebuildTabFont, RebuildRowFont, RebuildAccentHex = nil, nil, nil
        local RowHoverTween = TweenInfo.new(0.08)

        local function EscapeRichText(Value: string): string
            local Str = tostring(Value)
            if not Str:find("[<>&]", 1) then
                return Str
            end
            return (Str:gsub("[<>&]", { ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;" }))
        end

        --// Wraps the query's match in accent + bold. The query is spaceless
        --// (normalized), so match against spaceless text and map back. \\--
        local function HighlightMatch(Text: string, Query: string, Lower: string?): string
            --// Fast path: plain substring (covers single-word queries, the
            --// common case) without building the spaceless map. \\--
            Lower = Lower or LowerCached(Text)
            local PlainS, PlainE = Lower:find(Query, 1, true)
            if PlainS then
                --// Accent colour is the only reliable emphasis here: an explicit
                --// FontFace on the row makes <b> a no-op. Matches the arrow,
                --// badges and slider fill. \\--
                local Hex = RebuildAccentHex or "#FFFFFF"
                return EscapeRichText(Text:sub(1, PlainS - 1))
                    .. string.format('<font color="%s"><b>%s</b></font>', Hex, EscapeRichText(Text:sub(PlainS, PlainE)))
                    .. EscapeRichText(Text:sub(PlainE + 1))
            end

            local Stripped, Map = {}, {}
            for i = 1, #Lower do
                local Ch = Lower:sub(i, i)
                if not Ch:match("%s") then
                    table.insert(Stripped, Ch)
                    table.insert(Map, i)
                end
            end

            local S, E = table.concat(Stripped):find(Query, 1, true)
            if not S then
                return EscapeRichText(Text)
            end

            local OrigStart, OrigEnd = Map[S], Map[E]
            local Hex = RebuildAccentHex or "#FFFFFF"

            return EscapeRichText(Text:sub(1, OrigStart - 1))
                .. string.format('<font color="%s"><b>%s</b></font>', Hex, EscapeRichText(Text:sub(OrigStart, OrigEnd)))
                .. EscapeRichText(Text:sub(OrigEnd + 1))
        end

        --// Legacy non-virtualized row builder (kept unused; virtualization below). \\--
        local function MakeRowLegacy(Cfg, Order)
            local Depth = Cfg.Depth or 0
            local Z     = 12002

            local Btn = New("TextButton", {
                BackgroundColor3       = "MainColor",
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, RowH),
                Text                   = "",
                LayoutOrder            = Order,
                ZIndex                 = Z,
                Parent                 = ScrollFrame,
            })
            Library:AddToRegistry(Btn, { BackgroundColor3 = "MainColor" })
            New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })

            if Depth > 0 then
                for D = 1, Depth do
                    local LineX       = (D - 1) * Indent + 5
                    local IsDeepest   = (D == Depth)
                    local Terminating = IsDeepest and (Cfg.IsLast or false)

                    local VLine = New("Frame", {
                        BackgroundColor3 = "OutlineColor",
                        BorderSizePixel  = 0,
                        Position = UDim2.new(0, LineX, 0, 0),
                        Size     = UDim2.new(0, 1, 0, Terminating and RowH / 2 or RowH),
                        ZIndex   = Z + 1,
                        Parent   = Btn,
                    })
                    Library:AddToRegistry(VLine, { BackgroundColor3 = "OutlineColor" })

                    if IsDeepest then
                        local HLine = New("Frame", {
                            BackgroundColor3 = "OutlineColor",
                            BorderSizePixel  = 0,
                            Position = UDim2.new(0, LineX, 0, RowH / 2 - 1),
                            Size     = UDim2.new(0, Indent - 2, 0, 1),
                            ZIndex   = Z + 1,
                            Parent   = Btn,
                        })
                        Library:AddToRegistry(HLine, { BackgroundColor3 = "OutlineColor" })
                    end
                end
            end

            local TextX  = Depth * Indent + (Depth > 0 and 2 or 0)
            local BadgeW = 0

            local BadgeText, BadgeShadeStep
            local RowTextColorFn = nil

            if Cfg.IsTab then
                RowTextColorFn = function() return Library:GetAccentShade(1) end
            elseif Cfg.IsSection then
                RowTextColorFn = function() return Library:GetAccentShade(2) end
            elseif Cfg.IsSubSection then
                RowTextColorFn = function() return Library:GetAccentShade(1) end
            elseif Cfg.IsElement and Cfg.ElementType then
                local TypeLabels = {
                    Button = "BTN", Toggle = "TGL", Slider = "SLD",
                    Dropdown = "DROP", ColorPicker = "CLR", Input = "TXT",
                    Label = "LBL", KeyPicker = "KEY", SubButton = "SUB",
                    Checkbox = "CHK", ProgressBar = "PRG", Viewport = "VPT",
                    Image = "IMG", Video = "VID",
                }

                BadgeShadeStep = (Order % 2 == 0) and 2 or 1
                BadgeText = TypeLabels[Cfg.ElementType] or Cfg.ElementType:upper():sub(1, 4)
            end

            if BadgeText then
                BadgeW = 34

                local ShadeFn = function() return Library:GetAccentShade(BadgeShadeStep) end

                local Badge = New("Frame", {
                    BackgroundColor3       = ShadeFn,
                    BackgroundTransparency = 0,
                    BorderSizePixel        = 0,
                    Position = UDim2.new(1, -(BadgeW + 4), 0.5, -8),
                    Size     = UDim2.new(0, BadgeW, 0, 16),
                    ZIndex   = Z + 2,
                    Parent   = Btn,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Badge })
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size           = UDim2.fromScale(1, 1),
                    Text           = BadgeText,
                    TextColor3     = Color3.new(1, 1, 1),
                    TextSize       = 9,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Font           = Enum.Font.GothamBold,
                    ZIndex         = Z + 3,
                    Parent         = Badge,
                })
            end

            local LblFont
            if Cfg.IsTab then
                LblFont = RebuildTabFont
                if not LblFont then
                    local Base = Font.fromEnum(Enum.Font.GothamBold)
                    LblFont = Font.new(Base.Family, Enum.FontWeight.Heavy, Base.Style)
                end
            else
                LblFont = RebuildRowFont
                if not LblFont then
                    LblFont = Font.fromEnum(Enum.Font.GothamMedium)
                end
            end
            local LblTextSize = Cfg.IsTab and 13 or 12

            local LblText = Cfg.Text
            if Cfg.Highlight and Cfg.Highlight ~= "" then
                LblText = HighlightMatch(Cfg.Text, Cfg.Highlight)
            else
                LblText = EscapeRichText(Cfg.Text)
            end

            local Lbl = New("TextLabel", {
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, TextX, 0, 0),
                Size           = UDim2.new(1, -(TextX + (BadgeW > 0 and BadgeW + 8 or 0)), 1, 0),
                Text           = LblText,
                RichText       = true,
                TextColor3     = RowTextColorFn or "FontColor",
                TextSize       = LblTextSize,
                FontFace       = LblFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = Cfg.IsTab and 0 or (Cfg.IsElement and 0.35 or 0.1),
                TextTruncate   = Enum.TextTruncate.AtEnd,
                ZIndex         = Z + 1,
                Parent         = Btn,
            })

            Btn.MouseEnter:Connect(function()
                TweenService:Create(Btn, RowHoverTween, { BackgroundTransparency = 0.82 }):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Btn, RowHoverTween, { BackgroundTransparency = 1 }):Play()
            end)

            if Cfg.OnActivate then
                Btn.MouseButton1Click:Connect(Cfg.OnActivate)
            end

            return Btn
        end

        --// Virtualized results: RowData holds ALL matches (cheap tables);
        --// only the visible window (+overscan) gets real instances. \\--
        local RowData         = {}
        local RowPool         = {}
        local BuildGeneration = 0
        local ActiveRows      = RowPool --// legacy alias; pooled buttons live here \\--

        local TypeLabels = {
            Button = "BTN", Toggle = "TGL", Slider = "SLD",
            Dropdown = "DROP", ColorPicker = "CLR", Input = "TXT",
            Label = "LBL", KeyPicker = "KEY", SubButton = "SUB",
            Checkbox = "CHK", ProgressBar = "PRG", Viewport = "VPT",
            Image = "IMG", Video = "VID",
        }

        local MaxDepthLines = 6
        local Overscan = 8
        local LastRenderFirst, LastRenderLast, LastRenderTotal = nil, nil, nil

        local function BuildDisplayText(TextValue: string, Highlight: string?, Lower: string?): string
            if Highlight and Highlight ~= "" then
                return HighlightMatch(TextValue, Highlight, Lower)
            end
            return EscapeRichText(TextValue)
        end

        local function CreatePooledRow()
            local Z = 12002

            local Btn = New("TextButton", {
                BackgroundColor3       = "MainColor",
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, RowH),
                Text                   = "",
                AutoButtonColor        = false,
                ZIndex                 = Z,
                Visible                = false,
                Parent                 = ScrollFrame,
            })
            Library:AddToRegistry(Btn, { BackgroundColor3 = "MainColor" })
            New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })

            local VLines = {}
            for _ = 1, MaxDepthLines do
                local VLine = New("Frame", {
                    BackgroundColor3 = "OutlineColor",
                    BorderSizePixel  = 0,
                    Size     = UDim2.new(0, 1, 0, RowH),
                    ZIndex   = Z + 1,
                    Visible  = false,
                    Parent   = Btn,
                })
                Library:AddToRegistry(VLine, { BackgroundColor3 = "OutlineColor" })
                table.insert(VLines, VLine)
            end

            local HLine = New("Frame", {
                BackgroundColor3 = "OutlineColor",
                BorderSizePixel  = 0,
                Size     = UDim2.new(0, Indent - 2, 0, 1),
                ZIndex   = Z + 1,
                Visible  = false,
                Parent   = Btn,
            })
            Library:AddToRegistry(HLine, { BackgroundColor3 = "OutlineColor" })

            local Badge = New("Frame", {
                BackgroundTransparency = 0,
                BorderSizePixel        = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -4, 0.5, 0),
                Size     = UDim2.new(0, 34, 0, 16),
                ZIndex   = Z + 2,
                Visible  = false,
                Parent   = Btn,
            })
            New("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Badge })
            local BadgeLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size           = UDim2.fromScale(1, 1),
                Text           = "",
                TextColor3     = Color3.new(1, 1, 1),
                TextSize       = 9,
                Font           = Enum.Font.GothamBold,
                ZIndex         = Z + 3,
                Parent         = Badge,
            })

            local Lbl = New("TextLabel", {
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, 0, 1, 0),
                Text           = "",
                RichText       = true,
                TextColor3     = "FontColor",
                TextSize       = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate   = Enum.TextTruncate.AtEnd,
                ClipsDescendants = true,
                ZIndex         = Z + 1,
                Parent         = Btn,
            })

            local Handle = {
                Btn = Btn,
                VLines = VLines,
                HLine = HLine,
                Badge = Badge,
                BadgeLabel = BadgeLabel,
                Lbl = Lbl,
                Data = nil,
                Index = nil,
            }

            Btn.MouseEnter:Connect(function()
                TweenService:Create(Btn, RowHoverTween, { BackgroundTransparency = 0.82 }):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Btn, RowHoverTween, { BackgroundTransparency = 1 }):Play()
            end)
            --// Activate on release, and only for a clean tap. Firing on press made touch-scrolling the
            --// results select whatever row the finger landed on. The row's data is captured on press so a
            --// rebuild that reuses this instance before release still activates the row that was pressed. \\--
            local PressData, PressPos, PressCanvas
            local Dragged = false
            local TapSlop = 10

            local function IsPress(Input: InputObject)
                return Input.UserInputType == Enum.UserInputType.MouseButton1
                    or Input.UserInputType == Enum.UserInputType.Touch
            end

            Btn.InputBegan:Connect(function(Input)
                if not IsPress(Input) then
                    return
                end
                PressData = Handle.Data
                PressPos = Vector2.new(Input.Position.X, Input.Position.Y)
                PressCanvas = ScrollFrame.CanvasPosition
                Dragged = false
            end)

            Btn.InputChanged:Connect(function(Input)
                if PressData and PressPos
                    and (Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseMovement)
                    and (Vector2.new(Input.Position.X, Input.Position.Y) - PressPos).Magnitude > TapSlop then
                    Dragged = true
                end
            end)

            Btn.InputEnded:Connect(function(Input)
                if not IsPress(Input) or not PressData then
                    return
                end

                local Data = PressData
                local Scrolled = PressCanvas and (ScrollFrame.CanvasPosition - PressCanvas).Magnitude > 4
                PressData, PressPos, PressCanvas = nil, nil, nil

                if not Dragged and not Scrolled and Data.OnActivate then
                    task.spawn(Data.OnActivate)
                end
            end)

            table.insert(RowPool, Handle)
            return Handle
        end

        local function ConfigureRow(Handle, Cfg, Index: number)
            Handle.Data = Cfg
            Handle.Index = Index
            local Btn, Lbl = Handle.Btn, Handle.Lbl
            local Depth: number = Cfg.Depth or 0

            Btn.Visible = true
            Btn.Position = UDim2.fromOffset(0, (Index - 1) * RowH)

            for I, VLine in Handle.VLines do
                if I <= Depth then
                    local LineX = (I - 1) * Indent + 5
                    local IsDeepest = (I == Depth)
                    local Terminating = IsDeepest and (Cfg.IsLast or false)
                    VLine.Visible = true
                    VLine.Position = UDim2.new(0, LineX, 0, 0)
                    VLine.Size = UDim2.new(0, 1, 0, Terminating and RowH / 2 or RowH)
                else
                    VLine.Visible = false
                end
            end

            if Depth > 0 then
                local LineX = (Depth - 1) * Indent + 5
                Handle.HLine.Visible = true
                Handle.HLine.Position = UDim2.new(0, LineX, 0, RowH / 2 - 1)
            else
                Handle.HLine.Visible = false
            end

            local TextX = Depth * Indent + (Depth > 0 and 2 or 0)
            local BadgeW = 0

            if Cfg.BadgeText then
                BadgeW = 34
                Handle.Badge.Visible = true
                Handle.BadgeLabel.Text = Cfg.BadgeText
                local Step = Cfg.BadgeShadeStep or 1
                local ShadeFn = function() return Library:GetAccentShade(Step) end
                Library:AddToRegistry(Handle.Badge, { BackgroundColor3 = ShadeFn })
                Handle.Badge.BackgroundColor3 = ShadeFn()
            else
                Handle.Badge.Visible = false
            end

            Lbl.Position = UDim2.new(0, TextX, 0, 0)
            Lbl.Size = UDim2.new(1, -(TextX + (BadgeW > 0 and BadgeW + 8 or 0)), 1, 0)
            Lbl.Text = Cfg.DisplayText or Cfg.Text
            --// Plain rows skip the RichText parser entirely; only match
            --// highlights pay for tag parsing. \\--
            Lbl.RichText = Cfg.HasHighlight == true
            Lbl.FontFace = Cfg.IsTab and RebuildTabFont or RebuildRowFont
            Lbl.TextSize = Cfg.IsTab and 13 or 12
            Lbl.TextTransparency = Cfg.IsTab and 0 or (Cfg.IsElement and 0.35 or 0.1)

            local ColorValue = Cfg.RowColorFn or "FontColor"
            Library:AddToRegistry(Lbl, { TextColor3 = ColorValue })
            if typeof(ColorValue) == "function" then
                Lbl.TextColor3 = ColorValue()
            else
                local Resolved = GetSchemeValue(ColorValue)
                if Resolved then
                    Lbl.TextColor3 = Resolved
                end
            end
        end

        local function RenderVisible(Force: boolean?)
            local Total = #RowData
            if Total == 0 or not SearchOverlay.Visible then
                return
            end

            local ScrollY = ScrollFrame.CanvasPosition.Y
            local ViewH = ScrollFrame.AbsoluteSize.Y
            if ViewH <= 1 then
                ViewH = math.min(400, Total * RowH)
            end

            local First = math.clamp(math.floor(ScrollY / RowH) + 1 - Overscan, 1, Total)
            local Last = math.clamp(math.ceil((ScrollY + ViewH) / RowH) + Overscan, 1, Total)
            if Last < First then
                Last = First
            end

            --// Scroll ticks that don't move the window reuse rows as-is.
            --// Re-assigning RichText every pixel is what made it jitter. \\--
            if not Force and First == LastRenderFirst and Last == LastRenderLast and Total == LastRenderTotal then
                return
            end
            LastRenderFirst, LastRenderLast, LastRenderTotal = First, Last, Total

            local Needed = Last - First + 1
            while #RowPool < Needed do
                CreatePooledRow()
                if #RowPool > 64 then
                    break
                end
            end
            Needed = math.min(Needed, #RowPool)

            --// Rotation reuse: handles already showing an index in the new
            --// window keep it (position is index-derived, so nothing moves).
            --// Only genuinely new edge rows pay ConfigureRow. Scrolling one
            --// row-stride used to re-parse RichText on all ~40 rows. \\--
            local ByIndex = {}
            for _, Handle in RowPool do
                if Handle.Index then
                    ByIndex[Handle.Index] = Handle
                end
            end

            local ShownCount = 0
            local Used = {}
            for DataIndex = First, Last do
                if ShownCount >= #RowPool then
                    break
                end
                local Handle = ByIndex[DataIndex]
                if Handle then
                    Used[Handle] = true
                    Handle.Btn.Visible = true
                else
                    local Free = nil
                    for _, Candidate in RowPool do
                        if not Used[Candidate] and (not Candidate.Index or Candidate.Index < First or Candidate.Index > Last) then
                            Free = Candidate
                            break
                        end
                    end
                    if not Free then
                        for _, Candidate in RowPool do
                            if not Used[Candidate] then
                                Free = Candidate
                                break
                            end
                        end
                    end
                    if Free then
                        if ByIndex[Free.Index] == Free then
                            ByIndex[Free.Index] = nil
                        end
                        ConfigureRow(Free, RowData[DataIndex], DataIndex)
                        Used[Free] = true
                    end
                end
                ShownCount += 1
            end

            for _, Handle in RowPool do
                if not Used[Handle] then
                    Handle.Data = nil
                    Handle.Index = nil
                    Handle.Btn.Visible = false
                end
            end
        end

        local RenderQueued = false
        --// Scroll position changes render synchronously (same frame) so
        --// rows track the thumb; size changes coalesce via defer. \\--
        local function RenderOnScroll()
            if SearchOverlay.Visible and #RowData > 0 then
                RenderVisible(false)
            end
        end
        local function QueueRender()
            if RenderQueued then
                return
            end
            RenderQueued = true
            task.defer(function()
                RenderQueued = false
                if SearchOverlay.Visible and #RowData > 0 then
                    RenderVisible(false)
                end
            end)
        end

        do
            --// UIListLayout fights manual virtualized positioning, so remove
            --// it (it has no Enabled property). Manual offsets + CanvasSize
            --// fully own the layout from here. \\--
            local ListLayout = ScrollFrame:FindFirstChildOfClass("UIListLayout")
            if ListLayout then
                Library:RemoveFromRegistry(ListLayout)
                ListLayout:Destroy()
            end
            ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
            ScrollFrame.CanvasSize = UDim2.fromOffset(0, 0)
            ScrollFrame.CanvasPosition = Vector2.zero
        end
        Library:GiveSignal(ScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(RenderOnScroll))
        Library:GiveSignal(ScrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(QueueRender))

        local function ClearRows()
            table.clear(RowData)
            LastRenderFirst, LastRenderLast, LastRenderTotal = nil, nil, nil
            for _, Handle in RowPool do
                Handle.Data = nil
                Handle.Index = nil
                if Handle.Btn then
                    Handle.Btn.Visible = false
                end
            end
            ScrollFrame.CanvasSize = UDim2.fromOffset(0, 0)
            ScrollFrame.CanvasPosition = Vector2.zero
        end

        local function CloseOverlayImpl()
            SearchOverlay.Visible = false
            ClearRows()
        end
        CloseOverlay = CloseOverlayImpl

        local function RepositionOverlay()
            local ScaleFactor = math.max(Library.DPIScale or 1, 0.0001)

            local SearchAbsPos  = SearchBox.AbsolutePosition
            local SearchAbsSize = SearchBox.AbsoluteSize
            local MainAbsPos    = MainFrame.AbsolutePosition

            local RelativeX = (SearchAbsPos.X - MainAbsPos.X) / ScaleFactor
            local RelativeY = (SearchAbsPos.Y - MainAbsPos.Y) / ScaleFactor
            local BoxWidth  = SearchAbsSize.X / ScaleFactor
            local BoxHeight = SearchAbsSize.Y / ScaleFactor

            local Viewport   = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local MaxHeight  = math.max((Viewport.Y / ScaleFactor) - (RelativeY + BoxHeight + 4) - (12 / ScaleFactor), 80)
            local WantHeight = math.min(400, MaxHeight)

            SearchOverlay.Size     = UDim2.fromOffset(BoxWidth + 3, WantHeight)
            SearchOverlay.Position = UDim2.fromOffset(RelativeX, RelativeY + BoxHeight + 4)
        end

        Library:GiveDPIScaleCallback(function()
            if SearchOverlay.Visible then

                task.spawn(function()
                    RunService.RenderStepped:Wait()
                    if SearchOverlay.Visible then
                        RepositionOverlay()
                    end
                end)
            end
        end)

        local function RebuildOverlay(SearchText)
            BuildGeneration += 1
            local MyGen = BuildGeneration

            ClearRows()
            ScrollFrame.CanvasPosition = Vector2.zero

            --// Compute once per rebuild; every row reuses these. \\--
            do
                local Base = Font.fromEnum(Enum.Font.GothamBold)
                RebuildTabFont = Font.new(Base.Family, Enum.FontWeight.Heavy, Base.Style)
                RebuildRowFont = Font.fromEnum(Enum.Font.GothamMedium)

                local Accent = Library.Scheme and Library.Scheme.AccentColor
                local Ok, Hex = pcall(function()
                    return Accent and Accent:ToHex()
                end)
                RebuildAccentHex = (Ok and Hex) and ("#" .. Hex) or "#FFFFFF"
            end

            local Search    = NormalizeSearch(LowerText(SearchText):match("^%s*(.-)%s*$") or "")
            local Filtering = Search ~= ""

            local TabList  = {}
            local TabOrder = {}
            for I, BtnInfo in Library.TabButtons do
                if BtnInfo.Label then
                    local N = BtnInfo.Label.Text
                    if N and not TabOrder[N] then TabOrder[N] = I end
                end
            end
            for TabName, Tab in Library.Tabs do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabList, { Name = TabName, Tab = Tab, Order = TabOrder[TabName] or 9999 })
                end
            end
            table.sort(TabList, function(A, B) return A.Order < B.Order end)

            if Library.ActiveTab then
                local ActiveEntry, RestEntries = nil, {}
                for _, TabEntry in TabList do
                    if TabEntry.Tab == Library.ActiveTab then
                        ActiveEntry = TabEntry
                    else
                        table.insert(RestEntries, TabEntry)
                    end
                end
                if ActiveEntry then
                    local Reordered = { ActiveEntry }
                    for _, TabEntry in RestEntries do
                        table.insert(Reordered, TabEntry)
                    end
                    TabList = Reordered
                end
            end

            local RowOrder = 0
            --// No cap: virtualization renders only the visible window,
            --// so the full result set stays available. \\--
            local QueryHighlight = Filtering and Search or nil

            local function PushRow(Cfg)
                RowOrder += 1
                local Idx = RowOrder

                local BadgeText, BadgeShadeStep = nil, nil
                if Cfg.IsElement and Cfg.ElementType then
                    BadgeShadeStep = (Idx % 2 == 0) and 2 or 1
                    BadgeText = TypeLabels[Cfg.ElementType] or Cfg.ElementType:upper():sub(1, 4)
                end

                local ColorFn = nil
                if Cfg.IsTab then
                    ColorFn = function() return Library:GetAccentShade(1) end
                elseif Cfg.IsSection then
                    ColorFn = function() return Library:GetAccentShade(2) end
                elseif Cfg.IsSubSection then
                    ColorFn = function() return Library:GetAccentShade(1) end
                end

                Cfg.DisplayText = BuildDisplayText(Cfg.Text, QueryHighlight, LowerCached(Cfg.Text))
                Cfg.HasHighlight = QueryHighlight ~= nil
                Cfg.BadgeText = BadgeText
                Cfg.BadgeShadeStep = BadgeShadeStep
                Cfg.RowColorFn = ColorFn
                RowData[Idx] = Cfg

                if Idx % 500 == 0 then
                    task.wait()
                    if MyGen ~= BuildGeneration then
                        return false
                    end
                end
                return true
            end

            for _, TabEntry in TabList do
                if MyGen ~= BuildGeneration then return end

                local TabName    = TabEntry.Name
                local Tab        = TabEntry.Tab
                local TabMatches = {}

                local SortedSections = {}
                for SectionName, Section in Tab.Sections do
                    table.insert(SortedSections, { Name = SectionName, Section = Section })
                end

                table.sort(SortedSections, function(A, B)
                    return (A.Section.Order or 0) < (B.Section.Order or 0)
                end)

                for _, SectionEntry in SortedSections do
                    local SectionName = SectionEntry.Name
                    local Section     = SectionEntry.Section
                    local SectionMatches = not Filtering or TryFuzzyMatch(SectionName, Search)
                    local ElMatches = {}
                    CollectElements(Section, Search, SectionMatches, Filtering, ElMatches)
                    if SectionMatches or #ElMatches > 0 then
                        table.insert(TabMatches, { SectionName = SectionName, Section = Section, Elements = ElMatches, SectionMatch = SectionMatches })
                    end
                end

                if Tab.SectionGroups then
                    for _, SectionGroup in Tab.SectionGroups do

                        local SortedPages = {}
                        for PageName, Page in SectionGroup.Tabs do
                            table.insert(SortedPages, { Name = PageName, Page = Page })
                        end
                        table.sort(SortedPages, function(A, B)
                            return (A.Page.Order or 0) < (B.Page.Order or 0)
                        end)

                        for _, PageEntry in SortedPages do
                            local PageName = PageEntry.Name
                            local Page     = PageEntry.Page
                            local PageMatches = not Filtering or TryFuzzyMatch(PageName, Search)
                            local PageElMatches = {}
                            CollectElements(Page, Search, PageMatches, Filtering, PageElMatches)
                            if PageMatches or #PageElMatches > 0 then
                                table.insert(TabMatches, { SectionName = PageName, Section = Page, Elements = PageElMatches, SectionMatch = PageMatches })
                            end
                        end
                    end
                end

                if #TabMatches == 0 then continue end

                if not PushRow({
                    Text       = TabName,
                    Depth      = 0,
                    IsTab      = true,
                    OnActivate = function() NavigateTo(Tab, nil, nil) end,
                }) then return end

                for Si, SecEntry in TabMatches do
                    if MyGen ~= BuildGeneration then return end
                    local IsLastSec = Si == #TabMatches
                    local Section   = SecEntry.Section

                    if not PushRow({
                        Text         = SecEntry.SectionName,
                        Depth        = 1,
                        IsSection    = true,
                        SectionMatch = SecEntry.SectionMatch,
                        IsLast       = IsLastSec and #SecEntry.Elements == 0,
                        OnActivate   = function() NavigateTo(Tab, Section, nil) end,
                    }) then return end

                    for Ei, ElEntry in SecEntry.Elements do
                        if MyGen ~= BuildGeneration then return end

                        local RowDepth = 1 + (ElEntry.Depth or 1)
                        local IsLastInGroup = Ei == #SecEntry.Elements

                        if ElEntry.IsSubSection then
                            local TargetSubSection = ElEntry.SubSection
                            if not PushRow({
                                Text         = ElEntry.Text,
                                Depth        = RowDepth,

                                IsSubSection = true,
                                SectionMatch = true,
                                IsLast       = IsLastInGroup,
                                OnActivate   = function() NavigateTo(Tab, Section, nil, TargetSubSection) end,
                            }) then return end
                        else
                            local ElInfo = ElEntry.Info
                            if not PushRow({
                                Text        = ElEntry.Text,
                                Depth       = RowDepth,
                                IsElement   = true,
                                IsLast      = IsLastInGroup,
                                ElementType = ElEntry.ElType,
                                OnActivate  = function() NavigateTo(Tab, Section, ElInfo) end,
                            }) then return end
                        end
                    end
                end
            end

            if MyGen ~= BuildGeneration then return end
            Library.LastSearchResultCount = #RowData
            ScrollFrame.CanvasSize = UDim2.fromOffset(0, #RowData * RowH + 6)
            ScrollFrame.CanvasPosition = Vector2.zero
            RenderVisible(true)
            if not Filtering then
                print(string.format("[Astral] search open (%s): %d rows, %d pooled", Library.BuildId, #RowData, #RowPool))
            end
        end

        local function OpenOverlay()
            RepositionOverlay()
            SearchOverlay.Visible = true
            task.spawn(RebuildOverlay, SearchBox.Text)
        end

        SearchBox.Focused:Connect(OpenOverlay)

        Library:GiveSignal(SearchBox:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if SearchOverlay.Visible then
                RepositionOverlay()
            end
        end))
        Library:GiveSignal(SearchBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if SearchOverlay.Visible then
                RepositionOverlay()
            end
        end))

        local OverlayRebuildQueued = false
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if SearchOverlay.Visible then
                --// Trailing-edge debounce: fast typing rebuilds once, after a pause \\--
                if OverlayRebuildQueued then return end
                OverlayRebuildQueued = true
                task.delay(0.08, function()
                    OverlayRebuildQueued = false
                    if SearchOverlay.Visible then
                        task.spawn(RebuildOverlay, SearchBox.Text)
                    end
                end)
            end
        end)

        Library:GiveActiveTabChangedCallback(function()
            if SearchOverlay.Visible then
                task.spawn(RebuildOverlay, SearchBox.Text)
            end
        end)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input, _Processed)
            if not SearchOverlay.Visible then return end

            if Input.UserInputType == Enum.UserInputType.MouseButton1
                or Input.UserInputType == Enum.UserInputType.Touch then
                --// The ScreenGui ignores the GUI inset, so AbsolutePosition is in screen space while
                --// Input.Position is not: add the inset back. Using the event's own position (instead of
                --// GetMouseLocation) keeps touch accurate. \\--
                local Pos = Vector2.new(Input.Position.X, Input.Position.Y) + game:GetService("GuiService"):GetGuiInset()
                local function InFrame(Frame: GuiObject)
                    local FPos, FSize = Frame.AbsolutePosition, Frame.AbsoluteSize
                    return Pos.X >= FPos.X and Pos.X <= FPos.X + FSize.X
                        and Pos.Y >= FPos.Y and Pos.Y <= FPos.Y + FSize.Y
                end

                --// Touches inside the overlay (including drag-scrolling) are left to the ScrollingFrame. \\--
                if not InFrame(SearchOverlay) and not InFrame(SearchBox) then
                    SearchBox:ReleaseFocus()
                    CloseOverlay()
                end
            end

            if Input.KeyCode == Enum.KeyCode.Escape then
                SearchBox.Text = ""
                SearchBox:ReleaseFocus()
                CloseOverlay()
            end
        end))
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if Input.KeyCode == Enum.KeyCode.Escape then
            -- Releasing focus from a text input takes priority and never toggles the window --
            local FocusedBox = UserInputService:GetFocusedTextBox()
            if FocusedBox then
                FocusedBox:ReleaseFocus()
                return
            end

            -- Dismiss the topmost dialog before closing any open menu --
            if Library.ActiveDialog and Library.ActiveDialog.OutsideClickDismiss ~= false then
                Library.ActiveDialog:Dismiss()
                return
            end

            if CurrentMenu then
                CurrentMenu:Close()
                return
            end

            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    Window.MainFrame = MainFrame
    Library.Window = Window

    Library:RescanStyle()
    Library:UpdateWindowStyle()

    return Window
end

function Library:CreateLoading(LoadingInfo)
    if Library.ActiveLoading then
        Library:Notify({
            Title = "Astral",
            Description = "A Loading GUI already exists -- only one can be active at a time.",
        })
        return Library.ActiveLoading
    end

    LoadingInfo = Library:Validate(LoadingInfo, Templates.Loading)

    local ShouldWait = LoadingInfo.WaitForIconsOnLoad
    if ShouldWait == nil then
        ShouldWait = Library.WaitForIconsOnLoad
    end
    if ShouldWait ~= false then
        Library:WaitForIcons(10)
    end

    local Loading = {
        CurrentStep = LoadingInfo.CurrentStep,
        TotalSteps = LoadingInfo.TotalSteps,

        ShowSidebar = LoadingInfo.ShowSidebar,
        AutoResizeHeight = LoadingInfo.AutoResizeHeight,
        IsError = false,
        Destroyed = false,
        AlwaysOnTop = LoadingInfo.AlwaysOnTop,

        WindowWidth = LoadingInfo.WindowWidth,
        WindowHeight = LoadingInfo.WindowHeight,
        BaseWindowHeight = LoadingInfo.WindowHeight,
        WindowErrorHeight = LoadingInfo.WindowHeight,

        ContentWidth = LoadingInfo.ContentWidth,
        SidebarWidth = LoadingInfo.SidebarWidth,
    }

    local ScreenGui = New("ScreenGui", {
        Name = "AstralLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    })
    ParentUI(ScreenGui)
    Loading.ScreenGui = ScreenGui
    SetAlwaysOnTop(ScreenGui, LoadingInfo.AlwaysOnTop)

    ScreenGui.DescendantRemoving:Connect(function(Inst)
        Library:RemoveFromRegistry(Inst)
    end)

    local MainFrame = New("TextButton", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = function()
            return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
        end,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Loading.ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth, Loading.WindowHeight),
        ClipsDescendants = true,
        Text = "",
        AutoButtonColor = false,
        Parent = ScreenGui,
    })
    Library:AddOutline(MainFrame)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = MainFrame }))

    local InitialScale
    if LoadingInfo.DPIScale ~= nil then
        local DPIValue = math.clamp(tonumber(LoadingInfo.DPIScale) or 5, 1, 10)
        local ScaleFactor
        if DPIValue <= 5 then
            ScaleFactor = 0.40 + ((DPIValue - 1) / 4) * 0.60
        else
            ScaleFactor = 1.00 + ((DPIValue - 5) / 5) * 0.50
        end
        InitialScale = ScaleFactor
    else
        InitialScale = 1
    end

    local MainScale = New("UIScale", {
        Scale = InitialScale,
        Parent = MainFrame
    })
    table.insert(Library.Scales, MainScale)
    Library.ScalesOffset[MainScale] = 0

    local Container = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, Loading.ContentWidth, 1, 0),
        Parent = MainFrame,
    })

    local SideBar = New("Frame", {
        Name = "SideBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Loading.ContentWidth, 0),
        Size = UDim2.new(0, Loading.ShowSidebar and Loading.SidebarWidth or 0, 1, 0),
        ClipsDescendants = true,
        Visible = Loading.ShowSidebar,
        Parent = MainFrame,
    })
    local SidebarCorner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = SideBar })
    table.insert(Library.Corners, SidebarCorner)

    Library:AddOutline(SideBar)

    local SidebarDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Visible = Loading.ShowSidebar,
        Parent = SideBar,
    })

    local TopBar = New("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 2,
        Parent = Container,
    })
    Library:MakeDraggable(MainFrame, TopBar, true, true)

    local TitleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TopBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = TitleHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        Parent = TitleHolder,
    })

    if LoadingInfo.Icon then

        local IsBuiltInIcon = CustomImageManager.IsBuiltIn(LoadingInfo.Icon)
        local ResolvedIconId = IsBuiltInIcon and CustomImageManager.GetAsset(LoadingInfo.Icon) or LoadingInfo.Icon
        local Icon = Library:GetCustomIcon(ResolvedIconId)
        local _WindowIcon = New("ImageLabel", {
            Image = Icon.Url,
            ImageColor3 = IsBuiltInIcon and "AccentColor" or "WhiteColor",
            ImageRectOffset = Icon.ImageRectOffset,
            ImageRectSize = Icon.ImageRectSize,
            Size = LoadingInfo.IconSize,
            Parent = TitleHolder,
        })
        if IsBuiltInIcon then
            Library:AddToRegistry(_WindowIcon, { ImageColor3 = "AccentColor" })
        end
    else
        local _WindowIcon = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = LoadingInfo.IconSize,
            Text = LoadingInfo.Title:sub(1, 1),
            TextScaled = true,
            Visible = false,
            Parent = TitleHolder,
        })
    end

    local TitleX = Library:GetTextBounds(
        LoadingInfo.Title,
        Library.Scheme.Font,
        20,
        TitleHolder.AbsoluteSize.X - (LoadingInfo.Icon and (LoadingInfo.IconSize.X.Offset + 6) or 0) - 12
    )
    local _WindowTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, TitleX, 1, 0),
        Text = LoadingInfo.Title,
        TextSize = 20,
        Parent = TitleHolder,
    })

    Library:MakeLine(Container, {
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local InnerContent = New("Frame", {
        Name = "InnerContent",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        Parent = InnerContent,
    })

    local IconHolder = New("Frame", {
        Name = "IconHolder",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(64, 64),
        Parent = InnerContent,
    })

    local IsBuiltInLoadingIcon = CustomImageManager.IsBuiltIn(LoadingInfo.LoadingIcon)
    local ResolvedLoadingIconId = IsBuiltInLoadingIcon and CustomImageManager.GetAsset(LoadingInfo.LoadingIcon) or LoadingInfo.LoadingIcon
    local LoaderIcon = Library:GetCustomIcon(ResolvedLoadingIconId)
    local LoadingIcon = New("ImageLabel", {
        Name = "LoaderIcon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        Image = LoaderIcon.Url,
        ImageRectOffset = LoaderIcon.ImageRectOffset,
        ImageRectSize = LoaderIcon.ImageRectSize,
        ImageColor3 = LoadingInfo.LoadingIconColor or (IsBuiltInLoadingIcon and "AccentColor" or "WhiteColor"),
        Parent = IconHolder,
    })

    local RotationTween
    if LoadingInfo.LoadingIconTweenTime > 0 then
        RotationTween = TweenService:Create(
            LoadingIcon,
            TweenInfo.new(LoadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            { Rotation = 360 }
        )
        RotationTween:Play()
    end

    local MessageLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 18,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local DescriptionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local SliderBar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0.7, 0, 0, 15),
        Parent = InnerContent,
    })
    Library:AddOutline(SliderBar)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderBar }))

    local SliderFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = SliderBar,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderFill }))

    local ProgressLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextSize = 14,
        ZIndex = 2,
        Parent = SliderBar,
    })
    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = GetTextStrokeColor,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = ProgressLabel,
    })

    local SidebarScrolling = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 0,
        Parent = SideBar,
    })
    Library:AddCustomScrollbar(SidebarScrolling)
    local SidebarList = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarScrolling,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        Parent = SidebarScrolling,
    })

    local SidebarObject = {
        Elements = {},
        ConditionalGroups = {},
        SectionGroups = {},

        BoxHolder = SidebarScrolling,
        Container = SidebarScrolling,

        Resize = function(self)
            SidebarScrolling.CanvasSize = UDim2.fromOffset(0, SidebarList.AbsoluteContentSize.Y + 24)
        end,
        Tab = {
            Elements = {},
            ConditionalGroups = {},
            ConditionalSections = {},
            SectionGroups = {},
        },
    }

    SidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarObject:Resize()
    end)

    setmetatable(SidebarObject, BaseSection)
    Loading.Sidebar = SidebarObject

    local ErrorFrame = New("Frame", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        ClipsDescendants = true,
        Visible = false,
        Parent = Container,
    })

    local _ErrorTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 15),
        Size = UDim2.new(1, -30, 0, 18),
        Text = "Error",
        TextColor3 = "RedColor",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ErrorFrame,
    })

    local ErrorLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 39),
        Size = UDim2.new(1, -30, 1, -90),
        Text = "Error Message",
        TextSize = 14,
        TextTransparency = 0.2,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = ErrorFrame,
    })

    local ErrorButtonsDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, -48),
        Size = UDim2.new(1, -30, 0, 1),
        Visible = false,
        Parent = ErrorFrame,
    })

    local ErrorButtonsHolder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 42),
        Visible = false,
        Parent = ErrorFrame,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ErrorButtonsHolder,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = ErrorButtonsHolder,
    })

    function Loading:UpdateLayout()
        if Loading.IsError then
            Loading:RecalculateErrorHeight()
        end

        local ShowSidebar = Loading.ShowSidebar
        local FinalWidth = ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth
        local FinalHeight = Loading.IsError and Loading.WindowErrorHeight or Loading.WindowHeight

        if ShowSidebar then
            SideBar.Visible = true
            SidebarDivider.Visible = true
        end

        TweenService:Create(MainFrame, Library.TweenInfo, { Size = UDim2.fromOffset(FinalWidth, FinalHeight) }):Play()
        TweenService:Create(SideBar, Library.TweenInfo, { Position = UDim2.fromOffset(Loading.ContentWidth, 0), Size = UDim2.new(0, ShowSidebar and Loading.SidebarWidth or 0, 1, 0) }):Play()
        TweenService:Create(Container, Library.TweenInfo, { Size = UDim2.new(0, ShowSidebar and Loading.ContentWidth or Loading.WindowWidth, 1, 0) }):Play()

        if not ShowSidebar then
            task.delay(Library.TweenInfo.Time, function()
                if not Loading.ShowSidebar then
                    SideBar.Visible = false
                    SidebarDivider.Visible = false
                end
            end)
        end
    end

    function Loading:RecalculateLoadingHeight()
        if not Loading.AutoResizeHeight then
            return
        end

        local RequiredHeight =
              49
            + 48
            + InnerContent.UIListLayout.AbsoluteContentSize.Y

        Loading.WindowHeight = math.max(Loading.BaseWindowHeight, RequiredHeight)
    end

    function Loading:SetMessage(Text)
        MessageLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetDescription(Text)
        DescriptionLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetLoadingIcon(Icon)
        local IconData = Library:GetCustomIcon(Icon)
        LoadingIcon.Image = IconData.Url
        LoadingIcon.ImageRectOffset = IconData.ImageRectOffset
        LoadingIcon.ImageRectSize = IconData.ImageRectSize
    end

    function Loading:SetLoadingIconTweenTime(TweenTime)
        if RotationTween then
            RotationTween:Cancel()
            RotationTween:Destroy()
        end

        if TweenTime > 0 then
            RotationTween = TweenService:Create(
                LoadingIcon,
                TweenInfo.new(TweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
                { Rotation = 360 }
            )
            RotationTween:Play()
        else
            LoadingIcon.Rotation = 0
        end
    end

    function Loading:SetLoadingIconColor(Color)
        LoadingIcon.ImageColor3 = Color
    end

    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = math.clamp(Step, 0, Loading.TotalSteps)

        local Progress = Loading.CurrentStep / Loading.TotalSteps
        TweenService:Create(SliderFill, Library.TweenInfo, { Size = UDim2.fromScale(Progress, 1) }):Play()

        ProgressLabel.Text = string.format("%d/%d", Loading.CurrentStep, Loading.TotalSteps)
    end

    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        Loading:SetCurrentStep(Loading.CurrentStep)
    end

    function Loading:SetWindowHeight(Height)
        Loading.WindowHeight = Height
        Loading:UpdateLayout()
    end

    function Loading:SetWindowWidth(Width)
        Loading.WindowWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetContentWidth(Width)
        Loading.ContentWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetSidebarWidth(Width)
        Loading.SidebarWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetAlwaysOnTop(Enabled: boolean)
        Loading.AlwaysOnTop = Enabled == true
        SetAlwaysOnTop(Loading.ScreenGui, Loading.AlwaysOnTop)
    end

    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        Loading:UpdateLayout()
    end

    function Loading:ShowErrorPage(Enabled)
        Loading.IsError = Enabled
        InnerContent.Visible = not Enabled
        ErrorFrame.Visible = Enabled

        if Loading.ShowSidebar then
            Loading:ShowSidebarPage(not Enabled)
        else
            Loading:UpdateLayout()
        end
    end

    function Loading:RecalculateErrorHeight()
        local TargetWidth = (Loading.ShowSidebar and Loading.ContentWidth or Loading.WindowWidth) - 30
        local _, ErrorY = Library:GetTextBounds(ErrorLabel.Text, Library.Scheme.Font, 14, TargetWidth)

        ErrorLabel.Size = UDim2.new(1, -30, 0, ErrorY)

        local HasButtons = ErrorButtonsHolder.Visible
        local RequiredHeight =
              49
            + 15
            + 18
            + 6
            + ErrorY
            + 15
            + (HasButtons and 48 or 0)

        Loading.WindowErrorHeight = RequiredHeight
    end

    function Loading:SetErrorMessage(Text)
        ErrorLabel.Text = Text
        Loading:UpdateLayout()
    end

    function Loading:SetErrorButtons(Buttons)
        assert(typeof(Buttons) == "table", "Buttons must be a table")

        for _, button in ErrorButtonsHolder:GetChildren() do
            if button:IsA("Frame") then
                button:Destroy()
            end
        end

        local HasButtons = GetTableSize(Buttons) > 0
        ErrorButtonsHolder.Visible = HasButtons
        ErrorButtonsDivider.Visible = HasButtons

        for Idx, ButtonInfo in Buttons do
            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                Parent = ErrorButtonsHolder,
            })

            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"

            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = TextBtn
                })
            )

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or Idx,
                TextColor3 = TextColor,
                TextSize = 14,
                Parent = TextBtn,
            })

            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Loading)
                end
            end)
        end

        Loading:UpdateLayout()
    end

    function Loading:Destroy()
        if RotationTween then
            RotationTween:Cancel()
        end

        ScreenGui:Destroy()
        Loading.Destroyed = true
        Library.ActiveLoading = nil

        if Library.Toggle and Library.Toggled == false and Library.Unloaded ~= true then
            Library:Toggle(true)
        end
    end

    Loading.Continue = Loading.Destroy;

    if Library.Toggle and Library.Toggled and Library.Unloaded ~= true then
        Library:Toggle(false)
    end

    Loading:SetCurrentStep(Loading.CurrentStep)

    Library.ActiveLoading = Loading
    return Loading
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library

return Library
