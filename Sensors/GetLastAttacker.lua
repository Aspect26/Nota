local sensorInfo = {
	name = "GetUnitsLastAttacker",
	desc = "Gets random last attacker if any unit has one.",
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
local spGetLastAttacker = Spring.GetUnitLastAttacker

return function()
	if #units > 0 then
		for i=1, #units do
			local lastAttacker = spGetLastAttacker(units[i])
			if lastAttacker ~= nil then
				return lastAttacker
			end
		end
	end
	
	return nil
end
