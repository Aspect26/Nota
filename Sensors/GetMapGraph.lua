local sensorInfo = {
	name = "GetMapGraph",
	author = "Julius Flimmel",
	date = "2018-05-27",
	license = "N/A",
}

-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching
local SAMPLE_SIZE = 100

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
local spGetUnitRange = Spring.GetUnitMaxRange
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight

local function GetDistance(a, b)
    local xSqr = (a.x - b.x) * (a.x - b.x)
    local ySqr = (a.y - b.y) * (a.y - b.y)
    local zSqr = (a.z - b.z) * (a.z - b.z)
    return math.sqrt(xSqr + ySqr + zSqr)
end

local function IsInRange(unit, mapX, mapZ)
    local range = spGetUnitRange(unit)
    -- TODO: hardcoded range :(
    range = 200
    --Spring.Echo("RANGE: " .. range) <- dont uncomment this, causes crash :(

    local unitX, unitY, unitZ = spGetUnitPosition(unit)
    local mapHeight = spGetGroundHeight(mapX, mapZ)
    local distance = GetDistance({x = unitX, y = unitY, z = unitZ}, {x = mapX, y = mapHeight, z = mapZ})

    -- TODO: finetune this constant -> our unit will be above ground not on the ground
    return distance - 10 < range
end

local function GetEnemyUnits()
    -- TODO: hard coded team id :( :( :(
    return Spring.GetTeamUnits(1)
end

local function IsPointDangerous(x, y)
    local enemyUnits = GetEnemyUnits()

    for i=1, #enemyUnits do
        local unit = enemyUnits[i]
        if IsInRange(unit, x ,y) then
            return true
        end
    end

    return false
end

local function IsNodeInGraphDangerous(graph, x, y)
    local node = graph[x][y]
    if node.dangerous ~= nil then
        return node.dangerous
    else
        local dangerous = IsPointDangerous(node.x, node.y)
        node.dangerous = dangerous
        return node.dangerous
    end
end

local function CreateNode(sampleX, sampleY)
    local mapXPos = sampleX * SAMPLE_SIZE
    local mapYPos = sampleY * SAMPLE_SIZE

    return {
        x = mapXPos,
        y = mapYPos,
        neighbours = {}
    }
end


local function CreateNodes(samplesX, samplesY)
    local nodes = {}
    for x=1,samplesX do
        nodes[x] = {}
        for y=1,samplesY do
            nodes[x][y] = CreateNode(x ,y)
        end
    end

    return nodes
end

local function createEdgesFor(graph, x, y)
    local node = graph [x][y]
    if IsPointDangerous(node.x, node.y) then
        return
    end

    local edges = {}

    if x > 1 and not IsNodeInGraphDangerous(graph, x - 1, y) then
        edges[#edges + 1] = { x = x - 1, y = y }
    end

    if x < #graph and not IsNodeInGraphDangerous(graph, x + 1, y) then
        edges[#edges + 1] = { x = x + 1, y = y }
    end

    if y > 1 and not IsNodeInGraphDangerous(graph, x, y - 1) then
        edges[#edges + 1] = { x = x, y = y - 1}
    end

    if y < #graph[x] and not IsNodeInGraphDangerous(graph, x, y + 1) then
        edges[#edges + 1] = { x = x, y = y + 1}
    end

    graph[x][y].edges = edges
end

local function setEdges(graph)
    for x=1, #graph do
       for y=1, #graph[x] do
           createEdgesFor(graph, x, y)
       end
    end
end

return function()
	local width = mapWidth
    local height = mapHeight
    local samplesX = math.floor(width / SAMPLE_SIZE)
    local samplesY = math.floor(height / SAMPLE_SIZE)
    local nodes = CreateNodes(samplesX, samplesY)
    setEdges(nodes)

    return nodes
end
