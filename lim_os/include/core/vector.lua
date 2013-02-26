function vector.from_table(t)
	if t then
		return vector.new(t.x, t.y, t.z)
	else
		return nil
	end
end