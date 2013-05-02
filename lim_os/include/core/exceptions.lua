-- Exception handling

local _error = error
function error(table_, level)
	level = level or 1
	if level == 0 then
		level = 1  -- force level > 0, as our exception handler expects this
	end
	_error(textutils.serialize(table_), level+1)
end

function print_exception(error_string)
	local prefix, e = exceptions.deserialize(error_string)
	local message = prefix
	if type(e) == "table" then
		message = message.. e.message..' ('..e.type..')'
	else
		message = error_string
	end
	print(message)
	log(message)
	
	return e
end

-- print and abort
local function handle_exception(error_string)
	print_exception(error_string)
	_error()  -- abort
end

-- exactly like pcall, but doesn't display thrown error
function try(...)
	local f = table.remove(arg, 1)
	return xpcall(function() f(unpack(arg)) end, function(e) return e end)
end

-- catches exceptions, prints them properly, then crashes the application
-- func: a function with no args that returns nothing
function catch(func)
	xpcall(func, handle_exception)
end

-- basic Exception
function Exception(message)
	error({type="Exception", message=message}, 2)
end

exceptions = {}
function exceptions.deserialize(str)
	local prefix, e = string.match(str, "([^:]+:[^:]+: )(.+)")
	e = textutils.unserialize(e)
	return prefix, e
end