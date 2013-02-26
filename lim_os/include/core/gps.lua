-- improved gps api

-- throws GPSException when no reception
-- returns a vector
local _locate = gps.locate
function gps.locate()
	local x, y, z = _locate()
	if not x then
		error({type="GPSException", message="No GPS reception"})
	end
	pos = vector.new(x, y, z)
	return pos
end