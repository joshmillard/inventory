module(..., package.seeall);

-- inventory tetris sketch


-- some board drawing constants
BX = 100
BY = 75
TSIZE = 40

-- includes
require "Board"
require "Loot"

-- global structures
b = nil 	-- the board
curr_p = nil -- our current piece in play


function love.load()

	love.graphics.setMode(640, 480, false, true, 0)
	love.graphics.setCaption("Inventory Tetris")

	b = Board.new(12,8)
	get_new_curr_piece()

end

-- event loop
function love.update(dt)


end


-- draw shit each frame
function love.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print("hey there", 10,10)

	draw_board()
	draw_curr_piece()

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

	end

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
for i,v in ipairs(b:get_loot_tiles(curr_p)) do
	print(v[1] .. "," .. v[2])
end
--TODO: b:check_for_matches()
		get_new_curr_piece()
	else
		-- can't drop here, maybe play a nice error noise!
	end	
end

-- check to see if there are any three-piece matches as a result of newly-placed piece
function check_for_matches()

end


-- fetch a new piece as the current piece
function get_new_curr_piece()
	curr_p = Loot.new()
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

	for i,v in ipairs(b:p()) do
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
end

function draw_curr_piece()
	draw_piece(curr_p, true)
end

