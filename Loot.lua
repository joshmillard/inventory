module(..., package.seeall);

-- the loot object

TSIZE = 40

local path = "art/loot/"
local id_counter = 1

-- define some basic loot
local loots = {

{name = "sword", slot = "hand", category = "weapon", kind="sword", subkind="broadsword", w = 1, h = 3, file = "sword", layout = { {true}, {true}, {true} } },

{name = "buckler", slot = "hand", category = "armor", kind="shield", subkind="buckler", w = 2, h = 2, file = "buckler", layout = { {true, true}, {true, true} } },

{name = "mace", slot = "hand", category = "weapon", kind="club", subkind="mace", w = 2, h = 3, file = "mace", layout = { {true, false}, {true, true}, {false, true} } },

{name = "axe", slot = "hand", category = "weapon", kind="axe", subkind="war axe", w = 2, h = 3, file = "axe", layout = { {true, true}, {true, true}, {true, false} } },

{name = "armor", slot = "body", category = "armor", kind="body_armor", subkind="platemail", w = 2, h = 4, file = "armor", layout = { {true, true}, {true, true}, {true, true}, {true, true} } },

{name = "bow", slot = "hand", category = "weapon", kind="bow", subkind="wood bow", w = 2, h = 4, file = "bow", layout = { {true, false}, {true, true}, {true, true}, {true, false} } },

{name = "gauntlet", slot = "arms", category = "armor", kind="gauntlet", subkind="plate gauntlet", w = 2, h = 1, file = "gauntlet", layout = { {true, true} } },

{name = "helmet", slot = "head", category = "armor", kind="helmet", subkind="wildling helmet", w = 3, h = 2, file = "helmet", layout = { {true, false, true}, {true, true, true} } },

{name = "staff", slot = "hand", category = "weapon", kind="staff", subkind="gem staff", w = 1, h = 4, file = "staff", layout = { {true}, {true}, {true}, {true} } },

}

-- provide base statistics for various kinds of loot
local base_stats = {
	sword = {attack = 3},
	club = {attack = 4},
	axe = {attack = 5},
	bow = {attack = 6},
	staff = {attack = 4},
	
	shield = {defense = 4},
	body_armor = {defense = 8},
	gauntlet = {defense = 1, attack = 1},
	helmet = {defense = 5}, 
}

local prefixes = {
	common = {"dull", "rusty", "questionable", "underwhelming", "crude", "dodgy"},
	fancy = {"solid", "respectable", "decent", "whelming", "not half bad", "workmanlike", "hunky dorey"},
	rare = {"stunning", "quite good", "jaw-dropping", "overwhelming", "amazeballs", "shit hot"},
}

local suffixes = {
	common = {"crap", "junk", "bullshit", "crumbliness", "meh", "blarg", "buyer's remorse"},
	fancy = {"solidity", "respectability", "acceptability", "non-shittiness", "okayness"},
	rare = {"OMG", "daaaaang", "hey gurl", "sweetness", "radness", "badassitude"},
}

local buffs = {
	{attack = 2, prefix = "plinking", suffix = "plinks"},
	{attack = 4, prefix = "walloping", suffix = "wallopedness"}, 
	{attack = 5, prefix = "violent", suffix = "violence"},
	{attack = 7, prefix = "terrifying", suffix = "terror"},

	{defense = 1, prefix = "slippery", suffix = "sunblock"},
	{defense = 3, prefix = "hardened", suffix = "hardness"},
	{defense = 5, prefix = "rugged", suffix = "turtling"},
	{defense = 8, prefix = "impenetrable", suffix = "diamond"},

	{attack = -1, defense = -1, prefix = "cursed", suffix = "bummerness"},
	{attack = 1, defense = 1, prefix = "blessed", suffix = "sanctification"},
} 


-- return a randomly selected buff for some loot
local function get_random_buff()
	local b = buffs[math.random(table.getn(buffs))]
	local pre, suf
	if math.random() > 0.5 then
		pre = b.prefix
	else
		suf = b.suffix
	end	

	return b.attack or 0, b.defense or 0, pre, suff 
end


local function get_random_loot_by_subkind(rank, subkind)

	local l = nil
	local found = false
	for k,v in pairs(loots) do
		if v.subkind == subkind then
			l = v
			found = true
			break
		end
	end
	if not found then
		-- fishing for a non-existent subkind, this is real bad!
		print "no such subtype found!"
		return nil
	end

	-- generate the image data from file
	local img = love.graphics.newImage(path .. l.file .. ".png")

	-- generate a name
	local prefix, suffix
	pretable = nil
	suftable = nil
	if rank == 1 then
		pretable = prefixes.common
		suftable = suffixes.common
	elseif rank == 2 then
		pretable = prefixes.fancy
		suftable = suffixes.fancy
	elseif rank == 3 then
		pretable = prefixes.rare
		suftable = suffixes.rare
	else
		print("WTF IS THIS RANK: " .. rank)
		return nil
	end

	if math.random() > 0.5 then
		prefix = pretable[math.random(table.getn(pretable))]
--		name = prefix .. " " .. name 
	end
	if math.random() > 0.5 then
		suffix = suftable[math.random(table.getn(suftable))]
--		name = name .. " of " .. suffix
	end
 
	-- get base statistics from kind
	local attack = base_stats[l.kind].attack or 0
	local defense = base_stats[l.kind].defense or 0

	-- add buffs for higher-rank loot
	local prefix_buff, suffix_buff
	for i=1, rank - 1 do
		local attack_buff, defense_buff, pb, sb = get_random_buff()
		attack = attack + attack_buff
		defense = defense + defense_buff

		if prefix_buff and pb then
			prefix_buff = prefix_buff .. ", " .. pb
		elseif pb then
			prefix_buff = pb
		end
		if suffix_buff and sb then
			suffix_buff = suffix_buff .. " and " .. sb
		elseif sb then
			suffix_buff = sb
		end

	end

	-- finalize name string
	local namestr = ""

	if prefix_buff then namestr = namestr .. prefix_buff end

	if prefix then 
		if prefix_buff then 
			namestr = namestr .. ", " .. prefix
		else 
			namestr = namestr .. prefix
		end
	end

	if namestr ~= "" then namestr = namestr .. " " end

	namestr = namestr .. l.name

	if suffix_buff then
		namestr = namestr .. " of " .. suffix_buff
	elseif suffix then
		namestr = namestr .. " of " .. suffix
	end
	
	return namestr, l.slot, l.category, l.kind, l.subkind, attack, defense, l.w, l.h, img, l.layout
end

-- generate a sample bit of loop
local function get_random_loot(rank)
	local l = loots[math.random(table.getn(loots))]
	return get_random_loot_by_subkind(rank, l.subkind)
end

-- return the layout of this piece
local function layout(loot)
	return loot.tile_layout
end

local function h(loot)
	return loot.height
end

local function w(loot)
	return loot.width
end

local function tx(loot)
	return loot.tilex
end

local function ty(loot)
	return loot.tiley
end

local function set_position(loot, x, y)
	loot.tilex = x
	loot.tiley = y
end

local function image(loot)
	return loot.loot_image
end

local function angle(loot)
	return loot.rotation
end

-- rotate the layout 90 degrees
local function rotate_clockwise(loot)
	local newlayout = {}
	for x = 1, loot.width do
		newlayout[x] = {}
		for y=loot.height, 1, -1 do
			table.insert(newlayout[x], loot.tile_layout[y][x])
		end
	end
	loot.tile_layout = newlayout
	loot.width, loot.height = loot.height, loot.width

	loot.rotation = loot.rotation + 90
	if loot.rotation == 360 then
		loot.rotation = 0
	end

end

local function orient_for_homunculus(loot)
	while loot.rotation ~= 0 do
		rotate_clockwise(loot)
	end
	-- compensating for current guantlet example being oriented wrong for gear display
	if loot.slot == "arms" then
		rotate_clockwise(loot)
	end
end

local function image_offset(loot)
	local xoff = 0 
	local yoff = 0
	if loot.rotation == 90 then
		yoff = loot.width		
	elseif loot.rotation == 180 then
		xoff = loot.width
		yoff = loot.height
	elseif loot.rotation == 270 then
		xoff = loot.height
	end
	return {x = xoff * TSIZE, y = yoff * TSIZE}
end

-- return the global id counter value and increment it, so no two loots have the same id
local function get_unique_loot_id()
	id_counter = id_counter + 1
	return id_counter
end

-- generate a new piece of loot
function new(r, subkind)

	local o = {}
	o.id = get_unique_loot_id()

	o.rank = 1
	if not r then
		r = 1
	end
	if r >= 3 then
		o.rank = 3
	elseif r >= 2 then
		o.rank = 2
	end

	if subkind then
		o.name, o.slot, o.category, o.kind, o.subkind, o.attack, o.defense, o.width, o.height, o.loot_image, o.tile_layout = get_random_loot_by_subkind(o.rank, subkind)
	else
		o.name, o.slot, o.category, o.kind, o.subkind, o.attack, o.defense, o.width, o.height, o.loot_image, o.tile_layout = get_random_loot(o.rank)
	end

	o.rotation = 0	
	o.tilex = 1 -- x and y coordinates of origin in board space
	o.tiley = 1

	o.h = h
	o.w = w
	o.layout = layout
	o.rotate_clockwise = rotate_clockwise

	-- methods
	o.tx = tx
	o.ty = ty
	o.set_position = set_position
	o.image = image
	o.angle = angle
	o.image_offset = image_offset
	o.orient_for_homunculus = orient_for_homunculus

	return o
end

