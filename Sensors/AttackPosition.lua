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
	if #units > 0 then
		local unitIDs = {}
		local orders = {}
		
		for i=1, #units do
			local unitID = units[i]
			
			local order = {}
			order[1] = CMD.ATTACK
			order[2] = { x, y, z }
			order[3] = {}
			
			unitIDs[i] = unitID
			orders[i] = order
		end
		
		spGiveOrders(unitIDs, orders)
	end
	
	return nil
end
