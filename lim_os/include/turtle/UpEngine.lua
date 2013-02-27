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

end)