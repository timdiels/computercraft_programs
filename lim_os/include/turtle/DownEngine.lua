catch(function()

DownEngine = Engine:new()

function DownEngine:dig()
	turtle.digDown()
end

function DownEngine:detect()
	return turtle.detectDown()
end

function DownEngine:move()
	turtle.down()
end

function DownEngine:drop()
	turtle.dropDown()
end

end)