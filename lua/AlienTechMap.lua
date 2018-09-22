-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\AlienTechMap.lua
--
-- Created by: Andreas Urwalek (and@unknownworlds.com)
--
-- Formatted alien tech tree.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

kAlienTechMapYStart = 1

kAlienTechMap =
{

                    { kTechId.Harvester, 4, 0 },   { kTechId.Hydra, 8, 0 },
  
                   { kTechId.CragHive, 4, 3 },        { kTechId.ShadeHive, 6, 3 },        { kTechId.ShiftHive, 8, 3 },     { kTechId.WhipHive, 10, 3 },
                     { kTechId.Crag, 4, 4 },            { kTechId.Shade, 6, 4 },            { kTechId.Shift, 8, 4 },         { kTechId.Whip, 10, 4 },
    { kTechId.Carapace, 2.5, 5 },   { kTechId.Regeneration, 3.25, 5 },  { kTechId.Redemption, 4, 5 },
    { kTechId.Silence, 5, 5 },      { kTechId.Ghost, 5.75, 5 },         { kTechId.Aura, 6.5, 5 },
    { kTechId.Celerity, 7.5, 5 },   { kTechId.Adrenaline, 8.25, 5 },    { kTechId.Redeployment, 9, 5 },
    { kTechId.Focus, 10, 5 },       { kTechId.Fury, 10.75, 5 },         { kTechId.Bombard, 11.5, 5 },
  

    {kTechId.TwoHives, 6, 7},
                                                            
    {kTechId.Leap, 3.5, 8}, 
    {kTechId.BileBomb, 5, 8},
    {kTechId.Umbra, 6.5, 8},
    {kTechId.Metabolize, 8, 8},
    {kTechId.Stomp, 9.5, 8},
    
    {kTechId.ThreeHives, 6, 9},
    
    {kTechId.Xenocide, 3.5, 10}, 
    {kTechId.Web, 4.5, 10},
    {kTechId.BabblerEgg, 5.5, 10},
    {kTechId.PrimalScream, 6.5, 10},
    {kTechId.AcidRocket, 7.5, 10},
    {kTechId.Devour, 8.5, 10},
    {kTechId.Charge, 9.5, 10},
}

kAlienLines = 
{
    //GetLinePositionForTechMap(kAlienTechMap, kTechId.Harvester, kTechId.Hive),

    { 7, 0, 7, 2.5 },
    { 4, 2.5, 10, 2.5},
    { 4, 2.5, 4, 3},{ 7, 2.5, 7, 3},{ 10, 2.5, 10, 3},
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.Crag),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.Shade),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.Shift),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.WhipHive, kTechId.Whip),
    
    { 7, 2, 8, 2 },
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Crag, kTechId.Carapace),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Crag, kTechId.Regeneration),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Crag, kTechId.Redemption),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shade, kTechId.Silence),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shade, kTechId.Ghost),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shade, kTechId.Aura),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shift, kTechId.Celerity),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shift, kTechId.Adrenaline),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shift, kTechId.Redeployment),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Whip, kTechId.Focus),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Whip, kTechId.Fury),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Whip, kTechId.Bombard),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.TwoHives, kTechId.Leap),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.TwoHives, kTechId.BileBomb),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.TwoHives, kTechId.Umbra),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.TwoHives, kTechId.Metabolize),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.TwoHives, kTechId.Stomp),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.Xenocide),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.Web),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.BabblerEgg),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.PrimalScream),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.AcidRocket),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.Devour),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ThreeHives, kTechId.Charge),

}