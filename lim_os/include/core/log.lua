
local f = fs.open("error.log", 'a')
function log(message)
	f.writeLine('Day '..os.day()..' '..textutils.formatTime( os.time(), true )..': '..message)
	f.flush()
end