local Util = require("scripts.util")

DecisionBox = {}
DecisionBox.__index = DecisionBox

-- The last four itens are the objects
function DecisionBox.create(arrayRotation,colorNames,colorArray,layer,confirmImage,cancelImage,titleText,descriptionText)
    local object = {}
    setmetatable(object,DecisionBox)
    object.arrayX={340, 340, 444, 410, 460}
	object.arrayY={730, 310, 310, 504, 720}
	object.arrayRotation=arrayRotation
	object.colorNames=colorNames
	object.colorArray=colorArray
	object.layer=layer
	object.layer.alpha=0
	object.confirmImage=confirmImage
	object.confirmImage.x = 110
	object.confirmImage.y = 50
	object.cancelImage=cancelImage
	object.cancelImage.x = 110
	object.cancelImage.y = 130
	object.cardImage=nil
	object.cardImageWidth=0
	object.cardImageHeight=0
	object.animation=nil
	object.titleText=titleText
	object.titleText.x = 110
	object.titleText.y = 0
	object.descriptionText=descriptionText
	object.descriptionText.x = 110
	object.descriptionText.y = 20
    return object
end

function DecisionBox:activate(playerTurn,text)
	local index = playerTurn
	local colorNumber = 1
	self.layer.x=self.arrayX[index]
	self.layer.y=self.arrayY[index]
	self.layer.rotation = self.arrayRotation[index]
	self.titleText.text="Jogador "..self.colorNames[index]..":"
	self.titleText:setFillColor(self.colorArray[index][1],self.colorArray[index][2],self.colorArray[index][3])
	self.descriptionText.text=text
	self.descriptionText:setFillColor(colorNumber,colorNumber,colorNumber)
	transition.to( self.layer, { time=400, alpha=1, transition=easing.inOutQuad })
end

function DecisionBox:deactivate() 
	transition.to( self.layer, { time=400, alpha=0, transition=easing.inOutQuad })
end

-- Add a card to the box. The card must be at world position without a layer.
function DecisionBox:addCard(cardImage,animationPath)
	self.cardImage=cardImage
	self.cardImageWidth=cardImage.width
	self.cardImageHeight=cardImage.height
	Util.addDisplayObjectKeepingPosition(self.cardImage,self.layer)
	transition.to( self.cardImage, { delay=200, time=400, x=0, y=80, rotation=0, transition=easing.inOutQuad })
	local animationFunction = function()
		self.animation = criarAnimacao(self.cardImage, animationPath,false)
		self.layer:insert(self.animation)
		self.animation:play() 
	end
	transition.to( self.cardImage, { delay=600, time=400, width=270, height=369, transition=easing.inOutQuad, onComplete=animationFunction})
end

-- Remove a card for the box. The card will return at world position without a layer.
function DecisionBox:removeCard(newX,newY,newRotation,animationPath)
	Util.removeDisplayObjectKeepingPosition(self.cardImage,self.layer)
	self.animation:removeSelf()
	self.animation = criarAnimacao(self.cardImage, animationPath,true)
	self.animation:play() 
	local destroyAnimation = function()
		self.cardImage.isVisible=true
		transition.to( self.cardImage, {time=400, width=self.cardImageWidth, height=self.cardImageHeight, x=newX, y=newY, rotation=newRotation, transition=easing.inOutQuad})
		self.animation:removeSelf()
		self.animation=nil
		self.cardImage=nil
	end
	timer.performWithDelay(1000,destroyAnimation)
end

function DecisionBox:finalize()
	self.layer:removeSelf()
end