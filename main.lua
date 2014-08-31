require 'trace'
require 'strict'
require 'player'
require 'local_player'
require 'computer_player'
require 'player_display'
require 'bullet'
require 'player_sound'

print = trace.print;
math.randomseed(os.time()) 

g_key_state = {run = false, left = false, right = false, down = false, melee = false, fire = false, shield = false}
g_key_map = { a = 'run', left = 'left', right = 'right', down = 'down', s = 'melee', d = 'fire', [' '] = 'down'}

g_camera_x = 0;
g_camera_y = 0;

g_map_w = 3000;
g_map_h = 2000;

g_player = {}
g_bg = {}
g_bullets = {}
g_npc = {}
g_explode = {}

function new_delegate()
	local obj = {}
	local m_reciver;
	local m_func;

	obj.set = function(reciver, _func)
		assert(type(reciver) == 'table');
		assert(type(_func) == 'string');
		m_reciver = reciver;
		m_func = _func;
	end

	obj.invoke = function(...)
		if m_reciver and m_func then
			return m_reciver[m_func](...);
		end
	end
	
	return obj;
end

function new_image_cache()
	local cache = {}
	
	return function(path)
		if not cache[path] then
			cache[path] = love.graphics.newImage(path)
		end
		return cache[path]
	end
end

g_load_image = new_image_cache();

-- 包装的东西太少好像没什么用
function new_timer()
	local obj = {}
	local m_time;
	local m_duration;
	
	obj.update = function(dt)
		m_time = m_time + dt;
	end
	obj.alarm = function()
		return m_time > m_duration;
	end
	obj.reset = function()
		m_time = 0;
	end
end

function new_background()
	local bg = {}
	local m_image = g_load_image("bg02.png");
	local m_tile_w = m_image:getWidth();
	local m_tile_h = m_image:getHeight();
	
	bg.draw = function ()
		local graphics = love.graphics;
		graphics.setColor(255, 255, 255);
		local width, height = graphics.getDimensions();
		local ox = g_camera_x % m_tile_w;
		local oy = g_camera_y % m_tile_h;
		for i = 0, width / m_tile_w + 1 do
			for j = 0, height / m_tile_h + 1 do
				graphics.draw(m_image, i * m_tile_w - ox, j * m_tile_h - oy);
			end
		end
	end
	
	return bg;
end

function new_explode(m_x, m_y)
	local obj = {}
	local m_timer = 0;
	local m_state = 1;
	local m_destroy = false; 
	local m_inertia_x = 0;
	local m_inertia_y = 0;
	local m_img = {}
	local m_sound = love.audio.newSource("explode01.wav", "static")
	
	do
		table.insert(m_img, g_load_image("explode01.png"));
		table.insert(m_img, g_load_image("explode02.png"));
		table.insert(m_img, g_load_image("explode03.png"));
		local angle = g_player.get_angle();
		m_inertia_x = math.cos(angle) * 800;
		m_inertia_y = math.sin(angle) * 800;
		love.audio.play(m_sound)
	end
	
	obj.is_destroy = function() return m_destroy end
	
	obj.draw = function()
		if m_state <= 3 then
			local graphics = love.graphics;
			local img = m_img[m_state]
			local iw, ih = img:getDimensions()
			graphics.setColor(255,255, 255);
			graphics.draw(img,
				m_x - g_camera_x, m_y - g_camera_y,
				0, 1, 1,
				iw/2, ih/2);
		end
	end
	
	local update_inertia = function(inertia, dt)
		if inertia > 0 then
			inertia = inertia - 250 * dt;
			if inertia < 0 then
				inertia = 0;
			end
		end
		if inertia < 0 then
			inertia = inertia + 250 * dt;
			if inertia > 0 then
				inertia = 0;
			end
		end
		return inertia;
	end
	
	obj.update = function(dt)
		m_timer = m_timer + dt;
		if m_timer > 0.2 then
			m_timer = 0;
			m_state = m_state + 1;
		end
		if m_state > 3 then
			m_destroy = true
		end
		m_inertia_x = update_inertia(m_inertia_x, dt);
		m_inertia_y = update_inertia(m_inertia_y, dt);
		m_x = m_x + m_inertia_x * dt;
		m_y = m_y + m_inertia_y * dt;
	end
	return obj;
end

function love.load()
   g_player = new_local_player();
	-- for i = 1, 100 do
		-- table.insert(g_npc, new_computer_player());
	-- end
   g_bg = new_background();
   love.graphics.setNewFont(12)
   love.graphics.setBackgroundColor(255,255,255)
end

g_npc_spawn_timer = 0;

function love.update(dt)
	g_npc_spawn_timer = g_npc_spawn_timer + dt;
	if g_npc_spawn_timer > 5 then
		g_npc_spawn_timer = 0;
		if #g_npc < 100 then
			table.insert(g_npc, new_computer_player());
		end
	end
	
	g_player.update(dt);
	if g_player.is_destroy() then
		g_player.respawn()
	end
	for idx, bullet in ipairs(g_bullets) do
		bullet.update(dt);
		if bullet.is_destroy() then
			table.remove(g_bullets, idx);
		end
	end
	for idx, cplayer in ipairs(g_npc) do
		cplayer.update(dt);
		cplayer.collision(idx);
		if cplayer.is_destroy() then
			local x,y = cplayer.get_position();
			table.remove(g_npc, idx);
			table.insert(g_explode, new_explode(x,y));
			g_player.gain_hp(20);
		end
	end
	for idx, explode in ipairs(g_explode) do
		explode.update(dt);
	end
end

function love.draw()
	g_bg.draw();

	trace.draw()

	local graphics = love.graphics;
	local sw, sh = graphics.getDimensions();

	-- 边界
	if g_camera_x + sw > g_map_w then
		graphics.line(g_map_w - g_camera_x, 0, g_map_w - g_camera_x, sh - 1);
	end
	if g_camera_y + sh > g_map_h then
		graphics.line(0, g_map_h - g_camera_y, sw - 1, g_map_h - g_camera_y);
	end
	if g_camera_x < 0 then
		graphics.line(- g_camera_x, 0, - g_camera_x, sh -1);
	end
	if g_camera_y < 0 then
		graphics.line(0, - g_camera_y, sw - 1, - g_camera_y);
	end
	-- bullet
	for k,v in ipairs(g_bullets) do
		v.draw();
	end
	-- NPC
	for idx, cplayer in ipairs(g_npc) do
		cplayer.draw();
	end
	for idx, explode in ipairs(g_explode) do
		explode.draw();
	end
	g_player.draw();
	graphics.setColor(0,255,0);
	graphics.print("FPS: "..tostring(love.timer.getFPS( )), sw - 50, 10)
end

function love.keypressed(key)
	local action = g_key_map[key]
	if action ~= nil then
		g_key_state[action] = true;
	end
end

function love.keyreleased(key)
	local action = g_key_map[key]
	if action ~= nil then
		g_key_state[action] = false;
	end
end