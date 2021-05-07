

BattleMessageState = Class{__includes = BaseState}

function BattleMessageState:init(msg, onClose, canInput)
    self.textbox = Textbox(0, VIRTUAL_HEIGHT - 64, VIRTUAL_WIDTH, 64, msg, gFonts['medium'])

    
    self.onClose = onClose or function() end

    
    self.canInput = canInput

    
    if self.canInput == nil then self.canInput = true end
end

function BattleMessageState:update(dt)
    if self.canInput then
        self.textbox:update(dt)

        if self.textbox:isClosed() then
            gStateStack:pop()
            self.onClose()
        end
    end
end

function BattleMessageState:render()
    self.textbox:render()
end