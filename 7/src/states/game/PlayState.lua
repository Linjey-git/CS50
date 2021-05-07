

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.level = Level()

    gSounds['field-music']:setLooping(true)
    gSounds['field-music']:play()

    self.dialogueOpened = false
end

function PlayState:update(dt)
    if not self.dialogueOpened and love.keyboard.wasPressed(CTRL_HEAL) then
        
        
        gSounds['heal']:play()
        self.level.player.party.pokemon[1].currentHP = self.level.player.party.pokemon[1].HP
        
        
        gStateStack:push(DialogueState('Your Pokemon has been healed!',
    
        function()
            self.dialogueOpened = false
        end))
    end

    self.level:update(dt)
end

function PlayState:render()
    self.level:render()
end