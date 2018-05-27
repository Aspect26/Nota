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
local SAMPLE_SIZE = 2000

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

local echo = Spring.Echo

local function EchoNode(graph, x, y)
    local node = graph[x][y]
    local edgesString = ""
    if node.edges then
        for e=1, #node.edges do
            local edge = node.edges[e]
            edgesString = edgesString .. "(" .. edge.x .. "," .. edge.y .. "),"
        end
    end

    echo("Node(" .. x .. "," .. y .. "): X=" .. node.x .. ",Y=" .. node.y .. ",E=" .. edgesString)
end

return function(mapGraph)
    echo("Width: " .. #mapGraph .. ", Height: " .. #mapGraph[1])
    for x=1, #mapGraph do
       for y=1, #mapGraph[x] do
          EchoNode(mapGraph, x, y)
       end
    end
end
