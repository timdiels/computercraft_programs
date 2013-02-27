catch(function()

include("turtle/Engine.lua")
include("turtle/UpEngine.lua")
include("turtle/DownEngine.lua")
include("turtle/ForwardEngine.lua")

turtle.engines = {
	[Direction.FORWARD]=ForwardEngine:new(),
	[Direction.UP]=UpEngine:new(),
	[Direction.DOWN]=DownEngine:new(),
}

end)