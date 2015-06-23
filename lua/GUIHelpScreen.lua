// Natural Selection 2 'Classic' Mod
// lua\GUIHelpScreen.lua
// - Dragon

Script.Load("lua/GUIScript.lua")

local kClassTechIdToIndex = {	kTechId.Skulk, kTechId.Gorge, kTechId.Lerk, kTechId.Fade, kTechId.Onos, 
								kTechId.Marine, kTechId.JetpackMarine, kTechId.HeavyArmorMarine, kTechId.MarineCommander}
								
local kClassDetails = 	{	{ DisplayName = Locale.ResolveString("SKULK"), TextureName = "ui/Skulk.dds", Description = Locale.ResolveString("SKULK_HELP"), Width = GUIScale(240), Height = GUIScale(170) },
							{ DisplayName = Locale.ResolveString("GORGE"), TextureName = "ui/Gorge.dds", Description = Locale.ResolveString("GORGE_HELP"), Width = GUIScale(200), Height = GUIScale(167) },
							{ DisplayName = Locale.ResolveString("LERK"), TextureName = "ui/Lerk.dds", Description = Locale.ResolveString("LERK_HELP"), Width = GUIScale(284), Height = GUIScale(253) },
							{ DisplayName = Locale.ResolveString("FADE"), TextureName = "ui/Fade.dds", Description = Locale.ResolveString("FADE_HELP"), Width = GUIScale(188), Height = GUIScale(220) },
							{ DisplayName = Locale.ResolveString("ONOS"), TextureName = "ui/Onos.dds", Description = Locale.ResolveString("ONOS_HELP"), Width = GUIScale(304), Height = GUIScale(326) },
							{ DisplayName = Locale.ResolveString("MARINE"), TextureName = "ui/Onos.dds", Description = Locale.ResolveString("MARINE_HELP"), Width = GUIScale(304), Height = GUIScale(326) },
							{ DisplayName = Locale.ResolveString("JETPACK_MARINE"), TextureName = "ui/Onos.dds", Description = Locale.ResolveString("JETPACK_MARINE_HELP"), Width = GUIScale(304), Height = GUIScale(326) },
							{ DisplayName = Locale.ResolveString("HEAVY_ARMOR_MARINE"), TextureName = "ui/Onos.dds", Description = Locale.ResolveString("HEAVY_ARMOR_MARINE_HELP"), Width = GUIScale(304), Height = GUIScale(326) },
							{ DisplayName = Locale.ResolveString("MARINE_COMMANDER"), TextureName = "ui/Onos.dds", Description = Locale.ResolveString("MARINE_COMMANDER_HELP"), Width = GUIScale(304), Height = GUIScale(326) }							
						}

local kClassPicturePosition = GUIScale( Vector(0, 0, 0))
local kClassDescriptionPosition = GUIScale( Vector(400, 50, 0))
local kClassTitlePosition = GUIScale( Vector(470, 10, 0))

local kTitleFont = Fonts.kAgencyFB_Medium
local kDescriptionFont = Fonts.kAgencyFB_Small

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
						
local kWeaponIconSize = GUIScale( Vector(150, 150, 0))
local kWeaponTitleSize = GUIScale(40)
local kWeaponIconPositionTable = GUIScale( Vector(0, 420, 0))
local kWeaponDescriptionTable = GUIScale( Vector(170, 420, 0))
local kMaxWeaponListings = 5

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
								kTechId.ArmsLab
								}

local kUpgradeDetails = {	{ DisplayName = Locale.ResolveString("CARAPACE"), TextureName = "", UnlockedDescription = "Carrypace", LockedDescription = Locale.ResolveString("CARAPACE_LOCKED") },
							{ DisplayName = Locale.ResolveString("REGENERATION"), TextureName = "", UnlockedDescription = "Fade regen", LockedDescription = Locale.ResolveString("REGENERATION_LOCKED") },
							{ DisplayName = Locale.ResolveString("REDEMPTION"), TextureName = "", UnlockedDescription = "Onoooos", LockedDescription = Locale.ResolveString("REDEMPTION_LOCKED") },
							{ DisplayName = Locale.ResolveString("CRAG"), TextureName = "", UnlockedDescription = "Got any shells?", LockedDescription = Locale.ResolveString("CRAG_LOCKED") },
							{ DisplayName = Locale.ResolveString("CELERITY"), TextureName = "", UnlockedDescription = "celery", LockedDescription = Locale.ResolveString("CELERITY_LOCKED") },
							{ DisplayName = Locale.ResolveString("ADRENALINE"), TextureName = "", UnlockedDescription = "hold mouse2", LockedDescription = Locale.ResolveString("ADRENALINE_LOCKED") },
							{ DisplayName = Locale.ResolveString("REDEPLOYMENT"), TextureName = "", UnlockedDescription = "cheaty teleport", LockedDescription = Locale.ResolveString("REDEPLOYMENT_LOCKED") },
							{ DisplayName = Locale.ResolveString("SILENCE"), TextureName = "", UnlockedDescription = "shhhhh", LockedDescription = Locale.ResolveString("SILENCE_LOCKED") },
							{ DisplayName = Locale.ResolveString("SHIFT"), TextureName = "", UnlockedDescription = "shifty", LockedDescription = Locale.ResolveString("SHIFT_LOCKED") },
							{ DisplayName = Locale.ResolveString("SILENCE"), TextureName = "", UnlockedDescription = "stealth shhhh", LockedDescription = Locale.ResolveString("SILENCE_LOCKED") },
							{ DisplayName = Locale.ResolveString("AURA"), TextureName = "", UnlockedDescription = "i see dead people", LockedDescription = Locale.ResolveString("AURA_LOCKED") },
							{ DisplayName = Locale.ResolveString("GHOST"), TextureName = "", UnlockedDescription = "etheral", LockedDescription = Locale.ResolveString("GHOST_LOCKED") },
							{ DisplayName = Locale.ResolveString("CAMOUFLAGE"), TextureName = "", UnlockedDescription = "cloaking is clearly a bad name", LockedDescription = Locale.ResolveString("CAMOUFLAGE_LOCKED") },
							{ DisplayName = Locale.ResolveString("SHADE"), TextureName = "", UnlockedDescription = "shadey", LockedDescription = Locale.ResolveString("SHADE_LOCKED") },
							{ DisplayName = Locale.ResolveString("FOCUS"), TextureName = "", UnlockedDescription = "swipe swipe swipe", LockedDescription = Locale.ResolveString("FOCUS_LOCKED") },
							{ DisplayName = Locale.ResolveString("FURY"), TextureName = "", UnlockedDescription = "swwwwwwwwwwwwwwwiiippppeee", LockedDescription = Locale.ResolveString("FURY_LOCKED") },
							{ DisplayName = Locale.ResolveString("BOMBARD"), TextureName = "", UnlockedDescription = "okay bilebomb", LockedDescription = Locale.ResolveString("BOMBARD_LOCKED") },
							{ DisplayName = Locale.ResolveString("WHIP"), TextureName = "", UnlockedDescription = "whip it good", LockedDescription = Locale.ResolveString("WHIP_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMOR1"), TextureName = "", UnlockedDescription = "+20", LockedDescription = Locale.ResolveString("ARMOR1_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMOR2"), TextureName = "", UnlockedDescription = "+40", LockedDescription = Locale.ResolveString("ARMOR2_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMOR3"), TextureName = "", UnlockedDescription = "+60", LockedDescription = Locale.ResolveString("ARMOR3_LOCKED") },
							{ DisplayName = Locale.ResolveString("WEAPONS1"), TextureName = "", UnlockedDescription = "+10%", LockedDescription = Locale.ResolveString("WEAPONS1_LOCKED") },
							{ DisplayName = Locale.ResolveString("WEAPONS2"), TextureName = "", UnlockedDescription = "+20%", LockedDescription = Locale.ResolveString("WEAPONS2_LOCKED") },
							{ DisplayName = Locale.ResolveString("WEAPONS3"), TextureName = "", UnlockedDescription = "+30%", LockedDescription = Locale.ResolveString("WEAPONS3_LOCKED") },
							{ DisplayName = Locale.ResolveString("MOTION_TRACKING"), TextureName = "", UnlockedDescription = "Piiiiiiiiiing", LockedDescription = Locale.ResolveString("MOTION_TRACKING_LOCKED") },
							{ DisplayName = Locale.ResolveString("HAND_GRENADES"), TextureName = "", UnlockedDescription = "when in doubt nades out", LockedDescription = Locale.ResolveString("HAND_GRENADES_LOCKED") },
							{ DisplayName = Locale.ResolveString("ARMS_LAB"), TextureName = "", UnlockedDescription = "get yo upgrades here", LockedDescription = Locale.ResolveString("ARMS_LAB_LOCKED") }
						}

local kUpgradeIconSize = GUIScale( Vector(100, 100, 0))
local kUpgradeSpacing = GUIScale( Vector(120, 120, 0))
local kUpgradeIconTablePosition = GUIScale( Vector(700, 420, 0))
local kUpgradeTitleSize = GUIScale(40)
local kUpgradeDescriptionTablePosition = GUIScale( Vector(820, 420, 0))
local kMaxUpgrades = 4
local kUpgradesTexture = "ui/buildmenu.dds"

local kGameplayTipsPosition = GUIScale( Vector(820, 40, 0))
local kGameplayTitlePosition = GUIScale( Vector(820, 0, 0))

local kGameplayTips = 	{
							[kAlienTeamType] = 	{
													{ Tip = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_1"), Title = Locale.ResolveString("ALIEN_GAMEPLAY_TITLE_1"), Time = 0 },
													{ Tip = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_2"), Title = Locale.ResolveString("ALIEN_GAMEPLAY_TITLE_2"), Time = 5 },
													{ Tip = Locale.ResolveString("ALIEN_GAMEPLAY_TIPS_3"), Title = Locale.ResolveString("ALIEN_GAMEPLAY_TITLE_3"), Time = 15 }
												},
							[kMarineTeamType] = {
													{ Tip = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_1"), Title = Locale.ResolveString("MARINE_GAMEPLAY_TITLE_1"), Time = 0 },
													{ Tip = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_2"), Title = Locale.ResolveString("MARINE_GAMEPLAY_TITLE_2"), Time = 5 },
													{ Tip = Locale.ResolveString("MARINE_GAMEPLAY_TIPS_3"), Title = Locale.ResolveString("MARINE_GAMEPLAY_TITLE_3"), Time = 15 }
												}
						}

local kBackgroundSize = GUIScale( Vector(1344, 756, 0))
local kWeaponUpgradeUpdateSpeed = 1

class 'GUIHelpScreen' (GUIScript)

local function LookupWeaponList()
    return PlayerUI_GetInventoryTechIds()
end

local function LookupUpgradesList(self)
	local techTable = { }
    local techTree = GetTechTree()
	local upgradeSlots = kUpgradeSlots[self.teamType]
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

local function LookupClassIndex()
    local player = Client.GetLocalPlayer()
    local techId = player:GetTechId()
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
    self.classDisplayIcon:SetSize(Vector(kClassDetails[self.classType].Width, kClassDetails[self.classType].Height, 0))
    self.classDisplayIcon:SetPosition(kClassPicturePosition)
    self.classDisplayIcon:SetTexture(kClassDetails[self.classType].TextureName)
    self.classDisplayIcon:SetLayer(kGUILayerPlayerHUDForeground2)
    self.classDisplayIcon:SetScale(Vector(1.3, 1.3, 0))
    self.background:AddChild(self.classDisplayIcon)
	
	self.classDisplayText = GUIManager:CreateTextItem()
    self.classDisplayText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.classDisplayText:SetPosition(kClassDescriptionPosition)
    self.classDisplayText:SetFontName(kDescriptionFont)
    self.classDisplayText:SetTextAlignmentX(GUIItem.Align_Min)
    self.classDisplayText:SetTextAlignmentY(GUIItem.Align_Min)
    self.classDisplayText:SetText(kClassDetails[self.classType].Description)
    self.classDisplayText:SetColor(ColorIntToColor(self.teamColor))
    self.classDisplayText:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.classDisplayText)
	
	self.classDisplayName = GUIManager:CreateTextItem()
    self.classDisplayName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.classDisplayName:SetPosition(kClassTitlePosition)
    self.classDisplayName:SetFontName(kTitleFont)
    self.classDisplayName:SetTextAlignmentX(GUIItem.Align_Min)
    self.classDisplayName:SetTextAlignmentY(GUIItem.Align_Min)
    self.classDisplayName:SetText(kClassDetails[self.classType].DisplayName)
    self.classDisplayName:SetColor(ColorIntToColor(self.teamColor))
    self.classDisplayName:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.classDisplayName)
	
end

local function InitializeWeaponObjects(self)

	self.weaponObjects = { }

	for i = 1, kMaxWeaponListings do
	
	    self.weaponObjects[i] = { }
		self.weaponObjects[i].icon = GUIManager:CreateGraphicItem()
		self.weaponObjects[i].icon:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.weaponObjects[i].icon:SetSize(kWeaponIconSize)
		self.weaponObjects[i].icon:SetPosition(Vector(kWeaponIconPositionTable.x, kWeaponIconPositionTable.y + (kWeaponIconSize.y * (i - 1)), 0))
		self.weaponObjects[i].icon:SetTexture(kCrapWeaponTexture)
		self.weaponObjects[i].icon:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.weaponObjects[i].icon)
		
		self.weaponObjects[i].description = GUIManager:CreateTextItem()
		self.weaponObjects[i].description:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.weaponObjects[i].description:SetPosition(Vector(kWeaponDescriptionTable.x, kWeaponDescriptionTable.y + kWeaponTitleSize + (kWeaponIconSize.y * (i - 1)), 0))
		self.weaponObjects[i].description:SetFontName(kDescriptionFont)
		self.weaponObjects[i].description:SetTextAlignmentX(GUIItem.Align_Min)
		self.weaponObjects[i].description:SetTextAlignmentY(GUIItem.Align_Min)
		self.weaponObjects[i].description:SetText("")
		self.weaponObjects[i].description:SetColor(ColorIntToColor(self.teamColor))
		self.weaponObjects[i].description:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.weaponObjects[i].description)
		
		self.weaponObjects[i].title = GUIManager:CreateTextItem()
		self.weaponObjects[i].title:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.weaponObjects[i].title:SetPosition(Vector(kWeaponDescriptionTable.x, kWeaponDescriptionTable.y + (kWeaponIconSize.y * (i - 1)), 0))
		self.weaponObjects[i].title:SetFontName(kTitleFont)
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
		self.upgradeObjects[i].description:SetFontName(kDescriptionFont)
		self.upgradeObjects[i].description:SetTextAlignmentX(GUIItem.Align_Min)
		self.upgradeObjects[i].description:SetTextAlignmentY(GUIItem.Align_Min)
		self.upgradeObjects[i].description:SetText("")
		self.upgradeObjects[i].description:SetColor(ColorIntToColor(self.teamColor))
		self.upgradeObjects[i].description:SetLayer(kGUILayerPlayerHUDForeground2)
		self.background:AddChild(self.upgradeObjects[i].description)
		
		self.upgradeObjects[i].title = GUIManager:CreateTextItem()
		self.upgradeObjects[i].title:SetAnchor(GUIItem.Left, GUIItem.Top)
		self.upgradeObjects[i].title:SetPosition(Vector(kUpgradeDescriptionTablePosition.x, kUpgradeDescriptionTablePosition.y + (kUpgradeSpacing.y * (i - 1)), 0))
		self.upgradeObjects[i].title:SetFontName(kTitleFont)
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
					self.upgradeObjects[i].title:SetText(kUpgradeDetails[index].DisplayName)
					self.upgradeObjects[i].icon:SetIsVisible(true)
					self.upgradeObjects[i].description:SetIsVisible(true)
					self.upgradeObjects[i].title:SetIsVisible(true)
					self.upgradeObjects[i].index = index
					self.upgradeObjects[i].status = status
				end
			end
		end
		self.lastupgradelist = self.upgradeList
	end
	
end

local function InitializeGameplaySuggestions(self)

	self.gameplayDisplayText = GUIManager:CreateTextItem()
    self.gameplayDisplayText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.gameplayDisplayText:SetPosition(kGameplayTipsPosition)
    self.gameplayDisplayText:SetFontName(kDescriptionFont)
    self.gameplayDisplayText:SetTextAlignmentX(GUIItem.Align_Min)
    self.gameplayDisplayText:SetTextAlignmentY(GUIItem.Align_Min)
    self.gameplayDisplayText:SetText("")
    self.gameplayDisplayText:SetColor(ColorIntToColor(self.teamColor))
    self.gameplayDisplayText:SetLayer(kGUILayerPlayerHUDForeground2)
    self.background:AddChild(self.gameplayDisplayText)

	self.gameplayDisplayName = GUIManager:CreateTextItem()
    self.gameplayDisplayName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.gameplayDisplayName:SetPosition(kGameplayTitlePosition)
    self.gameplayDisplayName:SetFontName(kTitleFont)
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
					self.gameplayDisplayText:SetText(teamGameplay[i].Tip)
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
	self.classType = LookupClassIndex()
	self.weaponList = LookupWeaponList()
	self.upgradeList = LookupUpgradesList(self)
	self.gametime = LookupGameTimeinMinutes()
	
	if self.teamType == kAlienTeamType then
		self.teamColor = kAlienTeamColor 
	elseif self.teamType == kMarineTeamType then
		self.teamColor = kMarineTeamColor
	else
		self.teamColor = kNeutralTeamColor
	end
	
	if self.classType > 0 then
		//Init stuff - player is a valid 'class'
		InitializeClassObjects(self)
		InitializeGameplaySuggestions(self)
		InitializeWeaponObjects(self)
		InitializeUpgradeObjects(self)
		//Update Stuff?
		UpdateWeaponObjects(self)
		UpdateUpgradeObjects(self)
		UpdateGameplaySuggestions(self)
	end

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
		self.weaponList = LookupWeaponList()
		self.upgradeList = LookupUpgradesList(self)
		self.gametime = LookupGameTimeinMinutes()
		self.lastFullupdate = 0
	end
    
    if self.helpScreenButton then
		
		//Update weapon/upgrade tables on a slower cycle.  Might not need this..
		self.lastFullupdate = self.lastFullupdate + deltaTime
		if self.lastFullupdate > kWeaponUpgradeUpdateSpeed then
			self.weaponList = LookupWeaponList()
			self.upgradeList = LookupUpgradesList(self)
			self.gametime = LookupGameTimeinMinutes()
			UpdateWeaponObjects(self)
			UpdateUpgradeObjects(self)
			UpdateGameplaySuggestions(self)
			self.lastFullupdate = self.lastFullupdate - kWeaponUpgradeUpdateSpeed
		end		
		
    end
	
	self.background:SetIsVisible(self.helpScreenButton)
	self.lastButtonState = self.helpScreenButton

end