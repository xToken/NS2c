// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\TurretFactoryMixin.lua
// - Dragon

Script.Load("lua/FunctionContracts.lua")

TurretFactoryMixin = CreateMixin( TurretFactoryMixin )
TurretFactoryMixin.type = "TurretFactory"

TurretFactoryMixin.expectedCallbacks =
{
}

function TurretFactoryMixin:__initmixin()
    if Server then
        self.powerConsumerIds = {}
    end
end

if Server then

    local function OnTFacDestroyed(self)

        for _, powerConsumerId in ipairs(self.powerConsumerIds) do
            local powerConsumer = Shared.GetEntity(powerConsumerId)
            if powerConsumer and HasMixin(powerConsumer, "TurretMixin") then
                powerConsumer:OnTurretFactoryDestroyed(self)
            end
        end

    end
    
    local function ScanForUnPoweredTurrets(self)
        local turrets = GetEntitiesWithMixin("Turret")
        Shared.SortEntitiesByDistance(self:GetOrigin(), turrets)
        for index, turret in ipairs(turrets) do
            local toTarget = turret:GetOrigin() - self:GetOrigin()
            local distanceToTarget = toTarget:GetLength()
            if distanceToTarget < kTurretFactoryAttachRange and GetIsUnitActive(turret) then
                if (turret:GetRequiresAdvanced() and self:GetTechId() == kTechId.AdvancedTurretFactory) or not turret:GetRequiresAdvanced() then
                    turret:OnTurretFactoryCompleted()
                end
            end
        end
    end
    
    function TurretFactoryMixin:AddConsumer(consumer)
        assert(consumer)
        table.insertunique(self.powerConsumerIds, consumer:GetId())
    end
    
    function TurretFactoryMixin:RemoveConsumer(consumer)
        assert(consumer)
        table.remove(self.powerConsumerIds, consumer:GetId())
    end
    
    function TurretFactoryMixin:OnKill()
        OnTFacDestroyed(self)
    end

    function TurretFactoryMixin:OnDestroy()
        OnTFacDestroyed(self)
    end
    
    function TurretFactoryMixin:OnEntityChange(oldId, newId)
        ScanForUnPoweredTurrets(self)
    end
    
    function TurretFactoryMixin:OnRecycled()
        OnTFacDestroyed(self)
    end
    
    function TurretFactoryMixin:OnConstructionComplete()
        ScanForUnPoweredTurrets(self)
    end

end