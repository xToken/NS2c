// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenu.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at) and
//                  Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/WindowManager.lua")
Script.Load("lua/GUIAnimatedScript.lua")
Script.Load("lua/menu/MenuMixin.lua")
Script.Load("lua/menu/Link.lua")
Script.Load("lua/menu/SlideBar.lua")
Script.Load("lua/menu/ContentBox.lua")
Script.Load("lua/menu/Image.lua")
Script.Load("lua/menu/Table.lua")
Script.Load("lua/menu/Ticker.lua")
Script.Load("lua/ServerBrowser.lua")
Script.Load("lua/menu/Form.lua")
Script.Load("lua/dkjson.lua")

local kMainMenuLinkColor = Color(137 / 255, 137 / 255, 137 / 255, 1)

class 'GUIMainMenu' (GUIAnimatedScript)

Script.Load("lua/menu/GUIMainMenu_FindPeople.lua")
Script.Load("lua/menu/GUIMainMenu_PlayNow.lua")
Script.Load("lua/menu/GUIMainMenu_Mods.lua")
Script.Load("lua/menu/GUIMainMenu_Tutorial.lua")

// Min and maximum values for the mouse sensitivity slider
local kMinSensitivity = 1
local kMaxSensitivity = 20

local kMinAcceleration = 1
local kMaxAcceleration = 1.4

local kDisplayModes = { "windowed", "fullscreen", "fullscreen-windowed" }
local kAmbientOcclusionModes = { "off", "medium", "high" }

    
local kLocales =
    {
        { name = "enUS", label = "English" },
        { name = "frFR", label = "French" },
        { name = "deDE", label = "German" },
        { name = "koKR", label = "Korean" },
        { name = "plPL", label = "Polish" },
        { name = "esES", label = "Spanish" },
        { name = "seSW", label = "Swedish" },
    }

function GUIMainMenu:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    Shared.Message("Main Menu Initialized at Version: " .. Shared.GetBuildNumber())
    
    // provides a set of functions required for window handling
    AddMenuMixin(self)
    self:SetCursor("ui/Cursor_MenuDefault.dds")
    self:SetWindowLayer(kWindowLayerMainMenu)
    
    LoadCSSFile("lua/menu/main_menu.css")
    
    self.mainWindow = self:CreateWindow()
    self.mainWindow:SetCSSClass("main_frame")
    
    self.tvGlareImage = CreateMenuElement(self.mainWindow, "Image")
    self.tvGlareImage:SetCSSClass("tvglare")
    
    self.mainWindow:DisableTitleBar()
    self.mainWindow:DisableResizeTile()
    self.mainWindow:DisableCanSetActive()
    self.mainWindow:DisableContentBox()
    self.mainWindow:DisableSlideBar()
    
    self.showWindowAnimation = CreateMenuElement(self.mainWindow, "Font", false)
    self.showWindowAnimation:SetCSSClass("showwindow_hidden")
    
    self.openedWindows = 0
    self.numMods = 0
    
    local eventCallbacks =
    {
        OnEscape = function (self)
        
            if MainMenu_IsInGame() then
                self.scriptHandle:SetIsVisible(false)
            end
            
        end,
        
        OnShow = function (self)
            MainMenu_Open()
        end,
        
        OnHide = function (self)
        
            if MainMenu_IsInGame() then
            
                MainMenu_ReturnToGame()
                return true
                
            else
                return false
            end
            
        end
    }
    
    self.mainWindow:AddEventCallbacks(eventCallbacks)
    
    self:CreatePlayWindow()
    self:CreateTutorialWindow()
    self:CreateOptionWindow()
    self:CreateModsWindow()
    self:CreatePasswordPromptWindow()
    self:CreateAlertWindow()
    
    local TriggerOpenAnimation = function(window)
    
        if not window:GetIsVisible() then
        
            window.scriptHandle.windowToOpen = window
            window.scriptHandle:SetShowWindowName(window:GetWindowName())
            
        end
        
    end
    
    self.scanLine = CreateMenuElement(self.mainWindow, "Image")
    self.scanLine:SetCSSClass("scanline")

    self.tweetText = CreateMenuElement(self.mainWindow, "Ticker")
    
    self.logo = CreateMenuElement(self.mainWindow, "Image")
    self.logo:SetCSSClass("logo")
    
    self:CreateMenuBackground()
    self:CreateProfile()
    
    if MainMenu_IsInGame() then
    
        // Create "resume playing" button
        self.resumeLink = self:CreateMainLink("RESUME GAME", "resume_ingame", "01")
        self.resumeLink:AddEventCallbacks(
        {
            OnClick = function(self)
                self.scriptHandle:SetIsVisible(not self.scriptHandle:GetIsVisible())
            end
        })
        
        // Create "go to ready room" button
        self.readyRoomLink = self:CreateMainLink("GO TO READY ROOM", "readyroom_ingame", "02")
        self.readyRoomLink:AddEventCallbacks(
        {
            OnClick = function(self)
                self.scriptHandle:SetIsVisible(not self.scriptHandle:GetIsVisible())
                Shared.ConsoleCommand("rr")
            end
        })
        
        self.playLink = self:CreateMainLink("PLAY", "play_ingame", "03")
        self.playLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.playWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.optionLink = self:CreateMainLink("OPTIONS", "options_ingame", "04")
        self.optionLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.optionWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.tutorialLink = self:CreateMainLink("TRAINING", "tutorial_ingame", "05")
        self.tutorialLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.tutorialWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        // Create "disconnect" button
        self.disconnectLink = self:CreateMainLink("DISCONNECT", "disconnect_ingame", "06")
        self.disconnectLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                self.scriptHandle:HideMenu()
                
                Shared.ConsoleCommand("disconnect")

                self.scriptHandle:ShowMenu()
                
            end
        })
        
    else
    
        self.playLink = self:CreateMainLink("PLAY", "play", "01")
        self.playLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.playWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.tutorialLink = self:CreateMainLink("TRAINING", "tutorial", "02")
        self.tutorialLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.tutorialWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.optionLink = self:CreateMainLink("OPTIONS", "options", "03")
        self.optionLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.optionWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.modsLink = self:CreateMainLink("MODS", "mods", "04")
        self.modsLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                TriggerOpenAnimation(self.scriptHandle.modsWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.quitLink = self:CreateMainLink("EXIT", "exit", "04")
        self.quitLink:AddEventCallbacks(
        {
            OnClick = function(self)
                Client.Exit()
            end
        })
        
    end
    
end

function GUIMainMenu:SetShowWindowName(name)

    self.showWindowAnimation:SetText(ToString(name))
    self.showWindowAnimation:GetBackground():DestroyAnimations()
    self.showWindowAnimation:SetIsVisible(true)
    self.showWindowAnimation:SetCSSClass("showwindow_hidden")
    self.showWindowAnimation:SetCSSClass("showwindow_animation1")
    
end

function GUIMainMenu:CreateMainLink(text, className, linkNum)

    local mainLink = CreateMenuElement(self.menuBackground, "Link")
    mainLink:SetText(text)
    mainLink:SetCSSClass(className)
    mainLink:SetTextColor(kMainMenuLinkColor)
    mainLink:SetBackgroundColor(Color(1,1,1,0))
    mainLink:EnableHighlighting()
    
    mainLink.linkIcon = CreateMenuElement(mainLink, "Font")
    mainLink.linkIcon:SetText(linkNum)
    mainLink.linkIcon:SetCSSClass(className)
    mainLink.linkIcon:SetTextColor(Color(1,1,1,0))
    mainLink.linkIcon:EnableHighlighting()
    mainLink.linkIcon:SetBackgroundColor(Color(1,1,1,0))
    
    local eventCallbacks =
    {
        OnMouseIn = function (self, buttonPressed)
            MainMenu_OnMouseIn()
        end,
        
        OnMouseOver = function (self, buttonPressed)        
            self.linkIcon:OnMouseOver(buttonPressed)
        end,
        
        OnMouseOut = function (self, buttonPressed)
            self.linkIcon:OnMouseOut(buttonPressed) 
            MainMenu_OnMouseOut()
        end
    }
    
    mainLink:AddEventCallbacks(eventCallbacks)
    
    return mainLink
    
end

function GUIMainMenu:Uninitialize()

    self:DestroyAllWindows()    
    GUIAnimatedScript.Uninitialize(self)
    
end

function GUIMainMenu:CreateMenuBackground()

    self.menuBackground = CreateMenuElement(self.mainWindow, "Image")
    self.menuBackground:SetCSSClass("menu_bg_show")
    
end

function GUIMainMenu:CreateProfile()

    self.profileBackground = CreateMenuElement(self.menuBackground, "Image")
    self.profileBackground:SetCSSClass("profile")


    local eventCallbacks =
    {
        // Trigger initial animation
        OnShow = function(self)
        
            // Passing updateChildren == false to prevent updating of children
            self:SetCSSClass("profile", false)
            
        end,
        
        // Destroy all animation and reset state
        OnHide = function(self) end
    }
    
    self.profileBackground:AddEventCallbacks(eventCallbacks)
    
    // create avatar icon.
    self.avatar = CreateMenuElement(self.profileBackground, "Image")
    self.avatar:SetCSSClass("avatar")
    self.avatar:SetBackgroundTexture("*avatar")
        
    // create SE and dev tools icons, TODO: set correct CSS class
    self.seIcon = CreateMenuElement(self.profileBackground, "Image")
    self.seIcon:SetCSSClass("se_enabled")
    self.seIcon:EnableHighlighting()
    
    self.devToolsIcon = CreateMenuElement(self.profileBackground, "Image")
    self.devToolsIcon:SetCSSClass("devtoolsicon")  
    self.devToolsIcon:EnableHighlighting()  
    
    // create dlc icons    
    self.dlcIcons = {}
    for _, dlc in ipairs(MainMenu_GetDLCs()) do
    
        local dlcIcon = CreateMenuElement(self.profileBackground, "Image")
        dlcIcon:SetCSSClass(dlc)
        dlcIcon:EnableHighlighting() 
        table.insert(self.dlcIcons, dlcIcon)
    
    end
    
    self.playerName = CreateMenuElement(self.profileBackground, "Font")
    self.playerName:SetCSSClass("profile")
    
end  

local function FinishWindowAnimations(self)
    self:GetBackground():EndAnimations()
end    

local function RefreshServerList(self)

    self.numServers = 0
    self.refreshingServerList = true
    self.serverTable:ClearChildren()
    Client.RebuildServerList()
    self.playWindow.refreshButton:SetText("REFRESHING...")
    self.selectServer:SetIsVisible(false)
    
end

function GUIMainMenu:ProcessJoinServer()

    if MainMenu_GetSelectedServer() ~= nil then
    
        if MainMenu_GetSelectedRequiresPassword() then
            self.passwordPromptWindow:SetIsVisible(true)
        else
            MainMenu_JoinSelected()
        end
        
    end
    
end

function GUIMainMenu:CreateAlertWindow()

    self.alertWindow = self:CreateWindow()    
    self.alertWindow:SetWindowName("ALERT")
    self.alertWindow:SetInitialVisible(false)
    self.alertWindow:SetIsVisible(false)
    self.alertWindow:DisableResizeTile()
    self.alertWindow:DisableSlideBar()
    self.alertWindow:DisableContentBox()
    self.alertWindow:SetCSSClass("alert_window")
    self.alertWindow:DisableCloseButton()
    self.alertWindow:AddEventCallbacks( { OnBlur = function(self) self:SetIsVisible(false) end } )
    
    self.alertText = CreateMenuElement(self.alertWindow, "Font")
    self.alertText:SetCSSClass("alerttext")
    
    local okButton = CreateMenuElement(self.alertWindow, "MenuButton")
    okButton:SetCSSClass("bottomcenter")
    okButton:SetText("OK")
    
    okButton:AddEventCallbacks({ OnClick = function (self)

        self.scriptHandle.alertWindow:SetIsVisible(false)

    end  })
    
end 

function GUIMainMenu:CreatePasswordPromptWindow()

    self.passwordPromptWindow = self:CreateWindow()    
    self.passwordPromptWindow:SetWindowName("ENTER PASSWORD")
    self.passwordPromptWindow:SetInitialVisible(false)
    self.passwordPromptWindow:SetIsVisible(false)
    self.passwordPromptWindow:DisableResizeTile()
    self.passwordPromptWindow:DisableSlideBar()
    self.passwordPromptWindow:DisableContentBox()
    self.passwordPromptWindow:SetCSSClass("passwordprompt_window")
    self.passwordPromptWindow:DisableCloseButton()
    
    self.passwordPromptWindow:AddEventCallbacks( { OnBlur = function(self) self:SetIsVisible(false) end } )
    
    self.passwordForm = CreateMenuElement(self.passwordPromptWindow, "Form", false)
    self.passwordForm:SetCSSClass("passwordprompt")

    // Password entry
    local textinput = self.passwordForm:CreateFormElement(Form.kElementType.TextInput, "PASSWORD", Client.GetOptionString("serverPassword", ""))
    textinput:SetCSSClass("serverpassword")
    
    
    local descriptionText = CreateMenuElement(self.passwordPromptWindow.titleBar, "Font", false)
    descriptionText:SetCSSClass("passwordprompt_title")
    descriptionText:SetText("ENTER PASSWORD")

    local joinServer = CreateMenuElement(self.passwordPromptWindow, "MenuButton")
    joinServer:SetCSSClass("bottomcenter")
    joinServer:SetText("JOIN")
    
    joinServer:AddEventCallbacks({ OnClick =
    function (self)
    
        local formData = self.scriptHandle.passwordForm:GetFormData()
        MainMenu_SetSelectedServerPassword(formData.PASSWORD)
        MainMenu_JoinSelected()
        
    end })
    
end

function GUIMainMenu:CreateServerListWindow()

    self.playWindow:GetContentBox():SetCSSClass("server_list")
    
    local refresh = CreateMenuElement(self.playWindow, "MenuButton")
    refresh:SetCSSClass("refresh")
    refresh:SetText("REFRESH")
    self.playWindow.refreshButton = refresh
    refresh:AddEventCallbacks({ 
        OnClick = function() 
            RefreshServerList(self) 
        end 
    })
    
    self.joinServerButton = CreateMenuElement(self.playWindow, "MenuButton")
    self.joinServerButton:SetCSSClass("apply")
    self.joinServerButton:SetText("JOIN")
    self.joinServerButton:AddEventCallbacks( {OnClick = function(self) self.scriptHandle:ProcessJoinServer() end } )
    
    self.highlightServer = CreateMenuElement(self.playWindow:GetContentBox(), "Image")
    self.highlightServer:SetCSSClass("highlight_server")
    self.highlightServer:SetIgnoreEvents(true)
    self.highlightServer:SetIsVisible(false)
    
    self.blinkingArrow = CreateMenuElement(self.highlightServer, "Image")
    self.blinkingArrow:SetCSSClass("blinking_arrow")
    self.blinkingArrow:GetBackground():SetInheritsParentStencilSettings(false)
    self.blinkingArrow:GetBackground():SetStencilFunc(GUIItem.Always)
    
    self.selectServer = CreateMenuElement(self.playWindow:GetContentBox(), "Image")
    self.selectServer:SetCSSClass("select_server")
    self.selectServer:SetIsVisible(false)
    self.selectServer:SetIgnoreEvents(true)

    self.serverRowNames = CreateMenuElement(self.playWindow, "Table")
    self.serverTable = CreateMenuElement(self.playWindow:GetContentBox(), "Table")

    local columnClassNames =
    {
        "private",
        "servername",
        "game",
        "map",
        "players",
        "ping"
    }
 
    
    local rowNames = { { "", "NAME", "GAME", "MAP", "PLAYERS", "PING" } }

    -- closure
    local serverTable   = self.serverTable
    local reverse       = false
    local sortedColumn  = nil

    local entryCallbacks = {
        {
                OnClick = function()

                    serverTable:SetSortRow(true)
                    if sortedColumn ~= 1 then
                        sortedColumn = 1
                        reverse = false
                    else
                        reverse = not reverse
                    end
                    
                    if reverse then
                        serverTable:SetComparator(function(a,b) 
                            return (a[1] and 1 or 0) > (b[1] and 1 or 0)
                        end, reverse)
                    else
                        serverTable:SetComparator(function(a,b) 
                            return (a[1] and 1 or 0) < (b[1] and 1 or 0)
                        end, reverse)
                    end   

                end
        },
        {
            OnClick = function()
                
                serverTable:SetSortRow(true)
                if sortedColumn ~= 2 then
                    sortedColumn = 2
                    reverse = false
                else
                    reverse = not reverse
                end
                
                if reverse then
                    serverTable:SetComparator(function(a,b) 
                        return a[2][1]:upper() > b[2][1]:upper()
                    end, reverse)
                else
                    serverTable:SetComparator(function(a,b) 
                        return a[2][1]:upper() < b[2][1]:upper()
                    end, reverse)
                end

            end
        },

        {
            OnClick = function()

                /* =Game type not used yet=
                serverTable:SetSortRow(true)
                reverse = not reverse
                
                if reverse then
                    serverTable:SetComparator(function(a,b) 
                        return a[2][1]:upper() > b[2][1]:upper()
                    end, reverse)
                else
                    serverTable:SetComparator(function(a,b) 
                        return a[2][1]:upper() < b[2][1]:upper()
                    end, reverse)
                end
                */
                
            end
        },

        {
            OnClick = function()

                serverTable:SetSortRow(true)
                if sortedColumn ~= 4 then
                    sortedColumn = 4
                    reverse = false
                else
                    reverse = not reverse
                end
                
                if reverse then
                    serverTable:SetComparator(function(a,b) 
                        return a[4]:upper() > b[4]:upper()
                    end, reverse)
                else
                    serverTable:SetComparator(function(a,b) 
                        return a[4]:upper() < b[4]:upper()
                    end, reverse)
                end

            end
        },

        {
            OnClick = function()

                serverTable:SetSortRow(true)
                if sortedColumn ~= 5 then
                    sortedColumn = 5
                    // Sort player count in a descending order - we want full servers first!
                    reverse = true
                else
                    reverse = not reverse
                end
 
                if reverse then
                    serverTable:SetComparator(function(a,b) 
                        return tonumber(a[5][1]) > tonumber(b[5][1])
                    end, reverse)
                else
                    serverTable:SetComparator(function(a,b) 
                        return tonumber(a[5][1]) < tonumber(b[5][1])
                    end, reverse)
                end

            end
        },

        {
            OnClick = function()

                serverTable:SetSortRow(true)
                if sortedColumn ~= 6 then
                    sortedColumn = 6
                    reverse = false
                else
                    reverse = not reverse
                end

                if reverse then
                    serverTable:SetComparator(function(a,b) 
                        return tonumber(a[6]) > tonumber(b[6])
                    end)
                else
                    serverTable:SetComparator(function(a,b) 
                        return tonumber(a[6]) < tonumber(b[6])
                    end)
                end

            end
        },
    }
    
    
    self.serverRowNames:SetCSSClass("server_list_row_names")
    self.serverRowNames:SetColumnClassNames(columnClassNames)
    self.serverRowNames:SetEntryCallbacks(entryCallbacks)
    self.serverRowNames:SetRowPattern( {RenderServerNameEntry} )
    self.serverRowNames:SetTableData(rowNames)
    
    self.serverTable:SetCSSClass("server_list")
    
    local rowPattern =
    {
        RenderPrivateEntry,
        RenderServerNameEntry,
        RenderStatusIconsEntry,
        RenderMapNameEntry,
        RenderPlayerCountEntry,
        RenderPingEntry
    }
    
    self.serverTable:SetRowPattern(rowPattern)
    self.serverTable:SetColumnClassNames(columnClassNames)
    
    local OnRowCreate = function(row)
    
        local eventCallbacks =
        {
            OnMouseIn = function(self, buttonPressed)
                MainMenu_OnMouseIn()
            end,
            
            OnMouseOver = function(self)
            
                local height = self:GetHeight()
                local topOffSet = self:GetBackground():GetPosition().y + self:GetParent():GetBackground():GetPosition().y
                self.scriptHandle.highlightServer:SetBackgroundPosition(Vector(0, topOffSet, 0), true)
                self.scriptHandle.highlightServer:SetIsVisible(true)
                
            end,
            
            OnMouseOut = function(self)
                self.scriptHandle.highlightServer:SetIsVisible(false)
            end,
            
            OnMouseDown = function(self, key, doubleClick)
            
                local height = self:GetHeight()
                local topOffSet = self:GetBackground():GetPosition().y + self:GetParent():GetBackground():GetPosition().y
                self.scriptHandle.selectServer:SetBackgroundPosition(Vector(0, topOffSet, 0), true)
                self.scriptHandle.selectServer:SetIsVisible(true)
                MainMenu_SelectServer(self:GetId())
                
                if doubleClick then
                
                    if (self.timeOfLastClick ~= nil and (Shared.GetTime() < self.timeOfLastClick + .3)) then
                        self.scriptHandle:ProcessJoinServer()
                    end
                    
                end
                
                self.timeOfLastClick = Shared.GetTime()
                
            end
        }
        
        row:AddEventCallbacks(eventCallbacks)
        row:SetChildrenIgnoreEvents(true)
        
    end
    
    self.serverTable:SetRowCreateCallback(OnRowCreate)
    
    self.playWindow:AddEventCallbacks({ 
        OnShow = function() 
            // Default to sorting by ping!
            sortedColumn = nil
            entryCallbacks[6].OnClick()
            RefreshServerList(self) 
        end 
    })
    
end

local function SaveServerSettings(self)

    local formData = self.createServerForm:GetFormData()
    Client.SetOptionString("serverName", formData.ServerName)
    Client.SetOptionString("mapName", formData.Map)
    Client.SetOptionString("gameMod", formData.GameMode)
    Client.SetOptionInteger("playerLimit", formData.PlayerLimit)
    Client.SetOptionString("serverPassword", formData.Password)
    
end

local function CreateExploreServer(self)

    local formData = self.createExploreServerForm:GetFormData()
    
    local modIndex      = Client.GetLocalModId("explore")
    
    if modIndex == -1 then
        Shared.Message("Explore mode does not exist!")
        return
    end
    
    local password      = formData.Password
    local port          = 27015
    local maxPlayers    = formData.PlayerLimit
    local serverName    = formData.ServerName
    local mapName       = "ns2_" .. string.lower(formData.Map)
    
    if Client.StartServer(modIndex, mapName, serverName, password, port, maxPlayers) then
        LeaveMenu()
    end
    
end

local function CreateServer(self)

    SaveServerSettings(self)
    local formData = self.createServerForm:GetFormData()
    
    local modIndex      = self.createServerForm.modIds[formData.Map_index]
    local password      = formData.Password
    local port          = 27015
    local maxPlayers    = formData.PlayerLimit
    local serverName    = formData.ServerName
    
    if modIndex == 0 then
        local mapName = formData.GameMode .. "_" .. string.lower(formData.Map)
        if Client.StartServer(mapName, serverName, password, port, maxPlayers) then
            LeaveMenu()
        end
    else
        if Client.StartServer(modIndex, serverName, password, port, maxPlayers) then
            LeaveMenu()
        end
    end
    
end

function GUIMainMenu:CreateServerDetailWindow()

    self.serverDetailWindow = self:CreateWindow()
    self:SetupWindow(self.hostGameWindow, "SERVER DETAIL")
    self.serverDetailWindow:DisableSlideBar()
    self.serverDetailWindow:AddEventCallbacks({ OnShow = function() LoadServerDetails(self) end })

end
 
local function GetMaps()

    Client.RefreshModList()
    
    local mapNames = { }
    local modIds   = { }
    
    // First add all of the maps that ship with the game into the list.
    // These maps don't have corresponding mod ids since they are loaded
    // directly from the main game.
    local shippedMaps = MainMenu_GetMapNameList()
    for i = 1, #shippedMaps do
        mapNames[i] = shippedMaps[i]
        modIds[i]   = 0
    end
    
    // TODO: Add levels from mods we have installed
    
    return mapNames, modIds

end

GUIMainMenu.CreateOptionsForm = function(mainMenu, content, options)

    local form = CreateMenuElement(content, "Form", false)
    
    local rowHeight = 50
    
    for i = 1, #options do
    
        local option = options[i]
        local input
        
        if option.type == "select" then
            input = form:CreateFormElement(Form.kElementType.DropDown, option.name, option.value)
            if option.values then
                input:SetOptions(option.values)
            end                
        elseif option.type == "slider" then
            input = form:CreateFormElement(Form.kElementType.SlideBar, option.name, option.value)
            // HACK: Really should use input:AddSetValueCallback, but the slider bar bypasses that.
            if option.sliderCallback then
                input:Register(
					{OnSlide =
						function(value, interest)
							option.sliderCallback(mainMenu)
						end
					}, SLIDE_HORIZONTAL)
            end
        else
            input = form:CreateFormElement(Form.kElementType.TextInput, option.name, option.value)
        end
        
        if option.callback then
            input:AddSetValueCallback(option.callback)
        end
        
        local y = rowHeight * (i - 1)
        
        input:SetCSSClass("option_input")
        input:SetTopOffset(y)
        
        local label = CreateMenuElement(form, "Font", false)
        label:SetCSSClass("option_label")
        label:SetText(option.label .. ":")
        label:SetTopOffset(y)
        label:SetIgnoreEvents(true)

        mainMenu.optionElements[option.name] = input
        
    end
    
    form:SetCSSClass("options")
    return form

end

function GUIMainMenu:CreateExploreWindow()

    local minPlayers            = 2
    local maxPlayers            = 32
    local playerLimitOptions    = { }
    
    for i = minPlayers, maxPlayers do
        table.insert(playerLimitOptions, i)
    end

    local gameModes = CreateServerUI_GetGameModes()

    local hostOptions = 
        {
            {   
                name   = "ServerName",            
                label  = "SERVER NAME",
                value  = "Explore Mode"
            },
            {   
                name   = "Password",            
                label  = "PASSWORD [OPTIONAL]",
            },
            {
                name    = "Map",
                label   = "MAP",
                type    = "select",
                value  = "Summit",
            },

            {
                name    = "PlayerLimit",
                label   = "PLAYER LIMIT",
                type    = "select",
                values  = playerLimitOptions,
                value   = 4
            },
        }
        
    self.optionElements = { }
    
    local content = self.explore
    local createServerForm = GUIMainMenu.CreateOptionsForm(self, content, hostOptions)
    
    self.createExploreServerForm = createServerForm
    self.createExploreServerForm:SetCSSClass("createserver")
    
    local mapList = self.optionElements.Map
    
    self.exploreButton = CreateMenuElement(self.tutorialWindow, "MenuButton")
    self.exploreButton:SetCSSClass("apply")
    self.exploreButton:SetText("EXPLORE")
    
    self.exploreButton:AddEventCallbacks({
             OnClick = function (self) CreateExploreServer(self.scriptHandle) end
        })

    self.explore:AddEventCallbacks({
             OnShow = function (self)
                local mapNames = { "Summit" }
                mapList:SetOptions( mapNames )
            end
        })
    
end

function GUIMainMenu:CreateHostGameWindow()

    self.createGame:AddEventCallbacks({ OnHide = function() SaveServerSettings(self) end })

    local minPlayers            = 2
    local maxPlayers            = 32
    local playerLimitOptions    = { }
    
    for i = minPlayers, maxPlayers do
        table.insert(playerLimitOptions, i)
    end

    local gameModes = CreateServerUI_GetGameModes()

    local hostOptions = 
        {
            {   
                name   = "ServerName",            
                label  = "SERVER NAME",
                value  = Client.GetOptionString("serverName", "NS2 Listen Server")
            },
            {   
                name   = "Password",            
                label  = "PASSWORD [OPTIONAL]",
                value  = Client.GetOptionString("serverPassword", "")
            },
            {
                name    = "Map",
                label   = "MAP",
                type    = "select",
                value  = Client.GetOptionString("mapName", "Summit")
            },
            {
                name    = "GameMode",
                label   = "GAME MODE",
                type    = "select",
                values  = gameModes,
                value   = gameModes[CreateServerUI_GetGameModesIndex()]
            },
            {
                name    = "PlayerLimit",
                label   = "PLAYER LIMIT",
                type    = "select",
                values  = playerLimitOptions,
                value   = Client.GetOptionInteger("playerLimit", 16)
            },
        }
        
    self.optionElements = { }
    
    local content = self.createGame
    local createServerForm = GUIMainMenu.CreateOptionsForm(self, content, hostOptions)
    
    self.createServerForm = createServerForm
    self.createServerForm:SetCSSClass("createserver")
    
    local mapList = self.optionElements.Map
    
    self.hostGameButton = CreateMenuElement(self.playWindow, "MenuButton")
    self.hostGameButton:SetCSSClass("apply")
    self.hostGameButton:SetText("CREATE")
    
    self.hostGameButton:AddEventCallbacks({
             OnClick = function (self) CreateServer(self.scriptHandle) end
        })

    self.createGame:AddEventCallbacks({
             OnShow = function (self)
                local mapNames
                mapNames, createServerForm.modIds = GetMaps()
                mapList:SetOptions( mapNames )
            end
        })
    
end

local function InitKeyBindings(keyInputs)

    local bindingsTable = BindingsUI_GetBindingsTable()
    for b = 1, #bindingsTable do
        keyInputs[b]:SetValue(bindingsTable[b].current)
    end
    
end

local function CreateKeyBindingsForm(mainMenu, content)

    local keyBindingsForm = CreateMenuElement(content, "Form", false)
    
    local bindingsTable = BindingsUI_GetBindingsTable()
    
    mainMenu.keyInputs = { }
    
    local rowHeight = 50
    
    for b = 1, #bindingsTable do
    
        local binding = bindingsTable[b]
        
        local keyInput = keyBindingsForm:CreateFormElement(Form.kElementType.FormButton, "INPUT" .. b, binding.current)
        keyInput:SetCSSClass("option_input")
        keyInput:AddEventCallbacks( { OnBlur = function(self) keyInput.ignoreFirstKey = nil end } )
        
        function keyInput:OnSendKey(key, down)
        
            if not down then
            
                // We want to ignore the click that gave this input focus.
                if keyInput.ignoreFirstKey == true then
                
                    local keyString = Client.ConvertKeyCodeToString(key)
                    keyInput:SetValue(keyString)
                    
                end
                keyInput.ignoreFirstKey = true
                
            end
            
        end
        
        local keyInputText = CreateMenuElement(keyBindingsForm, "Font", false)
        keyInputText:SetText(string.upper(binding.detail) ..  ":")
        keyInputText:SetCSSClass("option_label")
        
        local y = rowHeight * (b  - 1)
        
        keyInput:SetTopOffset(y)
        keyInputText:SetTopOffset(y)
        
        keyInput.inputName = binding.name
        table.insert(mainMenu.keyInputs, keyInput)
        
    end
    
    InitKeyBindings(mainMenu.keyInputs)
    
    keyBindingsForm:SetCSSClass("keybindings")
    
    return keyBindingsForm
    
end

local function InitOptions(optionElements)
        
    local function BoolToIndex(value)
        if value then
            return 2
        end
        return 1
    end

    local nickName              = OptionsDialogUI_GetNickname()
    local mouseSens             = (OptionsDialogUI_GetMouseSensitivity() - kMinSensitivity) / (kMaxSensitivity - kMinSensitivity)
    local mouseAcceleration     = Client.GetOptionBoolean("input/mouse/acceleration", false)
    local accelerationAmount    = (Client.GetOptionFloat("input/mouse/acceleration-amount", 1) - kMinAcceleration) / (kMaxAcceleration -kMinAcceleration)
    local invMouse              = OptionsDialogUI_GetMouseInverted()
    local rawInput              = Client.GetOptionBoolean("input/mouse/rawinput", false)
    local locale                = Client.GetOptionString( "locale", "enUS" )
    local showHints             = Client.GetOptionBoolean( "showHints", true )
    local showCommanderHelp     = Client.GetOptionBoolean( "commanderHelp", true )
    local drawDamage            = Client.GetOptionBoolean( "drawDamage", true )
    local rookieMode            = Client.GetOptionBoolean( kRookieOptionsKey, true )

    local screenResIdx          = OptionsDialogUI_GetScreenResolutionsIndex()
    local visualDetailIdx       = OptionsDialogUI_GetVisualDetailSettingsIndex()
    local displayMode           = table.find(kDisplayModes, OptionsDialogUI_GetWindowMode())
    local displayBuffering      = Client.GetOptionInteger("graphics/display/display-buffering", 0)
    local multicoreRendering    = Client.GetOptionBoolean("graphics/multithreaded", true)
    local textureStreaming      = Client.GetOptionBoolean("graphics/texture-streaming", false)
    local ambientOcclusion      = Client.GetOptionString("graphics/display/ambient-occlusion", kAmbientOcclusionModes[1])
	local fovAdjustment			= Client.GetOptionFloat("graphics/display/fov-adjustment", 0)

    // support legacy values    
    if ambientOcclusion == "false" then
        ambientOcclusion = "off"
    elseif ambientOcclusion == "true" then
        ambientOcclusion = "high"
    end

    local shadows               = OptionsDialogUI_GetShadows()
    local reflections           = Client.GetOptionBoolean("graphics/display/reflections", false)
    local bloom                 = OptionsDialogUI_GetBloom()
    local atmospherics          = OptionsDialogUI_GetAtmospherics()
    local anisotropicFiltering  = OptionsDialogUI_GetAnisotropicFiltering()
    local antiAliasing          = OptionsDialogUI_GetAntiAliasing()
    
    local soundVol              = Client.GetOptionInteger("soundVolume", 90) / 100
    local musicVol              = Client.GetOptionInteger("musicVolume", 90) / 100
    local voiceVol              = Client.GetOptionInteger("voiceVolume", 90) / 100
    
    for i=1,#kLocales do
        if kLocales[i].name == locale then
            optionElements.Language:SetOptionActive( i )
        end    
    end

    optionElements.NickName:SetValue( nickName )
    optionElements.Sensitivity:SetValue( mouseSens )
    optionElements.AccelerationAmount:SetValue( accelerationAmount )
    optionElements.MouseAcceleration:SetOptionActive( BoolToIndex(mouseAcceleration) )
    optionElements.InvertedMouse:SetOptionActive( BoolToIndex(invMouse) )
    optionElements.RawInput:SetOptionActive( BoolToIndex(rawInput) )
    optionElements.ShowHints:SetOptionActive( BoolToIndex(showHints) )
    optionElements.ShowCommanderHelp:SetOptionActive( BoolToIndex(showCommanderHelp) )
    optionElements.DrawDamage:SetOptionActive( BoolToIndex(drawDamage) )
    optionElements.RookieMode:SetOptionActive( BoolToIndex(rookieMode) )

    optionElements.DisplayMode:SetOptionActive( displayMode )
    optionElements.DisplayBuffering:SetOptionActive( displayBuffering + 1 )
    optionElements.Resolution:SetOptionActive( screenResIdx )
    optionElements.Shadows:SetOptionActive( BoolToIndex(shadows) )
    optionElements.Bloom:SetOptionActive( BoolToIndex(bloom) )
    optionElements.Atmospherics:SetOptionActive( BoolToIndex(atmospherics) )
    optionElements.AnisotropicFiltering:SetOptionActive( BoolToIndex(anisotropicFiltering) )
    optionElements.AntiAliasing:SetOptionActive( BoolToIndex(antiAliasing) )
    optionElements.Detail:SetOptionActive(visualDetailIdx)
    optionElements.MulticoreRendering:SetOptionActive( BoolToIndex(multicoreRendering) )
    optionElements.TextureStreaming:SetOptionActive( BoolToIndex(textureStreaming) )
    optionElements.AmbientOcclusion:SetOptionActive( table.find(kAmbientOcclusionModes, ambientOcclusion) )
    optionElements.Reflections:SetOptionActive( BoolToIndex(reflections) )
	optionElements.FOVAdjustment:SetValue(fovAdjustment)
    
    optionElements.SoundVolume:SetValue(soundVol)
    optionElements.MusicVolume:SetValue(musicVol)
    optionElements.VoiceVolume:SetValue(voiceVol)
    
end

local function SaveSecondaryGraphicsOptions(mainMenu)
    // These are options that are pretty quick to change, unlike screen resolution etc.
    // Have this separate, since graphics options are auto-applied
        
    local multicoreRendering = mainMenu.optionElements.MulticoreRendering:GetActiveOptionIndex() > 1
    local textureStreaming = mainMenu.optionElements.TextureStreaming:GetActiveOptionIndex() > 1
    local ambientOcclusionIdx = mainMenu.optionElements.AmbientOcclusion:GetActiveOptionIndex()
    local reflections = mainMenu.optionElements.Reflections:GetActiveOptionIndex() > 1
    local visualDetailIdx = mainMenu.optionElements.Detail:GetActiveOptionIndex()
    local shadows               = mainMenu.optionElements.Shadows:GetActiveOptionIndex() > 1
    local bloom                 = mainMenu.optionElements.Bloom:GetActiveOptionIndex() > 1
    local atmospherics          = mainMenu.optionElements.Atmospherics:GetActiveOptionIndex() > 1
    local anisotropicFiltering  = mainMenu.optionElements.AnisotropicFiltering:GetActiveOptionIndex() > 1
    local antiAliasing          = mainMenu.optionElements.AntiAliasing:GetActiveOptionIndex() > 1
    
    Client.SetOptionBoolean("graphics/multithreaded", multicoreRendering)
    Client.SetOptionBoolean("graphics/texture-streaming", textureStreaming)
    Client.SetOptionString("graphics/display/ambient-occlusion", kAmbientOcclusionModes[ambientOcclusionIdx] )
    Client.SetOptionBoolean("graphics/display/reflections", reflections)  
    Client.SetOptionInteger( kDisplayQualityOptionsKey, visualDetailIdx - 1 )
    Client.SetOptionBoolean ( kShadowsOptionsKey, shadows )
    Client.SetOptionBoolean ( kBloomOptionsKey, bloom )
    Client.SetOptionBoolean ( kAtmosphericsOptionsKey, atmospherics )
    Client.SetOptionBoolean ( kAnisotropicFilteringOptionsKey, anisotropicFiltering )
    Client.SetOptionBoolean ( kAntiAliasingOptionsKey, antiAliasing )
    
end

local function OnGraphicsOptionsChanged(mainMenu)
	SaveSecondaryGraphicsOptions(mainMenu)
	Client.ReloadGraphicsOptions()
	Render_SyncRenderOptions()    
end

local function OnSoundVolumeChanged(mainMenu)
    local soundVol = mainMenu.optionElements.SoundVolume:GetValue() * 100
	OptionsDialogUI_SetSoundVolume( soundVol )
end
local function OnMusicVolumeChanged(mainMenu)
    local musicVol = mainMenu.optionElements.MusicVolume:GetValue() * 100
    OptionsDialogUI_SetMusicVolume( musicVol )
end
local function OnVoiceVolumeChanged(mainMenu)
    local voiceVol = mainMenu.optionElements.VoiceVolume:GetValue() * 100
    OptionsDialogUI_SetVoiceVolume( voiceVol )
end

local function OnFOVAdjustChanged(mainMenu)
    local value = mainMenu.optionElements.FOVAdjustment:GetValue()
    Client.SetOptionFloat("graphics/display/fov-adjustment", value)
end

local function SaveOptions(mainMenu)

    local nickName              = mainMenu.optionElements.NickName:GetValue()
    local mouseSens             = mainMenu.optionElements.Sensitivity:GetValue() * (kMaxSensitivity - kMinSensitivity) + kMinSensitivity
    local mouseAcceleration     = mainMenu.optionElements.MouseAcceleration:GetActiveOptionIndex() > 1
    local accelerationAmount    = mainMenu.optionElements.AccelerationAmount:GetValue() * (kMaxAcceleration - kMinAcceleration) + kMinAcceleration
    local invMouse              = mainMenu.optionElements.InvertedMouse:GetActiveOptionIndex() > 1
    local rawInput              = mainMenu.optionElements.RawInput:GetActiveOptionIndex() > 1
    local locale                = kLocales[mainMenu.optionElements.Language:GetActiveOptionIndex()].name
    local showHints             = mainMenu.optionElements.ShowHints:GetActiveOptionIndex() > 1
    local showCommanderHelp     = mainMenu.optionElements.ShowCommanderHelp:GetActiveOptionIndex() > 1
    local drawDamage            = mainMenu.optionElements.DrawDamage:GetActiveOptionIndex() > 1
    local rookieMode            = mainMenu.optionElements.RookieMode:GetActiveOptionIndex() > 1
    
    local screenResIdx          = mainMenu.optionElements.Resolution:GetActiveOptionIndex()
    local visualDetailIdx       = mainMenu.optionElements.Detail:GetActiveOptionIndex()
    local displayBuffering      = mainMenu.optionElements.DisplayBuffering:GetActiveOptionIndex() - 1
    local displayMode           = mainMenu.optionElements.DisplayMode:GetActiveOptionIndex()
    local shadows               = mainMenu.optionElements.Shadows:GetActiveOptionIndex() > 1
    local bloom                 = mainMenu.optionElements.Bloom:GetActiveOptionIndex() > 1
    local atmospherics          = mainMenu.optionElements.Atmospherics:GetActiveOptionIndex() > 1
    local anisotropicFiltering  = mainMenu.optionElements.AnisotropicFiltering:GetActiveOptionIndex() > 1
    local antiAliasing          = mainMenu.optionElements.AntiAliasing:GetActiveOptionIndex() > 1
    
    local soundVol              = mainMenu.optionElements.SoundVolume:GetValue() * 100
    local musicVol              = mainMenu.optionElements.MusicVolume:GetValue() * 100
    local voiceVol              = mainMenu.optionElements.VoiceVolume:GetValue() * 100
    
    Client.SetOptionString( "locale", locale )

    Client.SetOptionBoolean("input/mouse/rawinput", rawInput)
    Client.SetOptionBoolean("input/mouse/acceleration", mouseAcceleration)
    Client.SetOptionBoolean( "showHints", showHints )
    Client.SetOptionBoolean( "commanderHelp", showCommanderHelp )
    Client.SetOptionBoolean( "drawDamage", drawDamage)
    Client.SetOptionBoolean( kRookieOptionsKey, rookieMode)

    Client.SetOptionFloat("input/mouse/acceleration-amount", accelerationAmount)
    
    // Some redundancy with ApplySecondaryGraphicsOptions here, no harm.
    OptionsDialogUI_SetValues(
        nickName,
        mouseSens,
        screenResIdx,
        visualDetailIdx,
        soundVol,
        musicVol,
        kDisplayModes[displayMode],
        shadows,
        bloom,
        atmospherics,
        anisotropicFiltering,
        antiAliasing,
        invMouse,
        voiceVol)
    SaveSecondaryGraphicsOptions(mainMenu)
    Client.SetOptionInteger("graphics/display/display-buffering", displayBuffering)
    
    // This will reload the first three graphics settings
    OptionsDialogUI_ExitDialog()

    Render_SyncRenderOptions() 
    
    for k = 1, #mainMenu.keyInputs do
    
        local keyInput = mainMenu.keyInputs[k]
        Client.SetOptionString("input/" .. keyInput.inputName, keyInput:GetValue())
        
    end
    Client.ReloadKeyOptions()
    

end

function GUIMainMenu:CreateOptionWindow()

    self.optionWindow = self:CreateWindow()
    self.optionWindow:DisableCloseButton()
    self.optionWindow:SetCSSClass("option_window")
    
    self:SetupWindow(self.optionWindow, "OPTIONS")
    local function InitOptionWindow()
    
        InitOptions(self.optionElements)
        InitKeyBindings(self.keyInputs)
        
    end
    self.optionWindow:AddEventCallbacks({ OnHide = InitOptionWindow })
    
    local content = self.optionWindow:GetContentBox()
    
    local back = CreateMenuElement(self.optionWindow, "MenuButton")
    back:SetCSSClass("back")
    back:SetText("BACK")
    back:AddEventCallbacks( { OnClick = function() self.optionWindow:SetIsVisible(false) end } )
    
    local apply = CreateMenuElement(self.optionWindow, "MenuButton")
    apply:SetCSSClass("apply")
    apply:SetText("APPLY")
    apply:AddEventCallbacks( { OnClick = function() SaveOptions(self) end } )

	self.fpsDisplay = CreateMenuElement( self.optionWindow, "MenuButton" )
	self.fpsDisplay:SetCSSClass("fps")
    
    local screenResolutions = OptionsDialogUI_GetScreenResolutions()
    
    local languages = { }
    for i = 1,#kLocales do
        languages[i] = kLocales[i].label
    end

    local generalOptions =
        {
            { 
                name    = "NickName",
                label   = "NICKNAME",
            },
            {
                name    = "Language",
                label   = "LANGUAGE",
                type    = "select",
                values  = languages,
            },
            { 
                name    = "Sensitivity",
                label   = "MOUSE SENSITIVITY",
                type    = "slider",
            },
            {
                name    = "InvertedMouse",
                label   = "REVERSE MOUSE",
                type    = "select",
                values  = { "NO", "YES" }
            },
            {
                name    = "MouseAcceleration",
                label   = "MOUSE ACCELERATION",
                type    = "select",
                values  = { "OFF", "ON" }
            },
            {
                name    = "AccelerationAmount",
                label   = "ACCELERATION AMOUNT",
                type    = "slider",
            },
            {
                name    = "RawInput",
                label   = "RAW INPUT",
                type    = "select",
                values  = { "OFF", "ON" }
            },
            {
                name    = "ShowHints",
                label   = "SHOW HINTS",
                type    = "select",
                values  = { "NO", "YES" }
            },  
            {
                name    = "ShowCommanderHelp",
                label   = "COMMANDER HELP",
                type    = "select",
                values  = { "OFF", "ON" }
            },  
            {
                name    = "DrawDamage",
                label   = "DRAW DAMAGE",
                type    = "select",
                values  = { "NO", "YES" }
            },  
            {
                name    = "RookieMode",
                label   = "ROOKIE MODE",
                type    = "select",
                values  = { "NO", "YES" }
            },          
            { 
                name    = "FOVAdjustment",
                label   = "FOV ADJUSTMENT",
                type    = "slider",
                sliderCallback = OnFOVAdjustChanged,
            },
        }

    local soundOptions =
        {
            { 
                name    = "SoundVolume",
                label   = "SOUND VOLUME",
                type    = "slider",
                sliderCallback = OnSoundVolumeChanged,
            },
            { 
                name    = "MusicVolume",
                label   = "MUSIC VOLUME",
                type    = "slider",
                sliderCallback = OnMusicVolumeChanged,
            },
            { 
                name    = "VoiceVolume",
                label   = "VOICE VOLUME",
                type    = "slider",
                sliderCallback = OnVoiceVolumeChanged,
            },
        }        
        
    local autoApplyCallback = function(formElement) OnGraphicsOptionsChanged(self) end
    
    local graphicsOptions = 
        {
            {   
                name   = "Resolution",
                label  = "RESOLUTION",
                type   = "select",
                values = screenResolutions,
            },
            {   
                name   = "DisplayMode",            
                label  = "DISPLAY MODE",
                type   = "select",
                values = { "WINDOWED", "FULLSCREEN", "FULLSCREEN WINDOWED" }
            },
            {   
                name   = "DisplayBuffering",            
                label  = "WAIT FOR VERTICAL SYNC",
                type   = "select",
                values = { "DISABLED", "DOUBLE BUFFERED", "TRIPLE BUFFERED" }
            },
            {
                name    = "Detail",
                label   = "TEXTURE QUALITY",
                type    = "select",
                values  = { "LOW", "MEDIUM", "HIGH" },
                callback = autoApplyCallback
            },
            {
                name    = "AntiAliasing",
                label   = "ANTI-ALIASING",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },
            {
                name    = "Bloom",
                label   = "BLOOM",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },
            {
                name    = "Atmospherics",
                label   = "ATMOSPHERICS",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },
            {   
                name    = "AnisotropicFiltering",
                label   = "ANISOTROPIC FILTERING",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },
            {
                name    = "AmbientOcclusion",
                label   = "AMBIENT OCCLUSION",
                type    = "select",
                values  = { "OFF", "MEDIUM", "HIGH" },
                callback = autoApplyCallback
            },    
            {
                name    = "Reflections",
                label   = "REFLECTIONS",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },            
            {
                name    = "Shadows",
                label   = "SHADOWS",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },
            {
                name    = "TextureStreaming",
                label   = "TEXTURE STREAMING (EXPERIMENTAL)",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },
            {
                name    = "MulticoreRendering",
                label   = "MULTICORE RENDERING",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = autoApplyCallback
            },            
        }
        
    self.optionElements = { }
    
    local generalForm     = GUIMainMenu.CreateOptionsForm(self, content, generalOptions)
    local keyBindingsForm = CreateKeyBindingsForm(self, content)
    local graphicsForm    = GUIMainMenu.CreateOptionsForm(self, content, graphicsOptions)
    local soundForm       = GUIMainMenu.CreateOptionsForm(self, content, soundOptions)
    
    local tabs = 
        {
            { label = "GENERAL",  form = generalForm },
            { label = "BINDINGS", form = keyBindingsForm, scroll=true },
            { label = "GRAPHICS", form = graphicsForm },
            { label = "SOUND",    form = soundForm },
        }
        
    local xTabWidth = 256

    local tabBackground = CreateMenuElement(self.optionWindow, "Image")
    tabBackground:SetCSSClass("tab_background")
    tabBackground:SetIgnoreEvents(true)
    
    local tabAnimateTime = 0.1
        
    for i = 1,#tabs do
    
        local tab = tabs[i]
        local tabButton = CreateMenuElement(self.optionWindow, "MenuButton")
        
        local function ShowTab()
            for j =1,#tabs do
                tabs[j].form:SetIsVisible(i == j)
                self.optionWindow:ResetSlideBar()
                self.optionWindow:SetSlideBarVisible(tab.scroll == true)
                local tabPosition = tabButton.background:GetPosition()
                tabBackground:SetBackgroundPosition( tabPosition, false, tabAnimateTime ) 
            end
        end
    
        tabButton:SetCSSClass("tab")
        tabButton:SetText(tab.label)
        tabButton:AddEventCallbacks({ OnClick = ShowTab })
        
        local tabWidth = tabButton:GetWidth()
        tabButton:SetBackgroundPosition( Vector(tabWidth * (i - 1), 0, 0) )
        
        // Make the first tab visible.
        if i==1 then
            tabBackground:SetBackgroundPosition( Vector(tabWidth * (i - 1), 0, 0) )
            ShowTab()
        end
        
    end        
    
    InitOptionWindow()
  
end

function GUIMainMenu:Update(deltaTime)

    PROFILE("GUIMainMenu:Update")
    
    if self:GetIsVisible() then

        local currentTime = Client.GetTime();
        
        // Refresh the mod list once every 5 seconds
        self.timeOfLastRefresh = self.timeOfLastRefresh or currentTime
        if self.modsWindow:GetIsVisible() and currentTime - self.timeOfLastRefresh >= 5 then
            self:RefreshModsList()
            self.timeOfLastRefresh = currentTime;
        end

        self.tweetText:Update(deltaTime)
    
        local alertText = MainMenu_GetAlertMessage()
        if self.currentAlertText ~= alertText then
        
            self.currentAlertText = alertText
            
            if self.currentAlertText then
                self.alertText:SetText(self.currentAlertText)
                self.alertWindow:SetIsVisible(true)
            end
            
        end
    
        // update only when visible
        GUIAnimatedScript.Update(self, deltaTime)
        self.playerName:SetText(OptionsDialogUI_GetNickname())
        
        if self.modsWindow:GetIsVisible() then
            self:UpdateModsWindow(self)
        end
        
        if self.playWindow:GetIsVisible() then
        
            if not Client.GetServerListRefreshed() then

                local reload = false
            
                for s = 0, Client.GetNumServers() - 1 do
                
                    if s + 1 > self.numServers then

                        local name = Client.GetServerName(s)
                        local mode = "ns2"
                        local map = GetTrimmedMapName(Client.GetServerMapName(s))
                        local numPlayers = Client.GetServerNumPlayers(s)
                        local maxPlayers = Client.GetServerMaxPlayers(s)
                        local ping = Client.GetServerPing(s)
                        local address = Client.GetServerAddress(s)
                        local requiresPassword = Client.GetServerRequiresPassword(s)
                        local rookieFriendly = Client.GetServerHasTag(s, "rookie")
                        local friendsOnServer = false
                        local lanServer = false
                        local customGame = false

                        reload = true
                    
                        self.numServers = self.numServers + 1
                        
                        // Change name to display "rookie friendly" at the end of the line
                        if rookieFriendly then
                            local maxLen = 25
                            local separator = ConditionalValue(string.len(name) > 25, "...", " ")
                            name = name:sub(0, maxLen) .. separator  .. Locale.ResolveString("ROOKIE_FRIENDLY")
                        end
                        
                        self.serverTable:AddRow({ requiresPassword, {name, rookieFriendly}, { friendsOnServer, lanServer, customGame }, map, { numPlayers, maxPlayers }, ping}, s)
                        
                    end
                    
                end

                if reload then
                
                    self.serverTable:Sort()
                    
                    self.serverListSize = self.createGame:GetBackground():GetSize()
                    self.serverListSize.y = self.createGame:GetContentSize().y
                    
                    self.createGame:GetBackground():SetSize(self.serverListSize)
                    
                end
                
            elseif self.refreshingServerList then
            
                self.refreshingServerList = false
                self.playWindow.refreshButton:SetText("REFRESH")
                
            end
            
        end

        self:UpdateFindPeople(deltaTime)        
        self.playNowWindow:UpdateLogic(self)

		self.fpsDisplay:SetText(string.format("FPS: %.0f", Client.GetFrameRate()))
        
    end
    
end

function GUIMainMenu:ShowMenu()

    self.menuBackground:SetIsVisible(true)
    self.menuBackground:SetCSSClass("menu_bg_show", false)
    
    self.logo:SetIsVisible(true)
    
end

function GUIMainMenu:HideMenu()

    self.menuBackground:SetCSSClass("menu_bg_hide", false)

    if self.resumeLink then
        self.resumeLink:SetIsVisible(false)
    end
    if self.readyRoomLink then
        self.readyRoomLink:SetIsVisible(false)
    end
    if self.modsLink then
        self.modsLink:SetIsVisible(false)
    end
    self.playLink:SetIsVisible(false)
    self.tutorialLink:SetIsVisible(false)
    self.optionLink:SetIsVisible(false)
    if self.quitLink then
        self.quitLink:SetIsVisible(false)
    end
    if self.disconnectLink then
        self.disconnectLink:SetIsVisible(false)
    end
    
    self.logo:SetIsVisible(false)
    
end

function GUIMainMenu:OnAnimationsEnd(item)
    
    if item == self.scanLine:GetBackground() then
        self.scanLine:SetCSSClass("scanline")
    end
    
end

function GUIMainMenu:OnAnimationCompleted(animatedItem, animationName, itemHandle)

    if animationName == "ANIMATE_LINK_BG" then
    
        if self.modsLink then
            self.modsLink:ReloadCSSClass()
        end
        if self.quitLink then
            self.quitLink:ReloadCSSClass()
        end
        self.highlightServer:ReloadCSSClass()
        if self.disconnectLink then
            self.disconnectLink:ReloadCSSClass()
        end
        if self.resumeLink then
            self.resumeLink:ReloadCSSClass()
        end
        if self.readyRoomLink then
            self.readyRoomLink:ReloadCSSClass()
        end
        self.playLink:ReloadCSSClass()
        self.tutorialLink:ReloadCSSClass()
        self.optionLink:ReloadCSSClass()
        
    elseif animationName == "ANIMATE_BLINKING_ARROW" then
    
        self.blinkingArrow:SetCSSClass("blinking_arrow")
        
    elseif animationName == "MAIN_MENU_OPACITY" then
    
        if self.menuBackground:HasCSSClass("menu_bg_hide") then
            self.menuBackground:SetIsVisible(false)
        end    

    elseif animationName == "MAIN_MENU_MOVE" then
    
        if self.menuBackground:HasCSSClass("menu_bg_show") then

            if self.resumeLink then
                self.resumeLink:SetIsVisible(true)
            end
            if self.readyRoomLink then
                self.readyRoomLink:SetIsVisible(true)
            end
            if self.modsLink then
                self.modsLink:SetIsVisible(true)
            end
            self.playLink:SetIsVisible(true)
            self.tutorialLink:SetIsVisible(true)
            self.optionLink:SetIsVisible(true)
            if self.quitLink then
                self.quitLink:SetIsVisible(true)
            end
            if self.disconnectLink then
                self.disconnectLink:SetIsVisible(true)
            end
        end
        
    elseif animationName == "SHOWWINDOW_UP" then
    
        self.showWindowAnimation:SetCSSClass("showwindow_animation2")
    
    elseif animationName == "SHOWWINDOW_RIGHT" then
    
        self.windowToOpen:SetIsVisible(true)
        self.showWindowAnimation:SetIsVisible(false)
        
    elseif animationName == "SHOWWINDOW_LEFT" then

        self.showWindowAnimation:SetCSSClass("showwindow_animation2_close")
        
    elseif animationName == "SHOWWINDOW_DOWN" then

        self.showWindowAnimation:SetCSSClass("showwindow_hidden")
        self.showWindowAnimation:SetIsVisible(false)
        
    end

end

function GUIMainMenu:OnWindowOpened(window)

    self.openedWindows = self.openedWindows + 1
    
    self.showWindowAnimation:SetCSSClass("showwindow_animation1")
    
end

function GUIMainMenu:OnWindowClosed(window)
    
    self.openedWindows = self.openedWindows - 1
    
    if self.openedWindows <= 0 then
    
        self:ShowMenu()
        self.showWindowAnimation:SetCSSClass("showwindow_animation1_close")
        self.showWindowAnimation:SetIsVisible(true)
        
    end
    
end

function GUIMainMenu:SetupWindow(window, title)

    window:SetCanBeDragged(false)
    window:SetWindowName(title)
    window:AddClass("main_menu_window")
    window:SetInitialVisible(false)
    window:SetIsVisible(false)
    window:DisableResizeTile()
    
    local eventCallbacks =
    {
        OnShow = function(self)
            self.scriptHandle:OnWindowOpened(self)
            MainMenu_OnWindowOpen()
        end,
        
        OnHide = function(self)
            self.scriptHandle:OnWindowClosed(self)
        end
    }
    
    window:AddEventCallbacks(eventCallbacks)
    
end

function GUIMainMenu:OnResolutionChanged(oldX, oldY, newX, newY)

    GUIAnimatedScript.OnResolutionChanged(self, oldX, oldY, newX, newY)

    for _,window in ipairs(self.windows) do
        window:ReloadCSSClass()
    end
    
    // this is a hack. fix reloading of slidebars instead
    if self.generalForm then
        self.generalForm:Uninitialize()
        self.generalForm = CreateGeneralForm(self, self.optionWindow:GetContentBox())
    end    
    
end
