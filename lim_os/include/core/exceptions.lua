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
	local prefix, e = exception.deserialize(error_string)
	if type(e) == "table" then
		e = e.message..' ('..e.type..')'
	end
	local message = prefix..e
	print(message)
	log(message)
end

-- print and abort
local function handle_exception(error_string)
	print_exception(error_string)
	_error()  -- abort
end

-- exactly like pcall, but doesn't display thrown error
function try(...)
	local f = table.remove(arg, 1)
	return xpcall(function() f(unpack(arg)) end, noop)
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

exception = {}
function exception.deserialize(str)
	local prefix, e = string.match(error_string, "([^:]+:[^:]+: )(.+)")
	e = textutils.unserialize(e)
	return prefix, e
end