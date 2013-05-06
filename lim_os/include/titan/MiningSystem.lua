-- Keeps track of what parts of planet have been mined

-- ENSURE: At any point in time, program must be able to handle being aborted and restarted

catch(function()

MiningSystem = Object:new()
MiningSystem._STATE_FILE = "/mining_system.state"

function MiningSystem:new(home_pos)
	local obj = Object.new(self)
	self._home_pos = vector.copy(home_pos)
	obj:_load()
	return obj
end

-- Load from file
function MiningSystem:_load()
	-- load persistent things
	local state = io.from_file(self._STATE_FILE)
	if state then
		table.merge(self, state)
	else
		self._last_pos = nil  -- last issued position
		self._issued_positions = {}  -- currently issued positions (i.e. they're mining there)
		
		self:_save()
	end
end

-- Save state to file
function MiningSystem:_save()
	io.to_file(self._STATE_FILE, {
		_last_pos = self._last_pos,
		_issued_positions = self._issued_positions,
	})
end

-- whether given chunk has already been mined out
function MiningSystem:is_chunk_mined(chunk)
	local corner1 = chunk:mul(CHUNK_SIZE)
	
	local corner2 = vector.copy(corner1)
	corner2.x = corner2.x + CHUNK_SIZE-1
	
	local corner3 = vector.copy(corner1)
	corner3.z = corner3.z + CHUNK_SIZE-1
	
	local corner4 = vector.copy(corner1)
	corner4.x = corner4.x + CHUNK_SIZE-1
	corner4.z = corner4.z + CHUNK_SIZE-1
	
	return self:is_pos_mined(corner1) and self:is_pos_mined(corner2) and self:is_pos_mined(corner3) and self:is_pos_mined(corner4)
end

-- whether given pos has already been mined out
function MiningSystem:is_pos_mined(pos)
	return self:_get_distance(pos) <= self:_get_last_mined_out_distance()
end

-- returns distance of last mined out pos
function MiningSystem:_get_last_mined_out_distance()
	-- find min distance
	local d = self:_get_distance(last_pos)
	for _, pos in pairs(self._issued_positions) do
		local d2 = self:_get_distance(pos)
		if d > d2 then
			d = d2
		end
	end
	
	return d - 1
end

-- returns n where n is the n-th step to go from home_pos to pos according to our mining path
function MiningSystem:_get_distance(pos)
	if pos == nil then
		return 0
	end
	
	-- Note: make a drawing to understand the math below
	local dp = pos:sub(self._home_pos)
	local d = math.max(math.abs(dp.x), math.abs(dp.z))
	local distance = 0
	
	if (dp.x == d and dp.z == d) then
		-- traversed path forms a full square
		if d > 0 then
			local side = 2*d+1
			distance = distance + side * side - 1
		end
	else
		-- distance of traversing inner square
		if d > 0 then
			local side = 2*(d-1)+1
			distance = distance + side * side - 1
		end
		
		-- add distance of traversing outer border
		local side = 2*d+1
		if dp.z == d then
			-- go up (when viewing the XZ plane frontally with X pointing up, Z pointing right)
			distance = distance + 3*(side-1) + (dp.x + d)
		elseif dp.x == -d then
			-- go right
			distance = distance + 2*(side-1) + (dp.z + d)
		elseif dp.z == -d then
			-- go down 
			distance = distance + (side-1) + 2*d - (dp.x + d)
		elseif dp.x == d then
			-- go left
			distance = distance + 2*d - (dp.z + d)
		end
	end
	
	return distance
end

-- notify that certain requester completed its last mining assignment
function MiningSystem:finished_mining(requester_id)
	self._issued_positions[requester_id] = nil
	self:_save()
end

-- returns next available mining pos and considers it assigned to whoever requested it
-- requester_id: id of whoever is making the request
-- moves in counter-clockwise spiral in the xz plane, starts towards x = a square spiral
function MiningSystem:get_next(requester_id)
	if self._last_pos == nil then
		self._last_pos = vector.copy(self._home_pos)
	else
		-- Note: make a drawing if you don't understand the math
		local dp = self._last_pos:sub(self._home_pos)
		local d = math.max(math.abs(dp.x), math.abs(dp.z))
		
		-- Note: the ordering of the ifs is reverse chronological, which is crucial for correct behaviour
		if (dp.x == d and dp.z == d) then
			-- finished a square (!= tile), move to next square
			self._last_pos.x = self._last_pos.x + 1
		elseif dp.z == d then
			-- go up (when viewing the XZ plane frontally with X pointing up, Z pointing right)
			self._last_pos.x = self._last_pos.x + 1
		elseif dp.x == -d then
			-- go right
			self._last_pos.z = self._last_pos.z + 1
		elseif dp.z == -d then
			-- go down 
			self._last_pos.x = self._last_pos.x - 1
		elseif dp.x == d then
			-- go left
			self._last_pos.z = self._last_pos.z - 1
		end
	end
	
	self._issued_positions[requester_id] = vector.copy(self._last_pos)
	self:_save()
	return vector.copy(self._last_pos)
end

end)