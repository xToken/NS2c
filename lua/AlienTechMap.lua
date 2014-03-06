// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienTechMap.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// Formatted alien tech tree.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

kAlienTechMapYStart = 1

kAlienTechMap =
{

                    { kTechId.Harvester, 4, 0 },                           //{ kTechId.Hive, 7, 0 },{ kTechId.ResearchBioMassOne, 9, 0 },{ kTechId.ResearchBioMassTwo, 10, 0, UpdateBioMassText, ""},
  
                   //{ kTechId.CragHive, 4, 3 },                               { kTechId.ShadeHive, 7, 3 },                            { kTechId.ShiftHive, 10, 3 },
              //{ kTechId.Shell, 4, 4, SetShellIcon },                     { kTechId.Veil, 7, 4, SetVeilIcon },                    { kTechId.Spur, 10, 4, SetSpurIcon },
  //{ kTechId.Carapace, 3.5, 5 },{ kTechId.Regeneration, 4.5, 5 }, { kTechId.Phantom, 6.5, 5 },{ kTechId.Aura, 7.5, 5 },{ kTechId.Celerity, 9.5, 5 },{ kTechId.Adrenaline, 10.5, 5 },
  
  //{kTechId.UpgradeGorge, 5, 1},{kTechId.GorgeTunnelTech, 8, 1},
  //{kTechId.BabblerEgg, 4, 2},{kTechId.BileBomb, 5, 2, nil, "3"},{kTechId.Web, 6, 2, nil, "7"},
  
  //{kTechId.Drifter, 8, 2},

  //{kTechId.Whip, 4, 6}, 
  //{kTechId.UpgradeSkulk, 4, 7},                                                            
  //{kTechId.Leap, 3.5, 8, nil, "4"}, {kTechId.Xenocide, 4.5, 8, nil, "7"},         
  
  //{kTechId.Crag, 10, 6}, 
  //{kTechId.UpgradeOnos, 10, 7},   
  //{kTechId.Charge, 9, 8, nil, "3"},{kTechId.Devour, 10, 8, nil, "5"}, {kTechId.Stomp, 11, 8, nil, "9"},
  
  //{kTechId.Shift, 4, 9},    
  //{kTechId.UpgradeLerk, 4, 10},                                 
  //{kTechId.Umbra, 3.5, 11, nil, "4"},{kTechId.Spores, 4.5, 11, nil, "6"},
   
  //{kTechId.Shade, 10, 9},
  //{kTechId.UpgradeFade, 10, 10},
  //{kTechId.ShadowStep, 9, 11, nil, "2"},{kTechId.Vortex, 10, 11, nil, "5"},{kTechId.Stab, 11, 11, nil, "8"},
}

kAlienLines = 
{
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Harvester, kTechId.Hive),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.ResearchBioMassOne),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.ResearchBioMassOne, kTechId.ResearchBioMassTwo),
    { 7, 0, 7, 2.5 },
    { 4, 2.5, 10, 2.5},
    { 4, 2.5, 4, 3},{ 7, 2.5, 7, 3},{ 10, 2.5, 10, 3},
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.Shell),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.Veil),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.Spur),
    
    { 7, 2, 8, 2 },
 
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeGorge, kTechId.GorgeTunnelTech),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeGorge, kTechId.BabblerEgg),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeGorge, kTechId.BileBomb),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeGorge, kTechId.Web),
    
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Carapace),GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Regeneration),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Phantom),GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Aura),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Celerity),GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Adrenaline),
    
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Whip, kTechId.UpgradeSkulk),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeSkulk, kTechId.Leap),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeSkulk, kTechId.Xenocide),

    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Crag, kTechId.UpgradeOnos),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeOnos, kTechId.Charge),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeOnos, kTechId.Devour),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeOnos, kTechId.Stomp),

    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Shift, kTechId.UpgradeLerk),  
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeLerk, kTechId.Umbra),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeLerk, kTechId.Spores),

    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Shade, kTechId.UpgradeFade),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeFade, kTechId.ShadowStep),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeFade, kTechId.Vortex),
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.UpgradeFade, kTechId.Stab),

}





