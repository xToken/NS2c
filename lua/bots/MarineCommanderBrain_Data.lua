
Script.Load("lua/bots/BrainSenses.lua")
Script.Load("lua/CommanderHelp.lua")

//----------------------------------------
//  
//----------------------------------------

kMarineComBrainActions = 
{
    function( bot, brain )

        local name = "upgrade"
        local com = bot:GetPlayer()
        local teamNum = com:GetTeamNumber()
        local sdb = brain:GetSenses()
        local techIds = sdb:Get("doableTechIds")

        return { name = name, weight = 0.0,
            perform = function(move)
                // TOOD
            end }

    end
}

//----------------------------------------
//  Build the senses database
//----------------------------------------

function CreateMarineComSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("doableTechIds", function(db)
            return db.bot.brain:GetDoableTechIds( db.bot:GetPlayer() )
            end)

    return s

end

//----------------------------------------
//  
//----------------------------------------
