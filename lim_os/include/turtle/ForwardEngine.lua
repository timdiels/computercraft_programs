catch(function()

ForwardEngine = Object:new()
function ForwardEngine.dig()
	return turtle.dig()
end

function ForwardEngine.detect()
	return turtle.detect()
end

function ForwardEngine.move()
	return turtle.forward()
end

end)