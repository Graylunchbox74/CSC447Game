# CSC447Game  
Game for CSC 447  

**Overview**  
Simple grid game. Coded in Love2D Game Framework using Lua. The concept is for the player to find the key on the map. The player must take the key to the door to unlock it. The player wins the game when they get the flag.  

**Controls**  
Use arrow keys to move around the player. Move the player over items on the map to pick them up. Use the number keys to select what item you want. Use the space bar to use the item. For example, face the door with a key in hand and press space. This will open the door so you can get to the flag.  

**Map Features**  
 - Grass - normal speed to walk over  
 - Water - half speed to walk over  
 - Brick - Can't walk on  
 - Door(locked) - Can't walk on  
 - Door(unlocked) - Can get through  

**Items**  
 - Sword - used to kill enemy  
 - Key - used to unlock door  
 - Flag - win the game if collected  

**Enemy**  
While attempting to get to the flag, the player will also need to escape or battle the enemy. The enemy is a white circle character which will traverse towards the player. The goal of the player is to get to the flag before the enemy can kill them. If not possible, the player has the option to find a sword on the map. The player can press space while near the enemy to kill them.  