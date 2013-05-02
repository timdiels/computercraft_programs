-- Titan, orders all Drones

-- REQUIRES: is at least a computer, with modem on top
-- ENSURE: At any point in time, handle server crashes well

catch(function()

Titan = Object:new()
Titan._STATE_FILE = "/titan.state"

function Titan:new()
	local obj = Object.new(self)
	obj:_load()
	return obj
end

function Titan:_load()
	self._mining_system = MiningSystem:new()
	self._build_system = BuildSystem:new()
end

function Titan:_send(destination, contents)
	local msg = {user='limyreth'}
	msg.contents = contents
	msg = textutils.serialize(msg)
	rednet.send(destination, msg);
end

function Titan:run()
	rednet.open('top')
	while true do
		local sender, msg, distance = rednet.receive()
		msg = textutils.unserialize(msg)
		if msg.user == 'limyreth' then
			if msg.contents.type == 'mine_request' then
				self:_send(sender, self._mining_system:get_next())
			elseif msg.contents.type == 'build_request' then
				self:_send(sender, self._build_system:get_next())  --TODO if builders exhaust materials slower than miners, than we'll occasionally have to have them dump their materials in the lava pit
			else
				assert(false)
			end
		end
	end
end

end)