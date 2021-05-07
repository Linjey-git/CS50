

Room = Class{}

function Room:init(player, x, y)

	self.width = MAP_WIDTH
	self.height = MAP_HEIGHT

	self.player = player

	self.occupiedTiles = {}
	for i = 1, self.height do
		self.occupiedTiles[i] = {}
	end
	self.playerStartX = math.floor((x - MAP_RENDER_OFFSET_X) / TILE_SIZE)
	self.playerStartY = math.floor((y - MAP_RENDER_OFFSET_Y) / TILE_SIZE)
	for i=0, 2 do
		self:fillTile(self.playerStartX, self.playerStartY + i)
		self:fillTile(self.playerStartX + 1, self.playerStartY + i)
	end

	self.objects = {}
	self:generateObjects()

	self.tiles = {}
	self:generateWallsAndFloors()

	self.entities = {}
	self:generateEntities()

	self.projectiles = {}

	self.doorways = {}
	table.insert(self.doorways, Doorway('top', false, self))
	table.insert(self.doorways, Doorway('bottom', false, self))
	table.insert(self.doorways, Doorway('left', false, self))
	table.insert(self.doorways, Doorway('right', false, self))

	self.renderOffsetX = MAP_RENDER_OFFSET_X
	self.renderOffsetY = MAP_RENDER_OFFSET_Y

	self.adjacentOffsetX = 0
	self.adjacentOffsetY = 0

end

function Room:generateEntities()
	local types = {'skeleton', 'slime', 'bat', 'ghost', 'spider'}

	for i = 1, 10 do
		local type = types[math.random(#types)]
		local entityX, entityY = self:placeEntity()

		table.insert(self.entities, Entity {
			animations = ENTITY_DEFS[type].animations,
			walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,
			hitbox = ENTITY_DEFS[type].hitbox,
			hurtbox = ENTITY_DEFS[type].hurtbox,
			flier = ENTITY_DEFS[type].flier,
			room = self,

			x = entityX,
			y = entityY,

			width = 16,
			height = 16,

			health = 1,
			onDeath = function(entity)
				if math.random(8) > 6 then
					Timer.after(KNOCKBACK_SPEED + 0.8, function()
						table.insert(self.objects,
							GameObject(GAME_OBJECT_DEFS['heart'], entity.x, entity.y))
					end)
				end
			end
		})

		self.entities[i].stateMachine = StateMachine {
			['walk'] = function() return EntityWalkState(self.entities[i]) end,
			['idle'] = function() return EntityIdleState(self.entities[i]) end
		}

		self.entities[i]:changeState('idle')
	end
end


function Room:generateObjects()
	local x, y = self:placeEntity()
	table.insert(self.objects, GameObject(GAME_OBJECT_DEFS['switch'], x, y))

	local switch = self.objects[1]

	switch.onCollide = function()
		if switch.state == 'unpressed' then
			switch.state = 'pressed'

			for k, doorway in pairs(self.doorways) do
				doorway.open = true
			end

			gSounds['door']:play()
		end
	end
	local numberPots = math.random(30)
	for i = 0, numberPots do
		local x, y = self:placeEntity()
		table.insert(self.objects, GameObject(GAME_OBJECT_DEFS['pot'], x, y))
	end
end

function Room:generateWallsAndFloors()
	for y = 1, self.height do
		table.insert(self.tiles, {})

		for x = 1, self.width do
			local id = TILE_EMPTY

			if x == 1 and y == 1 then
				id = TILE_TOP_LEFT_CORNER
			elseif x == 1 and y == self.height then
				id = TILE_BOTTOM_LEFT_CORNER
			elseif x == self.width and y == 1 then
				id = TILE_TOP_RIGHT_CORNER
			elseif x == self.width and y == self.height then
				id = TILE_BOTTOM_RIGHT_CORNER

			elseif x == 1 then
				id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
			elseif x == self.width then
				id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
			elseif y == 1 then
				id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
			elseif y == self.height then
				id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
			else
				id = TILE_FLOORS[math.random(#TILE_FLOORS)]
			end

			table.insert(self.tiles[y], {
				id = id
			})
		end
	end
end

function Room:update(dt)
	if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

	self.player:update(dt)

	for i = #self.entities, 1, -1 do
		local entity = self.entities[i]
		if not entity.dead then
			entity:processAI(dt)
		end

		entity:update(dt)

		if not entity.dead and self.player:collides(entity.hitbox)
			and not self.player.invulnerable then
			if self.player.idle then
				if entity.direction == 'right' then
					self.player.directionHit = 'left'
				elseif entity.direction == 'left' then
					self.player.directionHit = 'right'
				elseif entity.direction == 'down' then
					self.player.directionHit = 'up'
				else
					self.player.directionHit = 'down'
				end
			end
			gSounds['hit-player']:play()
			self.player:changeState('damage')
			self.player:damage(1)
			self.player:goInvulnerable(1)

			if self.player.health == 0 then
				gStateMachine:change('game-over')
			end
		end

		for p, projectile in pairs(self.projectiles) do
			projectile:update(dt)
			if entity:collides(projectile) and not entity.dead and not projectile.exploded then
				if projectile.fireDirection == 'left' then
					entity.directionHit = 'right'
				elseif projectile.fireDirection == 'right' then
					entity.directionHit = 'left'
				elseif projectile.fireDirection == 'up' then
					entity.directionHit = 'down'
				elseif projectile.fireDirection == 'down' then
					entity.directionHit = 'up'
				end
				entity:damage(1)
				gSounds['hit-enemy']:setVolume(0.6)
				gSounds['hit-enemy']:play()
				projectile:explode()

		elseif 	projectile.x <= MAP_LEFT_EDGE - projectile.width or
				projectile.x >= MAP_RIGHT_EDGE or
				projectile.y <= MAP_TOP_EDGE - 2 - projectile.height or
				projectile.y  >= MAP_BOTTOM_EDGE then
						projectile:explode()
			end

			
			if projectile.timeExploded > 10 then
				table.remove(self.projectiles, p)
			end
		end
	end

	for k, object in pairs(self.objects) do
		object:update(dt)

		if self.player:collides(object) then
			object.onCollide(self.player, object)
			if object.consumed then
				table.remove(self.objects, k)
			end
		end
	end
end



function Room:placeEntity()
	local x = math.random(self.width - 2)
	local y = math.random(self.height - 2)
	while(self.occupiedTiles[y][x] == true) do
		x = math.random(self.width - 2)
		y = math.random(self.height - 2)
	end
	self:fillTile(x, y)
	return MAP_RENDER_OFFSET_X + TILE_SIZE * x, MAP_RENDER_OFFSET_Y + TILE_SIZE * y
end

function Room:fillTile(x, y)
	if self.occupiedTiles[y] == nil then
		self.occupiedTiles[y] = {}
	end
	self.occupiedTiles[y][x] = true
end

function Room:emptyTile(x, y)
	if self.occupiedTiles[y] == nil then
		self.occupiedTiles[y] = {}
	end
	self.occupiedTiles[y][x] = false
end

function Room:render()
	for y = 1, self.height do
		for x = 1, self.width do
			local tile = self.tiles[y][x]
			love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
				(x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX,
				(y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
		end
	end

	if gShowDebug then
		love.graphics.setColor(255, 0, 255, 200)
		for i=1, MAP_HEIGHT - 2 do
			for j=1, MAP_WIDTH - 2 do
				if self.occupiedTiles[i][j] == true then
					love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + j *
					TILE_SIZE, MAP_RENDER_OFFSET_Y + i * TILE_SIZE, TILE_SIZE,
					TILE_SIZE)
				end
			end
		end
		love.graphics.setColor(255, 255, 255, 255)

		love.graphics.rectangle('fill', self.playerStartX * TILE_SIZE + MAP_RENDER_OFFSET_X,
								self.playerStartY * TILE_SIZE + MAP_RENDER_OFFSET_Y,
								TILE_SIZE * 2, TILE_SIZE * 3)
		love.graphics.setFont(gFonts['medium'])
		love.graphics.printf('x: ' .. tostring(self.playerStartX) .. '  y: ' ..
							tostring(self.playerStartY), 0, 0, VIRTUAL_WIDTH, 'right')
		love.graphics.printf('projectiles: ' .. tostring(#self.projectiles),
										0, 200, VIRTUAL_WIDTH, 'right')
	end

	for k, doorway in pairs(self.doorways) do
		doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
	end

	for k, object in pairs(self.objects) do
		object:render(self.adjacentOffsetX, self.adjacentOffsetY)
	end

	for k, projectile in pairs(self.projectiles) do
		projectile:render(self.adjacentOffsetX, self.adjacentOffsetY)
	end

	for k, entity in pairs(self.entities) do
		entity:render(self.adjacentOffsetX, self.adjacentOffsetY)
	end

	love.graphics.stencil(function()
		love.graphics.rectangle('fill', -TILE_SIZE - 6,
				MAP_RENDER_OFFSET_Y + (self.height / 2) * TILE_SIZE - TILE_SIZE,
				TILE_SIZE * 2 + 6, TILE_SIZE * 2)

		love.graphics.rectangle('fill',
				MAP_RENDER_OFFSET_X + (self.width * TILE_SIZE) - 6,
				MAP_RENDER_OFFSET_Y + (self.height / 2) * TILE_SIZE - TILE_SIZE,
				TILE_SIZE * 2 + 6, TILE_SIZE * 2)

		love.graphics.rectangle('fill',
				MAP_RENDER_OFFSET_X + (self.width / 2) * TILE_SIZE - TILE_SIZE,
				-TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

		love.graphics.rectangle('fill',
				MAP_RENDER_OFFSET_X + (self.width / 2) * TILE_SIZE - TILE_SIZE,
				VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
		end, 'replace', 1)

	love.graphics.setStencilTest('less', 1)

	if self.player then
		self.player:render()
	end

	love.graphics.setStencilTest()


	if gShowGrid then
		love.graphics.setColor(0, 0, 255, 128)
		for x = MAP_RENDER_OFFSET_X, VIRTUAL_WIDTH, 16 do
			for y = MAP_RENDER_OFFSET_Y, VIRTUAL_HEIGHT, 16 do
				love.graphics.rectangle('line', x, y, TILE_SIZE, TILE_SIZE)
			end
		end
		love.graphics.setColor(255, 255, 255, 255)
	end
end
