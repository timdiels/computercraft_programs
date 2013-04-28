-- Titan, orders all Drones

-- REQUIRES: is at least a computer, with modem on top
-- ENSURE: At any point in time, handle server crashes well

catch(function()

Titan = Object:new()
Titan._STATE_FILE = "/titan.state"
Titan._engines = turtle.engines

function Titan:new()
	local obj = Object.new(self)
	obj:_load()
	return obj
end

function Titan:_load()
	self._mining_system = MiningSystem:new()
end

function Titan:run()
	rednet.open('top')
	while true do
		local sender, msg, distance = rednet.receive()
		msg = textutils.deserialize(msg)
		if msg.user == 'limyreth' then
			rednet.send(sender, 'lolololol')
		end
	end
end

end)