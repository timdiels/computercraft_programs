-- improved gps api

-- throws GPSException when no reception
-- returns a vector
gps_ = {}
function gps_.locate()
	local x, y, z = gps.locate()
	if not x then
		error({type="GPSException", message="No GPS reception"})
	end
	pos = vector.new(x, y, z)
	return pos
end