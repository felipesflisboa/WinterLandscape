require("scripts.efeitos")
require("scripts.game")
AudioUtil = require("scripts.audioUtil")

local IMGDIR = "images/intro/"

display.setStatusBar( display.HiddenStatusBar )

--Muda Anchor para Top Left
display.setDefault( "anchorX", 0.0 )
display.setDefault( "anchorY", 0.0 )

-- Definição dos display groups (camadas)
bg = display.newGroup()
botoesLayers = display.newGroup()
bgCredito = display.newGroup()
bgComoJogar = display.newGroup()

local travarBotoes = false

-- Funcao que torna o botao vermelho ao touch
local function tintRed (evento)
	if travarBotoes then return true end
	if (evento.phase == "began") then
		evento.target:setFillColor(1, 0, 0, 1)
	elseif (evento.phase == "ended") then
		evento.target:setFillColor(1, 1, 1, 1)
		travarBotoes=true
		if evento.target.id == "botao1p" then tapBotao1p() end
		if evento.target.id == "botao3p" then tapBotao3p() end
		if evento.target.id == "botao4p" then tapBotao4p() end
		if evento.target.id == "botao5p" then tapBotao5p() end
		if evento.target.id == "botaoComo" then tapBotaoComo() end
		if evento.target.id == "botaoCredito" then tapBotaoCredito() end
	end
end


--BG  do Menu
function mostrarIntro()
	timer.performWithDelay(800,function() AudioUtil.playBGM("sound_splashScreen.mp3",0) end)
	mostrarMenu()
end

function mostrarMenu(event)
	travarBotoes=false
	transition.to(bg,{time=800, alpha=1, transition=easing.InOutQuad})
	transition.to(botoesLayers,{time=800, alpha=1, transition=easing.InOutQuad})
	transition.to(bgCredito,{time=800, alpha=0, transition=easing.InOutQuad})
	transition.to(bgComoJogar,{time=800, alpha=0, transition=easing.InOutQuad})
	return true
end

function inicializar()
	mostrarIntro()

	local background = display.newImageRect( bg,IMGDIR.."bg.png", 768, 1024)
	
	local baseMenu = display.newImageRect( bg,IMGDIR.."baseMenu.png", 768, 1024)

	transFade( background, 500, 5000)

	transFade( baseMenu, 800, 1000)

	--Botoes e suas transições
	local botao1p = display.newImageRect( botoesLayers, IMGDIR.."botao1p.png", 55, 53 )
	botao1p.x = 314
	botao1p.y = 625
	transFade (botao1p, 800, 2000)
	botao1p.id = "botao1p"

	local botao2p = display.newImageRect( botoesLayers, IMGDIR.."botao2p.png", 55, 53 )
	botao2p.x = 314
	botao2p.y = 675
	transFade (botao2p, 1000, 2000)
	botao2p.id = "botao2p"
	botao2p:setFillColor(0.5, 0.5, 0.5, 1)

	local botao3p = display.newImageRect( botoesLayers, IMGDIR.."botao3p.png", 55, 68 )
	botao3p.x = 312 
	botao3p.y = 740
	transFade (botao3p, 1200, 2000)
	botao3p.id = "botao3p"

	local botao4p = display.newImageRect( botoesLayers, IMGDIR.."botao4p.png", 55, 68 )
	botao4p.x = 312
	botao4p.y = 830
	transFade (botao4p, 1400, 2000)
	botao4p.id = "botao4p"

	local botao5p = display.newImageRect( botoesLayers, IMGDIR.."botao5p.png", 55, 68 )
	botao5p.x = 311
	botao5p.y = 910
	transFade (botao5p, 1600, 2500)
	botao5p.id = "botao5p"


	local botaoCredito = display.newImageRect( botoesLayers, IMGDIR.."botaoCredito.png", 48, 185)
	botaoCredito.x = 0
	botaoCredito.y = 130 
	transFade (botaoCredito, 1800, 2000)
	botaoCredito.id = "botaoCredito"

	local botaoComo = display.newImageRect( botoesLayers, IMGDIR.."botaoComo.png", 48, 185 )
	botaoComo.x = 0
	botaoComo.y = 300
	transFade (botaoComo, 1800, 2000)
	botaoComo.id = "botaoComo"

	--Listeners
	botao1p:addEventListener( "touch", tintRed)
	botao3p:addEventListener( "touch", tintRed)
	botao4p:addEventListener( "touch", tintRed)
	botao5p:addEventListener( "touch", tintRed)
	botaoCredito:addEventListener( "touch", tintRed)
	botaoComo:addEventListener( "touch", tintRed)
end

--Funcoes dos Botões
function tapBotao1p()
	esconderMenu()
	initializeGame(1)
end

function tapBotao2p ()
	esconderMenu()
	initializeGame(2)
end

function tapBotao3p ()
	esconderMenu()
	initializeGame(3)
end

function tapBotao4p ()
	esconderMenu()
	initializeGame(4)
end

function tapBotao5p ()
	esconderMenu()
	initializeGame(5)
end

function tapBotaoComo ()
	mostrarComoJogar()
end

function tapBotaoCredito ()
 	mostrarCreditos()
end

function esconderMenu()
	transition.to(bg,{time=800, alpha=0, transition=easing.InOutQuad})
	transition.to(botoesLayers,{time=800, alpha=0, transition=easing.InOutQuad})
end

function mostrarCreditos()
	transition.to(bgCredito,{time=800, alpha=1, transition=easing.InOutQuad})
	local imgCreditos = display.newImageRect( bgCredito,IMGDIR.."creditos.png",  768, 1024)

	imgCreditos:addEventListener( "tap", mostrarMenu)
end

function mostrarComoJogar()
	transition.to(bgComoJogar,{time=800, alpha=1, transition=easing.InOutQuad})
	local imgComo = display.newImageRect( bgComoJogar, IMGDIR.."como.png",  768, 1024)

	imgComo:addEventListener( "tap", mostrarMenu)
end


inicializar()