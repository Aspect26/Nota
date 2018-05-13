local sensorInfo = {
	name = "AttackUnit",
	author = "Julius Flimmel",
	date = "2018-05-13",
	license = "N/A",
}

-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching
local commanderID = 0

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local spGiveOrders = Spring.GiveOrderArrayToUnitArray

return function(x, y, z)
	if y == nil then
		if x == nil then
			return nil
		else
			x, y, z = Spring.GetUnitPosition(x)
		end
	end
	if #units > 0 then
		local unitIDs = {}
		local orders = {}
		
		for i=1, #units do
			local unitID = units[i]
			local unitX, unitY, unitZ = Spring.GetUnitPosition(unitID)
			local direction = { x = x - unitX, y = y - unitY, z = z - unitZ }
			local directionLength = math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
			if directionLength < 100 then
				return nil
			end
			local directionFactor = 100;
			direction = { x = (direction.x / directionLength) * directionFactor, y = (direction.y / directionLength) * directionFactor, z = (direction.z / directionLength) * directionFactor }
			directionLength = math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
			
			local order = {}
			order[1] = CMD.MOVE
			order[2] = { unitX + direction.x, unitY + direction.y, unitZ + direction.z }
			order[3] = {}
			
			unitIDs[i] = unitID
			orders[i] = order
		end
		
		spGiveOrders(unitIDs, orders)
	end
	
	return nil
end
