local math = require("math")
local os = require("os")

local event = require("event") -- our custom event handler
local EventObj = event:New()

-- randomize our math function
math.randomseed(os.time())

local fruits = {}
local fruitImages = nil

--io.stdout:setvbuf("no")
local pos = {x = 300, y = 490}
local arrow_image = nil
local move = {left = false, right = false}
local basket_speed = 400
local fruit_speed = 70
local points = 0

local spread_range = {X = {-200, 200}, Y = {-100, 100}}

local SCREEN_WIDTH = love.graphics.getWidth()
local SCREEN_HEIGHT = love.graphics.getHeight()


local FRUIT_SCALE = 0.13
local BASKET_SCALE = 0.2
local PAUSED = false

local LEVEL_COMPLETED = false

local game_coroutine = nil

-- the number of falling fruit remaining
local numOfFruit = math.huge

local basket_image = nil
local basket_size = { X = 0, Y = 0 }
local background_image = nil
local background_offset = {X = 0, Y = 0}
local lastSpawnTime = math.huge

local imageFileNames = nil


function table_find(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function create_fruit(amount, fruitImages, imageFileNames)
	local sprX = spread_range.X
	local sprY = spread_range.Y

	for i = 1, amount do
        local randomIndex = math.random(1, #imageFileNames)
        local chosenFilename = imageFileNames[randomIndex]

        local randomPos = {
            randX = math.random(50, 500) + math.random(sprX[1], sprX[2]),
            randY = math.random(5, 250) + math.random(sprY[1], sprY[2]),
        }

        local fruitObject = {
            Texture = fruitImages[chosenFilename], 
            Position = {X = randomPos.randX, Y = randomPos.randY},
			Size = {X = 0, Y = 0},
            IsMoving = true
        }

		-- calculate the size of the textures applied the given scale
		fruitObject.Size = {
			X = fruitObject.Texture:getWidth() * FRUIT_SCALE,
			Y = fruitObject.Texture:getHeight() * FRUIT_SCALE
		}

        table.insert(fruits, fruitObject)
    end
end

-- timer switches
local levelCompleteTimerStarted = false
local shouldShowArrows = false

local timers = {}

function register_timer(delay, callback, repeats, ...)
    table.insert(timers, {
        callback = callback,
        delayTime = delay,
        callback_args = {...},
        --_doesTimerRepeat = repeats,
        _delayTimer = 0
    })
end

function gameLevelLogic()
	-- lets start level 2
			-- numOfFruit = 10
			-- create_fruit(numOfFruit, fruitImages, imageFileNames)

			-- register_timer(3, function()

			-- 	numOfFruit = 10
			-- 	create_fruit(numOfFruit, fruitImages, imageFileNames)
				

			-- end)

			-- register_timer(3, function()

			-- 	numOfFruit = 10
			-- 	create_fruit(numOfFruit, fruitImages, imageFileNames)
				

			-- end)
	while true do
        print("Waiting for LevelCompleted event...")
        event.waitUntil(EventObj, "LevelCompleted")
        print("Event fired, coroutine resumed!")

		--levelCompleteTimerStarted = false


        numOfFruit = 10
        create_fruit(numOfFruit, fruitImages, imageFileNames)

        --levelCompleteTimerStarted = false
    end
end

function love.load()
	love.graphics.setBackgroundColor(200, 200, 200, 1)

	-- load our backgrond image
	background_image = love.graphics.newImage("assets/fruitgame_background.png")

	local scaleX = background_image:getWidth()
	local scaleY = background_image:getHeight()

	background_offset.scaleX = SCREEN_WIDTH / scaleX
	background_offset.scaleY = SCREEN_HEIGHT / scaleY

	-- load our arrow image (shared we just need to draw multiple times)
	arrow_image = love.graphics.newImage("assets/arrow.png")

	-- load our basket image
	basket_image = love.graphics.newImage("assets/basket.png")
	-- lets resize our basket and give update its applied scale
	basket_size.X = basket_image:getWidth() * BASKET_SCALE
	basket_size.Y = basket_image:getHeight() * BASKET_SCALE

	-- set our font
	myFont = love.graphics.newFont(24)
    love.graphics.setFont(myFont)

    -- table to store images by filename
    fruitImages = {}

    -- load all fruit images
    local imageFiles = love.filesystem.getDirectoryItems("assets/fruit_images")

    -- filter image files and load images
    imageFileNames = {}  -- to hold just the valid filenames
    for _, filename in ipairs(imageFiles) do
        if filename:match("%.png$") or filename:match("%.jpg$") or filename:match("%.jpeg$") then
            local path = "assets/fruit_images/" .. filename
            fruitImages[filename] = love.graphics.newImage(path)
            table.insert(imageFileNames, filename)  
        end
    end

    fruits = {}

    -- create 5 fruit objects
	numOfFruit = 5
    create_fruit(numOfFruit, fruitImages, imageFileNames)

	-- create the level listener
	EventObj:OnEvent("LevelCompleted", function()

		print("Level completed!")
		
	end)

	-- create our game logic coroutine
	game_coroutine = coroutine.create(gameLevelLogic)

	local ok, err = coroutine.resume(game_coroutine)
	if not ok then
		print("Error in coroutine:", err)
	end
end

function newLevelArrowEffect()

	-- since the time system is non yielding we need to offset the delay
	-- using the index
	local onDuration = 0.15        -- how long arrows stay on
	local offDuration = 0.17       -- how long arrows stay off
	local totalCycle = onDuration + offDuration

	for i = 0, 3 do
		local onDelay = i * totalCycle
		local offDelay = onDelay + onDuration

		register_timer(onDelay, function()
			--print("toggle on")
			shouldShowArrows = true
		end)

		register_timer(offDelay, function()
			--print("toggle off")
			shouldShowArrows = false
		end)
	end
end

function love.update(dt)
	if PAUSED then return end

	if numOfFruit == 0 and not levelCompleteTimerStarted then
		levelCompleteTimerStarted = true
		register_timer(3, function()
			print("Timer has completed!")

			newLevelArrowEffect()
			print("we have passed the effect")

			EventObj:Fire("LevelCompleted")
		end)
	end

	-- if we do it this way this supports multiple timers per callback
	for i = #timers, 1, -1 do
        local timer = timers[i]
        timer._delayTimer = timer._delayTimer + dt

        if timer._delayTimer >= timer.delayTime then
            timer.callback(unpack(timer.callback_args))

			-- removing repeat logic for now
            -- if timer._doesTimerRepeat == true then
            --     timer._delayTimer = 0
            -- else
            --     table.remove(timers, i)
            -- end
			table.remove(timers, i)
        end
    end

	if move.left then
		pos.x = pos.x - basket_speed * dt
	end
	
	if move.right then
		pos.x = pos.x + basket_speed * dt
	end

    for i, fruit_obj in ipairs(fruits) do
		if fruit_obj.IsMoving == true and fruit_obj.Position then
			fruit_obj.Position.Y = fruit_obj.Position.Y + fruit_speed * dt
		end
	end

	-- we want it to land in the basket not at the handle
	local adjustedY = (175 * BASKET_SCALE)

	-- collision logic
	-- we loop this way because table.remove() shifts the elements on remove
	for i = #fruits, 1, -1 do
		local fruit_obj = fruits[i]

		if checkCollision(pos.x, pos.y + adjustedY,
			basket_size.X, basket_size.Y - adjustedY,

			fruit_obj.Position.X, fruit_obj.Position.Y,
			fruit_obj.Size.X, fruit_obj.Size.Y
		) and fruit_obj.IsMoving == true then
			print("we caught a fruit!")
			points = points + 5
			numOfFruit = numOfFruit - 1
			table.remove(fruits, i)

		elseif fruit_obj.Position.Y > SCREEN_HEIGHT then

			print("missed a fruit!")
			numOfFruit = numOfFruit - 1
			table.remove(fruits, i)
		end
	end
end

function love.keypressed(key)
	if key == "left" then
		move.left = true
	elseif key == "right" then
		move.right = true
	elseif key == "escape" then
		love.event.quit()
	elseif key == "f1" then
		PAUSED = not PAUSED
	else
		--do nothing
	end
end

function love.keyreleased(key)
    if key == "left" then
		move.left = false
	elseif key == "right" then
		move.right = false
	else
		--do nothing
	end
end


function love.draw()

	-- -- load the background image
	-- love.graphics.draw(background_image, 0, 0)
	love.graphics.draw(background_image, 0, 0, 0,                             -- no rotation
    	background_offset.scaleX,
    	background_offset.scaleY
	)


	if PAUSED == true then
		-- create paused bg
		love.graphics.setColor(200, 200, 200, 1) -- red, semi-transparent
		love.graphics.rectangle("fill", (SCREEN_HEIGHT/2), (SCREEN_HEIGHT/2)-25, 200, 100-25)
		love.graphics.setColor(1, 1, 1, 1) -- reset color

		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.printf("PAUSED", 0, SCREEN_HEIGHT/2, SCREEN_WIDTH, "center")

		
		--return
	end

	
	love.graphics.setColor(0, 0, 0, 1)
	local points_str = string.format("Points: %d", points)
    love.graphics.printf(points_str, 0, 10, SCREEN_WIDTH, "left")
	love.graphics.setColor(1, 1, 1, 1) -- reset color
    -- render our basket
    --love.graphics.print("|____________|", pos.x, pos.y)
	love.graphics.draw(basket_image, pos.x, pos.y, 0, BASKET_SCALE, BASKET_SCALE)

	love.graphics.setColor(1, 0, 0, 0.3) -- red, semi-transparent
	love.graphics.rectangle("fill", pos.x, pos.y+35, basket_size.X, basket_size.Y-35)
	love.graphics.setColor(1, 1, 1, 1) -- reset color

	-- lets draw our arrows
	if shouldShowArrows == true then
		local tempPos = 125
		for i = 1, 4 do

			if tempPos == 2 then
				tempPos = tempPos + 400
			end

			love.graphics.draw(arrow_image, tempPos, 80, 0, 0.5, 0.5)
			tempPos = tempPos + 150

		end
	end


	for i, fruit_obj in ipairs(fruits) do
		
		local fruitPos = fruit_obj.Position
		local fruitSize = fruit_obj.Size
    	if fruit_obj.Texture and fruitPos and fruit_obj.IsMoving == true then

			love.graphics.setColor(1, 0, 0, 0.3) -- red, semi-transparent
			love.graphics.rectangle("fill", fruitPos.X, fruitPos.Y, fruitSize.X,fruitSize.Y)
			love.graphics.setColor(1, 1, 1, 1) -- reset color


    		love.graphics.draw(fruit_obj.Texture, fruitPos.X, fruitPos.Y, 0, FRUIT_SCALE, FRUIT_SCALE)
		end
	end
end