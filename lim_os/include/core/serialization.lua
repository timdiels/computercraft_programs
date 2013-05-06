
__TYPES = {}

function textutils.objectify(t)
	if type(t) == 'table' then	
		for k, v in pairs(t) do
			if k ~= '__TYPE' then
				t[k] = textutils.objectify(v)
			end
		end
		
		if t.__TYPE ~= nil then
			t = __TYPES[t.__TYPE]:from_table(t)
		end
	end
	
	return t
end

local unserialize_ = textutils.unserialize
function textutils.unserialize(str)
	local t = unserialize_(str)
	return textutils.objectify(t)
end