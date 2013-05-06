
local f = fs.open("error.log", 'a')
function log(message, enable_print)
	message = debug.tostring(message)
	enable_print = enable_print or false
	f.writeLine('Day '..os.day()..' '..textutils.formatTime( os.time(), true )..': '..message)
	f.flush()
	if enable_print then
		print(message)
	end
end

function log_exception(error_string, enable_print)
	enable_print = enable_print or false
	local prefix, e = exceptions.deserialize(error_string)
	local message = prefix
	message = message.. e.message..' ('..e.type..')'
	log(message, enable_print)
	
	return error_string
end