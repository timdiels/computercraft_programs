-- This file included by default on entire system

--- no-op (cfr assembly): no operation: a function that does nothing
function noop(...)
end

-----------------------
-- error handling
-----------------------

local _error = error
function error(table_, level)
	level = level or 1
	if level == 0 then
		level = 1  -- force level > 0, as our exception handler expects this
	end
	_error(textutils.serialize(table_), level+1)
end

-- print and abort
local function handle_exception(error_string)
	prefix, e = string.match(error_string, "([^:]+:[^:]+: )(.+)")
	e = textutils.unserialize(e)
	if type(e) == "table" then
		e = e.message..' ('..e.type..')'
	end
	print(prefix..e)
	_error()  -- abort
end

-- exactly like pcall, but doesn't display thrown error
function try(...)
	return xpcall(unpack(arg), noop)
end

-- func: a function with no args that returns nothing
function catch(func)
	xpcall(func, handle_exception)
end


----------------
-- Assertions
----------------

local function AssertionException(message, level)
	level = level or 1
	error({type="AssertionException", message=message}, level+1)
end

function assert(condition, message, level)
	level = level or 1
	message = message or "Assertion failed"
	if not condition then
		AssertionException(message, level+1)
	end
end

function require_(condition, level)
	level = level or 1
	assert(condition, 'Require failed', level+1)
end

function ensure(condition, level)
	level = level or 1
	assert(condition, 'Ensure failed', level+1)
end


----------------------
-- Debugging utils
----------------------

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


-----------------
-- OO Base
-----------------

Object = {}

-- self is the object, not its metatable
function Object.__index_func(self, key)
	local value = getmetatable(self)[key]
	if type(value) == "function" then
		-- assume it's not a static function, we don't support those currently
		function method(...)
			return value(self, unpack(arg))
		end
		return method
	else
		return value
	end
end

function Object:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = Object.__index_func
	return obj
end


------------
-- More io
------------

-- path: abs path
-- if path does not exist, returns nil
function io.from_file(path)
	require_(type(path) == "string")

	if not fs.exists(path) then
		return
	end
	
	local f = fs.open(path, 'r')
	if not f then
		Exception("Failed to open: "..path)
	end
	
	local table_ = textutils.unserialize(f.readAll())
	f.close()
	return table_
end

-- path: abs path
function io.to_file(path, table_)
	require_(type(path) == "string")
	require_(type(table_) == "table")
	
	local f = fs.open(path, 'w')
	if not f then
		Exception("Failed to open: "..path)
	end
	
	local str = textutils.serialize(table_)
	f.write(str)
	f.close()
end


--------------
-- More table
--------------

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

--------------------------------------
-- Turtle api that throws exceptions
--------------------------------------
if turtle then
	local _turnLeft = turtle.turnLeft
	function turtle.turnLeft()
		assert(_turnLeft(), "turtle api lied")
	end

	local _turnRight = turtle.turnRight
	function turtle.turnRight()
		assert(_turnRight(), "turtle api lied")
	end

	local _forward = turtle.forward
	function turtle.forward()
		if not _forward() then
			Exception("Failed to move forward")
		end
	end

	local _back = turtle.back
	function turtle.back()
		if not _back() then
			Exception("Failed to move backward")
		end
	end

	local _down = turtle.down
	function turtle.down()
		if not _down() then
			Exception("Failed to move down")
		end
	end

	local _up = turtle.up
	function turtle.up()
		if not _up() then
			Exception("Failed to move up")
		end
	end

	local _dig = turtle.dig
	function turtle.dig()
		if not _dig() then
			Exception("Failed to dig")
		end
	end

	local _digDown = turtle.digDown
	function turtle.digDown()
		if not _digDown() then
			Exception("Failed to dig down")
		end
	end

	local _digUp = turtle.digUp
	function turtle.digUp()
		if not _digUp() then
			Exception("Failed to dig up")
		end
	end
end


-----------
-- Other
-----------

-- Careful, doesn't check for including the same file twice
function include(file)
	assert(shell.run("/lim_os/include/"..file), "Error in included file", 2)
end

-- basic Exception
function Exception(message)
	error({type="Exception", message=message}, 2)
end


---------------------------------------------------------------
-- Include everything here (to avoid including things twice)
---------------------------------------------------------------

include("Orientation.lua")
include("turtle/Driver.lua")
