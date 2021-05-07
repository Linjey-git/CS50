--[[
    v Class
    Author: Serhii Horbonos
    linjey.ubi@gmail.com

    The PauseState is the pausing screen of the game. It should
    display "Pause" and also key of continuation.
]]

PauseState = Class{__includes = BaseState}

function PauseState:enter(playState)
    self.playState = playState 
end

function PauseState:exit()
    return self.playState
end

function PauseState:update(dt)
    -- transition to countdown when enter/return are pressed
    if love.keyboard.wasPressed('p') then
        gStateMachine:change('play')
    end
end

function PauseState:render()
    -- simple UI code
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Fifty Bird', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Pause ', 0, 100, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Press "P" to proceed', 0, 120, VIRTUAL_WIDTH, 'center')
end