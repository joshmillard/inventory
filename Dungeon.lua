module(..., package.seeall);

-- the dungeon, through which our hero crawls

--[[
- background art, and an array of background art tiles to scroll through
- an array of baddies and other encounters
- various dungeon data and shit and who knows just what, let's go crazy
--]]

DLENGTH = 6 -- how much of the dungeon backdrop to keep around

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
end

-- instantiate a dungeon!
function new()
	local o = {}

	-- methods
	o.advance_backdrop = advance_backdrop
	o.add_backdrop_tile = add_backdrop_tile
	o.discard_backdrop_tile = discard_backdrop_tile

	-- data an initialization	
	o.backdrop_images = load_backdrop_images()
	o.backdrop_fademask = load_backdrop_fademask()
	
	o.tile_list = {}
	o.tile_width = 160
	o.tile_pos = 0
	init_backdrop_tiles(o)

	return o

end
