AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Category = "TBOI"
ENT.Spawnable = true
ENT.PrintName = "Bloat Eye"
ENT.ClassName = "ent_bloat_eye"

ENT.BloatParent = nil 
ENT.Material = Material("npc_bloat_tboi/animations/BloatEye/BloatEye.vmt")
ENT.spritesize = 70
ENT.Bounce = true
ENT.Speed = 500
 
local color_white = Color(255,255,255)

if SERVER then

function ENT:Initialize()
    self:SetModel("models/xqm/rails/gumball_1.mdl")   
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)                 
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:GetPhysicsObject():EnableGravity(false)
    self:GetPhysicsObject():Wake()  
    if self.move_vect == nil then
        -- self.move_vect = vector_origin
        self.move_vect = Vector(1,1,0):GetNormalized() * self.Speed
    end
end

function ENT:Think()
    self:GetPhysicsObject():SetVelocity(self.move_vect)
    local move_angle = self.move_vect:Angle()
    move_angle.p = 0
    self.move_vect = move_angle:Forward() * self.Speed
end

function ENT:PhysicsCollide(colData,collider)
    local hit_ent = colData.HitEntity
    if hit_ent:GetClass() != "npc_bloat_tboi" and hit_ent:GetClass() != "ent_bloat_tear" and hit_ent != "ent_bloat_eye" then  
        hit_ent:TakeDamage(90, self, self)
        if self.Bounce == false then
            self:Remove()
            self:EmitSound("npc_bloat_tboi/sfx_bloat_tear_block.wav",100,100,1)
        else
            self.move_vect = self.move_vect - 2 * (self.move_vect:Dot(colData.HitNormal)) * colData.HitNormal
        end
    end
end 

end

if CLIENT then
function ENT:ComputeDrawNormal()
    local pos = self:GetPos()
    local normal = LocalPlayer():EyePos() - pos
    normal:Normalize()   
    return normal
end

function ENT:Draw()
    local mins,maxs = self:GetCollisionBounds()
    -- self:DrawModel()
    render.SetMaterial(self.Material)
    render.DrawQuadEasy(self:GetPos(),self:ComputeDrawNormal(),self.spritesize,self.spritesize,color_white,180)
    -- render.DrawWireframeBox(self:GetPos(),angle_zero,mins,maxs,color_white,false)
end

function ENT:ImpactTrace()
    return true
end

language.Add(ENT.ClassName,"LITTLE FUCKER")
killicon.Add(ENT.ClassName,"vgui/hud/killicons/bloatkillicon",Color( 255, 255, 255,255))

end

