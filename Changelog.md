# Changelog

3-5-16

Fixed compatibility with 289

2-12-16

Fixed floating armory.
Fixed MT not working in combat mode.
Fixed game not ending when 0 players on team or when team concedes in combat mode.
Made MT update faster on client side.

Added sv_maxentities to control max entities in 15m radius (10-75)

2-12-16

Updated for B285

12-25-15

Updated for 279

12-4-15

Updates for 278
Fix for scan requiring 21 energy

10-17-15

Updates for 276

7-7-15

Combat Mode Changes:
Fixed missing XP rewards for team actions (healing/welding).
Added server adjustable level cap (sv_combatmaxlevel (5-20).
Added late join experience based on teammates.
Fixed levels lost for hydras or dying as egg/leaving team as egg.
Added server toggle for round length in minutes (sv_combatroundlength 5-60).
Added server toggle for spawn protection in seconds (sv_combatspawnprotection 0-5).
Added server toggle for combat default winner (sv_combatdefaultwinner 1/Marines, 2/Aliens)
Fixed Hive and Harvester being buildable in Combat.
Fixed resource display assert.
Some small caching for GUI updates of level/xp.
Moved RoundLength messages to TeamMessages.
Redesigned Marine Buy Menu

Classic Mode Changes:
Added multiplier for ammo packs, Rifle picks up 2x ammo (2 Clips).
Added commander requirement toggle for server admins (sv_classiccommrequired true/false).
Server admins can control maximum amount of sentries per room (sv_classicmaxsentries 1-12).
Server admins can control maximum amount of sieges per room (sv_classicmaxsieges 1-10).
Server admins can control maximum amount of turret factories per room (sv_classicmaxfactories 1-3).
Server admins can control maximum amount of nearby alien structures of EACH type (sv_classicmaxalienstructures 8-16).
Added callback for commander messages about building counts so clients can see limits if they hit them.

Overall Changes:
Fall Damage can be toggled as server setting (sv_falldamage true/false).
Added check on extended bindings to prevent assert.
Updated ReadyRoom Join Text.
Added Help Screen (default bound to I).
Added Living check for Redemption (cant redem if you're dead silly).
Fixed primal not being networked.
Completely reworked Localization Overloading, can support multiple languages (message if you want to help with translations).
Improved GameMode command (sv_gamemode).  sv_gamemode 0 is default, selects between combat/classic based on mapname.  sv_gamemode 1 will force Classic, sv_gamemode 2 will force Combat.
Added sv_classichelp command to show info on classic specific commands.
Updated Menu Hook to not required file replacement, should improve forward compatibility.
Cleaned up some entities to prevent obstacle issues.
Added new HMG sound which is shorter to use during prolonged firing.
Fixed alien upgrade icons showing briefly on team join.
Fixed weapon attack effects after building.
Added vanillamovement path for Jetpacks and Fades
Updated ladders to be predicted.

5-30-15

Fixed scan highlight showing up for parasited marines.
Fixed assert from infestation on shades when spectating.
Fixed ghost structures not poofing.
Fixed votes counting that were recieved right after successful vote.


Updated readyroom text regarding mod feedback and information.

Slightly nerfed electrify - 5 more tres, 15 seconds longer to research and 2 less damage /tick.
Made predicted projectiles a bit more predictable.

5-28-15

Updated for B274

1-24-15

Updates for B273

12-23-14

Updates to fix some bugs

12-19-14

Updated for B272

12-7-14

Updated for B271

9-6-14

Updated for 269

8-28-14

Some minor fixes and improvements.

8-24-14

Updated to support B268

8-7-14

Updated to support B267

Fixed scans fo real this time, i hope. :E

6-30-14

Fixed issue with scans, along with a number of other bugs.

6-22-14

Compatibility with B266

5-12-14

Compatibility with B265

4-12-14

Fixed marines not being slowed on land.

Fixed other minor issues such as rifle cinematic bug.

3-31-14

Fixed issue with many structures causing tech not to be unlocked.
Fixed pistol bug.
Fixed timing issue with some alien support structures

3-2-14

Fixed issue with upgradeable mixin causing errors on structure deaths.

2-27-14

- Changed advancedmovement option to toggle between a re-created 'Vanilla' NS2 movement system, and the original 'Classic' movement system.  This is something that can be toggled by each user independently currently.
- Fixed issues with obs beacon and hopefully fixed issues with watermod.

2-7-14

- Fixed bug with Blink not being calculated independantly from moverate, caused fade blink energy consumption to double with last patch.
- Changed Gravity constant to match scaling values applied to other movement variables from NS1.
- Increased marine and fade movement speeds slightly.
- Fixed skulk crouching not disabling wallwalking.

2-16-14

Big Features:

- Added 'Combat' mode similar to NS1's combat. By default this activates on any map with co_ in its name.  Mode can also be manually changed by server admins using sv_gamemode.

- Added support for B263.

Changes

- Change many marine structures to be fully animated client side.
- Reworked alien upgrades system so that upgrades do not need to be repurchased each time you evolve.
- Disabled 'HeavyArmor'  standin model, added green nanoshield effect to standard marines to signify heavy armor.
- Added hit knockback and viewpunch, modeled after NS1.
- Implemented AirMove cap from NS1, caps speed when over 3x base move speed.
- Hive type can now be voted for once hive has been dropped, and can be selected before hive has finished building.
- Changed default move rate for Classic to 60/s.
- Jetpack takeoff clears any slows.

Bug Fixes

- Fixed alien spectator not recieving updates on time remaining before spawning.
- Fixed issue with grenades not being able to detonate right away.
- Fixed issue with bilebomb and acid rocket causing them to detonate in your face, or not detonate at all.
- Fixed upgrade replacement penalty time not applying.
- Changed gorge building placement for Crag, Shift, Shade, Whip and Hydra back to allowing placement on wall/ceilings.
- Lowered Fade Carapace down to 220 from 250.
- Tweaked alien upgrade HUD icons to better align with actual upgrade status.
- Fixed issue with landing impact not being calculated correctly.
- Fixed issue with web model rendering incorrectly during placement.

Balance Changes

- Adjusted jetpack fuel usage and reworked movement to be closer to NS1.
- Increased Catpack research time from 15 to 25 seconds.
- Increased Turret Factory upgrade time from 30 to 45 seconds.
- Increased sentry build time from 7 to 9 seconds.
- Increased SiegeCannon build time from 10 to 11 seconds.
- Lowered replacing upgrade penalty time from 6 to 4 seconds.
- Increased energy cost to drop structures from 5 to 10.
- Increased drop range of all structures but hive from 3 to 6.

For more information visit http://www.unknownworlds.com/ns2/forums/index.php?showtopic=121482

*Credits*

Base 'goldsource' style movement - Maesse

NS1 LMG remake model, font and sounds - Evil_Ice