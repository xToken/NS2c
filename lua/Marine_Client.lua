// lua\Marine_Client.lua
//

Marine.k2DHUDFlash = "ui/marine_hud_2d.swf"

local kMarineHealthbarOffset = Vector(0, 1.2, 0)
function Marine:GetHealthbarOffset()
    return kMarineHealthbarOffset
end

function MarineUI_GetHasObservatory()

    local player = Client.GetLocalPlayer()
    
    if player then    
        return GetHasTech(player, kTechId.Observatory) 
    end
    
    return false

end

function MarineUI_GetHasArmsLab()

    local player = Client.GetLocalPlayer()
    
    if player then    
        return GetHasTech(player, kTechId.ArmsLab)  
    end
    
    return false

end

local function GetIsCloseToMenuStructure(self)
    
    local ptlabs = GetEntitiesForTeamWithinRange("PrototypeLab", self:GetTeamNumber(), self:GetOrigin(), PrototypeLab.kResupplyUseRange)
    local armories = GetEntitiesForTeamWithinRange("Armory", self:GetTeamNumber(), self:GetOrigin(), Armory.kResupplyUseRange)
    
    return (ptlabs and #ptlabs > 0) or (armories and #armories > 0)

end

function Marine:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    self.notifications = {}
    self.timeLastSpitHitEffect = 0
    
    if self:GetTeamNumber() ~= kTeamReadyRoom then

        if self.marineHUD == nil then
            self.marineHUD = GetGUIManager():CreateGUIScript("Hud/Marine/GUIMarineHUD")
        end
        
        self:TriggerHudInitEffects()
        
        if self.waypoints == nil then
            self.waypoints = GetGUIManager():CreateGUIScript("GUIWaypoints")
            self.waypoints:InitMarineTexture()
        end
        
        if self.pickups == nil then
            self.pickups = GetGUIManager():CreateGUIScript("GUIPickups")
        end

        if self.hints == nil then
            self.hints = GetGUIManager():CreateGUIScript("GUIHints")
        end
        
        if self.guiOrders == nil then
            self.guiOrders = GetGUIManager():CreateGUIScript("GUIOrders")
        end
        
        if self.sensorBlips == nil then
            self.sensorBlips = GetGUIManager():CreateGUIScript("GUISensorBlips")
        end 
       
        if self.unitStatusDisplay == nil then
            self.unitStatusDisplay = GetGUIManager():CreateGUIScript("GUIUnitStatus")
            self.unitStatusDisplay:EnableMarineStyle()
        end
        
    end
    
end

function Marine:TriggerHudInitEffects()

    self.marineHUD:TriggerInitAnimations()

end

function Marine:UnitStatusPercentage()
    return self.unitStatusPercentage
end

function Marine:ShowMap(showMap, showBig, forceReset)

    Player.ShowMap(self, showMap, showBig, forceReset)
    
    if showMap ~= self.mapState then
    
        self.mapState = showMap
        
        if not self.timeLastMapStateChange then
            self.timeLastMapStateChange = 0
        end
    
        if self.mapState and self.timeLastMapStateChange + 3 < Shared.GetTime() then
            
            self.timeLastMapStateChange = Shared.GetTime()
        
            local hudParams = self:GetHudParams()
            hudParams.initProjectingCinematic = true    
            self:SetHudParams(hudParams)
        end
    
    end

end

function Marine:GetHudParams()

    if self.hudParams == nil then
    
        self.hudParams = {}
        self.hudParams.timeDamageTaken = nil
        // scalar 0-1        
        self.hudParams.damageIntensity = 0
        // boolean to check if a hud cinematic should be played,  init with true so respawning / ejecting from CS / joining team will trigger it
        self.hudParams.initProjectingCinematic = true
    
    end
    
    return self.hudParams

end

function Marine:SetHudParams(hudParams)
    self.hudParams = hudParams
end

function Marine:UpdateClientEffects(deltaTime, isLocal)
    
    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    if isLocal then
    
        self:UpdateGhostModel()
        
        if self.marineHUD then
            self.marineHUD:SetIsVisible(self:GetIsAlive())
        end
        
   end
    
    
end

function Marine:OnUpdateRender()

    PROFILE("Marine:OnUpdateRender")
    
    Player.OnUpdateRender(self)
    
    local isLocal = self:GetIsLocalPlayer()
    
    // Synchronize the state of the light representing the flash light.
    self.flashlight:SetIsVisible(self.flashlightOn and (isLocal or self:GetIsVisible()) )
    
    if self.flashlightOn then
    
        local coords = Coords(self:GetViewCoords())
        coords.origin = coords.origin + coords.zAxis * 0.75
        
        self.flashlight:SetCoords(coords)
        
        // Only display atmospherics for third person players.
        local density = 0.4
        if isLocal and not self:GetIsThirdPerson() then
            density = 0
        end
        self.flashlight:SetAtmosphericDensity(density)
        
    end
    
    // Don't draw waypoint if we have hints displaying (to avoid the screen telling the player
    // about too many things to do)
    local waypointVisible = true
    if self.hints and self.hints:GetIsDisplayingHint() then
        waypointVisible = false
    end
    
    if self.waypoints then
        self.waypoints:SetWaypointVisible(waypointVisible)
    end
    
end

function Marine:CloseMenu()
   
    return false
    
end

function Marine:AddNotification(locationId, techId)

    local locationName = ""

    if locationId ~= 0 then
        locationName = Shared.GetString(locationId)
    end

    table.insert(self.notifications, { LocationName = locationName, TechId = techId })

end

// this function returns the oldest notification and clears it from the list
function Marine:GetAndClearNotification()

    local notification = nil

    if table.count(self.notifications) > 0 then
    
        notification = { LocationName = self.notifications[1].LocationName, TechId = self.notifications[1].TechId }
        table.remove(self.notifications, 1)
    
    end
    
    return notification

end

function Marine:UpdateClientHelp()

    local kDefaultScanRange = 10
    local teamNumber = self:GetTeamNumber()
    
    // Look for structure that needs to be built
    function isBuildStructure(ent)
        return ent:GetCanConstruct(self)
    end
    
    local origin = self:GetModelOrigin()

    local structures = Shared.GetEntitiesWithTagInRange("class:Structure", origin, kDefaultScanRange, isBuildStructure)
    Shared.SortEntitiesByDistance(origin, structures)
    
    for index = 1, #structures do
        local structure = structures[index]
        local localizedStructureName = Locale.ResolveString(LookupTechData(structure:GetTechId(), kTechDataDisplayName))
        local buildStructureText = Locale.ResolveString("BUILD_STRUCTURE") .. localizedStructureName
        self:AddBindingHint("Use", structure:GetId(), buildStructureText, 3)
    end
    
    // Look for unattached resource nozzles
    /*
    function isFreeResourcePoint(ent)
        return (ent:GetAttached() == nil)
    end
    for index, nozzle in ipairs( GetSortedByFunctor("ResourcePoint", self:GetModelOrigin(), kDefaultScanRange, isFreeResourcePoint) ) do
        self:AddInfoHint(nozzle:GetId(), "UNATTACHED_NOZZLE", 1)
    end

    // Look for unbuilt resource nozzles
    function isFreeTechPoint(ent)
        return (ent:GetAttached() == nil)
    end
    for index, nozzle in ipairs( GetSortedByFunctor("TechPoint", self:GetModelOrigin(), kDefaultScanRange, isFreeTechPoint) ) do
        self:AddInfoHint(nozzle:GetId(), "UNATTACHED_TECH_POINT", 1)
    end
    */
       
end

function Marine:TriggerFootstep()

    Player.TriggerFootstep(self)
    
    if self == Client.GetLocalPlayer() and not self:GetIsThirdPerson() then
    
        local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
        cinematic:SetRepeatStyle(Cinematic.Repeat_None)
        
    end

end

gCurrentHostStructureId = Entity.invalidId

function MarineUI_SetHostStructure(structure)

    if structure then
        gCurrentHostStructureId = structure:GetId()
    end    

end

function MarineUI_GetCurrentHostStructure()

    if gCurrentHostStructureId and gCurrentHostStructureId ~= Entity.invalidId then
        return Shared.GetEntity(gCurrentHostStructureId)
    end

    return nil    

end

// Bring up buy menu
function Marine:BuyMenu(structure)
    
    
end

function Marine:UpdateMisc(input)

    Player.UpdateMisc(self, input)
    
    if not Shared.GetIsRunningPrediction() then

        if input.move.x ~= 0 or input.move.z ~= 0 then

            self:CloseMenu()
            
        end
        
    end
    
end

function Marine:OnCountDown()

    Player.OnCountDown(self)
    
    if self.marineHUD then
        self.marineHUD:SetIsVisible(false)
    end

end

function Marine:OnCountDownEnd()

    Player.OnCountDownEnd(self)
    
    if self.marineHUD then
        self.marineHUD:SetIsVisible(true)
        self:TriggerHudInitEffects()
    end

end

function Marine:OnOrderSelfComplete(orderType)

    self:TriggerEffects("complete_order")

end

function Marine:UpdateGhostModel()

    self.currentTechId = nil
    self.ghostStructureCoords = nil
    self.ghostStructureValid = false
    self.showGhostModel = false
    
    local weapon = self:GetActiveWeapon()

    if weapon and weapon:isa("Mines") then
    
        self.currentTechId = kTechId.Mine
        self.ghostStructureCoords = weapon:GetGhostModelCoords()
        self.ghostStructureValid = weapon:GetIsPlacementValid()
        self.showGhostModel = weapon:GetShowGhostModel()
    
    end

end

function Marine:GetShowGhostModel()
    return self.showGhostModel
end    

function Marine:GetGhostModelTechId()
    return self.currentTechId
end

function Marine:GetGhostModelCoords()
    return self.ghostStructureCoords
end

function Marine:GetIsPlacementValid()
    return self.ghostStructureValid
end
