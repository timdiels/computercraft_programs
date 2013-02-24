-- Orientation in the XZ plane
-- An enum (NORTH, ...). Don't instantiate it yourself.

catch(function()

Orientation = Object:new()

-- returns orientation left of current orientation
function Orientation:left()
	return Orientation._left_of[self]
end

-- returns orientation right of current orientation
function Orientation:right()
	return Orientation._right_of[self]
end

function Orientation:opposite()
	return Orientation._right_of[Orientation._right_of[self]]
end

function Orientation:get_axis()
	if self._orientation == Orientation.X or self._orientation == Orientation.X.opposite() then
		return "x"
	else
		return "z"
	end
end

Orientation.NORTH = Orientation:new()
Orientation.EAST = Orientation:new()
Orientation.SOUTH = Orientation:new()
Orientation.WEST = Orientation:new()

Orientation._left_of = {
	[Orientation.EAST] = Orientation.NORTH,
	[Orientation.SOUTH] = Orientation.EAST,
	[Orientation.WEST] = Orientation.SOUTH,
	[Orientation.NORTH] = Orientation.WEST,
}

Orientation._right_of = {}
for k,v in pairs(Orientation._left_of) do
	Orientation._right_of[v] = k
end

Orientation.X = Orientation.EAST
Orientation.Z = Orientation.SOUTH

end)