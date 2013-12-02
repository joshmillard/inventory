module(..., package.seeall);

-- the loot object

TSIZE = 40

local path = "art/loot/"

-- generate a sample bit of loop
local function get_random_loot()
	local r = math.random(3)

	local w, h, layout
	if r == 1 then
		-- a sword! a 1x3 array of tiles
		w = 1
		h = 3
		image = love.graphics.newImage(path .. "sword.png")
		layout = { {true}, {true}, {true} }
	elseif r == 2 then
		-- a buckler!
		w = 2
		h = 2
		image = love.graphics.newImage(path .. "buckler.png")
		layout = { {true, true}, {true, true} }
	elseif r == 3 then
		-- a mace!
		w = 2
		h = 3
		image = love.graphics.newImage(path .. "mace.png")
		layout = { {true, false}, {true, true}, {false, true} }
	end

	return w, h, image, layout
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

-- generate a new piece of loot
function new()

	local o = {}
	o.width, o.height, o.loot_image, o.tile_layout = get_random_loot()
	o.rotation = 0	
	o.tilex = 1 -- x and y coordinates of origin in board space
	o.tiley = 1

	o.h = h
	o.w = w
	o.layout = layout
	o.rotate_clockwise = rotate_clockwise

	o.tx = tx
	o.ty = ty
	o.set_position = set_position
	o.image = image
	o.angle = angle
	o.image_offset = image_offset

	return o
end

