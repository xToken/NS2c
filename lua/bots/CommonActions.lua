//----------------------------------------
//  Collection of common actions shared between many brains
//----------------------------------------

function CreateExploreAction( weightIfTargetAcquired, moveToFunction )

    return function(bot, brain)

        local name = "explore"
        local player = bot:GetPlayer()
        local origin = player:GetOrigin()

        local findNew = true
        if brain.exploreTargetId ~= nil then
            local target = Shared.GetEntity(brain.exploreTargetId)
            if target ~= nil then
                local dist = target:GetOrigin():GetDistance(origin)
                if dist > 5.0 then
                    findNew = false
                end
            end
        end

        if findNew then

            local memories = GetTeamMemories( player:GetTeamNumber() )
            local exploreMems = FilterTable( memories,
                    function(mem)
                        return mem.entId ~= brain.exploreTargetId
                            and ( mem.btype == kMinimapBlipType.ResourcePoint
                                or mem.btype == kMinimapBlipType.TechPoint )
                    end )

            // pick one randomly
            if #exploreMems > 0 then
                local targetMem = exploreMems[ math.random(#exploreMems) ]
                brain.exploreTargetId = targetMem.entId
            else
                brain.exploreTargetId = nil
            end
        end

        local weight = 0.0
        if brain.exploreTargetId ~= nil then
            weight = weightIfTargetAcquired
        end

        return { name = name, weight = weight,
            perform = function(move)
                local target = Shared.GetEntity( brain.exploreTargetId )
                if brain.debug then
                    DebugPrint("exploring to move target %s", ToString(target:GetOrigin()))
                end

                moveToFunction( origin, target:GetOrigin(), bot, brain, move )
            end }
    end

end


//----------------------------------------
//  Commander stuff
//----------------------------------------

function CreateBuildStructureAction( techId, className, numExistingToWeightLPF, buildNearClass, maxDist )

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]

        // find structures we can build near
        local hosts = GetEntitiesForTeam( buildNearClass, com:GetTeamNumber() )

        if coms ~= nil and #coms > 0
        and hosts ~= nil and #hosts > 0 then
            assert( coms[1] == com )

            // figure out how many exist already
            local existingEnts = GetEntitiesForTeam( className, com:GetTeamNumber() )
            weight = EvalLPF( #existingEnts, numExistingToWeightLPF )
        end

        return { name = name, weight = weight,
            perform = function(move)

                // Pick a random host for now
                local host = hosts[ math.random(#hosts) ]
                local pos = GetRandomBuildPosition( techId, host:GetOrigin(), maxDist )
                if pos ~= nil then
                    brain:ExecuteTechId( com, techId, pos, com )
                end

            end }
    end

end

function CreateUpgradeStructureAction( techId, weightIfCanDo, existingTechId )

    return function(bot, brain)

        local name = EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local structures = doables[techId]

        if structures ~= nil then

            weight = weightIfCanDo

            // but if we have the upgrade already, halve the weight
            // TODO THIS DOES NOT WORK WTFFF
            if existingTechId ~= nil then
//                DebugPrint("Checking if %s exists..", EnumToString(kTechId, existingTechId))
                if com:GetTechTree():GetHasTech(existingTechId) then
                    DebugPrint("halving weight for already having %s", name)
                    weight = weight * 0.5
                end
            end

        end

        return {
            name = name, weight = weight,
            perform = function(move)

                if structures == nil then return end
                // choose a random host
                local host = structures[ math.random(#structures) ]
                brain:ExecuteTechId( com, techId, Vector(0,0,0), host )

            end }
    end

end
