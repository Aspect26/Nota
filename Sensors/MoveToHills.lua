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

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local spGiveOrder = Spring.GiveOrderToUnit

return function(hills)
	if #units > 0 then
		for i=1, #units do
			local unitID = units[i]
			hills[i].assignedTo = unitID
			spGiveOrder(unitID, CMD.MOVE, { hills[i].x, hills[i].height, hills[i].y }, {})
		end
		
	end
	
	return hills
end
