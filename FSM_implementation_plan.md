# Implement Finite State Machine for Player Movement

This plan outlines the refactoring of the player's movement logic in `space_garden.p8` into a Finite State Machine (FSM). This will cleanly separate the human and ship states, enabling independent logic (like true multi-directional flying for the ship without gravity interference) while keeping the existing collision functions (`_collide_map` and `ship_collider`) completely untouched.

## User Review Required

> [!IMPORTANT]
> The `README.md` specifies different controls than what is currently implemented. Specifically:
> *   **Jump** will change from `X` (button 5) to `Arrow Up` (button 2).
> *   **Crouch** will be mapped to `Arrow Down` (button 3).
> *   The current controlled ascent/descent mechanic using Up/Down arrows will be replaced by the raw Jump (Up arrow) and full flight controls for the ship.
> 
> Please confirm if you are okay with changing the jump button from X to Up Arrow to match the README.

## Proposed Changes

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
*   **Physics:** Apply gravity to `dy` and friction to `dx`.
*   **Controls:**
    *   `btn(0)` (Left) / `btn(1)` (Right): Run forward.
    *   `btn(2)` (Up): Jump (replaces the old jump logic).
    *   `btn(3)` (Down): Crouch.
    *   `btnp(4)` (C): Change to Ship (Sets `player.state = "ship"` and applies the `y -= 8` offset).
    *   `btnp(5)` (X): Interact (Placeholder for future feature).
*   **Collision:** Uses only `_collide_map`.

### 4. State: Player_Ship (`update_ship`)
This function will handle multi-directional zero-gravity movement.
*   **Physics:** Remove gravity. Apply friction to **both** `dx` and `dy` so the ship drifts smoothly to a halt when no buttons are pressed.
*   **Controls:**
    *   `btn(0)` (Left) / `btn(1)` (Right): Fly horizontally.
    *   `btn(2)` (Up) / `btn(3)` (Down): Fly vertically.
    *   `btnp(4)` (C): Change to Human (Sets `player.state = "human"`).
    *   `btnp(5)` (X): Shoot (Placeholder for future feature).
*   **Collision:** Uses only `ship_collider`.

### 5. Animation Update
We will quickly patch `player_animate()` and `_draw()` to use `player.state == "ship"` instead of the old `player.is_ship` boolean, ensuring the visuals remain exactly as they were.

## Verification Plan

### Automated/Code Checks
*   Verify `ship_collider` and `_collide_map` are not modified.
*   Verify the code parses correctly in PICO-8 format.

### Manual Verification
1.  Load the game. The player should start in human form, falling under gravity.
2.  Press Up arrow to jump. Verify collisions work correctly (snapping to the ground).
3.  Press 'C' to transform into the ship.
4.  Use all four arrow keys to fly around freely. Verify that the ship doesn't get stuck on one axis and hovers correctly when keys are released.
5.  Press 'C' to turn back into a human. Verify gravity kicks back in.
