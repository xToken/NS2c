
Script.Load("lua/Utility.lua")
Script.Load("lua/GUIUtility.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/BindingsDialog.lua")
Script.Load("lua/NS2Utility.lua")

local kModeText =
{
    ["starting local server"]   = { text = "STARTING LOCAL SERVER" },
    ["attempting connection"]   = { text = "ATTEMPTING CONNECTION" },
    ["authenticating"]          = { text = "AUTHENTICATING" },
    ["connection"]              = { text = "CONNECTING" },
    ["loading"]                 = { text = "LOADING" },
    ["waiting"]                 = { text = "WAITING FOR SERVER" },
    ["precaching"]              = { text = "PRECACHING", display = "count" },
    ["initializing_game"]       = { text = "INITIALIZING GAME" },
    ["loading_map"]             = { text = "LOADING MAP" },
    ["loading_assets"]          = { text = "LOADING ASSETS" },
    ["downloading_mods"]        = { text = "DOWNLOADING MODS" },
    ["checking_consistency"]    = { text = "CHECKING CONSISTENCY" },
    ["compiling_shaders"]       = { text = "LOADING SHADERS", display = "count" }
}

local kTipStrings =
{ 
    "LOADING_TIP_FF", "LOADING_TIP_MUTE", "LOADING_TIP_INFESTATION", "LOADING_TIP_RESOURCES",
    "LOADING_TIP_SPAWN", "LOADING_TIP_MAP", "LOADING_TIP_EVOLVE", "LOADING_TIP_F4", "LOADING_TIP_VENTS", "LOADING_TIP_WALLRUN",
    "LOADING_TIP_ROOKIES", "LOADING_TIP_REQ_MENU", "LOADING_TIP_SAYINGS_MENU", "LOADING_TIP_EXPLORE", "LOADING_TIP_SCOREBOARD",
    "LOADING_TIP_GOTOALERT", "LOADING_TIP_RAMBO", "LOADING_TIP_NOIINTEAM", "LOADING_TIP_MODS", "LOADING_TIP_COMMANDER_SPEAKING", 
    "LOADING_TIP_SPEEDYGONZALES", "LOADING_TIP_BEARARMS", "LOADING_TIP_ABILITIES", "LOADING_TIP_SUPPORT", "LOADING_TIP_PRIORITY", 
    "LOADING_TIP_GOODCOMM",
}

local spinner = nil
local statusText = nil
local statusTextShadow = nil
local dotsText = nil
local dotsTextShadow = nil
local tipText = nil
local tipTextBg = nil
local tipNextHint = nil
local tipNextHintBg = nil
local modsBg = nil
local modsText = nil
local modsTextShadow = nil

local tipIndex = 0
local timeOfLastTip = nil
local timeOfLastSpace = nil

// background slideshow
local backgrounds = nil
local transition = nil
local currentBgId
local currentBackground = nil
local lastFadeEndTime = 0.0
local currentMapName = ''
local mainLoading = false
local bgSize
local bgPos

local kBgFadeTime = 2.0
local kBgStayTime = 3.0

local function GetMapName()

    local mapName = Shared.GetMapName()
    if mapName == '' then
        mapName = Client.GetOptionString("lastServerMapName", "")
    end
    return mapName
    
end

local function UpdateServerInformation()

    local numMods = Client.GetNumMods()
    
    local msg1 = ""
    local msg2 = "SERVER MODIFICATIONS:\n"
        
    if Client.GetConnectedServerIsSecure() then
        msg1 = "NOTE: THIS SERVER IS VAC SECURED\nCHEATING WILL RESULT IN A PERMANENT BAN"  
    end

    local numMountedMods = 0
    
    if numMods > 0 then
        for i = 1,numMods do
            if Client.GetIsModMounted(i) then
                    
                numMountedMods = numMountedMods + 1
                local title = Client.GetModTitle(i)
                local state  = Client.GetModState(i)
                msg2 = msg2 .. string.format("\n      %s", title)
                
            end
        end
    end
    
    local text = ""
    
    if msg1 ~= "" then
        text = msg1 .. "\n\n"
    end
    if numMountedMods > 0 then
        text = text .. msg2
    end
    
    if text == "" then
    
        modsText:SetIsVisible(false)
        modsTextShadow:SetIsVisible(false)
        
    else
    
        modsText:SetIsVisible(true)
        modsText:SetText(text)
        modsTextShadow:SetIsVisible(true)
        modsTextShadow:SetText(text)
        
    end    

end

function OnUpdateRender()

    UpdateServerInformation()
    
    local spinnerSpeed  = 2
    local dotsSpeed     = 0.5
    local maxDots       = 4
    
    local time = Shared.GetTime()

    if spinner ~= nil then
        local angle = -time * spinnerSpeed
        spinner:SetRotation( Vector(0, 0, angle) )
    end
    
    if statusText ~= nil then
        
        local mode = Client.GetModeDescription()
        local count, total = Client.GetModeProgress()
        local text
        local suffix
        
        if kModeText[mode] then
            text = kModeText[mode].text
            if kModeText[mode].display == "count" and total ~= 0 then
                text = text .. string.format(" (%d%%)", math.ceil((count / total) * 100))
            end
        else            
            text = "LOADING"
        end
        
        if mode == "loading" then
            local mapName = Shared.GetMapName()
            if mapName ~= "" then
                text = text .. " " .. Shared.GetMapName()
            end    
        end
        
        statusText:SetText(text)
        statusTextShadow:SetText(text)
        
        // Add animated dots to the text.
        local numDots = math.floor(time / dotsSpeed) % (maxDots + 1)
        dotsText:SetText(string.rep(".", numDots))
        dotsTextShadow:SetText(string.rep(".", numDots))
        
    end
    
    if not mainLoading then
    
        // Set backgrounds to the same size
        tipTextBg:SetSize(Vector(tipText:GetSize().x, tipText:GetSize().y, 0))
        tipTextBg:SetPosition(Vector(tipText:GetPosition().x - tipText:GetSize().x/2, tipText:GetPosition().y - tipText:GetSize().y/2, 0))
        
        tipNextHintBg:SetSize(Vector(tipNextHint:GetSize().x, tipNextHint:GetSize().y, 0))
        tipNextHintBg:SetPosition(Vector(tipNextHint:GetPosition().x - tipNextHint:GetSize().x/2, tipNextHint:GetPosition().y - tipNextHint:GetSize().y/2, 0))
        
    end
        
    // Check if map specific backgrounds became available
    if not mainLoading then
        local newMapName = GetMapName()
        if newMapName ~= '' and currentMapName ~= newMapName then    
            currentMapName = newMapName
            InitializeBackgrounds()
            currentBgId = 0
            lastFadeEndTime = time - 2*kBgStayTime
        end
    end
        
    // Update background image slideshow
    if backgrounds ~= nil then
    
        if transition then
            local fraction = (time-transition.startTime) / transition.duration
            
            if fraction > 1.0 then
                // fade done - swap buffers
                if transition.from then
                    transition.from:SetLayer(1)
                    transition.from:SetIsVisible(false)
                end
                if transition.to then                
                    transition.to:SetLayer(2)
                    transition.to:SetColor(Color(1,1,1,1))
                end
                transition = nil
                lastFadeEndTime = time
            else
                if transition.from then
                    transition.from:SetLayer(1)
                end
                if transition.to then
                    transition.to:SetLayer(2)
                    transition.to:SetColor(Color(1,1,1,fraction))
                    transition.to:SetIsVisible(true)
                end
            end
        
        else
        
            if (time-lastFadeEndTime) > kBgStayTime then
            
                if currentBgId < #backgrounds then
                    
                    // time to fade
                    local nextBgId = math.min(currentBgId+1, #backgrounds)

                    transition = {}
                    transition.startTime = time
                    transition.duration = kBgFadeTime
                    transition.from = currentBackground
                    transition.to = backgrounds[nextBgId]
                    currentBgId = nextBgId
                    currentBackground = backgrounds[currentBgId]

                end
                
            end
        
        end

    end
    
end

function SetTipText(tipIndex)

    assert(tipIndex >= 1)
    assert(tipIndex <= #kTipStrings)
    
    local chosenTipString = kTipStrings[tipIndex]
    
    chosenTipString = Locale.ResolveString(chosenTipString)

    // Translate string to account for findings
    chosenTipString = SubstituteBindStrings(chosenTipString)

    // Add "Tip:" and spaces before and after for padding
    tipText:SetText(" " .. Locale.ResolveString("LOADING_TIP") .. " " .. chosenTipString .. " ")
    
    timeOfLastTip = Shared.GetTime()

end

function NextTip()
    tipIndex = 1 + (tipIndex + 1) % #kTipStrings
    SetTipText(tipIndex)    
end

// out - a table reference, which will be filled with ordered filenames
function InitBackgroundFileNames( out )

    // First try to get screens for the map
    // local mapname = Client.GetOptionString("lastServerMapName", "")
    local mapname = GetMapName()

    if mapname ~= '' then
    
        for i = 1,100 do
            
            local searchResult = {}
            Shared.GetMatchingFileNames( string.format("screens/%s/%d.jpg", mapname, i ), false, searchResult )

            if #searchResult == 0 then
                // found no more - must be done
                break
            else
                // found one - add it
                out[ #out+1 ] = searchResult[1]
            end

        end
        
    end
    
    // did we find any?
    if #out == 0 then
        //Print("Found no map-specific ordered screenshots for %s. Using shots in 'screens' instead.", mapname)
        Shared.GetMatchingFileNames("screens/*.jpg", false, out )
    end
end

function InitializeBackgrounds()

    local backgroundFileNames = {}
    InitBackgroundFileNames( backgroundFileNames )
    backgrounds = {}
    for i = 1, #backgroundFileNames do

        backgrounds[i] = GUI.CreateItem()
        backgrounds[i]:SetSize( bgSize )
        backgrounds[i]:SetPosition( bgPos )
        backgrounds[i]:SetTexture( backgroundFileNames[i] )
        backgrounds[i]:SetIsVisible( false )

    end

end


// NOTE: This does not refer to the loading screen being done..it's referring to the loading of the loading screen
function OnLoadComplete(main)

    mainLoading = (main ~= nil)

    // Make the mouse visible so that the user can alt-tab out in Windowed mode.
    Client.SetMouseVisible(true)
    Client.SetMouseClipped(false)

    local randomizer = Randomizer()
    randomizer:randomseed(Shared.GetSystemTime())

    local backgroundAspect = 16.0/9.0

    local ySize = Client.GetScreenHeight()
    local xSize = ySize * backgroundAspect
    
    bgSize = Vector( xSize, ySize, 0 )
    bgPos = Vector( (Client.GetScreenWidth() - xSize) / 2, (Client.GetScreenHeight() - ySize) / 2, 0 ) 

    // Create all bgs
    if not mainLoading then
        
        currentMapName = GetMapName()
        InitializeBackgrounds()

        // Init background slideshow state

        lastFadeEndTime = Shared.GetTime()
        currentBgId = 1
        if currentBgId <= #backgrounds then
            currentBackground = backgrounds[currentBgId]
            currentBackground:SetIsVisible( true )
        end

    end
    
    if mainLoading then
	//letterbox for non16:9 resolutions
	local backgroundAspect = 9.0/16.0
    local xSize = Client.GetScreenWidth()
	local ySize = xSize * backgroundAspect
	bgPos = Vector(0, (Client.GetScreenHeight() - ySize) / 2, 0 ) 
        bgSize = Vector( xSize, ySize, 0 )
        loadscreen = GUI.CreateItem()
        loadscreen:SetSize( bgSize )
		loadscreen:SetPosition( bgPos )
        loadscreen:SetTexture( "screens/loadingscreen.jpg" )
    end
    
    local spinnerSize   = GUIScale(256)
    local spinnerOffset = GUIScale(50)

    spinner = GUI.CreateItem()
    spinner:SetTexture("ui/loading/spinner.dds")
    spinner:SetSize( Vector( spinnerSize, spinnerSize, 0 ) )
    spinner:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset, Client.GetScreenHeight() - spinnerSize - spinnerOffset, 0 ) )
    spinner:SetBlendTechnique( GUIItem.Add )
    spinner:SetLayer(3)
    
    local statusOffset = GUIScale(50)

    local shadowOffset = 2

    statusTextShadow = GUI.CreateItem()
    statusTextShadow:SetOptionFlag(GUIItem.ManageRender)
    statusTextShadow:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset+shadowOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset+shadowOffset, 0 ) )
    statusTextShadow:SetTextAlignmentX(GUIItem.Align_Max)
    statusTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
    statusTextShadow:SetFontName("fonts/AgencyFB_large.fnt")
    statusTextShadow:SetColor(Color(0,0,0,1))
    statusTextShadow:SetLayer(3)
        
    statusText = GUI.CreateItem()
    statusText:SetOptionFlag(GUIItem.ManageRender)
    statusText:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset, 0 ) )
    statusText:SetTextAlignmentX(GUIItem.Align_Max)
    statusText:SetTextAlignmentY(GUIItem.Align_Center)
    statusText:SetFontName("fonts/AgencyFB_large.fnt")
    statusText:SetLayer(3)

    dotsTextShadow = GUI.CreateItem()
    dotsTextShadow:SetOptionFlag(GUIItem.ManageRender)
    dotsTextShadow:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset+shadowOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset+shadowOffset, 0 ) )
    dotsTextShadow:SetTextAlignmentX(GUIItem.Align_Min)
    dotsTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
    dotsTextShadow:SetFontName("fonts/AgencyFB_large.fnt")
    dotsTextShadow:SetColor(Color(0,0,0,1))
    dotsTextShadow:SetLayer(3)
    
    dotsText = GUI.CreateItem()
    dotsText:SetOptionFlag(GUIItem.ManageRender)
    dotsText:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset, 0 ) )
    dotsText:SetTextAlignmentX(GUIItem.Align_Min)
    dotsText:SetTextAlignmentY(GUIItem.Align_Center)
    dotsText:SetFontName("fonts/AgencyFB_large.fnt")
    dotsText:SetLayer(3)
    
    if not mainLoading then

        // Draw background behind it (create first so it's behind)
        tipTextBg = GUI.CreateItem()
        tipTextBg:SetColor(Color(0, 0, 0, 0))
        tipTextBg:SetIsVisible( Client.GetOptionBoolean("showHints", true) )
        tipTextBg:SetLayer(3)
        
        tipText = GUI.CreateItem()
        tipText:SetOptionFlag(GUIItem.ManageRender)
        tipText:SetPosition(Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() - 41, 0))
        tipText:SetTextAlignmentX(GUIItem.Align_Center)
        tipText:SetTextAlignmentY(GUIItem.Align_Center)
        tipText:SetFontName("fonts/AgencyFB_small.fnt")
        tipText:SetLayer(3)
        
        // Only show tip if show hints is on
        tipText:SetIsVisible( Client.GetOptionBoolean("showHints", true) )

        // Pick random tip to start
        tipIndex = randomizer:random(1, #kTipStrings)
        SetTipText(tipIndex)
        
        // Tell user they can hit space for the next tip (create bg first so it draws behind)
        tipNextHintBg = GUI.CreateItem()
        tipNextHintBg:SetColor(Color(0, 0, 0, 0))
        tipNextHintBg:SetIsVisible( Client.GetOptionBoolean("showHints", true) )
        tipNextHintBg:SetLayer(3)

        tipNextHint = GUI.CreateItem()
        tipNextHint:SetOptionFlag(GUIItem.ManageRender)
        tipNextHint:SetPosition(Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() - 15, 0))
        tipNextHint:SetTextAlignmentX(GUIItem.Align_Center)
        tipNextHint:SetTextAlignmentY(GUIItem.Align_Center)
        tipNextHint:SetFontName("fonts/AgencyFB_small.fnt")
        tipNextHint:SetColor(Color(1, 1, 0, 1))
        tipNextHint:SetIsVisible( Client.GetOptionBoolean("showHints", true) )
        tipNextHint:SetLayer(3)
    
        // Translate string to account for findings
        tipNextHint:SetText(" " .. SubstituteBindStrings(Locale.ResolveString("LOADING_TIP_NEXT")) .. " " )
        
    end
    
    // Create a box to show the mods that the server is running
    modsText = GUI.CreateItem()
    modsText:SetOptionFlag(GUIItem.ManageRender)
    modsText:SetPosition(Vector(Client.GetScreenWidth() * 0.15, Client.GetScreenHeight() * 0.18, 0))
    modsText:SetFontName("fonts/AgencyFB_small.fnt")
    modsText:SetLayer(3)
    modsText:SetIsVisible(false)
    
    modsTextShadow = GUI.CreateItem()
    modsTextShadow:SetOptionFlag(GUIItem.ManageRender)
    modsTextShadow:SetPosition(Vector(Client.GetScreenWidth() * 0.15 + 1, Client.GetScreenHeight() * 0.18 + 1, 0))
    modsTextShadow:SetFontName("fonts/AgencyFB_small.fnt")
    modsTextShadow:SetLayer(2)
    modsTextShadow:SetIsVisible(false)
    modsTextShadow:SetColor(Color(0, 0, 0, 1))
    
end

// Return true if the event should be stopped here.
local function OnSendKeyEvent(key, down)

    if not mainLoading then
        if key == InputKey.Space and (timeOfLastSpace == nil or Shared.GetTime() > timeOfLastSpace + 0.5) then
            NextTip()
            timeOfLastSpace = Shared.GetTime()
        end
    end
    
end

Event.Hook("LoadComplete", OnLoadComplete)
Event.Hook("UpdateRender", OnUpdateRender)
Event.Hook("SendKeyEvent", OnSendKeyEvent)