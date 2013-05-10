-- Client side main class of Worker drones of Titan

-- REQUIRES: is a mining turtle with unlimited fuel and a modem at right side
-- ENSURE: At any point in time, handle server crashes well

-- TODO don't move through finished building chunks (basically just move towards building surface without digging or getting stuck! Will need a DroneDriver that takes that into account and has a dumber Driver of itself)

catch(function()

Drone = Object:new()
Drone._mining_height_min = 5  -- bedrock goes up to height 4, and our AI doesn't handle bedrock
Drone._mining_height_max = TERRAIN_HEIGHT_MAX
Drone._engines = turtle.engines
-- self._target_pos: x, z coord of place to mine/build. y-coord of mining is ignored, y-coord of build pos points to lowest spot to build at

-- titan_id: computer id of Titan
function Drone:new(titan_id)
	local obj = Object.new(self)
	obj._titan_id = titan_id
	obj._driver = Driver:new()
	return obj
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

function Drone:_fetch_command(is_initial_command)
	local stats = {}	
	stats.finished = not is_initial_command  -- whether or not prev command has been finished
	stats.can_mine = turtle.getItemCount(13) == 0
	stats.can_build = self:_get_material_count() < 16
	log(stats)
	
	local command = self:_query({type='command_request', drone_stats=stats})
	log(command)
	self._state = command.state
	self._target_pos = command.target_pos
end

function Drone:_build()
	local pos = vector.copy(self._target_pos)
	local cur_pos = self._driver:get_pos()
	
	local start_y = pos.y
	local stop_y = pos.y+15
	local cur_y = cur_pos.y
	local step = 1
	
	if pos.x == cur_pos.x and pos.z == cur_pos.z and cur_pos.y >= start_y-1 and cur_pos.y <= stop_y+1 then
		-- we may have already partially built it, so start by breaking down what we had already built
		local p = vector.copy(pos)
		
		-- mine to bottom
		self._driver:go_to(p, {'x', 'z', 'y'}, {x=false, y=true, z=false})
		
		-- mine to top
		p.y = p.y + 15
		self._driver:go_to(p, {'x', 'z', 'y'}, {x=false, y=true, z=false})
	end
	
	if  math.abs(cur_y - start_y) > math.abs(cur_y - stop_y) then
		-- move from top to bottom
		start_y, stop_y = stop_y, start_y
		move_engine, place_engine = place_engine, move_engine
		step = -1
	--else move from bottom to top
	end
	
	pos.y = start_y
	
	local p = vector.copy(pos)
	p.y = pos.y - step
	self:_cross_chunk_move(p)
	
	self._driver:go_to(pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
	
	for j=1,16 do	
		pos.y = pos.y + step
		self._driver:go_to(pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
		
		for i=1,16 do
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
	log('cross chunk move')
	-- Move to nearest empty chunk pos
	local free_pos = self:_query({type='nearest_free_pos_request', drone_pos=self._driver:get_pos()})
	log(free_pos)
	log(destination)
	self._driver:go_to(free_pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
	
	-- Move to actual destination
	self._driver:go_to(destination, {'y', 'x', 'z'}, {x=false, y=false, z=false})
end

function Drone:_mine()
	-- goto top mining pos
	self._target_pos.y = self._mining_height_max + 1
	self._driver:go_to(self._target_pos, {'x', 'z', 'y'}, {x=false, y=false, z=false})
	
	-- mine down
	self._target_pos.y = self._mining_height_min
	self._driver:go_to(self._target_pos, {'y'}, {y=true})
	
	-- return to top
	self._target_pos.y = self._mining_height_max + 1
	self._driver:go_to(self._target_pos, {'y'}, {x=false, y=false, z=false})
end

-- move to drop of point
function Drone:_go_to_drop_pos()
	self:_cross_chunk_move(self._target_pos)
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
	for i=1,16 do
		count = count + turtle.getItemCount(i)
	end
	return count
end

function Drone:run()
	self:_fetch_command(true)
	
	while true do
		if self._state == DroneState.MINING then
			log('mining', true)
			self:_mine()
		elseif self._state == DroneState.DROP_JUNK then
			log('drop junk', true)
			self:_drop_junk()
		elseif self._state == DroneState.BUILDING then
			log('building', true)
			self:_build()
		elseif self._state == DroneState.DROP_ALL then
			log('drop all', true)
			self:_drop_all()
		else
			log(self._state, true)
			assert(false)
		end
		
		self:_fetch_command(false)
	end
end

end)