

-- This function can return:
--  { "none" }
--  { "move", change_in_x, change_in_y }
--
function enemy_action(self, player, world, entities)
  return { "none" }
end

return enemy_action
