-- Worker drones of Titan

-- REQUIRES: is a mining turtle with unlimited fuel and a modem at right side
-- ENSURE: At any point in time, handle server crashes well

-- TODO don't move through finished building chunks (basically just move towards building surface without digging or getting stuck! Will need a DroneDriver that takes that into account and has a dumber Driver of itself)

catch(function()

DroneState = Object:new()
DroneState.IDLE = 1
DroneState.MINING = 2
DroneState.BUILDING = 3

Drone = Object:new()
Drone._STATE_FILE = "/drone.state"
Drone._mining_height_min = 4
Drone._mining_heigth_max = 200
Drone._engines = turtle.engines
-- self._mining_pos: x, z coord of place to mine. y-coord is ignored

-- titan_id: computer id of Titan
function Drone:new(titan_id)
	local obj = Object.new(self)
	obj._titan_id = titan_id
	obj:_load()
	return obj
end

-- Load from file
function Drone:_load()
	self._driver = Driver:new()
	
	-- load persistent things
	local state = io.from_file(self._STATE_FILE)
	if state then
		table.merge(self, state)
		self._mining_pos = vector.from_table(self._mining_pos)
	else
		self._home_pos = gps_.persistent_locate()
		
		self._state = DroneState.IDLE
		self._mining_pos = nil
		
		self:_save()
	end
end

-- Save state to file
function Drone:_save()
	io.to_file(self._STATE_FILE, {
		_state = self._state,
		_mining_pos = self._mining_pos,
	})
end

function Drone:_fetch_mining_pos()
	rednet.open('right')
	rednet.send(self._titan_id, textutils.serialize({user='limyreth'}))
	local sender, msg, distance = rednet.receive()
	print(msg)
	rednet.close('right')
	
	self._mining_pos = reply.whatevs
end

function Drone:_mine()
	local start_pos = self._mining_pos
	start_pos.y = Drone._mining_heigth_max + 1
	self._driver:go_to(start_pos, {'y', 'x', 'z'}, {x=false, y=false, z=false})
	
	local end_pos = self._mining_pos
	end_pos.y = Drone._mining_heigth_min
	self._driver:go_to(end_pos, {'y'}, {y=true})
end

-- Dumps all useless materials
-- REQUIRE: hanging above lava
function Drone:_dump_all()
	print("Emptying inventory")
	self._engines[Direction.DOWN]:drop_all()
	turtle.select(1)
end

function Drone:run()
	while true do
		if self._state == DroneState.IDLE then
			self:_fetch_mining_pos()
			self._state = DroneState.MINING
		elseif self._state == DroneState.MINING then
			self._mine()
			self._state = DroneState.IDLE
		else
			assert(false)
			-- TODO build...
		end
		
		self:_save()
	end
end

end)