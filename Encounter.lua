module(..., package.seeall);

-- generic dungeon encounter container

require "Monster"

--[[
	Encounters exist at a physical position within the dungeon, toward which the hero
	proceeds stopping at each one.  Most encounters will be Monster types which, if the hero
	survives the fight, yield up a piece of loot that needs to be placed before proceeding to
	the next encounter; other encounters are things like treasure chests (free (good?) loot!),
	healing fountains, recycle bins, etc.
--]]

local function get_random_encounter(kind)
	if kind == "monster" then
		local m = Monster.new()
		return m
	else
		-- don't know what to do with this sort of encounter
		print("Bad encounter type: " .. kind)
		return nil
	end

end

local function advance_encounter(enc, x)
	enc.xpos = enc.xpos - x
end

-- return a new encounter
function new(xpos)
	local o = {}

	o.kind = "monster"
	o.encounter = get_random_encounter(o.kind)
	o.xpos = xpos

	-- methods
	o.advance_encounter = advance_encounter

	return o
end





