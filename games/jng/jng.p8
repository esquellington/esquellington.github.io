pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

----------------------------------------------------------------
-- run with: ./pico-8/pico8 -run ./jng.p8 -desktop . -windowed 1
----------------------------------------------------------------

----------------------------------------------------------------
-- init
----------------------------------------------------------------
function _init()
   caabb_88 = aabb_init(0,0,8,8)
   caabb_1616 = aabb_init(0,0,16,16)
   cinitial_room_coords = v2init( 0, 0 )

   --debug options
   debug = {}
   debug.cnummodes = 6
   debug.mode = 0
   debug.paused = false
   debug.log = {}
   debug.can_die = false

   init_archetypes()
   init_game()
end

----------------------------------------------------------------
-- update
----------------------------------------------------------------
function _update()
   if not debug.paused then
      --game
      game.t = game.t+1
      --entities
      update_player()
      update_enemies()
      update_bullets()
      update_vfx()
   end
   --debug
   if btnp(2) then --up
      debug.mode = (debug.mode+1) % debug.cnummodes
   end
   if btnp(3) then --down
      debug.paused = not debug.paused
   end
end

----------------------------------------------------------------
-- draw
----------------------------------------------------------------
function _draw()

   cls()

   --lightning
   -- todo: do it only on boss room, use sprite 255, not 0!
   -- todo use prob distrib with given expectation period
   --(start time) and random duration (alternate white/blue during
   --interval)
   if level.room_coords.x == 7 and level.room_coords.y == 0 then
      if game.t % 30 == 0 then
         if flr(rnd(100)) < 25 then
            pal(0,7)
            palt(0,false)
         end
      elseif game.t % 29 == 0 then
         if flr(rnd(100)) < 25 then
            pal(0,12)
            palt(0,false)
         end
      else
         pal()
         palt(0,true)
      end
   -- elseif level.room_coords.x == 7 and level.room_coords.y == 1 then
   --    if game.t % 10 == 0 then
   --       pal(9,10)
   --    else
   --       pal()
   --    end
   end

   --bckgnd
   map(level.room_coords.x * 16,
       level.room_coords.y * 16,
       0,0,16,16,
       0x7f )

   --enemies
   for e in all(room.enemies) do
      if e.hit_timeout % 2 == 0 then
         local act = e.action
         while act.sub != nil do
            act = act.sub
         end
         local anm = e.a.table_anm[act.anm_id]
         if e.a == a_skullboss
            or e.a == a_flameboss
            or e.a == a_finalboss then
            spr( anm.k[ 1 + act.t % #anm.k ],
                 e.p1.x, e.p1.y,
                 2,2,
                 e.sign<0 )
         else
            local anm_t
            if anm.no_cycle then
               anm_t = min(1+act.t,#anm.k)
            else
               anm_t = 1+act.t%#anm.k
            end
            spr( anm.k[ anm_t ],
                 e.p1.x, e.p1.y,
                 1,1,
                 e.sign<0 )
         end
      end
      if debug.mode > 0 then
         print_action( e.action, e.p1.x-4, e.p1.y-4  )
      end
   end

   --player
   if player.is_mutated then
      pal(8,11)
      pal(13,3)
   end
   if player.invulnerability_t % 2 == 0 then
      local anm = g_anim[player.state]
      if player.state == 6 and player.sign*player.v.x < 0 then
         anm = g_anim[7]
      end --hack: draw backwards jump shoot
      local anm_t
      if anm.no_cycle then
         anm_t = min(1+player.t,#anm.k)
      else
         anm_t = 1+player.t%#anm.k
      end
      spr( anm.k[anm_t],
           player.p1.x, player.p1.y,
           1,1,
           player.sign<0 )
   end
   pal()

   --player bullets
   for b in all(room.bullets) do
      local anm = b.a.table_anm[b.anm_id]
      spr( anm.k[1+b.t%#anm.k],
           b.p1.x, b.p1.y,
           1,1,
           player.sign<0 )
   end

   --vfx
   for v in all(room.vfx) do
      spr( v.anm.k[1+v.t%#v.anm.k],
           v.p.x, v.p.y,
           1,1,
           v.sign<0 )
   end

   -- map overlay
   map(level.room_coords.x * 16,
       level.room_coords.y * 16,
       0,0,16,16,
       0x80 )

   --hud
   for i=0,player.health-1 do
      spr( 41, i*8, 0 ) --heart
   end
   for i=1,player.num_orbs do
      spr( 64, 128-i*8, 0 ) --orb
   end

   if debug.mode > 0 then
      --entity boxes
      local colors = {10,11,8,12}
      for e in all(room.entities) do
         local a = e.a
         local boxes = {a.cvisualbox,a.cmovebox,a.cdamagebox,a.cattackbox}
         local box = boxes[debug.mode]
         if box != nil then
            box = aabb_apply_sign_x(box,e.sign)
            rect( e.p1.x + box.min.x,
                  e.p1.y + box.min.y,
                  e.p1.x + box.max.x-1,
                  e.p1.y + box.max.y-1,
                  colors[debug.mode] )
         end
      end

      -- debug info
      -- if debug.mode == 1 then
      --    print("t:"..game.t/10,1,1,14)
      --    print("a:"..g_anim[player.state].n,108,1,14)
      --    print("mem:"..stat(0),1,122,14)
      --    print("cpu:"..stat(1),84,122,14)
      -- elseif debug.mode == 2 then
      --    color(14)
      --    cursor(0,0)
      --    for s in all( debug.log ) do
      --       print( s )
      --    end
      -- end

      -- -- animations
      -- -- if debug.mode == 5 then
      -- --    local n=0
      -- --    for a in all(g_anim) do
      -- --       local i = flr(n/6)
      -- --       local j = flr(n%6)
      -- --       spr( a.k[1+game.t%#a.k],
      -- --            10+20*j,
      -- --            10+10*i )
      -- --       n+=1
      -- --    end
      -- -- end

      -- -- ground-cast
      -- -- if true then
      -- --    for c in all(player.ground_ccd_1) do
      -- --       rect( c.point.x, c.point.y, c.point.x + 11*c.normal.x, c.point.y + 11*c.normal.y )
      -- --    end
      -- -- end
   end
end

----------------------------------------------------------------
-- archetypes
----------------------------------------------------------------

function uncompress_anim( archetype )
   for id,anm in pairs(archetype.table_anm) do
      local k = anm.k
      if type(k[1]) != type(1) then --k is sequence of spans {frame,count}
         anm.k = {}
         for span in all(k) do
            for f=1,span[2] do
               add( anm.k, span[1] )
            end
         end
         -- add( debug.log, "anm has "..#anm.k.." compressed frames" )
      end
   end
end

function init_archetypes()

   --level
   a_level = {}
   a_level.cnumrooms = v2init( 8, 3 )
   a_level.cgravity_y = 0.5

   --rooms
   a_room = {}
   a_room.csizes = v2init( 128, 128 )

   ---- entities
   g_archetypes = {}
   --player
   a_player = {}
   a_player.table_anm = {}
   a_player.table_anm["idle"] = {n="idl" ,k={ {16,8}, {17,8} }}
   a_player.table_anm["run"]  = {n="run" ,k={ {18,6}, {19,4}, {20,6}, {21,4} }}
   a_player.table_anm["jump"] = {n="jmp" ,no_cycle=true,k={ {22,4}, {23,4}, {24,4}, {25,4} }}
   a_player.table_anm["fall"] = {n="fall" ,k={ {32,4}, {33,4} }}
   a_player.table_anm["shi"]  = {n="shi"  ,k={ 8,8,9,9,9 }}
   a_player.table_anm["shj"]  = {n="shj"  ,k={ 12,12,13,13  }}
   a_player.table_anm["shjb"] = {n="shjb" ,k={ 14,14,15,15 }} --same #frames as "shj"
   a_player.table_anm["hit"]  = {n="hit" ,no_cycle=true,k={ {34,5}, {35,5*7} }}
   a_player.table_anm["hitb"]  = {n="hitb",no_cycle=true,k={ {36,4}, {37,4}, {38,4} }}
   uncompress_anim( a_player )
   a_player.cvisualbox = caabb_88
   a_player.cmovebox   = aabb_init( 1, 1, 7, 7 )
   a_player.cdamagebox = aabb_init( 2, 1, 6, 7 )
   a_player.cattackbox = nil
   a_player.cmaxvel = v2init( 5, 5 )
   g_anim={}
   add( g_anim, a_player.table_anm["idle"] )
   add( g_anim, a_player.table_anm["run"] )
   add( g_anim, a_player.table_anm["jump"] )
   add( g_anim, a_player.table_anm["fall"] )
   add( g_anim, a_player.table_anm["shi"] )
   add( g_anim, a_player.table_anm["shj"] )
   add( g_anim, a_player.table_anm["shjb"] )
   add( g_anim, a_player.table_anm["hit"] )
   add( g_anim, a_player.table_anm["hitb"] )

   --caterpillar
   a_caterpillar = {}
   a_caterpillar.table_anm = {}
   a_caterpillar.table_anm["move"] = {k={ {48,6}, {49,6} }}
   uncompress_anim( a_caterpillar )
   a_caterpillar.cvisualbox = caabb_88
   a_caterpillar.cmovebox   = caabb_88
   a_caterpillar.cdamagebox = aabb_init( 1, 4, 7, 8 )
   a_caterpillar.cattackbox = aabb_init( 1, 4, 7, 8 )
   a_caterpillar.cspeed = 0.5
   a_caterpillar.chealth = 1
   a_caterpillar.replacetileoffset = v2init(0,-1)

   --caterpillar2
   a_caterpillar2 = {}
   a_caterpillar2.table_anm = {}
   a_caterpillar2.table_anm["move"] = {k={50,50,50,50,51,51,51,51}}
   a_caterpillar2.cvisualbox = caabb_88
   a_caterpillar2.cmovebox   = caabb_88
   a_caterpillar2.cdamagebox = aabb_init( 0, 2, 8, 8 )
   a_caterpillar2.cattackbox = caabb_88
   a_caterpillar2.cspeed = 1
   a_caterpillar2.chealth = 2
   a_caterpillar2.replacetileoffset = v2init(0,-1)

   --saw
   a_saw = {}
   a_saw.table_anm = {}
   a_saw.table_anm["move"] = {k={60,61,62,63}}
   a_saw.cvisualbox = caabb_88
   a_saw.cmovebox   = caabb_88
   a_saw.cdamagbox  = nil
   a_saw.cattackbox = aabb_init( 2, 2, 6, 6 )
   a_saw.cspeed = 1
   a_saw.chealth = 1
   a_saw.replacetileoffset = v2init(1,0)

   --stalactite
   a_stalactite = {}
   a_stalactite.table_anm = {}
   a_stalactite.table_anm["idle"] = {k={78}}
   a_stalactite.table_anm["move"] = a_stalactite.table_anm["idle"]
   a_stalactite.table_anm["hit"]  = {k={79,79,79}}
   a_stalactite.cvisualbox = caabb_88
   a_stalactite.cmovebox   = aabb_init( 1, 1, 7, 7 )
   a_stalactite.cdamagbox  = nil
   a_stalactite.cattackbox = caabb_88
   a_stalactite.cspeed = 5
   a_stalactite.chealth = 1
   a_stalactite.replacetileoffset = v2init(0,1)

   --grunt
   a_grunt = {}
   a_grunt.table_anm = {}
   a_grunt.table_anm["idle"] = {k={ {102,6}, {103,6} }}
   a_grunt.table_anm["move"] = {k={ {105,4}, {104,4} }}
   a_grunt.table_anm["attack"] = {k={ {105,8}, {106,6} }}
   uncompress_anim( a_grunt )
   a_grunt.cvisualbox = caabb_88
   a_grunt.cmovebox   = caabb_88
   a_grunt.cdamagebox = caabb_88
   a_grunt.cattackbox = caabb_88
   a_grunt.cspeed = 1
   a_grunt.chealth = 4
   a_grunt.replacetileoffset = v2init(0,-1)

   --cthulhu
   a_cthulhu = {}
   a_cthulhu.table_anm = {}
   a_cthulhu.table_anm["move"]   = {k={ {86,4}, {87,4}, {88,4}, {89,4} }}
   a_cthulhu.table_anm["attack"] = {k={ {90,4}, {91,4} }}
   uncompress_anim( a_cthulhu )
   a_cthulhu.cvisualbox = caabb_88
   a_cthulhu.cmovebox   = caabb_88
   a_cthulhu.cdamagebox = caabb_88
   a_cthulhu.cattackbox = aabb_init( 1, 3, 7, 8 )
   a_cthulhu.cspeed = 0.4
   a_cthulhu.chealth = 2
   a_cthulhu.cshootpos = v2init( 7, 0 )
   a_cthulhu.replacetileoffset = v2init(0,-1)

   --mouse
   a_mouse = {}
   a_mouse.table_anm = {}
   a_mouse.table_anm["move"] = {k={ {118,5}, {119,5} }}
   uncompress_anim( a_mouse )
   a_mouse.cvisualbox = caabb_88
   a_mouse.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_mouse.cdamagebox = nil
   a_mouse.cattackbox = nil
   a_mouse.cspeed = 0.3
   a_mouse.chealth = 1
   a_mouse.replacetileoffset = v2init(-1,0)

   --bird
   a_bird = {}
   a_bird.table_anm = {}
   a_bird.table_anm["idle"] = {k={ {120,4}, {121,4} }}
   a_bird.table_anm["move"] = {k={ {122,5}, {123,5} }}
   uncompress_anim( a_bird )
   a_bird.cvisualbox = caabb_88
   a_bird.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_bird.cdamagebox = caabb_88
   a_bird.cattackbox = caabb_88
   a_bird.cspeed = 1.25
   a_bird.chealth = 1
   a_bird.replacetileoffset = v2init(0,-1)

   --arachno
   a_arachno = {}
   a_arachno.table_anm = {}
   a_arachno.table_anm["move"] = {k={ {124,5}, {125,5} }}
   a_arachno.table_anm["jump_up"] = {k={126}} --up
   a_arachno.table_anm["jump_down"] = {k={127}} --down
   uncompress_anim( a_arachno )
   a_arachno.cvisualbox = caabb_88
   a_arachno.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_arachno.cdamagebox = caabb_88
   a_arachno.cattackbox = aabb_init( 1, 3, 7, 8 )
   a_arachno.cspeed = 0.75
   a_arachno.chealth = 2
   a_arachno.replacetileoffset = v2init(0,-1)

   --teeth
   a_teeth = {}
   a_teeth.table_anm = {}
   a_teeth.table_anm["move"] = {k={ {68,3}, {69,8}, {70,3} }}
   uncompress_anim( a_teeth )
   a_teeth.cvisualbox = caabb_88
   a_teeth.cmovebox   = caabb_88
   a_teeth.cdamagbox  = nil
   a_teeth.cattackbox = aabb_init( 1, 2, 6, 8 )
   a_teeth.cspeed = 1.5
   a_teeth.chealth = 1
   a_teeth.replacetileoffset = v2init(0,-1)

   --bullets
   a_blast = {}
   a_blast.table_anm = {}
   a_blast.table_anm["move"] = {k={1,1,1,2,2,2,3,3,3,2,2}}
   a_blast.table_anm["hit"] = {k={4,4,5,5,6,6,6,7}}
   a_blast.cvisualbox = caabb_88
   a_blast.cmovebox   = nil
   a_blast.cdamagbox  = nil
   a_blast.cattackbox = aabb_init( 4, 3, 8, 4 )
   a_blast.cspeed = 4

   --enemy bullets
   a_spit = {}
   a_spit.table_anm = {}
   a_spit.table_anm["move"] = {k={66}}
   a_spit.table_anm["hit"] = {no_cycle=true,k={67,67,67}}
   a_spit.cvisualbox = caabb_88
   a_spit.cmovebox   = aabb_init( 4, 3, 7, 4 )
   a_spit.cdamagbox  = nil
   a_spit.cattackbox = aabb_init( 3, 3, 6, 4 )
   a_spit.cspeed = 3

   a_flame = {}
   a_flame.table_anm = {}
   a_flame.table_anm["idle"] = {k={ {247,3}, {248,3} }}
   a_flame.table_anm["move"] = {k={ {249,3}, {250,3} }}
   a_flame.table_anm["hit"] = {no_cycle=true,k={ {234,3}, {235,3}, --hit
                                                 {247,5}, {248,5},
                                                 {247,5}, {248,5},
                                                 {247,5}, {248,5} }} --remain 30 frames (1 sec)
   uncompress_anim( a_flame )
   a_flame.cvisualbox = caabb_88
   a_flame.cmovebox   = caabb_88
   a_flame.cdamagbox  = nil
   a_flame.cattackbox = aabb_init( 2, 4, 6, 8 )
   a_flame.cspeed = 1

   a_skull = {}
   a_skull.table_anm = {}
   a_skull.table_anm["move"] = {k={ {94,5}, {95,5} }}
   a_skull.table_anm["hit"]  = a_skull.table_anm["move"] --todo
   uncompress_anim( a_skull )
   a_skull.cvisualbox = caabb_88
   a_skull.cmovebox   = aabb_init( 4, 3, 7, 4 )
   a_skull.cdamagbox  = nil
   a_skull.cattackbox = aabb_init( 4, 0, 7, 3 )
   a_skull.cspeed = 2

   -- vfx
   a_death = {}
   a_death.table_anm = {}
   a_death.table_anm["hit"] = {k={74,74,75,75,76,76,77}}--,77,76,75,76,77}}

   -- collectables
   a_orb = {}
   a_orb.table_anm = {}
   a_orb.table_anm["idle"] = {k={64,64,64,65,65,65}}
   a_orb.cvisualbox = caabb_88
   a_orb.cmovebox   = caabb_88
   a_orb.cdamagbox  = nil
   a_orb.cattackbox = nil
   a_orb.cspeed = 0
   a_orb.replacetileoffset = v2init(0,-1)

   a_mutator = {}
   a_mutator.table_anm = {}
   a_mutator.table_anm["idle"] = {k={45}}
   a_mutator.cvisualbox = caabb_88
   a_mutator.cmovebox   = caabb_88
   a_mutator.cdamagbox  = nil
   a_mutator.cattackbox = nil
   a_mutator.cspeed = 0
   a_mutator.replacetileoffset = v2init(1,0)

   --env entities
   a_torch = {}
   a_torch.table_anm = {}
   a_torch.table_anm["idle"] = {k={201,201,201,202,202,202}}
   a_torch.cvisualbox = caabb_88
   a_torch.cmovebox   = nil
   a_torch.cdamagbox  = nil
   a_torch.cattackbox = nil
   a_torch.cspeed = 0

   --bosses
   a_skullboss = {}
   a_skullboss.table_anm = {}
   a_skullboss.table_anm["idle"] = {k={138,138,138,140,140,140}}
   a_skullboss.table_anm["move"] = {k={138}}
   a_skullboss.table_anm["attack"] = {k={142}}
   a_skullboss.table_anm["jump_up"] = {k={142}}
   a_skullboss.table_anm["jump_down"] = {k={138}}
   a_skullboss.cvisualbox = caabb_1616
   a_skullboss.cmovebox   = caabb_1616
   a_skullboss.cdamagebox = aabb_init( 4, -1, 13, 9 )
   a_skullboss.cattackbox = caabb_1616
   a_skullboss.cspeed = 1
   a_skullboss.chealth = 10
   a_skullboss.cshootpos = v2init( 10, 6 )
   a_skullboss.replacetileoffset = v2init(1,0)

   a_flameboss = {}
   a_flameboss.table_anm = {}
   a_flameboss.table_anm["idle"] = {k={170,170,170,172,172,172}}
   a_flameboss.table_anm["move"] = {k={174}}
   a_flameboss.table_anm["attack"] = {k={170}}
   a_flameboss.table_anm["jump_up"] = {k={172}}
   a_flameboss.table_anm["jump_down"] = {k={170}}
   a_flameboss.cvisualbox = caabb_1616
   a_flameboss.cmovebox   = caabb_1616
   a_flameboss.cdamagebox = aabb_init( 4, -1, 13, 9 )
   a_flameboss.cattackbox = caabb_1616
   a_flameboss.cspeed = 2.5
   a_flameboss.chealth = 10
   a_flameboss.cshootpos = v2init( 10, 6 )
   a_flameboss.replacetileoffset = v2init(1,0)

   a_finalboss = {}
   a_finalboss.table_anm = {}
   a_finalboss.table_anm["idle"] = {k={136,136,136,168,168,168}}
   a_finalboss.table_anm["move"] = {k={136}}
   a_finalboss.table_anm["attack"] = {k={136}}
   a_finalboss.table_anm["jump_up"] = {k={168}}
   a_finalboss.table_anm["jump_down"] = {k={136}}
   a_finalboss.cvisualbox = caabb_1616
   a_finalboss.cmovebox   = caabb_1616
   a_finalboss.cdamagebox = aabb_init( 4, -1, 13, 9 )
   a_finalboss.cattackbox = caabb_1616
   a_finalboss.cspeed = 2.5
   a_finalboss.chealth = 20
   a_finalboss.cshootpos = v2init( 10, 6 )
   a_finalboss.replacetileoffset = v2init(1,0)

   a_cthulhu.cshoottype = a_spit
   a_skullboss.cshoottype = a_skull
   a_flameboss.cshoottype = a_flame
   a_finalboss.cshoottype = a_spit

end

----------------------------------------------------------------
-- game
----------------------------------------------------------------
function init_game()
   game = {}
   game.t = 0
   game.is_skub_alive = true
   game.is_flab_alive = true
   game.is_finb_alive = true

   player = { a = a_player,
              state = 1,
              t = 0,
              p0 = v2init( 28, 24 ),
              p1 = v2init( 28, 24 ),
              sign = 1,
              v = v2zero(),
              on_ground = false,
              jump_s = 0,  --original jump direction
              invulnerability_t = 0, --frames remaining
              health = 3,
              num_orbs = 4,
              num_orbs_placed = 0,
              is_mutated = false }

   level = {}
   level.a = a_level
   level.room_coords = cinitial_room_coords

   room = new_room( a_room, level.room_coords )
end

----------------------------------------------------------------
-- player
----------------------------------------------------------------
--- ccd movement with strong non-penetration guarantee on static map tiles
function update_player()

   -- debug.log = {}
   player.t += 1
   if player.invulnerability_t > 0 then
      player.invulnerability_t -= 1
   end
   player.p0 = player.p1
   local anm = g_anim[player.state]

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
         player.t = 0
         player.state = 1
         player.v = v2zero()
      end

      -- idle/run
      if player.state==1 then
         -- todo in transitions to run, try to start with
         -- alternative/random legs to improve variation
         if btn(0) then
            player.t = 0
            player.state = 2
            player.sign = -1
            player.v = v2init(-1.25,0)
         elseif btn(1) then
            player.t = 0
            player.state = 2
            player.sign = 1
            player.v = v2init(1.25,0)
         end
      elseif player.state==2 then --run
         if not (btn(0) or btn(1)) then
            player.t = 0
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
         else --reset run speed, otherwise sometimes gets stuck in corners when revesing direction
            player.v = v2init(player.sign*1.25,0)
         end
      end

      --jump
      if btnp(5) then
         player.t = 0
         player.state = 3
         player.v.y = -4
         if btn(0) then
            player.jump_s = -1
            player.v.x = -1.25
         elseif btn(1) then
            player.jump_s = 1
            player.v.x = 1.25
         else
            player.jump_s = 0
            player.v.x = 0
         end
      end

   else --on_air

      -- idle,run / jmp
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
         --horizontal jump speed is constantly applied to allow jumping
         --over neighbour blocks
         player.v.x = player.jump_s * 1.25
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
         -- air control todo: does not work anymore since on_ground refactor
         -- player.v.x = -player.v.x
      end

      --double-jump if mutated todo limit usage!!
      if -- player.is_mutated
         -- and
         player.v.y >= 0 then
         if btnp(5) then
            player.t = 0
            player.state = 3
            player.v.y = -4
            if btn(0) then
               player.jump_s = -1
               player.v.x = -1.25
            elseif btn(1) then
               player.jump_s = 1
               player.v.x = 1.25
            else
               player.jump_s = 0
               player.v.x = 0
            end
         end
      end
   end

   --shoot
   if player.state!=5 and player.state!=6 and btnp(4) then
      player.t = 0
      if player.state==3 then
         player.state = 6 --shoot jump
      else --idle/run
         player.state = 5 --shoot idle
         player.v.x = 0
      end
      new_bullet_blast( player.p0, player.sign )
   end

   local movebox = aabb_apply_sign_x(player.a.cmovebox,player.sign)
   local damagebox = aabb_apply_sign_x(player.a.cdamagebox,player.sign)
   local acc = v2init( 0, level.a.cgravity_y )
   local pred_vel = v2clamp( v2add( player.v, acc ),
                             v2scale(-1,player.a.cmaxvel),
                             player.a.cmaxvel )

   -- ccd-advance
   local p1
   local num_hits_map
   -- first handle collisions with solid map
   p1, num_hits_map, player.handled_collisions = advance_ccd_box_vs_map( player.p0, v2add( player.p0, pred_vel ), movebox, 1, false )
   -- then handle collisions with damage map important: we do it in a
   -- second pass to allow non-damage tiles to prevent the player from
   -- hitting damage tiles if already supported/deflected by
   -- non-damage tiles
   local p2
   local hits_ccd = {}
   p2, num_hits_map, hits_ccd = advance_ccd_box_vs_map( player.p0, p1, damagebox, 2, false )

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
   hits_ccd = ccd_box_vs_map( player.p0, p2,
                              movebox,
                              8, --collectable
                              false ) --all collisions
   for c in all(hits_ccd) do
      if mget(c.tile_j,c.tile_i) == 64 then
         player.num_orbs += 1
         mset( c.tile_j, c.tile_i, mget( c.tile_j+a_orb.replacetileoffset.x, c.tile_i+a_orb.replacetileoffset.y ) )
         for e in all(room.entities) do
            if e.a == a_orb then
               kill_entity( e )
            end
         end
      elseif mget(c.tile_j,c.tile_i) == 45 then
         player.is_mutated = true
         mset( c.tile_j, c.tile_i, mget( c.tile_j+a_mutator.replacetileoffset.x, c.tile_i+a_mutator.replacetileoffset.y ) )
         for e in all(room.entities) do
            if e.a == a_mutator then
               kill_entity( e )
            end
         end
      end
   end

   -- advance
   player.p1 = p2
   player.v = v2sub( player.p1, player.p0 )

   -- process hits if not invulnerable
   if (hit_enemy or num_hits_map != 0)
      and player.invulnerability_t == 0 then
      player.t = 0
      player.state = 8 --hit todo decide hit/hitb
      player.invulnerability_t = 60
      player.sign = -player.sign
      player.v = v2init( player.sign * 1.5, -3 )
      if debug.can_die then
         player.health -= 1
      end
      if player.health == 0 then
         init_game()
      end
   end

   -- check on ground for next frame
   player.ground_ccd_1 = ccd_box_vs_map( player.p0, v2add( player.p1, v2init(0,1) ),
                                         movebox,
                                         3, --flags: 0 is_solid, 1 is_damage
                                         false ) --all collisions
   player.on_ground = false
   for c in all(player.ground_ccd_1) do
                              --add( debug.log, "ground(p1) "..c.normal.x..","..c.normal.y )
      if c.normal.y < 0 and player.v.y >= 0 then --todo could filter by y-component values for inclined ground
         player.on_ground = true
      end
   end

   -- change room
   -- todo: access room-specific archetypes a_room[j][i] from map
   local offset = 16*8
   if player.v.x > 0
      and player.p1.x > offset - movebox.max.x
      and level.room_coords.x < level.a.cnumrooms.x-1 then
      level.room_coords.x += 1
      room = new_room( a_room, level.room_coords )
      player.p1.x = movebox.min.x
      --add( debug.log, "room_x "..level.room_coords.x )
   elseif player.v.x < 0
      and player.p1.x < movebox.min.x
      and level.room_coords.x > 0 then
      level.room_coords.x -= 1
      room = new_room( a_room, level.room_coords )
      player.p1.x = offset - movebox.max.x
      --add( debug.log, "room_x "..level.room_coords.x )
   elseif player.v.y > 0
      and player.p1.y > offset - movebox.max.y
      and level.room_coords.y < level.a.cnumrooms.y-1 then
      level.room_coords.y += 1
      room = new_room( a_room, level.room_coords )
      player.p1.y = movebox.min.y
   elseif player.v.y < 0
      and player.p1.y < movebox.min.y
      and level.room_coords.y > 0 then
      level.room_coords.y -= 1
      room = new_room( a_room, level.room_coords )
      player.p1.y = offset - movebox.max.y
   end

   --borders todo these should be also treated as ccd contacts,
   --otherwise clamping may cause interpenetration with map tiles!!
   player.p1 = apply_borders( player.p1, movebox )
end

function advance_ccd_box_vs_map( p0, p1, box, flags, b_first_only )

   local d = v2sub( p1, p0 )
   local remaining_time = 1 --1 step remaining
   local collisions_ccd = ccd_box_vs_map( p0, p1,
                                          box,
                                          flags,
                                          b_first_only )
   local num_hits = 0
   local handled_collisions = {}
   while collisions_ccd != nil do
      local b_retest = false
      for c in all(collisions_ccd) do
         if not b_retest
            and
            not contains_collision_with_normal( handled_collisions, c.normal ) --todo: we could filter it with dn < 0 too and avoid tracking handled coll completely
         then
            add( handled_collisions, c )
            -- move up to toi
            p0 = v2add( p0, v2scale( 0.99*c.interval.min, d ) )
            -- clip interval
            local remaining_fraction = (1-c.interval.min) --interval [min..1] becomes new [0..1]
            remaining_time *= remaining_fraction
            -- correct displacement
            local dn = v2dot( d, c.normal )
            if dn < 0 then
               d = v2sub( d, v2scale( dn, c.normal ) )
               num_hits += 1
            end
            -- predict during remaining fraction along corrected displacement
            p1 = v2add( p0, v2scale( remaining_fraction, d ) )
            b_retest = true
         end
      end
      -- retest if required of flag for exit otherwise
      if b_retest and remaining_time > 0.01 then
         collisions_ccd = ccd_box_vs_map( p0, p1,
                                          box,
                                          flags,
                                          b_first_only )
      else
         collisions_ccd = nil
      end
   end

   return p1, num_hits, handled_collisions
end

----------------------------------------------------------------
-- rooms
----------------------------------------------------------------
function new_room( archetype, coords )
   kill_room()
   local r = {}
   --init
   r.a = archetype
   r.enemies = {}
   r.entities = {}
   r.zombies = {}
   r.bullets = {}
   r.vfx = {}
   --add player
   add( r.entities, player )
   --process static map cells to create entities
   for j=0,15 do
      for i=0,15 do
         new_room_process_map_cell( r, j, i, coords.x*16 + j, coords.y*16 + i )
      end
   end
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
   local e = nil
   local pos = v2init( room_j*8, room_i*8 )
   if m == 48 then
      e = new_entity( a_caterpillar, pos, new_action_patrol( pos, -1 ) )
   elseif m == 50 then
      e = new_entity( a_caterpillar2, pos, new_action_patrol( pos, -1 ) )
   elseif m == 86 then --cthulhu_patroler
      e = new_entity( a_cthulhu, pos, new_action_patrol( pos, -1 ) )
   elseif m == 90 then --cthulhu_shooter
      e = new_entity( a_cthulhu, pos, new_action_shoot( 30, "straight" ) )
   elseif m == 102 then
      e = new_entity( a_grunt, pos, new_action_wait_and_ram( pos, -1 ) )
   elseif m == 118 then
      e = new_entity( a_mouse, pos, new_action_patrol( pos, -1 ) )
   elseif m == 120 then
      e = new_entity( a_bird, pos, new_action_wait_and_fly( pos, -1 ) )
   elseif m == 124 then
      e = new_entity( a_arachno, pos, new_action_patrol_and_jump( pos, -1 ) )
   elseif m == 60 then --saw l2r
      e = new_entity( a_saw, pos, new_action_oscillate( pos, v2init(1,0), 4*8, 300 ) )
   elseif m == 63 then --saw r2l
      e = new_entity( a_saw, pos, new_action_oscillate( pos, v2init(-1,0), 4*8, 300 ) )
   elseif m == 68 then
      e = new_entity( a_teeth, pos, new_action_patrol( pos, -1 ) )
   elseif m == 78 then
      e = new_entity( a_stalactite, pos, new_action_wait_and_drop( pos ) )
   elseif m == 247 then --temporal: falling flame
      e = new_entity( a_flame, pos, new_action_wait_and_drop( pos ) )
   elseif m == 248 then --resting flame
      e = new_entity( a_flame, pos, new_action_idle() )
      --bosses
   elseif m == 138 and game.is_skub_alive then
      e = new_entity( a_skullboss, pos, new_action_skullboss() )
   elseif m == 170 and game.is_flab_alive and player.num_orbs == 4 then
      e = new_entity( a_flameboss, pos, new_action_flameboss() )
   elseif m == 136 and game.is_finb_alive then
      e = new_entity( a_finalboss, pos, new_action_skullboss() )
      --these should be entities but not enemies, but by now are handled as enemies to avoid extra code.
   elseif m == 201 then
      e = new_entity( a_torch, pos, new_action_idle() )
   elseif m == 64 then
      e = new_entity( a_orb, pos, new_action_idle() )
   elseif m == 71 then
      e = new_entity( a_mutator, pos, new_action_idle() )
   elseif m == 73 and player.num_orbs_placed < player.num_orbs then
      mset(map_j,map_i,72) --install orb permanently
      player.num_orbs_placed += 1
   end

   -- init common part and add enemy
   if e != nil then
      e.health = e.a.chealth
      e.hit_timeout = 0
      add( r.enemies, e )
      add( r.entities, e )
      --remember spawn pos and replace background with tile at e.a.replacetileoffset
      local a = e.a
      if a.replacetileoffset != nil
         and a != a_orb
         and a != a_mutator
      then
         e.spawn_tile_i = map_i
         e.spawn_tile_j = map_j
         e.spawn_tile_value = m
         mset( map_j, map_i, mget( map_j+a.replacetileoffset.x, map_i+a.replacetileoffset.y ) )
      end
   end
end

----------------------------------------------------------------
-- enemies
----------------------------------------------------------------
function new_entity( _archetype, _pos, _action )
   local e = { a = _archetype,
               action = _action,
               p0 = _pos,
               p1 = _pos,
               sign = -1 }
   return e
end

function kill_entity( e )
   del(room.enemies,e)
   del(room.entities,e)
   add(room.zombies,e)
   -- kill bosses permanently
   if e.a == a_skullboss then
      game.is_skub_alive = false
   elseif e.a == a_flameboss then
      game.is_flab_alive = false
   elseif e.a == a_finalboss then
      game.is_finb_alive = false
   end
end

function update_enemies()
   for e in all(room.enemies) do
      if e.hit_timeout > 0 then
         e.hit_timeout -= 1
      end
      e.p0 = e.p1
      e.action = update_action( e, e.action )

      -- remove if no action or out (important for enemy-bullets)
      if e.action == nil or is_out( e.p1 ) then
         kill_entity( e )
      end
   end
end

----------------------------------------------------------------
-- actions
----------------------------------------------------------------

----------------------------------------------------------------
function new_action_idle()
   return { name = "idle", anm_id = "idle", t = 0, finished = false }
end

-- move unconditionally
function new_action_move( target_pos )
   return { name = "move", anm_id = "move", t = 0, finished = false,
            p_target = target_pos }
end

-- ballistic projectile, play "hit" and disappear on impact. supersedes "fall"
function new_action_particle( _v, _a )
   return { name = "part", anm_id = "move", t = 0, finished = false,
            vel = _v, acc = _a }
end

function new_action_hit()
   return { name = "hit", anm_id = "hit", t = 0, finished = false }
end

-- shoot with cooldown timeout
function new_action_shoot( _timeout, _type )
   return { name = "shoot", anm_id = "attack", t = _timeout-1, finished = false,
            timeout = _timeout,
            type = _type }
end

-- move on ground, stop at target/wall/cliff/border
function new_action_move_on_ground( target_pos )
   return { name = "mong", anm_id = "move", t = 0, finished = false,
            p_target = target_pos }
end

-- move on ground, stop at target/wall/cliff/border
function new_action_jump_on_ground( target_pos )
   return { name = "jong", anm_id = "jump_up", t = 0, finished = false, first = true,
            p_target = target_pos }
end

-- patrol in flat area, stop and turn at wall/cliff/border
function new_action_patrol( start_pos, sign_x )
   return { name = "ptrl", anm_id = "move", t = 0, finished = false,
            p_start = start_pos,
            sub = new_action_move_on_ground( v2add( start_pos, v2init( 128*sign_x, 0 ) ) ) }
end

-- wait on spot, ram to player when on same ground level, accessible and within range
function new_action_wait_and_ram( start_pos, sign_x )
   return { name = "w&r", anm_id = "idle", t = 0, finished = false,
            p_start = start_pos,
            sub = new_action_idle() }
end

-- wait on spot, fly to player when within radius
function new_action_wait_and_fly( start_pos, sign_x )
   return { name = "w&f", anm_id = "idle", t = 0, finished = false,
            p_start = start_pos,
            sub = new_action_idle() }
end

-- wait on spot, fall on player when on same horizontal level
function new_action_wait_and_drop( start_pos )
   return { name = "w&d", anm_id = "idle", t = 0, finished = false,
            p_start = start_pos,
            sub = new_action_idle() }
end

-- wait on spot, fly to player when within radius
function new_action_patrol_and_jump( start_pos, sign_x )
   return { name = "p&j", anm_id = "move", t = 0, finished = false,
            p_start = start_pos,
            sub = new_action_patrol( start_pos, sign_x ) }
end

-- follow nav points todo use list instead of just 2!!
-- function new_action_path( start_pos, end_pos )
--    return { name = "path", anm_id = "move", t = 0, finished = false,
--             p_start = start_pos,
--             p_end = end_pos,
--             sub = new_action_move( end_pos ),
--             phase = 1 }
-- end

-- oscillate from midpos along dir with sinusoid of given amplitude (in pixels) and period (in frames)
function new_action_oscillate( mid_pos, _dir, _amplitude, _period )
   return { name = "oscl", anm_id = "move", t = 0, finished = false,
            p_mid = mid_pos,
            dir = _dir,
            amplitude = _amplitude,
            period = _period }
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
            phase = _phase }
end

function new_action_skullboss()
   return { name = "skub", anm_id = "idle", t = 0, finished = false,
            sub = new_action_idle(),
            phase = 1 }
end

function new_action_flameboss()
   return { name = "flab", anm_id = "idle", t = 0, finished = false,
            sub = new_action_idle(),
            phase = 1 }
end

----------------------------------------------------------------
function update_action( _entity, _action )
   local act = _action
   act.t += 1
   if _action.name == "idle" then
      --idle do nothing
   elseif _action.name == "move" then
      act = update_action_move( _entity, _action )
   elseif _action.name == "part" then
      act = update_action_particle( _entity, _action )
   elseif _action.name == "hit" then
      act = update_action_hit( _entity, _action )
   elseif _action.name == "shoot" then
      act = update_action_shoot( _entity, _action )
   elseif _action.name == "mong" then
      act = update_action_move_on_ground( _entity, _action )
   elseif _action.name == "jong" then
      act = update_action_jump_on_ground( _entity, _action )
   elseif _action.name == "ptrl" then
      act = update_action_patrol( _entity, _action )
   elseif _action.name == "oscl" then
      act = update_action_oscillate( _entity, _action )
   elseif _action.name == "sinu" then
      act = update_action_sinusoid( _entity, _action )
   elseif _action.name == "w&r" then
      act = update_action_wait_and_ram( _entity, _action )
   elseif _action.name == "w&f" then
      act = update_action_wait_and_fly( _entity, _action )
   elseif _action.name == "w&d" then
      act = update_action_wait_and_drop( _entity, _action )
   elseif _action.name == "p&j" then
      act = update_action_patrol_and_jump( _entity, _action )
   elseif _action.name == "skub" then
      act = update_action_skullboss( _entity, _action )
   elseif _action.name == "flab" then
      act = update_action_flameboss( _entity, _action )
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
   --todo if collision, change to "action_impact" and die afterwards
   local movebox = aabb_apply_sign_x( entity.a.cmovebox, entity.sign )
   local map_collisions = ccd_box_vs_map( entity.p0,
                                          entity.p1,
                                          movebox,
                                          5,   --flags: 1 is_solid, 2 is_damage, 4 is destructible
                                          true ) --first-only
   if #map_collisions > 0 then
      entity.p1 = v2add( entity.p0, v2scale( 0.99*map_collisions[1].interval.min, action.vel ) )
      return new_action_hit()
   else
      return action
   end
end

function update_action_hit( entity, action )
   if action.t > #entity.a.table_anm[action.anm_id].k then
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
      local e = nil
      if action.type == "straight" then
         e = new_entity( st,
                         pos,
                         new_action_particle( v2init( entity.sign*st.cspeed, 0 ), v2init(0,0) ) )
      elseif action.type == "parabolic" then
         e = new_entity( st,
                         pos,
                         new_action_particle( compute_projectile_vel_45deg( v2sub( player.p1, pos ), 0.125 ),
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
      --debug.paused = true
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
      local b_hit_wall = is_solid( p_forward )
      local b_hit_border = is_out( p_forward )
      local b_hit_cliff = not is_solid( p_feet )
      local diff = v2sub( action.p_target, entity.p1 )
      local dist = v2length( diff )
      if b_hit_wall
         or b_hit_border
         or b_hit_cliff then
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
   local acc_y = 0.5 * level.a.cgravity_y --0.5 slowdown over global acc to get slower trajectory
   local diff = v2sub( action.p_target, entity.p1 )
   if action.first then
      action.v = compute_projectile_vel_45deg( diff, acc_y )
      action.first = false
   elseif not action.finished then
      local dist = v2length( diff )
      action.v.y += acc_y
      local speed = v2length( action.v )
      if dist < speed then
         -- success, closer than 1 timestep advance
         entity.p1 = action.p_target
         action.finished = true
      else
         -- todo this seems to easily overshoot
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
   hits_ccd = ccd_box_vs_map( p1, v2init(p2.x,p1.y),
                              aabb_init(0,0,1,1),
                              3,
                              true )
   return #hits_ccd == 0
end

function has_line_of_sight_downwards( p1, p2 )
   if abs(p1.x - p2.x) > 8 then
      return false
   end
   hits_ccd = ccd_box_vs_map( p1, v2init(p1.x,p2.y),
                              aabb_init(0,0,1,1),
                              3,
                              true )
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
      if has_line_of_sight_horizontal( v2add(entity.p1,v2init(4,4)), v2add(player.p1,v2init(4,4)) ) then
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
      if v2length( v2sub( player.p1, entity.p1 ) ) < 64 then
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
      if has_line_of_sight_downwards( v2add(entity.p1,v2init(4,4)), v2add(player.p1,v2init(4,4)) ) then
         action.sub = new_action_particle( v2zero(), v2init(0,a_level.cgravity_y) )
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
   -- todo check range
   then
      if abs(player.p1.x-entity.p1.x) < 64
         and
         has_line_of_sight_horizontal( v2add(entity.p1,v2init(4,4)), v2add(player.p1,v2init(4,4)) ) then
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

function update_action_skullboss( entity, action )
   local sub = update_action( entity, action.sub )
   entity.sign = sgn( player.p1.x - entity.p1.x )
   -- intro/combat/outtro phases
   if action.phase == 1 then --intro
      if action.t > 60 then
         action.phase = 2
      end
   elseif action.phase == 2 then --combat
      if sub.name == "idle" and sub.t > 30 then --1s
         sub = new_action_shoot(30,"sinusoid")
      elseif sub.name == "shoot" and sub.t > 120 then --4x shots
         if entity.p1.x > 100 then
            sub = new_action_jump_on_ground( v2init(0,104) )
         else
            sub = new_action_jump_on_ground( v2init(112,104) )
         end
      elseif sub.name == "jong" and sub.finished then
         sub = new_action_idle()
      end
   else --outtro
      --todo
   end
   action.sub = sub
   return action
end

function update_action_flameboss( entity, action )
   local sub = update_action( entity, action.sub )
   entity.sign = sgn( player.p1.x - entity.p1.x )
   -- intro/combat/outtro phases
   if action.phase == 1 then --intro
      if action.t > 60 then
         action.phase = 2
         sub = new_action_jump_on_ground( v2init(112,104) )
      end
   elseif action.phase == 2 then --combat
      if sub.name == "idle" and sub.t > 30 then --1s
         sub = new_action_shoot(30,"parabolic")
      elseif sub.name == "shoot" and sub.t > 90 then --3x shots
         if entity.p1.x > 100 then
            --sub = new_action_jump_on_ground( v2init(0,104) )
            sub = new_action_move_on_ground( v2init(0,104) )
         else
            sub = new_action_jump_on_ground( v2init(112,104) )
         end
      elseif sub.name == "jong" and sub.finished then
         sub = new_action_idle()
      elseif sub.name == "mong" and sub.finished then
         sub = new_action_idle()
      end
   else --outtro
      --todo
   end
   action.sub = sub
   return action
end

----------------------------------------------------------------
-- bullets
----------------------------------------------------------------
function new_bullet_blast( _p, _s )
--   debug.paused = true
   local b = { a = a_blast,
               anm_id = "move",
               t = 0,
               p0 = _p,
               p1 = _p,
               sign = _s,
               v = v2init( _s*a_blast.cspeed, 0 ) }
   add(room.bullets,b)
   add(room.entities,b)
end

function update_bullets()
   --move room.bullets
   for b in all(room.bullets) do
      b.t += 1
      b.p0 = b.p1
      b.p1 = v2add( b.p0, b.v )

      -- test against map
      local map_collisions = ccd_box_vs_map( b.p0,
                                             b.p1,
                                             aabb_apply_sign_x( b.a.cattackbox, b.sign ),
                                             5,   --flags: 1 is_solid, 2 is_damage, 4 is destructible
                                             true ) --first-only
      -- if map collision, save it and shorten predicted trajectory
      if #map_collisions > 0 then
         b.p1 = v2add( b.p0, v2scale( map_collisions[1].interval.min, b.v ) )
         -- UNNECESSARY b.v = v2zero()
      end

      -- test against enemies
      local enm_collisions = ccd_box_vs_entities( b.p0,
                                                  b.p1,
                                                  aabb_apply_sign_x( b.a.cattackbox, b.sign ),
                                                  room.enemies,
                                                  "cdamagebox",
                                                  true ) --first-only

      -- if there's enemy collision, either there was no map collision
      -- or the enemy one happened first during the shortened
      -- trajectory, so in both cases we handle the enemy collision.
      -- todo: vfx could be different for map/enemies
      local b_delete = true
      local b_fx = true
      if #enm_collisions > 0 then
         --local enm_c = enm_collisions[1]
         -- UNNECESSARY b.p1 = v2add( b.p0, v2scale( enm_c.interval.min, b.v ) )
         -- UNNECESSARY b.v = v2zero()
         local e = enm_collisions[1].entity
         if e.a.cdamagebox != nil
            and e.health == 1 then
            kill_entity( e )
            new_vfx( a_death, e.p1, e.sign )
         else
            e.health -= 1
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
         -- todo play sfx
         new_vfx( a_blast, b.p1, b.sign )
      end
      if b_delete then
         del( room.bullets, b )
         del( room.entities, b )
      end
   end
end

----------------------------------------------------------------
-- vfx
----------------------------------------------------------------
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

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------
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

-- invert l/r an aabb (assuming sprite size 8 or 16... this is ugly)
function aabb_apply_sign_x( aabb, sign_x )
   if sign_x < 0 then
      if aabb.max.x - aabb.min.y > 8 then
         return { min = v2init( 15 - aabb.max.x, aabb.min.y ),
                  max = v2init( 15 - aabb.min.x, aabb.max.y ) }
      else
         return { min = v2init( 7 - aabb.max.x, aabb.min.y ),
                  max = v2init( 7 - aabb.min.x, aabb.max.y ) }
      end
   end
   -- otherwise
   return aabb
end

function is_solid( p )
   return fget( mget( level.room_coords.x * 16 + flr(p.x/8),
                      level.room_coords.y * 16 + flr(p.y/8) ),
                0 )
end

function apply_borders( p, box )
   return v2init( clamp( p.x, 0-box.min.x, room.a.csizes.x-box.max.x ),
                  clamp( p.y, 0-box.min.y-8, room.a.csizes.y-box.max.y ) )
end

function contains_collision_with_normal( collisions, n )
--   add( debug.log, "contains? "..n.x..","..n.y )
   for v in all(collisions) do
      if v.normal.x == n.x
         and
         v.normal.y == n.y
      then
--         add( debug.log, "found" )
         return true
      -- else
      --    add( debug.log, "not equal to "..v.normal.x..","..v.normal.y )
      end
   end
   return false
end

----------------------------------------------------------------
-- vec2 functions
----------------------------------------------------------------
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
   local fat_aabb = aabb_init_2( v2sub( aabb.min, box_aabb_hs ), v2add( aabb.max, box_aabb_hs ) )
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
   local tile_max = v2flr( v2scale( 0.125, aabb.max ) ) --1/8
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
function ccd_box_vs_map( box_pos0, box_pos1, box_aabb, flag_mask, b_first_only )
   -- swept aabb
   local swept_aabb = aabb_init_2( v2add( v2min( box_pos0, box_pos1 ), box_aabb.min ),
                                  v2add( v2max( box_pos0, box_pos1 ), box_aabb.max ) )
   local overlaps = bp_aabb_vs_map( swept_aabb, flag_mask )
   local collisions = {}
   for o in all(overlaps) do

      -- debug bp
      rect( o.tile_j*8, o.tile_i*8,
            (o.tile_j+1)*8, (o.tile_i+1)*8,
            7 )

      local tile_aabb_min = v2init( o.tile_j*8, o.tile_i*8 )
      local tile_aabb_max = v2add( tile_aabb_min, v2init(8,8) ) --8,8 are the sizes of map tile, but could be sub-box

      --todo: consider instead geting only up to the first non-0 hit, and clipping interval incrementally to reduce tested pairs
      local c = ccd_box_vs_aabb( box_pos0, box_pos1, box_aabb,
                                 aabb_init_2( tile_aabb_min, tile_aabb_max ) )
      if c != nil then
         c.tile_i = level.room_coords.y * 16 + o.tile_i
         c.tile_j = level.room_coords.x * 16 + o.tile_j
         c.flags = fget( mget( c.tile_j, c.tile_i ) )
         add( collisions, c )
      end
   end

   return ccd_sort_collisions( collisions, b_first_only )
end

--[[
   ccd between box and entity["entity_box_name"]
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ccd_box_vs_entities( box_pos0, box_pos1, box_aabb, table_entities, entity_box_name, b_first_only )
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
   return ccd_sort_collisions( collisions, b_first_only )
end

function ccd_sort_collisions( collisions, b_first_only )
   -- first-only
   if b_first_only != nil and b_first_only then
      local first = nil
      for c in all(collisions) do
         if first == nil then
            first = c
         else
            if c.interval.min < first.interval.min then
               first = c
            end
         end
      end
      collisions = { first }
   else
      --bubble-sort collisions on increasing inverval.min
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
   end
   return collisions
end
----------------------------------------------------------------

__gfx__
0000000000000000000000000000000000000090000000000000000000a000000008800000880000000880000088000000088000008800000008808000888800
00000000000000000000009000000990000000090000909a000000000000a0000088900408890040008890040889004000889004088900400088980408898040
00000000000099a0000009a900009aa90000009a000009a70000900a090000000844544488454400088544448844440008445444884544000844544488454400
00000000000aaaaa0000aaa90000aaa9000009a700099a7a09a9a979000a00008485500084550000088550008855000084855000845500000485500084550000
00000000000099a0000009a900009aa90000009a000009a700900a97090000008885000084500000888500008850000008550000845000000885880084588800
00000000000000000000009000000990000000090000909a000000090000a0000805550008555000080555000855000080555500805550000085d080085d0000
0000000000000000000000000000000000000090000000000000000000a00000000d050000d00500000d050000d050000dd005000dd0050000050dd00050dd00
000000000000000000000000000000000000000000000000000000000000000000d005500d00005000d005500d000500d0005000d00005000000500d000500d0
00088000000088000000880000088000000088000008800000008890000088900000088088080880eee88eeeee88eeeeeee88eeeeee88eeeee88ee8eee88eeee
00889000000889000088890400889000008889040088900000088450008884500080889008888890ee889eeee889eeeeee889eeeee889eeee88988eee889888e
08845000008845008884544408845000884445400884500000884550080845500888845088088450e88454ee88454eeee8845eeee8845eee88454eee88454eee
08455000088455000840550088845400084055008884540008845500008455000088455400884554e8455ccd8455ccde88455ccd8845ccde8455ccde845ccdee
884544000884540080055000080540008005500008044000008055550800555500004500000045008844ccde844ccdeee844ccdee84ccdee844ccdee84ccd4ee
08055500008d55400055ddd0000d5000000d55500005d0000000d0050000d0050000555500005550e8e555eee855eeee8e5555ee8e555eeee85d8eeee85d8eee
000d0500000d05005500000d000d50000dd000050005d000000d0050000d0050000dd0050000d005eeede5eeeede5eeeeddee5eeeddee5eeee5eddeeee5eddee
00d0055000d005500000000000d05000000000000050d00000d0000000d0000000d0005000dd0005eedee55eedeee5eedeee5eeedeeee5eeeee5eedeeee5eede
80808880080488000008800000080808008800008088000000808800eee22eeeeee11eee002e0000eeeebbee00000dd89438900000000000eeeeeeeeeeeeeeee
08488904088489040088880000888880088980000889800400088880ee229eeeee119eee0028e800eebbb9e40008355883d88d0000000000eeeeeeeeeeeeeeee
08844540088445400884590008459888084550008885544008884590e224deeee114deee08828e80bbb4544400d89345534d54400000bb00eeeeeeeeeeeeeeee
00885500008855000845540004554800884554000884550000845540e24ddeeee14ddeee02828e80eb4e55ee0d43d3d44d3554500000b300eeeeeeeeeeeeeeee
00055000000550000845440040554080808450400808440000405440224544ee114544ee082e2e20bee55eee0d3435888d534435000b3000eeeeeeeeeeeeeeee
000d5500000d5500008550000054000008d500008000d50008005500e2e55deee1e55dee00e88200ee55333e89354d895d345398000b3000eeeeeeeeeeeeeeee
000d0500000d050000d050000d05000000d0500000dd0500000d0500eeede5eeeeede5ee0002800055eeeee38834355355344388000b0000eeeeeeeeeeeeeeee
00d0500000d050000d005000d00550000d0050000000500000d00550eedee5deeedee5de00000000eeeeeeee4343b4b343b3434b00b30000eeeeeeeeeeeeeeee
00000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eeeee6667ee7ee776eee6e6777e7e00000000777700600777700706660070
00000000000000000000000000000000ee7eeeeeeeee7eeeeee6eeeeeeeee7ee7e666ee6ee7667e77e666ee6eee667e766666006007770607006770700066007
00000000000000000000000000000000ee77677eee7677eeee7677eee66777eee76666e7ee666667e7666676ee66666700666606077666600066677700666607
00000000000000000000000000070700ee6657eee77566eeee76577eee7567eee6657667e665566e76655667e667566607657666776556600665567706675667
00ee0000000000000077700070e7e707ee7566eeee66577ee77567eeee7657ee766556676665766e7667566ee665566e77655660766576606667567006655677
00e2200000e2e20007e2270007e2e270e77677eeee7767eeee7767eeee77766e6766667e766666ee7e66667e766666ee77766600706666006066660006666770
0e22e8000e2e2e800e22e8000e2e2e80eeeee7eeeee7eeeeeeee6eeeee7eeeee6ee666e77e766eee6ee666e77e7667ee70776007700660006006666606077700
022eee0002e2eee0022eee0002e2eee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6eee677ee7e7776eeeeee77ee7ee766670077770070066600000000006007777
00000000000000000000000000008000000000000000000000000000eeeeeeee2d2ddd2d2d2ddd2d0000000000000000000200000000000005555aa000000000
000000000000000000000000000000e0000000000000000000000000eeeeeeee2dcccc2d2d66662d0000000000022000000e000000000000055aa550000a0000
00cccc0000cccc000028e000000e00000000000000008e7000000000eeeeeeeedc6996c2d6dd666200222200002ee200000e00000002000000a555000a000a00
0c6996c00c6aa6c022228e0000000200000000000008e70000000000eeeeeeeedc9aa9cdd6d66d6d022ee220002ee200000e0000000e00000055500005050005
0c9aa9c00ca99ac00028e0000002000070000000008e700000000000eeeeeeee2c9aa9c226666d6202eeee20002ee200000e0000000e00000005a00050500a00
0c9aa9c00ca99ac00000000000000080e70000000827000000028e80eeeeeeeedc6996cdd66ddd6d022ee220002ee200000e000000020000000a000000a05005
0c6996c00c6aa6c0000000000000e0008e70000082e70000008e7778eeeeeeeed2cccc2dd266662d0022220000022000000e00000000000000050000a0555500
00cccc0000cccc000000000000000000082720002e28700002e70007eeeeeeee22dd2dd222dd2dd200000000000000000002000000000000000a0000055a5aa0
00000000cdcddcdc555555550c0d070dc0d0c0000070d0c00000000000022200000233200222000000022000000022020000000000000000009a8777000a8777
7707c077dddddddd55eeee55c070c0c0070c0000000c0c0d00000000002333200023388223332000002332020002332000000000000000009a88707009a87070
cc7cc7ccdddddddd5eeeeee50d0d0d0dc0d07000000070d0022200000023883200233332238332000238832000238832000000000000000009a8767699887676
cccccccc1d1dd1dd5eeeeee5c0c070c00c0d0c00000d0c0d2333200000233332000230022333320002333202002333200000000000000000000a8707009a8777
cdcddcdcd1dd1d1d5eeeeee50d0c0d0cd0c0d00000c0d0c023383200000232020023202002320020023220200232220260760700687607000000006000000000
dcdccdcc1d1dd1d15eeeeee5d0d0d0700d07000000070d0d02333200002320000232000000232000232000022320002077700707777007070000000000000000
cdcddcdd1111111155eeee55070c0c0dc0c0c0000000c07023222320023232002323000002323200323200003230000270770606787706060000000000000000
dddddddd1111111155555555d0c0d0c00c0d0700000c0d0c32323233232323203232000023232320232320002323000067706565677065650000000000000000
22222222eeeeeeee1111111122222222444444442222222200066600000666000006660000666000eeeee66eeeeeeeeeeeeeeeeeeee666eeeeee666eeeeeeeee
42929242d1c1c1d151616151526662554ff44fffd26662dd00688860006888600068886006888600eeee6886eeeeeeeeeeeeeeeeee68886eeee68886eeeeeeee
49999244dcccc1dd5666615556666255ff4ff4f4d66662dd00466860044668600444686044668600e4414486eeeeeceeeeeeceeeee46686eee144686eeeeeeee
49999244dcccc1dd566661555666625544444444d6666ddd0444160044411640044444444441600041114486eeeee7ceeeee7ceee44416eee414416eeeeeeeee
22222222eeeeeeee11111111222222224444444422222222044111404411114401144444441111001111446eeeeee7cdeeee7cdee441114e411441eeeeeeeeee
242929241d1c1c1d15161615552666254f4f4f4fdd26662d441111444411114401111144011111401111444eeeee7ccdeee7ccde441111444111444eeeeeeeee
44299994dd1ccccd5516666555266665f4fff4f4dd26666d4411114401111100d1111000011111405111144eeee7ccddee7ccdde44111144e111144eeeeeeeee
44299994dd1ccccd551666655526666544444444dd66666d00d5550000d55500d115550005551d005511444eeccccddeecccdddeeed555eeee555deeeeeeeeee
2222222244f444440000000000000000222222224494444400000000000000000000000000000000000000000000000000000000000000000000222222000000
4999944444444f4400060000000060004cc7ddd444444944000000000000000000000000000000000dd000000002200002222000002222000002028202220000
499994444f44444406050060060050604cccddd4494444440000000000000000000220000022000000dd200000112800000282000000282000001120d0282000
499994444444f44f05050050050050504cccddd4444494490000000000000000000028000002800010dd2800011dd22000012200000112200dd111100d122dd0
2222222244f4444405050050050050504dddc774449444440000000000000000000dd22000dd2200011dd22010dd00020011100000111000d00d111000d1d00d
444999944444444405560560065065504dddcc7444444444000000000000000000ddd10200dd10200000000200dd00000d111dd00dd111d000d0d0d0000d0d00
44499994f44444f456560565565065654dddccc4944444940505a0000005a00000dd10000ddd100000000000000d0000d0d0d00dd00d0d0d000d00d0000d00d0
444999944444f4446555655665565556444444444444944400566500055665000dd101000dd101000000000000000000d0000d0000d0000d00000d000000d000
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f2000000880000002000220022000000000000000000000000000002200220000
00000000000000000000000000000000000000000000000000000000000000002200008778000022000222002200000000002200220000000000002220022000
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f0220087887800220000022202220000000002220022000000000000222022200
00000000000000000000000000000000000000000000000000000000000000000222008778002220000022222220000000000222022200000000000222222200
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f0222228778222220000028828820000000000222222200000000000288288200
00000000000000000000000000000000000000000000000000000000000000000022111881112200000022222220000000000288288200000000333222222200
9d9d9d9d9d9d9d889d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f00211dd88dd11200003332222233300003333222222233000003333322002230
000000000000000000000000000000000000000000000000000000000000000000111ddd1dd111000333b22222bb33003333332222233330003333bb22002333
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f081121d1dd1211803333bbbb3bbb333033033b22222b3330003303bbb2002b33
0000000000000000000000000000000000000000000000000000000000000000888022111122088833003bbb3bb3033033003bbb3bb300330330033bb3202b33
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f8080255115520808330003335330003333300333533003330333003333322033
000000000000000000000000000000000000000000000000000000000000000080002552255200083330cc5555cc03333330ccc555cc033303330ccc555cc333
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f0802552202552080333ccc0555cc03330000ccc555ccc0000333ccc555cc3330
00000000000000000000000000000000000000000000000000000000000000000002d520025d2000000cc10550c10000000cc10550cc1000000cc1550cc13330
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f000ddd2002ddd00000c111000011100000c111000011100000c1110001110000
0000000000000000000000000000000000000000000000000000000000000000002dd020020dd200001111100111110000111110011111000011110001111000
9d9d9d9c9d9d9d9d9d9d9d9d9c9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f0000000880000000000110011000000000000000000000000000011110000000
00000000000000000000000000000000000000000000000000000000000000002000008778000002000111001100000000001100110000000000000111100000
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f2200087887800022000011101110000000001110011000000000000011110000
00000000000000000000000000000000000000000000000000000000000000000220008778000220000011111110000000000111011100a00000000111111000
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f022200877800222000a01881881000a09000011111110a0008a8001118181000
000000000000000000000000000000000000000000000000000000000000000002222289982222200a001111111000a009000188188100a0000a99a111110990
9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f00221118811122000a222111112220a0092221111111228a0000022a99aa989a
000000000000000000000000000000000000000000000000000000000000000000211dd88dd1120008a23111113322808a222211111228aa00889a88aa8a8a88
9d9d1f1f9d9d9d9d9d9d9d9d1f1f9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f00111ddd1dd111008aa2333323332aa8a882231111132980aa902299889888a8
0000000000000000000000000000000000000000000000000000000000000000081121d1dd12118098002333233202899a80233323320aa80000988a999aa99a
9d1f9d9d9d9d1f9d9d1f9d9d9d9d1f9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f8880251111520888aa800222522008aa88a0022252200a8800998aa2225008a0
00000000000000000000000000000000000000000000000000000000000000008800255225520088a880cc5555cc088a8aa0ccc555cc0999088000cc555cc000
1f9d9d9d9d9d9d9d9d9d9d449d9d9d1f1f9d9d9d9d9d9d9d9d9d9d9d9d9d9d1f0882555205552880999ccc0555cc09999980ccc555ccc00000011ccc550cc000
00000000000000000000000000000000000000000000000000000000000000000002d520025d2000000cc10550c10000000cc10550cc100000011c0550cc1000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f000ddd2002ddd00000c111000011100000c11100001110000011100001111000
0000000000000000000000000000000000000000000000000000000000000000002dd020020dd200001111100111110000111110011111000010000000011100
22d2d2d22d2d2d22000000022000000000000000000000006d2dddd62222255555522dd20000008008000000eeeeeeee0000000000000000eeeeeeeeeeeeeeee
002d2d2dd2d2d20000000002200000004000000000000004d66dd66ddd2555cc885552d20800009009000080eeeeeeee0000000001111110eeeeeeeeeeeeeeee
0002d2dddd2d20000000002222000000f40000000000004fd6866c6dd255000c8aad552d8900089009800098eeeeeeee0000000000000011eeeeeeeeeeeeeeee
00002d2dd2d20000000002d22d2000004f400000000004f4dd6d26dd25550000abbb55529a90099aa99009a9eeeeeeee0000000000000000eeeeeeeeeeeeeeee
000002d22d20000000002d2dd2d20000f4f4000000004f4f2d6dd6d225005000ab5555524440044444400444eeeeeeee0000011000000000eeeeeeeeeeeeeeee
00000022220000000002d2dddd2d200044ff40000004ff4fd6b6696d55a00500b55ccc554440044444400444eeeeeeee0001100111000000eeeeeeeeeeeeeeee
0000000220000000002d2d2dd2d2d200ff44f400004f44ffd66dd66d5a00005c55cbbbc50400004004000040eeeeeeee0110000000000000eeeeeeeeeeeeeeee
000000022000000022d2d2d22d2d2d224fff4f4004f4f4f46dddd2d65b0000055cb888b50400004004000040eeeeeeee0000000000000000eeeeeeeeeeeeeeee
04f444f44f444f4000000004400000004f4f4f4004f4fff400555000500000c555baa88500000011eeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeee
0044f444444f44000000000440000000ff44f400004f44ff0566650000000050c55bba8511000100eeeeeeeeeeeeeeee0000000011000001eeeeeeeeeeeeeeee
00004f4444f400000000004444000000f4ff40000004ff440566665000000500bc55ba5500101000eeeeeeeeeeeeeeee0000000000111110eeeeeeeeeeeeeeee
0000044444400000000004f44f400000f4f4000000004f4f06555665000000008bc5bd5200010000eeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeee
000000f44f00000000004444444400004f400000000004f456666565000000008bc5555210001000eeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeee
000000444400000000044f4444f44000f40000000000004f56556665000000008bc5552d00010100eeeeeeeeeeeeeeee0111110000000000eeeeeeeeeeeeeeee
00000004400000000044f444444f440040000000000000045666666000005cc8bc5552dd00100011eeeeeeeeeeeeeeee0000001100000000eeeeeeeeeeeeeeee
000000000000000044f444f44f444f44000000000000000036336363000005555552dddd11000000eeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeee
2222222256556556000000005050505050505050f4f4ff4f3b3b43b400000300003000001000001100009000000000000000067777600000eeee9eee00000000
02222222656665650000000055555555555555554f4ff4f433b33b4b00030030003000000100010000080000000000900006777777776000e9eeeeee40000040
0002d2dd566666560000000050505050505050504f4f4ff44343433b030b3030030030000010100000098000080009000067776676677600eeeeeeee00000000
00002d2d666555660000002050505050605050504ff4f4fff4444344030300b00303b03000010000080a9080008008000677667777777760eee9eee900004000
000002d25656566620000d2d5555555566555555f4ff4f444444f4440b0300300b0030300000100080098008008098000777777777777770eeeeeeee00000000
0000002256666665d2dd22dd50505050605050504f4f4ff44f444444300303b0030030b00001010089a9aa9808a99a806777666777767776eeeeeeee00000000
0000000265665556dd22dd2d50505050505050504f4f4f4f444444f44b33b4340b30300300100010899aa9988a9a9a9877667776777766779eeeee9e04000000
00000002565566562dd2d2d25050505050505050f4f4f4f44444f444b43b4343434b33b4110000010889998089a889897777667777777777eee9eeee00000400
2222222205555650000000002dd2d2d2d2d2d2d20000889aa999800000000000000000000009000000009000e4ee4ee47777777777777776eeee4efe00000100
2222222065666565000000002dddd2d22dd2d2d200000089aa8800000000000000000000000980000009a000e4ee4ee47776777777767776efeeeefe01000000
dd2d200056666655200000022dd2dd202dd2d2dd000088aa980000000000000000000000008980000008a8004ee4ee4e6777766777767776efe4ee4e00000000
d2d2000056656565d222222d02d2dd20d2d2dd2d0008999aaa88000000080000000000000089a8000089a8004ee4ee4e0777777777677770eee4fe4e00000000
2d200000565656652dddddd202dd2d20dddd2d2d000088aaa99980000009800000009000009a9a00009a9900e4ee4ee40677677776767760e4eefeee00001000
2200000056666665d2dddd2d02dd2d202d2d2ddd00000089aa880000008a90800808980008aaa9000089aa90e4ee4ee40067777777777600eefe4ee400000000
20000000556656552d2dd2d22d2ddd202d2dd2d2000088aa9800000008a9a8a009a99800089a9800008a9a804ee4ee4e00067777777760004efeeeee10000010
2000000006556550ddd22ddd22d2d2d2d2d2d2d20008999aa9880000a99aa99a9a8a9a890089a0000009a8004ee4ee4e00000777766000004ee4efee00000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000400001010800000000000000000000000000000000000008080000000000000808000000000000020208808080000000000000804000004001010101400000000000000000000040010202010500000000000000000000
0202020202020202000000000000000002020202020202020000000000000000020202020202020200000000000000000202020202020202000000000000000040404040404040404040400040400000010101014040014040400000404040400101404001400140404000004040404001014040400202000000004040404040
__map__
ffffffffffffffffffffffffffffffffffffffccffffffffffffffffffffffffffdcffffffffffffffdcffffffffffffffffccffffffffffffffffffffffffffffffffffffffccffffffcdffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffccffffdcffffffffffffffccddcdffffffffffffffffffccffffffffffffcdffccffffffffffffddffffffccffffffffffffffffffddffffffffffcdffffffffddffffffffffffcdfffffffffffffffffffffffffffffffffffffffffffffffff2ffffffffffffdd
ffffffffffffffffffffffffffffffffffddffdcffccffffffffffffcdffffffccffffffffffc2f2f2f2f2f2c3ffcdffffdcffffccffffffffcdffffddccffffff635dffffffffff63ffff63ffffffffffffffffffffccffffffcccdffffffffffffffffffffffddffffffffffffdcffffdddcffffffffff65ffffffdccdffff
ffffffffffffffffffcccccdffffffffffffffffffffffffffffffffffffffffffffffffffc2c14e0000004ec0c3ffffffffffffffffffffffffffffffffffffff636363ff63ffffffffff4effffffffddffccffffffffffffffffffffccffffffffffccffffffffffdcffffddffffffffccffffffffffe265c3ffffdcdddccd
ffddcdffffffffffffffffffffffffffffffc2f2f2f2f2f2f2f2f2f2f2f2f2c3ffc2f2f2f2c100000000000000c0f2f2f2f2f2f2c3ffc2f2f2f2f2c3ff40ffffff634ec0636363ffffffffffffffffffffffffffffddffffffccffffffffffffffffffffffffffffffffffffffffffffdddcddffffffff656565c3ffffffffff
ffffffffffffffffc5d4ffffffcccdffffc2c1c0c1c0f4c1c0c1c0f4c1c0c1c0f4c100c0f4000000000000000000f4c10000004ec0f4c100000000c0f2f0ffffff630000000000e063ffccddffcd63f0ffddffdcffffffffffffcdffffffddffffffffffffccffdcffffdddcffdddcffccffccffffffff65656565ffffffffff
ffffffffc5ffcdffd5c4fffffffffffffff300000000f300000000f300000000f3000000f3000000000000000000f3000000000000f3000000000000f3ffffffff63000000000000c0630000000063ffffffffffffff78ffffffffffffffffffffffccffffffffffffddffecedccffffdcffffdcffffffc7c86565c3c2ffffff
ffffffffd5c4ffffc5d4ffcdfffffffffff300000000f300000000f300000000f3000000f3000000000000000000f3000000000000f3000000000000f3ffffffff630000000000000000005d630063ffffcdffffffff7060ffffffddffccffffffffffffffffffffddccddfcfddcddffffccffffffddffd7d865ffc0f4ffffff
ffffccffffd5c4c5d4ffffffffffd5c4fff300000000f300000000f300000000f3000000f30000000000000000636363f000000000f3000000000000f3ffffffff6300000000636363636363c10063ffffffffffff7060707078ffffffffddffddffffffffdccdffffcddccdffffccffffffdccdffffffff6565e2fff3ffffff
ffccffddffffd5e5ffffffc5ffffc5d4fff300000000f300000000f300000000f3006363630000000000e0f000c0f4c10000000000f3000000000000f3dcffffcd6300000063c10000000000000063ffffffffff607070607060ffffffffffffffffffffffdcdddccddcffddccffffdcccdcdcdddccdffe2656565e2f3ffffff
ffffffffc5c4ffe5c5d4ffd5c4c5d4fffff300000000f300000000f3006600636363634ef300e0f0000000000000f3000000000000f300000000005af30000000063000063c1000000000000000063ffffffffff7060707070706464646464ffffffffcccdffffdcddffffffddccffffffcdffffffffe2656565656565c3ffff
5cffffd5d4d5c4e5d4ffccffd5e5c5c4fff300000000f300005a6363636363636363c100f3000000000000000000f300000000e06363630000000063c10000000063635c0076006363636300000063ffffffffff70747060746000c5d4ffffffffcdffdcddffffffffffffddffffcdffdccdffffffffc66565c6656565c0ffff
5c5cffffffffd5e5ffffffffffe5d4fffff300000000f300636363636363636363c10000f3000000000000000000f3000000000000f3c063000000000000000000c06363636363c1000000000063c1ffffffff63607070706070c5d40000ffffffffffffffffffffffff63ffffdccdffffffffffffe265c1c065656565ffffff
efe4ffffffffffe5ffffffffffe5fffffff3000000636363636363637575757575000000f30000e0f00000000000f3000000000000f300c063000000000000000000f300000000000000000063c1006363e2e2c07060e3e37060d400000000ffffffffffffffff63dd0000dcff63ffffffffffffff65c18affc0656565ffffff
efe4e82b2ce8e8e53072d6ff30e5ffffc2f4c363757575757575757575757575755c000063000000005c0063e2c2f4c300000066c2f4c30075000000006600636300f300000000000066637575006363636363ff6070e3e360700000000000f1f1ffffffff7c63c10000000000c063ffffe2ffffe265ffffffff656565ffe2c3
efe6717171e6e6e671e6e65ce6e671e66363636363636363637171717171717171e6e6e663737372727373636363636362626262626262757575626262626262626262626262626262757575757575626262626262626262626250f1505050626262626262626250505050505050626262626262626262626262626262626262
efefd07171717171717171717171717171717171717171717171717171717171717171716363636363636363636363636363717171717171717171717171717162626262627171717171717171717171717171717171717171515151515151f1f1f1f1f1f1f1f171717171717171717171717171717171717171717171717171
efefefd071d1d07171717171717171717171717171717171717171717171d0d1d07171d1eff4c1ffffc0f4efefefefefefefefefefefefefefefefefd071d1efefefefefefd075d1efefefefef4eefefefefefefefd071717151515151515151f1f1f1f1f1f1f17171717171f1717171717171717171d1d0d1d071d1d0717171
e0efefefefefefd0717171717171d1d071d1d0717171d14ed071d14e71d1efefefefefefeff3ff2dfffff3efefefefefefefefefefefefefefefefefef4eefefefefef7cefef75efefefefefefefefefefefefefefefefd0717151f151515171f1f1f1f1f1f1717171f1717171717171717171d071d1ffffffff71ffff71d171
efe0efefefefefef4ed0717171d1efefd1efef4ed071efefef71efefd1efefefefefefefeff1f1f1f1f1f1efefefefefef72e1e1e1e1e1e1e1e1e1efefefefefef72e1e1e1e1e1e1e1e1e1efefefefefefefeff1efefefefd0715371535371717171717171717171717171d1d071f171f671d1ffd1ffffffffffd0ffffd0fff5
efefe0efefefefefefef7171d1efefefefefefefef71efefefd1efefefefefefefefefeff1f1e9e9e9e9f1f1efefefefefe1c1e9e9e9e9e9e9e9c0e1efefefefefe1c1e9e9e1e9e9e9e9c0e1efefefefefefefc0f1efefefef555353535354717171717171717171d1ffffffffd07171f6d1fffffffffffffffffffffffffff5
efefefefefefefefefefd071efefefefefefefefefd0efefefefefefefefefefefefeff1f1e9e9e9e9e9e9f1f1efefefefe1e9e9e9e9c9e9e9e9e9e9e9e1e1e1e1e1e9e9e9e9e9e9c9e9e9e9e9e9e1e1e172efefc0f1efefef555353535354d07171717171d1d0d1ffffffffffffffd0f6fffffffffffffffffffffffffffff5
efefefeff0efefefefefef71efefefefefefefefefefefefefefefefefefefefefeff1f1e9e9e9e9e9e9e9e9f1e1efefefe1e9e9e9e9e9e9e9e9e9e9e1c1e9e9e9e9e9e9e9e9e9e9e9e9e9e9e1e1e1e1e1c1efefefc0f156ef555353535354efd0717171d1fffffffffffffffffffffff6ffffffffffffffffffffffffffc3f5
efefeff0efefefefefefefd0efefefefefefefefefefefefefefefefefefefefef72f1e9e9e9e988e9e9e9e9e9e1e1ef5ce140e9e966e9e9e9e9e1e9e9e9c9e9e9e9e9e9e9e1e966e9e9e9e1e9e9e9e9e9efefefefefc0f1f1f1f153535354efffd071d1ffffffffffffffffff78fffff6c2ffffffffffffffffc2ffffc2c1f5
efeff0efefefefefefefefefefefefefefefefefefefefefefefefefefefefef72f1e9e9e9c9e9e9e9e9c9e9e9e9e17272e1e1e1e1e1e1e1e1e1c1e9e9e9e9e9e9e1e9e9e1e1e1e1e1e1e1e140e9e9c9e9efefefefefefef4e555554f1535456ffffffffffffff78ffffffffc2c1fffff6c0c3ffffc3ffffffffc0c3c2c1fff5
eff0efefefefefefefefefefefefefefefefefefefefefefefefefefefefefeff1e9e9e9e9e9e9e9e9e9e9e9e9e9e9e1e1c1e9e9e9e9e9e9e9e9e9e9e1e1e1e1e1c1e9e1c1e9e9e9e9e9e9c0e1e9e9e9e9efefefefefefefef5555545555f1f1ffffffffffffffc0c3ffffffc0c3fffff6ffc0c3c2c1ffc2c3ffffc049fffff5
efefefefefefefefefefefefefefefefefefefefefd071d1efefef7cefefefeff4e9e9e9e9e9e9e9e9e9e9e9e9e9e9f4f4e9e9e9e9e9c9e9e9e9e9e1c1e9e9e9e9e9e9e9e9e9c9e9e9e9e9e9e9e9e1e1e1f0efefefefefefef555554f1f154efffffffffffffffc2c1ffffffc2f4c1fff6ffff49c1ffc24949c3fffff3fffff5
71d1efefefefefefefefefefefefefefefefefefd071d1d0717171717171d1eff4c3e9e9e9e9e9e9e9e9e9e9e9e9c2f4f4c3e9e9e9e9e9e9e9e9e1c1e9e9e9e9e9e9e9e9e9e9e93ce9e9e9e9e95dc0e1e1efefefefef56efef55f154555554efffffffffffffffc0c3ffffffc1c0c3fff6ffc2c1ffc2c1ffffc0c3ffc0c3fff5
7171d1efefefefefefefefefefefefefefefefd071d1000000000000d071d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e9e9e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1efefefefeff1f1ef555554555454effffffffffffffffff3fffffffffff3fff6fff3fffff3fffffffff3fffff3fff5
f17171d1efefefefefefefefefefefefefefd071d1000000000000000075f1f1f10000000000f1000000003c00000000000000000000000000000000c0f10000000000000000000000000000000000e1e1efefefefefefeff1f15554555454efffffffffffffff5af3fffffffffff3fffffff3fffff3ffaafffff3fffff3fff5
f1f1d1ef32efefeff172efefefef32f1f1d071d10040f15c00440000007575755d770000003c00000000e100000000f1f1000000003c00000000003c00000000000000003c0000000000003f0000000000efefefefefefefef5555f15050f1efffe7e8e8e7e8f1f1f1f8f8f1f8f8f1f1f1c2c1ffc2c1ffffffffc0c3ffc0c3f5
f1f1f1eff1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f17171e6e6e6e6e6e6e6e6e6e6e6e6e6e6f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
__sfx__
01040000350703507030070330702b070300702b070300603505027040270402b030290202b020300103001027050250501f0501c0501d0502105024050210501e0501d0501c05039050370501e050170500f050
0110000028070000000000000000280700000029070000002b07000000000000000028070000002b070000002d070000002b07000000280700000000000000002607000000000000000024070000000000000000
0110000024070000000000000000280700000000000000001f0700000000000000002807000000000000000024070000000000000000280700000000000000001f07000000000000000028070000000000000000
0110000022070000000000000000260700000000000000001d0700000000000000002607000000000000000022070000000000000000260700000000000000001d07000000000000000026070000000000000000
01100000290700000000000000002d0700000000000000002b0700000029070000002607000000240700000022070000001c0701d070000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01024141
02 03044141
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
