AddCSLuaFile()

ENT.Base = "ent_bloat_eye"
ENT.Type = "anim"
ENT.Category = "TBOI"
ENT.Spawnable = true
ENT.PrintName = "Bloat Tear"
ENT.ClassName = "ent_bloat_tear"

ENT.Material = Material("npc_bloat_tboi/animations/BloatTear/BloatTear.vmt")
ENT.spritesize = 30
ENT.Bounce = false
ENT.Speed = 1100

if CLIENT then

language.Add("ent_bloat_tear","LITTLE FUCKER")
killicon.Add("ent_bloat_tear","vgui/hud/killicons/bloatkillicon",Color( 255, 255, 255,255))

end