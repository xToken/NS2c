// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DSPEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// From FMOD documentation:
//
// DSP_Mixer        This unit does nothing but take inputs and mix them together then feed the result to the soundcard unit.
// DSP_Oscillator   This unit generates sine/square/saw/triangle or noise tones.
// DSP_LowPass      This unit filters sound using a high quality, resonant lowpass filter algorithm but consumes more CPU time.
// DSP_ITLowPass    This unit filters sound using a resonant lowpass filter algorithm that is used in Impulse Tracker, but with limited cutoff range (0 to 8060hz).
// DSP_HighPass     This unit filters sound using a resonant highpass filter algorithm.
// DSP_Echo         This unit produces an echo on the sound and fades out at the desired rate.
// DSP_Flange       This unit produces a flange effect on the sound.
// DSP_Distortion   This unit distorts the sound.
// DSP_Normalize    This unit normalizes or amplifies the sound to a certain level.
// DSP_ParamEQ      This unit attenuates or amplifies a selected frequency range.
// DSP_PitchShift   This unit bends the pitch of a sound without changing the speed of playback.
// DSP_Chorus       This unit produces a chorus effect on the sound.
// DSP_Reverb       This unit produces a reverb effect on the sound.
// DSP_VSTPlugin    This unit allows the use of Steinberg VST plugins.
// DSP_WinampPlugin This unit allows the use of Nullsoft Winamp plugins.
// DSP_ITEcho       This unit produces an echo on the sound and fades out at the desired rate as is used in Impulse Tracker.
// DSP_Compressor   This unit implements dynamic compression (linked multichannel, wideband).
// DSP_LowPassSimple This unit filters sound using a simple lowpass with no resonance, but has flexible cutoff and is fast.
// DSP_Delay            This unit produces different delays on individual channels of the sound.
// DSP_Tremolo      This unit produces a tremolo/chopper effect on the sound.
//            
// ========= For more information, visit us at http://www.unknownworlds.com =======================

//NS2c
//Removed low health DSP

local masterCompressorId = -1
local nearDeathId = -1

local kThresholdId = 0
local kAttackId = 1
local kReleaseId = 2
local kMakeUpGainId = 3

local kThresholdDefault = -4
local masterCompressorThreshold = kThresholdDefault
local kAttackDefault = 18
local masterCompressorAttack = kAttackDefault
local kReleaseDefault = 60
local masterCompressorRelease = kReleaseDefault
local kMakeUpGainDefault = 9
local masterCompressorMakeUpGain = kMakeUpGainDefault

function CreateDSPs()

    // Used to adjust the master volume.
    masterCompressorId = Client.CreateDSP(SoundSystem.DSP_Compressor)
    
    // Threshold.
    Client.SetDSPFloatParameter(masterCompressorId, kThresholdId, masterCompressorThreshold)
    // Attack.
    Client.SetDSPFloatParameter(masterCompressorId, kAttackId, masterCompressorAttack)
    // Release.
    Client.SetDSPFloatParameter(masterCompressorId, kReleaseId, masterCompressorRelease)
    // Make up gain.
    Client.SetDSPFloatParameter(masterCompressorId, kMakeUpGainId, masterCompressorMakeUpGain)
    
    // Near-death effect low-pass filter.
    nearDeathId = Client.CreateDSP(SoundSystem.DSP_LowPassSimple)
    Client.SetDSPActive(nearDeathId, false)
    Client.SetDSPFloatParameter(nearDeathId, 0, 2738)
    
end

local function OnAdjustMasterCompressorThreshold(threshold)

    threshold = tonumber(threshold) or kThresholdDefault
    if threshold < -60 or threshold > 0 then
    
        Print("Warning: Threshold must be between -60 and 0. Defaulting to " .. kThresholdDefault)
        threshold = kThresholdDefault
        
    end
    masterCompressorThreshold = threshold
    Print("New Threshold: " .. masterCompressorThreshold)
    Client.SetDSPFloatParameter(masterCompressorId, kThresholdId, masterCompressorThreshold)
    
end
Event.Hook("Console_mct", OnAdjustMasterCompressorThreshold)

local function OnAdjustMasterCompressorAttack(attack)

    attack = tonumber(attack) or kAttackDefault
    if attack < 10 or attack > 200 then
    
        Print("Warning: Second parameter attack must be between 10 and 200. Defaulting to " .. kAttackDefault)
        attack = kAttackDefault
        
    end
    masterCompressorAttack = attack
    Print("New Attack: " .. masterCompressorAttack)
    Client.SetDSPFloatParameter(masterCompressorId, kAttackId, masterCompressorAttack)
    
end
Event.Hook("Console_mca", OnAdjustMasterCompressorAttack)

local function OnAdjustMasterCompressorRelease(release)

    release = tonumber(release) or kReleaseDefault
    if release < 20 or release > 1000 then
    
        Print("Warning: Third parameter release must be between 20 and 1000. Defaulting to " .. kReleaseDefault)
        release = kReleaseDefault
        
    end
    masterCompressorRelease = release
    Print("New Release: " .. masterCompressorRelease)
    Client.SetDSPFloatParameter(masterCompressorId, kReleaseId, masterCompressorRelease)
    
end
Event.Hook("Console_mcr", OnAdjustMasterCompressorRelease)

local function OnAdjustMasterCompressorMakeUpGain(makeUpGain)

    makeUpGain = tonumber(makeUpGain) or kMakeUpGainDefault
    if makeUpGain < 0 or makeUpGain > 30 then
    
        Print("Warning: Fourth parameter make up gain must be between 0 and 30. Defaulting to " .. kMakeUpGainDefault)
        makeUpGain = kMakeUpGainDefault
        
    end
    masterCompressorMakeUpGain = makeUpGain
    Print("New Make Up Gain: " .. masterCompressorMakeUpGain)
    Client.SetDSPFloatParameter(masterCompressorId, kMakeUpGainId, masterCompressorMakeUpGain)
    
end
Event.Hook("Console_mcg", OnAdjustMasterCompressorMakeUpGain)

function UpdateDSPEffects()

    PROFILE("DSPEffects:UpdateDSPEffects")
end