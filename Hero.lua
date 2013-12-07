module(..., package.seeall);

-- the bold, fearless, doomed hero you're assisting in their dungeon crawl

local classlist = {"fighter", "wizard", "rogue"}

local class = {
	fighter = {defense = 3, max_hp = 5},
	wizard = {attack = 4, defense = 0, max_hp = -2},
	rogue = {attack = 1, defense = 1},
}

local names = {
	fighter = {"Beefcake", "Lump", "Pounder", "Bluto", "Croc", "Conan", "Ares"},
	wizard = {"Xerxes", "Zardoz", "Cyrodill", "Merlin", "Gob", "Elbereth", "Gandalf"},
	rogue = {"Mal", "Gareth", "Snitch", "Worm", "Knifey", "Wiley", "Tiptoes"},
}

-- definitions for the gear homunculus slots: name = {xoffset, yoffset, width, height}
local hom_loot_defs = {
	head = {x=80, y=20, width=120, height=80},
	body = {x=100, y=120, width=80, height=160},
	hands = {x=40, y=160, width=40, height=80},
	feet = {x=100, y=300, width=80, height=80},
	item = {x=200, y=260, width=40, height=40},
	lefthand = {x=260, y=60, width=80, height=120},
	righthand = {x=260, y=200, width=80, height=120},
}

-- set up the homunculus graphics and spatial defs
function init_homunculus()
	local himage = love.graphics.newImage("art/homunculus/homunculus.png")
	local hloot = {}
	for k,v in pairs(hom_loot_defs) do
		hloot[k] = {}
		hloot[k].x = v.x
		hloot[k].y = v.y
		hloot[k].width = v.width
		hloot[k].height = v.height
	end

	return himage, hloot
end


-- generate a random hero
function get_random_hero()
	local attack = 1
	local defense = 0
	local max_hp = 10
	
	local cl = classlist[math.random(table.getn(classlist))]
	local attack_bonus, defense_bonus, max_hp_bonus = class[cl].attack, class[cl].defense, class[cl].max_hp
	if attack_bonus then attack = attack + attack_bonus end
	if defense_bonus then defense = defense + defense_bonus end
	if max_hp_bonus then max_hp = max_hp + max_hp_bonus end

	local name = names[cl][math.random(table.getn(names[cl]))]

	return name, cl, attack, defense, max_hp  

end

-- construct the hero
function new()
	local o = {}

	o.name, o.class, o.attack, o.defense, o.max_hp = get_random_hero()
	o.hp = o.max_hp

	o.equipment = {
		head = nil,
		body = nil,
		feet = nil,
		arms = nil,
		lefthand = nil,
		righthand = nil,
		item = nil, 
	} -- a hash of loot: head, body, hand, foot armor and a couple weapon slots

	-- the background image and spatial definitions for the gear homunculus
	o.hom = {}
	o.hom.image = {}
	o.hom.loot = {}
	o.hom.image, o.hom.loot = init_homunculus()

	o.images = {} -- hash of sprite collections for displaying hero avatar
	
	return o
end
