-- merge b into a
function table.merge(a, b)
	for k,v in pairs(b) do
		a[k] = v
	end
end

-- shallow comparison
function table.equals(a, b)
	if #a ~= #b then
		return false
	end
	
	for k,v in pairs(a) do
		if a[k] ~= b[k] then
			return false
		end
	end
	
	return true
end

-- returns shallow copy
function table.copy(a)
	b = {}
	
	for k,v in pairs(a) do
		b[k] = v
	end
	
	return b
end