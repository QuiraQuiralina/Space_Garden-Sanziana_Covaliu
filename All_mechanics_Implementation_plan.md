# 🌌 Space Garden - All Mechanics & Implementation Plans

Welcome to the comprehensive implementation chronicle for **Space Garden**. This document compiles all of our architectural designs, active implementation plans, and completed phase histories in a cohesive chronological timeline.

> [!NOTE]
>
> ### 📜 Essential Rules of the Workspace
>
> - **The `README.md` is the ground truth for structural ideas.** It must **never** be edited.
> - **All new features and changes are proposed and detailed in this document first.**
> - **Code modifications to `space_garden.p8` are only performed AFTER an implementation plan is accepted by the user.**
> - When a prompt is given, we always check both the `README.md` and this plan file for steps and insights.

---

## 📅 Chronological Development Roadmap

Below is the structured, sequential history of our game's development and planning, presented in the exact chronological order of the implementation plans:

- **[PLAN I] Finite State Machine (FSM) for Player Movement** ➔ _Movement logic refactoring, multi-directional flight controls, and state routing._
- **[PLAN II] Health & Animations Integration** ➔ _System expansion, 10-hearts layout, and particle drop behaviors._
- **[LOG III] Historical Completion Log (Phases 1 to 14)** ➔ _The fully realized features powering the current space_garden.p8 codebase._

---

# 🚀 [PLAN I] Finite State Machine for Player Movement

This plan outlines the refactoring of the player's movement logic in `space_garden.p8` into a Finite State Machine (FSM). This will cleanly separate the human and ship states, enabling independent logic (like true multi-directional flying for the ship without gravity interference) while keeping the existing collision functions (`_collide_map` and `ship_collider`) completely untouched.

## 👥 User Review Required

> [!IMPORTANT]
> The `README.md` specifies different controls than what is currently implemented. Specifically:
>
> - **Jump** will change from `X` (button 5) to `Arrow Up` (button 2).
> - **Crouch** will be mapped to `Arrow Down` (button 3).
> - The current controlled ascent/descent mechanic using Up/Down arrows will be replaced by the raw Jump (Up arrow) and full flight controls for the ship.
>
> Please confirm if you are okay with changing the jump button from X to Up Arrow to match the README.

## 🛠️ Proposed Changes

### 1. State Initialization

We will update the `_init()` function to replace `player.is_ship = false` with a string-based state representation: `player.state = "human"`. We will also add any necessary variables like `crouching`.

### 2. The FSM Router

We will modify the main `player_update()` function to simply route the logic to the appropriate state function:

```lua
function player_update()
  if player.state == "human" then
    update_human()
  elseif player.state == "ship" then
    update_ship()
  end

  -- map limits applied universally
  local current_w = (player.state == "ship") and 16 or player.w
  player.x = mid(map_start, player.x, map_end - current_w)
end
```

### 3. State: Player_Human (`update_human`)

This function will contain all gravity, friction, and collision logic specific to the human.

- **Physics:** Apply gravity to `dy` and friction to `dx`.
- **Controls:**
  - `btn(0)` (Left) / `btn(1)` (Right): Run forward.
  - `btn(2)` (Up): Jump (replaces the old jump logic).
  - `btn(3)` (Down): Crouch.
  - `btnp(4)` (C): Change to Ship (Sets `player.state = "ship"` and applies the `y -= 8` offset).
  - `btnp(5)` (X): Interact (Placeholder for future feature).
- **Collision:** Uses only `_collide_map`.

### 4. State: Player_Ship (`update_ship`)

This function will handle multi-directional zero-gravity movement.

- **Physics:** Remove gravity. Apply friction to **both** `dx` and `dy` so the ship drifts smoothly to a halt when no buttons are pressed.
- **Controls:**
  - `btn(0)` (Left) / `btn(1)` (Right): Fly horizontally.
  - `btn(2)` (Up) / `btn(3)` (Down): Fly vertically.
  - `btnp(4)` (C): Change to Human (Sets `player.state = "human"`).
  - `btnp(5)` (X): Shoot (Placeholder for future feature).
- **Collision:** Uses only `ship_collider`.

### 5. Animation Update

We will quickly patch `player_animate()` and `_draw()` to use `player.state == "ship"` instead of the old `player.is_ship` boolean, ensuring the visuals remain exactly as they were.

## 🧪 Verification Plan

### Automated/Code Checks

- Verify `ship_collider` and `_collide_map` are not modified.
- Verify the code parses correctly in PICO-8 format.

### Manual Verification

1.  Load the game. The player should start in human form, falling under gravity.
2.  Press Up arrow to jump. Verify collisions work correctly (snapping to the ground).
3.  Press 'C' to transform into the ship.
4.  Use all four arrow keys to fly around freely. Verify that the ship doesn't get stuck on one axis and hovers correctly when keys are released.
5.  Press 'C' to turn back into a human. Verify gravity kicks back in.

---

# 💚 [PLAN II] Health & Animations Integration

## 🛠️ Proposed Changes

### 1. Health Increase & Green Crystal Logic

- Update `_init()`: Set `player.health = 10` and `player.max_health = 10`.
- Update `_init()`: Make sure the HUD draws 10 hearts properly without overlapping. We may need to wrap them to a second row or space them tighter if 10 doesn't fit on one line!
- Update Green Crystal collision (sprite 22): When collected, it will increase `player.health` by 1 (capped at `player.max_health`) in addition to incrementing the win condition counter.

### 2. Animations Integration

We have a few specific sprite sequences to implement based on your request and the README:

- **Crystal Collection (`26, 27`)**: When a blue crystal (fuel) or green crystal (health) is touched, instead of instantly disappearing `mset(x, y, 0)`, we can spawn a temporary "particle/effect" object at that location that quickly plays sprites `26 -> 27` and then deletes itself.
- **Health Loss (`9, 10, 11`)**: When the player takes damage (loses a heart), we can spawn an effect at the player's location that animates through `9 -> 10 -> 11` floating upwards.

## ❓ Open Questions

Before I start coding, I need clarification on exactly how you envision these animations:

1. **"Fuel drop (same as crystal collection)"**: Do you mean that asteroids/enemies should have a random chance to _drop_ a fuel crystal when they die? Or did you just mean that the animation for picking up fuel is the same as the crystal collection animation?
2. **"Health drop"**: Does this mean enemies should randomly drop health items (green crystals) when they die? Or do you mean the `Health_loss (9, 10, 11)` animation should play when the player gets hurt?
3. **HUD Layout**: 10 hearts (sprite 8) side-by-side will take up 90 pixels (out of the 128 pixel screen). This is quite long! Do you want them all in one row at the top left, or should they wrap to a second row (e.g., 5 hearts on top, 5 hearts below)?

---

# 📜 [LOG III] Historical Completion Log (Phases 1-14)

Here is the full record of all the phases we have completed so far!

---

### 🟢 Phase 1: HUD & Resource Management Complete

We have officially implemented the foundation for the game's health and fuel mechanics!

#### What was implemented:

- **Core Variables:** The player now starts with `health = 5` and `fuel = 5` (out of a `max_fuel` of 10).
- **The HUD:** Added a brand new `draw_hud()` function that renders statically to the screen (using a camera reset technique). It neatly displays your hearts (sprite 8) and your fuel crystals (sprite 24) at the top of the screen.
- **Transformation Constraint:** In human form, pressing 'C' now checks if you have at least `2.5` fuel (25%). If you don't, the ship won't start!
- **Fuel Consumption:** While flying the ship, your fuel slowly drains over time.
- **Low Fuel Warning:** When your fuel dips below `2.5`, the fuel bar on the HUD begins to flicker rapidly to warn you!
- **Emergency Ejection:** If your fuel hits exactly `0` while flying, you are automatically and forcefully ejected back into human form.

---

### 🟢 Phase 2: Collectibles (Crystals) Complete

You can now refuel your ship!

#### What was implemented:

- **Direct Map Collision:** Removed the old spawner script. The game now constantly scans the exact map tiles the player's bounding box is currently touching.
- **The Blue Flag:** If any of the tiles the player touches has the **BLUE flag** (Flag 4), the game registers it as a crystal pickup!
- **The Constraint:** You can walk right through crystals if your fuel is `10/10`. They will only trigger if you need fuel!
- **Collection:** When you grab one, it plays a sound effect (`sfx(0)`), deletes the crystal directly from the map (`mset`), and adds `+1` to your fuel bar!

---

### 🟢 Phase 3: Ship Combat Complete

Pew pew! The ship is now armed and dangerous!

#### What was implemented:

- **SFX Mapping:** Added all the proper sound effects! `sfx(1)` for jumping, `sfx(2)`/`sfx(3)` for transforming, and a persistent engine loop `sfx(6)` while in the ship!
- **Shooting:** By pressing **X** (`btnp(5)`), the ship now spawns a purple energy bullet (`sprite 22`) that travels infinitely in the direction the ship is facing.
- **Ship Animation:** When you shoot, the ship briefly swaps to its firing sprite (`sprite 56`) for 15 frames!
- **Bullet Lifecycle:** Bullets have a `life` of 45 frames (1.5 seconds) so they don't clog up the memory forever if they miss.

---

### 🟢 Phase 4: Asteroids Complete

You now have targets to shoot at!

#### What was implemented:

- **Asteroid Spawner:** While flying the ship, the game randomly spawns asteroids just off-screen (to the right). They pick randomly from your asteroid sprite list (`82, 83, 98, 99, 114, 115`) and drift slowly to the left with slight vertical variation.
- **Combat:** If your bullets touch an asteroid, both the bullet and the asteroid are destroyed! The asteroid will play `sfx(5)` and play its explosive destruction animation (`sprites 40-43`).
- **Player Damage:** If you fail to shoot an asteroid and it crashes into your ship, it will explode, play the sound, and deduct **1 Health** from your health bar!

---

### 🟢 Phase 6: The Laser Bridge Mechanics Complete

The laser bridge is now fully dynamic and animated, exactly as requested!

#### What was implemented:

- **Emitter Scanning:** When the game boots, it automatically finds any Laser Emitters (sprites 28, 29, 30) you placed on the map.
- **Manual Cleanup:** Just in case you left any manual laser pieces (sprites 12, 13, 14) drawn on the map, the game instantly hides them on boot so they don't interfere with the physics engine.
- **Distance Calculation:** Every emitter shoots a ray out across the gap until it hits a solid wall, logging exactly how many tiles need to be bridged. It resolves overlaps automatically if two emitters face each other!
- **The Bridge Animation (`update_lasers`):**
  - The first **2 tiles** immediately in front of any emitter are drawn using a perfectly stable, safe laser (sprite 12).
  - Any tile extending further than 2 blocks outward becomes part of the **pulsating middle gap**.
  - The pulsating tiles run a temporal animation cycle (`12 -> 13 -> 14 -> empty -> 14 -> 13`) giving a beautiful flashing effect!
- **Dynamic Physics (`fset`):** The game forcefully edits the collision flags of the sprites in code: `12` and `13` are perfectly walkable, while `14` and `empty` are physically disabled! This means if the player is standing on the bridge when it flashes to the empty state, they will plummet through!

---

### 🟢 Phase 7: UI & End Screens Complete

The state machine is fully operational! The game now gracefully handles win and loss conditions.

#### What was implemented:

- **The State Machine:** The game engine has been wrapped in a global `game_state` (`"play"`, `"dead"`, `"win"`). All physics and interactions freeze perfectly when a game over triggers.
- **Green Gems (Win Condition):** The game scans your map on boot and counts exactly how many Green Gems (sprite 22) exist. When you collect them all, it triggers the Win State!
- **The Death Screen:** If your health hits 0, it draws sprite 23 directly in the center `(60, 60)`. It then spawns an infinite shower of particles that animate through the health-loss sprites (8, 9, 10, 11). The spawner uses mathematical geometry bounds to absolutely guarantee NO particles ever spawn in the center 3x3 tile exclusion zone around your death sprite!
- **The Win Screen:** It uses the exact same geometry exclusion logic as the Death Screen, but draws the full heart (sprite 8) in the center, surrounded by particles animating through the ship destruction sprites (40, 41, 42, 43).
- **Restart Logic:** Simply press **X** on either end screen to instantly wipe the state and start a fresh run from `_init()`!

---

### 🟢 Phase 8: Enemy Plants Complete

The static plant tiles have been upgraded into active threats with their own AI!

#### What was implemented:

- **Dynamic Conversion:** When the game starts, any Plant sprite (`77`) found on the map is instantly converted into a dynamic entity and erased from the static map.
- **Proximity AI:** The plants will sit completely idle. But if the player steps within a 10-tile radius, they instantly shift into their attack state! If the player steps out of the radius, they stop attacking.
- **Animation & Spawning:** Once aggroed, they begin cycling their shooting animation (`68 -> 67 -> 66 -> 65`). EXACTLY when the animation hits frame `66`, an enemy bullet spawns.
- **Homing Bullets:** The enemy bullets constantly re-evaluate the player's position, chasing them horizontally and vertically! The bullets animate backward in a cycle as requested (`112 -> 96 -> 80 -> 64`).
- **Dynamic Damage Immunity:**
  - **Ship Form:** Totally immune! If a bullet hits the ship, the bullet explodes safely (`40..43`). The ship can also shoot its own bullets to destroy the plants (which triggers the same explosion)!
  - **Human Form:** Vulnerable! If the human touches a plant body or gets hit by a homing bullet, they lose 1 health and trigger a brand new Hurt Animation (sprite `16`).
- **New Dying State:** Instead of instantly teleporting to the Death Screen when health hits 0, the game enters a `"dying"` state. The player drops to the ground and animates through the death sequence (`16 -> 17 -> 18 -> 19 -> 20 -> 21`) before the Death Screen finally appears!

---

### 🟢 Phase 9: Health UI & Drops Complete

The game's health, HUD, and item collection systems have received a major glow-up!

#### What was implemented:

- **10 Hearts UI:** The maximum health was doubled from 5 to 10!
- **Animated HUD State Machine:** The static health bar is now a fully animated UI!
  - **Health Loss:** Taking damage triggers a specific heart to enter a `"losing"` state. It visually animates through the destruction sprites (`9 -> 10 -> 11`) on the HUD before finally settling on empty!
  - **Health Gain:** Picking up a Green Crystal triggers the exact opposite. A missing heart will enter a `"gaining"` state, animating backwards (`11 -> 10 -> 9`) until it solidifies back into a full heart (`8`).
- **Green Crystal Drops:** If you shoot down an Enemy Plant, it will dynamically drop a physical Green Crystal entity into the world! Collecting it increases your health by 1, and won't be collected if you are already at max health (10).
- **Collection Particle Effects:** Whenever you pick up _any_ crystal (Blue Fuel on the map, Green Health on the map, or Green Health dropped from enemies), the game now spawns a temporary particle effect at that specific coordinate that flashes sprites `26, 27` to visually confirm the pickup!

---

### 🟢 Phase 10: Fuel UI Complete

The game's fuel bar has been upgraded to use the same dynamic animation system as the health bar!

#### What was implemented:

- **Animated HUD State Machine:** The static fuel bar is now fully animated!
  - **Fuel Loss:** When the ship naturally consumes a full unit of fuel, the corresponding fuel crystal on the HUD cycles through sprites `26 -> 27` before disappearing.
  - **Fuel Gain:** Picking up a Blue Crystal triggers a missing fuel spot on the HUD to animate backwards `27 -> 26` until it solidifies back into a full crystal (`24`).
- **Persistent Low Fuel Warning:** The flashing red warning sequence automatically restricts itself to only the _remaining_ solid crystals when fuel drops below 2.5!

---

### 🟢 Phase 11: Unified Win Condition & Fall Death Complete

The game's progression and bottomless hazard mechanics are now unified and robust!

#### What was implemented:

- **Unified Green Gem Calculation:** The game now automatically adds map-placed static green crystals and the plant enemies together during initialization (`total_green_gems = static_green_gems + total_enemy_plants`). This dynamically accounts for plant crystal drops.
- **Full-Health Map Pickups:** The player can pick up static green gems from the map at full health (10/10) to progress towards the win condition, triggering the correct audio and collection particle effects.
- **Full-Health Dropped Pickups:** The player can collect green gem drops from defeated plants even at full health, incrementing the green gems progress correctly.
- **Falling Hazard Pit Death:** A human player falling below Y = 120 is immediately defeated. Their health drops to 0, state transitions to `"dying"`, sound effect `sfx(5)` plays, and they fall to their doom playing the death animation sequence smoothly before launching the retry/restart screen.

---

### 🟢 Phase 12: Game Balancing Updates Complete

The game has been perfectly tuned to optimize player experience, making ship navigation manageable, static map hazards shootable, and enemy projectiles dodgeable!

#### What was implemented:

- **Asteroid Balance:** Cooldown timer increased from `10 + rnd(15)` to `20 + rnd(20)` (which the player refined) and drift velocity reduced to `dx = -0.5 - rnd(0.8)` and `dy = (rnd(1) - 0.5) * 0.3`.
- **Shootable Map Asteroids:** Any static background map tile of the asteroid sprite set (`82, 83, 98, 99, 114, 115`) now explodes on player bullet collision, clearing the tile with `mset(tx, ty, 0)`, playing `sfx(5)`, and showing the standard destruction animation (`40..43`).
- **Dodgeable Enemy Projectiles:** Plant enemy bullets are now fired less frequently (every 180 frames). The trajectory direction vector is calculated once at spawn time, and the bullet moves linearly without homing, allowing the player to dodge successfully.

---

### 🟢 Phase 13: Jump Height Balancing Complete

The player's jump has been successfully balanced and tuned for a higher, more satisfying jump curve!

#### What was implemented:

- **Impulse & Speed Cap Adjustments:** Increased `player.boost` to `4.8` and the maximum vertical velocity cap `player.max_dy` to `4.8` in `_init()`. This removes the upward velocity bottleneck, letting the full jump impulse move the player significantly higher while maintaining solid falling kinetics.

---

### 🟢 Phase 14: 3x3 Bullet Splash Complete

Upgrade player bullets to deal 3x3 tile area-of-effect damage, enabling massive chain-explosions of obstacles (flying asteroids, plant enemies, and map-painted static asteroids) centered on impact.

#### What was implemented:

- **Impact Tracking & Center Computation**: Refactored player bullet collision in `update_bullets()` so that the moment a bullet touches a flying asteroid, a plant enemy, or a map asteroid, it captures the center tile coordinate `(hit_tx, hit_ty)` and signals a hit.
- **3x3 AoE Area**: Implemented a 24x24 pixel bounding box `(sx = (hit_tx - 1) * 8, sy = (hit_ty - 1) * 8, sw = 24, sh = 24)` to act as the splash zone.
- **Flying Obstacle Sweeper**: Any active flying asteroids within the AoE box explode instantly (`death_timer = 16`, play standard explosion SFX).
- **Aggressive Enemy Sweeper**: Any active plant enemies within the AoE box are defeated, playing standard explosion SFX and dropping green crystals to support progression.
- **Background Terrain chain-destruction**: Evaluated a 3x3 tile neighborhood around the impact tile. Any matching static background map asteroids are cleared (`mset(tx, ty, 0)`), spawning a dedicated visual explosion object and playing standard explosion SFX for each destroyed tile.
