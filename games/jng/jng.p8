pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

----------------------------------------------------------------
-- run with: ./pico-8/pico8 -run ./jng.p8 -desktop . -windowed 0
----------------------------------------------------------------

----------------------------------------------------------------
-- init
----------------------------------------------------------------
function _init()
   init_archetypes()
   init_game()
   --debug options
   debug = {}
   debug.cnummodes = 6 --none,movebox,damagebox,attackbox,visualbox,anim
   debug.mode = 0
   debug.paused = false
   debug.messages = {}
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
      if game.t % 60 == 0 then
         pal(0,7)
         palt(0,false)
      elseif game.t % 59 == 0 then
         pal(0,12)
         palt(0,false)
      else
         pal()
         palt(0,true)
      end
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
         if e.a == a_skullboss or e.a == a_flameboss then
            spr( anm.k[ 1 + act.t % #anm.k ],
                 e.p1.x, e.p1.y,
                 2,2,
                 e.sign<0 )
         else
            if anm.c then
               spr( anm.k[ 1 + act.t % #anm.k ],
                    e.p1.x, e.p1.y,
                    1,1,
                    e.sign<0 )
            else
               spr( anm.k[ min(1+act.t,#anm.k) ],
                    e.p1.x, e.p1.y,
                    1,1,
                    e.sign<0 )
            end
         end
      end
      if debug.mode > 0 then
         print_action( e.action, e.p1.x-4, e.p1.y-4  )
      end
   end

   --player
   -- temp: disabled to see "normal" colors
   -- if player.is_mutated then
   --    pal(8,11)
   --    pal(13,3)
   -- end
   if player.invulnerability_t % 2 == 0 then
      local anm = g_anim[player.state]
      if player.state == 6 and player.sign*player.v.x < 0 then
         anm = g_anim[7]
      end --hack: draw backwards jump shoot
      if anm.c then
         spr( anm.k[1+player.t%#anm.k],
              player.p1.x, player.p1.y,
              1,1,
              player.sign<0 )
      else
         spr( anm.k[ min(1+player.t,#anm.k) ],
              player.p1.x, player.p1.y,
              1,1,
              player.sign<0 )
      end
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

   if debug.mode > 0 then
      --entity boxes
      for e in all(room.entities) do
         if debug.mode == 1 and e.a.cmovebox != nil then
            local movebox = aabb_apply_sign_x(e.a.cmovebox,e.sign)
            rect( e.p0.x + movebox.min.x,
                  e.p0.y + movebox.min.y,
                  e.p0.x + movebox.max.x-1,
                  e.p0.y + movebox.max.y-1,
                  3 )
            rect( e.p1.x + movebox.min.x,
                  e.p1.y + movebox.min.y,
                  e.p1.x + movebox.max.x-1,
                  e.p1.y + movebox.max.y-1,
                  11 )
         end
         if debug.mode == 2 and e.a.cdamagebox != nil then
            local damagebox = aabb_apply_sign_x(e.a.cdamagebox,e.sign)
            rect( e.p1.x + damagebox.min.x,
                  e.p1.y + damagebox.min.y,
                  e.p1.x + damagebox.max.x-1,
                  e.p1.y + damagebox.max.y-1,
                  8 )
         end
         if debug.mode == 3 and e.a.cattackbox != nil then
            local attackbox = aabb_apply_sign_x(e.a.cattackbox,e.sign)
            rect( e.p1.x + attackbox.min.x,
                  e.p1.y + attackbox.min.y,
                  e.p1.x + attackbox.max.x-1,
                  e.p1.y + attackbox.max.y-1,
                  12 )
         end
         if debug.mode == 4 and e.a.cvisualbox != nil then
            local visualbox = aabb_apply_sign_x(e.a.cvisualbox,e.sign)
            rect( e.p1.x + visualbox.min.x,
                  e.p1.y + visualbox.min.y,
                  e.p1.x + visualbox.max.x-1,
                  e.p1.y + visualbox.max.y-1,
                  10 )
         end
      end

      if debug.mode == 1 then
         -- debug info
         print("t:"..game.t/10,1,1,7)
         print("a:"..g_anim[player.state].n,108,1,7)
         print("mem:"..stat(0),1,122,7)
         print("cpu:"..stat(1),84,122,7)
      end

      --animations
      if debug.mode == 5 then
         local n=0
         for a in all(g_anim) do
            local i = flr(n/6)
            local j = flr(n%6)
            spr( a.k[1+game.t%#a.k],
                 10+20*j,
                 10+10*i )
            n+=1
         end
      end

      if true then
         for c in all(player.ground_ccd_1) do
            rect( c.point.x, c.point.y, c.point.x + 11*c.normal.x, c.point.y + 11*c.normal.y )
         end

         for b in all(room.bullets) do
            for c in all(b.handled_collisions) do
               rect( c.point.x, c.point.y, c.point.x + 11*c.normal.x, c.point.y + 11*c.normal.y )
            end
         end
      end
   end

   for s in all( debug.messages ) do
      print( s )
   end
end

----------------------------------------------------------------
-- archetypes
----------------------------------------------------------------
function init_archetypes()

   --global animation table
   g_anim={}

   --level
   a_level = {}
   a_level.cnumrooms = v2init( 8, 3 )
   a_level.cgravity_y = 0.5

   --rooms
   a_room = {}
   a_room.csizes = v2init( 128, 128 )

   ---- entities
   --player
   a_player = {}
   a_player.table_anm = {}
   a_player.table_anm["idle"] = {n="idl" ,c=true ,k={16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17}}
   a_player.table_anm["run"]  = {n="run" ,c=true ,k={18,18,18,18,18,18,19,19,19,19,20,20,20,20,20,20,21,21,21,21}}
   a_player.table_anm["jump"] = {n="jmp" ,c=false,k={22,22,22,22,23,23,23,23,24,24,24,24,25,25,25,25}}
   a_player.table_anm["fall"] = {n="fall",c=true ,k={32,32,32,32,33,33,33,33}}
   a_player.table_anm["shi"]  = {n="shi" ,c=true ,k={8,8,9,9,9}}
   a_player.table_anm["shj"]  = {n="shj" ,c=true ,k={12,12,13,13}}
   a_player.table_anm["shjb"] = {n="shjb",c=true ,k={14,14,15,15}} --same #frames as "shj"
   a_player.table_anm["hit"]  = {n="hit" ,c=false,k={34,34,34,34,34,
                                                     35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35 }}
   a_player.table_anm["hitb"]  = {n="hitb",c=false,k={36,36,36,36,37,37,37,37,38,38,38,38}}
   a_player.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_player.cmovebox   = aabb_init( 1, 1, 7, 7 )
   a_player.cdamagebox = aabb_init( 2, 1, 6, 7 )
   a_player.cattackbox = nil
   a_player.cmaxvel = v2init( 5, 5 )
   add( g_anim, a_player.table_anm["idle"] )
   add( g_anim, a_player.table_anm["run"] )
   add( g_anim, a_player.table_anm["jump"] )
   add( g_anim, a_player.table_anm["fall"] )
   add( g_anim, a_player.table_anm["shi"] )
   add( g_anim, a_player.table_anm["shj"] )
   add( g_anim, a_player.table_anm["shjb"] )
   add( g_anim, a_player.table_anm["hit"] )
   add( g_anim, a_player.table_anm["hitb"] )

   --enemies--
   --caterpillar
   a_caterpillar = {}
   a_caterpillar.table_anm = {}
   a_caterpillar.table_anm["move"] = {c=true,k={48,48,48,48,48,48,49,49,49,49,49,49}}
   a_caterpillar.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_caterpillar.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_caterpillar.cdamagebox = aabb_init( 1, 4, 7, 8 )
   a_caterpillar.cattackbox = aabb_init( 1, 4, 7, 8 )
   a_caterpillar.cspeed = 0.5
   a_caterpillar.chealth = 1
   add( g_anim, a_caterpillar.table_anm["move"] )

   --caterpillar2 (angry)
   a_caterpillar2 = {}
   a_caterpillar2.table_anm = {}
   a_caterpillar2.table_anm["move"] = {c=true,k={50,50,50,50,51,51,51,51}}
   a_caterpillar2.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_caterpillar2.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_caterpillar2.cdamagebox = aabb_init( 0, 2, 8, 8 )
   a_caterpillar2.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_caterpillar2.cspeed = 1
   a_caterpillar2.chealth = 2
   add( g_anim, a_caterpillar2.table_anm["move"] )

   --saw
   a_saw = {}
   a_saw.table_anm = {}
   a_saw.table_anm["move"] = {c=true,k={60,61,62,63}}
   a_saw.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_saw.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_saw.cdamagbox  = nil
   a_saw.cattackbox = aabb_init( 2, 2, 6, 6 )
   a_saw.cspeed = 1
   a_saw.chealth = 1
   add( g_anim, a_saw.table_anm["move"] )

   --stalactite
   a_stalactite = {}
   a_stalactite.table_anm = {}
   a_stalactite.table_anm["idle"] = {c=true,k={77}}
   a_stalactite.table_anm["move"] = a_stalactite.table_anm["idle"]
   a_stalactite.table_anm["hit"]  = {c=true,k={78,78,78}}
   a_stalactite.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_stalactite.cmovebox   = aabb_init( 1, 1, 7, 7 )
   a_stalactite.cdamagbox  = nil
   a_stalactite.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_stalactite.cspeed = 5
   a_stalactite.chealth = 1
   add( g_anim, a_stalactite.table_anm["move"] )
   add( g_anim, a_stalactite.table_anm["hit"] )

   --grunt
   a_grunt = {}
   a_grunt.table_anm = {}
   a_grunt.table_anm["idle"] = {c=true,k={102,102,102,102,102,102,103,103,103,103,103,103}}
   a_grunt.table_anm["move"] = {c=true,k={105,105,105,105,104,104,104,104}}
   a_grunt.table_anm["attack"] = {c=true,k={105,105,105,105,105,105,105,105,
                                            104,104,104,104,104,104,
                                            105,105,105,105,105,105,105,105,
                                            106,106,106,106,106,106}}
   a_grunt.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_grunt.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_grunt.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_grunt.cattackbox = aabb_init( 0, 0, 8, 8 )
--   a_grunt.cspeed = 0.5
   a_grunt.cspeed = 1
   a_grunt.chealth = 4
   add( g_anim, a_grunt.table_anm["idle"] )
   add( g_anim, a_grunt.table_anm["move"] )
   add( g_anim, a_grunt.table_anm["attack"] )

   --cthulhu
   a_cthulhu = {}
   a_cthulhu.table_anm = {}
   a_cthulhu.table_anm["move"]   = {c=true,k={86,86,86,86,87,87,87,87,88,88,88,88,89,89,89,89}}
   a_cthulhu.table_anm["attack"] = {c=false,k={90,90,91,91}}
   a_cthulhu.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_cthulhu.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_cthulhu.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_cthulhu.cattackbox = aabb_init( 1, 3, 7, 8 )
   a_cthulhu.cspeed = 0.4
   a_cthulhu.chealth = 2
   a_cthulhu.cshootpos = v2init( 7, 0 )
   add( g_anim, a_cthulhu.table_anm["move"] )
   add( g_anim, a_cthulhu.table_anm["attack"] )

   --mouse
   a_mouse = {}
   a_mouse.table_anm = {}
   a_mouse.table_anm["move"] = {c=true,k={118,118,118,118,118,119,119,119,119,119}}
   a_mouse.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_mouse.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_mouse.cdamagebox = nil
   a_mouse.cattackbox = nil
   a_mouse.cspeed = 0.3
   a_mouse.chealth = 1
   add( g_anim, a_mouse.table_anm["move"] )

   --bird
   a_bird = {}
   a_bird.table_anm = {}
   a_bird.table_anm["idle"] = {c=true,k={120,120,120,120,121,121,121,121}}
   a_bird.table_anm["move"] = {c=true,k={122,122,122,122,122,123,123,123,123,123}}
   a_bird.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_bird.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_bird.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_bird.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_bird.cspeed = 1.25
   a_bird.chealth = 1
   add( g_anim, a_bird.table_anm["idle"] )
   add( g_anim, a_bird.table_anm["move"] )

   --arachno
   a_arachno = {}
   a_arachno.table_anm = {}
   a_arachno.table_anm["move"] = {c=true,k={124,124,124,124,124,125,125,125,125,125}}
   a_arachno.table_anm["jump_up"] = {c=true,k={126}} --up
   a_arachno.table_anm["jump_down"] = {c=true,k={127}} --down
   a_arachno.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_arachno.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_arachno.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_arachno.cattackbox = aabb_init( 1, 3, 7, 8 )
   a_arachno.cspeed = 0.75
   a_arachno.chealth = 2
   add( g_anim, a_arachno.table_anm["move"] )

   --teeth
   a_teeth = {}
   a_teeth.table_anm = {}
   a_teeth.table_anm["move"] = {c=true,k={68,68,68,69,69,69,69,69,69,69,69,70,70,70}}
   a_teeth.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_teeth.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_teeth.cdamagbox  = nil
   a_teeth.cattackbox = aabb_init( 1, 2, 6, 8 )
   a_teeth.cspeed = 1.5
   a_teeth.chealth = 1
   add( g_anim, a_teeth.table_anm["move"] )

   --bullets
   a_blast = {}
   a_blast.table_anm = {}
   a_blast.table_anm["move"] = {c=true,k={1,1,1,2,2,2,3,3,3,2,2}}
   a_blast.table_anm["hit"]     = {c=true,k={4,4,5,5,6,6,6,7}}
   a_blast.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_blast.cmovebox   = nil
   a_blast.cdamagbox  = nil
   a_blast.cattackbox = aabb_init( 4, 3, 8, 4 )
   a_blast.cspeed = 4
   add( g_anim, a_blast.table_anm["move"] )
   add( g_anim, a_blast.table_anm["hit"] )

   --enemy bullets
   a_spit = {}
   a_spit.table_anm = {}
   a_spit.table_anm["move"] = {c=true,k={66}}
   a_spit.table_anm["hit"]  = {c=false,k={67,67,67}}
   a_spit.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_spit.cmovebox   = aabb_init( 4, 3, 7, 4 )
   a_spit.cdamagbox  = nil
   a_spit.cattackbox = aabb_init( 3, 3, 6, 4 )
   a_spit.cspeed = 3

   add( g_anim, a_spit.table_anm["move"] )
   add( g_anim, a_spit.table_anm["hit"] )

   a_flame = {}
   a_flame.table_anm = {}
   a_flame.table_anm["idle"] = {c=true,k={247,247,247,248,248,248}}
   a_flame.table_anm["move"] = {c=true,k={249,249,249,250,250,250}}
   a_flame.table_anm["hit"] = {c=false,k={234,234,234,235,235,235, --hit
                                          247,247,247,248,248,248, --remain 30 frames (1 sec)
                                          247,247,247,248,248,248,
                                          247,247,247,248,248,248,
                                          247,247,247,248,248,248,
                                          247,247,247,248,248,248 }}
   a_flame.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_flame.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_flame.cdamagbox  = nil
   a_flame.cattackbox = aabb_init( 2, 4, 7, 8 )
   a_flame.cspeed = 1
   add( g_anim, a_flame.table_anm["idle"] )
   add( g_anim, a_flame.table_anm["move"] )
   add( g_anim, a_flame.table_anm["hit"] )

   a_skull = {}
   a_skull.table_anm = {}
   a_skull.table_anm["move"] = {c=true,k={94,94,94,94,94,95,95,95,95,95}}
   a_skull.table_anm["hit"]  = a_skull.table_anm["move"] --todo
   a_skull.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_skull.cmovebox   = aabb_init( 4, 3, 7, 4 )
   a_skull.cdamagbox  = nil
   a_skull.cattackbox = aabb_init( 4, 3, 7, 4 )
   a_skull.cspeed = 2
   add( g_anim, a_skull.table_anm["move"] )

   -- collectables
   a_orb = {}
   a_orb.table_anm = {}
   a_orb.table_anm["idle"] = {c=true,k={64,64,64,65,65,65}}
   a_orb.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_orb.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_orb.cdamagbox  = nil
   a_orb.cattackbox = nil
   a_orb.cspeed = 0
   add( g_anim, a_orb.table_anm["idle"] )

   --env entities
   a_torch = {}
   a_torch.table_anm = {}
   a_torch.table_anm["idle"] = {c=true,k={201,201,201,202,202,202}}
   a_torch.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_torch.cmovebox   = nil
   a_torch.cdamagbox  = nil
   a_torch.cattackbox = nil
   a_torch.cspeed = 0
   add( g_anim, a_torch.table_anm["idle"] )

   --bosses
   a_skullboss = {}
   a_skullboss.table_anm = {}
   a_skullboss.table_anm["idle"] = {c=true,k={138,138,138,140,140,140}}
   a_skullboss.table_anm["move"] = {c=true,k={138}}
   a_skullboss.table_anm["attack"] = {c=true,k={142}}
   a_skullboss.table_anm["jump_up"] = {c=true,k={142}}
   a_skullboss.table_anm["jump_down"] = {c=true,k={138}}
   a_skullboss.cvisualbox = aabb_init( 0, 0, 16, 16 )
   a_skullboss.cmovebox   = aabb_init( 0, 0, 16, 16 )
   a_skullboss.cdamagebox = aabb_init( 4, -1, 13, 9 )
   a_skullboss.cattackbox = aabb_init( 0, 0, 16, 16 )
   a_skullboss.cspeed = 1
   a_skullboss.chealth = 10
   a_skullboss.cshootpos = v2init( 10, 6 )
   add( g_anim, a_skullboss.table_anm["idle"] )
   add( g_anim, a_skullboss.table_anm["attack"] )

   a_flameboss = {}
   a_flameboss.table_anm = {}
   a_flameboss.table_anm["idle"] = {c=true,k={170,170,170,172,172,172}}
   a_flameboss.table_anm["move"] = {c=true,k={170}}
   a_flameboss.table_anm["attack"] = {c=true,k={174}}
   a_flameboss.cvisualbox = aabb_init( 0, 0, 16, 16 )
   a_flameboss.cmovebox   = aabb_init( 0, 0, 16, 16 )
   a_flameboss.cdamagebox = aabb_init( 0, 0, 16, 16 )
   a_flameboss.cattackbox = aabb_init( 0, 0, 16, 16 )
   a_flameboss.cspeed = 1
   a_flameboss.chealth = 10
   add( g_anim, a_flameboss.table_anm["idle"] )
   add( g_anim, a_flameboss.table_anm["attack"] )

   -- assoc bullets with enemies
   a_cthulhu.cshoottype = a_spit
   a_skullboss.cshoottype = a_skull

end

----------------------------------------------------------------
-- game
----------------------------------------------------------------
function init_game()
   --game
   game = {}
   game.t = 0

   --player
   player = { a = a_player,
              state = 1,
              t = 0,
              p0 = v2init( 3.5*8, 3*8 ),
              p1 = v2init( 3.5*8, 3*8 ),
              sign = 1,
              v = v2zero(),
              on_ground = false,
              is_mutated = true,
              jump_s = 0,  --original jump direction
              invulnerability_t = 0 } --frames remaining

   --level
   level = {}
   level.a = a_level
   level.room_coords = v2init( 7, 0 )
   --room
   room = new_room( a_room, level.room_coords )
end

----------------------------------------------------------------
-- player
----------------------------------------------------------------
--- ccd movement with strong non-penetration guarantee on static map tiles
function update_player()

   debug.messages = {}

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
      if player.is_mutated and player.v.y >= 0 then
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
   -- then handle collisions with damage map2 important: we do it in a
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
   end

   -- check on ground for next frame
   player.ground_ccd_1 = ccd_box_vs_map( player.p0, v2add( player.p1, v2init(0,1) ),
                                         movebox,
                                         1+2, --flags: 0 is_solid, 1 is_damage
                                         false ) --all collisions
   player.on_ground = false
   for c in all(player.ground_ccd_1) do
                              --add( debug.messages, "ground(p1) "..c.normal.x..","..c.normal.y )
      if c.normal.y < 0 and player.v.y >= 0 then --todo could filter by y-component values for inclined ground
         player.on_ground = true
      end
   end

   -- change room
   -- todo: access room-specific archetypes a_room[j][i] from map
   if player.v.x > 0
      and player.p1.x > 16 * 8 - movebox.max.x
      and level.room_coords.x < level.a.cnumrooms.x-1 then
      level.room_coords.x += 1
      room = new_room( a_room, level.room_coords )
      player.p1.x = movebox.min.x
      --add( debug.messages, "room_x "..level.room_coords.x )
   elseif player.v.x < 0
      and player.p1.x < movebox.min.x
      and level.room_coords.x > 0 then
      level.room_coords.x -= 1
      room = new_room( a_room, level.room_coords )
      player.p1.x = 16*8 - movebox.max.x
      --add( debug.messages, "room_x "..level.room_coords.x )
   elseif player.v.y > 0
      and player.p1.y > 16 * 8 - movebox.max.y
      and level.room_coords.y < level.a.cnumrooms.y-1 then
      level.room_coords.y += 1
      room = new_room( a_room, level.room_coords )
      player.p1.y = movebox.min.y
   elseif player.v.y < 0
      and player.p1.y < movebox.min.y
      and level.room_coords.y > 0 then
      level.room_coords.y -= 1
      room = new_room( a_room, level.room_coords )
      player.p1.y = 16*8 - movebox.max.y
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
   local r = {}
   --init
   r.a = archetype
   r.enemies = {}
   r.entities = {}
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

function new_room_process_map_cell( r, room_j, room_i, map_j, map_i )
   local m = mget( map_j, map_i )
   local e = nil
   local pos = v2init( room_j*8, room_i*8 )
   if m == 48 then
      e = new_enemy( a_caterpillar, pos, new_action_patrol( pos, -1 ) )
   elseif m == 50 then
      e = new_enemy( a_caterpillar2, pos, new_action_patrol( pos, -1 ) )
   elseif m == 86 then --cthulhu_shooter
      e = new_enemy( a_cthulhu, pos, new_action_shoot( 30 ) )
   elseif m == 89 then --cthulhu_patroller
      e = new_enemy( a_cthulhu, pos, new_action_patrol( pos, -1 ) )
   elseif m == 102 then
      e = new_enemy( a_grunt, pos, new_action_wait_and_ram( pos, -1 ) )
   elseif m == 118 then
      e = new_enemy( a_mouse, pos, new_action_patrol( pos, -1 ) )
   elseif m == 120 then
      e = new_enemy( a_bird, pos, new_action_wait_and_fly( pos, -1 ) )
   elseif m == 124 then
      e = new_enemy( a_arachno, pos, new_action_patrol_and_jump( pos, -1 ) )
   elseif m == 60 then --saw l2r
      e = new_enemy( a_saw, pos, new_action_oscillate( pos, v2init(1,0), 4*8, 300 ) )
   elseif m == 63 then --saw r2l
      e = new_enemy( a_saw, pos, new_action_oscillate( pos, v2init(-1,0), 4*8, 300 ) )
   elseif m == 68 then
      e = new_enemy( a_teeth, pos, new_action_patrol( pos, -1 ) )
   elseif m == 77 then
      e = new_enemy( a_stalactite, pos, new_action_wait_and_drop( pos ) )
   elseif m == 247 then
      e = new_enemy( a_flame, pos, new_action_wait_and_drop( pos ) )
      --these are not enemies but entities
   elseif m == 201 then
      e = new_enemy( a_torch, pos, new_action_idle() )
   elseif m == 64 then
      e = new_enemy( a_orb, pos, new_action_idle() )
      --bosses
   elseif m == 138 then
      e = new_enemy( a_skullboss, pos, new_action_skullboss() )
   elseif m == 170 then
      e = new_enemy( a_flameboss, pos, new_action_idle() )
   end

   -- init common part and add enemy
   if e != nil then
      e.health = e.a.chealth
      e.hit_timeout = 0
      add( r.enemies, e )
      add( r.entities, e )

      --temp replace with upper tile, todo should restore original value when enemies are destroyed, or keep map modified for persistent deaths
      -- mset( map_j, map_i, mget( map_j, map_i-1 ) )

   end
end

----------------------------------------------------------------
-- enemies
----------------------------------------------------------------
function new_enemy( _archetype, _pos, _action )
   local e = { a = _archetype,
               action = _action,
               p0 = _pos,
               p1 = _pos,
               sign = -1 }
   return e
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
         del( room.enemies, e )
         del( room.entities, e )
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

-- function new_action_fall( _gravity_y )
--    return { name = "fall", anm_id = "move", t = 0, finished = false,
--             v_y = 0, gravity_y = _gravity_y }
-- end

-- ballistic projectile, play "hit" and disappear on impact. supersedes "fall"
function new_action_particle( _v, _a )
   return { name = "part", anm_id = "move", t = 0, finished = false,
            vel = _v, acc = _a }
end

function new_action_hit()
   return { name = "hit", anm_id = "hit", t = 0, finished = false }
end

-- shoot with cooldown timeout
function new_action_shoot( _timeout )
   return { name = "shoot", anm_id = "attack", t = _timeout-1, finished = false,
            timeout = _timeout }
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
            sub = new_action_idle() }
end

----------------------------------------------------------------
function update_action( _entity, _action )
   local act = _action
   act.t += 1
   if _action.name == "idle" then
      --idle do nothing
   elseif _action.name == "move" then
      act = update_action_move( _entity, _action )
   -- elseif _action.name == "fall" then
   --    act = update_action_fall( _entity, _action )
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
         local dir = v2scale( 1.0/dist, diff )
         entity.p1 = v2add( entity.p0, v2scale( min(entity.a.cspeed,dist), dir ) )
         entity.sign = sgn( dir.x )
      else
         entity.p1 = action.p_target
         action.finished = true
      end
   end
   return action
end

-- function update_action_fall( entity, action )
--    if not action.finished then
--       action.v_y += action.gravity_y
--       entity.p1.y += action.v_y
--       --todo finish if hit ground??
--    end
--    return action
-- end

function update_action_particle( entity, action )
   action.vel = v2add( action.vel, action.acc )
   entity.p1 = v2add( entity.p0, action.vel )
   --todo if collision, change to "action_impact" and die afterwards
   local movebox = aabb_apply_sign_x( entity.a.cmovebox, entity.sign )
   local map_collisions = ccd_box_vs_map( entity.p0,
                                          entity.p1,
                                          movebox,
                                          1+4,   --flags: 1 is_solid, 2 is_damage, 4 is destructible
                                          true ) --first-only
   if #map_collisions > 0 then
      local map_c = map_collisions[1]
      entity.p1 = v2add( entity.p0, v2scale( 0.99*map_c.interval.min, action.vel ) )
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
      local phase = 0
      if (action.t / action.timeout) % 2 > 0 then phase = 0.5 end
      local e = new_enemy( st,
                           pos,
                           new_action_particle( v2init( entity.sign*st.cspeed, -4 ), v2init(0,0.5) ) )
                           --new_action_particle( v2init( entity.sign*st.cspeed, 0 ), v2init(0,0) ) )
                           --new_action_sinusoid( pos, v2init( entity.sign, 0 ), st.cspeed, 10, 30, phase ) )
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
         local dir = v2scale( 1.0/dist, diff )
         entity.p1 = v2add( entity.p0, v2scale( min(entity.a.cspeed,dist), dir ) )
         entity.sign = sgn( dir.x )
      end
   end
   return action
end

--todo: now its just move_on_ground
function update_action_jump_on_ground( entity, action )
   local slowdown_factor = 0.5
   if action.first then
      -- solve for projectile |v0| thrown at 45 deg that hits target, no sign considered yet
      -- todo no solution if target is above 45 deg, detect it and avoid jumping
      local c45 = cos(0.125) --angle 0..2pi --> 0..1
      local a = slowdown_factor * level.a.cgravity_y
      local dx = action.p_target.x - entity.p1.x
      local dy = action.p_target.y - entity.p1.y
      local t = sqrt( abs( 2 * (dy-dx) / a ) )
      local speed = abs(dx) / (c45*t) --speed to hit target at 45 deg angle
      -- compute vel vector from magnitude and direction with correct sign
      action.v = v2scale( speed, v2init( sgn(dx) * c45, -c45 ) )
      action.first = false
   elseif not action.finished then
      local diff = v2sub( action.p_target, entity.p1 )
      local dist = v2length( diff )
      action.v.y += slowdown_factor * level.a.cgravity_y
      local speed = v2length( action.v )
      if dist < speed then
         -- success, closer than 1 timestep advance
         entity.p1 = action.p_target
         action.finished = true
      else
         -- todo this seems to easily overshoot so dist < speed is never fulfilled and action never ends...
         -- it would be better to just detect target ground level and jump there or use it's height at least
         -- advance
         local dir = v2scale( 1.0/speed, action.v )
         entity.p1 = v2add( entity.p0, v2scale( min(speed,dist), dir ) )
         entity.sign = sgn( dir.x )
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
      -- move along direction hacked as move towards out-of-room target, so that never arrives there
      action.sub = new_action_move_on_ground( v2add( entity.p1, v2init( 128*entity.sign, 0 ) ) )
   end
   return action
end

function update_action_wait_and_ram( entity, action )
   -- update sub
   action.sub = update_action( entity, action.sub )
   -- think
   if action.sub.name == "idle"
      and
      action.sub.t > #entity.a.table_anm[action.sub.anm_id].k --only replan after whole cycle
   -- todo check range
   then
      if flr(player.p1.y) == flr(entity.p1.y) then
         action.sub = new_action_move_on_ground( player.p1 ) --ram to player --todo use attack anim instead of walk...
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
   -- todo check range
   then
      local diff = v2sub( player.p1, entity.p1 )
      local dist = v2length( diff )
      if dist < 64 then
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
      if abs(player.p1.x - entity.p1.x) < 8 and player.p1.y > entity.p1.y then
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
      local diff = v2sub( player.p1, entity.p1 )
      local dist = v2length( diff )
      if dist < 64
         and
      flr(player.p1.y) == flr(entity.p1.y) then
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

-- function update_action_path( entity, action )
--    local sub = update_action_move( entity, action.sub )
--    if sub.finished then
--       if action.phase == 1 then
--          action.sub = new_action_move( action.p_start )
--          action.phase = 2
--       else
--          action.sub = new_action_move( action.p_end )
--          action.phase = 1
--       end
--    else
--       -- keep action, already updated
--    end
--    return action
-- end

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
   action.sub = update_action( entity, action.sub )
   -- idle intro phase
   if action.sub.name == "idle" then
      if action.sub.t > 30 then --1s
         entity.sign = sgn( player.p1.x - entity.p1.x )
         action.sub = new_action_shoot(30)
      end
   elseif action.sub.name == "shoot" then
      if action.sub.t > 120 then
         --action.sub = new_action_idle()
         action.sub = new_action_jump_on_ground( v2add( v2init(player.p1.x,128-16), v2init(0,-8) ) )
      end
   elseif action.sub.name == "jong" then
      if action.sub.finished then
         action.sub = new_action_idle()
      end
   end
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
                                             1+4,   --flags: 1 is_solid, 2 is_damage, 4 is destructible
                                             true ) --first-only
      -- if map collision, save it and shorten predicted trajectory
      if #map_collisions > 0 then
         local map_c = map_collisions[1]
         b.p1 = v2add( b.p0, v2scale( 0.99*map_c.interval.min, b.v ) )
         b.v = v2zero()
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
      if #enm_collisions > 0 then
         local enm_c = enm_collisions[1]
         b.p1 = v2add( b.p0, v2scale( 0.99*enm_c.interval.min, b.v ) )
         b.v = v2zero()
         new_vfx_blast( b.p1, b.sign )
         del( room.bullets, b )
         del( room.entities, b )
         local e = enm_c.entity
         if e.a.cdamagebox != nil
            and e.health == 1 then
            del( room.enemies, e )
            del( room.entities, e )
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
         -- todo play vfx/sfx
         new_vfx_blast( b.p1, b.sign )
         del( room.bullets, b )
         del( room.entities, b )
      elseif is_out(b.p1) then
         del( room.bullets, b )
         del( room.entities, b )
      end
   end
end

----------------------------------------------------------------
-- vfx
----------------------------------------------------------------
function new_vfx_blast( _p, _s )
   local v = { anm = a_blast.table_anm["hit"],
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
   if aabb.max.x - aabb.min.y > 8 then
      if sign_x < 0 then
         return { min = v2init( 15 - aabb.max.x, aabb.min.y ),
                  max = v2init( 15 - aabb.min.x, aabb.max.y ) }
      else
         return aabb
      end
   else
      if sign_x < 0 then
         return { min = v2init( 7 - aabb.max.x, aabb.min.y ),
                  max = v2init( 7 - aabb.min.x, aabb.max.y ) }
      else
         return aabb
      end
   end
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
--   add( debug.messages, "contains? "..n.x..","..n.y )
   for v in all(collisions) do
      if v.normal.x == n.x
         and
         v.normal.y == n.y
      then
--         add( debug.messages, "found" )
         return true
      -- else
      --    add( debug.messages, "not equal to "..v.normal.x..","..v.normal.y )
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
00088000000088000000880000088000000088000008800000008890000088900000088088080880000880000088000000088000000880000088008000880000
00889000000889000088890400889000008889040088900000088450008884500080889008888890008890000889000000889000008890000889880008898880
08845000008845008884544408845000884445400884500000884550080845500888845088088450088454008845400008845000088450008845400088454000
0845500008845500084055008884540008405500888454000884550000845500008845540088455408455ccd8455ccd088455ccd8845ccd08455ccd0845ccd00
884544000884540080055000080540008005500008044000008055550800555500004500000045008844ccd0844ccd000844ccd0084ccd00844ccd0084ccd400
08055500008d55400055ddd0000d5000000d55500005d0000000d0050000d005000055550000555008055500085500008055550080555000085d8000085d8000
000d0500000d05005500000d000d50000dd000050005d000000d0050000d0050000dd0050000d005000d050000d050000dd005000dd005000050dd000050dd00
00d0055000d005500000000000d05000000000000050d00000d0000000d0000000d0005000dd000500d005500d000500d0005000d0000500000500d0000500d0
808088800804880000088000000808080088000080880000008088000002200000011000000000000000000000000dd894389000000000000000000000000000
08488904088489040088880000888880088980000889800400088880002290000011900000000000000000000008355883d88d00000000000000000000000000
088445400884454008845900084598880845500088855440088845900224d0000114d000000066660000000000d89345534d5440000000000000000000000000
00885500008855000845540004554800884554000884550000845540024dd000014dd00000066606000000000d43d3d44d355450000000000000000000000000
00055000000550000845440040554080808450400808440000405440224544001145440000066666000000000d3435888d534435000000000000000000000000
000d5500000d5500008550000054000008d500008000d5000800550002055d0001055d00000000000000000089354d895d345398000000000000000000000000
000d0500000d050000d050000d05000000d0500000dd0500000d0500000d0500000d050000000000000000008834355355344388000000000000000000000000
00d0500000d050000d005000d00550000d0050000000500000d0055000d005d000d005d000000000000000004343b4b343b3434b000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000770000066670070077600060677707000000000777700600777700706660070
00000000000000000000000000000000007000000000700000060000000007007066600600766707706660060006670766666006007770607006770700066007
00000000000000000000000000000000007767700076770000767700066777000766660700666667076666760066666700666606077666600066677700666607
00000000000000000000000000070700006657000775660000765770007567000665766706655660766556670667566607657666776556600665567706675667
00ee0000000000000077700070e7e707007566000066577007756700007657007665566766657660766756600665566077655660766576606667567006655677
00e2200000e2e20007e2270007e2e270077677000077670000776700007776606766667076666600706666707666660077766600706666006066660006666770
0e22e8000e2e2e800e22e8000e2e2e80000007000007000000006000007000006006660770766000600666077076670070776007700660006006666606077700
022eee0002e2eee0022eee0002e2eee0000000000000000000000000000000006000677007077760000007700700766670077770070066600000000006007777
0000000000000000000000000000800000000000000000000000000000000000252555252525552502002002002002000002000205555aa0000000000000bb00
000000000000000000000000000000e00000000000000000000000000000000025cccc2525666625000000002002200202020000055aa550000a000000bbb904
00cccc0000cccc000028e000000e00000000000000008e700000000000bb00005c6996c2565566622022220002022020000e020000a555000a000a00bbb45444
0c6996c00c6aa6c022228e0000000200000000000008e70000000000003b00005c9aa9c556566565022ee220002ee200202e200200555000050500050b405500
0c9aa9c00ca99ac00028e0000002000070000000008e7000000000000003b0002c9aa9c22666656202eeee20202ee200002e20200005a00050500a00b0055000
0c9aa9c00ca99ac00000000000000080e70000000827000000028e800003b0005c6996c556655565022ee220002ee202002e2000000a000000a0500500553330
0c6996c00c6aa6c0000000000000e0008e70000082e70000008e77780000b00052cccc25526666250022220002022000020e020000050000a055550055000003
00cccc0000cccc000000000000000000082720002e28700002e7000700003b005255255252552552200000020020002000020002000a0000055a5aa000000000
00000000cdcddcdc555555550c0d070dc0d0c0000070d0c00000000000022200000233200222000000022000000022020000000000000000009a8777000a8777
7707c077dddddddd55666655c070c0c0070c0000000c0c0d00000000002333200023388223332000002332020002332000000000000000009a88707009a87070
cc7cc7ccdddddddd566666650d0d0d0dc0d07000000070d0022200000023883200233332238332000238832000238832000000000000000009a8767699887676
cccccccc1d1dd1dd56666665c0c070c00c0d0c00000d0c0d2333200000233332000230022333320002333202002333200000000000000000000a8707009a8777
cdcddcdcd1dd1d1d566666650d0c0d0cd0c0d00000c0d0c023383200000232020023202002320020023220200232220260760700687607000000006000000000
dcdccdcc1d1dd1d156666665d0d0d0700d07000000070d0d02333200002320000232000000232000232000022320002077700707777007070000000000000000
cdcddcdd1111111155666655070c0c0dc0c0c0000000c07023222320023232002323000002323200323200003230000270770606787706060000000000000000
dddddddd1111111155555555d0c0d0c00c0d0700000c0d0c32323233232323203232000023232320232320002323000067706565677065650000000000000000
22222222111111111111111122222222444444442222222200066600000666000006660000666000000006600000000000000000000666000000666000000000
42929242d1c1c1d151616151526662554ff44fff5266625500688860006888600068886006888600000068860000000000000000006888600006888600000000
49999244dcccc1dd5666615556666255ff4ff4f456666255004668600446686004446860446686000441448600000c000000c000004668600014468600000000
49999244dcccc1dd566661555666625544444444566665550444160044411640044444444441600041114486000007c000007c00044416000414416000000000
2222222211111111111111112222222244444444222222220441114044111144011444444411110011114460000007cd00007cd0044111404114410000000000
242929241d1c1c1d15161615552666254f4f4f4f55266625441111444411114401111144011111401111444000007ccd0007ccd0441111444111444000000000
44299994dd1ccccd5516666555266665f4fff4f4552666654411114401111100d111100001111140511114400007ccdd007ccdd0441111440111144000000000
44299994dd1ccccd5516666555266665444444445566666500d5550000d55500d115550005551d00551144400ccccdd00cccddd000d5550000555d0000000000
2222222244f444440000000000000000222222224494444400000000000000000000000000000000000000000000000000000000000000000000222222000000
4999944444444f4400060000000060004cc7ddd444444944000000000000000000000000000000000dd000000002200002222000002222000002028202220000
499994444f44444406050060060050604cccddd4494444440000000000000000000220000022000000dd200000112800000282000000282000001120d0282000
499994444444f44f05050050050050504cccddd4444494490000000000000000000028000002800010dd2800011dd22000012200000112200dd111100d122dd0
2222222244f4444405050050050050504dddc774449444440000000000000000000dd22000dd2200011dd22010dd00020011100000111000d00d111000d1d00d
444999944444444405560560065065504dddcc7444444444000000000000000000ddd10200dd10200000000200dd00000d111dd00dd111d000d0d0d0000d0d00
44499994f44444f456560565565065654dddccc4944444940505a0000005a00000dd10000ddd100000000000000d0000d0d0d00dd00d0d0d000d00d0000d00d0
444999944444f4446555655665565556444444444444944400566500055665000dd101000dd101000000000000000000d0000d0000d0000d00000d000000d000
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f2000000880000002000220022000000000000000000000000000002200220000
00000000000000000000000000000000000000000000000000000000000000002200008778000022000222002200000000002200220000000000002220022000
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f0220087887800220000022202220000000002220022000000000000222022200
00000000000000000000000000000000000000000000000000000000000000000222008778002220000022222220000000000222022200000000000222222200
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f0222228778222220000028828820000000000222222200000000000288288200
00000000000000000000000000000000000000000000000000000000000000000022111881112200000022222220000000000288288200000000333222222200
adadadadadadad8a9a8898adadadadadadadadadadadadadadadadadadadad1f00211dd88dd11200003332222233300003333222222233000003333322002230
000000000000000000000000000000000000000000000000000000000000000000111ddd1dd111000333b22222bb33003333332222233330003333bb22002333
adadadadadadad8b9b8999adadadadadadadadadadadadadadadadadadadad1f031121d1dd1211303333bbbb3bbb333033033b22222b3330003303bbb2002b33
0000000000000000000000000000000000000000000000000000000000000000333022111122033333003bbb3bb3033033003bbb3bb300330330033bb3202b33
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f3030255115520303330003335330003333300333533003330333003333322033
000000000000000000000000000000000000000000000000000000000000000030002552255200033330dd5555dd03333330ddd555dd033303330ddd555dd333
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f0302552202552030333ddd0555dd03330000ddd555ddd0000333ddd555dd3330
00000000000000000000000000000000000000000000000000000000000000000002d520025d2000000dd10550d10000000dd10550dd1000000dd1550dd13330
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f000ddd2002ddd00000d111000011100000d111000011100000d1110001110000
0000000000000000000000000000000000000000000000000000000000000000002dd002020dd200001111100111110000111110011111000011110001111000
adadad9cadadadadadadadad9cadadadadadadadadadadadadadadadadadad1f2000000880000002000110011000000000000000000000000000011110000000
00000000000000000000000000000000000000000000000000000000000000002200008778000022000111001100000000001100110000000000000111100000
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f0220087887800220000011101110000000001110011000000000000011110000
00000000000000000000000000000000000000000000000000000000000000000222008778002220000011111110000000000111011100a00000000111111000
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f022222877822222000a01881881000a09000011111110a0008a8001118181000
000000000000000000000000000000000000000000000000000000000000000000221118811122000a001111111000a009000188188100a0000a99a111110990
adadadadadadadadadadadadadadadadadadadadadadadadadadadadadadad1f00211dd88dd112000a222111112220a0092221111111228a0000022a99aa989a
000000000000000000000000000000000000000000000000000000000000000000111ddd1dd1110008a23111113322808a222211111228aa00889a88aa8a8a88
adad1f1fadadadadadadadad1f1fadadadadadadadadadadadadadadadadad1f081121d1dd1211808aa2333323332aa8a882231111132980aa902299889888a8
0000000000000000000000000000000000000000000000000000000000000000888022111122088898002333233202899a80233323320aa80000988a999aa99a
ad1fadadadad1fadad1fadadadad1fadadadadadadadadadadadadadadadad1f8080255115520808aa800222522008aa88a0022252200a8800998aa2225008a0
00000000000000000000000000000000000000000000000000000000000000008000255225520008a880dd5555dd088a8aa0ddd555dd0999088000dd555dd000
1fadadadadadadadadadad44adadad1f1fadadadadadadadadadadadadadad1f0802552202552080999ddd0555dd09999980ddd555ddd00000011ddd550dd000
00000000000000000000000000000000000000000000000000000000000000000002d520025d2000000dd10550d10000000dd10550dd100000011d0550dd1000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f000ddd2002ddd00000d111000011100000d11100001110000011100001111000
0000000000000000000000000000000000000000000000000000000000000000002dd020020dd200001111100111110000111110011111000010000000011100
22525252252525220000000220000000400000000000000465255556111115555551166100000080080000000000000000000000000000000000000000000000
00252525525252000000000220000000400000000000000456655665661555cc88555161080000900900008000000aa000000000011111100000000111000000
00025255552520000000002222000000440000000000004f56866c656155000c8aa6551189000890098000980000a00000000000000000110000000001111110
000025255252000000000252252000004f400000000004f45565265515550000abbb55519a90099aa99009a9000aa00000000000000000000000000000000000
00000252252000000000252552520000f4f4000000004f4f2565565215005000ab555551444004444440044400aa000000000111000000000000000000000000
00000022220000000002525555252000ff4f40000004f4f456b6696555a00500b55ccc55444004444440044400a0000000011101110000000111110000000000
00000002200000000025252552525200f4f4f400004f4f4f566556655a00005c55cbbbc504000040040000400000000001110000000000000000011100000000
000000022000000022525252252525224f4f4f444444fff4655552565b0000055cb888b504000040040000400000000000000000000000000000000000000000
04f444f44f444f4000000004400000004fff444444f4f4f400555000500000c555baa88511000000000000111100000000000000000000000000000000000000
0044f444444f44000000000440000000f4f4f400004f4f4f0566650000000050c55bba8500100011110001000010001100000000111000000000000000001110
00004f4444f4000000000044440000004f4f40000004f4ff0566665000000500bc55ba5500010100001010000001010000000000001111100000001110111000
0000044444400000000004f44f400000f4f4000000004f4f06555665000000008bc5b65110001000000100001000100000000000000000000000000011100000
000000f44f00000000004444444400004f400000000004f456666565000000008bc5555100010001100010000001000000000000000000000000000000000000
000000444400000000044f4444f44000f40000000000004456556665000000008bc5551600101000000101000010100001111110000000001100000000000000
00000004400000000044f444444f440040000000000000045666666000005cc8bc55516611000100001000111100010000000011100000000111111000000000
000000000000000044f444f44f444f44400000000000000436336363000005555551111100000011110000000000001100000000000000000000000000000000
2222222256556556000000006566556550505050f4f4f4f43b3b43b4000003000030000010000011000090000000000000000677776000000000000000000000
0222222265666565000000006555ee56555555554ff4f4f433b33b4b00030030003000000100010000080000000000900006777777776000000a000000000000
0002525556666656000000005eeeeee5505050504ff4f4ff4343433b030b303003003000001010000009800008000900006777667667760000aa0000000aaa00
000025256665556600000050eee5e5e560505050f4f4ff4ff4444344030300b00303b03000010000080a908000800800067766777777776000a0000000a00000
000002525656566650000656ee555eee66555555ffff4f4f4444f4440b0300300b003030000010008009800800809800077777777777777000aaaa0000a00000
000000225666666555665556e5eeeee5605050504f4f4fff4f444444300303b0030030b00001010089a9aa9808a99a80677766677776777600000a00000a0000
000000026566555666555656ee5eee56505050504f4ff4f4444444f44b33b4340b30300300100010899aa9988a9a9a98776677767777667700000000000aaa00
000000025655665656656555e55e556550505050f4f4f4f44444f444b43b4343434b33b4110000010889998089a8898977776677777777770000000000000000
222222220555565006555550055655e0525252520000889aa9998000000000000000000000090000000090000400400477777777777777760000000000000000
2222222065666565556666e655656e552552525200000089aa8800000000000000000000000980000009a0000400400477767777777677760aa0000000000000
552520005666665556665ee55666e66525525255000088aa980000000000000000000000008980000008a8004004004067777667777677760aa00a0000000000
52520000566565655665e665566ee565525255250008999aaa88000000080000000000000089a8000089a8004004004007777777776777700a0a0a0000000000
2520000056565665566ee65656e6566555552525000088aaa99980000008808000009000009a9a00009a99000400400406776777767677600a00aa0000000000
220000005666666565ee66655e6666652525255500000089aa880000808990899008980008aaa9000089aa9004004004006777777777760000aaaa0000000000
200000005566565556e66655ee56665625255252000088aa9800000098a9a8a9980a9808089a9800008a9a8040040040000677777777600000000a0000000000
20000000065565500555555005655550525252520008999aa9880000a99aa99a9a8a9a890089a0000009a8004004004000000777766000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000400001010000000000000000000000000000000000000008080000000000080808000000000000020208808080000000000000804000004001010101400000000000000000000040010202010500000000000000000000
0202020202020202020200000000000002020202020202020202000000000000020202020202020202020000000000000202020202020202020200000000000040404040404040404040400040404040010101014040014040404040404040400101400101400140404000004040404001010101400202000000004040404040
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffe2ffffffffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000c2f4f4f4f4c3000000000000000000000000000000000000000000635d00000000006300006300000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffff62ffffffffffffff
000000000000aa000000000000000000000000000000000000000000000000000000000000c2c14d00004dc0c30000000000000000000000000000000000000000636363006300000000004d00000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffe262c3ffffffffffff
0000000000000000000000000000000000c2f4f4f4f4f4f4f4f4f4f4f4f4f4c300c2f4f4f4c1000000000000c0f4f4f4f4f4f4f4c300c2f4f4f4f4c30040000000634dc0636363000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffff626262c3ffffffffff
0000000000000000c5d400008a00000000f4c1004dc0f4c1c0c1c0f4c1c0c1c0f4c10000000000000000000000c0f4c10000004dc0f4c100000000c0f4f0000000630000000000e063000000000063f00000000000000000000000000000000000000000000000000000ff000000ffffffffffffffffff62626262ffffffffff
00000000c5000000d5c400000000000000f4f7000000f400000000f400000000f400000000000000000000000000f4000000000000f4000000000000f40000000063000000000000c063000000006300000000000000000000000000000000000000000000000000000000ecedcccdffffffffffffffffc7c86262c3c2ffffff
00000000d5c40000c5d40000000000c400f400000000f400000000f400000000f400000000000000000000000000f4000000000000f4000000000000f400000000630000000000000000005d6300630000000000000070607800000000000000000000000000000000cecffcfddcddffffffffffffffffd7d862ffc0f4ffffff
0000000000d5c4c5d40000c50000c5d400f400000000f400000000f400000000f4000000000000000000000000636363f000000000f4000000000000f4000000006300000000636363636363c1006300000000000070607070000000000000000000000000cecfcdccdedfcd0000ffffffffffffffffffff6262e2fff4ffffff
000000000000d5e5000000d5c4c5d40000f400000000f400000000f400000000f4006363630000000000e0f000c0f4c10000000000f4000000000000f4000000006300000063c1000000000000006300000000006070706070600000000078000000000000dedfcecfdddcddcecfffffffffffffffffffe262626262f4ffffff
00000000c5c400e5c5d40000d5e5c4c500f400000000f400000000f4006600636363634d0000e0f0000000000000f4000000000000f4000000000056f40000000063000063c10000000000000000630000000000706070707070646464646400000000cccd0000dedd000000deccccffffffffffffffe2656565656565c3c2ff
5c0000d5d4d5c4e5d400000000d5e5d400f400000000f40000566363636363636363d10000000000000000000000f400000000e06363000000000063c10000000063635c00760063636363000000630000000000707470607460000000000000000000dcdd000000000000ce0000cecfffffffffffff65c6c665c1c065c0f4ff
5c5c00000000d5e5000000000000e50000f400000000f400636363636363636371d1000000000000000000000000f4000000000000f46300000000000000000000c06363636363c1000000000063c1000000006360707070607000000000000000000000000000000000630000dedfffffffffffffffc6c1c0c6c3c265fff4ff
fbe40000000000e5000000000000e50000f4000000636363636363637575757575000000000000e0f00000000000f4000000000000f4006300000000000000000000c0f4000000000000000063c10063630000c07060e5e570600000000000000000000000000063cecf00cf0063ffffffe2ffffffffc18a8bc0656565fff4ff
fbe4e82b2ce8e8e53072d60030e8e500c2f4c363757575757575757575757575755c000063000000005c006300c2f4c300000066c2f4c3750000000000660063630000f4000000000066637575006363636300006070e5e560700000000000f1f1000000007c63c1dedf000000c063ffc2f4e2ffffe2ff9a9bff656565c2f4c3
fbe6717171e6e6e671e6e65ce6e671e6636363636363636363717171717171717171717163737372727373636363636362626262626275757562626262626262626262626262626262757575757575626262626262626262626250f150505050626262626262625050505050505062626262e1e1e1e1e1626262626262626262
fb00d071717171717171717171717171717171717171717171717171717171717171717163636363636363636363636363637171717171717171717171717171626262626271717171717171717171717171717171717171715151515151515151f1f1f1f1f1f171717171717171717171717171717171717171717171717171
fb0000d071d1d07171717171717171717171717171717171717171717171d0d1d07171d100f4c10000c0f40000000000000000000000000000000000d071d1000000000000d0d10000000000004d00000000000000d07171715151515151515151f1f1f1f1f1f17171717171f3717171717171717171d1d0d1d071d1d0717171
d0000000fb0000d0717171717171d1d071d1d0717171d14dd071d14d71d100000000000000f400470000f40000000000000000660000000000000000004d00000000006600000000000000000000000000000000000000d0715151f151515171f1f1f1f1f1f1717171f3717171717171717171d071d10000000071000071d171
00d00000fb0000004dd0717171d10000d100004dd071000000710000d10000000000000000f1f1f1f1f1f100000000000072e1e1e1e1e1e1e1e1e100000000000072e1e1e1e1e1e1e1e1e10000000000000000f100000000d0715371535371717171717171717171717171d1d071f371f671d100d10000000000d00000d000f5
0000d000fb00000000007171d1000000000000000071000000d100000000000000000000f1f1e9e9e9e9f1f10000000000e1c1e9e9e9e9e9e9e9c0e10000000000e1c1e9e9e9e9e9e9e9c0e100000000000000c0f1000000005553535353540000000000000000000000000000d07171f6d100000000000000000000000000f5
00000000fb0000000000d071000000000000000000d000000000000000000000000000f1f1e9e9e9e9e9e9f1f100000000e1e9e9e9e9c9e9e9e9e9e9e9e1e1e1e1e1e9e9e9e9c9e9e9e9e9e9e9e9e1e1e1720000c0f100000055535353535400000000000000000000000000000000d0f60000000000000000000000000000f5
00000000d10000000000007100000000000000000000000000000000000000000000f1f1e9e9e9e9e9e9e9e9f1e1000000e1e9e9e9e9e9e9e9e9e9e9e1c1e9e9e9e9e9e9e9e9e9e9e9e9e9e9e1e100e1e1c1000000c0f159005540545353540000000000000000000000000000780000f600000000000000000000000000c3f5
000000d100000000000000d000000000000000000000000000000000000000000072f1e9e9e9e9e9e9e9e9e9e9e1e1005ce1e9e9e97ce9e9e9e9e9e9e9e9e9e9e9e9e9e9e97ce9e9e9e9e9e1000000e1e100000000004df1f1f1f1545353540000000000000000000000000000c20000f6c20000000000000000c20000c2c1f5
0000d1000000000000000000000000000000000000000000000000000000000072f1e9e9e9c9e9e9e9e9c9e9e9e9e17272e1e9e1e1e1e1e1e1e1e9e9e9e9e9e9e9e1e9e9e1e1e1e1e1e1e1e140000000000000000000000000555554f153545900000000000000000078000000c0c300f6c0c30000c300000000c0c3c2c100f5
fbd10000000000000000000000000000000000000000d0d30000006600000000f1e9e9e9e9e9e9e9e9e9e9e9e9e9e9e1e1c1e9e9e9e9e9e9e9e9e9e9e1e1e1e1e1c1e9e1c1e9e9e9e9e9e9c0e10000000000000000000000005555545555f1f1000000000000000000c300000000c0c30000c0c3c2c100c2c30000c0f40000f5
fb0000000000000000000000000000000000000000d071717171717171d10000f4e9e9e9e9e9e9e9e9e9e9e9e9e9e9f4f4e9e9e9e9e9c9e9e9e9e9e1c1e9e9e9e9e9e9e9e9e9c9e9e9e9e9e9e9e9e1e1e1f000000000000000555554f1f154000000000000000000c2c100000000c2f4000000f4c100c24849c30000f40000f5
71d1000000000000000000000000000000000000d071d100000000d07171d100f4c3e9e9e9e9e9e9e9e9e9e9e9e9c2f4f4c3e9e9e9e9e9e9e9e9e1c1e9e9e9e9e9e9e9e9e9e9e93ce9e9e9e9e95dc0e1e1000000000059000055f154555554000000000000000000c0c300c20000c1f40000c2c100c2c10000c0c300c0c300f5
7171d100000000000000000000000000000000d071d1000000000000d071d3f1f1f1f1f1f1f1f1f1f1f1f1f1f1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e9e9e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e10000000000f1f10055555455545400000000000000000000f400c0c30000f40000f40000f400000000f40000f400f5
f17171d10000000000000000000000000000d071d1000000000000000075f1f1f10000000000f1000000003c00000000000000000000000000000000c0f10000000000000000000000000000000000e1e100000000000000f1f1555455545400000000000000000000f40000f40000f40000f40000f400aaab00f40000f400f5
f1f1d10032000000f1720000000032f1f1d071d10040f10000440000007575755d770000003c00000000e100000000f1f1000000003c00000000003c00000000000000003c0000000000003f000000000000000000000000005555f15050f10000e7e8e8e7e74e0056f1f7f7f1f7f7f100c2f400f74900babb0049f700f4c3f5
f1f1f100f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f17171e6e6e6e6e6e6e6e6e6e6e6e6e6e6e671f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
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
