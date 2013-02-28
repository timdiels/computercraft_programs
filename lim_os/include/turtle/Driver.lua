-- Drives your turtle
-- Requires to reach its destination (can handle an occasional interruption)
-- Assumes it can move backwards 1 tile when started
-- Assumes that destination can be reached by first moving along x, then z, then y
-- Handles GPS outage or moving out of range well
-- Note: Driver is fuel agnostic (TODO might want to be able to ask Driver fuel distance from pos to some destination, based on the usual assumptions... Does failed movement cost fuel??)
-- Note: any turtle needs gps to move reliably. And thus so does this

-- TODO stop saving
-- TODO no longer handles going out of gps range well. Instead you might have to set it manually (because we no longer call gps all the time)
-- TODO Does dig fail when inventory is full? We assume as much in our miner!!

-- Note: you can have only one Driver instance (because of state saving)

catch(function()

Driver = Object:new()

Driver._STATE_FILE = "/driver.state"
Driver._engines = turtle.engines

function Driver:new(persistent)
	local obj = Object.new(self)
	obj:_load(persistent)
	return obj
end

-- Load from file
function Driver:_load(persistent)
	self._persistent = persistent  -- whether or not to save things
	
	if persistent then
		-- load persistent things
		local state = io.from_file(self._STATE_FILE)
		if state then
			table.merge(self, state)
			self._destination = vector.from_table(self._destination)
		end
		
		-- resume movement if we were moving
		if self._destination then
			self:_move_to_destination()
		end
	end
end

function Driver:_save()
	if persistent then
		io.to_file(self._STATE_FILE, {
			_destination = self._destination,
			_movement_order = self._movement_order,
			_may_dig = self._may_dig,
		})
	end
end

function Driver:orient(orientation)
	assert(orientation:is_orientation())
	require_(orientation ~= nil)
	self:_load_orientation()
	if orientation == self._orientation:left() then
		self:turn_left()
	else
		while self._orientation ~= orientation do
			self:turn_right()
		end
	end
end

-- See the goto program for an example
function Driver:go_to(destination, movement_order, may_dig)
	assert(destination ~= nil)
	assert(movement_order ~= nil)
	may_dig = may_dig or {x=true, y=true, z=true}
	
	self._destination = destination
	self._movement_order = movement_order
	self._may_dig = may_dig
	self:_save()

	self:_move_to_destination()
end

function Driver:turn_left()
	turtle.turnLeft()
	if self._orientation then
		self._orientation = self._orientation:left()
	end
end

function Driver:turn_right()
	turtle.turnRight()
	if self._orientation then
		self._orientation = self._orientation:right()
	end
end

function Driver:_dig(direction)
	local axis
	
	if direction == Direction.FORWARD then
		if self._orientation then
			axis = self._orientation:get_axis()
		else
			axis = "x"
		end
	else
		axis = "y"
	end
		
	if self._may_dig[axis] then
		self._engines[direction]:dig()
	else
		Exception("Not allowed to dig along axis: "..axis)
	end
end

function Driver:_move_to_destination()
	while not self:_has_reached_destination() do
		self:_move_one_tile()
	end
	
	-- destination reached
	self._destination = nil
	self:_save()
end

function Driver:_move_one_tile()
	require_(not self:_has_reached_destination())
	
	local pos = self:_get_pos()
	local new_pos = vector.from_table(self._pos)
	
	for _, axis in pairs(self._movement_order) do
		if pos[axis] ~= self._destination[axis] then
			local forward = false
			if self._destination[axis] > pos[axis] then
				forward = true
			end
			
			local direction
			if axis == 'y' then
				if forward then
					direction = Direction.UP
					new_pos.y = new_pos.y + 1
				else
					direction = Direction.DOWN
					new_pos.y = new_pos.y - 1
				end
			else
				local orientation
				if axis == 'x' then
					orientation = Orientation.X
					if forward then
						new_pos.x = new_pos.x + 1
					else
						new_pos.x = new_pos.x - 1
					end
				else
					orientation = Orientation.Z
					if forward then
						new_pos.z = new_pos.z + 1
					else
						new_pos.z = new_pos.z - 1
					end
				end
				
				if not forward then
					orientation = orientation:opposite()
				end
				
				self:orient(orientation)
				direction = Direction.FORWARD
			end
			
			self:_move(direction)
			break
		end
	end
	
	self._pos = vector.from_table(new_pos)
	ensure(pos ~= self:_get_pos())
end

-- TODO move into base Engine
-- move a tile in direction and be extremely persistent about it
function Driver:_move(direction)
	assert(direction ~= nil)
	
	if turtle.getFuelLevel() == 0 then
		Exception("Out of fuel")
	end
	
	-- keep trying:
	-- * a player/mob could be in the way
	-- * a gravel could fall on top
	while true do
		if self._engines[direction]:detect() then
			if not try(self._dig, self, direction) then
				Exception("Path blocked")
			end
		end
		
		local engine = self._engines[direction]
		if try(engine.move, engine) then
			-- check whether or not we moved out of gps range
			if not try(gps_.locate) then
				turtle.back()
				if try(gps_.locate) then
					error({type="GPSOutOfRangeException", message="GPS out of range (or inaccurate)"})
				end
				
				-- it wasn't out of range, gps probably just failing atm
				turtle.forward()
			end
			
			break
		end
		
		os.sleep(0.5)
	end
end

function Driver:_get_pos()
	if not self._pos then
		self._pos = gps_.persistent_locate()
	end
	return self._pos
end

function Driver:_load_orientation()
	if self._orientation then
		return  -- already loaded
	end
	
	local p1 = self:_get_pos()
	local p2 = nil  -- = pos after moving forward 
	for i=1,4 do
		if try(self._move, self, Direction.FORWARD) then
			p2 = gps_.persistent_locate()
			turtle.back() --TODO persistent move backwards
			break
		end
		self:turn_right()
	end
	
	if not p2 then
		Exception("Disoriented")  -- we are surrounded by unminable blocks or out of fuel
	end
	
	local dp = p2 - p1
	assert(dp.y == 0)
	if dp.x ~= 0 then
		assert(dp.z == 0)
		if dp.x > 0 then
			self._orientation = Orientation.X
		else
			self._orientation = Orientation.X:opposite()
		end
	else
		assert(dp.x == 0)
		if dp.z > 0 then
			self._orientation = Orientation.Z
		else
			self._orientation = Orientation.Z:opposite()
		end
	end
	
	ensure(self._orientation ~= nil)
end

function Driver:_has_reached_destination()
	return self._destination == nil or table.equals(self._destination, self:_get_pos())
end

end)