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

local game_stack = {}
function game_stack:push(item)
    if item.load then item:load() end
    table.insert(self, item)
end

function game_stack:pop()
    if self[#self].unload then self[#self]:unload() end
    table.remove(self, #self, 1)
end

main_menu = {}
function main_menu:load()
    self.BUTTON_HEIGHT = 64
    self.buttons = {}
    font = love.graphics.newFont(32)
    table.insert(self.buttons, newButton("Start Game",
     function()
         game_stack:push(game)
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

-- Inventory
Inventory = {}

function Inventory:new(capacity)
    local items = {}
    for i=1,capacity do table.insert(items, {}) end

    local o = {
        capacity = capacity,
        items = items
    }
    setmetatable(o, { __index = Inventory })
    return o
end

function Inventory:add_item(item_name, count)
    local existing = nil
    for k, v in ipairs(self.items) do
        if v.name == item_name then
            existing = v
            break
        end
    end

    if existing then
        existing.count = existing.count + count
    else
        for k, v in ipairs(self.items) do
            if v.name == nil then
                self.items[k] = {
                    name = item_name,
                    count = count,
                }

                break
            end
        end
        
        return false
    end

    return true
end

function Inventory:remove_item(item_name, count)
    local existing = nil
    local existing_idx = 0

    for k, v in ipairs(self.items) do
        if v.name == item_name then
            existing = v
            existing_idx = k
            break
        end
    end

    if existing then
        if existing.count >= count then
            existing.count = existing.count - count

            if existing.count == 0 then
                self.items[existing_idx] = {}
            end

            return true
        end
    end

    return false
end

Images_To_Load = {
    { "standard_enemy", "assets/enemy_standard.png" },
    { "player", "assets/player.png" },

    { "water", "assets/water.png" },
    { "grass", "assets/grass.png" },
    { "brick", "assets/brick.png" },

    { "flag",        "assets/flag.png" },
    { "arrow_item",  "assets/arrow.png" },
    { "sword_item",  "assets/sword.png" },
    { "bow_item",    "assets/bow.png" },
    { "key_item",    "assets/key.png" },
    { "potion_item", "assets/potion.png" },
    
}
images = {}

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

    -- Load Images
    for _, to_load in ipairs(Images_To_Load) do
        local img = love.graphics.newImage(to_load[2])
        img:setFilter("nearest")

        images[to_load[1]] = img 
    end

    self.oof = love.audio.newSource("assets/oof.mp3", "stream")
    self.d2 = love.audio.newSource("assets/D2BeyondLight.mp3", "stream")


    self.enemies = {
        {},
    }

    self.flag = {
        x = 6,
        y = 9
    }

    self.player = {
        x = 5,
        y = 5,

        start_x  = 5,
        start_y  = 5,
        target_x = 5,
        target_y = 5,

        hotbar = Inventory:new(5),
        selected_item = 1,

        bag = Inventory:new(8),

        health     = 7,
        max_health = 10,

        current_action     = "",
        action_timer       = 0,
        action_timer_delta = 1,

        queued_actions = {},
    }

    self.player.hotbar:add_item("potion", 2)
    self.player.hotbar:add_item("key", 2)
    self.player.hotbar:remove_item("potion", 2)
    self.player.bag:add_item("potion", 10)
end

function can_walk_on(board, x, y)
    local cell = board[y + 1][x + 1]
    
    if cell == "g" then return true, 1 end
    if cell == "w" then return true, 0.5 end
    
    return false, 0
end


function game:update(dt)
    if self.player.current_action == "" and #self.player.queued_actions > 0 then
        local action = self.player.queued_actions[1]
        table.remove(self.player.queued_actions, 1, 1)

        if action[1] == "move" then
            local px = math.floor(self.player.x + 0.5)
            local py = math.floor(self.player.y + 0.5)

            local can_walk, speed = can_walk_on(self.game_state, px + action[2], py + action[3])
            if can_walk then
                self.player.start_x  = px
                self.player.start_y  = py
                self.player.target_x = px + action[2]
                self.player.target_y = py + action[3]
                self.player.current_action = action[1]

                self.player.action_timer = 0
                self.player.action_timer_delta = 3 * speed
            end
        end
    end

    self.player.action_timer = self.player.action_timer + dt * self.player.action_timer_delta
    if self.player.action_timer > 1 then
        self.player.action_timer = 0
        self.player.current_action = ""

        self.player.x = self.player.target_x
        self.player.y = self.player.target_y
    end

    if self.player.current_action == "move" then
        local t = self.player.action_timer
        self.player.x = t * self.player.target_x + (1 - t) * self.player.start_x
        self.player.y = t * self.player.target_y + (1 - t) * self.player.start_y
    end
end

function game:keypressed(key, scancode, isrepeat)
    -- This is liable to break things in the future, but for now, I only care about the first time a key is pressed.
    if isrepeat then return end

    if key == "left"  then table.insert(self.player.queued_actions, { "move", -1,  0 }) end
    if key == "right" then table.insert(self.player.queued_actions, { "move",  1,  0 }) end
    if key == "up"    then table.insert(self.player.queued_actions, { "move",  0, -1 }) end
    if key == "down"  then table.insert(self.player.queued_actions, { "move",  0,  1 }) end

    if key == "1" then self.player.selected_item = 1 end
    if key == "2" then self.player.selected_item = 2 end
    if key == "3" then self.player.selected_item = 3 end
    if key == "4" then self.player.selected_item = 4 end
    if key == "5" then self.player.selected_item = 5 end
end

function game:draw()
	--love.audio.play( self.d2 )

    --draw map
    local square_size = self.wh/#self.game_state[1]

    love.graphics.setColor(1,1,1,1)
    local image_map = {
        w = images.water,
        g = images.grass,
        b = images.brick
    }
    for y,row in ipairs(self.game_state) do
        for x,col in ipairs(row) do
            love.graphics.draw(image_map[col],(x - 1) * square_size,(y - 1) * square_size,0,square_size/16,square_size/16)
        end
    end

    --draw items on map

    --draw flag on map
    love.graphics.draw(images.flag,self.flag.x * square_size,self.flag.y * square_size,0,square_size/16, square_size/16)

    love.graphics.setColor(1,1,1,1)
    --draw player / enemies
    for _,enemy in ipairs(self.enemies) do
        love.graphics.draw(images.standard_enemy,0,0,0,square_size/16, square_size/16)
    end

    love.graphics.draw(images.player,self.player.x * square_size,self.player.y * square_size,0,square_size/16, square_size/16)

    --draw inventory
    local inventory_height = 0.1 * self.wh
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill", 0, self.wh - inventory_height, self.ww, inventory_height)
    local item_imgs = {
        potion  = images.potion_item,
        sword   = images.sword_item,
        bow     = images.bow_item,
        arrow   = images.arrow_item,
        key     = images.key_item,
    }

    local function drawItem(item, x, y)
        if item.name ~= nil then
            love.graphics.draw(item_imgs[item.name],
                x, y,
                0,
                ((self.ww / 13) - 10) / 16, (inventory_height - 10) / 16)

            --insert item that goes here if there is one
            love.graphics.print(tostring(item.count), x - 4, y)
        end
    end

    for i=0,self.player.hotbar.capacity - 1 do
        if self.player.selected_item - 1 == i then
            love.graphics.setColor(0.7,0.7,0.7,1)
        else
            love.graphics.setColor(0.4,0.4,0.4,1)
        end
        love.graphics.rectangle("fill", i * (self.ww / 10) + 5, self.wh - inventory_height + 5, (self.ww / 10) - 10, inventory_height - 10)
    end

    love.graphics.setColor(1,1,1,1)
    for i, item in ipairs(self.player.hotbar.items) do
        drawItem(item, (i - 1) * (self.ww / 10) + 15, self.wh - inventory_height + 5)
    end

    --health bar
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Health:", self.ww / 2 + 10, self.wh - inventory_height + 10)
    love.graphics.setColor(1,0,0,1)
    love.graphics.rectangle("fill", self.ww / 2 + 10, self.wh - inventory_height + 30, self.ww / 2 - 20, inventory_height - 40)
    love.graphics.setColor(0,1,0,1)
    love.graphics.rectangle("fill", self.ww / 2 + 10, self.wh-inventory_height + 30, (self.ww / 2 - 20) * (self.player["health"]/self.player.max_health), inventory_height - 40)

    --side bar
    local yoff = 0
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    for i=1,self.player.bag.capacity do
        love.graphics.rectangle("fill", ((i - 1) % 2) * (self.ww / 10) + 15 + 12 * square_size, 12 + yoff, (self.ww / 10) - 10, inventory_height - 10)
        if i % 2 == 0 then yoff = yoff + self.ww / 11 end
    end

    yoff = 0
    love.graphics.setColor(1,1,1,1)
    for i, item in ipairs(self.player.bag.items) do
        drawItem(item, ((i - 1) % 2) * (self.ww / 10) + 25 + 12 * square_size, 12 + yoff)
        if i % 2 == 0 then yoff = yoff + self.ww / 11 end
    end
end

function love.load()
    game_stack:push(main_menu)
end

function love.update(dt)
    if love.keyboard.isDown "escape" then
        love.event.quit()
    end

    if game_stack[#game_stack].update then
        game_stack[#game_stack]:update(dt)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if game_stack[#game_stack].keypressed then
        game_stack[#game_stack]:keypressed(key, scancode, isrepeat)
    end
end

function love.draw()
    game_stack[#game_stack]:draw()
end
