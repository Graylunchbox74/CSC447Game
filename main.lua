----------------------------------------------------------------------------
------------------------Requirements for Enemy AI---------------------------
----------------------------------------------------------------------------
--1. AI should create a path from its current position to the player and use that path to move to the player
    --1a. Try to make the AI choose an efficient path, remember that water takes twice as long to walk through as grass
--2. An issue with AI in games is that they are highly predictable, implement some randomness into your AI so the player can't always determine the next move

last_mouse_down = false
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
    { "door",  "assets/door.png"  },

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

    self.entity_map = {}
    for line in love.filesystem.lines("level1.txt") do
        table.insert(self.entity_map, {})
        for i=1, #line do
            table.insert(self.entity_map[#self.entity_map], line:sub(i,i))
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

    self.enemies = {
        {},
    }

    self.flag = {
        x = 6,
        y = 9
    }

    self.projectiles = {}

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

    self.player.hotbar:add_item("potion", 2)
    self.player.hotbar:add_item("key", 2)
    self.player.bag:add_item("potion", 10)

    self.player.hotbar:add_item("bow", 1)
    self.player.hotbar:add_item("arrow", 5)
    self.player.bag:add_item("arrow", 5)
end

function can_walk_on(board, x, y)
    if x < 0 or y < 0 or x >= #board[1] or y >= #board then return false end
    local cell = board[y + 1][x + 1]
    
    if cell == "g" then return true, 1 end
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

function facing_block(board, x, y, dx, dy)
    if x + dx < 0 or y + dy < 0 or x + dx >= #board[1] or y + dy >= #board then return " " end
    return board[y + dy + 1][x + dx + 1]
end

function game:log(msg)
    if #self.sidebar_log > 17 then
        table.remove(self.sidebar_log, 1, 1)
    end

    table.insert(self.sidebar_log, msg)
end

function game:set_block(x, y, block)
    if x < 0 or y < 0 or x >= #self.game_state[1] or y >= #self.game_state then return end
    self.game_state[y + 1][x + 1] = block
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

            table.insert(self.projectiles, {
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
        local block = facing_block(self.game_state, player.target_x, player.target_y, player.last_dx, player.last_dy)
        if block == "d" and player.hotbar:remove_item("key", 1) then
            self:set_block(player.target_x + player.last_dx, player.target_y + player.last_dy, "g")
        end
    end
end

function game:update(dt)
    for _, proj in ipairs(self.projectiles) do
        proj.x = proj.x + proj.dx
        proj.y = proj.y + proj.dy

        if not can_pass_over(self.game_state, math.floor(proj.x + 0.5), math.floor(proj.y + 0.5)) then
            proj.dead = true
        end
    end

    for proj_idx, proj in ipairs(self.projectiles) do
        if proj.dead then
            table.remove(self.projectiles, proj_idx, 1)
        end
    end

    if self.player.current_action == "" and #self.player.queued_actions > 0 then
        local action = self.player.queued_actions[1]
        table.remove(self.player.queued_actions, 1, 1)

        if action[1] == "move" then
            local px = math.floor(self.player.x + 0.5)
            local py = math.floor(self.player.y + 0.5)

            local can_walk, speed = can_walk_on(self.game_state, px + action[2], py + action[3])
            self.player.last_dx = action[2]
            self.player.last_dy = action[3]
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

        if action[1] == "use_item" then
            local item_to_use = self.player.hotbar.items[action[2]]
            if item_to_use.name ~= nil then
                self:use_item(item_to_use, self.player, nil)

                self:log("Player used " .. item_to_use.name)
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

    if key == "space" then table.insert(self.player.queued_actions, { "use_item", self.player.selected_item }) end
end

function game:draw()
	--love.audio.play( self.d2 )

    --draw map
    local square_size = self.wh/#self.game_state[1]

    love.graphics.setColor(1,1,1,1)
    local image_map = {
        w = { images.water },
        g = { images.grass },
        b = { images.brick },
        d = { images.grass, images.door },
    }
    for y,row in ipairs(self.game_state) do
        for x,col in ipairs(row) do
            for _, img in ipairs(image_map[col]) do
                love.graphics.draw(img, (x - 1) * square_size,(y - 1) * square_size,0,square_size/16,square_size/16)
            end
        end
    end

    --draw items on map
    for _, proj in ipairs(self.projectiles) do
        love.graphics.draw(images[proj.img], proj.x * square_size, proj.y * square_size, 0, square_size/16, square_size/16)
    end

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
        love.graphics.rectangle("fill", ((i - 1) % 2) * (self.ww / 10) + 24 + 12 * square_size, 8 + yoff, (self.ww / 10) - 10, inventory_height - 10)
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
    table.insert(self.options, newButton("Load Level",
        function()
            self.options = {}
            self.load_level = true
            table.insert(self.options, newButton("Load",
            function()

            end))
            table.insert(self.options, newButton("Exit",
            function()
                love.event.quit()
            end))
            
        end
    ))
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

    self.d2 = love.audio.newSource("assets/D2BeyondLight.mp3", "static")

    self.tiles = {"w","b","g"}
    self.tile_names = {
        w="water",
        b="wall",
        g="grass"
    }

    self.entities = {"n", "p", "e", "b", "a", "f", "s"}
    self.entity_names = {
        n = "nothing",
        p = "player",
        e = "standard_enemy",
        b = "bow_item",
        a = "arrow_item",
        f = "flag",
        s = "sword_item",
        o = "potion_item"
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
        wall="b"
    }
    local entity_string_map = {
        nothing="n",
        player="p",
        standard_enemy="e",
        bow_item="b",
        arrow_item="a",
        flag="f",
        sword_item="s",
        potion_item="o"
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
        w = self.images.water,
        g = self.images.grass,
        b = self.images.brick
    }

    local entity_image_map = {
        b = self.images.bow_item,
        a = self.images.arrow_item,
        p = self.images.player,
        e = self.images.standard_enemy,
        s = self.images.sword_item,
        f = self.images.flag,
        o = self.images.potion_item
    }

    local starting_x = self.square_size * #self.world_map[1] + 5
    local starting_y = 15
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
        love.graphics.draw(image_map[tile], x, y, 0, block_size/16, block_size/16)
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
    end

    --draw map
    --draw items/enemies/player on map
    for y,row in ipairs(self.world_map) do
        for x,col in ipairs(row) do
            love.graphics.draw(image_map[col],(x - 1) * self.square_size,(y - 1) * self.square_size,0,self.square_size/16,self.square_size/16)
            if self.entity_map[y][x] ~= "n" then
                love.graphics.draw(entity_image_map[self.entity_map[y][x]], (x - 1) * self.square_size,(y - 1) * self.square_size,0,self.square_size/16,self.square_size/16)
            end
        end
    end 

    


end

