-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIHiveStatus.lua
--
-- Created by: Brock Gillespie (brock@naturalselection2.com)
--
-- Manages displaying the health, chambers, contructions, eggs, and commander occupancy
-- of all Hive Status UI elements.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--[[
TODO / Improvements
Use for Commander:
 - Allow clicking on container to snap-view to Hive
 - Offset base position to allow for room of Biomass?
 -- Biomass (and associated tech-unlocks) takes up a HUGE amount of
    the upper-left part of CommanderUI...makes it quite hard to re-use
    this for Khamm. BUT, Alien Khamm cannot quickly navigate between
    Hives without setting up Control groups (BAD!), so...worth experimenting!
 
 - Allowing Hive-Status on-click when respawning (just like mini-map) for
   spawn-point selection could be worthwhile.
   -- Note: this requires hiding / removing Biomass from Minimap view
   -- Is this duplicate info show on map?
   -- Should it be show for AlienSpectators?
--]]

Script.Load("lua/GUIScript.lua")
Script.Load("lua/Hud/Alien/GUIAlienHUDStyle.lua")

--convert precache assets to class statics?
local kContainerBackgroundTex = PrecacheAsset("ui/alien_hivestatus_frame_bgs.dds")
local kHiveStatusIconsTex = PrecacheAsset("ui/alien_hivestatus_hiveicons.dds")
local kUpgradesIconTex = PrecacheAsset("ui/alien_hivestatus_chamber_icons.dds")
local kHiveTypesEggIconTex = PrecacheAsset("ui/alien_hivestatus_types_egg_icons.dds")
local kLocationBg = PrecacheAsset("ui/alien_hivestatus_locationname_bg.dds")
local kCommanderIcons = PrecacheAsset("ui/alien_hivestatus_commicons.dds")


class 'GUIHiveStatus' (GUIScript)

GUIHiveStatus.kEntityTypes = { "Hive", "Spur", "Veil", "Shell", "Egg" }
GUIHiveStatus.kUpdateRate = 0.0125 --32Hz  --0.04 --25Hz UI update-throttle
GUIHiveStatus.kMaxStatusSlots = 5
GUIHiveStatus.kLowEggCountThreshold = 3 --XXX could make proportional to team-size

--GUIHiveStatus.kEggsCountFontColor = Color(1,1,1,1) --kAlienFontColor
GUIHiveStatus.kEggsCountFontColor = Color( 0.99, 0.82, 0.61, 1 ) --kAlienFontColor
GUIHiveStatus.kLocationTextColor = kAlienFontColor
local chamberFontColor = kAlienFontColor
chamberFontColor.a = 0.725
GUIHiveStatus.kUpgradesCountTextColor = chamberFontColor
GUIHiveStatus.kEggsIconColor = Color( 1, 1, 1, 1 )

GUIHiveStatus.kInCombatPulsateColor = Color( 0.662, 0.274, 0.286 )

--Hive Status Frames texture offsets (additive from top-left)
GUIHiveStatus.kContainerFrameTexOffsets = {} --Top-Left texture coords, Bottom-Right is defined by adding size
GUIHiveStatus.kContainerFrameTexOffsets[1] = Vector( 0, 0, 0 )
GUIHiveStatus.kContainerFrameTexOffsets[2] = Vector( 0, 125, 0 )
GUIHiveStatus.kContainerFrameTexOffsets[3] = Vector( 0, 250, 0 )
GUIHiveStatus.kContainerFrameTexOffsets[4] = Vector( 0, 375, 0 )
GUIHiveStatus.kContainerFrameTexOffsets[5] = Vector( 0, 500, 0 )

GUIHiveStatus.kHiveTypeIconTexOffsets = {}
GUIHiveStatus.kHiveTypeIconTexOffsets[1] = Vector( 0, 60, 0 )
GUIHiveStatus.kHiveTypeIconTexOffsets[2] = Vector( 65, 60, 0 )
GUIHiveStatus.kHiveTypeIconTexOffsets[3] = Vector( 130, 60, 0 )

GUIHiveStatus.kEggCountIconTexOffset = Vector( 195, 60, 0 )


function GUIHiveStatus:Initialize()
    PROFILE("GUIHiveStatus:Initialize")
    
    self.kStatusBackgroundSize = GUIScale( Vector( 275, 430, 0 ) )
    self.kHiveContainerSize = GUIScale( Vector( 228, 50, 0 ) )
    self.kHiveIconSize = GUIScale( Vector( 75, 72, 0 ) )
    self.kHiveTypeIconSize = GUIScale( Vector( 39, 36, 0 ) )
    self.kEggCountIconSize = GUIScale( Vector( 39, 36, 0 ) )
    self.kUpgradeChamberSize = GUIScale( Vector( 40, 40, 0 ) )
    self.kUpgradeChamberTextBgSize = GUIScale( Vector( 39, 36, 0 ) )
    self.kLocationBackgroundSize = GUIScale( Vector( 141, 24, 0 ) )
    self.kCommanderIconSize = GUIScale( Vector( 35, 32, 0 ) )
    
    self.kStatusBackgroundPosition = GUIScale( Vector( 0, 72, 0 ) )
    
    self.kHiveContainerPositions = {}
    self.kHiveContainerPositions[1] = GUIScale( Vector( 32, 5, 0 ) )
    self.kHiveContainerPositions[2] = GUIScale( Vector( 20, 90, 0 ) )
    self.kHiveContainerPositions[3] = GUIScale( Vector( 6, 175, 0 ) )
    self.kHiveContainerPositions[4] = GUIScale( Vector( 10, 260, 0 ) )
    self.kHiveContainerPositions[5] = GUIScale( Vector( 20, 345, 0 ) )
    
    -- subtle spacing / inset is handled by the texture image itself
    self.kHiveIconPosition = GUIScale( Vector( 69, 6, 0 ) )
    self.kHiveFillUpIconPosition = GUIScale( Vector( 69, 42, 0 ) )
    self.kHiveTypeIconPosition = GUIScale( Vector( 52, 7, 0 ) ) --24, 10, 0
    self.kEggCountIconPosition = GUIScale( Vector( 24, 30, 0 ) ) --y=30
    self.kEggCountTextPosition = GUIScale( Vector( -2.1, 8.4, 0 ) )
    self.kCommanderIconPosition = GUIScale( Vector( 112, 4, 0 ) )
    self.kLocationBackgroundPosition = GUIScale( Vector( -6, -13.2, 0 ) )
    self.kLocationTextPosition = GUIScale( Vector( 9, 6, 0 ) )
    
    --chamber icons are center/middle anchored
    self.kUpgradeChamberPositions = {} --relative to hive-frame
    self.kUpgradeChamberPositions[1] = GUIScale( Vector( 12, -10, 0 ) )
    self.kUpgradeChamberPositions[2] = GUIScale( Vector( 50, -10, 0 ) )
    self.kUpgradeChamberPositions[3] = GUIScale( Vector( 84, -10, 0 ) )
    
    --Note: Text Backgrounds are parented to Chamber GUIItems
    self.kUpgradeChamberTextBgPosition = GUIScale( Vector( -self.kUpgradeChamberSize.x * 0.36, 0, 0 ) )
    self.kUpgradeChamberTextPosition = GUIScale( Vector( -3.28, -8, 0 ) )
    
    self.kEggTextFontScale = GUIScale( Vector(1,1,0) * 0.4725 )
    self.kLocationTextFontScale = GUIScale( Vector(1,1,0) * 0.465 )
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( self.kStatusBackgroundSize )
    self.background:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.background:SetPosition( self.kStatusBackgroundPosition )
    self.background:SetIsVisible( true )
    self.background:SetLayer( kGUILayerPlayerHUD )
    self.background:SetColor( Color( 0.5, 0.5, 0.5, 0 ) )
    
    self:Reset()
    
    self:SetIsVisible(not HelpScreen_GetHelpScreen():GetIsBeingDisplayed())
    
end

function GUIHiveStatus:SetIsVisible(state)
    
    self.visible = state
    self:Update(0)
    
end

function GUIHiveStatus:GetIsVisible()
    
    return (self.visible == true)
    
end

function GUIHiveStatus:Uninitialize()
    PROFILE("GUIHiveStatus:Uninitialize")
    
    for idx = 1, #self.statusSlots do
        self:UninitializeStatusSlot( idx )
        self.statusSlots[idx] = nil
    end
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
end

function GUIHiveStatus:UninitializeStatusSlot( slotIdx )
    PROFILE("GUIHiveStatus:UninitializeStatusSlot")
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    
    if self.statusSlots[slotIdx] ~= nil then
        
        --Easier to loop through all children and go from there?
        GUI.DestroyItem( self.statusSlots[slotIdx].background )
        GUI.DestroyItem( self.statusSlots[slotIdx].frame )
        GUI.DestroyItem( self.statusSlots[slotIdx].hiveNormalIcon )
        GUI.DestroyItem( self.statusSlots[slotIdx].hiveIconBackground )
        GUI.DestroyItem( self.statusSlots[slotIdx].hiveConstructedIcon )
        GUI.DestroyItem( self.statusSlots[slotIdx].hiveDamageIcon )
        GUI.DestroyItem( self.statusSlots[slotIdx].hiveTypeIcon )
        GUI.DestroyItem( self.statusSlots[slotIdx].eggsText )
        GUI.DestroyItem( self.statusSlots[slotIdx].eggsIcon )
        GUI.DestroyItem( self.statusSlots[slotIdx].locationBackground )
        GUI.DestroyItem( self.statusSlots[slotIdx].locationText )
        GUI.DestroyItem( self.statusSlots[slotIdx].commanderIcon )
        
        --[[
        for i = 1, #self.statusSlots[slotIdx].chambers do
            GUI.DestroyItem( self.statusSlots[slotIdx].chambers[i]. )
            GUI.DestroyItem( self.statusSlots[slotIdx].chambers[i]. )
            GUI.DestroyItem( self.statusSlots[slotIdx].chambers[i]. )
            
            --TODO nil out chamber slots
        end
        --]]
        
        self.statusSlots[slotIdx].background = nil
        self.statusSlots[slotIdx].frame = nil
        self.statusSlots[slotIdx].hiveNormalIcon = nil
        self.statusSlots[slotIdx].hiveIconBackground = nil
        self.statusSlots[slotIdx].hiveConstructedIcon = nil
        self.statusSlots[slotIdx].hiveDamageIcon = nil
        self.statusSlots[slotIdx].hiveTypeIcon = nil
        self.statusSlots[slotIdx].eggsText = nil
        self.statusSlots[slotIdx].eggsIcon = nil
        self.statusSlots[slotIdx].locationBackground = nil
        self.statusSlots[slotIdx].locationText = nil
        self.statusSlots[slotIdx].commanderIcon = nil
        
    end
    
end

function GUIHiveStatus:Reset()
    
    self.statusSlots = {}
    self.statusSlots[1] = { _isEmpty = true, _locationId = 0 }
    self.statusSlots[2] = { _isEmpty = true, _locationId = 0 }
    self.statusSlots[3] = { _isEmpty = true, _locationId = 0 }
    self.statusSlots[4] = { _isEmpty = true, _locationId = 0 }
    self.statusSlots[5] = { _isEmpty = true, _locationId = 0 }
    
    self.nextUpdateTime = 0
    self.nextDataUpdateTime = 0
    
    self.teamInfoEnt = nil --ensure valid per-round ent ref
    self.validLocations = {}
    
    local techPoints = GetEntitiesMatchAnyTypes( { "TechPoint" } )
    if techPoints then
        for _, techPoint in ipairs(techPoints) do
            table.insert( self.validLocations, techPoint.locationId )
        end
    end
    
    self.teamInfoEnt = GetTeamInfoEntity( kTeam2Index ) --Data Source
    
end

function GUIHiveStatus:OnResolutionChanged( oldX, oldY, newX, newY )
    self:Uninitialize()
    self:Initialize()
end

function GUIHiveStatus:PulseIconRed( origColor )
    local anim = ( math.cos( Shared.GetTime() * 10) + 1 ) * 0.5
    local color = Color( 0.662, 0.274, 0.286 )  --TODO change to class global
    GUIMixColor( color, origColor, anim )
    return color
end


function GUIHiveStatus:HideHiveIcon( slotIdx )
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx < GUIHiveStatus.kMaxStatusSlots )
    
    self.statusSlots[slotIdx].hiveNormalIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveDamageIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveIconBackground:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveTypeIcon:SetIsVisible( false )
    
end

function GUIHiveStatus:SetHiveTypeIcon( slotIdx, typeFlag )
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( type(typeFlag) == "number" ) 
    assert( typeFlag >= 0 and typeFlag < 6 )
    
    if typeFlag == 0 then
        self.statusSlots[slotIdx].hiveTypeIcon:SetIsVisible(false)
        return
    end
    
    if typeFlag > 2 then
        
        --TODO Simplify
        local texCoords = {}
        if typeFlag == 3 then
            texCoords = { 0, 0, 65, 60 }
        elseif typeFlag == 4 then
            texCoords = { 72, 0, 130, 60 }
        elseif typeFlag == 5 then
            texCoords = { 130, 0, 195, 60 }
        end
        
        if texCoords[1] ~= nil then
            self.statusSlots[slotIdx].hiveTypeIcon:SetTexturePixelCoordinates( texCoords[1], texCoords[2], texCoords[3], texCoords[4] )
        end
        self.statusSlots[slotIdx].hiveTypeIcon:SetIsVisible( texCoords[1] ~= nil and self.visible )
        
    end
    
end

function GUIHiveStatus:UpdateHiveIconDisplay( slotIdx, typeFlag, builtScalar, healthScalar, maxHealth, inCombat )
    PROFILE("GUIHiveStatus:UpdateHiveIconDisplay")
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( type(typeFlag) == "number" )
    assert( typeFlag >= 0 and typeFlag < 6 ) --TODO Need enum/range global(s)
    assert( type(healthScalar) == "number" )
    assert( type(maxHealth) == "number" )
    
    self:SetHiveTypeIcon( slotIdx, typeFlag )
    
    if typeFlag == 0 then --FIXME need flag as enum
        self:HideHiveIcon( slotIdx )
        return
    end
    
    self.statusSlots[slotIdx].hiveIconBackground:SetIsVisible( self.visible )
    
    if typeFlag == 1 then
    --Unbuilt
        local buildSize = Vector( self.kHiveIconSize.x, self.kHiveIconSize.y * builtScalar, 0 )
        local posBuildOffsetY = self.kHiveIconPosition.y + ( ( 1 - builtScalar ) * self.kHiveIconSize.y )
        local buildPosition = Vector( self.kHiveIconPosition.x, posBuildOffsetY, 0 )
        
        --GUIScale( 
        
        self.statusSlots[slotIdx].hiveConstructedIcon:SetSize( buildSize )
        self.statusSlots[slotIdx].hiveConstructedIcon:SetPosition( buildPosition )
        self.statusSlots[slotIdx].hiveConstructedIcon:SetTexturePixelCoordinates( 250, 120 - 120 * builtScalar, 373, 120 ) --TODO Use global tex-coord var
        
        local showDamage = false
        showDamage = ( healthScalar * maxHealth < maxHealth )
        
        if showDamage then
            
            local damageSize = Vector( self.kHiveIconSize.x, self.kHiveIconSize.y * (1 - healthScalar), 0 )
            
            self.statusSlots[slotIdx].hiveDamageIcon:SetIsVisible( self.visible )
            self.statusSlots[slotIdx].hiveDamageIcon:SetSize( damageSize )
            self.statusSlots[slotIdx].hiveDamageIcon:SetTexturePixelCoordinates( 
                375, 0, 498, 120 * ( 1 - healthScalar )
            ) --TODO Use global tex-coord var
            
            if inCombat then
                self.statusSlots[slotIdx].hiveDamageIcon:SetColor( self:PulseIconRed( Color( 1, 1, 1, 1 ) ) )
            else
                self.statusSlots[slotIdx].hiveDamageIcon:SetColor( Color( 1, 1, 1, 1 ) )
            end
        end
        
    end
    
    self.statusSlots[slotIdx].hiveConstructedIcon:SetIsVisible( builtScalar < 1 and self.visible )
    self.statusSlots[slotIdx].hiveNormalIcon:SetIsVisible( builtScalar == 1 and self.visible )
    
    if builtScalar == 1 and healthScalar > 0 then
    --Built
        
        local healthSize = Vector( self.kHiveIconSize.x, self.kHiveIconSize.y * healthScalar, 0 )
        local posHealthOffsetY = self.kHiveIconPosition.y + ( (1 - healthScalar) * self.kHiveIconSize.y )
        local healthPosition = Vector( self.kHiveIconPosition.x, posHealthOffsetY, 0 )
        
        self.statusSlots[slotIdx].hiveNormalIcon:SetSize( healthSize )
        self.statusSlots[slotIdx].hiveNormalIcon:SetPosition( healthPosition )
        self.statusSlots[slotIdx].hiveNormalIcon:SetTexturePixelCoordinates( 0, 120 - 120 * healthScalar, 123, 120 ) --TODO Use global tex-coord var
        
        if healthScalar < 1 then
            
            local damageSize = Vector( self.kHiveIconSize.x, self.kHiveIconSize.y * (1 - healthScalar), 0 )
            
            self.statusSlots[slotIdx].hiveDamageIcon:SetIsVisible( self.visible )
            self.statusSlots[slotIdx].hiveDamageIcon:SetSize( damageSize )
            self.statusSlots[slotIdx].hiveDamageIcon:SetTexturePixelCoordinates( 
                375, 0, 498, 120 * ( 1 - healthScalar )
            ) --TODO Use global tex-coord var
            
            if inCombat then
                self.statusSlots[slotIdx].hiveDamageIcon:SetColor( self:PulseIconRed( Color( 1, 1, 1, 1 ) ) )
            else
                self.statusSlots[slotIdx].hiveDamageIcon:SetColor( Color( 1, 1, 1, 1 ) )
            end
            
        else
            self.statusSlots[slotIdx].hiveDamageIcon:SetIsVisible( false )
            self.statusSlots[slotIdx].hiveDamageIcon:SetColor( Color( 1, 1, 1, 1 ) )
        end
        
    end
    
end

--TODO Will need some simple logic to derive chamberIdx from where this is called
---- Will need to use upgradeChamber.activeChamber flag to denote "is occupied slot"
function GUIHiveStatus:AddUpgradeChamber( slotIdx, chamberTechId, chamberIdx )
    PROFILE("GUIHiveStatus:AddUpgradeChamber")
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( type(chamberIdx) == "number" )
    assert( chamberIdx > 0 and chamberIdx < 4 )
    assert( chamberTechId ~= nil )
    
    local chamber = self.statusSlots[slotIdx].chambers[chamberIdx]
    
    if chamber then
        
        local allowableChamberSlot = (
            chamber.chamberCount == 0 
            or chamber.chamberType == nil
            or chamber.chamberType == chamberTechId
        )
        
        if allowableChamberSlot then
            
        else
            Log("Mismatched Chamber type for existing slot")
            assert(false) --???
        end
        
    end
    
end

function GUIHiveStatus:UpdateCommanderIcon( slotIdx )
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    
    --TODO Change to func with multi return vars
    local commanderType = self.teamInfoEnt.commanderClassType
    local commanderLocationId = self.teamInfoEnt.commanderLocationId
    local texCoords = {}
    
    if self.statusSlots[slotIdx]._locationId == commanderLocationId then
        
        if commanderType > 0 then
        --Type: 0-No Kham, 1-Skulk, 2-Gorge, 3-Lerk, 4-Fade, 5-Onos
            if commanderType == 5 then 
                texCoords = { 0, 0, 72, 68 } --Onos
            elseif commanderType == 4 then 
                texCoords = { 72, 0, 144, 68 } --Fade
            elseif commanderType == 3 then 
                texCoords = { 144, 0, 216, 68 } --Lerk
            elseif commanderType == 2 then 
                texCoords = { 216, 0, 288, 68 } --Gorge
            elseif commanderType == 1 then 
                texCoords = { 288, 0, 360, 68 } --Skulk
            end
            
        end
        
        if texCoords[1] ~= nil then
            self.statusSlots[slotIdx].commanderIcon:SetTexturePixelCoordinates( texCoords[1], texCoords[2], texCoords[3], texCoords[4] )
        end        
    end
    
    self.statusSlots[slotIdx].commanderIcon:SetIsVisible( texCoords[1] ~= nil and self.visible )
    
end


function GUIHiveStatus:ClearStatusSlot( slotIdx )
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    
    self.statusSlots[slotIdx]._isEmpty = true
    
    if self.statusSlots[slotIdx].background ~= nil then
    --Trap to ensure slot was created before this was called
        
        self.statusSlots[slotIdx].background:SetIsVisible( false )
        self.statusSlots[slotIdx].frame:SetIsVisible( false )
        self.statusSlots[slotIdx].hiveConstructedIcon:SetIsVisible( false )
        self.statusSlots[slotIdx].hiveIconBackground:SetIsVisible( false )
        self.statusSlots[slotIdx].hiveNormalIcon:SetIsVisible( false )
        self.statusSlots[slotIdx].hiveTypeIcon:SetIsVisible( false )
        self.statusSlots[slotIdx].eggsIcon:SetIsVisible( false )
        self.statusSlots[slotIdx].eggsText:SetIsVisible( false )
        self.statusSlots[slotIdx].locationBackground:SetIsVisible( false )
        self.statusSlots[slotIdx].locationText:SetIsVisible( false )
        self.statusSlots[slotIdx].commanderIcon:SetIsVisible( false )
        self.statusSlots[slotIdx]._locationId = 0
        
        --TODO Handle data stuff and any "reset" actions (per guiitem) needed
        --  Chambers, for example
    end
    
end

function GUIHiveStatus:UpdateSlotOrdering( slotIdx )
--When this is called, the statusSlot with slotIdx IS empty
--and as with Update(), all slots are processed with top->down sequence (i.e. slotIdx + 1)
    
    PROFILE("GUIHiveStatus:UpdateSlotsOrdering")
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    
    local nextSlotIdx = slotIdx + 1
       
    self.statusSlots[slotIdx]._locationId = self.statusSlots[nextSlotIdx]._locationId
    self.statusSlots[slotIdx]._isEmpty = false
    
    self.statusSlots[slotIdx].background:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].frame:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].hiveIconBackground:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].eggsIcon:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].eggsText:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].locationBackground:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].locationText:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].commanderIcon:SetIsVisible( self.visible )
    
    --TODO Handle chambers
    
    self:ClearStatusSlot( nextSlotIdx )
    
end

--[[
Each status frame is associated to a given location, NOT a given status-slot
Frames can be moved/re-ordered to any slot at any time.
--]]
function GUIHiveStatus:UpdateStatusSlot( slotIdx, slotData )
    PROFILE("GUIHiveStatus:UpdateStatusSlot")
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( type(slotData) == "table" )
    
    if self.statusSlots[slotIdx] ~= nil then
        
        local isEmpty = 
            slotData.eggCount == 0 
            and slotData.hiveFlag == 0 
            --TODO Add chambers
        
        if isEmpty then
        --Now and Empty-Slot, test and re-order next slot if able
            if slotIdx + 1 <= GUIHiveStatus.kMaxStatusSlots then
                if not self.statusSlots[slotIdx + 1]._isEmpty then
                    self:UpdateSlotOrdering( slotIdx )
                else
                    self:ClearStatusSlot( slotIdx )
                end
            end
            return
        end
        
        --cheaper to just force visible instead of checking visibility each update
        self.statusSlots[slotIdx].background:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].frame:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].locationText:SetText( string.upper( Shared.GetString( slotData.locationId ) ) )
        self.statusSlots[slotIdx].locationText:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].locationBackground:SetIsVisible( self.visible )
        
        self.statusSlots[slotIdx].eggsIcon:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].eggsText:SetText( ToString(slotData.eggCount) )
        
        local eggIconColor = GUIHiveStatus.kEggsIconColor
        if slotData.eggInCombat and slotData.eggCount > 0 then
            eggIconColor = self:PulseIconRed( GUIHiveStatus.kEggsIconColor )
        end
        self.statusSlots[slotIdx].eggsIcon:SetColor( eggIconColor )
        
        if slotData.eggCount < self.kLowEggCountThreshold then
            self.statusSlots[slotIdx].eggsIcon:SetTexturePixelCoordinates( 260, 0, 325, 60 ) --TODO Move to local global
        else
            self.statusSlots[slotIdx].eggsIcon:SetTexturePixelCoordinates( 195, 0, 260, 60 ) --TODO Move to local global
        end
        
        self:UpdateHiveIconDisplay( 
            slotIdx, slotData.hiveFlag, slotData.hiveBuiltFraction, 
            slotData.hiveHealthScalar, slotData.hiveMaxHealth,
            slotData.hiveInCombat
        )
        
        self:UpdateCommanderIcon( slotIdx )
        
        local prevSlotIdx = slotIdx - 1
        if prevSlotIdx > 0 then
            if self.statusSlots[prevSlotIdx]._isEmpty then
                self:UpdateSlotOrdering( prevSlotIdx ) --FIXME Calling here means duplicate SetIsVisible() calls
            end
        end
        
    end
    
end

function GUIHiveStatus:Update( deltaTime ) 
    PROFILE("GUIHiveStatus:Update")
    
    local fullMode = Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Full
    self.background:SetIsVisible( fullMode and self.visible )
    if not fullMode then
        return
    end
    
    local player = Client.GetLocalPlayer()
    if player then --TODO Spectator, dead checks, etc
        if player:GetBuyMenuIsDisplaying() or player:GetIsMinimapVisible() or PlayerUI_GetIsTechMapVisible() then
            self.background:SetIsVisible( false )
            return
        else
            self.background:SetIsVisible( self.visible ) --faster to just set true, than check
        end
    end
    
    --TODO examine .updateInterval as its used in other elements instead of below
    local time = Shared.GetTime()
    if ( self.nextUpdateTime > 0 and time < self.nextUpdateTime ) or time < 2 then  --skip until update window and ignore first 2 seconds of gametime
        return
    end
    
    --TODO Examine slot-data for InCombat flags, set to "max-interval" while in combat? Or on state changes?
    self.nextUpdateTime = time + GUIHiveStatus.kUpdateRate
    
    --temp-cache locationIds, denotes if slot was created
    local slotLocations = 
    {
        self.statusSlots[1]._locationId,
        self.statusSlots[2]._locationId,
        self.statusSlots[3]._locationId,
        self.statusSlots[4]._locationId,
        self.statusSlots[5]._locationId
    }
    
    for locIdx = 1, #self.validLocations do
        
        local locationId = self.validLocations[locIdx]
        
        if locationId then
            
            local slotData = self.teamInfoEnt:GetLocationSlotData( locationId )
            
            if slotData then
                
                local emptySlotData = slotData.hiveFlag == 0 and slotData.eggCount == 0
                
                for idx, slotTbl in ipairs(self.statusSlots) do --Top-Down slot update order
                    
                    if not emptySlotData and self.statusSlots[idx]._isEmpty and not table.find( slotLocations, locationId ) then
                        self:CreateStatusContainer( idx, locationId )
                        slotLocations[idx] = locationId
                    end
                    
                    if not self.statusSlots[idx]._isEmpty and self.statusSlots[idx]._locationId == locationId then
                        self:UpdateStatusSlot( idx, slotData )
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

--[[
All Hive Status UI (per location-slot) heiarchy is as follows:
  Background (Parent of all Elements and Total UI widget bounds)
    (All Location Containers are numerically indexed array)
    - frame (background image for each slot)
    - background
      - Hive Image
      - Hive Building Background Image
      - Hive Contruction Image
      - Hive Damage Image
      - Hive Type Icon
      - Egg Count Icon
          - Egg Count Text
      - Location Text Background
        - Location Text
      - Chamber Slots (numerically indexed array)
        - Chamber Icon
          - Chamber Count Text Background
            - Chamber Count Text
      
MAX 5 Slots
 - Upwards bounds check is done that prevent 5+ slots (will not be displayed)
--]]
function GUIHiveStatus:CreateStatusContainer( slotIdx, locationId )
    PROFILE("GUIHiveStatus:CreateStatusContainer")
    
    assert( type(slotIdx) == "number" )
    assert( type(locationId) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    
    if self.statusSlots[slotIdx] == nil then
        self.statusSlots[slotIdx] = {}
    end
    
    self.statusSlots[slotIdx]._locationId = locationId
    self.statusSlots[slotIdx]._isEmpty = false
    
    --Separate background than frame so frame visibility can be toggled
    self.statusSlots[slotIdx].background = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].background:SetSize( self.kHiveContainerSize )
    self.statusSlots[slotIdx].background:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].background:SetPosition( self.kHiveContainerPositions[slotIdx] )
    self.statusSlots[slotIdx].background:SetInheritsParentScaling( true )
    self.statusSlots[slotIdx].background:SetColor( Color( 0, 0, 0, 0 ) ) --TODO Find global of this, silly to declare inline
    self.statusSlots[slotIdx].background:SetLayer( kGUILayerPlayerHUD )
    
    --Hive Status background image/frame
    self.statusSlots[slotIdx].frame = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].frame:SetSize( self.kHiveContainerSize )
    self.statusSlots[slotIdx].frame:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].frame:SetPosition( self.kHiveContainerPositions[slotIdx] )
    self.statusSlots[slotIdx].frame:SetIsVisible( false )
    self.statusSlots[slotIdx].frame:SetLayer( kGUILayerPlayerHUD )
    self.statusSlots[slotIdx].frame:SetColor( Color( 1, 1, 1, 1 ) )
    self.statusSlots[slotIdx].frame:SetTexture( kContainerBackgroundTex )
    --Vector( 380, 125, 0 ) --Texture dimensions (per slot)
    self.statusSlots[slotIdx].frame:SetTexturePixelCoordinates( --FIXME Not using class global (but must be texture-sample size)
        0, GUIHiveStatus.kContainerFrameTexOffsets[slotIdx].y, 
        380, 125 * slotIdx 
    )
    self.background:AddChild( self.statusSlots[slotIdx].frame ) --separation of frame allows it to be toggled
    
    self.statusSlots[slotIdx].hiveNormalIcon = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].hiveNormalIcon:SetSize( self.kHiveIconSize )
    self.statusSlots[slotIdx].hiveNormalIcon:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].hiveNormalIcon:SetPosition( self.kHiveIconPosition )
    self.statusSlots[slotIdx].hiveNormalIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveNormalIcon:SetLayer( kGUILayerPlayerHUDForeground1 )
    self.statusSlots[slotIdx].hiveNormalIcon:SetTexture( kHiveStatusIconsTex )
    self.statusSlots[slotIdx].hiveNormalIcon:SetTexturePixelCoordinates( 0, 0, 125, 120 ) --TODO move to local class/global
    self.statusSlots[slotIdx].hiveNormalIcon:SetColor( Color( 1, 1, 1, 1 ) )
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].hiveNormalIcon )
    
    self.statusSlots[slotIdx].hiveIconBackground = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].hiveIconBackground:SetSize( self.kHiveIconSize )
    self.statusSlots[slotIdx].hiveIconBackground:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].hiveIconBackground:SetPosition( self.kHiveIconPosition )
    self.statusSlots[slotIdx].hiveIconBackground:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveIconBackground:SetLayer( kGUILayerPlayerHUD )
    self.statusSlots[slotIdx].hiveIconBackground:SetTexture( kHiveStatusIconsTex )
    self.statusSlots[slotIdx].hiveIconBackground:SetTexturePixelCoordinates( 125, 0, 250, 120 ) --TODO move to local class/global
    self.statusSlots[slotIdx].hiveIconBackground:SetColor( Color( 1, 1, 1, 0.7 ) )
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].hiveIconBackground )
    
    self.statusSlots[slotIdx].hiveConstructedIcon = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].hiveConstructedIcon:SetSize( self.kHiveIconSize )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetPosition( self.kHiveIconPosition )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetLayer( kGUILayerPlayerHUDForeground1 )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetTexture( kHiveStatusIconsTex )
    self.statusSlots[slotIdx].hiveConstructedIcon:SetTexturePixelCoordinates( 250, 0, 375, 120 ) --TODO move to local class/global
    self.statusSlots[slotIdx].hiveConstructedIcon:SetColor( Color( 1, 1, 1, 0.85 ) )
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].hiveConstructedIcon )
    
    self.statusSlots[slotIdx].hiveDamageIcon = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].hiveDamageIcon:SetSize( self.kHiveIconSize )
    self.statusSlots[slotIdx].hiveDamageIcon:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].hiveDamageIcon:SetPosition( self.kHiveIconPosition )
    self.statusSlots[slotIdx].hiveDamageIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveDamageIcon:SetLayer( kGUILayerPlayerHUDForeground2 )
    self.statusSlots[slotIdx].hiveDamageIcon:SetColor( Color( 1, 1, 1, 1 ) )
    self.statusSlots[slotIdx].hiveDamageIcon:SetTexture( kHiveStatusIconsTex )
    self.statusSlots[slotIdx].hiveDamageIcon:SetTexturePixelCoordinates( 375, 0, 500, 120 )  --TODO move to local class/global
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].hiveDamageIcon )
    
    self.statusSlots[slotIdx].hiveTypeIcon = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].hiveTypeIcon:SetSize( self.kHiveTypeIconSize )
    self.statusSlots[slotIdx].hiveTypeIcon:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].hiveTypeIcon:SetPosition( self.kHiveTypeIconPosition )
    self.statusSlots[slotIdx].hiveTypeIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].hiveTypeIcon:SetLayer( kGUILayerPlayerHUDForeground3 )
    self.statusSlots[slotIdx].hiveTypeIcon:SetColor( Color( 1, 1, 1, 1 ) )
    self.statusSlots[slotIdx].hiveTypeIcon:SetTexture( kHiveTypesEggIconTex )
    self.statusSlots[slotIdx].hiveTypeIcon:SetTexturePixelCoordinates( 0, 0, 65, 60 )  --TODO move to local class/global
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].hiveTypeIcon )
    
    self.statusSlots[slotIdx].eggsIcon = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].eggsIcon:SetSize( self.kEggCountIconSize )
    self.statusSlots[slotIdx].eggsIcon:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].eggsIcon:SetPosition( self.kEggCountIconPosition )
    self.statusSlots[slotIdx].eggsIcon:SetIsVisible( self.visible ) --Eggs only visible on initial starting-hive (handled in Update)
    self.statusSlots[slotIdx].eggsIcon:SetLayer( kGUILayerPlayerHUDForeground1 )
    self.statusSlots[slotIdx].eggsIcon:SetColor( GUIHiveStatus.kEggsIconColor )
    self.statusSlots[slotIdx].eggsIcon:SetTexture( kHiveTypesEggIconTex )
    self.statusSlots[slotIdx].eggsIcon:SetTexturePixelCoordinates( 195, 0, 260, 60 ) --TODO Move to local global
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].eggsIcon )
    
    self.statusSlots[slotIdx].eggsText = GUIManager:CreateTextItem()
    self.statusSlots[slotIdx].eggsText:SetPosition( self.kEggCountTextPosition )
    self.statusSlots[slotIdx].eggsText:SetAnchor( GUIItem.Middle, GUIItem.Top )
    self.statusSlots[slotIdx].eggsText:SetFontName( Fonts.kAgencyFB_Large_Bold )
    self.statusSlots[slotIdx].eggsText:SetColor( GUIHiveStatus.kEggsCountFontColor )
    self.statusSlots[slotIdx].eggsText:SetScale( self.kEggTextFontScale )  --Scaled???
    self.statusSlots[slotIdx].eggsText:SetLayer( kGUILayerPlayerHUDForeground2 )
    self.statusSlots[slotIdx].eggsText:SetIsVisible( self.visible )
    self.statusSlots[slotIdx].eggsIcon:AddChild( self.statusSlots[slotIdx].eggsText )
    
    self.statusSlots[slotIdx].locationBackground = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].locationBackground:SetSize( self.kLocationBackgroundSize )
    self.statusSlots[slotIdx].locationBackground:SetPosition( self.kLocationBackgroundPosition )
    self.statusSlots[slotIdx].locationBackground:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].locationBackground:SetIsVisible( self.visible ) --Location ALWAYS visible ...?
    self.statusSlots[slotIdx].locationBackground:SetLayer( kGUILayerPlayerHUDForeground3 )
    self.statusSlots[slotIdx].locationBackground:SetColor( Color( 1, 1, 1, 1 ) )
    self.statusSlots[slotIdx].locationBackground:SetTexture( kLocationBg )
    
    self.statusSlots[slotIdx].locationText = GUIManager:CreateTextItem()
    self.statusSlots[slotIdx].locationText:SetPosition( self.kLocationTextPosition )
    self.statusSlots[slotIdx].locationText:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].locationText:SetIsVisible( self.visible ) --Location ALWAYS visible
    self.statusSlots[slotIdx].locationText:SetFontName( Fonts.kAgencyFB_Large_Bold )
    self.statusSlots[slotIdx].locationText:SetColor( GUIHiveStatus.kLocationTextColor )
    self.statusSlots[slotIdx].locationText:SetScale( self.kLocationTextFontScale ) --???? Scaled?
    self.statusSlots[slotIdx].locationText:SetLayer( kGUILayerPlayerHUDForeground4 )
    self.statusSlots[slotIdx].locationBackground:AddChild( self.statusSlots[slotIdx].locationText )
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].locationBackground )
    
    --[[
    self.statusSlots[slotIdx].chambers = {}
    self.statusSlots[slotIdx].chambers[1] = {}
    self.statusSlots[slotIdx].chambers[2] = {}
    self.statusSlots[slotIdx].chambers[3] = {}
    self.statusSlots[slotIdx].chambers[1].chamberType = kTechId.None
    self.statusSlots[slotIdx].chambers[2].chamberType = kTechId.None
    self.statusSlots[slotIdx].chambers[3].chamberType = kTechId.None
    --]]
    
    self.statusSlots[slotIdx].commanderIcon = GUIManager:CreateGraphicItem()
    self.statusSlots[slotIdx].commanderIcon:SetSize( self.kCommanderIconSize )
    self.statusSlots[slotIdx].commanderIcon:SetPosition( self.kCommanderIconPosition )
    self.statusSlots[slotIdx].commanderIcon:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.statusSlots[slotIdx].commanderIcon:SetLayer( kGUILayerPlayerHUDForeground4 )
    self.statusSlots[slotIdx].commanderIcon:SetTexture( kCommanderIcons )
    self.statusSlots[slotIdx].commanderIcon:SetTexturePixelCoordinates( 288, 0, 360, 68 ) --Defaults to Skulk --TODO Wireup in Update for Khamm Lifeform
    self.statusSlots[slotIdx].commanderIcon:SetIsVisible( false )
    self.statusSlots[slotIdx].commanderIcon:SetColor( Color( 1, 1, 1, 1 ) )
    
    self.statusSlots[slotIdx].background:AddChild( self.statusSlots[slotIdx].commanderIcon )
    self.background:AddChild( self.statusSlots[slotIdx].background )
    
end

function GUIHiveStatus:GetIsChamberSlotOfType( slotIdx, chamberSlotIdx, chamberTypeId )
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( type(chamberSlotId) == "number" )
    assert( chamberSlotId > 0 and chamberSlotId < 4 )
    
    if self.statusSlots[slotIdx].chambers[chamberSlotId] ~= nil then
    
        
    
    end
    
    return false
    
end

function GUIHiveStatus:CreateUpgradeChamberSlot( parentGUIItem, slotIdx, chamberSlotId, chamberTechId )
    PROFILE("GUIHiveStatus:CreateUpgradeChamberSlot")
    Log("GUIHiveStatus:CreateUpgradeChamberSlot()")
    
    assert( type(chamberSlotId) == "number" )
    assert( chamberSlotId > 0 and chamberSlotId < 4 )
    
    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( parentGUIItem ~= nil )
    
    if self.statusSlots[slotIdx].chambers[chamberSlotId] == nil then
        self.statusSlots[slotIdx].chambers[chamberSlotId] = {}
    end
    
    self.statusSlots[slotIdx].chambers[chamberSlotId].chamberType = chamberTechId
    
    self.statusSlots[slotIdx].chambers[chamberSlotId].chamberIcon = GUIManager:CreateGraphicItem()
    chamberIcon:SetSize( GUIHiveStatus.kUpgradeChamberSize )
    chamberIcon:SetPosition( GUIHiveStatus.kUpgradeChamberPositions[chamberSlotId] )
    chamberIcon:SetAnchor( GUIItem.Center, GUIItem.Middle )
    chamberIcon:SetTexture( kUpgradesIconTex )
    
    if chamberTechId == kTechId.Shell then
        chamberIcon:SetTexturePixelCoordinates( 0, 0, 80, 80 )
    elseif chamberSlotId == kTechId.Veil then
        chamberIcon:SetTexturePixelCoordinates( 0, 160, 80, 240 )
    elseif chamberSlotId == kTechId.Spur then
        chamberIcon:SetTexturePixelCoordinates( 0, 80, 80, 160 )
    end
    
    chamberIcon:SetIsVisible( false )
    chamberIcon:SetColor( Color( 1, 1, 1, 0.75 ) )
    self.statusSlots[slotIdx].chambers[chamberSlotId].chamberIcon = chamberIcon
    
    self.statusSlots[slotIdx].chambers[chamberSlotId].countText = GUIManager:CreateTextItem()
    countText:SetPosition( GUIHiveStatus.kUpgradeChamberTextPosition )
    countText:SetAnchor( GUIItem.Center, GUIItem.Middle )
    countText:SetFontName( Fonts.kAgencyFB_Tiny )
    countText:SetColor( GUIHiveStatus.kUpgradesCountTextColor )
    countText:SetIsVisible( false )
    self.statusSlots[slotIdx].chambers[chamberSlotId].countText = countText
    
    self.statusSlots[slotIdx].chambers[chamberSlotId].textBg = GUIManager:CreateGraphicItem()
    textBg:SetSize( GUIHiveStatus.kUpgradeChamberTextBgSize )
    textBg:SetPosition( GUIHiveStatus.kUpgradeChamberTextBgPosition )
    textBg:SetAnchor( GUIItem.Center, GUIItem.Middle )
    textBg:SetTexture( kHiveTypesEggIconTex )
    textBg:SetTexturePixelCoordinates( 325, 0, 385, 60 ) --TODO Move to local global
    textBg:SetIsVisible( false )
    textBg:SetColor( Color( 1, 1, 1, 0.8 ) )
    
    textBg:AddChild( countText )
    chamberIcon:AddChild( textBg )
    parentGUIItem:AddChild( chamberIcon )
    
end
