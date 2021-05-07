

PlayState = Class{__includes = BaseState}

function PlayState:init()
	self.camX = 0
	self.camY = 0
	self.backgroundX = 0

	self.gravityOn = true
	self.gravityAmount = 6

	gSounds['play-bg']:setLooping(true)
	gSounds['play-bg']:setVolume(0.3)
	gSounds['play-bg']:play()

	self.victoryTimer = 0
	self.gameOverTimer = 0
	self.victory = false

end

function PlayState:enter(params)

	self.level = params.level
	self.levelNumber = params.levelNumber
	self.background = params.background
	self.tileMap = self.level.tileMap
	self.clock = params.clock
	local passedScore = params.score

	self.drop = 0
	for column = 1, self.level.tileMap.width do
			local columnEmpty = true
		for row = 1, self.level.tileMap.height do
			if self.level.tileMap.tiles[row][column].id == TILE_ID_GROUND then
				columnEmpty = false
				self.drop = column - 1
				break
			end
		end
		if columnEmpty == false then
			break
		end
	end

	self.player = Player({
		x = self.drop * TILE_SIZE, y = 0,
		width = 16, height = 20,
		texture = 'green-alien',
		stateMachine = StateMachine {
			['idle'] = function() return PlayerIdleState(self.player) end,
			['walking'] = function() return PlayerWalkingState(self.player) end,
			['jump'] = function() return PlayerJumpState(self.player, self.gravityAmount) end,
			['falling'] = function() return PlayerFallingState(self.player, self.gravityAmount) end,
			['death'] = function() return PlayerDeathState(self.player, self.gravityAmount) end,
			['victory'] = function() return PlayerVictoryState(self.player) end
		},
		map = self.tileMap,
		level = self.level,
		score = (passedScore == 0) and 0 or passedScore
	})

	self:spawnEnemies()

	self.player:changeState('falling', {xMomentum = PLAYER_WALK_SPEED})

	self.clock.pause = false
end

function PlayState:update(dt)
	Timer.update(dt)
	self.clock:update(dt)

	if self.player.victory then
		self.victory = true
	end

	if self.victory and self.victoryTimer == 0 then
		gSounds['play-bg']:stop()
		gSounds['win']:setVolume(0.5)
		gSounds['win']:play()
		self.clock.pause = true
		self.victoryTimer = 2.87 
	end

	if self.victoryTimer < 0 then
		gStateMachine:change('victory', {
			player = self.player,
			levelNumber = self.levelNumber,
			background = self.background,
			clock = self.clock
		})
	end

	if self.victoryTimer > 0 then
		self.victoryTimer = self.victoryTimer - dt
	end

	if self.player.gameOver then
		love.audio.stop()
		gSounds['death']:setVolume(0.5)
		gSounds['death']:play()
		self.clock.pause = true
		self.gameOverTimer = 1.5
		self.player.dead = true
		self.player.gameOver = false
	end

	if self.gameOverTimer > 0 then
		self.gameOverTimer = self.gameOverTimer - dt
	end

	if self.gameOverTimer < 0 then
		gStateMachine:change('game-over', {
			player = self.player,
			levelNumber = self.levelNumber,
			background = self.background,
			clock = self.clock
		})
	end

	self.level:clear()

	self.player:update(dt)
	self.level:update(dt)

	if self.player.x <= 0 then
		self.player.x = 0
	elseif self.player.x > TILE_SIZE * self.tileMap.width - self.player.width and not self.victory then
		self.player.x = TILE_SIZE * self.tileMap.width - self.player.width
	end

	self:updateCamera()
end

function PlayState:render()
	love.graphics.push()
	love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX), 0)
	love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX),
		gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
	love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256), 0)
	love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256),
		gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)

	love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))

	self.level:render()

	self.player:render()
	love.graphics.pop()

	love.graphics.setFont(gFonts['medium'])
	gPrint(tostring(self.player.score), 4, 4)

	self.clock:render()

	if self.player.key > 0 then
		love.graphics.setColor(0, 0, 0, 0)
		love.graphics.rectangle('fill', 0, VIRTUAL_HEIGHT - 16, 16, 16)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(gTextures['keys-and-locks'], gFrames['keys-and-locks'][self.player.key], 0, VIRTUAL_HEIGHT - 16)

	elseif self.player.goal > 0 then
		love.graphics.setColor(0, 0, 0, 0)
		love.graphics.rectangle('fill', 0, VIRTUAL_HEIGHT - 16, 16, 16)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(gTextures['flags'], gFrames['flags'][self.player.goal], 0, VIRTUAL_HEIGHT - 12)
	end
end

function PlayState:updateCamera()
	if not self.victory then
		self.camX = math.max(0,
			math.min(TILE_SIZE * self.tileMap.width - VIRTUAL_WIDTH,
			self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

		self.backgroundX = (self.camX / 3) % 256
	end
end

function PlayState:spawnEnemies()
	for x = 1, self.tileMap.width do

		local groundFound = false

		for y = 1, self.tileMap.height do
			if not groundFound then
				if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
					groundFound = true

					if math.random(10) == 1 then
						local snailType = (math.random(4) < 3) and 1 or 2

						local snail
						snail = Snail {
							texture = 'creatures',
							id = (snailType == 1) and 'snail1' or 'snail2',
							x = (x - 1) * TILE_SIZE,
							y = (y - 2) * TILE_SIZE + 2,
							width = 16,
							height = 16,
							type = snailType,
							hp = snailType,
							scoreMod = snailType * snailType,
							stateMachine = StateMachine {
								['idle'] = function() return SnailIdleState(self.tileMap, self.player, snail) end,
								['moving'] = function() return SnailMovingState(self.tileMap, self.player, snail) end,
								['chasing'] = function() return SnailChasingState(self.tileMap, self.player, snail) end
							}
						}
						snail:changeState('idle', {
							wait = math.random(5)
						})

						table.insert(self.level.entities, snail)
					end
				end
			end
		end
	end
end
