catch(function()

DownEngine = Object:new()
function DownEngine.dig()
	return turtle.digDown()
end

function DownEngine.detect()
	return turtle.detectDown()
end

function DownEngine.move()
	return turtle.down()
end

end)