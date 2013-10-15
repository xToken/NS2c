
Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local gMarineAimJitterAmount = 0.8

//----------------------------------------
//  Data includes values, but also functions.
//  We put them in this file so we can easily hotload it and iterate live.
//  Nothing in this file should affect other game state, except where it is used.
//----------------------------------------

//----------------------------------------
//  Phase gates
//----------------------------------------
local function FindNearestPhaseGate(fromPos, favoredGateId)

    local gates = GetEntitiesForTeam( "PhaseGate", kMarineTeamType )

    return GetMinTableEntry( gates,
            function(gate)

                assert( gate ~= nil )

                if gate:GetIsBuilt() and gate:GetIsPowered() then

                    local dist = fromPos:GetDistance(gate:GetOrigin())
                    if gate:GetId() == favoredGateId then
                        return dist * 0.9
                    else
                        return dist
                    end

                else
                    return nil
                end

            end)

end

//----------------------------------------
//  Returns the distance, maybe using phase gates.
//----------------------------------------
local function GetPhaseDistanceForMarine( marinePos, to, lastNearestGateId )

    local p0Dist, p0 = FindNearestPhaseGate(marinePos, lastNearestGateId)
    local p1Dist, p1 = FindNearestPhaseGate(to, nil)
    local euclidDist = marinePos:GetDistance(to)

    // Favor the euclid dist just a bit..to prevent thrashing
    if p0Dist ~= nil and p1Dist ~= nil and (p0Dist + p1Dist) < euclidDist*0.9 then
        return (p0Dist + p1Dist), p0
    else
        return euclidDist, nil
    end

end


//----------------------------------------
//  Handles things like using phase gates
//----------------------------------------
local function PerformMove( marinePos, targetPos, bot, brain, move )

    local dist, gate = GetPhaseDistanceForMarine( marinePos, targetPos, brain.lastGateId )

    if gate ~= nil then

        local gatePos = gate:GetOrigin()
        bot:GetMotion():SetDesiredMoveTarget( gatePos )
        bot:GetMotion():SetDesiredViewTarget( nil )
        brain.lastGateId = gate:GetId()

    else

        bot:GetMotion():SetDesiredMoveTarget( targetPos )
        bot:GetMotion():SetDesiredViewTarget( nil )
        brain.lastGateId = nil

    end
end

//----------------------------------------
//  
//----------------------------------------
local function GetCanAttack(marine)
    local weapon = marine:GetActiveWeapon()
    if weapon ~= nil then
        if weapon:isa("ClipWeapon") then
            return weapon:GetAmmo() > 0
        else
            return true
        end
    else
        return false
    end
end

//----------------------------------------
//  Utility perform function used by multiple wants
//----------------------------------------

local function PerformAttackEntity( eyePos, target, lastSeenPos, bot, brain, move )

    assert(target ~= nil )

    if not target.GetIsSighted then
        Print("attack target has no GetIsSighted: %s", target:GetClassName() )
    end

    local sighted = target:GetIsSighted()
    local aimPos = sighted and GetBestAimPoint( target ) or lastSeenPos
    local dist = GetDistanceToTouch( eyePos, target )
    local doFire = false

    // Avoid doing expensive vis check if we are too far
    // TODO we should cache this, because we probably already did the vis check when evaluating its urgency
    local hasClearShot = dist < 20.0 and GetBotCanSeeTarget( bot:GetPlayer(), target )

    if not hasClearShot then

        // just keep moving along the path to find it
        PerformMove( eyePos, aimPos, bot, brain, move )
        doFire = false

    else

        if dist > 40.0 then
            // close in on it first without firing
            bot:GetMotion():SetDesiredMoveTarget( aimPos )
            doFire = false
        elseif dist > 15.0 then
            // move towards it while firing
            bot:GetMotion():SetDesiredMoveTarget( aimPos )
            doFire = true
        elseif dist < 10.0 then
            // too close - back away while firing
            bot:GetMotion():SetDesiredMoveTarget( nil )
            bot:GetMotion():SetDesiredMoveDirection( -( aimPos-eyePos ) )
            doFire = true
        else
            // good distance
            // TODO strafe with some regularity
            bot:GetMotion():SetDesiredMoveTarget(nil)
            bot:GetMotion():SetDesiredMoveDirection(nil)
            doFire = true
        end
    end

    if doFire then
        // jitter view target a little bit, if they are moving at all
        local jitter = Vector(0,0,0)
        if HasMixin(target, "BaseMove") then
            jitter = Vector( math.random(), math.random(), math.random() ) * gMarineAimJitterAmount
        end
        bot:GetMotion():SetDesiredViewTarget( aimPos+jitter )
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
    else
        bot:GetMotion():SetDesiredViewTarget( nil )
    end
    
    // Draw a red line to show what we are trying to attack
    if gBotDebug:Get("debugall") or brain.debug then

        if doFire then
            DebugLine( eyePos, aimPos, 0.0,   1,0,0,1, true)
        else
            DebugLine( eyePos, aimPos, 0.0,   1,0.5,0,1, true)
        end

    end

end

//----------------------------------------
//  
//----------------------------------------
local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, mem.lastSeenPos, bot, brain, move )

    else

        assert(false)
        // This should never really happen..

    end

    brain.teamBrain:AssignBotToMemory(bot, mem)

end

//----------------------------------------
//  
//----------------------------------------
local function PerformUse(marine, target, bot, brain, move)

    assert(target)
    local usePos = target:GetOrigin()
    local dist = GetDistanceToTouch(marine:GetEyePos(), target)

    local hasClearShot = dist < 5 and GetBotCanSeeTarget( marine, target )

    if not hasClearShot then
        // cannot see it yet - keep moving
        PerformMove( marine:GetOrigin(), usePos, bot, brain, move )
    elseif dist < 1.5 then
        // close enough to just use
        move.commands = AddMoveCommand( move.commands, Move.Use )
        bot:GetMotion():SetDesiredViewTarget( target:GetEngagementPoint() )
        bot:GetMotion():SetDesiredMoveTarget( nil )
    else
        // not close enough - keep moving, but also just do use to be safe.
        // Robo factory still gives us issues
        move.commands = AddMoveCommand( move.commands, Move.Use )
        PerformMove( marine:GetOrigin(), usePos, bot, brain, move )
    end

    brain.teamBrain:AssignBotToEntity( bot, target:GetId() )

end


//----------------------------------------
//  
//----------------------------------------
local function GetIsUseOrder(order)
    return order:GetType() == kTechId.Construct 
            or order:GetType() == kTechId.AutoConstruct
            or order:GetType() == kTechId.Build
            or order:GetType() == kTechId.Weld
end


//----------------------------------------
//  Each want function should return the fuzzy weight or tree along with a closure to perform the action
//  The order they are listed should not really matter, but it is used to break ties (again, ties should be unlikely given we are using fuzzy, interpolated eval)
//  Must NOT be local, since MarineBrain uses it.
//----------------------------------------
kMarineBrainActions =
{
    function(bot, brain)

        local name = "grabShotgun"

        local marine = bot:GetPlayer()
        local haveShotgun = marine:GetWeapon( Shotgun.kMapName ) ~= nil
        local shotguns = GetEntitiesWithinRangeAreVisible( "Shotgun", marine:GetOrigin(), 20, true )
        // ignore shotguns owned by someone already
        shotguns = FilterArray( shotguns, function(ent) return ent:GetParent() == nil end )
        local bestDist, bestShotgun = GetNearestFiltered(marine:GetOrigin(), shotguns)

        local weight = 0.0
        if not haveShotgun and bestShotgun ~= nil then
            weight = EvalLPF( bestDist, {
                    {0.0  , 10.0} , 
                    {3.0  , 10.0} , 
                    {5.0  , 1.0}  , 
                    {10.0 , 0.2}
                    })
        end

        return { name = name, weight = weight,
                perform = function(move)
                    if bestShotgun ~= nil then
                        PerformMove( marine:GetOrigin(), bestShotgun:GetOrigin(), bot, brain, move )
                        if bestDist < 1.0 then
                            move.commands = AddMoveCommand( move.commands, Move.Drop )
                        end
                    end
                end }
    end,

    function(bot, brain)

        local name = "medpack"
        local marine = bot:GetPlayer()
        local sdb = brain:GetSenses()

        local weight = 0.0
        local health = sdb:Get("healthFraction")

        local pos = marine:GetOrigin()
        local meds = GetEntitiesWithinRangeAreVisible( "MedPack", pos, 10, true )
        local bestDist, bestMed = GetNearestFiltered( pos, meds )

        if bestMed ~= nil then
            weight = EvalLPF( bestDist, {
                    {0.0, EvalLPF(health, {
                        {0.0, 20.0},
                        {0.8, 1.0},
                        {1.0, 0.0}
                        })},
                    {5.0, EvalLPF(health, {
                        {0.0, 20.0},
                        {0.5, 1.0},
                        {1.0, 0.0}
                        })},
                    {10.0, EvalLPF(health, {
                        {0.0, 20.0},
                        {0.1, 1.0},
                        {1.0, 0.0}
                        })}
                    })
        end

        return { name = name, weight = weight,
                perform = function(move)
                    PerformMove( pos, bestMed:GetOrigin(), bot, brain, move )
                end }
    end,

    function(bot, brain)

        local name = "ammopack"
        local weight = 0.0
        local sdb = brain:GetSenses()
        local marine = bot:GetPlayer()
        local pos = marine:GetOrigin()

        local weapon = marine:GetActiveWeapon()
        local bestPack = nil
        local bestDist = nil

        if weapon ~= nil and weapon:isa("ClipWeapon") then

            local ammo = sdb:Get("ammoFraction")
            local packs = GetEntitiesWithinRangeAreVisible( "AmmoPack", pos, 10, true )

            local function IsPackForWeapon(pack)

                if pack:isa("WeaponAmmoPack") then
                    local weaponClass = pack:GetWeaponClassName()
                    return weapon:GetClassName() == weaponClass
                else
                    return true
                end

            end

            bestDist, bestPack = GetNearestFiltered( pos, packs, IsPackForWeapon )

            if bestPack ~= nil then
                weight = EvalLPF( bestDist, {
                        {0.0, EvalLPF(ammo, {
                            {0.0, 20.0},
                            {0.8, 1.0},
                            {1.0, 0.0}
                            })},
                        {5.0, EvalLPF(ammo, {
                            {0.0, 20.0},
                            {0.5, 1.0},
                            {1.0, 0.0}
                            })},
                        {10.0, EvalLPF(ammo, {
                            {0.0, 20.0},
                            {0.1, 1.0},
                            {1.0, 0.0}
                            })}
                        })
            end
        end

        return { name = name, weight = weight,
                perform = function(move)
                    PerformMove( pos, bestPack:GetOrigin(), bot, brain, move )
                end }
    end,

    function(bot, brain)

        local name = "reload"

        local marine = bot:GetPlayer()
        local weapon = marine:GetActiveWeapon()
        local s = brain:GetSenses()
        local weight = 0.0

        if weapon ~= nil and weapon:isa("ClipWeapon") and s:Get("ammoFraction") > 0.0 then

            local threat = s:Get("biggestThreat")

            if threat ~= nil and threat.distance < 10 and s:Get("clipFraction") > 0.0 then
                // threat really close, and we have some ammo, shoot it!
                weight = 0.0
            else
                weight = EvalLPF( s:Get("clipFraction"), {
                        { 0.0 , 15 } , 
                        { 0.1 , 0 }  , 
                        { 1.0 , 0 }
                        })
            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                move.commands = AddMoveCommand(move.commands, Move.Reload)
            end }
    end,

    function(bot, brain)

        local name = "attack"

        local marine = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local threat = sdb:Get("biggestThreat")
        local weight = 0.0

        if threat ~= nil and sdb:Get("weaponReady") then

            weight = EvalLPF( threat.distance, {
                        { 0.0, EvalLPF( threat.urgency, {
                            {0, 0},
                            {10, 25}
                            })},
                        { 10.0, EvalLPF( threat.urgency, {
                            {0, 0},
                            {10, 5} })},
                        // Never let it drop too low - ie. keep it always above explore
                        { 100.0, 0.1 } })
        end


        return { name = name, weight = weight,
            perform = function(move)
                PerformAttack( marine:GetEyePos(), threat.memory, bot, brain, move )
            end }
    end,
/*
    function(bot, brain)

        local name = "weld"
        local marine = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local weight = 0.0

        if sdb:Get("welder") ~= nil and sdb:Get("nearestWeldable") ~= nil then
            weight = 0.4
        else
            weight = 0.0
        end

        return { name = name, weight = weight,
            perform = function(move)

                if not sdb:Get("welderReady") then
                    // switch to welder
                    marine:SetActiveWeapon( Welder.kMapName, true )
                else
                    local target = sdb:Get("nearestWeldable")
                    assert(target ~= nil)
                    PerformUse( marine, target, bot, brain , move )
                end

            end }
    end,
*/
    function(bot, brain)

        local name = "order"

        local marine = bot:GetPlayer()
        local order = bot:GetPlayerOrder()
        local teamBrain = bot.brain.teamBrain

        local weight = 0.0

        if order ~= nil then

            local targetId = order:GetParam()
            local target = Shared.GetEntity(targetId)

            if target ~= nil and (order:GetType() == kTechId.Construct or order:GetType() == kTechId.Build) then

                // Because construct orders are often given by the auto-system, do not necessarily obey them
                // Load-balance them
                local numOthers = teamBrain:GetNumOthersAssignedToEntity( targetId, bot )
                if numOthers >= 2 then
                    weight = 0.0
                else
                    weight = 2.0
                end

            else

                // Could be attack, weld, etc.
                weight = 2.0

            end

        end

        return { name = name, weight = weight,
            perform = function(move)
                if order then

                    brain.teamBrain:UnassignBot(bot)

                    local target = Shared.GetEntity(order:GetParam())

                    if target ~= nil and order:GetType() == kTechId.Attack then

                        PerformAttackEntity( marine:GetEyePos(), target, order:GetLocation(), bot, brain, move )

                    elseif target ~= nil and GetIsUseOrder(order) then

                        PerformUse( marine, target, bot, brain , move )

                    elseif order:GetType() == kTechId.Move then

                        PerformMove( marine:GetOrigin(), order:GetLocation(), bot, brain, move )

                    else

                        DebugPrint("unknown order type: %d", order:GetType())
                        PerformMove( marine:GetOrigin(), order:GetLocation(), bot, brain, move )

                    end
                end
            end }
    end,

    function( bot, brain )

        local name = "ping"
        local weight = 0.0
        local marine = bot:GetPlayer()
        local db = brain:GetSenses()
        local pos = marine:GetOrigin()

        local kPingLifeTime = 30.0
        local pingPos = db:Get("comPingPosition")

        if pingPos ~= nil and db:Get("comPingElapsed") ~= nil and db:Get("comPingElapsed") < kPingLifeTime then


            if brain.lastReachedPingPos ~= nil and pingPos:GetDistance(brain.lastReachedPingPos) < 1e-2 then
                // we already reached this ping - ignore it
            elseif db:Get("comPingXZDist") > 5 then
                // respond to ping with fairly high priority
                // but allow direct orders to override
                weight = 1.5
            else
                // we got close enough, remember to ignore this ping
                brain.lastReachedPingPos = db:Get("comPingPosition")
            end

        end

        return { name = name, weight = weight,
            perform = function(move)
                local pingPos = db:Get("comPingPosition")
                assert(pingPos ~= nil)
                PerformMove( marine:GetOrigin(), pingPos, bot, brain, move )
            end}

    end,

    function(bot, brain)

        local name = "retreat"
        local marine = bot:GetPlayer()
        local sdb = brain:GetSenses()

        local armory = sdb:Get("nearestArmory").armory
        local armoryDist = sdb:Get("nearestArmory").distance
        local minFraction = math.min( sdb:Get("healthFraction"), sdb:Get("ammoFraction") )

        // If we are pretty close to the armory, stay with it a bit longer to encourage full-healing, etc.
        // so pretend our situation is more dire than it is
        if armory ~= nil and armoryDist < 4.0 and minFraction < 0.8 then
            if brain.debug then
                Print("close to armory, being less risky")
            end
            minFraction = minFraction / 3.0
        end

        local weight = 0.0

        if armory ~= nil then

            weight = EvalLPF( minFraction, {
                    { 0.0, 20.0 },
                    { 0.3, 0.0 },
                    { 1.0, 0.0 }
                    })
        end

        return { name = name, weight = weight,
            perform = function(move)
                if armory ~= nil then

                    // we are retreating, unassign ourselves from anything else, e.g. attack targets
                    brain.teamBrain:UnassignBot(bot)

                    local touchDist = GetDistanceToTouch( marine:GetEyePos(), armory )
                    if touchDist > 1.5 then
                        if brain.debug then DebugPrint("going towards armory at %s", ToString(armory:GetEngagementPoint())) end
                        PerformMove( marine:GetOrigin(), armory:GetEngagementPoint(), bot, brain, move )
                    else
                        // sit and wait to heal, ammo, etc.
                        brain.retreatTargetId = nil
                        bot:GetMotion():SetDesiredViewTarget( armory:GetEngagementPoint() )
                        bot:GetMotion():SetDesiredMoveTarget( nil )
                    end
                else
                    assert(false)
                    // should never happen
                end

            end }

    end,

    //----------------------------------------
    //  
    //----------------------------------------
    CreateExploreAction( 0.05, function( pos, targetPos, bot, brain, move )
            if gBotDebug:Get("debugall") or brain.debug then
                DebugLine(bot:GetPlayer():GetEyePos(), targetPos+Vector(0,1,0), 0.0,     0,0,1,1, true)
            end
            PerformMove(pos, targetPos, bot, brain, move)
            end ),

    //----------------------------------------
    //  
    //----------------------------------------
    function(bot, brain)
        return { name = "debug idle", weight = 0.01,
                perform = function(move)
                    // Do a jump..for fun
                    move.commands = AddMoveCommand(move.commands, Move.Jump)
                    bot:GetMotion():SetDesiredViewTarget(nil)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                end }
    end

}

//----------------------------------------
//  More urgent == should really attack it ASAP
//----------------------------------------
local function GetAttackUrgency(bot, mem)

    local teamBrain = bot.brain.teamBrain

    // See if we know whether if it is alive or not
    local target = Shared.GetEntity(mem.entId)
    if not HasMixin(target, "Live") or not target:GetIsAlive() then
        return nil
    end

    // for load-balancing
    local numOthers = teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= bot:GetPlayer():GetId() then
                    return true
                end
                return false
            end)

    // Closer --> more urgent

    local closeBonus = 0
    local dist = bot:GetPlayer():GetOrigin():GetDistance( mem.lastSeenPos )

    if dist < 15 then
        // Do not modify numOthers here
        closeBonus = 10/math.max(0.01, dist)
    end

    //----------------------------------------
    // Passives - not an immediate threat, but attack them if you got nothing better to do
    //----------------------------------------
    local passiveUrgencies =
    {
        [kMinimapBlipType.Crag] = numOthers >= 2           and 0.2 or 0.95, // kind of a special case
        [kMinimapBlipType.Hive] = numOthers >= 6           and 0.5 or 0.9,
        [kMinimapBlipType.Harvester] = numOthers >= 2      and 0.4 or 0.8,
        [kMinimapBlipType.Egg] = numOthers >= 1            and 0.2 or 0.5,
        [kMinimapBlipType.Shade] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shift] = numOthers >= 2          and 0.2 or 0.5
    }

    if bot.brain.debug then
        if mem.btype == kMinimapBlipType.Hive then
            Print("got Hive, urgency = %f", passiveUrgencies[mem.btype])
        end
    end

    if passiveUrgencies[ mem.btype ] ~= nil then
        return passiveUrgencies[ mem.btype ] + closeBonus
    end

    //----------------------------------------
    //  Active threats - ie. they can hurt you
    //  Only load balance if we cannot see the target
    //----------------------------------------
    function EvalActiveUrgenciesTable(numOthers)
        local activeUrgencies =
        {
            [kMinimapBlipType.Embryo] = numOthers >= 1 and 0.1 or 1.0,
            [kMinimapBlipType.Hydra] = numOthers >= 2  and 0.1 or 2.0,
            [kMinimapBlipType.Whip] = numOthers >= 2   and 0.1 or 3.0,
            [kMinimapBlipType.Skulk] = numOthers >= 2  and 0.1 or 4.0,
            [kMinimapBlipType.Lerk] = numOthers >= 2   and 0.1 or 5.0,
            [kMinimapBlipType.Fade] = numOthers >= 3   and 0.1 or 6.0,
            [kMinimapBlipType.Onos] =  numOthers >= 4  and 0.1 or 7.0,
        }
        return activeUrgencies
    end

    // Optimization: we only need to do visibilty check if the entity type is active
    // So get the table first with 0 others
    local urgTable = EvalActiveUrgenciesTable(0)

    if urgTable[ mem.btype ] then

        // For nearby active threads, respond no matter what - regardless of how many others are around
        if dist < 15 then
            numOthers = 0
        end

        urgTable = EvalActiveUrgenciesTable(numOthers)
        return urgTable[ mem.btype ] + closeBonus

    end

    return nil

end

//----------------------------------------
//  Build the senses database
//----------------------------------------

function CreateMarineBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("clipFraction", function(db)
            local marine = db.bot:GetPlayer()
            local weapon = marine:GetActiveWeapon()
            if weapon ~= nil then
                if weapon:isa("ClipWeapon") then
                    return weapon:GetClip() / weapon:GetClipSize()
                else
                    return 1.0
                end
            else
                return 0.0
            end
            end)

    s:Add("ammoFraction", function(db)
            local marine = db.bot:GetPlayer()
            local weapon = marine:GetActiveWeapon()
            if weapon ~= nil then
                if weapon:isa("ClipWeapon") then
                    return weapon:GetAmmo() / weapon:GetMaxAmmo()
                else
                    return 1.0
                end
            else
                return 0.0
            end
            end)

    s:Add("welder", function(db)
            local marine = db.bot:GetPlayer()
            return marine:GetWeapon( Welder.kMapName )
            end)

    s:Add("welderReady", function(db)
            local marine = db.bot:GetPlayer()
            return marine:GetActiveWeapon():GetMapName() == Welder.kMapName
            end)

    s:Add("weaponReady", function(db)
            return db:Get("ammoFraction") > 0
            end)

    s:Add("healthFraction", function(db)
            local marine = db.bot:GetPlayer()
            return marine:GetHealthFraction()
            end)

    s:Add("biggestThreat", function(db)
            local marine = db.bot:GetPlayer()
            local memories = GetTeamMemories( marine:GetTeamNumber() )
            local maxUrgency, maxMem = GetMaxTableEntry( memories,
                function( mem )
                    return GetAttackUrgency( db.bot, mem )
                end)
            local dist = nil
            if maxMem ~= nil then
                if db.bot.brain.debug then
                    Print("max mem type = %s", EnumToString(kMinimapBlipType, maxMem.btype))
                end
                dist = marine:GetEyePos():GetDistance(maxMem.lastSeenPos)
                return {urgency = maxUrgency, memory = maxMem, distance = dist}
            else
                return nil
            end
            end)

    s:Add("nearestArmory", function(db)

            local marine = db.bot:GetPlayer()
            local armories = GetEntitiesForTeam( "Armory", kMarineTeamType )

            local dist, armory = GetMinTableEntry( armories,
                function(armory)
                    assert( armory ~= nil )
                    if armory:GetIsBuilt() then
                        local dist,_ = GetPhaseDistanceForMarine( marine:GetOrigin(), armory:GetOrigin(), db.bot.brain.lastGateId )

                        // Weigh our previous nearest a bit better, to prevent thrashing
                        if armory:GetId() == db.lastNearestArmoryId then
                            return dist * 0.9
                        else
                            return dist
                        end
                    end
                end)

            if armory ~= nil then db.lastNearestArmoryId = armory:GetId() end
            return {armory = armory, distance = dist}

            end)

    s:Add("nearestWeldable", function(db)

            local marine = db.bot:GetPlayer()
            local targets = GetEntitiesWithMixinForTeamWithinRange( "Weldable", kMarineTeamType, marine:GetOrigin(), 10.0 )

            local dist, target = GetMinTableEntry( targets,
                function(target)
                    assert( target ~= nil )
                    if target:GetCanBeWelded() then
                        return marine:GetOrigin():GetDistance( target:GetOrigin() )
                    end
                end)

            return {target = target, distance = dist}

            end)
    s:Add("comPingElapsed", function(db)

            local pingTime = GetGamerules():GetTeam1():GetCommanderPingTime()

            if pingTime > 0 and pingTime ~= nil and pingTime < Shared.GetTime() then
                return Shared.GetTime() - pingTime
            else
                return nil
            end

            end)

    s:Add("comPingPosition", function(db)
            local rawPos = GetGamerules():GetTeam1():GetCommanderPingPosition()
            // the position is usually up in the air somewhere, so pretend we did a commander pick to put it somewhere sensible
            local trace = GetCommanderPickTarget(
                db.bot:GetPlayer(), // not right, but whatever
                rawPos,
                true, // worldCoords Specified
                false, // isBuild
                true // ignoreEntities
                )

            if trace ~= nil and trace.fraction < 1 then
                return trace.endPoint
            else
                return  nil
            end

            end)

    s:Add("comPingXZDist", function(db)
            local marine = db.bot:GetPlayer()
            if db:Get("comPingPosition") ~= nil then
                local delta = db:Get("comPingPosition") - marine:GetOrigin()
                return delta:GetLengthXZ()
            end
            end)

    return s

end

if Server then
Event.Hook("Console_marinejitter", function(client, arg)
        gMarineAimJitterAmount = tonumber(arg)
        Print("gMarineAimJitterAmount = %f", gMarineAimJitterAmount)
        end
        )
end
