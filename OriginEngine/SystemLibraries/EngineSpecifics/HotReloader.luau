local engineSpecifics = script.Parent
local systemLibraries = engineSpecifics.Parent

local Maid = require(systemLibraries.Components.Maid)

local hotReloaderSingletons = {}

local runningThreads = {}
local markedReloaders = {}

function hotReloaderSingletons.BuildReloader(reloadID: string, src)
	assert(
		markedReloaders[reloadID] == false, 
		`{reloadID} has already been built consider calling .Reload instead`
	)
	
	local initMethod = assert(src.Init or src._Init, `{reloadID} Missing Init method {src}`)
	
	local reloadMaid = Maid.new()
	local reloadThread = nil
	
	local function NewReloader()
		if reloadMaid then
			reloadMaid:DoCleaning()
		end
		
		reloadThread = reloadMaid:Add(coroutine.create(function(...) 
			coroutine.yield()
			initMethod(...)
		end))
	end
	
	return function()
		coroutine.resume(reloadThread)
		
	end
end


return hotReloaderSingletons
