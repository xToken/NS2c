//----------------------------------------
//  
//----------------------------------------

Script.Load("lua/bots/PlayerBrain.lua")

local gDebug = false

//----------------------------------------
//  Utility funcs
//----------------------------------------
function GetRandomBuildPosition(techId, aroundPos, maxDist)

    local extents = GetExtents(techId)
    local validationFunc = LookupTechData(techId, kTechDataRequiresInfestation, nil) and GetIsPointOnInfestation or nil
    local randPos = GetRandomSpawnForCapsule(extents.y, extents.x, aroundPos, 0.01, maxDist, EntityFilterAll(), validationFunc)
    return randPos

end

//----------------------------------------
//  
//----------------------------------------
class 'CommanderBrain' (PlayerBrain)

function CommanderBrain:GetShouldDebug(bot)
    //return true
    return gDebug
end

//----------------------------------------
//  This enumerates EVERYTHING that the commander can do right now - EVERYTHING
//  The result is a hash table with techId as keys and an array of units as values. These are the units that you can perform the tech on (it may just be com)
//----------------------------------------
function CommanderBrain:GetDoableTechIds(com)

    local teamNum = self:GetExpectedTeamNumber()
    local tree = GetTechTree(teamNum)

    local doables = {}

    local function GetIsActionButton(techNode)

        return not techNode:GetIsPassive()
        and not techNode:GetIsMenu()

    end

    local function HandleUnitActionButton(unit, techNode)

        assert( techNode ~= nil )
        assert( GetIsActionButton(techNode) )
        local techId = techNode:GetTechId()

        if techNode:GetAvailable() then

            // check cool down
            if com:GetIsTechOnCooldown(techId) then
                return
            end

            local allowed, canAfford = unit:GetTechAllowed( techId, techNode, com )

            if self.debug then
                Print("%s-%d.%s = %s (%s^%s)",
                        unit:GetClassName(),
                        unit:GetId(),
                        EnumToString(kTechId, techId),
                        ToString( allowed and canAfford ),
                        ToString(allowed),
                        ToString(canAfford) )
            end

            if allowed and canAfford then
                if doables[techId] == nil then
                    doables[techId] = {}
                end
                table.insert( doables[techId], unit )
            end

        end
        
    end

    //----------------------------------------
    // Go through all units, gather all the things we can do with them
    //----------------------------------------

    local function CollectUnitDoableTechIds( unit, menuTechId, doables, visitedMenus )

        // Very important. Menus are naturally cyclic, since there is always a "back" button
        visitedMenus[menuTechId] = true

        local techIds = unit:GetTechButtons( menuTechId ) or {}

        for _, techId in ipairs(techIds) do

            if techId ~= kTechId.None then

                local techNode = tree:GetTechNode(techId)
                assert(techNode ~= nil)

                if techNode:GetIsMenu() and visitedMenus[techId] == nil then
                    CollectUnitDoableTechIds( unit, techId, doables, visitedMenus )
                elseif GetIsActionButton(techNode) then
                    HandleUnitActionButton( unit, techNode )
                end
            end
        end

    end

    for _, unit in ipairs(GetEntitiesForTeam("ScriptActor", teamNum)) do
        CollectUnitDoableTechIds( unit, kTechId.RootMenu, doables, {} )
    end

    //----------------------------------------
    //  Now do commander buttons. They are all in a two-level table, so no need to recurse.
    //----------------------------------------

    // Now do commander buttons - all of them
    for _,menu in pairs( com:GetButtonTable() ) do

        for _,techId in ipairs(menu) do

            if techId ~= kTechId.None then

                local techNode = tree:GetTechNode(techId)
                assert( techNode ~= nil )

                if GetIsActionButton(techNode) then
                    HandleUnitActionButton( com, techNode )
                end
            end
        end
    end

    return doables

end

//----------------------------------------
//  Helper function for subclasses
//----------------------------------------
function CommanderBrain:ExecuteTechId( commander, techId, position, hostEntity )

    DebugPrint("Combrain executing %s at %s on %s", EnumToString(kTechId, techId),
            ToString(position),
            hostEntity == nil and "<no target>" or hostEntity:GetClassName())

    local techNode = commander:GetTechTree():GetTechNode( techId )

    assert( hostEntity:GetTechAllowed(techId, techNode, commander) )

    // We should probably use ProcessTechTreeAction instead here...
    local success, keepGoing = commander:ProcessTechTreeActionForEntity(
            techNode,
            position,
            Vector(0,1,0),  // normal
            true,   // isCommanderPicked
            0,  // orientation
            hostEntity,
            nil, // trace
            true // isBot
            )

    if success then
    
        // set cooldown
        local cooldown = LookupTechData(techId, kTechDataCooldown, 0)
        if cooldown ~= 0 then
            commander:SetTechCooldown(techId, cooldown, Shared.GetTime())
        end

    else

        if self.debug then
            DebugPrint("Failed to perform action %s", EnumToString(kTechId, techId))
        end
    end
    
    return success
end

//----------------------------------------
//  
//----------------------------------------
Event.Hook("Console_bot_com",
    function()
        gDebug = not gDebug
        Print("CommanderBrain debug = %s", ToString(gDebug))
    end)
