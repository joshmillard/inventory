module(..., package.seeall);

-- the puzzleboard structure

local function set(board, x, y, val)
	if x < 1 or x > board.width or y < 1 or y > board.height then
		print("full(" .. x .. "," .. y ..") out of bounds")
		return nil
	end
	board.tiles[y][x] = val
end


local function full(board, x, y)
	if x < 1 or x > board.width or y < 1 or y > board.height then
		print("full(" .. x .. "," .. y ..") out of bounds")
		return nil
	end
	return board.tiles[y][x]
end

local function h(board)
	return board.height
end

local function w(board)
	return board.width
end

-- create and return a board
function new(width, height)
	local o = {}
	o.width = width
	o.height = height

	o.tiles = {}
	for y=1, height do
		o.tiles[y] = {}
		for x=1, width do
			table.insert(o.tiles[y], false)
		end
	end
		
	o.full = full
	o.set = set
	o.h = h
	o.w = w

	return o
end
