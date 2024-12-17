AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Spawnable = true
ENT.Category = "TBOI"
ENT.PrintName = "Bloat Puddle"
ENT.ClassName = "ent_bloat_puddle"

function ENT:Initialize()
    self.SetModel("models/hunter/blocks/cube4x4x025.mdl")
end

function ENT:Draw()