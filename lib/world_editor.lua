
function newButton(text, fn)
    return {
        text = text,
        fn = fn
    }
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
                    world_editor.load()
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
                if bn and mx ~= mouse_x and my ~= mouse_y then
                    mouse_x = mx
                    mouse_y = my
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
                if bn and mx ~= mouse_x and my ~= mouse_y then
                    mouse_x = mx
                    mouse_y = my
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
    self.wh = love.graphics.getHeight()
    self.ww = love.graphics.getWidth()

    self.world_map = {}
    for i=1, world_size do
        table.insert(self.world_map, {})
        for x=1, world_size do
            table.insert(self.world_map, 'w')
        end
    end
    self.selected_placement = "grass"
    self.square_size = self.wh/#self.world_map[1]
end

function world_editor:update()
    local tile_map = {
        water="w",
        grass="g",
        wall="b"
    }
    if love.mouse.isDown() then
        local x = love.mouse.getX()
        local y = love.mouse.getY()

        --find the tile to replace if the mouse is in the tile area
        if x <= self.square_size * #world_map[1] and y <= x <= self.square_size * #world_map[1] then
            local row = math.floor(x / self.square_size)
            local column = math.floor(y / self.square_size)
            world_map[row][column] = tile_map[self.selected_placement]
        end
        --change the block type if mouse is in the inventory area
    end
end

function world_editor:draw()
	--love.audio.play( self.d2 )

    --draw map

    love.graphics.setColor(1,1,1,1)
    local image_map = {
        w = images.water,
        g = images.grass,
        b = images.brick
    }
    for y,row in ipairs(self.world_map) do
        for x,col in ipairs(row) do
            love.graphics.draw(image_map[col],(x - 1) * self.square_size,(y - 1) * self.square_size,0,self.square_size/16,self.square_size/16)
        end
    end 
    
    
    --draw sidebar (should have the different tiles/items that can be placed)


    --draw items/enemies/player on map
end

return {world_editor=world_editor, world_editor_menu=world_editor_menu}