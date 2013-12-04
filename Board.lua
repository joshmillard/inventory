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
--  table.insert(board.pieces, loot)
	board.pieces[loot.id] = loot
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

-- remove a piece of loot from the board
local function remove_loot_from_board(board, loot)
	-- yank piece out of list
--	table.remove(board.pieces, loot)
	board.pieces[loot.id] = nil
	-- free up those board tiles
	local l = loot:layout()
	for y=1, loot:h() do
		for x=1, loot:w() do
			if l[y][x] then
				board:set(x + loot:tx() - 1, y + loot:ty() - 1, nil)
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
	local t = board:get_loot_tiles(loot)
	local adjacent = {}
	local dirs = { {"top", 0, -1}, {"left", -1, 0}, {"bottom", 0, 1}, {"right", 1, 0} }
		-- directions plus spatial offests dx and dy for that direction from current tile
		-- would make sense to just make this a bit of global constant stuff or something
	for i,v in ipairs(t) do
		for j,w in ipairs(dirs) do
			local n = board:get_tile(v:tx() + w[2], v:ty() + w[3])	
			if n then
				local oc = n:get_occupant()
				if oc and oc ~= loot then 
					local id = oc.id
					adjacent[oc.id] = oc
				end
			end
		end
	end

	local found = {}
	for k,v in pairs(adjacent) do
		table.insert(found, v)
	end

	return found	
end

-- given a piece of loot, return the list of tiles that loot occupies on the board
local function get_loot_tiles(board, loot)
	local l = loot:layout()
	local t = {}
	for y=1, loot:h() do
		for x=1, loot:w() do
			if l[y][x] then
				local temptile = board:get_tile(x + loot:tx() - 1, y + loot:ty() - 1)
				if temptile then
					table.insert(t, temptile)
				end
			end
		end
	end

	return t
end

local function get_tile(board, x, y)
	if x < 1 or x > board.width or y < 1 or y > board.height then
		-- out of bounds
		return nil
	end
	return board.tiles[y][x]
end

local function p(board)
	return board.pieces
end

local function print_board(board)
	print("Board is " .. board.width .. "x" .. board.height)
	for y=1, board.height do
		local str = ""
		for x=1, board.width do
			local tempt = board:get_tile(x, y)
			str = str .. tempt:tx() .. "," .. tempt:ty() .. "\t"
		end
		print(str)
	end
end

-- create and return a board
function new(width, height)
	local o = {}
	o.width = width   -- dimensions in tiles
	o.height = height

	o.pieces = {} -- hash of pieces currently on the board key: loot.id, val: loot object

	o.tiles = {}
	for y=1, height do
		o.tiles[y] = {}
		for x=1, width do
			table.insert(o.tiles[y], Tile.new(x, y))
		end
	end
		
	-- assign member functions
	o.full = full
	o.set = set
	o.h = h
	o.w = w
	o.p = p

	o.add_loot_to_board = add_loot_to_board
	o.remove_loot_from_board = remove_loot_from_board
	o.check_for_overlap = check_for_overlap
	o.get_adjacent_loot = get_adjacent_loot
	o.get_loot_tiles = get_loot_tiles
	o.get_tile = get_tile
	o.print_board = print_board

	return o
end
