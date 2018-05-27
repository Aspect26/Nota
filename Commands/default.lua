function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Acquire targets for picking units",
		parameterDefs = {
			{ 
				name = "position",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
			{ 
				name = "formation", -- relative formation
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "<relative formation>",
			},
			{ 
				name = "fight",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "false",
			}
		}
	}
end

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local function ClearState(self)
	self.threshold = THRESHOLD_DEFAULT
	self.lastPointmanPosition = Vec3(0,0,0)
end

function Run(self, units, parameter)
	local position = parameter.position -- Vec3
	local formation = parameter.formation -- array of Vec3
	local fight = parameter.fight -- boolean
	
	--Spring.Echo(dump(parameter.formation))
	
	-- validation
	if (#units > #formation) then
		Logger.warn("formation.move", "Your formation size [" .. #formation .. "] is smaller than needed for given count of units [" .. #units .. "] in this group.") 
		return FAILURE
	end
	
	-- pick the spring command implementing the move
	local cmdID = CMD.MOVE
	if (fight) then cmdID = CMD.FIGHT end

	local pointman = units[1] -- while this is running, we know that #units > 0, so pointman is valid
	local pointX, pointY, pointZ = SpringGetUnitPosition(pointman)
	local pointmanPosition = Vec3(pointX, pointY, pointZ)
	
	-- threshold of pointan success
	if (pointmanPosition == self.lastPointmanPosition) then 
		self.threshold = self.threshold + THRESHOLD_STEP 
	else
		self.threshold = THRESHOLD_DEFAULT
	end
	self.lastPointmanPosition = pointmanPosition
	
	-- check pointman success
	-- THIS LOGIC IS TEMPORARY, NOT CONSIDERING OTHER UNITS POSITION
	if (pointmanPosition:Distance(position) < self.threshold) then
		return SUCCESS
	else
		SpringGiveOrderToUnit(pointman, cmdID, position:AsSpringVector(), {})
		
		for i=2, #units do
			local thisUnitWantedPosition = pointmanPosition + formation[i]
			SpringGiveOrderToUnit(units[i], cmdID, thisUnitWantedPosition:AsSpringVector(), {})
		end
		
		return RUNNING
	end
end


function Reset(self)
	ClearState(self)
end
