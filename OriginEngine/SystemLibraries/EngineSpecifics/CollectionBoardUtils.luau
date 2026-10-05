local engineSpecifics = script.Parent
local systemLibraries = engineSpecifics.Parent

local Signal = require(systemLibraries.Components.Signal)

local CollectionBoardUtils = {}
local storedCollections = {}:: {[string]: CollectionObject}

local NEW_COLLECTION_SIGNAL = Signal.new()

export type CollectionObject = typeof(CollectionBoardUtils.NewUnMarkedCollection())

local collectionStoreMeta = {} do
	collectionStoreMeta.__index = collectionStoreMeta
	
	function collectionStoreMeta.Get(collectionObject: CollectionObject, path: {string})
		if not path or #path <= 0 then
			return collectionObject.Data
		end
		
		const pathLength = #path
		local root = collectionObject.data

		const path = table.clone(path)
		const index = table.remove(path, pathLength)

		for i=1, pathLength - 1 do
			root = root[path[i]]

			if not root then
				return nil
			end
		end

		return root[index], root, index
	end	
	
	function collectionStoreMeta.Set<t>(collectionObject: CollectionObject, path: {string}, value: t): t
		const oldValue, root, index = collectionObject:Get(path)

		if root then
			root[index] = value
			collectionObject._priv.onChange:Fire(path, index, oldValue, value)
		end
	end
	
	function collectionStoreMeta.FindValue(collectionObject: CollectionObject, path: {string}, value): any?
		const arrayValue, root, index = collectionObject:Get(path)

		if typeof(arrayValue) == "table" then
			return table.find(arrayValue, value)
		end
	end

	function collectionStoreMeta.InsertValue<t>(collectionObject: CollectionObject, path: {string}, value: t): t
		const arrayValue, root, index = collectionObject:Get(path)

		if typeof(arrayValue) == "table" then
			const newPath = table.clone(path)

			table.insert(newPath, #arrayValue+1)
			table.insert(arrayValue, value)

			collectionObject._priv.onChange:Fire(newPath, #arrayValue, nil, value)
		end
	end

	function collectionStoreMeta.RemoveValue(collectionObject: CollectionObject, path: {string}, valueIndex: number)
		const arrayValue, root, index = collectionObject:Get(path)

		if typeof(arrayValue) == "table" then
			const newPath = table.clone(path)
			const oldValue = table.remove(arrayValue, valueIndex)

			if oldValue then
				table.insert(newPath, valueIndex)
				collectionObject._priv.onChange:Fire(newPath, #newPath, oldValue, nil)
			end
		end
	end

	function collectionStoreMeta.OnPathChanged(
		collectionObject: CollectionObject,
		path: {string}, 
		callback: (
			path: {string}, 
			index: any,
			oldValue: any,
			value: any
		)->nil)


		return collectionObject._priv.onChange:Connect(function(recievedPath, index, oldValue, Value)
			for index, pathElement in path do
				local recievedPathValue = recievedPath[index]
				if not (recievedPathValue and recievedPathValue == pathElement) then
					return
				end
			end

			callback(recievedPath, index, oldValue, Value)
		end)
	end

	function collectionStoreMeta.OnValueChanged(
		collectionObject: CollectionObject,
		path: {string}, 
		callback: (
			path: {string}, 
			oldValue: any,
			value: any
		)->nil)

		const pathLength = #path

		return collectionObject._priv.onChange:Connect(function(recievedPath, index, oldValue, Value)
			if #recievedPath ~= pathLength then
				return
			end  

			for index, pathElement in path do
				local recievedPathValue = recievedPath[index]
				if not (recievedPathValue and recievedPathValue == pathElement) then
					return
				end
			end

			callback(recievedPath, oldValue, Value)
		end)
	end
end

function CollectionBoardUtils.GetAllCollections(): {[string]: CollectionObject}
	return storedCollections
end

function CollectionBoardUtils.AwaitCollection(requestedHeader: string, yieldTime: number?): CollectionObject
	local awaitedCollection = storedCollections[requestedHeader]
	if awaitedCollection then
		return awaitedCollection
	end
	
	local currentThread = coroutine.running()
	local cancelAwaitThread: thread = nil
	local awaitConnection = NEW_COLLECTION_SIGNAL:Connect(function(header, collection)
		if cancelAwaitThread then
			task.cancel(cancelAwaitThread)
		end
		
		if requestedHeader == header then
			coroutine.resume(currentThread, collection)
		end
	end)
	
	local cancelAwaitThread = task.delay(yieldTime, function()
		cancelAwaitThread = nil
		awaitedCollection:Disconnect()
		coroutine.resume(currentThread)
	end)
	
	return coroutine.yield()
end

function CollectionBoardUtils.GetCollection(requestedHeader: string): CollectionObject
	return storedCollections[requestedHeader]
end

function CollectionBoardUtils.GetOrCreateCollection(requestedHeader: string)
	local newCollection = CollectionBoardUtils.NewUnMarkedCollection()
	collectionStoreMeta[requestedHeader] = newCollection
	
	NEW_COLLECTION_SIGNAL:Fire(requestedHeader, collectionStoreMeta)
end 

function CollectionBoardUtils.NewUnMarkedCollection()
	local collectionMock = {
		_priv = {
			onChange = Signal.new()
		},
		data = {}
	}
	
	return setmetatable(collectionMock, collectionStoreMeta)
end

return CollectionBoardUtils
