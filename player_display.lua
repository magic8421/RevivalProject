function new_player_display(key_state, _super, _type)
	local obj = {}
	local super = _super;
	local m_key_state = key_state;
	local m_image;
	local m_flame_img = g_load_image("flame01.png");
	local m_width
	local m_height
	local m_melee_img = {}
	table.insert(m_melee_img, g_load_image("melee01.png"));
	table.insert(m_melee_img, g_load_image("melee02.png"));
	table.insert(m_melee_img, g_load_image("melee03.png"));
	local m_shield_img = g_load_image("shield01.png");
	local m_hurt_img = g_load_image("hurt01.png");
	local m_arrow_img = g_load_image("arrow01.png");
	
	do
		if _type == 'player' then
			m_image = g_load_image("ship02.png");
		elseif _type == 'npc' then
			m_image = g_load_image("ship01.png");
		end
		m_width = m_image:getWidth();
		m_height = m_image:getHeight();
	end
	
	obj.draw = function()
		local m_x, m_y = super.get_position();
		local m_angle = super.get_angle();
		local graphics = love.graphics;
		graphics.setColor(255, 255, 255);
		graphics.draw(m_image, 
			m_x - g_camera_x, m_y - g_camera_y, -- position
			m_angle, 1, 1, -- angle scale
			m_width / 2, m_height / 2); -- offset
		local fw, fh = m_flame_img:getDimensions();
		if m_key_state.run and not m_key_state.down then
			graphics.draw(m_flame_img, 
			m_x - g_camera_x, m_y - g_camera_y, 
			m_angle, 1, 1, 
			46, 18);
		end
		if m_key_state.down then
			graphics.draw(m_flame_img, 
			m_x - g_camera_x, m_y - g_camera_y, 
			m_angle + math.pi, 1, 1, 
			46, 18);
		end
		local melee = super.get_melee_state();
		if melee ~= 0 then
			graphics.draw(m_melee_img[melee],
				m_x - g_camera_x, m_y - g_camera_y, -- position
				m_angle + math.pi / 2, 1, 1,
				75, 100);
		end
		local hp_w = 60;
		graphics.setColor(255,255, 0);
		local x = m_x - g_camera_x - 27;
		local y = m_y - g_camera_y + 40;
		graphics.line(x, y,	x + hp_w * super.get_hp() / 100, y);
		
		if super.is_shield() then
			local iw, ih = m_shield_img:getDimensions()
			graphics.setColor(255,255, 255);
			graphics.draw(m_shield_img,
				m_x - g_camera_x, m_y - g_camera_y,
				0, 1, 1,
				iw/2, ih/2);
		end
		
		if super.is_hurt() then
			local iw, ih = m_hurt_img:getDimensions()
			graphics.setColor(255,255, 255);
			graphics.draw(m_hurt_img,
				m_x - g_camera_x, m_y - g_camera_y,
				0, 1, 1,
				iw/2, ih/2);
		end
		
		if _type == 'player' then
			local iw, ih = m_arrow_img:getDimensions()
			graphics.setColor(255,255, 255);
			graphics.draw(m_arrow_img,
				m_x - g_camera_x, m_y - g_camera_y,
				m_angle + math.pi / 2, 1, 1,
				iw/2, ih + 30);
		end
	end
	
	return obj;
end
