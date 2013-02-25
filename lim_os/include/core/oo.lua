Object = {}

-- self is the object, not its metatable
function Object.__index_func(self, key)
	local value = getmetatable(self)[key]
	if type(value) == "function" then
		-- assume it's not a static function, we don't support those currently
		function method(...)
			return value(self, unpack(arg))
		end
		return method
	else
		return value
	end
end

function Object:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = Object.__index_func
	return obj
end