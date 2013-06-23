catch(function()

UpEngine = Engine:new()

function UpEngine:dig()
	turtle.digUp()
end

function UpEngine:detect()
	return turtle.detectUp()
end

function UpEngine:move()
	turtle.up()
end

function UpEngine:drop()
	turtle.dropUp()
end

function UpEngine:place()
	while self:detect() do
		os.sleep(1)
	end
	turtle.placeUp()
end

end)