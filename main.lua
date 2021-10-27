--2D game explained
--map is a 2 dimensional grid where each "turn" the player moves, each enemy gets to move too
--map will have standard ground, water (takes 2 "turns" to walk through 1 water instead of the standard 1 turn for normal ground), walls (cannot move through walls), doors (can be opened if unlocked with key)
--player starts with nothing in inventory
--player has 5 health
--n enemies spawn at start of level in predetermined locations
--enemies deal 1 damage on the player per attack and enemies are only melee (unless they have a bow and arrow)
--items in game have different actions
--  -sword: deals 1 damage to enemy (enemies have 2 health)
--  -potion: heals player to full health
--  -key: opens a door that corresponds to the key color
--  -bow and arrow: shoots arrow in 1 of 4 directions (up, down, left, right) arrow moves 2 spaces per turn and deals 2 damage
--      -enemies can also pick up or spawn with a bow and arrow
--if player steps on golden flag they win the level

----------------------------------------------------------------------------
------------------------requirements for enemy AI---------------------------
----------------------------------------------------------------------------
--1. AI should create a path from its current position to the player and use that path to move to the player
--2. An issue with AI in games is that they are highly predictable, implement some randomness into your AI so the player can't always determine the next move
--3. 




function newButton(text, fn)
    return {
        text = text,
        fn = fn
    }
end

main_menu = {}
local game_stack = {main_menu}

function main_menu:load()
    self.BUTTON_HEIGHT = 64
    self.buttons = {}
    font = love.graphics.newFont(32)
    table.insert(self.buttons, newButton("Start Game",
     function()
        game:load()
        table.insert(game_stack, game)
     end))

     table.insert(self.buttons, newButton("Map Editor",
     function()
        print("ello mate")
     end))
     
     table.insert(self.buttons, newButton("Exit",
     function()
        love.event.quit(0)
     end))     
end
function main_menu:draw()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()

    local button_width = ww * (1/3)
    local margin = 16

    local total_height = (self.BUTTON_HEIGHT + margin) * #self.buttons
    local cursor_y = 0

    for i, button in ipairs(self.buttons) do
        local bx = (ww * 0.5) - (button_width * 0.5)
        local by = (wh * 0.5) - (self.BUTTON_HEIGHT * 0.5) - (total_height * 0.5) + cursor_y

        local color = {0.4,0.4,0.5,1}

        --check mouse position--
        local mx, my = love.mouse.getPosition()

        if mx >= bx and my >= by and mx <= bx + button_width and my <= by + self.BUTTON_HEIGHT then
            color = {0.5,0.4,0.4,1}
            bn = love.mouse.isDown(1)
            if bn then
                button.fn()
            end
        end

        love.graphics.setColor(unpack(color))
        love.graphics.rectangle("fill",
         bx,
         by,
         button_width,
         self.BUTTON_HEIGHT
        )

        love.graphics.setColor(1,1,1,1)

        local textH = font:getHeight(button.text)
        local textW = font:getWidth(button.text)

        love.graphics.print(
            button.text,
            font,
            (ww * 0.5) - textW * 0.5,
            by + textH * 0.5
        )

        cursor_y = cursor_y + (self.BUTTON_HEIGHT + margin)

    end
end


game = {}
function game:load()
    self.ww = love.graphics.getWidth()
    self.wh = love.graphics.getHeight()

    --game_state is the map
    self.game_state = {}
    for line in love.filesystem.lines("level1.txt") do
        table.insert(self.game_state, {})
        for i=1, #line do
            table.insert(self.game_state[#self.game_state], line:sub(i,i))
        end
    end

    self.standard_enemy_image = love.graphics.newImage("assets/enemy_standard.png")
    self.standard_enemy_image:setFilter("nearest")
    self.player_image = love.graphics.newImage("assets/player.png")
    self.player_image:setFilter("nearest")

    self.water_image = love.graphics.newImage("assets/water.png")
    self.water_image:setFilter("nearest")
    self.grass_image = love.graphics.newImage("assets/grass.png")
    self.grass_image:setFilter("nearest")
    self.brick_image = love.graphics.newImage("assets/brick.png")
    self.brick_image:setFilter("nearest")
    self.arrow_image = love.graphics.newImage("assets/arrow.png")
    self.arrow_image:setFilter("nearest")
    self.bow_image   = love.graphics.newImage("assets/bow.png")
    self.bow_image:setFilter("nearest")
    self.flag_image  = love.graphics.newImage("assets/flag.png")
    self.flag_image:setFilter("nearest")
    self.key_image = love.graphics.newImage("assets/key.png")
    self.key_image:setFilter("nearest")
    self.potion_image = love.graphics.newImage("assets/potion.png")
    self.potion_image:setFilter("nearest")
    self.sword_image = love.graphics.newImage("assets/sword.png")
    self.sword_image:setFilter("nearest")
    self.oof = love.audio.newSource("assets/oof.mp3", "stream")
    self.d2 = love.audio.newSource("assets/D2BeyondLight.mp3", "stream")


    self.enemies = {
        {},
    }

    self.flag = {
        x = 6,
        y = 9
    }

    self.player_max_health = 10
    self.player = {
        x = 5,
        y = 5,
        items = {
            potions = 0,
            sword = 0,
            bow = 0,
            arrows = 0,
            keys = 0
        },
        health = self.player_max_health - 3
    }
end


function game:draw()
	love.audio.play( self.d2 )
    --draw map
    local curr_x = 0
    local curr_y = 0
    local square_size = self.wh/#self.game_state[1]
    for _,y in ipairs(self.game_state) do
        for _,x in ipairs(y) do
            local images = {
                w = self.water_image,
                g = self.grass_image,
                b = self.brick_image
            }
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(images[x],curr_x,curr_y,0,square_size/16,square_size/16)
            curr_x = curr_x + square_size
        end
        curr_x = 0
        curr_y = curr_y + square_size
    end

    --draw items on map

    --draw flag on map
    love.graphics.draw(self.flag_image,self.flag.x * square_size,self.flag.y * square_size,0,square_size/self.flag_image:getWidth(), square_size/self.flag_image:getHeight())

    love.graphics.setColor(1,1,1,1)
    --draw player / enemies
    for _,enemy in ipairs(self.enemies) do
        love.graphics.draw(self.standard_enemy_image,0,0,0,square_size/self.standard_enemy_image:getWidth(), square_size/self.standard_enemy_image:getHeight())
    end

    love.graphics.draw(self.player_image,self.player.x * square_size,self.player.y * square_size,0,square_size/self.player_image:getWidth(), square_size/self.player_image:getHeight())

    --draw inventory
    local inventory_height = 0.1 * self.wh
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill", 0, self.wh - inventory_height, self.ww, inventory_height)
    imgs = {
        self.potion_image,
        self.sword_image,
        self.bow_image,
        self.arrow_image,
        self.key_image
    }
    for i=1, 5 do
        love.graphics.setColor(0.4,0.4,0.4,1)
        love.graphics.rectangle("fill", (self.ww / 2 / 5) * (i-1) + 5, self.wh - inventory_height + 5,  (self.ww / 2 / 5) - 10, inventory_height - 10)
        --insert item that goes here if there is one
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(imgs[i], (self.ww / 2 / 5) * (i-1) + 5, self.wh - inventory_height + 5, 0, ((self.ww / 2 / 5) - 10) / 16, (inventory_height - 10) /16)
        


        love.graphics.print(tostring(i), (self.ww / 2 / 5) * (i-1) + 7, self.wh - inventory_height + 7)
    end

    --health bar
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Health:", self.ww / 2 + 10, self.wh - inventory_height + 10)
    love.graphics.setColor(1,0,0,1)
    love.graphics.rectangle("fill", self.ww / 2 + 10, self.wh - inventory_height + 30, self.ww / 2 - 20, inventory_height - 40)
    love.graphics.setColor(0,1,0,1)
    love.graphics.rectangle("fill", self.ww / 2 + 10, self.wh-inventory_height + 30, (self.ww / 2 - 20) * (self.player["health"]/self.player_max_health), inventory_height - 40)
end

function love.load()
    game_stack[#game_stack]:load()
end

function love.draw()
    game_stack[#game_stack]:draw()
end