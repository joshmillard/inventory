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
require "Monster"

-- global structures
b = nil 	-- the board
curr_p = nil -- our current piece in play
hero = nil -- our brave, doomed hero
dungeon = nil -- our dungeon

score = 0 -- silly placeholder matching metric

mouse_tx = 0
mouse_ty = 0

gamemode = nil -- state value for major game modes (title screen, dungeon crawl, etc)
gamestate = nil -- state value for tracking game flow
fightstate = nil -- sub-state value for tracking fight flow

function love.load()

	love.graphics.setMode(SCREENWIDTH, SCREENHEIGHT, false, true, 0)
	love.graphics.setCaption("Inventory Tetris")

	b = Board.new(12,8)

	hero = Hero.new()

	Monster.init_monster_sprites()
	dungeon = Dungeon.new()	

	init_title()
	gamemode = "title"

end

-- do the appropriate setup (and shutdown?) of stuff to switch from the
-- current gamemode to new gamemode "mode"
function switch_gamemode(mode)
	if mode == "title" then
		gamemode = "title"
	
	elseif mode == "dungeon" then
		-- do all sorts of dungeon setup, presumably
		-- but for now just switch some real basic stuff
		print("Switching game mode to dungeon...")
		gamemode = "dungeon"
		gamestate = "moving"
		hero.sprite:switch_anim("walk")

	else
		-- what game mode is this?
		print("Unknown gamemode " .. mode .. ", declining to switch from " .. gamemode .. " .")		
	end

end

-- event loop
function love.update(dt)


if gamemode == "title" then
	-- do title update stuff...

elseif gamemode == "dungeon" then
	-- do core gameplay loop stuff...

	-- check on some mouse position stuff
	if curr_p then
		-- if we have no piece we're manhandling, we don't need to do this
		update_mouse_board_position()
	end

	-- animate the hero
	-- TODO: generalize to "animate_sprites(dt)" call that will iterate through a list of all
	--  active sprites in the game...
--	hero.sprite:animate(dt)
	-- should animate monster in dungeon, too...

	local monst = dungeon:get_next_encounter()

	if gamestate == "moving" then
		hero.sprite:animate(dt)
		local distance_to_next = monst.xpos
		if distance_to_next <= 200*dt then
			-- we've arrived at the next encounter!
			dungeon:advance_backdrop(distance_to_next)
			
			-- and now switch modes based on what kind of thing we're Encountering
			if monst.kind == "monster" then
				hero.sprite:switch_anim("attack")
				gamestate = "fighting"
				fightstate = "hero attack anim"
			elseif monst.kind == "sign" then
				-- switch to Readin' A Sign mode
				hero.sprite:switch_anim("stand")
				gamestate = "reading"
			else
				-- don't know what to make of this!
				print("Mysterious encounter kind: " .. monst.kind)
			end
		else
			-- we're still not there, keep walking
			dungeon:advance_backdrop(200*dt)
		end
		hero.sprite:animate(dt)

	elseif gamestate == "reading" then
		-- we're just waiting for someone to hit Any Key, really...

	elseif gamestate == "fighting" then
		-- handle fighty bits
		if fightstate == "hero attack anim" then
			-- check to see if we're done with the attack anim yet
			if hero.sprite:animate(dt) then
				-- we looped ot the end of the fight animation, let's move on to damage calc
				fightstate = "hero attack calc"
				hero.sprite:switch_anim("stand")
			end
		elseif fightstate == "hero attack calc" then
			local damage = hero.curr_attack - monst.encounter.defense
			if damage < 0 then
				damage = 0
			end
			print("hero does " .. damage .. " damage!")
			monst.encounter.hp = monst.encounter.hp - damage
			if monst.encounter.hp > 0 then
				-- monster survived hero's attack, now he gets a whack
				fightstate = "monster attack anim"
				monst.encounter.sprite:switch_anim("attack")
			else
				-- fight's over, hero won, let's nix the monster and get a piece of loot
				-- TODO ^^^
				print("monster dispatched, let's get a piece!")
				local spoils = monst.encounter:get_loot()
				curr_p = Loot.new(1, spoils)
				print("Ooh, it's a " .. spoils)
				monst.encounter.sprite:switch_anim("dead")
				dungeon:dismiss_current_encounter()
				gamestate = "placing"
			end
		elseif fightstate == "monster attack anim" then
			if monst.encounter.sprite:animate(dt) then
				fightstate = "monster attack calc"
				monst.encounter.sprite:switch_anim("stand")
			end
		elseif fightstate == "monster attack calc" then
			local damage = monst.encounter.attack - hero.curr_defense
			if damage < 0 then
				damage = 0
			end
			hero.hp = hero.hp - damage
			print("monster does " .. damage .. " damage to hero!")
			if hero.hp > 0 then
				-- hero survived and gets another whack at monnster
				fightstate = "hero attack anim"
				hero.sprite:switch_anim("attack")
			else
				-- hero is dead, end of dungeon crawl, bummer!
				print("Hero died, back to town we should go!")
				gamestate = "dead"
				hero.sprite:switch_anim("dead")
				-- TODO ^^^
			end
	
		else
			-- mysterious situation!
			print("What the hell fightstate is this: " .. fightstate)
		end
	

	elseif gamestate == "placing" then
		-- handle loot-placing bits
		if not curr_p then
			-- no piece currently in hand, must be time to move on to next encounter...
			gamestate = "moving"
			hero.sprite:switch_anim("walk")
		end

	elseif gamestate == "dead" then
		-- oh no, the hero is dead!

	else
		-- what gamestate is this omg?
		print("MYSTERY GAMESTATE: " .. gamestate)
	end

end -- end gamemode condition


end


-- draw shit each frame
function love.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print("hey there", 10,10)

	if gamemode == "title" then
		draw_title()

	elseif gamemode == "dungeon" then

		draw_hero_stats()
		draw_hero_homunculus()
		draw_board()
		draw_dungeon()
		draw_next_encounter_stats()
		if curr_p then
			draw_curr_piece()
			draw_curr_piece_stats()
		end
		draw_hover_piece_stats()

		if gamestate == "reading" then
			draw_encounter_text()
		end

	else
		-- unknown gamemode, what?
		print("Unknown gamemode: " .. gamemode)
	end

end


-- handle keyboard press events
function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end

	if gamemode == "title" then
		-- handly any key thing
		switch_gamemode("dungeon")

	elseif gamemode == "dungeon" then
		-- handle main game loop input
	
		--elseif key == "up" or key == "down" or key == "left" or key == "right" then
		--move_curr_piece(key)

		if gamestate == "reading" then
			if key == " " then
				-- dismiss this sign
				dungeon:dismiss_current_encounter()
				gamestate = "moving"
				hero.sprite:switch_anim("walk")
			end

		elseif gamestate == "placing" then

			if key == "r" then
				rotate_curr_piece()

			elseif key == " " then
				drop_curr_piece()

			elseif key == "e" then
				hero:put_gear_on_hero(curr_p)
				curr_p = nil
			
			end

		else
			-- some other gamestate...
		end			

	end -- end gamemode conditional

end


function love.keyreleased(key)

end

-- handle mousebutton events

function love.mousepressed(x, y, button)

	if gamemode == "title" then
		-- title input

	elseif gamemode == "dungeon" then
	
	if button == "r" then
		rotate_curr_piece()
	elseif button == "l" then
		drop_curr_piece()
	end

	end -- end gamemode conditional
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

	if not curr_p then
		print("We don't HAVE a piece, shouldn't be allowed to call drop_curr_piece() here!")
		return
	end

	if not b:check_for_overlap(curr_p) then
		-- no overlap with current board loot, we can drop here!
		b:add_loot_to_board(curr_p)
		local rank = check_for_matches(curr_p)
		if not rank then
			-- dismiss the piece
			curr_p = nil
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
	
	if draw_p.attack > 0 then
		love.graphics.setColor(100,200,100)
		love.graphics.printf("Attack +" .. draw_p.attack, xpos, ypos, 200, "center")
		ypos = ypos + 15
	elseif draw_p.attack < 0 then
		love.graphics.setColor(200,50,50)
		love.graphics.printf("Attack " .. draw_p.attack, xpos, ypos, 200, "center")
		ypos = ypos + 15
	end

	if draw_p.defense > 0 then
		love.graphics.setColor(100,200,100)
		love.graphics.printf("Defense +" .. draw_p.defense, xpos, ypos, 200, "center")
		ypos = ypos + 15
	elseif draw_p.defense < 0 then
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

	-- draw the hero
	draw_dungeon_monsters()
	draw_dungeon_hero()

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

function draw_dungeon_monsters()
	local MONSTER_XOFFSET = 80
	for i,v in ipairs(dungeon.encounters) do
		if v.encounter.sprite:curr_frame() then
			if v.xpos > 500 then
				-- probably shouldn't be able to see this guy yet, for now hackily just decline to draw...
			else
				love.graphics.setColor(255,255,255,255)
				love.graphics.draw(v.encounter.sprite:curr_frame(), v.xpos + MONSTER_XOFFSET, 590)
			end
		end
	end
end

function draw_next_encounter_stats()
	local NEXTE_X = 600
	local NEXTE_Y = 600
	local ypos = 0

	love.graphics.setColor(255,255,255,255)
	love.graphics.print("Next encounter:", NEXTE_X, NEXTE_Y + ypos)
	ypos = ypos + 20

	local e = dungeon:get_next_encounter()
	if not e then
		-- no actual encounter coming up!
		love.graphics.setColor(255,0,0,255)
		love.graphics.print("None loaded!", NEXTE_X, NEXTE_Y + ypos)
	elseif e.kind == "monster" then
		love.graphics.setColor(255,255,255)
		love.graphics.print(e.encounter.name .. " (" .. e.kind .. ")", NEXTE_X, NEXTE_Y + ypos)
		ypos = ypos + 15
		love.graphics.print("Attack: " .. e.encounter.attack, NEXTE_X, NEXTE_Y + ypos)
		ypos = ypos + 15
		love.graphics.print("Defense: " .. e.encounter.defense, NEXTE_X, NEXTE_Y + ypos)
		ypos = ypos + 15
		love.graphics.print("HP (max): " .. e.encounter.hp .. "(" .. e.encounter.max_hp .. ")", NEXTE_X, NEXTE_Y + ypos)
		ypos = ypos + 15

	elseif e.kind == "sign" then
		love.graphics.setColor(255,255,255)
		love.graphics.print("A sign approaches!", NEXTE_X, NEXTE_Y + ypos)

	else
		-- worry about when there's more encounter types!

	end
end

-- load art assets for the title screen
function init_title()
	titleart = love.graphics.newImage("art/title/dungeon_caddy_title.png")
end

-- draw title
function draw_title()
	love.graphics.setBackgroundColor(0,0,0,255)
	love.graphics.clear()

	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(titleart, 12, 75)

	love.graphics.print("(press any key)", 450, 700)
end

-- draw the content of an encounter sign
function draw_encounter_text()

	-- draw a wooden sign
	love.graphics.setColor(65,67,60,255)
	love.graphics.rectangle("fill", (SCREENWIDTH / 2) - 50, 20, 100, SCREENHEIGHT)
	love.graphics.setColor(140, 120, 90)
	love.graphics.rectangle("fill", (SCREENWIDTH / 2) - 30, 40, 60, SCREENHEIGHT)

	love.graphics.setColor(65,67,60,255)
	love.graphics.rectangle("fill", 100, 100, SCREENWIDTH - 200, SCREENHEIGHT - 200)
	love.graphics.setColor(177,150,106,255)
	love.graphics.rectangle("fill", 120, 120, SCREENWIDTH - 240, SCREENHEIGHT - 240)
 
	-- and render the text
	love.graphics.setColor(0,0,0,255)
	love.graphics.printf(dungeon:get_next_encounter().encounter:get_text(), 300, 200, SCREENWIDTH - 600, "center")

end
