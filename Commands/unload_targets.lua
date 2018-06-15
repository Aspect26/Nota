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

local SAFE_AREA_RADIUS = 600 -- TODO: this can bea read from the mission info too!
local UNLOADING_WAIT_CYCLES = 4
local UNLOADING_RESTART_TIMEOUT = 14
local UNIT_UNLOADING_DISTANCE = 75

local function ClearState(self)
    self.units = nil
    self.safeArea = nil
    self.unitTargets = nil
    self.issuedMoveToSafeArea = false
    self.allReachedSafeArea = false
    self.issuedUnloading = false
    self.waitedForUnloading = 0
    self.waitedForUnloadRestart = 0
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

local function GetLocationOutsideSafeArea(self)
    local fixedPoint = { x=self.safeArea.x + SAFE_AREA_RADIUS, y=self.safeArea.y, z=self.safeArea.z + SAFE_AREA_RADIUS }
    local offsetedPoint = { x=fixedPoint.x + math.random(350), y=fixedPoint.y, z=fixedPoint.z + math.random(350) }
    return offsetedPoint
end

local function GetRandomLandingLocation(self)
    return {
        x=self.safeArea.x + math.random(-SAFE_AREA_RADIUS / 2, SAFE_AREA_RADIUS / 2),
        y=self.safeArea.y,
        z=self.safeArea.z + math.random(-SAFE_AREA_RADIUS / 2, SAFE_AREA_RADIUS / 2)
    }
end

local function IsFreeLocation(position, forbiddenPositions)
    if (not forbiddenPositions) or (#forbiddenPositions == 0) then
        return true
    end

    for i=1, #forbiddenPositions do
        local forbiddenPosition = forbiddenPositions[i]
        local distance = Distance(position, forbiddenPosition)
        if distance < UNIT_UNLOADING_DISTANCE then
            return false
        end
    end

    return true
end

local function IssueMoveOrders(self)
    -- TODO: hardcoded team ID :(
    local myUnits = Spring.GetTeamUnits(0)
    local forbiddenLocations = {}
    for i=1, #myUnits do
        local x,y,z = Spring.GetUnitPosition(myUnits[i])
        forbiddenLocations[#forbiddenLocations + 1] = { x=x, y=y, z=z }
    end

    -- TODO: use pathfinding!!
    for i=1, #self.units do
        local unit = self.units[i]
        if #Spring.GetUnitIsTransporting(unit) > 0 then

            local position = GetRandomLandingLocation(self)

            while not IsFreeLocation(position, forbiddenLocations) do
                position = GetRandomLandingLocation(self)
            end

            forbiddenLocations[#forbiddenLocations + 1] = position
            spGiveOrderToUnit(unit, CMD.MOVE, { position.x, position.y, position.z }, {})
        end
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
        if not UnitIsDead(rescuer) and Distance({x=rescuerX, y=rescuerY, z=rescuerZ}, self.safeArea) > SAFE_AREA_RADIUS then
            return false
        end
    end

    self.allReachedSafeArea = true
    return true
end

local function IssueUnloading(self)
    Spring.Echo("ISSUING UNLOADING")
    for i=1, #self.units do
        local rescuer = self.units[i]
        if #Spring.GetUnitIsTransporting(rescuer) > 0 then
            Spring.Echo("Issued unloading unit: " .. rescuer)
            local x, y, z = spGetUnitPosition(rescuer)
            spGiveOrderToUnit(rescuer, CMD.UNLOAD_UNIT, { x, y, z }, {})
        end
    end

    self.issuedUnloading = true
end

local function AllTargetsUnloaded(self)
    if not self.unitTargets then
        self.unitTargets = {}
    end

    local finished = true
    for i=1, #self.units do
        local rescuer = self.units[i]
        if not UnitIsDead(rescuer) and #Spring.GetUnitIsTransporting(rescuer) > 0 then
            finished = false
        else
            if not self.unitTargets[rescuer] then
                local moveAwayLocation = GetLocationOutsideSafeArea(self)
                self.unitTargets[rescuer] = moveAwayLocation
                spGiveOrderToUnit(rescuer, CMD.MOVE, {moveAwayLocation.x, moveAwayLocation.y, moveAwayLocation.z}, {})
            end
        end
    end

    return finished
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
        self.waitedForUnloadRestart = 0
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
        self.waitedForUnloadRestart = self.waitedForUnloadRestart + 1

        Spring.Echo(self.waitedForUnloadRestart)
        if self.waitedForUnloadRestart == UNLOADING_RESTART_TIMEOUT / 2 then
            IssueMoveOrders(self)
        end
        if self.waitedForUnloadRestart == UNLOADING_RESTART_TIMEOUT then
            IssueUnloading(self)
            self.waitedForUnloadRestart = 0
        end

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
