// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAssets.lua
//
// Created by: Mats Olsson (mats.olsson@matsotech.se)
//
// All assets used by GUIView scripts must be Precached here.
//
// The NS2 GUI system are run both in the main Lua VM and in the per-GUIView Lua VMs.
// The per-view VMs are loaded on demand when a new GUI-display are needed. As this pretty
// much only happens when you change weapons, the extra cost to create a VM and compile
// the (small) scripts used by it do not impact gameplay much - as long as the resources 
// used by the scripts are precached.
//
// This file is loaded by the main Client VM before any GUIViews are created. By listing
// the assets here, we can make sure that they do not cause hitching problems later.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Fonts = {}
Textures = {}
Materials = {}
Sounds = {}
Shaders = {}
Models = {}

// Used by GUIView paths
PrecacheAsset = PrecacheAsset or function(name) return name end 

// Keep sorted for easy lookup, please
Fonts.kAgencyFB_Huge = PrecacheAsset("fonts/AgencyFB_huge.fnt")
Fonts.kAgencyFB_Large_Bold = PrecacheAsset("fonts/AgencyFB_large_bold.fnt")
Fonts.kAgencyFB_Large = PrecacheAsset("fonts/AgencyFB_large.fnt")
Fonts.kAgencyFB_Medium = PrecacheAsset("fonts/AgencyFB_medium.fnt")
Fonts.kAgencyFB_Small = PrecacheAsset("fonts/AgencyFB_small.fnt")
Fonts.kAgencyFB_Smaller_Bordered = PrecacheAsset("fonts/AgencyFB_smaller_bordered.fnt")
Fonts.kAgencyFB_Tiny= PrecacheAsset("fonts/AgencyFB_tiny.fnt")
Fonts.kInsight = PrecacheAsset("fonts/insight.fnt")
Fonts.kArial_15 = PrecacheAsset("fonts/Arial_15.fnt")
Fonts.kArial_17 = PrecacheAsset("fonts/Arial_17.fnt")
Fonts.kKartika_Small = PrecacheAsset("fonts/Kartika_small.fnt")
Fonts.kStamp_Large = PrecacheAsset("fonts/Stamp_large.fnt")
Fonts.kStamp_Medium = PrecacheAsset("fonts/Stamp_medium.fnt")
Fonts.kStamp_Huge = PrecacheAsset("fonts/Stamp_huge.fnt")
Fonts.kMicrogrammaDMedExt_Large = PrecacheAsset("fonts/MicrogrammaDMedExt_large.fnt")
Fonts.kMicrogrammaDMedExt_Medium = PrecacheAsset("fonts/MicrogrammaDMedExt_medium.fnt")
Fonts.kMicrogrammaDMedExt_Medium2 = PrecacheAsset("fonts/MicrogrammaDMedExt_medium2.fnt")
Fonts.kMicrogrammaDMedExt_Small = PrecacheAsset("fonts/MicrogrammaDMedExt_small.fnt")
Fonts.kLMGFont = PrecacheAsset("fonts/LMGFont.fnt")

---------------
Textures.kExosuit_View_Panel_Armor = PrecacheAsset("models/marine/exosuit/exosuit_view_panel_armor.dds")

Textures.kCommanderBar = PrecacheAsset("ui/commanderbar.dds")
Textures.kCrosshairIcons = PrecacheAsset("ui/crosshairicons.dds")
Textures.kCrosshairs = PrecacheAsset("ui/crosshairs.dds")
Textures.kCrosshairsHit = PrecacheAsset("ui/crosshairs-hit.dds")
Textures.kCrosshairHit = PrecacheAsset("ui/crosshairs-hit.dds")
Textures.kHealthCircle = PrecacheAsset("ui/health_circle.dds")

Textures.kShotgunDisplay = PrecacheAsset("ui/ShotgunDisplay.dds")
Textures.kWelderSquares = PrecacheAsset("ui/WelderSquares.dds")

Textures.kInventoryIcons = PrecacheAsset("ui/inventory_icons.dds")
Textures.kAlienBuyMenu = PrecacheAsset("ui/alien_buymenu.dds")
Textures.kAlienEvolution = PrecacheAsset("ui/alien_evolution.dds")
Textures.kAlienLogoutSmkMask = PrecacheAsset("ui/alien_logout_smkmask.dds")
Textures.kBiomassBar = PrecacheAsset("ui/biomass_bar.dds")
Textures.kEgg = PrecacheAsset("ui/Egg.dds")

Textures.kAlienRequestMenu = PrecacheAsset('ui/alien_request_menu.dds')
Textures.kAlienRequestButton = PrecacheAsset('ui/alien_request_button.dds')

Textures.kFade = PrecacheAsset('ui/Fade.dds')
Textures.kGorge = PrecacheAsset('ui/Gorge.dds')
Textures.kLerk = PrecacheAsset('ui/Lerk.dds')
Textures.kOnos = PrecacheAsset('ui/Onos.dds')
Textures.kSkulk = PrecacheAsset('ui/Skulk.dds')

Textures.kAlienBuymenuMask = PrecacheAsset('ui/alien_buymenu_mask.dds')
Textures.kAlienBuyslot = PrecacheAsset('ui/alien_buyslot.dds')
Textures.kAlienBuyslotLocked = PrecacheAsset('ui/alien_buyslot_locked.dds') 
Textures.kAlienBackground = PrecacheAsset('ui/AlienBackground.dds')
Textures.kPresIconBig = PrecacheAsset('ui/pres_icon_big.dds')
Textures.kFadeBlink = PrecacheAsset('ui/fade_blink.dds')
Textures.kGorgeSpit = PrecacheAsset('ui/gorge_spit.dds')
Textures.kBabblerMoveIcons = PrecacheAsset('ui/babbler_move_icons.dds')
Textures.kAlienBlood1 = PrecacheAsset('ui/damageFeedback/alien_blood1.dds')
Textures.kAlienBlood2 = PrecacheAsset('ui/damageFeedback/alien_blood2.dds')

---------------------

Models.kLerkViewSpike = PrecacheAsset('models/alien/lerk/lerk_view_spike.model')



----------------



  
-----

// Each GUIView has its own GUISystem with its own surfaceShader manager that has a different template than the
// standard VM. So they cannot share precaching of them - the standard VM fails to compile them. *sigh*
//Shaders.kGUIWavyNoMask = PrecacheAsset("shaders/GUIWavyNoMask.surface_shader")
//Shaders.kGUISystem = PrecacheAsset("shaders/GUISystem.hlsl")
//Shaders.kGUIBasic = PrecacheAsset("shaders/GUIBasic.surface_shader")
//Shaders.kGUISmoke = PrecacheAsset("shaders/GUISmoke.surface_shader")

// CQ: Should replace this list with proper constants like the above...
local shaderList = {
    'cinematics/vfx_materials/2em_scroll_vtxcolor.surface_shader',
    'cinematics/vfx_materials/Emissive_glow.surface_shader',
    'cinematics/vfx_materials/bilebomb.surface_shader',
    'cinematics/vfx_materials/bilebomb_exoview.surface_shader',
    'cinematics/vfx_materials/build.surface_shader',
    'cinematics/vfx_materials/burning.surface_shader',
    'cinematics/vfx_materials/burning_view.surface_shader',
    'cinematics/vfx_materials/decals/alien_blood.surface_shader',
    'cinematics/vfx_materials/decals/env_wet.surface_shader',
    'cinematics/vfx_materials/decals/railgun_hole.surface_shader',
    'cinematics/vfx_materials/decals/shockwave_crack.material',
    'cinematics/vfx_materials/decals/shockwave_crack.dds',
    'cinematics/vfx_materials/decals/shockwave_crack_normal.dds',
    'cinematics/vfx_materials/decals/shockwave_crack_specular.dds',
    'cinematics/vfx_materials/decals/shockwave_crack_opacity.dds',
    'cinematics/vfx_materials/drips.surface_shader',
    'cinematics/vfx_materials/elec_trails.surface_shader',
    'cinematics/vfx_materials/forcefield.surface_shader',
    'cinematics/vfx_materials/nanoshield.surface_shader',
    'cinematics/vfx_materials/nanoshield_exoview.surface_shader',
    'cinematics/vfx_materials/nanoshield_view.surface_shader',
    'cinematics/vfx_materials/parasited.surface_shader',
    'cinematics/vfx_materials/pulse_gre_elec.material',
    'cinematics/vfx_materials/refract_emissive_normal.surface_shader',
    'cinematics/vfx_materials/refract_flame_01_normal.dds',
    'cinematics/vfx_materials/refract_normal.surface_shader',
    'cinematics/vfx_materials/rupture.surface_shader',
    'cinematics/vfx_materials/sprinklers.surface_shader',
    'cinematics/vfx_materials/window_rain.surface_shader',
    'materials/biodome/biodome_glass.surface_shader',
    'materials/effects/mesh_effects/view_blood.surface_shader',
    'materials/effects/mesh_effects/view_spit.surface_shader',
    'materials/infestation/infestation_decal.surface_shader',
    'materials/power/powered_decal.surface_shader',
    'models/alien/alien.surface_shader',
    'models/alien/alien_alpha.surface_shader',
    'models/alien/cyst/cyst.surface_shader',
    'models/effects/descent_gravity_ceiling.dds',
    'models/hologram.surface_shader',
    'models/marine/Dropship/dropship_fx_thrusters.surface_shader',
    'models/marine/exosuit/exosuit.surface_shader',
    'models/marine/marine.surface_shader',
    'models/marine/marine_noemissive.surface_shader',
    'models/marine/prototype_lab/prototype_lab_screen.surface_shader',
    'models/props/descent/descent_skybox_planet.surface_shader',
    'models/props/descent/descent_skybox_planet_asteroids.surface_shader',
    'models/props/descent/descent_skybox_planet_ring.surface_shader',
    'models/props/docking/docking_shower_fx_puddle.surface_shader',
    'shaders/Decal.surface_shader',
    'shaders/Emissive.surface_shader',
    'shaders/ExoView.surface_shader',
    'shaders/Level.surface_shader',
    'shaders/Level_alpha.surface_shader',
    'shaders/Level_emissive.surface_shader',
    'shaders/MarinePatch.surface_shader',
    'shaders/Model.surface_shader',
    'shaders/Model_alpha.surface_shader',
    'shaders/Model_emissive.surface_shader',
    'shaders/Model_emissive_alpha.surface_shader',
    'shaders/SkyBox.surface_shader',
    'shaders/WeaponView.surface_shader',
    'shaders/WeaponView_emissive.surface_shader',
    'shaders/emissive.surface_shader',
    'shaders/glass_refract.surface_shader',
    'shaders/water_refract.surface_shader',
}

// 
// should search-n-replace these in the lua files - or at least ensure they are precached
//
local texturesList = {
    'ui/Cursor_MarineCommanderDefault.dds',
    'ui/Cursor_MenuDefault.dds',
    'ui/alien_minimap_smkmask.dds',
    'ui/black_dot.dds',
    'ui/blip.dds',
    'ui/commanderping.dds',
    'ui/damageFeedback/blood1.dds',
    'ui/damageFeedback/blood2.dds',
    'ui/hud_damage_arrow.dds',
    'ui/hud_elements.dds',
    'ui/insight_resources.dds',
    'ui/leftbox.dds',
    'ui/mapconnector_line.dds',
    'ui/marine_buy_bigicons.dds',
    'ui/marine_buymenu_button.dds',
    'ui/marine_buymenu_selector.dds',
    'ui/marine_jetpackfuel.dds',
    'ui/marine_request_button.dds',
    'ui/marine_request_menu.dds',
    'ui/menu/arrow_horiz.dds',
    'ui/menu/blinking_arrow.dds',
    'ui/menu/grid.dds',
    'ui/menu/nonfavorite.dds',
    'ui/menu/repeating_bg.dds',
    'ui/menu/repeating_bg_black.dds',
    'ui/menu/scanLine_big.dds',
    'ui/minimap_blip.dds',
    'ui/objectives_alien.dds',
    'ui/objectives_marine.dds',
    'ui/readyroomorders.dds',
    'ui/rightbox.dds',
    'ui/sensor.dds',
    'ui/speaker.dds',
    'ui/transparent.dds',
    'ui/unitstatus_alien.dds',
    "ui/fade_shadow.dds",
    "ui/Cursor_MenuDefault.dds",
    'ui/Cursor_AlienCommanderDefault.dds',
    'ui/Cursor_FriendlyAction.dds',
    'ui/Cursor_BuildTargetDefault.dds',
    'ui/alien_commander_alert_badge.dds',
    'ui/parasite.dds',
    'ui/alien_commander_textures.dds',
    'ui/alien_commander_smkmask.dds',
    'ui/alien_commander_tabs.dds',
    'ui/alien_buildmenu_highlight.dds',
    'ui/alien_buildmenu_buttonbg.dds',
    'ui/alien_command_cooldown.dds',
    'ui/alien_commander_logout.dds',
    'ui/alien_ressources_smkmask.dds',
    'ui/alien_buildmenu_profile.dds',
    'ui/marine_commander_tabs.dds',
    'ui/marine_buildmenu_highlight.dds',
    'ui/marine_buildmenu_buttonbg.dds',
    'ui/marine_command_cooldown.dds',
    'ui/marine_commander_logout.dds',
    'ui/electric.dds',
    'ui/commander_alert_badge.dds',
    'ui/order_line.dds',
    'ui/drop_icons.dds',
    'ui/healthbarsmall.dds',
	'ui/lmgdisplay.dds'
}


// convinience to keep things neat and sorted
local showSorted = false
for _,tab in ipairs({shaderList, texturesList}) do
  table.sort(tab)
  local duplicateSet = {}
  for _,name in ipairs(tab) do
      if showSorted then
          if not duplicateSet[name] then
              Print("    '%s',", name)
              duplicateSet[name] = true
          end
      end
      PrecacheAsset(name)
  end
end

