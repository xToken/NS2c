//    
// lua\EEMSupport.lua    
// To support eem

if TrainMixin then

	function TrainMixin:GetControllerPhysicsGroup()
		return PhysicsGroup.WhipGroup
	end

end