DRY_RUN = true

event.register(tes3.event.initialized, function()
    if tes3.isModActive("Tel_Amur.esp") or DRY_RUN then
        -- require("telamur.shaders.fogInterior")
        require("telamur.music.controller")
        require("telamur.sounds.controller")
    end
end)