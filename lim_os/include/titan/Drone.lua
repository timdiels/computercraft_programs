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
Drone._mining_height_min = 5  -- bedrock goes up to height 4, and our AI doesn't handle bedrock
Drone._mining_height_max = 160
Drone._engines = turtle.engines
-- self._target_pos: x, z coord of place to mine/build. y-coord of mining is ignored, y-coord of build pos points to lowest spot to build at

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
		self._target_pos = vector.from_table(self._target_pos)
	else
		self._state = DroneState.IDLE
		self:_save()
	end
end

-- Save state to file
function Drone:_save()
	io.to_file(self._STATE_FILE, {
		_state = self._state,
		_target_pos = self._target_pos,
	})
end

function Drone:_query(contents)
	rednet.open('right')
	rednet.send(self._titan_id, textutils.serialize({user='limyreth', contents=contents}))
	while true do
		local sender, msg, distance = rednet.receive()
		msg = textutils.unserialize(msg)
		if msg.user == 'limyreth' then
			rednet.close('right')
			return msg.contents
		end
	end
end

function Drone:_request_mining_pos()
	self._target_pos = vector.from_table(self:_query({type='mine_request'}))
end

function Drone:_request_build_pos()
	self._target_pos = vector.from_table(self:_query({type='build_request'}))
end

function Drone:_build()
	-- TODO
	-- Note this totally works right after mining   TODO anytime
	local pos = vector.copy(self._target_pos)
	pos.y = pos.y - 1
	self._driver:go_to(pos, {'y', 'x', 'z'}, {x=false, y=false, z=false})
	
	todobuild()
end

function Drone:_mine()
	self._target_pos.y = self._mining_height_max + 1
	self._driver:go_to(self._target_pos, {'y', 'x', 'z'}, {x=false, y=false, z=false})
	
	self._target_pos.y = self._mining_height_min
	self._driver:go_to(self._target_pos, {'y'}, {y=true})
end

-- Dumps all useless materials
-- REQUIRE: hanging above lava
function Drone:_dump_all()
	self._engines[Direction.DOWN]:drop_all()
	turtle.select(1)
end

function Drone:run()
	while true do
		if self._state == DroneState.IDLE then
			if getItemCount(13) > 0 then
				self._state = DroneState.BUILDING
			else
				self:_request_mining_pos()
				self._state = DroneState.MINING
			end
		elseif self._state == DroneState.MINING then
			log('mine')
			self:_mine()
			self._state = DroneState.IDLE
		elseif self._state == DroneState.BUILDING then
			-- TODO if empty then state = idle
			-- request next build location, move to it and build, from down to up, then up down, then down up, ... (simply depends on pos relative to it...)
			log('build')
			self:_request_build_pos()
			self:_build()
		else
			assert(false)
		end
		
		self:_save()
	end
end

end)