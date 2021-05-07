

require 'src/Dependencies'

function love.load()
	love.graphics.setDefaultFilter('nearest', 'nearest')
	love.graphics.setFont(gFonts['medium'])
	love.window.setTitle('Super 50 Bros.')

	math.randomseed(os.time())

	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = false,
		vsync = true,
		resizable = true
	})

	gStateMachine = StateMachine {
		['start'] = function() return StartState() end,
		['play'] = function() return PlayState() end,
		['victory'] = function() return VictoryState() end,
		['game-over'] = function() return GameOverState() end
	}
	gStateMachine:change('start')

	love.keyboard.keysPressed = {}
end

function love.resize(w, h)
	push:resize(w, h)
end

function love.keypressed(key)
	if key == 'escape' then

		gSounds['win']:stop()
		gSounds['victory-bg']:stop()
		gSounds['game-over-bg']:stop()
		gStateMachine:change('start')
	end

	love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
	return love.keyboard.keysPressed[key]
end

function love.update(dt)
	gStateMachine:update(dt)

	love.keyboard.keysPressed = {}
end

function love.draw()
	push:start()
	gStateMachine:render()
	push:finish()
end
