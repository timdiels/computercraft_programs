
local _new = vector.new
function vector.new(...)
	local obj = _new(unpack(arg))
	obj.__TYPE = 'vector'
	return obj
end

function vector.copy(t)
	return Vector:from_table(t)
end

Vector = Object:new()
__TYPES['vector'] = Vector

function Vector:from_table(t)
	return vector.new(t.x, t.y, t.z)
end