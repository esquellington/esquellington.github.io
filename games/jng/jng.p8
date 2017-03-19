pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

----------------------------------------------------------------
-- run with: ./pico-8/pico8 -windowed 0 -run ./jng.p8
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

   -- map background
   map(level.room_coords.x * 16,
       level.room_coords.y * 16,
       0,0,16,16,
       0x7f )
   -- rect(0,0,127,127,1)

   --enemies
   for e in all(room.enemies) do
      local act = e.action
      local anm = e.a.table_anm[act.anm_id]
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
      if debug.mode > 0 then
         print( e.action.name, e.p1.x-4, e.p1.y-4 )
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

   --bullets
   for b in all(room.bullets) do
      local anm = b.a.table_anm[b.s]
      if anm.c then
         spr( anm.k[1+b.t%#anm.k],
              b.p1.x, b.p1.y,
              1,1,
              player.sign<0 )
      else
         spr( anm.k[ min(1+b.t,#anm.k) ],
              b.p1.x, b.p1.y,
              1,1,
              player.sign<0 )
      end
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

      --bullet boxes
      -- for b in all(room.bullets) do
      --    if debug.mode == 3 and b.a.cattackbox != nil then
      --       local attackbox = aabb_apply_sign_x(b.a.cattackbox,b.sign)
      --       rect( b.p0.x + attackbox.min.x,
      --             b.p0.y + attackbox.min.y,
      --             b.p0.x + attackbox.max.x-1,
      --             b.p0.y + attackbox.max.y-1,
      --             1 )
      --       rect( b.p1.x + attackbox.min.x,
      --             b.p1.y + attackbox.min.y,
      --             b.p1.x + attackbox.max.x-1,
      --             b.p1.y + attackbox.max.y-1,
      --             12 )
      --    end
      -- end

      if debug.mode == 1 then
         -- debug info
         print("t:"..game.t/10,1,1,7)
         print("a:"..g_anim[player.state].n,108,1,7)
         print("mem:"..stat(0),1,122,7)
         print("cpu:"..stat(1),84,122,7)
         -- player status
         -- if player.on_ground then
         --    print("g:1",30,1,7)
         -- else
         --    print("g:0",30,1,7)
         -- end
         --print("v:"..player.v.x..","..player.v.y,50,1,7)
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

      -- testiiiiiing
      if false then
         local lambda01 = game.t/1000
         lambda01 = lambda01 - flr(lambda01) --cast to 0..1
         local rp = vec2_init( 64 + 64*cos(lambda01),
                               64 + 64*sin(lambda01) )
         circfill( rp.x, rp.y, 2, 10 )
         local bp = vec2_init( 64, 64 )
         circfill( bp.x, bp.y, 2, 10 )
         local rd = vec2_sub( bp, rp )
         local rh = ray_vs_aabb( rp, rd, {min=0,max=1},
                                 aabb_init_2( vec2_sub(bp,vec2_init(10,10) ), vec2_add(bp,vec2_init(10,10) ) ) )
         if rh != nil then
            circfill( rh.point.x, rh.point.y, 3, 10 )
         end
      end

      if false then
         local lambda01 = game.t/1000
         lambda01 = lambda01 - flr(lambda01) --cast to 0..1 for sin/cos
         local p0 = { x=64 + 64*cos(lambda01),
                      y=64 + 64*sin(lambda01) }
         local p1 = { x=64 + 16*sin(lambda01),
                      y=64 + 16*cos(lambda01) }
         -- here we use p,hs cause it's simpler
         local hs0 = { x=4, y=4 }
         local hs1 = { x=16, y=16 }
         rect( p0.x-hs0.x, p0.y-hs0.y, p0.x+hs0.x, p0.y+hs0.y, 8 )
         rect( p1.x-hs1.x, p1.y-hs1.y, p1.x+hs1.x, p1.y+hs1.y, 8 )
         -- convert to aabb instead of p,hs
         local rh = ccd_box_vs_aabb( vec2_sub(p0,hs0), vec2_sub(p1,hs0), aabb_init( 0, 0, 8, 8 ), --cmovebox
                                     aabb_init_2( vec2_sub(p1,hs1), vec2_add(p1,hs1) ),
                                     1 ) --flag 0 == is_solid
         if rh != nil then
            circfill( rh.point.x, rh.point.y, 2, 8 )
            rect( rh.point.x-hs0.x, rh.point.y-hs0.y,
                  rh.point.x+hs0.x, rh.point.y+hs0.y, 9 )
         end
      end

      if false then
         local movebox = player.a.cmovebox
         local aabb_min = vec2_add( vec2_min( player.p0, player.p1 ), movebox.min )
         local aabb_max = vec2_add( vec2_max( player.p0, player.p1 ), movebox.max )
         local overlaps = bp_aabb_vs_map( aabb_init_2( aabb_min, aabb_max ), 0 )
         if overlaps != nil then
            for o in all(overlaps) do
               rect( o.tile_j*8, o.tile_i*8,
                     (o.tile_j+1)*8, (o.tile_i+1)*8,
                     11 )
            end
         end
      end

      if false then
         local lambda01 = game.t/1000
         lambda01 = lambda01 - flr(lambda01) --cast to 0..1 for sin/cos
         local p0 = vec2_init( 64 + 50*cos(lambda01),
                               64 + 50*sin(lambda01) )
         local p1 = vec2_init( 64, 64 )
         -- draw bp box for debug
         local rmin = vec2_add( vec2_min( p0, p1 ), player.a.cmovebox.min )
         local rmax = vec2_add( vec2_max( p0, p1 ), player.a.cmovebox.max )
         rect( rmin.x, rmin.y, rmax.x, rmax.y, 11 )
         circfill( p0.x, p0.y, 2, 14 )
         circfill( p1.x, p1.y, 2, 15 )
         -- ccd
         local contacts = ccd_box_vs_map( p0, p1, player.a.cmovebox, 1 ) --flags: 0 is_solid, 1 is_damage
         if contacts != nil then
            local c = contacts[1] --first only
            circfill( c.point.x, c.point.y, 2, 2 )
            rect( c.point.x, c.point.y, c.point.x + 11*c.normal.x, c.point.y + 11*c.normal.y )
            --print( "c[1].t="..c.interval.min, c.point.x, c.point.y )
            --print( c.interval.min, c.point.x, c.point.y )
         end
         local it_c = 0
         for c in all(contacts) do
            circfill( c.point.x, c.point.y, 1, 3 + it_c%13 )
            it_c += 1
            --print( "c["..it_c.."].t="..c.interval.min, c.point.x, c.point.y )
            --print( c.interval.min, c.point.x, c.point.y )
         end
      end

      if true then
         -- player collisions
--         for c in all(player.handled_collisions) do
         for c in all(player.ground_ccd_1) do
            rect( c.point.x, c.point.y, c.point.x + 11*c.normal.x, c.point.y + 11*c.normal.y )
            -- print( "c["..it_c.."].t="..c.interval.min, c.point.x, c.point.y )
            -- print( c.interval.min, c.point.x, c.point.y )
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
   --player move (todo refactor into a_player)
   g_anim[1]={n="idl",c=true,k={16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17}}
   g_anim[2]={n="run",c=true,k={18,18,18,18,18,18,19,19,19,19,20,20,20,20,20,20,21,21,21,21}}--airborne frames get more presence, so looks nicer
   g_anim[3]={n="jmp",c=false,k={22,22,22,22,23,23,23,23,24,24,24,24,25,25,25,25}}
   g_anim[4]={n="fall",c=true,k={32,32,32,32,33,33,33,33}}
   --player shoot (should have same length)
   -- g_anim[5]={n="shi",c=true,k={26,27,27,27}}
   -- g_anim[6]={n="shj",c=true,k={28,28,29,29}}
   -- g_anim[7]={n="shjb",c=true,k={30,30,31,31}} --shoot jump backwards important: must have same #frames as "shj"
   --g_anim[5]={n="shi",c=true,k={10,10,11,11}}
   g_anim[5]={n="shi",c=true,k={8,8,9,9,9}}
   g_anim[6]={n="shj",c=true,k={12,12,13,13}}
   g_anim[7]={n="shjb",c=true,k={14,14,15,15}} --shoot jump backwards important: must have same #frames as "shj"
   --hits
   g_anim[8]={n="hit",c=false,k={ 34,34,34,34,34,
                          35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35, 35,35,35,35,35 }}
   g_anim[9]={n="hitb",c=false,k={36,36,36,36,37,37,37,37,38,38,38,38}}
   --enm
   g_anim[10]={n="wrm1",c=true,k={48,48,48,48,48,48,49,49,49,49,49,49}}
   g_anim[11]={n="wrm2",c=true,k={50,50,50,50,51,51,51,51}}
   g_anim[12]={n="saw1",c=true,k={52,52,52,52,53,53,53,53}}
   g_anim[13]={n="saw2",c=true,k={54,54,54,54,55,55,55,55}}
   g_anim[14]={n="saw3",c=true,k={56,57,58,59}}
   g_anim[15]={n="saw4",c=true,k={60,61,62,63}}
   --blast
   g_anim[16]={n="blast1",c=true,k={1}}--deprecated
   g_anim[17]={n="blast2",c=true,k={1}}--deprecated
   g_anim[18]={n="blast3",c=true,k={1,1,1,2,2,2,3,3,3,2,2}}
   g_anim[19]={n="blast_hit",c=true,k={4,4,5,5,6,6,6,7}}
   -- proves
   g_anim[20]={n="grunt_idle",c=true,k={102,102,102,102,102,102,103,103,103,103,103,103}}
   g_anim[21]={n="grunt_move",c=true,k={102,102,102,102,102,102,103,103,103,103,103,103}}
   g_anim[22]={n="grunt_attack",c=true,k={105,105,105,105,105,105,105,105,104,104,104,104,104,104,105,105,105,105,105,105,105,105,106,106,106,106,106,106}}
   g_anim[23]={n="cthulhu_idle",c=true,k={86,86,86,86,87,87,87,87,88,88,88,88,89,89,89,89}}
   g_anim[24]={n="cthulhu_move",c=true,k={86,86,86,86,87,87,87,87,88,88,88,88,89,89,89,89}}
   g_anim[25]={n="cthulhu_attack",c=true,k={90,90,91,91}}
   g_anim[26]={n="mouse_move",c=true,k={118,118,118,118,118,119,119,119,119,119}}
   g_anim[27]={n="bird_move",c=true,k={120,120,120,120,120,121,121,121,121,121}}
   g_anim[28]={n="arachno_move",c=true,k={122,122,122,122,122,123,123,123,123,123}}
   g_anim[29]={n="skull",c=true,k={94,94,94,94,94,95,95,95,95,95}}

   --level
   a_level = {}
   a_level.cnumrooms = vec2_init( 8, 2 )

   --rooms
   a_room = {}
   a_room.csizes = vec2_init( 128, 128 )

   --player
   a_player = {}
   a_player.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_player.cmovebox   = aabb_init( 1, 1, 7, 7 )
   a_player.cdamagebox = aabb_init( 2, 1, 6, 7 )
   a_player.cattackbox = nil
   a_player.cmaxvel = vec2_init( 5, 5 )

   --enemies--
   --saw
   a_saw = {}
   a_saw.table_anm = {}
   a_saw.table_anm["idle"] = g_anim[15]
   a_saw.table_anm["move"] = g_anim[15]
   a_saw.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_saw.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_saw.cdamagbox  = nil
   a_saw.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_saw.cspeed = 1

   --caterpillar
   a_caterpillar = {}
   a_caterpillar.table_anm = {}
   a_caterpillar.table_anm["idle"] = g_anim[10]
   a_caterpillar.table_anm["move"] = g_anim[10]
   a_caterpillar.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_caterpillar.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_caterpillar.cdamagebox = aabb_init( 1, 4, 7, 8 )
   a_caterpillar.cattackbox = aabb_init( 1, 4, 7, 8 )
   a_caterpillar.cspeed = 0.5

   --caterpillar2 (angry)
   a_caterpillar2 = {}
   a_caterpillar2.table_anm = {}
   a_caterpillar2.table_anm["idle"] = g_anim[11]
   a_caterpillar2.table_anm["move"] = g_anim[11]
   a_caterpillar2.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_caterpillar2.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_caterpillar2.cdamagebox = aabb_init( 0, 2, 8, 8 )
   a_caterpillar2.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_caterpillar2.cspeed = 1

   --grunt
   a_grunt = {}
   a_grunt.table_anm = {}
   a_grunt.table_anm["idle"]   = g_anim[20]
   a_grunt.table_anm["move"]   = g_anim[21]
   a_grunt.table_anm["attack"] = g_anim[22]
   a_grunt.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_grunt.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_grunt.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_grunt.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_grunt.cspeed = 0.5

   --cthulhu
   a_cthulhu = {}
   a_cthulhu.table_anm = {}
   a_cthulhu.table_anm["idle"]   = g_anim[23]
   a_cthulhu.table_anm["move"]   = g_anim[24]
   a_cthulhu.table_anm["attack"] = g_anim[25]
   a_cthulhu.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_cthulhu.cmovebox   = aabb_init( 0, 0, 8, 8 )
   a_cthulhu.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_cthulhu.cattackbox = aabb_init( 1, 3, 7, 8 )
   a_cthulhu.cspeed = 0.4

   --mouse
   a_mouse = {}
   a_mouse.table_anm = {}
   a_mouse.table_anm["idle"] = g_anim[26]
   a_mouse.table_anm["move"] = g_anim[26]
   a_mouse.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_mouse.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_mouse.cdamagebox = nil
   a_mouse.cattackbox = nil
   a_mouse.cspeed = 0.3

   --bird
   a_bird = {}
   a_bird.table_anm = {}
   a_bird.table_anm["idle"] = g_anim[27]
   a_bird.table_anm["move"] = g_anim[27]
   a_bird.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_bird.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_bird.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_bird.cattackbox = aabb_init( 0, 0, 8, 8 )
   a_bird.cspeed = 0.6

   --arachno
   a_arachno = {}
   a_arachno.table_anm = {}
   a_arachno.table_anm["idle"] = g_anim[28]
   a_arachno.table_anm["move"] = g_anim[28]
   a_arachno.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_arachno.cmovebox   = aabb_init( 2, 0, 6, 8 )
   a_arachno.cdamagebox = aabb_init( 0, 0, 8, 8 )
   a_arachno.cattackbox = aabb_init( 1, 3, 7, 8 )
   a_arachno.cspeed = 0.75

   --bullets
   a_blast = {}
   a_blast.table_anm = {}
   a_blast.table_anm["default"] = g_anim[18]
   a_blast.cvisualbox = aabb_init( 0, 0, 8, 8 )
   a_blast.cmovebox   = nil
   a_blast.cdamagbox  = nil
   a_blast.cattackbox = aabb_init( 4, 3, 7, 4 )
   a_blast.cspeed = 4

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
              p0 = vec2_init( 3.5*8, 3*8 ),
              p1 = vec2_init( 3.5*8, 3*8 ),
              sign = 1,
              v = vec2_zero(),
              on_ground = false,
              is_mutated = true,
              jump_s = 0,  --original jump direction
              invulnerability_t = 0 } --frames remaining

   --level
   level = {}
   level.a = a_level
   level.room_coords = vec2_init( 0, 0 )
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
         player.v = vec2_zero()
      end

      -- idle/run
      if player.state==1 then
         -- todo in transitions to run, try to start with
         -- alternative/random legs to improve variation
         if btn(0) then
            player.t = 0
            player.state = 2
            player.sign = -1
            player.v = vec2_init(-1.25,0)
         elseif btn(1) then
            player.t = 0
            player.state = 2
            player.sign = 1
            player.v = vec2_init(1.25,0)
         end
      elseif player.state==2 then --run
         if not (btn(0) or btn(1)) then
            player.t = 0
            player.state = 1
            player.v = vec2_zero()
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
            player.v = vec2_init(player.sign*1.25,0)
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
   local acc = vec2_init( 0, 0.5 ) --pixels/frame^2
   local pred_vel = vec2_clamp( vec2_add( player.v, acc ),
                                vec2_scale(-1,player.a.cmaxvel),
                                player.a.cmaxvel )

   -- ccd-advance
   local p1
   local num_hits_map
   -- first handle collisions with solid map
   p1, num_hits_map, player.handled_collisions = advance_ccd_box_vs_map( player.p0, vec2_add( player.p0, pred_vel ), movebox, 1, false )
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
         local attack_aabb = aabb_init_2( vec2_add( attackbox.min, e.p1 ),
                                          vec2_add( attackbox.max, e.p1 ) )
         if ccd_box_vs_aabb( player.p0, p2, damagebox, attack_aabb ) != nil then
            hit_enemy = true
         end
      end
   end

   -- advance
   player.p1 = p2
   player.v = vec2_sub( player.p1, player.p0 )

   -- process hits if not invulnerable
   if (hit_enemy or num_hits_map != 0)
      and player.invulnerability_t == 0 then
      player.t = 0
      player.state = 8 --hit todo decide hit/hitb
      player.invulnerability_t = 60
      player.sign = -player.sign
      player.v = vec2_init( player.sign * 1.5, -3 )
   end

   -- check on ground for next frame
   player.ground_ccd_1 = ccd_box_vs_map( player.p0, vec2_add( player.p1, vec2_init(0,1) ),
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

   local d = vec2_sub( p1, p0 )
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
            p0 = vec2_add( p0, vec2_scale( 0.99*c.interval.min, d ) )
            -- clip interval
            local remaining_fraction = (1-c.interval.min) --interval [min..1] becomes new [0..1]
            remaining_time *= remaining_fraction
            -- correct displacement
            local dn = vec2_dot( d, c.normal )
            if dn < 0 then
               d = vec2_sub( d, vec2_scale( dn, c.normal ) )
               num_hits += 1
            end
            -- predict during remaining fraction along corrected displacement
            p1 = vec2_add( p0, vec2_scale( remaining_fraction, d ) )
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
   local pos = vec2_init( room_j*8, room_i*8 )
   if m == 48 then --caterpillar
      e = new_enemy( a_caterpillar, pos, new_action_patrol( pos, -1 ) )
   elseif m == 50 then --caterpillar2
      e = new_enemy( a_caterpillar2, pos, new_action_patrol( pos, -1 ) )
   elseif m == 86 then --cthulhu
      e = new_enemy( a_cthulhu, pos, new_action_patrol( pos, -1 ) )
   elseif m == 102 then --grunt
      e = new_enemy( a_grunt, pos, new_action_wait_and_ram( pos, -1 ) )
   elseif m == 118 then --mouse
      e = new_enemy( a_mouse, pos, new_action_patrol( pos, -1 ) )
   elseif m == 120 then --bird
      e = new_enemy( a_bird, pos, new_action_idle() )
  elseif m == 122 then --arachno
     e = new_enemy( a_arachno, pos, new_action_patrol( pos, -1 ) )
   elseif m == 60 then --saw
      --todo: consider "finding" amplitude up to closest collision, instead of hardcoding it
      e = new_enemy( a_saw, pos, new_action_oscillate( pos, vec2_init(1,0), 32, 300 ) )
   end

   -- add enemy if created
   if e != nil then
      add( r.enemies, e )
      add( r.entities, e )
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
      e.action.t += 1
      e.p0 = e.p1
      e.action = update_action( e, e.action )
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

-- move on ground, stop at target/wall/cliff/border
function new_action_move_on_ground( target_pos )
   return { name = "move_on_ground", anm_id = "move", t = 0, finished = false,
            p_target = target_pos }
end

-- patrol in flat area, stop and turn at wall/cliff/border
function new_action_patrol( start_pos, sign_x )
   return { name = "patrol", anm_id = "move", t = 0, finished = false,
            p_start = start_pos,
            dir = vec2_init( sign_x, 0 ),
            sub = new_action_move( vec2_add( start_pos, vec2_init( 128*sign_x, 0 ) ) ) }
end

-- wait on spot, ram to player when on same ground level, accessible and within range
function new_action_wait_and_ram( start_pos, sign_x )
   return { name = "wait_and_ram", anm_id = "idle", t = 0, finished = false,
            p_start = start_pos,
            dir = vec2_init( sign_x, 0 ),
            sub = new_action_idle() }
end

-- follow nav points todo use list instead of just 2!!
function new_action_path( start_pos, end_pos )
   return { name = "path", anm_id = "move", t = 0, finished = false,
            p_start = start_pos,
            p_end = end_pos,
            sub = new_action_move( end_pos ),
            phase = 1 }
end

-- oscillate from midpos along dir with sinusoid of given amplitude (in pixels) and period (in frames)
function new_action_oscillate( mid_pos, _dir, _amplitude, _period )
   return { name = "oscillate", anm_id = "move", t = 0, finished = false,
            p_mid = mid_pos,
            dir = _dir,
            amplitude = _amplitude,
            period = _period }
end

----------------------------------------------------------------
function update_action( _entity, _action )
   if _action.name == "move" then
      return update_action_move( _entity, _action )
   elseif _action.name == "move_on_ground" then
      return update_action_move_on_ground( _entity, _action )
   elseif _action.name == "patrol" then
      return update_action_patrol( _entity, _action )
   elseif _action.name == "oscillate" then
      return update_action_oscillate( _entity, _action )
   elseif _action.name == "wait_and_ram" then
      return update_action_wait_and_ram( _entity, _action )
   else
      --idle do nothing
      return _action
   end
end

function update_action_move( entity, action )
   if not action.finished then
      local diff = vec2_sub( action.p_target, entity.p1 )
      local dist = vec2_length( diff )
      if dist > 0.5 then
         local dir = vec2_scale( 1.0/dist, diff )
         entity.p1 = vec2_add( entity.p0, vec2_scale( min(entity.a.cspeed,dist), dir ) )
         entity.sign = sgn( dir.x )
      else
         entity.p1 = action.p_target
         action.finished = true
      end
   end
   return action
end

--todo make new action_move_on_ground that accounts for walls/cliffs/border as patro, and reuse it for wait_and_ram
function update_action_move_on_ground( entity, action )
   if not action.finished then
      local movebox = aabb_apply_sign_x( entity.a.cmovebox, entity.sign )
      local p_forward
      local p_feet
      if entity.sign > 0 then
         p_forward = vec2_add( entity.p1,
                               vec2_init( movebox.max.x, 0.5*(movebox.max.y-movebox.min.y) ) )
         p_feet = vec2_add( entity.p1,
                            vec2_init( movebox.max.x-1, movebox.max.y ) )
      else
         p_forward = vec2_add( entity.p1,
                               vec2_init( movebox.min.x, 0.5*(movebox.max.y-movebox.min.y) ) )
         p_feet = vec2_add( entity.p1,
                            vec2_init( movebox.min.x+1, movebox.max.y ) )
      end
      local b_hit_wall = is_solid( p_forward )
      local b_hit_border = is_out( p_forward )
      local b_hit_cliff = not is_solid( p_feet )
      local diff = vec2_sub( action.p_target, entity.p1 )
      local dist = vec2_length( diff )
      if b_hit_wall
         or b_hit_border
         or b_hit_cliff then
            -- blocked
         action.finished = true
      elseif dist < 0.5 then
            -- success
         entity.p1 = action.p_target
         action.finished = true
      else
            -- advance
         local dir = vec2_scale( 1.0/dist, diff )
         entity.p1 = vec2_add( entity.p0, vec2_scale( min(entity.a.cspeed,dist), dir ) )
         entity.sign = sgn( dir.x )
      end
   end
   return action
end

function update_action_patrol( entity, action )
   action.sub = update_action_move_on_ground( entity, action.sub )
   if action.sub.finished then
      entity.sign = -entity.sign
      -- move along direction hacked as move towards out-of-room target, so that never arrives there
      action.sub = new_action_move( vec2_add( entity.p1, vec2_init( 128*entity.sign, 0 ) ) )
   end
   return action
end

function update_action_wait_and_ram( entity, action )
   -- update sub
   action.sub = update_action( entity, action.sub )
   -- think
   if action.sub.name == "idle" then
      --waiting, ram if player is in same level, in range and accessible
      --if true then --player_on_same_line( ) then
      if flr(player.p1.y) == flr(entity.p1.y) then --todo: use line-of-sight
         action.sub = new_action_move_on_ground( player.p1 ) --ram to player --todo use attack anim instead of walk...
      end
   else
      --ramming
      --todo reuse action_move_on_ground to accounts for walls/cliffs/border
      --todo rethink if not accessible anymore, after timeout
   end
   return action
end

function update_action_path( entity, action )
   local sub = update_action_move( entity, action.sub )
   if sub.finished then
      if action.phase == 1 then
         action.sub = new_action_move( action.p_start )
         action.phase = 2
      else
         action.sub = new_action_move( action.p_end )
         action.phase = 1
      end
   else
      -- keep action, already updated
   end
   return action
end

function update_action_oscillate( entity, action )
   entity.p1 = vec2_add( action.p_mid, vec2_scale( action.amplitude * sin( action.t/action.period ), action.dir ) )
   return action
end

----------------------------------------------------------------
-- bullets
----------------------------------------------------------------
function new_bullet_blast( _p, _s )
--   debug.paused = true
   local b = { a = a_blast,
               s = "default",
               t = 0,
               p0 = _p,
               p1 = _p,
               sign = _s,
               v = vec2_init( _s*a_blast.cspeed, 0 ) }
   add(room.bullets,b)
   add(room.entities,b)
end

function update_bullets()
   --move room.bullets
   for b in all(room.bullets) do
      b.t += 1
      b.p0 = b.p1
      b.p1 = vec2_add( b.p0, b.v )

      -- test against map
      local map_collisions = ccd_box_vs_map( b.p0,
                                             b.p1,
                                             aabb_apply_sign_x( b.a.cattackbox, b.sign ),
                                             1+4,   --flags: 1 is_solid, 2 is_damage, 4 is destructible
                                             true ) --first-only
      -- if map collision, save it and shorten predicted trajectory
      if #map_collisions > 0 then
         local map_c = map_collisions[1]
         b.p1 = vec2_add( b.p0, vec2_scale( 0.99*map_c.interval.min, b.v ) )
         b.v = vec2_zero()
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
         b.p1 = vec2_add( b.p0, vec2_scale( 0.99*enm_c.interval.min, b.v ) )
         b.v = vec2_zero()
         new_vfx_blast( b.p1, b.sign )
         del( room.bullets, b )
         del( room.entities, b )
         local e = enm_c.entity
         if e.a.cdamagebox != nil then
            del( room.enemies, e )
            del( room.entities, e )
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
   local v = { anm = g_anim[19],
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
   return { min = vec2_init( _x0, _y0 ),
            max = vec2_init( _x1, _y1 ) }
end

function aabb_init_2( _pmin, _pmax )
   return { min = _pmin,
            max = _pmax }
end

-- invert l/r an aabb (assuming sprite size 8... this is ugly)
function aabb_apply_sign_x( aabb, sign_x )
   if sign_x < 0 then
      return { min = vec2_init( 7 - aabb.max.x, aabb.min.y ),
               max = vec2_init( 7 - aabb.min.x, aabb.max.y ) }
   else
      return aabb
   end
end

function is_solid( p )
   return fget( mget( level.room_coords.x * 16 + flr(p.x/8),
                      level.room_coords.y * 16 + flr(p.y/8) ),
                0 )
end

function apply_borders( p, box )
   return vec2_init( clamp( p.x, 0-box.min.x, room.a.csizes.x-box.max.x ),
                     --clamp( p.y, 0-box.min.y, room.a.csizes.y-box.max.y ) )
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
function vec2_init( _x, _y ) return { x = _x, y = _y } end
function vec2_zero() return { x = 0, y = 0 } end
function vec2_get( v, i ) if i==0 then return v.x else return v.y end end
function vec2_set( v, i, s ) if i==0 then v.x = s else v.y = s end end
function vec2_add( v1, v2 ) return { x = v1.x + v2.x, y = v1.y + v2.y } end
function vec2_sub( v1, v2 ) return { x = v1.x - v2.x, y = v1.y - v2.y } end
function vec2_dot( v1, v2 ) return v1.x*v2.x + v1.y*v2.y end
function vec2_scale( s, v ) return { x = s*v.x, y = s*v.y } end
function vec2_min( v1, v2 ) return { x = min(v1.x,v2.x), y = min(v1.y,v2.y) } end
function vec2_max( v1, v2 ) return { x = max(v1.x,v2.x), y = max(v1.y,v2.y) } end
function vec2_flr( v ) return { x = flr(v.x), y = flr(v.y) } end
function vec2_length2( v ) return vec2_dot( v, v )  end
function vec2_length( v ) return sqrt( vec2_length2( v ) ) end
function vec2_clamp( v, l, u ) return { x = min( max( v.x, l.x ), u.x ),
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
      if abs( vec2_get( ray_dir, it_axis ) ) < 0.001 then --g_pdefaultcontext->m_epsilon_dir )
         if abs( vec2_get( ray_pos, it_axis ) ) > vec2_get( aabb_hs, it_axis ) then
            -- no hit
            return nil
         end
         -- otherwise, current axis does not clip the interval, and
         -- other axis must be checked as usual.
      else
         local inv_divisor = 1.0 / vec2_get( ray_dir, it_axis )
         local lambda0 = ( -vec2_get( aabb_hs, it_axis ) - vec2_get( ray_pos, it_axis ) ) * inv_divisor
         local lambda1 = (  vec2_get( aabb_hs, it_axis ) - vec2_get( ray_pos, it_axis ) ) * inv_divisor
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
   rh.point  = vec2_add( ray_pos, vec2_scale( rh.interval.min, ray_dir ) )
   rh.normal = {x=0,y=0}
   if vec2_get( ray_pos, first_hit_axis ) < 0 then
      vec2_set( rh.normal, first_hit_axis, -1 )
   else
      vec2_set( rh.normal, first_hit_axis, 1 )
   end
   return rh
end

--[[
   ray vs aabb
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ray_vs_aabb( ray_pos, ray_dir, interval,
                      aabb )
   local aabb_mid = vec2_scale( 0.5, vec2_add( aabb.min, aabb.max ) )
   local aabb_hs = vec2_scale( 0.5, vec2_sub( aabb.max, aabb.min ) )
   local rp = vec2_sub( ray_pos, aabb_mid )
   local rh = ray_vs_centered_aabb( rp, ray_dir, interval,
                                    aabb_hs ) --hs try to use full aabb instead
   if rh != nil then
      rh.point = vec2_add( rh.point, aabb_mid ) --just translate
   end
   return rh
end

--[[
   ccd between moving box and static aabb
   returns { point, normal, interval } if hit, and nil otherwise
--]]
function ccd_box_vs_aabb( box_pos0, box_pos1, box_aabb,
                          aabb )
   local box_aabb_mid = vec2_scale( 0.5, vec2_add( box_aabb.min, box_aabb.max ) )
   local box_aabb_hs = vec2_scale( 0.5, vec2_sub( box_aabb.max, box_aabb.min ) )
   local box_mid = vec2_add( box_pos0, box_aabb_mid )
   local ray_dir = vec2_sub( box_pos1, box_pos0 )
   local fat_aabb = aabb_init_2( vec2_sub( aabb.min, box_aabb_hs ), vec2_add( aabb.max, box_aabb_hs ) )
   return ray_vs_aabb( box_mid, ray_dir, {min=0,max=1},
                       fat_aabb )
end

--[[
   bp to gather static solid tiles in the map that overlap an aabb
   returns { tile_i, tile_j } if hit, and nil otherwise
--]]
function bp_aabb_vs_map( aabb, flag_mask )
   local overlaps = {}
   local tile_min = vec2_flr( vec2_scale( 0.125, aabb.min ) ) --1/8
   local tile_max = vec2_flr( vec2_scale( 0.125, aabb.max ) ) --1/8
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
   local swept_aabb = aabb_init_2( vec2_add( vec2_min( box_pos0, box_pos1 ), box_aabb.min ),
                                  vec2_add( vec2_max( box_pos0, box_pos1 ), box_aabb.max ) )
   local overlaps = bp_aabb_vs_map( swept_aabb, flag_mask )
   local collisions = {}
   for o in all(overlaps) do

      -- debug bp
      rect( o.tile_j*8, o.tile_i*8,
            (o.tile_j+1)*8, (o.tile_i+1)*8,
            7 )

      local tile_aabb_min = vec2_init( o.tile_j*8, o.tile_i*8 )
      local tile_aabb_max = vec2_add( tile_aabb_min, vec2_init(8,8) ) --8,8 are the sizes of map tile, but could be sub-box

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
                                    aabb_init_2( vec2_add( e.p1, local_aabb.min ), vec2_add( e.p1, local_aabb.max ) ) )
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
088445400884454008845900084598880845500088855440088845900224d0000114d000000000000000000000d89345534d5440000000000000000000000000
00885500008855000845540004554800884554000884550000845540024dd000014dd00000000000000000000d43d3d44d355450000000000000000000000000
00055000000550000845440040554080808450400808440000405440224544001145440000000000000000000d3435888d534435000000000000000000000000
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
00000000000000000000bb00000000000055555000666660007777700888888000000000000000000000000000000000000000005aa555550000000000000000
000000000000000000bbb90400000000005000000060000000000070080000800000000000000000000000000000000000000000055aa5500000000000000000
00cccc0000cccc00bbb4544400bb00000050000000600000000000700800008000028280000080e0000028e0000282800000000000555a000788000000000000
0c6996c00c6aa6c00b405500003b000000555550006666600000007008888880282e2e2e0022e2880022228e282e2e2e00000000000555000078800000000000
0c9aa9c00ca99ac0b00550000003b00000000050006000600000077008000080020082e0000e08e0000028e0020082e000000000000a50000007880000000000
0c9aa9c00ca99ac0005533300003b0000000005000600060000077000800008000000000000000000000000000000000000000000000a0000000780000000000
0c6996c00c6aa6c0550000030000b000000000500060006000007000080000800000000000000000000000000000000000000000000050000000782000000000
00cccc0000cccc000000000000003b000055555000666660000070000888888000000000000000000000000000000000000000000000a0000007822000000000
00000000cdcddcdccdcddcdc0c0d070dc0d0c0000070d0c000000000000222000002332002220000000220000000220200000000000000000000000000000000
7707c077dddddddddddddeedc070c0c0070c0000000c0c0d00000000002333200023388223332000002332020002332000000000000000000000000000000000
cc7cc7ccddddddddddddeedd0d0d0d0dc0d07000000070d00222000000238832002333322383320002388320002388320000000000000000009a8776000a8666
cccccccc1d1dd1dd1d1ee1ddc0c070c00c0d0c00000d0c0d23332000002333320002300223333200023332020023332000000000000000009a88707009a87070
cdcddcdcd1dd1d1dd1de1d1d0d0c0d0cd0c0d00000c0d0c0233832000002320200232020023200200232202002322202607607006876070009a8777699887776
dcdccdcc1d1dd1d11dedd1d1d0d0d0700d07000000070d0d0233320000232000023200000023200023200002232000207770070777700707000a8706009a8777
cdcddcdd1111111111e11111070c0c0dc0c0c0000000c07023222320023232002323000002323200323200003230000270770606787706060000006000000000
dddddddd1111111111111111d0c0d0c00c0d0700000c0d0c32323233232323203232000023232320232320002323000067706565677065650000000000000000
22222222111111111111111122222222444444444444444400066600000066600006660000666000000006600000000000000000000000000000000000000000
42929242d1c1c1d151616151526662554ff44fff4f4fff4f00688860000688860068886006888600000068860000000000000000000000000000000000000000
49999244dcccc1dd5666615556666255ff4ff4f4f4f4f4f4004668600014468604446860446686000441448600000c000000c000000000000000000000000000
49999244dcccc1dd566661555666625544444444444444440444160004144160044444444441600041114486000007c000007c00000000000000000000000000
2222222211111111111111112222222244444444444444440441114041144100011444444411110011114460000007cd00007cd0000000000000000000000000
242929241d1c1c1d15161615552666254f4f4f4f4f4ff4ff441111444111444001111144011111401111444000007ccd0007ccd0000000000000000000000000
44299994dd1ccccd5516666555266665f4fff4f4fff44ff44411114401111440d111100001111140511114400007ccdd007ccdd0000000000000000000000000
44299994dd1ccccd5516666555266665444444444444444400d5550000555d00d115550005551d00551144400ccccdd00cccddd0000000000000000000000000
2222222244f444440000000000000000222222224494444400000000000000000000000000000000000000000000000000000000000000000000000000000000
4999944444444f4400060000000060004cc7ddd44444494400000000000000000dd0000000022000022220000022220000000000000000000000000000000000
499994444f44444406050060060050604cccddd449444444000000000000000000dd200000112800000282000000282000000000000000000000000000000000
499994444444f44f05050050050050504cccddd444449449000000000000000010dd2800011dd220000122000001122000000000000000000000000000000000
2222222244f44444050500500500505044444444449444440000000000000000011dd22010dd0002001110000011100000000000000000000000000000000000
444999944444444405560560065065504dddc7744444444400000000000000000000000200dd00000d111dd00dd111d000000000000000000000000000000000
44499994f44444f456560565565065654dddcc74944444940505a0000005a00000000000000d0000d0d0d00dd00d0d0d00000000000000000000000000000000
444999944444f44465556556655655564dddccc44444944400566500055665000000000000000000d0000d0000d0000d00000000000000000000000000000000
4f4f4f4ff4f4f4f40000000000000000000220022000000000000000000000000000002200220000000000000000000000000000033bbbb00033333003333300
44f4f4ffff4f4f4400000000000000000002220022000000000022002200000000000022200220000000000000000000000000003bbbbbbb03bbbbb33bbbbb30
044f4f4ff4f4f44000000000000000000000222022200000000022200220000000000002220222000000000000000000000000003bb3b3bb3bb3bbb3b333bbb3
0044f4ffff4f440000000000000000000000222222200000000002220222000000000002222222000000000000000000000000003bbb3b3b3bb3b3bb3bbb33b3
0004f4ffff4f400000000000000000000000288288200000000002222222000000000002882882000000000000000000000000003b33bbb33b3b3bbbb3b3bbb3
00044f4ff4f4400000000000000000000000222222200000000002882882000000003332222222000000000000000000000000003bbb333b3b3bb3bbbb3b3bb3
00004f4ff4f40000000000000000000000333222223330000333322222223300000333332200223000000000000000000000000003bbbbb33b3b3bbbbbbbbbb3
00004f4ff4f4000000000000000000000333b22222bb33003333332222233330003333bb220023330000000000000000000000000033333003b3bbb00bbbb330
00004ffff4f4000000000000000000003333bbbb3bbb333033033b22222b3330003303bbb2002b33000000000000000000000000000003330bbb3b30b3b30000
00004ffff4f40000000000000000000033003bbb3bb3033033003bbb3bb300330330033bb3202b3300000000000000000000000000003bbbbbb3b3b33b3b3000
00004ffff4f4000000000000000000003300033353300033333003335330033303330033333220330000000000000000000000000003bb3bbb3bb3b3bb3b3000
000044ffff44000000000000000000003330dd5555dd03333330ddd555dd033303330ddd555dd3330000000000000000000000000003bb3bbbb3b3b33b3b3000
000044ffff4400000000000000000000333ddd0555dd03330000ddd555ddd0000333ddd555dd33300000000000000000000000000003b3b3bb3b3bb3b3bb3000
00004f4ffff400000000000000000000000dd10550d10000000dd10550dd1000000dd1550dd133300000000000000000000000000003b3bb3bbb3bb3b3bb3000
00004f4ffff40000000000000000000000d111000011100000d111000011100000d11100011100000000000000000000000000000003b3b33bbbbb30bbb30000
00004f4ffff40000000000000000000000111110011111000011111001111100001111000111100000000000000000000000000000003b3b0333330033300000
00004f4ff4f40000000000000000000000011001100000000000000000000000000001111000000000000000000000004000000000000004ffff4ffffff40000
00004f4ff4f40000000000000000000000011100110000000000110011000000000000011110000000000000000000004000000000000004ffff4ffffff40000
00004f4ff4f4000000000000000000000000111011100000000011100110000000000000111100000000000000000000440000000000004fffff4ffffff40000
000044ffff4400000000000000000000000011111110000000000111011100a0000000011111100000000000000000004f400000000004f4f4ff4f4fff440000
000044ffff440000000000000000000000a01881881000a09000011111110a0008a80011181810000000000000000000f4f4000000004f4ff4ffff4fff440000
00004ffffff4000000000000000000000a001111111000a009000188188100a0000a99a1111109900000000000000000ff4f40000004f4f4ff4ff4fff4f40000
00004ffffff4000000000000000000000a222111112220a0092221111111228a0000022a99aa989a0000000000000000f4f4f400004f4f4fff4ff4fff4f40000
00004ffffff40000000000000000000008a23111113322808a222211111228aa00889a88aa8a8a8800000000000000004f4f4f444444fff4ff4ff4fff4f40000
00004f4ff4f4000000000000000000008aa2333323332aa8a882231111132980aa902299889888a800000000000000004fff444444f4f4f4f4f4f4f4f4f40000
00004f4ff4f40000000000000000000098002333233202899a80233323320aa80000988a999aa99a0000000000000000f4f4f400004f4f4f4ff4f4f4f4f40000
00044f4ff4f440000000000000000000aa800222522008aa88a0022252200a8800998aa2225008a000000000000000004f4f40000004f4ff4ff4f4fff4f44000
0004f4ffff4f40000000000000000000a880dd5555dd088a8aa0ddd555dd0999088000dd555dd0000000000000000000f4f4000000004f4ff4ffff4fff4f4000
0044f4ffff4f44000000000000000000999ddd0555dd09999980ddd555ddd00000011ddd550dd00000000000000000004f400000000004f4ffff4f4fff4f4400
044f4f4ff4f4f4400000000000000000000dd10550d10000000dd10550dd100000011d0550dd10000000000000000000f4000000000000444f4f4ffff4f4f440
44f4f4ffff4f4f44000000000000000000d111000011100000d11100001110000011100001111000000000000000000040000000000000044f4ff4f4ff4f4f44
4f4f4f4ff4f4f4f4000000000000000000111110011111000011111001111100001000000001110000000000000000004000000000000004f4f4f4f4f4f4f4f4
22525252252525220000000220000000252555552222222265255556111115555551166100000080080000000000000000000000000000000000000000000000
00252525525252000000000220000000252552552666625556655665661555cb8855516108000090090000800000000000000000011111100000000111000000
00025255552520000000002222000000252552552266625556866c6561555cb88aa6551189000890098000980000000000000000000000110000000001111110
0000252552520000000002522520000052555525252662555565265515555cb8abbb55519a90099aa99009a90000000000000000000000000000000000000000
00000252252000000000252552520000525255255252222225655652156b5cb8ab55555144400444444004440000000000000111000000000000000000000000
00000022220000000002525555252000555255255525262556b6696555ab55cbb55ccc5544400444444004440000000000011101110000000111110000000000
0000000220000000002525255252520055525552525252655665566558abb55c55cbbbc504000040040000400000000001110000000000000000011100000000
00000002200000002252525225252522555255522525252565555256588aab555cb888b504000040040000400000000000000000000000000000000000000000
04f444f44f444f4000000004400000000000000000000000005550005b888bc555baa88511000000000000111100000000000000000000000000000000000000
0044f444444f440000000004400000000000000000000000056665005cbbbc55c55bba8500100011110001000010001100000000111000000000000000001110
00004f4444f40000000000444400000000000000000000000566665055ccc55bbc55ba5500010100001010000001010000000000001111100000001110111000
0000044444400000000004f44f400000000000000000000006555665155555ba8bc5b65110001000000100001000100000000000000000000000000011100000
000000f44f00000000004444444400000000000000000000566665651555bbba8bc5555100010001100010000001000000000000000000000000000000000000
000000444400000000044f4444f4400000000000000000005655666511556aa88bc5551600101000000101000010100001111110000000001100000000000000
00000004400000000044f444444f440000000000000000005666666016155588bc55516611000100001000111100010000000011100000000111111000000000
000000000000000044f444f44f444f44000000000000000036336363166115555551111100000011110000000000001100000000000000000000000000000000
2222222256556556565655656566556550505050000000003b3b43b4000003000030000010000011111155554004004000000677776000000000067777600000
02222222656665656566665665556656555555550000000033b33b4b000300300030000001000100555511114004004000067787778760000006777777776000
0002525556666656566656655666666550505050000000004343433b030b30300300300000101000000000000400400400677768768876000067776676677600
000025256665556656656665666565656050505000000000f4444344030300b00303b03000010000111155550400400406776678777877600677667777777760
0000025256565666666556566655566666555555000000004444f4440b0300300b00303000001000555511114004004007786877778777700777777777777770
0000002256666665556566566566666560505050000000004f444444300303b0030030b000010100000000004004004067778677778677766777666777767776
000000026566555656566655665666565050505000000000444444f44b33b4340b30300300100010111155550400400478668778778766877766777677776677
0000000256556656666665666556556550505050000000004444f444b43b4343434b33b411000001555511110400400478788677878777887777667777777777
22222222055556500655555005565560000000000000889aa99980000000000000000000f44444ff110011000400400478787777877777787777777777777776
222222206566656555666656556566550000000000000089aa88000000000000000000004f444f44001100110400400478787787877687787776777777767776
5525200056666655566656655666666500000000000088aa98000000000000000000000044f4f444000000004004004067877687877687766777766777767776
52520000566565655665666556656565000000000008999aaa8800000008000800000000444f4444110011004004004007877787776887700777777777677770
2520000056565665566656565656566500000000000088aaa999800000898089800080004444f444001100110400400406776887767687600677677776767760
220000005666666565656665556666650000000000000089aa8800008089808998089808444f4f44000000000400400400677877777876000067777777777600
2000000055665655565666555656665600000000000088aa9800000098a9a8a99808980844f444f4110011004004004000067877777660000006777777776000
20000000065565500555555005655550000000000008999aa9880000a99aa99a9a8a9a89ff44444f001100114004004000000777766000000000077776600000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000008080008102040800000000000024000020202808080000000000000804040404001010101010000000000000000000040010202010500000000000000000000
4040000002020202020200000040000040400000020202020202000000000000404000000202020202020000404040404040000002020202020200004040404040404040404040404040400040404040010101010000014040400000404040400101010105000140404000404040404001010101000202020200000040404040
__map__
00008d00000000008d8d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8d008d008d8d00008d008d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c2c300000000000000
008d8d008d008d008d8d8d000000000000000000000000000000000000000000000000000000c2c4c4c4c4c3000000000000000000000000000000000000000000635d00000000006300006300000000000000000000000000000000000000000000000000000000000000000000000000000000000000626200000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000c2c14d00004dc0c30000000000000000000000000000000000000000636363006300000000004d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000626200000000000000
0000000000000000000000000000000000c2c4c4c4c4c4c4c4c4c4c4c4c4c4c300c2c4c4c4c1000000000000c0c4c4c4c4c4c4c4c300c2c4c4c4c4c30040000000634dc063636300000000000000000000000000000000000000000000000000000000000000000000eeef0000000000000000000000c26262c3000000000000
0000000000000000adbc00000000000000c4c1004dc0c4c1c0c1c0c4c1c0c1c0c4c10000000000000000000000c0c6c10000004dc0c4c100000000c0c4f0000000630000000000e063000000000063f000000000000000000000000000000000000000000000000000feff00000000000000000000c262626262c30000000000
00000000ad000000bdac00000000000000c400000000c400000000c400000000c400000000000000000000000000c4000000000000c4000000000000c40000000063000000000000c0630000000063000000000000000000000000000000000000000000000000000000000000cccd0000000000006262c7c862620000000000
00000000bdac0000adbc0000000000ac00c400000000c400000000c400000000c400000000000000000000000000c4000000000000c4000000000000c400000000630000000000000000005d6300630000000000000000000000000000000000000000000000000000cecf0000dcdd0000000000006262d7d862620000000000
0000000000bdacadbc0000ad0000adbc00c400000000c400000000c400000000c4000000000000000000000000636363f000000000c4000000000000c4000000006300000000636363636363c1006300000000000000606070000000000000000000000000cecfcdccdedfcd00000000000000c3c2626262626262c3c2000000
000000000000bdbe000000bdacadbc0000c400000000c400000000c400000000c4006363630000000000e0f000c0c4c10000000000c4000000000000c4000000006300000063c1000000000000006300000000000060607070600000000078000000000000dedfcecfdddcddcecf0000000000c4c1626262626262c0c4000000
00000000adac00beadbc0000bdbeacad00c400000000c400000000c4006600636363634d0000e0f0000000000000c4000000000000c4000000000000c00000000063000063c10000000000000000630000000000006070607070646564656400000000cccd0000dedd000000decccc00000000c40063636363636300c4000000
5c0000bdbcbdacbebc00000000bdbebc00c400000000c40000006363636363636363d10000000000000000000000c400000000e06363000000000000000000000063635c00760063636363000000630000000000007074607470c10000000000000000dcdd000000000000000000cecf00c3c2636363c66363c6636363c3c200
5c5c00000000bdbe000000000000be0000c400000000c432636363636363636371d1000000000000000000000000c4000000000000c46300000000000000000000c06363636363c1000000000063c100000000006360707060700000000000000000000000000000000000630000dedf00c4c163636363c1c063636363c0c400
ebe40000000000be000000000000be0000c4000000636363636363637575757575000000000000e0f00000000000c4000000000000c4006300000000000000630000c0c4000000000000000063c1000000630000c07060607060000000000000000000000000006363cecf000000630000c40063c663c18485c063c66300c400
ebe4e82b2ce8e8be3072d60030e8be00c2c4c363757575757575757575757575755c000063000000005c006300c2c4c300000066c2c4c3750000000000566363000000c400000000006663757500006363636300006070ae60700000000000f2f2000000007a6363c1dedf000000c063c2c4c363636300949500636363c2c4c3
ebe6717171e6e6e671e6e65ce6e671e6636363636363636363717171717171717171717163737372727373636363636362626262626275757562626262626262626262626262626262757575757575626262626262626262626250f3505050506262626262626262505050505050506262626262626262626262626262626262
eb00d071717171717171717171717171717171717171717171717171717171717171717163636363636363636363636363637171717171717171717171717171626262626271717171717171717171717171717171717171715151515151515151f3f3f3f3f3f371717171717171717171717171717171717171717171717171
eb0000d071d1d07171717171717171717171717171717171717171717171d0d1d07171d100c4c10000c0c40000000000000000000000000000000000d071d1000000000000d0d100000000004d00d071d100000000d07171715151515151515151f3f3f3f3f3f37171717171f3717171717171717171d1d0d1d071d1d0717171
d0000000000000d0717171717171d1d071d1d0717171d14dd071d14d71d100000000000000c400430000c40000000000000000660000000000000000004d00000000006600000000000000000000004d00000000000000d0715151f351515171f3f3f3f3f3f3717171f3717171717171717171d071d10000000071000071d171
00d00000000000004dd0717171d10000d100004dd071000000710000d10000000000000000f2f2f2f2f2f200000000000072e3e3e3e3e3e3e3e3e300000000000072e3e3e3e3e3e3e3e3e30000000000000000f100000000d0715371535371717171717171717171717171d1d071f371f671d100d10000000000d00000d000f5
0000d0000000000000007171d1000000000000000071000000d100000000000000000000f2f2e9e9e9e9f2f20000000000e3c1e9e9e9e9e9e9e9c0e30000000000e3c1e9e9e9e9e9e9e9c0e300000000000000c0f1000000005553535353540000000000000000000000000000d07171f6d100000000000000000000000000f5
00000000000000000000d071000000000000000000d000000000000000000000000000f2f2e9e9e9e9e9e9f2f200000000e3e9e9e9e9c9e9e9e9e9e9e9e3e3e3e3e3e9e9e9e9c9e9e9e9e9e9e9e9e3e3e3720000c0f100000055535353535400000000000000000000000000000000d0f60000000000000000000000000000f5
00000000d10000000000007100000000000000000000000000000000000000000000f2f2e9e9e9e9e9e9e9e9f2e3000000e3e9e9e9e9e9e9e9e9e9e9e3c1e9e9e9e9e9e9e9e9e9e9e9e9e9e9e3e300e3e3c1000000c0f156005540545353540000000000000000000000000000780000f600000000000000000000000000c3f5
000000d1000000000000007100000000000000000000000000000000000000000072f2e9e9e9e9e9e9e9e9e9e9e3e3005ce3e9e9e97ae9e9e9e9e9e9e9e9e9e9e9e9e9e9e97ae9e9e9e9e9e3000000e3e300000000004df1f1f1f1545353540000000000000000000000000000c20000f6c20000000000000000c20000c2c1f5
0000d10000000000000000d0000000000000000000000000000000000000000072f2e9e9e9c9e9e9e9e9c9e9e9e9e37272e3e9e3e3e3e3e3e3e3e9e9e9e9e9e9e9e3e9e9e3e3e3e3e3e3e3e340000000000000000000000000555554f153545600000000000000000078000000c0c300f6c0c30000c300000000c0c3c2c100f5
00d1000000000000000000000000000000000000000000d0d300006600000000f2e9e9e9e9e9e9e9e9e9e9e9e9e9e9e3e3c1e9e9e9e9e9e9e9e9e9e9e3e3e3e3e3c1e9e3c1e9e9e9e9e9e9c0e30000000000000000000000005555545555f1f1000000000000000000c300000000c0c30000c0c3c2c100c2c30000c0c40000f5
00000000000000000000000000000000000000000000d071d1d0717171d10000c4e9e9e9e9e9e9e9e9e9e9e9e9e9e9c4c4e9e9e9e9e9c9e9e9e9e9e3c1e9e9e9e9e9e9e9e9e9c9e9e9e9e9e9e9e9e3e3e3f000000000000000555554f1f154000000000000000000c2c100000000c2c4000000c4c100c2c4c4c30000c40000f5
71d100000000000000000000000000000000000000d071d10000d0717171d100c4c3e9e9e9e9e9e9e9e9e9e9e9e9c2c4c4c3e9e9e9e9e9e9e9e9e3c1e9e9e9e9e9e9e9e9e9e9e93ce9e9e9e9e95dc0e3e3000000000056000055f154555554000000000000000000c0c300c20000c1c40000c2c100c2c10000c0c300c0c300f5
7171d10000000000000000000000000000000000d071d10000000000d071d3f3f3f3f2f2f2f2f2f2f2f2f2f2f2e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e9e9e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e30000000000f1f10055555455545400000000000000000000c400c0c30000c40000c40000c400000000c40000c400f5
f17171d1000000000000000000000000000000d071d10000007a00000075e2e2e30000000000f200000000003c00000000000000000000000000000000c0f100000000000000000000000000000000e3e300000000000000f1f1555455545400000000000000000000c40000c40000c40000c40000c400a4a500c40000c400f5
f1f1d10000004ef27200004e00004ef10000d071d100f240f2f20000007575755d770000005600003c00e300000000f10000003c0000000000000000000000000000003c0000000000000000000000000000000000000000005555f15050f10000e7e8e8e7e74e0056f2f7f7f2f7f7f100c2c400f7c400b4b500c4f700c4c3f5
f1f1f2f3f1f2f3f3f3f3f2f2f1f3f2f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f17171e6e6e6e6e6e6e6e6e6e6e6e6e6e6e671f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
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

