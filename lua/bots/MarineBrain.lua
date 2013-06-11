
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/bots/MarineBrain_Data.lua")

gMarineBrains = {}

//----------------------------------------
//  
//----------------------------------------
class 'MarineBrain' (PlayerBrain)

function MarineBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateMarineBrainSenses()
    table.insert(gMarineBrains, self)

    self.hadAmmo = false
    self.hadGoodHealth = false

end

function MarineBrain:Update( bot, move )

    if gBotDebug:Get("spam") then
        Print("MarineBrain:Update")
    end

    PlayerBrain.Update( self, bot, move )

    local marine = bot:GetPlayer()

    if marine ~= nil and marine:GetIsAlive() then

        // Send ammo request
        if self.hadAmmo then
            if self.senses:Get("ammoFraction") <= 0.0 then
                CreateVoiceMessage( marine, kVoiceId.MarineRequestAmmo )
                self.hadAmmo = false
            end
        else
            if self.senses:Get("ammoFraction") > 0.0 then
                self.hadAmmo = true
            end
        end

        // Med kit request
        if self.hadGoodHealth then
            if self.senses:Get("healthFraction") <= 0.5 then
                if math.random() < 0.2 then
                    CreateVoiceMessage( marine, kVoiceId.MarineRequestMedpack )
                end
                self.hadGoodHealth = false
            end
        else
            if self.senses:Get("healthFraction") > 0.5 then
                self.hadGoodHealth = true
            end
        end

    else
        self.hadAmmo = false
        self.hadGoodHealth = false
    end

end

function MarineBrain:GetExpectedPlayerClass()
    return "Marine"
end

function MarineBrain:GetExpectedTeamNumber()
    return kMarineTeamType
end

function MarineBrain:GetActions()
    return kMarineBrainActions
end

function MarineBrain:GetSenses()
    return self.senses
end

