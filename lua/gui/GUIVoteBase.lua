//NS2 GUI Vote Base

Script.Load("lua/GUIScript.lua")

class 'GUIVoteBase' (GUIScript)

local kScale = 1.2
GUIVoteBase.kFontName = "fonts/AgencyFB_medium.fnt"
GUIVoteBase.kFontScale = GUIScale(Vector(1,1,0)) * 0.7

GUIVoteBase.kBgSize = GUIScale(Vector(230, 50, 0)) * kScale
GUIVoteBase.kSize = GUIVoteBase.kBgSize

GUIVoteBase.kTextYOffset = GUIScale(6) * kScale

GUIVoteBase.kBgPosition = Vector(GUIVoteBase.kBgSize.x * -.5, GUIScale(-150) * kScale, 0)

local kScale = 1.2

function GUIVoteBase:Initialize()
    self.votemenu = GUIManager:CreateGraphicItem()
    self.votemenu:SetSize(GUIVoteBase.kBgSize)
    self.votemenu:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.votemenu:SetPosition(GUIVoteBase.kBgPosition)
    self.votemenu:SetTexture(texture)
    self.votemenu:SetTexturePixelCoordinates(unpack(kBackgroundPixelCoords))
    self.votemenu:SetColor(Color(1,1,1,0))
	
	self.headerText = GUIManager:CreateTextItem()
    self.headerText:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.headerText:SetTextAlignmentX(GUIItem.Align_Center)
    self.headerText:SetTextAlignmentY(GUIItem.Align_Min)
    self.headerText:SetPosition(Vector(0, GUIVoteBase.kTextYOffset, 0))
    self.headerText:SetInheritsParentAlpha(true)
    self.headerText:SetFontName(GUIVoteBase.kFontName)
    self.headerText:SetScale(GUIVoteBase.kFontScale)
    self.headerText:SetColor(Color(1,1,1,1))
    self.votemenu:AddChild(self.headerText)
	
	self.votemenu:SetIsVisible(false)
end

function GUIVoteBase:Uninitialize()
    if self.votemenu then
        GUI.DestroyItem(self.votemenu)
        self.votemenu = nil
    end
end

function GUIVoteBase:Update(deltaTime)

end
    

//GUIVoteBase
//local kVoteBaseUpdateMessage = 
//{
//	key              	= "integer",
//	header         		= string.format("string (%d)", kMaxVoteStringLength),
//	option1         	= string.format("string (%d)", kMaxVoteStringLength),
//	option1desc         = string.format("string (%d)", kMaxVoteStringLength),
//	option2        		= string.format("string (%d)", kMaxVoteStringLength),
//	option2desc         = string.format("string (%d)", kMaxVoteStringLength),
//	option3        		= string.format("string (%d)", kMaxVoteStringLength),
//	option3desc         = string.format("string (%d)", kMaxVoteStringLength),
//	option4        		= string.format("string (%d)", kMaxVoteStringLength),
//	option4desc         = string.format("string (%d)", kMaxVoteStringLength),
//	option5         	= string.format("string (%d)", kMaxVoteStringLength),
//	option5desc         = string.format("string (%d)", kMaxVoteStringLength),
//	footer         		= string.format("string (%d)", kMaxVoteStringLength),
//	votetime   	  		= "time"
//}

