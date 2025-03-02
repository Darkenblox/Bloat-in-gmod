AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "brush"
ENT.Spawnable = false 
ENT.Category = "TBOI"
ENT.PrintName = "Bloat Puddle Trigger"
ENT.ClassName = "trigger_bloat_puddle"

if SERVER then

function ENT:Initialize()
    self:SetCollisionBounds(self.puddle:OBBMins(),self.puddle:OBBMaxs())
    self:SetTrigger(true)
    self:SetSolid(SOLID_BBOX)
    self:SetAngles(angle_zero)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:Touch(entity)
    entity.inBloatBlood = true
    entity.puddleEnt = self
end

function ENT:EndTouch(entity)
    entity.inBloatBlood = false
    entity.puddleEnt = nil
end

end