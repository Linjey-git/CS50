

Entity = Class{}

function Entity:init(def)
    self.direction = 'down'

    self.animations = self:createAnimations(def.animations)

    self.mapX = def.mapX
    self.mapY = def.mapY

    self.width = def.width
    self.height = def.height

    self.x = (self.mapX - 1) * TILE_SIZE

    
    self.y = (self.mapY - 1) * TILE_SIZE - self.height / 2
end

function Entity:changeState(name)
    self.stateMachine:change(name)
end

function Entity:changeAnimation(name)
    self.currentAnimation = self.animations[name]
end

function Entity:createAnimations(animations)
    local animationsReturned = {}

    for k, animationDef in pairs(animations) do
        animationsReturned[k] = Animation {
            texture = animationDef.texture or 'entities',
            frames = animationDef.frames,
            interval = animationDef.interval
        }
    end

    return animationsReturned
end


function Entity:onInteract()

end

function Entity:processAI(params, dt)
    self.stateMachine:processAI(params, dt)
end

function Entity:update(dt)
    self.currentAnimation:update(dt)
    self.stateMachine:update(dt)
end

function Entity:render()
    self.stateMachine:render()
end