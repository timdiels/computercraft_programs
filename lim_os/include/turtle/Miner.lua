-- Mine layers [6, 15] (<6 has bedrock)
-- Makes a shaft down from its starting location
-- Mines first quadrant, second, third, fourth
-- Returns when full, drops stuff in chest in front, refuses to leave unless everything dropped
-- Returns when fuel becomes low, expects chest with fuel to its left
-- Returning implies using gps to go to (x, z) spot, points back to its original orientation, moves up to starting y
-- Starting location is passed as program args and is referred to as Home location
-- Startup script calls this thing!

-- ENSURE: At any point in time, program must be able to handle being aborted and restarted

catch(function()

Miner = Object:new()
Miner._STATE_FILE = "/miner.state"

function Miner:new()
	local obj = Object.new(self)
	obj._load()
	return obj
end

-- Load from file
function Miner:_load()
	self._driver = Driver:new()
	
	-- load persistent things
	if fs.exists(Miner._STATE_FILE) then
		-- home_pos, state
	else
		self._state = "initial"
		self._home_pos = gps_.locate()
		
		--+2
		self._last_mined_pos = table.copy(self._home_pos)
		self._last_mined_pos.y = 7
	end
end

-- Save state to file
function Miner:_save()
	error("Not implemented")
end

function Miner:_go_home()
	self._state = "going home"
	-- TODO if mining this would depend on which quadrant we're in
	self._driver.go_to(self._home_pos, {'x', 'z', 'y'})
end

function Miner:_go_mine()
	self._state = "mining"
	self._driver.go_to(self._last_mined_pos, {'x', 'z', 'y'})
end

function Miner:_mine()
	return dig() and digDown() and digUp()
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
		if self._state == "initial" then
			self._go_home()
		elseif self._state == "going home" then
			print("Press any key to continue mining")
			read()
			self._go_mine()
			-- TODO drop stuff in chest
		elseif self._state == "mining" then
			-- TODO what if inventory full, ...
			self._go_home()
			if mine() then
				--TODO destination = ... next
			else
				goHome()
			end
		elseif self._state == "error" then
			exit()
		else
			assert(false, 1, "Invalid state: "..self._state)
		end
		
		--if isLowOnFuel() then
		--	goHome()
		--end
	end
end

-- TODO add a Log class that logs to file

end)