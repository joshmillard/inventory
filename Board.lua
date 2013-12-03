module(..., package.seeall);

-- the puzzleboard structure

require "Tile"

-- set the tracked occupant piece of this board tile to a given piece of loot (or nil if emptying)
local function set(board, x, y, loot)
	if x < 1 or x > board.width or y < 1 or y > board.height then
		print("full(" .. x .. "," .. y ..") out of bounds")
		return nil
	end
	board.tiles[y][x]:set_occupant(loot)
end

local function full(board, x, y)
	if x < 1 or x > board.width or y < 1 or y > board.height then
		print("full(" .. x .. "," .. y ..") out of bounds")
		return nil
	end
	return board.tiles[y][x]:get_occupant()
end

local function h(board)
	return board.height
end

local function w(board)
	return board.width
end

-- add a piece to the board
local function add_loot_to_board(board, loot)
  -- add this piece to the list
  table.insert(board.pieces, loot)
  -- mark the board tiles as occupied
  local l = loot:layout()
  for y=1, loot:h() do
    for x=1, loot:w() do
      if l[y][x] then
        board:set(x + loot:tx() - 1, y + loot:ty() - 1, loot)
      end
    end
  end
end

-- check to see if a given piece overlaps with the current board state's fixed loot
local function check_for_overlap(board, loot)
	
  local l = loot:layout()
  for y=1, loot:h() do
    for x=1, loot:w() do
      if l[y][x] then
        if board:full(x + loot:tx() - 1, y + loot:ty() - 1) then
	        -- there's an occupied tile under this part of the current piece, no good
	        print("Can't drop here, there's an occupied square!")
	        return true
	      end
	    end
	  end
	end

	-- no overlap between loot and board
	return false
end



-- given a piece of loot on the board, check the neighboring spaces to that loot and
-- compile a list of adjacent (cardinal, not diagonal) pieces of loot on the board
local function get_adjacent_loot(board, loot)
	-- TODO: call get_loot_tiles, iterate over that list of coordinates creating a hash of
  -- pieces found neighboring each to create final list of neighboring loot	
end

-- given a piece of loot, return the list of tiles that loot occupies on the board
local function get_loot_tiles(board, loot)
	local l = loot:layout()
	local t = {}
	for y=1, loot:h() do
		for x=1, loot:w() do
			if l[y][x] then
				table.insert(t, {x + loot:tx() - 1, y + loot:ty() - 1})
			end
		end
	end

	return t
end

local function p(board)
	return board.pieces
end

-- create and return a board
function new(width, height)
	local o = {}
	o.width = width   -- dimensions in tiles
	o.height = height

	o.pieces = {} -- list of pieces currently on the board

	o.tiles = {}
	local neighbors = {top = true, right = true, bottom = true, left = true}
	for y=1, height do
		neighbors.top = true
		neighbors.bottom = true
		if y == 1 then
			neighbors.top = false
		elseif y == o.height then
			neighbors.bottom = false
		end
		o.tiles[y] = {}
		for x=1, width do
			neighbors.left = true
			neighbors.right = true
			if x == 1 then
				neighbors.left = false
			elseif x == o.width then
				neighbors.right = false
			end
			table.insert(o.tiles[y], Tile.new(x, y, neighbors.top, neighbors.right, neighbors.bottom, neighbors.left))
		end
	end
		
	-- assign member functions
	o.full = full
	o.set = set
	o.h = h
	o.w = w
	o.p = p

	o.add_loot_to_board = add_loot_to_board
	o.check_for_overlap = check_for_overlap
	o.get_adjacent_loot = get_adjacent_loot
	o.get_loot_tiles = get_loot_tiles

	return o
end
