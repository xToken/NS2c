decoda_name = "Loading"

Script.Load("lua/ModLoader.lua")
Script.Load("lua/GUIUtility.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/BindingsDialog.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/SabotCoreClient.lua")
Script.Load("lua/PrecacheList.lua")

local kModeText =
{
    ["starting local server"]   = { text = Locale.ResolveString("STARTING_LOCAL_SERVER") },
    ["attempting connection"]   = { text = Locale.ResolveString("ATTEMPTING_CONNECTION") },
    ["authenticating"]          = { text = Locale.ResolveString("AUTHENTICATING") },
    ["connection"]              = { text = Locale.ResolveString("CONNECTING") },
    ["loading"]                 = { text = Locale.ResolveString("LOADING_2") },
    ["waiting"]                 = { text = Locale.ResolveString("CONNECTING") },
    ["precaching"]              = { text = Locale.ResolveString("PRECACHING") },
    ["initializing_game"]       = { text = Locale.ResolveString("INITIALIZING_GAME") },
    ["loading_map"]             = { text = Locale.ResolveString("LOADING_MAP") },
    ["loading_assets"]          = { text = Locale.ResolveString("LOADING_ASSETS") },
    ["downloading_mods"]        = { text = Locale.ResolveString("DOWNLOADING_MODS") },
    ["checking_consistency"]    = { text = Locale.ResolveString("CONNECTING") },
    ["compiling_shaders"]       = { text = Locale.ResolveString("LOADING_SHADERS") }
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

local spinner
local statusText, statusTextShadow
local dotsText, dotsTextShadow
local tipText, tipTextBg
local tipNextHint, tipNextHintBg
local modsBg, modsText, modsTextShadow

local tipIndex = 0
local timeOfLastTip, timeOfLastSpace
local precached = false

-- background slideshow
local backgrounds
local transition
local currentBgId, currentBackground
local lastFadeEndTime = 0.0
local mainLoading = false
local bgSize, bgPos

local kBgFadeTime = 2.0
local kBgStayTime = 3.0

local mapBackgrounds = false
local searchedMapBackgrounds = false
local randomizer

local usedBGs = {}
local loopTimes = 0

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
    local msg2 = Locale.ResolveString("LOADING_MODLIST")
        
    if Client.GetConnectedServerIsSecure() then
        msg1 = Locale.ResolveString("LOADING_VAC")  
    end

    local numMountedMods = 0
    
    if numMods > 0 then
        for i = 1,numMods do
            if Client.GetIsModMounted(i) then
                    
                numMountedMods = numMountedMods + 1
                local title = Client.GetModTitle(i)
                local state  = Client.GetModState(i)
                local downloading, bytesDownloaded, totalBytes, retries, status = Client.GetModDownloadProgress(i)
                local percent = ""
                local retryText = retries == 0 and "" or string.format("[retry %2d]", retries)
                if downloading then
                    percent = "0%"
                    if totalBytes > 0 then
                        percent = string.format("%d%%", math.floor((bytesDownloaded / totalBytes) * 100))
                    end
                end
                local statusText = Locale.ResolveString(status)
                if status == "MOD_STATUS_AVAILABLE" then
                    -- stop showing retries once the status is available
                    retryText = ""
                end
                msg2 = msg2 .. string.format("\n      %s  %s %s %s", title, statusText, percent, retryText)
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
            text = string.format("%s", kModeText[mode].text, count, total)
            if total ~= 0 and mode ~= "checking_consistency" then
                text = text .. string.format(" (%d%%)", math.ceil((count / total) * 100))
            end
        else            
            text = Locale.ResolveString("LOADING_2")
        end
        
        local mapName = Shared.GetMapName()
        if mode == "loading_map" then
            if mapName ~= "" then
                text = text .. " " .. string.UTF8Upper(mapName)
            end    
        end
        
        if mode == "initializing_game" and mapName ~= "" and searchedMapBackgrounds == false then
            InitializeBackgrounds()
            if mapBackgrounds == true then
                currentBgId = 0
                lastFadeEndTime = Shared.GetTime() - 2*kBgStayTime
            end
            searchedMapBackgrounds = true
        end
        
        statusText:SetText(text)
        statusTextShadow:SetText(text)
        
        -- Add animated dots to the text.
        local numDots = math.floor(time / dotsSpeed) % (maxDots + 1)
        dotsText:SetText(string.rep(".", numDots))
        dotsTextShadow:SetText(string.rep(".", numDots))
        
    end
    
    if not mainLoading then
    
        -- Set backgrounds to the same size
        tipTextBg:SetSize(Vector(tipText:GetSize().x, tipText:GetSize().y, 0))
        tipTextBg:SetPosition(Vector(tipText:GetPosition().x - tipText:GetSize().x/2, tipText:GetPosition().y - tipText:GetSize().y/2, 0))
        
        tipNextHintBg:SetSize(Vector(tipNextHint:GetSize().x, tipNextHint:GetSize().y, 0))
        tipNextHintBg:SetPosition(Vector(tipNextHint:GetPosition().x - tipNextHint:GetSize().x/2, tipNextHint:GetPosition().y - tipNextHint:GetSize().y/2, 0))
        
    end
        
    -- Update background image slideshow
    if backgrounds ~= nil then
    
        if transition then
            local fraction = (time-transition.startTime) / transition.duration
            
            if fraction > 1.0 then
                -- fade done - swap buffers
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
                    
                    -- time to fade
                    local nextBgId
                    
                    -- We want to pick non-repeating backgrounds only when they are not map specific backgrounds
                    if mapBackgrounds == true then
                        nextBgId = math.min(currentBgId+1, #backgrounds)
                    else
                        local next = randomizer:random(1, #backgrounds)
                        
                        loopTimes = 0
                        while usedBGs[next] == true and loopTimes < 50 do
                            next = randomizer:random(1, #backgrounds)
                            loopTimes = loopTimes + 1
                        end
                        
                        nextBgId = next
                        
                    end

                    transition = {}
                    transition.startTime = time
                    transition.duration = kBgFadeTime
                    transition.from = currentBackground
                    transition.to = backgrounds[nextBgId]
                    currentBgId = nextBgId
                    usedBGs[nextBgId] = true
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

    -- Translate string to account for findings
    chosenTipString = SubstituteBindStrings(chosenTipString)

    -- Add "Tip:" and spaces before and after for padding
    tipText:SetText(" " .. Locale.ResolveString("LOADING_TIP") .. " " .. chosenTipString .. " ")
    
    timeOfLastTip = Shared.GetTime()

end

function NextTip()
    tipIndex = 1 + (tipIndex + 1) % #kTipStrings
    SetTipText(tipIndex)    
end

-- out - a table reference, which will be filled with ordered filenames
function InitBackgroundFileNames( out )

    -- First try to get screens for the map
    -- local mapname = Client.GetOptionString("lastServerMapName", "")
    local mapname = GetMapName()

    if mapname ~= '' then
    
        for i = 1,100 do
            
            local searchResult = {}
            Shared.GetMatchingFileNames( string.format("screens/%s/%d.jpg", mapname, i ), false, searchResult )

            mapBackgrounds = true
            if #searchResult == 0 then
                -- found no more - must be done
                break
            else
                -- found one - add it
                out[ #out+1 ] = searchResult[1]
            end

        end
        
    end
    
    -- did we find any?
    if #out == 0 then
        --Print("Found no map-specific ordered screenshots for %s. Using shots in 'screens' instead.", mapname)
        Shared.GetMatchingFileNames("screens/custom/*.jpg", false, out )
        if #out == 0 then        
            Shared.GetMatchingFileNames("screens/*.jpg", false, out )
        end
        mapBackgrounds = false
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

    for i = 1, #backgroundFileNames do
       usedBGs[i] = false
    end
    
end


-- NOTE: This does not refer to the loading screen being done..it's referring to the loading of the loading screen
function OnLoadComplete(main)

    mainLoading = (main ~= nil)

    -- Make the mouse visible so that the user can alt-tab out in Windowed mode.
    Client.SetMouseVisible(true)
    Client.SetMouseClipped(false)

    randomizer = Randomizer()
    randomizer:randomseed(Shared.GetSystemTime())
    for i = 1, 100 do math.random() end

    local backgroundAspect = 16.0/9.0

    local ySize = Client.GetScreenHeight()
    local xSize = ySize * backgroundAspect
    
    bgSize = Vector( xSize, ySize, 0 )
    bgPos = Vector( (Client.GetScreenWidth() - xSize) / 2, (Client.GetScreenHeight() - ySize) / 2, 0 ) 

    -- Create all bgs
    if not mainLoading then
        
        InitializeBackgrounds()

        -- Init background slideshow state

        lastFadeEndTime = Shared.GetTime()
        currentBgId = 1
        if currentBgId <= #backgrounds then
            currentBackground = backgrounds[currentBgId]
            currentBackground:SetIsVisible( true )
        end

    end
    
    if mainLoading then
    --letterbox for non16:9 resolutions
    local backgroundAspect = 9.0/16.0
    local xSize = Client.GetScreenWidth()
    local ySize = xSize * backgroundAspect
    bgPos = Vector(0, (Client.GetScreenHeight() - ySize) / 2, 0 ) 
        bgSize = Vector( xSize, ySize, 0 )
        local loadscreen = GUI.CreateItem()
        loadscreen:SetSize( bgSize )
        loadscreen:SetPosition( bgPos )
        loadscreen:SetTexture( "screens/IntroScreen.jpg" )
    end
    
    local spinnerSize   = GUIScale(192)
    local spinnerOffset = GUIScale(50)

    spinner = GUI.CreateItem()
    spinner:SetTexture("ui/loading/spinner.dds")
    spinner:SetSize( Vector( spinnerSize, spinnerSize, 0 ) )
    spinner:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset, Client.GetScreenHeight() - spinnerSize - spinnerOffset, 0 ) )
    spinner:SetBlendTechnique( GUIItem.Add )
    spinner:SetLayer(3)
    
    local statusOffset = GUIScale(5)

    local shadowOffset = GUIScale(2)

    statusTextShadow = GUI.CreateItem()
    statusTextShadow:SetOptionFlag(GUIItem.ManageRender)
    statusTextShadow:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset+shadowOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset+shadowOffset, 0 ) )
    statusTextShadow:SetTextAlignmentX(GUIItem.Align_Max)
    statusTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
    statusTextShadow:SetFontName(Fonts.kAgencyFB_Large)
    statusTextShadow:SetColor(Color(0,0,0,1))
    statusTextShadow:SetScale(GetScaledVector())
    GUIMakeFontScale(statusTextShadow)
    statusTextShadow:SetLayer(3)
        
    statusText = GUI.CreateItem()
    statusText:SetOptionFlag(GUIItem.ManageRender)
    statusText:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset, 0 ) )
    statusText:SetTextAlignmentX(GUIItem.Align_Max)
    statusText:SetTextAlignmentY(GUIItem.Align_Center)
    statusText:SetFontName(Fonts.kAgencyFB_Large)
    statusText:SetScale(GetScaledVector())
    GUIMakeFontScale(statusText)
    statusText:SetLayer(3)

    dotsTextShadow = GUI.CreateItem()
    dotsTextShadow:SetOptionFlag(GUIItem.ManageRender)
    dotsTextShadow:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset+shadowOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset+shadowOffset, 0 ) )
    dotsTextShadow:SetTextAlignmentX(GUIItem.Align_Min)
    dotsTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
    dotsTextShadow:SetFontName(Fonts.kAgencyFB_Large)
    dotsTextShadow:SetColor(Color(0,0,0,1))
    dotsTextShadow:SetScale(GetScaledVector())
    GUIMakeFontScale(dotsTextShadow)
    dotsTextShadow:SetLayer(3)
    
    dotsText = GUI.CreateItem()
    dotsText:SetOptionFlag(GUIItem.ManageRender)
    dotsText:SetPosition( Vector( Client.GetScreenWidth() - spinnerSize - spinnerOffset - statusOffset, Client.GetScreenHeight() - spinnerSize / 2 - spinnerOffset, 0 ) )
    dotsText:SetTextAlignmentX(GUIItem.Align_Min)
    dotsText:SetTextAlignmentY(GUIItem.Align_Center)
    dotsText:SetFontName(Fonts.kAgencyFB_Large)
    dotsText:SetScale(GetScaledVector())
    GUIMakeFontScale(dotsText)
    dotsText:SetLayer(3)

    if not mainLoading then

        -- Draw background behind it (create first so it's behind)
        tipTextBg = GUI.CreateItem()
        tipTextBg:SetColor(Color(0, 0, 0, 0))
        tipTextBg:SetIsVisible( Client.GetOptionBoolean("showHints", true) )
        tipTextBg:SetLayer(3)
        
        tipText = GUI.CreateItem()
        tipText:SetOptionFlag(GUIItem.ManageRender)
        tipText:SetPosition(Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() - GUIScale(41), 0))
        tipText:SetTextAlignmentX(GUIItem.Align_Center)
        tipText:SetTextAlignmentY(GUIItem.Align_Center)
        tipText:SetFontName(Fonts.kAgencyFB_Small)
        tipText:SetScale(GetScaledVector())
        GUIMakeFontScale(tipText)
        tipText:SetLayer(3)
        
        -- Only show tip if show hints is on
        tipText:SetIsVisible( Client.GetOptionBoolean("showHints", true) )

        -- Pick random tip to start
        tipIndex = randomizer:random(1, #kTipStrings)
        SetTipText(tipIndex)
        
        -- Tell user they can hit space for the next tip (create bg first so it draws behind)
        tipNextHintBg = GUI.CreateItem()
        tipNextHintBg:SetColor(Color(0, 0, 0, 0))
        tipNextHintBg:SetIsVisible( Client.GetOptionBoolean("showHints", true) )
        tipNextHintBg:SetLayer(3)

        tipNextHint = GUI.CreateItem()
        tipNextHint:SetOptionFlag(GUIItem.ManageRender)
        tipNextHint:SetPosition(Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() - GUIScale(15), 0))
        tipNextHint:SetTextAlignmentX(GUIItem.Align_Center)
        tipNextHint:SetTextAlignmentY(GUIItem.Align_Center)
        tipNextHint:SetFontName(Fonts.kAgencyFB_Small)
        tipNextHint:SetScale(GetScaledVector())
        GUIMakeFontScale(tipNextHint)
        tipNextHint:SetColor(Color(1, 1, 0, 1))
        tipNextHint:SetIsVisible( Client.GetOptionBoolean("showHints", true) )
        tipNextHint:SetLayer(3)
    
        -- Translate string to account for findings
        tipNextHint:SetText(" " .. SubstituteBindStrings(Locale.ResolveString("LOADING_TIP_NEXT")) .. " " )

    end
    
    -- Create a box to show the mods that the server is running
    modsText = GUI.CreateItem()
    modsText:SetOptionFlag(GUIItem.ManageRender)
    modsText:SetPosition(Vector(Client.GetScreenWidth() * 0.15, Client.GetScreenHeight() * 0.18, 0))
    modsText:SetFontName(Fonts.kAgencyFB_Small)
    modsText:SetScale(GetScaledVector())
    GUIMakeFontScale(modsText)
    modsText:SetLayer(3)
    modsText:SetIsVisible(false)
    
    modsTextShadow = GUI.CreateItem()
    modsTextShadow:SetOptionFlag(GUIItem.ManageRender)
    modsTextShadow:SetPosition(Vector(Client.GetScreenWidth() * 0.15 + GUIScale(1.5), Client.GetScreenHeight() * 0.18 + GUIScale(1.5), 0))
    modsTextShadow:SetFontName(Fonts.kAgencyFB_Small)
    modsTextShadow:SetScale(GetScaledVector())
    GUIMakeFontScale(modsTextShadow)
    modsTextShadow:SetLayer(2)
    modsTextShadow:SetIsVisible(false)
    modsTextShadow:SetColor(Color(0, 0, 0, 1))
    
end

-- Return true if the event should be stopped here.
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