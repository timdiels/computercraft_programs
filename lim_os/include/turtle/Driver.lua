-- Drives your turtle
-- Requires GPS to reach its destination (can handle an occasional interruption)
-- Assumes it can move backwards 1 tile when started
-- Assumes that destination can be reached by first moving along x, then z, then y
-- Note: Driver is fuel agnostic (TODO might want to be able to ask Driver fuel distance from pos to some destination, based on the usual assumptions... Does failed movement cost fuel??)

-- TODO Does dig fail when inventory is full? We assume as much in our miner!!

-- Refactors:
-- TODO add an Axis/Orientation class or something

catch(function()

Driver = Object:new()

Driver._STATE_FILE = "/driver.state"

Driver.X = 1
Driver.Y = 2
Driver.Z = 3
Driver.EAST = Driver.X
Driver.SOUTH = Driver.Z
Driver.WEST = -Driver.EAST
Driver.NORTH = -Driver.SOUTH
Driver.UP = Driver.Y
Driver.DOWN = -Driver.UP

Driver._axis_to_orientation = {x=Driver.X, y=Driver.Y, z=Driver.Z}

function Driver:new()
	local obj = Object.new(self)
	obj:_load()
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
		self:_move_to_destination()
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
	require_(math.abs(orientation) ~= Driver.UP)
	
	self:_load_orientation()
	while self._orientation ~= orientation do
		self:turn_right()
	end
end

function Driver:up()
	if turtle.detectUp() then
		turtle.digUp()
	end
	
	turtle.up()
end

function Driver:down()
	if turtle.detectDown() then
		turtle.digDown()
	end
	
	turtle.down()
end

function Driver:forward()
	turtle.forward()
end

function Driver:back()
	turtle.back()
end

-- See the goto program for an example
function Driver:go_to(destination, movement_order, may_dig)
	self._destination = destination
	self._movement_order = movement_order
	self._may_dig = may_dig
	self:_save()

	self:_move_to_destination()
end

function Driver:turn_left()
	turtle.turnLeft()
	if self._orientation == Driver.EAST then
		self._orientation = Driver.NORTH
	elseif self._orientation == Driver.SOUTH then
		self._orientation = Driver.EAST
	elseif self._orientation == Driver.WEST then
		self._orientation = Driver.SOUTH
	elseif self._orientation then
		assert(self._orientation == Driver.NORTH)
		self._orientation = Driver.WEST
	end
end

function Driver:turn_right()
	turtle.turnRight()
	if self._orientation == Driver.NORTH then
		self._orientation = Driver.EAST
	elseif self._orientation == Driver.EAST then
		self._orientation = Driver.SOUTH
	elseif self._orientation == Driver.SOUTH then
		self._orientation = Driver.WEST
	elseif self._orientation then
		assert(self._orientation == Driver.WEST)
		self._orientation = Driver.NORTH
	end
end

function Driver:_move_to_destination()
	local i=10
	while not self:_has_reached_destination() do
		self:_move_one_tile()
		i=i-1
		if i<0 then
			break
		end
	end
	
	-- destination reached
	self._destination = nil
	self:_save()
end

function Driver:_move_one_tile()
	require_(not self:_has_reached_destination())
	
	local pos = self:_get_pos()
	for _, axis in pairs(self._movement_order) do
		if pos[axis] ~= self._destination[axis] then
			local orientation = Driver._axis_to_orientation[axis]
			if self._destination[axis] < pos[axis] then
				orientation = -orientation
			end
			
			self:_move(orientation)
			break
		end
	end
	
	ensure(pos ~= self:_get_pos())
end

function Driver:_move(direction)
	local old_pos = self:_get_pos()
	if math.abs(direction) == Driver.Y then
		if direction == Driver.UP then
			if turtle.detectUp() then
				if self._may_dig[axis] then
					turtle.digUp()
				else
					Exception("Path blocked")
				end
			end
			
			turtle.up()
		else
			if turtle.detectDown() then
				if self._may_dig[axis] then
					turtle.digDown()
				else
					Exception("Path blocked")
				end
			end
			
			turtle.down()
		end
	else
		self:orient(direction)
		if turtle.detect() then
			if self._may_dig[axis] then
				turtle.dig()
			else
				Exception("Path blocked")
			end
		end
		turtle.forward()
	end
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
	
	local p1 = self:_get_pos()
	local p2 = nil  -- = pos after moving forward 
	for i=1,4 do
		local success = try(self.forward, self)
		if success then
			p2 = self:_get_pos()
			self:back()
			break
		end
		self:turn_right()
	end
	if not p2 then
		Exception("Disoriented")  -- we are surrounded by blocks or out of fuel
		-- TODO as a last desparation move we might try to dig the tile in front of us
	end
	
	local dp = p2 - p1
	assert(dp.y == 0)
	if dp.x ~= 0 then
		assert(dp.z == 0)
		if dp.x > 0 then
			self._orientation = Driver.X
		else
			self._orientation = -Driver.X
		end
	else
		assert(dp.x == 0)
		if dp.z > 0 then
			self._orientation = Driver.Z
		else
			self._orientation = -Driver.Z
		end
	end
end

function Driver:_has_reached_destination()
	local ret = self._destination == nil or table.equals(self._destination, self:_get_pos())
	print(ret)
	return ret
end

end)