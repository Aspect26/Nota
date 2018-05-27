local sensorInfo = {
    name = "AcquireTargets",
    author = "Julius Flimmel",
    date = "2018-05-27",
    license = "N/A",
}

-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "message") -- communication backend load

local spGetUnitPosition = Spring.GetUnitPosition

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
    return {
        period = EVAL_PERIOD_DEFAULT
    }
end

local nonRescuableUnits = { armatlas = true, armpeep = true, armwin = true }
local safeAreaCenter = {}

local function Distance(a, b)
    if not a or not b or not a.x or not a.y or not a.z or not b.x or not b.y or not b.z then
        -- magic constant
        return 926232
    end

    local xSqr = (a.x - b.x) * (a.x - b.x)
    local ySqr = (a.y - b.y) * (a.y - b.y)
    local zSqr = (a.z - b.z) * (a.z - b.z)
    return math.sqrt(xSqr + ySqr + zSqr)
end

local function UnitNeedsRescuing(unit)
    local unitDefID = Spring.GetUnitDefID(unit)
    local unitType = UnitDefs[unitDefID].name

    if nonRescuableUnits[unitType] then
        return false
    else
        local x, y, z = spGetUnitPosition(unit)
        -- TODO: hardcoded area :(
        return Distance({x=x,y=y,z=z}, safeAreaCenter) > 600
    end
end

local function GetUnitsToRescue()
    -- TODO: hardcoded team ID :(
    local myUnits = Spring.GetTeamUnits(0)
    local unitsToRescue = {}

    if #myUnits > 0 then
        for i=1, #myUnits do
            local myUnit = myUnits[i]
            if UnitNeedsRescuing(myUnit) then
                unitsToRescue[#unitsToRescue + 1] = myUnit
            end
        end
    end

    return unitsToRescue
end


return function(safeArea)
    safeAreaCenter = safeArea
    local targetsMap = {}
    local unitsToRescue = GetUnitsToRescue()

    if #units > 0 and #unitsToRescue > 0 then
        for i=1, #units do
            if #unitsToRescue >= i then
                targetsMap[units[i]] = unitsToRescue[i]
            end
        end
    end

    return targetsMap
end
