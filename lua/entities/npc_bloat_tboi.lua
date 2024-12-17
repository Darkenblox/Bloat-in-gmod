AddCSLuaFile()

ENT.Base 		= "base_nextbot"
ENT.Spawnable	= true

--DONT FORGET TO CHECK IF PLAYER IS NOCLIPPING
--frame increment in GM:Think

local color_white = Color(255,255,255)
local color_red = Color( 255, 0, 0 )
local color_blu = Color( 0, 0, 255 )
local mins, maxs = Vector( -24, -3, -2 ), Vector( 24, 3, 2 )
local vector_fwd = Vector(1,0,0)
local vector_rgt = Vector(0,1,0)
local vector_up = Vector(0,0,1)

local switch_mat = {
	["Death"] = Material("npc_bloat_tboi/animations/BloatDeath/BloatDeath.vmt"),
	["JumpUp"] = Material("npc_bloat_tboi/animations/BloatJumpUp/BloatJumpUp.vmt"),
	["JumpDown"] = Material("npc_bloat_tboi/animations/BloatJumpDown/BloatJumpDown.vmt"),
	["Appear"] = Material("npc_bloat_tboi/animations/BloatAppear/BloatAppear.vmt"),
	["Walk"] = Material("npc_bloat_tboi/animations/BloatWalk/BloatWalk.vmt"),
	["AttackCreep"] = Material("npc_bloat_tboi/animations/BloatAttack02/BloatAttack02.vmt"),
	["AttackSlam"] = Material("npc_bloat_tboi/animations/BloatAttack01/BloatAttack01.vmt"),
	["AttackBrim"] = Material("npc_bloat_tboi/animations/BloatAttackBrim/BloatAttackBrim.vmt"),
	["Idle"] = Material("npc_bloat_tboi/animations/BloatIdle/BloatIdle.png")
}

--DebugDraw
hook.Add( "PostDrawTranslucentRenderables", "BloatDebug", function()
	local Playerxy = Vector(LocalPlayer():GetPos().x,LocalPlayer():GetPos().y)	
	for k,v in pairs(ents.GetAll()) do
		if v:GetClass() == "npc_bloat_tboi" then
			local min,max = v:GetCollisionBounds()
			local tleft,tright,tfwd,tbck = v:CheckBrim()
			render.DrawLine(v:BellyPos(), v:BellyPos() + vector_fwd*v.BrimRange,color_red,true)
			render.DrawLine(v:BellyPos(), v:BellyPos() + vector_rgt*v.BrimRange,color_red,true)
			render.DrawLine(v:BellyPos(), v:BellyPos() - vector_rgt*v.BrimRange,color_red,true)
			render.DrawLine(v:BellyPos(), v:BellyPos() - vector_fwd*v.BrimRange,color_red,true)
			render.SetColorMaterial()
			-- render.DrawBox(tfwd.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)
			-- render.DrawBox(tleft.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)
			-- render.DrawBox(tright.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)
			-- render.DrawBox(tbck.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)		
			render.DrawWireframeBox(v:GetPos(), v:GetAngles(),v:OBBMins(),v:OBBMaxs(),color_red)		
			-- render.DrawSphere(v:BellyPos(),1200,50,50,color_red)
		end
	end
end )
--end draw line

function ENT:Initialize()
	self.JumpedDown 	= false
	self.BrimRange 		= 900
	self.Height 		= 512
	self.BellyOffset	= Vector(0,0,80)
	self.SprOffset 		= Vector(0,0,213)	--SpriteOffset		
	self.LoseTargetDist	= 2100	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 2000	-- How far to search for enemies
	self:SetHealth(100)
	self:SetState("Appear")

	--set to this model for collisions and hitbox
	self:SetModel("models/props_phx/construct/metal_plate_curve360x2.mdl")	
	self:SetCollisionBounds(Vector(-64,-64,0),Vector(64,64,145))
	self:SetAngles(angle_zero)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:SetupDataTables()
	self:NetworkVar("Float",0,"Frame")
	self:NetworkVar("String",1,"State")
	self:NetworkVarNotify("State",function ()
		self:SetFrame(0)
	end)
end

function ENT:SetEnemy(ent)
	self.Enemy = ent
end

function ENT:GetEnemy()
	return self.Enemy
end

function ENT:HaveEnemy()
	if ( self:GetEnemy() and IsValid(self:GetEnemy()) ) then
		if ( self:GetRangeTo(self:GetEnemy():GetPos()) > self.LoseTargetDist ) then
			return self:FindEnemy()
		elseif ( self:GetEnemy():IsPlayer() and !self:GetEnemy():Alive() ) then
			return self:FindEnemy()
		end
		return true
	else
		return self:FindEnemy()
	end
end

function ENT:FindEnemy()
	local _ents = ents.FindInSphere( self:GetPos(), self.SearchRadius )
	for k,v in ipairs( _ents ) do
		if ( v:IsPlayer() ) then
			self:SetEnemy(v)
			return true
		end
	end
	self:SetEnemy(nil)
	return false
end

function ENT:BellyPos()
	return self:GetPos() + self.BellyOffset
end

function ENT:SprPos()
	return self:GetPos() + self.SprOffset
end

function ENT:CheckBrim()
	local TrLeft = util.TraceHull({
	start = self:GetPos(),
	endpos = self:GetPos() - vector_rgt*self.BrimRange,
	mins = self:OBBMins(),
	maxs = self:OBBMaxs(),
	whitelist = true,
	filter = player.GetAll(),
	ignoreworld = true,
	})
	local TrRight = util.TraceHull({
	start = self:GetPos(),
	endpos = self:GetPos() + vector_rgt*self.BrimRange,
	mins = self:OBBMins(),
	maxs = self:OBBMaxs(),
	whitelist = true,
	filter = player.GetAll(),
	ignoreworld = true,
	})
	local TrForward = util.TraceHull({
	start = self:GetPos(),
	endpos = self:GetPos() + vector_fwd*self.BrimRange,
	mins = self:OBBMins(),
	maxs = self:OBBMaxs(),
	whitelist = true,
	filter = player.GetAll(),
	ignoreworld = true,
	})
	local TrBack = util.TraceHull({
	start = self:GetPos(),
	endpos = self:GetPos() - vector_fwd*self.BrimRange,
	mins = self:OBBMins(),
	maxs = self:OBBMaxs(),
	whitelist = true,
	filter = player.GetAll(),
	ignoreworld = true,
	})
	return TrLeft,TrRight,TrForward,TrBack	
end

function ENT:ComputeDrawNormal(player)					
	local pos = self:GetPos()
	local normal = player:GetPos() - pos
	local xyNormal = vector_fwd*normal.x + vector_rgt*normal.y
	xyNormal:Normalize()
	return xyNormal
end

function ENT:ComputeDrawBrimNormal(player,fwd)					
	local pos = self:GetPos()
	local normal = player:GetPos() - pos
	local xyNormal = vector_origin
	if fwd then 
		xyNormal = vector_rgt*normal.y + vector_up*normal.z
	else 
		xyNormal = vector_fwd*normal.x + vector_up*normal.z
	end
	xyNormal:Normalize()
	-- return vector_fwd
	return xyNormal
end

if SERVER then

function ENT:HandleJump(seekpos)
	--StartJump
	if self:GetState() == "Idle" then
		local targetarea = navmesh.Find(seekpos,900,100,100)
		if #targetarea == 0 then
			self:GetEnemy():PrintMessage(3,"Bloat cant find a place to jump to, maybe try rebuilding navmesh")
		else
			self:SetState("JumpUp")
		end
	end
	--JumpUp
	if self:GetState() == "JumpUp" and self:GetFrame() > 32 then
		local iterations = 0
		while self:GetState() == "JumpUp" do
			iterations 	= iterations + 1
			local targetarea = navmesh.Find(seekpos,900,100,100)
			local targetpos = targetarea[math.random(#targetarea)]:GetRandomPoint()
			local tr = util.TraceEntity({
				start = targetpos,
				endpos = targetpos
			}, self)
			if not tr.Hit then
				self:SetPos(targetpos)
				self:SetState("JumpDown")
			elseif iterations > 400 then
				self:SetState("JumpDown")
			end
		end
	end
	--JumpDown
	if self:GetState() == "JumpDown" then
		if self:GetFrame() > 28					 and self.JumpedDown == false then
			for i=1,8 do
				local tear = ents.Create("ent_bloat_tear")
				tear:SetPos(self:BellyPos())
				tear.move_vect = Angle(0,45*i,0):Forward() * 1100
				tear.BloatParent = self
				tear:Spawn()
			end
			self.JumpedDown = true
		end
		if self:GetFrame() > 67 then
			self:SetState("Idle")
			self.JumpedDown = false
		end
	end
end

function ENT:RunBehaviour()
	while true do	
		if self:GetState() == "Appear" and self:GetFrame() > 19 then
			self:SetState("Idle")
		end
		if self:GetState() == "Death" then
			for i=1,100 do
				local explo = ents.Create( "env_explosion" )
				explo:SetPos( self:GetPos() )
				explo:Spawn()
				explo:Fire( "Explode" )
				explo:SetKeyValue( "IMagnitude", 0 )
				coroutine.wait(0.02)	
			end
			self:Remove()	
		else
		if self:HaveEnemy() then
			-- Look at enemy
			self:SetAngles(self:ComputeDrawNormal(self:GetEnemy()):Angle())

			--Brim
				--Brimcheck/damage
				if self:GetState() == "AttackBrim" or self:GetState() == "Idle" then
					local tleft,tright,tfwd,tbck = self:CheckBrim()
					for k,v in pairs({tleft,tright,tfwd,tbck}) do
						if v.Hit then
							if self:GetState() == "AttackBrim" then	
								if self:GetFrame() >= 8 and self:GetFrame() <= 60 then
									local dmg = DamageInfo()
									local dmgvect = (v.HitPos - self:GetPos()):GetNormalized() * 300000000000000000
									dmgvect.z = 1000000000000000
									dmg:SetAttacker(self)
									dmg:SetDamageForce(dmgvect)
									dmg:SetDamage(1000)
									v.Entity:TakeDamageInfo(dmg) --make inflictor the brimstone sprite ig
								end
							elseif math.random(3)==1 then
								coroutine.wait(0.5)
								self:SetState("AttackBrim")	
							end
						end
					end
				end
				--Brimstate end
				if self:GetState() == "AttackBrim" and 	self:GetFrame() > 67 then
					self:SetState("Idle")
					coroutine.wait(1.5)
				end					

			--Idle (brim takes priority)
			if self:GetState() == "Idle" then
				local idle_transition = math.random(1000)
				if 	idle_transition < 3 then 
					self:HandleJump(self:GetEnemy():GetPos())
				elseif self:GetEnemy():GetPos():Distance(self:GetPos()) < 1200 then
					if idle_transition < 8 and self:GetEnemy():GetPos():Distance(self:GetPos()) > 300 then
						self:SetState("Walk")
						self.loco:SetDesiredSpeed(100)
						self.loco:SetAcceleration(100)
						self.loco:SetDeceleration(1000)
					elseif idle_transition < 12 then
						
					end
				end
			end

			--Jumpstate
			if self:GetState() == "JumpUp" or self:GetState() == "JumpDown" then
				self:HandleJump(self:GetEnemy():GetPos())
			end

			--Walk
			if self:GetState() == "Walk" then
				if self:GetFrame() < 25 then self.loco:Approach(self:GetEnemy():GetPos(),1) end
				if self:GetFrame() > 29 then self:SetState("Idle") end
			end
		
		else
			--Jump to random spot if cannot find an enemy
			if math.random(5000) == 1 or self:GetState() == "JumpUp" or self:GetState() == "JumpDown" then
				self:HandleJump(self:GetPos())
			end
		end
		end
		coroutine.yield()					
	end				
end

hook.Add("Think","IncrementFrameBloat",function()
	for k,v in pairs(ents.GetAll()) do
		if v:GetClass() == "npc_bloat_tboi" then
			v:SetFrame(v:GetFrame() + 30 * FrameTime())
			--print(v:GetFrame())
		end	
	end
end)

function ENT:OnKilled( dmginfo )
	hook.Call( "OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )
	self:SetState("Death")
end

--to delete
function ENT:FollowPlayer()
	--placeholder follow nextbot
	local path = Path("Follow")
	local player = Entity(1)
	self.loco:SetClimbAllowed(true)
	path:SetMinLookAheadDistance( 3000 )
	path:SetGoalTolerance( 200 )
	path:Compute( self, player:GetPos() )
	path:Draw()
	self.loco:SetJumpHeight(1000)
	self.loco:SetDeathDropHeight(10000)
	self.loco:SetStepHeight(18)
	self.loco:SetJumpGapsAllowed(true)
	path:Update(self)
end

end

if CLIENT then

function ENT:Draw()
	self:SetRenderAngles(self:ComputeDrawNormal(LocalPlayer()):Angle())
	render.SetMaterial(switch_mat[self:GetState()])
	switch_mat[self:GetState()]:SetInt("$frame",math.floor(self:GetFrame()))
	render.DrawQuadEasy(self:SprPos(),self:ComputeDrawNormal(LocalPlayer()),self.Height/2,self.Height,color_white,180)
	render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim01/BloatBrim01.vmt"))
	local relativeY = LocalPlayer():GetPos().y>self:GetPos().y and 1 or -1
	local relativeX = LocalPlayer():GetPos().x>self:GetPos().x and 1 or -1
	render.DrawQuadEasy(self:BellyPos()- relativeX * vector_fwd*128,self:ComputeDrawBrimNormal(LocalPlayer(),true),256,64,color_white, 90*relativeX + 90*relativeY)
	render.DrawQuadEasy(self:BellyPos()- relativeY * vector_rgt*128,self:ComputeDrawBrimNormal(LocalPlayer(),false),256,64,color_white, 90*relativeX - 90*relativeY)
	render.DrawQuadEasy(self:BellyPos()+ relativeX * vector_fwd*128,self:ComputeDrawBrimNormal(LocalPlayer(),true),256,64,color_white, 90*relativeX - 90*relativeY)
	render.DrawQuadEasy(self:BellyPos()+ relativeY * vector_rgt*128,self:ComputeDrawBrimNormal(LocalPlayer(),false),256,64,color_white, 90*relativeY + 90*relativeX)
	if self:GetState() == "AttackBrim" and self:GetFrame() >= 8 and self:GetFrame() <= 60 then
		
	end
end	

language.Add("npc_bloat_tboi", "LITTLE FUCKER")

end

list.Set( "NPC", "npc_bloat_tboi", {
	Name = "Bloat",
	Class = "npc_bloat_tboi",
	Category = "TBOI"
})