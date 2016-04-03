local Signal = require 'lib.hump.signal'
local Timer = require 'lib.hump.timer'
local Gamestate = require "lib.hump.gamestate"

local state = {
  intro = {},
  driving = {},
  reading = {},
  outro = {},
}

local love = love
local debug = false

local music
local img = {}

local a=64 -- pixels
local scale = 8

local fuel = 1
local speed = 0
local accel = 45
local friction = 37
local maxspeed = 80
local consumption = .005
local distance = 0

local palette = {
{43,8,6},
{123,163,139},
{220,208,160},
{255,255,184},
{196,32,41},
}

local texts = {
  [0] = "Press up arrow",
  [2] = "Are we there yet?",
  [10] = "We will not get\nany further\nwithout more fuel",
  [50] = "There's no way back",
  [55] = "Does it make any sense?",
  [66] = "Will it stop?",
  "Maybe I'm just too old",
  "Where am I even going?",
  "Didn't I had someone with me?",
  "She will not remember",
  "They are safe there",
  "They are safer where they are now",
  "I will miss her",

}
local sortedTextsKeys = {}

local sfx = {}


--------------


local getQuads = function(image)
  local quads={}
  for i=0,image:getWidth()/a do
    quads[i] = love.graphics.newQuad(a*i, 0, a, a, image:getWidth(), image:getHeight())
  end
  return quads
end

local scaleWindow = function()
  if scale < 1 then scale = 1; return end
  if not love.window.setMode( scale*a, scale*a ) then scale = 8 end -- default is the value fitting conf.lua
end

function love.load()
  scaleWindow()
  love.graphics.setDefaultFilter("nearest")

  music = love.audio.newSource( 'music/Stunts (1990) - Soundtrack.mp3', 'stream' )
  music:setLooping( true )
  music:setVolume(.7)
  --music:play()

  for _,v in ipairs(love.filesystem.getDirectoryItems("sfx")) do
    sfx[v:match("^(.+)%..+$")] = love.audio.newSource("sfx/"..v, "static")
  end
  sfx.idle:setLooping(true)
  sfx.going:setLooping(true)

  for _,f in ipairs({"bg1", "fuel", "road", "car", "sign"}) do
    img[f] = {}
    img[f].img = love.graphics.newImage("img/"..f..".png")
    img[f].quads = getQuads(img[f].img)
    --img[f].counter = 0
    img[f].quads.current = img[f].quads[0]
  end

  love.graphics.setNewFont( "font/tom-thumb.bdf", 6 )

  for k in pairs(texts) do
    table.insert(sortedTextsKeys, k)
  end
  table.sort(sortedTextsKeys)
  for k,v in ipairs(sortedTextsKeys) do print (k,v) end

  Gamestate.registerEvents()
  Gamestate.switch(state.driving)
  --Gamestate.push(state.reading)

  Signal.emit('game_started') -- TODO after main menu?
end


function love.draw()
  love.graphics.scale(scale)
end

function love.update(dt)
  Timer.update(dt)
end



-------------- driving
local lastgas = false

function state.driving:update(dt)
  local origspeed = speed
  local gas = love.keyboard.isDown("up") and fuel > 0
  if gas then
    speed = speed + dt*accel
    if not lastgas then Signal.emit('accel_start') end
  else
    if lastgas then Signal.emit('accel_end') end
  end
  lastgas = gas

  speed = speed - dt*friction -- FIXME ???
  speed = math.max(math.min(maxspeed, speed), 0)

  fuel = fuel - dt*speed*consumption

  distance = distance + speed * dt * 0.01

  img.fuel.quads.current = img.fuel.quads[math.floor(math.max(0,math.min(#img.fuel.quads-1,#img.fuel.quads*fuel)))]
  img.road.quads.current = img.road.quads[math.floor(distance*100) % #img.road.quads]
  img.car.quads.current = img.car.quads[math.floor(distance*10) % #img.car.quads]
  img.sign.quads.current = img.sign.quads[math.floor(distance*18) % #img.sign.quads]

  if fuel <= 0 then Signal.emit('out_of_fuel') end
  if origspeed == 0 and speed > 0 then Signal.emit('started') end
  if origspeed > 0 and speed == 0 then Signal.emit('stopped') end

end

function state.driving:draw()
  love.graphics.setColor(255,255,255)
  love.graphics.draw(img.bg1.img, 0, 0)
  love.graphics.draw(img.fuel.img, img.fuel.quads.current, 0, 0)
  love.graphics.draw(img.road.img, img.road.quads.current, 0, 0)
  love.graphics.draw(img.car.img, img.car.quads.current, 0, 0)
  love.graphics.draw(img.sign.img, img.sign.quads.current, 0, 0)
  --love.graphics.rectangle("fill",3,3,math.floor(speed),1)
  love.graphics.setColor(palette[1])
  love.graphics.print("E", 44, 1)
  love.graphics.print("F", 60, 1)

  if debug then
    love.graphics.printf(math.floor(speed), 0, 1, a, "center")
    love.graphics.print(math.floor(distance), 1, 1)
    love.graphics.print(math.floor(fuel*1000)/1000, 1, 8)
  end
end





-------------- reading
function state.reading:draw()
  love.graphics.setColor(palette[3])
  love.graphics.rectangle("fill", 0, 0, a, a)
  local textKey = sortedTextsKeys[1]
  for _,key in pairs(sortedTextsKeys) do if distance > key then textKey = key end end

  love.graphics.setColor(palette[1])
  love.graphics.print(texts[textKey], 1, 1)
end

function state.reading:keypressed(key)
  if key=='up' then Gamestate.pop() end
end



--------------

Signal.register('stopped', function()
  --Gamestate.push(state.reading)
end)




--- sfx

local sfxTimers = {}
local stopAllSfx = function()
  for _,v in pairs(sfx) do v:stop() end
  for _,v in pairs(sfxTimers) do Timer.cancel(v) end
  sfxTimers = {}
end

Signal.register('game_started', function()
  local delay = 1
  table.insert(sfxTimers, Timer.after(delay, function() sfx.start:play() end))
  table.insert(sfxTimers, Timer.after(delay + sfx.start:getDuration(), function() sfx.idle:play() end))
end)

Signal.register('accel_start', function()
  stopAllSfx()
  sfx.speedup:play()
  table.insert(sfxTimers, Timer.after(sfx.speedup:getDuration(), function() sfx.going:play() end))
end)

Signal.register('accel_end', function()
  if fuel > 0 then
    stopAllSfx()
    sfx.speeddown:play()
    table.insert(sfxTimers, Timer.after(sfx.speeddown:getDuration(), function() sfx.idle:play() end))
  end
end)

local stopPlayed = false
Signal.register('out_of_fuel', function()
  if not stopPlayed then
    stopAllSfx()
    sfx.stop:play()
    stopPlayed = true
  end
end)

Signal.register('stopped', function()
  if(fuel>0) then
    stopAllSfx()
    sfx.idle:play()
  end
end)



 -----controls

 function love.keypressed(key)
   if key=='d' then debug = not debug end
   if key=='escape' then love.event.quit() end
   if key=='+' or key=='kp+' then scale = scale + 1; scaleWindow() end
   if key=='-' or key=='kp-' then scale = scale - 1; scaleWindow() end
 end
 function love.textinput(text)
   if text=='+' then scale = scale + 1; scaleWindow() end
   if text=='-' then scale = scale - 1; scaleWindow() end
 end
