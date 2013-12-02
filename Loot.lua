module(..., package.seeall);

-- the loot object

TSIZE = 40

local path = "art/loot/"

-- define some basic loot
local loots = {

{name = "sword", w = 1, h = 3, file = "sword", layout = { {true}, {true}, {true} } },
{name = "buckler", w = 2, h = 2, file = "buckler", layout = { {true, true}, {true, true} } },
{name = "mace", w = 2, h = 3, file = "mace", layout = { {true, false}, {true, true}, {false, true} } },
{name = "axe", w = 2, h = 3, file = "axe", layout = { {true, true}, {true, true}, {true, false} } },
{name = "armor", w = 2, h = 4, file = "armor", layout = { {true, true}, {true, true}, {true, true}, {true, true} } },
{name = "bow", w = 2, h = 4, file = "bow", layout = { {true, false}, {true, true}, {true, true}, {true, false} } },
{name = "gauntlet", w = 2, h = 1, file = "gauntlet", layout = { {true, true} } },
{name = "helmet", w = 3, h = 2, file = "helmet", layout = { {true, false, true}, {true, true, true} } },
{name = "staff", w = 1, h = 4, file = "staff", layout = { {true}, {true}, {true}, {true} } },

}

-- generate a sample bit of loop
local function get_random_loot()
	local l = loots[math.random(table.getn(loots))]
	local img = love.graphics.newImage(path .. l.file .. ".png")
	return l.w, l.h, img, l.layout
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

