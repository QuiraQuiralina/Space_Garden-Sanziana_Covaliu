pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
  -- reload sprite and map memory from the cartridge ROM to RAM
  -- this ensures all mset() changes (enemies, crystals, lasers) are wiped on restart!
  reload(0x0, 0x0, 0x3000)

  -- changed pl to player to match the rest of your code
  player = {
    sp = 1, x = 59, y = 59, w = 8, h = 8, flp = false,
    dx = 0, dy = 0, max_dx = 2, max_dy = 3,
    acc = 0.5, boost = 4, anim = 0,
    running = false, jumping = false,
    falling = false, sliding = false, landed = false,
    state = "human", crouching = false,
    health = 10, max_health = 10,
    fuel = 5, max_fuel = 10,
    crystals_collected = 0,
    hearts = {},
    fuel_icons = {}
  }
  for i=1, 10 do
    add(player.hearts, {state="full", timer=0, sp=8})
    local fuel_st = "empty"
    if i <= 5 then fuel_st = "full" end
    add(player.fuel_icons, {state=fuel_st, timer=0, sp=24})
  end
  player.last_fuel_int = 5
  gravity = 0.3
  friction = 0.85
  map_start = 0
  map_end = 1024
  respawning_crystals = {}
  bullets = {}
  asteroids = {}
  generator_on = false
  laser_bridge_active = true
  
  lasers = {}
  emitters = {}
  for my = 0, 63 do
    for mx = 0, 127 do
      local sp = mget(mx, my)
      if sp >= 12 and sp <= 14 then
        mset(mx, my, 0) -- hide manual lasers
      elseif sp >= 28 and sp <= 30 then
        add(emitters, { x = mx, y = my, type = sp })
      end
    end
  end

  local temp_lasers = {}
  for e in all(emitters) do
    if e.type == 28 or e.type == 30 then
      local dist = 1
      while dist < 128 do
        local sp = mget(e.x + dist, e.y)
        if fget(sp, 0) then break end
        add(temp_lasers, {x=e.x+dist, y=e.y, dist=dist})
        dist += 1
      end
    end
    if e.type == 29 or e.type == 30 then
      local dist = 1
      while dist < 128 do
        local sp = mget(e.x - dist, e.y)
        if fget(sp, 0) then break end
        add(temp_lasers, {x=e.x-dist, y=e.y, dist=dist})
        dist += 1
      end
    end
  end

  -- resolve overlaps for dual emitters facing each other
  local unique_lasers = {}
  for l in all(temp_lasers) do
    local key = l.x..","..l.y
    if not unique_lasers[key] then
      unique_lasers[key] = {x=l.x, y=l.y, dist=l.dist}
    else
      if l.dist < unique_lasers[key].dist then
        unique_lasers[key].dist = l.dist
      end
    end
  end

  for k, v in pairs(unique_lasers) do
    add(lasers, v)
  end

  -- ensure physics flags are correct for bridge logic
  fset(12, 0, true)
  fset(13, 0, true)
  fset(14, 0, false)

  game_state = "play" -- can be "play", "dead", "win"
  end_particles = {}
  enemies = {}
  enemy_bullets = {}
  items = {}
  effects = {}
  
  -- count green gems
  total_green_gems = 0
  for my = 0, 63 do
    for mx = 0, 127 do
      local sp = mget(mx, my)
      if sp == 22 then
        total_green_gems += 1
      elseif sp == 77 then
        add(enemies, { x = mx * 8, y = my * 8, state = "idle", timer = 0, health = 1, death_timer = 0 })
        mset(mx, my, 0)
      end
    end
  end
  player.green_gems_collected = 0
end

function _update()
  if game_state == "play" then
    player_update()
    player_animate()
    update_respawns()
    update_bullets()
    update_asteroids()
    update_lasers()
    update_enemies()
    update_enemy_bullets()
    update_effects()
    camera_update()
    
    local current_fuel_int = flr(player.fuel)
    if current_fuel_int < player.last_fuel_int then
      for i = current_fuel_int + 1, player.last_fuel_int do
        if i <= player.max_fuel and i > 0 then
          player.fuel_icons[i].state = "losing"
          player.fuel_icons[i].timer = 0
        end
      end
    elseif current_fuel_int > player.last_fuel_int then
      for i = player.last_fuel_int + 1, current_fuel_int do
        if i <= player.max_fuel and i > 0 then
          player.fuel_icons[i].state = "gaining"
          player.fuel_icons[i].timer = 0
        end
      end
    end
    player.last_fuel_int = current_fuel_int
    
    if player.hurt_timer and player.hurt_timer > 0 then
      player.hurt_timer -= 1
    end

    if player.health <= 0 and player.state ~= "dying" then
      player.state = "dying"
      player.death_timer = 0
    end
    
    if player.state == "dying" then
      player.death_timer += 1
      if player.death_timer > 30 then
        game_state = "dead"
        end_particles = {}
      end
    end
    
    if total_green_gems > 0 and player.green_gems_collected >= total_green_gems then
      game_state = "win"
      end_particles = {}
    end
  elseif game_state == "dead" or game_state == "win" then
    update_end_screen()
  end
end

function update_end_screen()
  if flr(time() * 30) % 2 == 0 then
    local px, py
    local valid = false
    while not valid do
      px = rnd(128)
      py = rnd(128)
      if not (px >= 52 and px <= 76 and py >= 52 and py <= 76) then
        valid = true
      end
    end
    add(end_particles, {x=px, y=py, life=16})
  end

  for p in all(end_particles) do
    p.life -= 1
    if p.life <= 0 then
      del(end_particles, p)
    end
  end

  if btnp(5) then -- press X to retry
    _init()
  end
end

function update_lasers()
  if not laser_bridge_active then
    for l in all(lasers) do
      mset(l.x, l.y, 0) -- remove bridge when off
    end
    return
  end

  -- animate bridge when active
  local pulse_frames = { 12, 12, 13, 14, 0, 14, 13 }
  local f_idx = (flr(time() * 4) % #pulse_frames) + 1
  local cur_pulse_frame = pulse_frames[f_idx]

  for l in all(lasers) do
    if l.dist <= 2 then
      mset(l.x, l.y, 12) -- stable near emitter
    else
      mset(l.x, l.y, cur_pulse_frame) -- pulsating in middle
    end
  end
end

function update_enemies()
  for e in all(enemies) do
    if e.death_timer > 0 then
      e.death_timer -= 1
      if e.death_timer <= 0 then
        del(enemies, e)
      end
    else
      -- proximity check (roughly 10 tiles)
      local dist = abs(player.x - e.x) + abs(player.y - e.y)
      if dist < 80 then
        if e.state == "idle" then
          e.state = "shoot"
          e.timer = 0
        end
      else
        e.state = "idle"
        e.timer = 0
      end

      if e.state == "shoot" then
        e.timer += 1
        -- 5 ticks per frame. Frames: 68, 67, 66, 65
        if e.timer == 10 then
          -- Exactly on frame 66
          add(enemy_bullets, {x = e.x, y = e.y, timer = 0, impact_timer = 0})
          sfx(2)
        end
        if e.timer >= 120 then -- wait ~4 seconds between shots
          e.timer = 0 -- restart animation loop if still in proximity
        end
      end

      -- player human vs static plant collision
      if player.state == "human" and (not player.hurt_timer or player.hurt_timer <= 0) then
        if check_aabb(player.x, player.y, player.w, player.h, e.x, e.y, 8, 8) then
          change_health(-1)
          player.hurt_timer = 15
          sfx(5)
        end
      end
    end
  end
end

function update_enemy_bullets()
  for b in all(enemy_bullets) do
    if b.impact_timer > 0 then
      b.impact_timer -= 1
      if b.impact_timer <= 0 then
        del(enemy_bullets, b)
      end
    else
      b.timer += 1
      
      -- chase player
      local dx = 0
      local dy = 0
      if player.x < b.x then dx = -1 elseif player.x > b.x then dx = 1 end
      if player.y < b.y then dy = -1 elseif player.y > b.y then dy = 1 end
      
      b.x += dx * 0.4
      b.y += dy * 0.4
      
      if b.timer > 150 then
        del(enemy_bullets, b)
      end
      
      local pw = player.state == "ship" and 16 or player.w
      local ph = player.state == "ship" and 16 or player.h
      if check_aabb(player.x, player.y, pw, ph, b.x, b.y, 8, 8) then
        if player.state == "ship" then
          b.impact_timer = 16 -- destroyed on ship
        elseif player.state == "human" and (not player.hurt_timer or player.hurt_timer <= 0) then
          change_health(-1)
          player.hurt_timer = 15
          b.impact_timer = 16
        end
        sfx(5)
      end
    end
  end
end

function update_bullets()
  for b in all(bullets) do
    if b.impact_timer and b.impact_timer > 0 then
      b.impact_timer -= 1
      if b.impact_timer <= 0 then
        del(bullets, b)
      end
    else
      b.x += b.dx
      b.life -= 1

      local hit = false
      for a in all(asteroids) do
        if a.death_timer == 0 and check_aabb(b.x, b.y, 8, 8, a.x, a.y, 8, 8) then
          b.impact_timer = 5
          a.death_timer = 16
          sfx(5) -- asteroid death
          hit = true
          break
        end
      end

      if not hit then
        for e in all(enemies) do
          if e.death_timer == 0 and check_aabb(b.x, b.y, 8, 8, e.x, e.y, 8, 8) then
            b.impact_timer = 5
            e.death_timer = 16
            add(items, {x=e.x, y=e.y, sp=22}) -- spawn green crystal
            sfx(5)
            hit = true
            break
          end
        end
      end

      if not hit and b.life <= 0 then
        del(bullets, b)
      end
    end
  end
end

function update_asteroids()
  if player.state == "ship" then
    if not player.asteroid_timer then player.asteroid_timer = 10 end
    player.asteroid_timer -= 1
    if player.asteroid_timer <= 0 then
      player.asteroid_timer = 10 + rnd(15) -- much faster spawning!
      local cam_x = peek2(0x5f28)
      local cam_y = peek2(0x5f2a)
      local spr_list = { 82, 83, 98, 99, 114, 115 }
      add(
        asteroids, {
          x = cam_x + 130 + rnd(20),
          y = cam_y + rnd(120),
          dx = -1 - rnd(1.5), -- slightly faster drift
          dy = (rnd(1) - 0.5) * 0.5,
          sp = spr_list[flr(rnd(#spr_list)) + 1],
          life = 300,
          death_timer = 0
        }
      )
    end
  end

  for a in all(asteroids) do
    if a.death_timer > 0 then
      a.death_timer -= 1
      if a.death_timer <= 0 then
        del(asteroids, a)
      end
    else
      a.x += a.dx
      a.y += a.dy
      a.life -= 1

      -- hit player (both human and ship!)
      local pw = player.state == "ship" and 16 or player.w
      local ph = player.state == "ship" and 16 or player.h
      if check_aabb(player.x, player.y, pw, ph, a.x, a.y, 8, 8) then
        if not player.hurt_timer or player.hurt_timer <= 0 then
          change_health(-1)
          player.hurt_timer = 15
        end
        a.death_timer = 16
        sfx(5)
      end

      if a.life <= 0 then
        del(asteroids, a)
      end
    end
  end
end

function update_respawns()
  for c in all(respawning_crystals) do
    c.timer -= 1
    if c.timer <= 0 then
      mset(c.x, c.y, c.spr)
      del(respawning_crystals, c)
    end
  end
end

function _draw()
  cls()
  if game_state == "play" then
    map(0, 0)
    draw_asteroids()
    draw_items()
    draw_enemies()
    draw_enemy_bullets()
    draw_bullets()
    draw_effects()

    if player.state == "ship" then
      local ship_spr = 32
      if player.shoot_timer and player.shoot_timer > 0 then
        ship_spr = 38
      end
      spr(ship_spr, player.x, player.y, 2, 2, player.flp)

      -- Muzzle flash / bullet exiting gun (sprite 56)
      if player.shoot_timer and player.shoot_timer > 0 then
        if player.flp then
          spr(56, player.x - 8, player.y + 8, 1, 1, true)
        else
          spr(56, player.x + 16, player.y + 8)
        end
      end
    else
      if player.state == "dying" then
        local d_frame = flr(player.death_timer / 5)
        if d_frame > 5 then d_frame = 5 end
        spr(16 + d_frame, player.x, player.y, 1, 1, player.flp)
      else
        if player.hurt_timer and player.hurt_timer > 0 then
          spr(16, player.x, player.y, 1, 1, player.flp)
        else
          spr(player.sp, player.x, player.y, 1, 1, player.flp)
        end
      end
    end

    draw_hud()
  elseif game_state == "dead" or game_state == "win" then
    draw_end_screen()
  end
end

function draw_end_screen()
  camera() -- reset camera
  
  if game_state == "dead" then
    spr(23, 60, 60)
  elseif game_state == "win" then
    spr(8, 60, 60)
  end

  for p in all(end_particles) do
    local frame = flr((16 - p.life) / 4) -- 0 to 3
    local sp = (game_state == "dead") and (8 + frame) or (40 + frame)
    spr(sp, p.x, p.y)
  end

  print("press x to restart", 28, 100, 7)
end

function draw_bullets()
  for b in all(bullets) do
    if b.impact_timer and b.impact_timer > 0 then
      spr(59, b.x, b.y, 1, 1, b.dx < 0)
    else
      local b_spr = 57 + (flr(time() * 8) % 2)
      spr(b_spr, b.x, b.y, 1, 1, b.dx < 0)
    end
  end
end

function draw_asteroids()
  for a in all(asteroids) do
    if a.death_timer > 0 then
      local frame = flr((16 - a.death_timer) / 4)
      spr(40 + frame, a.x, a.y)
    else
      spr(a.sp, a.x, a.y)
    end
  end
end

function draw_items()
  for i in all(items) do
    spr(i.sp, i.x, i.y)
  end
end

function draw_effects()
  for e in all(effects) do
    if e.type == "crystal" then
      local frame = flr(e.timer / 5)
      if frame > 1 then frame = 1 end
      spr(26 + frame, e.x, e.y)
    end
  end
end

function draw_enemies()
  for e in all(enemies) do
    if e.death_timer > 0 then
      local frame = flr((16 - e.death_timer) / 4)
      spr(40 + frame, e.x, e.y)
    else
      if e.state == "idle" then
        spr(77, e.x, e.y)
      elseif e.state == "shoot" then
        if e.timer >= 20 then
          spr(77, e.x, e.y) -- sit idle between shots
        else
          local frame_idx = flr(e.timer / 5)
          if frame_idx > 3 then frame_idx = 3 end
          local sprites = {68, 67, 66, 65}
          spr(sprites[frame_idx + 1], e.x, e.y)
        end
      end
    end
  end
end

function draw_enemy_bullets()
  for b in all(enemy_bullets) do
    if b.impact_timer > 0 then
      local frame = flr((16 - b.impact_timer) / 4)
      spr(40 + frame, b.x, b.y)
    else
      local frames = {112, 96, 80, 64}
      local f_idx = (flr(b.timer / 4) % #frames) + 1
      spr(frames[f_idx], b.x, b.y)
    end
  end
end

function draw_hud()
  camera()
  -- reset camera to 0,0 for static UI

  -- draw health
  for i = 1, player.max_health do
    local h = player.hearts[i]
    local sp = 0
    if h.state == "full" then
      sp = 8
    elseif h.state == "losing" then
      local frames = {9, 10, 11}
      local f_idx = flr(h.timer / 4) + 1
      if f_idx > #frames then
        h.state = "empty"
      else
        sp = frames[f_idx]
        h.timer += 1
      end
    elseif h.state == "gaining" then
      local frames = {11, 10, 9}
      local f_idx = flr(h.timer / 4) + 1
      if f_idx > #frames then
        h.state = "full"
        sp = 8
      else
        sp = frames[f_idx]
        h.timer += 1
      end
    end
    
    if sp > 0 then
      spr(sp, 2 + (i - 1) * 9, 2)
    end
  end

  -- draw fuel (sprite 24)
  for i = 1, player.max_fuel do
    local f = player.fuel_icons[i]
    local sp = 0
    if f.state == "full" then
      sp = 24
    elseif f.state == "losing" then
      local frames = {26, 27}
      local f_idx = flr(f.timer / 4) + 1
      if f_idx > #frames then
        f.state = "empty"
      else
        sp = frames[f_idx]
        f.timer += 1
      end
    elseif f.state == "gaining" then
      local frames = {27, 26}
      local f_idx = flr(f.timer / 4) + 1
      if f_idx > #frames then
        f.state = "full"
        sp = 24
      else
        sp = frames[f_idx]
        f.timer += 1
      end
    end
    
    if sp > 0 then
      local draw_this = true
      -- blink low fuel only for the remaining full icons
      if f.state == "full" and i <= 2 and player.fuel < 2.5 and flr(time() * 8) % 2 == 0 then
        draw_this = false
      end
      if draw_this then
        spr(sp, 2 + (i - 1) * 9, 12)
      end
    end
  end

  camera_update()
  -- restore camera
end

function player_update()
  if player.state == "dying" then
    -- only apply gravity so the player falls to the floor while dying
    player.dy += gravity
    player.y += player.dy
    if player.dy > 0 then
      if _collide_map(player, "down", 0) then
        player.dy = 0
        player.y = flr((player.y + player.h) / 8) * 8 - player.h
      end
    end
  elseif player.state == "human" then
    update_human()
  elseif player.state == "ship" then
    update_ship()
  end

  -- map limits
  local current_w = (player.state == "ship") and 16 or player.w
  player.x = mid(map_start, player.x, map_end - current_w)
end

function update_human()
  -- physics
  player.dy += gravity
  player.dx *= friction

  -- controls
  if btn(0) then
    player.dx -= player.acc
    player.running = true
    player.flp = true
  elseif btn(1) then
    player.dx += player.acc
    player.running = true
    player.flp = false
  else
    -- slide/idle logic
    if player.running and not player.falling and not player.jumping then
      player.running = false
      player.sliding = true
    end
  end

  -- crouch
  if btn(3) and player.landed then
    player.crouching = true
  else
    player.crouching = false
  end

  -- transform
  if btnp(4) then
    if player.fuel >= 2.5 then
      player.state = "ship"
      player.y -= 8
      sfx(3) -- transform up sound
      sfx(0, 3) -- start engine loop on channel 3
      player.last_engine_sfx = 0
      return
    end
  end

  -- interact
  if btnp(5) then
    local corners = {
      { x = player.x + 2, y = player.y + 2 },
      { x = player.x + player.w - 2, y = player.y + 2 },
      { x = player.x + 2, y = player.y + player.h - 2 },
      { x = player.x + player.w - 2, y = player.y + player.h - 2 }
    }
    for c in all(corners) do
      local cx = flr(c.x / 8)
      local cy = flr(c.y / 8)
      local spr_id = mget(cx, cy)

      if fget(spr_id, 3) then
        -- GREEN flag (Interactable)
        if spr_id == 63 then
          mset(cx, cy, 47)
          generator_on = true
          sfx(0)
          break
        elseif generator_on then
          if spr_id == 31 then
            mset(cx, cy, 15)
            laser_bridge_active = false -- bridge OFF
            sfx(0)
            break
          elseif spr_id == 15 then
            mset(cx, cy, 31)
            laser_bridge_active = true -- bridge ON
            sfx(0)
            break
          end
        end
      end
    end
  end

  -- jump - mapped to arrow up (btnp(2))
  if btnp(2) and player.landed then
    player.dy -= player.boost
    player.landed = false
    player.jumping = true
    sfx(1) -- jump sound
  end

  if player.landed then
    player.jumping = false
  end

  -- speed limits
  player.dy = mid(-player.max_dy, player.dy, player.max_dy)

  -- y movement & collision
  player.y += player.dy
  if player.dy > 0 then
    if _collide_map(player, "down", 0) then
      player.landed = true
      player.falling = false
      player.dy = 0
      player.y = flr((player.y + player.h) / 8) * 8 - player.h
    end
  elseif player.dy < 0 then
    if _collide_map(player, "up", 0) then
      player.dy = 0
      player.y = flr((player.y - 1) / 8) * 8 + 8
    end
  end

  -- x movement & collision
  player.x += player.dx
  if player.dx > 0 then
    if _collide_map(player, "right", 0) then
      player.dx = 0
      player.x = flr((player.x + player.w) / 8) * 8 - player.w
    end
  elseif player.dx < 0 then
    if _collide_map(player, "left", 0) then
      player.dx = 0
      player.x = flr((player.x - 1) / 8) * 8 + 8
    end
  end

  check_crystal_collision()
end

function update_ship()
  -- engine loop on channel 3 (alternates 0 and 6)
  if stat(49) == -1 then
    if player.last_engine_sfx == 0 then
      sfx(6, 3)
      player.last_engine_sfx = 6
    else
      sfx(0, 3)
      player.last_engine_sfx = 0
    end
  end

  -- fuel management (tripled duration)
  player.fuel -= 0.006
  if player.fuel <= 0 then
    player.fuel = 0
    player.state = "human"
    sfx(3) -- transform down sound
    sfx(-1, 3) -- stop engine loop
    return
  end

  -- physics (zero gravity drift)
  player.dx *= friction
  player.dy *= friction

  -- horizontal controls
  if btn(0) then
    player.dx -= player.acc
    player.flp = true
  elseif btn(1) then
    player.dx += player.acc
    player.flp = false
  end

  -- vertical controls
  if btn(2) then
    player.dy -= player.acc
  elseif btn(3) then
    player.dy += player.acc
  end

  -- transform back to human
  if btnp(4) then
    player.state = "human"
    sfx(3) -- transform down sound
    sfx(-1, 3) -- stop engine loop
    return
  end

  -- shoot
  if player.shoot_timer and player.shoot_timer > 0 then
    player.shoot_timer -= 1
  end

  if btnp(5) then
    add(
      bullets, {
        x = player.x + (player.flp and -8 or 16),
        y = player.y + 8,
        dx = player.flp and -4 or 4,
        life = 45
      }
    )
    sfx(2) -- shoot sound
    player.shoot_timer = 5
  end

  -- speed limits
  player.dy = mid(-player.max_dy, player.dy, player.max_dy)

  -- y movement & collision
  player.y += player.dy
  if player.dy > 0 then
    if ship_collider(player, "down", 0) then
      player.dy = 0
      player.y = flr((player.y + 16) / 8) * 8 - 16
    end
  elseif player.dy < 0 then
    if ship_collider(player, "up", 0) then
      player.dy = 0
      player.y = flr((player.y - 1) / 8) * 8 + 8
    end
  end

  -- x movement & collision
  player.x += player.dx
  if player.dx > 0 then
    if ship_collider(player, "right", 0) then
      player.dx = 0
      player.x = flr((player.x + 16) / 8) * 8 - 16
    end
  elseif player.dx < 0 then
    if ship_collider(player, "left", 0) then
      player.dx = 0
      player.x = flr((player.x - 1) / 8) * 8 + 8
    end
  end
end

function player_animate()
  if player.state == "ship" then return end

  -- using time() (lowercase) instead of Time()
  if not player.landed then
    player.sp = 7
  elseif abs(player.dx) > 0.1 then
    player.sp = 2 + (flr(time() * 10) % 3) -- walk cycle (sprites 2, 3, 4)
  else
    player.sp = flr(time() * 4) % 2 -- idle cycle (sprites 0, 1)
  end
end

function check_aabb(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < x2 + w2 and x1 + w1 > x2
      and y1 < y2 + h2 and y1 + h1 > y2
end

function change_health(amount)
  if amount < 0 then
    if player.health > 0 then
      player.hearts[player.health].state = "losing"
      player.hearts[player.health].timer = 0
      player.health -= 1
    end
  elseif amount > 0 then
    if player.health < player.max_health then
      player.health += 1
      player.hearts[player.health].state = "gaining"
      player.hearts[player.health].timer = 0
    end
  end
end

function check_crystal_collision()
  if player.state == "ship" then return end

  local corners = {
    { x = player.x + 2, y = player.y + 2 },
    { x = player.x + player.w - 2, y = player.y + 2 },
    { x = player.x + 2, y = player.y + player.h - 2 },
    { x = player.x + player.w - 2, y = player.y + player.h - 2 }
  }

  for c in all(corners) do
    local map_x = flr(c.x / 8)
    local map_y = flr(c.y / 8)
    local spr_id = mget(map_x, map_y)

    if fget(spr_id, 4) then
      -- BLUE flag (Collectible)
      if player.fuel < player.max_fuel then
        sfx(4) -- crystal pick-up sound
        player.fuel = min(player.fuel + 1, player.max_fuel)
        player.crystals_collected += 1
        mset(map_x, map_y, 0) -- remove the crystal from the map
        add(respawning_crystals, { x = map_x, y = map_y, spr = spr_id, timer = 4500 }) -- 2.5 mins respawn
        add(effects, {x = map_x * 8, y = map_y * 8, timer = 0, type = "crystal"})
        break -- only collect one at a time
      end
    end
    
    if spr_id == 22 then
      if player.health < player.max_health then
        sfx(4)
        player.green_gems_collected += 1
        change_health(1)
        mset(map_x, map_y, 0)
        add(effects, {x = map_x * 8, y = map_y * 8, timer = 0, type = "crystal"})
        break
      end
    end
  end

  -- Check dropped items
  for i in all(items) do
    if check_aabb(player.x, player.y, player.w, player.h, i.x, i.y, 8, 8) then
      if i.sp == 22 and player.health < player.max_health then
        sfx(4)
        change_health(1)
        add(effects, {x = i.x, y = i.y, timer = 0, type = "crystal"})
        del(items, i)
      end
    end
  end
end

function update_effects()
  for e in all(effects) do
    e.timer += 1
    if e.type == "crystal" then
      if e.timer > 10 then del(effects, e) end
    end
  end
end

function camera_update()
  local cam_x = player.x - 64 + (player.w / 2)
  local cam_y = player.y - 64 + (player.h / 2)
  camera(cam_x, cam_y)
end

function _collide_map(obj, aim, flag)
  local x, y = obj.x, obj.y
  local w, h = obj.w, obj.h
  local x1, y1, x2, y2

  if aim == "down" then
    x1 = x + 2
    y1 = y + h
    x2 = x + w - 2
    y2 = y + h
  elseif aim == "up" then
    x1 = x + 2
    y1 = y - 1
    x2 = x + w - 2
    y2 = y - 1
  elseif aim == "right" then
    x1 = x + w
    y1 = y + 2
    x2 = x + w
    y2 = y + h - 2
  elseif aim == "left" then
    x1 = x - 1
    y1 = y + 2
    x2 = x - 1
    y2 = y + h - 2
  end

  -- check tiles (mget uses tile coords, so divide by 8)
  if fget(mget(x1 / 8, y1 / 8), flag) or fget(mget(x2 / 8, y2 / 8), flag) then
    return true
  end
  return false
end

function ship_collider(obj, aim, flag)
  local x, y = obj.x, obj.y
  local x1, y1, x2, y2, x3, y3, x4, y4

  if aim == "down" then
    x1 = x + 2 y1 = y + 16
    x2 = x + 6 y2 = y + 16
    x3 = x + 10 y3 = y + 16
    x4 = x + 14 y4 = y + 16
  elseif aim == "up" then
    x1 = x + 2 y1 = y - 1
    x2 = x + 6 y2 = y - 1
    x3 = x + 10 y3 = y - 1
    x4 = x + 14 y4 = y - 1
  elseif aim == "right" then
    x1 = x + 16 y1 = y + 2
    x2 = x + 16 y2 = y + 6
    x3 = x + 16 y3 = y + 10
    x4 = x + 16 y4 = y + 14
  elseif aim == "left" then
    x1 = x - 1 y1 = y + 2
    x2 = x - 1 y2 = y + 6
    x3 = x - 1 y3 = y + 10
    x4 = x - 1 y4 = y + 14
  end

  if fget(mget(x1 / 8, y1 / 8), flag)
      or fget(mget(x2 / 8, y2 / 8), flag)
      or fget(mget(x3 / 8, y3 / 8), flag)
      or fget(mget(x4 / 8, y4 / 8), flag) then
    return true
  end
  return false
end

__gfx__
04444440044444400044444000444440004444400044444000000000004444400220022002200220022002200000000011111111100110111001000104494550
04f71f1004f71f10004f71f0004f71f0004f71f0004f71f000444440004f71f028822882288228822882028202220220cccccccc0cc0cc0c0c00c00c04bbbb50
04fffff004fffef0404fffe0404fffe0404fffe0404fffe0004f71f0404fffe08888888888822888882202880282028077777777777777777707070704bbbb50
444ff444444ff444444ff440444ff440444ff440444ff440404fffe0444ff44088888878888288888882028802820220ccccccccc00cc0c0c00c00c004444540
00eeee0000eeee00feeee000feeee000feeee000feeee000444ff440feeeeeef2888878228828882288200220222002011111111101011011010100100045000
0f02d0f000feef0000eee00000eee00000eee00000eee000feeeeeef00eeee000288782002822820028220200022202000000000000000000000000000045000
f002d00f0f02d0f02220d0000020d0000d2dd0000020d00000eee000022dd0000028820000282200002820000002200000000000000000000000000004945550
0022dd000022dd000000d000020d00000020000000020d0000ddd222000000000002200000022000000220000000200000000000000000000000000049444444
02222220022222200222000000000000000000000000000000333300000000000111111001111110001111000000000056555555494444444944444404494550
0217e7100210e01022ee200e00000e00000000000000000003bbbb30220882201cccccc11cccccc101c77c10000000000067660000676600009a990004888850
22ee2ee022ee2ee02e1ee2802000800000000000000000003b3333b322280222cccccc7ccccccccc0c7777c0000c70000067660000676900009a990004888850
222ee220222ee220e1ee8820ee08000000000000000000003b3bb3b320288202ccccc7cccccccc7c01c77c100001c0000067660000679900009a990004444540
e888888ee888888e2ee88200ee80000200220000004400003b3bb3b3202802021ccc7cc11cccc7c1001cc1000000000056555555494444444944444400045000
008888000088880022888000228800202ee200004ff400003b3333b32228822201c7cc1001cc7c10000110000000000056555555494444444944444400045000
001020000010200002812000228882002ee882224ffee22203bbbb3000000000001cc100001cc100000000000000000005655550049444400494444004945550
01000200010002000810020028288111222281114444eddd00333300000000000001100000011000000000000000000000565500004444000049440049444444
00000000000000000000000000000000000000000000000000000000000000000000000070000007707070070000000000565500004944000049440000000000
00000000000000000000000000000000000000000000000000000000000000000000000007000070070000700700007000565500004945000049440008000000
00000000000000000000000000000000000000000000000000000000000000000070070000777700700700070007000700565500004955000049440000200000
000000000000000000000000cc00000000000000cc00000000000000000000000007700000700700000007000000000000565500004f54000049440000050000
00000000000000000000000c44c000000000000c44c0000000000000000000000007700000700700707000070000000000565500005f44000049440000005000
0000000000000000000000c4ff4c0000000000c4ff4c000000000000000000000070070000777700700070000007070000565500005f54000049440000494400
00000000cc00000000000111111d0000a0000111111d000000000000cc0000000000000007000070070000700700007000565500005f45000049440004945550
0000000c44c0000000001118b111d000a9001118b111d0000000000c44c000000000000070000007707007077070070700565500004f55000049440049444444
000000c4ff4c0000aa61111111111ddd9861111111111ddd000000c4ff4c00000000070000000000000000000000000000565500004944000049440000008000
00000111111d0000a961ddddddddd1119861ddddddddd11100000111111d00000007007000000000000000000000007000565500004945000049440000002000
00001118b111d000000dddddddd00000a90dddddddd00000a9001118b111d0000070000000000000000000000000000700565500004944000049440000005000
9961111111111ddd00ddddddd0000000a0ddddddd00000009861111111111ddd77089a7708089a7780889a7708089a7700565500005f44000049440000005000
9861ddddddddd1110dddddd0000000000dddddd0000000009861ddddddddd1117770000000000000000000000000000700565500005f55000049440000005000
000dddddddd0000000000000000000000000000000000000a90dddddddd000000007000000000000000000000000007005655550049444400494444000494400
00ddddddd00000000000000000000000000000000000000000ddddddd00000000000700000000000000000000000000005655550049455500494444004945550
0dddddd000000000000000000000000000000000000000000dddddd0000000000700000700000000000000000000000056555555494444444944444449444444
0000000080022000000a2000800a2000000a200000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee008000800000eeeeeeeeeeee00
00000000002aa20080aa280800aa280080a228080eeeeeeeeeeeeeeeeeee222eeeeeeeeeeeeeeeeeeeeeeeeeee2222eeeeeeeee00008e8000eeeeeeeeeeeeee0
228a0000002aa20800a2280000a2280800228800ee2222eee222222eeee22422ee2eeeeeee2eeeeeeee2ee2ee222422e22222eee008ee808ee2222ee22222eee
2228a0a002aaaa200aa2288002228e8008e8ee80e222222222224422e2224542e222eee2e2222e2eee22ee22224244222222222e08eeee80e22222222222222e
228a0000e2aaaa2e2a228e8ee828ee8ee8eeee8ee244444522424422224244422242e222224422222222ee2224424442f444442ee8eeee8ee2444222f444442e
000000000e2222e00228e8e00e8ee8e00e8ee8e00204444454444f444442444424422242244444424542222444444f444444442e0e8ee8e0e244f44444445020
0000000000eeee0000eeee0000eeee0000eeee0000054f44444644444644444f4f4224444f44444444444224444544444454442e00eeee00e254444444540020
0000000000022000000220000002200000022000000044464f444445444445444444444644444446f44544464f4444466444442e00022000e244446464440000
000000000b0000304000000000ee440000022e000000444545444444444444444444444444444644444444f4444444444444442e00e22e00e244444444444000
000000000bb00030004445000ee44440000220000000f46444444f4444544f4444f44444446444444444444444464f44444f422e22022000e224446446445500
228aa0000bbb003004e424200e64454000022000000544444444444444444444444444644444445444444444454444444444422e2e222000ee24444444445500
2228aa0a0bbbb03004444220044422200002e022000554444544555444444444464444444f4444444f44644444444ff4454442ee02e22022ee24f44444444400
228aa0000bbbb0300224222002222200000222e200055444444455544444444444222244422222244444444444444ff4444442ee002222e2ee244454f4444400
000000000bbb0030022224200222004200022e2000004f4444f4444444f44422222ee22222eeee222244444444f444444444622e22022e20ee24444444445000
000000000bb00030002522000022042200e2220000004446444444444444442eeeeeeeeeeeeeeeeee2444454444444454444422e2e222200e224644444540000
000000000b00003000000000000000000002200000004544454464444444642eeeeeeeeeeeeeeeeee2444444454444444544442e02e22022e244444464440000
00000000bbbb0000000e420000ee440000022e0000004445464444444444442e00022e0000e22000e2444444444444444444442ef4444544e244444444444000
000000000bbb3300000462000ee46440220220000004444444444544444f442e2202200000022e00e24444644f4444444544442e44244446e244444446440000
228aaa0003bb033000022200ee4444222e2220000044f444444444444444442e2e22200022022022e24444444444464444444422422242222244446444400000
2228aaa0030b003000000000e4444e2202e2e00000444444455446444544442e02e220222e2222e2e244f44444446c644444444442e242e244f4444444400000
228aa000030000300e2000004464222200222000004644f4455444444444442e002222e202e22e20e244445444446c644444444422e222e24444445444400000
00000000033003300220ee20444222e200022e0000444444455444f44444442e00022e2000222200e244444444444644f44444442eee22e24444444445500000
00000000003333000000e420052e222000e2200000055464444444444444442e0002220000022000e24464444544444444444444eeeee2e244544f4445500000
000000000000000000002220002222000002200000005444454464444544442e0002200000022000e2444444444444f4445444f4eeeeeeee4444444444440000
0000000020000008000000e20000000000022e000000444f454444644444442eeeeeeeeeeeeeeeeee2444444444444444444542e444f4544e246444444444000
000000000800002000000022000e40000002200000004444444444444544442eeeeeeeeeeeeeee2ee2444444444444f44544442e64444444e244444446444000
228aaa0a0080020000e4000000e4440000e2200000006f444444444444444422ee2eeeeee22ee22e22444464464444444446442e44442224e244446444444000
2228aa00000820000e4440000e4464200002e0000000444444444f4444444444e222eee22222e22244f44444444546644444442e22242e24e24f444444454000
228aa0a000028000e644420004444220000220000000445544f44444444444442242e2222442e24444444454444446644444422e2e222e22e224445444440000
0000000000200800444522000054220000022e000000045544445444f444444424422242444222444444444444444444222222ee2ee2eee2ee22222245500000
0000000002000080044220000002200000e220000000004444555544444444444f4224444f44544444544f4444f44454eeeeeeeeeeeeeeeeeeeeeeee45500000
00000000800000020022000000000000000220000000000445555544445444f444444446444444464444444444444444eeeeeee0eeeeeeee0eeeeeee40000000
c2000000f2e494b4c4d500d50000000000000000000000000000000000000000000000000000000000000000e5b6b6c50000e7d7d695d7d785d6d7c700000000
e5b6b6c500000000008100000000000000262726350026002600002726000026003526000026260036002635352600253625000000e565666566b7b5c5000000
c30000e494a765b777a494f40000000000000000000000000000000000000000000000000000000000000000e7d7d6c700000000000000000000000000000000
e7d7d6c700000000000000000000000000360035263526000026002626002600260000360000260026000035003726272637000000e565b765b56567c5000000
6474a4a77595d6d785a5b677c4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000e4c40000000000000026352600260026262600350026002726002635003600352635003626362635000000e4a766656567b765c5000000
65b6b6b6c581818181e5b56577b4c4000000000000000000000000000000000000000000000000000000000000000000d40000c1c0d0e0e0d0c0e1c0d0e0e0e0
e0d0c0d10000008100e7c700000000810000362635262725263526262636003526610026000026000026002626252637000000e4a765b7b56565b766c5000000
b6b5b6b5c581818181e5b6b7b6b577c400000000000000008100000000000000000000000000000000d4000000000000860000c2000000000000e20000000000
810000e200000000000000000000000000000026262625263525360000262700262600260026003626002536263625000000e4a7b765666567666565c5000000
65b6b56577748797a4a766b565b7b67764c4000000000000000000000000000000000000000000000045000000810000460000c2e4a4b4c40000d20000d40000
000000e2f1e49474a484c40000e4a4b4c40000002636263726272637262600003626260025362626372627263700000000e4a76565b765b56565b766c5000000
65b665b7b6b7676566b767b5b6b565b7b5657484c40000e4b494c4000000000000000000000000000046000000000000d50000c2e5b6b6c50000d200004700e4
a4b4c4d2e4a7b76766b577c400e5b6b6c500000000002526362635262526262625352626272637262536263500000000e4a76566b56765b767656665c5000000
b6b6b575d795d785d6d685d6d7d68595a567b767c50000e5b7657774c4f3000000d4000000000000004754847464a4b4c400f1c2e7d7d6c70000e281004500e5
b6b6c5d2e567b56665b767c500e7d7d6c7000000000000252637263526272536263626362635262527263700000000e4a765b7656665b56565b76567c5000000
b56575c7000000000000000000000000e7a565b5c50000e56766b6657784c4000045000081000000004755b56665b7b577a4f4c2000000000000e300f3d500e7
d7d6c7c2e5b766b7b665b7c5000000000000f100000000000026352637262726e4a4b4c437262536263500000000e4a7b56665b565b76565b7656666c5000000
b6b6c50000006100000000000000000000e7a5b6c50000e5b565b566b56577c40047000000f1000000d55667b7656665b765f5c20000d40000e4a4a4a4c40000
000000d2e7a565b5656675c700000000e4748494b4c400000000002526362635e5b6b6c5263626352636000000e4a7b7666665b7b56567b56565b765c5000000
b566f5000000000000000000000000000000e7a5c50000e5b6b5b765b667b677c4d500e4a4b4c40000e4a765b565b5b665b5f6c200004600e4a765b56577c400
000000c200e7d685d795c70000000000e567b5676677c4000000000036263726e7d7d6c72726272536000000e4a7b66565b565b56665666565b56566c5000000
66b6f600000000000000000000000000000000e5c50000e5676566b665b5b76777f400e5b6b6c50000e5b5b76765b7b56667f5c20000d5e4a7b566b766b577c4
000000c1c0d0d0e0e0e0e0e0d0d0c0d1e5656665b7b577c400000000003526272626352636262635000000e4a766656566666567656665b5b76565b5c5000000
6665c400810000000000000000000000000000e7c70000e5b5b7b5b7b56566b765f500e7d7d6c70000e5b765b5b765b765b5f6c2000054a76567b7b665b76577
f40000d200d4000000000000000000e2e565b7b66765b677c40000000000000000000000000000000000e4a7656765b56565b6656766b5656566b565c5000000
b566c50000008100000081000000000000000000000000e5b6666567b765b66566f600000000000000e566b6666566656765c5c200005565b76565b56766b565
f500f1d300d5000000000000000000e2e567b5656665b56665c4f30000000000000000000000000000e4a7676565666665676565b5656765b5656765c5000000
66b6c58100810000810000000081008100008100000000e5b565b5b766b666b575f6c1c0d0e0d0c0d1e565b76567b7b565b7c5c20000566766b56665b765b666
f600e4a4b4c4000000000000000000e2e565656667666665b5656494748494947464847484a484a474e665666567b565b5b7b56565b76665b7656675c7000000
85a57784a4b4648494c400810000000081000000008100e5b7b6666575d685d7c700c2d400000000d2e785d6a5656575d695c7c200005766b5b665b7b567b565
f700e5b6b6c500000000d481000000e2e7a56565b5656766656665b56667656665656665676566656566b56565b765b7656567b765b565b7656675c700000000
00e78585a5b6b566b5c500008100810000008100000000e5b575d6d7c70000000000c24500000000c2000000e785d7c7000000c200d400e7a5b766b5666675c7
0000e7d7d6c700000000d500000000e200e7a5666566b7666565b565b7656665656665b56665b566656665656565b56565b565676565b5656675c70000000000
00000000e7858585a57784a4b464849484a4b464849474a7d7c70000000000000000c29681000000c20000d400000000000000c281960000e7a567666575c700
000000000000000000e4a4b4c40000e20000e7a565656665b5656765b56566b76565666566656565656567b7b56565b76765b56565b7656575c7000000000000
000000000000d400e7d6d785d785d695d7d68595d695d6c700000000000000000000c3d500000000c200004700000000000000c300d5000000e785d7d6c70000
000000000000000000e5b6b6c50000e2000000e7a565676666b765666565b56565b56565b76565b5b6b5656665b7b565b7b565b765676575c700000000000000
00000000000047000000000000000000000000000000000000000000000000000000e4a4b4c40000d281009600000000d40000e4a4b4c4000000000000000000
d40081000000000000e7d7d6c70000e200000000e7a5656566666565b565656665656665b56665666565b765b7656565b5656665b56575c70000000000000000
0000000081009600000000000000000000000000000000000000000000d481000000e5b6b6c50000d30000d500000000450000e5b6b6c500000000d400000000
d5000000000000d400000000000000e20081d40000e7a56567656566656665b7666565b56565666565b566656665b7656565b7b56575c7000000000000000000
000000000000d500000000000000000000000000000000d40000000000d500000000e7d7d6c70000e4a4b4c400000081460000e7d7d6c7000000819600000000
e4a4b4c40000004500000000000000e20000d5000000e7a56565666667656665656665656566b76565656565b765b565b76765b775c700000000000000000000
0054847464a4b4c400000000d40000000081d4000000004700000000e4a4b4c40000000000000000e5b6b6c500000000d500000000000000000000d500000000
e5b6b6c50000009681000000000000e2e4a4b4c4000000e7a5b56565656765b56565b765666565656665b5666565666565666575c70000000000000000000000
6155b56665b7b577a4f40000460000000000d5000000008681000000e5b6b6c50000000000000000e7d7d6c70000e4a4b4c400000000000000e4a4b4c4000000
e7d7d6c7000000d50000000000d400e2e5b6b6c500000000e7a5b5676665666565b56665666565656665b765656565b7656575c7000000000000000000000000
005667b7656665b765f5000045810000e4a4b4c4000000d500000000e7d7d6c70000000000000000000000000000e5b6b6c500000000000000e5b6b6c5000000
000000000000e4a4b4c40000004500e2e7d7d6c70000000000e7a566b7b56565676565666565676566656665676566b5b775c700000000000000000000000000
e4a765b565b5b665b5f60000d5000000e5b6b6c50000e4a4b4c40000000000000000000000000000000000000000e7d7d6c700000000000000e7d7d6c7000000
000000000000e5b6b6c50000008600e200000000000000000000e7d685d7d685958595d7d6d7d69585d6d79585d6d7d6d7c70000000000000000000000000000
e5b5b76765b7b56667f500e4a4b4c400e7d7d6c70000e5b6b6c50000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000e7d7d6c7000000d500e3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5b765b5b765b765b5f600e5b6b6c500000000000000e7d7d6c70000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e4a4b4c4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e566b6666566656765c500e7d7d6c700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e5b6b6c5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e565b76567b7b565b7c5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e7d7d6c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e785d6a5656575d695c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000e785d7c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
00000000000000000000000001010008000000000000100010100000090909080000000000000000000000000101010800000000000000002020202001010108a0c0c0c0c00303030303030303c00303a000c3c3800303030303030303800303a000c3c3800303038080030303030303a000c3c3800303030303030303030303
0707020702000000000000070000000000070702020000000000000100000000000101010100000000000001000000000001010101000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c000000000000000000003f4e4c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c0000000000000000004e4a6e6c4c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c00000000000000004e6e7b566b6c4c001f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a464748494a4b48476e56767b665b6c4b4a4f1c0c0d0d0c1d1f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56567b765b567b5b565b5b665b76667b665b5f2c000000002d45474c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
567b5b56567b7b56567b567b66565b565b666f3c180000002c75566c4c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
577e587d6d58597d6d6d586d7d6d7d5876566c4b794c00002c00555b6c4c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c00000000000000000000000000000065767b5b7b5c00002c00655b666c4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c000000000000000000000000000000656666765b5c00002d00555b66666c4c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c000000000000000000000000000000007556667b5c00002c0065567b56666c4c0000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c0000000000000000000000000000000000755b665c00163c007556667b76566c4c1f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c000000000000000000000000000000000000656677794b78794c565b667b5b7b6c4f1c0c1e0c1e0c1e0c0d0e00000e0d0c1e0c0d0e0e0d0c1e0c0c1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e4a49484c0000000000000000
2c00000000000000000000000000000000000000755b7b6b5b565b565b5b765b565b5f2c002d002d002d00000000000000002d0000000000002d00002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e565666774c00000000000000
2c00000000000000000000000000000000000000007e597d597d586d7b7b7b565b566f2c002e002d002d00000000000000002e0000000000002e00002c0000000000000000000000000000000000000000000000000000000000000000000000000062000000000000000000000000000000005e56665b56774c000000000000
2c000000000000000000000000000000000000000000000000000000757b7b7b565b7f2c002e002e002d00000000000000002d0000000000002e00002c0018000000000000000000000000000000000000000000000000000000000000000000000000620000006200006200000062000000007e5a56567b66774c0000000000
2c00000000000000000000000000000000000000000000000000000000557b7b5b67002c002d002e002e00000000000000002e0000000000002d00002d1f0000000000000000000000000000000000000000006200000000620000000000000062620000000000620000620000006200000000007e5a7b567656774c00000000
2c00000000000000004d00000000000000000000000000000000000000657b7b7b5c003c003e003d003d00000000000000002d0000000000002d00003d4e4c0000000000000000000000000000000000000000620000000000620000006200000000000000006200006200000000620000000000005e7656665b66774c000000
2c00000000000000007400000000000000000000000000000000000000007e7d6b6c4b4a464b49464a494f000000000000002e0000000000002e004e4a6e6c4c00000000000000000000000000000000000062530000000062626200000000000062000000000000000062006200006300000000005e566656667b565c000000
2c000000000000000068004d0000000000000000000000000000000000000000655b5b5b66565b567b5b5f000000000000003e0000000000003e4e6e7b566b5c00000000180000000000000000000062000072625300000000006200006200000000000000000062000062000072000052000000005e5b56567b56565c000000
2c00000000000000006400740000000000000000000000000000000000000000555b56576d587d5a567b6f00001800000045464748494a4b48476e567657587c00180000000000000000000000000062630000536262000000620000006200000000620000000000620000720053625372630000005e567b565666665c000000
2c00160000000018007400540000000000000000000000000000000000000000007e7d7c0000007e7d6d7f00000000000055567b765b567b5b565b5b577c0000000000004e4c00000000000000000000626272625362000000006200006200000000006200006200006200006200626353005200005e5666566656565c000000
2c000000000000000068007400000000000000000000000000000000000000000000000000000000000000004e4a4b4c00657b5b56567b7b56567b577c0000004e4a4b4c7e7c00000000000000000000006300536262000000006200000062006200000072000053000072006200620062626300005e56767b5676565c000000
__sfx__
0010200a0001001010010100101001010010100101001010020100301004010040100401004010040100401004010040100401003010020100101001010000100001000010000100001000010000100001000010
0001000003010060100a0100c0100e01010010110101301014010160101701018010190101a0101b0101c0101d0101d0101e0101e0101f0101f01020010210102201023010240102501027010290102c01030010
000100003f0603d0603b060380603606034060310602f0602c0602a060280602606023060210601f0601d0601b06019060170601506013060110600f0600d0600b06009060080600606005060030600106000060
00020000060100b0100e010110101301014010150101401014010120100f0100d01012010180101c0101e0101f0101f0101e0101c01017010120101701020010290102e0103201033010320102f010290101d010
00100000237102a7303475039770370003e0002c700087000570019000100000a000010000100001000020000200002000010000000001000080000c00012000150000c000090000700002000010000000000000
00100000025500455005550065500455001550006100061003610095300e550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000020100201002010020100201002010020100501007010090100a0100a0100a0100a0100a0100a0100a010090100801007010050100401003010020100201002010020100201002010020100201003010
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000450003500095000d5000b500025001d5001d5001b500195001650013500115001050010500125001750021500285002b5002e50030500305002e5002b500285002650023500215001f5001e5001d500
__music__
04 00010203
00 410a4344

