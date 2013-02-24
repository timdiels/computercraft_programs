-- Drives your turtle
-- Requires GPS to reach its destination (can handle an occasional interruption)
-- Assumes it can move backwards 1 tile when started
-- Assumes that destination can be reached by first moving along x, then z, then y
-- Note: Driver is fuel agnostic (TODO might want to be able to ask Driver fuel distance from pos to some destination, based on the usual assumptions... Does failed movement cost fuel??)
-- TODO when an orient is interrupted, it will not be continued next run

-- TODO Does dig fail when inventory is full? We assume as much in our miner!!

-- TODO moving through gravel
catch(function()

Driver = Object:new()

Driver._STATE_FILE = "/driver.state"

function Driver:new()
	local obj = Object.new(self)
	obj._load()
	return obj
end

-- Load from file
function Driver:_load()
	-- load persistent things
	local state = io.from_file(self._STATE_FILE)
	if state then
		table.merge(self, state)
	end
	
	-- resume movement if we were moving
	if self._destination then
		self._move_to_destination()
	end
end

function Driver:_save()
	io.to_file(self._STATE_FILE, {
		_destination = self._destination,
		_movement_order = self._movement_order,
		_may_dig = self._may_dig,
	})
end

function Driver:orient(orientation)
	require_(orientation ~= nil, 1)
	self._load_orientation()
	if orientation == self._orientation.left() then
		self.turn_left()
	else
		while self._orientation ~= orientation do
			self.turn_right()
		end
	end
end

-- See the goto program for an example
function Driver:go_to(destination, movement_order, may_dig)
	self._destination = destination
	self._movement_order = movement_order
	self._may_dig = may_dig
	self._save()

	self._move_to_destination()
end

function Driver:turn_left()
	turtle.turnLeft()
	if self._orientation then
		self._orientation = self._orientation.left()
	end
end

function Driver:turn_right()
	turtle.turnRight()
	if self._orientation then
		self._orientation = self._orientation.right()
	end
end

function Driver:_dig()
	local may_dig
	if self._orientation then
		local axis = self._orientation.get_axis()
		may_dig = self._may_dig[axis]
	else
		may_dig = self._may_dig["x"] and self._may_dig["z"]
	end
	
	if may_dig then
		turtle.dig()
	else
		Exception("Not allowed to dig along axis: "..axis)
	end
end
	
function Driver:_dig_up()
	if self._may_dig["y"] then
		turtle.digUp()
	else
		Exception("Not allowed to dig along axis: y")
	end
end

function Driver:_dig_down()
	if self._may_dig["y"] then
		turtle.digDown()
	else
		Exception("Not allowed to dig along axis: y")
	end
end

function Driver:_move_to_destination()
	while not self._has_reached_destination() do
		self._move_one_tile()
	end
	
	-- destination reached
	self._destination = nil
	self._save()
end

function Driver:_move_one_tile()
	require_(not self._has_reached_destination())
	
	local pos = self._get_pos()
	for _, axis in pairs(self._movement_order) do
		if pos[axis] ~= self._destination[axis] then
			local forward = false
			if self._destination[axis] > pos[axis] then
				forward = true
			end
			
			if axis == 'y' then
				if forward then
					if turtle.detectUp() then
						if not try(self._dig_up) then
							Exception("Path blocked")
						end
					end
					
					turtle.up()
				else
					if turtle.detectDown() then
						print(self)
						if not try(self._dig_down) then
							Exception("Path blocked")
						end
					end
					
					turtle.down()
				end
			else
				local orientation
				if axis == 'x' then
					orientation = Orientation.X
				else
					orientation = Orientation.Z
				end
				
				if not forward then
					orientation = orientation.opposite()
				end
				
				self.orient(orientation)
				if turtle.detect() then
					if not try(self._dig) then
						Exception("Path blocked")
					end
				end
				turtle.forward()
			end
			
			break
		end
	end
	
	ensure(pos ~= self._get_pos())
end

-- TODO perhaps buffer location (only changes in _move)
function Driver:_get_pos()
	local x, y, z = gps.locate()
	if not x then
		error({type="GPSException", message="No GPS reception"})
	end
	pos = vector.new(x, y, z)
	return pos
end

function Driver:_load_orientation()
	if self._orientation then
		return  -- already loaded
	end
	
	local p1 = self._get_pos()
	local p2 = nil  -- = pos after moving forward 
	for i=1,4 do
		if try(turtle.forward) then
			p2 = self._get_pos()
			turtle.back()
			break
		end
		self.turn_right()
	end
	
	if not p2 then
		if turtle.getFuelLevel() == 0 then
			Exception("Disoriented and out of fuel")
		end
		
		-- find a block to mine
		for i=1,4 do
			if try(self._dig) then
				turtle.forward()
				p2 = self._get_pos()
				turtle.back()
				break
			end
			self.turn_right()
		end
		
		if not p2 then
			Exception("Disoriented")  -- we are surrounded by blocks or out of fuel
		end
	end
	
	local dp = p2 - p1
	assert(dp.y == 0)
	if dp.x ~= 0 then
		assert(dp.z == 0)
		if dp.x > 0 then
			self._orientation = Orientation.X
		else
			self._orientation = Orientation.X.opposite()
		end
	else
		assert(dp.x == 0)
		if dp.z > 0 then
			self._orientation = Orientation.Z
		else
			self._orientation = Orientation.Z.opposite()
		end
	end
	
	ensure(self._orientation ~= nil)
end

function Driver:_has_reached_destination()
	return self._destination == nil or table.equals(self._destination, self._get_pos())
end

end)