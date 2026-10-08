--- @module tad.audio
--- @summary Audio playback and volume controls.
--- @description Blah blah blah.

--- @function tad.audio.setVolume
--- @summary Sets the master audio volume.
--- @param volume number Master volume from 0 to 1.
--- @return nil Nothing.
--- @example
--- tad.audio.setVolume(0.5)
function audio.setVolume(volume)
end

--- @function tad.audio.getVolume
--- @summary Returns the master audio volume.
--- @return volume number Current master volume between 0 and 1.
--- @example
--- local volume = tad.audio.getVolume()
function audio.getVolume()
end

--- @function tad.audio.newSource
--- @summary Creates an audio source. (This is temporary and just here to test the API docs.)
--- @param path string Path to an audio file.
--- @return source tad.audio.Source new audio source.
--- @example
--- local music = tad.audio.newSource('music.mp3')
function audio.newSource(path)
end

--- @class tad.audio.Source
--- @summary A playable audio source.
--- @description (This is temporary and just here to test the API docs.)

--- @method tad.audio.Source:play
--- @summary Starts playback.
--- @return nil Nothing.
--- @example
--- music:play()
function Source:play()
end

--- @method tad.audio.Source:stop
--- @summary Stops playback.
--- @return nil Nothing.
--- @example
--- music:stop()
function Source:stop()
end

--- @method tad.audio.Source:setVolume
--- @summary Sets the volume of the source.
--- @param volume number Source volume from 0 to 1.
--- @return nil Nothing.
--- @example
--- music:setVolume(0.25)
function Source:setVolume(volume)
end

--- @class tad.audio.SoundData
--- @summary Audio sample data. (This is temporary and just here to test the API docs.)
--- @field sampleRate number Samples per second.
--- @field channels number Number of audio channels.
