catch(function()

Engine = Object:new()

function Engine:drop_all()
	for i=1,16 do
		turtle.select(i)
		self.drop()
	end
end

end)