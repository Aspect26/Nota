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
local spGiveOrders = Spring.GiveOrderArrayToUnitArray

function isFarEnough(sample, excludes, radius) 
	if #excludes > 0 then
		for i=1,#excludes do
			local exclude = excludes[i]
			if math.abs(sample.x - exclude.x) < radius or math.abs(sample.y - exclude.y) < radius then
				return { is=false, exclude=exclude }
			end
		end
		return { is=true }
	else
		return { is=true }
	end
end

function getMax(samples, excludes, radius)
	local currentMax = { height = 0 }
	for x=0,#samples do
		for y=0,#samples[x] do
			if samples[x][y].height > currentMax.height and isFarEnough(samples[x][y], excludes, radius).is then
				currentMax = samples[x][y]
			end
		end
	end
	
	return currentMax
end

function enemiesToSamples(enemies)
	local samples = {}
	for i=1,#enemies do
		samples[i] = { x = enemies[i].x, height = enemies[i].y, y = enemies[i].z }
	end
	
	return samples
end

function getSafeAndUnsafe(hills, enemies, radius)
	enemies = enemiesToSamples(enemies)
	local safe = {}
	local unsafe = {}
	
	for i=1,#hills do
		local hill = hills[i]
		local farEnough = isFarEnough(hill, enemies, radius)
		if farEnough.is then
			safe[#safe + 1] = hill
		else
			unsafe[#unsafe + 1] = hill
			unsafe[#unsafe].enemy = farEnough.exclude
		end
	end
	
	return { safe=safe, unsafe=unsafe }
end

function getMaxFour(samples, enemies, radius)
	local maxes = {}
	
	for i=1,4 do
		local newMax = getMax(samples, maxes, radius)
		maxes[i] = newMax
	end

	return getSafeAndUnsafe(maxes, enemies, radius)
end

return function(enemies)
	local samples = {}
	local width = Game.mapSizeX
	local height = Game.mapSizeZ
	local samplingSize = 50;
	local samplesWidth = math.floor(width / samplingSize)
	local samplesHeight = math.floor(height / samplingSize)
	
	for x=0,samplesWidth do
		samples[x] = {}
		for y=0,samplesHeight do
			local xPos = x * samplingSize
			local yPos = y * samplingSize
			samples[x][y] = { x=xPos, y=yPos, height=Spring.GetGroundHeight(xPos, yPos) }
		end
	end
	
	return getMaxFour(samples, enemies, 100)
end
