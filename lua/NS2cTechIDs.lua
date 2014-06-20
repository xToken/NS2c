Script.Load( "lua/Mixins/Elixer_Utility.lua" )
Elixer.UseVersion( 1.5 )

local ClassicTechIds =
{
'AlienAlertHiveSpecialComplete',
'AlienAlertEnemyApproaches',
'Redemption',
'Focus',
'Silence2',
'Fury',
'Bombard',
'Redeployment',
'Ghost',
'UpgradeToWhipHive',
'WhipHive',
'Devour',
'Metabolize',
'AcidRocket',
'WebStalk',
'PrimalScream',

'MotionTracking',
'HeavyMachineGun',
'Mines',
'HeavyArmor',
'HeavyArmorTech',
'HandGrenades',
'HandGrenadesTech',
'Electrify',
'SiegeCannon',
'TurretFactory',
'AdvancedTurretFactory',
'UpgradeTurretFactory',
'HeavyArmorMarine',
'AllMarines',
}

for _, v in ipairs( ClassicTechIds ) do
	AppendToEnum( kTechId, v )
end