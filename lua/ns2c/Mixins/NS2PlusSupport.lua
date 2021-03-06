// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c 
// lua\Mixins\NS2PlusSupport.lua
// - Dragon

ExoWeaponHolder = { }
ExoWeaponHolder.kSlotNames = enum({ 'Left', 'Right' })

HallucinationCloud = { }

local function ExecuteShot()
end

local function DummyFunc()
	ExecuteShot()
end

Railgun = { }
Railgun.OnTag = DummyFunc

BoneWall = { }
BoneWall.kModelName = PrecacheAsset("models/alien/infestationspike/infestationspike.model")

EnzymeCloud = { }
EnzymeCloud.kRadius = 0

MucousMembrane = { }
MucousMembrane.kRadius = 0

NutrientMist = { }
NutrientMist.kSearchRange = 0

Rupture = { }
Rupture.kRadius = 0

function Marine:GetIsVortexed()
    return false
end

function Alien:GetHasMucousShield()
    return false
end

function Alien:GetMuscousShieldAmount()
    return 0
end

function Alien:GetMaxShieldAmount()
    return 0
end

function Alien:GetShieldPercentage()
    return 0
end

function Hive:GetBioMassLevel()
    return 0
end

local function GetChambersMod(chamber, teamNumber)
    local gameInfo = GetGameInfoEntity()
    if gameInfo and gameInfo:GetGameMode() == kGameMode.Combat then
        return 3
    else
        local teamInfo = GetTeamInfoEntity(teamNumber)
        if teamInfo then
            return teamInfo:GetNumUpgradeStructures(chamber)
        end
    end
end

function GetShellLevel(teamNumber)
    return GetChambersMod(kTechId.Crag, teamNumber)
end

function GetSpurLevel(teamNumber)
    return GetChambersMod(kTechId.Shift, teamNumber)
end

function GetVeilLevel(teamNumber)
    return GetChambersMod(kTechId.Shade, teamNumber)
end