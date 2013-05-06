-- Keeps track of what parts of planet have been mined

-- ENSURE: At any point in time, program must be able to handle being aborted and restarted

catch(function()

MiningSystem = Object:new()
MiningSystem._STATE_FILE = "/mining_system.state"

function MiningSystem:new()
	local obj = Object.new(self)
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
		self._home_pos = gps_.persistent_locate()
		self._last_pos = nil
		
		self:_save()
	end
end

-- Save state to file
function MiningSystem:_save()
	io.to_file(self._STATE_FILE, {
		_home_pos = self._home_pos,
		_last_pos = self._last_pos,
	})
end

-- returns next available mining pos and considers it assigned to whoever requested it
function MiningSystem:get_next()
	if self._last_pos == nil then
		self._last_pos = vector.copy(self._home_pos)
	else
		-- make a drawing if you don't understand the math
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
	
	self:_save()
	return vector.copy(self._last_pos)
end

end)