local math = require("math")
local os = require("os")

-- randomize our math function
math.randomseed(os.time())

local fruits = {}

--io.stdout:setvbuf("no")
local pos = {x = 300, y = 500}
local move = {left = false, right = false}
local basket_speed = 250
local fruit_speed = 100
local points = 0

local SCREEN_WIDTH = love.graphics.getWidth()
local SCREEN_HEIGHT = love.graphics.getHeight()


local FRUIT_SCALE = 0.13
local BASKET_SCALE = 0.2
local PAUSED = false

local basket_image = nil
local basket_size = { X = 0, Y = 0 }
local lastSpawnTime = math.huge

function love.conf(t)
	t.console = true
end

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

function love.load()
	love.graphics.setBackgroundColor(200, 200, 200, 1)

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
    local imageFileNames = {}  -- to hold just the valid filenames
    for _, filename in ipairs(imageFiles) do
        if filename:match("%.png$") or filename:match("%.jpg$") or filename:match("%.jpeg$") then
            local path = "assets/fruit_images/" .. filename
            fruitImages[filename] = love.graphics.newImage(path)
            table.insert(imageFileNames, filename)  
        end
    end

    fruits = {}

    -- create 5 fruit objects
    for i = 1, 5 do
        local randomIndex = math.random(1, #imageFileNames)
        local chosenFilename = imageFileNames[randomIndex]

        local randomPos = {
            randX = math.random(50, 500),
            randY = math.random(50, 250),
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

function love.update(dt)
	if PAUSED then return end
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
			table.remove(fruits, i)

		elseif fruit_obj.Position.Y > SCREEN_HEIGHT then

			print("missed a fruit!")
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

local renderlist = {}

function love.draw()

	if PAUSED == true then
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.printf("PAUSED", 0, SCREEN_HEIGHT/2, SCREEN_WIDTH, "center")
		love.graphics.setColor(1, 1, 1, 1) -- reset color
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