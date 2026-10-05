local pathCollectorSingletons = {}

function pathCollectorSingletons.CollectDescending(directory: any, indexFn: (item: any, nextIndex: number)->(boolean, any, any?), maxDepth: number?)
	local function GetDescendants(item)
		if typeof(item) ~= "table" then
			item = item:GetChildren()
		end
		
		return item
	end
	
	local function Descend(root, depth: number, path: {})
		local collection = {}
		local descendants = GetDescendants(root)
		
		depth = (depth or 0) + 1
		if depth > maxDepth then
			return
		end
		
		local nextIndex = 1
		for _, item in descendants do
			path = path and table.clone(path) or {}
			
			local shouldCollect, index, value = indexFn(item, nextIndex, path)
			
			if not shouldCollect then
				continue
			end
			
			if index == nil then
				Descend(item, depth, path)
				continue
			end
			
			table.insert(path, index)
			
			if value == nil then
				collection[index] = Descend(item, depth, path)
			else
				collection[index] = value
			end
			
			nextIndex += 1
		end
		
		return collection
	end
	
	return Descend(directory, 0)
end

function pathCollectorSingletons.Collect(
	directory: any,
	indexFn: (item: any, nextIndex: number)->(boolean, any, any)
): {[any]: any}
	
	if typeof(directory) ~= "table" then
		directory = directory:GetChildren()
	end
	
	local collection = {}
	local nextIndex = 1
	for _, item in directory do
		local shouldCollect, index, value = indexFn(item, nextIndex)
		
		if shouldCollect and index and value then
			nextIndex += 1
			collection[index] = value
		end
	end 
	
	return collection
end

--function pathcollectorSingletons.FilterCollect(directory: Instance, indexFn: (path: {string}, ))

return pathCollectorSingletons
