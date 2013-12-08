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
	arms = {x=40, y=160, width=40, height=80},
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

-- total up hero's base stats and equipment stats to produce current total stats
local function recalculate_hero_stats(hero)
	local attack = hero.attack
	local defense = hero.defense
	for k,v in pairs(hero.equipment) do
		if v.attack then
			attack = attack + v.attack
		end
		if v.defense then
			defense = defense + v.defense
		end
	end
	hero.curr_attack = attack
	hero.curr_defense = defense
end

-- passed a given piece of loot, put it on the hero, possibly ditching previous gear
local function put_gear_on_hero(hero, loot)
	if not loot then
		-- hrm! the nerve!
		return nil
	end
	if loot.slot == "hand" then
		-- special case, we have both a left hand and a right hand
		-- though this is silly hacky bullshit, really we should be told which hand we're
		-- equipping on the way into this function, TODO that
		if not hero.equipment["lefthand"] then
			hero.equipment["lefthand"] = loot
		else
			hero.equipment["righthand"] = loot
		end
	else
		hero.equipment[loot.slot] = loot
	end

	loot:orient_for_homunculus()
	hero:recalculate_hero_stats()
end

-- load up some image data
function init_images()
	local stand = love.graphics.newImage("art/crawl/hero_standing.png")
	local walk = love.graphics.newImage("art/crawl/hero_walking.png")
	local attack = love.graphics.newImage("art/crawl/hero_attacking.png")

	local anims = { 
		stand = { stand }, 
		walk = { walk, stand }, 
		attack = { attack, stand } 
	}

	return anims
end

-- update animation frame for hero if enough time has passed
local function animate(hero, dt)
	local delay = 0.1
	hero.anim_timer = hero.anim_timer + dt
	if hero.anim_timer > delay then
		-- we've been on this frame long enough, let's move to the next one
		local frames = hero.images[hero.anim_state]
		local max_frame = table.getn(frames)
		hero.anim_frame = hero.anim_frame + 1
		if hero.anim_frame > max_frame then
			-- loop back to the original frame if we were on the last one already
			hero.anim_frame = 1
		end
		hero.anim_timer = hero.anim_timer - delay
	end
end

-- move to walking animation
local function switch_anim(hero, anim)
	hero.anim_timer = 0
	hero.anim_state = anim
	hero.anim_frame = 1
end

-- construct the hero
function new()
	local o = {}

	o.name, o.class, o.attack, o.defense, o.max_hp = get_random_hero()
	o.hp = o.max_hp
	o.curr_attack = o.attack
	o.curr_defense = o.defense

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

	o.images = init_images() -- hash of sprite collections for displaying hero avatar
	o.anim_state = "stand"	
	o.anim_timer = 0
	o.anim_frame = 1

	-- methods
	o.put_gear_on_hero = put_gear_on_hero
	o.recalculate_hero_stats = recalculate_hero_stats
	o.animate = animate
	o.switch_anim = switch_anim

	return o
end
