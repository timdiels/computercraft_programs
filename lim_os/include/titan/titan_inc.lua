CHUNK_SIZE = 16
TERRAIN_HEIGHT_MAX = 130  -- the max height at which a block of terrain (tree, dirt, ...) can occur

if turtle then
	include("titan/Drone.lua")
end

include("titan/MiningSystem.lua")
include("titan/BuildSystem.lua")
include("titan/GarbageSystem.lua")
include("titan/Titan.lua")