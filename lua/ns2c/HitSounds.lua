if Client then

    kHitSounds =
    {
        "sound/hitsounds_client.fev/hitsounds/low",  -- low impact
        "sound/hitsounds_client.fev/hitsounds/mid",  -- mid impact
        "sound/hitsounds_client.fev/hitsounds/high", -- high impact
    }

    local kHitSoundVol = 0.0

    for _,hitsound in ipairs( kHitSounds ) do
        Client.PrecacheLocalSound( hitsound )
    end

    function HitSounds_PlayHitsound( i )
        if kHitSounds[i] then
            StartSoundEffect( kHitSounds[i], kHitSoundVol )
        end
    end

    function HitSounds_SyncOptions()
        kHitSoundVol = Client.GetOptionFloat( "hitsound-vol", 0.0 )
    end

end

if Server then

    local hits = {}

    -- Percentages used for weapons with variable damage
    local kHitSoundHigh = 0.9
    local kHitSoundMid = 0.5

    local kHitSoundHighShotgunHitCount = 14
    local kHitSoundMidShotgunHitCount = 6

    local kHitSoundHighXenoHitCount = 4
    local kHitSoundMidXenoHitCount = 2

    local kHitSoundEnabledForWeapon =
    set {
        kTechId.Axe, kTechId.Welder, kTechId.Pistol, kTechId.Rifle, kTechId.Shotgun, kTechId.HeavyMachineGun, kTechId.GrenadeLauncher,
        kTechId.Claw, kTechId.Minigun, kTechId.Railgun,
        kTechId.Bite, kTechId.Parasite, kTechId.Xenocide,
        kTechId.Spit,
        kTechId.LerkBite, kTechId.Spikes,
        kTechId.Swipe,
        kTechId.Gore,
    }


    function HitSound_IsEnabledForWeapon( techId )
        return techId and kHitSoundEnabledForWeapon[techId]
    end

    function HitSound_RecordHit( attacker, target, amount, point, overkill, weapon )
        attacker = (attacker and attacker:GetId()) or Entity.invalidId
        target = (target and target:GetId()) or Entity.invalidId

        local hit
        for i=1,#hits do
            hit = hits[i]
            if hit.attacker == attacker and hit.target == target and hit.weapon == weapon then
                if amount > 0 then
                    hit.point = point -- always use the last point that caused damage
                end
                hit.amount = hit.amount + amount
                hit.overkill = hit.overkill + overkill
                hit.hitcount = hit.hitcount + 1
                return
            end
        end

        if amount > 0 then
            hits[#hits+1] =
            {
                attacker = attacker,
                target = target,
                amount = amount,
                point = point,
                overkill = overkill,
                weapon = weapon,
                hitcount = 1
            }
        end

    end

    -- Let mods determine the sound to be played in case they add their own weapons, etc
    function HitSound_ChooseSound(hit)
        local sound = 1
        local attacker = Shared.GetEntity(hit.attacker)
        if hit.weapon == kTechId.GrenadeLauncher then
            -- Grenade Launcher is not affected by weapon upgrades
            local damageAmount = hit.overkill / kGrenadeLauncherGrenadeDamage
            if kHitSoundHigh <= damageAmount then
                sound = 3
            elseif kHitSoundMid <= damageAmount then
                sound = 2
            end
        elseif hit.weapon == kTechId.Shotgun then
            -- Shotgun hitsound is based on number of pellets that hit a single target
            if kHitSoundHighShotgunHitCount <= hit.hitcount then
                sound = 3
            elseif kHitSoundMidShotgunHitCount <= hit.hitcount then
                sound = 2
            end
        elseif hit.weapon == kTechId.LerkBite then
            sound = 3
        end

        return sound
    end

    function HitSound_DispatchHits()
        local hitsounds = {}
        local attackers = {}
        local xenocounts = {}
        local xenoattacker = {}

        for i = 1, #hits do
            local hit = hits[i]
            local attacker = Shared.GetEntity(hit.attacker)
            local target = Shared.GetEntity(hit.target)

            if attacker and target and target:isa("Player") and not target:isa("Embryo") then

                local sound = HitSound_ChooseSound(hit)

                -- I suppose this doesn't make Xeno hitsounds super moddable, but...
                if hit.weapon == kTechId.Xenocide then
                    -- Xenocide hitsound is based on number of people hit
                    xenocounts[attacker] = ( xenocounts[attacker] or 0 ) + 1
                    if xenocounts[attacker] == 1 then
                        table.insert(xenoattacker, attacker)
                    end
                end

                if not hitsounds[attacker] then
                    table.insert(attackers, attacker)
                end

                -- Prefer sending an event only for the best hit
                hitsounds[attacker] = math.max( hitsounds[attacker] or 0, sound )
            end

            -- Send the accumulated damage message
            if attacker then
                SendDamageMessage( attacker, target, hit.amount, hit.point, hit.overkill )
            end

        end

        -- Xenocide hitsound is based on number of people hit
        for i = 1, #xenoattacker do
            local sound = 1
            local attacker = xenoattacker[i]
            local xenocount = xenocounts[attacker]

            if kHitSoundHighXenoHitCount <= xenocount then
                sound = 3
            elseif kHitSoundMidXenoHitCount <= xenocount then
                sound = 2
            end

            -- Prefer sending an event only for the best hit
            hitsounds[attacker] = math.max( hitsounds[attacker] or 0, sound )
        end

        for i = 1, #attackers do
            local attacker = attackers[i]
            local sound = hitsounds[attacker]

            local msg = BuildHitSoundMessage(sound)

            -- damage reports must be reliable when not spectating
            Server.SendNetworkMessage(attacker, "HitSound", msg, true)
        end

        -- Clear the record
        hits = {}
    end

    -- Hook the UpdateServer event just in case Player.OnProcessMove wasn't called or was overridden
    Event.Hook("UpdateServer", HitSound_DispatchHits)
end