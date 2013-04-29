Queue = Object:new()

function Queue:new()
	return {first = 0, last = -1}
end

function Queue:push_front(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

function Queue:push_back(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

function Queue:pop_front()
	local first = self.first
	if first > self.last then error("self is empty") end
	local value = self[first]
	self[first] = nil        -- to allow garbage collection
	self.first = first + 1
	return value
end

function Queue:pop_back()
	local last = self.last
	if self.first > last then error("self is empty") end
	local value = self[last]
	self[last] = nil         -- to allow garbage collection
	self.last = last - 1
	return value
end

function Queue:is_empty()
	return self.first > self.last
end