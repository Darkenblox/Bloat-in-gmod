AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Spawnable = true
ENT.Category = "TBOI"
ENT.PrintName = "Bloat Tear"
ENT.ClassName = "ent_bloat_tear"

ENT.Bloat = nil 
 
local color_white = Color(255,255,255)

function ENT:Initialize()
    self:SetModel("models/xqm/rails/gumball_1.mdl")   
    print(self.BloatParent)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)                 
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:GetPhysicsObject():EnableGravity(false)
    self:GetPhysicsObject():Wake()  
end

if SERVER then
function ENT:Think()
    self:GetPhysicsObject():SetVelocity(self.move_vect)
end

function ENT:PhysicsCollide(colData,collider)
    local hit_ent = colData.HitEntity
    if hit_ent:GetClass() != "npc_bloat_tboi" and hit_ent:GetClass() != "ent_bloat_tear" then  
        hit_ent:TakeDamage(90, self.BloatParent, self.BloatParent)
        self:Remove()
    end
end 
end

if CLIENT then
function ENT:ComputeDrawNormal()
    local pos = self:GetPos()
    local normal = LocalPlayer():GetPos() - pos
    local xyNormal = normal - vector_up*normal
    xyNormal:Normalize()    
    return xyNormal
end

function ENT:Draw()
    local mins,maxs = self:GetCollisionBounds()
    -- self:DrawModel()
    render.SetMaterial(Material("npc_bloat_tboi/animations/BloatTear/BloatTear.vmt"))
    render.DrawQuadEasy(self:GetPos(),self:ComputeDrawNormal(),30,30,color_white,180)
    -- render.DrawWireframeBox(self:GetPos(),angle_zero,mins,maxs,color_white,false)
end

function ENT:ImpactTrace()
    return true
end

language.Add("ent_bloat_tear","Bloat")

end

list.Set( "NPC", "ent_bloat_tear", {
	Name = "BloatTear",
	Class = "ent_bloat_tear",
	Category = "TBOI"
})  