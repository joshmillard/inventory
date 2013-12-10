module(..., package.seeall);

-- a simple sprite utility class
--[[
	A sprite is a collection of animation states, each containing references to one or
	more Image objects that can be cycled through as looped frames in an animation, along 
	with some member functions for initializing and animating the sprite.

	Improvements could include optional per-animation delay settings and non-looping options
	that return a value when finishing final frame of animation, for trigger events based on
	completion of an animation sequence.
--]]

-- switch to named animation state if it exists, resetting to first frame
local function switch_anim(sprite, name)
	if not sprite.anims[name] then
		-- no such animation registered in this sprite
		print("No such anim state: " .. name)
		return nil
	end
  sprite.anim_timer = 0
  sprite.anim_state = name
  sprite.anim_frame = 1
end

-- register a new animation set with this sprite
local function add_anim(sprite, name, images)
	sprite.anims[name] = images
end

-- advance timer by dt seconds, change frame if it's been long enough on the current frame
local function animate(sprite, dt)
	local looped = false
	if not sprite.anims[sprite.anim_state] then
		-- looks like we're not actually ready to animate yet, get outta here
		return nil
	end
	sprite.anim_timer = sprite.anim_timer + dt
  if sprite.anim_timer > sprite.anim_delay then
    -- we've been on this frame long enough, let's move to the next one
    local frames = sprite.anims[sprite.anim_state]
    local max_frame = table.getn(frames)
    sprite.anim_frame = sprite.anim_frame + 1
    if sprite.anim_frame > max_frame then
      -- loop back to the original frame if we were on the last one already
      sprite.anim_frame = 1
			looped = true
    end
    sprite.anim_timer = sprite.anim_timer - sprite.anim_delay
  end

	-- returns true if we looped back to first frome, so caller can check for completed cycle
	return looped
end

-- return the image for the current animation and frame
local function curr_frame(sprite)
	if not sprite.anims[sprite.anim_state] then
		-- not set up!
		return nil
	end
	return sprite.anims[sprite.anim_state][sprite.anim_frame]
end

-- return a new instance of a sprite object with the same content as this one
local function new_copy(sprite)
	local c = {}

	c.anims = sprite.anims
	c.anim_timer = sprite.anim_timer
	c.anim_state = sprite.anim_state
	c.anim_frame = sprite.anim_frame
	c.anim_delay = sprite.anim_delay

	c.add_anim = sprite.add_anim
	c.animate = sprite.animate
	c.switch_anim = sprite.switch_anim
	c.curr_frame = sprite.curr_frame
	c.new_copy = sprite.new_copy

	return c
end

-- return a new sprite
function new()
	local o = {}

	o.anims = {} -- hash of collections of image references
	o.anim_timer = 0 -- current time since frame change, in seconds
	o.anim_state = nil -- name of current state in anims that we're on
	o.anim_frame = 1 -- which frame of the current state we're on
	o.anim_delay = 0.1 -- time between frames, in seconds

	-- methods
	o.add_anim = add_anim
	o.animate = animate
	o.switch_anim = switch_anim
	o.curr_frame = curr_frame
	o.new_copy = new_copy

	return o

end
