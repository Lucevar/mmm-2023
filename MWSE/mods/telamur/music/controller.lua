local utils = require("telamur.utils")
local MUSICDIR = "Data Files\\Music\\telamur\\"
local SILENCE = "telamur\\Special\\silence.mp3"
local previousCell

--- @type function
local isTelAmurCell = utils.cells.isTelAmurCell

--- @type string[]
local whitelistedTracks = {}

local waterLayer = { volume = waterVolume }
event.register("loaded", function()
    waterLayer.sound = assert(tes3.getSound("Water Layer"))
    waterLayer.prevVolume = waterLayer.sound.volume
end)

local function onCombatStart(e)
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    if not isTelAmur then return end

    if grurnPlayed == true then return end

    local target = e.target.reference.id
    local actor = e.actor.reference.id
    if string.startswith(target, GRURN_ID)
    or string.startswith(actor, GRURN_ID) then
        tes3.streamMusic{path = "fm\\Battle\\tew_cc_grurn_battle.mp3", situation = tes3.musicSituation.battle}
    end
end

--- @param e musicSelectTrackEventData
local function prioritiseTelAmurMusic(e)
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    local wasTelAmur = previousCell and isTelAmurCell(previousCell)
    if isTelAmur and not wasTelAmur then
        e.music = table.choice(whitelistedTracks)
        e.situation = config.musicSituation
        previousCell = cell
        return false
    end
end

local function onCombatStopped()
    if tes3.player.mobile.inCombat then return end -- Because MW can be really dumb with that one
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    if isTelAmur then
        tes3.streamMusic{path = table.choice(whitelistedTracks), situation = config.musicSituation}
        previousCell = cell
    end
end

local function TelAmurConditionCheck()
    local cell = tes3.getPlayerCell()
    local isTelAmur = isTelAmurCell(cell)
    local wasTelAmur = previousCell and isTelAmurCell(previousCell)

    if isTelAmur and not wasTelAmur then
        waterLayer.sound.volume = waterVolume
        tes3.streamMusic{path = table.choice(whitelistedTracks), situation = config.musicSituation}
    elseif wasTelAmur and not isTelAmur then
        waterLayer.sound.volume = waterLayer.prevVolume
        tes3.streamMusic{path = SILENCE, situation = tes3.musicSituation.explore}
    end
    previousCell = cell
end

local function populateTracks()
    for track in lfs.dir(MUSICDIR) do
		if (track ~= ".." and track ~= "." and track ~= "Special") and (string.endswith(track, ".mp3")) then
            table.insert(whitelistedTracks, #whitelistedTracks+1, "fm\\" .. track)
        end
    end
    assert(whitelistedTracks, "Missing music files!")
end

local function resetOnLoad()
    previousCell = nil
end

populateTracks()
event.register(tes3.event.musicSelectTrack, prioritiseTelAmurMusic, { priority = 360 })
event.register(tes3.event.cellChanged, TelAmurConditionCheck)
event.register(tes3.event.load, resetOnLoad)
event.register(tes3.event.combatStart, onCombatStart)

-- For some reason a config check inside the event didn't work, and we don't want to claim the event
-- This requires restart after toggling in MCM, but oh well
if config.musicSituation == tes3.musicSituation.explore then
    event.register(tes3.event.combatStopped, onCombatStopped)
end
