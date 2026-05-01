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
                [CONTROLS]
                    Arrow up    - Jump
                    Arrow down  - Crouch
                    Arrow left  - Run foward (to the left of the screen)
                    Arrow right - Run foward (to the right of the screen)
                    X - Interact with objects
                    C - Change to Ship
                [HEALTH BAR]
                    3 HEARTS
                    _Healthbar variable
                [ITEMS SPAWN]
                    Crystals
            Player_Ship
                [CONTROLS]
                    Arrow up    - Fly up
                    Arrow down  - Fly Down
                    Arrow left  - Fly foward (to the left of the screen)
                    Arrow right - Fly foward (to the right of the screen)
                    X - Shoot down objects
                    C - Change to human
                [HEALTH BAR]
                    5 HEARTS
                    _Fuel variable
                [ITEMS SPAWN]
                    Asteroids


    []Explore ways to shoot down things
    []Explore ways to make the map procedually 
        Asteroid spawner with lifetime reverse counter
        Map spawner with predetermined islands
{ViSUAL}
    
    []PLAYER
        []player_run_anim
        []player_hurt_anim
        []player_death_anim
        []player_crouch
    []SHIP
        []ship_fly_anim
        []ship_idle_anim
        [x]ship_destruction_anim
    []INTERACTIONS_GROUND
        [x]platform_anim
        [x]lever_anim
        [x]button_anim
    []ASTEOIRDS
        []bullet_anim
        []asteroid_idle
        [x]asteroid_death_anim
    []ENEMY_PLANTS
        [x]enemy_anim
        []enemy_shoot_anim
        [x]enemy_death_anim
    []CRYSTALS
        []crystals_idle_anim
        []crystals_pick-up_anim
