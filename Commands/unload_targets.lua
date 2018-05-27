function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Unload picked units in safe area",
		parameterDefs = {
            {
                name = "safeArea",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "nil",
            },
        }
	}
end

-- GET SAFE AREA "core.MissionInfo().safeArea.center"

-- speed-ups
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spIsUnitDead = Spring.GetUnitIsDead

local SAFE_AREA_DISTANCE_THRESHOLD = 500 -- TODO: this can bea read from the mission info too!
local UNLOADING_WAIT_CYCLES = 10

local function ClearState(self)
    self.units = nil
    self.safeArea = nil
    self.issuedMoveToSafeArea = false
    self.allReachedSafeArea = false
    self.issuedUnloading = false
    self.waitedForUnloading = 0
end

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

local function UnitIsDead(unit)
    local dead = spIsUnitDead(unit)

    if dead == nil or dead == true then
        return true
    else
        return false
    end
end

local function IssueMoveOrders(self)
    for i=1, #self.units do
        local unit = self.units[i]
        -- TODO: use pathfinding!!
        spGiveOrderToUnit(unit, CMD.MOVE, { self.safeArea.x, self.safeArea.y, self.safeArea.z }, {})
    end

    self.issuedMoveToSafeArea = true
end

local function AllReachedSafeAreaOrDead(self)
    if self.allReachedSafeArea then
        return true
    end

    for i=1, #self.units do
        local rescuer = self.units[i]
        local rescuerX, rescuerY, rescuerZ = spGetUnitPosition(rescuer)
        if not UnitIsDead(rescuer) and Distance({x=rescuerX, y=rescuerY, z=rescuerZ}, self.safeArea) > SAFE_AREA_DISTANCE_THRESHOLD then
            return false
        end
    end

    self.allReachedSafeArea = true
    return true
end

local function IssueUnloading(self)
    for i=1, #self.units do
        local rescuer = self.units[i]
        local x, y, z = spGetUnitPosition(rescuer)
        spGiveOrderToUnit(rescuer, CMD.UNLOAD_UNITS, { x, y, z, 300 }, {})
    end

    self.issuedUnloading = true
end

local function AllTargetsUnloaded(self)
    for i=1, #self.units do
        local rescuer = self.units[i]
        if not UnitIsDead(rescuer) and #Spring.GetUnitIsTransporting(rescuer) > 0 then
            return false
        end
    end

    return true
end

local function Process(self)
    if not self.issuedMoveToSafeArea then
        IssueMoveOrders(self)
        return RUNNING
    end

    if not AllReachedSafeAreaOrDead(self) then
        return RUNNING
    end

    if self.waitedForUnloading == nil then
        self.waitedForUnloading = 0
    end

    if self.waitedForUnloading <= UNLOADING_WAIT_CYCLES then
        self.waitedForUnloading = self.waitedForUnloading + 1
        return RUNNING
    end

    if not self.issuedUnloading then
        IssueUnloading(self)
        return RUNNING
    end

    if not AllTargetsUnloaded(self) then
        return RUNNING
    end

    return SUCCESS
end

function Run(self, units, params)
    if #units == 0 then
        return TRUE
    end

    if not params.safeArea then
       return FAILURE
    end

    self.units = units
    self.safeArea = params.safeArea

    return Process(self)
end


function Reset(self)
	ClearState(self)
end
