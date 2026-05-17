# Complete Project History

Here is the full record of all the phases we have completed so far!

---

# Phase 1: HUD & Resource Management Complete

We have officially implemented the foundation for the game's health and fuel mechanics!

## What was implemented:
*   **Core Variables:** The player now starts with `health = 5` and `fuel = 5` (out of a `max_fuel` of 10).
*   **The HUD:** Added a brand new `draw_hud()` function that renders statically to the screen (using a camera reset technique). It neatly displays your hearts (sprite 8) and your fuel crystals (sprite 24) at the top of the screen.
*   **Transformation Constraint:** In human form, pressing 'C' now checks if you have at least `2.5` fuel (25%). If you don't, the ship won't start!
*   **Fuel Consumption:** While flying the ship, your fuel slowly drains over time. 
*   **Low Fuel Warning:** When your fuel dips below `2.5`, the fuel bar on the HUD begins to flicker rapidly to warn you!
*   **Emergency Ejection:** If your fuel hits exactly `0` while flying, you are automatically and forcefully ejected back into human form.

---

# Phase 2: Collectibles (Crystals) Complete

You can now refuel your ship!

## What was implemented:
*   **Direct Map Collision:** Removed the old spawner script. The game now constantly scans the exact map tiles the player's bounding box is currently touching.
*   **The Blue Flag:** If any of the tiles the player touches has the **BLUE flag** (Flag 4), the game registers it as a crystal pickup!
*   **The Constraint:** You can walk right through crystals if your fuel is `10/10`. They will only trigger if you need fuel!
*   **Collection:** When you grab one, it plays a sound effect (`sfx(0)`), deletes the crystal directly from the map (`mset`), and adds `+1` to your fuel bar!

---

# Phase 3: Ship Combat Complete

Pew pew! The ship is now armed and dangerous!

## What was implemented:
*   **SFX Mapping:** Added all the proper sound effects! `sfx(1)` for jumping, `sfx(2)`/`sfx(3)` for transforming, and a persistent engine loop `sfx(6)` while in the ship!
*   **Shooting:** By pressing **X** (`btnp(5)`), the ship now spawns a purple energy bullet (`sprite 22`) that travels infinitely in the direction the ship is facing.
*   **Ship Animation:** When you shoot, the ship briefly swaps to its firing sprite (`sprite 56`) for 15 frames!
*   **Bullet Lifecycle:** Bullets have a `life` of 45 frames (1.5 seconds) so they don't clog up the memory forever if they miss.

---

# Phase 4: Asteroids Complete

You now have targets to shoot at!

## What was implemented:
*   **Asteroid Spawner:** While flying the ship, the game randomly spawns asteroids just off-screen (to the right). They pick randomly from your asteroid sprite list (`82, 83, 98, 99, 114, 115`) and drift slowly to the left with slight vertical variation.
*   **Combat:** If your bullets touch an asteroid, both the bullet and the asteroid are destroyed! The asteroid will play `sfx(5)` and play its explosive destruction animation (`sprites 40-43`).
*   **Player Damage:** If you fail to shoot an asteroid and it crashes into your ship, it will explode, play the sound, and deduct **1 Health** from your health bar!

---

# Phase 6: The Laser Bridge Mechanics Complete

The laser bridge is now fully dynamic and animated, exactly as requested!

## What was implemented:
*   **Emitter Scanning:** When the game boots, it automatically finds any Laser Emitters (sprites 28, 29, 30) you placed on the map.
*   **Manual Cleanup:** Just in case you left any manual laser pieces (sprites 12, 13, 14) drawn on the map, the game instantly hides them on boot so they don't interfere with the physics engine.
*   **Distance Calculation:** Every emitter shoots a ray out across the gap until it hits a solid wall, logging exactly how many tiles need to be bridged. It resolves overlaps automatically if two emitters face each other!
*   **The Bridge Animation (`update_lasers`):**
    *   The first **2 tiles** immediately in front of any emitter are drawn using a perfectly stable, safe laser (sprite 12).
    *   Any tile extending further than 2 blocks outward becomes part of the **pulsating middle gap**.
    *   The pulsating tiles run a temporal animation cycle (`12 -> 13 -> 14 -> empty -> 14 -> 13`) giving a beautiful flashing effect!
*   **Dynamic Physics (`fset`):** The game forcefully edits the collision flags of the sprites in code: `12` and `13` are perfectly walkable, while `14` and `empty` are physically disabled! This means if the player is standing on the bridge when it flashes to the empty state, they will plummet through!

---

# Phase 7: UI & End Screens Complete

The state machine is fully operational! The game now gracefully handles win and loss conditions.

## What was implemented:
*   **The State Machine:** The game engine has been wrapped in a global `game_state` (`"play"`, `"dead"`, `"win"`). All physics and interactions freeze perfectly when a game over triggers.
*   **Green Gems (Win Condition):** The game scans your map on boot and counts exactly how many Green Gems (sprite 22) exist. When you collect them all, it triggers the Win State!
*   **The Death Screen:** If your health hits 0, it draws sprite 23 directly in the center `(60, 60)`. It then spawns an infinite shower of particles that animate through the health-loss sprites (8, 9, 10, 11). The spawner uses mathematical geometry bounds to absolutely guarantee NO particles ever spawn in the center 3x3 tile exclusion zone around your death sprite!
*   **The Win Screen:** It uses the exact same geometry exclusion logic as the Death Screen, but draws the full heart (sprite 8) in the center, surrounded by particles animating through the ship destruction sprites (40, 41, 42, 43).
*   **Restart Logic:** Simply press **X** on either end screen to instantly wipe the state and start a fresh run from `_init()`!

---

# Phase 8: Enemy Plants Complete

The static plant tiles have been upgraded into active threats with their own AI!

## What was implemented:
*   **Dynamic Conversion:** When the game starts, any Plant sprite (`77`) found on the map is instantly converted into a dynamic entity and erased from the static map.
*   **Proximity AI:** The plants will sit completely idle. But if the player steps within a 10-tile radius, they instantly shift into their attack state! If the player steps out of the radius, they stop attacking.
*   **Animation & Spawning:** Once aggroed, they begin cycling their shooting animation (`68 -> 67 -> 66 -> 65`). EXACTLY when the animation hits frame `66`, an enemy bullet spawns.
*   **Homing Bullets:** The enemy bullets constantly re-evaluate the player's position, chasing them horizontally and vertically! The bullets animate backward in a cycle as requested (`112 -> 96 -> 80 -> 64`).
*   **Dynamic Damage Immunity:**
    *   **Ship Form:** Totally immune! If a bullet hits the ship, the bullet explodes safely (`40..43`). The ship can also shoot its own bullets to destroy the plants (which triggers the same explosion)!
    *   **Human Form:** Vulnerable! If the human touches a plant body or gets hit by a homing bullet, they lose 1 health and trigger a brand new Hurt Animation (sprite `16`). 
*   **New Dying State:** Instead of instantly teleporting to the Death Screen when health hits 0, the game enters a `"dying"` state. The player drops to the ground and animates through the death sequence (`16 -> 17 -> 18 -> 19 -> 20 -> 21`) before the Death Screen finally appears!

---

# Phase 9: Health UI & Drops Complete

The game's health, HUD, and item collection systems have received a major glow-up!

## What was implemented:
*   **10 Hearts UI:** The maximum health was doubled from 5 to 10!
*   **Animated HUD State Machine:** The static health bar is now a fully animated UI!
    *   **Health Loss:** Taking damage triggers a specific heart to enter a `"losing"` state. It visually animates through the destruction sprites (`9 -> 10 -> 11`) on the HUD before finally settling on empty!
    *   **Health Gain:** Picking up a Green Crystal triggers the exact opposite. A missing heart will enter a `"gaining"` state, animating backwards (`11 -> 10 -> 9`) until it solidifies back into a full heart (`8`).
*   **Green Crystal Drops:** If you shoot down an Enemy Plant, it will dynamically drop a physical Green Crystal entity into the world! Collecting it increases your health by 1, and won't be collected if you are already at max health (10). 
*   **Collection Particle Effects:** Whenever you pick up *any* crystal (Blue Fuel on the map, Green Health on the map, or Green Health dropped from enemies), the game now spawns a temporary particle effect at that specific coordinate that flashes sprites `26, 27` to visually confirm the pickup!

---

# Phase 10: Fuel UI Complete

The game's fuel bar has been upgraded to use the same dynamic animation system as the health bar!

## What was implemented:
*   **Animated HUD State Machine:** The static fuel bar is now fully animated!
    *   **Fuel Loss:** When the ship naturally consumes a full unit of fuel, the corresponding fuel crystal on the HUD cycles through sprites `26 -> 27` before disappearing.
    *   **Fuel Gain:** Picking up a Blue Crystal triggers a missing fuel spot on the HUD to animate backwards `27 -> 26` until it solidifies back into a full crystal (`24`).
*   **Persistent Low Fuel Warning:** The flashing red warning sequence automatically restricts itself to only the *remaining* solid crystals when fuel drops below 2.5!
