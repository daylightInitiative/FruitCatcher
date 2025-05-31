local math = require("math")

local util = {}

function util.math_clamp(_in, low, high)
	return math.min(math.max( _in, low ), high)
end

function util.checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function util.table_find(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

function util.table_concat(t1,t2)
    -- iterate through the second table
    for i = 1, #t2 do
	    -- t1[len+1] = t2[i]
		-- this works since tables in lua are mutable
        t1[#t1+1] = t2[i]
    end
    return t1
end

function util.isnumber(n)
	return type(n) == "number"
end

function util.PrintTable(t1, indent, depth)
	space_amount = indent or 4 -- default

	table.sort(t1, function(a, b)
		if ( util.isnumber( a ) and util.isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	for k, v in pairs(t1) do
		
		print(string.rep(" ", space_amount), k, v)

		if type(v) == "table" then
			-- we could recurse here but we probably dont need this
			space_amount = space_amount + 4
			--PrintTable()

			table.sort(v, function(a, b)
				if ( util.isnumber( a ) and util.isnumber( b ) ) then return a < b end
				return tostring( a ) < tostring( b )
			end )

			for k, v in pairs(v) do
		
				print(string.rep(" ", space_amount), k, v)

			end
		end

	end
end

return util