// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTreeButtons.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Hard-coded data which maps tech tree constants to indices into a texture. Used to display
// icons in the commander build menu and alien buy menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// These are the icons that appear next to alerts or as hotkey icons.
// Icon size should be 20x20. Also used for the alien buy menu.
function CommanderUI_Icons()

    local player = Client.GetLocalPlayer()
    if(player and (player:isa("Alien") or player:isa("AlienCommander"))) then
        return "alien_upgradeicons"
    end
    
    return "marine_upgradeicons"

end

function CommanderUI_MenuImageSize()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return 640, 1040
    end
    
    return 960, 960
    
end

// Init icon offsets
kTechIdToMaterialOffset = {}

function InitTechTreeMaterialOffsets()

    // Init icon offsets
    kTechIdToMaterialOffset = {}
    
    // Resource Points
    kTechIdToMaterialOffset[kTechId.ResourcePoint] = 89
    kTechIdToMaterialOffset[kTechId.ResourcePoint] = 0

    // First row
    kTechIdToMaterialOffset[kTechId.CommandStation] = 0
    
    kTechIdToMaterialOffset[kTechId.Armory] = 1
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing extractor
    kTechIdToMaterialOffset[kTechId.Extractor] = 3
    kTechIdToMaterialOffset[kTechId.InfantryPortal] = 4
    kTechIdToMaterialOffset[kTechId.Sentry] = 5
    
    kTechIdToMaterialOffset[kTechId.RoboticsFactory] = 6    
    kTechIdToMaterialOffset[kTechId.UpgradeRoboticsFactory] = 6
    kTechIdToMaterialOffset[kTechId.ARCRoboticsFactory] = 6
    
    kTechIdToMaterialOffset[kTechId.Observatory] = 7
    // TODO: Change this
    kTechIdToMaterialOffset[kTechId.ArmsLab] = 11
    
    // Second row - Non-player orders
    kTechIdToMaterialOffset[kTechId.Recycle] = 12
    kTechIdToMaterialOffset[kTechId.Move] = 13
    kTechIdToMaterialOffset[kTechId.Stop] = 14
    kTechIdToMaterialOffset[kTechId.RootMenu] = 15
    kTechIdToMaterialOffset[kTechId.Cancel] = 16
    kTechIdToMaterialOffset[kTechId.Construct] = 22
    
    //kTechIdToMaterialOffset[kTechId.] = 17 // MAC build
    
    kTechIdToMaterialOffset[kTechId.Attack] = 18
    kTechIdToMaterialOffset[kTechId.SetRally] = 19
    kTechIdToMaterialOffset[kTechId.SetTarget] = 28
    kTechIdToMaterialOffset[kTechId.Weld] = 21
    kTechIdToMaterialOffset[kTechId.BuildMenu] = 22
    kTechIdToMaterialOffset[kTechId.AdvancedMenu] = 23    
    
    kTechIdToMaterialOffset[kTechId.MarineAlertOrderComplete] = 60

    kTechIdToMaterialOffset[kTechId.Defend] = 27

    kTechIdToMaterialOffset[kTechId.AssistMenu] = 33
    kTechIdToMaterialOffset[kTechId.WeaponsMenu] = 55
    
    // Fourth row - droppables, research
    kTechIdToMaterialOffset[kTechId.AmmoPack] = 36
    kTechIdToMaterialOffset[kTechId.MedPack] = 37
    kTechIdToMaterialOffset[kTechId.JetpackTech] = 40
    kTechIdToMaterialOffset[kTechId.Jetpack] = 40
    kTechIdToMaterialOffset[kTechId.Scan] = 41
    kTechIdToMaterialOffset[kTechId.ARC] = 44
    kTechIdToMaterialOffset[kTechId.CatPack] = 45
    kTechIdToMaterialOffset[kTechId.CatPackTech] = 45
    
    // Fifth row 
    kTechIdToMaterialOffset[kTechId.Shotgun] = 48
    kTechIdToMaterialOffset[kTechId.Armor1] = 49
    kTechIdToMaterialOffset[kTechId.Armor2] = 50
    kTechIdToMaterialOffset[kTechId.Armor3] = 51
        
    // upgrades
    kTechIdToMaterialOffset[kTechId.Weapons1] = 55
    kTechIdToMaterialOffset[kTechId.Weapons2] = 56
    kTechIdToMaterialOffset[kTechId.Weapons3] = 57
    
    kTechIdToMaterialOffset[kTechId.Marine] = 60
    kTechIdToMaterialOffset[kTechId.JetpackMarine] = 60
    kTechIdToMaterialOffset[kTechId.HeavyArmorMarine] = 61
    kTechIdToMaterialOffset[kTechId.DistressBeacon] = 63
    kTechIdToMaterialOffset[kTechId.AdvancedArmory] = 65
    kTechIdToMaterialOffset[kTechId.AdvancedArmoryUpgrade] = 65
    kTechIdToMaterialOffset[kTechId.PhaseGate] = 67
    kTechIdToMaterialOffset[kTechId.PhaseTech] = 68
    kTechIdToMaterialOffset[kTechId.MotionTracking] = 10

    kTechIdToMaterialOffset[kTechId.GrenadeLauncher] = 72
    kTechIdToMaterialOffset[kTechId.HeavyArmorTech] = 75
    kTechIdToMaterialOffset[kTechId.HeavyArmor] = 76
    kTechIdToMaterialOffset[kTechId.Mine] = 8
    kTechIdToMaterialOffset[kTechId.Mines] = 8
    kTechIdToMaterialOffset[kTechId.Welder] = 17
    kTechIdToMaterialOffset[kTechId.HeavyMachineGun] = 47
    kTechIdToMaterialOffset[kTechId.HandGrenadesTech] = 46
    kTechIdToMaterialOffset[kTechId.HandGrenades] = 46
    kTechIdToMaterialOffset[kTechId.Electrify] = 9
    
    // Doors
    kTechIdToMaterialOffset[kTechId.Door] = 84
    kTechIdToMaterialOffset[kTechId.DoorOpen] = 85
    kTechIdToMaterialOffset[kTechId.DoorClose] = 86
    kTechIdToMaterialOffset[kTechId.DoorLock] = 87
    kTechIdToMaterialOffset[kTechId.DoorUnlock] = 88
    // 89 = nozzle
    // 90 = tech point
    
    kTechIdToMaterialOffset[kTechId.PrototypeLab] = 94
    
    // Generic orders 
    kTechIdToMaterialOffset[kTechId.Default] = 0
    kTechIdToMaterialOffset[kTechId.Move] = 1
    kTechIdToMaterialOffset[kTechId.Attack] = 2
    kTechIdToMaterialOffset[kTechId.Build] = 3
    kTechIdToMaterialOffset[kTechId.Construct] = 8
    kTechIdToMaterialOffset[kTechId.Stop] = 5
    kTechIdToMaterialOffset[kTechId.SetRally] = 6
    kTechIdToMaterialOffset[kTechId.SetTarget] = 7
    
    // Menus
    kTechIdToMaterialOffset[kTechId.RootMenu] = 21
    kTechIdToMaterialOffset[kTechId.BuildMenu] = 8
    kTechIdToMaterialOffset[kTechId.AdvancedMenu] = 9
    kTechIdToMaterialOffset[kTechId.AssistMenu] = 10
    kTechIdToMaterialOffset[kTechId.MarkersMenu] = 14
    kTechIdToMaterialOffset[kTechId.UpgradesMenu] = 12
    kTechIdToMaterialOffset[kTechId.Cancel] = 5
           
    // Lifeforms
    kTechIdToMaterialOffset[kTechId.Skulk] = 16
    kTechIdToMaterialOffset[kTechId.Gorge] = 17
    kTechIdToMaterialOffset[kTechId.Lerk] = 18
    kTechIdToMaterialOffset[kTechId.Fade] = 19
    kTechIdToMaterialOffset[kTechId.Onos] = 20
    
    // Structures
    kTechIdToMaterialOffset[kTechId.Hive] = 24
    kTechIdToMaterialOffset[kTechId.CragHive] = 40
    kTechIdToMaterialOffset[kTechId.ShadeHive] = 64
    kTechIdToMaterialOffset[kTechId.ShiftHive] = 56
    kTechIdToMaterialOffset[kTechId.WhipHive] = 48
    
    kTechIdToMaterialOffset[kTechId.UpgradeToCragHive] = 40
    kTechIdToMaterialOffset[kTechId.UpgradeToShadeHive] = 64
    kTechIdToMaterialOffset[kTechId.UpgradeToShiftHive] = 56
    kTechIdToMaterialOffset[kTechId.UpgradeToWhipHive] = 48
    
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing harvester
    kTechIdToMaterialOffset[kTechId.Harvester] = 27
    kTechIdToMaterialOffset[kTechId.Egg] = 30
    
    // Doors
    // $AS - Aliens can select doors if an onos can potential break a door
    // the alien commander should be able to see its health I would think
    // we do not have any art for doors on aliens so we once again use the
    // question mark 
    kTechIdToMaterialOffset[kTechId.Door] = 22
    kTechIdToMaterialOffset[kTechId.DoorOpen] =22
    kTechIdToMaterialOffset[kTechId.DoorClose] = 22
    kTechIdToMaterialOffset[kTechId.DoorLock] = 22
    kTechIdToMaterialOffset[kTechId.DoorUnlock] = 22
    
    // upgradeable alien abilities
    kTechIdToMaterialOffset[kTechId.Leap] = 105
    kTechIdToMaterialOffset[kTechId.BileBomb] = 107
    kTechIdToMaterialOffset[kTechId.Umbra] = 114
    kTechIdToMaterialOffset[kTechId.Metabolize] = 110
    kTechIdToMaterialOffset[kTechId.Stomp] = 111
    
    kTechIdToMaterialOffset[kTechId.Xenocide] = 108
    kTechIdToMaterialOffset[kTechId.Web] = 112
    kTechIdToMaterialOffset[kTechId.PrimalScream] = 20
    kTechIdToMaterialOffset[kTechId.Spikes] = 114
    kTechIdToMaterialOffset[kTechId.AcidRocket] = 113
    kTechIdToMaterialOffset[kTechId.Smash] = 111
    kTechIdToMaterialOffset[kTechId.Charge] = 111
      
    //Chambers
    kTechIdToMaterialOffset[kTechId.Crag] = 40
    kTechIdToMaterialOffset[kTechId.Shift] = 56
    kTechIdToMaterialOffset[kTechId.Shade] = 64
    kTechIdToMaterialOffset[kTechId.Whip] = 48
        
    kTechIdToMaterialOffset[kTechId.Adrenaline] = 83
    kTechIdToMaterialOffset[kTechId.Celerity] = 84
    kTechIdToMaterialOffset[kTechId.Redeployment] = 56
    
    kTechIdToMaterialOffset[kTechId.Silence] = 85
    kTechIdToMaterialOffset[kTechId.Ghost] = 86
    kTechIdToMaterialOffset[kTechId.Aura] = 60
    
    kTechIdToMaterialOffset[kTechId.Carapace] = 81
    kTechIdToMaterialOffset[kTechId.Regeneration] = 82
    kTechIdToMaterialOffset[kTechId.Redemption] = 87
    
    kTechIdToMaterialOffset[kTechId.Focus] = 80
    kTechIdToMaterialOffset[kTechId.Fury] = 104
    kTechIdToMaterialOffset[kTechId.Bombard] = 53
    
    //Hydra
    kTechIdToMaterialOffset[kTechId.Hydra] = 88
    
end

function GetMaterialXYOffset(techId)

    local index = nil
    
    local columns = 12
    index = kTechIdToMaterialOffset[techId]
    
    if index == nil then
        Print("Warning: %s did not define kTechIdToMaterialOffset ", EnumToString(kTechId, techId) )
    end

    if(index ~= nil) then
    
        local x = index % columns
        local y = math.floor(index / columns)
        return x, y
        
    end
    
    return nil, nil
    
end

function GetPixelCoordsForIcon(entityId, forMarine)

    local ent = Shared.GetEntity(entityId)
    
    if (ent ~= nil and ent:isa("ScriptActor")) then
    
        local techId = ent:GetTechId()
        
        if (techId ~= kTechId.None) then
            
            local xOffset, yOffset = GetMaterialXYOffset(techId, forMarine)
            
            return {xOffset, yOffset}
            
        end
                    
    end
    
    return nil
    
end
