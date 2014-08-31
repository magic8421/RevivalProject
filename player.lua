function new_player(_type, key_state, sound_obj)
	local player = {}
	local m_type = _type;
	local m_sound_obj = sound_obj;
	local m_x, m_y = math.random(g_map_w), math.random(g_map_h);
	local m_radius = 30;
	local m_angle = math.random(0, 2 * math.pi);
	local m_rotate_acc = 2.5 * math.pi;
	local m_rotate_speed = 0;
	local m_rotate_friction = 8 * math.pi;
	local m_rotate_max = 1.5 * math.pi;
	local m_speed = 0;
	local m_accelerate = 230;
	local m_max_speed = 500; -- 单位: 秒/像素
	local m_friction = 250;
	local m_fire_timer = 0;
	local m_melee_timer = 0;
	local m_melee_state = 0;
	local m_key_state = key_state;
	local m_hp = 100;
	local m_hurt_timer = 0;
	local m_destroy = false;
	local m_inertia_x = 0;
	local m_inertia_y = 0;
	local m_shield = false;
	local m_shield_timer = 0;

	local abs, sqrt, cos, sin = math.abs, math.sqrt, math.cos, math.sin;
	local pi = math.pi;
	do
		if m_type == 'npc' then
			m_max_speed = m_max_speed * 0.6;
			m_accelerate = m_accelerate * 0.6;
		end
	end

	-- player.sound_sword = new_delegate();
	-- player.sound_shield = new_delegate();
	-- player.sound_fire = new_delegate();
	
	player.get_position = function() return m_x, m_y; end
	player.get_angle = function() return m_angle; end
	player.get_border_ratio = function()
		local speed_x = m_speed * cos(m_angle);
		local speed_y = m_speed * sin(m_angle);
		return 0.5 - speed_x / m_max_speed * 0.15,
			0.5 - speed_y / m_max_speed * 0.15;
	end
	player.get_radius = function() return m_radius; end
	player.get_melee_state = function() return m_melee_state; end
	player.get_hp = function() return m_hp; end
	player.is_hurt = function() return m_hurt_timer > 0 end
	player.is_destroy = function() return m_destroy end
	player.is_shield = function() return m_shield end
	
	player.set_angle = function(an)
		m_angle = an;
	end
	
	player.offset = function(x, y)
		m_x = m_x + x;
		m_y = m_y + y;
	end

	player.collision = function (other)
		local x1, y1 = m_x, m_y;
		local x2, y2 = other.get_position();
		local tolerance = 10;

		if abs(x1 - x2) > m_radius * 2 + tolerance or
			abs(y1 - y2) > m_radius * 2 + tolerance then
			return;
		end
		if sqrt((x2 - m_x)^2 + (y2 - m_y)^2) < m_radius * 2 then
			-- 用向量的方法做排斥力
			local d1 = sqrt((x1 - x2)^2 + (y1 - y2)^2)
			local d2 = (2 * m_radius - d1) / 2;
			local a1 = x1 - x2;
			local a2 = y1 - y2;
			local b1 = a1 * d2 / d1;
			local b2 = a2 * d2 / d1;
			player.offset(b1, b2);
			other.offset(-b1,-b2);
		end
	end
	
	local melee_collision = function (ox, oy, distance)
		local angle;
		if sqrt((ox - m_x)^2 + (oy - m_y)^2) < distance then
			angle = math.atan2((oy - m_y), (ox - m_x))
			if angle < 0 then
				angle = 2 * pi + angle;
			end
			local diff_ang = abs(m_angle - angle)
			if diff_ang < pi * 0.4 or diff_ang > pi * 1.6 then
				return true
			end
		end
		return false;
	end
	
	player.melee = function(other, dt)
		if other.is_hurt() or m_melee_state ~= 2 then
			return;
		end
		local ox, oy = other.get_position();
		local distance = 120;
		if melee_collision(ox, oy, distance) then
			other.damage(20, m_angle, 400);
		end
		if m_type == 'player' then
			for k,v in ipairs(g_bullets) do
				local x,y = v.get_position();
				if not v.is_destroy() and v.get_type() == 'npc'
					and melee_collision(x, y, 90) then
						v.destroy();
					-- print('cut');
				end
			end
		end
	end
	
	player.update = function(dt)
		-- 旋转
		m_angle = m_angle + dt * m_rotate_speed;
		m_angle = m_angle % (pi * 2);
		if m_key_state.right then
			m_rotate_speed = m_rotate_speed + m_rotate_acc * dt;
			if m_rotate_speed > m_rotate_max then
				m_rotate_speed = m_rotate_max;
			end
		end
		if m_key_state.left then
			m_rotate_speed = m_rotate_speed - m_rotate_acc * dt;
			if m_rotate_speed < -m_rotate_max then
				m_rotate_speed = -m_rotate_max;
			end
		end
		if not m_key_state.right and not m_key_state.left then
			if m_rotate_speed > 0 then
				m_rotate_speed = m_rotate_speed - m_rotate_friction * dt;
				if m_rotate_speed < 0 then
					m_rotate_speed = 0;
				end
			end
			if m_rotate_speed < 0 then
				m_rotate_speed = m_rotate_speed + m_rotate_friction * dt;
				if m_rotate_speed > 0 then
					m_rotate_speed = 0;
				end
			end
		end
		
		-- 加速度
		if m_key_state.run and not m_key_state.down then
			m_speed = m_speed + dt * m_accelerate;
		end
		
		-- 防御
		m_shield_timer = m_shield_timer + dt;
		if m_key_state.down then
			m_speed = m_speed - dt * (m_accelerate + m_friction);
			if m_shield == false and m_shield_timer > 0.4 then
				m_shield = true;
				m_shield_timer = 0;
			end
		end
		if m_shield == true and m_shield_timer > 0.4 then
			m_shield = false;
			m_shield_timer = 0;
		end
		
		-- if not m_key_state.run and not m_key_state.down then
			m_x = m_x + m_inertia_x * dt;
			m_y = m_y + m_inertia_y * dt;
		-- end
		-- 射击
		m_fire_timer = m_fire_timer + dt;
		if m_key_state.fire and m_fire_timer > 0.7 and m_melee_state == 0 and
			m_melee_timer > 0.3 then
			table.insert(g_bullets, new_bullet(m_type, m_x, m_y, m_angle, 400));
			if m_sound_obj then
				m_sound_obj.fire();
			end
			m_fire_timer = 0;
		end
		-- 近战
		m_melee_timer = m_melee_timer + dt;
		if m_key_state.melee and m_melee_state == 0 and m_melee_timer > 0.3
			and not m_key_state.fire then
			m_melee_state = 1
			m_melee_timer = 0;
		end
		if m_melee_state ~= 0 then
			if m_melee_timer > 0.1 then
				m_melee_timer = 0;
				m_melee_state = m_melee_state + 1;
				if m_melee_state > 3 then
					m_melee_state = 0;
				end
			end
		end
		if m_melee_state == 1 then
			if m_sound_obj then
				m_sound_obj.sword();
			end
		end
		-- 摩擦力
		if not m_key_state.run and not m_key_state.down then
			m_speed = m_speed - dt * m_friction;
		end
		if m_speed < 0 then
			m_speed = 0
		elseif m_speed > m_max_speed then
			m_speed = m_max_speed;
		end
		-- 移动
		-- X
		if m_hurt_timer == 0 then
			m_x = m_x + cos(m_angle) * m_speed * dt;
			m_y = m_y + sin(m_angle) * m_speed * dt;
		end
		if m_x + m_radius > g_map_w then
			m_x = g_map_w - m_radius;
		end
		if m_x - m_radius < 0 then
			m_x = m_radius;
		end
		if m_y + m_radius > g_map_h then
			m_y = g_map_h - m_radius;
		end
		if m_y - m_radius < 0 then
			m_y = m_radius;
		end
		
		-- 被攻击之后的滑动
		if m_inertia_x > 0 then
			m_inertia_x = m_inertia_x - m_friction * dt;
			if m_inertia_x < 0 then
				m_inertia_x = 0;
			end
		end
		if m_inertia_x < 0 then
			m_inertia_x = m_inertia_x + m_friction * dt;
			if m_inertia_x > 0 then
				m_inertia_x = 0;
			end
		end
		if m_inertia_y > 0 then
			m_inertia_y = m_inertia_y - m_friction * dt;
			if m_inertia_y < 0 then
				m_inertia_y = 0;
			end
		end
		if m_inertia_y < 0 then
			m_inertia_y = m_inertia_y + m_friction * dt;
			if m_inertia_y > 0 then
				m_inertia_y = 0;
			end
		end
		
		-- 被攻击停顿
		if m_hurt_timer > 0 then
			m_hurt_timer = m_hurt_timer - dt;
			if m_hurt_timer < 0 then
				m_hurt_timer = 0;
			end
		end
	end
	
	player.damage = function (hp, angle, energy)
		if m_shield then
			-- TODO 防御成功也有动量
			if m_sound_obj then
				m_sound_obj.shield();
			end
			return;
		end
		m_inertia_x = m_inertia_x + cos(angle) * energy;
		m_inertia_y = m_inertia_y + sin(angle) * energy;
		
		m_hurt_timer = 0.2;
		-- if m_shield == false then
			m_hp = m_hp - hp;
		-- end
		if m_hp < 0 then
			m_hp = 0
		end
		if m_hp == 0 then
			m_destroy = true;
		end
	end
	
	player.respawn = function()
		m_hp = 100;
		m_x, m_y = math.random(g_map_w), math.random(g_map_h);
		m_destroy = false;
	end
	
	player.gain_hp = function(hp)
		assert(hp > 0)
		m_hp = m_hp + hp
		if m_hp > 100 then
			m_hp = 100;
		end
	end
	return player;
end
