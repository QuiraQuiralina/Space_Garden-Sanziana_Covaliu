# Implementation Plan: Health & Animations

## Proposed Changes

### 1. Health Increase & Green Crystal Logic
- Update `_init()`: Set `player.health = 10` and `player.max_health = 10`.
- Update `_init()`: Make sure the HUD draws 10 hearts properly without overlapping. We may need to wrap them to a second row or space them tighter if 10 doesn't fit on one line!
- Update Green Crystal collision (sprite 22): When collected, it will increase `player.health` by 1 (capped at `player.max_health`) in addition to incrementing the win condition counter.

### 2. Animations Integration
We have a few specific sprite sequences to implement based on your request and the README:

- **Crystal Collection (`26, 27`)**: When a blue crystal (fuel) or green crystal (health) is touched, instead of instantly disappearing `mset(x, y, 0)`, we can spawn a temporary "particle/effect" object at that location that quickly plays sprites `26 -> 27` and then deletes itself.
- **Health Loss (`9, 10, 11`)**: When the player takes damage (loses a heart), we can spawn an effect at the player's location that animates through `9 -> 10 -> 11` floating upwards. 

## Open Questions

Before I start coding, I need clarification on exactly how you envision these animations:

1. **"Fuel drop (same as crystal collection)"**: Do you mean that asteroids/enemies should have a random chance to *drop* a fuel crystal when they die? Or did you just mean that the animation for picking up fuel is the same as the crystal collection animation?
2. **"Health drop"**: Does this mean enemies should randomly drop health items (green crystals) when they die? Or do you mean the `Health_loss (9, 10, 11)` animation should play when the player gets hurt?
3. **HUD Layout**: 10 hearts (sprite 8) side-by-side will take up 90 pixels (out of the 128 pixel screen). This is quite long! Do you want them all in one row at the top left, or should they wrap to a second row (e.g., 5 hearts on top, 5 hearts below)?
