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
	if not _dig() then
		Exception("Failed to dig")
	end
end

local _digDown = turtle.digDown
function turtle.digDown()
	if not _digDown() then
		Exception("Failed to dig down")
	end
end

local _digUp = turtle.digUp
function turtle.digUp()
	if not _digUp() then
		Exception("Failed to dig up")
	end
end