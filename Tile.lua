module(..., package.seeall);

-- a board tile structure

-- given a direction string, return whether this tile has a neighbor there
local function has_neighbor(tile, direction)
	return tile.neighbors.direction
end

-- return a reference to the loot piece occupying this tile, or nil if none
local function get_occupant(tile)
	return tile.occupant
end

-- set the reference for this tile
local function set_occupant(tile, loot)
	tile.occupant = loot
end

function new(x, y, top, right, bottom, left)

	local o = {}
	o.x = x
	o.y = y
	o.occupant = nil
	o.neighbors = {top = top, right = right, bottom = bottom, left = left}

	o.has_neighbor = has_neighbor
	o.get_occupant = get_occupant
	o.set_occupant = set_occupant

	return o
end
