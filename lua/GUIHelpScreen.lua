// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\GUIHelpScreen.lua
// - Dragon

Script.Load("lua/GUIScript.lua")

// Mendasp, I'm not sure if I hate you or love you...
local kScreenScaleAspect = 1280

local function ScreenSmallAspect()

    local screenWidth = Client.GetScreenWidth()
    local screenHeight = Client.GetScreenHeight()
    return ConditionalValue(screenWidth > screenHeight, screenHeight, screenWidth)

end

local function GUICorrectedScale(size)
    if ScreenSmallAspect() > kScreenScaleAspect then
        return (ScreenSmallAspect() / kScreenScaleAspect) * size * 1.15
    else
        return math.scaledown(size, ScreenSmallAspect(), kScreenScaleAspect) * (2 - (ScreenSmallAspect() / kScreenScaleAspect))
    end
end

local kClassTechIdToIndex = {	kTechId.Skulk, kTechId.Gorge, kTechId.Lerk, kTechId.Fade, kTechId.Onos, kTechId.Embryo, 
								kTechId.Marine, kTechId.JetpackMarine, kTechId.HeavyArmorMarine, kTechId.MarineCommander,
								kTechId.ReadyRoomPlayer }
								
local kClassDetails = 	{	{   DisplayName = "SKULK", TextureName = "ui/Skulk.dds", 
                                Description = "SKULK_HELP", Width = GUIScale(240), Height = GUIScale(170) },
                                
							{   DisplayName = "GORGE", TextureName = "ui/Gorge.dds", 
                                Description = "GORGE_HELP", Width = GUIScale(200), Height = GUIScale(167) },
                                
							{   DisplayName = "LERK", TextureName = "ui/Lerk.dds", 
                                Description = "LERK_HELP", Width = GUIScale(284), Height = GUIScale(253) },
                                
							{   DisplayName = "FADE", TextureName = "ui/Fade.dds", 
                                Description = "FADE_HELP", Width = GUIScale(188), Height = GUIScale(220) },
                                
							{   DisplayName = "ONOS", TextureName = "ui/Onos.dds", 
                                Description = "ONOS_HELP", Width = GUIScale(304), Height = GUIScale(326) },
                                
                            {   DisplayName = "EMBRYO", TextureName = "ui/Onos.dds", 
                                Description = "EMBRYO_HELP", Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = "MARINE", TextureName = "ui/Onos.dds", 
                                Description = "MARINE_HELP", Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = "JETPACK_MARINE", TextureName = "ui/Onos.dds", 
                                Description = "JETPACK_MARINE_HELP", Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = "HEAVY_ARMOR_MARINE", TextureName = "ui/Onos.dds", 
                                Description = "HEAVY_ARMOR_MARINE_HELP", Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = "MARINE_COMMANDER", TextureName = "ui/Onos.dds", 
                                Description = "MARINE_COMMANDER_HELP", Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = "READY_ROOM_PLAYER", TextureName = "ui/Onos.dds", 
                                Description = "READY_ROOM_PLAYER_HELP", Width = GUIScale(304), Height = GUIScale(326) }
						}

//local kClassPicturePosition = GUICorrectedScale( Vector(0, 0, 0))  Gotta fight Scaling Creep
local kClassPicturePositionUnscaled = Vector(30, 30, 0)
local kClassPicturePosition = GUICorrectedScale(kClassPicturePositionUnscaled)
local kClassDescription1PositionUnscaled = Vector(400, 50, 0)
local kClassDescription1Position = GUICorrectedScale(kClassDescription1PositionUnscaled)
local kClassDescription2PositionUnscaled = Vector(400, 225, 0)
local kClassDescription2Position = GUICorrectedScale(kClassDescription2PositionUnscaled)
local kClassDescriptionWidthUnscaled = 575
local kClassDescriptionWidth = kClassDescriptionWidthUnscaled //GUICorrectedScale(kClassDescriptionWidthUnscaled)
local kClassTitlePositionUnscaled = Vector(470, 10, 0)
local kClassTitlePosition = GUICorrectedScale(kClassTitlePositionUnscaled)

local kLargeFont = Fonts.kAgencyFB_Medium
local kLargeFontUnscaled = Vector(1, 1, 1) * 1
local kLargeFontScale = GUICorrectedScale(kLargeFontUnscaled)
local kMediumFont = Fonts.kAgencyFB_Small
local kMediumFontUnscaled = Vector(1, 1, 1) * 1
local kMediumFontScale = GUICorrectedScale(kMediumFontUnscaled)
local kSmallFont = Fonts.kAgencyFB_Tiny
local kSmallFontUnscaled = Vector(1, 1, 1) * 1
local kSmallFontScale = GUICorrectedScale(kSmallFontUnscaled)
//Fonts.kAgencyFB_Medium
//Fonts.kAgencyFB_Small
//Fonts.kAgencyFB_Smaller_Bordered
//Fonts.kAgencyFB_Tiny

local kWeaponTechIdToIndex = { 	kTechId.Bite, kTechId.Spit, kTechId.BuildAbility, kTechId.LerkBite, kTechId.Swipe, kTechId.Gore, kTechId.Smash,
								kTechId.Parasite, kTechId.Spray, kTechId.Spores, kTechId.Blink, kTechId.Charge,
								kTechId.Leap, kTechId.BileBomb, kTechId.Umbra, kTechId.Metabolize, kTechId.Stomp,
								kTechId.Xenocide, kTechId.Web, kTechId.PrimalScream, kTechId.AcidRocket, kTechId.Devour, kTechId.BabblerAbility,
								kTechId.Spikes,
								kTechId.Rifle, kTechId.Shotgun, kTechId.HeavyMachineGun, kTechId.GrenadeLauncher,
								kTechId.Welder, kTechId.Mines, kTechId.HandGrenades, kTechId.Pistol, kTechId.Axe,
								kTechId.Jetpack, kTechId.HeavyArmor
								}

local kWeaponDetails = {	{ DisplayName = "BITE", TextureName = "", Description = "BITE_HELP" },
							{ DisplayName = "SPIT", TextureName = "", Description = "SPIT_HELP" },
							{ DisplayName = "BUILD_ABILITY", TextureName = "", Description = "BUILD_ABILITY_HELP" },
							{ DisplayName = "LERK_BITE", TextureName = "", Description = "LERK_BITE_HELP" },
							{ DisplayName = "SWIPE_BLINK", TextureName = "", Description = "SWIPE_BLINK_HELP" },
							{ DisplayName = "GORE", TextureName = "", Description = "GORE_HELP" },
							{ DisplayName = "SMASH", TextureName = "", Description = "SMASH_HELP" },
							{ DisplayName = "PARASITE", TextureName = "", Description = "PARASITE_HELP" },
							{ DisplayName = "SPRAY", TextureName = "", Description = "SPRAY_HELP" },
							{ DisplayName = "SPORES", TextureName = "", Description = "SPORES_HELP" },
							{ DisplayName = "BLINK", TextureName = "", Description = "BLINK_HELP" },
							{ DisplayName = "CHARGE", TextureName = "", Description = "CHARGE_HELP" },
							{ DisplayName = "LEAP", TextureName = "", Description = "LEAP_HELP" },
							{ DisplayName = "BILEBOMB", TextureName = "", Description = "BILEBOMB_HELP" },
							{ DisplayName = "UMBRA", TextureName = "", Description = "UMBRA_HELP" },
							{ DisplayName = "METABOLIZE", TextureName = "", Description = "METABOLIZE_HELP" },
							{ DisplayName = "STOMP", TextureName = "", Description = "STOMP_HELP" },
							{ DisplayName = "XENOCIDE", TextureName = "", Description = "XENOCIDE_HELP" },
							{ DisplayName = "WEB", TextureName = "", Description = "WEB_HELP" },
							{ DisplayName = "PRIMAL_SCREAM", TextureName = "", Description = "PRIMAL_SCREAM_HELP" },
							{ DisplayName = "ACID_ROCKET", TextureName = "", Description = "ACID_ROCKET_HELP" },
							{ DisplayName = "DEVOUR", TextureName = "", Description = "DEVOUR_HELP" },
							{ DisplayName = "BABBLER_ABILITY", TextureName = "", Description = "BABBLER_ABILITY_HELP" },
							{ DisplayName = "SPIKES", TextureName = "", Description = "SPIKES_HELP" },
							{ DisplayName = "RIFLE", TextureName = "", Description = "RIFLE_HELP" },
							{ DisplayName = "SHOTGUN", TextureName = "", Description = "SHOTGUN_HELP" },
							{ DisplayName = "HEAVY_MACHINE_GUN", TextureName = "", Description = "HEAVY_MACHINE_GUN_HELP" },
							{ DisplayName = "GRENADE_LAUNCHER", TextureName = "", Description = "GRENADE_LAUNCHER_HELP" },
							{ DisplayName = "WELDER", TextureName = "", Description = "WELDER_HELP" },
							{ DisplayName = "MINE", TextureName = "", Description = "MINE_HELP" },
							{ DisplayName = "HAND_GRENADES", TextureName = "", Description = "HAND_GRENADES_HELP" },
							{ DisplayName = "PISTOL", TextureName = "", Description = "PISTOL_HELP" },
							{ DisplayName = "SWITCH_AX", TextureName = "", Description = "SWITCH_AX_HELP" },
							{ DisplayName = "JETPACK", TextureName = "", Description = "JETPACK_HELP" },
							{ DisplayName = "HEAVY_ARMOR", TextureName = "", Description = "HEAVY_ARMOR_HELP" }
						}
					
local kWeaponIconSizeUnscaled = Vector(100, 100, 0)
local kWeaponIconSize = GUICorrectedScale(kWeaponIconSizeUnscaled)
local kWeaponSpacingUnscaled = Vector(120, 120, 0)
local kWeaponSpacing = GUICorrectedScale(kWeaponSpacingUnscaled)
local kWeaponTitleSizeUnscaled = 30
local kWeaponTitleSize = GUICorrectedScale(kWeaponTitleSizeUnscaled)
local kWeaponIconPositionTableUnscaled = Vector(0, 420, 0)
local kWeaponIconPositionTable = GUICorrectedScale(kWeaponIconPositionTableUnscaled)
local kWeaponDescriptionTableUnscaled = Vector(120, 420, 0)
local kWeaponDescriptionTable = GUICorrectedScale(kWeaponDescriptionTableUnscaled)
local kWeaponDescriptionWidthUnscaled = 550
local kWeaponDescriptionWidth = kWeaponDescriptionWidthUnscaled //GUICorrectedScale(kWeaponDescriptionWidthUnscaled)
local kMaxWeaponListings = 4

//Eventually use specific textures for each weapon/ability.. maybe?  or atleast something a bit higher res.
local kCrapWeaponTexture = kInventoryIconsTexture

local kUpgradeTechStatus = enum({'Unlocked', 'Locked'})

local kUpgradeSlots = 	{
                            [kAlienTeamType] = 	{
                                                    { TechId = kTechId.Crag, SubUpgrades = { kTechId.Carapace, kTechId.Regeneration, kTechId.Redemption } },
                                                    { TechId = kTechId.Shift, SubUpgrades = { kTechId.Celerity, kTechId.Adrenaline, kTechId.Redeployment, kTechId.Silence2 } },
                                                    { TechId = kTechId.Shade, SubUpgrades = { kTechId.Silence, kTechId.Aura, kTechId.Ghost, kTechId.Camouflage } },
                                                    { TechId = kTechId.Whip, SubUpgrades = { kTechId.Focus, kTechId.Fury, kTechId.Bombard } }
                                                },
							[kMarineTeamType] = {
													{ TechId = kTechId.Armor1, SubUpgrades = { kTechId.Armor1, kTechId.Armor2, kTechId.Armor3 } },
													{ TechId = kTechId.Weapons1, SubUpgrades = { kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3 } },
													{ TechId = kTechId.MotionTracking },
													{ TechId = kTechId.HandGrenadesTech }
												},
							[kNeutralTeamType] ={
													{ TechId = kTechId.Move },
													{ TechId = kTechId.Construct },
													{ TechId = kTechId.Attack },
													{ TechId = kTechId.Defend }
												}
						}

local kUpgradeTechIdToIndex = { kTechId.Carapace, kTechId.Regeneration, kTechId.Redemption, kTechId.Crag,
								kTechId.Celerity, kTechId.Adrenaline, kTechId.Redeployment, kTechId.Silence2, kTechId.Shift,
								kTechId.Silence, kTechId.Aura, kTechId.Ghost, kTechId.Camouflage, kTechId.Shade,
								kTechId.Focus, kTechId.Fury, kTechId.Bombard, kTechId.Whip,
								kTechId.Armor1, kTechId.Armor2, kTechId.Armor3,
								kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3,
								kTechId.MotionTracking,
								kTechId.HandGrenadesTech,
								kTechId.Move, kTechId.Construct, kTechId.Attack, kTechId.Defend
								}

local kUpgradeDetails = {	{ DisplayName = "CARAPACE", TextureName = "", UnlockedDescription = "CARAPACE_UNLOCKED", LockedDescription = "CARAPACE_LOCKED" },
							{ DisplayName = "REGENERATION", TextureName = "", UnlockedDescription = "REGENERATION_UNLOCKED", LockedDescription = "REGENERATION_LOCKED" },
							{ DisplayName = "REDEMPTION", TextureName = "", UnlockedDescription = "REDEMPTION_UNLOCKED", LockedDescription = "REDEMPTION_LOCKED" },
							{ DisplayName = "CRAG", TextureName = "", UnlockedDescription = "CRAG_UNLOCKED", LockedDescription = "CRAG_LOCKED" },
							{ DisplayName = "CELERITY", TextureName = "", UnlockedDescription = "CELERITY_UNLOCKED", LockedDescription = "CELERITY_LOCKED" },
							{ DisplayName = "ADRENALINE", TextureName = "", UnlockedDescription = "ADRENALINE_UNLOCKED", LockedDescription = "ADRENALINE_LOCKED" },
							{ DisplayName = "REDEPLOYMENT", TextureName = "", UnlockedDescription = "REDEPLOYMENT_UNLOCKED", LockedDescription = "REDEPLOYMENT_LOCKED" },
							{ DisplayName = "SILENCE", TextureName = "", UnlockedDescription = "SILENCE_UNLOCKED", LockedDescription = "SILENCE_LOCKED" },
							{ DisplayName = "SHIFT", TextureName = "", UnlockedDescription = "SHIFT_UNLOCKED", LockedDescription = "SHIFT_LOCKED" },
							{ DisplayName = "SILENCE", TextureName = "", UnlockedDescription = "SILENCE_UNLOCKED", LockedDescription = "SILENCE_LOCKED" },
							{ DisplayName = "AURA", TextureName = "", UnlockedDescription = "AURA_UNLOCKED", LockedDescription = "AURA_LOCKED" },
							{ DisplayName = "GHOST", TextureName = "", UnlockedDescription = "GHOST_UNLOCKED", LockedDescription = "GHOST_LOCKED" },
							{ DisplayName = "CAMOUFLAGE", TextureName = "", UnlockedDescription = "CAMOUFLAGE_UNLOCKED", LockedDescription = "CAMOUFLAGE_LOCKED" },
							{ DisplayName = "SHADE", TextureName = "", UnlockedDescription = "SHADE_UNLOCKED", LockedDescription = "SHADE_LOCKED" },
							{ DisplayName = "FOCUS", TextureName = "", UnlockedDescription = "FOCUS_UNLOCKED", LockedDescription = "FOCUS_LOCKED" },
							{ DisplayName = "FURY", TextureName = "", UnlockedDescription = "FURY_UNLOCKED", LockedDescription = "FURY_LOCKED" },
							{ DisplayName = "BOMBARD", TextureName = "", UnlockedDescription = "BOMBARD_UNLOCKED", LockedDescription = "BOMBARD_LOCKED" },
							{ DisplayName = "WHIP", TextureName = "", UnlockedDescription = "WHIP_UNLOCKED", LockedDescription = "WHIP_LOCKED" },
							{ DisplayName = "ARMOR1", TextureName = "", UnlockedDescription = "ARMOR1_UNLOCKED", LockedDescription = "ARMOR1_LOCKED" },
							{ DisplayName = "ARMOR2", TextureName = "", UnlockedDescription = "ARMOR2_UNLOCKED", LockedDescription = "ARMOR2_LOCKED" },
							{ DisplayName = "ARMOR3", TextureName = "", UnlockedDescription = "ARMOR3_UNLOCKED", LockedDescription = "ARMOR3_LOCKED" },
							{ DisplayName = "WEAPONS1", TextureName = "", UnlockedDescription = "WEAPONS1_UNLOCKED", LockedDescription = "WEAPONS1_LOCKED" },
							{ DisplayName = "WEAPONS2", TextureName = "", UnlockedDescription = "WEAPONS2_UNLOCKED", LockedDescription = "WEAPONS2_LOCKED" },
							{ DisplayName = "WEAPONS3", TextureName = "", UnlockedDescription = "WEAPONS3_UNLOCKED", LockedDescription = "WEAPONS3_LOCKED" },
							{ DisplayName = "MOTION_TRACKING", TextureName = "", UnlockedDescription = "MOTION_TRACKING_UNLOCKED", LockedDescription = "MOTION_TRACKING_LOCKED" },
							{ DisplayName = "HAND_GRENADES", TextureName = "", UnlockedDescription = "HAND_GRENADES_UNLOCKED", LockedDescription = "HAND_GRENADES_LOCKED" },
							{ DisplayName = "MOVE", TextureName = "", UnlockedDescription = "MOVE_UNLOCKED", LockedDescription = "MOVE_LOCKED" },
							{ DisplayName = "CONSTRUCT", TextureName = "", UnlockedDescription = "CONSTRUCT_UNLOCKED", LockedDescription = "CONSTRUCT_LOCKED" },
							{ DisplayName = "ATTACK", TextureName = "", UnlockedDescription = "ATTACK_UNLOCKED", LockedDescription = "ATTACK_LOCKED" },
							{ DisplayName = "DEFEND", TextureName = "", UnlockedDescription = "DEFEND_UNLOCKED", LockedDescription = "DEFEND_LOCKED" },
						}

local kUpgradeIconSizeUnscaled = Vector(100, 100, 0)
local kUpgradeIconSize = GUICorrectedScale(kUpgradeIconSizeUnscaled)
local kUpgradeSpacingUnscaled = Vector(120, 120, 0)
local kUpgradeSpacing = GUICorrectedScale(kUpgradeSpacingUnscaled)
local kUpgradeIconTablePositionUnscaled = Vector(700, 420, 0)
local kUpgradeIconTablePosition = GUICorrectedScale(kUpgradeIconTablePositionUnscaled)
local kUpgradeTitleSizeUnscaled = 30
local kUpgradeTitleSize = GUICorrectedScale(kUpgradeTitleSizeUnscaled)
local kUpgradeDescriptionTablePositionUnscaled = Vector(820, 420, 0)
local kUpgradeDescriptionTablePosition = GUICorrectedScale(kUpgradeDescriptionTablePositionUnscaled)
local kUpgradeDescriptionWidthUnscaled = 600
local kUpgradeDescriptionWidth = kUpgradeDescriptionWidthUnscaled //GUICorrectedScale(kUpgradeDescriptionWidthUnscaled)
local kMaxUpgrades = 4
local kUpgradesTexture = "ui/buildmenu.dds"

local kGameplayTips1PositionUnscaled = Vector(1045, 50, 0)
local kGameplayTips1Position = GUICorrectedScale(kGameplayTips1PositionUnscaled)
local kGameplayTips2PositionUnscaled = Vector(1045, 225, 0)
local kGameplayTips2Position = GUICorrectedScale(kGameplayTips2PositionUnscaled)
local kGameplayTitlePositionUnscaled = Vector(1045, 10, 0)
local kGameplayTitlePosition = GUICorrectedScale(kGameplayTitlePositionUnscaled)
local kGameplayTipsWidthUnscaled = 525
local kGameplayTipsWidth = kGameplayTipsWidthUnscaled //GUICorrectedScale(kGameplayTipsWidthUnscaled)

local kGameplayTips = 	{
							[kAlienTeamType] = 	{
													{ Tip = "ALIEN_GAMEPLAY_TIPS_EARLY", Title = "ALIEN_GAMEPLAY_TITLE_EARLY", Time = 0 },
													{ Tip = "ALIEN_GAMEPLAY_TIPS_MID", Title = "ALIEN_GAMEPLAY_TITLE_MID", Time = 5 },
													{ Tip = "ALIEN_GAMEPLAY_TIPS_LATE", Title = "ALIEN_GAMEPLAY_TITLE_LATE", Time = 15 }
												},
							[kMarineTeamType] = {
													{ Tip = "MARINE_GAMEPLAY_TIPS_EARLY", Title = "MARINE_GAMEPLAY_TITLE_EARLY", Time = 0 },
													{ Tip = "MARINE_GAMEPLAY_TIPS_MID", Title = "MARINE_GAMEPLAY_TITLE_MID", Time = 5 },
													{ Tip = "MARINE_GAMEPLAY_TIPS_LATE", Title = "MARINE_GAMEPLAY_TITLE_LATE", Time = 15 }
												},
							[kNeutralTeamType] = {
													{ Tip = "READY_ROOM_TIPS_EARLY", Title = "READY_ROOM_TITLE_EARLY", Time = 0 }
												}
						}

local kBackgroundSizeUnscaled = Vector(1600, 900, 0)
local kBackgroundSize = GUICorrectedScale(kBackgroundSizeUnscaled)

local kUpdateSpeed = 1

class 'GUIHelpScreen' (GUIScript)

local function LookupWeaponList(teamType)
    if teamType == kNeutralTeamType then
        //Do we want to show anything here for those special ones?
        
    end
    return PlayerUI_GetInventoryTechIds()
end

local function LookupUpgradesList(teamType)
	local techTable = { }
    local techTree = GetTechTree()
    local player = Client.GetLocalPlayer()
	local upgradeSlots = kUpgradeSlots[teamType]
	if teamType == kNeutralTeamType then
	    //This is just a hack to always populate the table.. these dont REALLY matter.  Just forcing through system using rando techIds.
	    for i = 1, #upgradeSlots do
            table.insert(techTable, {techId = upgradeSlots[i].TechId, techStatus = kUpgradeTechStatus.Unlocked})
        end
        return techTable
    end
	if techTree and upgradeSlots and player then
		for i = 1, #upgradeSlots do
			local techStatus = kUpgradeTechStatus.Locked
			local techId = upgradeSlots[i].TechId
			local techNode = techTree:GetTechNode(techId)
			if techNode then
				//Determine Status - This sucks since nodes are not consistently setup.
				//Since this just runs on a subset, dont need to account for every case atm.
				//If we have the tech, or have the upgrade.
				if techNode:GetHasTech() then
					techStatus = kUpgradeTechStatus.Unlocked
					//If we have the tech, check to see if we have a subupgrade of it
					if upgradeSlots[i].SubUpgrades then
						for j = 1, #upgradeSlots[i].SubUpgrades do
							local subNode = techTree:GetTechNode(upgradeSlots[i].SubUpgrades[j])
							if (subNode and subNode:GetHasTech()) or player:GetHasUpgrade(upgradeSlots[i].SubUpgrades[j]) then
								//We have a subnode, update data to be inserted into table.
								techId = upgradeSlots[i].SubUpgrades[j]
								techStatus = kUpgradeTechStatus.Unlocked
							end
						end
					end
				end
				table.insert(techTable, {techId = techId, techStatus = techStatus})
			end
		end
	end
	return techTable	
end

local function LookupClassIndex(teamType)
    local player = Client.GetLocalPlayer()
    local techId = player:GetTechId()
    //Cheaty override for RR players
    if teamType == kNeutralTeamType then
        techId = kTechId.ReadyRoomPlayer
    end
	if table.contains(kClassTechIdToIndex, techId) then
		for index, cTechId in ipairs(kClassTechIdToIndex) do
			if techId == cTechId then
				return index
			end
		end
	end
	return 0
end

local function LookupWeaponIndex(techId)
	if table.contains(kWeaponTechIdToIndex, techId) then
		for index, cTechId in ipairs(kWeaponTechIdToIndex) do
			if techId == cTechId then
				return index
			end
		end
	end
	return 0
end

local function LookupUpgradeIndex(techId)
	if table.contains(kUpgradeTechIdToIndex, techId) then
		for index, cTechId in ipairs(kUpgradeTechIdToIndex) do
			if techId == cTechId then
				return index
			end
		end
	end
	return 0
end

local function LookupGameTimeinMinutes()
	local gameTime = PlayerUI_GetGameLengthTime()
    return math.floor( gameTime / 60 )
end

local function InitializeClassObjects(self)

	self.classDisplayIcon = GUIManager:CreateGraphicItem()
    self.classDisplayIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.classDisplayIcon:SetSize(Vector(kClassDetails[self.classIndex].Width, kClassDetails[self.classIndex].Height, 0))
    self.classDisplayIcon:SetPosition(kClassPicturePosition)
    self.classDisplayIcon:SetTexture(kClassDetails[self.classIndex].TextureName)
    self.classDisplayIcon:SetLayer(kGUILayerPlayerHUDForeground2)
    self.classDisplayIcon:SetScale(Vector(1.3, 1.3, 0))
    self.background:AddChild(self.classDisplayIcon)
	
	self.classDisplayText1 = GUIManager:CreateTextItem()
    self.classDisplayText1:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.classDisplayText1:SetPosition(kClassDescription1Position)
    self.classDisplayText1:SetFontName(kMediumFont)
    self.classDisplayText1:SetScale(kMediumFontScale)
    self.classDisplayText1:SetTextAlignmentX(GUIItem.Align_Min)
    self.classDisplayText1:SetTextAlignmentY(GUIItem.Align_Min)
    self.classDisplayText1:SetText("")
    self.classDisplayText1:SetColor(ColorIntToColor(self.teamColor))
    self.classDisplayText1:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.classDisplayText1)
    
    self.classDisplayText2 = GUIManager:CreateTextItem()
    self.classDisplayText2:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.classDisplayText2:SetPosition(kClassDescription2Position)
    self.classDisplayText2:SetFontName(kMediumFont)
    self.classDisplayText2:SetScale(kMediumFontScale)
    self.classDisplayText2:SetTextAlignmentX(GUIItem.Align_Min)
    self.classDisplayText2:SetTextAlignmentY(GUIItem.Align_Min)
    self.classDisplayText2:SetText("")
    self.classDisplayText2:SetColor(ColorIntToColor(self.teamColor))
    self.classDisplayText2:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.classDisplayText2)
	
	self.classDisplayName = GUIManager:CreateTextItem()
    self.classDisplayName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.classDisplayName:SetPosition(kClassTitlePosition)
    self.classDisplayName:SetFontName(kLargeFont)
    self.classDisplayName:SetScale(kLargeFontScale)
    self.classDisplayName:SetTextAlignmentX(GUIItem.Align_Min)
    self.classDisplayName:SetTextAlignmentY(GUIItem.Align_Min)
    self.classDisplayName:SetText("")
    self.classDisplayName:SetColor(ColorIntToColor(self.teamColor))
    self.classDisplayName:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.classDisplayName)
	
end

local function UpdateClassObjects(self)

    if self.classIndex > 0 and self.classIndex ~= self.lastclassIndex then
        self.classDisplayText1:SetText(Locale.ResolveString(kClassDetails[self.classIndex].Description .. "_1"))
        self.classDisplayText1:SetTextClipped(true, kClassDescriptionWidth, 1024)
        self.classDisplayText2:SetText(Locale.ResolveString(kClassDetails[self.classIndex].Description .. "_2"))
        self.classDisplayText2:SetTextClipped(true, kClassDescriptionWidth, 1024)
        self.classDisplayName:SetText(Locale.ResolveString(kClassDetails[self.classIndex].DisplayName))
        self.classDisplayIcon:SetSize(Vector(kClassDetails[self.classIndex].Width, kClassDetails[self.classIndex].Height, 0))
        self.classDisplayIcon:SetTexture(kClassDetails[self.classIndex].TextureName)
        self.lastclassIndex = self.classIndex
        self.lastupgradelist = nil // To Make sure upgrades are updated correctly after egging.
    end
    
end

local function InitializeWeaponObjects(self)

	self.weaponObjects = { }

	for i = 1, kMaxWeaponListings do
	
	    self.weaponObjects[i] = { }
		self.weaponObjects[i].icon = GUIManager:CreateGraphicItem()
		self.weaponObjects[i].icon:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.weaponObjects[i].icon:SetSize(kWeaponIconSize)
		self.weaponObjects[i].icon:SetPosition(Vector(kWeaponIconPositionTable.x, kWeaponIconPositionTable.y + (kWeaponSpacing.y * (i - 1)), 0))
		self.weaponObjects[i].icon:SetTexture(kCrapWeaponTexture)
		self.weaponObjects[i].icon:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.weaponObjects[i].icon)
		
		self.weaponObjects[i].description = GUIManager:CreateTextItem()
		self.weaponObjects[i].description:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.weaponObjects[i].description:SetPosition(Vector(kWeaponDescriptionTable.x, kWeaponDescriptionTable.y + kWeaponTitleSize + (kWeaponSpacing.y * (i - 1)), 0))
		self.weaponObjects[i].description:SetFontName(kSmallFont)
		self.weaponObjects[i].description:SetScale(kSmallFontScale)
		self.weaponObjects[i].description:SetTextAlignmentX(GUIItem.Align_Min)
		self.weaponObjects[i].description:SetTextAlignmentY(GUIItem.Align_Min)
		self.weaponObjects[i].description:SetText("")
		self.weaponObjects[i].description:SetColor(ColorIntToColor(self.teamColor))
		self.weaponObjects[i].description:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.weaponObjects[i].description)
		
		self.weaponObjects[i].title = GUIManager:CreateTextItem()
		self.weaponObjects[i].title:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.weaponObjects[i].title:SetPosition(Vector(kWeaponDescriptionTable.x, kWeaponDescriptionTable.y + (kWeaponSpacing.y * (i - 1)), 0))
		self.weaponObjects[i].title:SetFontName(kMediumFont)
		self.weaponObjects[i].title:SetScale(kMediumFontScale)
		self.weaponObjects[i].title:SetTextAlignmentX(GUIItem.Align_Min)
		self.weaponObjects[i].title:SetTextAlignmentY(GUIItem.Align_Min)
		self.weaponObjects[i].title:SetText("")
		self.weaponObjects[i].title:SetColor(ColorIntToColor(self.teamColor))
		self.weaponObjects[i].title:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.weaponObjects[i].title)
		
		self.weaponObjects[i].index = 0
		
	end

end

local function UpdateWeaponObjects(self)

	if self.weaponList and self.weaponList ~= self.lastweaponlist then
		for i = 1, kMaxWeaponListings do
			if self.weaponList[i] then
				local invSlot = self.weaponList[i]
				local index = LookupWeaponIndex(invSlot.TechId)
				if self.weaponObjects[i].index ~= index then
					if kWeaponDetails[index].TextureName ~= "" then
						//Use better texture
						self.upgradeObjects[i].icon:SetTexture(kWeaponDetails[index].TextureName)
					end
					self.weaponObjects[i].icon:SetTexturePixelCoordinates(GetTexCoordsForTechId(invSlot.TechId))
					self.weaponObjects[i].description:SetText(Locale.ResolveString(kWeaponDetails[index].Description))
					self.weaponObjects[i].description:SetTextClipped(true, kWeaponDescriptionWidth, 1024)
					self.weaponObjects[i].title:SetText(Locale.ResolveString(kWeaponDetails[index].DisplayName))
					self.weaponObjects[i].icon:SetIsVisible(true)
					self.weaponObjects[i].description:SetIsVisible(true)
					self.weaponObjects[i].title:SetIsVisible(true)
					self.weaponObjects[i].index = index
				end
			else
				self.weaponObjects[i].icon:SetIsVisible(false)
				self.weaponObjects[i].description:SetIsVisible(false)
				self.weaponObjects[i].title:SetIsVisible(false)
				self.weaponObjects[i].description:SetText("")
				self.weaponObjects[i].title:SetText("")
				self.weaponObjects[i].index = 0
			end
		end
		self.lastweaponlist = self.weaponList
	end
	
end

local function InitializeUpgradeObjects(self)

	self.upgradeObjects = { }

	for i = 1, kMaxUpgrades do
	
	    self.upgradeObjects[i] = { }
		self.upgradeObjects[i].icon = GUIManager:CreateGraphicItem()
		self.upgradeObjects[i].icon:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.upgradeObjects[i].icon:SetSize(kUpgradeIconSize)
		self.upgradeObjects[i].icon:SetPosition(Vector(kUpgradeIconTablePosition.x, kUpgradeIconTablePosition.y + (kUpgradeSpacing.y * (i - 1)), 0))
		self.upgradeObjects[i].icon:SetTexture(kUpgradesTexture)
		self.upgradeObjects[i].icon:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.upgradeObjects[i].icon)
		
		self.upgradeObjects[i].description = GUIManager:CreateTextItem()
		self.upgradeObjects[i].description:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.upgradeObjects[i].description:SetPosition(Vector(kUpgradeDescriptionTablePosition.x, kUpgradeDescriptionTablePosition.y + kUpgradeTitleSize + (kUpgradeSpacing.y * (i - 1)), 0))
		self.upgradeObjects[i].description:SetFontName(kSmallFont)
		self.upgradeObjects[i].description:SetScale(kSmallFontScale)
		self.upgradeObjects[i].description:SetTextAlignmentX(GUIItem.Align_Min)
		self.upgradeObjects[i].description:SetTextAlignmentY(GUIItem.Align_Min)
		self.upgradeObjects[i].description:SetText("")
		self.upgradeObjects[i].description:SetColor(ColorIntToColor(self.teamColor))
		self.upgradeObjects[i].description:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.upgradeObjects[i].description)
		
		self.upgradeObjects[i].title = GUIManager:CreateTextItem()
		self.upgradeObjects[i].title:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.upgradeObjects[i].title:SetPosition(Vector(kUpgradeDescriptionTablePosition.x, kUpgradeDescriptionTablePosition.y + (kUpgradeSpacing.y * (i - 1)), 0))
		self.upgradeObjects[i].title:SetFontName(kMediumFont)
		self.upgradeObjects[i].title:SetScale(kMediumFontScale)
		self.upgradeObjects[i].title:SetTextAlignmentX(GUIItem.Align_Min)
		self.upgradeObjects[i].title:SetTextAlignmentY(GUIItem.Align_Min)
		self.upgradeObjects[i].title:SetText("")
		self.upgradeObjects[i].title:SetColor(ColorIntToColor(self.teamColor))
		self.upgradeObjects[i].title:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.upgradeObjects[i].title)
		
		self.upgradeObjects[i].index = 0
		self.upgradeObjects[i].status = 0
		
	end

end

local function UpdateUpgradeObjects(self)

	if self.upgradeList and self.upgradeList ~= self.lastupgradelist then
		for i = 1, kMaxUpgrades do
			if self.upgradeList[i] then
				local upgSlot = self.upgradeList[i]
				local techId = upgSlot.techId
                local index = LookupUpgradeIndex(techId)
                local status = upgSlot.techStatus     
                local LocalizedString, GameString
                GameString = kUpgradeDetails[index].LockedDescription
                if kUpgradeDetails[index].TextureName ~= "" then
                    //Use better texture
                    self.upgradeObjects[i].icon:SetTexture(kUpgradeDetails[index].TextureName)
                else
                    self.upgradeObjects[i].icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId)))
                end
                if status == kUpgradeTechStatus.Unlocked then
                    GameString = kUpgradeDetails[index].UnlockedDescription
                end
                //Check for class specific version
                if self.classIndex > 0 then
                    LocalizedString = Locale.ResolveString(GameString .. "_" .. kClassDetails[self.classIndex].DisplayName)
                end
                if self.classIndex == 0 or LocalizedString == GameString .. "_" .. kClassDetails[self.classIndex].DisplayName then
                    //No class specific one, use other
                    LocalizedString = Locale.ResolveString(GameString)
                end
                self.upgradeObjects[i].description:SetText(LocalizedString)
                self.upgradeObjects[i].description:SetTextClipped(true, kUpgradeDescriptionWidth, 1024)
                self.upgradeObjects[i].title:SetText(Locale.ResolveString(kUpgradeDetails[index].DisplayName))
                self.upgradeObjects[i].icon:SetIsVisible(true)
                self.upgradeObjects[i].description:SetIsVisible(true)
                self.upgradeObjects[i].title:SetIsVisible(true)
                self.upgradeObjects[i].index = index
                self.upgradeObjects[i].status = status
		    else
		        self.upgradeObjects[i].description:SetText("")
                self.upgradeObjects[i].title:SetText("")
		        self.upgradeObjects[i].icon:SetIsVisible(false)
                self.upgradeObjects[i].description:SetIsVisible(false)
                self.upgradeObjects[i].title:SetIsVisible(false)
			end
		end
		self.lastupgradelist = self.upgradeList
	end
	
end

local function InitializeGameplaySuggestions(self)

	self.gameplayDisplayText1 = GUIManager:CreateTextItem()
    self.gameplayDisplayText1:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.gameplayDisplayText1:SetPosition(kGameplayTips1Position)
    self.gameplayDisplayText1:SetFontName(kMediumFont)
    self.gameplayDisplayText1:SetScale(kMediumFontScale)
    self.gameplayDisplayText1:SetTextAlignmentX(GUIItem.Align_Min)
    self.gameplayDisplayText1:SetTextAlignmentY(GUIItem.Align_Min)
    self.gameplayDisplayText1:SetText("")
    self.gameplayDisplayText1:SetColor(ColorIntToColor(self.teamColor))
    self.gameplayDisplayText1:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.gameplayDisplayText1)
    
    self.gameplayDisplayText2 = GUIManager:CreateTextItem()
    self.gameplayDisplayText2:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.gameplayDisplayText2:SetPosition(kGameplayTips2Position)
    self.gameplayDisplayText2:SetFontName(kMediumFont)
    self.gameplayDisplayText2:SetScale(kMediumFontScale)
    self.gameplayDisplayText2:SetTextAlignmentX(GUIItem.Align_Min)
    self.gameplayDisplayText2:SetTextAlignmentY(GUIItem.Align_Min)
    self.gameplayDisplayText2:SetText("")
    self.gameplayDisplayText2:SetColor(ColorIntToColor(self.teamColor))
    self.gameplayDisplayText2:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.gameplayDisplayText2)

	self.gameplayDisplayName = GUIManager:CreateTextItem()
    self.gameplayDisplayName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.gameplayDisplayName:SetPosition(kGameplayTitlePosition)
    self.gameplayDisplayName:SetFontName(kLargeFont)
    self.gameplayDisplayName:SetScale(kLargeFontScale)
    self.gameplayDisplayName:SetTextAlignmentX(GUIItem.Align_Min)
    self.gameplayDisplayName:SetTextAlignmentY(GUIItem.Align_Min)
    self.gameplayDisplayName:SetText("")
    self.gameplayDisplayName:SetColor(ColorIntToColor(self.teamColor))
    self.gameplayDisplayName:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.gameplayDisplayName)

end

local function UpdateGameplaySuggestions(self)

	if self.gametime and self.gametime ~= self.lastgametimeupdate then
		local teamGameplay = kGameplayTips[self.teamType]
		if teamGameplay then
			for i = 1, #teamGameplay do
				if self.gametime >= teamGameplay[i].Time then
					self.gameplayDisplayName:SetText(Locale.ResolveString(teamGameplay[i].Title))
					self.gameplayDisplayText1:SetText(Locale.ResolveString(teamGameplay[i].Tip .. "_1"))
					self.gameplayDisplayText1:SetTextClipped(true, kGameplayTipsWidth, 1024)
					self.gameplayDisplayText2:SetText(Locale.ResolveString(teamGameplay[i].Tip .. "_2"))
					self.gameplayDisplayText2:SetTextClipped(true, kGameplayTipsWidth, 1024)
				end
			end
		end
		self.lastgametimeupdate = self.gametime
	end
	
end
	
function GUIHelpScreen:Initialize()

    self.helpScreenButton = false
    self.lastButtonState = true		//This doesnt make sense, but prevents invalid teamtype from causing it to regen tables twice in single frame.
	
    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetSize(kBackgroundSize)
    self.background:SetPosition(-kBackgroundSize * 0.5)
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetIsVisible(true)
    self.background:SetColor(Color(0.0,0.0,0.0,0.4))
    self.background:SetLayer(kGUILayerScoreboard)
    
    self.teamType = PlayerUI_GetTeamType()
	self.classIndex = LookupClassIndex(self.teamType)
	self.weaponList = LookupWeaponList(self.teamType)
	self.upgradeList = LookupUpgradesList(self.teamType)
	self.gametime = LookupGameTimeinMinutes()
	
	if self.teamType == kAlienTeamType then
		self.teamColor = kAlienTeamColor 
	elseif self.teamType == kMarineTeamType then
		self.teamColor = kMarineTeamColor
	else
		self.teamColor = kNeutralTeamColor
	end
	
	InitializeClassObjects(self)
    InitializeGameplaySuggestions(self)
    InitializeWeaponObjects(self)
    InitializeUpgradeObjects(self)
	
	if self.classIndex > 0 then
		//Update Stuff - player is a valid 'class'
		UpdateClassObjects(self)
		UpdateWeaponObjects(self)
		UpdateUpgradeObjects(self)
		UpdateGameplaySuggestions(self)
	end
	
	self.background:SetIsVisible(false)

end

function GUIHelpScreen:Uninitialize()

    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end

end

function GUIHelpScreen:SendKeyEvent(key, down)

    if GetIsBinding(key, "ShowHelpScreen") then
        self.helpScreenButton = down
    end

end

function GUIHelpScreen:GetIsVisible()
    return self.background ~= nil and self.background:GetIsVisible()
end

function GUIHelpScreen:OnResolutionChanged(oldX, oldY, newX, newY)

    kClassPicturePosition = GUICorrectedScale(kClassPicturePositionUnscaled)
    kClassDescription1Position = GUICorrectedScale(kClassDescription1PositionUnscaled)
    kClassDescription2Position = GUICorrectedScale(kClassDescription2PositionUnscaled)
    kClassTitlePosition = GUICorrectedScale(kClassTitlePositionUnscaled)
    kWeaponIconSize = GUICorrectedScale(kWeaponIconSizeUnscaled)
    kWeaponSpacing = GUICorrectedScale(kWeaponSpacingUnscaled)
    kWeaponTitleSize = GUICorrectedScale(kWeaponTitleSizeUnscaled)
    kWeaponIconPositionTable = GUICorrectedScale(kWeaponIconPositionTableUnscaled)
    kWeaponDescriptionTable = GUICorrectedScale(kWeaponDescriptionTableUnscaled)
    kUpgradeIconSize = GUICorrectedScale(kUpgradeIconSizeUnscaled)
    kUpgradeSpacing = GUICorrectedScale(kUpgradeSpacingUnscaled)
    kUpgradeIconTablePosition = GUICorrectedScale(kUpgradeIconTablePositionUnscaled)
    kUpgradeTitleSize = GUICorrectedScale(kUpgradeTitleSizeUnscaled)
    kUpgradeDescriptionTablePosition = GUICorrectedScale(kUpgradeDescriptionTablePositionUnscaled)
    kGameplayTips1Position = GUICorrectedScale(kGameplayTips1PositionUnscaled)
    kGameplayTips2Position = GUICorrectedScale(kGameplayTips2PositionUnscaled)
    kGameplayTitlePosition = GUICorrectedScale(kGameplayTitlePositionUnscaled)
    kBackgroundSize = GUICorrectedScale(kBackgroundSizeUnscaled)
    //kClassDescriptionWidth = GUICorrectedScale(kClassDescriptionWidthUnscaled)
    //kWeaponDescriptionWidth = GUICorrectedScale(kWeaponDescriptionWidthUnscaled)
    //kUpgradeDescriptionWidth = GUICorrectedScale(kUpgradeDescriptionWidthUnscaled)
    //kGameplayTipsWidth = GUICorrectedScale(kGameplayTipsWidthUnscaled)
    kLargeFontScale = GUICorrectedScale(kLargeFontUnscaled)
    kMediumFontScale = GUICorrectedScale(kMediumFontUnscaled)
    kSmallFontScale = GUICorrectedScale(kSmallFontUnscaled)
    
    self:Uninitialize()
    self:Initialize()
    
end

function GUIHelpScreen:Update(deltaTime)

    local teamType = PlayerUI_GetTeamType()
	//Re-Init if wonky team changes occurs.
    if teamType ~= self.teamType then
        self:Uninitialize()
        self:Initialize()
    end
	
	if self.helpScreenButton and not self.lastButtonState then
		// Update everything now.
		self.lastclassIndex = nil
		self.lastweaponlist = nil
		self.lastupgradelist = nil
		self.lastgametimeupdate = nil
		self.lastFullupdate = kUpdateSpeed
	end
    
    if self.helpScreenButton then
		
		//Update weapon/upgrade tables on a slower cycle.  Might not need this..
		self.lastFullupdate = self.lastFullupdate + deltaTime
		if self.lastFullupdate > kUpdateSpeed then
		    self.classIndex = LookupClassIndex(self.teamType)
			self.weaponList = LookupWeaponList(self.teamType)
			self.upgradeList = LookupUpgradesList(self.teamType)
			self.gametime = LookupGameTimeinMinutes()
			UpdateClassObjects(self)
			UpdateWeaponObjects(self)
			UpdateUpgradeObjects(self)
			UpdateGameplaySuggestions(self)
			self.lastFullupdate = self.lastFullupdate - kUpdateSpeed
		end
		
    end
	
	self.background:SetIsVisible(self.helpScreenButton)
	self.lastButtonState = self.helpScreenButton

end