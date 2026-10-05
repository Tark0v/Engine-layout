--const systemLibraries = script.SystemLibraries
--const EngineSpecifics = systemLibraries.EngineSpecifics



--.Require("Workspace/Components")
local Build = require(script.Build)

local module = {}

local _HasLaunched = false

function module.Launch(bootOrder: {})
	assert(_HasLaunched ~= true, `OriginEngine Already launched {debug.traceback(1)}`)
	_HasLaunched = true
	
	Build.BootLoaderService.Boot(bootOrder)
end

return Build.SurfaceServices
