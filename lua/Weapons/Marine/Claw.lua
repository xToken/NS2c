// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\Claw.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/Marine/Welder.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponSlotMixin.lua")

class 'Claw' (Welder)

Claw.kMapName = "claw"

local networkVars = { }

AddMixinNetworkVars(ExoWeaponSlotMixin, networkVars)

function Claw:OnCreate()

    Welder.OnCreate(self)
    
    InitMixin(self, ExoWeaponSlotMixin)
    
    self.clawAttacking = false
    
end

function Claw:GetDeathIconIndex()
    return kDeathMessageIcon.Claw
end

function Claw:GetWeight()
    return kClawWeight
end

function Claw:OnTag()
end

Shared.LinkClassToMap("Claw", Claw.kMapName, networkVars)