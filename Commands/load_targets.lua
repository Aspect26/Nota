function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Acquire targets for picking units",
		parameterDefs = {
            {
                name = "unitTargets",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "nil",
            },
        }
	}
end

-- speed-ups
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spIsUnitDead = Spring.GetUnitIsDead

local TARGET_DISTANCE_THRESHOLD = 100

local function ClearState(self)
	self.unitTargets = nil
    self.allReachedTargets = false
    self.issuedLoading = false
end

local function Distance(a, b)
    -- TODO: WTF? why does they do not contain the x,y,z????
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

local function SetUnitPaths(self, unitTargets)
    local dataWithPath = {}
    for rescuer, rescuee in pairs(unitTargets) do
        local x, y, z = spGetUnitPosition(rescuee)
        dataWithPath[rescuer] = {
            -- TODO: implement path searching
            path = {
                { x, y, z  }
            },
            unit = rescuee
        }
    end
    self.unitTargets = dataWithPath
end

local function CreateMoveCommands(path)
    if #path == 0 then
        return {}
    else
        local commands = {}
        for i=1, #path do
            local pathPoint = path[i]
            local command = {
                id = CMD.MOVE,
                params = pathPoint,
            }
            commands[#commands + 1] = command
        end

        return commands
    end
end

local function IssueMoveOrders(self)
    for rescuer, rescueData in pairs(self.unitTargets) do
        local rescuePath = rescueData.path
        local moveCommands = CreateMoveCommands(rescuePath)
        if #moveCommands ~= 0 then
            for i=1, #moveCommands do
                local command = moveCommands[i]
                spGiveOrderToUnit(rescuer, command.id, command.params, {"shift"})
            end
        end
    end
end

local function AllReachedTargetsOrDead(self)
    if self.allReachedTargets then
        return true
    end

    local unitsNotReached = 0

    for rescuer, rescueData in pairs(self.unitTargets) do
        local rescuerX, rescuerY, rescuerZ = spGetUnitPosition(rescuer)
        local targetX, targetY, targetZ = spGetUnitPosition(rescueData.unit)
        if not UnitIsDead(rescuer) and Distance({x=rescuerX, y=rescuerY, z=rescuerZ}, {x=targetX, y=targetY, z=targetZ}) > TARGET_DISTANCE_THRESHOLD then
            unitsNotReached = unitsNotReached + 1
        end
    end

    Spring.Echo("RESCUEES NOT REACEHD: " .. unitsNotReached)
    -- TODO: HACK HERE!!!!!!
    if unitsNotReached <= 2 then
        self.allReachedTargets = true
        return true
    else
        return false
    end
end

local function IssueLoading(self)
    for rescuer, rescueData in pairs(self.unitTargets) do
        local rescuee = rescueData.unit
        spGiveOrderToUnit(rescuer, CMD.LOAD_UNITS, { rescuee }, {})
    end

    self.issuedLoading = true
end

local function AllTargetsLoaded(self)
    for rescuer, rescueData in pairs(self.unitTargets) do
        local rescuee = rescueData.unit
        if not UnitIsDead(rescuer) and not UnitIsDead(rescuee) and Spring.GetUnitTransporter(rescuee) ~= rescuer then
            return false
        end
    end

    return true
end

local function Process(self, unitTargets)
    if not self.unitTargets then
        SetUnitPaths(self, unitTargets)
        IssueMoveOrders(self)
        return RUNNING
    end

    if not AllReachedTargetsOrDead(self) then
        return RUNNING
    end

    if not self.issuedLoading then
        IssueLoading(self)
    end

    if not AllTargetsLoaded(self) then
        return RUNNING
    end

    return SUCCESS
end

function Run(self, units, params)
    if #units == 0 then
        return FAILURE
    end

    if not params.unitTargets then
       return FAILURE
    end

    return Process(self, params.unitTargets)
end


function Reset(self)
	ClearState(self)
end
