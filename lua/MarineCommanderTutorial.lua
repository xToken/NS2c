// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommanderTutorial.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommanderTutorialUtility.lua")

local buildArmory = "One of the most important tasks as marine commander is to support your troops. Select the build menu [1:BuildMenu] and build an Armory [2:Armory] in your base. From this structure, your marines will be able to obtain ammo and heal themselve."
local buildArmorySteps = 
{
    { CompletionFunc = GetHasMenuSelected(kTechId.BuildMenu), HighlightButton = kTechId.BuildMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.Armory), HighlightButton = kTechId.Armory, HighlightWorld = GetPlaceForUnit(kTechId.Armory, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kArmoryCost, kMarineTeamType, buildArmory, buildArmorySteps)


local dropMedPack = "You directly supply your Marines by dropping packs they can pick up. Select the assist menu [1:AssistMenu] and drop a medpack [2:MedPack] to heal wounded marines."
local dropMedPackSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AssistMenu), HighlightButton = kTechId.AssistMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.MedPack), HighlightButton = kTechId.MedPack, UpdateHighlightWorld = GetWoundedMarinePosition },
}
AddCommanderTutorialEntry(kMedPackCost, kMarineTeamType, dropMedPack, dropMedPackSteps, nil, GetHasWoundedMarine, nil, nil, 7)



local dropAmmoPack = "You directly supply your Marines by dropping packs they can pick up. Select the assist menu [1:AssistMenu] and drop an ammopack [2:AmmoPack] to provide ammunition."
local dropAmmoPackSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AssistMenu), HighlightButton = kTechId.AssistMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.AmmoPack), HighlightButton = kTechId.AmmoPack, UpdateHighlightWorld = GetMarineLowOnAmmoPosition },
}
AddCommanderTutorialEntry(kAmmoPackCost, kMarineTeamType, dropAmmoPack, dropAmmoPackSteps, nil, GetHasMarineLowOnAmmo, nil, nil, 7)



local buildExtractor = "You need a higher resource [CollectResources] income. Select the build menu [1:BuildMenu] and build an Extractor [2:Extractor] at the closes resource node."
local buildExtractorSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.BuildMenu), HighlightButton = kTechId.BuildMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.Extractor), HighlightButton = kTechId.Extractor, HighlightWorld = GetClosestFreeResourcePoint },
}
AddCommanderTutorialEntry(kExtractorCost, kMarineTeamType, buildExtractor, buildExtractorSteps)


local orderTroops = "Order your marines to build the structures you just dropped. To select all marines, click on the item at the top left [1:Marine]. Then right click on an unbuilt structure to give them a build order [2:Construct] "
local orderTroopsStep = 
{
    { CompletionFunc = GetHasUnitSelected(kTechId.Marine) },
    { CompletionFunc = GetSelectionHasOrder(kTechId.Construct), HighlightButton = kTechId.Construct },
}
AddCommanderTutorialEntry(0, kMarineTeamType, orderTroops, orderTroopsStep, nil, GetHasUnbuiltStructure(), nil, nil, 7)



local buildArmslab = "Your team needs upgrades. Select the build menu [1:BuildMenu] and create an Arms Lab [2:ArmsLab] in your base."
local buildArmslabSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.BuildMenu), HighlightButton = kTechId.BuildMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.ArmsLab), HighlightButton = kTechId.ArmsLab, HighlightWorld = GetPlaceForUnit(kTechId.ArmsLab, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kArmsLabCost, kMarineTeamType, buildArmslab, buildArmslabSteps, nil, TutorialNotHasTech(kTechId.ArmsLab), nil)



local upgradeAtArmsLab = "Select the Arms Lab [1:ArmsLab] and chose either weapons [2:Weapons1] or armor [2:Armor1] upgrade. Each cathegory can be upgraded three times."
local upgradeAtArmsLabStep = 
{
    { CompletionFunc = GetHasUnitSelected(kTechId.ArmsLab), HighlightWorld = GetUnitPosition(kTechId.ArmsLab) },
    { CompletionFunc = GetHasTechUsed({kTechId.Armor1, kTechId.Weapons1}), HighlightButton = {kTechId.Armor1, kTechId.Weapons1} },
}
AddCommanderTutorialEntry(kWeapons1ResearchCost, kMarineTeamType, upgradeAtArmsLab, upgradeAtArmsLabStep, nil, {TutorialNotHasTech(kTechId.Armor1), TutorialNotHasTech(kTechId.Weapons1), TutorialGetHasTech(kTechId.ArmsLab)})


local viewTechMap = "To see an overview of all technologies, click on the Tech Map icon [1:Research] next to the minimap on the bottom left of your screen."
local viewTechMapSteps =
{
    { CompletionFunc = PlayerUI_GetIsTechMapVisible }
}
AddCommanderTutorialEntry(0, kMarineTeamType, viewTechMap, viewTechMapSteps)


local buildObs = "Advanced technologies allows marines to travel instantly between two points. To unlock this technology, select the advanced build menu [1:AdvancedMenu] and create an Observatory [2:Observatory] in your base. Observatories have a passive ability and scan the area around it."
local buildObsSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton = kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.Observatory), HighlightButton =  kTechId.Observatory, HighlightWorld = GetPlaceForUnit(kTechId.ArmsLab, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kObservatoryCost, kMarineTeamType, buildObs, buildObsSteps, nil, TutorialNotHasTech(kTechId.Observatory), nil)


local researchPhaseTech = "Select your Observatory [1:Observatory] and click on Phase Tech [2:PhaseTech]"
local researchPhaseTechSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.Observatory), HighlightWorld = GetUnitPosition(kTechId.Observatory) },
    { CompletionFunc = GetHasTechUsed(kTechId.PhaseTech), HighlightButton =  kTechId.PhaseTech },
}
AddCommanderTutorialEntry(kPhaseTechResearchCost, kMarineTeamType, researchPhaseTech, researchPhaseTechSteps, nil, {TutorialNotHasTech(kTechId.PhaseTech), TutorialGetHasTech(kTechId.Observatory)})


local buildPhaseGate = "Phase Gate Technology is now unlocked. Select the advanced build menu [1:AdvancedMenu]. All phase gates you build will be connected with each other (connection is indicated as a line on the minimap) and allow marines to instantly travel between those points. Build the first Phase Gate [2:PhaseGate] in your base."
local buildPhaseGateSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton =  kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.PhaseGate), HighlightButton =  kTechId.PhaseGate, HighlightWorld = GetPlaceForUnit(kTechId.PhaseGate, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kPhaseGateCost, kMarineTeamType, buildPhaseGate, buildPhaseGateSteps, nil, {TutorialNotHasTech(kTechId.PhaseGate), TutorialGetHasTech(kTechId.PhaseTech)})


local buildSecondGate = "Now chose and a destination point, ideally next to an unoccupiet Tech Point [TechPoint]. Select the advanced build menu [1:AdvancedMenu] and build the phase gate [2:PhaseGate]"
local buildSecondGateSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton =  kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.PhaseGate), HighlightButton =  kTechId.PhaseGate, HighlightWorld = GetPlaceForUnit(kTechId.PhaseGate, GetClosestFreeTechPoint) },
}
AddCommanderTutorialEntry(kPhaseGateCost, kMarineTeamType, buildSecondGate, buildSecondGateSteps, nil, {NotHasUnitCount("PhaseGate", 2), TutorialGetHasTech(kTechId.PhaseTech)})


local upgradeArmory = "To unlock more powerful weapons, you need to selec your Armory [1:Armory] and upgrade it [2:AdvancedArmoryUpgrade]. This will allow your marine to purchase Grenade Launchers [GrenadeLauncher] and Flame Throwers [Flamethrower]"
local upgradeArmorySteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.Armory), HighlightWorld = GetUnitPosition(kTechId.Armory) },
    { CompletionFunc = GetHasTechUsed(kTechId.AdvancedArmoryUpgrade), HighlightButton = kTechId.AdvancedArmoryUpgrade },
}
AddCommanderTutorialEntry(kAdvancedArmoryUpgradeCost, kMarineTeamType, upgradeArmory, upgradeArmorySteps, nil, GetHasUnitIsNotResearching(kTechId.Armory), "ADV_ARMORY")



local armorUpgradeReminder = "Dont forget that your Arms Lab provides multiple levels of armor upgrades. Select the Arms Lab [1:ArmsLab] and research armor level 2 [2:Armor2]"
local armorUpgradeReminderSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.ArmsLab), HighlightWorld = GetUnitPosition(kTechId.ArmsLab) },
    { CompletionFunc = GetHasTechUsed(kTechId.Armor2), HighlightButton = kTechId.Armor2 },
}
AddCommanderTutorialEntry(kArmor2ResearchCost, kMarineTeamType, armorUpgradeReminder, armorUpgradeReminderSteps, nil, TutorialGetIsTechAvailable(kTechId.Armor2))



local weaponUpgradeReminder = "Dont forget that your Arms Lab provides multiple levels of weapon upgrades. Select the Arms Lab [1:ArmsLab] and research weapons level 2 [2:Weapons2]"
local weaponUpgradeReminderSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.ArmsLab), HighlightWorld = GetUnitPosition(kTechId.ArmsLab) },
    { CompletionFunc = GetHasTechUsed(kTechId.Weapons2), HighlightButton = kTechId.Weapons2 },
}
AddCommanderTutorialEntry(kWeapons2ResearchCost, kMarineTeamType, weaponUpgradeReminder, weaponUpgradeReminderSteps, nil, TutorialGetIsTechAvailable(kTechId.Weapons2))



local experimentalTech = "Now since you have an Advanced Armory, its time to unlock more equipment for your marines. A series of experimental technology can be accessed via the advanced build menu [1:AdvancedMenu] at the [2:PrototypeLab]"
local experimentalTechSteps =
{
    { CompletionFunc = GetHasMenuSelected(kTechId.AdvancedMenu), HighlightButton = kTechId.AdvancedMenu },
    { CompletionFunc = GetHasTechUsed(kTechId.PrototypeLab), HighlightButton = kTechId.PrototypeLab, HighlightWorld = GetPlaceForUnit(kTechId.PrototypeLab, GetCommandStructureOrigin) },
}
AddCommanderTutorialEntry(kPrototypeLabCost, kMarineTeamType, experimentalTech, experimentalTechSteps, nil, TutorialGetHasTech(kTechId.AdvancedArmory))


local upgradeJetpack = "Select the prototype lab [1:PrototypeLab] and research Jetpacks [2:JetpackTech]"
local upgradeJetpackSteps =
{
    { CompletionFunc = GetHasUnitSelected(kTechId.PrototypeLab), HighlightWorld = GetUnitPosition(kTechId.PrototypeLab) },
    { CompletionFunc = GetHasTechUsed(kTechId.JetpackTech), HighlightButton = kTechId.JetpackTech },
}
AddCommanderTutorialEntry(kJetpackCost, kMarineTeamType, upgradeJetpack, upgradeJetpackSteps, nil, {TutorialNotHasTech(kTechId.JetpackTech), TutorialGetHasTech(kTechId.PrototypeLab)})



