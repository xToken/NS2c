
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kStationBuildDist = 15.0

local function CreateBuildNearStationAction( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureAction(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "CommandStation",
            kStationBuildDist )
end

//----------------------------------------
//  
//----------------------------------------

kMarineComBrainActions = 
{
    CreateBuildNearStationAction( kTechId.Armory         , "Armory"         , 1 , 1.1 )             , 
    CreateBuildNearStationAction( kTechId.InfantryPortal , "InfantryPortal" , 2 , 1+math.random() ) , 
    CreateBuildNearStationAction( kTechId.Observatory    , "Observatory"    , 1 , 1+math.random() ) , 
    CreateBuildNearStationAction( kTechId.PhaseGate      , "PhaseGate"      , 1 , 1+math.random() ) , 
    CreateBuildNearStationAction( kTechId.ArmsLab        , "ArmsLab"        , 1 , 1+math.random() ) , 
    CreateBuildNearStationAction( kTechId.PrototypeLab   , "PrototypeLab"   , 1 , 1+math.random() ) , 

    // Upgrades from structures
    //CreateUpgradeStructureAction( kTechId.ShotgunTech           , 1.0 ) , 
    //CreateUpgradeStructureAction( kTechId.MinesTech             , 1.0+math.random() ) , 
    //CreateUpgradeStructureAction( kTechId.WelderTech            , 1.0+math.random() ) , 
    CreateUpgradeStructureAction( kTechId.AdvancedArmoryUpgrade , 1.0+math.random() ) , 
    // TODO

    CreateUpgradeStructureAction( kTechId.PhaseTech , 1.0+math.random() ),

    CreateUpgradeStructureAction( kTechId.Weapons1 , 1.0+math.random() ) , 
    CreateUpgradeStructureAction( kTechId.Weapons2 , 1.0+math.random() ) , 
    CreateUpgradeStructureAction( kTechId.Weapons3 , 1.0+math.random() ) , 
    CreateUpgradeStructureAction( kTechId.Armor1   , 1.0+math.random() ) , 
    CreateUpgradeStructureAction( kTechId.Armor2   , 1.0+math.random() ) , 
    CreateUpgradeStructureAction( kTechId.Armor3   , 1.0+math.random() ) , 

    function(bot, brain)

        local name = "extractor"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetRP = nil

        if doables[kTechId.Extractor] ~= nil then

            targetRP = sdb:Get("resPointToTake")

            if targetRP ~= nil then
                weight = EvalLPF( sdb:Get("numExtractors"),
                        {
                        {0, 2},
                        {1, 1.5},
                        {2, 1.1},
                        {3, 1.0}
                        })
            end

        end

        return { name = name, weight = weight,
            perform = function(move)
                if targetRP ~= nil then
                    local success = brain:ExecuteTechId( com, kTechId.Extractor, targetRP:GetOrigin(), com )
                end
            end}
    end,

    function(bot, brain)

        return { name = "idle", weight = 1e-5,
            perform = function(move)
                if brain.debug then
                    DebugPrint("idling..")
                end 
            end}
    end
}

//----------------------------------------
//  Build the senses database
//----------------------------------------

function CreateMarineComSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("gameMinutes", function(db)
            return (Shared.GetTime() - GetGamerules():GetGameStartTime()) / 60.0
            end)

    s:Add("doableTechIds", function(db)
            return db.bot.brain:GetDoableTechIds( db.bot:GetPlayer() )
            end)

    s:Add("stations", function(db)
            return GetEntitiesForTeam("CommandStation", kMarineTeamType)
            end)

    s:Add("availResPoints", function(db)
            return GetAvailableResourcePoints()
            end)

    s:Add("numExtractors", function(db)
            return GetNumEntitiesOfType("Extractor", kMarineTeamType)
            end)

    s:Add("resPointToTake", function(db)
            local rps = db:Get("availResPoints")
            local stations = db:Get("stations")
            local dist, rp = GetMinTableEntry( rps, function(rp)
                return GetMinDistToEntities( rp, stations )
                end)
            return rp
            end)

    return s

end

//----------------------------------------
//  
//----------------------------------------
