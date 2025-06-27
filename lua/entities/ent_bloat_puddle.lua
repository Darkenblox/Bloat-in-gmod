AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Spawnable = false
ENT.Category = "TBOI"
ENT.PrintName = "Bloat Puddle"
ENT.ClassName = "ent_bloat_puddle"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

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
color_black = Color(0,0,0,10)

function ENT:SetupDataTables()
    self:NetworkVar("Int",0,"PuddleIndex")
    self:SetPuddleIndex(1)
    self:NetworkVar("Bool",0,"ToDissolve")
end

if SERVER then

function ENT:Initialize()
    self:SetToDissolve(false)
    local puddlesize = math.floor((self:GetPuddleIndex()-1) / 6)
    if puddlesize == 0 then
        puddlesize = 64
    elseif puddlesize == 1 then
        puddlesize = 128
    else
        puddlesize = 256
    end
    self:SetCollisionBounds(Vector(-puddlesize/2,-puddlesize/2,0),Vector(puddlesize/2,puddlesize/2,2))
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetSolid(SOLID_BBOX)
    self:SetAngles(angle_zero)
    self.trigger = ents.Create("trigger_bloat_puddle")
    self.trigger.puddle = self
    -- trigger spawned when bloat does it
    self:DrawShadow(false)
    self:CallOnRemove("DeleteTrigger",function()
        if self.trigger:IsValid() then
            self.trigger:Remove()
        end
    end)

    timer.Simple(6,function() 
        if self:IsValid() then
            self:SetToDissolve(true)
            if self.trigger:IsValid() then
                self.trigger:Remove()
            end
        end
        timer.Simple(3 ,function() 
            if self:IsValid() then
                self:Remove() 
            end
        end)
    end)
end

-- hook.Add("PlayerButtonDown","Indexchange",function(ply,button)
--     for k,v in pairs(ents.GetAll()) do
--         if v:GetClass() == "ent_bloat_puddle" then
--             if button == KEY_DOWN then
--                 v:SetPuddleIndex(v:GetPuddleIndex() - 1)
--             elseif button == KEY_UP then
--                 v:SetPuddleIndex(v:GetPuddleIndex() + 1)
--             end
--         end
--     end
-- end)

function ENT:Think()
    if self.trigger:IsValid() then
        self.trigger:SetPos(self:GetPos())
    end
    -- local puddlesize = math.floor(self:GetPuddleIndex()/ 6)
    -- if puddlesize == 0 then
    --     puddlesize = 64
    -- elseif puddlesize == 1 then
    --     puddlesize = 128
    -- else
    --     puddlesize = 256
    -- end
    -- self:SetCollisionBounds(Vector(-puddlesize/2,-puddlesize/2,0),Vector(puddlesize/2,puddlesize/2,2))
    -- if self.trigger:IsValid() then
    --     self.trigger:SetCollisionBounds(Vector(-puddlesize/2,-puddlesize/2,0),Vector(puddlesize/2,puddlesize/2,2))
    -- end
    local filteredents = {self,self.trigger}
    for k,v in pairs(ents.GetAll()) do
        if v:IsNPC() or v:IsNextBot() or v:IsPlayer() then
            table.insert(filteredents,v)
        end
    end

    local tr = util.TraceHull({
        start = self:GetPos(),
        endpos = self:GetPos() - vector_up * 256,
        mins = self:OBBMins(),
        maxs = self:OBBMaxs(),
        collisiongroup = COLLISION_GROUP_DEBRIS,
        filter = filteredents
    },self)

    local groundOffset = self:GetToDissolve() and 0.05 or 0.2
    self:SetPos(tr.HitPos + vector_up * groundOffset)
end 

end

if CLIENT then

function ENT:Initialize()
    self.spritesize = self:OBBMaxs().x * 2
    self.color = color_white
    self.alpha = 1
end

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

function ENT:DrawTranslucent()
    self:DrawSprite()
end

function ENT:DrawSprite()
    self:SetRenderBounds(self:OBBMins(), self:OBBMaxs())
    if self:GetToDissolve() then
        self.spritesize = Lerp(0.01, self.spritesize, 0)
        self.color = self.color:Lerp(color_black,0.005)
        self.alpha = Lerp(0.005,self.alpha,0.1)
    else
        self.spritesize = self:OBBMaxs().x * 2
    end
    local puddlesize = self.spritesize
    local color = self.color
    local alpha = self.alpha
    local mat = puddles[self:GetPuddleIndex()]
    mat:SetVector("$color",color:ToVector())
    mat:SetFloat("$alpha",alpha)
    render.SetMaterial(mat)
    render.DrawQuadEasy(self:GetPos(),vector_up,puddlesize,puddlesize,color_white,0)	
end

end