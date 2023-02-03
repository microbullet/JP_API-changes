id = "navy"
setup = {
  slots_max = { 10, 10 },
}
weapons = {
  { gid = 0, name = "Solomon", chamber_max = 2, firepower = 4, firerange = 3, spread = 55, ammo_max = 6, }, --4
  { gid = 1, name = "Victoria", chamber_max = 1, firepower = 5, firerange = 4, spread = 45, ammo_max = 3, },
  { gid = 2, name = "Ramesses II", chamber_max = 2, firepower = 4, firerange = 3, spread = 65, ammo_max = 5,
    knockback = 50, },
  { gid = 3, name = "Richard III", chamber_max = 3, firepower = 3, firerange = 3, spread = 75, ammo_max = 8 },
  { gid = 4, name = "Makeda", chamber_max = 2, firepower = 3, firerange = 3, spread = 50, ammo_max = 6, blade = 2 }
}
ranks = {
  { nothing = 1 },
  { gain = { 0, 0 } },
  { gain = { 1 } },
  { king_hp = 1 },
  { spread = 10 },
  { ammo_max = -1 },
  { gain = { 2 } },
  { king_hp = 1 },
  { rook_hp = 1 },
  { boss_hprc = 200 },
  { gain = { 3 }, delay = 10 },
  { knight_hp = 1 },
  { spread = 15 },
  { rook_hp = 1 },
  { all_hp = 1, ammo_max = 2 },
}
base = {
  promotion = 1, surrender = 1, moat_row_4 = 1, moat_row_5 = 1, flip_walk = 1, bridge_col_2 = 1, bridge_col_6 = 1,
  gain = { 3, 0, 0, 0, 1, 5, 2, 0 },

}
allow_modules = { "moats" }

-- JP_API CODE
do -- VERSION 2.3
  MODNAME = current_mod

  MODULES = {}
  foreach(ls("mods/" .. MODNAME .. "/modules/"), function(module_name)
    if module_name:sub(-4) ~= ".lua" then return end
    module = table_from_file("mods/" .. MODNAME .. "/modules/" .. module_name:sub(1, -5))
    if ban_modules and tbl_index(module.id, ban_modules) > 0 then return end
    if allow_modules and tbl_index(module.id, ban_modules) < 0 then return end
    add(MODULES, module)
  end)

  do -- LOGGING CODE
    function _logv(o, start_str, max_depth)
      if not start_str then
        start_str = ""
      end
      if not max_depth then
        max_depth = 4
      end
      local function data_tostring_recursive(data, depth, parent)
        local function indent(n)
          local s = "  "
          return s:rep(n + 1)
        end

        if data == nil then
          return "nil"
        end
        local data_type = type(data)
        if data_type == type(true) then
          if data then
            return "true"
          else
            return "false"
          end
        elseif data_type == type(1) then
          return "" .. data
        elseif data_type == type("") then
          return "\"" .. data .. "\""
        elseif data_type == type(function() end) then
          return "function()"
        elseif data_type == type({}) then
          if depth == max_depth then
            return "{...}"
          end
          local data_string = "{"
          for key, value in pairs(data) do
            if value == _G then
              data_string = data_string .. "\n" .. indent(depth) ..
                  data_tostring_recursive(key, depth + 1, data) .. ": {_G}," -- don't recurse into _G
            elseif value == parent then
              data_string = data_string .. "\n" .. indent(depth) ..
                  data_tostring_recursive(key, depth + 1, data) .. ": {parent}," -- don't recurse into parent
            else
              data_string = data_string .. "\n" .. indent(depth) ..
                  data_tostring_recursive(key, depth + 1, data) ..
                  ": " .. data_tostring_recursive(value, depth + 1, data) .. ","
            end
          end
          if data_string == "{" then
            return "{}"
          end
          if data_string:sub(-1) == "," then
            data_string = data_string:sub(1, -2)
          end
          data_string = data_string .. "\n" .. indent(depth - 1) .. "}"
          return data_string
        else
          return "MISSING DATA TYPE: " .. data_type
        end
      end

      _log("DATA START: " .. start_str .. "\n" .. data_tostring_recursive(o, 0) .. "\nDATA END")
    end

    function _logs(o, value, max_depth)
      if not max_depth then
        max_depth = 4
      end
      local function search_recurse(p, v, d, path)
        if type(p) == type({}) then
          for k, v2 in pairs(p) do
            if v2 == v then
              if (type(k) == type("")) or (type(k) == type(1)) then
                _log(path .. "." .. k)
              else
                _log(path .. "[non-string key]")
              end
            elseif (d < max_depth) and (v2 ~= _G) then
              if (type(k) == type("")) or (type(k) == type(1)) then
                search_recurse(v2, v, d + 1, path .. "." .. k)
              else
                search_recurse(v2, v, d + 1, path .. "[non-string key]")
              end
            end
          end
        end
      end

      if (type(value) == type("")) or (type(value) == type(1)) then
        _log("SEARCHING FOR " .. value)
      else
        _log("SEARCHING FOR NON-STRING/NUMBER")
      end
      search_recurse(o, value, 0, "")
    end
  end

  do -- LISTENER CODE
    ons_updated = false
    function init_listeners()
      if LISTENER then
        del(ents, LISTENER)
      end
      LISTENER = mke()
      do -- EVENT LIST
        LISTENER.listeners = {}
        LISTENER.specials = {}

        LISTENER.listeners["shot"] = {}
        LISTENER.listeners["blade"] = {}
        LISTENER.listeners["move"] = {}
        LISTENER.listeners["special"] = {}

        LISTENER.listeners["upd"] = {}
        LISTENER.listeners["dr"] = {}

        LISTENER.listeners["bullet_init"] = {}
        LISTENER.listeners["bullet_upd"] = {}

        LISTENER.listeners["grenade_init"] = {}
        LISTENER.listeners["grenade_upd"] = {}
        LISTENER.listeners["grenade_bounce"] = {}
        LISTENER.listeners["grenade_land"] = {}
        LISTENER.listeners["grenade_explode"] = {}

        LISTENER.listeners["bad_death"] = {}

        LISTENER.listeners["pawn_death"] = {}
        LISTENER.listeners["knight_death"] = {}
        LISTENER.listeners["bishop_death"] = {}
        LISTENER.listeners["rook_death"] = {}
        LISTENER.listeners["queen_death"] = {}
        LISTENER.listeners["king_death"] = {}

        LISTENER.listeners["after_black"] = {}
        LISTENER.listeners["after_white"] = {}

        LISTENER.listeners["floor_start"] = {}
        LISTENER.listeners["floor_end"] = {}
      end
      local function card_fixing(ent)
        function fix_card(tfcard)
          tfcard.old_dr = tfcard.dr
          tfcard.og_gid = tfcard.gid
          tfcard.card_counter = true
          tfcard.dr = function(self, ...)
            if self.flip_co and self.flip_co > 0.5 then
              self.gid = 59 + self.team
            else
              self.gid = self.og_gid
            end
            self.old_dr(self, unpack({ ... }))
          end
        end

        if ent.gid and ent.gid >= 120 and not ent.card_counter then
          fix_card(ent)
        end
        if ent.cards then
          for sub_ent in all(ent.cards) do
            if sub_ent.gid and sub_ent.gid >= 120 and not sub_ent.card_counter then
              fix_card(sub_ent)
            end
          end
        end
      end

      local function click_tracking(ent)
        local function grenade_tracking(ent) -- (Glacies)
          local function setup_bounce(grenade)
            if not grenade.twf then return end
            grenade.old_twf = grenade.twf
            grenade.state = (grenade.jz > 20)
            grenade.twf = function()
              if grenade.state then
                for listener in all(LISTENER.listeners["grenade_bounce"]) do
                  listener(grenade)
                end
              else
                for listener in all(LISTENER.listeners["grenade_land"]) do
                  listener(grenade)
                end
                local delay = 57
                local sq = get_square_at(grenade.x, grenade.y)
                if sq then
                  if abs(hero.sq.px - sq.px) < 2 and abs(hero.sq.py - sq.py) < 2 then delay = 236 end
                  wait(delay, function()
                    for listener in all(LISTENER.listeners["grenade_explode"]) do
                      listener(grenade)
                    end
                  end)
                end
              end
              grenade.old_twf()
              setup_bounce(grenade)
            end
          end

          if not ent.fra then return end
          if ent.tracked then return end
          ent.tracked = true
          for listener in all(LISTENER.listeners["grenade_init"]) do
            listener(ent)
          end
          ent.old_upd = ent.upd
          ent.upd = function(self)
            for listener in all(LISTENER.listeners["grenade_upd"]) do
              listener(self)
            end
            self.old_upd(self)
          end
          setup_bounce(ent)
        end

        local function special_tracker(ent2)
          if ent2.right_clic then
            local skip = false
            for special, func in pairs(LISTENER.specials) do
              if stack[special] then
                ent2.old_right_clic = func
                skip = true
              end
            end
            if not skip then
              ent2.old_right_clic = ent2.right_clic
            end
            ent2.right_clic = function()
              ent2.old_right_clic()
              for listener in all(LISTENER.listeners["special"]) do
                listener()
              end
              for ent3 in all(ents) do
                grenade_tracking(ent3)
              end
            end
          end
        end

        local function shoot_tracker(ent2)
          ent2.old_left_clic = ent2.left_clic
          ent2.left_clic = function()
            local old_sq = hero.sq
            ent2.old_left_clic()
            if old_sq ~= hero.sq then
              for listener in all(LISTENER.listeners["move"]) do
                listener()
              end
            end
            local shot = false
            for b in all(bullets) do
              if b.shot and not b.old_upd then
                b.old_upd = b.upd
                b.upd = function(self)
                  for listener in all(LISTENER.listeners["bullet_upd"]) do
                    listener(self)
                  end
                  self.old_upd(self)
                end
                for listener in all(LISTENER.listeners["bullet_init"]) do
                  listener(b)
                end
                shot = true
              end
            end
            if shot then
              for listener in all(LISTENER.listeners["shot"]) do
                listener()
              end
            end
          end
          special_tracker(ent)
        end

        local function blade_tracker(ent2)
          ent2.old_left_clic = ent2.left_clic
          ent2.left_clic = function()
            local folly = check_folly_shields(hero.sq)
            if folly then
              if ((#hero.sq.danger == 1) and (hero.sq.danger[1] == get_square_at(mx, my).p)) or
                  hero.bushido then
                folly = false
              end
            end
            ent2.old_left_clic()
            if not folly then
              for listener in all(LISTENER.listeners["blade"]) do
                listener()
              end
            end
          end
          special_tracker(ent)
        end

        local function move_tracker(ent2)
          ent2.old_left_clic = ent2.left_clic
          ent2.left_clic = function()
            local old_sq = hero.sq
            ent2.old_left_clic()
            if old_sq ~= hero.sq then
              for listener in all(LISTENER.listeners["move"]) do
                listener()
              end
            end
          end
          special_tracker(ent)
        end

        if not hero then return end
        local ent_sq = get_square_at(ent.x, ent.y)
        if ent.button and ent_sq and ent.left_clic and not ent.old_left_clic then
          local hero_square = hero.sq
          if not hero_square then return end
          if abs(ent_sq.px - hero_square.px) <= 1 and abs(ent_sq.py - hero_square.py) <= 1 then
            -- WITHIN 3x3
            if not ent_sq.p then move_tracker(ent)
            elseif stack.blade and ent_sq.p.hp <= stack.blade then blade_tracker(ent)
            else shoot_tracker(ent) end
          else
            shoot_tracker(ent)
          end
        end

      end

      LISTENER.run = true
      LISTENER.jumping = false
      function LISTENER:upd()
        if not LISTENER.run then return end
        for ent in all(ents) do
          click_tracking(ent)
          card_fixing(ent)
        end
        for listener in all(LISTENER.listeners["upd"]) do
          listener(self)
        end
        for special, func in pairs(LISTENER.specials) do
          if stack.special == special then
            stack.special = "grenade"
            stack[special] = true
          end
        end
        if hero and hero.twc then
          LISTENER.jumping = true
        end
        if hero and (not hero.twc) and LISTENER.jumping then
          LISTENER.jumping = false
          for listener in all(LISTENER.listeners["after_black"]) do
            listener()
          end
        end
      end

      function LISTENER:dr()
        if not LISTENER.run then return end
        lprint("JP_API 2.3", 250, 162.5, 2)
        lprint(MODNAME, 5, 162.5, 2)
        for listener in all(LISTENER.listeners["dr"]) do
          listener(self)
        end
      end

      do -- File Loading setup
        mode.on_new_turn = function()
          if on_new_turn then
            on_new_turn()
          end
          for listener in all(LISTENER.listeners["after_white"]) do
            listener()
          end
        end

        mode.on_bad_death = function(e)
          if on_bad_death then
            on_bad_death(e)
          end
          for listener in all(LISTENER.listeners["bad_death"]) do
            listener(e)
          end
        end

        mode.on_pawn_death = function()
          if on_pawn_death then
            on_pawn_death()
          end
          for listener in all(LISTENER.listeners["pawn_death"]) do
            listener()
          end
        end

        mode.on_knight_death = function()
          if on_knight_death then
            on_knight_death()
          end
          for listener in all(LISTENER.listeners["knight_death"]) do
            listener()
          end
        end

        mode.on_bishop_death = function()
          if on_bishop_death then
            on_bishop_death()
          end
          for listener in all(LISTENER.listeners["bishop_death"]) do
            listener()
          end
        end

        mode.on_rook_death = function()
          if on_rook_death then
            on_rook_death()
          end
          for listener in all(LISTENER.listeners["rook_death"]) do
            listener()
          end
        end

        mode.on_queen_death = function()
          if on_queen_death then
            on_queen_death()
          end
          for listener in all(LISTENER.listeners["queen_death"]) do
            listener()
          end
        end

        mode.on_king_death = function()
          if on_king_death then
            on_king_death()
          end
          for listener in all(LISTENER.listeners["king_death"]) do
            listener()
          end
        end

        mode.on_empty = function()
          if on_empty then
            on_empty()
          end
          for listener in all(LISTENER.listeners["floor_end"]) do
            listener()
          end
        end

        mode.next_floor = function()
          if next_floor then
            next_floor()
          end
          for listener in all(LISTENER.listeners["floor_start"]) do
            listener()
          end
        end
      end

      do -- FIX EXHAUST (Glacies)
        mode.grow = function()
          grow()
          local total_choices = 0
          for ent in all(ents) do
            if ent.cards then
              total_choices = total_choices + 1
            end
          end
          for ent in all(ents) do
            if ent.cards then
              for ca in all(ent.cards) do
                wait(23 + 8 * total_choices + 16 * #ent.cards, function()
                  if ca.flipped then
                    ca.flipped = false
                    ca.old_upd = ca.upd
                    ca.upd = nil
                    wait(2, function()
                      ca.flipped = true
                      ca.upd = ca.old_upd
                      ca.old_upd = nil
                    end)
                  end
                end)
              end
            end
          end
        end
      end

      do -- BAN CARDS (Glacies)
        if not mode.ban then mode.ban = {} end
        if mode.weapons and mode.weapons[mode.weapons_index + 1].ban then
          for ca in all(mode.weapons[mode.weapons_index + 1].ban) do
            for acard in all(cards.pool) do
              if acard.id == ca then
                del(cards.pool, acard)
              end
            end
          end
        end
        if mode.ranks and mode.ranks[mode.ranks_index + 1].ban then
          for ca in all(mode.ranks[mode.ranks_index + 1].ban) do
            for acard in all(cards.pool) do
              if acard.id == ca then
                del(cards.pool, acard)
              end
            end
          end
        end
      end

      do -- CUSTOM GUN ART
        weapons_width, weapons_height = srfsize("weapons")
        if weapons_width == 160 then
          target("weapons")
          if mode.weapons then
            for i = 0, 15 do
              for j = 0, 15 do
                sset(32 + i, j, pget(144 + i, 16 * (mode.weapons_index + 1) + j))
              end
            end
          else
            for i = 0, 15 do
              for j = 0, 15 do
                sset(32 + i, j, pget(144 + i, j))
              end
            end
          end
        end
      end

      for module in all(MODULES) do -- Load important parts of modules
        if module.start then
          setfenv(module.start, getfenv(1))
          module.start()
        end
        for k, v in pairs(module) do
          if k == "on_new_turn" then
            setfenv(v, getfenv(1))
            add_listener("after_white", v)
          end
          if k == "on_empty" then
            setfenv(v, getfenv(1))
            add_listener("floor_end", v)
          end
          if k == "next_floor" then
            setfenv(v, getfenv(1))
            add_listener("floor_start", v)
          end
          if k:sub(1, 3) == "on_" and LISTENER.listeners[k:sub(4)] then
            setfenv(v, getfenv(1))
            add_listener(k:sub(4), v)
          end
        end
      end
    end

    function add_listener(event, listener)
      if not LISTENER.listeners[event] then
        LISTENER.listeners[event] = {}
      end

      del(LISTENER.listeners[event], listener)
      add(LISTENER.listeners[event], listener)
    end

    function remove_listener(event, listener)
      del(LISTENER.listeners[event], listener)
    end

    function new_special(name, special)
      LISTENER.specials[name] = special
    end
  end
  local function do_swapping()
    target("weapons")
    local weapons_img = {}
    local weapons_width, weapons_height = srfsize("weapons")
    for p = 1, weapons_width * weapons_height do
      weapons_img[p] = pget(p % weapons_width, flr(p / weapons_width))
    end

    for k, weapon in pairs(weapons) do
      if k ~= (weapon.gid + 1) then
        y_offset = 24 * ((weapon.gid + 1) - k)
        for x = 0, 95 do
          for y = (24 * (k - 1)), (24 * (k)) - 1 do
            pset(x, y, weapons_img[x + (y + y_offset) * weapons_width])
          end
        end
        y_offset = 16 * ((weapon.gid + 1) - k)
        for x = 96, 160 do
          for y = (16 * k), (24 * (k + 1)) - 1 do
            pset(x, y, weapons_img[x + (y + y_offset) * weapons_width])
          end
        end
      end
    end
  end

  function initialize()
    palette("mods\\" .. MODNAME .. "\\gfx.png") -- USE CUSTOM PALLETE

    load_mod("none") -- FIX GLITCHED ART
    load_mod(MODNAME)

    if mode.ranks then mode.ranks_index = mid(0, bget(0, 4), #ranks - 1) end -- FIX RANK CRASH
    if mode.weapons then
      mode.weapons_index = mid(0, bget(1, 4), #weapons - 1) -- FIX WEAPONS CRASH
      do_swapping()
    end

    for module in all(MODULES) do -- LOAD MODULES
      if module.initialize then
        setfenv(module.initialize, getfenv(1))
        module.initialize()
      end
    end

    for fcard in all(CARDS) do -- FIX ART LIMIT (Thanks Glacies)
      if fcard.real_team == 0 or fcard.real_team == 1 then
        fcard.team = fcard.real_team
      end
    end

    for ach in all(ACHIEVEMENTS) do -- FIX PIECE LIMIT (Thanks Glacies)
      if ach.id == "HOW IT SHOULD BE" or "SHE IS EVERYWHERE" then
        del(ACHIEVEMENTS, ach)
      end
    end

    wait(20, enable_description) -- ENABLE GUN DESCRIPTIONS
  end

  -- GUN DESCRIPTIONS
  function enable_description()
    local function spawn_gun_description()
      local hinty = 67
      if not mode.ranks then hinty = 40 end
      local x = {}
      if weapons[mode.weapons_index + 1].desc then
        x = mk_hint_but(280, hinty - 3, 8, 9, weapons[mode.weapons_index + 1].desc, { 4 }, 100, nil,
          { x = 170, y = hinty + 8 })
        x.button = false
      else
        x = mke()
      end
      x.lastindex = mode.weapons_index
      x.dr = function(self)
        if (not mode.weapons_index) then
          del(ents, self)
          return
        end
        if weapons[mode.weapons_index + 1].desc then
          local printy = -10
          for ent in all(ents) do
            if ent.id == "weapons" then
              printy = ent.y + 1
            end
          end
          lprint("?", 284, printy, 5)
        end
        if (mode.weapons_index ~= self.lastindex) then
          del(ents, self)
          spawn_gun_description()
        end
      end
    end

    local function spawn_rank_description()
      local hinty = 14
      if not mode.weapons then hinty = 45 end
      local x = {}
      if ranks[mode.ranks_index + 1].desc then
        x = mk_hint_but(278, hinty - 3, 8, 9, ranks[mode.ranks_index + 1].desc, { 4 }, 100, nil,
          { x = 170, y = hinty + 8 })
        x.button = false
      else
        x = mke()
      end
      x.lastindex = mode.ranks_index
      x.dr = function(self)
        if (not mode.ranks_index) then
          del(ents, self)
          return
        end
        if ranks[mode.ranks_index + 1].desc then
          local printy = -10
          for ent in all(ents) do
            if ent.id == "ranks" then
              printy = ent.y + 1
            end
          end
          if printy == -10 then
            del(ents, self)
            return
          end
          lprint("?", 280, printy, 5)
        end
        if (mode.ranks_index ~= self.lastindex) then
          del(ents, self)
          spawn_rank_description()
        end
      end
    end

    if mode.weapons then
      spawn_gun_description()
    end

    if mode.ranks then
      spawn_rank_description()
    end
  end

  -- NEEDED FOR GUN DESCRIPTIONS
  function get_weapons_list()
    local a = {}
    for i = 0, #weapons do
      add(a, i)
    end
    return a
  end
end
-- JP_API CODE END

do
  function mod_setup()
    init_listeners()
    add_listener("dr", function()
      lprint(lang.credits, 181, 158, 6)
    end)
  end
end

function start()

  init_vig({ 1, 2, 3 }, function()
    init_game()
    mode.lvl = 0
    mode.turns = 0

    -- MOD SETUP
    mod_setup()

    next_floor()
  end)

end

function next_floor()
  mode.lvl = mode.lvl + 1
  new_level()
end

function grow()
  if mode.lvl < 11 then
    local data = {
      id = "level_up",
      pan_xm = 1,
      pan_ym = 2,
      pan_width = 80,
      pan_height = 96,
      choices = {
        { { team = 0 }, { team = 1 } },
        { { team = 0 }, { team = 1 } },
      },
      force = {
        { lvl = 3, id = "Homecoming", choice_index = 0, card_index = 1, desc_key = "queen_escape" },
        { lvl = 3, id = "Homecoming", choice_index = 1, card_index = 1, desc_key = "queen_everywhere" }
      }
    }
    level_up(data, next_floor)
  elseif mode.lvl == 11 then
    add(upgrades, { gain = { 6 }, sac = { 5 } })
    init_vig({ 4 }, next_floor)
  end
end

function outro()

  local v = { 6, 7 }
  local best = 13
  trig_achievement("COMPLETE")

  if boss.book then
    best = 14
    v = { 8, 6, 11 }
    trig_achievement("AVENGED")
    if chamber > 0 then
      best = 15
      v = { 8, 9, 10, 6, 12 }
      trig_achievement("EXORCISED")
    end
  end

  -- BEST FLOOR
  local rank = mode.ranks_index + 1
  progress(rank, 1, bfl)

  -- BEST RANK
  progress(0, 1, rank)

  -- BEST TIME
  if opt("speedrun") == 1 then
    local best_time = bget(rank, 2)
    if best_time == 0 or chrono_time < best_time then
      bset(rank, 2, chrono_time)
      new_best_time = true
    end
  end
  --
  save()


  -- COLLECTION
  check_collections()


  init_vig(v, init_menu)
end

-- ON
function on_empty()
  end_level(grow)

end

function on_hero_death()
  progress(mode.ranks_index + 1, 1, mode.lvl)
  check_collections()
  save()
  gameover()
end

function on_boss_death()
  -- CHECK BLACK BISHOP SPAWN
  local bishops = get_pieces(2)
  local book = has_card("The Red Book")
  local theo = perm["Theocracy"]
  if book and theo and (#bishops == 1 or (DEV and #bishops >= 1)) then
    bishops[1].chosen = true
    spawn_dark_bishop()
    return
  end

  -- END GAME
  music("ending_A", 0)
  fade_to(-4, 30, outro)

end

function check_unlocks()
end

function save_preferences()
  bset(0, 4, mode.ranks_index)
  bset(1, 4, mode.weapons_index)
  save()
end

--
function draw_inter()
  local s = lang.floor_
  local x = lprint(s, MCW / 2, board_y - 19, 3, 1)
  lprint(mode.lvl, x, board_y - 19, 5)
end