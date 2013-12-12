module(..., package.seeall);

-- a container class for managing and playing back sound effects

local defaultsounds = {
bell = "sound/bell.mp3",
dong = "sound/dong.mp3",
shake = "sound/shake.mp3",
zoot = "sound/zoot.mp3",
doop = "sound/doop.mp3",
kick = "sound/kick.mp3",
rattle = "sound/rattle.mp3",
tom = "sound/tom.mp3",
}

-- return a new SoundData object from file f
local function create_sound(f)
	local newsound = love.audio.newSource(f)
	if not newsound then
		print("Failed to create sound from file " .. f)
		return nil
	end
	return newsound
end


-- setup our initial fleet of sound effects
local function init_sounds()
	
	local s = {}
	for k,v in pairs(defaultsounds) do
		s[k] = create_sound(v)
	end

	return s
end

-- play back a sound effect
local function play(soundbank, name)
	if not soundbank.sounds[name] then
		print("Can't play sound " .. name .. ": no such sound in soundbank")
		return
	end
	love.audio.play(soundbank.sounds[name])
end

-- create a Soundbank object
function new()

	local o = {}
	o.sounds = init_sounds()

	-- methods
	o.play = play

	return o
end
