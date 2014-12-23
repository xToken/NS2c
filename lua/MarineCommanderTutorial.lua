// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommanderTutorial.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommanderTutorialUtility.lua")
local Resolve = Locale.ResolveString

local buildArmory = Resolve("COMMANDER_TUT_BUILD_ARMORY")
local buildArmorySteps = 
{
    { CompletionFunc = GetHasMenuSelected(kTechId.BuildMenu), HighlightButton = kTechId.BuildMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.Armory), HighlightButton = kTechId.Armory, HighlightWorld = GetPlaceForUnit(kTechId.Armory, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kArmoryCost, kMarineTeamType, buildArmory, buildArmorySteps)


local dropMedPack =  Resolve("COMMANDER_TUT_DROP_MEDPACK")
local dropMedPackSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AssistMenu), HighlightButton = kTechId.AssistMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.MedPack), HighlightButton = kTechId.MedPack, UpdateHighlightWorld = GetWoundedMarinePosition },
}
AddCommanderTutorialEntry(kMedPackCost, kMarineTeamType, dropMedPack, dropMedPackSteps, nil, GetHasWoundedMarine, nil, nil, 7)



local dropAmmoPack = Resolve("COMMANDER_TUT_DROP_AMMOPACK")
local dropAmmoPackSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AssistMenu), HighlightButton = kTechId.AssistMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.AmmoPack), HighlightButton = kTechId.AmmoPack, UpdateHighlightWorld = GetMarineLowOnAmmoPosition },
}
AddCommanderTutorialEntry(kAmmoPackCost, kMarineTeamType, dropAmmoPack, dropAmmoPackSteps, nil, GetHasMarineLowOnAmmo, nil, nil, 7)



local buildExtractor = Resolve("COMMANDER_TUT_BUILD_EXTRACTOR")
local buildExtractorSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.BuildMenu), HighlightButton = kTechId.BuildMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.Extractor), HighlightButton = kTechId.Extractor, HighlightWorld = GetClosestFreeResourcePoint },
}
AddCommanderTutorialEntry(kExtractorCost, kMarineTeamType, buildExtractor, buildExtractorSteps)


local orderTroops = Resolve("COMMANDER_TUT_ORDER_TROOPS")
local orderTroopsStep = 
{
    { CompletionFunc = GetHasUnitSelected(kTechId.Marine) },
    { CompletionFunc = GetSelectionHasOrder(kTechId.Construct), HighlightButton = kTechId.Construct },
}
AddCommanderTutorialEntry(0, kMarineTeamType, orderTroops, orderTroopsStep, nil, GetHasUnbuiltStructure(), nil, nil, 7)



local buildArmslab = Resolve("COMMANDER_TUT_BUILD_ARMS_LAB")
local buildArmslabSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.BuildMenu), HighlightButton = kTechId.BuildMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.ArmsLab), HighlightButton = kTechId.ArmsLab, HighlightWorld = GetPlaceForUnit(kTechId.ArmsLab, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kArmsLabCost, kMarineTeamType, buildArmslab, buildArmslabSteps, nil, TutorialNotHasTech(kTechId.ArmsLab), nil)



local upgradeAtArmsLab = Resolve("COMMANDER_TUT_UPGRADE_AT_ARMS_LAB")
local upgradeAtArmsLabStep = 
{
    { CompletionFunc = GetHasUnitSelected(kTechId.ArmsLab), HighlightWorld = GetUnitPosition(kTechId.ArmsLab) },
    { CompletionFunc = GetHasTechUsed({kTechId.Armor1, kTechId.Weapons1}), HighlightButton = {kTechId.Armor1, kTechId.Weapons1} },
}
AddCommanderTutorialEntry(kWeapons1ResearchCost, kMarineTeamType, upgradeAtArmsLab, upgradeAtArmsLabStep, nil, {TutorialNotHasTech(kTechId.Armor1), TutorialNotHasTech(kTechId.Weapons1), TutorialGetHasTech(kTechId.ArmsLab)})


local viewTechMap = Resolve("COMMANDER_TUT_VIEW_TECH")
local viewTechMapSteps =
{
    { CompletionFunc = PlayerUI_GetIsTechMapVisible }
}
AddCommanderTutorialEntry(0, kMarineTeamType, viewTechMap, viewTechMapSteps)


local buildObs = Resolve("COMMANDER_TUT_BUILD_OBS")
local buildObsSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton = kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.Observatory), HighlightButton =  kTechId.Observatory, HighlightWorld = GetPlaceForUnit(kTechId.ArmsLab, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kObservatoryCost, kMarineTeamType, buildObs, buildObsSteps, nil, TutorialNotHasTech(kTechId.Observatory), nil)


local researchPhaseTech = Resolve("COMMANDER_TUT_RESEARCH_PHASE_TECH")
local researchPhaseTechSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.Observatory), HighlightWorld = GetUnitPosition(kTechId.Observatory) },
    { CompletionFunc = GetHasTechUsed(kTechId.PhaseTech), HighlightButton =  kTechId.PhaseTech },
}
AddCommanderTutorialEntry(kPhaseTechResearchCost, kMarineTeamType, researchPhaseTech, researchPhaseTechSteps, nil, {TutorialNotHasTech(kTechId.PhaseTech), TutorialGetHasTech(kTechId.Observatory)})


local buildPhaseGate = Resolve("COMMANDER_TUT_BUILD_PHASE_GATE")
local buildPhaseGateSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton =  kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.PhaseGate), HighlightButton =  kTechId.PhaseGate, HighlightWorld = GetPlaceForUnit(kTechId.PhaseGate, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kPhaseGateCost, kMarineTeamType, buildPhaseGate, buildPhaseGateSteps, nil, {TutorialNotHasTech(kTechId.PhaseGate), TutorialGetHasTech(kTechId.PhaseTech)})


local buildSecondGate = Resolve("COMMANDER_TUT_BUILD_SECOND_PHASE_GATE")
local buildSecondGateSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton =  kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.PhaseGate), HighlightButton =  kTechId.PhaseGate, HighlightWorld = GetPlaceForUnit(kTechId.PhaseGate, GetClosestFreeTechPoint) },
}
AddCommanderTutorialEntry(kPhaseGateCost, kMarineTeamType, buildSecondGate, buildSecondGateSteps, nil, {NotHasUnitCount("PhaseGate", 2), TutorialGetHasTech(kTechId.PhaseTech)})


local upgradeArmory = Resolve("COMMANDER_TUT_UPGRADE_ARMORY")
local upgradeArmorySteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.Armory), HighlightWorld = GetUnitPosition(kTechId.Armory) },
    { CompletionFunc = GetHasTechUsed(kTechId.AdvancedArmoryUpgrade), HighlightButton = kTechId.AdvancedArmoryUpgrade },
}
AddCommanderTutorialEntry(kAdvancedArmoryUpgradeCost, kMarineTeamType, upgradeArmory, upgradeArmorySteps, nil, GetHasUnitIsNotResearching(kTechId.Armory), "ADV_ARMORY")



local armorUpgradeReminder = Resolve("COMMANDER_TUT_UPGRADE_ARMOR_TWO")
local armorUpgradeReminderSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.ArmsLab), HighlightWorld = GetUnitPosition(kTechId.ArmsLab) },
    { CompletionFunc = GetHasTechUsed(kTechId.Armor2), HighlightButton = kTechId.Armor2 },
}
AddCommanderTutorialEntry(kArmor2ResearchCost, kMarineTeamType, armorUpgradeReminder, armorUpgradeReminderSteps, nil, TutorialGetIsTechAvailable(kTechId.Armor2))



local weaponUpgradeReminder = Resolve("COMMANDER_TUT_UPGRADE_WEAPON_TWO")
local weaponUpgradeReminderSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.ArmsLab), HighlightWorld = GetUnitPosition(kTechId.ArmsLab) },
    { CompletionFunc = GetHasTechUsed(kTechId.Weapons2), HighlightButton = kTechId.Weapons2 },
}
AddCommanderTutorialEntry(kWeapons2ResearchCost, kMarineTeamType, weaponUpgradeReminder, weaponUpgradeReminderSteps, nil, TutorialGetIsTechAvailable(kTechId.Weapons2))



local experimentalTech = Resolve("COMMANDER_TUT_BUILD_PROTO")
local experimentalTechSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton = kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.PrototypeLab), HighlightButton = kTechId.PrototypeLab, HighlightWorld = GetPlaceForUnit(kTechId.PrototypeLab, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kPrototypeLabCost, kMarineTeamType, experimentalTech, experimentalTechSteps, nil, TutorialGetHasTech(kTechId.AdvancedArmory))


local upgradeJetpack = Resolve("COMMANDER_TUT_UPGRADE_JETPACK")
local upgradeJetpackSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.PrototypeLab), HighlightWorld = GetUnitPosition(kTechId.PrototypeLab) },
    { CompletionFunc = GetHasTechUsed(kTechId.JetpackTech), HighlightButton = kTechId.JetpackTech },
}
AddCommanderTutorialEntry(kJetpackCost, kMarineTeamType, upgradeJetpack, upgradeJetpackSteps, nil, {TutorialNotHasTech(kTechId.JetpackTech), TutorialGetHasTech(kTechId.PrototypeLab)})



