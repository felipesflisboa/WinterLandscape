require("scripts.efeitos")
require("scripts.game")
AudioUtil = require("scripts.audioUtil")

local IMGDIR = "images/intro/"

display.setStatusBar( display.HiddenStatusBar )

--Muda Anchor para Top Left
display.setDefault( "anchorX", 0.0 )
display.setDefault( "anchorY", 0.0 )

-- Definição dos display groups (camadas)
menu = display.newGroup()
bgCredito = display.newGroup()
bgComoJogar = display.newGroup()

-- Funcao que torna o botao vermelho ao touch
local function tintRed (evento)
	if (evento.phase == "began") then
		evento.target:setFillColor(1, 0, 0, 1)
	elseif (evento.phase == "ended") then
		evento.target:setFillColor(1, 1, 1, 1)
		local funcao = nil
		if evento.target.id == "botao1p" then funcao=tapBotao1p end
		if evento.target.id == "botao3p" then funcao=tapBotao3p end
		if evento.target.id == "botao4p" then funcao=tapBotao4p end
		if evento.target.id == "botao5p" then funcao=tapBotao5p end
		if evento.target.id == "botaoComo" then funcao=tapBotaoComo end
		if evento.target.id == "botaoCredito" then funcao=tapBotaoCredito end
		
		transition.to( menu, {time=400, alpha=0, transition=easing.inOutQuad, onComplete=funcao })
	end
end


--BG  do Menu
function mostrarMenu()
	tocarMusica()
	bgCredito.alpha = 0
	bgComoJogar.alpha = 0
	transFade (menu, 0, 400)
end

function tocarMusica()
	timer.performWithDelay(400-2,function() AudioUtil.playBGM("sound_splashScreen.mp3",0) end)
end

function inicializar()
	tocarMusica()

	bgCredito.alpha = 0
	bgComoJogar.alpha = 0
	menu.alpha = 1

	local background = display.newImageRect( menu,IMGDIR.."bg.png", 768, 1024)
	
	local baseMenu = display.newImageRect( menu,IMGDIR.."baseMenu.png", 768, 1024)

	transFade( background, 500, 5000)

	transFade( baseMenu, 0, 2000)

	--Botoes e suas transições
	local botao1p = display.newImageRect( menu, IMGDIR.."botao1p.png", 55, 53 )
	botao1p.x = 310
	botao1p.y = 625
	transFade (botao1p, 800, 2000)
	botao1p.id = "botao1p"

	local botao2p = display.newImageRect( menu, IMGDIR.."botao2p.png", 55, 53 )
	botao2p.x = 310
	botao2p.y = 675
	transFade (botao2p, 1000, 2000)
	botao2p.id = "botao2p"
	botao2p:setFillColor(0.5, 0.5, 0.5, 1)


	local botao3p = display.newImageRect( menu, IMGDIR.."botao3p.png", 55, 68 )
	botao3p.x = 312 
	botao3p.y = 740
	transFade (botao3p, 1200, 2000)
	botao3p.id = "botao3p"


	local botao4p = display.newImageRect( menu, IMGDIR.."botao4p.png", 55, 68 )
	botao4p.x = 312
	botao4p.y = 830
	transFade (botao4p, 1400, 2000)
	botao4p.id = "botao4p"


	local botao5p = display.newImageRect( menu, IMGDIR.."botao5p.png", 55, 68 )
	botao5p.x = 311
	botao5p.y = 910
	transFade (botao5p, 1600, 2500)
	botao5p.id = "botao5p"


	local botaoCredito = display.newImageRect( menu, IMGDIR.."botaoCredito.png", 48, 185)
	botaoCredito.x = 0
	botaoCredito.y = 130 
	transFade (botaoCredito, 1800, 2000)
	botaoCredito.id = "botaoCredito"


	local botaoComo = display.newImageRect( menu, IMGDIR.."botaoComo.png", 48, 185 )
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
	initializeGame(1,esconderMenu)
end

function tapBotao2p ()
	esconderMenu()
	initializeGame(2,esconderMenu)
end

function tapBotao3p ()
	esconderMenu()
	initializeGame(3,esconderMenu)
end

function tapBotao4p ()
	esconderMenu()
	initializeGame(4,esconderMenu)
end

function tapBotao5p ()
	esconderMenu()
	initializeGame(5,esconderMenu)
end

function tapBotaoComo ()
	mostrarComoJogar()
end

function tapBotaoCredito ()
 	mostrarCreditos()
end

function esconderMenu()
	menu.alpha = 0
end

function mostrarComoJogar()
	local imgComoJogar = display.newImageRect( bgComoJogar,IMGDIR.."comojogar.png", 768, 1024)
	local btVoltar = display.newImageRect(bgComoJogar, IMGDIR.."voltar.jpg", 200, 100 )
	transFade( bgComoJogar, 500, 500)
	btVoltar.x = 300
	btVoltar.y = 900
	
	btVoltar.id = "btVoltar"
	transFade( imgComoJogar, 0, 500, esconderMenu)
	transFade( btVoltar, 0, 500)
	btVoltar:addEventListener( "touch", mostrarMenu)
end

function mostrarCreditos()
	local imgCreditos = display.newImageRect( bgCredito,IMGDIR.."creditos.png",  768, 1024)
	local btVoltar = display.newImageRect(bgCredito, IMGDIR.."voltar.jpg", 200, 100 )
	transFade( bgCredito, 500, 500)
	btVoltar.x = 300
	btVoltar.y = 900
	
	btVoltar.id = "btVoltar"
	transFade( imgCreditos, 0, 500, esconderMenu)
	transFade( btVoltar, 0, 500)
	
	btVoltar:addEventListener( "touch", mostrarMenu)
end


inicializar()
