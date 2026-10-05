local requireSingletons = {}

local source = {}

local defaultParser = "/"

local function splitPath(path: string, parser)
	local parser = parser or defaultParser
	
	if typeof(path) == "string" then
		path = path:split(parser)
	end
	
	return path
end 

local function PathResolver(path: string, requireParams)
	path = splitPath(path, requireParams.Parser)
	
	local resolvedPath = source
	for _, nextPath in path do
		resolvedPath = resolvedPath[nextPath]
		
		if not resolvedPath then
			return nil
		end
	end
	
	return resolvedPath
end

function requireSingletons._Init(packages: {})
	source = packages
end

function requireSingletons.Require(path: string, requireParams: {})
	requireParams = requireParams or {}
	
	local resolvePath = PathResolver(path, requireParams)
	return resolvePath
end

function requireSingletons.AwaitRequire(path: string, yieldTime: number, requireParams: {})
	requireParams = requireParams or {}
	
	local splitPath = splitPath(path, requireParams)
	local resolvedPath = PathResolver(splitPath, requireParams)
	if resolvedPath then
		return resolvedPath
	end
	
	local timeBetween = .01
	local now = os.clock()
	
	while not resolvedPath do
		resolvedPath = PathResolver(splitPath, requireParams)
		
		if yieldTime and os.clock() - now >= yieldTime then
			break
		end
		
		task.wait(timeBetween)		
	end
	
	return resolvedPath
end

return requireSingletons
