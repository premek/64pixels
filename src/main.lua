local Signal = require 'lib.hump.signal'
local Timer = require 'lib.hump.timer'
local Gamestate = require "lib.hump.gamestate"

local state = {
  mainmenu = {d=0, locked = nil},
  intro = {d=0, ends=nil, speed=30},
  driving = {d=0, locked = nil, lastgas = false},
  reading = {},
  outro = {},
}

local love = love
local debug = false

local music = {}
local img = {}
local sfx = {}

local a=64 -- pixels
local scale = 8

local fuel = 1
local speed = 0
local accel = 45
local friction = 37
local maxspeed = 80
local consumption = .0001
local distance = 0

local palette = {
{43,8,6},
{123,163,139},
{220,208,160},
{255,255,184},
{196,32,41},
}


local introText = "Drive away. To a different city. Or to the woods maybe. Listen to the radio. Watch the landscape. Stop sometimes to think and enjoy the countryside if you want to. Relax.          Hold up arrow key to accelerate"

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



-------------- load


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

  music[1] = love.audio.newSource( 'music/i think i get it.mp3', 'stream' )
  music[2] = love.audio.newSource( 'music/think of me think of us.mp3', 'stream' )
  music[1]:setVolume(0.8)
  music[2]:setVolume(0.8)

  for _,v in ipairs(love.filesystem.getDirectoryItems("sfx")) do
    local k = v:match("^(.+)%..+$")
    sfx[k] = love.audio.newSource("sfx/"..v, "static")
    sfx[k]:setVolume(0.8)
  end
  for _,v in ipairs({"idle", "going"}) do sfx[v]:setLooping(true) end
  sfx.radiofm:setVolume(1)
  sfx.cardooropenclose4:setVolume(1)

  for _,v in ipairs(love.filesystem.getDirectoryItems("img")) do
    local f = v:match("^(.+)%..+$")
    img[f] = {}
    img[f].img = love.graphics.newImage("img/"..f..".png")
    img[f].quads = getQuads(img[f].img)
    img[f].quads.current = img[f].quads[0]
  end

  love.graphics.setNewFont( "font/tom-thumb.bdf", 6 )

  for k in pairs(texts) do
    table.insert(sortedTextsKeys, k)
  end
  table.sort(sortedTextsKeys)

  Gamestate.registerEvents()
  Gamestate.switch(state.mainmenu)

  Signal.emit('game_started')
end


function love.draw()
  love.graphics.scale(scale)
end

function love.update(dt)
  Timer.update(dt)
end





-------------- driving
function state.driving:update(dt)
  local origspeed = speed

  if state.driving.d < state.driving.locked then
    state.driving.d = state.driving.d + dt
  else
    local gas = love.keyboard.isDown("up") and fuel > 0
    if gas then
      speed = speed + dt*accel
      if not state.driving.lastgas then Signal.emit('accel_start') end
    else
      if state.driving.lastgas then Signal.emit('accel_end') end
    end
    state.driving.lastgas = gas
  end

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


-------------- mainmenu
function state.mainmenu:update(dt)
  state.mainmenu.d = state.mainmenu.d + dt
end
function state.mainmenu:draw()
  love.graphics.setColor(palette[3])
  love.graphics.rectangle("fill", 0, 0, a, a)
  love.graphics.setColor(palette[1])
  love.graphics.printf("64 Pixels\nRoad Trip", 0, 10, a, "center")
  if state.mainmenu.d > state.mainmenu.locked then
    love.graphics.printf("Press any key\nto start", 0, 40, a, "center")
  end
  love.graphics.setColor({0,0,0,255-state.mainmenu.d*255})
  love.graphics.rectangle("fill", 0, 0, a, a)
end

function state.mainmenu:keypressed(key)
  if state.mainmenu.d > state.mainmenu.locked then
    Gamestate.switch(state.intro)
  end
end


------------- intro
function state.intro:enter()
  state.intro.ends = (introText:len()*4+a) / state.intro.speed
end
function state.intro:update(dt)
  state.intro.d = state.intro.d + dt
  print(state.intro.d, state.intro.ends)
  if state.intro.d > state.intro.ends then
    Gamestate.switch(state.driving)
    Signal.emit('driving_started')
  end
end

function state.intro:draw()
  love.graphics.setColor(255,255,255)
  love.graphics.draw(img.bg1.img, 0, 0)
  love.graphics.draw(img.road.img, img.road.quads.current, 0, 0)
  love.graphics.draw(img.car.img, img.car.quads.current, 0, 0)

  love.graphics.setColor(palette[1])
  love.graphics.print(introText, 64 - math.floor(state.intro.d*state.intro.speed), 9)
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
  local delay = .5
  Timer.after(delay, function() sfx.cardooropenclose4:play() end)
  delay = delay + sfx.cardooropenclose4:getDuration()
  Timer.after(delay, function() sfx.start:play() end)
  delay = delay + sfx.start:getDuration()
  Timer.after(delay, function() sfx.idle:play() end)
  state.mainmenu.locked = delay
end)

Signal.register('driving_started', function()
  sfx.radiofm:play()
  state.driving.locked = sfx.radiofm:getDuration()

  Timer.after(sfx.radiofm:getDuration(), function() music[1]:play() end)
  Timer.after(sfx.radiofm:getDuration() + music[1]:getDuration(), function() music[2]:play() end)
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
