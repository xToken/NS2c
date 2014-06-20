// Fixes for missing stuff.
class 'LayMines' (Weapon)
LayMines.kMapName = "laymines"

function LayMines:GetIsValidRecipient(recipient)
	return false
end

Shared.LinkClassToMap("LayMines", LayMines.kMapName)

class 'BoneWall' (CommanderAbility)
BoneWall.kMapName = "bonewall"

function BoneWall:OnCreate()
end

Shared.LinkClassToMap("BoneWall", BoneWall.kMapName)

class 'FlamethrowerAmmo' (WeaponAmmoPack)
FlamethrowerAmmo.kMapName = "flamethrowerammo"

Shared.LinkClassToMap("FlamethrowerAmmo", FlamethrowerAmmo.kMapName)

class 'LerkBite' (Ability)
LerkBite.kMapName = "lerkbite"

function LerkBite:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

Shared.LinkClassToMap("LerkBite", LerkBite.kMapName)

class 'StabBlink' (Ability)
StabBlink.kMapName = "stabblink"

function StabBlink:OnTag()
end

Shared.LinkClassToMap("StabBlink", StabBlink.kMapName)

class 'Drifter' (ScriptActor)
Drifter.kMapName = "drifter"

local function IsBeingGrown()
end

function Drifter:OnOverrideOrder()
    IsBeingGrown()
end

Shared.LinkClassToMap("Drifter", Drifter.kMapName)

FireMixin = { }

local function SharedUpdate()
end

function FireMixin:OnUpdate()
    SharedUpdate()
end

Flame= { }
Flame.kMapName = "flame"

ClusterGrenade= { }
ClusterGrenade.kMapName = "clustergrenade"

ClusterFragment = { }
ClusterFragment.kMapName = "clusterfragment"

NerveGasCloud = { }
NerveGasCloud.kMapName = "nervegascloud"

PulseGrenade = { }
PulseGrenade.kMapName = "pulsegrenade"

DotMarker = { }
DotMarker.kMapName = "dotmarker"

WhipBomb = { }
WhipBomb.kMapName = "whipbomb"