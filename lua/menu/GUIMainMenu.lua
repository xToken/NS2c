// ======= Copyright (c) 2003-2014, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\menu\GUIMainMenu.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworld.com) and
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
Script.Load("lua/menu/GatherFrame.lua")
Script.Load("lua/menu/ServerTabs.lua")
Script.Load("lua/menu/PlayerEntry.lua")
Script.Load("lua/dkjson.lua")
Script.Load("lua/menu/MenuPoses.lua")
Script.Load("lua/HitSounds.lua")

local kMainMenuLinkColor = Color(137 / 255, 137 / 255, 137 / 255, 1)

class 'GUIMainMenu' (GUIAnimatedScript)

Script.Load("lua/menu/GUIMainMenu_PlayNow.lua")
Script.Load("lua/menu/GUIMainMenu_Mods.lua")
Script.Load("lua/menu/GUIMainMenu_Training.lua")
Script.Load("lua/menu/GUIMainMenu_Web.lua")
Script.Load("lua/menu/GUIMainMenu_Gather.lua")
Script.Load("lua/menu/GUIMainMenu_Customize.lua")

-- Min and maximum values for the mouse sensitivity slider
local kMinSensitivity = 0.01
local kMaxSensitivity = 20

local kMinAcceleration = 1
local kMaxAcceleration = 1.4

local kWindowModeIds         = { "windowed", "fullscreen", "fullscreen-windowed" }
local kWindowModeNames       = { "WINDOWED", "FULLSCREEN", "FULLSCREEN WINDOWED" }

local kAmbientOcclusionModes = { "off", "medium", "high" }
local kInfestationModes      = { "minimal", "rich" }
local kParticleQualityModes  = { "low", "high" }
local kRenderDevices         = Client.GetRenderDeviceNames()
local kRenderDeviceDisplayNames = {}

for i = 1, #kRenderDevices do
    local name = kRenderDevices[i]
    if name == "D3D11" or name == "OpenGL" then
        name = name .. " (Beta)"
    end
    kRenderDeviceDisplayNames[i] = name
end
    
local kLocales =
    {
        { name = "enUS", label = "English" },
        { name = "bgBG", label = "Bulgarian" },
        { name = "hrHR", label = "Croatian"},
        { name = "csCS", label = "Czech" },
        { name = "daDK", label = "Danish"},
        { name = "nlNL", label = "Dutch"},
        { name = "fiFI", label = "Finnish"},
        { name = "frFR", label = "French" },       
        { name = "deDE", label = "German" },
        { name = "itIT", label = "Italian" },
        { name = "koKR", label = "Korean" },
        { name = "noNO", label = "Norwegian" },
        { name = "plPL", label = "Polish" },
        { name = "ptBR", label = "Portuguese" },
        { name = "ruRU", label = "Russian" },
        { name = "esES", label = "Spanish" },
        { name = "seSW", label = "Swedish" }
    }    

local gMainMenu
function GetGUIMainMenu()

    return gMainMenu
    
end

function GUIMainMenu:TriggerOpenAnimation(window)

    if not window:GetIsVisible() then

        self.windowToOpen = window
        self:SetShowWindowName(window:GetWindowName())

    end

    MainMenu_OnPlayButtonClicked()

end

function GUIMainMenu:Initialize()

    GUIAnimatedScript.Initialize(self)

    Shared.Message("Main Menu Initialized at Version: " .. Shared.GetBuildNumber())
    Shared.Message("Steam Id: " .. Client.GetSteamId())
    
    --provides a set of functions required for window handling
    AddMenuMixin(self)
    self:SetCursor("ui/Cursor_MenuDefault.dds")
    self:SetWindowLayer(kWindowLayerMainMenu)
    
    LoadCSSFile("lua/menu/main_menu.css")
    
    self.mainWindow = self:CreateWindow()
    self.mainWindow:SetCSSClass("main_frame")
    
    self.tvGlareImage = CreateMenuElement(self.mainWindow, "Image")
    
    if MainMenu_IsInGame() then
        self.tvGlareImage:SetCSSClass("tvglare_dark")
        self.tvGlareImage:SetIsVisible(false)
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
    
    self.optionTooltip = GetGUIManager():CreateGUIScriptSingle("menu/GUIHoverTooltip")
    
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
                ClientUI.EvaluateUIVisibility(Client.GetLocalPlayer())
                
                //Clear active element which caused mouse wheel to not register events
                GetWindowManager():SetElementInactive()
                
                return true
                
            else
                return false
            end
            
        end
    }
    
    self.mainWindow:AddEventCallbacks(eventCallbacks)

    -- To prevent load delays, we create most windows lazily.
    -- But these are fast enough to just do immediately.
    self:CreatePasswordPromptWindow()
    self:CreateAutoJoinWindow()
    self:CreateAlertWindow()
    self:CreatePlayerCountAlertWindow()
    self:CreateServerNetworkModedAlertWindow()
    self:CreatePlayWindow()    
    self.playWindow:SetIsVisible(false)
    
    if not MainMenu_IsInGame() then
        self:CreateOptionWindow()
        self.optionWindow:SetIsVisible(false)
    end
    
    self.scanLine = CreateMenuElement(self.mainWindow, "Image")
    self.scanLine:SetCSSClass("scanline")

    self.tweetText = CreateMenuElement(self.mainWindow, "Ticker")
    
    --self.logo = CreateMenuElement(self.mainWindow, "Image")
    --self.logo:SetCSSClass("logo")
    
    self:CreateMenuBackground()
    self:CreateProfile()

    gMainMenu = self
    
    self.Links = {}
    self:CreateMainLinks()
    
    local VoiceChat = Client.GetOptionString("input/VoiceChat", "LeftAlt")
    local ShowMap = Client.GetOptionString("input/ShowMap", "C")
    local TextChat = Client.GetOptionString("input/TextChat", "Y")
    local TeamChat = Client.GetOptionString("input/TeamChat", "Return")
    local SelectNextWeapon = Client.GetOptionString("input/SelectNextWeapon", "MouseWheelUp")
    local SelectPrevWeapon = Client.GetOptionString("input/SelectPrevWeapon", "MouseWheelDown")
    local Drop = Client.GetOptionString("input/Drop", "G")

    local VoiceChatCom = Client.GetOptionString("input/VoiceChatCom", VoiceChat)
    local ShowMapCom = Client.GetOptionString("input/ShowMapCom", ShowMap)
    local TextChatCom = Client.GetOptionString("input/TextChatCom", TextChat)
    local TeamChatCom = Client.GetOptionString("input/TeamChatCom", TeamChat)
    local OverHeadZoomIncrease = Client.GetOptionString("input/OverHeadZoomIncrease", SelectNextWeapon)
    local OverHeadZoomDecrease = Client.GetOptionString("input/OverHeadZoomDecrease", SelectPrevWeapon)
    local OverHeadZoomReset = Client.GetOptionString("input/OverHeadZoomReset", Drop)
    
    Client.SetOptionString("input/VoiceChatCom", VoiceChatCom)
    Client.SetOptionString("input/ShowMapCom", ShowMapCom)
    Client.SetOptionString("input/TextChatCom", TextChatCom)
    Client.SetOptionString("input/TeamChatCom", TeamChatCom)
    Client.SetOptionString("input/OverHeadZoomIncrease", OverHeadZoomIncrease)
    Client.SetOptionString("input/OverHeadZoomDecrease", OverHeadZoomDecrease)
    Client.SetOptionString("input/OverHeadZoomReset", OverHeadZoomReset)

    local gPlayerData = {}
    local kPlayerRankingRequestUrl = "http://sabot.herokuapp.com/api/get/playerData/"

        local function PlayerDataResponse(steamId)
            return function (playerData)
        
                PROFILE("PlayerRanking:PlayerDataResponse")
                
                local obj, pos, err = json.decode(playerData, 1, nil)
                
                if obj then
                
                    gPlayerData[steamId..""] = obj
                
                    -- its possible that the server does not send all data we want, need to check for nil here to not cause any script errors later:            
                    obj.skill = obj.skill or 0
                    obj.level = obj.level or 0

                    Client.SetOptionFloat("player-skill", tonumber(obj.skill))
                    Client.SetOptionInteger("player-ranking", obj.level)
                
                end
            end
       end
       
    local requestUrl = kPlayerRankingRequestUrl .. Client.GetSteamId()
    Shared.SendHTTPRequest(requestUrl, "GET", { }, PlayerDataResponse(Client.GetSteamId()))
end

function GUIMainMenu:SetShowWindowName(name)

    self.showWindowAnimation:SetText(ToString(name))
    self.showWindowAnimation:GetBackground():DestroyAnimations()
    self.showWindowAnimation:SetIsVisible(true)
    self.showWindowAnimation:SetCSSClass("showwindow_hidden")
    self.showWindowAnimation:SetCSSClass("showwindow_animation1")
    
end

function GUIMainMenu:CreateMainLink(text, linkNum,OnClick)
    
    local cssClass = MainMenu_IsInGame() and "ingame" or "mainmenu"
    local mainLink = CreateMenuElement(self.menuBackground, "Link")
    mainLink:SetText(Locale.ResolveString(text))
    mainLink:SetCSSClass(cssClass)
    mainLink:SetTopOffset(50 + 70 * linkNum)
    mainLink:SetBackgroundColor(Color(1,1,1,0))
    mainLink:EnableHighlighting()
    
    mainLink.linkIcon = CreateMenuElement(mainLink, "Font")
    local linkNumText = string.format("%s%s", linkNum < 10 and "0" or "", linkNum)
    mainLink.linkIcon:SetText(linkNumText)
    mainLink.linkIcon:SetCSSClass(cssClass)
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
    local callbackTable =
    {
        OnClick = OnClick
    }
    mainLink:AddEventCallbacks(callbackTable)
    
    return mainLink
    
end

function GUIMainMenu:Uninitialize()

    gMainMenu = nil
    self:DestroyAllWindows()
    
    if self.newsScript then
    
        GetGUIManager():DestroyGUIScript(self.newsScript)
        self.newsScript = nil
        
    end
    
    if self.optionsTooltip then
    
        GetGUIManager():DestroyGUIScript(self.optionTooltip)
        self.optionTooltip = nil
        
    end
    
    GUIAnimatedScript.Uninitialize(self)
    
end

function GUIMainMenu:Restart()
    self:Uninitialize()
    self:Initialize()
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
        -- Trigger initial animation
        OnShow = function(self)
        
            -- Passing updateChildren == false to prevent updating of children
            self:SetCSSClass("profile", false)
            
        end,
        
        -- Destroy all animation and reset state
        OnHide = function(self) end
    }
    
    self.profileBackground:AddEventCallbacks(eventCallbacks)
    
    -- Create avatar icon.
    self.avatar = CreateMenuElement(self.profileBackground, "Image")
    self.avatar:SetCSSClass("avatar")
    self.avatar:SetBackgroundTexture("*avatar")
    
    self.playerName = CreateMenuElement(self.profileBackground, "Link")
    self.playerName:SetCSSClass("profile")

    self.rankLevel = CreateMenuElement(self.profileBackground, "Link")
    self.rankLevel:SetCSSClass("rank_level")
    
    eventCallbacks =
    {
        OnClick = function (self, buttonPressed)
            Client.ShowWebpage("http://hive.naturalselection2.com/profile/".. Client.GetSteamId())
        end,
        
        OnMouseIn = function (self, buttonPressed)
            MainMenu_OnMouseIn()
        end,
    }
    
    self.playerName:AddEventCallbacks(eventCallbacks)
    self.rankLevel:AddEventCallbacks(eventCallbacks)
    
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
        serverEntry.playerSkill = currentFavorite.playerSkill or 0
        serverEntry.rookieFriendly = currentFavorite.rookieFriendly or false
        serverEntry.gatherServer = currentFavorite.gatherServer or false
        serverEntry.friendsOnServer = false
        serverEntry.lanServer = false
        serverEntry.tickrate = 30
        serverEntry.currentScore = 0
        serverEntry.performanceScore = 0
        serverEntry.performanceQuality = 0
        serverEntry.serverId = -f
        serverEntry.numRS = currentFavorite.numRS or 0
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
    self.playWindow.updateButton:SetText(Locale.ResolveString("SERVERBROWSER_UPDATE"))
    self.playWindow:ResetSlideBar()
    self.selectServer:SetIsVisible(false)
    self.serverList:ClearChildren()
    -- Needs to be done here because the server IDs will change.
    self:ResetServerSelection()
    
    AddFavoritesToServerList(self.serverList)
    
end

local function JoinServer(self)

    local selectedServer = MainMenu_GetSelectedServer()

    if selectedServer ~= nil then 

        if selectedServer >= 0 and MainMenu_GetSelectedIsFull() and MainMenu_ForceJoin ~= true then
        
            self.autoJoinWindow:SetIsVisible(true)
            self.autoJoinText:SetText(ToString(MainMenu_GetSelectedServerName()))
            
        else
            MainMenu_JoinSelected()
        end
        if selectedServer >= 0 and MainMenu_ForceJoin() == true then
            MainMenu_JoinSelected()
        end
        if selectedServer >= 0 and MainMenu_GetSelectedIsFullWithNoRS() == true then
            self.forceJoin:SetIsVisible(false)
        else
            self.forceJoin:SetIsVisible(true)
        end
    end
    
end

function GUIMainMenu:ProcessJoinServer(pastWarning)

    if MainMenu_GetSelectedServer() then
        if MainMenu_GetSelectedIsHighPlayerCount() and not pastWarning and not Client.GetOptionBoolean("never_show_pca", false) then
            self.playerCountAlertWindow:SetIsVisible(true)
        elseif MainMenu_GetSelectedIsNetworkModded() and (not pastWarning or pastWarning == 1) and not Client.GetOptionBoolean("never_show_snma", false) then
            self.serverNetworkModedAlertWindow:SetIsVisible(true)
        elseif MainMenu_GetSelectedRequiresPassword() then
            self.passwordPromptWindow:SetIsVisible(true)
        else
            JoinServer(self)
        end     
    end
    
end

function GUIMainMenu:CreateAlertWindow()

    self.alertWindow = self:CreateWindow()    
    self.alertWindow:SetWindowName(Locale.ResolveString("ALERT"))
    self.alertWindow:SetInitialVisible(false)
    self.alertWindow:SetIsVisible(false)
    self.alertWindow:DisableResizeTile()
    self.alertWindow:DisableSlideBar()
    self.alertWindow:DisableContentBox()
    self.alertWindow:SetCSSClass("alert_window")
    self.alertWindow:DisableCloseButton()
    self.alertWindow:AddEventCallbacks( { OnBlur = function(self) self:SetIsVisible(false) end } )
    self.alertWindow:SetLayer(kGUILayerMainMenuDialogs)
    
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

function GUIMainMenu:CreatePlayerCountAlertWindow()

    self.playerCountAlertWindow = self:CreateWindow()    
    self.playerCountAlertWindow:SetWindowName(Locale.ResolveString("ALERT"))
    self.playerCountAlertWindow:SetInitialVisible(false)
    self.playerCountAlertWindow:SetIsVisible(false)
    self.playerCountAlertWindow:DisableResizeTile()
    self.playerCountAlertWindow:DisableSlideBar()
    self.playerCountAlertWindow:DisableContentBox()
    self.playerCountAlertWindow:SetCSSClass("warning_alert_window")
    self.playerCountAlertWindow:DisableCloseButton()
    self.playerCountAlertWindow:SetLayer(kGUILayerMainMenuDialogs)
    
    self.playerCountAlertWindow:AddEventCallbacks( { OnBlur = function(self) self:SetIsVisible(false) end } )
    
    self.playerCountAlertText = CreateMenuElement(self.playerCountAlertWindow, "Font")
    self.playerCountAlertText:SetCSSClass("warning_alerttext")
    self.playerCountAlertText:SetText(WordWrap(self.playerCountAlertText.text, Locale.ResolveString("PLAYER_COUNT_WARNING"), 0, 460) )
    
    local okButton = CreateMenuElement(self.playerCountAlertWindow, "MenuButton")
    okButton:SetCSSClass("warning_alert_join")
    okButton:SetText(string.UTF8Upper(Locale.ResolveString("OK")))
    
    local cancel = CreateMenuElement(self.playerCountAlertWindow, "MenuButton")
    cancel:SetCSSClass("warning_alert_cancle")
    cancel:SetText(string.UTF8Upper(Locale.ResolveString("CANCEL")))
    
    okButton:AddEventCallbacks({ 
        OnClick = function (self)
            self.scriptHandle.playerCountAlertWindow:SetIsVisible(false)
            self.scriptHandle:ProcessJoinServer( 1 )
        end 
    })
    
    cancel:AddEventCallbacks({ 
        OnClick = function (self)    
            self.scriptHandle.playerCountAlertWindow:SetIsVisible(false)
        end 
    })
    
    self.neverShow = CreateMenuElement(self.playerCountAlertWindow, "Checkbox")
    self.neverShow:SetCSSClass("never_show_again")
    self.neverShow:SetChecked(Client.GetOptionBoolean("never_show_pca", false))
    self.neverShowText = CreateMenuElement(self.playerCountAlertWindow, "Font")
    self.neverShowText:SetCSSClass("never_show_again_text")
    self.neverShowText:SetText(Locale.ResolveString("NEVER_SHOW_AGAIN"))
    self.neverShow:AddSetValueCallback(function(self)

        Client.SetOptionBoolean("never_show_pca", true)
        
    end)
    
end

function GUIMainMenu:CreateServerNetworkModedAlertWindow()

    self.serverNetworkModedAlertWindow = self:CreateWindow()    
    self.serverNetworkModedAlertWindow:SetWindowName(Locale.ResolveString("ALERT"))
    self.serverNetworkModedAlertWindow:SetInitialVisible(false)
    self.serverNetworkModedAlertWindow:SetIsVisible(false)
    self.serverNetworkModedAlertWindow:DisableResizeTile()
    self.serverNetworkModedAlertWindow:DisableSlideBar()
    self.serverNetworkModedAlertWindow:DisableContentBox()
    self.serverNetworkModedAlertWindow:SetCSSClass("warning_alert_window")
    self.serverNetworkModedAlertWindow:DisableCloseButton()
    self.serverNetworkModedAlertWindow:SetLayer(kGUILayerMainMenuDialogs)
    
    self.serverNetworkModedAlertWindow:AddEventCallbacks( { OnBlur = function(self) self:SetIsVisible(false) end } )
    
    self.playerCountAlertText = CreateMenuElement(self.serverNetworkModedAlertWindow, "Font")
    self.playerCountAlertText:SetCSSClass("warning_alerttext")
    self.playerCountAlertText:SetText(WordWrap(self.playerCountAlertText.text, Locale.ResolveString("SERVER_NETWOK_MODED_WARNING"), 0, 460))
    
    local okButton = CreateMenuElement(self.serverNetworkModedAlertWindow, "MenuButton")
    okButton:SetCSSClass("warning_alert_join")
    okButton:SetText(string.UTF8Upper(Locale.ResolveString("JOIN")))
    
    local cancel = CreateMenuElement(self.serverNetworkModedAlertWindow, "MenuButton")
    cancel:SetCSSClass("warning_alert_cancle")
    cancel:SetText(string.UTF8Upper(Locale.ResolveString("CANCEL")))
    
    okButton:AddEventCallbacks({ 
        OnClick = function (self)
            self.scriptHandle.serverNetworkModedAlertWindow:SetIsVisible(false)
            self.scriptHandle:ProcessJoinServer( 2 )
        end 
    })
    
    cancel:AddEventCallbacks({ 
        OnClick = function (self)    
            self.scriptHandle.serverNetworkModedAlertWindow:SetIsVisible(false)
        end 
    })
    
    self.neverShow = CreateMenuElement(self.serverNetworkModedAlertWindow, "Checkbox")
    self.neverShow:SetCSSClass("never_show_again")
    self.neverShow:SetChecked(Client.GetOptionBoolean("never_show_snma", false))
    self.neverShowText = CreateMenuElement(self.serverNetworkModedAlertWindow, "Font")
    self.neverShowText:SetCSSClass("never_show_again_text")
    self.neverShowText:SetText(Locale.ResolveString("NEVER_SHOW_AGAIN"))
    self.neverShow:AddSetValueCallback(function(self)
        
        Client.SetOptionBoolean("never_show_snma", true)
        
    end)
    
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
    self.autoJoinWindow:SetLayer(kGUILayerMainMenuDialogs)
    
    self.forceJoin = CreateMenuElement(self.autoJoinWindow, "MenuButton")
    self.forceJoin:SetCSSClass("forcejoin")
    self.forceJoin:SetText(Locale.ResolveString("AUTOJOIN"))
    
    local cancel = CreateMenuElement(self.autoJoinWindow, "MenuButton")
    cancel:SetCSSClass("autojoin_cancel")
    cancel:SetText(Locale.ResolveString("AUTOJOIN_CANCEL"))
    
    local text = CreateMenuElement(self.autoJoinWindow, "Font")
    text:SetCSSClass("auto_join_text")
    text:SetText(Locale.ResolveString("AUTOJOIN_JOIN"))
    
    local autoJoinTooltip = CreateMenuElement(self.autoJoinWindow, "Font")
    autoJoinTooltip:SetCSSClass("auto_join_text_tooltip")
    autoJoinTooltip:SetText(Locale.ResolveString("AUTOJOIN_JOIN_TOOLTIP"))
    
    self.autoJoinText = CreateMenuElement(self.autoJoinWindow, "Font")
    self.autoJoinText:SetCSSClass("auto_join_text_servername")
    self.autoJoinText:SetText("")
    
    self.blinkingArrowTwo = CreateMenuElement(self.autoJoinWindow, "Image")
    self.blinkingArrowTwo:SetCSSClass("blinking_arrow_two")

    self.forceJoin:AddEventCallbacks( {OnClick = 
    function(self) 
        self.scriptHandle:ProcessJoinServer() 
        MainMenu_ForceJoin(true)
    end } )
    
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
    passwordPromptWindow:SetLayer(kGUILayerMainMenuDialogs)
        
    self.passwordForm = CreateMenuElement(passwordPromptWindow, "Form", false)
    self.passwordForm:SetCSSClass("passwordprompt")
    
    local textinput = self.passwordForm:CreateFormElement(Form.kElementType.TextInput, "PASSWORD", "")
    textinput:SetCSSClass("serverpassword")    
    textinput:AddEventCallbacks({
        OnEscape = function(self)
            passwordPromptWindow:SetIsVisible(false) 
        end
    })
    
    local descriptionText = CreateMenuElement(passwordPromptWindow.titleBar, "Font", false)
    descriptionText:SetCSSClass("passwordprompt_title")
    descriptionText:SetText(Locale.ResolveString("PASSWORD"))
    
    local joinServer = CreateMenuElement(passwordPromptWindow, "MenuButton")
    joinServer:SetCSSClass("bottomcenter")
    joinServer:SetText(Locale.ResolveString("JOIN"))
    
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

local kTickrateDescription = "PERFORMANCE: %s%%"

local function CreateFilterForm(self)

    self.filterForm = CreateMenuElement(self.playWindow, "Form", false)
    self.filterForm:SetCSSClass("filter_form")
    
    self.filterServerName = self.filterForm:CreateFormElement(Form.kElementType.TextInput, Locale.ResolveString("SERVERBROWSER_SERVERNAME"))
    self.filterServerName:SetCSSClass("filter_servername")
    self.filterServerName:AddSetValueCallback(function(self)
    
        local value = StringTrim(self:GetValue())
        self.scriptHandle.serverList:SetFilter(12, FilterServerName(value))
        
        Client.SetOptionString("filter_servername", value)
        
    end)
    
    local description = CreateMenuElement(self.filterServerName, "Font")
    description:SetText(Locale.ResolveString("SERVERBROWSER_SERVERNAME"))
    description:SetCSSClass("filter_description")
    
    self.filterMapName = self.filterForm:CreateFormElement(Form.kElementType.TextInput, Locale.ResolveString("SERVERBROWSER_MAPNAME"))
    self.filterMapName:SetCSSClass("filter_mapname")
    self.filterMapName:AddSetValueCallback(function(self)
    
        local value = StringTrim(self:GetValue())
        self.scriptHandle.serverList:SetFilter(2, FilterMapName(value))
        Client.SetOptionString("filter_mapname", self.scriptHandle.filterMapName:GetValue())
        
    end)
    
    description = CreateMenuElement(self.filterMapName, "Font")
    description:SetText(Locale.ResolveString("SERVERBROWSER_MAPNAME"))
    description:SetCSSClass("filter_description")
    
    self.filterTickrate = self.filterForm:CreateFormElement(Form.kElementType.SlideBar, Locale.ResolveString("SERVERBROWSER_TICKRATE"))
    self.filterTickrate:SetCSSClass("filter_tickrate")
    self.filterTickrate:AddSetValueCallback( function(self)
    
        local value = self:GetValue()
        self.scriptHandle.serverList:SetFilter(3, FilterMinRate(value))
        Client.SetOptionString("filter_tickrate", ToString(value))
        
        self.scriptHandle.tickrateDescription:SetText(string.format("%s %s%%", Locale.ResolveString("SERVERBROWSER_MAXPERF"), ToString(math.round(value * 100)))) 
        
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
            textValue = Locale.ResolveString("FILTER_UNLIMTED")
        else        
            textValue = ToString(math.round(value * kFilterMaxPing))
        end

        self.scriptHandle.pingDescription:SetText(string.format("%s %s", Locale.ResolveString("SERVERBROWSER_MAXPING"), textValue))    
        
    end )

    self.pingDescription = CreateMenuElement(self.filterMaxPing, "Font")
    self.pingDescription:SetCSSClass("filter_description")
    
    self.filterHasPlayers = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, Locale.ResolveString("SERVERBROWSER_FILTER_EMPTY"))
    self.filterHasPlayers:SetCSSClass("filter_hasplayers")
    self.filterHasPlayers:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(5, FilterEmpty(self:GetValue()))
        Client.SetOptionString("filter_hasplayers", ToString(self.scriptHandle.filterHasPlayers:GetValue()))
        
    end)

    description = CreateMenuElement(self.filterHasPlayers, "Font")
    description:SetText(Locale.ResolveString("SERVERBROWSER_FILTER_EMPTY"))
    description:SetCSSClass("filter_description")

    self.filterFull = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, Locale.ResolveString("SERVERBROWSER_FILTER_FULL"))
    self.filterFull:SetCSSClass("filter_full")
    self.filterFull:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(6, FilterFull(self:GetValue()))
        Client.SetOptionString("filter_full", ToString(self.scriptHandle.filterFull:GetValue()))
        
    end)
    
    description = CreateMenuElement(self.filterFull, "Font")
    description:SetText(Locale.ResolveString("SERVERBROWSER_FILTER_FULL"))
    description:SetCSSClass("filter_description")
    
    self.filterPassworded = self.filterForm:CreateFormElement(Form.kElementType.Checkbox, Locale.ResolveString("SERVERBROWSER_PASSWORDED"))
    self.filterPassworded:SetCSSClass("filter_passworded")
    self.filterPassworded:AddSetValueCallback(function(self)
    
        self.scriptHandle.serverList:SetFilter(9, FilterPassworded(self:GetValue()))
        Client.SetOptionString("filter_passworded", ToString(self.scriptHandle.filterPassworded:GetValue()))
        
    end)
    
    description = CreateMenuElement(self.filterPassworded, "Font")
    description:SetText(Locale.ResolveString("SERVERBROWSER_PASSWORDED"))
    description:SetCSSClass("filter_description")

    self.filterMapName:SetValue(Client.GetOptionString("filter_mapname", ""))
    self.filterTickrate:SetValue(tonumber(Client.GetOptionString("filter_tickrate", "0")) or 0)
    self.filterHasPlayers:SetValue(Client.GetOptionString("filter_hasplayers", "false"))
    self.filterFull:SetValue(Client.GetOptionString("filter_full", "false"))
    self.filterMaxPing:SetValue(tonumber(Client.GetOptionString("filter_maxping", "1")) or 1)
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

local function GetPerformanceTextFromIndex(serverIndex)
    if gUsePerformanceBrowser then
        local currentScore = Client.GetServerCurrentPerformanceScore(serverIndex)
        local performanceScore = Client.GetServerPerformanceScore(serverIndex);
        local performanceQuality = Client.GetServerPerformanceQuality(serverIndex);
        local str = ServerPerformanceData.GetText(currentScore, performanceScore, performanceQuality, Client.GetServerTickRate(serverIndex))
        return string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PERF"), str)
    end
    local performance = math.round(Clamp(GetServerTickRate(serverIndex) / 30, 0, 1) * 100)
    return string.format("%s %s%%", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PERF"), ToString(performance))
end
  
local function GetPerformanceText(serverData)
    if gUsePerformanceBrowser then
        local str = ServerPerformanceData.GetText(serverData.currentScore, serverData.performanceScore, serverData.performanceQuality, serverData.tickrate)
        return string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PERF"), str)
    end
    local performance = math.round(Clamp(serverData.tickrate / 30, 0, 1) * 100)
    return string.format("%s %s%%", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PERF"), ToString(performance))
end

function GUIMainMenu:CreateServerDetailsWindow()

    self.serverDetailsWindow = self:CreateWindow()
    
    self.serverDetailsWindow:SetWindowName(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS"))
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
        self.serverAddress:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_ADDRESS"))
        self.playerCount:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PLAYERS"))
        self.ping:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PING"))
        self.gameMode:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_GAME"))
        self.map:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_MAP"))
        self.modsDesc:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_MODS"))
        self.modList:SetText("...")
        self.performance:SetText(Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PERF"))
        
        if serverData then
    
            self.serverName:SetText(serverData.name)
            self.serverAddress:SetText(string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_ADDRESS"), ToString(serverData.address)))
            local numReservedSlots = GetNumServerReservedSlots(serverData.serverId)
            self.playerCount:SetText(string.format("%s %d / %d", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PLAYERS"), serverData.numPlayers, (serverData.maxPlayers - numReservedSlots)))
            self.ping:SetText(string.format("%s %d", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PING"), serverData.ping))
            self.gameMode:SetText(string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_GAME"), serverData.mode))
            self.map:SetText(string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_MAP"), serverData.map))
            
            self.favoriteIcon:SetIsVisible(serverData.favorite)
            self.passwordedIcon:SetIsVisible(serverData.requiresPassword)
            self.performance:SetText( GetPerformanceText( serverData ) )
        
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
             self.serverAddress:SetText(string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_ADDRESS"), ToString(Client.GetServerAddress(self.serverIndex))))
             
             local numReservedSlots = GetNumServerReservedSlots(self.serverIndex)
             self.playerCount:SetText(string.format("%s %d / %d", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PLAYERS"), Client.GetServerNumPlayers(self.serverIndex), (Client.GetServerMaxPlayers(self.serverIndex) - numReservedSlots)))
             self.ping:SetText(string.format("%s %d", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_PING"), Client.GetServerPing(self.serverIndex)))
             self.gameMode:SetText(string.format("%s %s", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_GAME"), FormatGameMode(Client.GetServerGameMode(self.serverIndex))))
             self.map:SetText(string.format("%s %s",Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_MAP"), GetTrimmedMapName(Client.GetServerMapName(self.serverIndex))))
             
             self.performance:SetText( GetPerformanceTextFromIndex(self.serverIndex) )
             
             local modString = Client.GetServerKeyValue(self.serverIndex, "mods") -- "7c59c34 7b986f5 5f9ccf1 5fd7a38 5fdc381 6ec6bcd 676c71a 7619dc7"
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
             
             self.modsDesc:SetText(string.format("%s %d", Locale.ResolveString("SERVERBROWSER_SERVER_DETAILS_MODS"), modCount))
             if modTitles then
                self.modList:SetText(modTitles)
             end
             
             self.passwordedIcon:SetIsVisible(Client.GetServerRequiresPassword(self.serverIndex))
             
             local playersInfo = { }
             Client.GetServerPlayerDetails(self.serverIndex, playersInfo)
             --TestGetServerPlayerDetails(self.serverIndex, playersInfo)
             
             -- update entry count:
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
             
             -- update data and positions
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
    self.playWindow.detailsButton:SetText(Locale.ResolveString("DETAILS"))

    self.playWindow.detailsButton:AddEventCallbacks({
        OnClick = function(self)
            self.scriptHandle.serverDetailsWindow:SetServerData(MainMenu_GetSelectedServerData(), MainMenu_GetSelectedServer() or 0)
            self.scriptHandle.serverDetailsWindow:SetIsVisible(MainMenu_GetSelectedServerData() ~= nil)
        end
    })

    local update = CreateMenuElement(self.playWindow, "MenuButton")
    update:SetCSSClass("update")
    update:SetText(Locale.ResolveString("UPDATE"))
    self.playWindow.updateButton = update
    update:AddEventCallbacks({
        OnClick = function()
            UpdateServerList(self)
        end
    })
    
    self.joinServerButton = CreateMenuElement(self.playWindow, "MenuButton")
    self.joinServerButton:SetCSSClass("apply")
    self.joinServerButton:SetText(Locale.ResolveString("JOIN"))
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
        "playerskill",
        "servername",
        "game",
        "map",
        "players",
        "rate",
        "ping"
    }
    
    local rowNames = { { Locale.ResolveString("SERVERBROWSER_FAVORITE"), Locale.ResolveString("SERVERBROWSER_PRIVATE"), Locale.ResolveString("SERVERBROWSER_SKILL"), Locale.ResolveString("SERVERBROWSER_NAME"), Locale.ResolveString("SERVERBROWSER_GAME"), Locale.ResolveString("SERVERBROWSER_MAP"), Locale.ResolveString("SERVERBROWSER_PLAYERS"), Locale.ResolveString("SERVERBROWSER_PERF"), Locale.ResolveString("SERVERBROWSER_PING") } }
    
    local serverList = self.serverList
    
    local entryCallbacks = {
        { OnClick = function() UpdateSortOrder(1) serverList:SetComparator(SortByFavorite) end },
        { OnClick = function() UpdateSortOrder(2) serverList:SetComparator(SortByPrivate) end },
        { OnClick = function() UpdateSortOrder(3) serverList:SetComparator(SortByPlayerSkill) end },
        { OnClick = function() UpdateSortOrder(4) serverList:SetComparator(SortByName) end },
        { OnClick = function() UpdateSortOrder(5) serverList:SetComparator(SortByMode) end },
        { OnClick = function() UpdateSortOrder(6) serverList:SetComparator(SortByMap) end },
        { OnClick = function() UpdateSortOrder(7) serverList:SetComparator(SortByPlayers) end },
        { OnClick = function() UpdateSortOrder(8) serverList:SetComparator(SortByTickrate) end },
        { OnClick = function() UpdateSortOrder(9) serverList:SetComparator(SortByPing) end }
    }
    
    self.serverRowNames:SetCSSClass("server_list_row_names")
    self.serverRowNames:AddCSSClass("server_list_names")
    self.serverRowNames:SetColumnClassNames(columnClassNames)
    self.serverRowNames:SetEntryCallbacks(entryCallbacks)
    self.serverRowNames:SetRowPattern( { RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, RenderServerNameEntry, } )
    self.serverRowNames:SetTableData(rowNames)
    
    self.playWindow:AddEventCallbacks({
        OnShow = function()
        
            -- Default to no sorting.
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

local function CreateServer(self)

    local formData = self.createServerForm:GetFormData()
    SaveServerSettings(formData)
    
    local modIndex      = self.createServerForm.modIds[formData.Map_index]
    local password      = formData.Password
    local port          = tonumber(formData.Port)
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
    
    -- First add all of the maps that ship with the game into the list.
    -- These maps don't have corresponding mod ids since they are loaded
    -- directly from the main game.
    local shippedMaps = MainMenu_GetMapNameList()
    for i = 1, #shippedMaps do
        mapNames[i] = shippedMaps[i]
        modIds[i]   = 0
    end
    
    -- TODO: Add levels from mods we have installed
    
    return mapNames, modIds

end

GUIMainMenu.CreateOptionsForm = function(mainMenu, content, options, optionElements)

    local form = CreateMenuElement(content, "Form", false)
    
    local rowHeight = 50
    
    for i = 1, #options do
    
        local option = options[i]
        local input
        local input_display
        local defaultInputClass = "option_input"
        
        local y = rowHeight * (i - 1)
        
        if option.type == "select" then
            input = form:CreateFormElement(Form.kElementType.DropDown, option.name, option.value)
            if option.values then
                input:SetOptions(option.values)
            end                
        elseif option.type == "slider" then
            input = form:CreateFormElement(Form.kElementType.SlideBar, option.name, option.value)
            input_display = form:CreateFormElement(Form.kElementType.TextInput, option.name, option.value)
            input_display:SetNumbersOnly(true)    
            input_display:SetXAlignment(GUIItem.Align_Min)
            input_display:SetMarginLeft(5)
            if option.formName and option.formName == "sound" then
                input_display:SetCSSClass("display_sound_input")
            else
                input_display:SetCSSClass("display_input")
            end
            input_display:SetTopOffset(y)
            input_display:SetValue(ToString( input:GetValue() ))
            input_display:AddEventCallbacks({ 
                
            OnEnter = function(self)
                if input_display:GetValue() ~= "" and input_display:GetValue() ~= "." then
                    if option.name == "Sensitivity" then
                        input:SetValue((input_display:GetValue() - kMinSensitivity) / (kMaxSensitivity - kMinSensitivity))
                    elseif option.name == "AccelerationAmount" then
                        input:SetValue(input_display:GetValue())
                    elseif option.name == "FOVAdjustment" then
                        input:SetValue(input_display:GetValue() / 20)
                    else
                        input:SetValue(input_display:GetValue())
                    end
                end
                if input_display:GetValue() == "" or input_display:GetValue() == "." then
                    if option.name == "Sensitivity" then
                        input_display:SetValue(ToString(string.sub(OptionsDialogUI_GetMouseSensitivity(), 0, 4)))
                    elseif option.name == "AccelerationAmount" then
                        input_display:SetValue(ToString(string.sub(input:GetValue(), 0, 4)))
                    elseif option.name == "FOVAdjustment" then
                        input_display:SetValue(ToString(string.format("%.0f", input:GetValue() * 20)))
                    else
                        input_display:SetValue(ToString(string.sub(input:GetValue(),0, 4)))
                    end
                end
            
            end,
            OnBlur = function(self)
                if input_display:GetValue() ~= "" and input_display:GetValue() ~= "." then
                    if option.name == "Sensitivity" then
                        input:SetValue((input_display:GetValue() - kMinSensitivity) / (kMaxSensitivity - kMinSensitivity))
                    elseif option.name == "AccelerationAmount" then
                        input:SetValue(input_display:GetValue())
                    elseif option.name == "FOVAdjustment" then
                        input:SetValue(input_display:GetValue() / 20)
                    else
                        input:SetValue(input_display:GetValue())
                    end
                end
                
                if input_display:GetValue() == "" or input_display:GetValue() == "." then
                    if option.name == "Sensitivity" then
                        input_display:SetValue(ToString(string.sub(OptionsDialogUI_GetMouseSensitivity(), 0, 4)))
                    elseif option.name == "AccelerationAmount" then
                        input_display:SetValue(ToString(string.sub(input:GetValue(), 0, 4)))
                    elseif option.name == "FOVAdjustment" then
                        input_display:SetValue(ToString(string.format("%.0f", input:GetValue() * 20)))
                    else
                        input_display:SetValue(ToString(string.sub(input:GetValue(),0, 4)))
                    end
                end
            end,
            })
            -- HACK: Really should use input:AddSetValueCallback, but the slider bar bypasses that.
            if option.sliderCallback then
                input:Register(
                    {OnSlide =
                        function(value, interest)
                            option.sliderCallback(mainMenu)
                            if option.name == "Sensitivity" then
                                input_display:SetValue(ToString(string.sub(OptionsDialogUI_GetMouseSensitivity(), 0, 4)))
                            elseif option.name == "AccelerationAmount" then
                                input_display:SetValue(ToString(string.sub(input:GetValue(), 0, 4)))
                            elseif option.name == "FOVAdjustment" then
                                input_display:SetValue(ToString(string.format("%.0f", input:GetValue() * 20)))
                            else
                                input_display:SetValue(ToString(string.sub(input:GetValue(),0, 4)))
                            end
                        end
                    }, SLIDE_HORIZONTAL)
            end
        elseif option.type == "progress" then
            input = form:CreateFormElement(Form.kElementType.ProgressBar, option.name, option.value)       
        elseif option.type == "checkbox" then
            input = form:CreateFormElement(Form.kElementType.Checkbox, option.name, option.value)
            defaultInputClass = "option_checkbox"
        elseif option.type == "numberBox" then
            input = form:CreateFormElement(Form.kElementType.TextInput, option.name, option.value)
            input:SetNumbersOnly(true)
            if option.length then
                input:SetMaxLength(option.length)
            end
        else
            input = form:CreateFormElement(Form.kElementType.TextInput, option.name, option.value)
        end
        
        if option.callback then
            input:AddSetValueCallback(option.callback)
        end
        local inputClass = defaultInputClass
        if option.inputClass then
            inputClass = option.inputClass
        end
        
        input:SetCSSClass(inputClass)
        input:SetTopOffset(y)

        for index, child in ipairs(input:GetChildren()) do
            -- Hitsounds preview, remove menu sound click callback and add the hitsound
            if option.name == "HitSoundVolume" then
                child.clickCallbacks = {}
                table.insert(child.clickCallbacks, function(self) HitSounds_PlayHitsound(1) end)
            end
            
            child:AddEventCallbacks({ 
                OnMouseOver = function(self)
                    if gMainMenu ~= nil then
                        local text = option.tooltip
                        if text ~= nil then
                            gMainMenu.optionTooltip:SetText(text)
                            gMainMenu.optionTooltip:Show()
                        else
                            gMainMenu.optionTooltip:Hide()
                        end
                    end    
                end,
                
                OnMouseOut = function(self)
                    if gMainMenu ~= nil then
                        gMainMenu.optionTooltip:Hide()
                    end
                end,
                })
        end

        local label = CreateMenuElement(form, "Font", false)
        label:SetCSSClass("option_label")
        label:SetText(option.label .. ":")
        label:SetTopOffset(y)
        label:SetIgnoreEvents(false)
        
        optionElements[option.name] = input

    end
    
    form:SetCSSClass("options")

    return form

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
                label  = Locale.ResolveString("SERVERBROWSER_SERVERNAME"),
                value  = Client.GetOptionString("serverName", "NS2 Listen Server")
            },
            {   
                name   = "Password",            
                label  = Locale.ResolveString("SERVERBROWSER_CREATE_PASSWORD"),
                value  = Client.GetOptionString("serverPassword", "")
            },
            {
                name    = "Port",
                label   = Locale.ResolveString("SERVERBROWSER_CREATE_PORT"),
                type      = "numberBox",
                length     = 5,
                value   = Client.GetOptionString("listenPort", "27015")
            },
            {
                name    = "Map",
                label   = Locale.ResolveString("SERVERBROWSER_MAP"),
                type    = "select",
                value  = Client.GetOptionString("mapName", "Summit")
            },
            {
                name    = "GameMode",
                label   = Locale.ResolveString("SERVERBROWSER_CREATE_GAME_MODE"),
                type    = "select",
                values  = gameModes,
                value   = gameModes[CreateServerUI_GetGameModesIndex()]
            },
            {
                name    = "PlayerLimit",
                label   = Locale.ResolveString("SERVERBROWSER_CREATE_PLAYER_LIMIT"),
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
    self.hostGameButton:SetText(Locale.ResolveString("MENU_CREATE"))
    
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
    
        if bindingsTable[b].current == "None" then
            keyInputs[b]:SetValue("")
        else
            keyInputs[b]:SetValue(bindingsTable[b].current)
        end
        
    end
    
end

local function InitKeyBindingsCom(keyInputsCom)

    local bindingsTableCom = BindingsUI_GetComBindingsTable()
    for c = 1, #bindingsTableCom do
        if bindingsTableCom[c].current == "None" then
            keyInputsCom[c]:SetValue("")
        else
            keyInputsCom[c]:SetValue(bindingsTableCom[c].current)
        end
    end  
    
end

local function CheckForConflictedKeys(keyInputs)

    -- Reset back to non-conflicted state.
    for k = 1, #keyInputs do
        keyInputs[k]:SetCSSClass("option_input")
    end
    
    -- Check for conflicts.
    for k1 = 1, #keyInputs do
    
        for k2 = 1, #keyInputs do
        
            if k1 ~= k2 then
            
                local boundKey1 = Client.GetOptionString("input/" .. keyInputs[k1].inputName, "")
                local boundKey2 = Client.GetOptionString("input/" .. keyInputs[k2].inputName, "")
                if (boundKey1 ~= "None" and boundKey2 ~= "None") and boundKey1 == boundKey2 then
                
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
        
           if not down and key ~= InputKey.Escape then
            
                -- We want to ignore the click that gave this input focus.
                if keyInput.ignoreFirstKey == true then
                
                    local keyString = Client.ConvertKeyCodeToString(key)
                    keyInput:SetValue(keyString)
                    
                    Client.SetOptionString("input/" .. keyInput.inputName, keyString)
                    
                    CheckForConflictedKeys(mainMenu.keyInputs)
                    
                    GetWindowManager():ClearActiveElement(self)
                    
                    keyInput.ignoreFirstKey = false
                    
                else
                    keyInput.ignoreFirstKey = true
                end
                
            end
            
        end
        
        function keyInput:OnMouseWheel(up)
            if up then
                self:OnSendKey(InputKey.MouseWheelUp, false)
            else
                self:OnSendKey(InputKey.MouseWheelDown, false)
            end
        end
        
        local clearKeyInput = CreateMenuElement(keyBindingsForm, "MenuButton", false)
        clearKeyInput:SetCSSClass("clear_keybind")
        clearKeyInput:SetText("x")
        
        function clearKeyInput:OnClick()
            Client.SetOptionString("input/" .. keyInput.inputName, "None")
            keyInput:SetValue("")
            CheckForConflictedKeys(mainMenu.keyInputs)
        end

        local keyInputText = CreateMenuElement(keyBindingsForm, "Font", false)
        keyInputText:SetText(string.UTF8Upper(binding.detail) ..  ":")
        keyInputText:SetCSSClass("option_label")
        
        local y = rowHeight * (b  - 1)
        
        keyInput:SetTopOffset(y)
        keyInputText:SetTopOffset(y)
        clearKeyInput:SetTopOffset(y)
        
        keyInput.inputName = binding.name
        table.insert(mainMenu.keyInputs, keyInput)
        
    end
    
    InitKeyBindings(mainMenu.keyInputs)
    
    CheckForConflictedKeys(mainMenu.keyInputs)
    
    keyBindingsForm:SetCSSClass("keybindings")
    
    return keyBindingsForm
    
end

local function CreateKeyBindingsFormCom(mainMenu, content)

    local keyBindingsFormCom = CreateMenuElement(content, "Form", false)
    
    local bindingsTableCom = BindingsUI_GetComBindingsTable()
    mainMenu.keyInputsCom = { }
    local rowHeight = 50
    
    for b = 1, #bindingsTableCom do
    
        local bindingCom = bindingsTableCom[b]
        
        local keyInputCom = keyBindingsFormCom:CreateFormElement(Form.kElementType.FormButton, "INPUT" .. b, bindingCom.current)
        keyInputCom:SetCSSClass("option_input")
        keyInputCom:AddEventCallbacks( { OnBlur = function(self) keyInputCom.ignoreFirstKey = nil end } )
        
        function keyInputCom:OnSendKey(key, down)
        
            if not down and key ~= InputKey.Escape then
            
                -- We want to ignore the click that gave this input focus.
                if keyInputCom.ignoreFirstKey == true then
                
                    local keyStringCom = Client.ConvertKeyCodeToString(key)
                    keyInputCom:SetValue(keyStringCom)
                    
                    Client.SetOptionString("input/" .. keyInputCom.inputName, keyStringCom)
                    
                    CheckForConflictedKeys(mainMenu.keyInputsCom)
                    
                end
                keyInputCom.ignoreFirstKey = true
                
            end
            
        end
        
        function keyInputCom:OnMouseWheel(up)
            if up then
                self:OnSendKey(InputKey.MouseWheelUp, false)
            else
                self:OnSendKey(InputKey.MouseWheelDown, false)
            end
        end
        
        local keyInputTextCom = CreateMenuElement(keyBindingsFormCom, "Font", false)
        keyInputTextCom:SetText(string.UTF8Upper(bindingCom.detail) ..  ":")
        keyInputTextCom:SetCSSClass("option_label")
        
        local clearKeyInput = CreateMenuElement(keyBindingsFormCom, "MenuButton", false)
        clearKeyInput:SetCSSClass("clear_keybind")
        clearKeyInput:SetText("x")
        
        function clearKeyInput:OnClick()
            Client.SetOptionString("input/" .. keyInputCom.inputName, "None")
            keyInputCom:SetValue("")
            CheckForConflictedKeys(mainMenu.keyInputsCom)
        end
        
        local y = rowHeight * (b  - 1)
        
        keyInputCom:SetTopOffset(y)
        keyInputTextCom:SetTopOffset(y)
        clearKeyInput:SetTopOffset(y)
        
        keyInputCom.inputName = bindingCom.name
        table.insert(mainMenu.keyInputsCom, keyInputCom)
        
    end

    InitKeyBindingsCom(mainMenu.keyInputsCom)
    CheckForConflictedKeys(mainMenu.keyInputsCom)
    
    keyBindingsFormCom:SetCSSClass("keybindings")
    
    return keyBindingsFormCom
    
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
    local physicsMultithreading = Client.GetOptionBoolean( "physicsMultithreading", false)
    local advancedmovement      = Client.GetOptionBoolean( "AdvancedMovement", false )

    local screenResIdx          = OptionsDialogUI_GetScreenResolutionsIndex()
    local visualDetailIdx       = OptionsDialogUI_GetVisualDetailSettingsIndex()
    local display               = OptionsDialogUI_GetDisplay()

    local windowMode            = table.find(kWindowModeIds, OptionsDialogUI_GetWindowModeId()) or 1
    local windowModes           = OptionsDialogUI_GetWindowModes()
    local windowModeOptionIndex = table.find(windowModes, windowMode) or 1
    
    local displayBuffering      = Client.GetOptionInteger("graphics/display/display-buffering", 0)
    local ambientOcclusion      = Client.GetOptionString("graphics/display/ambient-occlusion", kAmbientOcclusionModes[1])
    local reflections           = Client.GetOptionBoolean("graphics/reflections", false)
    local particleQuality       = Client.GetOptionString("graphics/display/particles", "low")
    local infestation           = Client.GetOptionString("graphics/infestation", "rich")
    local fovAdjustment         = Client.GetOptionFloat("graphics/display/fov-adjustment", 0)
    local cameraAnimation       = Client.GetOptionBoolean("CameraAnimation", false)
    local physicsGpuAcceleration = Client.GetOptionBoolean(kPhysicsGpuAccelerationKey, false)
    local decalLifeTime         = Client.GetOptionFloat("graphics/decallifetime", 0.2)
    local textureManagement     = Client.GetOptionInteger("graphics/textureManagement", 0)
    
    local minimapZoom = Client.GetOptionFloat("minimap-zoom", 0.75)
    local hitsoundVolume = Client.GetOptionFloat("hitsound-vol", 0.0)
    
    local hudmode = Client.GetOptionInteger("hudmode", kHUDMode.Full)
        
    local lightQuality = Client.GetOptionInteger("graphics/lightQuality", 2)
    
    -- support legacy values    
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
    
    local renderDevice = Client.GetOptionString("graphics/device", kRenderDevices[1])
    
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
    local recordingReleaseDelay = Client.GetOptionFloat("recordingReleaseDelay", 0.15)
    
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
	optionElements.PhysicsMultithreading:SetOptionActive( BoolToIndex(physicsMultithreading) )
    optionElements.AdvancedMovement:SetOptionActive( BoolToIndex(advancedmovement) )

    optionElements.RenderDevice:SetOptionActive( table.find(kRenderDevices, renderDevice) )
    optionElements.Display:SetOptionActive( display + 1 )
    optionElements.WindowMode:SetOptionActive( windowModeOptionIndex )
    optionElements.DisplayBuffering:SetOptionActive( displayBuffering + 1 )
    optionElements.Resolution:SetOptionActive( screenResIdx )
    optionElements.Shadows:SetOptionActive( BoolToIndex(shadows) )
    optionElements.Infestation:SetOptionActive( table.find(kInfestationModes, infestation) )
    optionElements.Bloom:SetOptionActive( BoolToIndex(bloom) )
    optionElements.Atmospherics:SetOptionActive( BoolToIndex(atmospherics) )
    optionElements.AnisotropicFiltering:SetOptionActive( BoolToIndex(anisotropicFiltering) )
    optionElements.AntiAliasing:SetOptionActive( BoolToIndex(antiAliasing) )
    optionElements.Detail:SetOptionActive(visualDetailIdx)
    optionElements.AmbientOcclusion:SetOptionActive( table.find(kAmbientOcclusionModes, ambientOcclusion) )
    optionElements.Reflections:SetOptionActive( BoolToIndex(reflections) )
    optionElements.FOVAdjustment:SetValue(fovAdjustment)
    optionElements.MinimapZoom:SetValue(minimapZoom)
    optionElements.HitSoundVolume:SetValue(hitsoundVolume)
    optionElements.DecalLifeTime:SetValue(decalLifeTime)
    optionElements.CameraAnimation:SetOptionActive( BoolToIndex(cameraAnimation) )
    optionElements.PhysicsGpuAcceleration:SetOptionActive( BoolToIndex(physicsGpuAcceleration) )
    optionElements.ParticleQuality:SetOptionActive( table.find(kParticleQualityModes, particleQuality) ) 
    optionElements.TextureManagement:SetOptionActive( textureManagement )
    
    optionElements.SoundInputDevice:SetOptionActive(soundInputDevice)
    optionElements.SoundOutputDevice:SetOptionActive(soundOutputDevice)
    optionElements.SoundVolume:SetValue(soundVol)
    optionElements.MusicVolume:SetValue(musicVol)
    optionElements.VoiceVolume:SetValue(voiceVol)
    optionElements.hudmode:SetValue(hudmode == 1 and Locale.ResolveString("HIGH") or Locale.ResolveString("LOW"))
    optionElements.LightQuality:SetOptionActive( lightQuality )
    
    optionElements.RecordingGain:SetValue(recordingGain)
    optionElements.RecordingReleaseDelay:SetValue( recordingReleaseDelay )
    
end

local function SaveSecondaryGraphicsOptions(mainMenu)
    -- These are options that are pretty quick to change, unlike screen resolution etc.
    -- Have this separate, since graphics options are auto-applied

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
    local renderDeviceIdx       = mainMenu.optionElements.RenderDevice:GetActiveOptionIndex()
    local lightQuality          = mainMenu.optionElements.LightQuality:GetActiveOptionIndex()
    local textureManagement     = mainMenu.optionElements.TextureManagement:GetActiveOptionIndex()

    Client.SetOptionBoolean("graphics/reflections", reflections)
    Client.SetOptionString("graphics/display/ambient-occlusion", kAmbientOcclusionModes[ambientOcclusionIdx] )
    Client.SetOptionString("graphics/display/particles", kParticleQualityModes[particleQualityIdx] )
    Client.SetOptionString("graphics/infestation", kInfestationModes[infestationIdx] )
    Client.SetOptionInteger( kDisplayQualityOptionsKey, visualDetailIdx - 1 )
    Client.SetOptionBoolean ( kShadowsOptionsKey, shadows )
    Client.SetOptionBoolean ( kBloomOptionsKey, bloom )
    Client.SetOptionBoolean ( kAtmosphericsOptionsKey, atmospherics )
    Client.SetOptionBoolean ( kAnisotropicFilteringOptionsKey, anisotropicFiltering )
    Client.SetOptionBoolean ( kAntiAliasingOptionsKey, antiAliasing )
    Client.SetOptionString("graphics/device", kRenderDevices[renderDeviceIdx] )
    Client.SetOptionInteger("graphics/lightQuality", lightQuality)
    Client.SetOptionInteger("graphics/textureManagement", textureManagement)
    
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

local function OnRecordingReleaseDelayChanged(mainMenu)
    local value = mainMenu.optionElements.RecordingReleaseDelay:GetValue()
    Client.SetOptionFloat("recordingReleaseDelay", value)
end

local function OnRecordingGainChanged(mainMenu)
    local recordingGain = mainMenu.optionElements.RecordingGain:GetValue()
    Client.SetRecordingGain(recordingGain)
    Client.SetOptionFloat("recordingGain", recordingGain)
end

local function OnSensitivityChanged(mainMenu)
    local value = mainMenu.optionElements.Sensitivity:GetValue()
    if value >= 0 then
        OptionsDialogUI_SetMouseSensitivity(value * (kMaxSensitivity - kMinSensitivity) + kMinSensitivity)
    end
end

local function OnAccelerationAmountChanged(mainMenu)
    local value = mainMenu.optionElements.AccelerationAmount:GetValue()
    Client.SetOptionFloat("input/mouse/acceleration-amount", value * (kMaxAcceleration - kMinAcceleration) + kMinAcceleration )
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

local function OnHitSoundVolumeChanged(mainMenu)
   
    local value = mainMenu.optionElements.HitSoundVolume:GetValue()
    Client.SetOptionFloat("hitsound-vol", value)

    if HitSounds_SyncOptions then
        HitSounds_SyncOptions()
    end
    
end
    
function OnDisplayChanged(oldDisplay, newDisplay)

    if gMainMenu ~= nil and gMainMenu.optionElements ~= nil then
        gMainMenu.optionElements.Display:SetOptionActive( newDisplay + 1 )
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
    local physicsMultithreading = mainMenu.optionElements.PhysicsMultithreading:GetActiveOptionIndex() > 1

    local display               = mainMenu.optionElements.Display:GetActiveOptionIndex() - 1
    local screenResIdx          = mainMenu.optionElements.Resolution:GetActiveOptionIndex()
    local visualDetailIdx       = mainMenu.optionElements.Detail:GetActiveOptionIndex()
    local displayBuffering      = mainMenu.optionElements.DisplayBuffering:GetActiveOptionIndex() - 1
    
    local windowModeOptionIndex = mainMenu.optionElements.WindowMode:GetActiveOptionIndex()
    local windowMode            = OptionsDialogUI_GetWindowModes()[windowModeOptionIndex]

    local shadows               = mainMenu.optionElements.Shadows:GetActiveOptionIndex() > 1
    local bloom                 = mainMenu.optionElements.Bloom:GetActiveOptionIndex() > 1
    local atmospherics          = mainMenu.optionElements.Atmospherics:GetActiveOptionIndex() > 1
    local anisotropicFiltering  = mainMenu.optionElements.AnisotropicFiltering:GetActiveOptionIndex() > 1
    local antiAliasing          = mainMenu.optionElements.AntiAliasing:GetActiveOptionIndex() > 1
    local textureManagement     = mainMenu.optionElements.TextureManagement:GetActiveOptionIndex()
   
    local soundVol              = mainMenu.optionElements.SoundVolume:GetValue() * 100
    local musicVol              = mainMenu.optionElements.MusicVolume:GetValue() * 100
    local voiceVol              = mainMenu.optionElements.VoiceVolume:GetValue() * 100

    local hudmode               = mainMenu.optionElements.hudmode:GetValue()
    local cameraAnimation       = mainMenu.optionElements.CameraAnimation:GetActiveOptionIndex() > 1
    local physicsGpuAcceleration = mainMenu.optionElements.PhysicsGpuAcceleration:GetActiveOptionIndex() > 1
    local advancedmovement      = mainMenu.optionElements.AdvancedMovement:GetActiveOptionIndex() > 1
    local particleQuality       = mainMenu.optionElements.ParticleQuality:GetActiveOptionIndex()
    
    local lightQuality          = mainMenu.optionElements.LightQuality:GetActiveOptionIndex()
    
    Client.SetOptionBoolean("input/mouse/rawinput", rawInput)
    Client.SetOptionBoolean("input/mouse/acceleration", mouseAcceleration)
    Client.SetOptionBoolean("showHints", showHints)
    Client.SetOptionBoolean("commanderHelp", showCommanderHelp)
    Client.SetOptionBoolean("drawDamage", drawDamage)
    Client.SetOptionBoolean(kRookieOptionsKey, rookieMode)
    Client.SetOptionBoolean("physicsMultithreading", physicsMultithreading)
    
    Client.SetOptionBoolean("CameraAnimation", cameraAnimation)
    Client.SetOptionBoolean(kPhysicsGpuAccelerationKey, physicsGpuAcceleration)
	Client.SetOptionBoolean( "AdvancedMovement", advancedmovement)
    Client.SetOptionInteger("hudmode", hudmode == Locale.ResolveString("HIGH") and kHUDMode.Full or kHUDMode.Minimal)
    Client.SetOptionInteger("graphics/lightQuality", lightQuality)
    Client.SetOptionFloat("input/mouse/acceleration-amount", accelerationAmount)
    Client.SetOptionInteger("graphics/textureManagement", textureManagement)
    
    if string.len(TrimName(nickName)) < 1 or not string.IsValidNickname(nickName) then
        nickName = Client.GetOptionString( kNicknameOptionsKey, Client.GetUserName() )
        mainMenu.optionElements.NickName:SetValue(nickName)
        MainMenu_SetAlertMessage("Invalid Nickname")
    end
    
    -- Some redundancy with ApplySecondaryGraphicsOptions here, no harm.
    OptionsDialogUI_SetValues(
        nickName,
        mouseSens,
        display,
        screenResIdx,
        visualDetailIdx,
        soundVol,
        musicVol,
        kWindowModeIds[windowMode],
        shadows,
        bloom,
        atmospherics,
        anisotropicFiltering,
        antiAliasing,
        invMouse,
        voiceVol)
        
    SaveSecondaryGraphicsOptions(mainMenu)
    Client.SetOptionInteger("graphics/display/display-buffering", displayBuffering)
    
    -- This will reload the first three graphics settings
    OptionsDialogUI_ExitDialog()

    SyncSecondaryGraphicsOptions()
    
    for k = 1, #mainMenu.keyInputs do
    
        local keyInput = mainMenu.keyInputs[k]
        local value = keyInput:GetValue()
        if value == "" then
            value = "None"
        end
        Client.SetOptionString("input/" .. keyInput.inputName, value)
        
    end
    Client.ReloadKeyOptions()
    
    for l = 1, #mainMenu.keyInputsCom do
    
        local keyInputCom = mainMenu.keyInputsCom[l]
        local value = keyInputCom:GetValue()
        if value == "" then
            value = "None"
        end
        Client.SetOptionString("input/" .. keyInputCom.inputName, value)
        
    end
    Client.ReloadKeyOptions()
    
    if locale ~= Client.GetOptionString("locale", "enUS") then
        Client.SetOptionString("locale", locale) 
        Client.RestartMain()
    end
    
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

local function StorePhysicsGpuAccelerationOption(formElement)
    Client.SetOptionBoolean(kPhysicsGpuAccelerationKey, formElement:GetActiveOptionIndex() > 1)
end

local function OnLightQualityChanged(formElement)

    Client.SetOptionInteger("graphics/lightQuality", formElement:GetActiveOptionIndex())
    
    if Lights_UpdateLightMode then
        Lights_UpdateLightMode()
    end
    
    Render_SyncRenderOptions()
    
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

    -- Get GUIDs of all audio devices
    local numDevices = Client.GetSoundDeviceCount(deviceType)
    local guids = {}
    for id = 1, numDevices do
        guids[id] = Client.GetSoundDeviceGuid(deviceType, id - 1)
    end

    local desiredGuid = guids[deviceId + 1]
    Client.SetSoundDevice(deviceType, deviceId)

    -- Check if GUIDs are still the same, update the list in process
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
        -- Device list order changed        
        -- Avoid re-entering this callback
        formElement.inSoundCallback = true
        
        local soundOutputDevices = OptionsDialogUI_GetSoundDeviceNames(deviceType)
        formElement:SetOptions(soundOutputDevices)
        
        -- Find the GUID we were trying to select again
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
        InitKeyBindingsCom(self.keyInputsCom)
        
    end
    self.optionWindow:AddEventCallbacks( {
        OnHide = function(self)
            InitOptionWindow()
        end
    } )
    
    local content = self.optionWindow:GetContentBox()
    
    local back = CreateMenuElement(self.optionWindow, "MenuButton")
    back:SetCSSClass("back")
    back:SetText(Locale.ResolveString("BACK"))
    back:AddEventCallbacks( { OnClick = function() self.optionWindow:SetIsVisible(false) end } )
    
    local apply = CreateMenuElement(self.optionWindow, "MenuButton")
    apply:SetCSSClass("apply")
    apply:SetText(Locale.ResolveString("MENU_APPLY"))
    apply:AddEventCallbacks( { OnClick = function() SaveOptions(self) end } )

    self.fpsDisplay = CreateMenuElement( self.optionWindow, "MenuButton" )
    self.fpsDisplay:SetCSSClass("fps") 
    
    self.warningLabel = CreateMenuElement(self.optionWindow, "MenuButton", false)
    self.warningLabel:SetCSSClass("warning_label")
    self.warningLabel:SetText(Locale.ResolveString("GAME_RESTART_REQUIRED"))
    self.warningLabel:SetIgnoreEvents(true)
    self.warningLabel:SetIsVisible(false)

    local displays = OptionsDialogUI_GetDisplays()    
    local windowModes = OptionsDialogUI_GetWindowModes()
    local windowModeNames = {}
    for i = 1, #windowModes do
        table.insert(windowModeNames, kWindowModeNames[windowModes[i]])
    end 

    local screenResolutions = OptionsDialogUI_GetScreenResolutions()
    local soundOutputDevices = OptionsDialogUI_GetSoundDeviceNames(Client.SoundDeviceType_Output)
    local soundInputDevices = OptionsDialogUI_GetSoundDeviceNames(Client.SoundDeviceType_Input)
    
    local languages = { }
    for i = 1,#kLocales do
        languages[i] = kLocales[i].label
    end
    
    local generalOptions =
        {
            { 
                name    = "NickName",
                label   = Locale.ResolveString("NICKNAME"),
            },
            {
                name    = "Language",
                label   = Locale.ResolveString("LANGUAGE"),
                type    = "select",
                values  = languages,
            },
            { 
                name    = "Sensitivity",
                label   = Locale.ResolveString("MOUSE_SENSITIVITY"),
                type    = "slider",
                sliderCallback = OnSensitivityChanged,
            },
            {
                name    = "InvertedMouse",
                label   = Locale.ResolveString("REVERSE_MOUSE"),
                type    = "select",
                values  = { Locale.ResolveString("NO"), Locale.ResolveString("YES") }
            },
            {
                name    = "MouseAcceleration",
                label   = Locale.ResolveString("MOUSE_ACCELERATION"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") }
            },
            {
                name    = "AccelerationAmount",
                label   = Locale.ResolveString("ACCELERATION_AMOUNT"),
                type    = "slider",
                sliderCallback = OnAccelerationAmountChanged,
            },
            {
                name    = "RawInput",
                label   = Locale.ResolveString("RAW_INPUT"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") }
            },
            {
                name    = "ShowHints",
                label   = Locale.ResolveString("SHOW_HINTS"),
                tooltip = Locale.ResolveString("OPTION_SHOW_HINTS"),
                type    = "select",
                values  = { Locale.ResolveString("NO"), Locale.ResolveString("YES") }
            },  
            {
                name    = "ShowCommanderHelp",
                label   = Locale.ResolveString("COMMANDER_HELP"),
                tooltip = Locale.ResolveString("OPTION_SHOW_COMMANDER_HELP"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") }
            },  
            {
                name    = "DrawDamage",
                label   = Locale.ResolveString("DRAW_DAMAGE"),
                tooltip = Locale.ResolveString("OPTION_DRAW_DAMAGE"),
                type    = "select",
                values  = { Locale.ResolveString("NO"), Locale.ResolveString("YES") }
            },  
            {
                name    = "RookieMode",
                label   = Locale.ResolveString("ROOKIE_MODE"),
                type    = "select",
                values  = { Locale.ResolveString("NO"), Locale.ResolveString("YES") }
            },          
            { 
                name    = "FOVAdjustment",
                label   = Locale.ResolveString("FOV_ADJUSTMENT"),
                type    = "slider",
                sliderCallback = OnFOVAdjustChanged,
            },
            { 
                name    = "MinimapZoom",
                label   = Locale.ResolveString("MINIMAP_ZOOM"),
                type    = "slider",
                sliderCallback = OnMinimapZoomChanged,
            },
            {
                name    = "CameraAnimation",
                label   = Locale.ResolveString("CAMERA_ANIMATION"),
                tooltip = Locale.ResolveString("OPTION_CAMERA_ANIMATION"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = StoreCameraAnimationOption
            }, 
            {
                name    = "AdvancedMovement",
                label   = "ADVANCED MOVEMENT",
				tooltip = "Enables/Disables forward movement override which attemps to make airstrafing easier for new players.",
                type    = "select",
                values  = { "OFF", "ON" },
                callback = StoreAdvancedMovementOption
            },
			{
                name    = "hudmode",
                label   = Locale.ResolveString("HUD_DETAIL"),
                tooltip = Locale.ResolveString("OPTION_HUDQUALITY"),
                type    = "select",
                values  = { Locale.ResolveString("HIGH"), Locale.ResolveString("LOW") },
                callback = autoApplyCallback
            },   
            {
                name    = "PhysicsGpuAcceleration",
                label   = Locale.ResolveString("PHYSX_GPU_ACCELERATION"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = StorePhysicsGpuAccelerationOption
            },
            {
                name    = "PhysicsMultithreading",
                label   = Locale.ResolveString("OPTION_PHYSICS_MULTITHREADING"),
                tooltip = Locale.ResolveString("OPTION_PHYSICS_MULTITHREADING_TOOLTIP"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
            },
        }

    local soundOptions =
        {
            {   
                name   = "SoundOutputDevice",
                label  = Locale.ResolveString("OUTPUT_DEVICE"),
                type   = "select",
                values = soundOutputDevices,
                callback = function(formElement) OnSoundDeviceChanged(self, formElement, Client.SoundDeviceType_Output) end,
            },
            {   
                name   = "SoundInputDevice",
                label  = Locale.ResolveString("INPUT_DEVICE"),
                type   = "select",
                values = soundInputDevices,
                callback = function(formElement) OnSoundDeviceChanged(self, formElement, Client.SoundDeviceType_Input) end,
            },            
            { 
                name    = "SoundVolume",
                label   = Locale.ResolveString("SOUND_VOLUME"),
                type    = "slider",
                sliderCallback = OnSoundVolumeChanged,
                formName = "sound",
            },
            { 
                name    = "MusicVolume",
                label   = Locale.ResolveString("MUSIC_VOLUME"),
                type    = "slider",
                sliderCallback = OnMusicVolumeChanged,
                formName = "sound",
            },
            { 
                name    = "HitSoundVolume",
                label   = Locale.ResolveString("HIT_SOUND_VOLUME"),
                tooltip = Locale.ResolveString("OPTION_HIT_SOUNDS"),
                type    = "slider",
                sliderCallback = OnHitSoundVolumeChanged,
                formName = "sound",
            },
            { 
                name    = "VoiceVolume",
                label   = Locale.ResolveString("VOICE_VOLUME"),
                type    = "slider",
                sliderCallback = OnVoiceVolumeChanged,
                formName = "sound",
            },
            {
                name    = "RecordingGain",
                label   = Locale.ResolveString("MICROPHONE_GAIN"),
                type    = "slider",
                sliderCallback = OnRecordingGainChanged,
                formName = "sound",
            },
            {
                name    = "RecordingReleaseDelay",
                label   = Locale.ResolveString("MICROPHONE_RELEASE_DELAY"),
                tooltip = Locale.ResolveString("MICROPHONE_RELEASE_DELAY_TTIP"),
                type    = "slider",
                sliderCallback = OnRecordingReleaseDelayChanged,
                formName = "sound",
            },
            {
                name    = "RecordingVolume",
                label   = Locale.ResolveString("MICROPHONE_LEVEL"),
                type    = "progress",
                formName = "sound",
            }
        }        
        
    local autoApplyCallback = function(formElement) OnGraphicsOptionsChanged(self) end
    
    local graphicsOptions = 
        {
            {   
                name   = "RenderDevice",
                label  = Locale.ResolveString("DEVICE"),
                type   = "select",
                tooltip = Locale.ResolveString("OPTION_DEVICE"),
                values = kRenderDeviceDisplayNames,
                callback = function(formElement) SaveSecondaryGraphicsOptions(self) self:UpdateRestartMessage() end,
            },  
            {
                name   = "Display",
                label  = Locale.ResolveString("DISPLAY"),
                tooltip = Locale.ResolveString("OPTION_DISPLAY"),
                type   = "select",
                values = displays,
            },      
            {   
                name   = "Resolution",
                label  = Locale.ResolveString("RESOLUTION"),
                type   = "select",
                values = screenResolutions,
            },
            {   
                name   = "WindowMode",            
                label  = Locale.ResolveString("WINDOW_MODE"),
                type   = "select",
                values = windowModeNames,
            },
            {   
                name   = "DisplayBuffering",            
                label  = Locale.ResolveString("VYSNC"),
                tooltip = Locale.ResolveString("OPTION_VYSNC"),
                type   = "select",
                values = { Locale.ResolveString("DISABLED"), Locale.ResolveString("DOUBLE_BUFFERED"), Locale.ResolveString("TRIPLE_BUFFERED") }
            },                       
            {
                name    = "Detail",
                label   = Locale.ResolveString("TEXTURE_QUALITY"),
                tooltip = Locale.ResolveString("OPTION_TEXTUREQUALITY"),
                type    = "select",
                values  = { Locale.ResolveString("LOW"), Locale.ResolveString("MEDIUM"), Locale.ResolveString("HIGH") },
                callback = autoApplyCallback
            },
            {
                name    = "TextureManagement",
                label   = Locale.ResolveString("OPTION_TEXTURE_MANAGEMENT"),
                tooltip = Locale.ResolveString("OPTION_TEXTURE_MANAGEMENT_TOOLTIP"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"),  Locale.ResolveString("GB_HALF"), Locale.ResolveString("GB_ONE"), Locale.ResolveString("GB_ONE_POINT_FIVE"), Locale.ResolveString("GB_TWO_PLUS")  },
                callback = autoApplyCallback
            },
            {
                name    = "ParticleQuality",
                label   = Locale.ResolveString("PARTICLE_QUALITY"),
                type    = "select",
                values  = { Locale.ResolveString("LOW"), Locale.ResolveString("HIGH") },
                callback = autoApplyCallback
            },   
            {
                name    = "Shadows",
                label   = Locale.ResolveString("SHADOWS"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = autoApplyCallback
            },
            {
                name    = "LightQuality",
                label   = Locale.ResolveString("LIGHT_QUALITY"),
                tooltip = Locale.ResolveString("OPTION_LIGHT_QUALITY"),
                type    = "select",
                values  = { Locale.ResolveString("LOW"), Locale.ResolveString("HIGH") },
                callback = OnLightQualityChanged
            },
            {
                name    = "AntiAliasing",
                label   = Locale.ResolveString("ANTI_ALIASING"),
                tooltip = Locale.ResolveString("OPTION_ANTI_ALIASING"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = autoApplyCallback
            },
            {
                name    = "Bloom",
                label   = Locale.ResolveString("BLOOM"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = autoApplyCallback
            },
            {
                name    = "Atmospherics",
                label   = Locale.ResolveString("ATMOSPHERICS"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = autoApplyCallback
            },
            {   
                name    = "AnisotropicFiltering",
                label   = Locale.ResolveString("AF"),
                tooltip = Locale.ResolveString("OPTION_AF"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = autoApplyCallback
            },
            {
                name    = "AmbientOcclusion",
                label   = Locale.ResolveString("AMBIENT_OCCLUSION"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("MEDIUM"), Locale.ResolveString("HIGH") },
                callback = autoApplyCallback
            },    
            {
                name    = "Reflections",
                label   = Locale.ResolveString("REFLECTIONS"),
                type    = "select",
                values  = { Locale.ResolveString("OFF"), Locale.ResolveString("ON") },
                callback = autoApplyCallback
            },
            {
                name    = "DecalLifeTime",
                label   = Locale.ResolveString("DECAL"),
                type    = "slider",
                sliderCallback = OnDecalLifeTimeChanged,
            },  
            {
                name    = "Infestation",
                label   = Locale.ResolveString("OPTION_INFESTATION"),
                type    = "select",
                values  = { Locale.ResolveString("MINIMAL"), Locale.ResolveString("RICH") },
                callback = autoApplyCallback
            },
        }
        
    -- save our option elements for future reference
    self.optionElements = { }
    
    local generalForm     = GUIMainMenu.CreateOptionsForm(self, content, generalOptions, self.optionElements)
    local keyBindingsForm = CreateKeyBindingsForm(self, content)
    local keyBindingsFormCom = CreateKeyBindingsFormCom(self, content)
    local graphicsForm    = GUIMainMenu.CreateOptionsForm(self, content, graphicsOptions, self.optionElements)
    local soundForm       = GUIMainMenu.CreateOptionsForm(self, content, soundOptions, self.optionElements)
    
    soundForm:SetCSSClass("sound_options")    
    self.soundForm = soundForm
        
    local tabs = 
        {
            { label = Locale.ResolveString("GENERAL"),  form = generalForm, scroll=true  },
            { label = Locale.ResolveString("BINDINGS"), form = keyBindingsForm, scroll=true },
            { label = Locale.ResolveString("OPTION_COMMANDER"), form = keyBindingsFormCom, scroll=true },
            { label = Locale.ResolveString("GRAPHICS"), form = graphicsForm, scroll=true },
            { label = Locale.ResolveString("SOUND"),    form = soundForm },
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
        
        -- Make the first tab visible.
        if i==1 then
            tabBackground:SetBackgroundPosition( Vector(tabWidth * (i - 1), 0, 0) )
            ShowTab()
        end
        
    end        
    
    InitOptionWindow()
  
end

local kReplaceAlertMessage = { }
kReplaceAlertMessage["Connection disallowed"] = Locale.ResolveString("SERVER_FULL")
function GUIMainMenu:Update(deltaTime)

    PROFILE("GUIMainMenu:Update")
    
    if self:GetIsVisible() then

        local currentTime = Client.GetTime()
        
        -- Refresh the mod list once every 5 seconds.
        self.timeOfLastRefresh = self.timeOfLastRefresh or currentTime
        if self.modsWindow and self.modsWindow:GetIsVisible() and currentTime - self.timeOfLastRefresh >= 5 then
        
            self:RefreshModsList()
            self.timeOfLastRefresh = currentTime
            
        end
        
        self.tweetText:Update(deltaTime)
        
        local alertText = MainMenu_GetAlertMessage()
        if self.currentAlertText ~= alertText then
        
            alertText = kReplaceAlertMessage[alertText] or alertText
            self.currentAlertText = alertText
            
            if self.currentAlertText then
            
                if self.currentAlertText == Locale.ResolveString("SERVER_FULL") or self.currentAlertText == Locale.ResolveString("INCORRECT_PASSWORD") then
                    self:ActivatePlayWindow()
                end
                
                local setAlertText = self.currentAlertText
                if setAlertText:len() > 32 then
                    setAlertText = setAlertText:sub(0, 32) .. "\n" .. setAlertText:sub(33, setAlertText:len())
                end
                self.alertText:SetText(setAlertText)
                self.alertWindow:SetIsVisible(true)
                
                MainMenu_OnTooltip()
                
            end
            
        end
        
        -- Update only when visible.
        GUIAnimatedScript.Update(self, deltaTime)
    
        if self.soundForm and self.soundForm:GetIsVisible() then
            if self.optionElements.RecordingVolume then
                self.optionElements.RecordingVolume:SetValue(Client.GetRecordingVolume())
                if Client.GetRecordingVolume() >= 1 then
                    self.optionElements.RecordingVolume:SetColor(Color(0.6, 0, 0, 1))
                elseif Client.GetRecordingVolume() > 0.5 and Client.GetRecordingVolume() < 1 then
                    self.optionElements.RecordingVolume:SetColor(Color(0.7, 0.7, 0, 1))
                else
                    self.optionElements.RecordingVolume:SetColor(Color(0.47, 0.67, 0.67, 1))
                end
                
            end
        end

        if self.menuBackground:GetIsVisible() then
            self.playerName:SetText(OptionsDialogUI_GetNickname())
            self.rankLevel:SetText(string.format( Locale.ResolveString("MENU_LEVEL"), Client.GetOptionInteger("player-ranking", 0)))
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
                self.playWindow.updateButton:SetText(Locale.ResolveString("UPDATE"))
            end
            
            if listChanged then
                self.serverList:RenderNow()
                self.serverTabs:SetGameTypes(self.serverList:GetGameTypes())
            end
            
            local countTxt = ToString(Client.GetNumServers()) .. (Client.GetServerListRefreshed() and "" or "...")
            self.serverCountDisplay:SetText(countTxt)
            
        end
        
        if self.playNowWindow then
            self.playNowWindow:UpdateLogic(self)
        end
        
        if self.fpsDisplay then
            self.fpsDisplay:SetText(string.format( Locale.ResolveString("MENU_FPS"), Client.GetFrameRate()))
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

        local lastModel = Client.GetOptionString("currentModel", "")
        if self.customizeFrame and self.customizeFrame:GetIsVisible() and MainMenu_IsInGame() then
            MenuPoses_Update(deltaTime)
            MenuPoses_SetViewModel(false)
            MenuPoses_SetModelAngle(self.sliderAngleBar:GetValue() or 0)
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
    
    --self.logo:SetIsVisible(true)
    
    if not MainMenu_IsInGame() and self.newsScript and self.newsScript.isVisible == false then
        self.newsScript:SetPlayAnimation("show")  
    end
    
end

function GUIMainMenu:HideMenu()

    self.menuBackground:SetCSSClass("menu_bg_hide", false)

    for i = 1, #self.Links do
        self.Links[i]:SetIsVisible(false)
    end
    
    --self.logo:SetIsVisible(false)
    if not MainMenu_IsInGame() and self.newsScript.isVisible == true then
        self.newsScript:SetPlayAnimation("hide")    
    end
    if self.firstRunWindow then
        self.firstRunWindow:SetIsVisible(false)
    end
    if self.tutorialNagWindow then
        self.tutorialNagWindow:SetIsVisible(false)
    end

end

function GUIMainMenu:OnAnimationsEnd(item)
    
    if item == self.scanLine:GetBackground() then
        self.scanLine:SetCSSClass("scanline")
    end
    
end

function GUIMainMenu:OnAnimationCompleted(animatedItem, animationName, itemHandle)

    if animationName == "ANIMATE_LINK_BG" then
        
        for i = 1, #self.Links do
            self.Links[i]:SetFrameCount(15, 1.6, AnimateLinear, "ANIMATE_LINK_BG")       
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

            for i = 1, #self.Links do
                self.Links[i]:SetIsVisible(true)
            end

        end
        
    elseif animationName == "SHOWWINDOW_UP" then
    
        self.showWindowAnimation:SetCSSClass("showwindow_animation2")
    
    elseif animationName == "SHOWWINDOW_RIGHT" and self.windowToOpen then

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
    
    -- this is a hack. fix reloading of slidebars instead
    if self.generalForm then
        self.generalForm:Uninitialize()
        self.generalForm = CreateGeneralForm(self, self.optionWindow:GetContentBox())
    end    
    
end

function GUIMainMenu:UpdateRestartMessage()
    
    local needsRestart = not Client.GetIsSoundDeviceValid(Client.SoundDeviceType_Input) or
                         not Client.GetIsSoundDeviceValid(Client.SoundDeviceType_Output) or
                         Client.GetRenderDeviceName() ~= Client.GetOptionString("graphics/device", "")
        
    if needsRestart then
        self.warningLabel:SetText(Locale.ResolveString("GAME_RESTART_REQUIRED"))
        self.warningLabel:SetIsVisible(true)    
    else
        self.warningLabel:SetIsVisible(false)        
    end

end

function OnSoundDeviceListChanged()

    -- The options page may not be initialized yet
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

-- Called when the options file is changed externally
local function OnOptionsChanged()

    if gMainMenu ~= nil and gMainMenu.optionElements then
        InitOptions(gMainMenu.optionElements)
    end
    
end

function GUIMainMenu:ActivatePlayWindow(playNow)

    if not self.playWindow then
        self:CreatePlayWindow()
    end

    if not playNow then
        self:TriggerOpenAnimation(self.playWindow)
        self:HideMenu()
    else
        self.playNowWindow:SetIsVisible(true)
    end

end

function GUIMainMenu:ActivateGatherWindow()

    if not self.gatherWindow then
        self:CreateGatherWindow()
    end
    self:TriggerOpenAnimation(self.gatherWindow)
    self:HideMenu()

end

function GUIMainMenu:ActivateCustomizeWindow()

    if not self.customizeWindow then
        self:CreateCustomizeWindow()
    end
    self:TriggerOpenAnimation(self.customizeFrame)
    self:HideMenu()

end

function GUIMainMenu:OnPlayClicked(playNow)

    local isRookie = Client.GetOptionBoolean( kRookieOptionsKey, true )
    local doneTutorial = Client.GetOptionBoolean( "playedTutorial", false )
    local stopNagging = Client.GetOptionBoolean( "disableTutorialNag", false )
    local lastLoadedBuild = Client.GetOptionInteger("lastLoadedBuild", 0)

    if not isRookie or doneTutorial or stopNagging then
        self:ActivatePlayWindow(playNow)
        return
    end

    self.tutorialNagWindow = self:CreateWindow()  
    self.tutorialNagWindow:SetWindowName("HINT")
    self.tutorialNagWindow:SetInitialVisible(true)
    self.tutorialNagWindow:SetIsVisible(true)
    self.tutorialNagWindow:DisableResizeTile()
    self.tutorialNagWindow:DisableSlideBar()
    self.tutorialNagWindow:DisableContentBox()
    self.tutorialNagWindow:SetCSSClass("tutnag_window")
    self.tutorialNagWindow:DisableCloseButton()
    self.tutorialNagWindow:SetLayer(kGUILayerMainMenuDialogs)
    
    local hint = CreateMenuElement(self.tutorialNagWindow, "Font")
    hint:SetCSSClass("first_run_msg")
    hint:SetText(Locale.ResolveString("TUTNAG_MSG"))
    hint:SetTextClipped( true, 400, 400 )

    local okButton = CreateMenuElement(self.tutorialNagWindow, "MenuButton")
    okButton:SetCSSClass("tutnag_play")
    okButton:SetText(Locale.ResolveString("TUTNAG_PLAY"))
    okButton:AddEventCallbacks({ OnClick = function()
            self:DestroyWindow( self.tutorialNagWindow )
            self.tutorialNagWindow = nil
            self:StartTutorial()
        end})

    local skipButton = CreateMenuElement(self.tutorialNagWindow, "MenuButton")
    skipButton:SetCSSClass("tutnag_later")
    skipButton:SetText(Locale.ResolveString("TUTNAG_LATER"))
    skipButton:AddEventCallbacks({OnClick = function()
            self:DestroyWindow( self.tutorialNagWindow )
            self.tutorialNagWindow = nil
            self:ActivatePlayWindow(playNow)
        end})

    skipButton = CreateMenuElement(self.tutorialNagWindow, "MenuButton")
    skipButton:SetCSSClass("tutnag_stop")
    skipButton:SetText(Locale.ResolveString("TUTNAG_STOP"))
    skipButton:AddEventCallbacks({OnClick = function()
            self:DestroyWindow( self.tutorialNagWindow )
            self.tutorialNagWindow = nil
            Client.SetOptionBoolean( "disableTutorialNag", true )
            self:ActivatePlayWindow(playNow)
        end})

end

local LinkItems =
{
    { "MENU_RESUME_GAME", function(self)

            self.scriptHandle:SetIsVisible(not self.scriptHandle:GetIsVisible())

        end
    },
    { "MENU_GO_TO_READY_ROOM", function(self)

            self.scriptHandle:SetIsVisible(not self.scriptHandle:GetIsVisible())
            Shared.ConsoleCommand("rr")

        end
    },
    { "MENU_VOTE", function(self)

            OpenVoteMenu()
            self.scriptHandle:SetIsVisible(false)

        end
    },
    { "MENU_SERVER_BROWSER", function(self)

            if MainMenu_IsInGame then
                self.scriptHandle:ActivatePlayWindow()
            else
                self.scriptHandle:OnPlayClicked()
            end

        end
    },
    { "MENU_ORGANIZED_PLAY", function(self)

            self.scriptHandle:ActivateGatherWindow()

        end
    },
    { "MENU_OPTIONS", function(self)

            if not self.scriptHandle.optionWindow then
                self.scriptHandle:CreateOptionWindow()
            end
            self.scriptHandle:TriggerOpenAnimation(self.scriptHandle.optionWindow)
            self.scriptHandle:HideMenu()

        end
    },
    { "MENU_CUSTOMIZE_PLAYER", function(self)

            self.scriptHandle:ActivateCustomizeWindow()
            self.scriptHandle.screenFade = GetGUIManager():CreateGUIScript("GUIScreenFade")
            self.scriptHandle.screenFade:Reset()

        end
    },
    { "MENU_DISCONNECT", function(self)

            self.scriptHandle:HideMenu()

            Shared.ConsoleCommand("disconnect")

            self.scriptHandle:ShowMenu()

        end
    },
    { "MENU_TRAINING", function(self)

            if not self.scriptHandle.trainingWindow then
                self.scriptHandle:CreateTrainingWindow()
            end
            self.scriptHandle:TriggerOpenAnimation(self.scriptHandle.trainingWindow)
            self.scriptHandle:HideMenu()

        end
    },
    { "MENU_MODS", function(self)

            if not self.scriptHandle.modsWindow then
                self.scriptHandle:CreateModsWindow()
            end            
            self.scriptHandle.modsWindow.sorted = false
            self.scriptHandle:TriggerOpenAnimation(self.scriptHandle.modsWindow)
            self.scriptHandle:HideMenu()

        end
    },
    { "MENU_CREDITS", function(self)

            self.scriptHandle:HideMenu()
            if not self.creditsScript then
                self.creditsScript = GetGUIManager():CreateGUIScript("menu/GUICredits")
            end
            MainMenu_OnPlayButtonClicked()
            self.creditsScript:SetPlayAnimation("show")
            self.creditsScript.closeEvent:AddHandler( self, function() self.scriptHandle:ShowMenu() end)

        end
    },
    { "MENU_EXIT", function()

            Client.Exit()
            
            if Sabot.GetIsInGather() then
                Sabot.QuitGather()
            end

        end    
    },
    { "MENU_QUICK_JOIN", function(self)

            self.scriptHandle:OnPlayClicked(true)

        end
    }
}
--Id of Links table is used to order links
local LinkOrder =
{
    { 4,13,9,6,10,11,12 },
    { 1,2,3,4,9,6,7,8 }
}

function GUIMainMenu:CreateMainLinks()
    
    local index = MainMenu_IsInGame() and 2 or 1
    local linkOrder = LinkOrder[index]
    for i=1, #linkOrder do
        local linkId = linkOrder[i]
        local text = LinkItems[linkId][1]
        local callbackTable = LinkItems[linkId][2]
        local link = self:CreateMainLink(text, i, callbackTable)
        table.insert(self.Links, link)
    end
    
end

--mode 1: Not Ingame 2: Ingame 3: Both
function GUIMainMenu:AddMainLink(name, position, OnClick, mode)
    if not ( name or position or OnClick or mode) then 
        return 
    end
    
    table.insert(LinkItems, {name, OnClick})
    if mode == 1 or mode == 3 then 
        table.insert(LinkOrder[1], position, #LinkItems)
    end
    if mode == 2 or mode == 3 then
        table.insert(LinkOrder[2], position, #LinkItems)
    end
    return true
end

function GUIMainMenu:RemoveMainLink(position, inGame)
    local orderTable = inGame and 2 or 1
    table.remove(LinksOrder[inGame], position)
end

Event.Hook("SoundDeviceListChanged", OnSoundDeviceListChanged)
Event.Hook("OptionsChanged", OnOptionsChanged)
Event.Hook("DisplayChanged", OnDisplayChanged)