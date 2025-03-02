AddCSLuaFile()

ENT.Base 		= "base_nextbot"

ENT.BellyOffset	= Vector(0,0,80)
ENT.SprOffset 		= Vector(0,0,213)
--DONT FORGET TO CHECK IF PLAYER IS NOCLIPPING
--WARN ABT NAVMESH

local color_white = Color(255,255,255)
local color_red = Color( 255, 0, 0 )
local color_blu = Color( 0, 0, 255 )
local mins, maxs = Vector( -24, -3, -2 ), Vector( 24, 3, 2 )
local vector_fwd = Vector(1,0,0)
local vector_rgt = Vector(0,1,0)
local vector_up = Vector(0,0,1)

local workshopID = ""

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

function ENT:SetupDataTables()
	self:NetworkVar("Float",0,"Frame")
	self:NetworkVar("String",1,"State")
	self:NetworkVar("Int",2,"BrimRange")
	self:NetworkVarNotify("State",function ()
		self:SetFrame(0)
	end)
	if SERVER then
		self:SetBrimRange(2000)
	end
end

function ENT:BellyPos()
	return self:GetPos() + self.BellyOffset
end

function ENT:SprPos()
	return self:GetPos() + self.SprOffset
end

function ENT:CheckBrim(startpos)

	local OBBscale = startpos and 0.25 or 1
	startpos = startpos and self:BellyPos() or self:GetPos()

	local filteredents = {}
	for k,v in pairs(ents.GetAll()) do
		if (v:IsPlayer() or v:IsNPC() or v:IsNextBot()) and v:GetClass() != "npc_bloat_tboi" then
			table.insert(filteredents,v)
		end
	end
	table.insert(filteredents,game.GetWorld())
	local TrLeft = util.TraceHull({
	start = startpos,
	endpos = startpos - vector_rgt*self:GetBrimRange(),
	mins = self:OBBMins() * OBBscale,
	maxs = self:OBBMaxs() * OBBscale,
	whitelist = true,
	filter = filteredents
	})
	local TrRight = util.TraceHull({
	start = startpos,
	endpos = startpos + vector_rgt*self:GetBrimRange(),
	mins = self:OBBMins() * OBBscale,
	maxs = self:OBBMaxs() * OBBscale,
	whitelist = true,
	filter = filteredents
	})
	local TrForward = util.TraceHull({
	start = startpos,
	endpos = startpos + vector_fwd*self:GetBrimRange(),
	mins = self:OBBMins() * OBBscale,
	maxs = self:OBBMaxs() * OBBscale,
	whitelist = true,
	filter = filteredents
	})
	local TrBack = util.TraceHull({
	start = startpos,
	endpos = startpos - vector_fwd*self:GetBrimRange(),
	mins = self:OBBMins() * OBBscale,
	maxs = self:OBBMaxs() * OBBscale,
	whitelist = true,
	filter = filteredents
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

if SERVER then

function ENT:Initialize()
	self.JumpedDown 	= false		
	self.LoseTargetDist	= 2100	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 2000	-- How far to search for enemies
	self:SetHealth(100)
	self:SetState("Appear")

	--set to this model for collisions and hitbox
	self:SetModel("models/props_phx/oildrum001.mdl")	
	self:SetCollisionBounds(Vector(-64,-64,0)/4,Vector(64,64,145)/4)
	self:SetModelScale(4,0)
	self:SetAngles(angle_zero)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

hook.Add("Tick","DealBloodDamage",function ()
	for k,v in pairs(ents.GetAll()) do
		if (v:IsPlayer() or v:IsNPC() or v:IsNextBot()) and v.inBloatBlood and v:GetClass()!="npc_bloat_tboi" then
			v:TakeDamage(1,ENT,v.puddleEnt)
		end
	end
end)

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
		if ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() ) then
			self:SetEnemy(v)
			return true
		end
	end
	self:SetEnemy(nil)
	return false
end

resource.AddWorkshop(workshopID)

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
		if self:GetFrame() > 28	and self.JumpedDown == false then
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
			if self:GetFrame() >73 then
				self:Remove()
			else
				local explo = ents.Create( "env_explosion" )
				explo:SetPos( self:GetPos() )
				explo:Spawn()
				-- explo:Fire( "Explode" )
				explo:SetKeyValue( "IMagnitude", 0 )
				coroutine.wait(0.02)	
			end
		else
		if self:HaveEnemy() then
			-- Look at enemy
			self:SetAngles(self:ComputeDrawNormal(self:GetEnemy()):Angle())

			--Brim
				--Brimcheck/damage
				if self:GetState() == "AttackBrim" or self:GetState() == "Idle" then
					local tleft,tright,tfwd,tbck = self:CheckBrim(false)
					for k,v in pairs({tleft,tright,tfwd,tbck}) do
						if v.Hit and v.HitNonWorld then
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

function ENT:ComputeDrawBrimNormal(fwd,brimpos)					
	local normal = LocalPlayer():EyePos() - brimpos
	-- render.DrawBox(pos,angle_zero,Vector(1000,1000,1000),Vector(-1000,-1000,-1000),color_red)
	normal:Normalize()
	local xyNormal = vector_origin
	if fwd then 
		xyNormal = vector_rgt*normal.y + vector_up*normal.z
	else 
		xyNormal = vector_fwd*normal.x + vector_up*normal.z
	end
	xyNormal:Normalize()	-- return vector_fwd
	xyNormal.z = math.max(xyNormal.z,0)
	return xyNormal
end

--DebugDraw AND BrimLaser draw
hook.Add( "PostDrawTranslucentRenderables", "BloatDebug", function()
	local Playerxy = Vector(LocalPlayer():GetPos().x,LocalPlayer():GetPos().y)	
	for k,v in pairs(ents.GetAll()) do
		if v:GetClass() == "npc_bloat_tboi" then
			local min,max = v:GetCollisionBounds()
			local tleft,tright,tfwd,tbck = v:CheckBrim(false)
			render.DrawLine(v:BellyPos(), v:BellyPos() + vector_fwd*v:GetBrimRange(),color_red,true)
			render.DrawLine(v:BellyPos(), v:BellyPos() + vector_rgt*v:GetBrimRange(),color_red,true)
			render.DrawLine(v:BellyPos(), v:BellyPos() - vector_rgt*v:GetBrimRange(),color_red,true)
			render.DrawLine(v:BellyPos(), v:BellyPos() - vector_fwd*v:GetBrimRange(),color_red,true)
			render.SetColorMaterial()
			-- render.DrawBox(tfwd.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)
			-- render.DrawBox(tleft.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)
			-- render.DrawBox(tright.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)
			-- render.DrawBox(tbck.HitPos,angle_zero,v:OBBMins(),v:OBBMaxs(),color_red)		
			render.DrawWireframeBox(v:GetPos(), v:GetAngles(),v:OBBMins(),v:OBBMaxs(),color_red)		
			-- render.DrawSphere(v:BellyPos(),1200,50,50,color_red)

			-- non debug part
			-- if v:GetState() == "AttackBrim" and v:GetFrame() >= 8 and v:GetFrame() <= 60 then
				v:DrawBrim(false,false)
				v:DrawBrim(true,false)
				v:DrawBrim(true,true)
				v:DrawBrim(false,true)
			-- end
		end
	end
end )

function ENT:Draw()
	self:SetRenderAngles(self:ComputeDrawNormal(LocalPlayer()):Angle())
	render.SetMaterial(switch_mat[self:GetState()])
	switch_mat[self:GetState()]:SetInt("$frame",math.floor(self:GetFrame()))
	render.DrawQuadEasy(self:SprPos(),self:ComputeDrawNormal(LocalPlayer()),256,512,color_white,180)

	-- print("Message in ENT:Draw : prevent brim from checking through walls and sprite goes through as well")
end	

-- this function is REALLY complicated i dunno what i was smoking
function ENT:DrawBrim(fwd,close)
	--either fwd or to the right
	--close is for the ones closest to the player
	local relativeY = LocalPlayer():GetPos().y>self:GetPos().y and 1 or -1
	local relativeX = LocalPlayer():GetPos().x>self:GetPos().x and 1 or -1
	local tr = {{},{}}
	local tleft,tright,tfwd,tbck = self:CheckBrim(true)
	-- 1 is X(fwd), 2 is Y(!fwd)
	tr[2][-1] = tleft
	tr[2][1] = tright 
	tr[1][-1] = tbck
	tr[1][1] = tfwd

	local angle = 90 * (close==fwd and relativeX - relativeY or relativeX + relativeY)
	local relative = fwd and relativeX or relativeY
	local vector = fwd and vector_fwd or vector_rgt
	relative = (close and 1 or -1) * relative

	local impact = tr[fwd and 1 or 2][relative].HitPos + vector_up * (self:BellyPos().z - tr[fwd and 1 or 2][relative].HitPos.z)
	local relativeImpact = fwd and impact.x or impact.y
	local relativePos = fwd and self:GetPos().x or self:GetPos().y
	local brimpos = vector_origin

	brimpos = self:BellyPos() + relative * vector*128
	render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim01/BloatBrim01.vmt"))
	render.DrawQuadEasy(brimpos,self:ComputeDrawBrimNormal(fwd,brimpos),256,64,color_white, angle)
	-- if too close to wall dont draw the end
	if relative * relativeImpact > relative * (relativePos + relative * 256) then
		render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim02/BloatBrim02.vmt"))
		local iterations = 0
		while relative * relativeImpact > relative * (relativePos + relative * (128+(iterations+1)*256)) do
			iterations = iterations + 1
			brimpos = self:BellyPos()+ relative * vector*(127 + 256*iterations)
			render.DrawQuadEasy(brimpos,self:ComputeDrawBrimNormal(fwd,brimpos),256,64,color_white, angle)
		end
		
		-- draw the end
		brimpos = impact - relative*vector*64
		render.DrawQuadEasy(brimpos,self:ComputeDrawBrimNormal(fwd,brimpos),256,64,color_white, angle)
	end
	--draw impact
	if tr[fwd and 1 or 2][relative].Hit then 
		brimpos = impact
		render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrimImpact/BloatBrimImpact.vmt"))
		render.DrawQuadEasy(brimpos ,self:ComputeDrawBrimNormal(fwd,brimpos),128,128,color_white, angle - 90)
	end

	--need to account for which one is closer to the player so as to not draw one on top of the one behind it :(
	--!close and fwd
	--render.DrawQuadEasy(self:BellyPos()- relativeX * vector_fwd*128,self:ComputeDrawBrimNormal(LocalPlayer(),true),256,64,color_white, 90*relativeX + 90*relativeY)
	--!close and !fwd
	--render.DrawQuadEasy(self:BellyPos()- relativeY * vector_rgt*128,self:ComputeDrawBrimNormal(LocalPlayer(),false),256,64,color_white, 90*relativeX - 90*relativeY)
	--close and fwd
	-- render.DrawQuadEasy(self:BellyPos() + relativeX * vector_fwd*128,self:ComputeDrawBrimNormal(LocalPlayer(),true),256,64,color_white, 90*relativeX - 90*relativeY)
	--close and !fwd
	-- render.DrawQuadEasy(self:BellyPos()+ relativeY * vector_rgt*128,self:ComputeDrawBrimNormal(LocalPlayer(),false),256,64,color_white, 90*relativeY + 90*relativeX)
end

language.Add("npc_bloat_tboi", "LITTLE FUCKER")

end

list.Set( "NPC", "npc_bloat_tboi", {
	Name = "Bloat",
	Class = "npc_bloat_tboi",
	Category = "TBOI"
})