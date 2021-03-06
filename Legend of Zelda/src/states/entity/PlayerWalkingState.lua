

PlayerWalkingState = Class{__includes = BaseState}

function PlayerWalkingState:init(player)
	self.player = player
	self.animation = Animation {
		frames = {10, 11},
		interval = 0.1
	}
	self.player.currentAnimation = self.animation
end

function PlayerWalkingState:update(dt)
	self.player.currentAnimation:update(dt)

	if self.player.victory then
		self.player:changeState('victory')
	end

	if not love.keyboard.isDown(PLAYER_LEFT) and not love.keyboard.isDown(PLAYER_RIGHT) then
		self.player:changeState('idle')
	else
		local tileBottomLeft = self.player.map:pointToTile(self.player.x + 4, self.player.y + self.player.height)
		local tileBottomRight = self.player.map:pointToTile(self.player.x + self.player.width - 4, self.player.y + self.player.height)

		self.player.y = self.player.y + 1

		local collidedObjects = self.player:checkObjectCollisions()

		self.player.y = self.player.y - 1

		if #collidedObjects == 0 and (tileBottomLeft and tileBottomRight) and (not tileBottomLeft:collidable() and not tileBottomRight:collidable()) then
			self.player.dy = 0
			self.player:changeState('falling', {xMomentum = self.player.speed})
		elseif love.keyboard.isDown(PLAYER_LEFT) then
			self.player.x = self.player.x - self.player.speed * dt
			self.player.direction = 'left'
			self.player:checkLeftCollisions(dt)
		elseif love.keyboard.isDown(PLAYER_RIGHT) then
			self.player.x = self.player.x + self.player.speed * dt
			self.player.direction = 'right'
			self.player:checkRightCollisions(dt)
		end
	end

	for k, entity in pairs(self.player.level.entities) do
		if entity:collides(self.player) then
			self.player.gameOver = true
			self.player:changeState('death')
		end
	end

	if love.keyboard.wasPressed(PLAYER_JUMP) then
		self.player:changeState('jump', {heightMod = 0, xMomentum = self.player.speed})
	end
end
