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
        return (ScreenSmallAspect() / kScreenScaleAspect)*size*1.15
    else
        return math.scaledown(size, ScreenSmallAspect(), kScreenScaleAspect) * (2 - (ScreenSmallAspect() / kScreenScaleAspect))
    end
end

local kClassTechIdToIndex = {	kTechId.Skulk, kTechId.Gorge, kTechId.Lerk, kTechId.Fade, kTechId.Onos, 
								kTechId.Marine, kTechId.JetpackMarine, kTechId.HeavyArmorMarine, kTechId.MarineCommander,
								kTechId.ReadyRoomPlayer }
								
local kClassDetails = 	{	{   DisplayName = Locale.ResolveString("SKULK"), TextureName = "ui/Skulk.dds", 
                                Description1 = Locale.ResolveString("SKULK_HELP_1"), Description2 = Locale.ResolveString("SKULK_HELP_2"),
                                Width = GUIScale(240), Height = GUIScale(170) },
                                
							{   DisplayName = Locale.ResolveString("GORGE"), TextureName = "ui/Gorge.dds", 
                                Description1 = Locale.ResolveString("GORGE_HELP_1"), Description2 = Locale.ResolveString("GORGE_HELP_2"), 
                                Width = GUIScale(200), Height = GUIScale(167) },
                                
							{   DisplayName = Locale.ResolveString("LERK"), TextureName = "ui/Lerk.dds", 
                                Description1 = Locale.ResolveString("LERK_HELP_1"), Description2 = Locale.ResolveString("LERK_HELP_2"), 
                                Width = GUIScale(284), Height = GUIScale(253) },
                                
							{   DisplayName = Locale.ResolveString("FADE"), TextureName = "ui/Fade.dds", 
                                Description1 = Locale.ResolveString("FADE_HELP_1"), Description2 = Locale.ResolveString("FADE_HELP_2"),
                                Width = GUIScale(188), Height = GUIScale(220) },
                                
							{   DisplayName = Locale.ResolveString("ONOS"), TextureName = "ui/Onos.dds", 
                                Description1 = Locale.ResolveString("ONOS_HELP_1"), Description2 = Locale.ResolveString("ONOS_HELP_2"),
                                Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = Locale.ResolveString("MARINE"), TextureName = "ui/Onos.dds", 
                                Description1 = Locale.ResolveString("MARINE_HELP_1"), Description2 = Locale.ResolveString("MARINE_HELP_2"), 
                                Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = Locale.ResolveString("JETPACK_MARINE"), TextureName = "ui/Onos.dds", 
                                Description1 = Locale.ResolveString("JETPACK_MARINE_HELP_1"), Description2 = Locale.ResolveString("JETPACK_MARINE_HELP_2"), 
                                Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = Locale.ResolveString("HEAVY_ARMOR_MARINE"), TextureName = "ui/Onos.dds", 
                                Description1 = Locale.ResolveString("HEAVY_ARMOR_MARINE_HELP_1"), Description2 = Locale.ResolveString("HEAVY_ARMOR_MARINE_HELP_2"), 
                                Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = Locale.ResolveString("MARINE_COMMANDER"), TextureName = "ui/Onos.dds", 
                                Description1 = Locale.ResolveString("MARINE_COMMANDER_HELP_1"), Description2 = Locale.ResolveString("MARINE_COMMANDER_HELP_2"), 
                                Width = GUIScale(304), Height = GUIScale(326) },
                                
							{   DisplayName = Locale.ResolveString("READY_ROOM_PLAYER"), TextureName = "ui/Onos.dds", 
                                Description1 = Locale.ResolveString("READY_ROOM_PLAYER_HELP_1"), Description2 = Locale.ResolveString("READY_ROOM_PLAYER_HELP_2"), 
                                Width = GUIScale(304), Height = GUIScale(326) }
						}

//local kClassPicturePosition = GUICorrectedScale( Vector(0, 0, 0))  Gotta fight Scaling Creep
local kClassPicturePosition = GUICorrectedScale( Vector(30, 30, 0))
local kClassDescription1Position = GUICorrectedScale( Vector(400, 50, 0))
local kClassDescription2Position = GUICorrectedScale( Vector(400, 225, 0))
local kClassDescriptionWidth = 600
local kClassTitlePosition = GUICorrectedScale( Vector(470, 10, 0))

local kLargeFont = Fonts.kAgencyFB_Medium
local kMediumFont = Fonts.kAgencyFB_Small
local kSmallFont = Fonts.kAgencyFB_Tiny
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

local kWeaponDetails = {	{ DisplayName = Locale.ResolveString("BITE"), TextureName = "", Description = Locale.ResolveString("BITE_HELP") },
							{ DisplayName = Locale.ResolveString("SPIT"), TextureName = "", Description = Locale.ResolveString("SPIT_HELP") },
							{ DisplayName = Locale.ResolveString("BUILD_ABILITY"), TextureName = "", Description = Locale.ResolveString("BUILD_ABILITY_HELP") },
							{ DisplayName = Locale.ResolveString("LERK_BITE"), TextureName = "", Description = Locale.ResolveString("LERK_BITE_HELP") },
							{ DisplayName = Locale.ResolveString("SWIPE_BLINK"), TextureName = "", Description = Locale.ResolveString("SWIPE_BLINK_HELP") },
							{ DisplayName = Locale.ResolveString("GORE"), TextureName = "", Description = Locale.ResolveString("GORE_HELP") },
							{ DisplayName = Locale.ResolveString("SMASH"), TextureName = "", Description = Locale.ResolveString("SMASH_HELP") },
							{ DisplayName = Locale.ResolveString("PARASITE"), TextureName = "", Description = Locale.ResolveString("PARASITE_HELP") },
							{ DisplayName = Locale.ResolveString("SPRAY"), TextureName = "", Description = Locale.ResolveString("SPRAY_HELP") },
							{ DisplayName = Locale.ResolveString("SPORES"), TextureName = "", Description = Locale.ResolveString("SPORES_HELP") },
							{ DisplayName = Locale.ResolveString("BLINK"), TextureName = "", Description = Locale.ResolveString("BLINK_HELP") },
							{ DisplayName = Locale.ResolveString("CHARGE"), TextureName = "", Description = Locale.ResolveString("CHARGE_HELP") },
							{ DisplayName = Locale.ResolveString("LEAP"), TextureName = "", Description = Locale.ResolveString("LEAP_HELP") },
							{ DisplayName = Locale.ResolveString("BILEBOMB"), TextureName = "", Description = Locale.ResolveString("BILEBOMB_HELP") },
							{ DisplayName = Locale.ResolveString("UMBRA"), TextureName = "", Description = Locale.ResolveString("UMBRA_HELP") },
							{ DisplayName = Locale.ResolveString("METABOLIZE"), TextureName = "", Description = Locale.ResolveString("METABOLIZE_HELP") },
							{ DisplayName = Locale.ResolveString("STOMP"), TextureName = "", Description = Locale.ResolveString("STOMP_HELP") },
							{ DisplayName = Locale.ResolveString("XENOCIDE"), TextureName = "", Description = Locale.ResolveString("XENOCIDE_HELP") },
							{ DisplayName = Locale.ResolveString("WEB"), TextureName = "", Description = Locale.ResolveString("WEB_HELP") },
							{ DisplayName = Locale.ResolveString("PRIMAL_SCREAM"), TextureName = "", Description = Locale.ResolveString("PRIMAL_SCREAM_HELP") },
							{ DisplayName = Locale.ResolveString("ACID_ROCKET"), TextureName = "", Description = Locale.ResolveString("ACID_ROCKET_HELP") },
							{ DisplayName = Locale.ResolveString("DEVOUR"), TextureName = "", Description = Locale.ResolveString("DEVOUR_HELP") },
							{ DisplayName = Locale.ResolveString("BABBLER_ABILITY"), TextureName = "", Description = Locale.ResolveString("BABBLER_ABILITY_HELP") },
							{ DisplayName = Locale.ResolveString("SPIKES"), TextureName = "", Description = Locale.ResolveString("SPIKES_HELP") },
							{ DisplayName = Locale.ResolveString("RIFLE"), TextureName = "", Description = Locale.ResolveString("RIFLE_HELP") },
							{ DisplayName = Locale.ResolveString("SHOTGUN"), TextureName = "", Description = Locale.ResolveString("SHOTGUN_HELP") },
							{ DisplayName = Locale.ResolveString("HEAVY_MACHINE_GUN"), TextureName = "", Description = Locale.ResolveString("HEAVY_MACHINE_GUN_HELP") },
							{ DisplayName = Locale.ResolveString("GRENADE_LAUNCHER"), TextureName = "", Description = Locale.ResolveString("GRENADE_LAUNCHER_HELP") },
							{ DisplayName = Locale.ResolveString("WELDER"), TextureName = "", Description = Locale.ResolveString("WELDER_HELP") },
							{ DisplayName = Locale.ResolveString("MINE"), TextureName = "", Description = Locale.ResolveString("MINE_HELP") },
							{ DisplayName = Locale.ResolveString("HAND_GRENADES"), TextureName = "", Description = Locale.ResolveString("HAND_GRENADES_HELP") },
							{ DisplayName = Locale.ResolveString("PISTOL"), TextureName = "", Description = Locale.ResolveString("PISTOL_HELP") },
							{ DisplayName = Locale.ResolveString("SWITCH_AX"), TextureName = "", Description = Locale.ResolveString("SWITCH_AX_HELP") },
							{ DisplayName = Locale.ResolveString("JETPACK"), TextureName = "", Description = Locale.ResolveString("JETPACK_HELP") },
							{ DisplayName = Locale.ResolveString("HEAVY_ARMOR"), TextureName = "", Description = Locale.ResolveString("HEAVY_ARMOR_HELP") }
						}
						
local kWeaponIconSize = GUICorrectedScale( Vector(100, 100, 0))
local kWeaponSpacing = GUICorrectedScale( Vector(120, 120, 0))
local kWeaponTitleSize = GUICorrectedScale(30)
local kWeaponIconPositionTable = GUICorrectedScale( Vector(0, 420, 0))
local kWeaponDescriptionTable = GUICorrectedScale( Vector(120, 420, 0))
local kWeaponDescriptionWidth = 550
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
								kTechId.ArmsLab,
								kTechId.Move, kTechId.Construct, kTechId.Attack, kTechId.Defend
								}

local kUpgradeDetails = {	{ DisplayName = Locale.ResolveString("CARAPACE"), TextureName = "", UnlockedDescription = Locale.ResolveString("CARAPACE_UNLOCKED"), LockedDescription = Locale.ResolveString("CARAPACE_LOCKED") },
							{ DisplayName = Locale.ResolveString("REGENERATION"), TextureName = "", UnlockedDescription = Locale.ResolveString("REGENERATION_UNLOCKED"), LockedDescription = Locale.ResolveString("REGENERATION_LOCKED") },
							{ DisplayName = Locale.ResolveString("REDEMPTION"), TextureName = "", UnlockedDescription = Locale.ResolveString("REDEMPTION_UNLOCKED"), LockedDescription = Locale.ResolveString("REDEMPTION_LOCKED") },
							{ DisplayName = Locale.ResolveString("CRAG"), TextureName = "", UnlockedDescription = Locale.ResolveString("CRAG_UNLOCKED"), LockedDescription = Locale.ResolveString("CRAG_LOCKED") },
							{ DisplayName = Locale.ResolveString("CELERITY"), TextureName = "", UnlockedDescription = Locale.ResolveString("CELERITY_UNLOCKED"), LockedDescription = Locale.ResolveString("CELERITY_LOCKED") },
							{ DisplayName = Locale.ResolveString("ADRENALINE"), TextureName = "", UnlockedDescription = Locale.ResolveString("ADRENALINE_UNLOCKED"), LockedDescription = Locale.ResolveString("ADRENALINE_LOCKED") },
							{ DisplayName = Locale.ResolveString("REDEPLOYMENT"), TextureName = "", UnlockedDescription = Locale.ResolveString("REDEPLOYMENT_UNLOCKED"), LockedDescription = Locale.ResolveString("REDEPLOYMENT_LOCKED") },
							{ DisplayName = Locale.ResolveString("SILENCE"), TextureName = "", UnlockedDescription = Locale.ResolveString("SILENCE_UNLOCKED"), LockedDescription = Locale.ResolveString("SILENCE_LOCKED") },
							{ DisplayName = Locale.ResolveString("SHIFT"), TextureName = "", UnlockedDescription = Locale.ResolveString("SHIFT_UNLOCKED"), LockedDescription = Locale.ResolveString("SHIFT_LOCKED") },
							{ DisplayName = Locale.ResolveString("SILENCE"), TextureName = "", UnlockedDescription = Locale.ResolveString("SILENCE_UNLOCKED"), LockedDescription = Locale.ResolveString("SILENCE_LOCKED") },
							{ DisplayName = Locale.ResolveString("AURA"), TextureName = "", UnlockedDescription = Locale.ResolveString("AURA_UNLOCKED"), LockedDescription = Locale.ResolveString("AURA_LOCKED") },
							{ DisplayName = Locale.ResolveString("GHOST"), TextureName = "", UnlockedDescription = Locale.ResolveString("GHOST_UNLOCKED"), LockedDescription = Locale.ResolveString("GHOST_LOCKED") },
							{ DisplayName = Locale.ResolveString("CAMOUFLAGE"), TextureName = "", UnlockedDescription = Locale.ResolveString("CAMOUFLAGE_UNLOCKED"), LockedDescription = Locale.ResolveString("CAMOUFLAGE_LOCKED") },
							{ DisplayName = Locale.ResolveString("SHADE"), TextureName = "", UnlockedDescription = Locale.ResolveString("SHADE_UNLOCKED"), LockedDescription = Locale.ResolveString("SHADE_LOCKED") },
							{ DisplayName = Locale.ResolveString("FOCUS"), TextureName = "", UnlockedDescription = Locale.ResolveString("FOCUS_UNLOCKED"), LockedDescription = Locale.ResolveString("FOCUS_LOCKED") },
							{ DisplayName = Locale.ResolveString("FURY"), TextureName = "", UnlockedDescription = Locale.ResolveString("FURY_UNLOCKED"), LockedDescription = Locale.ResolveString("FURY_LOCKED") },
							{ DisplayName = Locale.ResolveString("BOMBARD"), TextureName = "", UnlockedDescription = Locale.ResolveString("BOMBARD_UNLOCKED"), LockedDescription = Locale.ResolveString("BOMBARD_LOCKED") },
							{ DisplayName = Locale.ResolveString("WHIP"), TextureName = "", UnlockedDescription = Locale.ResolveString("WHIP_UNLOCKED"), LockedDescription = Locale.ResolveString("WHIP_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMOR1"), TextureName = "", UnlockedDescription = Locale.ResolveString("ARMOR1_UNLOCKED"), LockedDescription = Locale.ResolveString("ARMOR1_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMOR2"), TextureName = "", UnlockedDescription = Locale.ResolveString("ARMOR2_UNLOCKED"), LockedDescription = Locale.ResolveString("ARMOR2_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMOR3"), TextureName = "", UnlockedDescription = Locale.ResolveString("ARMOR3_UNLOCKED"), LockedDescription = Locale.ResolveString("ARMOR3_LOCKED") },
							{ DisplayName = Locale.ResolveString("WEAPONS1"), TextureName = "", UnlockedDescription = Locale.ResolveString("WEAPONS1_UNLOCKED"), LockedDescription = Locale.ResolveString("WEAPONS1_LOCKED") },
							{ DisplayName = Locale.ResolveString("WEAPONS2"), TextureName = "", UnlockedDescription = Locale.ResolveString("WEAPONS2_UNLOCKED"), LockedDescription = Locale.ResolveString("WEAPONS2_LOCKED") },
							{ DisplayName = Locale.ResolveString("WEAPONS3"), TextureName = "", UnlockedDescription = Locale.ResolveString("WEAPONS3_UNLOCKED"), LockedDescription = Locale.ResolveString("WEAPONS3_LOCKED") },
							{ DisplayName = Locale.ResolveString("MOTION_TRACKING"), TextureName = "", UnlockedDescription = Locale.ResolveString("MOTION_TRACKING_UNLOCKED"), LockedDescription = Locale.ResolveString("MOTION_TRACKING_LOCKED") },
							{ DisplayName = Locale.ResolveString("HAND_GRENADES"), TextureName = "", UnlockedDescription = Locale.ResolveString("HAND_GRENADES_UNLOCKED"), LockedDescription = Locale.ResolveString("HAND_GRENADES_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMS_LAB"), TextureName = "", UnlockedDescription = Locale.ResolveString("ARMS_LAB_UNLOCKED"), LockedDescription = Locale.ResolveString("ARMS_LAB_LOCKED") },
							{ DisplayName = Locale.ResolveString("MOVE"), TextureName = "", UnlockedDescription = Locale.ResolveString("MOVE_UNLOCKED"), LockedDescription = Locale.ResolveString("MOVE_LOCKED") },
							{ DisplayName = Locale.ResolveString("CONSTRUCT"), TextureName = "", UnlockedDescription = Locale.ResolveString("CONSTRUCT_UNLOCKED"), LockedDescription = Locale.ResolveString("CONSTRUCT_LOCKED") },
							{ DisplayName = Locale.ResolveString("ATTACK"), TextureName = "", UnlockedDescription = Locale.ResolveString("ATTACK_UNLOCKED"), LockedDescription = Locale.ResolveString("ATTACK_LOCKED") },
							{ DisplayName = Locale.ResolveString("DEFEND"), TextureName = "", UnlockedDescription = Locale.ResolveString("DEFEND_UNLOCKED"), LockedDescription = Locale.ResolveString("DEFEND_LOCKED") },
						}

local kUpgradeIconSize = GUICorrectedScale( Vector(100, 100, 0))
local kUpgradeSpacing = GUICorrectedScale( Vector(120, 120, 0))
local kUpgradeIconTablePosition = GUICorrectedScale( Vector(700, 420, 0))
local kUpgradeTitleSize = GUICorrectedScale(30)
local kUpgradeDescriptionTablePosition = GUICorrectedScale( Vector(820, 420, 0))
local kUpgradeDescriptionWidth = 500
local kMaxUpgrades = 4
local kUpgradesTexture = "ui/buildmenu.dds"

local kGameplayTips1Position = GUICorrectedScale( Vector(1070, 40, 0))
local kGameplayTips2Position = GUICorrectedScale( Vector(1070, 215, 0))
local kGameplayTitlePosition = GUICorrectedScale( Vector(1070, 0, 0))
local kGameplayTipsWidth = 500

local kGameplayTips = 	{
							[kAlienTeamType] = 	{
													{ Tip1 = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_1"), Tip2 = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_2"), Title = Locale.ResolveString("ALIEN_GAMEPLAY_TITLE_1"), Time = 0 },
													{ Tip1 = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_3"), Tip2 = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_4"), Title = Locale.ResolveString("ALIEN_GAMEPLAY_TITLE_2"), Time = 5 },
													{ Tip1 = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_5"), Tip2 = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_6"), Title = Locale.ResolveString("ALIEN_GAMEPLAY_TITLE_3"), Time = 15 }
												},
							[kMarineTeamType] = {
													{ Tip1 = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_1"), Tip2 = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_2"), Title = Locale.ResolveString("MARINE_GAMEPLAY_TITLE_1"), Time = 0 },
													{ Tip1 = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_3"), Tip2 = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_4"), Title = Locale.ResolveString("MARINE_GAMEPLAY_TITLE_2"), Time = 5 },
													{ Tip1 = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_5"), Tip2 = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_6"), Title = Locale.ResolveString("MARINE_GAMEPLAY_TITLE_3"), Time = 15 }
												},
							[kNeutralTeamType] = {
													{ Tip1 = Locale.ResolveString("READY_ROOM_TIPS_1"), Tip2 = Locale.ResolveString("READY_ROOM_TIPS_2"), Title = Locale.ResolveString("READY_ROOM_TITLE_1"), Time = 0 }
												}
						}

local kBackgroundSize = GUICorrectedScale( Vector(1632, 918, 0))
local kWeaponUpgradeUpdateSpeed = 1

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
	local upgradeSlots = kUpgradeSlots[teamType]
	if teamType == kNeutralTeamType then
	    //This is just a hack to always populate the table.. these dont REALLY matter.  Just forcing through system using rando techIds.
	    for i = 1, #upgradeSlots do
            table.insert(techTable, {techId = upgradeSlots[i].TechId, techStatus = kUpgradeTechStatus.Unlocked})
        end
        return techTable
    end
	if techTree and upgradeSlots then
		for i = 1, #upgradeSlots do
			local techStatus = kUpgradeTechStatus.Locked
			local techId = upgradeSlots[i].TechId
			local techNode = techTree:GetTechNode(techId)
			if techNode then
				//Determine Status - This sucks since nodes are not consistently setup.
				//Since this just runs on a subset, dont need to account for every case atm.
				if techNode:GetHasTech() then
					techStatus = kUpgradeTechStatus.Unlocked
					//If we have the tech, check to see if we have a subupgrade of it
					if upgradeSlots.SubUpgrades then
						for j = 1, #SubUpgrades do
							local subNode = techTree:GetTechNode(SubUpgrades[j])
							if subNode:GetHasTech() then
								//We have a subnode, update data to be inserted into table.
								techId = SubUpgrades[j]
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
    self.classDisplayName:SetTextAlignmentX(GUIItem.Align_Min)
    self.classDisplayName:SetTextAlignmentY(GUIItem.Align_Min)
    self.classDisplayName:SetText("")
    self.classDisplayName:SetColor(ColorIntToColor(self.teamColor))
    self.classDisplayName:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.classDisplayName)
	
end

local function UpdateClassObjects(self)

    if self.classIndex > 0 and self.classIndex ~= self.lastclassIndex then
        self.classDisplayText1:SetText(kClassDetails[self.classIndex].Description1)
        self.classDisplayText1:SetTextClipped(true, kClassDescriptionWidth, 1024)
        self.classDisplayText2:SetText(kClassDetails[self.classIndex].Description2)
        self.classDisplayText2:SetTextClipped(true, kClassDescriptionWidth, 1024)
        self.classDisplayName:SetText(kClassDetails[self.classIndex].DisplayName)
        self.classDisplayIcon:SetSize(Vector(kClassDetails[self.classIndex].Width, kClassDetails[self.classIndex].Height, 0))
        self.classDisplayIcon:SetTexture(kClassDetails[self.classIndex].TextureName)
        self.lastclassIndex = self.classIndex
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
					self.weaponObjects[i].description:SetText(kWeaponDetails[index].Description)
					self.weaponObjects[i].description:SetTextClipped(true, kWeaponDescriptionWidth, 1024)
					self.weaponObjects[i].title:SetText(kWeaponDetails[index].DisplayName)
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
                if self.upgradeObjects[i].index ~= index or self.upgradeObjects[i].status ~= status then
                    if kUpgradeDetails[index].TextureName ~= "" then
                        //Use better texture
                        self.upgradeObjects[i].icon:SetTexture(kUpgradeDetails[index].TextureName)
                    end
                    self.upgradeObjects[i].icon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId)))
                    if status == kUpgradeTechStatus.Unlocked then
                        self.upgradeObjects[i].description:SetText(kUpgradeDetails[index].UnlockedDescription)
                    else
                        self.upgradeObjects[i].description:SetText(kUpgradeDetails[index].LockedDescription)
                    end
                    self.upgradeObjects[i].description:SetTextClipped(true, kUpgradeDescriptionWidth, 1024)
                    self.upgradeObjects[i].title:SetText(kUpgradeDetails[index].DisplayName)
                    self.upgradeObjects[i].icon:SetIsVisible(true)
                    self.upgradeObjects[i].description:SetIsVisible(true)
                    self.upgradeObjects[i].title:SetIsVisible(true)
                    self.upgradeObjects[i].index = index
                    self.upgradeObjects[i].status = status
				end
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
					self.gameplayDisplayName:SetText(teamGameplay[i].Title)
					self.gameplayDisplayText1:SetText(teamGameplay[i].Tip1)
					self.gameplayDisplayText1:SetTextClipped(true, kGameplayTipsWidth, 1024)
					self.gameplayDisplayText2:SetText(teamGameplay[i].Tip2)
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

function GUIHelpScreen:Update(deltaTime)

    local teamType = PlayerUI_GetTeamType()
	//Re-Init if wonky team changes occurs.
    if teamType ~= self.teamType then
        self:Uninitialize()
        self:Initialize()
    end
	
	if self.helpScreenButton and not self.lastButtonState then
		// Update everything now.
		self.classIndex = LookupClassIndex(self.teamType)
		self.weaponList = LookupWeaponList(self.teamType)
		self.upgradeList = LookupUpgradesList(self.teamType)
		self.gametime = LookupGameTimeinMinutes()
		self.lastclassIndex = nil
		self.lastweaponlist = nil
		self.lastupgradelist = nil
		self.lastgametimeupdate = nil
		self.lastFullupdate = 0
	end
    
    if self.helpScreenButton then
		
		//Update weapon/upgrade tables on a slower cycle.  Might not need this..
		self.lastFullupdate = self.lastFullupdate + deltaTime
		if self.lastFullupdate > kWeaponUpgradeUpdateSpeed then
		    self.classIndex = LookupClassIndex(self.teamType)
			self.weaponList = LookupWeaponList(self.teamType)
			self.upgradeList = LookupUpgradesList(self.teamType)
			self.gametime = LookupGameTimeinMinutes()
			UpdateClassObjects(self)
			UpdateWeaponObjects(self)
			UpdateUpgradeObjects(self)
			UpdateGameplaySuggestions(self)
			self.lastFullupdate = self.lastFullupdate - kWeaponUpgradeUpdateSpeed
		end		
		
    end
	
	self.background:SetIsVisible(self.helpScreenButton)
	self.lastButtonState = self.helpScreenButton

end