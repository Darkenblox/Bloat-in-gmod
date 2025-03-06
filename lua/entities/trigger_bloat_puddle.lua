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
    self.touchedEnts = {}
    self:CallOnRemove("RemoveInBloodStatus", function() 
        for k,v in pairs(self.touchedEnts) do
            v.inBloatBlood = false
            v.puddleEnt = nil
        end
    end)
end

function ENT:Touch(entity)
    entity.inBloatBlood = true
    entity.puddleEnt = self.puddle
    if not self.touchedEnts[entity:GetName()] then
        self.touchedEnts[entity:GetName()] = entity
    end
end

function ENT:EndTouch(entity)
    entity.inBloatBlood = false
    entity.puddleEnt = nil
    self.touchedEnts[entity:GetName()] = nil
end

end