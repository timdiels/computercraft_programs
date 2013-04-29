-- This file is included by default on entire system

--- no-op (cfr assembly): no operation: a function that does nothing
function noop(...)
end

-- Careful, doesn't check for including the same file twice
function include(file)
	assert(shell.run("/lim_os/include/"..file), 2, "Error in included file")
end

-----------------
-- Include core
-----------------

include("core/assert.lua")
include("core/debug.lua")
include("core/exceptions.lua")
include("core/oo.lua")
include("core/io.lua")
include("core/table.lua")
include("core/gps.lua")
include("core/vector.lua")
include("core/log.lua")

include("core/Queue.lua")

---------------------------------------------------------------
-- Include everything else here too (to avoid including things twice)
---------------------------------------------------------------

include("Orientation.lua")

if turtle then
	include("turtle/turtle.lua")
	include("turtle/Direction.lua")
	include("turtle/engines.lua")
	include("turtle/Driver.lua")
	include("turtle/Miner.lua")
end