// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade_Client.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Fade.kFirstPersonMiniBlinkCinematic = "cinematics/alien/fade/miniblink1p.cinematic"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/fade_blink.surface_shader")

local kBlink2DSound = PrecacheAsset("sound/NS2.fev/alien/fade/blink_loop")

local kFadeCameraYOffset = 0.6

local kFadeTrailDark = {
    PrecacheAsset("cinematics/alien/fade/trail_dark_1.cinematic"),
    PrecacheAsset("cinematics/alien/fade/trail_dark_2.cinematic"),
}

local kFadeTrailGlow = {
    PrecacheAsset("cinematics/alien/fade/trail_glow_1.cinematic"),
    PrecacheAsset("cinematics/alien/fade/trail_glow_2.cinematic"),
}

function Fade:UpdateClientEffects(deltaTime, isLocal)

    Alien.UpdateClientEffects(self, deltaTime, isLocal)

    /*
    if not self.trailCinematic then
        self:CreateTrailCinematic()
    end
    
    //local showTrail = (self:GetIsBlinking() or self:GetIsShadowStepping()) and (not isLocal or self:GetIsThirdPerson())
    
    self.trailCinematic:SetIsVisible(showTrail)
    self.scanTrailCinematic:SetIsVisible(showTrail and self.isScanned)
    
    if self:GetIsAlive() then
    
        if self:GetIsShadowStepping() then
            self.blinkDissolve = 1    
        elseif self:GetIsBlinking() then
            self.blinkDissolve = 0.6
            self.wasBlinking = true
        else
        
            if self.wasBlinking then
                self.wasBlinking = false
                self.blinkDissolve = 1
            end    
        
            self.blinkDissolve = math.max(0, self.blinkDissolve - deltaTime)
        end
    
    else
        self.blinkDissolve = 0
    end  
    */
    if isLocal then
        self:UpdateBlink2DSound()
    end
    
end

function Fade:UpdateBlink2DSound()

    local playSound = self:GetIsBlinking() and not GetHasSilenceUpgrade(self)

    if playSound and not self.blinkSoundPlaying then
    
        //Shared.PlaySound(self, kBlink2DSound)
        //self.blinkSoundPlaying = true
        
    elseif not playSound and self.blinkSoundPlaying then
    
        //Shared.StopSound(self, kBlink2DSound)
        //self.blinkSoundPlaying = false
        
    end

end

function Fade:OnUpdateRender()
    
    PROFILE("Fade:OnUpdateRender")

    Player.OnUpdateRender(self)

    /*
    local model = self:GetRenderModel()
    if model and self.blinkDissolve then
    
        if not self.blinkMaterial then
            self.blinkMaterial = AddMaterial(model, "cinematics/vfx_materials/fade_blink.material") 
        end
        
        self.blinkMaterial:SetParameter("blinkAmount", self.blinkDissolve)  
        
    end

    self:SetOpacity((self:GetIsBlinking()) and 0 or 1, "blinkAmount")
    */
end  

function Fade:CreateTrailCinematic()

    /*
    local options = {
            numSegments = 2,
            collidesWithWorld = false,
            visibilityChangeDuration = 0.2,
            fadeOutCinematics = true,
            stretchTrail = false,
            trailLength = 1,
            minHardening = 0.01,
            maxHardening = 0.2,
            hardeningModifier = 0.8,
            trailWeight = 0
        }

    self.trailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)
    self.trailCinematic:SetCinematicNames(kFadeTrailDark)    
    self.trailCinematic:AttachToFunc(self, TRAIL_ALIGN_MOVE, Vector(0, 1.3, 0.2) )                
    self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    self.trailCinematic:SetOptions(options)

    self.scanTrailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)
    self.scanTrailCinematic:SetCinematicNames(kFadeTrailGlow)    
    self.scanTrailCinematic:AttachToFunc(self, TRAIL_ALIGN_MOVE, Vector(0, 1.3, 0.2) )                
    self.scanTrailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    self.scanTrailCinematic:SetOptions(options)
    */
end

function Fade:DestroyTrailCinematic()
    /*
    if self.trailCinematic then
    
        Client.DestroyTrailCinematic(self.trailCinematic)
        self.trailCinematic = nil
    
    end
    
    if self.scanTrailCinematic then
    
        Client.DestroyTrailCinematic(self.scanTrailCinematic)
        self.scanTrailCinematic = nil
    
    end
    */
end

function Fade:TriggerFirstPersonMiniBlinkEffect(direction)

    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
    cinematic:SetCinematic(Fade.kFirstPersonMiniBlinkCinematic)
    local coords = Coords.GetIdentity()
    coords.zAxis = direction
    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
    
    cinematic:SetCoords(coords)

end