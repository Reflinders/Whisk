--[[
	@@ Whisk
	
	Lightweight cleaner class
	
	~ Reflinders
]]

--[[
	Version => 1.0 -- RELEASE!!!
]]

function cleanup(obj, method)
	if typeof(method) == "function" then
		method(obj)

		return	
	end

	if method == "function" then
		obj()
	elseif method == "thread" then
		task.cancel(obj)
	else
		obj[method](obj)
	end
end

function getCleanMethod(obj)
	local t = typeof(obj)

	if t == "Instance" then
		return "Destroy"
	elseif t == "RBXScriptConnection" then
		return "Disconnect"
	end

	if t == "table" then
		return (obj.Destroy and "Destroy") 
			or (obj.Disconnect and "Disconnect")
	end

	return t
end

--@ Class `Whisk`

local Whisk = {}

do
	Whisk.__index = Whisk

	--@ Static function that returns whether or not an object is an instance of `Whisk`
	function Whisk:is()
		return type(self) == "table" and getmetatable(self) == Whisk
	end

	--@ Static function made as a util; cleans things up in the same manner as `Destroy`
	function Whisk.Cleanup(stuff: { any })
		for _, obj in stuff do
			cleanup(obj, getCleanMethod(obj))
		end

		table.clear(stuff)
	end

	--@ Creates a new `Whisk` instance and 'parents' it onto the instance called
	function Whisk.Extends<T>(self: T): T
		return self:Collect(Whisk.new())
	end

	--@ Removes a particular object from the cleaning queue with the additional option of having it not be cleaned
	function Whisk:Remove(foo: any, avoidClean: boolean)
		local method = self[foo]
		
		if method then
			if not avoidClean then
				cleanup(foo, method)
			end
			
			self[foo] = nil
		end
	end

	--@ Alternative of `Collect` that accepts a tuple rather than a singular object
	--@ unlike `Collect`, `Heap` cannot accept custom cleaning methods
	function Whisk:Heap(...)
		for _, item in {...} do
			self[item] = getCleanMethod(item)
		end
	end

	--@ Alternaive of `Collect` that is particularly made for signals
	function Whisk:Hook(signal: RBXScriptSignal | { Connect: () -> () }, qux: () -> ())
		return Whisk:Collect(signal:Connect(qux))
	end

	--@ Sole method for executing the cleaning queue; of course, it can be ran more than once
	function Whisk:Destroy()
		for item, method in self do
			cleanup(item, method)
		end	

		table.clear(self)
	end

	--@ Collects an object and adds it into the cleaning queue
	--@ optionally, you could give it a custom cleaning method that comes in the form of a function or string
	function Whisk:Collect<T>(item: T, method: (T) -> ()?)
		self[item] = method or getCleanMethod(item)

		return item
	end

	--@ Constructor :: Class `Whisk`
	function Whisk.new(): Type
		return setmetatable({}, Whisk)	
	end

	Whisk.Add = Whisk.Collect
end

export type Type = typeof(setmetatable({}, Whisk))

return Whisk
