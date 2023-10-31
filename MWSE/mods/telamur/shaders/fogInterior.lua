local fog = require("telamur.shaders.fog")
local cells = require("telamur.utils.cells")

local fogId = "Tel Amur Interior"

local isTelAmurFogCell = cells.isTelAmurFogCell

DENSITY = 4

local fogParams = {
    color = tes3vector3.new(0.78, 0.69, 0.21),
    center = tes3vector3.new(),
    radius = tes3vector3.new(),
    density = 60,
}

-- Determine fog position for interiors --
local function getFogLocation(cell)
	local pos = { x = 0, y = 0, z = 0 }
	local denom = 0
	local xs, zs = {}, {}

	for stat in cell:iterateReferences() do
		pos.x = pos.x + stat.position.x
		pos.z = pos.z + stat.position.z
		table.insert(xs, stat.position.x)
		table.insert(zs, stat.position.z)
		denom = denom + 1
	end

	return
		{ x = pos.x / denom, y = pos.y / denom, z = 0 },
		{
			width = math.abs(math.max(table.unpack(xs)) - math.min(table.unpack(xs))),
			depth =  math.abs(math.max(table.unpack(zs)) - math.min(table.unpack(zs))),
		}
end

local function calcInteriorFogParams(cell)
    local fogPos, fogDim = getFogLocation(cell)
    local depth = fogDim.depth
    local width = fogDim.width
    fogParams = {
        color = tes3vector3.new(0.78, 0.69, 0.21),
        center = tes3vector3.new(
            fogPos.x,
            fogPos.y,
            fogPos.z
		),
        radius = tes3vector3.new(width, width, depth),
        density = DENSITY
    }
end


local function update()
    local cell = tes3.getPlayerCell()
    local isAvailable = isTelAmurFogCell(cell)
    if isAvailable then
        calcInteriorFogParams(cell)
        fog.createOrUpdateFog(fogId, fogParams)
    else
        fog.deleteFog(fogId)
    end
end

event.register(tes3.event.cellChanged, update)
