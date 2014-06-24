--AudioUtil module
local AudioUtil = {}

local SEDIR= "audio/se/"
local BGMDIR = "audio/bgm/"

local lastMusic=nil
local lastMusicName=nil
local seTable={}

-- If the SE is new, add at seTable for future use. Default plays once
function AudioUtil.playSE(nameWithExtension,loops)
	loops=loops or 0
	if seTable[nameWithExtension]==nil then seTable[nameWithExtension] = audio.loadSound(SEDIR..nameWithExtension) end
	audio.play(seTable[nameWithExtension],{loops=loops})
end

-- Stops all the sound and plays the file name. Default plays at infinite looping
-- If the music is the same that is current playing, ignores the command.
function AudioUtil.playBGM(nameIncludingExtension,loops)
	loops=loops or -1
	if(lastMusicName==nameIncludingExtension) then
		return
	else
		lastMusicName=nameIncludingExtension
	end
	audio.stop()
	if lastMusic then 
		audio.dispose(lastMusic)
	end
	audio.setVolume(1.0,{channel=0})
	lastMusic=audio.loadStream(BGMDIR..nameIncludingExtension)
	audio.play(lastMusic,{loops=loops})
end

-- Stops the BGM and correctly resets the lastMusicName setting
function AudioUtil.stopBGM() 
	audio.stop()
	lastMusicName=nil
	if lastMusic then 
		audio.dispose(lastMusic)
	end
end

return AudioUtil