

Dungeon = Class{}

function Dungeon:init(player, dungeon)
	self.player = player

	self.rooms = {}

	self.currentRoom = Room(self.player, PLAYER_START_X, PLAYER_START_Y)
	self.player.room = self.currentRoom

	self.nextRoom = nil

	self.cameraX = 0
	self.cameraY = 0
	self.shifting = false

	Event.on('shift-left', function()
		self:beginShifting(-VIRTUAL_WIDTH, 0)
	end)

	Event.on('shift-right', function()
		self:beginShifting(VIRTUAL_WIDTH, 0)
	end)

	Event.on('shift-up', function()
		self:beginShifting(0, -VIRTUAL_HEIGHT)
	end)

	Event.on('shift-down', function()
		self:beginShifting(0, VIRTUAL_HEIGHT)
	end)
end


function Dungeon:beginShifting(shiftX, shiftY)
	self.shifting = true

	local playerX, playerY = self.player.x, self.player.y
	local destinationX, destinationY = self.player.x, self.player.y

	if shiftX > 0 then
		playerX = VIRTUAL_WIDTH + (MAP_LEFT_EDGE)
		destinationX = MAP_LEFT_EDGE
	elseif shiftX < 0 then
		playerX = -VIRTUAL_WIDTH + (MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - TILE_SIZE - self.player.width)
		destinationX = MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - TILE_SIZE - self.player.width - 1
	elseif shiftY > 0 then
		playerY = VIRTUAL_HEIGHT + (MAP_RENDER_OFFSET_Y + self.player.height / 2)
		destinationY = MAP_RENDER_OFFSET_Y + self.player.height / 2
	else
		playerY = -VIRTUAL_HEIGHT + MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE - self.player.height
		destinationY = MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE - self.player.height
	end

	self.nextRoom = Room(self.player, destinationX, destinationY)
	self.nextRoom.adjacentOffsetX = shiftX
	self.nextRoom.adjacentOffsetY = shiftY

	for k, doorway in pairs(self.nextRoom.doorways) do
		doorway.open = true
	end

	Timer.tween(1, {
		[self] = {cameraX = shiftX, cameraY = shiftY},
		[self.player] = {x = playerX, y = playerY}
	}):finish(function()
		self:finishShifting()

		if shiftX < 0 then
			self.player.x = destinationX
			self.player.direction = 'left'
		elseif shiftX > 0 then
			self.player.x = destinationX
			self.player.direction = 'right'
		elseif shiftY < 0 then
			self.player.y = destinationY
			self.player.direction = 'up'
		else
			self.player.y = destinationY
			self.player.direction = 'down'
		end

		for k, doorway in pairs(self.currentRoom.doorways) do
			doorway.open = false
		end

		gSounds['door']:play()
	end)
end


function Dungeon:finishShifting()
	self.cameraX = 0
	self.cameraY = 0
	self.shifting = false
	self.currentRoom = self.nextRoom
	self.nextRoom = nil
	self.currentRoom.adjacentOffsetX = 0
	self.currentRoom.adjacentOffsetY = 0
	self.player.room = self.currentRoom
end

function Dungeon:update(dt)
	if not self.shifting then
		self.currentRoom:update(dt)
	else
		self.player.currentAnimation:update(dt)
	end
end

function Dungeon:render()
	if self.shifting then
		love.graphics.translate(-math.floor(self.cameraX), -math.floor(self.cameraY))
	end

	self.currentRoom:render()

	if self.nextRoom then
		self.nextRoom:render()
	end
end
