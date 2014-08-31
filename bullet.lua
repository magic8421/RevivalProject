function new_bullet(_type, x, y, angle, speed)
	local bullet = {}
	local m_image = g_load_image("bullet01.png");
	local m_iw, m_ih = m_image:getDimensions();
	local m_x = x;
	local m_y = y;
	local m_angle = angle;
	local m_speed = speed;
	local m_destroy = false;
	local m_type = _type;
	
	bullet.get_position = function() return m_x, m_y end
	
	local collisio_each = function(other)
		local nx,ny = other.get_position();
		local dist = math.sqrt((m_x - nx) ^ 2 + (m_y - ny) ^ 2);
		if dist < other.get_radius() then
			return true
		else
			return false;
		end
	end
	
	local collision = function()
		if m_type == 'player' then
			for idx, npc in ipairs(g_npc) do
				if collisio_each(npc) then
					npc.damage(20, m_angle, 200);
					m_destroy = true;
				end
			end
		elseif m_type == 'npc' then
			if collisio_each(g_player) then
				g_player.damage(10, m_angle, 200);
				m_destroy = true;
			end
		end
	end
	
	bullet.update = function(dt)
		m_x = m_x + math.cos(m_angle) * m_speed * dt;
		if m_x < 0 or m_x > g_map_w then
			m_destroy = true;
		end
		m_y = m_y + math.sin(m_angle) * m_speed * dt;
		if m_y < 0 or m_y > g_map_h then
			m_destroy = true;
		end
		collision();
	end
	
	bullet.draw = function()
		local graphics = love.graphics;
		graphics.draw(m_image, m_x - g_camera_x, m_y - g_camera_y, m_angle, 1, 1, 0, m_ih / 2);
	end
	
	bullet.is_destroy = function()
		return m_destroy;
	end
	
	bullet.destroy = function()
		m_destroy = true;
	end
	
	bullet.get_type = function()
		return m_type;
	end

	return bullet;
end
