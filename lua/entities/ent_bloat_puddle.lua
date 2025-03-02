AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Spawnable = true
ENT.Category = "TBOI"
ENT.PrintName = "Bloat Puddle"
ENT.ClassName = "ent_bloat_puddle"

-- local puddles = {
--     ["Blood01"] = Material("npc_bloat_tboi/animations/BloatPuddle/Blood01/Blood01.vmt"),
--     ["Blood02"] = Material("npc_bloat_tboi/animations/BloatPuddle/Blood02/Blood02.vmt"),
--     ["Blood03"] = Material("npc_bloat_tboi/animations/BloatPuddle/Blood03/Blood03.vmt"),
--     ["Blood04"] = Material("npc_bloat_tboi/animations/BloatPuddle/Blood04/Blood04.vmt"),
--     ["Blood05"] = Material("npc_bloat_tboi/animations/BloatPuddle/Blood05/Blood05.vmt"),
--     ["Blood06"] = Material("npc_bloat_tboi/animations/BloatPuddle/Blood06/Blood06.vmt"),
-- }
local puddles = {
    Material("npc_bloat_tboi/animations/BloatPuddle/Blood01/Blood01.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/Blood02/Blood02.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/Blood03/Blood03.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/Blood04/Blood04.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/Blood05/Blood05.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/Blood06/Blood06.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BigBlood01/BigBlood01.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BigBlood02/BigBlood02.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BigBlood03/BigBlood03.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BigBlood04/BigBlood04.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BigBlood05/BigBlood05.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BigBlood06/BigBlood06.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BiggestBlood01/BiggestBlood01.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BiggestBlood02/BiggestBlood02.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BiggestBlood03/BiggestBlood03.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BiggestBlood04/BiggestBlood04.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BiggestBlood05/BiggestBlood05.vmt"),
    Material("npc_bloat_tboi/animations/BloatPuddle/BiggestBlood06/BiggestBlood06.vmt"),
}

vector_up = Vector(0,0,1)

color_white = Color(255,255,255)

function ENT:SetupDataTables()
    self:NetworkVar("Int",0,"MatIndex")
end

if SERVER then

function ENT:Initialize()
    -- self:SetModel("models/hunter/blocks/cube1x1x025.mdl")
    local puddlesize = math.floor(self:GetMatIndex() / 6)
    if puddlesize == 0 then
        puddlesize = 64
    elseif puddlesize == 1 then
        puddlesize = 128
    else
        puddlesize = 256
    end
    self:SetCollisionBounds(Vector(-puddlesize/2,-puddlesize/2,0),Vector(puddlesize/2,puddlesize/2,2))
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:SetSolid(SOLID_BBOX)
    self:SetAngles(angle_zero)
    self.parentBloat = nil
    self.trigger = ents.Create("trigger_bloat_puddle")
    self.trigger.puddle = self
    self.trigger:Spawn()
    self:SetMatIndex(1)
end

-- to delete (debug)
hook.Add("PlayerButtonDown","Indexchange",function(ply,button)
    for k,v in pairs(ents.GetAll()) do
        if v:GetClass() == "ent_bloat_puddle" then
            if button == KEY_DOWN then
                v:SetMatIndex(v:GetMatIndex() - 1)
            elseif button == KEY_UP then
                v:SetMatIndex(v:GetMatIndex() + 1)
            end
        end
    end
end)

function ENT:Think()

    self.trigger:SetPos(self:GetPos())

    local puddlesize = math.floor(self:GetMatIndex()/ 6)
    if puddlesize == 0 then
        puddlesize = 64
    elseif puddlesize == 1 then
        puddlesize = 128
    else
        puddlesize = 256
    end
    self:SetCollisionBounds(Vector(-puddlesize/2,-puddlesize/2,0),Vector(puddlesize/2,puddlesize/2,2))
    self.trigger:SetCollisionBounds(Vector(-puddlesize/2,-puddlesize/2,0),Vector(puddlesize/2,puddlesize/2,2))

    -- local colTbl = ents.FindInBox(self:OBBMins(),self:OBBMaxs())

    -- for k,v in pairs(colTbl) do
    --     if v:IsPlayer() or v:IsNPC() or v:IsNextBot() then
    --         v.inBloatBlood = true
    --         v.puddleEnt = self
    --         if self.touchedEnts[v:GetName()] == nil then
    --             self.touchedEnts[v:GetName()] = v
    --         end
    --     end
    -- end

    -- for k,v in pairs(ents.GetAll()) do
    --     if self.touchedEnts[v:GetName()] != nil and !table.HasValue(colTbl,v) then
    --         self.touchedEnts[v:GetName()] = nil 
    --         v.inBloatBlood = false
    --         v.puddleEnt = nil
    --     end
    -- end
end

-- function ENT:Touch(entity)
--     entity.inBloatBlood = true
--     entity.puddleEnt = self
-- end

-- function ENT:EndTouch(entity)
--     entity.inBloatBlood = false
--     entity.puddleEnt = nil
-- end

end

if CLIENT then

function ENT:ImpactTrace(traceTbl, DMGresult)
    if bit.band(DMGresult,DMG_BULLET) == DMG_BULLET then
        local effectdata = EffectData()
        effectdata:SetOrigin(traceTbl.HitPos)
        effectdata:SetFlags(3)
        effectdata:SetColor(0)
        effectdata:SetScale(3)
        util.Effect("bloodspray",effectdata)
        return true
    end
end

function ENT:Draw()
    local puddlesize = self:OBBMaxs().x * 2
    render.SetMaterial(puddles[self:GetMatIndex()])
    render.DrawQuadEasy(self:GetPos(),vector_up,puddlesize,puddlesize,color_white,0)	
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(),self:OBBMins(),self:OBBMaxs(),color_white)
end

end