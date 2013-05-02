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

-- keeps trying every 10 seconds
function gps_.persistent_locate()
	local first_print = true
		
	while true do
		local status, retval = pcall(gps_.locate)
		if status then
			if not first_print then
				print("GPS signal restored")
			end
			return retval
		end
		
		if first_print then
			print("No GPS signal")
			first_print = false
		end
		
		os.sleep(10)
	end
end