catch(function()

ForwardEngine = Engine:new()

function ForwardEngine:dig()
	turtle.dig()
end

function ForwardEngine:detect()
	return turtle.detect()
end

function ForwardEngine:move()
	turtle.forward()
end

function ForwardEngine:drop()
	turtle.drop()
end

function ForwardEngine:place()
	while self:detect() do
		os.sleep(1)
	end
	turtle.place()
end

end)