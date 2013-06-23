-- Turtle api that throws exceptions

local _turnLeft = turtle.turnLeft
function turtle.turnLeft()
	assert(_turnLeft(), "turtle api lied")
end

local _turnRight = turtle.turnRight
function turtle.turnRight()
	assert(_turnRight(), "turtle api lied")
end

local _forward = turtle.forward
function turtle.forward()
	if not _forward() then
		Exception("Failed to move forward")
	end
end

local _back = turtle.back
function turtle.back()
	if not _back() then
		Exception("Failed to move backward")
	end
end

local _down = turtle.down
function turtle.down()
	if not _down() then
		Exception("Failed to move down")
	end
end

local _up = turtle.up
function turtle.up()
	if not _up() then
		Exception("Failed to move up")
	end
end

local _dig = turtle.dig
function turtle.dig()
	if peripheral.getType('front') ~= 'turtle' then
		if not _dig() then
			Exception("Failed to dig")
		end
	end
end

local _digDown = turtle.digDown
function turtle.digDown()
	if peripheral.getType('bottom') ~= 'turtle' then
		if not _digDown() then
			Exception("Failed to dig down")
		end
	end
end

local _digUp = turtle.digUp
function turtle.digUp()
	if peripheral.getType('top') ~= 'turtle' then
		if not _digUp() then
			Exception("Failed to dig up")
		end
	end
end

function turtle.is_inventory_empty()
	for i=1,16 do
		if turtle.getItemCount(i) > 0 then
			return false
		end
	end
	return true
end

local _select = turtle.select
local _selected_slot = 1
function turtle.select(i)
	_select(i)
	_selected_slot = i
end

local _getItemCount = turtle.getItemCount
function turtle.getItemCount(i)
	i = i or _selected_slot
	return _getItemCount(i)
end

local _drop = turtle.drop
function turtle.drop(amount)
	if turtle.getItemCount() > 0 then
		if not _drop() then
			Exception("Failed to drop")
		end
	end
end

local _dropUp = turtle.dropUp
function turtle.dropUp(amount)
	if turtle.getItemCount() > 0 then
		if not _dropUp() then
			Exception("Failed to drop")
		end
	end
end

local _dropDown = turtle.dropDown
function turtle.dropDown(amount)
	if turtle.getItemCount() > 0 then
		if not _dropDown() then
			Exception("Failed to drop")
		end
	end
end
