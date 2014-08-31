function new_player_sound()
	local obj = {}
	-- TODO 共用一个data source
	local m_sound_sword = love.audio.newSource("sword01.wav", "static")
	local m_sound_shield = love.audio.newSource("shield01.wav", "static")
	local m_sound_fire = love.audio.newSource("fire01.wav", "static")
	
	obj.sword = function()
		love.audio.play(m_sound_sword);
	end
	
	obj.shield = function()
		love.audio.play(m_sound_shield);
	end
	
	obj.fire = function()
		love.audio.play(m_sound_fire);
	end
	
	return obj;
end