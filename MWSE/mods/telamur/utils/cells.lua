local this = {}

SFX_CELLS = {
    ["Zete Fyr's Pocket Realm"] = true,
    ["Tel Amur"] = true,
    ["Tel Amur, Grotto"] = true,
    ["Maw of Tel Amur"] = true
}

VFX_CELLS = {
    ["Zete Fyr's Pocket Realm"] = true
}

---@param cell tes3cell
function this.isTelAmurCell(cell)
    return SFX_CELLS[cell.name]
end

---@param cell tes3cell
function this.isTelAmurFogCell(cell)
    return VFX_CELLS[cell.name]
end

return this
