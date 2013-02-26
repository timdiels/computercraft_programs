-- Mine layers [6, 15] (<6 has bedrock)
-- Makes a shaft down from its starting/home location, mines in circular, counter-clockwise fashion
-- Returns when full
-- Starting location is passed as program args and is referred to as Home location
-- Startup script calls this thing!

-- ENSURE: At any point in time, program must be able to handle being aborted and restarted

-- TODO deal with GPSException(by moving back a few positions and issuing a go home command, where user can then decide whether it went out of gps range, or whether gps was just temp broken)
-- TODO mining higher when layer finished. Might even provide height to dig at as an arg...

catch(function()

Miner = Object:new()
Miner._STATE_FILE = "/miner.state"
Miner._engines = turtle.engines

function Miner:new()
	local obj = Object.new(self)
	obj._load()
	return obj
end

-- Load from file
function Miner:_load()
	self._driver = Driver:new()
	
	-- load persistent things
	local state = io.from_file(self._STATE_FILE)
	if state then
		table.merge(self, state)
		self._home_pos = vector.from_table(self._home_pos)
		self._mining_pos = vector.from_table(self._mining_pos)
	else
		self._home_pos = gps_.locate()
		
		-- where we currently/will mine
		self._mining_pos = table.copy(self._home_pos)
		self._mining_pos.y = 7
		
		self._save()
	end
end

-- Save state to file
function Miner:_save()
	io.to_file(self._STATE_FILE, {
		_home_pos = self._home_pos,
		_mining_pos = self._mining_pos,
	})
end

function Miner:_go_home()
	-- TODO if mining this would depend on which quadrant we're in
	self._driver.go_to(self._home_pos, {'x', 'z', 'y'})
end

function Miner:_go_to_mine()
	self._driver.go_to(self._mining_pos, {'y', 'x', 'z'})
end

function Miner:_set_next_mining_pos()
	-- make a drawing if you don't understand the math
	local dp = self._mining_pos:sub(self._home_pos)
	local d = math.max(math.abs(dp.x), math.abs(dp.z))
	
	-- Note: the ordering of the ifs is reverse chronological, which is crucial for correct behaviour
	if (dp.x == d and dp.z == d) then
		-- finished a square (!= tile), move to next square
		self._mining_pos.x = self._mining_pos.x + 1
		-- Note: d += 1
	elseif dp.z == d then
		-- go up (when viewing the XZ plane frontally with X pointing up, Z pointing right)
		self._mining_pos.x = self._mining_pos.x + 1
	elseif dp.x == -d then
		-- go right
		self._mining_pos.z = self._mining_pos.z + 1
	elseif dp.z == -d then
		-- go down 
		self._mining_pos.x = self._mining_pos.x - 1
	elseif dp.x == d then
		-- go left
		self._mining_pos.z = self._mining_pos.z - 1
	end
end

function Miner:_mine()
	self._go_to_mine()
	
	while true do
		-- Drill in all directions
		for direction, engine in pairs(self._engines) do
			if engine.detect() then
				engine.dig()
				if turtle.getItemCount(16) > 0 then
					-- we might drop items if we dig more
					Exception("Inventory full")
				end
			end
		end
		
		-- Move to next tile
		-- TODO
		self._set_next_mining_pos()
		self._save()
		self._go_to_mine()
		
		--if isLowOnFuel() then
		--	goHome()
		--end
	end
end

-- TODO return for fuel
--[[function Miner:_is_low_on_fuel()
	local needed_fuel = (math.abs(destination.x - pos.x) +
							math.abs(destination.y - pos.y) +
							math.abs(destination.z - pos.z) +
							10)  -- margin of 10
	return needed_fuel <= turtle.getFuelLevel()
end
]]

-- main miner loop
function Miner:run()
	while true do
		-- TODO drop stuff in chest
		print("Press any key to continue mining")
		read()
		
		-- mine
		_, e = pcall(self._mine)
		debug.print(e)
		self._go_home()
	end
end

-- TODO add a Log class that logs to file

end)