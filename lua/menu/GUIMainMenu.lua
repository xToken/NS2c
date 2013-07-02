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
Script.Load("lua/menu/ProgressBar.lua")
Script.Load("lua/menu/ContentBox.lua")
Script.Load("lua/menu/Image.lua")
Script.Load("lua/menu/Table.lua")
Script.Load("lua/menu/Ticker.lua")
Script.Load("lua/ServerBrowser.lua")
Script.Load("lua/menu/Form.lua")
Script.Load("lua/menu/ServerList.lua")
Script.Load("lua/menu/ServerTabs.lua")
Script.Load("lua/menu/PlayerEntry.lua")
Script.Load("lua/dkjson.lua")

local kMainMenuLinkColor = Color(137 / 255, 137 / 255, 137 / 255, 1)

class 'GUIMainMenu' (GUIAnimatedScript)

Script.Load("lua/menu/GUIMainMenu_FindPeople.lua")
Script.Load("lua/menu/GUIMainMenu_PlayNow.lua")
Script.Load("lua/menu/GUIMainMenu_Mods.lua")
Script.Load("lua/menu/GUIMainMenu_Tutorial.lua")
Script.Load("lua/menu/GUIMainMenu_Web.lua")

// Min and maximum values for the mouse sensitivity slider
local kMinSensitivity = 1
local kMaxSensitivity = 20

local kMinAcceleration = 1
local kMaxAcceleration = 1.4

local kDisplayModes = { "windowed", "fullscreen", "fullscreen-windowed" }
local kAmbientOcclusionModes = { "off", "medium", "high" }
local kInfestationModes = { "minimal", "rich" }
local kParticleQualityModes = { "low", "high" }
    
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

local gMainMenu

function GUIMainMenu:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    Shared.Message("Main Menu Initialized at Version: " .. Shared.GetBuildNumber())
    Shared.Message("Steam Id: " .. Client.GetSteamId())
    
    // provides a set of functions required for window handling
    AddMenuMixin(self)
    self:SetCursor("ui/Cursor_MenuDefault.dds")
    self:SetWindowLayer(kWindowLayerMainMenu)
    
    LoadCSSFile("lua/menu/main_menu.css")
    
    self.mainWindow = self:CreateWindow()
    self.mainWindow:SetCSSClass("main_frame")
    
    self.tvGlareImage = CreateMenuElement(self.mainWindow, "Image")
    
    if MainMenu_IsInGame() then
        self.tvGlareImage:SetCSSClass("tvglare_dark")
    else
        self.tvGlareImage:SetCSSClass("tvglare")
    end    
    
    self.mainWindow:DisableTitleBar()
    self.mainWindow:DisableResizeTile()
    self.mainWindow:DisableCanSetActive()
    self.mainWindow:DisableContentBox()
    self.mainWindow:DisableSlideBar()
    
    self.showWindowAnimation = CreateMenuElement(self.mainWindow, "Font", false)
    self.showWindowAnimation:SetCSSClass("showwindow_hidden")
    
    if not MainMenu_IsInGame() then
        self.newsScript = GetGUIManager():CreateGUIScript("menu/GUIMainMenuNews")
    end
    
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

    // To prevent load delays, we create most windows lazily.
    // But these are fast enough to just do immediately.
    self:CreatePasswordPromptWindow()
    self:CreateAutoJoinWindow()
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
    
        self.resumeLink = self:CreateMainLink("RESUME GAME", "resume_ingame", "01")
        self.resumeLink:AddEventCallbacks(
        {
            OnClick = function(self)
                self.scriptHandle:SetIsVisible(not self.scriptHandle:GetIsVisible())
            end
        })
        
        self.readyRoomLink = self:CreateMainLink("GO TO READY ROOM", "readyroom_ingame", "02")
        self.readyRoomLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                self.scriptHandle:SetIsVisible(not self.scriptHandle:GetIsVisible())
                Shared.ConsoleCommand("rr")
                
            end
        })
        
        self.voteLink = self:CreateMainLink("VOTE", "vote_ingame", "03")
        self.voteLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                OpenVoteMenu()
                self.scriptHandle:SetIsVisible(false)
                
            end
        })
        
        self.playLink = self:CreateMainLink("PLAY", "play_ingame", "04")
        self.playLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                if not self.scriptHandle.playWindow then
                    self.scriptHandle:CreatePlayWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.playWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.optionLink = self:CreateMainLink("OPTIONS", "options_ingame", "05")
        self.optionLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                if not self.scriptHandle.optionWindow then
                    self.scriptHandle:CreateOptionWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.optionWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.tutorialLink = self:CreateMainLink("PRACTICE", "tutorial_ingame", "06")
        self.tutorialLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                if not self.scriptHandle.tutorialWindow then
                    self.scriptHandle:CreateTutorialWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.tutorialWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        // Create "disconnect" button
        self.disconnectLink = self:CreateMainLink("DISCONNECT", "disconnect_ingame", "07")
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
            
                if not self.scriptHandle.playWindow then
                    self.scriptHandle:CreatePlayWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.playWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.tutorialLink = self:CreateMainLink("PRACTICE", "tutorial", "02")
        self.tutorialLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                if not self.scriptHandle.tutorialWindow then
                    self.scriptHandle:CreateTutorialWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.tutorialWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.optionLink = self:CreateMainLink("OPTIONS", "options", "03")
        self.optionLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                if not self.scriptHandle.optionWindow then
                    self.scriptHandle:CreateOptionWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.optionWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.modsLink = self:CreateMainLink("MODS", "mods", "04")
        self.modsLink:AddEventCallbacks(
        {
            OnClick = function(self)
            
                if not self.scriptHandle.modsWindow then
                    self.scriptHandle:CreateModsWindow()
                end
                TriggerOpenAnimation(self.scriptHandle.modsWindow)
                self.scriptHandle:HideMenu()
                
            end
        })
        
        self.quitLink = self:CreateMainLink("EXIT", "exit", "05")
        self.quitLink:AddEventCallbacks(
        {
            OnClick = function(self)
                Client.Exit()
            end
        })
        
    end
    
    gMainMenu = self
    
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

    gMainMenu = nil
    self:DestroyAllWindows()
    
    if self.newsScript then
    
        GetGUIManager():DestroyGUIScript(self.newsScript)
        self.newsScript = nil
        
    end
    
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
    
    // Create avatar icon.
    self.avatar = CreateMenuElement(self.profileBackground, "Image")
    self.avatar:SetCSSClass("avatar")
    self.avatar:SetBackgroundTexture("*avatar")
    
    self.playerName = CreateMenuElement(self.profileBackground, "Font")
    self.playerName:SetCSSClass("profile")
    
end  

local function FinishWindowAnimations(self)
    self:GetBackground():EndAnimations()
end

local function AddFavoritesToServerList(serverList)

    local favoriteServers = GetStoredServers()
    for f = 1, #favoriteServers do
    
        local currentFavorite = favoriteServers[f]
        if type(currentFavorite) == "string" then
            currentFavorite = { address = currentFavorite }
        end
        
        local serverEntry = { }
        serverEntry.name = currentFavorite.name or "No name"
        serverEntry.mode = "?"
        serverEntry.map = "?"
        serverEntry.numPlayers = 0
        serverEntry.maxPlayers = currentFavorite.maxPlayers or 24
        serverEntry.ping = 999
        serverEntry.address = currentFavorite.address or "127.0.0.1:27015"
        serverEntry.requiresPassword = currentFavorite.requiresPassword or false
        serverEntry.rookieFriendly = currentFavorite.rookieFriendly or false
        serverEntry.friendsOnServer = false
        serverEntry.lanServer = false
        serverEntry.tickrate = 30
        serverEntry.serverId = -f
        serverEntry.modded = currentFavorite.modded or false
        serverEntry.favorite = currentFavorite.favorite
        serverEntry.history = currentFavorite.history
        
        serverEntry.name = FormatServerName(serverEntry.name, serverEntry.rookieFriendly)
        
        local function OnServerRefreshed(serverData)
            serverList:UpdateEntry(serverData)
        end
        Client.RefreshServer(serverEntry.address, OnServerRefreshed)
        
        serverList:AddEntry(serverEntry)
        
    end
    
end

local function UpdateServerList(self)

    self.serverTabs:Reset()
    self.numServers = 0
    Client.RebuildServerList()
    self.playWindow.updateButton:SetText("UPDATING...")
    self.playWindow:ResetSlideBar()
    self.selectServer:SetIsVisible(false)
    self.serverList:ClearChildren()
    // Needs to be done here because the server IDs will change.
    self:ResetServerSelection()
    
    AddFavoritesToServerList(self.serverList)
    
end

local function JoinServer(self)

    if MainMenu_GetSelectedServer() >= 0 and MainMenu_GetSelectedIsFull() then
    
        self.autoJoinWindow:SetIsVisible(true)
        self.autoJoinText:SetText(ToString(MainMenu_GetSelectedServerName()))
        
    else
        MainMenu_JoinSelected()
    end
    
end

function GUIMainMenu:ProcessJoinServer()

    if MainMenu_GetSelectedServer() ~= nil then
    
        if MainMenu_GetSelectedRequiresPassword() then
            self.passwordPromptWindow:SetIsVisible(true)
        else
            JoinServer(self)
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
    
    self.alertText:SetTextClipped(true, 350, 100)
    
    local okButton = CreateMenuElement(self.alertWindow, "MenuButton")
    okButton:SetCSSClass("bottomcenter")
    okButton:SetText("OK")
    
    okButton:AddEventCallbacks({ OnClick = function (self)

        self.scriptHandle.alertWindow:SetIsVisible(false)

    end  })
    
end 

function GUIMainMenu:CreateAutoJoinWindow()

    self.autoJoinWindow = self:CreateWindow()    
    self.autoJoinWindow:SetWindowName("WAITING FOR SLOT ...")
    self.autoJoinWindow:SetInitialVisible(false)
    self.autoJoinWindow:SetIsVisible(false)
    self.autoJoinWindow:DisableTitleBar()
    self.autoJoinWindow:DisableResizeTile()
    self.autoJoinWindow:DisableSlideBar()
    self.autoJoinWindow:DisableContentBox()
    self.autoJoinWindow:SetCSSClass("autojoin_window")
    self.autoJoinWindow:DisableCloseButton()
    
    local cancel = CreateMenuElement(self.autoJoinWindow, "MenuButton")
    cancel:SetCSSClass("bottomcenter")
    cancel:SetText("CANCEL")
    
    local text = CreateMenuElement(self.autoJoinWindow, "Font")
    text:SetCSSClass("auto_join_text")
    text:SetText("WAITING FOR SLOT...")
    
    self.autoJoinText = CreateMenuElement(self.autoJoinWindow, "Font")
    self.autoJoinText:SetCSSClass("auto_join_text_servername")
    self.autoJoinText:SetText("")
    
    self.blinkingArrowTwo = CreateMenuElement(self.autoJoinWindow, "Image")
    self.blinkingArrowTwo:SetCSSClass("blinking_arrow_two")

    cancel:AddEventCallbacks({ OnClick =
    function (self)    
        self:GetParent():SetIsVisible(false)        
    end })
    
    local eventCallbacks =
    {
        OnShow = function(self)
            self.scriptHandle.updateAutoJoin = true
        end,
        OnHide = function(self)
            self.scriptHandle.updateAutoJoin = false
        end,
        OnBlur = function(self)
            self:SetIsVisible(false)
        end
    }
    
    self.autoJoinWindow:AddEventCallbacks(eventCallbacks)

end

function GUIMainMenu:CreatePasswordPromptWindow()

    self.passwordPromptWindow = self:CreateWindow()
    local passwordPromptWindow = self.passwordPromptWindow
    passwordPromptWindow:SetWindowName("ENTER PASSWORD")
    passwordPromptWindow:SetInitialVisible(false)
    passwordPromptWindow:SetIsVisible(false)
    passwordPromptWindow:DisableResizeTile()
    passwordPromptWindow:DisableSlideBar()
    passwordPromptWindow:DisableContentBox()
    passwordPromptWindow:SetCSSClass("passwordprompt_window")
    passwordPromptWindow:DisableCloseButton()
        
    self.passwordForm = CreateMenuElement(passwordPromptWindow, "Form", false)
    self.passwordForm:SetCSSClass("passwordprompt")
    
    local textinput = self.passwordForm:CreateFormElement(Form.kElementType.TextInput, "PASSWORD", Client.GetOptionString("serverPassword", ""))
    textinput:SetCSSClass("serverpassword")    
    textinput:AddEventCallbacks({
        OnEscape = function(self)
            passwordPromptWindow:SetIsVisible(false) 
        end 
    })
    
    local descriptionText = CreateMenuElement(passwordPromptWindow.titleBar, "Font", false)
    descriptionText:SetCSSClass("passwordprompt_title")
    descriptionText:SetText("ENTER PASSWORD")
    
    local joinServer = CreateMenuElement(passwordPromptWindow, "MenuButton")
    joinServer:SetCSSClass("bottomcenter")
    joinServer:SetText("JOIN")
    
    joinServer:AddEventCallbacks({ OnClick =
    function (self)
    
        local formData = self.scriptHandle.passwordForm:GetFormData()
        MainMenu_SetSelectedServerPassword(formData.PASSWORD)
        JoinServer(self.scriptHandle)
        
    end })

    passwordPromptWindow:AddEventCallbacks({ 
    
        OnBlur = function(self) 
            self:SetIsVisible(false) 
        end,
        
        OnEnter = function(self)
        
            local formData = self.scriptHandle.passwordForm:GetFormData()
            MainMenu_SetSelectedServerPassword(formData.PASSWORD)
            JoinServer(self.scriptHandle)
        
        end,

        OnShow = function(self)
            GetWindowManager():HandleFocusBlur(self, textinput)
        end,

    })
    
end

local kMaxPingDesciption = "MAX PING: %s"
local kTickrateDescription = "PERFORMANCE: %s%%"

local function CreateFilterForm(self)

    self.filterForm = CreateMenuElement(self.playWindow, "Form", false)
    self.filterForm:SetCSSClass("filter_form")
    /*
    self.filterGameMode = self.filterForm:CreateFormElement(Form.kElementType.TextInput, "GAME MODE")
    self.filterGameMode:SetCSSClass("filter_gamemode")
    self.filterGameMode:AddSetValueCallback(function(self)
    
        local value = StringTrim(self:GetValue())
        self.scriptHandle.serverList:SetFilter(1, FilterServerMode(value))
        
        Client.SetOptionString("filter_gamemode", value)
        
    end)
    
    local description = CreateMenuElement(self.filterGameMode, "Font")
    description:SetText("GAME")
    description:SetCSSClass("filter_description")
    
    */
    
    self.filterServerName = self.filterForm:CreateFormElement(Form.kElementType.TextInput, "SERVER NAME")
    self.filterServerName:SetCSSClass("filter_servername")
    self.filterServerName:AddSetValueCallback(function(self)
    
        local value = StringTrim(self:GetValue())
        self.scriptHandle.serverList:SetFilter(12, FilterServerName(value))
        
        Client.SetOptionString("filter_servername", value)
        
    end)
    
    local description = CreateMenuElement(self.filterServerName, "Font")
    description:SetText("SERVER NAME")
    description:SetCSSClass("filter_description")
    
    self.filterMapName = self.filterForm:CreateFormElement(Form.kElementType.TextInput, "MAP NAME")
    self.filterMapName:SetCSSClass("filter_mapname")
    self.filterMapName:AddSetValueCallback(function(self)
    
        local value = StringTrim(self:GetValue())
        self.scriptHandle.serverList:SetFilter(2, FilterMapName(value))
        Client.SetOptionString("filter_mapname", self.scriptHandle.filterMapName:GetValue())
        
    end)
    
    local description = CreateMenuElement(self.filterMapName, "Font")
    description:SetText("MAP NAME")
    description:SetCSSClass("filter_description")
    
    self.filterTickrate = self.filterForm:CreateFormElement(Form.kElementType.SlideBar, "TICK RATE")
    self.filterTickrate:SetCSSClass("filter_tickrate")
    self.filterTickrate:AddSetValueCallback( function(self)
    
        local value = self:GetValue()
        self.scriptHandle.serverList:SetFilter(3, FilterMinRate(value))
        Client.SetOptionString("filter_tickrate", ToString(value))
        
        self.scriptHandle.tickrateDescription:SetText(string.format(kTickrateDescription, ToString(math.round(value * 100)))) 
        
    end )

    self.tickrateDescription = CreateMenuElement(self.filterTickrate, "Font")
    self.tickrateDescription:SetCSSClass("filter_description")
    
    self.filterMaxPing = self.filterForm:CreateFormElement(Form.kElementType.SlideBar, "MAX PING")
    self.filterMaxPing:SetCSSClass("filter_maxping")
    self.filterMaxPing:AddSetValueCallback( function(self)
        
        local value = self.scriptHandle.filterMaxPing:GetValue()
        self.scriptHandle.serverList:SetFilter(4, FilterMaxPing(math.round(value * kFilterMaxPing)))
        Client.SetOptionString("filter_maxping", ToString(value))
        
        local textValue = ""
        if value == 1.0 then
            textValue = "unlimited"
        else        
            textValue = ToString(math.round(value * kFilterMaxPing))
        end

        self.scriptHandle.pingDescription:SetText(string.format(kMaxPingDesciption, textValue))    
        
    end )

    self.pingDescription = CreateMenuElement(self.filterMaxPing, "Font")
    self.pingDescription:SetCSSClass("filter_description")
    
    self.filterHasPlayers = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, "FILTER EMPTY")
    self.filterHasPlayers:SetCSSClass("filter_hasplayers")
    self.filterHasPlayers:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(5, FilterEmpty(self:GetValue()))
        Client.SetOptionString("filter_hasplayers", ToString(self.scriptHandle.filterHasPlayers:GetValue()))
        
    end)

    local description = CreateMenuElement(self.filterHasPlayers, "Font")
    description:SetText("FILTER EMPTY")
    description:SetCSSClass("filter_description")
    
    self.filterFull = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, "FILTER FULL")
    self.filterFull:SetCSSClass("filter_full")
    self.filterFull:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(6, FilterFull(self:GetValue()))
        Client.SetOptionString("filter_full", ToString(self.scriptHandle.filterFull:GetValue()))
        
    end)
    
    local description = CreateMenuElement(self.filterFull, "Font")
    description:SetText("FILTER FULL")
    description:SetCSSClass("filter_description")
    /*
    self.filterFavorites = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, "FAVORITES")
    self.filterFavorites:SetCSSClass("filter_favorites")
    self.filterFavorites:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(8, FilterFavoriteOnly(self:GetValue()))
        Client.SetOptionString("filter_favorites", ToString(self.scriptHandle.filterFavorites:GetValue()))
        
    end)
    
    local favoriteIcon = CreateMenuElement(self.filterFavorites, "Image", false)
    favoriteIcon:SetCSSClass("filter_favorites_icon", false)
    
    local description = CreateMenuElement(self.filterFavorites, "Font")
    description:SetText("FAVORITES")
    description:SetCSSClass("filter_description")
    
    */
    
    self.filterPassworded = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, "PASSWORDED")
    self.filterPassworded:SetCSSClass("filter_passworded")
    self.filterPassworded:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(9, FilterPassworded(self:GetValue()))
        Client.SetOptionString("filter_passworded", ToString(self.scriptHandle.filterPassworded:GetValue()))
        
    end)
    
    local description = CreateMenuElement(self.filterPassworded, "Font")
    description:SetText("PASSWORDED")
    description:SetCSSClass("filter_description")

    self.filterRookie = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, "FILTER ROOKIE")
    self.filterRookie:SetCSSClass("filter_rookie")
    self.filterRookie:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(10, FilterRookie(self:GetValue()))
        Client.SetOptionString("filter_rookie", ToString(self.scriptHandle.filterRookie:GetValue()))
        
    end)
    
    local description = CreateMenuElement(self.filterRookie, "Font")
    description:SetText("FILTER ROOKIE")
    description:SetCSSClass("filter_description")
    
    //self.filterGameMode:SetValue(Client.GetOptionString("filter_gamemode", ""))
    self.filterMapName:SetValue(Client.GetOptionString("filter_mapname", ""))
    self.filterTickrate:SetValue(tonumber(Client.GetOptionString("filter_tickrate", "0")) or 0)
    self.filterHasPlayers:SetValue(Client.GetOptionString("filter_hasplayers", "false"))
    self.filterFull:SetValue(Client.GetOptionString("filter_full", "false"))
    self.filterMaxPing:SetValue(tonumber(Client.GetOptionString("filter_maxping", "1")) or 1)
    self.filterRookie:SetValue(Client.GetOptionString("filter_rookie", "false"))
    //self.filterFavorites:SetValue(Client.GetOptionString("filter_favorites", "false"))
    self.filterPassworded:SetValue(Client.GetOptionString("filter_passworded", "true"))
    
end

local function TestGetServerPlayerDetails(index, table)

    table[1] = { name = "Test 1", score = 1, timePlayed = 200 }
    table[2] = { name = "Test 2", score = 10, timePlayed = 300 }
    table[3] = { name = "Test 3", score = 12, timePlayed = 450 }
    table[4] = { name = "Test 4", score = 100, timePlayed = 332 }
    table[5] = { name = "Test 5", score = 24, timePlayed = 800.6 }
    table[6] = { name = "Test 6", score = 22, timePlayed = 212.7 }
    table[7] = { name = "Test 7", score = 15, timePlayed = 80 }
    table[8] = { name = "Test 8", score = 90, timePlayed = 60 }
    table[9] = { name = "Test 9", score = 45, timePlayed = 1231 }
    table[10] = { name = "Test 10", score = 340, timePlayed = 564 }
    table[11] = { name = "Test 11", score = 400, timePlayed = 55 }
    table[12] = { name = "Test 1", score = 1, timePlayed = 645 }
    table[13] = { name = "Test 2", score = 10, timePlayed = 987 }
    table[14] = { name = "Test 3", score = 12, timePlayed = 456 }
    table[15] = { name = "Test 4", score = 100, timePlayed = 321 }
    table[16] = { name = "Test 5", score = 24, timePlayed = 458 }
    table[17] = { name = "Test 6", score = 22, timePlayed = 159 }
    table[18] = { name = "Test 7", score = 15, timePlayed = 852 }
    table[19] = { name = "Test 8", score = 90, timePlayed = 753 }
    table[20] = { name = "Test 9", score = 45, timePlayed = 50 }
    table[21] = { name = "Test 10", score = 340, timePlayed = 220 }
    table[22] = { name = "Test 11", score = 400, timePlayed = 443 }
    table[23] = { name = "Test 11", score = 400, timePlayed = 20 }
    table[24] = { name = "Test 11", score = 400, timePlayed = 30 }
    table[25] = { name = "Test 11", score = 400, timePlayed = 23 }
    table[26] = { name = "Test 11", score = 400, timePlayed = 5 }
    table[27] = { name = "Test 11", score = 400, timePlayed = 12 }
    table[28] = { name = "Test 11", score = 400, timePlayed = 800 }
    table[29] = { name = "Test 11", score = 400, timePlayed = 865 }
    table[30] = { name = "Test 11", score = 400, timePlayed = 744 }
    table[31] = { name = "Test 11", score = 400, timePlayed = 45.786 }
    table[32] = { name = "Test 11", score = 400, timePlayed = 558.987 }

end

local downloadedModDetails = { }
local currentlyDownloadingModDetails = nil

local function ModDetailsCallback(modId, title, description)

    downloadedModDetails[modId] = title
    currentlyDownloadingModDetails = nil
    
end

function GUIMainMenu:CreateServerDetailsWindow()

    self.serverDetailsWindow = self:CreateWindow()
    
    self.serverDetailsWindow:SetWindowName("SERVER DETAILS")
    self.serverDetailsWindow:SetInitialVisible(false)
    self.serverDetailsWindow:SetIsVisible(false)
    self.serverDetailsWindow:DisableResizeTile()
    self.serverDetailsWindow:SetCSSClass("serverdetails_window")
    self.serverDetailsWindow:DisableCloseButton()
    
    self.serverDetailsWindow:AddEventCallbacks({
        OnBlur = function(self)
            self:SetIsVisible(false)
        end
    })
    
    self.serverDetailsWindow.serverName = CreateMenuElement(self.serverDetailsWindow, "Font")
    
    self.serverDetailsWindow.serverAddress = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.serverAddress:SetTopOffset(32)    
    
    self.serverDetailsWindow.playerCount = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.playerCount:SetTopOffset(64)
    
    self.serverDetailsWindow.ping = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.ping:SetTopOffset(96)
    
    self.serverDetailsWindow.gameMode = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.gameMode:SetTopOffset(128)
    
    self.serverDetailsWindow.map = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.map:SetTopOffset(160)
    
    self.serverDetailsWindow.performance = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.performance:SetTopOffset(192)
    
    self.serverDetailsWindow.modsDesc = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.modsDesc:SetTopOffset(224)
    self.serverDetailsWindow.modsDesc:SetText("Installed Mods:")
    
    local windowWidth = self.serverDetailsWindow.background.guiItem:GetSize().x - 16
    
    self.serverDetailsWindow.modList = CreateMenuElement(self.serverDetailsWindow, "Font")
    self.serverDetailsWindow.modList:SetTopOffset(256)
    self.serverDetailsWindow.modList:SetCSSClass("serverdetails_modlist")
    self.serverDetailsWindow.modList.text:SetTextClipped(true, windowWidth, 200)
    
    self.serverDetailsWindow.favoriteIcon = CreateMenuElement(self.serverDetailsWindow, "Image")
    self.serverDetailsWindow.favoriteIcon:SetBackgroundSize(Vector(26, 26, 0))
    self.serverDetailsWindow.favoriteIcon:SetTopOffset(64)
    self.serverDetailsWindow.favoriteIcon:SetRightOffset(24)
    self.serverDetailsWindow.favoriteIcon:SetBackgroundTexture("ui/menu/favorite.dds")
    
    self.serverDetailsWindow.passwordedIcon = CreateMenuElement(self.serverDetailsWindow, "Image")
    self.serverDetailsWindow.passwordedIcon:SetBackgroundSize(Vector(26, 26, 0))
    self.serverDetailsWindow.passwordedIcon:SetTopOffset(96)
    self.serverDetailsWindow.passwordedIcon:SetRightOffset(24)
    self.serverDetailsWindow.passwordedIcon:SetBackgroundTexture("ui/lock.dds")
    
    self.serverDetailsWindow.playerEntries = {}
    
    self.serverDetailsWindow.SetServerData = function(self, serverData, serverIndex)
    
        self.serverIndex = serverIndex
        
        for i = 1,  #self.playerEntries do
        
            self.playerEntries[#self.playerEntries]:Uninitialize()
            self.playerEntries[#self.playerEntries] = nil
        
        end
        
        self.serverName:SetText("")
        self.serverAddress:SetText("Address:")
        self.playerCount:SetText("Players:")
        self.ping:SetText("Ping:")
        self.gameMode:SetText("Game Mode:")
        self.map:SetText("Map:")
        self.modsDesc:SetText("Installed Mods:")
        self.modList:SetText("...")
        self.performance:SetText("Performance:")
        
        if serverData then
    
            self.serverName:SetText(serverData.name)
            self.serverAddress:SetText(string.format("Address: %s", ToString(serverData.address)))
            self.playerCount:SetText(string.format("Players: %d / %d", serverData.numPlayers, serverData.maxPlayers))
            self.ping:SetText(string.format("Ping: %d", serverData.ping))
            self.gameMode:SetText(string.format("Game Mode: %s", serverData.mode))
            self.map:SetText(string.format("Map: %s", serverData.map))
            
            self.favoriteIcon:SetIsVisible(serverData.favorite)
            self.passwordedIcon:SetIsVisible(serverData.requiresPassword)
        
        elseif serverIndex > 0 then  
            self:SetRefreshed()  
        end
        
        if serverIndex > 0 then
            Client.RequestServerDetails(serverIndex)
        end
    
    end  
    
    self.serverDetailsWindow.SetRefreshed = function(self)
    
        if self.serverIndex > 0 then  

             local serverName = FormatServerName(Client.GetServerName(self.serverIndex), Client.GetServerHasTag(self.serverIndex, "rookie"))
    
             self.serverName:SetText(serverName)
             self.serverAddress:SetText(string.format("Address: %s", ToString(Client.GetServerAddress(self.serverIndex))))
             self.playerCount:SetText(string.format("Players: %d / %d", Client.GetServerNumPlayers(self.serverIndex), Client.GetServerMaxPlayers(self.serverIndex)))
             self.ping:SetText(string.format("Ping: %d", Client.GetServerPing(self.serverIndex)))
             self.gameMode:SetText(string.format("Game Mode: %s", FormatGameMode(Client.GetServerGameMode(self.serverIndex))))
             self.map:SetText(string.format("Map: %s", GetTrimmedMapName(Client.GetServerMapName(self.serverIndex))))
             
             local performance = math.round(Clamp(Client.GetServerTickRate(self.serverIndex) / 30, 0, 1) * 100)
             self.performance:SetText(string.format("Performance: %s%%", ToString(performance)))
             
             local modString = Client.GetServerKeyValue(self.serverIndex, "mods") // "7c59c34 7b986f5 5f9ccf1 5fd7a38 5fdc381 6ec6bcd 676c71a 7619dc7"
             local modTitles = nil
             
             local mods = StringSplit(StringTrim(modString), " ")
             local modCount = string.len(modString) == 0 and 0 or #mods
             for m = 1, #mods do
             
                local modId = tonumber("0x" .. mods[m])             
                if not currentlyDownloadingModDetails and modId and not downloadedModDetails[modId] then

                    Client.GetModDetails(modId, ModDetailsCallback)
                    currentlyDownloadingModDetails = modId
            
                end
                
                local modTitle = downloadedModDetails[modId]
                if modTitle then
                
                    if not modTitles then
                        modTitles = modTitle
                    else                
                        modTitles = modTitles .. ", " .. modTitle
                    end    
                        
                end
                
             end
             
             self.modsDesc:SetText(string.format("Installed Mods: %d", modCount))
             if modTitles then
                self.modList:SetText(modTitles)
             end
             
             self.passwordedIcon:SetIsVisible(Client.GetServerRequiresPassword(self.serverIndex))
             
             local playersInfo = { }
             Client.GetServerPlayerDetails(self.serverIndex, playersInfo)
             //TestGetServerPlayerDetails(self.serverIndex, playersInfo)
             
             // update entry count:
             local numEntries = #self.playerEntries
             local numCurrentEntries = #playersInfo
             
             if numEntries > numCurrentEntries then
             
                for i = 1,  numEntries - numCurrentEntries do
                
                    self.playerEntries[#self.playerEntries]:Uninitialize()
                    self.playerEntries[#self.playerEntries] = nil
                
                end
             
             elseif numCurrentEntries > numEntries then
             
                for i = 1, numCurrentEntries - numEntries do
                
                    local entry = CreateMenuElement(self:GetContentBox(), "PlayerEntry")
                    table.insert(self.playerEntries, entry)                    
                
                end
             
             end
             
             // update data and positions
             for i = 1, numCurrentEntries do
             
                local data = playersInfo[i]
                local entry = self.playerEntries[i]
                
                entry:SetTopOffset( (i-1) * kPlayerEntryHeight )
                entry:SetPlayerData(data)
             
             end
    
        end
    
    end
    
    self.serverDetailsWindow.slideBar:AddCSSClass("window_scroller_playernames")
    self.serverDetailsWindow:ResetSlideBar()

end

function GUIMainMenu:CreateServerListWindow()

    self.playWindow.detailsButton = CreateMenuElement(self.playWindow, "MenuButton")
    self.playWindow.detailsButton:SetCSSClass("serverdetailsbutton")
    self.playWindow.detailsButton:SetText("DETAILS")

    self.playWindow.detailsButton:AddEventCallbacks({
        OnClick = function(self)
            self.scriptHandle.serverDetailsWindow:SetServerData(MainMenu_GetSelectedServerData(), MainMenu_GetSelectedServer() or 0)
            self.scriptHandle.serverDetailsWindow:SetIsVisible(true)
        end
    })

    local update = CreateMenuElement(self.playWindow, "MenuButton")
    update:SetCSSClass("update")
    update:SetText("UPDATE")
    self.playWindow.updateButton = update
    update:AddEventCallbacks({
        OnClick = function()
            UpdateServerList(self)
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
    self.serverList = CreateMenuElement(self.playWindow:GetContentBox(), "ServerList")
    
    local columnClassNames =
    {
        "favorite",
        "private",
        "servername",
        "game",
        "map",
        "players",
        "rate",
        "ping"
    }
    
    local rowNames = { { "FAVORITE", "PRIVATE", "NAME", "GAME", "MAP", "PLAYERS", "PERF.", "PING" } }
    
    local serverList = self.serverList
    
    local entryCallbacks = {
        { OnClick = function() UpdateSortOrder(1) serverList:SetComparator(SortByFavorite) end },
        { OnClick = function() UpdateSortOrder(2) serverList:SetComparator(SortByPrivate) end },
        { OnClick = function() UpdateSortOrder(3) serverList:SetComparator(SortByName) end },
        { OnClick = function() UpdateSortOrder(4) serverList:SetComparator(SortByMode) end },
        { OnClick = function() UpdateSortOrder(5) serverList:SetComparator(SortByMap) end },
        { OnClick = function() UpdateSortOrder(6) serverList:SetComparator(SortByPlayers) end },
        { OnClick = function() UpdateSortOrder(7) serverList:SetComparator(SortByTickrate) end },
        { OnClick = function() UpdateSortOrder(8) serverList:SetComparator(SortByPing) end }
    }
    
    self.serverRowNames:SetCSSClass("server_list_row_names")
    self.serverRowNames:AddCSSClass("server_list_names")
    self.serverRowNames:SetColumnClassNames(columnClassNames)
    self.serverRowNames:SetEntryCallbacks(entryCallbacks)
    self.serverRowNames:SetRowPattern( { RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, } )
    self.serverRowNames:SetTableData(rowNames)
    
    self.playWindow:AddEventCallbacks({
        OnShow = function()
        
            // Default to no sorting.
            sortedColumn = nil
            entryCallbacks[6].OnClick()
            self.playWindow:ResetSlideBar()
            UpdateServerList(self)
            
        end
    })
    
    CreateFilterForm(self)
    
    self.serverCountDisplay = CreateMenuElement(self.playWindow, "MenuButton")
    self.serverCountDisplay:SetCSSClass("server_count_display")
    
    self.serverTabs = CreateMenuElement(self.playWindow, "ServerTabs", true)
    self.serverTabs:SetCSSClass("main_server_tabs")
    self.serverTabs:SetServerList(self.serverList)
    
end

function GUIMainMenu:ResetServerSelection()
    
    self.selectServer:SetIsVisible(false)
    MainMenu_SelectServer(nil, nil)
    
end

local function SaveServerSettings(formData)

    Client.SetOptionString("serverName", formData.ServerName)
    Client.SetOptionString("mapName", formData.Map)
    Client.SetOptionString("lastServerMapName", formData.Map)
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
    Client.SetOptionString("lastServerMapName", mapName)
    
    if Client.StartServer(modIndex, mapName, serverName, password, port, maxPlayers) then
        LeaveMenu()
    end
    
end

local function CreateServer(self)

    local formData = self.createServerForm:GetFormData()
    SaveServerSettings(formData)
    
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

GUIMainMenu.CreateOptionsForm = function(mainMenu, content, options, optionElements)

    local form = CreateMenuElement(content, "Form", false)
    
    local rowHeight = 50
    
    for i = 1, #options do
    
        local option = options[i]
        local input
        local defaultInputClass = "option_input"
        
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
        elseif option.type == "progress" then
            input = form:CreateFormElement(Form.kElementType.ProgressBar, option.name, option.value)       
        elseif option.type == "checkbox" then
            input = form:CreateFormElement(Form.kElementType.Checkbox, option.name, option.value)
            defaultInputClass = "option_checkbox"
        else
            input = form:CreateFormElement(Form.kElementType.TextInput, option.name, option.value)
        end
        
        if option.callback then
            input:AddSetValueCallback(option.callback)
        end
        
        local y = rowHeight * (i - 1)
        
        local inputClass = defaultInputClass
        if option.inputClass then
            inputClass = option.inputClass
        end
        
        input:SetCSSClass(inputClass)
        input:SetTopOffset(y)

        local label = CreateMenuElement(form, "Font", false)
        label:SetCSSClass("option_label")
        label:SetText(option.label .. ":")
        label:SetTopOffset(y)
        label:SetIgnoreEvents(true)

        optionElements[option.name] = input

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
        
    local createdElements = {}
    local content = self.explore
    local createServerForm = GUIMainMenu.CreateOptionsForm(self, content, hostOptions, createdElements)
    
    self.createExploreServerForm = createServerForm
    self.createExploreServerForm:SetCSSClass("createserver")
    
    local mapList = createdElements.Map
    
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

    self.createGame:AddEventCallbacks({ OnHide = function()
            SaveServerSettings(self.createServerForm:GetFormData())
            end })

    local minPlayers            = 2
    local maxPlayers            = 24
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
        
    local createdElements = {}
    
    local content = self.createGame
    local createServerForm = GUIMainMenu.CreateOptionsForm(self, content, hostOptions, createdElements)
    
    self.createServerForm = createServerForm
    self.createServerForm:SetCSSClass("createserver")
    
    local mapList = createdElements.Map
    
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

local function CheckForConflictedKeys(keyInputs)

    // Reset back to non-conflicted state.
    for k = 1, #keyInputs do
        keyInputs[k]:SetCSSClass("option_input")
    end
    
    // Check for conflicts.
    for k1 = 1, #keyInputs do
    
        for k2 = 1, #keyInputs do
        
            if k1 ~= k2 then
            
                local boundKey1 = Client.GetOptionString("input/" .. keyInputs[k1].inputName, "")
                local boundKey2 = Client.GetOptionString("input/" .. keyInputs[k2].inputName, "")
                if boundKey1 == boundKey2 then
                
                    keyInputs[k1]:SetCSSClass("option_input_conflict")
                    keyInputs[k2]:SetCSSClass("option_input_conflict")
                    
                end
                
            end
            
        end
        
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
                    
                    Client.SetOptionString("input/" .. keyInput.inputName, keyString)
                    
                    CheckForConflictedKeys(mainMenu.keyInputs)
                    
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
    
    CheckForConflictedKeys(mainMenu.keyInputs)
    
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
    local advancedmovement      = Client.GetOptionBoolean( "AdvancedMovement", false )

    local screenResIdx          = OptionsDialogUI_GetScreenResolutionsIndex()
    local visualDetailIdx       = OptionsDialogUI_GetVisualDetailSettingsIndex()
    local displayMode           = table.find(kDisplayModes, OptionsDialogUI_GetWindowMode())
    local displayBuffering      = Client.GetOptionInteger("graphics/display/display-buffering", 0)
    local multicoreRendering    = Client.GetOptionBoolean("graphics/multithreaded", true)
    local textureStreaming      = Client.GetOptionBoolean("graphics/texture-streaming", false)
    local ambientOcclusion      = Client.GetOptionString("graphics/display/ambient-occlusion", kAmbientOcclusionModes[1])
    local reflections           = Client.GetOptionBoolean("graphics/reflections", false)
    local particleQuality       = Client.GetOptionString("graphics/display/particles", "low")
    local infestation           = Client.GetOptionString("graphics/infestation", "rich")
    local fovAdjustment         = Client.GetOptionFloat("graphics/display/fov-adjustment", 0)
    local cameraAnimation       = Client.GetOptionBoolean("CameraAnimation", false) and "ON" or "OFF"
    local decalLifeTime         = Client.GetOptionFloat("graphics/decallifetime", 0.2)
    
    local minimapZoom = Client.GetOptionFloat( "minimap-zoom", 0.75 )
    local armorType = Client.GetOptionString( "armorType", "" )
    
    if string.len(armorType) == 0 then
    
        if GetHasBlackArmor() then
            armorType = "Black"
        elseif GetHasDeluxeEdition() then
            armorType = "Deluxe"
        else
            armorType = "Green"
        end
        
    end
    
    Client.SetOptionString("armorType", armorType)
    
    // support legacy values    
    if ambientOcclusion == "false" then
        ambientOcclusion = "off"
    elseif ambientOcclusion == "true" then
        ambientOcclusion = "high"
    end
    
    local shadows = OptionsDialogUI_GetShadows()
    local bloom = OptionsDialogUI_GetBloom()
    local atmospherics = OptionsDialogUI_GetAtmospherics()
    local anisotropicFiltering = OptionsDialogUI_GetAnisotropicFiltering()
    local antiAliasing = OptionsDialogUI_GetAntiAliasing()
    
    local soundInputDeviceGuid = Client.GetOptionString(kSoundInputDeviceOptionsKey, "Default")
    local soundOutputDeviceGuid = Client.GetOptionString(kSoundOutputDeviceOptionsKey, "Default")

    local soundInputDevice = 1
    if soundInputDeviceGuid ~= 'Default' then
        soundInputDevice = math.max(Client.FindSoundDeviceByGuid(Client.SoundDeviceType_Input, soundInputDeviceGuid), 0) + 2
    end
    
    local soundOutputDevice = 1
    if soundOutputDeviceGuid ~= 'Default' then
        soundOutputDevice = math.max(Client.FindSoundDeviceByGuid(Client.SoundDeviceType_Output, soundOutputDeviceGuid), 0) + 2
    end
    
    local soundVol = Client.GetOptionInteger("soundVolume", 90) / 100
    local musicVol = Client.GetOptionInteger("musicVolume", 90) / 100
    local voiceVol = Client.GetOptionInteger("voiceVolume", 90) / 100
    local recordingGain = Client.GetOptionFloat("recordingGain", 0.5)
    
    for i = 1, #kLocales do
    
        if kLocales[i].name == locale then
            optionElements.Language:SetOptionActive(i)
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
    optionElements.AdvancedMovement:SetOptionActive( BoolToIndex(advancedmovement) )

    optionElements.DisplayMode:SetOptionActive( displayMode )
    optionElements.DisplayBuffering:SetOptionActive( displayBuffering + 1 )
    optionElements.Resolution:SetOptionActive( screenResIdx )
    optionElements.Shadows:SetOptionActive( BoolToIndex(shadows) )
    optionElements.Infestation:SetOptionActive( table.find(kInfestationModes, infestation) )
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
    optionElements.MinimapZoom:SetValue(minimapZoom)
    optionElements.ArmorType:SetValue(armorType)
    optionElements.DecalLifeTime:SetValue(decalLifeTime)
    optionElements.CameraAnimation:SetValue(cameraAnimation)
    optionElements.ParticleQuality:SetOptionActive( table.find(kParticleQualityModes, particleQuality) ) 
    
    
    optionElements.SoundInputDevice:SetOptionActive(soundInputDevice)
    optionElements.SoundOutputDevice:SetOptionActive(soundOutputDevice)
    optionElements.SoundVolume:SetValue(soundVol)
    optionElements.MusicVolume:SetValue(musicVol)
    optionElements.VoiceVolume:SetValue(voiceVol)
    
    optionElements.RecordingGain:SetValue(recordingGain)
    
end

local function SaveSecondaryGraphicsOptions(mainMenu)
    // These are options that are pretty quick to change, unlike screen resolution etc.
    // Have this separate, since graphics options are auto-applied
        
    local multicoreRendering    = mainMenu.optionElements.MulticoreRendering:GetActiveOptionIndex() > 1
    local textureStreaming      = mainMenu.optionElements.TextureStreaming:GetActiveOptionIndex() > 1
    local ambientOcclusionIdx   = mainMenu.optionElements.AmbientOcclusion:GetActiveOptionIndex()
    local visualDetailIdx       = mainMenu.optionElements.Detail:GetActiveOptionIndex()
    local infestationIdx        = mainMenu.optionElements.Infestation:GetActiveOptionIndex()
    local shadows               = mainMenu.optionElements.Shadows:GetActiveOptionIndex() > 1
    local bloom                 = mainMenu.optionElements.Bloom:GetActiveOptionIndex() > 1
    local atmospherics          = mainMenu.optionElements.Atmospherics:GetActiveOptionIndex() > 1
    local anisotropicFiltering  = mainMenu.optionElements.AnisotropicFiltering:GetActiveOptionIndex() > 1
    local antiAliasing          = mainMenu.optionElements.AntiAliasing:GetActiveOptionIndex() > 1
    local particleQualityIdx    = mainMenu.optionElements.ParticleQuality:GetActiveOptionIndex()
    local reflections           = mainMenu.optionElements.Reflections:GetActiveOptionIndex() > 1
    
    Client.SetOptionBoolean("graphics/reflections", reflections)
    Client.SetOptionBoolean("graphics/multithreaded", multicoreRendering)
    Client.SetOptionBoolean("graphics/texture-streaming", textureStreaming)
    Client.SetOptionString("graphics/display/ambient-occlusion", kAmbientOcclusionModes[ambientOcclusionIdx] )
    Client.SetOptionString("graphics/display/particles", kParticleQualityModes[particleQualityIdx] )
    Client.SetOptionString("graphics/infestation", kInfestationModes[infestationIdx] )
    Client.SetOptionInteger( kDisplayQualityOptionsKey, visualDetailIdx - 1 )
    Client.SetOptionBoolean ( kShadowsOptionsKey, shadows )
    Client.SetOptionBoolean ( kBloomOptionsKey, bloom )
    Client.SetOptionBoolean ( kAtmosphericsOptionsKey, atmospherics )
    Client.SetOptionBoolean ( kAnisotropicFilteringOptionsKey, anisotropicFiltering )
    Client.SetOptionBoolean ( kAntiAliasingOptionsKey, antiAliasing )
    
end

local function SyncSecondaryGraphicsOptions()
    Render_SyncRenderOptions() 
    if Infestation_SyncOptions then
        Infestation_SyncOptions()
    end
    Input_SyncInputOptions()
end

local function OnGraphicsOptionsChanged(mainMenu)
    SaveSecondaryGraphicsOptions(mainMenu)
    Client.ReloadGraphicsOptions()
    SyncSecondaryGraphicsOptions()
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

local function OnRecordingGainChanged(mainMenu)
    local recordingGain = mainMenu.optionElements.RecordingGain:GetValue()
    Client.SetRecordingGain(recordingGain)
    Client.SetOptionFloat("recordingGain", recordingGain)
end

local function OnFOVAdjustChanged(mainMenu)
    local value = mainMenu.optionElements.FOVAdjustment:GetValue()
    Client.SetOptionFloat("graphics/display/fov-adjustment", value)
end

local function OnMinimapZoomChanged(mainMenu)

    local value = mainMenu.optionElements.MinimapZoom:GetValue()
    Client.SetOptionFloat("minimap-zoom", value)

    if SafeRefreshMinimapZoom then
        SafeRefreshMinimapZoom()
    end

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
    
    local armorType             = mainMenu.optionElements.ArmorType:GetValue()
    local cameraAnimation       = mainMenu.optionElements.CameraAnimation:GetActiveOptionIndex() > 1
    local advancedmovement      = mainMenu.optionElements.AdvancedMovement:GetActiveOptionIndex() > 1
    local particleQuality       = mainMenu.optionElements.ParticleQuality:GetActiveOptionIndex()
    
    Client.SetOptionString( "locale", locale )

    Client.SetOptionBoolean("input/mouse/rawinput", rawInput)
    Client.SetOptionBoolean("input/mouse/acceleration", mouseAcceleration)
    Client.SetOptionBoolean( "showHints", showHints )
    Client.SetOptionBoolean( "commanderHelp", showCommanderHelp )
    Client.SetOptionBoolean( "drawDamage", drawDamage)
    Client.SetOptionBoolean( kRookieOptionsKey, rookieMode)
    Client.SetOptionBoolean( "CameraAnimation", cameraAnimation)
    Client.SetOptionBoolean( "AdvancedMovement", advancedmovement)
    Client.SetOptionString( "armorType", armorType )

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

    SyncSecondaryGraphicsOptions()
    
    for k = 1, #mainMenu.keyInputs do
    
        local keyInput = mainMenu.keyInputs[k]
        Client.SetOptionString("input/" .. keyInput.inputName, keyInput:GetValue())
        
    end
    Client.ReloadKeyOptions()
    

end

local function StoreCameraAnimationOption(formElement)
    Client.SetOptionBoolean("CameraAnimation", formElement:GetActiveOptionIndex() > 1)
end

local function StoreAdvancedMovementOption(formElement)
    Client.SetOptionBoolean("AdvancedMovement", formElement:GetActiveOptionIndex() > 1)
    if UpdateMovementMode then
        UpdateMovementMode()
    end
end

local function OnDecalLifeTimeChanged(mainMenu)

    local value = mainMenu.optionElements.DecalLifeTime:GetValue()
    Client.SetOptionFloat("graphics/decallifetime", value)
    
end

local function OnSoundDeviceChanged(window, formElement, deviceType)

    if formElement.inSoundCallback then
        return
    end

    local activeOptionIndex = formElement:GetActiveOptionIndex()
    
    if activeOptionIndex == 1 then
        if Client.GetSoundDeviceCount(deviceType) > 0 then
            Client.SetSoundDevice(deviceType, 0)
        end
        
        if deviceType == Client.SoundDeviceType_Input then
            Client.SetOptionString(kSoundInputDeviceOptionsKey, 'Default')
        elseif deviceType == Client.SoundDeviceType_Output then
            Client.SetOptionString(kSoundOutputDeviceOptionsKey, 'Default')
        end        
        return
    end
    
    local deviceId = activeOptionIndex - 2

    // Get GUIDs of all audio devices
    local numDevices = Client.GetSoundDeviceCount(deviceType)
    local guids = {}
    for id = 1, numDevices do
        guids[id] = Client.GetSoundDeviceGuid(deviceType, id - 1)
    end

    local desiredGuid = guids[deviceId + 1]
    Client.SetSoundDevice(deviceType, deviceId)

    // Check if GUIDs are still the same, update the list in process
    local newNumDevices = Client.GetSoundDeviceCount(deviceType)
    local listChanged = numDevices ~= newNumDevices
    numDevices = newNumDevices
    
    for id = 1, numDevices do
        local guid = Client.GetSoundDeviceGuid(deviceType, id - 1)
        if guids[id] ~= guid then
            listChanged = true
            guids[id] = guid
        end
    end
    
    if listChanged then
        // Device list order changed        
        // Avoid re-entering this callback
        formElement.inSoundCallback = true
        
        local soundOutputDevices = OptionsDialogUI_GetSoundDeviceNames(deviceType)
        formElement:SetOptions(soundOutputDevices)
        
        // Find the GUID we were trying to select again
        deviceId = Client.FindSoundDeviceByGuid(deviceType, desiredGuid)
        
        if deviceId == -1 then
            deviceId = 0
        end
        
        formElement:SetOptionActive(deviceId + 1)
        Client.SetSoundDevice(deviceType, deviceId)
        
        formElement.inSoundCallback = false
    end
    
    window:UpdateRestartMessage()

    guid = guids[deviceId + 1]
    if guid == nil then
        Print('Warning: device %d (type %d) has invalid GUID', deviceId, deviceType)
        guid = ''
    end
    if deviceType == Client.SoundDeviceType_Input then
        Client.SetOptionString(kSoundInputDeviceOptionsKey, guid)
    elseif deviceType == Client.SoundDeviceType_Output then
        Client.SetOptionString(kSoundOutputDeviceOptionsKey, guid)
    end
    
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
    
    self.warningLabel = CreateMenuElement(self.optionWindow, "MenuButton", false)
    self.warningLabel:SetCSSClass("warning_label")
    self.warningLabel:SetText("Game restart required")
    self.warningLabel:SetIgnoreEvents(true)
    self.warningLabel:SetIsVisible(false)
    
    local screenResolutions = OptionsDialogUI_GetScreenResolutions()
    local soundOutputDevices = OptionsDialogUI_GetSoundDeviceNames(Client.SoundDeviceType_Output)
    local soundInputDevices = OptionsDialogUI_GetSoundDeviceNames(Client.SoundDeviceType_Input)
    
    local languages = { }
    for i = 1,#kLocales do
        languages[i] = kLocales[i].label
    end
    
    local armorTypes = {
        "Green"
    }
    
    if GetHasBlackArmor() then
        table.insert(armorTypes, "Black")
    end
    
    if GetHasDeluxeEdition() then
        table.insert(armorTypes, "Deluxe")
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
            { 
                name    = "MinimapZoom",
                label   = "MINIMAP ZOOM",
                type    = "slider",
                sliderCallback = OnMinimapZoomChanged,
            },
            
            {
                name    = "ArmorType",
                label   = "ARMOR TYPE",
                type    = "select",
                values  = armorTypes
            },
            
            {
                name    = "CameraAnimation",
                label   = "CAMERA ANIMATION",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = StoreCameraAnimationOption
            }, 
            
            {
                name    = "AdvancedMovement",
                label   = "ADVANCED MOVEMENT",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = StoreAdvancedMovementOption
            }, 
        }

    local soundOptions =
        {
            {   
                name   = "SoundOutputDevice",
                label  = "OUTPUT DEVICE",
                type   = "select",
                values = soundOutputDevices,
                callback = function(formElement) OnSoundDeviceChanged(self, formElement, Client.SoundDeviceType_Output) end,
            },
            {   
                name   = "SoundInputDevice",
                label  = "INPUT DEVICE",
                type   = "select",
                values = soundInputDevices,
                callback = function(formElement) OnSoundDeviceChanged(self, formElement, Client.SoundDeviceType_Input) end,
            },            
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
            {
                name    = "RecordingGain",
                label   = "MICROPHONE GAIN",
                type    = "slider",
                sliderCallback = OnRecordingGainChanged,
            },
            {
                name    = "RecordingVolume",
                label   = "MICROPHONE LEVEL",
                type    = "progress",
            }
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
                name    = "ParticleQuality",
                label   = "PARTICLE QUALITY",
                type    = "select",
                values  = { "LOW", "HIGH" },
                callback = autoApplyCallback
            },            
            {
                name    = "DecalLifeTime",
                label   = "DECAL LIFE TIME",
                type    = "slider",
                sliderCallback = OnDecalLifeTimeChanged,
            },    
            {
                name    = "Infestation",
                label   = "INFESTATION",
                type    = "select",
                values  = { "MINIMAL", "RICH" },
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
                label   = "TEXTURE STREAMING",
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
        
    // save our option elements for future reference
    self.optionElements = { }
    
    local generalForm     = GUIMainMenu.CreateOptionsForm(self, content, generalOptions, self.optionElements)
    local keyBindingsForm = CreateKeyBindingsForm(self, content)
    local graphicsForm    = GUIMainMenu.CreateOptionsForm(self, content, graphicsOptions, self.optionElements)
    local soundForm       = GUIMainMenu.CreateOptionsForm(self, content, soundOptions, self.optionElements)
    
    soundForm:SetCSSClass("sound_options")    
    self.soundForm = soundForm
        
    local tabs = 
        {
            { label = "GENERAL",  form = generalForm, scroll=true  },
            { label = "BINDINGS", form = keyBindingsForm, scroll=true },
            { label = "GRAPHICS", form = graphicsForm, scroll=true },
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
    
        local currentTime = Client.GetTime()
        
        // Refresh the mod list once every 5 seconds.
        self.timeOfLastRefresh = self.timeOfLastRefresh or currentTime
        if self.modsWindow and self.modsWindow:GetIsVisible() and currentTime - self.timeOfLastRefresh >= 5 then
        
            self:RefreshModsList()
            self.timeOfLastRefresh = currentTime
            
        end
        
        self.tweetText:Update(deltaTime)
        
        local alertText = MainMenu_GetAlertMessage()
        if self.currentAlertText ~= alertText then
        
            self.currentAlertText = alertText
            
            if self.currentAlertText then
            
                local setAlertText = self.currentAlertText
                if setAlertText:len() > 32 then
                    setAlertText = setAlertText:sub(0, 32) .. "\n" .. setAlertText:sub(33, setAlertText:len())
                end
                self.alertText:SetText(setAlertText)
                self.alertWindow:SetIsVisible(true)
                
            end
            
        end
        
        // Update only when visible.
        GUIAnimatedScript.Update(self, deltaTime)
    
        if self.soundForm and self.soundForm:GetIsVisible() then
            if self.optionElements.RecordingVolume then
                self.optionElements.RecordingVolume:SetValue(Client.GetRecordingVolume())
            end
        end
    
        if self.menuBackground:GetIsVisible() then
            self.playerName:SetText(OptionsDialogUI_GetNickname())
        end
        
        if self.modsWindow and self.modsWindow:GetIsVisible() then
            self:UpdateModsWindow(self)
        end
        
        if self.playWindow and self.playWindow:GetIsVisible() then
        
            local listChanged = false
        
            if not Client.GetServerListRefreshed() then
   
                for s = 0, Client.GetNumServers() - 1 do
                
                    if s + 1 > self.numServers then
                    
                        local serverEntry = BuildServerEntry(s)
                        if self.serverList:GetEntryExists(serverEntry) then
                        
                            self.serverList:UpdateEntry(serverEntry, true)
                            if GetServerIsFavorite(serverEntry.address) then
                                UpdateFavoriteServerData(serverEntry)
                            end
                            
                            if GetServerIsHistory(serverEntry.address) then
                                UpdateHistoryServerData(serverEntry)
                            end
                            
                        else
                        
                            self.serverList:AddEntry(serverEntry, true)
                            self.numServers = self.numServers + 1
                            
                        end
                        
                        listChanged = true
                        
                    end
                    
                end

                
            else
                self.playWindow.updateButton:SetText("UPDATE")
            end
            
            if listChanged then
                self.serverList:RenderNow()
                self.serverTabs:SetGameTypes(self.serverList:GetGameTypes())
            end
            
            local countTxt = ToString(Client.GetNumServers()) .. (Client.GetServerListRefreshed() and "" or "...")
            self.serverCountDisplay:SetText(countTxt)
            
        end
        
        self:UpdateFindPeople(deltaTime)

        if self.playNowWindow then
            self.playNowWindow:UpdateLogic(self)
        end
        
        if self.fpsDisplay then
            self.fpsDisplay:SetText(string.format("FPS: %.0f", Client.GetFrameRate()))
        end
        
        if self.updateAutoJoin then
        
            if not self.timeLastAutoJoinUpdate or self.timeLastAutoJoinUpdate + 10 < Shared.GetTime() then
            
                Client.RefreshServer(MainMenu_GetSelectedServer())
                
                if MainMenu_GetSelectedIsFull() then
                    self.timeLastAutoJoinUpdate = Shared.GetTime()
                else
                
                    MainMenu_JoinSelected()
                    self.autoJoinWindow:SetIsVisible(false)
                    
                end
                
            end
            
        end
        
        if self.serverDetailsWindow and self.serverDetailsWindow:GetIsVisible() then

            if not self.timeDetailsRefreshed or self.timeDetailsRefreshed + 0.5 < Shared.GetTime() then
            
                local index = self.serverDetailsWindow.serverIndex    
                
                if index > 0 then
                
                    local function RefreshCallback(index)
                        MainMenu_OnServerRefreshed(index)
                    end
                    Client.RefreshServer(index, RefreshCallback)
                    
                    self.timeDetailsRefreshed = Shared.GetTime()   
                
                end
            
            end
        
        end
        
    end
    
end

function GUIMainMenu:OnServerRefreshed(serverIndex)

    local serverEntry = BuildServerEntry(serverIndex)
    self.serverList:UpdateEntry(serverEntry)
    
    if self.serverDetailsWindow and self.serverDetailsWindow:GetIsVisible() then
        self.serverDetailsWindow:SetRefreshed()
    end
    
end

function GUIMainMenu:ShowMenu()

    self.menuBackground:SetIsVisible(true)
    self.menuBackground:SetCSSClass("menu_bg_show", false)
    
    self.logo:SetIsVisible(true)
    
    if self.newsScript then
        self.newsScript:SetIsVisible(true)
    end
    
end

function GUIMainMenu:HideMenu()

    self.menuBackground:SetCSSClass("menu_bg_hide", false)

    if self.resumeLink then
        self.resumeLink:SetIsVisible(false)
    end
    if self.readyRoomLink then
        self.readyRoomLink:SetIsVisible(false)
    end
    if self.voteLink then
        self.voteLink:SetIsVisible(false)
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
    if self.newsScript then
        self.newsScript:SetIsVisible(false)
    end
    
end

function GUIMainMenu:OnAnimationsEnd(item)
    
    if item == self.scanLine:GetBackground() then
        self.scanLine:SetCSSClass("scanline")
    end
    
end

function GUIMainMenu:OnAnimationCompleted(animatedItem, animationName, itemHandle)

    if animationName == "ANIMATE_LINK_BG" then
        
        local animBackgroundLink = {}
    
        if self.modsLink then
            table.insert(animBackgroundLink, self.modsLink)
        end
        if self.quitLink then
            table.insert(animBackgroundLink, self.quitLink)
        end
        table.insert(animBackgroundLink, self.highlightServer)
        if self.disconnectLink then
            table.insert(animBackgroundLink, self.disconnectLink)
        end
        if self.resumeLink then
            table.insert(animBackgroundLink, self.resumeLink)
        end
        if self.readyRoomLink then
            table.insert(animBackgroundLink, self.readyRoomLink)
        end
        if self.voteLink then
            table.insert(animBackgroundLink, self.voteLink)
        end
        table.insert(animBackgroundLink, self.playLink)
        table.insert(animBackgroundLink, self.tutorialLink)
        table.insert(animBackgroundLink, self.optionLink)
        
        for i = 1, #animBackgroundLink do        
            animBackgroundLink[i]:SetFrameCount(15, 1.6, AnimateLinear, "ANIMATE_LINK_BG")       
        end
        
    elseif animationName == "ANIMATE_BLINKING_ARROW" and self.blinkingArrow then
    
        self.blinkingArrow:SetCSSClass("blinking_arrow")
        
    elseif animationName == "ANIMATE_BLINKING_ARROW_TWO" then
    
        self.blinkingArrowTwo:SetCSSClass("blinking_arrow_two")
        
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
            if self.voteLink then
                self.voteLink:SetIsVisible(true)
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

function GUIMainMenu:UpdateRestartMessage()
    
    local needsRestart = not Client.GetIsSoundDeviceValid(Client.SoundDeviceType_Input) or
                         not Client.GetIsSoundDeviceValid(Client.SoundDeviceType_Output)
        
    if needsRestart then
        self.warningLabel:SetText("Game restart required")
        self.warningLabel:SetIsVisible(true)        
    else
        self.warningLabel:SetIsVisible(false)        
    end

end


function OnSoundDeviceListChanged()

    // The options page may not be initialized yet
    if gMainMenu ~= nil and gMainMenu.optionElements ~= nil then 

        local soundInputDeviceGuid = Client.GetOptionString(kSoundInputDeviceOptionsKey, "Default")
        local soundOutputDeviceGuid = Client.GetOptionString(kSoundOutputDeviceOptionsKey, "Default")

        local soundInputDevice = 1
        if soundInputDeviceGuid ~= 'Default' then
            soundInputDevice = math.max(Client.FindSoundDeviceByGuid(Client.SoundDeviceType_Input, soundInputDeviceGuid), 0) + 2
        end
        
        local soundOutputDevice = 1
        if soundOutputDeviceGuid ~= 'Default' then
            soundOutputDevice = math.max(Client.FindSoundDeviceByGuid(Client.SoundDeviceType_Output, soundOutputDeviceGuid), 0) + 2
        end

        local soundOutputDevices = OptionsDialogUI_GetSoundDeviceNames(Client.SoundDeviceType_Output)
        local soundInputDevices = OptionsDialogUI_GetSoundDeviceNames(Client.SoundDeviceType_Input)

        gMainMenu.optionElements.SoundInputDevice:SetOptions(soundInputDevices)
        gMainMenu.optionElements.SoundInputDevice:SetOptionActive(soundInputDevice)
        
        gMainMenu.optionElements.SoundOutputDevice:SetOptions(soundOutputDevices)
        gMainMenu.optionElements.SoundOutputDevice:SetOptionActive(soundOutputDevice)

    end

end

// Called when the options file is changed externally
local function OnOptionsChanged()

    if gMainMenu ~= nil then
        InitOptions(gMainMenu.optionElements)
    end
    
end

Event.Hook("SoundDeviceListChanged", OnSoundDeviceListChanged)
Event.Hook("OptionsChanged", OnOptionsChanged)
