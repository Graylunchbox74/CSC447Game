----------------------------------------------------------------------------
------------------------Requirements for Enemy AI---------------------------
----------------------------------------------------------------------------
--1. AI should create a path from its current position to the player and use that path to move to the player
    --1a. Try to make the AI choose an efficient path, remember that water takes twice as long to walk through as grass
--2. An issue with AI in games is that they are highly predictable, implement some randomness into your AI so the player can't always determine the next move
--3. The goal of the enemy is to kill the player before the player can reach the flag




--Extra Credit Opportunity

--We will use this game for future classes and just built it in the past two weeks on our free time, so its not very good
--
--1. Bug finding, find a bug in the game and submit it as an issue on Github (there are plenty of bugs)
--2. Make the code look readable, we didn't put much time into the code being efficient, readable or reliable, make some fixes and submit on github as a pull request
--  a. even commenting the code works for this (although reading our code might be gross)
--3. Make some additions to the game, be creative and make the game cool (only rule is that enemies must be able to be fully controlled by the enemy.lua file)

----------------------------------------------------------------------------------
------------------------Ideas for additions to the game---------------------------
----------------------------------------------------------------------------------
--1. More items
--2. Respawning Enemies
--3. Different types of enemies
--4. Different tiles that have unique properties
--the possibilities are endless






local enemy_action = require "enemy"

last_mouse_down = false
function newButton(text, fn)
    return {
        text = text,
        fn = fn
    }
end

local game_stack = {}
function game_stack:push(item, ...)
    if item.load then item:load(...) end
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
        game_stack:push(world_editor_menu)
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
            if not bn and last_mouse_down then
                button.fn()
            end
            last_mouse_down = bn
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

                return true
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
    { "door",  "assets/door2.png"  },
    { "flag",  "assets/flag.png"  },

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

    self.sidebar_log = {}

    self.entities = {}
	self:add_enemy(1, 1)

    self.player = {
        x = 5,
        y = 5,

        start_x  = 5,
        start_y  = 5,
        target_x = 5,
        target_y = 5,

        last_dx = 1,
        last_dy = 0,

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

    self:add_item(4, 5, "key")
    self:add_item(4, 6, "sword")
end

function game:load_level(level_name)
end

function can_walk_on(board, x, y)
    if x < 0 or y < 0 or x >= #board[1] or y >= #board then return false end
    local cell = board[y + 1][x + 1]
    
    if cell == "g" then return true, 1 end
    if cell == "f" then return true, 1 end
    if cell == "w" then return true, 0.5 end
    
    return false, 0
end

function can_pass_over(board, x, y)
    if x < 0 or y < 0 or x >= #board[1] or y >= #board then return false end
    local cell = board[y + 1][x + 1]
    
    if cell == "b" then return false end
    if cell == "d" then return false end
    
    return true
end

function game:log(msg)
    if #self.sidebar_log > 17 then
        table.remove(self.sidebar_log, 1, 1)
    end

    table.insert(self.sidebar_log, msg)
end

function game:add_enemy(x, y)
    local enemy = {
        kind = "enemy",
        x = x, y = y,
        start_x = x, start_y = y,
        target_x = x, target_y = y,

        current_action     = "",
        action_timer       = 0,
        action_timer_delta = 1,
    }

    table.insert(self.entities, enemy)
end

function game:add_item(x, y, item_name)
    local item = {
        kind = "item",
        x = x, y = y,
        item_name = item_name,
    }

    table.insert(self.entities, item)
end

function game:set_block(x, y, block)
    if x < 0 or y < 0 or x >= #self.game_state[1] or y >= #self.game_state then return end
    self.game_state[y + 1][x + 1] = block
end

function game:get_block(x, y)
    if x < 0 or y < 0 or x >= #self.game_state[1] or y >= #self.game_state then return " " end
    return self.game_state[y + 1][x + 1]
end

function game:get_entity_at(x, y, kind)
    for _, ent in ipairs(self.entities) do
        if math.floor(ent.x + 0.5) == x and math.floor(ent.y + 0.5) == y then
            if kind ~= nil then
                if ent.kind == kind then
                    return ent
                end
            else
                return ent
            end
        end
    end

    return nil
end

function game:use_item(item, player, enemy)
    -- EITHER player OR enemy is set depending on if it was an enemy or player using the item
    if player == nil then return end

    if item.name == "bow" then
        if player.hotbar:remove_item("arrow", 1) or player.bag:remove_item("arrow", 1) then
            local dx = 0
            local dy = 0
            if player.last_dx > 0 then dx = 0.2 end
            if player.last_dy > 0 then dy = 0.2 end
            if player.last_dx < 0 then dx = -0.2 end
            if player.last_dy < 0 then dy = -0.2 end

            table.insert(self.entities, {
                kind = "arrow",
                img  = "arrow_item",
                x  = player.start_x + player.last_dx,
                y  = player.start_y + player.last_dy,
                dx = dx,
                dy = dy
            })
        end
    end

    if item.name == "potion" then
        player.hotbar:remove_item("potion", 1)
        player.health = math.min(player.max_health, player.health + .2 * player.max_health)
    end

    if item.name == "key" then
        local block = self:get_block(player.target_x + player.last_dx, player.target_y + player.last_dy)
        if block == "d" and player.hotbar:remove_item("key", 1) then
            self:set_block(player.target_x + player.last_dx, player.target_y + player.last_dy, "g")
        end
    end

    if item.name == "sword" then
        local tx = player.x + player.last_dx
        local ty = player.y + player.last_dy
        local target = self:get_entity_at(tx, ty)

        if target ~= nil then
            if target.kind == "enemy" then
                love.audio.play(self.oof)
            end
            target.dead = true
        end
    end
end

function game:check_move_action(ent, action)
    if action[1] ~= "move" then return end

    local px = math.floor(ent.x + 0.5)
    local py = math.floor(ent.y + 0.5)

    local dx = math.min(1, math.max(-1, action[2]))
    local dy = math.min(1, math.max(-1, action[3]))
    local can_walk, speed = can_walk_on(self.game_state, px + dx, py + dy)
    ent.last_dx = dx
    ent.last_dy = dy
    if can_walk then
        ent.start_x  = px
        ent.start_y  = py
        ent.target_x = px + dx
        ent.target_y = py + dy
        ent.current_action = action[1]

        ent.action_timer = 0
        ent.action_timer_delta = 3 * speed
    end
end

function game:update_entity(dt, ent)
    ent.action_timer = ent.action_timer + dt * ent.action_timer_delta
    if ent.action_timer > 1 then
        ent.action_timer = 0
        ent.action_timer_delta = 0
        ent.current_action = ""

        ent.x = ent.target_x
        ent.y = ent.target_y
    end

    if ent.current_action == "move" then
        local t = ent.action_timer
        ent.x = t * ent.target_x + (1 - t) * ent.start_x
        ent.y = t * ent.target_y + (1 - t) * ent.start_y
    end
end

function game:update(dt)
    for _, ent in ipairs(self.entities) do
        if ent.kind == "arrow" then
            ent.x = ent.x + ent.dx
            ent.y = ent.y + ent.dy

            if not can_pass_over(self.game_state, math.floor(ent.x + 0.5), math.floor(ent.y + 0.5)) then
                ent.dead = true
            end

            local target = self:get_entity_at(math.floor(ent.x + 0.5), math.floor(ent.y + 0.5), "enemy")
            if target ~= nil then
                love.audio.play(self.oof)
                target.dead = true
                ent.dead = true
            end
        end

        if ent.kind == "enemy" then
            if ent.current_action == "" then
                local action = enemy_action(ent, self.player, self.game_state, self.entities)

                if action[1] == "move" then
                    self:check_move_action(ent, action)
                end
            end

            self:update_entity(dt, ent)
        end
    end

    for ent_idx, ent in ipairs(self.entities) do
        if ent.dead then
            table.remove(self.entities, ent_idx, 1)
        end
    end

    if self.player.current_action == "" and #self.player.queued_actions > 0 then
        local action = self.player.queued_actions[1]
        table.remove(self.player.queued_actions, 1, 1)

        if action[1] == "move" then
            self:check_move_action(self.player, action)
        end

        if action[1] == "use_item" then
            local item_to_use = self.player.hotbar.items[action[2]]
            if item_to_use.name ~= nil then
                self:use_item(item_to_use, self.player, nil)

                self:log("Player used " .. item_to_use.name)
            end
        end
    end

    self:update_entity(dt, self.player)

    if self.player.action_timer == 0 then
        local block = self:get_block(self.player.x, self.player.y)
        if block == "f" then
            self:win()
        end

        local item = self:get_entity_at(self.player.x, self.player.y, "item")
        if item ~= nil then
            item.dead = true
            self.player.hotbar:add_item(item.item_name, 1)
        end
    end
end

function game:win()
    game_stack:push(level_end_menu, self, "You Won!")
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

    if key == "space" then table.insert(self.player.queued_actions, { "use_item", self.player.selected_item }) end
end

function game:draw()
	-- love.audio.play( self.d2 )

    -- Draw map
    local square_size = self.wh/#self.game_state[1]

    love.graphics.setColor(1,1,1,1)
    local image_map = {
        w = { images.water },
        g = { images.grass },
        b = { images.brick },
        d = { images.grass, images.door },
        f = { images.grass, images.flag },
    }
    for y,row in ipairs(self.game_state) do
        for x,col in ipairs(row) do
            for _, img in ipairs(image_map[col]) do
                love.graphics.draw(img, (x - 1) * square_size,(y - 1) * square_size,0,square_size/16,square_size/16)
            end
        end
    end

    local item_imgs = {
        potion  = images.potion_item,
        sword   = images.sword_item,
        bow     = images.bow_item,
        arrow   = images.arrow_item,
        key     = images.key_item,
    }

    -- Draw items on map
    love.graphics.setColor(1,1,1,1)
    for _, ent in ipairs(self.entities) do
        if ent.kind == "arrow" then
            love.graphics.draw(images[ent.img], ent.x * square_size, ent.y * square_size, 0, square_size/16, square_size/16)
        end

        if ent.kind == "enemy" then
            love.graphics.draw(images.standard_enemy, ent.x * square_size, ent.y * square_size, 0, square_size/16, square_size/16)
        end

        if ent.kind == "item" then
            love.graphics.draw(item_imgs[ent.item_name], ent.x * square_size, ent.y * square_size, 0, square_size/16, square_size/16)
        end
    end

    love.graphics.draw(images.player,self.player.x * square_size,self.player.y * square_size,0,square_size/16, square_size/16)

    -- Draw hotbar
    local inventory_height = 0.1 * self.wh
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill", 0, self.wh - inventory_height, self.ww, inventory_height)
    local function drawItem(item, x, y, w, h)
        w = w or ((self.ww / 13) - 10)
        h = h or (inventory_height - 10)
        if item.name ~= nil then
            love.graphics.draw(item_imgs[item.name], x, y, 0, w/16, h/16)

            --insert item that goes here if there is one
            love.graphics.print(tostring(item.count), x - 4, y)
        end
    end

    for i=0,self.player.hotbar.capacity - 1 do
        local x = i * (self.ww / 10) + 5
        local y = self.wh - inventory_height + 5
        local w = (self.ww / 10) - 10
        local h = inventory_height - 10

        if self.player.selected_item - 1 == i then
            love.graphics.setColor(0.7,0.7,0.7,1)
        else
            local mx, my = love.mouse.getPosition()
            if x <= mx and y <= my and x + w >= mx and y + h >= my then
                love.graphics.setColor(0.6,0.6,0.6,1)
            else
                love.graphics.setColor(0.4,0.4,0.4,1)
            end
        end

        love.graphics.rectangle("fill", x, y, w, h)
    end

    love.graphics.setColor(1,1,1,1)
    for i, item in ipairs(self.player.hotbar.items) do
        drawItem(item, (i - 1) * (self.ww / 10) + 15, self.wh - inventory_height + 5)
    end

    -- Health bar
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Health:", self.ww / 2 + 10, self.wh - inventory_height + 10)
    love.graphics.setColor(1,0,0,1)
    love.graphics.rectangle("fill", self.ww / 2 + 10, self.wh - inventory_height + 30, self.ww / 2 - 20, inventory_height - 40)
    love.graphics.setColor(0,1,0,1)
    love.graphics.rectangle("fill", self.ww / 2 + 10, self.wh-inventory_height + 30, (self.ww / 2 - 20) * (self.player["health"]/self.player.max_health), inventory_height - 40)

    -- Side bar
    local yoff = 0
    for i=1,self.player.bag.capacity do
        local x = ((i - 1) % 2) * (self.ww / 10) + 24 + 12 * square_size
        local y = 8 + yoff
        local w = (self.ww / 10) - 10
        local h = inventory_height - 10

        local mx, my = love.mouse.getPosition()
        if x <= mx and y <= my and x + w >= mx and y + h >= my then
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
        else
            love.graphics.setColor(0.4, 0.4, 0.4, 1)
        end

        love.graphics.rectangle("fill", x, y, w, h)

        if i % 2 == 0 then yoff = yoff + inventory_height end
    end

    yoff = 0
    love.graphics.setColor(1,1,1,1)
    for i, item in ipairs(self.player.bag.items) do
        drawItem(item, ((i - 1) % 2) * (self.ww / 10) + 34 + 12 * square_size, 12 + yoff, (self.ww / 10) - 36, inventory_height - 20)
        if i % 2 == 0 then yoff = yoff + inventory_height end
    end
    
    yoff = yoff + 8
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", 12 * square_size, yoff, self.ww - 12 * square_size, self.wh - yoff - inventory_height)

    love.graphics.setColor(1, 1, 1, 1)
    for _, msg in ipairs(self.sidebar_log) do
        love.graphics.print(msg, 12 * square_size + 8, yoff, 0)
        yoff = yoff + 16
    end
end

level_end_menu = {}
function level_end_menu:load(game, msg)
    self.game = game
    self.msg = msg
end

function level_end_menu:update(dt)
end

function level_end_menu:keypressed(key)
    if key == "space" then
        game_stack:pop()
        game_stack:pop()
    end
end

function level_end_menu:draw()
    self.game:draw()

    local wh = love.graphics.getHeight()
    local ww = love.graphics.getWidth()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, ww, wh)

    local old_font = love.graphics.getFont()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.msg, 0, 200, ww / 2, "center", 0, 2, 2)
    love.graphics.setFont(old_font)

    love.graphics.printf("Press SPACE to return to the main menu", 0, 300, ww, "center")
end

world_editor_menu = {}
function world_editor_menu:load()
    self.BUTTON_HEIGHT = 64
    self.world_size = 16
    self.load_game_file = ""
    self.level_name = ""

    self.wh = love.graphics.getHeight()
    self.ww = love.graphics.getWidth()
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",0,0,self.ww, self.wh)

    self.load_level = false
    self.new_level = false
    self.options = {}
    table.insert(self.options, newButton("New Level",
        function()
            self.new_level = true
            self.options = {}
            table.insert(self.options, newButton("Create Level",
                function()
                    game_stack:push(world_editor)
                    -- world_editor.load()
                    -- table.insert(game_stack, world_editor)
                    
                end
            ))
            table.insert(self.options, newButton("Exit",
                function()
                    love.event.quit()
                end
            ))
        end
    ))
    table.insert(self.options, newButton("Exit",
        function()
            love.event.quit()
        end
    ))
end

function world_editor_menu:update()
    return
end




function world_editor_menu:draw()
    local mouse_x = 0
    local mouse_y = 0
    if self.new_level == false and self.load_level == false then
        local button_width = self.ww * (1/3)
        local margin = 16
    
        local total_height = (self.BUTTON_HEIGHT + margin) * #self.options
        local cursor_y = 0
    
        for i, button in ipairs(self.options) do
            local bx = (self.ww * 0.5) - (button_width * 0.5)
            local by = (self.wh * 0.5) - (self.BUTTON_HEIGHT * 0.5) - (total_height * 0.5) + cursor_y
    
            local color = {0.4,0.4,0.5,1}
    
            --check mouse position--
            local mx, my = love.mouse.getPosition()

            if mx >= bx and my >= by and mx <= bx + button_width and my <= by + self.BUTTON_HEIGHT then
                color = {0.5,0.4,0.4,1}
                bn = love.mouse.isDown(1)
                if not bn and last_mouse_down and mx ~= mouse_x and my ~= mouse_y then
                    mouse_x = mx
                    mouse_y = my
                    button.fn()
                end
            end
            last_mouse_down = bn

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
                (self.ww * 0.5) - textW * 0.5,
                by + textH * 0.5
            )
    
            cursor_y = cursor_y + (self.BUTTON_HEIGHT + margin)
    
        end   
    end
    if self.new_level == true then
        local labels = {
            self.world_size,
            self.level_name
        }
        local button_width = self.ww * (1/3)
        local margin = 16
    
        local total_height = (self.BUTTON_HEIGHT + margin) * #self.options
        local cursor_y = 0        
        for _,label in ipairs(labels) do
        end
    
        for i, button in ipairs(self.options) do
            local bx = (self.ww * 0.5) - (button_width * 0.5)
            local by = (self.wh * 0.5) - (self.BUTTON_HEIGHT * 0.5) - (total_height * 0.5) + cursor_y
    
            local color = {0.4,0.4,0.5,1}
    
            --check mouse position--
            local mx, my = love.mouse.getPosition()

            if mx >= bx and my >= by and mx <= bx + button_width and my <= by + self.BUTTON_HEIGHT then
                color = {0.5,0.4,0.4,1}
                bn = love.mouse.isDown(1)
                if not bn and last_mouse_down and mx ~= mouse_x and my ~= mouse_y then
                    mouse_x = mx
                    mouse_y = my
                    button.fn()
                end
                last_mouse_down = bn
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
                (self.ww * 0.5) - textW * 0.5,
                by + textH * 0.5
            )
    
            cursor_y = cursor_y + (self.BUTTON_HEIGHT + margin)
        end
            
    end
    if self.load_level == true then
    end
end



world_editor = {}
function world_editor:load(world_size)
    world_size = world_size or 16
    self.wh = love.graphics.getHeight()
    self.ww = love.graphics.getWidth()

    self.world_map = {}
    for i=1, world_size do
        table.insert(self.world_map, {})
        for x=1, world_size do
            table.insert(self.world_map[i], 'w')
        end
    end

    self.entity_map = {}
    for i=1, world_size do
        table.insert(self.entity_map, {})
        for x=1, world_size do
            table.insert(self.entity_map[i], 'n')
        end
    end

    self.selected_placement = "grass"
    self.placement_type = "tile"
    self.square_size = self.wh/#self.world_map[1]
    self.images = {}
    for _, to_load in ipairs(Images_To_Load) do
        local img = love.graphics.newImage(to_load[2])
        img:setFilter("nearest")

        self.images[to_load[1]] = img 
    end

    self.tiles = {"w","b","g","d","f"}
    self.tile_names = {
        w="water",
        b="wall",
        g="grass",
        d="door",
        f="flag",
    }

    self.entities = {"n", "p", "e", "b", "a", "s","k"}
    self.entity_names = {
        n = "nothing",
        p = "player",
        e = "standard_enemy",
        b = "bow_item",
        a = "arrow_item",
        s = "sword_item",
        o = "potion_item",
        k = "key_item",
    }
    self.entity_limits = {
        p = 1,
        f = 1,
        s = 1
    }
end

function world_editor:update()
    local tile_map = {
        water="w",
        grass="g",
        wall="b",
        door="d",
        flag="f",
    }
    local entity_string_map = {
        nothing="n",
        player="p",
        standard_enemy="e",
        bow_item="b",
        arrow_item="a",
        sword_item="s",
        potion_item="o",
        key_item="k",
    }
    if love.mouse.isDown(1) then
        local x = love.mouse.getX()
        local y = love.mouse.getY()
        --find the tile to replace if the mouse is in the tile area
        if x <= self.square_size * #self.world_map[1] and y <= self.square_size * #self.world_map[1] and x > 0 and y > 0 then
            local row = math.ceil(x / self.square_size)
            local column = math.ceil(y / self.square_size)
            if self.placement_type == "tile" then
                if self.world_map[column][row] ~= tile_map[self.selected_placement] then

                    self.world_map[column][row] = tile_map[self.selected_placement]
                end
            elseif self.placement_type == "entity" then
                if self.entity_map[column][row] ~= entity_string_map[self.selected_placement] then
                    if  self.entity_limits[entity_string_map[self.selected_placement]] ~= nil and self.entity_limits[entity_string_map[self.selected_placement]] > 0 then
                        self.entity_map[column][row] = entity_string_map[self.selected_placement]
                        self.entity_limits[entity_string_map[self.selected_placement]] = self.entity_limits[entity_string_map[self.selected_placement]] - 1
                    elseif self.entity_limits[entity_string_map[self.selected_placement]] == nil then
                        if self.entity_limits[self.entity_map[column][row]] ~= nil then
                            self.entity_limits[self.entity_map[column][row]] = self.entity_limits[self.entity_map[column][row]] + 1
                        end
                        self.entity_map[column][row] = entity_string_map[self.selected_placement]
                    end
                end
            end
        end
        --change the block type if mouse is in the inventory area
    end
end

function world_editor:draw()
    love.graphics.setColor(1,1,1,1)

    local image_map = {
        w = { self.images.water                    },
        g = { self.images.grass                    },
        b = { self.images.brick                    },
        d = { self.images.door,  self.images.grass },
        f = { self.images.flag,  self.images.grass },
    }

    local entity_image_map = {
        b = self.images.bow_item,
        a = self.images.arrow_item,
        p = self.images.player,
        e = self.images.standard_enemy,
        s = self.images.sword_item,
        o = self.images.potion_item,
        k = self.images.key_item
    }

    local starting_x = self.square_size * #self.world_map[1] + 5
    local starting_y = 15
    local ending_y = start_y
    --draw sidebar (should have the different tiles/items that can be placed)
    local block_size = 16
    for i,tile in ipairs(self.tiles) do
        local x = starting_x
        local y = (starting_y + block_size * (i-1)) + (15 * (i - 1))

        local hover_x = starting_x - 5
        local hover_y = y - 7.5
        local max_hover_y = hover_y + block_size + 15 
        local mouse_x = love.mouse.getX()
        local mouse_y = love.mouse.getY()
        if ( mouse_x > hover_x and mouse_x < self.ww and mouse_y > hover_y and mouse_y < max_hover_y ) or (self.selected_placement == self.tile_names[tile] and self.placement_type == "tile") then
            love.graphics.setColor(0.5,0.5,0.5,0.25)
            love.graphics.rectangle("fill", hover_x, hover_y, self.ww - hover_x, max_hover_y - hover_y)
            love.graphics.setColor(1,1,1,1)
            if love.mouse.isDown(1) then
                self.selected_placement = self.tile_names[tile]
                self.placement_type = "tile"
            end
        end


        local block_end = (starting_y + block_size * (i))
        love.graphics.draw(image_map[tile][1], x, y, 0, block_size/16, block_size/16)
        love.graphics.print(self.tile_names[tile], x + block_size + 5, y + block_size/3)
    end

    for i, entity in ipairs(self.entities) do
        local x = starting_x
        local y = (starting_y + block_size * (i-1)) + (15 * (i - 1)) + ((starting_y + block_size * (#self.tiles-1)) + (15 * (#self.tiles - 1)) + 35)

        local hover_x = starting_x - 5
        local hover_y = y - 7.5
        local max_hover_y = hover_y + block_size + 15 
        local mouse_x = love.mouse.getX()
        local mouse_y = love.mouse.getY()
        if ( mouse_x > hover_x and mouse_x < self.ww and mouse_y > hover_y and mouse_y < max_hover_y ) or (self.selected_placement == self.entity_names[entity] and self.placement_type == "entity" ) then
            love.graphics.setColor(0.5,0.5,0.5,0.25)
            love.graphics.rectangle("fill", hover_x, hover_y, self.ww - hover_x, max_hover_y - hover_y)
            love.graphics.setColor(1,1,1,1)
            if love.mouse.isDown(1) then
                self.selected_placement = self.entity_names[entity]
                self.placement_type = "entity"
            end
        end


        local block_end = (starting_y + block_size * (i))
        if entity ~= "n" then
            love.graphics.draw(entity_image_map[entity], x, y, 0, block_size/16, block_size/16)
        end
        love.graphics.print(self.entity_names[entity], x + block_size + 5, y + block_size/3)
        ending_y = max_hover_y
    end

    --draw map
    --draw items/enemies/player on map
    for y,row in ipairs(self.world_map) do
        for x,col in ipairs(row) do
            for i=#image_map[col],1,-1 do
                love.graphics.draw(image_map[col][i],(x - 1) * self.square_size,(y - 1) * self.square_size,0,self.square_size/16,self.square_size/16)
            end

            if self.entity_map[y][x] ~= "n" then
                love.graphics.draw(entity_image_map[self.entity_map[y][x]], (x - 1) * self.square_size,(y - 1) * self.square_size,0,self.square_size/16,self.square_size/16)
            end
        end
    end 


    --draw save and exit options
    --save option
    local curr_y = ending_y
    love.graphics.setColor(0.25,0.25,0.25,1)
    love.graphics.rectangle("fill", starting_x, ending_y, self.ww - starting_x, 20)
    love.graphics.setColor(1,1,1,1)
    curr_y = curr_y + 20
    love.graphics.print("Save", starting_x, curr_y + 15)
    mx = love.mouse.getX()
    my = love.mouse.getY()
    if mx >= starting_x and mx <= self.ww and my <= curr_y + 23.5 and my >= curr_y + 10 then
        bn = love.mouse.isDown(1)
        love.graphics.setColor(0.5,0.5,0.5,0.5)
        love.graphics.rectangle("fill", starting_x, curr_y + 10, self.ww - starting_x, 23.5)
        if not bn and last_mouse_down then
            --create string to print
            world_map_string = ""
            for y,row in ipairs(self.world_map) do
                for x,col in ipairs(row) do
                    world_map_string = world_map_string .. self.world_map[y][x]
                end
                world_map_string = world_map_string .. "\r\n"
            end
            
            world_map_string = world_map_string .. "\r\n"

            for y,row in ipairs(self.entity_map) do
                for x,col in ipairs(row) do
                    world_map_string = world_map_string .. self.entity_map[y][x]
                end
                world_map_string = world_map_string .. "\r\n"                
            end
            local file = io.open("./custom_level.txt", "wb")
            file:write(world_map_string)
            file:close()
            -- local success, message =love.filesystem.write("./custom_level.txt", world_map_string)

        end
        last_mouse_down = bn
    end

    curr_y = curr_y + 30
    love.graphics.print("Exit", starting_x, curr_y + 15)
    if mx >= starting_x and mx <= self.ww and my <= curr_y + 23.5 and my >= curr_y + 10 then
        bn = love.mouse.isDown(1)
        love.graphics.setColor(0.5,0.5,0.5,0.5)
        love.graphics.rectangle("fill", starting_x, curr_y + 10, self.ww - starting_x, 23.5)
        if not bn and last_mouse_down then
            game_stack:pop()
            game_stack:pop()
            game_stack:pop()
            game_stack:push(main_menu)
        end
        last_mouse_down = bn
    end    
    -- bn = love.mouse.isDown(1)
    -- mx = love.mouse.getX()
    -- my = love.mouse.getY()
    -- if not bn and last_mouse_down and mx >= starting_x and mx <= self.ww and my <= curr_y + 23.5 and my >= curr_y then
    -- end

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
