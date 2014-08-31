
function new_computer_player()
	local cplayer = {}
	local m_key_state = {run = false, fire = false, left = false, right = false}
	local super = new_player('npc', m_key_state, new_player_sound());
	local m_display = new_player_display(m_key_state, super, 'npc');
	
	local random = math.random;
	local m_run_timer = random(10);
	local m_fire_timer = random(10);
	local m_melee_timer = random(3);
	local m_shield_timer = random(1);

	local distance = function(x1, y1, x2, y2)
		return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
	end
	
	cplayer.update = function(dt)
		local x1,y1 = g_player.get_position();
		local x2,y2 = super.get_position();
		
		-- 跑
		m_run_timer = m_run_timer + dt;
		if m_run_timer > 10 then
			if random() > 0.93 then
				m_key_state.run = true;
			else
				m_key_state.run = false;
			end
			m_run_timer = 0;
		end
		
		if distance(x1, y1, x2, y2) < 300 then
			m_key_state.run = true;
		end
		
		-- 开火
		m_fire_timer = m_fire_timer + dt;
		if m_fire_timer > 5 then
			if random() < 0.4 and distance(x1,y1,x2,y2) < 400 and not m_key_state.run then
				m_key_state.fire = true;
			end
			m_fire_timer = 0;
		else
			m_key_state.fire = false;
		end
		
		-- 近战
		super.melee(g_player, dt);
		m_melee_timer = m_melee_timer + dt;
		if distance(x1,y1,x2,y2) < 100 then
			if m_melee_timer > 3 then
				if random() < 0.3 then
					m_key_state.melee = true;
				end
				if random() < 0.3 then
					m_key_state.down = true;
				end
				m_melee_timer = 0;
			end
		else
			m_key_state.melee = false;
			m_key_state.down = false;
		end
		
		-- 防御远程
		m_shield_timer = m_shield_timer + dt
		for k,v in ipairs(g_bullets) do
			if v.get_type() == 'player' then
				local bx,by = v.get_position();
				local px,py = super.get_position();
				if distance(bx, by, px, py) < 60  then
					if random() < 0.4 and m_shield_timer > 2 then
						m_key_state.down = true;
						m_shield_timer = 0;
					else
						m_key_state.down = false;
					end
				else
					m_key_state.down = false;
				end
			end
		end
		
		
		-- 方向
		local pi = math.pi;
		local px, py = g_player.get_position()
		local mx, my = super.get_position()
		local angle = math.atan2((py - my), (px - mx))
		-- if angle < 0 then
			-- angle = 2 * pi + angle;
		-- end
		-- local m_angle = super.get_angle();
		-- m_angle = m_angle % (pi * 2);
		-- print ('m:'..m_angle..' o:'..angle);
		-- if m_angle > angle then
			-- m_key_state.left = false;
			-- m_key_state.right = true;
		-- else
			-- m_key_state.left = true;
			-- m_key_state.right = false;
		-- end
		super.set_angle(angle);
		super.update(dt);
	end
	
	cplayer.draw = function()
		m_display.draw();
	end
	
	cplayer.get_super = function()
		return super;
	end
	
	cplayer.collision = function(i)
		-- 是组合不是排列 所以
		for j = i + 1, #g_npc do
			local other = g_npc[j];
			super.collision(other);
		end
	end
	
	cplayer.__index = super;
	setmetatable(cplayer, cplayer);
	return cplayer;
end
