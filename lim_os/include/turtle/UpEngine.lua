catch(function()

UpEngine = Object:new()
function UpEngine.dig()
	return turtle.digUp()
end

function UpEngine.detect()
	return turtle.detectUp()
end

function UpEngine.move()
	return turtle.up()
end

end)