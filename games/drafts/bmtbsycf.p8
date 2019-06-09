pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- run with: ./pico-8/pico8 -run ./bmtbsycf.p8 -desktop . -windowed 1

function _init()
   caabb_0088 = aabb_init(0,0,8,8)
   caabb_1616 = aabb_init(0,0,16,16)
   caabb_4073 = aabb_init( 4, 0, 7, 3 )
   caabb_4374 = aabb_init( 4, 3, 7, 4 )
   caabb_1177 = aabb_init( 1, 1, 7, 7 )
   caabb_1478 = aabb_init( 1, 4, 7, 8 )
   caabb_2068 = aabb_init( 2, 0, 6, 8 )
   caabb_4n1139 = aabb_init( 4, -1, 13, 9 )
   cv2_44 = v2init(4,4)
   init_archetypes()
   game_state = "menu"
   game_t = 0
   game_difficulty = 0
   debug_mode = 2
   init_persistence()

   sfx(2,0)

   messages = {}
end

function init_persistence()
   reload() --resets map/progress
   game_is_skub_alive = true
   game_is_flab_alive = true
   game_is_finb_alive = true
   game_num_orbs = 0
   game_num_orbs_placed = 0
   game_has_rose = false
   game_has_key = false
   game_has_sword = false
end

function _update()
   game_t += 1
   g_rnd_2 = flr(rnd(2))
   if game_state == "menu" then
      game_state = "play"
      init_game()
      player.health = a_player.table_health[game_difficulty+1]
      game_t = 0
   elseif game_state == "play" then
      update_player()
      update_enemies()
      update_bullets()
      update_vfx()
   end
end

function _draw()
   cls()
   pal()
   local table_text
   if game_state == "menu" then
      map( 16, 32, 0, 0, 16, 16, 0x7f )
   elseif game_state == "play" then
      draw_game()
   end
   for s in all(table_text) do
      if s[1] == game_t then
         add_message(s[2])
      end
   end
   for m in all(messages) do
      if m.t > 0 then
         print( m.text, 64-(2*#m.text), 128*(m.t/256), 3 ) --4*len/2 = 2*len
         m.t -= 1
      else
         del(messages,m)
      end
   end
end

function draw_game()

   local room_tile_x = level.room_coords.x * 16
   local room_tile_y = level.room_coords.y * 16

   --bckgnd
   map(room_tile_x,
       room_tile_y,
       0,0,16,16,
       0x7f )

   for e in all(room.enemies) do
      local e_p1 = e.p1
      if e.hit_timeout % 2 == 0 then
         local act = e.action
         while act.sub != nil do
            act = act.sub
         end
         local anm = e.a.table_anm[act.anm_id]
         local anm_t = 1+act.t%#anm.k
         if anm.no_cycle then
            anm_t = min(1+act.t,#anm.k)
         end
         local size_x = 1
         local size_y = 1
         if e.a.is_large != nil then
            size_x = 2
            size_y = 2
         end
         spr( anm.k[ anm_t ],
              e_p1.x, e_p1.y,
              size_x, size_y,
              e.sign<0 )
      end
   end

   -- player
   if player.inv_t % 2 == 0 then
      local anm = g_anim[player.state]
      if game_has_sword then
         anm = g_anim[player.state+8] --todo this needs to be fixed
      end
      local anm_t = 1+player.t%#anm.k
      if anm.no_cycle then
         anm_t = min(1+player.t,#anm.k)
      end
      spr( anm.k[anm_t],
           player.p1.x, player.p1.y,
           1,1,
           player.sign<0 )
   end

   -- sword
   if game_has_sword then
      local anm = g_anim[player.state+8] --todo this needs to be fixed
      local anm_t = 1+player.t%#anm.k
      spr( anm.k[anm_t]-1, -- sword sprite left to corresponding player sprite
           player.p1.x - player.sign*8, player.p1.y,
           1,1,
           player.sign<0 )
   else
      --standalone sword
      spr( 112, --todo explicit frame could be constant or short anim showing "magic"
           sword.p1.x, sword.p1.y,
           1,1,
           sword.sign<0 )
   end

   for b in all(room.bullets) do
      local anm = b.a.table_anm[b.anm_id]
      spr( anm.k[1+b.t%#anm.k],
           b.p1.x, b.p1.y,
           1,1,
           b.sign<0 )
   end

   for v in all(room.vfx) do
      spr( v.anm.k[1+v.t%#v.anm.k],
           v.p.x, v.p.y,
           1,1,
           v.sign<0 )
   end

   --overlay
   map(room_tile_x,
       room_tile_y,
       0,0,16,16,
       0x80 )

   if debug_mode > 0 then
      local colors = {10,11,8,12}
      for e in all(room.entities) do
         local a = e.a
         local e_p1 = e.p1
         local boxes = {a.cvisualbox,a.cmovebox,a.cdamagebox,a.cattackbox}
         local box = boxes[debug_mode]
         local col = colors[debug_mode]
         if box != nil then
            box = aabb_apply_sign_x(box,e.sign)
            if debug_mode == 2 and e.on_ground != nil and e.on_ground then
               col = 2
            end
            rect( e_p1.x + box.min.x,
                  e_p1.y + box.min.y,
                  e_p1.x + box.max.x-1,
                  e_p1.y + box.max.y-1,
                  col )
         end
      end
   end
end

function uncompress_anim( archetype )
   for id,anm in pairs(archetype.table_anm) do
      local k = anm.k
      if type(k[1]) != type(1) then --k=seq of spans {frame,count}
         anm.k = {}
         for span in all(k) do
            for f=1,span[2] do
               add( anm.k, span[1] )
            end
         end
      end
   end
end

function add_message( _text )
   add( messages, {t=256, text=_text} )
end

function init_archetypes()

   a_level_cnumrooms = v2init( 8, 3 )
   a_level_cgravity_y = 0.5

   local _table_anm =
      {
         idle  = {k={ {16,8}, {17,8} }},
         walk  = {k={ {18,6}, {19,3}, {20,6}, {21,3} }},
         jump  = {no_cycle=true,k={ {22,4}, {22,4} }}, --todo add frame
         fall  = {k={ {23,4}, {23,4} }}, --todo add frame
         shi   = {k={ {16,8}, {17,8} }},
         shj   = {k={ 12,12,13,13  }},
         shjb  = {k={ 14,14,15,15 }}, --same #frames as "shj",
         hit   = {no_cycle=true,k={ {23,10}, {23,30} }},
         hitb  = {no_cycle=true,k={ {23,4}, {23,4}, {23,4} }},
         idle_sword = {k={ {2,8}, {4,8} }},
         walk_sword = {k={ {6,6}, {8,6}, {10,8} }}
      }
   a_player =
      {
         table_anm  = _table_anm,
         --cmovebox   = caabb_1177, --caabb_0088 important: must be smaller than 0088 to fit in single-block holes!
         cmovebox   = caabb_0088, --important: must be smaller than 0088 to fit in single-block holes!
         cdamagebox = aabb_init( 2, 1, 6, 7 ),
         cattackbox = nil,
         cspeed     = 1,
         cmaxvel    = v2init( 5, 5 ),
         table_health = {-1,5,3}
      }
   uncompress_anim( a_player )
   -- indexed player anims
   g_anim = {}
   add( g_anim, _table_anm["idle"] ) --1
   add( g_anim, _table_anm["walk"] ) --2
   add( g_anim, _table_anm["jump"] ) --3
   add( g_anim, _table_anm["fall"] ) --4
   add( g_anim, _table_anm["shi"] )  --5
   add( g_anim, _table_anm["shj"] )  --6
   add( g_anim, _table_anm["shjb"] ) --7
   add( g_anim, _table_anm["hit"] )  --8
   add( g_anim, _table_anm["idle_sword"] )--9
   add( g_anim, _table_anm["walk_sword"] )--10

   a_sword =
      {
         table_anm =
            {
               idle = {k={112}}
            },
         cmovebox   = caabb_0088,
         cdamagebox = nil,
         cattackbox = nil,
         cspeed = 0
      }

   a_spit =
      {
         table_anm =
            {
               move = {k={66}},
               hit  = {k={67,67,67}}
            },
         cmovebox   = caabb_4374,
         cdamagbox  = nil,
         cattackbox = aabb_init( 1, 3, 6, 4 ),
         cspeed = 3
      }

   a_flame =
      {
         table_anm =
            {
               idle = {k={ {245,3}, {246,3} }},
               move = {k={ {247,3}, {248,3} }},
               hit  = {k={ {249,3}, {250,3},
                           {245,5}, {246,5},
                           {245,5}, {246,5},
                           {245,5}, {246,5} }},
               burn = {k={ {249,3}, {250,3}, {247,3} }}
            },
         cmovebox   = caabb_0088,
         cdamagbox  = nil,
         cattackbox = aabb_init( 2, 4, 6, 8 ),
         cspeed = 1.5
      }
   uncompress_anim( a_flame )

   local a_skull_move_anm = {k={ {94,5}, {95,5} }}
   a_skull =
      {
         table_anm =
            {
               move = a_skull_move_anm,
               hit  = a_skull_move_anm,
            },
         cmovebox   = caabb_4374,
         cdamagbox  = nil,
         cattackbox = caabb_4073,
         cspeed = 2
      }
   uncompress_anim( a_skull )

   local a_skull2_idle_anm = {k={58,58,59,59}}
   a_skull2 =
      {
         table_anm =
            {
               idle = a_skull2_idle_anm,
               move = a_skull2_idle_anm
            },
         cmovebox   = nil,
         cdamagbox  = nil,
         cattackbox = caabb_4073,
         cspeed = 0.5
      }

   local a_wave_move_anm = {k={ {106,5}, {107,5} }}
   a_wave =
      {
         table_anm =
            {
               move = a_wave_move_anm,
               hit  = a_wave_move_anm
            },
         cmovebox   = caabb_4374,
         cdamagbox  = nil,
         cattackbox = caabb_4073,
         cspeed = 2.5
      }
   uncompress_anim( a_wave )

   a_caterpillar =
      {
         table_anm =
            {
               move = {k={ {48,6}, {49,6} }}
            },
         cmovebox   = caabb_0088,
         cdamagebox = caabb_1478,
         cattackbox = caabb_1478,
         cspeed = 0.5,
         chealth = 1,
         rtoff = v2init(0,-1)
      }
   uncompress_anim( a_caterpillar )

   a_caterpillar2 =
      {
         table_anm =
            {
               move = {k={50,50,50,51,51,51}},
            },
         cmovebox   = caabb_0088,
         cdamagebox = aabb_init( 0, 2, 8, 8 ),
         cattackbox = caabb_0088,
         cspeed = 1,
         chealth = 2,
         rtoff = v2init(0,-1)
      }

   a_saw =
      {
         table_anm =
            {
               move = {k={60,61,62,63}}
            },
         cmovebox   = caabb_0088,
         cdamagbox  = nil,
         cattackbox = aabb_init( 2, 2, 6, 6 ),
         cspeed = 1,
         rtoff = v2init(1,0)
      }

   a_stalactite =
      {
         table_anm =
            {
               idle = {k={78}},
               move = {k={78}},
               hit  = {k={79,79,79}}
            },
         cmovebox   = caabb_1177,
         cdamagbox  = nil,
         cattackbox = caabb_0088,
         cspeed = 5,
         rtoff = v2init(0,1)
      }

   a_grunt =
      {
         table_anm =
            {
               idle = {k={ {102,6}, {103,6} }},
               move = {k={ {105,4}, {104,4} }},
               attack = {k={ {105,8}, {106,6} }}
            },
         cmovebox   = caabb_0088,
         cdamagebox = caabb_0088,
         cattackbox = caabb_0088,
         cspeed = 1,
         chealth = 3,
         rtoff = v2init(0,-1)
      }
   uncompress_anim( a_grunt )

   a_cthulhu =
      {
         table_anm =
            {
               move   = {k={ {86,4}, {87,4}, {88,4}, {89,4} }},
               attack = {k={ {90,4}, {91,4} }}
            },
         cvisualbox = caabb_0088,
         cmovebox   = caabb_0088,
         cdamagebox = caabb_0088,
         cattackbox = caabb_1478,
         cspeed = 0.4,
         chealth = 2,
         cshootpos = v2init( 7, 0 ),
         rtoff = v2init(0,-1),
         cshoottype = a_spit
      }
   uncompress_anim( a_cthulhu )

   a_mouse =
      {
         table_anm =
            {
               move = {k={ {118,5}, {119,5} }}
            },
         cmovebox   = caabb_2068,
         cdamagebox = nil,
         cattackbox = nil,
         cspeed = 0.3,
         rtoff = v2init(-1,0)
      }
   uncompress_anim( a_mouse )

   a_bird =
      {
         table_anm =
            {
               idle = {k={ {120,4}, {121,4} }},
               move = {k={ {122,5}, {123,5} }}
            },
         cmovebox   = caabb_2068,
         cdamagebox = caabb_0088,
         cattackbox = caabb_0088,
         cspeed = 1.25,
         chealth = 1,
         rtoff = v2init(0,-1)
      }
   uncompress_anim( a_bird )

   a_arachno =
      {
         table_anm =
            {
               move = {k={ {124,5}, {125,5} }},
               jump_up = {k={126}},
               jump_down = {k={127}}
            },
         cmovebox   = caabb_2068,
         cdamagebox = caabb_0088,
         cattackbox = caabb_1478,
         cspeed = 0.75,
         chealth = 2,
         rtoff = v2init(0,-1)
      }
   uncompress_anim( a_arachno )

   a_teeth =
      {
         table_anm =
            {
               move = {k={ {68,3}, {69,8}, {70,3} }}
            },
         cmovebox   = caabb_0088,
         cdamagbox  = nil,
         cattackbox = aabb_init( 1, 2, 6, 8 ),
         cspeed = 1.5,
         rtoff = v2init(0,-1)
      }
   uncompress_anim( a_teeth )

   a_blast =
      {
         table_anm =
            {
               move = {k={1,1,2,2,3,3,2}},
               hit  = {k={4,4,5,5,6,6,7}}
            },
         cmovebox   = nil,
         cdamagbox  = nil,
         cattackbox = caabb_4374,
         cspeed = 4,
         cdamage = 1
      }

   a_rose =
      {
         table_anm =
            {
               move = {k={29,29,29,30,30,30}},
               hit  = {k={109,109}}
            },
         cmovebox   = nil,
         cdamagbox  = nil,
         cattackbox = caabb_4374,
         cspeed = 2.5,
         cdamage = 2
      }

   -- vfx
   a_death = {}
   a_death.table_anm = { hit = {k={74,74,75,75,76,76,77}} }

   -- collectables
   a_orb =
      {
         table_anm =
            {
               idle = {k={64,64,65,65}}
            }
      }

   --env
   a_torch =
      {
         table_anm =
            {
               idle = {k={201,201,202,202}}
            }
      }
end

-- game
function init_game()
   game_t = 0

   player =
      {
         a = a_player,
         state = 1,
         t = 0,
         p0 = v2init( 8, 86 ),
         p1 = v2init( 8, 86 ),
         sign = 1,
         v = v2zero(),
         on_ground = false,
         jump_s = 0,
         inv_t = 0,
         health = 0,
         weapon_a = a_blast
      }

   sword =
      {
         a = a_sword,
         state = 1,
         t = 0,
         p0 = v2zero(),
         p1 = v2zero(),
         sign = 1,
         v = v2zero(),
         on_ground = false,
         inv_t = 0,
         health = 0
      }

   level = {}
   level.room_coords = v2zero()

   room = new_room( level.room_coords )
end

-- player
function update_player()
   player.t += 1
   if player.inv_t > 0 then
      player.inv_t -= 1
   end
   player.p0 = player.p1
   local anm = g_anim[player.state]
   local state0 = player.state

   -- temp grab/release sword
   if game_has_sword
      and btnp(2) then --up
         game_has_sword = false
         sword.p1 = v2add( player.p0, v2init(-8*player.sign,0) )
         sword.sign = player.sign
   end
   if not game_has_sword
      and btnp(3) then --up
         game_has_sword = true
         --sword.p1 = v2sub( player.p0, v2init(-8*player.sign,0) )
   end

   -- on_ground / on_air
   if player.on_ground then
      -- if we were in jmp/shj/fall/hit or just finished
      -- uninterruptible shoot, back to idle, go to idle and process
      -- inputs from there
      if player.state==3    --jmp
         or player.state==4 --fall
         or player.state==6 --shj
         or player.state==8 --hit
         or (player.state==5 and player.t > #anm.k) --shi finished
      then
         player.state = 1
         player.v = v2zero()
      end

      -- idle/walk
      if player.state==1 then
         if btn(0) then
            player.state = 2
            player.sign = -1
            player.v = v2init(-player.a.cspeed,0)
         elseif btn(1) then
            player.state = 2
            player.sign = 1
            player.v = v2init(player.a.cspeed,0)
         end
      elseif player.state==2 then --walk
         if not (btn(0) or btn(1)) then
            player.state = 1
            player.v = v2zero()
         elseif
            (player.sign>0
                and (btn(0)
                        and not btn(1))
                or
                player.sign<0
                and (not btn(0)
                        and btn(1)))
         then
            player.sign = -player.sign
            player.v.x = -player.v.x
         else --reset walk speed, otherwise sometimes gets stuck in corners when revesing direction
            player.v = v2init(player.sign*player.a.cspeed,0)
         end
      end

      --jump
      if btnp(5) then
         player.state = 3
         player.v.y = -4
         sfx(11+g_rnd_2)
         if btn(0) then
            player.jump_s = -1
            player.v.x = -player.a.cspeed
         elseif btn(1) then
            player.jump_s = 1
            player.v.x = player.a.cspeed
         else
            player.jump_s = 0
            player.v.x = 0
         end
      end

   else --on_air

      -- idle,walk / jmp
      if player.state==1 or player.state==2 then
         -- go to fall
         player.state = 4
         player.v.x = 0
      elseif player.state==3 or player.state==6 then
         --jmp/shj
         if player.state==6 and player.t > #anm.k then --finished anim
            player.state = 3 --jmp
            player.t = #g_anim[3].k / 2
         end
         --horiz jmp vel constantly applied to allow jmp
         --over neighbour blocks
         player.v.x = player.jump_s * player.a.cspeed
      end

      -- allow air turn
      if (player.sign>0
             and (btn(0)
                  and not btn(1)))
         or
         (player.sign<0
             and (not btn(0)
                  and btn(1)))
      then
         player.sign = -player.sign
      end

   end

   --shoot
   if player.state!=5
      and player.state!=6
      and player.state!=10
      and btnp(4) then
      if player.state==3 then
         player.state = 6 --shjmp
      else --idle/walk
         player.state = 5 --shidl
         player.v.x = 0
      end
      new_bullet_blast( player.p0, player.sign )
   end

   local movebox = aabb_apply_sign_x(a_player.cmovebox,player.sign)
   local damagebox = aabb_apply_sign_x(a_player.cdamagebox,player.sign)
   local acc = v2init( 0, a_level_cgravity_y )
   local pred_vel = v2clamp( v2add( player.v, acc ),
                             v2scale(-1,a_player.cmaxvel),
                             a_player.cmaxvel )

   -- ccd-advance
   local p1
   local num_hits_map
   -- first handle collisions with solid map
   p1, num_hits_map, player.handled_collisions = advance_ccd_box_vs_map( player.p0, v2add( player.p0, pred_vel ), movebox, 1 )
   -- then handle collisions with damage map. important: we do it in a
   -- second pass to allow non-damage tiles to prevent the player from
   -- hitting damage tiles if already supported/deflected by
   -- non-damage ones
   local p2
   local hits_ccd = {}
   p2, num_hits_map, hits_ccd = advance_ccd_box_vs_map( player.p0, p1, damagebox, 2 )

   -- test enemies for collision, even if we've already hit map damage
   local hit_enemy = false
   for e in all(room.enemies) do
      if e.a.cattackbox != nil  then
         local attackbox = aabb_apply_sign_x(e.a.cattackbox,e.sign)
         local attack_aabb = aabb_init_2( v2add( attackbox.min, e.p1 ),
                                          v2add( attackbox.max, e.p1 ) )
         if ccd_box_vs_aabb( player.p0, p2, damagebox, attack_aabb ) != nil then
            hit_enemy = true
         end
      end
   end

   -- test powerups/collectables
   hits_ccd = ccd_box_vs_map( player.p0, p2, movebox, 8 )
   for c in all(hits_ccd) do
      if mget(c.tile_j,c.tile_i) == 64 then
         game_num_orbs += 1
         mset( c.tile_j, c.tile_i, mget( c.tile_j, c.tile_i-1 ) )
         for e in all(room.entities) do
            if e.a == a_orb then
               kill_entity( e )
            end
         end
         sfx(9)
      elseif mget(c.tile_j,c.tile_i) == 42 then --rose
         game_has_rose = true
         mset( c.tile_j, c.tile_i, mget( c.tile_j+1, c.tile_i ) )
         player.weapon_a = a_rose
         sfx(9)
      elseif mget(c.tile_j,c.tile_i) == 71 then --key
         game_has_key = true
         mset( c.tile_j, c.tile_i, 0 )
         fset( 110, 0, false )
         sfx(9)
      -- elseif mget(c.tile_j,c.tile_i) == 45 then --broom
         -- game_has_broom = true
         -- mset( c.tile_j, c.tile_i, 0 )
         -- sfx(9)
         -- add_message("use broom with \x94")
      end
   end

   -- advance
   player.p1 = p2
   player.v = v2sub( player.p1, player.p0 )

   -- hits if !invulnerable
   if (hit_enemy or num_hits_map != 0)
      and player.inv_t == 0 then
      player.state = 8 --hit
      player.inv_t = 60
      --bounce along x, but do not turn player
      player.v = v2init( -player.sign * 1.5, -3 )
      if player.health > 0 then
         player.health -= 1
      end
      sfx(8)
   end

   -- check on ground for next frame using a shape-cast
   player.on_ground = false
   player.ground_ccd_1 = {}
   if player.v.y >= 0 then
      pred_vel = v2clamp( v2add( player.v, acc ),
                          v2scale(-1,a_player.cmaxvel),
                          a_player.cmaxvel )
      pred_vel.x = 0 -- y-only prediction??
      player.ground_ccd_1 = ccd_box_vs_map( player.p0,
                                            v2add( player.p1, pred_vel ),
                                            movebox,
                                            3 )
      for c in all(player.ground_ccd_1) do
         if c.normal.y < 0 then
            player.on_ground = true
            player.v.y = 0
         end
      end
   end

   -- reset time if state changed
   if player.state != state0 then
      player.t = 0
   end

   -- update-map
   local room_coords = level.room_coords
   local offset = 16*8
   if player.v.x > 0 and player.p1.x > offset - movebox.max.x and room_coords.x < a_level_cnumrooms.x-1 then
      room_coords.x += 1
      room = new_room( room_coords )
      player.p1.x = movebox.min.x
   elseif player.v.x < 0 and player.p1.x < movebox.min.x and room_coords.x > 0 then
      room_coords.x -= 1
      room = new_room( room_coords )
      player.p1.x = offset - movebox.max.x
   elseif player.v.y > 0 and player.p1.y > offset - movebox.max.y and room_coords.y < a_level_cnumrooms.y-1 then
      room_coords.y += 1
      room = new_room( room_coords )
      player.p1.y = movebox.min.y
   elseif player.v.y < 0 and player.p1.y < movebox.min.y and room_coords.y > 0 then
      room_coords.y -= 1
      room = new_room( room_coords )
      player.p1.y = offset - movebox.max.y
   end
   level.room_coords = room_coords

   --borders
   player.p1 = apply_borders( player.p1, movebox )
end

function advance_ccd_box_vs_map( p0, p1, box, flags )
   local d = v2sub( p1, p0 )
   local remaining_time = 1 --1 step remaining
   local collisions_ccd = ccd_box_vs_map( p0, p1, box, flags )
   local num_hits = 0
   local handled_collisions = {}
   while collisions_ccd != nil do
      local b_retest = false
      for c in all(collisions_ccd) do

         -- correct p0 if overlap
         if player.state == 10 then
            local tile_mid_y = 8*(c.tile_i - level.room_coords.y * 16) + 4
            local box_hs_y = 0.5 * (box.max.y - box.min.y)
            local diff_mid_y = p0.y + box.min.y + box_hs_y - tile_mid_y
            local depth_y = 8 - abs( diff_mid_y )
            if depth_y > 0 and depth_y < 3 then
               p0.y += sgn(diff_mid_y) * depth_y
            end
         end

         -- correct displacement
         local dn = v2dot( d, c.normal )
         if not b_retest
            and dn < 0
         then
            num_hits += 1
            add( handled_collisions, c )
            -- move up to toi
            p0 = v2add( p0, v2scale( 0.99*c.interval.min, d ) )
            -- clip interval
            local remaining_fraction = (1.0-c.interval.min) --interval [min..1] becomes new [0..1]
            remaining_time *= remaining_fraction
            -- correct displacement
            d = v2sub( d, v2scale( dn, c.normal ) )
            -- predict during remaining fraction along corrected displacement
            p1 = v2add( p0, v2scale( remaining_fraction, d ) )
            b_retest = true
         end
      end
      -- retest if required or flag for exit otherwise
      if b_retest and remaining_time > 0.01 then
         collisions_ccd = ccd_box_vs_map( p0, p1, box, flags )
      else
         collisions_ccd = nil
      end
   end
   return p1, num_hits, handled_collisions
end

-- rooms
function new_room( coords )
   kill_room()
   local r =
      {
         enemies = {},
         entities = {},
         zombies = {},
         bullets = {},
         vfx = {}
      }

   add( r.entities, player )
   add( r.entities, sword )
   -- temporal!!
   --process static map cells to create entities
   -- for j=0,15 do
   --    for i=0,15 do
   --       new_room_process_map_cell( r, j, i, coords.x*16 + j, coords.y*16 + i )
   --    end
   -- end

   --sfx
   sfx(-1,0) --stop last music
   if coords.x + coords.y == 0 then
      sfx(2,0)
   elseif coords.x == 7 and coords.y == 0 and game_is_skub_alive then
      sfx(19,0)
   elseif coords.x == 7 and coords.y == 1 and game_is_flab_alive then
      sfx(19,0)
   elseif coords.x == 0 and coords.y == 2 and game_is_finb_alive then
      sfx(22,0)
   end

   messages = {}

   return r
end

function kill_room()
   if room == nil then
      return
   end
   local f = function (e) if e.spawn_tile_value != nil then mset( e.spawn_tile_j, e.spawn_tile_i, e.spawn_tile_value ) end end
   foreach( room.zombies, f )
   foreach( room.entities, f )
end

function new_room_process_map_cell( r, room_j, room_i, map_j, map_i )
   local m = mget( map_j, map_i )
   local pos = v2init( room_j*8, room_i*8 )
   local e,a
   -- patrollers
   if m == 48 then
      a = a_caterpillar
   elseif m == 50 then
      a = a_caterpillar2
   elseif m == 86 then --cthulhu_patroller
      a = a_cthulhu
   elseif m == 118 then
      a = a_mouse
   elseif m == 68 then
      a = a_teeth
   end
   if a != nil then
      e = new_entity( a, pos, new_action_patrol( pos, -1 ) )
   else
   --idlers
      if m == 245 then --flame on ground
         a = a_flame
      elseif m == 201 then
         a = a_torch
      elseif m == 64 then
         a = a_orb
      end
      if a != nil then
         e = new_entity( a, pos, new_action_idle() )
      else
         -- misc
         if m == 124 then
            e = new_entity( a_arachno, pos, new_action_patrol_and_jump( pos, -1 ) )
         elseif m == 90 then --cthulhu_shooter
            e = new_entity( a_cthulhu, pos, new_action_shoot( 30, "horizontal" ) )
         elseif m == 102 then
            e = new_entity( a_grunt, pos, new_action_wait_and_ram() )
         elseif m == 120 then
            e = new_entity( a_bird, pos, new_action_wait_and_fly(60) )
         elseif m == 60 then --saw l2r
            e = new_entity( a_saw, pos, new_action_oscillate( pos, v2init(1,0), 24, 300 ) )
         elseif m == 63 then --saw r2l
            e = new_entity( a_saw, pos, new_action_oscillate( pos, v2init(-1,0), 24, 300 ) )
         elseif m == 78 then
            e = new_entity( a_stalactite, pos, new_action_wait_and_drop() )
         elseif m == 73 and game_num_orbs_placed < game_num_orbs then
            mset(map_j,map_i,72) --install orb
            game_num_orbs_placed += 1
         elseif m == 93 and not game_is_flab_alive then
            e = new_entity( a_skull2, pos, new_action_wait_and_fly(128) )
            --idlers
         elseif m == 247 then --suspended flame
            e = new_entity( a_flame, pos, new_action_idle() )
            e.action.anm_id = "burn" --hack
            e.action.t = flr(rnd(17))
         end
      end
   end

   -- init common, add enemy
   if e != nil then
      e.health = e.a.chealth
      e.hit_timeout = 0
      add( r.enemies, e )
      add( r.entities, e )
      --save spawn pos, replace bckgrnd with tile at e.a.rtoff
      local a = e.a
      if a.rtoff != nil
         and a != a_orb
      then
         e.spawn_tile_i = map_i
         e.spawn_tile_j = map_j
         e.spawn_tile_value = m
         mset( map_j, map_i, mget( map_j+a.rtoff.x, map_i+a.rtoff.y ) )
      end
   end
end

-- enemies
function new_entity( _archetype, _pos, _action )
   return { a = _archetype,
            action = _action,
            p0 = _pos,
            p1 = _pos,
            sign = -1 }
end

function kill_entity( e )
   del(room.enemies,e)
   del(room.entities,e)
   add(room.zombies,e)
end

function update_enemies()
   for e in all(room.enemies) do
      if e.hit_timeout > 0 then
         e.hit_timeout -= 1
      end
      e.p0 = e.p1
      e.action = update_action( e, e.action )
      -- remove if !action or out (req 4 enemy-bullets)
      if e.action == nil or is_out( e.p1 ) then
         kill_entity( e )
      end
   end
end

-- actions
function new_action_idle()
   return { name = "idle", anm_id = "idle", t = 0, finished = false,
           update_fn = function (ent,act) return act end }
end

-- move unconditionally
function new_action_move( target_pos )
   return { name = "move", anm_id = "move", t = 0, finished = false,
            p_target = target_pos,
            update_fn = update_action_move }
end

-- ballistic projectile
function new_action_particle( _v, _a )
   return { name = "part", anm_id = "move", t = 0, finished = false,
            vel = _v, acc = _a,
            update_fn = update_action_particle }
end

function new_action_hit()
   return { name = "hit", anm_id = "hit", t = 0, finished = false,
            update_fn = update_action_hit }
end

-- shoot with cooldown
function new_action_shoot( _timeout, _type )
   return { name = "shoot", anm_id = "attack", t = _timeout-1, finished = false,
            timeout = _timeout,
            type = _type,
            update_fn = update_action_shoot }
end

-- move on ground, stop at target/wall/cliff/border
function new_action_move_on_ground( target_pos )
   return { name = "mong", anm_id = "move", t = 0, finished = false,
            p_target = target_pos,
            update_fn = update_action_move_on_ground }
end

-- move on ground, stop at target/wall/cliff/border
function new_action_jump_on_ground( target_pos )
   return { name = "jong", anm_id = "jump_up", t = 0, finished = false, first = true,
            p_target = target_pos,
            update_fn = update_action_jump_on_ground }
end

-- patrol in flat area, stop and turn at wall/cliff/border
function new_action_patrol( start_pos, sign_x )
   return { name = "ptrl", anm_id = "move", t = 0, finished = false,
            sub = new_action_move_on_ground( v2add( start_pos, v2init( 128*sign_x, 0 ) ) ),
            update_fn = update_action_patrol }
                 end

-- wait on spot, ram to player if on same y-level, accessible & in range
function new_action_wait_and_ram()
   return { name = "w&r", anm_id = "idle", t = 0, finished = false,
            sub = new_action_idle(),
            update_fn = update_action_wait_and_ram }
end

-- wait on spot, fly to player when in radius
function new_action_wait_and_fly( _radius )
   return { name = "w&f", anm_id = "idle", t = 0, finished = false,
            sub = new_action_idle(),
            radius = _radius,
            update_fn = update_action_wait_and_fly }
end

-- wait on spot, fall on player when on same y-level
function new_action_wait_and_drop()
   return { name = "w&d", anm_id = "idle", t = 0, finished = false,
            sub = new_action_idle(),
            update_fn = update_action_wait_and_drop }
end

-- wait on spot, fly to player when in radius
function new_action_patrol_and_jump( start_pos, sign_x )
   return { name = "p&j", anm_id = "move", t = 0, finished = false,
            sub = new_action_patrol( start_pos, sign_x ),
            update_fn = update_action_patrol_and_jump }
end

-- oscillate from midpos along dir with sinusoid of given amplitude (pixels) and period (frames)
function new_action_oscillate( mid_pos, _dir, _amplitude, _period )
   return { name = "oscl", anm_id = "move", t = 0, finished = false,
            p_mid = mid_pos,
            dir = _dir,
            amplitude = _amplitude,
            period = _period,
            update_fn = update_action_oscillate }
end

-- linear vel along dir, sinusoid perpendicular to it
function new_action_sinusoid( _pos, _dir, _speed, _amplitude, _period, _phase )
   return { name = "sinu", anm_id = "move", t = 0, finished = false,
            start_pos = _pos,
            dir = _dir,
            normal = v2perp( _dir ),
            speed = _speed,
            amplitude = _amplitude,
            period = _period,
            phase = _phase,
            update_fn = update_action_sinusoid }
end

function update_action( _entity, _action )
   local act = _action
   act.t += 1

   if act.update_fn != nil then
      act = act.update_fn( _entity, _action )
   end

   if act != nil and act.sub != nil then
      act.anm_id = act.sub.anm_id
   end

   return act
end

function print_action( _action, _x, _y )
   if _action.sub == nil then
      print( _action.name, _x, _y )
   else
      print( _action.name.."/".._action.sub.name, _x, _y )
   end
end

function update_action_move( entity, action )
   if not action.finished then
      local diff = v2sub( action.p_target, entity.p1 )
      local dist = v2length( diff )
      if dist > entity.a.cspeed then
         entity.p1 = v2add( entity.p0, v2scale( min(entity.a.cspeed,dist)/dist, diff ) )
         entity.sign = sgn( diff.x )
      else
         entity.p1 = action.p_target
         action.finished = true
      end
   end
   return action
end

function update_action_particle( entity, action )
   action.vel = v2add( action.vel, action.acc )
   entity.p1 = v2add( entity.p0, action.vel )
   local movebox = aabb_apply_sign_x( entity.a.cmovebox, entity.sign )
   local map_collisions = ccd_box_vs_map( entity.p0, entity.p1, movebox, 5 )
   if #map_collisions > 0 then
      entity.p1 = v2add( entity.p0, v2scale( 1.01*map_collisions[1].interval.min, action.vel ) )
      return new_action_hit()
   else
      return action
   end
end

function update_action_hit( entity, action )
   if action.t == #entity.a.table_anm[action.anm_id].k then
      return nil
   else
      return action
   end
end

function projectile_apply_sign_x( p, sign_x, size_x )
   if sign_x < 0 then
      return v2init(size_x-p.x-8,p.y)
   else
      return p
   end
end

function update_action_shoot( entity, action )
   if action.t % action.timeout == 0 then
      local a = entity.a
      local st = a.cshoottype
      local pos = v2add( entity.p1, projectile_apply_sign_x( a.cshootpos, entity.sign, a.cvisualbox.max.x - a.cvisualbox.min.x ) )
      local diff = v2sub( player.p1, pos )
      local e = nil
      if action.type == "horizontal" then
         e = new_entity( st,
                         pos,
                         new_action_particle( v2init( entity.sign*st.cspeed, 0 ), v2zero() ) )
      elseif action.type == "straight" then
         local dist = v2length( diff )
         e = new_entity( st,
                         pos,
                         new_action_particle( v2scale( st.cspeed/dist, diff ), v2zero() ) )
      elseif action.type == "parabolic" then
         diff.y = 0 --temp: project on ground, otherwise it fails if player flies
         e = new_entity( st,
                         pos,
                         new_action_particle( compute_projectile_vel_45deg( diff, 0.125 ),
                                              v2init(0,0.125) ) )
      else --"sinusoid"
         local phase = 0
         if (action.t / action.timeout) % 2 > 0 then phase = 0.5 end
         e = new_entity( st,
                         pos,
                         new_action_sinusoid( pos, v2init( entity.sign, 0 ), st.cspeed, 10, 30, phase ) )
      end
      e.hit_timeout = 0
      e.sign = entity.sign
      add( room.enemies, e )
      add( room.entities, e )
      sfx(7)
   end
   return action
end

function update_action_move_on_ground( entity, action )
   if not action.finished then
      local movebox = aabb_apply_sign_x( entity.a.cmovebox, entity.sign )
      local p_forward
      local p_feet
      if entity.sign > 0 then
         p_forward = v2add( entity.p1,
                            v2init( movebox.max.x, 0.5*(movebox.max.y-movebox.min.y) ) )
         p_feet = v2add( entity.p1,
                            v2init( movebox.max.x-1, movebox.max.y ) )
      else
         p_forward = v2add( entity.p1,
                            v2init( movebox.min.x, 0.5*(movebox.max.y-movebox.min.y) ) )
         p_feet = v2add( entity.p1,
                            v2init( movebox.min.x+1, movebox.max.y ) )
      end
      local diff = v2sub( action.p_target, entity.p1 )
      local dist = v2length( diff )
      if is_solid( p_forward ) --hit wall
         or is_out( p_forward ) --hit border
         or not is_solid( p_feet ) --hit cliff
      then
         -- blocked
         entity.p1.x -= entity.sign
         action.finished = true
      elseif dist < entity.a.cspeed then
         -- success, closer than 1 timestep advance
         entity.p1 = action.p_target
         action.finished = true
      else
         -- advance
         entity.p1 = v2add( entity.p0, v2scale( min(entity.a.cspeed,dist)/dist, diff ) )
         entity.sign = sgn( diff.x )
      end
   end
   return action
end

-- solve for projectile |v0| thrown at 45 deg that hits target, no sign considered yet
-- todo no solution if target is above 45 deg, detect it and avoid jumping
function compute_projectile_vel_45deg( diff, acc_y )
   local t = sqrt( abs( 2 * (diff.y-diff.x) / acc_y ) )
   local cos45 = cos(0.125) --angle 0..2pi --> 0..1
   local speed = abs(diff.x) / (cos45*t) --speed to hit target at 45 deg angle
   -- compute vel vector from magnitude and direction with correct sign
   return v2scale( speed, v2init( sgn(diff.x) * cos45, -cos45 ) )
end

function update_action_jump_on_ground( entity, action )
   local acc_y = 0.5 * a_level_cgravity_y --0.5 slowdown over global acc to get slower trajectory
   local diff = v2sub( action.p_target, entity.p1 )
   if action.first then
      action.v = compute_projectile_vel_45deg( diff, acc_y )
      action.first = false
   elseif not action.finished then
      local dist = v2length( diff )
      action.v.y += acc_y
      local speed = v2length( action.v )
      if dist < speed then
         -- success, closer than 1 dt
         entity.p1 = action.p_target
         action.finished = true
      else
         -- todo this overshoots
         entity.p1 = v2add( entity.p0, v2scale( min(speed,dist)/speed, action.v ) )
         entity.sign = sgn( action.v.x )
      end
      if action.v.y > 0 then
         action.anm_id = "jump_down"
      end
   end
   return action
end

function update_action_patrol( entity, action )
   action.sub = update_action( entity, action.sub )
   if action.sub.finished then
      entity.sign = -entity.sign
      action.sub = new_action_move_on_ground( v2add( entity.p1, v2init( 128*entity.sign, 0 ) ) )
   end
   return action
end

function has_line_of_sight_horizontal( p1, p2 )
   if flr(p1.y) != flr(p2.y) then
      return false
   end
   hits_ccd = ccd_box_vs_map( p1, v2init(p2.x,p1.y), aabb_init(0,0,1,1), 3 )
   return #hits_ccd == 0
end

function has_line_of_sight_downwards( p1, p2 )
   if abs(p1.x - p2.x) > 8 then
      return false
   end
   hits_ccd = ccd_box_vs_map( p1, v2init(p1.x,p2.y),
                              aabb_init(0,0,1,1),
                              3)
   return #hits_ccd == 0
end

function update_action_wait_and_ram( entity, action )
   -- update sub
   action.sub = update_action( entity, action.sub )
   -- think
   if action.sub.name == "idle"
      and
      action.sub.t > #entity.a.table_anm[action.sub.anm_id].k --only replan after whole cycle
   then
      if has_line_of_sight_horizontal( v2add(entity.p1,cv2_44), v2add(player.p1,cv2_44) ) then
         action.sub = new_action_move_on_ground( player.p1 )
      end
   elseif action.sub.finished then
      --reached target, back to idle
      action.sub = new_action_idle()
   else
      --keep ramming
   end
   return action
end

function update_action_wait_and_fly( entity, action )
   -- update sub
   action.sub = update_action( entity, action.sub )
   -- think
   if action.sub.name == "idle"
      and
      action.sub.t > #entity.a.table_anm[action.sub.anm_id].k --only replan after whole cycle
   then
      if v2length( v2sub( player.p1, entity.p1 ) ) < action.radius then
         action.sub = new_action_move( player.p1 ) --flyto player
      end
   elseif action.sub.finished then
      --reached target, back to idle
      action.sub = new_action_idle()
   else
      --keep flying
   end
   return action
end

function update_action_wait_and_drop( entity, action )
   -- update sub
   action.sub = update_action( entity, action.sub )
   -- if it has hit the ground it may have disappeared, so return nil
   if action.sub == nil then
      return nil
   end

   if action.sub.name == "idle" then
      --fall if below
      if has_line_of_sight_downwards( v2add(entity.p1,cv2_44), v2add(player.p1,cv2_44) ) then
         action.sub = new_action_particle( v2zero(), v2init(0,a_level_cgravity_y) )
         sfx(10)
      end
   else
      --keep flying
   end
   return action
end

function update_action_patrol_and_jump( entity, action )
   -- update sub
   action.sub = update_action( entity, action.sub )
   -- think
   if action.sub.name == "ptrl"
      and
      action.sub.t > #entity.a.table_anm[action.sub.anm_id].k --only replan after whole cycle
   then
      if abs(player.p1.x-entity.p1.x) < 64
         and
         has_line_of_sight_horizontal( v2add(entity.p1,cv2_44), v2add(player.p1,cv2_44) ) then
         action.sub = new_action_jump_on_ground( player.p1 )
      end
   elseif action.sub.finished then
      --reached target, back to idle
      action.sub = new_action_patrol( entity.p1, entity.sign )
   else
      --keep ramming
   end
   return action
end

function update_action_oscillate( entity, action )
   entity.p1 = v2add( action.p_mid, v2scale( action.amplitude * sin( action.t/action.period ), action.dir ) )
   return action
end

function update_action_sinusoid( entity, action )
   entity.p1 = v2add( action.start_pos,
                      v2add( v2scale( action.t * action.speed, action.dir ),
                             v2scale( action.amplitude * sin( action.t/action.period + action.phase ), action.normal ) ) )
   return action
end

-- bullets
function new_bullet_blast( _p, _s )
   local b = { a = player.weapon_a,
               anm_id = "move",
               t = 0,
               p0 = _p,
               p1 = _p,
               sign = _s,
               v = v2init( _s*player.weapon_a.cspeed, 0 ) }
   add(room.bullets,b)
   add(room.entities,b)
   sfx(3+g_rnd_2)
end

function update_bullets()
   for b in all(room.bullets) do
      b.t += 1
      b.p0 = b.p1
      b.p1 = v2add( b.p0, b.v )

      local attackbox = aabb_apply_sign_x( b.a.cattackbox, b.sign )

      -- test against map
      --flags: 1 is_solid, 2 is_damage, 4 is destructible
      local map_collisions = ccd_box_vs_map( b.p0,
                                             b.p1,
                                             attackbox,
                                             5 )
      -- if map collision, save it and shorten predicted trajectory
      if #map_collisions > 0 then
         b.p1 = v2add( b.p0, v2scale( map_collisions[1].interval.min, b.v ) )
         -- unnecessary b.v = v2zero()
      end

      -- test against enemies
      local enm_collisions = ccd_box_vs_entities( b.p0,
                                                  b.p1,
                                                  attackbox,
                                                  room.enemies,
                                                  "cdamagebox" )

      -- if there's enemy collision, either there was no map collision
      -- or the enemy one happened first during the shortened
      -- trajectory, so in both cases we handle the enemy collision.
      local b_delete = true
      local b_fx = true
      if #enm_collisions > 0 then
         local e = enm_collisions[1].entity
         if e.a.cdamagebox != nil
            and e.health <= b.a.cdamage then
            kill_entity( e )
            new_vfx( a_death, e.p1, e.sign )
            sfx(6)
         else
            e.health -= b.a.cdamage
            e.hit_timeout = 4
         end
      elseif #map_collisions > 0 then
         local map_c = map_collisions[1]
         -- destructible scenario, flag 1<<2
         if band( map_c.flags, 4 ) != 0 then
            mset( map_c.tile_j, map_c.tile_i, 0 )
         end
      elseif not is_out(b.p1) then
         b_delete = false
         b_fx = false
      else
         b_fx = false
      end
      if b_fx then
         new_vfx( player.weapon_a, b.p1, b.sign )
         sfx(5)
      end
      if b_delete then
         del( room.bullets, b )
         del( room.entities, b )
      end
   end
end

-- vfx
function new_vfx( _a, _p, _s )
   local v = { anm = _a.table_anm["hit"],
               t = 0,
               sign = _s,
               p = _p  }
   add(room.vfx,v)
end

function update_vfx()
   for v in all(room.vfx) do
      v.t += 1
      if v.t >= #v.anm.k then
         del( room.vfx, v )
      end
   end
end

-- helpers
function clamp( v, l, u )
   return min( max( v, l ), u )
end

function is_out(p)
   return (p.x < 0 or p.x>127 or p.y < 0 or p.y>127)
end

function aabb_init( _x0, _y0, _x1, _y1 )
   return { min = v2init( _x0, _y0 ),
            max = v2init( _x1, _y1 ) }
end

function aabb_init_2( _pmin, _pmax )
   return { min = _pmin,
            max = _pmax }
end

-- hack: invert l/r an aabb (assuming size 8 or 16)
function aabb_apply_sign_x( aabb, sign_x )
   if sign_x < 0 then
      if aabb.max.x - aabb.min.y > 8 then
         return { min = v2init( 16 - aabb.max.x, aabb.min.y ),
                  max = v2init( 16 - aabb.min.x, aabb.max.y ) }
      else
         return { min = v2init( 8 - aabb.max.x, aabb.min.y ),
                  max = v2init( 8 - aabb.min.x, aabb.max.y ) }
      end
   end
   return aabb
end

function is_solid( p )
   return fget( mget( level.room_coords.x * 16 + flr(p.x/8),
                      level.room_coords.y * 16 + flr(p.y/8) ),
                0 )
end

function apply_borders( p, box )
   return v2init( clamp( p.x, 0-box.min.x, 128-box.max.x ),
                  clamp( p.y, 0-box.min.y-8, 128-box.max.y ) )
end

-- vec2 functions
function v2init( _x, _y ) return { x = _x, y = _y } end
function v2zero() return { x = 0, y = 0 } end
function v2get( v, i ) if i==0 then return v.x else return v.y end end
function v2set( v, i, s ) if i==0 then v.x = s else v.y = s end end
function v2add( v1, v2 ) return { x = v1.x + v2.x, y = v1.y + v2.y } end
function v2sub( v1, v2 ) return { x = v1.x - v2.x, y = v1.y - v2.y } end
function v2dot( v1, v2 ) return v1.x*v2.x + v1.y*v2.y end
function v2scale( s, v ) return { x = s*v.x, y = s*v.y } end
function v2min( v1, v2 ) return { x = min(v1.x,v2.x), y = min(v1.y,v2.y) } end
function v2max( v1, v2 ) return { x = max(v1.x,v2.x), y = max(v1.y,v2.y) } end
function v2flr( v ) return { x = flr(v.x), y = flr(v.y) } end
function v2ceil( v ) return { x = flr(v.x+0.9999), y = flr(v.y+0.9999) } end
function v2length2( v ) return v2dot( v, v )  end
function v2length( v ) return sqrt( v2length2( v ) ) end
function v2perp( v ) return { x = -v.y, y = v.x } end
function v2clamp( v, l, u ) return { x = min( max( v.x, l.x ), u.x ),
                                     y = min( max( v.y, l.y ), u.y ) } end

--[[
   ray vs aabb at origin
   returns { point, normal, interval } if hit, and nil otherwise
   inspired in rtcd 5.3, pg 181, ported from geo::np::graycast_centeredaabb()
--]]
function ray_vs_centered_aabb( ray_pos, ray_dir, ray_interval,
                               aabb_hs )
   local rh = {}
   rh.interval = ray_interval
   local first_hit_axis = 0
   for it_axis = 0,1 do
      -- if parallel to slab, either overlaps for any lambda or for none.
      if abs( v2get( ray_dir, it_axis ) ) < 0.001 then --g_pdefaultcontext->m_epsilon_dir )
         if abs( v2get( ray_pos, it_axis ) ) > v2get( aabb_hs, it_axis ) then
            -- no hit
            return nil
         end
         -- otherwise, current axis does not clip the interval, and
         -- other axis must be checked as usual.
      else
         local inv_divisor = 1.0 / v2get( ray_dir, it_axis )
         local lambda0 = ( -v2get( aabb_hs, it_axis ) - v2get( ray_pos, it_axis ) ) * inv_divisor
         local lambda1 = (  v2get( aabb_hs, it_axis ) - v2get( ray_pos, it_axis ) ) * inv_divisor
         if lambda1 < lambda0 then
            local tmp = lambda0
            lambda0 = lambda1
            lambda1 = tmp
         end
         -- clip lambda-interval and update first-axis
         if rh.interval.min < lambda0 then
            rh.interval.min = lambda0
            first_hit_axis = it_axis
         end
         if rh.interval.max > lambda1 then
            rh.interval.max = lambda1
         end
         if rh.interval.max < rh.interval.min then
            return nil
         end --empty interval, no overlap
      end
   end
   -- compute point and normal
   rh.point  = v2add( ray_pos, v2scale( rh.interval.min, ray_dir ) )
   rh.normal = {x=0,y=0}
   if v2get( ray_pos, first_hit_axis ) < 0 then
      v2set( rh.normal, first_hit_axis, -1 )
   else
      v2set( rh.normal, first_hit_axis, 1 )
   end
   return rh
end

--[[
   ray vs aabb
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ray_vs_aabb( ray_pos, ray_dir, interval,
                      aabb )
   local aabb_mid = v2scale( 0.5, v2add( aabb.min, aabb.max ) )
   local aabb_hs = v2scale( 0.5, v2sub( aabb.max, aabb.min ) )
   local rp = v2sub( ray_pos, aabb_mid )
   local rh = ray_vs_centered_aabb( rp, ray_dir, interval,
                                    aabb_hs ) --hs try to use full aabb instead
   if rh != nil then
      rh.point = v2add( rh.point, aabb_mid ) --just translate
   end
   return rh
end

--[[
   ccd between moving box and static aabb
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ccd_box_vs_aabb( box_pos0, box_pos1, box_aabb,
                          aabb )
   local box_aabb_mid = v2scale( 0.5, v2add( box_aabb.min, box_aabb.max ) )
   local box_aabb_hs = v2scale( 0.5, v2sub( box_aabb.max, box_aabb.min ) )
   local box_mid = v2add( box_pos0, box_aabb_mid )
   local ray_dir = v2sub( box_pos1, box_pos0 )
   local fat_aabb = aabb_init_2( v2sub( aabb.min, box_aabb_hs ),
                                 v2add( aabb.max, box_aabb_hs ) )
   return ray_vs_aabb( box_mid, ray_dir, {min=0,max=1},
                       fat_aabb )
end

--[[
   bp to gather static solid tiles in the map that overlap an aabb
   returns { tile_i, tile_j } if hit, and nil otherwise
--]]
function bp_aabb_vs_map( aabb, flag_mask )
   local overlaps = {}
   local tile_min = v2flr( v2scale( 0.125, aabb.min ) ) --1/8
   local tile_max = v2ceil( v2scale( 0.125, aabb.max ) ) --1/8
   --todo avoid accessing out of bounds, revisit rounding
   for j=tile_min.x, tile_max.x do
      for i=tile_min.y, tile_max.y do
         if band( flag_mask, fget( mget( level.room_coords.x * 16 + j,
                                         level.room_coords.y * 16 + i ) ) ) != 0 then
            add( overlaps, { tile_i=i, tile_j=j } )
         end
      end
   end
   return overlaps
end

--[[
   ccd between box and map
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ccd_box_vs_map( box_pos0, box_pos1, box_aabb, flag_mask )
   -- swept aabb
   local swept_aabb = aabb_init_2( v2add( v2min( box_pos0, box_pos1 ), box_aabb.min ),
                                   v2add( v2max( box_pos0, box_pos1 ), box_aabb.max ) )
   local overlaps = bp_aabb_vs_map( swept_aabb, flag_mask )
   local collisions = {}
   for o in all(overlaps) do

      local tile_aabb_min = v2init( o.tile_j*8, o.tile_i*8 )
      local tile_aabb_max = v2add( tile_aabb_min, v2init(8,8) )

      local c = ccd_box_vs_aabb( box_pos0, box_pos1, box_aabb,
                                 aabb_init_2( tile_aabb_min, tile_aabb_max ) )
      if c != nil then
         c.tile_i = level.room_coords.y * 16 + o.tile_i
         c.tile_j = level.room_coords.x * 16 + o.tile_j
         c.flags = fget( mget( c.tile_j, c.tile_i ) )
         add( collisions, c )
      end
   end

   return ccd_sort_collisions( collisions )
end

--[[
   ccd between box and map
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ccd_box_vs_map_downwards( box_pos0, box_pos1, box_aabb, flag_mask )
   -- swept aabb
   local swept_aabb = aabb_init_2( v2add( v2min( box_pos0, box_pos1 ), box_aabb.min ),
                                   v2add( v2max( box_pos0, box_pos1 ), box_aabb.max ) )
   local overlaps = bp_aabb_vs_map( swept_aabb, flag_mask )
   local collisions = {}
   for o in all(overlaps) do

      local tile_aabb_min = v2init( o.tile_j*8, o.tile_i*8 )
      local tile_aabb_max = v2add( tile_aabb_min, v2init(8,8) )

      local c = ccd_box_vs_aabb( box_pos0, box_pos1, box_aabb,
                                 aabb_init_2( tile_aabb_min, tile_aabb_max ) )
      if c != nil and c.normal.y < 0 then
         c.tile_i = level.room_coords.y * 16 + o.tile_i
         c.tile_j = level.room_coords.x * 16 + o.tile_j
         c.flags = fget( mget( c.tile_j, c.tile_i ) )
         add( collisions, c )
      end
   end

   return ccd_sort_collisions( collisions )
end

--[[
   ccd between box and entity["entity_box_name"]
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ccd_box_vs_entities( box_pos0, box_pos1, box_aabb, table_entities, entity_box_name )
   local collisions = {}
   for e in all(table_entities) do
      local local_aabb = e.a["cdamagebox"]
      if local_aabb != nil then
         local c = ccd_box_vs_aabb( box_pos0, box_pos1, box_aabb,
                                    aabb_init_2( v2add( e.p1, local_aabb.min ), v2add( e.p1, local_aabb.max ) ) )
         if c != nil then
            c.entity = e
            add( collisions, c )
         end
      end
   end
   return ccd_sort_collisions( collisions )
end

--bubble-sort collisions on increasing inverval.min
function ccd_sort_collisions( collisions )
   local b_continue = true
   local count = #collisions
   while b_continue do
      b_continue = false
      for i = 1,count-1 do
         if collisions[i].interval.min > collisions[i+1].interval.min then
            local tmp = collisions[i]
            collisions[i] = collisions[i+1]
            collisions[i+1] = tmp
            b_continue = true
         end
      end
   end
   return collisions
end

__gfx__
00000000000000000000ff0000000000000000000000000000000ff000000000000ff00000000000000000ff0ff000000011cccdff000000000000000000ff00
00000000000000090004ff00000000090000ff000000000000004ff000000009004ff00000000000000042ff0ff4000011ccccccff240000000000000004ff40
0000000000000119d442440000000119d444ff00000000009004244000000119d4244000000000009004244002424091cccccc11024240090000000000422240
0000000000111cdc9404420000111cdc94022400000001119d44442000111cdc90442000000001119d4444200224249cdcc11100022424d911100000009d4420
0000000001cccdc19042220001cccdc19044420000111ccdc944222001cccdc19442200000111ccdc9442220022244d9111000000022449cdcc1110001c99200
000000001ccccc10002222201ccccc100002222011cccccc190222201ccccc100222220011cccccc19022220002220090000000000222091cccccc111cccc920
00000000cdccc10000200020cdccc10000220020cccccc1100020020cdccc10002000200cccccc110002002000200200000000000020020011cccccc1dcc1020
00000000dc11000002000020dc11000002000020dccc110000200200dc11000020000200dccc1100002002000200020000000000020000200011cccd01110002
000ff0000000ff00000ff000000ff000000ff000000ff0000000ff00400ff40000000000000ff0000000ff0000ff0000000ff000000000000000077777700000
000ff0000004ff00004ff000000ff000000ff000000ff0000000ff00400ff04000000009004ff0000004ff4004ff4000000ff40090000000000077dd79707700
004224000042224004224040002420000044220400242200044222400442224000000119d424400000422240042224000004424d91100000000077dd91777770
042222400402220404224400004220000042224000242200042222400022220000111cdc904420000994d420024d499000024409cdc1110000000779dc177770
040222040402220400222000004420000004220000044200040222400022220001cccdc19442200001c9920000299c10000224491cdccc1000000791ccc17770
04222220002222200022222000222000000222220002200000022220000222201ccccc10022222001cdcd920029dcdc10022222001ccccc1000077771ccc1700
0020002000200020220000200020200002220002000202000022002000020002cdccc100020002001dcc10200201ccd100200020001cccdc0000777771cdc770
0200002002000020000000000200200000000000002002000200020000200002dc11000020000200011100022000111000200002000011cd00000770771cd770
000000000000000000008800000880000000880000088000dddd00dddddd50dd22220022000000000000dccc0000000000000003300000000880000007777770
000000000000000000888f040088f00000888f040088f000ddd0000dddd0000d2220000200000000000dc1c16100011100880030030000008008003330007700
000000000000000088845444088450008844454008845000dddde7dddddd97dd2222e7220000260000dc1c1c1c100c6108008300000000000000830003000000
000000000000000008405500888454000840550088845400dd00550ddd50550d220005020000000000dc1c1c161001110800981c600000000009981c60000700
000000000000000080055000080540008005500008044000d0005500d50055002000550000000000000dc1c1c1001cc1000901cc16000000009001cc16070000
00000000000000000055ddd0000d5000000d55500005d000007000d7507000d700700027006000060011dcc61001dc1000901cc1c601110009001cc1c6000000
00000000000000005500000d000d50000dd000050005d0000000d0dd5000d0dd000020220000000001c6111111ccc10000901cc1100c610000001cc110011100
00000000000000000000000000d05000000000000050d00000d0d0dd00d0d0dd0020202200000000111c1cccc61c1000000011c1c101c100000011c1c10c6100
cccc00cc11110011dddd00dd4444004466660066888800883333003399990099eeee00eeffff00ff1c61cccc1c6110000001d111110d10000001d1111101c100
ccc0000c11100001ddd0000d4440000466600006888000083330000399900009eee0000efff0000f11c1ccccc16c1000001dd1ccc61d1000001dd1ccc61d1000
cccce7cc1111e711dddde7dd4444e7446666e7668888e7883333e7339999e799eeee97eeffffe7ff1c161cccc16c100000111ccccc61000000111ccccc611000
cc20550c11205501dd20550d4420550466205506882055083320550399205509ee20550eff20550f11cc11ccc6c10000001c61ccc1c10000001c61ccc1c10000
c200550012005500d20055004200550062005500820055003200550092005500e2005500f200550001111d111110000000011d1cc610000000011d1cc6100000
227200c722720017227200d72272004722720067227200872272003722720097227200e7227200f7001ddd1c1dd1000000000dd11100000000000dd111000000
2220c0cc222010112220d0dd22204044222060662220808822203033222090992220e0ee2220f0ff01dd1001dd10000000001d1c0000000000001d1c00000000
22c0c0cc2210101122d0d0dd224040442260606622808088223030332290909922e0e0ee22f0f0ff1ddddd1ddddd10000000c1cccc0000000000c1cccc000000
222222222222222211111111111111110505050549494949eeeeeeeeeeeeeeee0000000000000000000000000000000020b33202000000000000008000000000
d26662dd5266625551616151516161515050505049444944eeeeeeeeeeeeeeee0000330000003330000000000000000020322b02000550000000009000220000
d66662dd5666625556666155566661550505050544494449eeeeeeee6e6eeeee0303bb300003bb83000000000000000020233202005675000222292002022290
d6666ddd566662555666615556666155050505054a494949eeeeeeee676eeeee303bbb83303bbbb20002520000025200023b3320050567502002222202002222
2222222222222222111111111111111105050505a0a94949eeeeeeee787776760003bbb303033bb3002525200025252000032000050056502002222502002422
dd26662d552666251516161515161615505050504a444944eee28e8e676ee7e70000333000000330085252500852525000020000005005002002442202004544
dd26666d5526666555166665551666650505050544494449ee8e7778e6eeeeee0000000000000000252525202525252000838000000550000222454002024440
dd66666d5526666555166665551666650505050549494949e2e7eee7eeeeeeee0000000000000000556565225655565200030000000000000000444400220000
055556505655655622d2d2d22d2d2d22eeeee777777eeeeeeeeeeeeeeeeebbee000bbb000000bb00000000000000000000020000eeee9eddeeeeeeeeeeeeee8e
6566656565666565002d2d2dd2d2d200eeee77dd797e77eeeeeeeeeeebeb38beb0b338b00b0b38b0000252000000000000030000eeee19ddeee55eeeeeeeee9e
56666655566666560002d2dddd2d2000eeee77dd9177777eeeeeeeeebeb333be0b0b33b0b0b333b0002525200002520000020000eee1cd9eee5675eee222292e
566565656665556600002d2dd2d20000eeeee779dc17777eeeeeeeeeeeebbbee0002bb00000bbb00285252500025252000030000ee1ccc19e5e5675e2ee22222
5656566556565666000002d22d200000eeeee791ccc1777eeeeeeeeeee22333e0022333000223330552525200852525000032000e1ccc1eee5ee565e2ee22225
56666665566666650000002222000000eeee77771ccc17eeeeeeeeeee225353202253532022535320652565225252520002b20001cdc1eeeee5ee5ee2ee24422
55665655656655560000000220000000eeee777771cdc77eeeeeeeeeee23552e00235520002355200000006050525652002b20001dc1eeeeeee55eeee222454e
06556550565566560000000220000000eeeee77e771cd77eeeeeeeeeee3ee5ee0030050000300500000000000060600000030000111eeeeeeeeeeeeeeeee4444
5000000500000000000000002222222222222222e777777eeeeeeeeeeeeeeeee000bbb000000bb0000000000000000000000033333330000eeeeeeeeeeeeee8e
5000000500000000000600002d2dd2d22d2dd2d23eee77eeeeeeeeeeeeeeeeeeb0b338b00b0b38b00000333333300000000033b35bb33000eee55eeeeeeeee9e
5555555500000000060500602dddddd22dddddd2e3eeeeeeeeeeeeeeeeeeeeee0b0b33b0b0b333b000033b35bb33000000033b353b3b3300ee5675eee222292e
500000050000000d0505005002d22d2002d22d206eeee7eeeee252eeeee252ee0023bb00002bbb000033b355b3b330000033bb53533b3300e5e5675e2ee22222
50000005000000d005050050202702022020020216e7eeeeee25252eee25252e0225332002253320033bb53533b33000003b8833883bb330e5ee565e2ee22225
5000000500044d00055605600000000707000700c6eeeeeee852525ee852525e225335222253352203b8833883bb330003bb883b8833bb30ee5ee5ee2ee24422
55555555004594005656056570000700000700001ee111ee2525252e2525252e02355520023555203bb883b8833bb30003b5885b88533b30eee55eeee222454e
5000000504495440655565560070000070000007c1ec61ee556565225655565200330550003305503b5835b83533b300003b5533b555b233eeeeeeeeeeee4444
000090dd01d00d1000000000e5e5e5e5eee1d11111e1c1eeeeeeeeeeeeeeeeeeeeeeeeee0000bb0003b5533b555b2330033b23552b32b2530000000000333000
000019dd1dcdccd1000000005e5e5e5eee1dd1ccc61d1eeeeee252eeeeeeeeeeeeee33ee0b0b38b033b23552b32b253003b23332b532b3230000200003bbb300
0001cd901dcd9cd109000000e5e5e5e5ee111ccccc611eeeee25252eeee252eee3e3bb3eb0b333b03b23332b532b323003b2b53253b23523200002333bb3b320
001ccc191cc99cc19a900000e5e5e5e5ee1c61ccc1c1eeee2852525eee25252e3e3bbb83002bbb003b2b53253b2352330332b5325b352b23020032b5b3bbb302
01ccc1001dc9dcd1a0aaa9a9e5e5e5e5eee11d1cc61eeeee5525252ee852525eeee3bbb302253320032b5325b333332300323b352b352bb22033b32bbb5b3002
1cdc100001ccdc109a900a0a5e5e5e5eeeeeedd111eeeeeee65256522525252eeeee333e22533522032bb3523b52bb2000322b3320b320b0053b883b88b30020
1dc10000001cd10009000000e5e5e5e5eeee1d1ceeeeeeeeeeeeee6e5e525652eeeeeeee020533203022b3320b320b2000020b0320b020b225b88323b88b3b23
111000000001100000000000e5e5e5e5eeeec1cccceeeeeeeeeeeeeeee6e6eeeeeeeeeee005003003020b0300b0200020002b0020b0000b025b2233b522b22b0
1616169e161616161616161616161616ad0000adbfbdad0000bdadbfbd0000bd2eeeeee88eeeeee2eee22ee22eeeeeeeeeeeeeeeeeeeeeeeeeeeee22ee22eeee
000000000000000000000000000000000000000000000000000000000000000022eeee8778eeee22eee222ee22eeeeeeeeee22ee22eeeeeeeeeeee222ee22eee
1616169e1c9e0c16161c9e0c16161616aebd00bcadbebc0000bcaebdbc00adbee22ee878878ee22eeeee222e222eeeeeeeee222ee22eeeeeeeeeeee222e222ee
0000000000000000000000000000000000000000000000000000000000000000e222ee8778ee222eeeee2222222eeeeeeeeee222e222eeeeeeeeeee2222222ee
1616169e9e9e9e0c1c9e9e9e0c16161600bc00efbe00aebdadbe00aeef00bc00e22222877822222eeeee2882882eeeeeeeeee2222222eeeeeeeeeee2882882ee
0000000000000000000000000000000000000000000000000000000000000000ee221118811122eeeeee2222222eeeeeeeeee2882882eeeeeeee3332222222ee
16161c9e9e9e9e9e9e9e9e9e9e0c161600efadef0000adbeaebd0000efbdef00ee211dd88dd112eeee33322222333eeee3333222222233eeeee3333322ee223e
0000000000000000000000000000000000000000000000000000000000000000ee111ddd1dd111eee333b22222bb33ee333333222223333eee3333bb22ee2333
c5379e9e9e9e9e9e9e9e9e9e9e9e37c500bcbeaebdadef0000efbdadbeaebc00e81121d1dd12118e3333bbbb3bbb333e33e33b22222b333eee33e3bbb2ee2b33
0000000000000000000000000000000000000000000000000000000000000000888e22111122e88833ee3bbb3bb3e33e33ee3bbb3bb3ee33e33ee33bb32e2b33
16169c9e9e9e9e9e9e9e9e9e9e9c161600bc0000aebeae0000beaebe0000bc008e8e25511552e8e833eee333533eee33333ee333533ee333e333ee3333322e33
00000000000000000000000000000000000000000000000000000000000000008eee25522552eee8333ecc5555cce333333eccc555cce333e333eccc555cc333
c5379e9e9e9e839e9e9e9e9e9e9e37c500bc000000000000000000000000bc00e8e25522e2552e8e333ccce555cce333eeeeccc555ccceeee333ccc555cc333e
0000000000000000000000000000000000000000000000000000000000000000eee2d52ee25d2eeeeeecc1e55ec1eeeeeeecc1e55ecc1eeeeeecc155ecc1333e
16169c9ebd9ebc839e9e9e9e9e9c1616adbe000000000000000000000000aebdeeeddd2ee2dddeeeeec111eeee111eeeeec111eeee111eeeeec111eee111eeee
0000000000000000000000000000000000000000000000000000000000000000ee2dde2ee2edd2eeee11111ee11111eeee11111ee11111eeee1111eee1111eee
c5379e9eef9ebcbc839e9ead9e9e37c5ae0000000000000000000000000000beeeeeeee88eeeeeeeeee11ee11eeeeeeeeeeeeeeeeeeeeeeee98eeeeeeeeee99e
00000000000000000000000000000000000000000000000000000000000000002eeeee8778eeeee2eee111ee11eeeeeeeeee11ee11eeeeee8aae11ee11eeea88
16169c9ebc83bcbcbc839ebc9e9c161600adbd0000ad00000000bd00aebd00ad22eee878878eee22eeee111e111eeeeeeeee111ee11eeeee88ee111ee11eeea8
0000000000000000000000000000000000000000000000000000000000000000e22eee8778eee22eeeee1111111eeeeeeeeee111e111eeae9a8ee111e111e989
c5379e9eaebcaeefefbe83bc9e9e37c5adbeaebe00aebd0000adbe0000bc00bce222ee8778ee222eeeae1881881eeeae9eeee1111111eaeea88ee1111111e8a9
0000000000000000000000000000000000000000000000000000000000000000e22222899822222eeaee1111111eeeaee9eee1881881eeae8a2ee1881881e28a
16169c9e9eef9ebcbc9eefbc9e9c1616aebd00adbfbfefbeaeefadbfbdefbfefee221118811122eeea22211111222eaee92221111111228a8922e111111122ae
0000000000000000000000000000000000000000000000000000000000000000ee211dd88dd112eee8a231111133228e8a222211111228aae922221111122a8e
c5379e9e9ebc9ebcbc9ebcbe9e9e37c500aebdae00bcbc82f1bcbc00bcbc00bcee111ddd1dd111ee8aa2333323332aa8a88223111113298e9ee2331111132ee8
0000000000000000000000000000000000000000000000000000000000000000e81121d1dd12118e98ee23332332e2899a8e23332332eaa8e9ee23322332ee9e
1616169e9eefad88efbdef9e9e161616ad00aebdadbebc0000bcaebfbebc00bc888e25111152e888aa8ee222522ee8aa88aee222522eea88eeeee225522eeeee
000000000000000000000000000000000000000000000000000000000000000088ee25522552ee88a88ecc5555cce88a8aaeccc555cce999e9eecc5555cceaee
9e9e9e9e25bcbcf6f6bcbc259e9e37c5aebdadefbe00aebdadbe00aebdae00bce8825552e555288e999ccce555cce999998eccc555ccceeeeeeeccc55ccceee9
0000000000000000000000000000000000000000000000000000000000000000eee2d52ee25d2eeeeeecc1e55ec1eeeeeeecc1e55ecc1eee9ee1cce55ecc1eae
2626262626262626262626262626262600aebeae000000aebe000000be0000beeeeddd2ee2dddeeeeec111eeee111eeeeec111eeee111eeeeee111eeee111eee
0000000000000000000000000000000000000000000000000000000000000000ee2dde2ee2edd2eeee11111ee11111eeee11111ee11111eeee1111eeee1111ee
22d2d2d22d2d2d22eeeeeee22eeeeeeeeeeeeeeee1eeeeee6d2dddd62222255555522dd2eeeeee8ee8eeeeee1d1dd1d1eeeeeeeeeeeeeeeeeeeeceeeee1eeeee
ee2d2d2dd2d2d2eeeeeeeee22eeeeeee4eee1ee1eeeee1e4d66dd66ddd2555cc885552d2e8eeee9ee9eeee8e1d1dd1d1eeeeeeeee111111e1eec11eee1eeee1e
eee2d2dddd2d2eeeeeeeee2222eeeeeef4eeeeeeeee1ee4fd6866c6dd255eeae8aad552d89eee89ee98eee98e1dd1d1eeeeeeeeeeeeeee11ee1c1eee1eeee1ee
eeee2d2dd2d2eeeeeeeee2d22d2eeeee4f4eeeeeeeeee4f4dd6d26dd2555eeeeabbb55529a9ee99aa99ee9a9e1d1dd1eeeeeeeeeeeeeeeeeee11ceeeeeee1eee
eeeee2d22d2eeeeeeeee2d2dd2d2eeeef4f4ee1ee1ee4f4f2d6dd6d225ee5eeeab555552444ee444444ee444e1dd1d1eeeeee11eeeeeeeeeeee11ce1eee1eeee
eeeeee2222eeeeeeeee2d2dddd2d2eee44ff4eeeeee4ff4fd6b6696d55aee5eeb55ccc55444ee444444ee444e1d1dd1eeee11ee111eeeeeeeee1c1eeee1eee1e
eeeeeee22eeeeeeeee2d2d2dd2d2d2eeff44f4eeee4f44ffd66dd66d5aeeee5c55cbbbc5e4eeee4ee4eeee4e1d1dd1d1e11eeeeeeeeeeeee1eec1eeeeeeee1ee
eeeeeee22eeeeeee22d2d2d22d2d2d224fff4f4ee4f4f4f46dddd2d65beeeee55cb888b5e4eeee4ee4eeee4e1d1dd1d1eeeeeeeeeeeeeeeeee1ece1eeeee1eee
e4f444f44f444f4eeeeeeee44eeeeeee4f4f4f4ee4f4fff4ee555eee5eeeeec555baa885eeeeee11eeeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeeeeceeeeeeeee1
ee44f444444f44eeeeeeeee44eeeeeeeff44f4eeee4f44ffe56665eeeeeeee5ec55bba8511eee1eeeeeeee1dd1eeeeeeeeeeeeee11eeeee11eeecee1eeeeee1e
eeee4f4444f4eeeeeeeeee4444eeeeeef4ff4e1eeee4ff44e566665eeeeee5eebc55ba55ee1e1eeeeeeee1d11d1eeeeeeeeeeeeeee11111eeeeeceeee1eee1ee
eeeee444444eeeeeeeeee4f44f4eeeeef4f4eeeeee1e4f4fe6555665eeeeeeee8bc5bd52eee1eeeeeeee1d1dd1d1eeeeeeeeeeeeeeeeeeeeeeececee1eeeeeee
eeeeeef44feeeeeeeeee44444444eeee4f4e1eeeeeeee4f456666565eeeeeeee8bc555521eee1eeeeee1d1d11d1d1eeeeeeeeeeeeeeeeeeee1ecee1eeeeeeee1
eeeeee4444eeeeeeeee44f4444f44eeef4eeeeeeeeeeee4f56556665eeeeeeee8bc5552deee1e1eeee1d1d1dd1d1d1eee11111eeeeeeeeeeeececeeeeeeee1ee
eeeeeee44eeeeeeeee44f444444f44ee4eeeeee1e1eeeee45666666eeeee5cc8bc5552ddee1eee11e1d1d1d11d1d1d1eeeeeee11eeeeeeee1eceeceee1ee1eee
eeeeeeeeeeeeeeee44f444f44f444f44eee1eeeeeeeeeeee36336363eeeee5555552dddd11eeeeee1d1d1d1dd1d1d1d1eeeeeeeeeeeeeeeeeceecece1ee1eeee
2222222256556556eeeeeeee4e4e4e4ee4f4eeeef4f4ff4f3b3b43b4eeeee3eeee3eeeee1eeeee111d1d1d1dd1d1d1d1eeeee677776eeeeeeeeeceeeeeeeeeee
e222222265666565eeeeeeee4e444e44ff4ff4f44f4ff4f433b33b4beee3ee3eee3eeeeee1eee1eee1d1d1d11d1d1d1eeee6777777776eee1eeeceee4eeeee4e
eee2d2dd56666656eeeeeeee444e444e4ff4ffff4f4f4ff44343433be3eb3e3ee3ee3eeeee1e1eeeee1d1d1dd1d1d1eeee677766766776eeee1cece1eeeeeeee
eeee2d2d66655566eeeeee2e4a4e4e4effff4ff44ff4f4fff4444344e3e3eebee3e3be3eeee1eeeeeee1d1d11d1d1eeee67766777777776eeeececeeeeee4eee
eeeee2d2565656662eeeed2daeae4e4ef4f4ff4ff4ff4f444444f444ebe3ee3eebee3e3eeeee1eeeeeee1d1dd1d1eeeee77777777777777eeecececeeeeeeeee
eeeeee2256666665d2dd22dd4a444e444ffff4f44f4f4ff44f4444443ee3e3bee3ee3ebeeee1e1eeeeeee1d11d1eeeee67776667777677761ceeceeceeeeeeee
eeeeeee265665556dd22dd2d444e444ef4f4ffff4f4f4f4f444444f44b33b434eb3e3ee3ee1eee1eeeeeee1dd1eeeeee7766777677776677eeecee1ce4eeeeee
eeeeeee2565566562dd2d2d24e4e4e4eee4f4f4ef4f4f4f44444f444b43b4343434b33b411eeeee1eeeeeee11eeeeeee7777667777777777e1eeceeeeeeee4ee
22222222e555565eeeeeeeee2dd2d2d2d2d2d2d2eeeeeeeeeeeeeeeeeee9eeeeeeee9eeeeeee9eeeeeeeeeeeeeeeeeee77777777777777761d1dd1d1eeeee1ee
2222222e65666565eeeeeeee2dddd2d22dd2d2d2eeeeeeeeeeeeeeeeeee98eeeeee9aeeeeee8eeeeeeeeee9eeeeeeeee77767777777677761d1dd1d1e1eeeeee
dd2d2eee566666552eeeeee22dd2dd2e2dd2d2ddeeeeeeeeeeeeeeeeee898eeeeee8a8eeeee98eeee8eee9ee1eeeeee16777766777767776d1dd1d1deeeeeeee
d2d2eeee56656565d222222de2d2dd2ed2d2dd2deee8eeeeeeeeeeeeee89a8eeee89a8eee8ea9e8eee8ee8eed111111de77777777767777ed1d1dd1deeeeeeee
2d2eeeee565656652dddddd2e2dd2d2edddd2d2deee98eeeeeee9eeeee9a9aeeee9a99ee8ee98ee8ee8e98ee1d1dd1d1e67767777676776ed1dd1d1deeee1eee
22eeeeee56666665d2dddd2de2dd2d2e2d2d2dddee8a9e8ee8e898eee8aaa9eeee89aa9e89a9aa98e8a99a8ed1d11d1dee677777777776eed1d1dd1deeeeeeee
2eeeeeee556656552d2dd2d22d2ddd2e2d2dd2d2e8a9a8aee9a998eee89a98eeee8a9a8e899aa9988a9a9a981d1dd1d1eee6777777776eee1d1dd1d11eeeee1e
2eeeeeeee655655eddd22ddd22d2d2d2d2d2d2d2a99aa99a9a8a9a89ee89aeeeeee9a8eee889998e89a88989d1d11d1deeeee777766eeeee1d1dd1d1eeeeeeee
__gff__
0000000000000000000000600060600000000000000000000000000000000101010101010101010101018080808080800101010101010101010180808080808001010101810100080202020202020101010140400000000002020202020000000404020101000000020202020202000001010801010101010002020202020202
0202020202020202000000000000000002020202020202020000000000000000020202020202020200000000000000000202020202020202000000000000000040404040606040404040404040404000010101016060014040404040404040000101400160600140404040404040404001014040400000020000024040404040
__map__
4500000000000000007200000040000000000000000000000000000000000000ffdcffffffffffffffdcffffffffffffffffccffffffffffffffffffffffffffffffffffffffccffffffcdffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff61
4040400000000060404040000040000000000000000000000000000000000000ffffffccddcdffffffffffffffffffccffffffffffffcdffccffffffffffffddffffffccffffffffffffffffffddffffffffffcdffffffffddffffffffffffcdfffffffffffffffffffffffffffffffffffffffffffffffff2ffffffffffff61
4000000000000060000000000040000000000000000000000000000000000000ccffffffffffc2f2f2f2f2f2c3ffcdffffdcffffccffffffffcdffffddccffffff635dffffffffff63ffff63ffffffffffffffffffffccffffffcccdffffffffffffffffffffffddffffffffffffdcffffdddcffffffffff65ffffffdc727261
400000000000006000004d004e40000000000000000000000000000000000000ffffffffffc2c14e0000004ec0c3ffffffffffffffffffffffffffffffffffffff636363ff63ffffffffff4effffffffddffccffffffffffffffffffffccffffffffffccffffffffffdcffffddffffffffccffffffffffe265c3ffffdc616161
4040404060404040000000004040000000000000000000000000000040000000ffc2f2f2f2c100000000000000c0f2f2f2f2f2f2c3ffc2f2f2f2f2c3ffffffffff6327c0636363ffffffffffffffffffffffffffffddffffffccffffffffffffffffffffffffffffffffffffffffffffdddcddffffffff656565c3ffffc06161
4000000060000000000000000000000000000000000000000000004040000000f4c100c0f4000000000000000000f4c100000000c0f4c100000000c0f2f0ffffff6300001c001ce063ffccddffcd63f0ffddffdcffffffffffffcdffffffddffffffffffffccffdcffffdddcffdddcffccffccffffffff65656565ffffffc061
4000000060000000580061000000714000000000000000000000404000000000f3000000f3000000000000000000f3000000000000f3000000000000f3ffffffff6300001c000000c0630000000063ffffffffffffff78ffffffffffffffffffffffccffffffffffffddffecedccffffdcffffdcffffffc7c86565c3c2ffff61
4000000040404040404040630040404000000000000000000040400000000000f3000000f3000000000000000000f3000000000000f3000000000000f3ffffffff630000000000000000005d630063ffffcdffffffff7060ffffffddffccffffffffffffffffffffddccddfcfddcddffffccffffffddffd7d865ffc0f4ffff61
402a2b00006a6b00000000000000004000000000000000004040000000000000f3000000f30000000000000000636363f000000000f3000000000000f3ffffffff6300000000636363636363c10063ffffffffffff7060707078ffffffffddffddffffffffdccdffffcddccdffffccffffffdccdffffffff6565e2fff3ffff61
403a3b00007a7b005b0000000000004000000000000040004000000000000000f3006363630000000000e0f000c0f4c10000000000f3000000000000f3dcffffcd6300000063c10000000000000063ffffffffff607070607060ffffffffffffffffffffffdcdddccddcffddccffffdcccdcdcdddccdffe2656565e2f3ffff61
40404040404040604040004800004053000000000040400000000000000000006363634ef300e0f0000000000000f3000000000000f300000000005af30000000063000063c1000000000000000063ffffffffff7060707070706464646464ffffffffcccdffffdcddffffffddccffffffcdffffffffe2656565656565c3ff61
4000000000000060004c000000405300000000004040000000000000000000006363c100f3000000000000000000f300000000e06363630000000063c10000000063635c0076006363636300000063ffffffffff70747060746000c5d4ffffffffcdffdcddffffffffffffddffffcdffdccdffffffffc66565c66565ffc0ff61
4000000000000060005c000000401e1f0000004040000000400000404000000063c10000f30000005d0000000000f3000000000000f3c063000000000000000000c06363636363c1000000000063c1ffffffff63607070706070c5d40000ffffffffffffffffffffffff63ffffdccdffffffffffffe265c1c0656565e2ffff61
4000000000000060005c000000442e2f00004040000000000000000000000040f3000000f30000e0f00000000000f3000000000000f300c063000000000000000000f300000000000000000063c1006363e2e2c0706000007060d400000000ffffffffffffffff63dd0000dcff63ffffffffffffff65c18affc0656565ffff61
40000000000000600000000000443e3f00404000000040000040400040004000f30037006300000000000063e2c2f4c30000000066f34000c0630000000066636300f300000000000066637575006363636363ff6070005660700000000000f1f1ffffffff5663c10000000000c063ffffe2ffffe265ffffffff656565e2ffe3
424242424242424242424242424242424242424242424242424242424242424271e6e6e663727272727272636363636362626262626262717171716262626262626262626262626262757575757575626262626262626262626250f1505050626262626262626250505050505050626262626262626262626262626262626262
eff0efefd0717171717171717171717171717171717171717171717171717171717171716363636363636363636363636363717171717171717171717171717162626262627171717171717171717171717171717171717171515151515151517171717171717171717171717171717171717171717171717171717171717171
efefefefefd0717171717171717171717171717171717171717171717171d0d1d07171d1eff4c1ffffc0f4efefefefefefefefefefefefefefefefefd071d1efefefefefefd075d1efefefefef4eefefefefefefefd07171715151515151515171717171717171717171717171717171717171717171d1d0d1d071d1d0717171
e0efefefefefd071717171717171d1d071d1d0717171d14ed071d14e71d1efefefefefefeff3ff40fffff3efefefefefefef5cefefef76efefefefefef4eefefefefef7cefef75efefefefefefefefefefefefefefef39d0717151f15151517171717171717171717171717171717171717171d071d1ffffffff71ffffffd071
efe0efefefefefef4ed0717171d1efefd1efefefd071efefef71efefd1efefefefefefefeff1f1f1f1f1f1efefefefefef72e1e1e1e1e1e1e1e1e1efefefefefef72e1e1e1e1e1e1e1e1e1efefefefefefefeff1efef39efd0715371535371717171717171717171717171d1d07171717171d1ffd1ffffffffffd0ffffffffd0
efefe0efefefefefefef7171d1efefefefefefefef71efefefd1efefefefefefefefefeff1f1e9e9e9e9f1f1efefefefefe127e9e9e9e9e9e9e9c0f1efefefefefe1c1e9e9f1e9e9e9e9c0f1efefefefefefefc0f1efefefef555353535354717171717171717171d1ff39ffffd071717171ffffffffffffffffffffffffffff
efefefeff0efefefefefd071efefefefefefefefefd0efefefefefefefefefefefefeff1f1e9e9e9e9e9e9f1f1efefefefe1e9e9e9e9c9e9e9e9e9e9e9e1e1e1e1e1e9e9e9e9e9e9c9e9e9e9e9e9e1e1e172efefc0f1efefef555353535354d07171717171d1d0d1ffff39ffffffffd071d1ffffffffffffffffffffffffffff
efefe0f0efefefefefefef71efefefefefefefefefefefefefefefefefefefefefeff1f1e9e9e9e9e9e9e9e9f1f1efefefe1e9e9e9e9e9e9e9e9e9e9f1c1e9e9e9e9e9e9e9e9e9e9e9e9e9e9e1e1e1e1e1c1efefefc0f156ef555353535354efd0717171d1ffffffffffffffffffffffffffffffffffffffffffffffffffffff
e0efefefefefefefefefefd0efefefefefefefefefefefefefefefefefefefefef72f1e9e9e9e9e9e9e9e9e9e9f1f1ef5de140e9e966e9e9e9e9f1e9e9e9c9e9e9e9e9e9e9f1e9e966e9e9e1e9e91ce1e1efefefefefc0f1f1f1f153535354efffd071d1ffffffffffffffffff78fffffffffffffffffff7f7ffc2ffffffc3ff
efe0f0efefefefefefefefefefefefefefefefefefefefefefefefefefefefef72f1e9e9e9c9e9e9e9e9c9e9e9e9f17272e1e1e1e1e1e1e1e1e1c1e9e9e9e9e9e9f1e9e9e1e1e1e1e1e1e1e12de9e9e1e1efefefefefefef4e555554f1535456ffff39ffffffff78ffffffffc2c1ffffffc2ffffffc3ffc0c1ffc0c3f7c2c1ff
efefefeff0efefefefefefefefefefefefefefefefefefefefefefefefefefeff1e9e9e9e9e9e9e9e9e9e9e9e9e9e9f1f1c1e9e9e9e9e9e9e9e9e9e9e1e1e1e1e1c1e9f1c1e9e9e9e9e9c0e1e1e95de1e172efefefefefefef5555545555f1f1ffff39ffffffffc0c3ffffffc0c3ffffffc0c3f7c2c1ffc2c3ffffc049c1ffff
efefeff0efefefefefefefefefefefefefefefefefd071d1efefef7cefefefeff4e9e9e9e9e9e9e9e9e9e9e9e9e9e9f4f4e9e9e9e9e9c9e9e9e9e9f1c1e9e9e9e9e9e9e9e9e9c9e9e9e9e9e96ee9f1f1e1c1efefefefefefef554054f1f154efffff39ffffffffc2c1ffffffc2f4c1ffffffc049c1ffc24949c3fffff3ffffff
efeff0efefefefefefefefefefefefefefefefefd071d1d0717171717171d1eff4c3e9e9e9e9e9e9e9e9e9e9e9e9c2f4f4c3e9e9e9e9e9e9e9e9f1c1e9e9e9e9e9e9e9e9e9e9e93ce9e9e9e1e1e1e1e1e1efefefefef56efef55f154555554efffffffffffffffc0c3ffffffc1c0c3fffffffff3ffc2c1ffffc0c3ffc0c3ffff
d1efefefefefefefefefefefefefefefefefefd071d1000039000039d071d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1e1f1f1e1e1e1e1e1e1e1e1e1e1e1e1e1e9e9e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1efefefefeff1f1ef555554555454effffffffffffffffff3fffffffffff3ffffffc2c1fff3fffffffff3fffff3ffff
71d1efefefefefefefefefefefefefefefefd071d1000000000000390075f1f100001c001c00f1000000003c00000000000000000000000000000000c0f100001c0000000000000000000000000000e1e1efefefefefefeff1f15554555454efffffffffffffff5af3fffffffffff3fffffff3fffff3ffaafffff3fffff3ffff
7171d1ef32efefeff172efefefef32f1f1757575002a005d004400000075757547000000003c00000000f100760000f1f1000000003c00000000003c00000000000000003c0000000000003f0000000000efefef37efef37ef5555f15050f1efffe737e8e7e8f1f1f1f5f5f1f5f5f1fffffff3ffc2c1ffffffffc0c3fff3ffff
f1f1f1eff1f1f1f1f1f1f1f1f1f1f1f1f1717171e6e6e671e6e671e6717171f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f171e6e67171e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
__sfx__
000a00000b61010620076300c640196401062014630076200e63006630046200362003610026100460002600016000360005600046000360008600066000a6000560005600076000560004600066000160001600
000b00000b61013620076302163018630106300b630076300463006630046200362003610026100460002600016000360005600046000360008600066000a6000560005600076000560004600066000160001600
000c002003617066170a6170d6170c6100a610076100b6100d6100d610096100561006610076100a6100e6100f6100d6100a610086100a6100d6101061011610106100e6100b61008610086100b6100961006610
000200000261005620076300463001620046200161001610016000360005600076000460002600026000160001600036000460005600066000260001600036000160005600086000260003600036000360001600
000200000261007620086200963004630086200462001610016100360005600076000460002600026000160001600036000460005600066000260001600036000160005600086000260003600036000360001600
000100001213018140101400714002130011200111001110031000110001100011000210001100011000210001100011000010000100001000010000100001000010000100001000010000100001000010000100
0002000007140161500916008130151400c1600814012130081400413001120011100110001100011000110001100011000110001100001000010000100001000010000100001000010000100001000010000100
0002000002210052200a23014220182100e220052100c210092200521007210072000420002200022000120001200032000420005200062000220001200032000120005200082000220003200032000320001200
000200001e6101d6201f620286102b610196101a6200f620136101261002620016100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0006000011530215402b5401e540085300152002520245101d5101751011500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000166202561027630216101d63019640136100f6200b6300762001630046000360002600016000160008600066000160002600006000060000600006000060000600006000060000600006000060000600
00010000067500675008750097500b7500d7400f73011720127201472016730177301773017730147300f7200b720057100270001700047000070000700007000070000700007000070000700007000070000700
0001000006750087500c7501175015750177401773015720117201072010730107300e7300a730037300272002720017100270001700047000070000700007000070000700007000070000700007000070000700
000600000f530145400a540125300f5200651002500245001d5001750011500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
002000202061123611236111e6211c6111c6111d6111e6211e6211c6111a6111b6111e621206211f6111a6111e611196111c6111f6111c6111b611216111e6211e61121611236211e6211d611226111a6111b611
002000201f611236111f611196211b6111e6111d6111b6211c62120611236111f6111a6211d6211f6111c6111a6111d6111a611196111c611216111e61123621226111a6111f621226211d6111a611196111b611
0014000005552065520555208552085520855208552095520955209552075520655206552065520655206552075520a5520b5520a552065520655206552065520a5520d55214552195521b5521c5521c5521c552
00200020095450d5450954505545065450d5450e54507545075450d5450c5450954506545045450156501565095420d5420954205542065420d5420e54207542075420d5420c5420954206542045420155201532
00280000145522755214552265521455223552145522055210552235521055222552105521f552105521c5520c552145520c552115520c5520f5520c5520e552095450c545065350953504525055250351501515
00200020090460d0460904605046060460d0460e04607046070460d0460c0460904606046040460104601046097460d7560975605746067460d7460e74607746077460d7460c7560975606756047460174601746
002000201b730107300c730207300c730107301b730107300b730207300b7301b730157301b7300b730207300b7301b730157301b73015730207300b730157300e73015730117301c7300b730157300e73015730
002000001b735107350c735207350c735107351b735107350b735207350b7351b735157351b7350b735207350b7351b735157351b73515735207350b735157350e7351573529735157350e735157352973515735
002000200b735157350e73515735117351c7350b735157350e73515735117351c7350b735157351173515735117351573515735157350e735137351373513735087350f7350f7350f735087350f735077350c735
00400020095520a552105521155216552175521d5521c55224552235521f5521d5521855215532025020d5020e5021150214502185021d5021b502135020b5020d502115020b5021c5020b502155020e50215502
00280020065550c5550a5550f5550d555125551454512522065420c5550a5550f5550d555125551454516522105420f5550e5550d5550d555115551354515522105420f5550e5550d5550d555115551355512565
__music__
00 4f514341
02 40444141
00 40414141
03 40414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141

