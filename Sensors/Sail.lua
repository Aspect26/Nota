local sensorInfo = {
	name = "Sailing",
	desc = "Implementes sailing behavior.",
	author = "Julius Flimmel",
	date = "2018-05-02",
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
local spGetWind = Spring.GetWind
local spGiveOrders = Spring.GiveOrderArrayToUnitArray
local spGetPosition = Spring.GetUnitPosition
local spGetTooltip = Spring.GetUnitTooltip

function getUnitStrategy(unitID) 
	-- Isn't there a better way to get unit type?
	if spGetTooltip(unitID) == 'Battle Commander - Assault Leader' then
		return commanderStrategy
	else 
		return otherStrategy
	end
end

function commanderStrategy(unitID)
	commanderID = unitID
	local commanderPosX, commanderPosY, commanderPosZ = spGetPosition(commanderID)
	local dirX, dirY, dirZ, strength, windDirX, windDirY, windDirZ = spGetWind()
	
	moveLocationX = commanderPosX + windDirX * 200
	moveLocationY = commanderPosY + windDirY * 200
	moveLocationZ = commanderPosZ + windDirZ * 200
	
	return CMD.MOVE, { moveLocationX, moveLocationY, moveLocationZ }
end

function otherStrategy(unitID) 
	return CMD.GUARD, { commanderID }
end

-- @description return current wind statistics
return function()
	if #units > 0 then
		local unitIDs = {}
		local orders = {}
		
		for i=1, #units do
			local unitID = units[i]
			local unitStrategy = getUnitStrategy(unitID)
			local command, params = unitStrategy(unitID)
			
			local order = {}
			order[1] = command
			order[2] = params
			order[3] = {}
			
			unitIDs[i] = unitID
			orders[i] = order
		end
		
		spGiveOrders(unitIDs, orders)
	end
end
