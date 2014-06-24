require("scripts.player")
require("scripts.decisionBox")
local Util = require("scripts.util")

local IMGDIR = "images/game/"

local DISTANCEGOAL = 10

local CARTA_CACADOR=1
local CARTA_PESCADOR=2
local CARTA_PATINADOR=3
local CARTA_DIABO=4
local CARTA_CORVO=5
local CARTA_LADRAO=6

local PLAYERSROTATION = {45,135,225,270,315}
local PLAYERSTEXTCOLOR = {{0.9, 0.9, 0.5},{0.6, 0.6, 1},{1, 0.4, 0.8},{1, 0.6, 0.6},{0.8, 1, 0.6}}
local CARDANIMATIONNAMES = ({
	[CARTA_CACADOR]="cartaCacadorRotate.png",
	[CARTA_PESCADOR]="cartaPescadorRotate.png",
	[CARTA_PATINADOR]="cartaPatinadorRotate.png",
	[CARTA_DIABO]="cartaDiaboRotate.png",
	[CARTA_CORVO]="cartaCorvoRotate.png",
	[CARTA_LADRAO]="cartaLadraoRotate.png",
})
local COLORNAMES = {"Amarelo","Azul","Rosa","Vermelho", "Verde"}
local FONT = "Garamond Premr Pro"
--local FONT = "Garamond Premier Pro Bold" -- Mac

-- Layers
local boardLayer = nil
local playersLayer = nil
local cardsLayer = nil
local hudLayer = nil
local blockLayer = nil
local featuredLayer = nil
local barLayer = nil
local messageLayer = nil

local layers = {}

-- GUI
local playersHUD = {}
local playersHUDBirds = {}
local playersHUDFish = {}
local playersIcons = {}
local cards = {}
local mainBars={}
local mainBarText=nil
local mainMessageText=nil
local subMessageText=nil
local deadIcon=nil
local blackBlock=nil
local board=nil
local decisionBox=nil

-- Steps
local STEP_SELECTCARD=1
local STEP_KILLER=2
local STEP_ACTION=3
local STEP_MOVE=4
local STEP_NEWORDER=5

-- Others
local playerCount = 0
local players = {}
local firstPlayer=0
local playerTurn=0
local stolenPlayer=0 -- For message
local step=0
local selectedCard = 0
local selectedCardLayerIndex = 0
local decisionTime = false
local gameOccurring=false
local touchTimeout=0
local turnNumber=0

--------------------------------------------------
--- Initialize/Finalize functions
--------------------------------------------------

function initializeGame(playersNumber, functionAfterFade)
	playerCount = playersNumber==1 and 5 or playersNumber -- When 1 is selected, is a 5 player game with bots
	
	-- Initialize player objects
	for i = 1, playerCount do
		local isBot = (playersNumber==1 and i~=1) and true or false
		players[i]=Player.create(i,isBot)
	end
	
	boardLayer=display.newGroup()
	playersLayer=display.newGroup()
	cardsLayer=display.newGroup()
	hudLayer=display.newGroup()
	blockLayer=display.newGroup() -- All below this layer cannot be visible when the black block is active
	featuredLayer=display.newGroup() -- A visible layer when black block is active
	barLayer=display.newGroup()
	messageLayer=display.newGroup()
	
	layers = {boardLayer,playersLayer,cardsLayer,hudLayer,blockLayer,featuredLayer,barLayer,messageLayer}
	
	board = display.newImageRect( boardLayer,IMGDIR.."tabuleiro.png", 769, 1024)
	
	-- Cards image
	local cardCount=1
	for _,cardIndex in ipairs({CARTA_CACADOR,CARTA_PESCADOR,CARTA_PATINADOR,CARTA_DIABO,CARTA_CORVO,CARTA_LADRAO}) do
		local cardPath = ({
			[CARTA_CACADOR]="cartaCacadorFrente.png",
			[CARTA_PESCADOR]="cartaPescadorFrente.png",
			[CARTA_PATINADOR]="cartaPatinadorFrente.png",
			[CARTA_DIABO]="cartaDiaboFrente.png",
			[CARTA_CORVO]="cartaCorvoFrente.png",
			[CARTA_LADRAO]="cartaLadraoFrente.png",
		})[cardIndex] 
		cards[cardIndex] = display.newImageRect( cardsLayer, IMGDIR..cardPath, 142, 190 )
		cards[cardIndex].anchorX = 0.5
		cards[cardIndex].anchorY = 0.5
		cards[cardIndex]:addEventListener( "touch", cardTouch)
		
	    local x, y, rotation = nonPlayerCardXYRotation(cardIndex)
		cards[cardIndex].x=x-150
		cards[cardIndex].y=y
		cards[cardIndex].rotation=rotation
		transition.to(cards[cardIndex], {delay=1000+300*cardCount, time=1200, x=x, y=y, transition=easing.inOutQuad})
		
		cardCount=cardCount+1
	end
	
	-- Dead Icon
	deadIcon = display.newImageRect( hudLayer, IMGDIR.."lapide.png", 58, 85 )
	deadIcon.alpha = 0
	
	local counterFontSize=32
	for i = 1, playerCount do 
		-- Player HUD
		local playersHUDPath = ({"playerAmareloHud.png","playerAzulHud.png","playerRosaHud.png","playerVermelhoHud.png","playerVerdeHud.png"})[i]
		playersHUD[i] = display.newImageRect( hudLayer, IMGDIR..playersHUDPath, ({208, 239, 207, 91, 241})[i], ({247, 209, 240, 394, 208})[i])
		local hudFinalX = ({37, 37, 553, 669, 519})[i]
		local hudFinalY = ({777, 0, 0, 315, 816})[i]
		local hudWidth = playersHUD[i].width
		local hudHeight = playersHUD[i].height
		-- Initial position before the HUD appears at screen
		playersHUD[i].x = ({-hudWidth, -hudWidth, hudWidth, hudWidth, hudWidth})[i] + hudFinalX
		playersHUD[i].y = ({hudHeight, -hudHeight, -hudHeight, 0, hudHeight})[i] + hudFinalY
	    transition.to(playersHUD[i], {delay=500+400*i, time=3000, x=hudFinalX, y=hudFinalY, transition=easing.inOutQuad})
		playersHUD[i]:addEventListener( "touch", playerTouch)
		
		-- Birds counter
		playersHUDBirds[i] = display.newText({parent=hudLayer, text="0",font=FONT, fontSize=counterFontSize})
		playersHUDBirds[i].x = ({116, 140, 684, 704, 660})[i]
		playersHUDBirds[i].y = ({918, 80, 104, 524, 944})[i]
		playersHUDBirds[i]:setFillColor(PLAYERSTEXTCOLOR[i][1],PLAYERSTEXTCOLOR[i][2],PLAYERSTEXTCOLOR[i][3])
		playersHUDBirds[i].anchorX = 0.5
		playersHUDBirds[i].rotation = PLAYERSROTATION[i]
		playersHUDBirds[i].alpha=0
		transition.to ( playersHUDBirds[i], { delay=5000, time=2000, alpha=1, transition=easing.inOutQuad})
		
		-- Fish counter
		playersHUDFish[i] = display.newText({parent=hudLayer, text="0",font=FONT, fontSize=counterFontSize})
		playersHUDFish[i].x = ({142, 110, 660, 704, 692})[i]
		playersHUDFish[i].y = ({952, 104, 72, 480, 920})[i]
		playersHUDFish[i]:setFillColor(PLAYERSTEXTCOLOR[i][1],PLAYERSTEXTCOLOR[i][2],PLAYERSTEXTCOLOR[i][3])
		playersHUDFish[i].anchorX = 0.5
		playersHUDFish[i].rotation = PLAYERSROTATION[i]
		playersHUDFish[i].alpha=0
		transition.to ( playersHUDFish[i], { delay=5000, time=2000, alpha=1, transition=easing.inOutQuad})
		
		-- Players Icons
		local playersIconsPath = ({"playerAmarelo.png","playerAzul.png","playerRosa.png","playerVermelho.png","playerVerde.png"})[i] 
		playersIcons[i] = display.newImageRect( playersLayer, IMGDIR..playersIconsPath, 45, 76 )
		playersIcons[i].x = ({300, 340, 380, 420, 460})[i]
		playersIcons[i].y = playerIconY(i)
	end

	-- Draw all bar at the same positions, but only the right one will be visible. The default is the last one
	for i = 1, playerCount+1 do 
		local mainBarsPaths = {"barraYellow.png","barraBlue.png","barraPink.png","barraRed.png","barraGreen.png","barraNeutra.png"}
		mainBars[i] = display.newImageRect( barLayer, IMGDIR..mainBarsPaths[i], 760, 1024 )
		if i<=playerCount then mainBars[i].isVisible = false end
	end
	
	-- Black block used at decision time
	blackBlock = display.newRect(blockLayer, 0, 0, 768, 1024)
	blackBlock:setFillColor(0,0,0)
	blackBlock.alpha=0
	
	-- Main HUD text
	mainBarText = display.newText({parent=barLayer, x=16, y=display.viewableContentHeight/2, text="",font=FONT, fontSize=18})
	mainBarText.anchorX = 0.5
	mainBarText.anchorY = 0.5
	mainBarText.rotation = 90	
	
	mainMessageText = display.newText({parent=messageLayer, x=display.viewableContentWidth/2+20, y=display.viewableContentHeight/2, text="",font=FONT, fontSize=50})
	mainMessageText.anchorX = 0.5
	mainMessageText.anchorY = 0.5
	mainMessageText.rotation = 90	
	
	subMessageText = display.newText({parent=messageLayer, x=display.viewableContentWidth/2-20, y=display.viewableContentHeight/2, text="",font=FONT, fontSize=18})
	subMessageText.anchorX = 0.5
	subMessageText.anchorY = 0.5
	subMessageText.rotation = 90	
	
	-- Decision Box
	local decisionBoxLayer = display.newGroup()
	local confirmButton = display.newImageRect( decisionBoxLayer, IMGDIR.."botaoConfirmar.png", 97, 97 )
	local cancelButton = display.newImageRect( decisionBoxLayer, IMGDIR.."botaoRecusar.png", 97, 97 )
	confirmButton:addEventListener( "touch", confirmTouch)
	cancelButton:addEventListener( "touch", cancelTouch)
	local titleText = display.newText({parent=decisionBoxLayer, text="",font=FONT, fontSize=22})
	local descriptionText = display.newText({parent=decisionBoxLayer, text="",font=FONT, fontSize=16})
	decisionBox = DecisionBox.create(PLAYERSROTATION,COLORNAMES,PLAYERSTEXTCOLOR,decisionBoxLayer,confirmButton,cancelButton,titleText,descriptionText)	
	
	-- Fade all layers and execute functionAfterFade after fade
	local delay=4000
	for i=1, #layers do
		transFade( layers[i], 0, delay)
	end
	timer.performWithDelay(delay,functionAfterFade)
	
	gameOccurring=true
	
	AudioUtil.playBGM("sound_inGame.mp3")
	firstPlayer=math.random(playerCount)
	setTouchWaitTime(delay+1600)
	timer.performWithDelay(delay+1600,nextTurn)
end

-- Remove all images, restart the layer and going back to the menu screen
function finalizeGame()
	playersHUDBirds={}
	playersHUDFish={}
	playersHUD={}
	playersIcons={}
	cards={}
	decisionBox:finalize()
	decisionBox=nil
	for i=1, #layers do
		layers[i]:removeSelf()
	end
	layers={}
	
	playerCount = 0
	players = {}
	firstPlayer=0
	playerTurn=0
	stolenPlayer=0
	step=0
	selectedCard = 0
	decisionTime = false
	turnNumber=0
end

function declareVictory(playerIndex)
	AudioUtil.playBGM("sound_success.mp3")
	-- An empty block just for doing a touch listenet on the entire screen
	display.newRect(messageLayer, 0, 0, 768, 1024).alpha=0.01
	showStepMessage(nil,playerIndex)
	local restart = function() 
		finalizeGame()
		audio.fadeOut({channel=0})
		mostrarIntro()
	end
	timer.performWithDelay(400,function() messageLayer:addEventListener( "touch",restart) end)
end

--------------------------------------------------
--- Other functions
--------------------------------------------------

function nextTurn()
	highlightPlayersIconsDeactivate()
	step = STEP_SELECTCARD
	turnNumber=turnNumber+1
	playerTurn=firstPlayer
	highlightPlayer(playerTurn)
	local after = function() -- Remove card, revive everyone and show step text
		local delay=500
		setTouchWaitTime(delay)
		for i = 1, playerCount do
			if players[i].card>0 then removePlayerCard(i) end
			if players[i].dead then revivePlayer(i) end
		end
		timer.performWithDelay(delay,function() showStepMessage(nil,nil,aiCommand) end)
	end
	showStepMessage(turnNumber,nil,after)
end

-- If a player have the right card, he call kill someone. Else go to the next step. Return if there is a killer among us
function killChoice()
	for i = 1, playerCount do
		if players[i].card==CARTA_DIABO then
			step = STEP_KILLER
			AudioUtil.playBGM("sound_gameOver.mp3")
			playerTurn=i
			highlightPlayer(playerTurn)
			local afterActionMessage = function()
				highlightPlayerHUDs(playerTurn)
				transition.to(blackBlock, {time=400, alpha=0.9, transition=easing.inOutQuad})
				aiCommand(nil,3000)
			end
			timer.performWithDelay(1000,function() showStepMessage(nil,nil,afterActionMessage) end) -- Extra delay time for music
			return
		end
	end
	step = STEP_ACTION
	timer.performWithDelay(1000,function() showStepMessage(nil,nil,initializeActionTurn) end)
end

function initializeActionTurn()
	-- Give bird to everyone
	for i = 1, playerCount do
		birdsReceived = (players[i].card==CARTA_CACADOR and not players[i].dead) and 2 or 1 
		setPlayerBirds(i,players[i].birds+birdsReceived)
	end
	nextAction(true)
end

function nextAction(firstTurn) -- If firstTurn == true then doesn't calls nextPlayerTurn
	firstTurn = false or firstTurn
	if not gameOccurring then return end 
	stolenPlayer=0
	if firstTurn or nextPlayerTurn() then
		if (players[playerTurn].card==CARTA_LADRAO or players[playerTurn].card==CARTA_CORVO) and not players[playerTurn].dead then
			-- If the player need a target selection
			print("Time left="..touchTimeout-system.getTimer())
			highlightPlayer(playerTurn)
			local highlight = function()
				highlightPlayerHUDs(playerTurn)
				transition.to(blackBlock, {time=400, alpha=0.9, transition=easing.inOutQuad})
				aiCommand(nil,1600)
			end
			timer.performWithDelay(400+2,highlight)
		elseif not players[playerTurn].dead and (players[playerTurn].card==CARTA_PATINADOR or players[playerTurn].card==CARTA_PESCADOR) then
			if players[playerTurn].card==CARTA_PESCADOR then	-- Transform bird into fish !
				setPlayerFish(playerTurn,players[playerTurn].fish+players[playerTurn].birds)
				setPlayerBirds(playerTurn,0)
			elseif players[playerTurn].card==CARTA_PATINADOR then
				movePlayerConsumingResources(playerTurn, true)
			end
			if not gameOccurring then return end 
			highlightPlayer(playerTurn)
			timer.performWithDelay(4000,function() nextAction();end)
		else	
			nextAction()
		end
	else
		step = STEP_MOVE
		highlightPlayer(playerTurn)
		showStepMessage(nil, nil, activatesMoveSelection)
	end
end

function actionPerformed()
	highlightPlayer(playerTurn)
	transition.to(blackBlock, {time=400, alpha=0, transition=easing.inOutQuad, onComplete=highlightPlayerHUDsDeactivate})
	timer.performWithDelay(4000,function() nextAction() end)
end					

function activatesMoveSelection()
	timer.performWithDelay(1600,activateDecisionTime)
	highlightPlayersIcons()
	aiCommand(nil,2800)
end

function nextMove()
	if not gameOccurring then return end 
	if nextPlayerTurn() then
		if players[playerTurn].dead or players[playerTurn].card==CARTA_LADRAO or players[playerTurn].card==CARTA_PATINADOR or players[playerTurn]:getPoints()==0 then
			nextMove()
		else
			deactivateDecisionTime()
			highlightPlayer(playerTurn)
			activatesMoveSelection()
		end
	else
		deactivateDecisionTime()
		local playerThatDefinesNewOrderIndex = 0
		for i = 1, playerCount do
			if players[i].card==CARTA_DIABO then
				playerThatDefinesNewOrderIndex=i
				break
			end
		end
		if playerThatDefinesNewOrderIndex==0 then
			nextTurn()
		else
			step = STEP_NEWORDER
			playerTurn=playerThatDefinesNewOrderIndex
			highlightPlayer(playerTurn)
			highlightPlayerHUDs(playerTurn)
			transition.to(blackBlock, {time=400, alpha=0.9, transition=easing.inOutQuad})
			aiCommand(nil,400)
		end
	end
end

function activateDecisionTime()
	if not gameOccurring then return end 
	decisionTime=true
	local delay = 0 
	decisionBox:activate(playerTurn,(selectedCard==0) and "Andar?" or "Confirma a seleção da carta?")
	if(selectedCard~=0) then -- Do the card animation
		delay = 600 
		cardsLayer:remove(cards[selectedCard])
		decisionBox:addCard(cards[selectedCard],IMGDIR..CARDANIMATIONNAMES[selectedCard])
	end
	transition.to(blackBlock, {delay=delay, time=400, alpha=0.9, transition=easing.inOutQuad })
end

function deactivateDecisionTime(playerIndex)
	if not gameOccurring then return end 
	decisionTime=false
	playerIndex = playerIndex or 0 -- 0 acts as no player index
	if(selectedCard~=0) then -- Do the card animation
		delay=1000
		local x,y,rotation = 0,0,0
		if playerIndex==0 then
			x,y,rotation=nonPlayerCardXYRotation(selectedCard)
		else
			x,y,rotation=playerCardXYRotation(playerIndex)
		end
		decisionBox:removeCard(x,y,rotation,IMGDIR..CARDANIMATIONNAMES[selectedCard])
		if playerIndex==0 then
			cardsLayer:insert(selectedCardLayerIndex,cards[selectedCard])
		else
			hudLayer:insert(1,cards[selectedCard])
		end
	end
	transition.to(blackBlock, {time=400, alpha=0, transition=easing.inOutQuad })
	decisionBox:deactivate()
	selectedCard=0
	selectedCardLayerIndex=0
end

function movePlayerConsumingResources(playerIndex,double)
	double=double or false
	distance=players[playerIndex]:moveConsumingResources(double)
	setPlayerBirds(playerIndex,0) -- Only for updating the counters
	setPlayerFish(playerIndex,0) -- Only for updating the counters
	movePlayerEffects(playerIndex,distance)
end

-- Only checks victory conditions and plays the animation
function movePlayerEffects(playerIndex,distance)
	transition.to(playersIcons[playerIndex], {y=playerIconY(playerIndex), time=800, transition=easing.inOutQuad, onComplete=animacaoCompleta})
	if(players[playerIndex].boardPosition>=DISTANCEGOAL) then 
		gameOccurring=false
		timer.performWithDelay(4000,function() declareVictory(playerIndex) end)
	end
end	

-- Set variable playerTurn to the next player. Returns false if the next player and the first player are equal (the cicle is complete).
function nextPlayerTurn()
	playerTurn = playerTurn==playerCount and 1 or playerTurn+1
	return ( firstPlayer ~= playerTurn )
end

--------------------------------------------------
--- Functions that change visual/player things
--------------------------------------------------

-- Highlight the player. When param<1 or there is no param = No Highlight 
-- Also, refreshes the mainBarText
function highlightPlayer(playerIndex)
	-- Only refreshes the mainBarText now.
	refreshmainBarText()
end

-- Highlight all player HUD except playerIndex
function highlightPlayerHUDs(playerIndex)
	print("highlightPlayerHUDs")
	for i = 1, playerCount do
		if i~=playerIndex then 
			featuredLayer:insert(cards[players[i].card])
			if players[i].dead then featuredLayer:insert(deadIcon) end
			featuredLayer:insert(playersHUD[i])
			featuredLayer:insert(playersHUDBirds[i])
			featuredLayer:insert(playersHUDFish[i])
		end
	end
end

function highlightPlayerHUDsDeactivate()
	print("highlightPlayerHUDsDeactivate")
	for i = 1, playerCount do 
		hudLayer:insert(cards[players[i].card]) 
	end
	hudLayer:insert(deadIcon) -- For fixing this icon position
	for i = 1, playerCount do 
		hudLayer:insert(playersHUD[i])
		hudLayer:insert(playersHUDBirds[i])
		hudLayer:insert(playersHUDFish[i])
	end
end

function highlightPlayersIcons()
	for i = 1, playerCount do
		featuredLayer:insert(playersIcons[i])
	end
end

function highlightPlayersIconsDeactivate()
	for i = 1, playerCount do
		playersLayer:insert(playersIcons[i])
	end
end

function removePlayerCard(playerIndex)
	local oldCard = players[playerIndex].card
	players[playerIndex].card=0
	if oldCard>0 then
		cardsLayer:insert(cards[oldCard])
		local x, y, rotation = nonPlayerCardXYRotation(oldCard) 
		transition.to(cards[oldCard], {time=400, x=x, y=y, rotation=rotation, transition=easing.inOutQuad })
		setTouchWaitTime(400)
	end
end

function playerCardXYRotation(playerIndex)
	local x = ({137, 140, 646, 684, 654})[playerIndex]
	local y = ({917, 110, 110, 512, 920})[playerIndex]
	return x,y,PLAYERSROTATION[playerIndex]
end

function nonPlayerCardXYRotation(cardIndex)
	local x = 60
	local y = 160 + 96 * cardIndex
	local rotation = 70
	return x,y,rotation
end

function setPlayerBirds(playerIndex, birds)
	players[playerIndex].birds = birds
	playersHUDBirds[playerIndex].text=players[playerIndex].birds
end

function setPlayerFish(playerIndex, fish)
	players[playerIndex].fish = fish
	playersHUDFish[playerIndex].text=players[playerIndex].fish
end

function killPlayer(playerIndex)
	players[playerIndex].dead=true
	AudioUtil.playSE("Die.wav")
	timer.performWithDelay(1200,function() AudioUtil.playBGM("sound_inGame.mp3") end)
	-- Change the only icon position, since only only one player can be dead per turn
	deadIcon.x = ({157, 196, 628, 630, 604})[playerIndex]
	deadIcon.y = ({857, 134, 160, 542, 900})[playerIndex]	
	deadIcon.rotation=PLAYERSROTATION[playerIndex]
	transition.to(deadIcon, { time=400, alpha=1, transition=easing.inOutQuad})
end

function revivePlayer(playerIndex)
	players[playerIndex].dead=false
	transition.to(deadIcon, { time=400, alpha=0, transition=easing.inOutQuad})
end

-- Return the player Y based in the boardPosition
function playerIconY(playerIndex)
	-- Defines the first and last positions
	local firstY=670
	local lastY=270
	local boardPosition = players[playerIndex].boardPosition
	if boardPosition>DISTANCEGOAL then boardPosition=DISTANCEGOAL end -- precaution
	return firstY-(firstY-lastY)*(boardPosition-1)/(DISTANCEGOAL-1)
end

--------------------------------------------------
--- Step/Bar Messages
--------------------------------------------------

-- If turn isn't nil, then show the turn message. 
-- If playerWinner isn't nil, then show the victory message and don't fade. 
-- onComplete is the function trigger at end of step Message.
function showStepMessage(turn,playerWinner,onComplete) 
	local duration=2300
	local selectedStep = step
	if selectedStep==STEP_KILLER then selectedStep=STEP_ACTION end
	local mainText=""
	local subText=""
	if playerWinner then
		mainText="VITÓRIA!!!"
		subText="Jogador "..COLORNAMES[playerWinner].." superou os desafios e chegou a cidade grande!"
	elseif turn then
		mainText="Rodada "..turn
	else
		mainText=({
			[STEP_SELECTCARD]="I. Fase de Seleção",
			[STEP_ACTION]="II. Fase de Execução",
			[STEP_MOVE]="III. Fase de Movimentação"
		})[selectedStep]
		subText=({
			[STEP_SELECTCARD]="Cada jogador seleciona uma carta que será usada nesta rodada.",
			[STEP_ACTION]="Cada jogador executa a função de sua carta.",
			[STEP_MOVE]="Cada jogador opta por utilizar ou não seus recursos para se movimentar."
		})[selectedStep]
	end
	mainMessageText.text=mainText
	subMessageText.text=subText
	local colorArray = playerWinner and PLAYERSTEXTCOLOR[playerWinner] or {1,1,1}
	subMessageText:setFillColor(colorArray[1],colorArray[2],colorArray[3])
	messageLayer.alpha=0
	transition.to(messageLayer,{time=400, alpha=1, transition=easing.inOutQuad})
	transition.to(blackBlock, {time=400, alpha=0.9, transition=easing.inOutQuad })
	if playerWinner then return end
	transition.to(blackBlock, {delay=(duration-400), time=400, alpha=0, transition=easing.inOutQuad })
	transition.to(messageLayer,{delay=(duration-400), time=400, alpha=0, transition=easing.inOutQuad, onComplete=onComplete})
	setTouchWaitTime(duration)
end

function refreshmainBarText()
	local text="Jogador "..COLORNAMES[playerTurn]..": "
	
	local textAction = {
		[CARTA_CACADOR]="",
		[CARTA_PESCADOR]="Usou seus pássaros para pegar peixes.",
		[CARTA_PATINADOR]="Usou seus recursos para andar o dobro.",
		[CARTA_DIABO]="",
		[CARTA_CORVO]="Escolha de quem irá roubar 2 pássaros ou 1 peixe.",
		[CARTA_LADRAO]="Escolha de quem irá roubar metade dos recursos"
	}
	local textStep={
		[STEP_SELECTCARD]="Selecione sua carta.",
		[STEP_KILLER]="Selecione quem será morto.",
		[STEP_ACTION]=textAction[players[playerTurn].card],
		[STEP_MOVE]="Andar?",
		[STEP_NEWORDER]="Escolha o primeiro jogador do próximo turno."
	}
	if stolenPlayer>0 then
		text=text.." Alvo escolhido foi o Jogador "..COLORNAMES[stolenPlayer]..": "
	else
		text=text..textStep[step]
	end
	mainBarText.text=text
	-- Displays the right bar
	for i = 1, playerCount+1 do
		mainBars[i].isVisible = playerTurn==i
	end
end

--------------------------------------------------
--- AI
--------------------------------------------------

function aiCommand(dummy,delay) -- Dummy is for problems when calling using closures.
	delay=delay and delay or 0
	local func = function()
		if not players[playerTurn].isBot then return end
		commands={}
		if step == STEP_SELECTCARD then
			if decisionTime then -- If the card is selected, just confirm
				confirmTouch(nil,true)
			else
				-- Get the best points, the best overall and the second best overall
				local bestPoints = 0
				local bestOverall = 0
				local secondBestOverall = 0
				for i = 1, playerCount do 
					if i~=playerTurn then
						if players[i]:getPoints()>=bestPoints then
							bestPoints=players[i]:getPoints()
						end 
						local overall = players[i]:getPoints()+players[i].boardPosition
						if overall>=bestOverall then
							secondBestOverall=bestOverall
							bestOverall=overall
						end 
					end
				end
				local firstPlayerAdvantage = bestOverall-secondBestOverall
				for _,cardIndex in ipairs({CARTA_CACADOR,CARTA_PESCADOR,CARTA_PATINADOR,CARTA_DIABO,CARTA_CORVO,CARTA_LADRAO}) do
					local alreadySelected = false
					for playerIndex = 1, playerCount do
						if players[playerIndex].card==cardIndex then alreadySelected=true end
					end
					if not alreadySelected then 
						local score = 3
						if cardIndex==CARTA_LADRAO then
							if (bestPoints-players[playerTurn]:getPoints())>1 then
								score=(bestPoints-players[playerTurn]:getPoints())*3-2
							else
								score=1
							end
						elseif cardIndex==CARTA_CORVO then 
							score=0
							if players[playerTurn]:getPoints()==0 then score=score+2 end
							if bestPoints>0 then score=score+2 end
							if score == 2 then score=score+2 end
						elseif cardIndex==CARTA_DIABO then 
							score=firstPlayerAdvantage
						elseif cardIndex==CARTA_PATINADOR then 
							score=players[playerTurn]:getPoints()*2
						elseif cardIndex==CARTA_PESCADOR then 
							score=players[playerTurn].birds*4
						end
						if score<1 then score=1 end
						commands[cardIndex]=score
					end 
				end
				commands = Util.cutLowValues(commands,4,0)
				local selectedCommand = Util.selectKeyFromValuePercent(commands)
				cardTouch(nil, selectedCommand)
			end
		elseif step == STEP_KILLER then
			for i = 1, playerCount do 
				if i~=playerTurn then
					local score = (players[i]:getPoints()+players[i].boardPosition)*2
					commands[i]=score
				end 
			end
			commands = Util.cutLowValues(commands,5,0)
			local selectedCommand = Util.selectKeyFromValuePercent(commands)
			playerTouch(nil, selectedCommand)
		elseif step == STEP_ACTION then
			print("ai STEP_ACTION")
			local onlyZero = true
			for i = 1, playerCount do 
				if i~=playerTurn then
					local score = players[i]:getPoints()
					if score>0 then onlyZero=false end
					commands[i]=score*2
				end 
				if onlyZero then 
					for key,value in pairs(commands) do 
						commands[key]=1
					end
				end
			end
			-- Avoiding problems when everybody have no resources
			commands = onlyZero and Util.cutLowValues(commands,0,1) or Util.cutLowValues(commands,4,0)
			local selectedCommand = Util.selectKeyFromValuePercent(commands)
			print("selectedCommand="..selectedCommand)
			playerTouch(nil, selectedCommand)
		elseif step == STEP_MOVE then
			print("ai STEP_MOVE")
			local score = players[playerTurn]:getPoints()
			if score>2 then score=score*2 end
			commands[1]=score -- confirm
			commands[2]=3 -- cancel
			commands = Util.cutLowValues(commands,6,0)
			local selectedCommand = Util.selectKeyFromValuePercent(commands)
			print("selectedCommand="..selectedCommand)
			if selectedCommand==1 then
				confirmTouch(nil,true)
			else
				cancelTouch(nil,true)
			end
		elseif step == STEP_NEWORDER then
			local selectedCommand = playerTurn==1 and playerCount or playerTurn-1
			playerTouch(nil, selectedCommand)
		end
	end	
	timer.performWithDelay(delay,func)
end

--------------------------------------------------
--- Touch functions
--------------------------------------------------
-- If indexTouchByBot~=nil then is a bot command.

function validTouch(event, touchByBot)
	return touchReady() and gameOccurring and ((event and event.phase == "ended" and not players[playerTurn].isBot) or touchByBot)
end

function setTouchWaitTime(milliseconds)
	print("setTouchWaitTime milliseconds="..milliseconds)
	touchTimeout=system.getTimer()+milliseconds
end

function touchReady() -- Return if touch isn't waiting waitTime
	return touchTimeout<system.getTimer()
end

function cardTouch (event,indexTouchByBot)
	local cardIndex=0
	if validTouch(event, indexTouchByBot) then
		print("validTouch indexTouchByBot="..tostring(indexTouchByBot))
		if indexTouchByBot then
			cardIndex=indexTouchByBot
		else
			for i = 1, #cards do
				if (event.target == cards[i]) then
					cardIndex=i
					break
				end
			end
		end
	end
	if cardIndex ~=0 and not decisionTime then
		-- Selected card options at each step
		if step == STEP_SELECTCARD then
			-- Ignores if the card was already selected
			local alreadySelected = false
			for playerIndex = 1, playerCount do
				if players[playerIndex].card==cardIndex then alreadySelected=true end
			end
			if not alreadySelected then
				selectedCard=cardIndex
				for i =1, cardsLayer.numChildren do -- Get the index and store at selectedCardLayerIndex
					if cards[selectedCard] == cardsLayer[i] then
						selectedCardLayerIndex = i
						break
					end
				end
				local delay=2000
				setTouchWaitTime(delay)
				activateDecisionTime()
				aiCommand(nil,delay+2)
			end
			return true
		end
	end
end

function playerTouch (event,indexTouchByBot)
	local playerIndex = 0
	if validTouch(event, indexTouchByBot) then
		if indexTouchByBot then
			playerIndex=indexTouchByBot
		else
			for i = 1, playerCount do
				if (event.target == playersHUD[i]) then
					playerIndex = i
					break
				end
			end
		end
	end
	if playerIndex ~= 0 and not decisionTime then
		if not touchReady() then return true end
		-- Selected player option at each step
		if step == STEP_KILLER then
			if playerIndex~=playerTurn then  -- Suicide isn't allowed
				killPlayer(playerIndex)
				transition.to(blackBlock, {time=400, alpha=0, transition=easing.inOutQuad, onComplete=highlightPlayerHUDsDeactivate})
				-- Next step
				firstPlayer=playerTurn
				step = STEP_ACTION
				initializeActionTurn()
			end
			return true
		elseif step == STEP_ACTION then
			if playerIndex~=playerTurn then -- Clicked at the target
				if players[playerTurn].card==CARTA_LADRAO then
					stolenPlayer=playerIndex
					local stolen = players[playerIndex]:getHalfBirdsAndFish()
					local stolenBirds=stolen[1]
					local stolenFish=stolen[2]
					setPlayerFish(playerIndex,players[playerIndex].fish-stolenFish)
					setPlayerBirds(playerIndex,players[playerIndex].birds-stolenBirds)
					setPlayerFish(playerTurn,players[playerTurn].fish+stolenFish)
					setPlayerBirds(playerTurn,players[playerTurn].birds+stolenBirds)
					highlightPlayer(playerTurn)
					actionPerformed()
				elseif players[playerTurn].card==CARTA_CORVO then
					stolenPlayer=playerIndex
					local stolenPoints = 0
					if players[playerIndex].fish>0 then
						stolenPoints=2
						setPlayerFish(playerIndex,players[playerIndex].fish-2)
					else
						-- If is less than 2, steal all.
						stolenPoints = players[playerIndex].birds<2 and players[playerIndex].birds or 2
						setPlayerBirds(playerIndex,players[playerIndex].birds-stolenPoints)
					end
					players[playerTurn].boardPosition = players[playerTurn].boardPosition+stolenPoints
					movePlayerEffects(playerTurn,stolenPoints)
					actionPerformed()
				end
			end
			return true
		elseif step == STEP_NEWORDER then
			if playerIndex~=playerTurn then  -- Cannot choose yourself for the first in the next turn
				firstPlayer=playerIndex
				transition.to(blackBlock, {time=400, alpha=0, transition=easing.inOutQuad, onComplete=function() highlightPlayerHUDsDeactivate(); nextTurn() end})
				setTouchWaitTime(400)
			end
			return true
		end
	end
end

function confirmTouch (event,touchByBot)
	if validTouch(event, touchByBot) and decisionTime then
		if step == STEP_SELECTCARD then
			local delay=1000
			players[playerTurn].card=selectedCard
			setTouchWaitTime(delay)
			deactivateDecisionTime(playerTurn)
			if nextPlayerTurn() then
				highlightPlayer(playerTurn)
				aiCommand(nil,delay+2)
			else
				killChoice()
			end
		elseif step == STEP_MOVE then
			local playerTurnNow=playerTurn -- Print purposes
			print("playerTurnNow="..playerTurnNow.." players[playerTurnNow]:getPoints()="..players[playerTurnNow]:getPoints().." players[playerTurnNow].boardPosition="..players[playerTurnNow].boardPosition)
			movePlayerConsumingResources(playerTurn)
			print("2 playerTurnNow="..playerTurnNow.." players[playerTurnNow]:getPoints()="..players[playerTurnNow]:getPoints().." players[playerTurnNow].boardPosition="..players[playerTurnNow].boardPosition)
			nextMove()
		end		
		return true
	end
end

function cancelTouch (event,touchByBot)
	if validTouch(event, touchByBot) and decisionTime then
		if step == STEP_SELECTCARD then
			setTouchWaitTime(1600)
			deactivateDecisionTime()
		elseif step == STEP_MOVE then
			nextMove()
		end		
		return true
	end
end