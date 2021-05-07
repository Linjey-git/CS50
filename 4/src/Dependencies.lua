
Class = require 'lib/class'
push = require 'lib/push'
Timer = require 'lib/knife.timer'


require 'src/constants'
require 'src/StateMachine'
require 'src/Util'

require 'src/states/BaseState'
require 'src/states/game/PlayState'
require 'src/states/game/StartState'

require 'src/states/game/VictoryState'
require 'src/states/game/GameOverState'

require 'src/states/entity/PlayerFallingState'
require 'src/states/entity/PlayerIdleState'
require 'src/states/entity/PlayerJumpState'
require 'src/states/entity/PlayerWalkingState'

require 'src/states/entity/PlayerDeathState'
require 'src/states/entity/PlayerVictoryState'

require 'src/states/entity/snail/SnailChasingState'
require 'src/states/entity/snail/SnailIdleState'
require 'src/states/entity/snail/SnailMovingState'

require 'src/Animation'
require 'src/Entity'
require 'src/GameObject'
require 'src/GameLevel'
require 'src/LevelMaker'
require 'src/Player'
require 'src/Snail'
require 'src/Tile'
require 'src/TileMap'

require 'src/Clock'


gSounds = {
	['jump'] = love.audio.newSource('sounds/jump.wav','static'),
	['death'] = love.audio.newSource('sounds/death.wav','static'),
	['play-bg'] = love.audio.newSource('sounds/music.wav','static'),
	['powerup-reveal'] = love.audio.newSource('sounds/powerup-reveal.wav','static'),
	['pickup'] = love.audio.newSource('sounds/pickup.wav','static'),
	['empty-block'] = love.audio.newSource('sounds/empty-block.wav','static'),
	['kill'] = love.audio.newSource('sounds/kill.wav','static'),
	['kill2'] = love.audio.newSource('sounds/kill2.wav','static'),
	
	['win'] = love.audio.newSource('sounds/win.wav','static'),
	
	['victory-bg'] = love.audio.newSource('sounds/victory-bg.mp3','static'),
	['game-over-bg'] = love.audio.newSource('sounds/gameover-bg.mp3','static')
}

gTextures = {
	['tiles'] = love.graphics.newImage('graphics/tiles.png'),
	['toppers'] = love.graphics.newImage('graphics/tile_tops.png'),
	['bushes'] = love.graphics.newImage('graphics/bushes_and_cacti.png'),
	['jump-blocks'] = love.graphics.newImage('graphics/jump_blocks.png'),
	['gems'] = love.graphics.newImage('graphics/gems.png'),
	['backgrounds'] = love.graphics.newImage('graphics/backgrounds.png'),
	['green-alien'] = love.graphics.newImage('graphics/pink_alien.png'),
	['creatures'] = love.graphics.newImage('graphics/creatures.png'),
	['keys-and-locks'] = love.graphics.newImage('graphics/keys_and_locks.png'),
	
	['poles'] = love.graphics.newImage('graphics/flags.png'),
	['flags'] = love.graphics.newImage('graphics/flags.png')
}

gFrames = {
	['tiles'] = GenerateQuads(gTextures['tiles'], TILE_SIZE, TILE_SIZE),

	['toppers'] = GenerateQuads(gTextures['toppers'], TILE_SIZE, TILE_SIZE),

	['bushes'] = GenerateQuads(gTextures['bushes'], 16, 16),
	['jump-blocks'] = GenerateQuads(gTextures['jump-blocks'], 16, 16),
	['gems'] = GenerateQuads(gTextures['gems'], 16, 16),
	['backgrounds'] = GenerateQuads(gTextures['backgrounds'], 256, 128),
	['green-alien'] = GenerateQuads(gTextures['green-alien'], 16, 20),
	['creatures'] = GenerateQuads(gTextures['creatures'], 16, 16),
	['keys-and-locks'] = GenerateQuads(gTextures['keys-and-locks'], 16, 16),
	
	['poles'] = GenerateQuadsPoles(gTextures['poles'], 6, 16, 16),
	['flags'] = GenerateQuadsFlags(gTextures['flags'], 6, 4, 16, 16)
}


gFrames['tilesets'] = GenerateTileSets(gFrames['tiles'],
	TILE_SETS_WIDE, TILE_SETS_TALL, TILE_SET_WIDTH, TILE_SET_HEIGHT)

gFrames['toppersets'] = GenerateTileSets(gFrames['toppers'],
	TOPPER_SETS_WIDE, TOPPER_SETS_TALL, TILE_SET_WIDTH, TILE_SET_HEIGHT)

gFonts = {
	['small'] = love.graphics.newFont('fonts/font.ttf', 8),
	['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
	['large'] = love.graphics.newFont('fonts/font.ttf', 32),
	['title'] = love.graphics.newFont('fonts/ArcadeAlternate.ttf', 32)
}

function gPrint(text, x, y, limit, align)
	love.graphics.setColor(0, 0, 0, 1)

	if align ~= nil or limit ~= nil then
		if limit == nil then
			limit = VIRTUAL_WIDTH
		elseif align == nil then
			align = 'left'
		end
		local font = love.graphics.getFont()
		if font == gFonts['title'] or font == gFonts['large'] then
			love.graphics.printf(text, x + 2, y + 2, limit, align)
		end
		love.graphics.printf(text, x + 1, y + 1, limit, align)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(text, x, y, limit, align)

	else
		love.graphics.print(text, x + 1, y + 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(text, x, y)
	end
end
