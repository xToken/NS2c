// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//    
// lua\InfestationMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
//    Anything that spawns Infestation should use this.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    
Script.Load("lua/Infestation_Client_SparserBlobPatterns.lua")

InfestationMixin = CreateMixin(InfestationMixin)
InfestationMixin.type = "Infestation"

local kInitialRadius = 0.5
local kMaxOutCrop = 0.45 // should be low enough so skulks can always comfortably see over it
local kMinOutCrop = 0.1 // should be 
local kMaxIterations = 16
local kInfestationRecedeRate = 6

local _quality = nil
local _numBlobsGenerated = 0

// Purely for debugging/recording. This only affects the visual blobs, NOT the actual infestation radius
local kDebugVisualGrowthScale = 1.0

InfestationMixin.expectedMixins =
{
    Live = "InfestationMixin makes only sense if this entity can take damage (has LiveMixin).",
}

InfestationMixin.expectedCallbacks =
{
    // Returns integer for infestation patch size
    GetMaxRadius = "",
    GetGrowthRate = "",
    GetInfestationDensity = "",
    GetMinRadius = ""
}

InfestationMixin.networkVars =
{
	timeCycleStarted = "time",
    timeCycleEnded = "time"
}

local function random(min, max)
    return math.random() * (max - min) + min
end

local function GetDisplayBlobs(self)

    if PlayerUI_IsOverhead() and self:ReturnPatchCoords(1).yAxis:DotProduct(Vector(0, 1, 0)) < 0.2 then
        return false
    end

    return true  

end
    
function InfestationMixin:OnKill()
    self.timeCycleEnded = Shared.GetTime()
end

function InfestationMixin:__initmixin()
    
    self.timeCycleStarted = Shared.GetTime()
    self.timeCycleEnded = 0
    
    if Client then
        self.minRadius = kInitialRadius
        self.InfestationLocations = { }
        self.InfestationLocations.top = nil
        self.InfestationLocations.north = nil
        self.InfestationLocations.south = nil
        self.InfestationLocations.east = nil
        self.InfestationLocations.west = nil
        self.InfestationLocations.bottom = nil
        self.lastframe = false
        self.validpositions = 0
        
        self:SetUpdates(true)
        
        self.infestationMaterial = Client.CreateRenderMaterial()
        self.infestationMaterial:SetMaterial("materials/infestation/infestation_decal.material")

        // always create blob coords even if we do not display them sometimes
        --self:EnforceOutcropLimits()
        --self:LimitBlobsAspectRatio()
        self:SpawnInfestation()
        self:ResetBlobPlacement()

        self.hasClientGeometry = false
    end
    
end

if Client then

	local Client_GetLocalPlayer = Client.GetLocalPlayer
        
    function InfestationMixin:ReturnPatchCoords(index)
        if not PlayerUI_IsOverhead() then
            if index == 1 and self.InfestationLocations.bottom ~= nil then
                return self.InfestationLocations.bottom
            elseif index == 2 and self.InfestationLocations.north ~= nil then
                return self.InfestationLocations.north
            elseif index == 3 and self.InfestationLocations.south ~= nil then
                return self.InfestationLocations.south
            elseif index == 4 and self.InfestationLocations.east ~= nil then
                return self.InfestationLocations.east
            elseif index == 5 and self.InfestationLocations.west ~= nil then
                return self.InfestationLocations.west
            elseif index == 6 and self.InfestationLocations.top ~= nil then
                return self.InfestationLocations.top
            end
        end
        return self.InfestationLocations.bottom
    end

    function InfestationMixin:GetRadius()

        PROFILE("InfestationMixin:GetRadius")

        local radiusCached = self.radiusCached
        local maxRadius = self:GetMaxRadius()
        local minRadius = self:GetMinRadius()
        
        if radiusCached and maxRadius == radiusCached and self:GetIsAlive() then
            return radiusCached
        end 
        
        local radius = 0
        
        // Check if Infestation was manually grown.
        if maxRadius == minRadius then
            radius = maxRadius
        else

            local cycleDuration = Shared.GetTime() - self.timeCycleStarted
            local growRadius = maxRadius - minRadius
            local timeRequired = growRadius / self:GetGrowthRate()
            local fraction = 0
            
            if self.timeCycleEnded == 0 then
                fraction = Clamp(cycleDuration / timeRequired, 0, 1)
                radius = minRadius + growRadius * fraction
            else
                oldfraction = Clamp(cycleDuration / timeRequired, 0, 1)
                oldradius = minRadius + growRadius * oldfraction
                fraction = 1 - Clamp((Shared.GetTime() - self.timeCycleEnded) / kInfestationRecedeRate, 0, 1)
                radius = oldradius * fraction
            end
             
        end
        
        if radius == maxRadius then
            self.radiusCached = radius
        end
        
        return radius
        
    end

    function InfestationMixin:SetRadiusPercent(percent)
        self.radius = Clamp(percent, 0, 1) * self:GetMaxRadius()
    end

    function InfestationMixin:SetFullyGrown()
        self.radius = self:GetMaxRadius()
    end

    function InfestationMixin:GetIsPointOnInfestation(point, verticalSize)

        local onInfestation = false
        
        // Check radius
        local radius = point:GetDistanceTo(self:GetOrigin())
        if radius <= self:GetRadius() then
        
            // Check dot product
            local toPoint = point - self:GetOrigin()
            local verticalProjection = math.abs( self:ReturnPatchCoords(1).yAxis:DotProduct( toPoint ) )
            
            onInfestation = (verticalProjection < verticalSize)
            
        end
        
        return onInfestation
       
    end

    local function GenerateInfestationCoords(origin, normal)

        local coords = Coords.GetIdentity()
        coords.origin = origin
        coords.yAxis = normal
        coords.zAxis = normal:GetPerpendicular()
        coords.xAxis = coords.zAxis:CrossProduct(coords.yAxis)
        
        return coords
        
    end

    function InfestationMixin:SpawnInfestation()

        local coords = self:GetCoords()
        local attached = self:GetAttached()
        if attached then
            // Add a small offset, otherwise we are not able to track the infested state of the techpoint.
            coords = attached:GetCoords()
            coords.origin = coords.origin + Vector(0.1, 0, 0.1)
        end
        
        self.InfestationLocations.bottom = coords
        self.validpositions = 1
        
        // Ceiling.
        local radius = self:GetMaxRadius()
        local trace = Shared.TraceRay(self:GetOrigin() + coords.yAxis * 0.1, self:GetOrigin() + coords.yAxis * radius,  CollisionRep.Default,  PhysicsMask.Bullets, EntityFilterAll())
        local roomMiddlePoint = self:GetOrigin() + coords.yAxis * 0.1
        if trace.fraction ~= 1 then
            self.InfestationLocations.top = GenerateInfestationCoords(trace.endPoint, trace.normal)
            self.validpositions = self.validpositions + 1
        end
        
        // Front wall.
        trace = Shared.TraceRay(roomMiddlePoint, roomMiddlePoint + coords.zAxis * radius, CollisionRep.Default,  PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction ~= 1 then
            self.InfestationLocations.north = GenerateInfestationCoords(trace.endPoint, trace.normal)
            self.validpositions = self.validpositions + 1
        end
        
        // Back wall.
        trace = Shared.TraceRay(roomMiddlePoint, roomMiddlePoint - coords.zAxis * radius, CollisionRep.Default,  PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction ~= 1 then
            self.InfestationLocations.south = GenerateInfestationCoords(trace.endPoint, trace.normal)
            self.validpositions = self.validpositions + 1
        end
        
        // Left wall.
        trace = Shared.TraceRay(roomMiddlePoint, roomMiddlePoint + coords.xAxis * radius, CollisionRep.Default,  PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction ~= 1 then
            self.InfestationLocations.east = GenerateInfestationCoords(trace.endPoint, trace.normal)
            self.validpositions = self.validpositions + 1
        end
        
        // Right wall.
        trace = Shared.TraceRay(roomMiddlePoint, roomMiddlePoint - coords.xAxis * radius, CollisionRep.Default,  PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction ~= 1 then
            self.InfestationLocations.west = GenerateInfestationCoords(trace.endPoint, trace.normal)
            self.validpositions = self.validpositions + 1
        end
        
        if GetAndCheckBoolean(self.startsBuilt, "startsBuilt", false) then    
            self:SetInfestationFullyGrown()    
        end
        
    end

	local function TraceBlobRay(startPoint, endPoint)
		// we only want to place blobs on static level geometry, so we select this rep and mask
		// For some reason, ceilings do not get infested with Default physics mask. So use Bullets
		return Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
	end

	local kTuckCheckDirs = {
		Vector(1,-0.01,0):GetUnit(),
		Vector(-1,-0.01,0):GetUnit(),
		Vector(0,-0.01,1):GetUnit(),
		Vector(0,-0.01,-1):GetUnit(),
		//Vector(1,0.01,0):GetUnit(),
		//Vector(-1,0.01,0):GetUnit(),
		//Vector(0,0.01,1):GetUnit(),
		//Vector(0,0.01,-1):GetUnit(),

		// diagonals
		Vector(1,-0.01,1):GetUnit(),
		Vector(1,-0.01,-1):GetUnit(),
		Vector(-1,-0.01,-1):GetUnit(),
		Vector(-1,-0.01,1):GetUnit(),
	}

	function InfestationMixin:CreateClientGeometry()

		if _quality == "rich" then
			self:CreateModelArrays(1, 0)
		end
		
		self.hasClientGeometry = true
		
	end

	function InfestationMixin:DestroyClientGeometry()

		if self.infestationModelArray ~= nil then
			Client.DestroyRenderModelArray(self.infestationModelArray)
			self.infestationModelArray = nil
		end

		if self.infestationShellModelArray ~= nil then
			Client.DestroyRenderModelArray(self.infestationShellModelArray)
			self.infestationShellModelArray = nil
		end
	  
		self.hasClientGeometry = false
		
	end

	function InfestationMixin:UpdateClientGeometry()
		
		local cloakFraction = 0
		local parent = self:GetParent()

		if parent ~= nil then
			if GetAreEnemies( parent, Client_GetLocalPlayer()) then
				if HasMixin(parent, "Cloakable") then
					cloakFraction = parent:GetCloakedFraction()
				end
			end
		end
		
		local radius = self:GetRadius()
		local maxRadius = self:GetMaxRadius()
		local radiusFraction = (radius / maxRadius) * kDebugVisualGrowthScale
		
		local origin = self:GetOrigin()
		local amount = radiusFraction
		
		if self.growStartTime ~= nil then
			local time = Shared.GetTime() - self.growStartTime
			amount = math.min(time * 5, amount)
		end

		// apply cloaking effects
		amount = amount * (1-cloakFraction)
		
		//Only update 1 per frame (may seem wierd)
		if self.infestationModelArray then
			if self.lastframe then
				SetMaterialParameters(self.infestationModelArray, amount, origin, maxRadius)
			else
				SetMaterialParameters(self.infestationShellModelArray, amount, origin, maxRadius)
			end
			self.lastframe = not self.lastframe
		end
		
	end

	function InfestationMixin:LimitBlobOutcrop( coords, allowedOutcrop )

		local c = coords

		// Directly enforce it in the normal direction
		local yLen = c.yAxis:GetLength()
		if yLen > allowedOutcrop then
			c.yAxis:Scale( allowedOutcrop/yLen )
		end

		function TuckIn( amounts, amount )

			if math.abs(amounts.x) > 0 then
				local oldLen = c.xAxis:GetLength()
				local s = math.max(allowedOutcrop, oldLen-math.abs(amounts.x))/oldLen
				c.xAxis:Scale(s)
			end
			if math.abs(amounts.y) > 0 then
				local oldLen = c.yAxis:GetLength()
				local s = math.max(allowedOutcrop, oldLen-math.abs(amounts.y))/oldLen
				c.yAxis:Scale(s)
			end
			if math.abs(amounts.z) > 0 then
				local oldLen = c.zAxis:GetLength()
				local s = math.max(allowedOutcrop, oldLen-math.abs(amounts.z))/oldLen
				c.zAxis:Scale(s)
			end
		end

		function CheckAndTuck( bsDir )

			local startPt = c:TransformPoint(bsDir)
			local trace = TraceBlobRay( startPt, c.origin )
			local toCenter = c.origin-startPt

			//DebugLine( startPt, c.origin, 1.0,    1,0,0,1)

			// Have some tolerance for the normal check
			if trace.fraction < 1.0 and trace.normal:DotProduct(toCenter) < -0.01 then
				// a valid hit
				local outcrop = (trace.endPoint-startPt):GetLength()
				local tuckAmount = math.max( 0, outcrop-allowedOutcrop )
				TuckIn( bsDir * tuckAmount )
				
			end

		end

		for dirNum, dir in ipairs(kTuckCheckDirs) do
			CheckAndTuck( dir )
		end

	end

	function InfestationMixin:EnforceOutcropLimits()

		if self.blobCoords == nil then
			return
		end

		for id, coords in ipairs(self.blobCoords) do
			if self.blobOutcrops then
				self:LimitBlobOutcrop( coords, self.blobOutcrops[id] )
			else
				self:LimitBlobOutcrop( coords, kMaxOutCrop )
			end
		end

	end

	local kMaxAspectRatio = 2.0

	function InfestationMixin:LimitBlobsAspectRatio()

		// ONLY in the XZ directions. We want to allow pancakes

		if self.blobCoords == nil then
			return
		end

		for id, c in ipairs(self.blobCoords) do
			xL = c.xAxis:GetLength()
			zL = c.zAxis:GetLength()
			local maxLen = kMaxAspectRatio * math.min( xL, zL )
			if xL > maxLen then c.xAxis:Scale( maxLen/xL ) end
			if zL > maxLen then c.zAxis:Scale( maxLen/zL ) end
		end

	end

	local function TraceBlobSpaceRay(x, z, hostCoords)

		local checkDistance = 2
		local startPoint = hostCoords.origin + hostCoords.yAxis * checkDistance / 2 + hostCoords.xAxis * x + hostCoords.zAxis * z
		local endPoint   = startPoint - hostCoords.yAxis * checkDistance
		return Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, EntityFilterAll())
	end

	local function GetBlobPlacement(x, z, xRadius, hostCoords)

		if hostCoords == nil then
			return nil
		end
		
		local trace = TraceBlobSpaceRay(x, z, hostCoords)
		
		// No geometry to place the blob on
		if trace.fraction == 1 then
			return nil
		end
		
		local position = trace.endPoint
		local normal   = trace.normal

		// Trace some rays to determine the average position and normal of
		// the surface the blob will cover.    
		
		local numTraces = 3
		local numHits   = 0
		local point = { }
		
		local maxDistance = 2
		
		for i=1,numTraces do
		
			local q = ((i - 1) * math.pi * 2) / numTraces
			local xOffset = math.cos(q) * xRadius * 1
			local zOffset = math.sin(q) * xRadius * 1
			local randTrace = TraceBlobSpaceRay(x + xOffset, z + zOffset, hostCoords)
			
			if randTrace.fraction == 1 or (randTrace.endPoint - position):GetLength() > maxDistance then
				return nil
			end
			
			point[i] = randTrace.endPoint
		
		end
		
		local normal = Math.CrossProduct( point[3] - point[1], point[2] - point[1] ):GetUnit()
		return position, normal

	end

	function InfestationMixin:PlaceBlobs(numBlobGens)

		PROFILE("InfestationMixin:PlaceBlobs")
	   
		local xOffset = 0
		local zOffset = 0
		local maxRadius = self:GetMaxRadius()

		local numBlobs   = 0
		local numBlobTries = numBlobGens * 5

		for j = 1, numBlobTries do
		
			local xRadius = random(0.5, 1.5)
			local yRadius = xRadius * 0.5   // Pancakes
			
			local minRand = 0.2
			local maxRand = maxRadius - xRadius

			// Get a uniformly distributed point the circle
			local x, z
			local hasValidPoint = false
			for iteration = 1, kMaxIterations do
				x = random(-maxRand, maxRand)
				z = random(-maxRand, maxRand)
				if x * x + z * z < maxRand * maxRand then
					hasValidPoint = true
					break
				end
			end
			
			if not hasValidPoint then
				Print("Error placing blob, max radius is: %f", maxRadius)
				x, z = 0, 0
			end
			
			local hostcords = self:ReturnPatchCoords(math.random(1,6))
			
			local position, normal = GetBlobPlacement(x, z, xRadius, hostcords)
			
			if position then
			
				local angles = Angles(0, 0, 0)
				angles.yaw = GetYawFromVector(normal)
				angles.pitch = GetPitchFromVector(normal) + (math.pi / 2)
				
				local normalCoords = angles:GetCoords()
				normalCoords.origin = position
				
				local coords = CopyCoords(normalCoords)
				
				coords.xAxis  = coords.xAxis * xRadius
				coords.yAxis  = coords.yAxis * yRadius
				coords.zAxis  = coords.zAxis * xRadius
				coords.origin = coords.origin
				
				table.insert(self.blobCoords, coords)
				numBlobs = numBlobs + 1
				
				if numBlobs == numBlobGens then
					break
				end

			end
		
		end

		return numBlobs
		
	end

	function InfestationMixin:ResetBlobPlacement()

		PROFILE("InfestationMixin:ResetBlobPlacement")

		self.blobCoords = { }
		
		local numBlobGens = self:GetMaxRadius() * self.validpositions * self:GetInfestationDensity()
		local parent = self:GetParent()
		if parent and parent.GetInfestationNumBlobSplats then
			numBlobGens = numBlobGens * parent:GetInfestationNumBlobSplats()
		end    
		
		self.numBlobsToGenerate = numBlobGens
		
	end

	local kGrowingRadialDistance = 0.2

	// t in [0,1]
	local function EaseOutElastic( t )
		local ts = t*t;
		local tc = ts*t;
		return -13.495*tc*ts + 36.2425*ts*ts - 29.7*tc + 3.40*ts + 4.5475*t
	end

	local function OnHostKilledClient(self)

		self.radiusCached = nil
		
	end

	local gDebugDrawBlobs = false
	local gDebugDrawInfest = false

	function InfestationMixin:DebugDrawBlobs()

		local player = Client.GetLocalPlayer()

		if self.blobCoords and player then

			for id,c in ipairs(self.blobCoords) do

				// only draw blobs within 5m of player - too slow otherwise
				if (c.origin-player:GetOrigin()):GetLength() < 5.0 then

					//DebugLine( c.origin, c.origin+c.xAxis, 0, 1,0,0,1 )
					DebugLine( c.origin, c.origin+c.yAxis * 2, 0, 0,1,0,1 )
					//DebugLine( c.origin, c.origin+c.zAxis, 0, 0,0,1,1 )
					//DebugLine( c.origin, c.origin-c.xAxis, 0, 1,1,1,1 )
					//DebugLine( c.origin, c.origin-c.yAxis, 0, 1,1,1,1 )
					//DebugLine( c.origin, c.origin-c.zAxis, 0, 1,1,1,1 )

				end
			end
		end

	end

	function InfestationMixin:DebugDrawInfest()

		DebugWireSphere( self:GetOrigin(), 1.0, 0,   1,0,0,1 )
		DebugLine( self:GetOrigin(), self:GetOrigin() + self:ReturnPatchCoords(1).yAxis*2, 0,     0,1,0,1)

	end
	
	function InfestationMixin:OnDestroy()
		if self.hasClientGeometry then
			self:DestroyClientGeometry()
		end    
	end

	function InfestationMixin:OnUpdate(deltaTime)
        
		PROFILE("InfestationMixin:OnUpdate")
		
        if _quality ~= "rich" then
            return
        end
		
		ScriptActor.OnUpdate(self, deltaTime)

        if not self:GetIsAlive() then
            OnHostKilledClient(self)
        end
		
		if gDebugDrawBlobs then
			self:DebugDrawBlobs()
		end

		if gDebugDrawInfest then
			self:DebugDrawInfest()
		end

		if self.numBlobsToGenerate > 0 then
			numBlobGens = math.min(_numBlobsToGenerate, self.numBlobsToGenerate)
			numBlobGens = self:PlaceBlobs(numBlobGens)
			self.numBlobsToGenerate = self.numBlobsToGenerate - numBlobGens
			_numBlobsToGenerate = _numBlobsToGenerate - numBlobGens
			if _numBlobsToGenerate == 0 then
				self.growStartTime = Shared.GetTime()
			end
		end
		
		if self.numBlobsToGenerate == 0 then
			self:UpdateBlobAnimation()
		end
		
	end

	function SetMaterialParameters(modelArray, radiusFraction, origin, maxRadius)

		modelArray:SetMaterialParameter("amount", radiusFraction)
		modelArray:SetMaterialParameter("origin", origin)
		modelArray:SetMaterialParameter("maxRadius", maxRadius)

	end

	function InfestationMixin:UpdateBlobAnimation()

		PROFILE("InfestationMixin:UpdateBlobAnimation")
		
		if not self.hasClientGeometry and GetDisplayBlobs(self) then
			self:CreateClientGeometry()
		end
		
		if self.hasClientGeometry and not GetDisplayBlobs(self) then
			self:DestroyClientGeometry()
		end    
	  
		self:UpdateClientGeometry()  
	  
	end

	local function CreateInfestationModelArray(modelName, blobCoords, origin, radialOffset, growthFraction, maxRadius, radiusScale, radiusScale2 )

		local modelArray = nil
		
		if #blobCoords > 0 then
				
			local coordsArray = { }
			local numModels = 0
			
			for index, coords in ipairs(blobCoords) do

				local c  = Coords()
				c.xAxis  = coords.xAxis  * radiusScale
				c.yAxis  = coords.yAxis  * radiusScale2
				c.zAxis  = coords.zAxis  * radiusScale
				c.origin = coords.origin - coords.yAxis * 0.3 // Embed slightly in the surface
				
				numModels = numModels + 1
				coordsArray[numModels] = c
				
			end
			
			if numModels > 0 then

				modelArray = Client.CreateRenderModelArray(RenderScene.Zone_Default, numModels)
				modelArray:SetCastsShadows(false)
				modelArray:InstanceMaterials()

				modelArray:SetModel(modelName)
				modelArray:SetModels( coordsArray )

			end
			
		end
		
		return modelArray

	end

	function InfestationMixin:CreateModelArrays( growthFraction, radialOffset )
		
		// Make blobs on the ground thinner to so that Skulks and buildings aren't
		// obscured.
		local scale = 1
		local hostcoords = self:ReturnPatchCoords(1)
		if hostcoords ~= nil and hostcoords.yAxis.y > 0.5 then
			scale = 0.75
		end

		self.infestationModelArray      = CreateInfestationModelArray( "models/alien/infestation/infestation_blob.model", self.blobCoords, self.growthOrigin, radialOffset, growthFraction, self:GetMaxRadius(), 1, 1 * scale )
		self.infestationShellModelArray = CreateInfestationModelArray( "models/alien/infestation/infestation_shell.model", self.blobCoords, self.growthOrigin, radialOffset, growthFraction, self:GetMaxRadius(), 1.75, 1.25 * scale )
		
	end

	local function OnCommandResizeBlobs()

	// NOTE: not sure if this works anymore

		if Client  then

			local infests = GetEntitiesWithMixin("Infestation")

			for id,infest in ipairs(infests) do
				infest:EnforceOutcropLimits()
				infest:LimitBlobsAspectRatio()
				// force recreation of model arrays
				infest:DestroyClientGeometry()
			end

		end

	end

	function Infestation_SetQuality(quality)

		_quality = quality
		Client.SetRenderSetting("infestation", _quality)
		
		local ents = GetEntitiesWithMixin("Infestation")
		for id,ent in ipairs(ents) do
			ent:DestroyClientGeometry()
		end
		
	end

	function Infestation_UpdateForPlayer()
		
		// Maximum number of blobs to generate in a frame
		_numBlobsToGenerate = 20

		// Change the texture scale when we're viewing top down to reduce the
		// tiling and make it look better.
		if PlayerUI_IsOverhead() then
			Client.SetRenderSetting("infestation_scale", 0.15)
		else
			Client.SetRenderSetting("infestation_scale", 0.30)
		end

	end

	function Infestation_SyncOptions()
		Infestation_SetQuality( Client.GetOptionString("graphics/infestation", "rich") )
	end

	local function OnLoadComplete()
		if Client then
			Infestation_SyncOptions()
		end
	end

	Event.Hook("Console_resizeblobs", OnCommandResizeBlobs)
	Event.Hook("Console_debugblobs", function() gDebugDrawBlobs = not gDebugDrawBlobs end)
	Event.Hook("Console_debuginfest", function() gDebugDrawInfest = not gDebugDrawInfest end)
	Event.Hook("LoadComplete", OnLoadComplete)

	Event.Hook("Console_blobspeed", function(scale)
		if tonumber(scale) then
			kDebugVisualGrowthScale = tonumber(scale)
		else
			Print("Usage: blobspeed 2.0")
		end
		Print("blobspeed = %f", kDebugVisualGrowthScale)
	end)
	
end