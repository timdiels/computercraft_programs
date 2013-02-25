-- Debugging utils

debug = debug or {}
function debug.print(a)
	if type(a) == "table" then
		for k,v in pairs(a) do
			print(tostring(k)..'='..tostring(v))
		end
	else
		print(tostring(a))
	end
end