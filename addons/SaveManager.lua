local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func)
    return func
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local Players: Players = cloneref(game:GetService("Players"))
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

local function GetDefaultConfigName()
    local player = Players.LocalPlayer
    local name = player and player.Name or "Player"

    name = name:gsub("[^%w_%-]", "")
    if name == "" then name = "Player" end

    return name .. "_Settings"
end

local SaveManager = {}
do
    SaveManager.Folder = "Astral"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil

    SaveManager.LoadingOrder = {}
    SaveManager.UseLoadingOrder = false

    SaveManager.CurrentConfig = nil
    SaveManager._Loading = false

    local function EncodeUDim2(Value: UDim2)
        return {
            X = { Scale = Value.X.Scale, Offset = Value.X.Offset },
            Y = { Scale = Value.Y.Scale, Offset = Value.Y.Offset },
        }
    end

    local function DecodeUDim2(Data: any)
        local DataType = typeof(Data)
        if DataType == "table" then
            return UDim2.new(Data.X.Scale, Data.X.Offset, Data.Y.Scale, Data.Y.Offset)
        elseif DataType == "UDim2" then
            return Data
        end

        return nil
    end

    SaveManager.Parser = {
        Toggle = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value == value then
                    object:RunChanged()
                    return
                end

                object:SetValue(value)
            end,
        },
        Slider = {
            Save = function(object)
                return tostring(object.Value)
            end,
            Load = function(object, value)
                if object.Value == value then
                    object:RunChanged()
                    return
                end

                object:SetValue(value)
            end,
        },
        ProgressBar = {
            Save = function(object)
                return tostring(object.Value)
            end,
            Load = function(object, value)
                if object.Value == value then
                    return
                end

                object:SetValue(value)
            end,
        },
        Dropdown = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value == value then
                    object:RunChanged()
                    return
                end

                object:SetValue(value)
            end,
        },
        ColorPicker = {
            Save = function(object)
                return { value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(object, value)
                object:SetValueRGB(Color3.fromHex(value.value), value.transparency)
            end,
        },
        KeyPicker = {
            Save = function(object)
                return {
                    mode = object.Mode,
                    key = object.Value,
                    modifiers = object.Modifiers,
                }
            end,
            Load = function(object, value)
                if type(value) ~= "table" then return end

                local key = value.key
                local mode = value.mode or object.Mode or object.DefaultMode
                local modifiers = value.modifiers

                object:SetValue({ Key = key, Mode = mode, Modifiers = modifiers })
            end,
        },
        Input = {
            Save = function(object)
                return object.Value
            end,
            Load = function(object, value)
                if object.Value ~= value and type(value) == "string" then
                    object:SetValue(value)
                end
            end,
        },
    }

    function SaveManager:SetLibrary(Library)
        self.Library = Library

        if Library and typeof(Library) == "table" then
            if Library.Toggled then
                warn("[SaveManager] SetLibrary() was called AFTER Library:CreateWindow(). " ..
                    "The window may have already auto-shown with default/unloaded values. " ..
                    "Call SaveManager:SetLibrary(Library) BEFORE Library:CreateWindow(...) instead.")
            end

            Library.DeferAutoShowTo = self
        end
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "GradientColor", "FontFace", "BackgroundImage",
            "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName", "ThemeManager_ThemeJSON",
        })
    end

    --// Config scopes: "Global" configs are shared by every account on this machine,
    --// "Per-User" configs live in a folder named after the account's UserId.
    local ScopeGlobal, ScopeUser = "Global", "Per-User"
    SaveManager.Scope = ScopeGlobal
    SaveManager.ScopeGlobal = ScopeGlobal
    SaveManager.ScopeUser = ScopeUser

    local ReservedNames = { autoload = true, active = true }

    local function GetUserId(): string
        local player = Players.LocalPlayer
        return tostring(player and player.UserId or 0)
    end

    local function EnsureFolder(path: string)
        local parts = path:split("/")
        for idx = 1, #parts do
            local sub = table.concat(parts, "/", 1, idx)
            if not isfolder(sub) then
                pcall(makefolder, sub)
            end
        end
    end

    function SaveManager:GetRootFolder(): string
        local folder = self.Folder .. "/settings"
        if typeof(self.SubFolder) == "string" and self.SubFolder ~= "" then
            folder = folder .. "/" .. self.SubFolder
        end

        return folder
    end

    function SaveManager:GetConfigFolder(scope: string?): string
        local root = self:GetRootFolder()
        if (scope or self.Scope) == ScopeUser then
            return root .. "/users/" .. GetUserId()
        end

        return root
    end

    function SaveManager:BuildFolderTree()
        EnsureFolder(self:GetConfigFolder(ScopeGlobal))

        if self.Scope == ScopeUser then
            EnsureFolder(self:GetConfigFolder(ScopeUser))
        end
    end

    function SaveManager:CheckFolderTree()
        if isfolder(self:GetConfigFolder()) then return end
        self:BuildFolderTree()
    end

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in pairs(list) do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:SetSubFolder(folder)
        self.SubFolder = folder
        self:BuildFolderTree()
    end

    function SaveManager:GetFilePath(name, scope)
        self:CheckFolderTree()
        return self:GetConfigFolder(scope) .. "/" .. name .. ".json"
    end

    --// Remembers which scope and config were last selected, so the next launch picks them back up.
    function SaveManager:ReadActiveState()
        local path = self:GetRootFolder() .. "/active.txt"
        if not isfile(path) then return {} end

        local ok, content = pcall(readfile, path)
        if not ok or typeof(content) ~= "string" then return {} end

        local decoded
        ok, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        if ok and typeof(decoded) == "table" then
            return decoded
        end

        return {}
    end

    function SaveManager:WriteActiveState()
        pcall(function()
            EnsureFolder(self:GetRootFolder())

            local state = self:ReadActiveState()
            state.scope = self.Scope

            if self.Scope == ScopeUser then
                if typeof(state.users) ~= "table" then
                    state.users = {}
                end
                state.users[GetUserId()] = self.CurrentConfig
            else
                state.global = self.CurrentConfig
            end

            writefile(self:GetRootFolder() .. "/active.txt", HttpService:JSONEncode(state))
        end)
    end

    function SaveManager:SetLoadingOrder(Enabled: boolean, Order: { string }?)
        SaveManager.UseLoadingOrder = Enabled == true
        SaveManager.LoadingOrder = typeof(Order) == "table" and Order or SaveManager.LoadingOrder
    end

    function SaveManager:Save(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
        end
        if ReservedNames[string.lower(name)] then
            return false, "Invalid config name provided"
        end
        self:CheckFolderTree()

        local fullPath = self:GetFilePath(name)

        local data = {}

        for idx, toggle in pairs(self.Library.Toggles) do
            if not toggle.Type then continue end
            if not self.Parser[toggle.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[toggle.Type].Save(toggle)
        end

        for idx, option in pairs(self.Library.Options) do
            if not option.Type then continue end
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[option.Type].Save(option)
        end

        --// Keybind menu state
        if self.Library.KeybindFrame then
            local Hidden = {}
            for Index, Option in self.Library.Options do
                if Option.Type == "KeyPicker" and Option.NoUI ~= true and Option.MenuVisible == false then
                    Hidden[Index] = true
                end
            end

            local KeybindMenu = self.Library.KeybindMenu
            local Collapsed = false
            if KeybindMenu and KeybindMenu.IsCollapsed then
                Collapsed = KeybindMenu:IsCollapsed() == true
            elseif self.Library.KeybindContainer then
                Collapsed = not self.Library.KeybindContainer.Visible
            end

            data.__keybindMenu = {
                visible = self.Library.KeybindFrame.Visible,
                position = EncodeUDim2(self.Library.KeybindFrame.Position),
                collapsed = Collapsed,
                hidden = Hidden,
            }
        end

        --// Section folded states
        if self.Library.Tabs then
            local FoldedSections = {}
            for TabIndex, Tab in self.Library.Tabs do
                if typeof(Tab) ~= "table" or Tab.IsKeyTab or not Tab.Sections then continue end

                for SectionIndex, Section in Tab.Sections do
                    if typeof(Section) ~= "table" or Section.Folded ~= true then continue end
                    if typeof(Section.SetFolded) ~= "function" then continue end

                    table.insert(FoldedSections, {
                        tabIdx = typeof(TabIndex) == "string" and TabIndex or Tab.Name,
                        idx = typeof(SectionIndex) == "string" and SectionIndex or Section.Name,
                    })
                end
            end

            if next(FoldedSections) then
                data.__foldedSections = FoldedSections
            end
        end

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return false, "failed to encode data"
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
        end
        self:CheckFolderTree()

        local file = self:GetFilePath(name)
        if not isfile(file) then return false, "invalid file" end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
        if not success then return false, "decode error" end

        self._Loading = true

        --// Keybind menu state
        if typeof(decoded.__keybindMenu) == "table" and self.Library.KeybindFrame then
            local MenuData = decoded.__keybindMenu

            self.Library.KeybindFrame.Visible = MenuData.visible == true

            local Position = DecodeUDim2(MenuData.position)
            if Position then
                self.Library.KeybindFrame.Position = Position
            end

            if self.Library.KeybindContainer then
                self.Library.KeybindContainer.Visible = MenuData.collapsed ~= true
            end

            local KeybindMenu = self.Library.KeybindMenu
            if KeybindMenu and KeybindMenu.SetCollapsed then
                KeybindMenu:SetCollapsed(MenuData.collapsed == true)
            end

            if typeof(MenuData.hidden) == "table" then
                for Index, Option in self.Library.Options do
                    if Option.Type ~= "KeyPicker" or Option.NoUI == true or not Option.SetMenuVisibility then
                        continue
                    end

                    Option:SetMenuVisibility(MenuData.hidden[Index] ~= true)
                end
            end
        end

        --// Section folded states
        if typeof(decoded.__foldedSections) == "table" and self.Library.Tabs then
            for _, Entry in decoded.__foldedSections do
                if typeof(Entry) ~= "table" then continue end

                local Tab = self.Library.Tabs[Entry.tabIdx]
                if typeof(Tab) ~= "table" or not Tab.Sections then continue end

                local Section = Tab.Sections[Entry.idx]
                if typeof(Section) ~= "table" or typeof(Section.SetFolded) ~= "function" then
                    --// Fall back to matching by section name
                    for _, Candidate in Tab.Sections do
                        if typeof(Candidate) == "table" and Candidate.Name == Entry.idx and typeof(Candidate.SetFolded) == "function" then
                            Section = Candidate
                            break
                        end
                    end
                end

                if typeof(Section) == "table" and typeof(Section.SetFolded) == "function" then
                    Section:SetFolded(true)
                end
            end
        end

        --// Elements (optionally in a caller-defined type order)
        local Queue = {}
        for idx, value in pairs(decoded) do
            if self.Ignore[idx] then continue end
            if idx == "__keybindMenu" or idx == "__foldedSections" then continue end

            local object = self.Library.Toggles[idx] or self.Library.Options[idx]
            if object and object.Type and self.Parser[object.Type] then
                table.insert(Queue, { object = object, value = value })
            end
        end

        if SaveManager.UseLoadingOrder == true and typeof(SaveManager.LoadingOrder) == "table" then
            table.sort(Queue, function(a, b)
                local aIndex = table.find(SaveManager.LoadingOrder, a.object.Type) or math.huge
                local bIndex = table.find(SaveManager.LoadingOrder, b.object.Type) or math.huge
                return aIndex < bIndex
            end)
        end

        for _, Entry in Queue do
            pcall(self.Parser[Entry.object.Type].Load, Entry.object, Entry.value)
        end

        task.defer(function()
            self._Loading = false
        end)

        self.CurrentConfig = name
        return true
    end

    function SaveManager:Delete(name)
        if not name or name:gsub(" ", "") == "" then
            return false, "no config file is selected"
        end

        local file = self:GetFilePath(name)
        if not isfile(file) then return false, "invalid file" end

        local success = pcall(delfile, file)
        if not success then return false, "delete file error" end

        return true
    end

    function SaveManager:RefreshConfigList()
        local success, data = pcall(function()
            self:CheckFolderTree()

            local out = {}
            local list = listfiles(self:GetConfigFolder())
            if typeof(list) ~= "table" then list = {} end

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
                        local name = file:sub(pos + 1, start - 1)
                        if not ReservedNames[name] then
                            table.insert(out, name)
                        end
                    end
                end
            end

            table.sort(out, function(a, b) return a:lower() < b:lower() end)

            return out
        end)

        if not success then
            --// This runs on a timer, so only complain once.
            if not self._ListErrorShown then
                self._ListErrorShown = true
                warn("[SaveManager] Failed to load config list: " .. tostring(data))
            end

            return {}
        end

        return data
    end

    --// Keeps the "Config file" dropdown in sync with the folder. Runs on the watcher timer,
    --// so new/removed files show up without any refresh button.
    function SaveManager:RefreshDropdown()
        local dropdown = self.Library and self.Library.Options.SaveManager_ConfigList
        if not dropdown then return end

        local list = self:RefreshConfigList()
        local key = self.Scope .. "|" .. tostring(self.CurrentConfig) .. "|" .. table.concat(list, "\n")
        if key == self._ListKey then return end
        self._ListKey = key

        self._SyncingUI = true
        dropdown:SetValues(list)
        if self.CurrentConfig and table.find(list, self.CurrentConfig) then
            dropdown:SetValue(self.CurrentConfig)
        end
        self._SyncingUI = false
    end

    function SaveManager:SaveJSON()
        local data = {}

        for idx, toggle in pairs(self.Library.Toggles) do
            if not toggle.Type then continue end
            if not self.Parser[toggle.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[toggle.Type].Save(toggle)
        end

        for idx, option in pairs(self.Library.Options) do
            if not option.Type then continue end
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            data[idx] = self.Parser[option.Type].Save(option)
        end

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return nil, false, "Failed to encode data"
        end

        return encoded, true
    end

    function SaveManager:LoadJSON(content)
        if not content or content:gsub(" ", "") == "" then
            return false, "No JSON provided"
        end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        if not success or typeof(decoded) ~= "table" then
            return false, "Failed to decode config data"
        end

        self._Loading = true

        local Queue = {}
        for idx, value in pairs(decoded) do
            if self.Ignore[idx] then continue end
            if idx == "__keybindMenu" or idx == "__foldedSections" then continue end

            local object = self.Library.Toggles[idx] or self.Library.Options[idx]
            if object and object.Type and self.Parser[object.Type] then
                table.insert(Queue, { object = object, value = value })
            end
        end

        if SaveManager.UseLoadingOrder == true and typeof(SaveManager.LoadingOrder) == "table" then
            table.sort(Queue, function(a, b)
                local aIndex = table.find(SaveManager.LoadingOrder, a.object.Type) or math.huge
                local bIndex = table.find(SaveManager.LoadingOrder, b.object.Type) or math.huge
                return aIndex < bIndex
            end)
        end

        for _, Entry in Queue do
            pcall(self.Parser[Entry.object.Type].Load, Entry.object, Entry.value)
        end

        task.defer(function()
            self._Loading = false
        end)

        return true
    end

    function SaveManager:ResetToDefaults()
        self._Loading = true

        for idx, toggle in pairs(self.Library.Toggles) do
            if self.Ignore[idx] then continue end
            if toggle.Default ~= nil and toggle.SetValue then
                pcall(toggle.SetValue, toggle, toggle.Default)
            end
        end

        for idx, option in pairs(self.Library.Options) do
            if self.Ignore[idx] then continue end

            if option.Type == "KeyPicker" and option.SetValue then
                local key = option.DefaultKey or option.Default or "None"
                local mode = option.DefaultMode or option.Mode
                local modifiers = table.clone(option.DefaultModifiers or {})

                pcall(option.SetValue, option, {
                    Key = key,
                    Mode = mode,
                    Modifiers = modifiers,
                })
            elseif option.Default ~= nil and option.SetValue then
                pcall(option.SetValue, option, option.Default)
            end
        end

        task.defer(function()
            self._Loading = false
        end)
    end

    function SaveManager:AutoSave()
        if self._Loading then return end
        if not self.CurrentConfig then return end

        self:Save(self.CurrentConfig)
    end

    local function Fingerprint(objectType, object)
        local ok, saved = pcall(SaveManager.Parser[objectType].Save, object)
        if not ok then return nil end

        local ok2, encoded = pcall(HttpService.JSONEncode, HttpService, saved)
        if not ok2 then return nil end

        return encoded
    end

    function SaveManager:StartAutoSaveWatcher()
        assert(self.Library, "Must set SaveManager.Library")

        if self._Watching then return end
        self._Watching = true

        task.spawn(function()
            local lastState = {}

            local function Snapshot()
                local state = {}

                for idx, toggle in pairs(self.Library.Toggles) do
                    if self.Ignore[idx] then continue end
                    if not toggle.Type or not self.Parser[toggle.Type] then continue end

                    state[idx] = Fingerprint(toggle.Type, toggle)
                end

                for idx, option in pairs(self.Library.Options) do
                    if self.Ignore[idx] then continue end
                    if not option.Type or not self.Parser[option.Type] then continue end

                    state[idx] = Fingerprint(option.Type, option)
                end

                return state
            end

            lastState = Snapshot()

            while self._Watching do
                task.wait(0.5)

                pcall(function() self:RefreshDropdown() end)

                local newState = Snapshot()
                local changed = false

                if not self._Loading then
                    for idx, value in pairs(newState) do
                        if lastState[idx] ~= value then
                            changed = true
                            break
                        end
                    end

                    if not changed then
                        for idx in pairs(lastState) do
                            if newState[idx] == nil then
                                changed = true
                                break
                            end
                        end
                    end
                end

                lastState = newState

                if changed then
                    self:AutoSave()
                end
            end
        end)
    end

    --// Picks the config to use on startup (creating one when the scope has none) and loads it.
    function SaveManager:EnsureStartupConfig()
        local state = self:ReadActiveState()

        if not self._ScopeRestored then
            self._ScopeRestored = true
            if state.scope == ScopeGlobal or state.scope == ScopeUser then
                self.Scope = state.scope
            end
        end

        self:BuildFolderTree()

        local Selected
        if self.Scope == ScopeUser then
            if typeof(state.users) == "table" then
                Selected = state.users[GetUserId()]
            end
        else
            Selected = state.global

            --// Older versions stored an "autoload" config name; keep honoring it.
            local legacyPath = self:GetRootFolder() .. "/autoload.txt"
            if Selected == nil and isfile(legacyPath) then
                local ok, legacyName = pcall(readfile, legacyPath)
                if ok and typeof(legacyName) == "string" then
                    Selected = legacyName
                end
            end
        end

        local list = self:RefreshConfigList()
        local DefaultName = self.Scope == ScopeUser and "Default" or GetDefaultConfigName()

        local Name
        if typeof(Selected) == "string" and table.find(list, Selected) then
            Name = Selected
        elseif table.find(list, DefaultName) then
            Name = DefaultName
        elseif #list > 0 then
            Name = list[1]
        end

        if Name then
            self:Load(Name)
        else
            --// No config yet: create one from the current defaults.
            self:ResetToDefaults()
            self.CurrentConfig = DefaultName
            self:Save(DefaultName)
        end

        self:WriteActiveState()
        return self.CurrentConfig
    end

    --// Switch to another config in the current scope. The config being left is saved first.
    function SaveManager:SelectConfig(name: string, silent: boolean?)
        if typeof(name) ~= "string" or name == "" or name == self.CurrentConfig then
            return false
        end

        self:AutoSave()

        local success, err = self:Load(name)
        if not success then
            self.Library:Notify({ Title = "SaveManager", Description = "Failed to load config: " .. tostring(err), Time = 4 })
            self._ListKey = nil
            self:RefreshDropdown()
            return false
        end

        self:WriteActiveState()

        if not silent then
            self.Library:Notify({ Title = "SaveManager", Description = string.format("Using config %q.", name), Time = 3 })
        end

        return true
    end

    --// Switch between Global and Per-User configs.
    function SaveManager:SetScope(scope: string)
        if scope ~= ScopeGlobal and scope ~= ScopeUser then
            return false, "Invalid config scope"
        end
        if scope == self.Scope then
            return true
        end

        self:AutoSave()

        self.Scope = scope
        self.CurrentConfig = nil
        self:EnsureStartupConfig()

        self._ListKey = nil
        self:RefreshDropdown()

        return true
    end

    --// Creates a new config from the current settings and starts using it.
    function SaveManager:CreateConfig(name: string)
        name = typeof(name) == "string" and (name:gsub("^%s+", ""):gsub("%s+$", "")) or ""

        if name == "" then
            return false, "Config name cannot be empty"
        end
        if name:find('[\\/:*?"<>|]') or ReservedNames[string.lower(name)] then
            return false, "Invalid config name provided"
        end
        if isfile(self:GetFilePath(name)) then
            return false, string.format("A config named %q already exists", name)
        end

        self:AutoSave()

        local success, err = self:Save(name)
        if not success then
            return false, err
        end

        self.CurrentConfig = name
        self:WriteActiveState()

        self._ListKey = nil
        self:RefreshDropdown()

        return true
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library")

        self:EnsureStartupConfig()

        local section = tab:AddRightSection("Configuration", "folder-cog")

        section:AddDropdown("SaveManager_Scope", {
            Text = "Config type",
            Values = { ScopeGlobal, ScopeUser },
            Default = self.Scope,
            Tooltip = "Global configs are shared by every account. Per-User configs belong to the account you are playing on.",
        })

        section:AddDropdown("SaveManager_ConfigList", {
            Text = "Config file",
            Values = self:RefreshConfigList(),
            Default = self.CurrentConfig,
        })

        section:AddInput("SaveManager_ConfigName", {
            Text = "Config name",
            Placeholder = "New config name...",
        })

        section:AddButton({ Text = "Create config", Func = function()
            local NameInput = self.Library.Options.SaveManager_ConfigName
            local success, err = self:CreateConfig(NameInput.Value)
            if not success then
                self.Library:Notify({ Title = "SaveManager", Description = tostring(err), Time = 4 })
                return
            end

            self.Library:Notify({ Title = "SaveManager", Description = string.format("Created config %q.", self.CurrentConfig), Time = 3 })
            NameInput:SetValue("")
        end })

        section:AddButton({ Text = "Delete config", Risky = true, Func = function()
            local Selected = self.CurrentConfig
            if not Selected then
                self.Library:Notify({ Title = "SaveManager", Description = "No config selected.", Time = 3 })
                return
            end
            
            self.Library.Window:AddDialog("DeleteConfig_" .. Selected, {
                Title = "Delete config",
                Description = string.format("Are you sure you want to delete %q? This cannot be undone.", Selected),
                Icon = "trash-2",
                FooterButtons = {
                    Cancel = { Title = "Cancel", Variant = "Secondary", Order = 1 },
                    Delete = { Title = "Delete", Variant = "Destructive", Order = 2, Callback = function(dialog)
                        local success, err = self:Delete(Selected)
                        if success then
                            self.CurrentConfig = nil
                            self._ListKey = nil -- Forces dropdown refresh
                            self:RefreshDropdown()
                            self.Library:Notify({ Title = "SaveManager", Description = string.format("Deleted config %q.", Selected), Time = 3 })
                        else
                            self.Library:Notify({ Title = "SaveManager", Description = "Failed to delete: " .. tostring(err), Time = 4 })
                        end
                        dialog:Dismiss()
                    end }
                }
            })
        end })

        section:AddLabel({ Text = "Changes are saved to the selected config automatically.", DoesWrap = true })

        self:SetIgnoreIndexes({ "SaveManager_Scope", "SaveManager_ConfigList", "SaveManager_ConfigName" })

        self.Library.Options.SaveManager_Scope:OnChanged(function(Value)
            if self._SyncingUI or Value == self.Scope then return end

            local success, err = self:SetScope(Value)
            if not success then
                self.Library:Notify({ Title = "SaveManager", Description = tostring(err), Time = 4 })
                return
            end

            self.Library:Notify({
                Title = "SaveManager",
                Description = string.format("Using %s config %q.", Value, tostring(self.CurrentConfig)),
                Time = 3,
            })
        end)

        self.Library.Options.SaveManager_ConfigList:OnChanged(function(Value)
            if self._SyncingUI or not Value or Value == self.CurrentConfig then return end

            self:SelectConfig(Value)
        end)

        self:StartAutoSaveWatcher()

        task.defer(function()
            if self.CurrentConfig then
                self:Load(self.CurrentConfig)
            end

            self:RevealAfterLoad()
        end)
    end

    function SaveManager:RevealAfterLoad()
        local Lib = self.Library
        local Window = Lib

        local AutoShow = true
        if Window and typeof(Window) == "table" and Window.AutoShow ~= nil then
            AutoShow = Window.AutoShow
        elseif Lib and Lib.AutoShow ~= nil then
            AutoShow = Lib.AutoShow
        end

        local LibraryTable = (Lib and typeof(Lib) == "table" and Lib) or (Window and typeof(Window) == "table" and Window.Library)
        if LibraryTable then
            while LibraryTable.ActiveLoading do
                task.wait()
            end
        end

        if Window and Window.Toggle then
            Window:Toggle(AutoShow)
        elseif Window and typeof(Window) == "table" and Window.Library and Window.Library.Toggle then
            Window.Library:Toggle(AutoShow)
        end

        if LibraryTable and LibraryTable.DeferAutoShowTo == self then
            LibraryTable.DeferAutoShowTo = nil
        end
    end

    function SaveManager:Init(Window)
        assert(self.Library, "Must set SaveManager.Library")
        Window = Window or self.Library

        if self.CurrentConfig then
            self:Load(self.CurrentConfig)
        else
            self:EnsureStartupConfig()
        end

        self:RevealAfterLoad()
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
