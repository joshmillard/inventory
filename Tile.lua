module(..., package.seeall);

-- a board tile structure

-- return a reference to the loot piece occupying this tile, or nil if none
local function get_occupant(tile)
	return tile.occupant
end

-- set the reference for this tile
local function set_occupant(tile, loot)
	tile.occupant = loot
end

local function tx(tile)
	return tile.x
end

local function ty(tile)
	return tile.y
end

function new(x, y)

	local o = {}
	o.x = x
	o.y = y
	o.occupant = nil

	o.tx = tx
	o.ty = ty
	o.get_occupant = get_occupant
	o.set_occupant = set_occupant

	return o
end
