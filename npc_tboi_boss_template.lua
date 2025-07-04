AddCSLuaFile()

ENT.Base 		= "base_nextbot"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

--offset values for drawing sprites and height of brim
ENT.BellyOffset	= Vector(0,0,80)
ENT.SprOffset 		= Vector(0,0,213)

local color_white = Color(255,255,255)
local color_red = Color( 255, 0, 0 )
local color_blu = Color( 0, 0, 255 )
local mins, maxs = Vector( -24, -3, -2 ), Vector( 24, 3, 2 )
local vector_fwd = Vector(1,0,0)
local vector_rgt = Vector(0,1,0)
local vector_up = Vector(0,0,1)

local workshopID = ""

--Use this structure for each state, vmt links to an animated texture
local switch_mat = {
	["State"] = Material("<boss_name>/animations/State/State.vmt"),
}

function ENT:SetupDataTables()
	--Used for handling states and keeping a steady framerate on the animation
	self:NetworkVar("Float",0,"Frame")
	self:NetworkVar("String",1,"State")
	self:NetworkVarNotify("State",function ()
		self:SetFrame(0)
	end)

	--Delete if you don't need Brimstone for the boss
	self:NetworkVar("Int",2,"BrimRange")
	if SERVER then
		self:SetBrimRange(10000)
	end
end

function ENT:BellyPos()
	return self:GetPos() + self.BellyOffset
end

function ENT:SprPos()
	return self:GetPos() + self.SprOffset
end

function ENT:CheckBrim(startpos)
	local OBBscale = startpos and 0.65 or 1
	startpos = startpos and self:BellyPos() - vector_up * 50 or self:GetPos()

	local filteredents = {}
	for k,v in pairs(ents.GetAll()) do
		if (v:IsPlayer() or v:IsNPC() or v:IsNextBot()) and v:GetClass() != self:GetClass() and v:GetClass() != "ent_boss_template_puddle" then
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

--the function used for getting the normal of the sprite pointing towards the player (stolen from sanic nextbot)
function ENT:ComputeDrawNormal(player)					
	local pos = self:GetPos()
	local normal = player:GetPos() - pos
	local xyNormal = vector_fwd*normal.x + vector_rgt*normal.y
	xyNormal:Normalize()
	return xyNormal
end

--useful function for spawning blood on an ellipse for example
function ENT:RandomPointsOnEllipse(pos,a,b)
	local angle = math.Rand(0,2*math.pi)
	local rad = math.random()
	local vect = math.sqrt(rad) * (vector_fwd * math.cos(angle) * a / 2 + vector_rgt * math.sin(angle) * b / 2)
	return pos + vect
end

if SERVER then

function ENT:Initialize()
	self:DrawShadow(false)
	self.LoseTargetDist	= 2100	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 2000	-- How far to search for enemies
	self:SetHealth(1500)
	self:SetState("Appear")

	--useful booleans
	--these are used if your boss needs to jump to another location
	self.JumpedDown 	= false		
	self.saidnojumpmessage = false

	--used if your boss needs to spill blood
	self.SpilledBlood 	= false

	--used if your boss shoots brimstone beams
	self.playedBrimSound = false

	--set to this model for collisions and hitbox (use a model that sort of fits the size of your boss)
	--this is the model used for the bloat Boss
	self:SetModel("models/props_phx/oildrum001.mdl")	
	self:SetCollisionBounds(Vector(-64,-64,0)/4,Vector(64,64,145)/4)
	self:SetModelScale(4,0)

	self:SetAngles(angle_zero)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)

	--this is used if your boss spawns bloodpuddles
	self.bloodpuddles = {}
	util.AddNetworkString("UpdatePuddleList")
	--dont forget to change the name of this
	self:CallOnRemove("DeleteBossTemplatePuddles",function() self:DeleteBossTemplatePuddles() end)
end

--important hook for the boss animation, it renders it at 30 fps like in isaac
hook.Add("Think","IncrementFrameBossTemplate",function()
	for k,v in pairs(ents.GetAll()) do
		if v:GetClass() == "npc_tboi_boss_template" then
			v:SetFrame(v:GetFrame() + 30 * FrameTime())
		end	
	end
end)

--The following code is from the facepunch wiki for handling ennemies
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
		if ( v:IsPlayer() or v:IsNPC() or v:IsNextBot() and v:GetClass()!=self:GetClass()) then
			self:SetEnemy(v)
			return true
		end
	end
	self:SetEnemy(nil)
	return false
end

resource.AddWorkshop(workshopID)

--this whole section can be deleted if you don't need puddles
hook.Add("Tick","DealBossTemplateBloodDamage",function ()
	for k,v in pairs(ents.GetAll()) do
		if (v:IsPlayer() or v:IsNPC() or v:IsNextBot()) and v.inBossTemplateBlood and v:GetClass()!="npc_tboi_boss_template" then
			v:TakeDamage(1,v.puddleEnt.parentBoss,v.puddleEnt.parentBoss)
		end
	end
end)
function ENT:CreatePuddle(index,pos)
	local bloodent = ents.Create("ent_boss_template_puddle")
	bloodent:SetPos(pos)
	bloodent:SetPuddleIndex(index)
	bloodent.parentBoss = self
	table.insert(self.bloodpuddles,bloodent)
	self:UpdateClientsidePuddlesList()
	bloodent:CallOnRemove("RemoveFromBloodList",function()
		if self:IsValid() then
			table.RemoveByValue(self.bloodpuddles,bloodent)
			self:UpdateClientsidePuddlesList()
		end
	end)
	bloodent:Spawn()
	timer.Simple(0.5,function() 
		if self:IsValid() and bloodent:IsValid() then
			bloodent.trigger:Spawn()
			if self:GetPos():Distance(bloodent:GetPos()) > 700 then
				bloodent:Remove()
			end
		end
	end)
end
function ENT:DeleteBossTemplatePuddles()
	for k,v in pairs(self.bloodpuddles) do
		if v:IsValid() then
			v:Remove()
		end
	end
end
function ENT:UpdateClientsidePuddlesList()
	net.Start("UpdatePuddleList")
	net.WriteEntity(self)
	net.WriteTable(self.bloodpuddles,false)
	net.Broadcast()
end
--tweak the values depending on your boss (creates a bunch of blood on the floor)
function ENT:SpillBlood(sizemult)
	sizemult = sizemult==nil and 1 or sizemult
	--one big blood
	self:CreatePuddle(math.random(13,18),self:GetPos())
	for i=1,5*sizemult do
		self:CreatePuddle(math.random(7,12),self:RandomPointsOnEllipse(self:GetPos(),200*sizemult,300*sizemult))
		self:CreatePuddle(math.random(1,6),self:RandomPointsOnEllipse(self:GetPos(),300*sizemult,400*sizemult))
	end
end

--this is more similar to bloat's jump, he will find a random place to jump to
--if you want another behaviour feel free to change this
function ENT:HandleJump(seekpos, jumprange)
	--StartJump
	if self:GetState() == "Idle" then
		local targetarea = navmesh.Find(seekpos,jumprange,5000,5000)
		if #targetarea == 0 then
			if not self.saidnojumpmessage then
				self:GetEnemy():PrintMessage(3,"BossTemplate cant find a place to jump to, maybe try rebuilding navmesh")
			end
		else
			self:SetState("JumpUp")
			self:EmitSound("npc_bloat_tboi/sfx_bloat_sloppy_roar.wav",100,100,1)
		end
	end
	--JumpUp
	if self:GetState() == "JumpUp" and self:GetFrame() > 32 then
		local iterations = 0
		while self:GetState() == "JumpUp" do
			iterations 	= iterations + 1
			if iterations > 400 then
				self:SetState("JumpDown")
			end
			local targetarea = navmesh.Find(seekpos,jumprange,5000,5000)
			if #targetarea > 0 then
				local targetpos = targetarea[math.random(#targetarea)]:GetRandomPoint()
				local tr = util.TraceEntity({
					start = targetpos,
					endpos = targetpos
				}, self)
				if not tr.Hit then
					self:SetPos(targetpos)
					self:SetState("JumpDown")
				end
			end
		end
	end
	--JumpDown
	if self:GetState() == "JumpDown" then
		if self:GetFrame() > 28	and self.JumpedDown == false then
			self:SpillBlood()
			self:EmitSound("npc_bloat_tboi/sfx_bloat_stomp.wav",100,100,1)
			self.JumpedDown = true
			timer.Simple(1.5,function()
				if self:IsValid() then
					self.JumpedDown = false
				end
			end)
		end
		if self:GetFrame() > 67 then
			self:SetState("Idle")
		end
	end
end

--this is the runbehaviour for the bloat bossfight
function ENT:RunBehaviour()
	while true do
		if self:GetState() == "Death" then
			if self:GetFrame() >73 then
				self:Remove()
			else
				local explo = ents.Create( "env_explosion" )
				explo:SetPos( self:GetPos() )
				explo:Spawn()
				explo:Fire( "Explode" )
				explo:SetKeyValue( "IMagnitude", 0 )
				coroutine.wait(0.02)	
			end
		else
		if self:GetState() == "Appear" and self:GetFrame() > 19 then
			self:SetState("Idle")
		end
		if self:HaveEnemy() then
			-- Look at enemy
			self:SetAngles(self:ComputeDrawNormal(self:GetEnemy()):Angle())

			--Brim
				--Brimcheck/damage
				if self:GetState() == "AttackBrim" or self:GetState() == "Idle" then
					local tleft,tright,tfwd,tbck = self:CheckBrim(true)
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
									v.Entity:TakeDamageInfo(dmg)
								end
							elseif math.random(3)==1 then
								coroutine.wait(0.5)
								self:SetState("AttackBrim")	
							end
						end
					end
				end
				--Brimstate sound and end
				if self:GetState() == "AttackBrim" then
					if self:GetFrame() > 8 and self.playedBrimSound == false then
						self:EmitSound("npc_bloat_tboi/sfx_bloat_brim.wav",100,100,1)
						self.playedBrimSound = true
					elseif self:GetFrame() > 67 then
						self:SetState("Idle")
						self.playedBrimSound = false
						coroutine.wait(1.5)
					end
				end					

			--Idle (brim takes priority)
			if self:GetState() == "Idle" then
				local idle_transition = math.random(2000)
				if 	idle_transition < 8 then 
					self:HandleJump(self:GetEnemy():GetPos(),1000)
				elseif self:GetEnemy():GetPos():Distance(self:GetPos()) < 1800 then
					if idle_transition < 14 and self:GetEnemy():GetPos():Distance(self:GetPos()) > 300 then
						self:SetState("Walk")
						self.loco:SetDesiredSpeed(100)
						self.loco:SetAcceleration(100)
						self.loco:SetDeceleration(1000)
					elseif idle_transition < 21 then
						self:SetState("AttackSlam")
						self:EmitSound("npc_bloat_tboi/sfx_bloat_sloppy_roar.wav",100,100,1)
					elseif idle_transition < 27 then
						self:SetState("AttackCreep")
						self:EmitSound("npc_bloat_tboi/sfx_bloat_roar.wav",100,100,1)
					end
				end
			end
			
			--Jumpstate
			if self:GetState() == "JumpUp" or self:GetState() == "JumpDown" then
				self:HandleJump(self:GetEnemy():GetPos(),2000)
			end

			--Walk
			if self:GetState() == "Walk" then
				if self:GetFrame() < 25 then self.loco:Approach(self:GetEnemy():GetPos(),1) end
				if self:GetFrame() > 29 then self:SetState("Idle") end
			end

			--AttackSlam
			if self:GetState() == "AttackSlam" then
				if self:GetFrame() > 37 and self.SpilledBlood == false then
					self:SpillBlood()
					self:FireTears()
					self:EmitSound("npc_bloat_tboi/sfx_bloat_stomp.wav",100,100,1)
					self.SpilledBlood = true
					timer.Simple(1.5,function()
						if self:IsValid() then
							self.SpilledBlood = false
						end
					end)
				end
				if self:GetFrame() > 75 then self:SetState("Idle") end
			end
		
			--AttackCreep
			if self:GetState() == "AttackCreep" then
				if self:GetFrame() > 18 and self.SpilledBlood == false then
					self:SpillBlood(1.5)
					self.SpilledBlood = true
					timer.Simple(1.5,function()
						if self:IsValid() then
							self.SpilledBlood = false
						end
					end)
				end
				if self:GetFrame() > 56 then self:SetState("Idle") end
			end
		else
			--Jump to random spot if cannot find an enemy
			if math.random(1000) == 1 or self:GetState() == "JumpUp" or self:GetState() == "JumpDown" then
				self:HandleJump(self:GetPos(),10000)
			end
		end
		end
		coroutine.yield()					
	end				
end

function ENT:OnKilled( dmginfo )
	hook.Call( "OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )
	self:SetState("Death")
	-- just in case
	timer.Simple(3,function()
		if self:IsValid() then
			self:Remove()
		end
	end)
end

end

if CLIENT then

function ENT:Initialize()
	self.bloodpuddles = {}
	net.Receive("UpdatePuddleList",function()
		local ent = net.ReadEntity()
		local bloodpuddles = net.ReadTable(false)
		if ent == self then
			self.bloodpuddles = bloodpuddles
		end
	end)
end

--function for drawing the brimstone sprite
function ENT:ComputeDrawBrimNormal(fwd,brimpos)					
	local normal = LocalPlayer():EyePos() - brimpos
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

-- --DebugDraw
-- hook.Add( "PostDrawTranslucentRenderables", "BloatDebug", function()
-- 	local Playerxy = Vector(LocalPlayer():GetPos().x,LocalPlayer():GetPos().y)	
-- 	for k,v in pairs(ents.GetAll()) do
-- 		if v:GetClass() == "npc_tboi_boss_template" then
-- 			local min,max = v:GetCollisionBounds()
-- 			local tleft,tright,tfwd,tbck = v:CheckBrim(true)
-- 			render.DrawLine(v:BellyPos(), v:BellyPos() + vector_fwd*v:GetBrimRange(),color_red,true)
-- 			render.DrawLine(v:BellyPos(), v:BellyPos() + vector_rgt*v:GetBrimRange(),color_red,true)
-- 			render.DrawLine(v:BellyPos(), v:BellyPos() - vector_rgt*v:GetBrimRange(),color_red,true)
-- 			render.DrawLine(v:BellyPos(), v:BellyPos() - vector_fwd*v:GetBrimRange(),color_red,true)
-- 			render.SetColorMaterial()
-- 			render.DrawBox(tfwd.HitPos,angle_zero,v:OBBMins()*0.65,v:OBBMaxs()*0.65,color_red)
-- 			render.DrawBox(tleft.HitPos,angle_zero,v:OBBMins()*0.65,v:OBBMaxs()*0.65,color_red)
-- 			render.DrawBox(tright.HitPos,angle_zero,v:OBBMins()*0.65,v:OBBMaxs()*0.65,color_red)
-- 			render.DrawBox(tbck.HitPos,angle_zero,v:OBBMins()*0.65,v:OBBMaxs()*0.65,color_red)		
-- 			render.DrawWireframeBox(v:GetPos(), v:GetAngles(),v:OBBMins(),v:OBBMaxs(),color_red)		
-- 			render.DrawWireframeSphere(v:BellyPos(),150,50,50,color_red)
-- 		end
-- 	end
-- end )

function ENT:DrawTranslucent()
	--delete if you dont need bloodpuddles
	for k,v in pairs(self.bloodpuddles) do
		if v:IsValid() then
			if self:GetPos():Distance(v:GetPos()) < 175 then
				v:SetNoDraw(true)
				v:DrawSprite()
			else
				v:SetNoDraw(false)
			end
		end
	end

	-- self:DrawModel()

	--if you dont need brim just keep the else statement
	if self:GetState() == "AttackBrim" and self:GetFrame() >= 8 and self:GetFrame() <= 60 then
		self:SetRenderBounds(self:OBBMins() * 300, self:OBBMaxs() * 300)
		self:DrawBrim(false,false)
		self:DrawBrim(true,false)
		self:DrawSprite()
		self:DrawBrim(true,true)
		self:DrawBrim(false,true)
	else
		--setrenderbounds is only used so that the boss doesnt clip into his blood puddles
		self:SetRenderBounds(self:OBBMins()*2, self:OBBMaxs()*2)
		self:DrawSprite()
	end
end	

function ENT:DrawSprite()
	self:SetRenderAngles(self:ComputeDrawNormal(LocalPlayer()):Angle())
	render.SetMaterial(switch_mat[self:GetState()])
	switch_mat[self:GetState()]:SetInt("$frame",math.floor(self:GetFrame()))
	render.DrawQuadEasy(self:SprPos(),self:ComputeDrawNormal(LocalPlayer()),256,512,color_white,180)
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

	-- if too close to wall dont draw the end
	if relative * relativeImpact > relative * (relativePos + relative * 140) then
		-- draw the end
		brimpos = impact - relative*vector*40
		render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim03/BloatBrim03.vmt"))
		render.DrawQuadEasy(brimpos,self:ComputeDrawBrimNormal(fwd,brimpos),128,64,color_white, angle)

		render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim02/BloatBrim02.vmt"))
		local iterations = 0
		while relative * relativeImpact > relative * (relativePos + relative * (92 + (iterations+1)*128)) do
			if iterations % 2 == 0 then
				render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim02/BloatBrim02.vmt"))
			else
				render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim03/BloatBrim03.vmt"))
			end
			brimpos = self:BellyPos()+ relative * vector*(128*(iterations + 1) + 64)
			render.DrawQuadEasy(brimpos,self:ComputeDrawBrimNormal(fwd,brimpos),128,64,color_white, angle)
			iterations = iterations + 1
		end
	end
	brimpos = self:BellyPos() + relative * vector*64
	render.SetMaterial(Material("npc_bloat_tboi/animations/BloatBrim/BloatBrim01/BloatBrim01.vmt"))
	render.DrawQuadEasy(brimpos,self:ComputeDrawBrimNormal(fwd,brimpos),128,64,color_white, angle)
	
	
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

language.Add("npc_tboi_boss_template", "Boss Template")
killicon.Add("npc_tboi_boss_template","vgui/hud/killicons/bosstemplatekillicon",Color( 255, 255, 255,255))

end

list.Set( "NPC", "npc_tboi_boss_template", {
	Name = "Boss Template",
	Class = "npc_tboi_boss_template",
	Category = "TBOI"
})