catch(function()

Engine = Object:new()

function Engine:drop_all()
	for i=1,16 do
		self.drop()
	end
end

end)