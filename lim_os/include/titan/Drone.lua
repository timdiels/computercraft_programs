-- Worker drones of Titan

-- REQUIRES: is a mining turtle with unlimited fuel and a modem at right side
-- ENSURE: At any point in time, handle server crashes well

-- TODO don't move through finished building chunks (basically just move towards building surface without digging or getting stuck! Will need a DroneDriver that takes that into account and has a dumber Driver of itself)

catch(function()

DroneState = Object:new()
DroneState.IDLE = 1
DroneState.MINING = 2
DroneState.REQUESTING_BUILD = 3
DroneState.BUILDING = 4
DroneState.DROP_JUNK = 5
DroneState.DROP_ALL = 6

Drone = Object:new()
Drone._STATE_FILE = "/drone.state"
Drone._mining_height_min = 5  -- bedrock goes up to height 4, and our AI doesn't handle bedrock
Drone._mining_height_max = 130
Drone._engines = turtle.engines
Drone._item_slots = 16
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
	local query_msg =  textutils.serialize({user='limyreth', contents=contents})
	local sender, msg, distance
	
	rednet.open('right')
	rednet.send(self._titan_id, query_msg)
	
	repeat
		sender, msg, distance = rednet.receive(5)
		if sender == nil then
			-- time out, send request again
			rednet.send(self._titan_id, query_msg)
		end
	until sender == self._titan_id
		
	rednet.close('right')
	msg = textutils.unserialize(msg)
	return msg.contents
end

function Drone:_build()
	local pos = vector.copy(self._target_pos)
	
	local start_y = pos.y
	local stop_y = pos.y+15
	local cur_pos = self._driver:get_pos()
	local cur_y = cur_pos.y
	local step = 1
	
	if  math.abs(cur_y - start_y) > math.abs(cur_y - stop_y) then
		-- move from top to bottom
		start_y, stop_y = stop_y, start_y
		move_engine, place_engine = place_engine, move_engine
		step = -1
	--else move from bottom to top
	end
	
	pos.y = start_y
	
	local dp = cur_pos:sub(pos)
	local destination_is_different_chunk = math.abs(dp.x) > CHUNK_SIZE or math.abs(dp.y) > CHUNK_SIZE or math.abs(dp.z) > CHUNK_SIZE
	if destination_is_different_chunk then
		local p = vector.copy(pos)
		p.y = pos.y - step
		self:_cross_chunk_move(p)
	end
	
	self._driver:go_to(pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
	
	for j=1,16 do	
		pos.y = pos.y + step
		self._driver:go_to(pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
		
		for i=1,self._item_slots do
			if turtle.getItemCount(i) > 0 then
				turtle.select(i)
				break
			end
		end
		if step > 0 then
			turtle.placeDown()
		else
			turtle.placeUp()
		end
	end
end

-- move to destination without colliding with already built chunks
function Drone:_cross_chunk_move(destination)
	-- Move to nearest empty chunk pos
	local free_pos = self:_query({type='nearest_free_pos_request', drone_pos=self._driver:get_pos()})
	self._driver:go_to(free_pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
	
	-- Move to actual destination
	self._driver:go_to(destination, {'x', 'z', 'y'}, {x=false, y=false, z=false})
end

function Drone:_mine()
	-- goto top mining pos
	self._target_pos.y = self._mining_height_max + 1
	self._driver:go_to(self._target_pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
	
	-- mine down
	self._target_pos.y = self._mining_height_min
	self._driver:go_to(self._target_pos, {'y'}, {y=true})
	
	-- return to top
	self._target_pos.y = self._mining_height_max + 15  -- +15 to allow collision resolution to happen some place where no mining happens (as turtles can mine each other...)
	self._driver:go_to(self._target_pos, {'y'}, {x=false, y=false, z=false})
end

-- move to drop of point
function Drone:_go_to_drop_pos()
	local pos = vector.copy(self._target_pos)
	pos.y = pos.y + 15  -- margin for collision resolving at a place that isn't filled with bots that dig
	self:_cross_chunk_move(pos)
	
	self._driver:go_to(self._target_pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
end

function Drone:_drop_junk()
	self:_go_to_drop_pos()
	
	-- drop
	local engine = self._engines[Direction.DOWN]
	for i=1,16 do
		turtle.select(i)
		if not try(engine.place, engine) or not try(engine.dig, engine) then
			engine:drop()
			os.sleep(1)  -- need to wait for the dropped stuff to fall; because we can't place where blocks are falling
		end
	end
end

function Drone:_drop_all()
	self:_go_to_drop_pos()
	
	-- drop
	local engine = self._engines[Direction.DOWN]
	for i=1,16 do
		turtle.select(i)
		engine:drop()
	end
end

function Drone:_get_material_count()
	local count = 0
	for i=1,self._item_slots do
		count = count + turtle.getItemCount(i)
	end
	return count
end

function Drone:run()
	while true do
		if self._state == DroneState.IDLE then
			if turtle.getItemCount(13) > 0 then
				self._state = DroneState.DROP_JUNK
			else
				self._target_pos = self:_query({type='mine_request'})
				self._state = DroneState.MINING
			end
		elseif self._state == DroneState.MINING then
			self:_mine()
			self._state = DroneState.IDLE
		elseif self._state == DroneState.DROP_JUNK then
			self._target_pos = self:_query({type='drop_request'})
			self:_drop_junk()
			self._state = DroneState.REQUEST_BUILD_ORDER
		elseif self._state == DroneState.REQUEST_BUILD_ORDER then
			local reply = self:_query({type='build_request'})
			if reply.type == 'build' then
				self._target_pos = reply.build_pos
				self._state = DroneState.BUILDING
			elseif reply.type == 'drop' then
				self._state = DroneState.DROP_ALL
			else
				assert(false)
			end
		elseif self._state == DroneState.BUILDING then
			self:_build()
			if self:_get_material_count() < 16 then
				self._state = DroneState.DROP_ALL
			else
				self._state = DroneState.REQUEST_BUILD_ORDER
			end
		elseif self._state == DroneState.DROP_ALL then
			self._target_pos = self:_query({type='drop_request'})
			self:_drop_all()
			self._state = DroneState.IDLE
		else
			assert(false)
		end
		
		self:_save()
	end
end

end)