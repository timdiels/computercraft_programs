Queue = Object:new()

-- queue of vectors
function Queue:new()
	local obj = Object.new(self)
	obj.first = 0
	obj.last = -1
	return obj
end

function Queue:from_table(t)
	local q = Queue:new()
	table.merge(q, t)
	for i = q.first, q.last do
		q[i] = vector.from_table(q[i])
	end
	return q
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