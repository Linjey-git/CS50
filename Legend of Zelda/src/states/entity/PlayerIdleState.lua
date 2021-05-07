

PlayerIdleState = Class{__includes = BaseState}

function PlayerIdleState:init(player)
	self.player = player

	self.animation = Animation {
		frames = {1},
		interval = 1
	}

	self.player.currentAnimation = self.animation
end

function PlayerIdleState:update(dt)

	if self.player.victory then
		self.player:changeState('victory')
	end

	if love.keyboard.isDown(PLAYER_LEFT) or love.keyboard.isDown(PLAYER_RIGHT) then
		self.player:changeState('walking')
	end

	if love.keyboard.wasPressed('space') then
		self.player:changeState('jump', {heightMod = 0, xMomentum = PLAYER_WALK_SPEED})
	end

	for k, entity in pairs(self.player.level.entities) do
		if entity:collides(self.player) then
			self.player.gameOver = true
			self.player:changeState('death')
		end
	end
end
