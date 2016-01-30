local kModelName = PrecacheAsset("models/marine/exosuit/exosuit_cm.model")
local kAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_cm.animation_graph")

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