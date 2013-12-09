module(..., package.seeall);

-- the monster class for dungeon encounters

require "Loot"

local artpath = "art/crawl/"


-- some monster definitions
local monsters = {
	{ name = "orc", attack = 3, defense = 1, max_hp = 6, 
			loot = {"war axe", "platemail", "wildling helmet"}  
	},
	{ name = "goblin", attack = 1, defense = 2, max_hp = 4,
			loot = {"broadsword", "buckler", "plate gauntlet"} 
	},
}

-- repository of images for monsters
local monster_sprites = {}

-- set up art assets for all monsters
function init_monster_sprites()
	for i,v in ipairs(monsters) do

		local img_stand = love.graphics.newImage(artpath .. v.name .. "_standing.png")
		local img_walk = love.graphics.newImage(artpath .. v.name .. "_walking.png")
		local img_attack = love.graphics.newImage(artpath .. v.name .. "_attacking.png")

		local s = Sprite.new()
		s:add_anim("stand", { img_stand })
		s:add_anim("walk", {img_walk, img_stand })
		s:add_anim("attack", {img_attack, img_stand })

		s:switch_anim("stand")

		monster_sprites[v.name] = s

	end
end

-- return a random monster
local function get_random_monster()
	local m = monsters[math.random(table.getn(monsters))]
	return m.name, m.attack, m.defense, m.max_hp, m.loot, monster_sprites[m.name]
end

-- return a piece of loot from this monster's collection
local function get_loot(monster)
	return monster.loot[math.random(table.getn(monster.loot))]
end

-- create a new monster
function new()
	local o = {}

	o.name, o.attack, o.defense, o.max_hp, o.loot, o.sprite = get_random_monster()
	o.hp = o.max_hp	

	-- method
	o.get_loot = get_loot

	return o
end
