-- Debugging utils

debug = debug or {}

function debug.tostring(a)
	if type(a) == "table" then
		str = ''
		for k,v in pairs(a) do
			str = str .. tostring(k)..'='..tostring(v).."\n"
		end
		return str
	else
		return tostring(a)
	end
end

function debug.print(a)
	print(debug.tostring(a))
end