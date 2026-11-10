local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func)
    return func
end)
local getgenv = getgenv or function()
    return shared
end

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(clonefunction) == "function" then

    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {}
do
    local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
    ThemeManager.Folder = "Astral"

    ThemeManager.Library = nil
    ThemeManager.AppliedToTab = false
    ThemeManager.DefaultThemeName = nil

    --// Accessibility: contrast warning state
    ThemeManager.ContrastLabel = nil
    ThemeManager.ContrastWasPoor = false

    --// WCAG21 constants (https://www.w3.org/TR/WCAG21/#dfn-relative-luminance)
    local ContrastWarnThreshold = 4.5 --// Accessibility: minimum WCAG AA contrast ratio for normal text
    local SrgbLinearThreshold = 0.03928 --// sRGB channel value below which the linear conversion is a simple divide
    local SrgbLinearDivisor = 12.92 --// Divisor used for channel values below SrgbLinearThreshold
    local SrgbGammaOffset = 0.055 --// Offset applied before the gamma expansion power curve
    local SrgbGammaScale = 1.055 --// Scale applied before the gamma expansion power curve
    local SrgbGammaExponent = 2.4 --// Exponent for the gamma expansion power curve
    local LuminanceRedWeight, LuminanceGreenWeight, LuminanceBlueWeight = 0.2126, 0.7152, 0.0722
    local ContrastRatioOffset = 0.05 --// Offset added to both luminances when computing a contrast ratio

    local function LinearizeChannel(Channel: number): number
        if Channel <= SrgbLinearThreshold then
            return Channel / SrgbLinearDivisor
        end

        return ((Channel + SrgbGammaOffset) / SrgbGammaScale) ^ SrgbGammaExponent
    end

    local function GetRelativeLuminance(Color: Color3): number
        local R = LinearizeChannel(Color.R)
        local G = LinearizeChannel(Color.G)
        local B = LinearizeChannel(Color.B)

        return LuminanceRedWeight * R + LuminanceGreenWeight * G + LuminanceBlueWeight * B
    end

    local function GetContrastRatio(ColorA: Color3, ColorB: Color3): number
        local LuminanceA = GetRelativeLuminance(ColorA)
        local LuminanceB = GetRelativeLuminance(ColorB)

        local Lighter = math.max(LuminanceA, LuminanceB)
        local Darker = math.min(LuminanceA, LuminanceB)

        return (Lighter + ContrastRatioOffset) / (Darker + ContrastRatioOffset)
    end

    --// Gradient end color used when a theme doesn't define its own: the background pushed toward the accent.
    local function DeriveGradient(BackgroundColor: Color3, AccentColor: Color3): Color3
        return BackgroundColor:Lerp(AccentColor, 0.08)
    end

    local function IsValidThemeData(Data: any): boolean
        if typeof(Data) ~= "table" then
            return false
        end

        --// Require the color scheme to be present; font/background image are optional and fall back to current values
        for _, SchemeIndex in ThemeFields do
            if typeof(Data[SchemeIndex]) ~= "string" then
                return false
            end
        end

        return true
    end
    ThemeManager.BuiltInThemes = {
        ["Default"] = {
            1,
            { FontColor = "ffffff", MainColor = "151519", AccentColor = "4287f5", BackgroundColor = "0d0d10", OutlineColor = "24242a", GradientColor = "192842" },
        },
        ["BBot"] = {
            2,
            { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414", GradientColor = "372b3f" },
        },
        ["Fatality"] = {
            3,
            { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d", GradientColor = "3f103c" },
        },
        ["Jester"] = {
            4,
            { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737", GradientColor = "46252c" },
        },
        ["Mint"] = {
            5,
            { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737", GradientColor = "233d34" },
        },
        ["Tokyo Night"] = {
            6,
            { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232", GradientColor = "282540" },
        },
        ["Ubuntu"] = {
            7,
            { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919", GradientColor = "593a2e" },
        },
        ["Quartz"] = {
            8,
            { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f", GradientColor = "252d3b" },
        },
        ["Nord"] = {
            9,
            { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a", GradientColor = "425360" },
        },
        ["Dracula"] = {
            10,
            { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4", GradientColor = "573b56" },
        },
        ["Monokai"] = {
            11,
            { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e", GradientColor = "4e212f" },
        },
        ["Gruvbox"] = {
            12,
            { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945", GradientColor = "562f2b" },
        },
        ["Solarized"] = {
            13,
            { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75", GradientColor = "2d322f" },
        },
        ["Catppuccin"] = {
            14,
            { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268", GradientColor = "4d4257" },
        },
        ["One Dark"] = {
            15,
            { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370", GradientColor = "453752" },
        },
        ["Cyberpunk"] = {
            16,
            { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e", GradientColor = "144c47" },
        },
        ["Oceanic Next"] = {
            17,
            { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46", GradientColor = "283d4e" },
        },
        ["Material"] = {
            18,
            { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242", GradientColor = "2d3648" },
        }
    }

    for _, Theme in ThemeManager.BuiltInThemes do
        if typeof(Theme[2]) == "table" and Theme[2].BackgroundImage == nil then
            Theme[2].BackgroundImage = ""
        end
    end

    function ThemeManager:SetLibrary(library)
        self.Library = library
    end

    function ThemeManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        paths[#paths + 1] = self.Folder .. "/themes"

        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then
                continue
            end
            pcall(makefolder, str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) then
            return
        end
        self:BuildFolderTree()

        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    --// Applies a flat theme data table (either a parsed theme file or an imported JSON blob) to the library.
    function ThemeManager:ApplyThemeData(ThemeData: any)
        if typeof(ThemeData) ~= "table" then
            return false, "Invalid theme data"
        end

        for idx, val in pairs(ThemeData) do
            if idx == "VideoLink" then
                continue
            elseif idx == "FontFace" then
                if typeof(val) ~= "string" or not Enum.Font[val] then
                    continue
                end

                self.Library:SetFont(Enum.Font[val])

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end
            elseif idx == "BackgroundImage" then
                if typeof(val) ~= "string" then
                    continue
                end

                self.Library:SetBackgroundImage(val)

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end
            elseif idx == "GradientColor" then
                local success, color = pcall(Color3.fromHex, val)
                if not success then
                    continue
                end

                self.Library.Scheme.GradientColor = color

                if self.Library.Options.GradientColor then
                    self.Library.Options.GradientColor:SetValueRGB(color)
                end
            elseif table.find(ThemeFields, idx) then
                local success, color = pcall(Color3.fromHex, val)
                if not success then
                    continue
                end

                self.Library.Scheme[idx] = color

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValueRGB(color)
                end
            end
        end

        --// Older themes have no gradient color; derive one so gradients still follow the theme.
        if typeof(ThemeData.GradientColor) ~= "string" then
            local Scheme = self.Library.Scheme
            local Derived = DeriveGradient(Scheme.BackgroundColor, Scheme.AccentColor)
            Scheme.GradientColor = Derived

            if self.Library.Options.GradientColor then
                self.Library.Options.GradientColor:SetValueRGB(Derived)
            end
        end

        self:ThemeUpdate()
        return true
    end

    function ThemeManager:ApplyTheme(theme)
        if not theme or (typeof(theme) == "string" and theme:gsub(" ", "") == "") then
            return false, "No theme is selected"
        end

        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]

        if not data then
            return false, "Theme not found"
        end

        if customThemeData then
            return self:ApplyThemeData(customThemeData)
        end

        local scheme = data[2]
        for idx, val in pairs(scheme) do
            if idx == "VideoLink" then
                continue
            elseif idx == "FontFace" then
                self.Library:SetFont(Enum.Font[val])

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end
            elseif idx == "BackgroundImage" then
                if typeof(val) == "string" and val ~= "" then
                    self.Library:SetBackgroundImage(val)
                end

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end
            else
                self.Library.Scheme[idx] = Color3.fromHex(val)

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValueRGB(Color3.fromHex(val))
                end
            end
        end

        self:ThemeUpdate()
        return true
    end

    function ThemeManager:GetContrastReport()
        local Library = self.Library
        local FontColorOption = Library.Options.FontColor
        local BackgroundColorOption = Library.Options.BackgroundColor
        local MainColorOption = Library.Options.MainColor

        if not (FontColorOption and BackgroundColorOption and MainColorOption) then
            return { Ratio = math.huge, PairName = "", Passes = true }
        end

        local FontColor = FontColorOption.Value
        local Surfaces = {
            { Name = "font color vs. background color", Color = BackgroundColorOption.Value },
            { Name = "font color vs. main color", Color = MainColorOption.Value },
        }

        local WorstRatio, WorstName = math.huge, ""
        for _, Surface in Surfaces do
            local Ratio = GetContrastRatio(FontColor, Surface.Color)
            if Ratio < WorstRatio then
                WorstRatio = Ratio
                WorstName = Surface.Name
            end
        end

        return {
            Ratio = WorstRatio,
            PairName = WorstName,
            Passes = WorstRatio >= ContrastWarnThreshold,
        }
    end

    function ThemeManager:UpdateContrastWarning()
        local ContrastLabel = ThemeManager.ContrastLabel
        if not ContrastLabel or ContrastLabel.Destroyed then
            return
        end

        local Library = self.Library
        local Report = self:GetContrastReport()
        local TextLabel = ContrastLabel.TextLabel

        if not TextLabel then
            return
        end

        if not Library.Registry[TextLabel] then
            Library:AddToRegistry(TextLabel, {})
        end

        if Report.Passes then
            ContrastLabel:SetText(string.format("Contrast check: good (%.1f:1)", Report.Ratio))

            TextLabel.TextColor3 = Library.Scheme.FontColor
            Library.Registry[TextLabel].TextColor3 = "FontColor"
        else
            ContrastLabel:SetText(string.format(
                "Low contrast (%.1f:1) between %s. Aim for at least %.1f:1 so text stays readable.",
                Report.Ratio, Report.PairName, ContrastWarnThreshold
            ))

            TextLabel.TextColor3 = Library.Scheme.RedColor
            Library.Registry[TextLabel].TextColor3 = "RedColor"

            if not ThemeManager.ContrastWasPoor then
                Library:Notify({
                    Title = "Low contrast theme",
                    Description = string.format(
                        "Your %s has a contrast ratio of %.1f:1, below the recommended %.1f:1. Text may be hard to read.",
                        Report.PairName, Report.Ratio, ContrastWarnThreshold
                    ),
                    Time = 10,
                })
            end
        end

        ThemeManager.ContrastWasPoor = not Report.Passes
    end

    function ThemeManager:ThemeUpdate()
        for i, field in ThemeFields do
            if self.Library.Options and self.Library.Options[field] then
                self.Library.Scheme[field] = self.Library.Options[field].Value
            end
        end

        if self.Library.Options and self.Library.Options.GradientColor then
            self.Library.Scheme.GradientColor = self.Library.Options.GradientColor.Value
        end

        if self.Library.Options and self.Library.Options.BackgroundImage then
            self.Library.Scheme.BackgroundImage = self.Library.Options.BackgroundImage.Value
        end

        self.Library:UpdateColorsUsingRegistry()
        self:UpdateContrastWarning()
    end

    function ThemeManager:GetCustomTheme(file)
        local path = self.Folder .. "/themes/" .. file .. ".json"
        if not isfile(path) then
            return nil
        end

        local data = readfile(path)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)

        if not success then
            return nil
        end

        return decoded
    end

    function ThemeManager:LoadDefault()
        local theme = "Default"
        local content = isfile(self.Folder .. "/themes/default.txt") and readfile(self.Folder .. "/themes/default.txt")

        local isDefault = true
        if content then
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
                isDefault = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end

        if isDefault then
            self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
        else
            self:ApplyTheme(theme)
        end
    end

    function ThemeManager:GetDefaultTheme()
        self:CheckFolderTree()

        local path = self.Folder .. "/themes/default.txt"
        if not isfile(path) then
            return "none", false, "Default theme is not set"
        end

        local success, name = pcall(readfile, path)
        if not (success and typeof(name) == "string") then
            return "none", false, name
        end

        if not (self.BuiltInThemes[name] or self:GetCustomTheme(name)) then
            return "none", false, "Theme file not found"
        end

        ThemeManager.DefaultThemeName = name
        return name, true
    end

    function ThemeManager:DeleteDefaultTheme()
        self:CheckFolderTree()

        local path = self.Folder .. "/themes/default.txt"
        if not isfile(path) then
            return false, "Default theme is not set"
        end

        local success, err = pcall(delfile, path)
        if not success then
            return false, err
        end

        ThemeManager.DefaultThemeName = nil
        return true
    end

    local function BuildCurrentThemeData()
        local Library = ThemeManager.Library
        local ThemeData = {
            FontFace = Library.Options.FontFace.Value,
            BackgroundImage = Library.Options.BackgroundImage and Library.Options.BackgroundImage.Value or "",
        }

        for _, SchemeIndex in ThemeFields do
            ThemeData[SchemeIndex] = Library.Options[SchemeIndex].Value:ToHex()
        end

        return ThemeData
    end

    function ThemeManager:SaveJSON()
        local ThemeData = BuildCurrentThemeData()

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, ThemeData)
        if not success then
            return "", false, "Failed to encode data"
        end

        return encoded, true
    end

    function ThemeManager:LoadJSON(content)
        if not content or content:gsub(" ", "") == "" then
            return false, "No JSON provided"
        end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        if not success or not IsValidThemeData(decoded) then
            return false, "Failed to decode theme data"
        end

        return ThemeManager:ApplyThemeData(decoded)
    end

    function ThemeManager:SaveDefault(theme)
        if not theme or (typeof(theme) == "string" and theme:gsub(" ", "") == "") then
            return false, "No theme is selected"
        end

        if not (self.BuiltInThemes[theme] or self:GetCustomTheme(theme)) then
            return false, "Theme does not exist"
        end

        local success, err = pcall(writefile, self.Folder .. "/themes/default.txt", theme)
        if not success then
            return false, tostring(err)
        end

        ThemeManager.DefaultThemeName = theme
        return true
    end

    function ThemeManager:SetDefaultTheme(theme)
        assert(self.Library, "Must set ThemeManager.Library first!")
        assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

        local FinalTheme = {}
        local LibraryScheme = {}
        for _, field in ThemeFields do
            if typeof(theme[field]) == "Color3" then
                FinalTheme[field] = "#" .. theme[field]:ToHex()
                LibraryScheme[field] = theme[field]

            elseif typeof(theme[field]) == "string" then
                FinalTheme[field] = if theme[field]:sub(1, 1) == "#" then theme[field] else ("#" .. theme[field])
                LibraryScheme[field] = Color3.fromHex(theme[field])

            else
                FinalTheme[field] = ThemeManager.BuiltInThemes["Default"][2][field]
                LibraryScheme[field] = Color3.fromHex(ThemeManager.BuiltInThemes["Default"][2][field])
            end
        end

        if typeof(theme["GradientColor"]) == "Color3" then
            FinalTheme["GradientColor"] = "#" .. theme["GradientColor"]:ToHex()
            LibraryScheme["GradientColor"] = theme["GradientColor"]
        elseif typeof(theme["GradientColor"]) == "string" then
            FinalTheme["GradientColor"] = if theme["GradientColor"]:sub(1, 1) == "#" then theme["GradientColor"] else ("#" .. theme["GradientColor"])
            LibraryScheme["GradientColor"] = Color3.fromHex(theme["GradientColor"])
        else
            local Derived = DeriveGradient(LibraryScheme.BackgroundColor, LibraryScheme.AccentColor)
            FinalTheme["GradientColor"] = "#" .. Derived:ToHex()
            LibraryScheme["GradientColor"] = Derived
        end

        if typeof(theme["FontFace"]) == "EnumItem" then
            FinalTheme["FontFace"] = theme["FontFace"].Name
            LibraryScheme["Font"] = Font.fromEnum(theme["FontFace"])

        elseif typeof(theme["FontFace"]) == "string" then
            FinalTheme["FontFace"] = theme["FontFace"]
            LibraryScheme["Font"] = Font.fromEnum(Enum.Font[theme["FontFace"]])

        else
            FinalTheme["FontFace"] = "GothamMedium"
            LibraryScheme["Font"] = Font.fromEnum(Enum.Font.GothamMedium)
        end

        for _, field in { "RedColor", "DarkColor", "WhiteColor" } do
            LibraryScheme[field] = self.Library.Scheme[field]
        end

        self.Library.Scheme = LibraryScheme
        self.BuiltInThemes["Default"] = { 1, FinalTheme }

        self.Library:UpdateColorsUsingRegistry()
    end

    function ThemeManager:SaveCustomTheme(file)
        if file:gsub(" ", "") == "" then
            return false, "Invalid theme name provided (empty)"
        end

        if string.lower(file) == "default" then
            return false, "Invalid theme name provided"
        end

        local theme = {}
        for _, field in ThemeFields do
            theme[field] = self.Library.Options[field].Value:ToHex()
        end
        if self.Library.Options["GradientColor"] then
            theme["GradientColor"] = self.Library.Options["GradientColor"].Value:ToHex()
        end
        theme["FontFace"] = self.Library.Options["FontFace"].Value
        theme["BackgroundImage"] = self.Library.Options["BackgroundImage"] and self.Library.Options["BackgroundImage"].Value or ""

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, theme)
        if not success then
            return false, "Failed to encode theme"
        end

        local writeSuccess, writeErr = pcall(writefile, self.Folder .. "/themes/" .. file .. ".json", encoded)
        if not writeSuccess then
            return false, tostring(writeErr)
        end

        return true
    end

    function ThemeManager:Delete(name)
        if not name then
            return false, "no config file is selected"
        end

        local file = self.Folder .. "/themes/" .. name .. ".json"
        if not isfile(file) then
            return false, "invalid file"
        end

        local success = pcall(delfile, file)
        if not success then
            return false, "delete file error"
        end

        if name == ThemeManager.DefaultThemeName then
            self:DeleteDefaultTheme()
        end

        return true
    end

    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. "/themes")

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then

                local pos = file:find(".json", 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= "/" and char ~= "\\" and char ~= "" do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == "/" or char == "\\" then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end

        return out
    end

    local function ShowDialog(Condition, Index, Title, Description, DestructiveText, DestructiveAction)
        if Condition() == false then
            return DestructiveAction()
        end

        local Window = ThemeManager.Library.Window
        if not Window or not Window.AddDialog then
            return DestructiveAction()
        end

        return Window:AddDialog(Index, {
            Title = Title,
            Description = Description,
            AutoDismiss = false,
            FooterButtons = {
                Cancel = {
                    Title = "Cancel",
                    Variant = "Ghost",
                    Order = 1,
                    Callback = function(Dialog)
                        Dialog:Dismiss()
                    end,
                },
                DestructiveAction = {
                    Title = DestructiveText,
                    Variant = "Destructive",
                    Order = 2,
                    Callback = function(Dialog)
                        Dialog:Dismiss()
                        DestructiveAction()
                    end,
                },
            },
        })
    end

    function ThemeManager:CreateThemeManager(groupbox)
        groupbox
            :AddLabel("Background color")
            :AddColorPicker("BackgroundColor", { Default = self.Library.Scheme.BackgroundColor })
        groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = self.Library.Scheme.MainColor })
        groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.Scheme.AccentColor })
        groupbox
            :AddLabel("Outline color")
            :AddColorPicker("OutlineColor", { Default = self.Library.Scheme.OutlineColor })
        groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = self.Library.Scheme.FontColor })
        groupbox:AddLabel("Gradient color"):AddColorPicker("GradientColor", {
            Default = self.Library.Scheme.GradientColor
                or DeriveGradient(self.Library.Scheme.BackgroundColor, self.Library.Scheme.AccentColor),
        })

        --// Accessibility: live contrast readout for the colors above
        ThemeManager.ContrastLabel = groupbox:AddLabel({
            Text = "Contrast check: n/a",
            DoesWrap = true,
        })

        groupbox:AddDropdown("FontFace", {
            Text = "Font Face",
            Default = "GothamMedium",
            Values = { "BuilderSans", "Code", "Fantasy", "Gotham", "GothamMedium", "Jura", "Roboto", "RobotoMono", "SourceSans" },
        })

        groupbox:AddInput("BackgroundImage", {
            Text = "Background Image",
            Default = "",
            Finished = true,
            ClearTextOnFocus = false,
            ClearTextOnBlur = false,
        })

        groupbox:AddToggle("ThemeManager_Gradients", {
            Text = "Gradients",
            Default = self.Library.GradientsEnabled ~= false,
            Callback = function(Value)
                self.Library:SetGradientsEnabled(Value)
            end,
        })

        groupbox:AddSlider("ThemeManager_Transparency", {
            Text = "Window transparency",
            Default = math.floor((self.Library.WindowTransparency or 0) * 100 + 0.5),
            Min = 0,
            Max = 85,
            Rounding = 0,
            Suffix = "%",
            Callback = function(Value)
                self.Library:SetWindowTransparency(Value / 100)
            end,
        })

        local ThemesArray = {}
        for Name, Theme in pairs(self.BuiltInThemes) do
            table.insert(ThemesArray, Name)
        end

        table.sort(ThemesArray, function(a, b)
            return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
        end)

        local ThemeList, CustomThemeList, CustomThemeName, ThemeJSONInput, DefaultThemeLabel
        local function RefreshList()
            if not CustomThemeList then return end
            CustomThemeList:SetValues(self:ReloadCustomThemes())
            CustomThemeList:SetValue(nil)

            if ThemeList then
                ThemeList:SetValues(ThemesArray)
            end
        end

        local function RefreshDefaultThemeLabel()
            local name = self:GetDefaultTheme()

            if DefaultThemeLabel then
                DefaultThemeLabel:SetText(string.format("Current default theme: %s", name))
            end
            RefreshList()
        end

        local function WithDefaultSuffix(Value)
            if Value ~= "Default" and Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end

        groupbox:AddDivider()

        groupbox:AddDropdown("ThemeManager_ThemeList", {
            Text = "Theme list",
            Values = ThemesArray,
            Default = 1,
            FormatDisplayValue = WithDefaultSuffix,
            FormatListValue = WithDefaultSuffix,
        })
        ThemeList = self.Library.Options.ThemeManager_ThemeList

        groupbox:AddButton("Set as default", function()
            local themeName = ThemeList.Value
            local success, err = self:SaveDefault(themeName)
            if not success then
                self.Library:Notify({ Title = "ThemeManager", Description = tostring(err), Time = 4 })
                return
            end

            self.Library:Notify(
                string.format("Set default theme to %q", themeName)
            )
            RefreshDefaultThemeLabel()
        end)

        ThemeList:OnChanged(function()
            self:ApplyTheme(ThemeList.Value)
        end)

        groupbox:AddDivider()

        groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
        CustomThemeName = self.Library.Options.ThemeManager_CustomThemeName

        local function SaveThemeWithContrastCheck(Name: string, SuccessMessage: string, OnSaved)
            local function DoSave()
                local Success, ErrorMessage = self:SaveCustomTheme(Name)
                if not Success then
                    self.Library:Notify({ Title = "ThemeManager", Description = string.format("Failed to save theme %q: %s", Name, tostring(ErrorMessage)), Time = 4 })
                    return
                end

                self.Library:Notify({ Title = "ThemeManager", Description = string.format(SuccessMessage, Name), Time = 3 })
                if OnSaved then OnSaved() end
            end

            local Report = self:GetContrastReport()
            if Report.Passes then
                DoSave()
                return
            end

            ShowDialog(
                function() return true end,
                "ThemeManager_LowContrastSave",
                "Low contrast theme",
                string.format(
                    "This theme has a contrast ratio of %.1f:1 between %s, below the recommended %.1f:1. Text may be hard to read. Save anyway?",
                    Report.Ratio, Report.PairName, 4.5
                ),
                "Save Anyway",
                DoSave
            )
        end

        groupbox:AddButton("Create theme", function()
            local name = CustomThemeName.Value

            if name:gsub(" ", "") == "" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Invalid theme name (empty).", Time = 3 })
                return
            end

            if string.lower(name) == "default" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Invalid theme name provided.", Time = 3 })
                return
            end

            ShowDialog(
                function()
                    return self:GetCustomTheme(name) ~= nil
                end,
                "ThemeManager_CreateTheme",
                "Theme already exists",
                string.format("A custom theme named %q already exists. Overwriting it will replace it with your current colors.", name),
                "Overwrite",
                function()
                    SaveThemeWithContrastCheck(name, "Created theme %q.", RefreshList)
                end
            )
        end)

        groupbox:AddDivider()

        groupbox:AddDropdown(
            "ThemeManager_CustomThemeList",
            { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1,
                FormatDisplayValue = WithDefaultSuffix, FormatListValue = WithDefaultSuffix }
        )
        CustomThemeList = self.Library.Options.ThemeManager_CustomThemeList

        groupbox:AddButton("Load theme", function()
            local name = CustomThemeList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Please select a theme first.", Time = 3 })
                return
            end

            local success, err = self:ApplyTheme(name)
            if not success then
                self.Library:Notify({ Title = "ThemeManager", Description = "Failed to load theme: " .. tostring(err), Time = 4 })
                return
            end

            self.Library:Notify({ Title = "ThemeManager", Description = string.format("Loaded theme %q.", name), Time = 3 })
        end)
        groupbox:AddButton("Overwrite theme", function()
            local name = CustomThemeList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Please select a theme first.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "ThemeManager_OverwriteTheme",
                "Overwrite theme",
                string.format("Are you sure you want to overwrite %q with your current colors? This cannot be undone.", name),
                "Overwrite",
                function()
                    SaveThemeWithContrastCheck(name, "Overwrote theme %q.")
                end
            )
        end)
        groupbox:AddButton("Delete theme", function()
            local name = CustomThemeList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Please select a theme first.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "ThemeManager_DeleteTheme",
                "Delete theme",
                string.format("Are you sure you want to delete %q? This cannot be undone.", name),
                "Delete",
                function()
                    local success, err = self:Delete(name)
                    if not success then
                        self.Library:Notify({ Title = "ThemeManager", Description = "Failed to delete theme: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "ThemeManager", Description = string.format("Deleted theme %q.", name), Time = 3 })
                    RefreshDefaultThemeLabel()
                end
            )
        end)
        groupbox:AddButton("Refresh list", function()
            RefreshList()
        end)
        groupbox:AddButton("Set as default", function()
            local name = CustomThemeList.Value
            if not name or name == "" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Please select a theme first.", Time = 3 })
                return
            end

            local success, err = self:SaveDefault(name)
            if not success then
                self.Library:Notify({ Title = "ThemeManager", Description = tostring(err), Time = 4 })
                return
            end

            self.Library:Notify(
                string.format("Set default theme to %q", name)
            )
            RefreshDefaultThemeLabel()
        end)
        groupbox:AddButton("Reset default", function()
            ShowDialog(
                function() return true end,
                "ThemeManager_ResetDefault",
                "Reset default theme",
                "Are you sure you want to clear the default theme? The library will revert to its built-in default on next load.",
                "Reset",
                function()
                    local success, err = self:DeleteDefaultTheme()
                    if not success then
                        self.Library:Notify({ Title = "ThemeManager", Description = "Failed to reset default theme: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "ThemeManager", Description = "Reset default theme.", Time = 3 })
                    RefreshDefaultThemeLabel()
                end
            )
        end)

        DefaultThemeLabel = groupbox:AddLabel("Current default theme: ...")

        groupbox:AddDivider()

        groupbox:AddInput("ThemeManager_ThemeJSON", { Text = "Theme JSON", Placeholder = "Paste theme JSON..." })
        ThemeJSONInput = self.Library.Options.ThemeManager_ThemeJSON

        groupbox:AddButton("Import theme", function()
            local content = ThemeJSONInput.Value
            if not content or content:gsub(" ", "") == "" then
                self.Library:Notify({ Title = "ThemeManager", Description = "Theme JSON cannot be empty.", Time = 3 })
                return
            end

            ShowDialog(
                function() return true end,
                "ThemeManager_ImportTheme",
                "Import theme",
                "Are you sure you want to import this theme? Your current colors will be overwritten.",
                "Import",
                function()
                    local success, err = self:LoadJSON(content)
                    if not success then
                        self.Library:Notify({ Title = "ThemeManager", Description = "Failed to import theme: " .. tostring(err), Time = 4 })
                        return
                    end

                    self.Library:Notify({ Title = "ThemeManager", Description = "Imported theme.", Time = 3 })
                end
            )
        end)

        groupbox:AddButton("Export current theme", function()
            local encoded, success, err = self:SaveJSON()
            if not success then
                self.Library:Notify({ Title = "ThemeManager", Description = tostring(err), Time = 4 })
                return
            end

            ThemeJSONInput:SetValue(encoded)
            if setclipboard then
                setclipboard(encoded)
                self.Library:Notify({ Title = "ThemeManager", Description = "Copied theme to your clipboard.", Time = 3 })
            end
        end)

        self:LoadDefault()
        self:UpdateContrastWarning()
        self.AppliedToTab = true

        RefreshDefaultThemeLabel()

        local function UpdateTheme()
            self:ThemeUpdate()
        end

        self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
        self.Library.Options.MainColor:OnChanged(UpdateTheme)
        self.Library.Options.AccentColor:OnChanged(UpdateTheme)
        self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
        self.Library.Options.FontColor:OnChanged(UpdateTheme)
        self.Library.Options.GradientColor:OnChanged(UpdateTheme)
        self.Library.Options.FontFace:OnChanged(function(Value)
            self.Library:SetFont(Enum.Font[Value])
            self.Library:UpdateColorsUsingRegistry()
        end)
        self.Library.Options.BackgroundImage:OnChanged(function(Value)
            self.Library:SetBackgroundImage(Value)
        end)
    end

    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        return tab:AddLeftSection("Themes", "paintbrush")
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "Must set ThemeManager.Library first!")
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

pcall(function()
    getgenv().AstralThemeManager = ThemeManager
end)
return ThemeManager
