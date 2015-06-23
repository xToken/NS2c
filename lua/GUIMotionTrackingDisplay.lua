// Natural Selection 2 'Classic' Mod
// lua\GUIMotionTrackingDisplay.lua
// - Dragon

class 'GUIMotionTrackingDisplay' (GUIScript)

local kIconSize = Vector(120, 120, 0)
local kHeartOffset = Vector(0, 0.6, 0)
local kLargeHeartOffset = Vector(0, 1.5, 0)
local kTexture = "ui/sensor.dds"

local function CreateMTIcon(self)

    local icon = GetGUIManager():CreateGraphicItem()
    icon:SetTexture(kTexture)
    icon:SetShader("shaders/GUIMotionTracking.surface_shader")
    icon:SetBlendTechnique(GUIItem.Add)
    self.background:AddChild(icon)
    
    return icon

end

function GUIMotionTrackingDisplay:Initialize()

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetColor(Color(0,0,0,0))
    
    self.icons = {}

end

function GUIMotionTrackingDisplay:Uninitialize()
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
    self.icons = nil
    
end

function GUIMotionTrackingDisplay:Update(deltaTime)

    local players = {}
    local player = Client.GetLocalPlayer()
    
    if player and GetHasTech(player, kTechId.MotionTracking) then
    
        local viewDirection = player:GetViewCoords().zAxis
        local eyePos = player:GetEyePos()
        
        local range = kMotionTrackingDetectionRange
        for _, enemyPlayer in ipairs( GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(player:GetTeamNumber()), eyePos, range) ) do
        
            if not enemyPlayer:isa("Spectator") and not enemyPlayer:isa("Commander") then

                if enemyPlayer:GetIsAlive() then                
                    if viewDirection:DotProduct(GetNormalizedVector(enemyPlayer:GetOrigin() - eyePos)) > 0 then
                        table.insert(players, enemyPlayer)    
                    end
                    
                end
                
            end
        
        end
    
    end
    
    local numPlayers = #players
    local numIcons = #self.icons
    
    if numPlayers > numIcons then
    
        for i = 1, numPlayers - numIcons do
            
            local icon = CreateMTIcon(self)
            table.insert(self.icons, icon)
            
        end
    
    elseif numIcons > numPlayers then
    
        for i = 1, numIcons - numPlayers do
            
            GUI.DestroyItem(self.icons[#self.icons])
            self.icons[#self.icons] = nil
            
        end
    
    end
    
    local eyePos = player:GetEyePos()
    
    for i = 1, numPlayers do
    
        local enemy = players[i]
        local icon = self.icons[i]
     
        //local color = Color(1, 1, 0, 1)
        local offset = (enemy:isa("Onos") or enemy:isa("Fade")) and kLargeHeartOffset or kHeartOffset
        
        local worldPos = enemy:GetOrigin() + offset
        local screenPos = Client.WorldToScreen(worldPos)
        local distanceFraction = 1 - Clamp((worldPos - eyePos):GetLength() / 20, 0, 0.8)

        local size = Vector(kIconSize.x, kIconSize.y, 0) * distanceFraction
        icon:SetPosition(screenPos - size * 0.5)
        icon:SetSize(size)  
        icon:SetColor(kBrightColor)
    
    end

end