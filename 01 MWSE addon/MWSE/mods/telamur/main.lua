event.register(tes3.event.initialized, function()
    if tes3.isModActive("Terror of Tel Amur.esp") then
        require("telamur.shaders.fogInterior")
        require("telamur.music.controller")
        require("telamur.sounds.controller")
    end
end)