-- NS2c_Shared.lua

Script.Load("lua/ns2c/TurretFactory.lua")
Script.Load("lua/ns2c/SiegeCannon.lua")
Script.Load("lua/ns2c/HeavyArmorMarine.lua")
Script.Load("lua/ns2c/HeavyArmor.lua")
Script.Load("lua/ns2c/Weapons/Marine/Mines.lua")
Script.Load("lua/ns2c/Weapons/Marine/HandGrenades.lua")

-- Load this last to hopefully attempt to support any latehook mods.
Script.Load("lua/ns2c/Mixins/WaterModSupport.lua")
Script.Load("lua/ns2c/Mixins/ExoCrashFix.lua")
Script.Load("lua/ns2c/Mixins/NS2PlusSupport.lua")

-- Load Overloads for Classic - Use these for simple changes to avoid complete file replacement
Script.Load("lua/ns2c/Overloads/SensorBlip.lua")
Script.Load("lua/ns2c/Overloads/Ladder.lua")