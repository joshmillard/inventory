module(..., package.seeall);

-- the dungeon, through which our hero crawls

--[[
- background art, and an array of background art tiles to scroll through
- an array of baddies and other encounters
- various dungeon data and shit and who knows just what, let's go crazy
--]]

require "Encounter"

DLENGTH = 6 -- how much of the dungeon backdrop to keep around
ELENGTH = 6 -- number of encounters to keep stocked

-- load image assets for backdrop
local function load_backdrop_images()
	local b_default = love.graphics.newImage("art/crawl/backdrop_1.png")
	local b_variant1 = love.graphics.newImage("art/crawl/backdrop_2.png")
	local b_variant2 = love.graphics.newImage("art/crawl/backdrop_3.png")
	local b_variant3 = love.graphics.newImage("art/crawl/backdrop_4.png")
	
	return {b_default, b_variant1, b_variant2, b_variant3}
end
	
-- load backdrop fade image
local function load_backdrop_fademask()
	return love.graphics.newImage("art/crawl/backdrop_fademask.png")
end

-- stock some tiles into our backdrop list for rendering
local function init_backdrop_tiles(d)
	for i=1, DLENGTH do
		d:add_backdrop_tile()
	end
end

-- add another tile to the list
local function add_backdrop_tile(d)
	if math.random() > 0.2 then
		-- mostly just plain dungeon tiles
		table.insert(d.tile_list, d.backdrop_images[1])
	else
		table.insert(d.tile_list, d.backdrop_images[math.random(3) + 1])
	end
end

-- remove the first tile from the list
local function discard_backdrop_tile(d)
	table.remove(d.tile_list, 1)
end

-- advance the dungeon by x pixels
local function advance_backdrop(d, x)
	d.tile_pos = d.tile_pos + x
	if d.tile_pos > d.tile_width then
		-- scrolled past a tile completely
		d.tile_pos = d.tile_pos - d.tile_width
		d:discard_backdrop_tile()
		d:add_backdrop_tile()
	end

	d:advance_encounters(x)
end

-- set up some initial encounters
local function init_encounters(d)
	for i=1, ELENGTH do
		d:add_encounter(100 + 160*i)
	end
end

-- add another encounter to the list
local function add_encounter(d, xpos)
	table.insert(d.encounters, Encounter.new(xpos))
end

-- remove first encounter from list
local function discard_encounter(d)
	table.remove(d.encounters, 1)
end

-- turn our attention to the next encounter in the list
local function dismiss_current_encounter(d)
	d.encounter_index = d.encounter_index + 1
	if not d.encounters[d.encounter_index] then
		-- uh oh, there's no actual encounter here, fwiw!
		print("no actual encounter at index " .. d.encounter_index)
	end
end

-- advance the encounters
local function advance_encounters(d, x)
	local killed = false
	for i,v in ipairs(d.encounters) do
		v.xpos = v.xpos - x
		if v.xpos < -50 then
			-- ditch after it gets too close, this is just a hack for now
			d:discard_encounter()
			d.encounter_index = d.encounter_index - 1
			print("Discarding an encounter...")
			killed = true
		end
	end
	if killed then
		d:add_encounter(800)
	end
end

-- get position of nearest encounter for calculating when the hero should stop walking
--  and have an encounter
local function get_next_encounter(dungeon)
	if table.getn(dungeon.encounters) == 0 then
		print("No encounters spawned, buh!")
		return nil
	end
	return dungeon.encounters[dungeon.encounter_index]
end


-- instantiate a dungeon!
function new()
	local o = {}

	-- methods
	o.advance_backdrop = advance_backdrop
	o.add_backdrop_tile = add_backdrop_tile
	o.discard_backdrop_tile = discard_backdrop_tile
	o.advance_encounters = advance_encounters 
	o.add_encounter = add_encounter
	o.discard_encounter = discard_encounter
	o.get_next_encounter = get_next_encounter
	o.dismiss_current_encounter = dismiss_current_encounter

	-- data an initialization	
	o.backdrop_images = load_backdrop_images()
	o.backdrop_fademask = load_backdrop_fademask()
	
	o.tile_list = {}
	o.tile_width = 160
	o.tile_pos = 0
	init_backdrop_tiles(o)

	o.encounters = {}
	init_encounters(o)
	o.encounter_index = 1 -- index into encounters table to the current/approaching next encounter of import

	return o

end
