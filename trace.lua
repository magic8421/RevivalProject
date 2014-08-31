-- http://yal.cc/love2d-simple-logger/

trace = {
	textl = { },
	count = 0,
	limit = 32
}

function trace.print(text)
	-- local text = "";
	-- for k,v in ipairs(arg) do
		-- if type(v) == 'number' or type(v) == 'string' then
			-- text = text .. tostring(v);
		-- elseif type(v) == 'boolean' then
			-- if v then
				-- text = text .. '(true)';
			-- else
				-- text = text .. '(false)';
			-- end 
		-- else
			-- text = text .. '('.. type(v) .. ')';
		-- end
		-- text = text .. v;
	-- end

	if (trace.count > trace.limit) then -- scroll elements
		table.remove(trace.textl, 1)
	else -- add element
		trace.count = trace.count + 1
	end -- write data:
	trace.textl[trace.count] = text
end

function trace.draw(x, y)
	local i, z, prefix
	prefix = '' 
	-- default position parameters:
	if (x == nil) then x = 16 end
	if (y == nil) then y = 16 end
	-- draw lines:
	for i = 1, trace.count do
		z = prefix .. trace.textl[i] -- string to draw
		-- z = prefix .. 'test'
		-- choose white/black outline:

		love.graphics.setColor(128, 128, 128)

		-- draw outline:
		love.graphics.print(z, x + 1, y)
		love.graphics.print(z, x - 1, y)
		love.graphics.print(z, x, y + 1)
		love.graphics.print(z, x, y - 1)
		-- draw color:
		love.graphics.setColor(255, 255, 255)
		love.graphics.print(z, x, y)
		-- concatenate prefix:
		prefix = prefix .. '\n'
	end
end