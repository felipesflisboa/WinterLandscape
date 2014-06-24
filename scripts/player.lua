Player = {}
Player.__index = Player

function Player.create(index,isBot)
    local object = {}
    setmetatable(object,Player)
    object.index = index 
    object.isBot=isBot and true or false
    object.card=0
	object.birds=0
	object.fish=0
	object.boardPosition=1
	object.dead=false
    return object
end

function Player:getPoints()
   return self.birds+self.fish*2
end

-- Consumes all fish and bird for moving. Returns the move distance
function Player:moveConsumingResources(double)
	double=double or false
	moveDistance = double and self:getPoints()*2 or self:getPoints()
	self.boardPosition = self.boardPosition + moveDistance
	self.birds=0
	self.fish=0
	return moveDistance
end

-- Returns an array with half of birds and fish (counting as total points).
-- Round up. Doesn't decrease from this object.
function Player:getHalfBirdsAndFish()
	local stolenBirds=0
	local stolenFish=0
	local totalSelfPoints = self:getPoints()
	while true do
		if (stolenFish*2+stolenBirds)*2>=totalSelfPoints then
			break
		elseif (stolenFish*2+stolenBirds)*2==totalSelfPoints-1 then
			if stolenBirds < self.birds then
				stolenBirds = stolenBirds+1
			elseif stolenFish < self.fish then
				stolenFish = stolenFish+1
			end
			break
		end
		if stolenFish < self.fish then
			stolenFish = stolenFish+1
		elseif stolenBirds < self.birds then
			stolenBirds = stolenBirds+1
		end
	end
	return stolenBirds,stolenFish
end

function Player:printStatus() -- Debug purposes
    print("Player="..self.index.." card="..self.card.." birds="..self.birds.." fish="..self.fish
			.." boardPosition="..self.boardPosition.." dead="..(self.dead and 1 or 0))
end