-- Titan, orders all Drones

-- REQUIRES: is at least a computer, with modem on top
-- ENSURE: At any point in time, handle server crashes well

catch(function()

Titan = Object:new()
Titan._STATE_FILE = "/titan.state"

function Titan:new()
	local obj = Object.new(self)
	obj:_load()
	return obj
end

function Titan:_load()
	self._home_pos = gps_.persistent_locate()
	self._home_chunk = vector.new(
		math.floor(self._home_pos.x / CHUNK_SIZE),
		math.floor(self._home_pos.y / CHUNK_SIZE),
		math.floor(self._home_pos.z / CHUNK_SIZE)
	)
	
	self._mining_system = MiningSystem:new()
	self._build_system = BuildSystem:new(self._mining_system)
	self._garbage_system = GarbageSystem:new()
end

function Titan:_send(destination, contents)
	local msg = {user='limyreth'}
	msg.contents = contents
	msg = textutils.serialize(msg)
	rednet.send(destination, msg);
end

-- Returns position nearest to given pos where there is guaranteed free space (i.e. mined out and has no chunks built there)
function Titan:_get_nearest_free_pos(pos)
	local chunk = pos
	chunk.x = math.floor(chunk.x / CHUNK_SIZE)
	chunk.z = math.floor(chunk.z / CHUNK_SIZE)
	
	local dc = self._home_chunk - chunk
	if chunk.x % 2 == self._home_chunk.x % 2 then
		-- we're not in empty chunk x-wise
		if dc.x > 0 then
			chunk.x = chunk.x + 1
		else
			chunk.x = chunk.x - 1
		end
	end
	
	if chunk.z % 2 == self._home_chunk.z % 2 then
		-- we're not in empty chunk z-wise
		if dc.z > 0 then
			chunk.z = chunk.z + 1
		else
			chunk.z = chunk.z - 1
		end
	end
	
	if not self._mining_system:is_chunk_mined(chunk) then
		return pos
	end
	
	pos.x = chunk.x * CHUNK_SIZE
	pos.z = chunk.z * CHUNK_SIZE
	
	return pos
end

function Titan:run()
	rednet.open('top')
	while true do
		local sender, msg, distance = rednet.receive()
		msg = textutils.unserialize(msg)
		if msg.user == 'limyreth' then
			self._mining_system:finished_mining(sender)
			if msg.contents.type == 'nearest_free_pos_request' then
				self:_send(sender, self:_get_nearest_free_pos(msg.contents.drone_pos))
			elseif msg.contents.type == 'drop_request' then
				self:_send(sender, self._garbage_system:get_next())
			elseif msg.contents.type == 'mine_request' then
				self:_send(sender, self._mining_system:get_next(sender))
			elseif msg.contents.type == 'build_request' then
				self:_send(sender, self._build_system:get_next())  --TODO if builders exhaust materials slower than miners, than we'll occasionally have to have them dump their materials in the lava pit
			else
				assert(false)
			end
		end
	end
end

end)