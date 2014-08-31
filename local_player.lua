function new_local_player()
	local lplayer = {}
	local super = new_player('player', g_key_state, new_player_sound());
	local m_display = new_player_display(g_key_state, super, 'player');
	
	lplayer.draw = function()
		m_display.draw();
	end
	
	lplayer.update = function(dt)
		super.update(dt)
		
		for idx, npc in ipairs(g_npc) do
			super.collision(npc);
		end
		
		for idx, npc in ipairs(g_npc) do
			super.melee(npc, dt);
		end
		local sw, sh = love.graphics.getDimensions();
		local border_ratio_x, border_ratio_y = super.get_border_ratio();
		local px,py = super.get_position();
		-- if px - g_camera_x > sw * (1 - border_ratio) then
			g_camera_x = px - sw * border_ratio_x;
		-- end
		-- if px - g_camera_x < sw * border_ratio then
			-- g_camera_x = px - sw * border_ratio;
		-- end
		-- if py - g_camera_y > sh * (1 - border_ratio) then
			g_camera_y = py - sh * border_ratio_y;
		-- end
		-- if py - g_camera_y < sh * border_ratio then
			-- g_camera_y = py - sh * border_ratio;
		-- end
	end
	
	lplayer.__index = super;
	setmetatable(lplayer, lplayer);
	return lplayer;
end
