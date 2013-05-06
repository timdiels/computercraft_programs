-- Keeps track of what has been built and needs to be built

-- ENSURE: At any point in time, program must be able to handle being aborted and restarted

-- Note: the lingo of this file considers a chunk a 16x16x16 block; this hampers scavengers from understanding this code
-- chunk coords = floor(regular coords / CHUNK_SIZE)

catch(function()

local CHUNK_SIZE = 16

BuildSystem = Object:new()
BuildSystem._STATE_FILE = "/build_system.state"
BuildSystem._MAX_HEIGHT = 13 -- chunks have to be built within these height bounds (in chunk coords)
BuildSystem._MIN_HEIGHT = 5


-- home_pos and last_pos are in chunk coords
-- _x_offset: x offset withing current chunk that is being built
-- _z_offset: z offset withing current chunk that is being built
-- build_queue: queue of chunks to build

function BuildSystem:new()
	local obj = Object.new(self)
	obj:_load()
	return obj
end

-- Load from file
function BuildSystem:_load()
	-- load persistent things
	local state = io.from_file(self._STATE_FILE)
	if state then
		table.merge(self, state)
	else
		self._home_chunk = gps_.persistent_locate()
		self._home_chunk.x = math.floor(self._home_chunk.x / CHUNK_SIZE)
		self._home_chunk.y = (BuildSystem._MAX_HEIGHT + BuildSystem._MIN_HEIGHT) / 2
		self._home_chunk.z = math.floor(self._home_chunk.z / CHUNK_SIZE)
		assert(self._home_chunk.y == math.floor(self._home_chunk.y))
		
		self._radius = 0
		self._build_queue = Queue:new()
		self._build_queue:push_back(vector.copy(self._home_chunk))
		self:_next_chunk()
		
		self:_save()
	end
end

-- Save state to file
function BuildSystem:_save()
	io.to_file(self._STATE_FILE, {
		_home_chunk = self._home_chunk,
		_current_chunk = self._current_chunk,
		_radius = self._radius,
		_x_offset = self._x_offset,
		_z_offset = self._z_offset,
		_build_queue = self._build_queue,
	})
end

-- returns next available mining pos and considers it assigned to whoever requested it
function BuildSystem:get_next()
	local finished_chunk = self._x_offset == CHUNK_SIZE-1 and self._z_offset == CHUNK_SIZE-1
	if finished_chunk then
		self:_next_chunk()
	end
	
	-- pos within a chunk
	if self._z_offset == CHUNK_SIZE - 1 then
		-- next line
		self._x_offset = self._x_offset + 1
		self._z_offset = -1
	end
	self._z_offset = self._z_offset + 1
	
	self:_save()
	
	local pos = self._current_chunk * CHUNK_SIZE
	pos.x = pos.x + self._x_offset
	pos.z = pos.z + self._z_offset
	return pos
end

-- move to next chunk
function BuildSystem:_next_chunk()
	if self._build_queue:is_empty() then
		self:_generate_next_build_queue()
	end
	
	self._current_chunk = self._build_queue:pop_front()
	self._x_offset = 0
	self._z_offset = -1
end

function BuildSystem:_generate_next_build_queue()
	self._radius = self._radius + 2
	
	local max_y = self._home_chunk.y + self._radius
	if max_y <= self._MAX_HEIGHT then
		for radius = 0, self._radius, 2 do
			self:_build_square(max_y, radius)
		end
		max_y = max_y - 1
	else
		max_y = MAX_HEIGHT
	end
	
	local min_y = self._home_chunk.y - self._radius
	if min_y <= self._MAX_HEIGHT then
		for radius = 0, self._radius, 2 do
			self:_build_square(min_y, radius)
		end
		min_y = min_y - 1
	else
		min_y = MAX_HEIGHT
	end
	
	for y = max_y, min_y, -2 do
		self:_build_square(y, self._radius)
	end
end

-- queue chunks in clockwise order for building
function BuildSystem:_build_square(y, radius)
	require_(radius % 2 == 0)
	
	if radius == 0 then
		local chunk = vector.copy(self._home_chunk)
		chunk.y = y
		self._build_queue:push_back(chunk)
	else	
		local right = self._home_chunk.x + radius
		local left = self._home_chunk.x - radius
		local top = self._home_chunk.z - radius
		local bottom = self._home_chunk.z + radius
		
		for x = left, right-2, 2 do
			self._build_queue:push_back(vector.new(x, y, top))
		end
		
		for z = top, bottom, 2 do
			self._build_queue:push_back(vector.new(right, y, z))
		end
		
		for x = right, left+2, -2 do
			self._build_queue:push_back(vector.new(x, y, bottom))
		end
		
		for z = bottom, top, -2 do
			self._build_queue:push_back(vector.new(left, y, z))
		end
	end
end
	
end)