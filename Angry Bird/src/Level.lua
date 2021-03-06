
Level = Class{}

function Level:init()
    self.world = love.physics.newWorld(0, 300)
    self.destroyedBodies = {}

    self.playerCollided = false
    function beginContact(a, b, coll)
        local types = {}
        types[a:getUserData()] = true
        types[b:getUserData()] = true

        if types['Obstacle'] and types['Player'] then
            if a:getUserData() == 'Obstacle' then
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            else
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            end

            self.playerCollided = true
        end

        if types['Obstacle'] and types['Alien'] then
            if a:getUserData() == 'Obstacle' then
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            else
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            end
        end

        if types['Player'] and types['Alien'] then
            if a:getUserData() == 'Player' then
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)
                
                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            else
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            end

            self.playerCollided = true
        end

       if types['Player'] and types['Ground'] then
            self.playerCollided = true
            gSounds['bounce']:stop()
            gSounds['bounce']:play()
        end
    end
    function endContact(a, b, coll)
        
    end

    function preSolve(a, b, coll)

    end

    function postSolve(a, b, coll, normalImpulse, tangentImpulse)

    end

    self.world:setCallbacks(beginContact, endContact, preSolve, postSolve)

     self.launchMarker = AlienLaunchMarker(self.world)

    self.aliens = {}

    self.players = {}

    self.obstacles = {}

    self.edgeShape = love.physics.newEdgeShape(0, 0, VIRTUAL_WIDTH * 3, 0)

   table.insert(self.aliens, Alien(self.world, 'square', VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2, 'Alien'))

    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 120, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 35, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'horizontal',
        VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - 35 - 110 - 35 / 2))

    self.groundBody = love.physics.newBody(self.world, -VIRTUAL_WIDTH, VIRTUAL_HEIGHT - 35, 'static')
    self.groundFixture = love.physics.newFixture(self.groundBody, self.edgeShape)
    self.groundFixture:setFriction(0.5)
    self.groundFixture:setUserData('Ground')

    self.background = Background()

    self.hasSplit = false
end

function Level:update(dt)
    self.launchMarker:update(dt)

    self.world:update(dt)

     for k, body in pairs(self.destroyedBodies) do
        if not body:isDestroyed() then 
            body:destroy()
        end
    end

    self.destroyedBodies = {}

    for i = #self.obstacles, 1, -1 do
        if self.obstacles[i].body:isDestroyed() then
            table.remove(self.obstacles, i)

            local soundNum = math.random(5)
            gSounds['break' .. tostring(soundNum)]:stop()
            gSounds['break' .. tostring(soundNum)]:play()
        end
    end

    for i = #self.aliens, 1, -1 do
        if self.aliens[i].body:isDestroyed() then
            table.remove(self.aliens, i)
            gSounds['kill']:stop()
            gSounds['kill']:play()
        end
    end

    for k, player in pairs(self.players) do
        local xPos, yPos = player.body:getPosition()
        local xVel, yVel = player.body:getLinearVelocity()
        
        if xPos < 0 or (math.abs(xVel) + math.abs(yVel) < 5) then
            player.body:destroy()
            table.remove(self.players, k)
        end
    end

    if self.launchMarker.launched then
        local xPos, yPos = self.launchMarker.alien.body:getPosition()
        local xVel, yVel = self.launchMarker.alien.body:getLinearVelocity()
        
        if xPos < 0 or (math.abs(xVel) + math.abs(yVel) < 5) and #self.players == 0 then
            self.launchMarker.alien.body:destroy()
            self.launchMarker = AlienLaunchMarker(self.world)

            self.hasSplit = false
            self.playerCollided = false

            if #self.aliens == 0 then
                gStateMachine:change('start')
            end
        end
    end

    if love.keyboard.isDown(PLAYER_SPLIT) and not self.hasSplit 
            and self.launchMarker.launched and not self.playerCollided then

        local gravX, gravY = self.world:getGravity()
        local playerVelocityX, playerVelocityY = self.launchMarker.alien.body:getLinearVelocity()
        local playerX = self.launchMarker.alien.body:getX()
        local playerY = self.launchMarker.alien.body:getY()
        local topAlien = Alien(self.world, 'round', playerX, playerY - 40, 'Player', 15)
        local botAlien = Alien(self.world, 'round', playerX, playerY + 40, 'Player', 10)

        topAlien.body:setLinearVelocity(playerVelocityX, playerVelocityY - 20) 
        botAlien.body:setLinearVelocity(playerVelocityX, playerVelocityY + 30)

        topAlien.fixture:setRestitution(0.4)
        botAlien.fixture:setRestitution(0.4)
        topAlien.body:setAngularDamping(1)
        botAlien.body:setAngularDamping(1)

        table.insert(self.players, topAlien)
        table.insert(self.players, botAlien)
        
        self.hasSplit = true
    end

    if #self.aliens == 0 and #love.mouse.keysPressed > 0 then
        gStateMachine:change('start')
    end
end

function Level:render()
    for x = -VIRTUAL_WIDTH, VIRTUAL_WIDTH * 2, 35 do
        love.graphics.draw(gTextures['tiles'], gFrames['tiles'][12], x, VIRTUAL_HEIGHT - 35)
    end

    self.launchMarker:render()

    for k, alien in pairs(self.aliens) do
        alien:render()
    end

    for k, obstacle in pairs(self.obstacles) do
        obstacle:render()
    end

    for k, player in pairs(self.players) do
        player:render()
    end

    if not self.launchMarker.launched then
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf('Click and drag circular alien to shoot!',
            0, 64, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255, 255, 255, 255)
    end
    
    if #self.aliens == 0 then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf('VICTORY', 0, VIRTUAL_HEIGHT / 2 - 32, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255, 255, 255, 255)
    end

end