module(..., package.seeall);

-- inventory tetris sketch

SCREENWIDTH = 1024
SCREENHEIGHT = 750

-- some board drawing constants
BX = 500
BY = 200
TSIZE = 40

-- homunculus origin
HOMX = 10
HOMY = 120

-- includes
require "Board"
require "Loot"
require "Hero"
require "Dungeon"

-- global structures
b = nil 	-- the board
curr_p = nil -- our current piece in play
hero = nil -- our brave, doomed hero
dungeon = nil -- our dungeon

score = 0 -- silly placeholder matching metric

mouse_tx = 0
mouse_ty = 0

function love.load()

	love.graphics.setMode(SCREENWIDTH, SCREENHEIGHT, false, true, 0)
	love.graphics.setCaption("Inventory Tetris")

	b = Board.new(12,8)
	get_new_curr_piece()

	hero = Hero.new()

	dungeon = Dungeon.new()	

end

-- event loop
function love.update(dt)
	-- check on some mouse position stuff
	update_mouse_board_position()

	-- animate the hero
	hero.sprite:animate(dt)
	
	if love.keyboard.isDown("w") then
		dungeon:advance_backdrop(200*dt)
	end

end


-- draw shit each frame
function love.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print("hey there", 10,10)

	draw_hero_stats()
	draw_hero_homunculus()
	draw_board()
	draw_dungeon()
	draw_dungeon_hero()
	draw_curr_piece()
	draw_curr_piece_stats()
	draw_hover_piece_stats()
end


-- handle keyboard press events
function love.keypressed(key)
	
	if key == "escape" then
		love.event.quit()

	elseif key == "up" or key == "down" or key == "left" or key == "right" then
		move_curr_piece(key)

	elseif key == "r" then
		rotate_curr_piece()

	elseif key == " " then
		drop_curr_piece()

	elseif key == "p" then
		b:print_board()

	elseif key == "e" then
		hero:put_gear_on_hero(curr_p)
		get_new_curr_piece()

	elseif key == "w" then
		hero.sprite:switch_anim("walk")

	elseif key == "f" then
		hero.sprite:switch_anim("attack")

	end

end

function love.keyreleased(key)

	if key == "w" then
		hero.sprite:switch_anim("stand")
	elseif key == "f" then
		hero.sprite:switch_anim("stand")

	end
end

-- handle mousebutton events

function love.mousepressed(x, y, button)
	if button == "r" then
		rotate_curr_piece()
	elseif button == "l" then
		drop_curr_piece()
	end
end

-- check to see if the mouse is over the board, and if so update its tx/ty values
function update_mouse_board_position()
	local mx, my = love.mouse.getPosition()
	if mx > BX and mx < BX + b:w()*TSIZE and my > BY and my < BY + b:h()*TSIZE then
		-- we're in bounds on the board, let's get this shit going!
		mouse_tx = math.floor( ((mx - BX - (0.5 * curr_p:w()*TSIZE)) + (0.5*TSIZE)) / TSIZE ) + 1
		mouse_ty = math.floor( ((my - BY - (0.5 * curr_p:h()*TSIZE)) + (0.5*TSIZE)) / TSIZE ) + 1
		curr_p:set_position(mouse_tx, mouse_ty)
		force_curr_piece_inbounds()
	else
		-- out of bounds don't care, so sad
	end
end

-- returns tx, ty coordinate of tile mouse is over if it's over board, nil otherise
function mouse_tile_position()
	local mx, my = love.mouse.getPosition()
	if mx > BX and mx < BX + b:w()*TSIZE and my > BY and my < BY + b:h()*TSIZE then
		-- mouse cursor is in the confines of the board, let's return a tile coordinate pair
		local newtx = math.floor( ((mx - BX) / TSIZE) + 1)
		local newty = math.floor( ((my - BY) / TSIZE) + 1)
		return newtx, newty
	end
	
	-- out of bounds
	return nil
end

-- move current piece on board
function move_curr_piece(direction)
	if direction == "left" then
		if curr_p:tx() > 1 then
			curr_p:set_position(curr_p:tx() - 1, curr_p:ty())
		end
	elseif direction == "right" then
		if curr_p:tx() + curr_p:w() - 1 < b:w() then
			curr_p:set_position(curr_p:tx() + 1, curr_p:ty())
		end
	elseif direction == "up" then
		if curr_p:ty() > 1 then
			curr_p:set_position(curr_p:tx(), curr_p:ty() - 1)
		end
	elseif direction == "down" then
		if curr_p:ty() + curr_p:h() - 1 < b:h() then
			curr_p:set_position(curr_p:tx(), curr_p:ty() + 1)
		end
	end
end

-- check bounds of current piece and force it inbounds if it's out
function force_curr_piece_inbounds()
	local left = curr_p:tx()
	local top = curr_p:ty()
	local right = curr_p:tx() + curr_p:w() - 1
	local bottom = curr_p:ty() + curr_p:h() - 1

	if left < 1 then 
		curr_p:set_position(1, curr_p:ty()) 
	elseif right > b:w() then
		curr_p:set_position(b:w() - curr_p:w() + 1, curr_p:ty())
	end

	if top < 1 then 
		curr_p:set_position(curr_p:tx(), 1)
	elseif bottom > b:h() then
		curr_p:set_position(curr_p:tx(), b:h() - curr_p:h() + 1)
	end
end

-- rotate the current piece
function rotate_curr_piece()
	curr_p:rotate_clockwise()
	force_curr_piece_inbounds()
end

-- try to drop the current piece onto the board
function drop_curr_piece()

	if not b:check_for_overlap(curr_p) then
		-- no overlap with current board loot, we can drop here!
		b:add_loot_to_board(curr_p)
		local rank = check_for_matches(curr_p)
		if not rank then
			-- No match, just generate a random piece
			get_new_curr_piece()
		else
			-- got a match, generate a new piece of the same kind and of (potentially) greater rank
			print("Average rank + 1 for matched set of " .. curr_p.subkind .. " is " .. rank)
			get_new_curr_piece(rank, curr_p.subkind)
		end 
	else
		-- can't drop here, maybe play a nice error noise!
	end	
end

-- check to see if there are any three-piece matches as a result of newly-placed piece
-- return rank value for new piece if matches found, nil otherwise
function check_for_matches(piece)
	local graph = {} -- hash of pieces that match this piece
	graph[piece.id] = piece -- this piece is clearly in the list of pieces of this type touching it...
	local todo = {}
	todo[piece.id] = piece
	local nothing_new = false

	repeat
		nothing_new = true
		for j,w in pairs(todo) do		
			local adjacent = b:get_adjacent_loot(w)
			for i,v in ipairs(adjacent) do
				if v.subkind == w.subkind then
					if not graph[v.id] then
						graph[v.id] = v
						todo[v.id] = v
						nothing_new = false
					end
				end
			end
			todo[w.id] = nil
		end
	until nothing_new

	-- debug: list all the pieces in this matching graph
	local num_matches = 0
	for k,v in pairs(graph) do
		num_matches = num_matches + 1
	end

	if num_matches >= 3 then
		local average_rank = 0
		print("Matching " .. num_matches .. " connected " .. piece.subkind .. " pieces!")
		for k,v in pairs(graph) do
			b:remove_loot_from_board(v)
			print("Removing " .. v.subkind .. " #" .. v.id)
			score = score + 1
			average_rank = average_rank + v.rank
		end
		average_rank = average_rank / 3 
		--[[
			This is a quick and dirty way to get a sense of whether the pieces matched were
			enough to justify sending back a better piece of equipment after a match.  Because
			we divide by three regardless of the number of matches, it's possible to match
			a larger number of lower-rank pieces and still have a chance to reach rank up.
		]]--
		return average_rank + 1
	end	

	return nil
end


-- fetch a new piece as the current piece
function get_new_curr_piece(rank, subkind)
	curr_p = Loot.new(rank, subkind)
	curr_p:set_position(1, 1) 
end

-- draw the board
function draw_board()

	BWIDTH = TSIZE * b:w()
	BHEIGHT = TSIZE * b:h()

	love.graphics.setColor(150,150,0)
	love.graphics.rectangle("line", BX - 1, BY - 1, BWIDTH + 2, BHEIGHT + 2)
	for y=1, b:h() do
		for x=1, b:w() do
			love.graphics.setColor(100,100,0)
			love.graphics.rectangle("line", BX + TSIZE*(x-1), BY + TSIZE*(y-1), TSIZE, TSIZE)
			if b:full(x, y) then
				love.graphics.setColor(50,50,50)
				love.graphics.rectangle("fill", BX + TSIZE*(x-1) + 1, BY + TSIZE*(y-1) + 1, TSIZE - 2, TSIZE - 2)
			end
		end
	end

	for k,v in pairs(b:p()) do
		draw_piece(v)
	end

end

-- draw the current piece we're considering placing
function draw_piece(draw_p, highlight)
	local layout = draw_p:layout()

	local bgcolor = {50,50,50,200}
	local fgcolor = {255,255,255,255}
	if highlight then
		bgcolor = {0,100,0,128}
		fgcolor = {255,255,255,128}
	end

	-- draw the backdrop
	for y=1, draw_p:h() do
		for x=1, draw_p:w() do
			if layout[y][x] then
				love.graphics.setColor(bgcolor)
				love.graphics.rectangle("fill", BX + TSIZE*(x + tonumber(draw_p:tx()) - 2), 
					BY + TSIZE*(y + tonumber(draw_p:ty()) - 2),
					TSIZE, TSIZE)
			end
		end
	end
	-- draw the graphics
	love.graphics.setColor(fgcolor)
	love.graphics.draw(draw_p:image(), BX + TSIZE*(draw_p:tx() - 1), BY + TSIZE*(draw_p:ty() - 1), math.rad(draw_p:angle()), 1, 1, draw_p:image_offset().x, draw_p:image_offset().y )

	-- draw a reference ID for debugging
	love.graphics.setColor(255,0,0)
	love.graphics.print(draw_p.id, BX + TSIZE*(draw_p:tx() - 1) + 5, BY + TSIZE*(draw_p:ty() - 1) + 5)

end

function draw_curr_piece()
	draw_piece(curr_p, true)
end

function draw_curr_piece_stats()
--	local x, y = love.mouse.getPosition()
	local CURRSTATSX = 800
	local CURRSTATSY = 30

	love.graphics.setColor(255,255,255,255)
	love.graphics.printf("Current piece:", 800, 10, 200, "center") 
	draw_piece_stats(curr_p, CURRSTATSX, CURRSTATSY)
end

function draw_piece_stats(loot, x, y)
	local draw_p = loot
	local xpos, ypos = x, y
	if xpos < 0 then
		xpos = 0
	end
	if xpos > SCREENWIDTH then
		xpos = SCREENWIDTH - 200
	end
	xpos = xpos + 5
	ypos = ypos + 5	

	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle("fill", xpos, ypos, 200, 100)

	ypos = ypos + 10

	love.graphics.setColor(0,255,0,255)
	love.graphics.printf(draw_p.name, xpos, ypos, 200, "center")
	ypos = ypos + 20
	
	if curr_p.attack > 0 then
		love.graphics.setColor(100,200,100)
		love.graphics.printf("Attack +" .. draw_p.attack, xpos, ypos, 200, "center")
		ypos = ypos + 15
	elseif curr_p.attack < 0 then
		love.graphics.setColor(200,50,50)
		love.graphics.printf("Attack " .. draw_p.attack, xpos, ypos, 200, "center")
		ypos = ypos + 15
	end

	if curr_p.defense > 0 then
		love.graphics.setColor(100,200,100)
		love.graphics.printf("Defense +" .. draw_p.defense, xpos, ypos, 200, "center")
		ypos = ypos + 15
	elseif curr_p.defense < 0 then
		love.graphics.setColor(200,50,50)
		love.graphics.printf("Defense " .. draw_p.defense, xpos, ypos, 200, "center")
		ypos = ypos + 15
	end

	love.graphics.printf("Rank:   " .. draw_p.rank, xpos, ypos, 200, "center")
end

-- returns a reference to a piece of loot under the mouse pointer, or nil if none
function get_board_piece_under_mouse()
	local thex, they = mouse_tile_position()
	if thex then
		-- mouse is on the board, let's find out what's under it
		local loot = b:full(thex, they)
		if loot then
			-- there's a piece, let's return that sucker
			return loot
		end
	end

	-- either the mouse wasn't over the board, or there was no piece under it's board position
	return nil
end

-- returns a reference to a piece of loot on the homunculus uner the mouse pointer, or nil if none
function get_gear_piece_under_mouse()
	local thex, they = love.mouse.getPosition()
	for k,v in pairs(hero.hom.loot) do
		-- see if we're within the confines of a given homunulus loot zone
		if thex > HOMX + v.x and thex < HOMX + v.x + v.width 
				and they > HOMY + v.y and they < HOMY + v.y + v.height then
			-- we're over this slot!
			if hero.equipment[k] then
				-- and there's actual loot, let's return it
				return hero.equipment[k]
			end
		end
	end 
	return nil
end

function draw_hover_piece_stats()
	local x, y = love.mouse.getPosition()
	local draw_p = get_board_piece_under_mouse()
	if not draw_p then
		-- okay, let's see if we're hovering over a homunculus gear piece instead!
		draw_p = get_gear_piece_under_mouse()
		if not draw_p then
			-- no piece there either, eff this
			return
		end
	end
	draw_piece_stats(draw_p, x - 100, y)
end

function draw_hero_stats()
	local STATSX = 10
	local STATSY = 10
	local STATSW = 200
	local STATSH = 100

	local wl = STATSX + 10 -- text padding limit
	local wr = STATSW - 20 -- padding bound
	local ypos = STATSY + 10
	local al = "center"

	love.graphics.setColor(50,50,50)
	love.graphics.rectangle("fill", STATSX, STATSY, STATSW, STATSH)
	
	love.graphics.setColor(255,255,200)
	love.graphics.printf(hero.name .. " the " .. hero.class, wl, ypos, wr, al)
	ypos = ypos + 20

	love.graphics.setColor(200,200,200)
	love.graphics.printf("HP: " .. hero.hp .. "/" .. hero.max_hp, wl, ypos, wr, al)
	ypos = ypos + 15
	love.graphics.printf("Attack: " .. hero.curr_attack, wl, ypos, wr, al)
	ypos = ypos + 15
	love.graphics.printf("Defense: " .. hero.curr_defense, wl, ypos, wr, al)
	ypos = ypos + 15

end

function draw_hero_homunculus()

	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(hero.hom.image, HOMX, HOMY)

	-- draw equipped loot, if any, for each slot
	for k,v in pairs(hero.hom.loot) do
		love.graphics.setColor(0,0,0)
		love.graphics.printf(k, HOMX + v.x, HOMY + v.y + (v.height / 2) - 10, v.width, "center")
		if hero.equipment[k] then
			local l = hero.equipment[k]
			local xoff = HOMX + v.x + ((v.width - (l:w() * TSIZE)) / 2)
			local yoff = HOMY + v.y + ((v.height - (l:h() * TSIZE)) / 2)

			love.graphics.setColor(255,255,255,255)
			love.graphics.draw(l:image(), xoff, yoff, math.rad(l:angle()), 1, 1, l:image_offset().x, l:image_offset().y )

		end
	end
end

function draw_dungeon()
	local DUNGEONX = 10
	local DUNGEONY = 530
	for i=1, 4 do
		love.graphics.setColor(255,255,255,255)
		love.graphics.draw(dungeon.tile_list[i], (dungeon.tile_width  * (i-1)) + DUNGEONX - dungeon.tile_pos, DUNGEONY)
	end

	-- and fade that shit
	love.graphics.setColor(255,255,255)
	love.graphics.draw(dungeon.backdrop_fademask, DUNGEONX, DUNGEONY)
end

function draw_dungeon_hero()
	local DHEROX = 50
	local DHEROY = 590

	if hero.sprite:curr_frame() then
		-- make sure this exists before we draw it; this should really probably be enforced better
		-- elsewhere in game logic, but, hey.
		love.graphics.setColor(255,255,255,255)
		love.graphics.draw(hero.sprite:curr_frame(), DHEROX, DHEROY)
	end
end
