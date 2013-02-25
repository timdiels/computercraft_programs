-- Mine layers [6, 15] (<6 has bedrock)
-- Makes a shaft down from its starting location
-- Mines first quadrant, second, third, fourth
-- Returns when full, drops stuff in chest in front, refuses to leave unless everything dropped
-- Returns when fuel becomes low, expects chest with fuel to its left
-- Returning implies using gps to go to (x, z) spot, points back to its original orientation, moves up to starting y
-- Starting location is passed as program args and is referred to as Home location
-- Startup script calls this thing!

-- ENSURE: At any point in time, program must be able to handle being aborted and restarted

function(catch(

Miner = Object.new()
Miner._STATE_FILE = "/miner.state"

local mining_layer = 6
local mining_column = home_pos.z
local mining_orientation = 0  -- or 2

function Miner:new()
	local obj = Object.new(self)
	self._load()
	return obj
end

-- Load from file
function Miner:_load()
	-- load persistent things
	if fs.exists(Miner._STATE_FILE) then
		-- home_pos, state
	else
		self.home_pos = gps.locate()
		self._go_home()
	end
end

-- Save state to file
function Miner:_save()
	error("Not implemented")
end

function Miner:_go_home()
	state = "going home"
	destination = home_pos
end

function Miner:_go_mine()
	state = "mining"
	Exception("TODO")
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

function tick()
	move()
	
	if hasReachedDestination() then
		if state == "going home" then
			print("Press any key to continue mining")
			read()
			
			-- TODO drop stuff in chest
			self.go_mine()
		elseif state == "going to mine" then
			error("Have yet to implement")
		elseif state == "mining" then
			-- TODO what if inventory full, ...
			if mine() then
				--TODO destination = ... next
			else
				goHome()
			end
		elseif state == "error" then
			exit()
		else
			assert(false, 1, "Invalid state: "..state)
		end
	end
	
	--if isLowOnFuel() then
	--	goHome()
	--end
end

-- TODO add a Log class that logs to file

end)