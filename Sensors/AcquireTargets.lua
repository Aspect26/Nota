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

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
    return {
        period = EVAL_PERIOD_DEFAULT
    }
end

-- TODO: add energy generators
local nonRescuableUnits = { armatlas = true, armpeep = true, armwin = true }

local function GetUnitsToRescue()
    -- TODO: hardcoded team ID :(
    local myUnits = Spring.GetTeamUnits(0)
    local unitsToRescue = {}

    if #myUnits > 0 then
        for i=1, #myUnits do
            local myUnit = myUnits[i]
            local unitDefID = Spring.GetUnitDefID(myUnit)
            local unitType = UnitDefs[unitDefID].name

            if not nonRescuableUnits[unitType] then
                unitsToRescue[#unitsToRescue + 1] = myUnit
            end
        end
    end

    return unitsToRescue
end


return function()
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
