// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineTechMap.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// Formatted marine tech tree.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

kMarineTechMapYStart = 2
kMarineTechMap =
{

        { kTechId.Extractor, 5, 1 },{ kTechId.CommandStation, 7, 1 },{ kTechId.InfantryPortal, 9, 1 },
        
        { kTechId.TurretFactory, 9, 3 },{ kTechId.UpgradeTurretFactory, 10, 2 },{ kTechId.SiegeCannon, 11, 2 },
                                          { kTechId.Sentry, 11, 4 },
                                          
                                          
        { kTechId.HandGrenadesTech, 2, 3 },{ kTechId.Mines, 3, 3 },{ kTechId.Shotgun, 4, 3 },{ kTechId.Welder, 5, 3 },
        
        { kTechId.Armory, 3.5, 4 }, 
         
        { kTechId.AdvancedArmory, 3.5, 5.5 },
        
        { kTechId.PrototypeLab, 3.5, 7 },

        { kTechId.HeavyArmorTech, 3, 8 },{ kTechId.JetpackTech, 4, 8 }, 
        
        
        { kTechId.ArmsLab, 9, 7 },{ kTechId.Weapons1, 10, 6.5 },{ kTechId.Weapons2, 11, 6.5 },{ kTechId.Weapons3, 12, 6.5 },
                                  { kTechId.Armor1, 10, 7.5 },{ kTechId.Armor2, 11, 7.5 },{ kTechId.Armor3, 12, 7.5 },
                                  
                                  
        { kTechId.CatPackTech, 8, 5.5 },

        { kTechId.Observatory, 6, 5 },{ kTechId.PhaseTech, 6, 6 },{ kTechId.PhaseGate, 6, 7 },{ kTechId.MotionTracking, 6, 8 },
                 

}

kMarineLines = 
{
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.Extractor),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.CommandStation, kTechId.InfantryPortal),
    
    { 7, 1, 7, 7 },
    { 7, 4, 3.5, 4 },
    // observatory:
    { 6, 5, 7, 5 },
    { 7, 7, 9, 7 },
    // nano shield:
    { 7, 4.5, 8, 4.5},
    // cat pack tech:
    { 7, 5.5, 8, 5.5},
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.HandGrenadesTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Mines),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Shotgun),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.Welder),

    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armory, kTechId.AdvancedArmory),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.HeavyMachineGun),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedArmory, kTechId.GrenadeLauncher),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.HeavyArmorTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PrototypeLab, kTechId.JetpackTech),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.PhaseTech),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Observatory, kTechId.MotionTracking),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.PhaseTech, kTechId.PhaseGate),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Weapons1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons1, kTechId.Weapons2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Weapons2, kTechId.Weapons3),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.Armor1),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor1, kTechId.Armor2),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.Armor2, kTechId.Armor3),
    
    GetLinePositionForTechMap(kMarineTechMap, kTechId.ArmsLab, kTechId.CatPackTech),
    
    { 7, 3, 9, 3 },
    GetLinePositionForTechMap(kMarineTechMap, kTechId.TurretFactory, kTechId.AdvancedTurretFactory),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.AdvancedTurretFactory, kTechId.SiegeCannon),
    GetLinePositionForTechMap(kMarineTechMap, kTechId.TurretFactory, kTechId.Sentry),
    
}