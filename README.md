# Home_Made_Game-Sanziana_Covaliu
Project for the Game Development Classes

//Description///////////////////////
    A 2D pixelart surfer-platformer game about a space explorer character that has a miniship that they can board and travel sections of the map shooting down asteroids with it.

//Character/////////////////////////

    Human
        Basic character control + Dodge, sprint, double-jump
        The human character responds to gravity while the ship does not (hence the flight). 
    Ship
        The ship form is conditioned and timed by a fuel bar that can be filled via collecting an item named 'crystals' while in human form
            There is a condition for transforming = They have the fuel bar above or equal to 50%.
                When they run low on fuel there's a warining sigh (a red vignette that pops and where it gets to 0% they are forced back to human form)
            --to be determined if on buttonpress or item collection
        The spaceship can also shoot down obstacles while in the human form, the player cound not pass them. The bullets are infinite and activated by a simple button press.
    

//Environment//////////////////////
    Ground
        Has some plant enemies (they do not move)
        Has some collectibles
    Flight
        Can shoot down asteroids
        Can collect rare gems if combos the asteroid debries

//Internal comments///////////////
   {ViSUAL} is the tag for sprites and map updated
   {CODE} is the tag for any new logic within the architecture

//To do//////////////////////////
{CODE}
    Explore ways to create the character transformer
    [SCRAPPED]Trigger the transformation through collecting a specific item
        
    [DONE]Trigger the transformation through a keypress
        [FIXED]The ship_sprite is 4 sprites and needs a new 16x16 collision system
            []Exploration of a character transform using the same logic as the player collision check
               [1st TRY] Uses flr (floor) to round and snap to the grid the character
                    Gemma's explanation is 
                        So essentially, flr acts to instantly scrub away any unwanted decimal fractional values or overlaps caused by speed/gravity, forcibly "snapping" the character squarely on top of the map grid with absolute geometric precision!
   
    [ONGOING]Explore a 5 item charge ship_fuel 
    [ONGOING]Explore a 3 hit player_healthbar                     
    
    [EXPLORING]Explore ways to navigate the Y axis on the ship
        [ONGOING] Finite State Machine implementation
            Player_Human
                [DONE]CONTROLS
                    Arrow up    - Jump
                    Arrow down  - Crouch
                    Arrow left  - Run foward (to the left of the screen)
                    Arrow right - Run foward (to the right of the screen)
                    X - Interact with objects
                    C - Change to Ship
                []HEALTH BAR
                    3 hearts
                    _Healthbar variable
                []ITEMS SPAWN
                    Crystals
            Player_Ship
                [DONE]CONTROLS
                    Arrow up    - Fly up
                    Arrow down  - Fly Down
                    Arrow left  - Fly foward (to the left of the screen)
                    Arrow right - Fly foward (to the right of the screen)
                    X - Shoot down objects
                    C - Change to human
                []HEALTH BAR
                    5 crystals
                    _Fuel variable
                []ITEMS SPAWN
                    Asteroids


    []Explore ways to shoot down things
    []Explore ways to make the map procedually 
        Asteroid spawner with lifetime reverse counter
        Map spawner with predetermined islands
{ViSUAL}
    
    []PLAYER
        [x]player_run_anim (sprites 2, 3 ,4)
        [x]player_idle (sprites 0, 1 ,4)
        [x]player_jump (sprite 7)
        [x]player_hurt_anim (sprite 16)
        [x]player_death_anim (sprites 16, 17, 18, 19, 20, 21)
        [x]player_slide (sprite 6)
    []SHIP
        [x]ship_fly_anim (big sprites frame_1 = 36, 37, 52, 53, frame_2 = 38, 39, 54, 55)
        [x]xship_idle_anim (big sprites frame_1 = 32, 33, 48, 49, frame_2 = 34, 35, 50, 51)
        [x]ship_destruction_anim (sprites 40, 41, 42, 43)
    []INTERACTIONS_GROUND
        [x]The_Laser_bridge_anim (sprites 12, 13, 14)
            FLAGS = RED on all sprites now
        Laser_generator_no_anim (sprites 28, 29, 30)
            FLAGS = RED, GREEN
        [x]The_Generator_Lever_anim (sprites 63 = OFF, 47 = ON) --// then the player can play the animation with btnp(5) but without any logical input after the first time.
            FLAGS = GREEN
        [x]The_Laser_Controller_anim (sprites 31 = OFF, 15 = ON)
            FLAGS = GREEN
    []ASTEOIRDS
        [x]ship_shoot_anim (sprite 56)
        [x]ship_bullet_anim (sprite 22) --// the coursor, we need to implement this keybind too
        [x]asteroids (sprite 82, 83, 98, 99, 114, 115) --//No_anim_just_position transform
        [x]asteroid_death_anim (sprites 40, 41, 42, 43)
            FLAGS = RED, ORANGE, PINK, WHITE
    []ENEMY_PLANTS
        [x]enemy_anim_idle (sprite 77)
        [x]enemy_anim_shoot (sprites 68, 67, 66, 65)
        [x]enemy_bullet_anim (sprites 64, 80, 96, 112, 96, 80, 64,)
        [x]enemy_death_anim (sprites 40, 41, 42, 43)
            FLAGS = PINK, WHITE
    []CRYSTALS 
        [x]blue_crystals_idle_anim (sprites 24, 25,)
        [x]blue_crystals_pick-up_anim (sprites 26, 27,)
            FLAGS = BLUE
        [x]Green_crystal (sprite 22) --// collect them all for endgame
    []HEALTH
        [x] Full_heart (sprite 8)
        [x] Health_loss (sprites 9, 10 ,11)
    []INTERFACE
        []Death_screen (sprite 23)
        Main Menu
        []Play (sprite 81)
        []Retry (sprite 97)
        []Quit (sprite 113)
        []Endgame screen 
            is sprite 8 in the middle with 
            looped animations of (sprites 40, 41, 42, 43) that play from random locations on screen (besides the 8 tiles in the middle)
    []Terrain
    Sprites
        from 69 till 76 and 78,79
        from 85 till 92 and 94,95
        from 101 till 103 and 106 till 111
        from 117 till 127
            FLAGS = RED, ORANGE

    [] endgame screen is sprite 8 in the middle with 
        looped animations of (sprites 40, 41, 42, 43) that play from random locations on screen (besides the 8 tiles in the middle)
    

FLAGS MEANING
RED = Terrain Collider from above
ORANGE = Terrain collider from below
GREEN = Interactible logic (the laser_bridge_function)
BLUE = Collectible
PURPLE = bullet
PINK = Shootable
WHITE = Deals damage on collision


SFX.1 = Engine (on loop while player in ship form)
SFX.1 = Player jump
SFX.2 = Player Shoot (X)
SFX.3 = Ship Transform / Human Transform (c)
SFX.4 = Crystal Pick_up
SFX.5 = Asteroid Death
SFX.6 = Engine (on loop while player in ship form)

The engine Loop should be (SFX 00 plays on player input, the c key. After the SFX oo finnishes, that should trigger SFX 06, that should play and when it finnishes should play SFX.00 and so on while the player_is_ship FSM)

