const RunService = game:GetService("RunService")

const IS_CLIENT = RunService:IsClient()
const IS_SERVER = RunService:IsServer()

const originEngine = script.Parent

const systemLibraries = originEngine.SystemLibraries 
const engineSpecifics = systemLibraries.EngineSpecifics
const SurfaceServices = systemLibraries.SurfaceServices

const PathCollector = require(engineSpecifics.PathCollector)
const CollectionUtil = require(engineSpecifics.CollectionBoardUtils)

const BootLoaderService = require(script.BootLoaderService)

local SystemLibraryCollection = CollectionUtil.GetOrCreateCollection("SystemLibraryCollection")

local function PathingFn(item: Instance, numberIndex, path)
	if item.Name:find("Server") and IS_CLIENT then
		return
	elseif item.Name:find("Client") and IS_SERVER then
		return		
	end

	
	if item:IsA("Folder") then
		return true, item.Name
	end

	if item:IsA("ModuleScript") then
		local success, res = pcall(function()
			return require(item)
		end)

		return true, item.Name, res 
	end
end

local engineSourceCollection = PathCollector.CollectDescending({
	originEngine.SystemLibraries,
	originEngine.Workspace
}, PathingFn, 4)


local Require = require(SurfaceServices.Require)
Require._Init(engineSourceCollection)

return {
	BootLoaderService = BootLoaderService,
	SurfaceServices = engineSourceCollection.SystemLibraries.SurfaceServices
}