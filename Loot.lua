module(..., package.seeall);

-- the loot object



-- generate a sample bit of loop
local function get_random_loot()
	local r = math.random(3)

	local w, h, layout
	if r == 1 then
		-- a sword! a 1x3 array of tiles
		w = 1
		h = 3
		layout = { {true}, {true}, {true} }
	elseif r == 2 then
		-- a shield!
		w = 2
		h = 2
		layout = { {true, true}, {true, true} }
	elseif r == 3 then
		-- a wand!
		w = 2
		h = 3
		layout = { {false, true}, {true, true}, {true, false} }
	end

	return w, h, layout
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
end

-- generate a new piece of loot
function new()

	local o = {}
	o.width, o.height, o.tile_layout = get_random_loot()
	o.rotation = 0	

	o.h = h
	o.w = w
	o.layout = layout
	o.rotate_clockwise = rotate_clockwise

	return o
end

