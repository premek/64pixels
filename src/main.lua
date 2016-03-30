local Signal = require 'lib.hump.signal'
local Gamestate = require "lib.hump.gamestate"

local driving = {}
local reading = {}

local love = love

local music
local img = {}

local a=64 -- pixels

local scale = 10

local fuel = 1
local speed = 0
local accel = 80
local friction = 60
local maxspeed = 80
local consumption = .001
local distance = 0


local texts = {
  [0] = "Press up arrow\nto start",
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
  "They are safer where they are now"

}
local sortedTextsKeys = {}

local getQuads = function(image, a)
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
  music:play()

  for _,f in ipairs({"bg1", "fuel", "road", "car"}) do
    img[f] = {}
    img[f].img = love.graphics.newImage("img/"..f..".png")
    img[f].quads = getQuads(img[f].img, a)
    --img[f].counter = 0
    img[f].quads.current = img[f].quads[0]
  end

  love.graphics.setNewFont( 7 )

  for k in pairs(texts) do
    table.insert(sortedTextsKeys, k)
  end
  table.sort(sortedTextsKeys)
  for k,v in ipairs(sortedTextsKeys) do print (k,v) end

  Gamestate.registerEvents()
  Gamestate.switch(driving)
  Gamestate.push(reading)

end


function love.draw()
  love.graphics.scale(scale)
end

--------------


function driving:update(dt)
  local origspeed = speed
  if love.keyboard.isDown("up") and fuel > 0 then
    speed = speed + dt*accel
  end
  speed = speed - dt*friction -- FIXME ???
  speed = math.max(math.min(maxspeed, speed), 0)

  fuel = fuel - dt*speed*consumption

  distance = distance + speed * dt * 0.01

  img.fuel.quads.current = img.fuel.quads[math.floor(math.max(0,math.min(#img.fuel.quads-1,#img.fuel.quads*fuel)))]

  img.road.quads.current = img.road.quads[math.floor(distance*100) % #img.road.quads]

  img.car.quads.current = img.car.quads[math.floor(distance*10) % #img.car.quads]

  if fuel <= 0 then Signal.emit('out_of_fuel') end
  if origspeed == 0 and speed > 0 then Signal.emit('started') end
  if origspeed > 0 and speed == 0 then Signal.emit('stopped') end

end

function driving:draw()
  love.graphics.setColor(255,255,255)
  love.graphics.draw(img.bg1.img, 0, 0)
  love.graphics.draw(img.fuel.img, img.fuel.quads.current, 0, 0)
  love.graphics.draw(img.road.img, img.road.quads.current, 0, 0)
  love.graphics.draw(img.car.img, img.car.quads.current, 0, 0)
  --love.graphics.rectangle("fill",3,3,math.floor(speed),1)
  love.graphics.setColor(34,32,52)
  love.graphics.printf(math.floor(speed), 0, 1, a, "center")
  love.graphics.print(math.floor(distance), 1, 1)

end



--------------
function reading:draw()
  love.graphics.setColor(255,255,255)
  love.graphics.rectangle("fill", 0, 0, a, a)
  local textKey = sortedTextsKeys[1]
  for _,key in pairs(sortedTextsKeys) do if distance > key then textKey = key end end

  love.graphics.setColor(34,32,52)
  love.graphics.print(texts[textKey], 1, 1)
end

function reading:keypressed(key)
  if key=='up' then Gamestate.pop() end
end

-----------

function love.keypressed(key)
  if key=='escape' then love.event.quit() end
  if key=='+' or key=='kp+' then scale = scale + 1; scaleWindow() end
  if key=='-' or key=='kp-' then scale = scale - 1; scaleWindow() end
end
function love.textinput(text)
  if text=='+' then scale = scale + 1; scaleWindow() end
  if text=='-' then scale = scale - 1; scaleWindow() end
end



--------------

Signal.register('stopped', function()
  Gamestate.push(reading)
end)
