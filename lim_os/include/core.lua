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
include("core/turtle.lua")
include("core/gps.lua")


---------------------------------------------------------------
-- Include everything else here too (to avoid including things twice)
---------------------------------------------------------------

include("Orientation.lua")
include("turtle/Direction.lua")
include("turtle/UpEngine.lua")
include("turtle/DownEngine.lua")
include("turtle/ForwardEngine.lua")
include("turtle/Driver.lua")
include("turtle/Miner.lua")
