-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

-- Lua Debugger extension for the Lua module.

-- Markdown:
-- ## Key Commands
--
-- + `Ctrl+L, D, S` (`⌘L, D, S` on Mac OSX): Start debugging.
-- + `Ctrl+L, D, Q` (`⌘L, D, Q` on Mac OSX): Stop debugging.
-- + `Ctrl+L, D, C` (`⌘L, D, C` on Mac OSX): Continue.
-- + `Ctrl+L, D, N` (`⌘L, D, N` on Mac OSX): Step over.
-- + `Ctrl+L, D, S` (`⌘L, D, S` on Mac OSX): Step into.
-- + `Ctrl+L, D, O` (`⌘L, D, O` on Mac OSX): Step out.
-- + `Ctrl+L, D, I` (`⌘L, D, I` on Mac OSX): Inspect.
-- + `Ctrl+L, D, L` (`⌘L, D, L` on Mac OSX): Show call stack.
-- + `Ctrl+L, D, B` (`⌘L, D, B` on Mac OSX): Toggle breakpoint.
-- + `Ctrl+L, D, Shift+B` (`⌘L, D, ⇧B` on Mac OSX): Delete breakpoint.
-- + `Ctrl+L, D, W` (`⌘L, D, W` on Mac OSX): Set watch.
-- + `Ctrl+L, D, Shift+W` (`⌘L, D, ⇧W` on Mac OSX): Delete watch.

require 'textadept.debugger'

local debugger = _m.textadept.debugger.new('lua')
_m.lua.debugger = debugger

-- For debugging coroutines within this debugger's coroutines, the current debug
-- hook needs to be propagated so `coroutine.create` and `coroutine.wrap` need
-- to be modified.
local coroutine_create, coroutine_wrap = coroutine.create, coroutine.wrap
function coroutine.create(f)
  local hook, mask, count = debug.gethook()
  if not hook then return coroutine_create(f) end
  local thread
  local function thread_hook(event, line) hook(event, line, thread, 3) end
  thread = coroutine_create(function(...)
    step_level[thread], stack_level[thread] = 0, 0
    debug.sethook(thread_hook, mask, count)
    return f(...)
  end)
  return thread
end
function coroutine.wrap(f)
  local hook, mask, count = debug.gethook()
  if not hook then return coroutine_wrap(f) end
  local function thread_hook(event, line) hook(event, line, thread, 3) end
  thread = coroutine_wrap(function(...)
    step_level[thread], stack_level[thread] = 0, 0
    debug.sethook(thread_hook, mask, count)
    return f(...)
  end)
  return thread
end

-- Get the stack at a given stack level for the debugger.
-- @param level The stack level to get the stack at.
-- @return table stack levels
function debugger.get_stack(level)
  local stack = {}
  while true do
    local info = debug.getinfo(level)
    if not info then break end
    stack[#stack + 1] = info
    level = level + 1
  end
  -- Ignore the last two stack levels which are calls from this debugger.
  stack[#stack], stack[#stack - 1] = nil, nil
  return stack
end

-- Get the environment at a given stack level for the debugger.
-- The returned table is suitable for setting as a function environment.
-- @param level The stack level to get the environment at.
-- @return table of name-value variable pairs. Also contains _LOCALS, _UPVALUES,
--   _GLOBALS, and _ENV tables containing their respective variable types.
function debugger.get_env(level)
  local env = { _LOCALS = {}, _UPVALUES = {}, _GLOBALS = getfenv(0) }
  -- Upvalues.
  local func = debug.getinfo(level, 'f').func
  local i = 1
  while true do
    local name, value = debug.getupvalue(func, i)
    if not name then break end
    if name:sub(1, 1) ~= '(' then
      env[name], env._UPVALUES[name] = value, value
    end
    i = i + 1
  end
  env._ENV = getfenv(func)
  -- Local variables (override upvalues as necessary).
  i = 1
  while true do
    local name, value = debug.getlocal(level, i)
    if not name then break end
    if name:sub(1, 1) ~= '(' then
      env[name], env._LOCALS[name] = value, value
    end
    i = i + 1
  end
  setmetatable(env, { __index = env._ENV, __newindex = env._ENV })
  return env
end

-- Hook called by the Lua debug library used for debugging.
-- @param event The event, either 'call', 'return', 'tail return', 'line', or
--   'count'.
-- @param line The line number.
-- @param thread The currently running thread. This is non-nil when a coroutine
--   is being run from within the debug coroutine.
-- @param level The level of the currently running thread. This is non-nil when
--   a coroutine is being run from within the debug coroutine.
function debugger.debug_hook(event, line, thread, level)
  if not debugger.debugging then return end
  debugger.current_thread = thread or 'main'
  level = level or 2
  local step_level, stack_level = debugger.step_level, debugger.stack_level
  local current_thread = debugger.current_thread
  if event == 'call' then
    stack_level[current_thread] = stack_level[current_thread] + 1
  elseif event == 'return' then
    stack_level[current_thread] = stack_level[current_thread] - 1
    if stack_level[current_thread] < 0 then stack_level[current_thread] = 0 end
    if stack_level['main'] == 1 then debugger:stop() end -- finished xpcall()
  else
    -- Get the filename.
    local file = debug.getinfo(level, 'S').source:match('^@?(.+)$')
    if file:find('modules[/\\]lua[/\\]debugger%.lua$') then return end
    -- Get the stack trace.
    local stack = debugger.get_stack(level + 1)
    -- Get the current environment.
    local env = debugger.get_env(level + 1)
    -- Check watches.
    local watch_id
    for i = 1, #debugger.watches do
      local f = debugger.watches[debugger.watches[i]]
      if type(f) == 'function' then
        local ok, result = pcall(setfenv(f, env))
        if ok and result then watch_id = i break end
      end
    end
    -- If at a breakpoint or watch, stepping into, or stepping over, resume the
    -- debugger coroutine to get the next instruction.
    if debugger.breakpoints[file] and debugger.breakpoints[file][line] or
       watch_id or debugger.stepping_into or debugger.stepping_over and
       (stack_level[current_thread] <= step_level[current_thread] or
        stack_level[current_thread] == 0) then
      local command = coroutine.yield {
        file = file, line = line, stack = stack, env = env, watch_id = watch_id
      }
      repeat
        local continue = true
        if not command then
          debugger:stop()
        elseif command == 'continue' then
          debugger.stepping_into, debugger.stepping_over = false, false
        elseif command == 'step_into' then
          debugger.stepping_into, debugger.stepping_over = true, false
        elseif command == 'step_over' then
          debugger.stepping_into, debugger.stepping_over = false, true
          step_level[current_thread] = stack_level[current_thread]
        elseif command == 'step_out' then
          debugger.stepping_into, debugger.stepping_over = false, true
          step_level[current_thread] = stack_level[current_thread] - 1
        elseif command:find('^set_stack') then
          local i = tonumber(command:match('^set_stack (%d+)'))
          local info = debug.getinfo(level + i, 'Sl')
          if info.what ~= 'C' then
            command = coroutine.yield {
              file = info.source:match('^@?(.+)$'), line = info.currentline,
              stack = stack, stack_pos = i,
              env = debugger.get_env(level + i + 1)
            }
          else
            command = coroutine.yield { C = true }
          end
          continue = false
        end
      until continue
    end
  end
end

-- Environment for debug scripts.
-- @class table
-- @name ENV
local ENV = {
  'assert', 'collectgarbage', 'dofile', 'error', 'getfenv', 'getmetatable',
  'ipairs', 'load', 'loadfile', 'loadstring', 'next', 'pairs', 'pcall', 'print',
  'rawequal', 'rawget', 'rawset', 'select', 'setfenv', 'setmetatable',
  'tonumber', 'tostring', 'type', 'unpack', 'xpcall', 'coroutine', 'module',
  'require', 'table', 'math', 'os', 'debug', 'lpeg', 'lfs',
  '_VERSION',
  -- Some functions and fields in the following libraries need to be excluded
  -- either because they belong to Textadept or they are data references that
  -- Textadept's state shares and could cause problems if modified.
  string = {
    'byte', 'char', 'dump', 'find', 'format', 'gmatch', 'gsub', 'len', 'lower',
    'match', 'rep', 'reverse', 'sub', 'upper'
  },
  io = {
    'close', 'flush', 'lines', 'open', 'popen', 'read', 'tmpfile', 'write',
    'type'
  },
  package = { 'cpath', 'loaders', 'loadlib', 'path', 'seeall' }
}
-- Creates the environment for debug scripts.
-- @see ENV
local function create_env()
  local env = {}
  -- Create the env from ENV.
  for k, v in pairs(ENV) do
    if type(k) == 'number' then
      env[v] = _G[v]
    else
      env[k] = {}
      for k2, v2 in ipairs(v) do env[k][v2] = _G[k][v2] end
    end
  end
  -- Create new references that do not interfere with Textadepts'.
  env._G, env.package.loaded, env.package.preload = env, {}, {}
  -- Modify input/output functions to interface with Textadept.
  env.print = function(...)
    debugger.debugging = false -- do not debug the following function calls
    local prev_view = #_VIEWS == 1 and 1 or _VIEWS[view]
    gui.print(...)
    gui.goto_view(prev_view)
    debugger.debugging = true -- resume debugging normally
  end
  env.io.stdin = { read = function(_, ...)
    local input = gui.dialog('inputbox', '--title', 'stdin', '--width', 400)
    return input:match('([^\n]+)\n$')
  end }
  env.io.stdout = { write = function(_, ...) env.print(...) end }
  env.io.stderr = { write = function(_, ...) env.print('STDERR:', ...) end }
  env.io.input = function(f)
    if not f then return env.io.stdin end
    env.io.stdin = f
  end
  env.io.output = function(f)
    if not f then return env.io.stdout end
    env.io.stdout = f
  end
  env.io.read = function(...) return env.io.input():read(...) end
  env.io.write = function(...) return env.io.output():write(...) end
  return env
end

-- Implementation for debugger:start().
-- @param filename The file to debug. Defaults to buffer.filename.
function debugger:handle_start(filename)
  if not filename then filename = buffer.filename end
  local f, err = loadfile(filename)
  if not f then error(err) end
  self.co = coroutine_create(function(f)
    self.current_thread = 'main'
    self.stepping_into, self.stepping_over = false, false
    self.step_level = { [self.current_thread] = 0 }
    self.stack_level = { [self.current_thread] = 1 }
    coroutine.yield()
    setfenv(f, create_env())
    debug.sethook(self.debug_hook, 'clr')
    xpcall(f, function(err)
      local info = debug.getinfo(2, 'Sl')
      -- If the error occurs in C (e.g. via Lua's 'error' function), go up the
      -- stack to where the error in Lua occurred.
      if info.what == 'C' then info = debug.getinfo(3, 'Sl') end
      local file, line = info.source:match('^@?(.+)$'), info.currentline
      local stack, env = self.get_stack(3), self.get_env(3)
      coroutine.yield {
        file = file, line = line, stack = stack, env = env, error = err
      }
    end)
    self:stop()
  end)
  coroutine.resume(self.co, f)
end

-- Implementation for debugger:stop().
function debugger:handle_stop()
  debug.sethook()
  coroutine.resume(self.co, false)
end

-- Performs a debugger action.
-- @param action The action to perform: 'continue', 'step_into', 'step_over', or
--   'step_out'.
local function handle(debugger, action)
  local ok, state = coroutine.resume(debugger.co, action)
  debugger:update_state(state)
end

-- Implementation for debugger:continue().
function debugger:handle_continue() handle(self, 'continue') end

-- Implementation for debugger:step_into().
function debugger:handle_step_into() handle(self, 'step_into') end

-- Implementation for debugger:step_over().
function debugger:handle_step_over() handle(self, 'step_over') end

-- Implementation for debugger:step_out().
function debugger:handle_step_out() handle(self, 'step_out') end

-- Implementation for debugger:set_watch().
-- Loads the given expression as a Lua chunk so it can be evaluated by the debug
-- hook.
function debugger:handle_set_watch(expr)
  local f, err = loadstring('return ('..expr..')')
  if not f then error(err) end
  self.watches[expr] = f
  return true
end

-- Implementation for debugger:delete_watch().
function debugger:handle_delete_watch(expr) self.watches[expr] = nil end

-- Implementation for debugger:get_call_stack().
function debugger:get_call_stack()
  if not self.state then return end
  local stack = self.state.stack
  local t = {}
  for _, info in ipairs(stack) do
    t[#t + 1] = ('(%s) %s:%d'):format(info.name or info.what, info.short_src,
                                      info.currentline)
  end
  return t, self.state.stack_pos
end

-- Implementation for debugger:set_stack().
function debugger:set_stack(level)
  local ok, state = coroutine.resume(debugger.co, 'set_stack '..level)
  if not state.C then self:update_state(state) end
end

-- Lua reserved words.
-- Used when displaying table keys in table_tostring().
-- @class table
-- @name reserved
local reserved = {
  ['and'] = 1, ['break'] = 1, ['do'] = 1, ['else'] = 1, ['elseif'] = 1,
  ['end'] = 1, ['false'] = 1, ['for'] = 1, ['function'] = 1, ['if'] = 1,
  ['in'] = 1, ['local'] = 1, ['nil'] = 1, ['not'] = 1, ['or'] = 1,
  ['repeat'] = 1, ['return'] = 1, ['then'] = 1, ['true'] = 1, ['until'] = 1,
  ['while'] = 1
}

local truncate_len = 25
-- Prints a value to a string as it might look in Lua syntax.
-- @param value The value to print.
-- @param truncate Flag indicating whether or not to truncate long strings.
-- @param level The table level (non-zero for tables inside tables).
-- @param visited Table of visited tables so recursion does not happen.
local function tostringi(value, truncate, level, visited)
  local truncate_len = truncate and truncate_len or math.huge
  if type(value) == 'string' then
    local v = ('%q'):format(value)
    if #v > truncate_len then v = v:sub(1, truncate_len)..' ..."' end
    return v
  elseif type(value) == 'table' then
    if not visited then visited = {} end
    local indent = (' '):rep(2 * (level or 0))
    local s = { '{ -- '..tostring(value) }
    for k, v in pairs(value) do
      if type(k) == 'string' then
        if #k > truncate_len then k = k:sub(1, truncate_len)..' ...' end
        if not k:find('^[%w_]+$') or reserved[k] then k = ('[%q]'):format(k) end
      else
        k = '['..tostring(k)..']'
      end
      if type(v) == 'string' then
        v = ('%q'):format(v)
        if #v > truncate_len then v = v:sub(1, truncate_len)..' ..."' end
      elseif type(v) == 'table' and not visited[v] then
        visited[v] = true
        v = tostringi(v, truncate, (level or 0) + 1, visited)
      else
        v = tostring(v)
      end
      s[#s + 1] = ('%s  %s = %s,'):format(indent, k, v)
    end
    s[#s + 1] = ('%s}'):format(indent)
    return table.concat(s, '\n')
  else
    return tostring(value)
  end
end

-- Implementation for debugger:inspect().
-- If a table value contains more than 20 lines, it is truncated.
function debugger:handle_inspect(symbol, pos)
  if self.state and self.state.env then
    local f = loadstring('return '..symbol)
    local ok, value = pcall(setfenv(f, self.state.env))
    if not ok then return end
    value = tostringi(value, true)
    local lines, s = 1, value:find('\n')
    while s and lines < 20 do
      lines = lines + 1
      s = value:find('\n', s + 1)
    end
    if lines >= 20 then value = value:sub(1, s)..'...' end
    buffer:call_tip_show(pos, symbol..' = '..value)
  end
end

-- Implementation for debugger:command().
-- Handle commands from the command entry during a debug session.
function debugger:handle_command(text)
  if not self.state or not self.state.env then return end
  gui.command_entry.focus() -- hide
  gui.print(text)
  if text:find('^%s*=') then
    local f, err = loadstring('return '..text:match('^%s*=(.+)$'))
    if not f then error(err) end
    local values = { setfenv(f, self.state.env)() }
    local n = select('#', unpack(values))
    for i = 1, n do values[i] = tostringi(values[i]) end
    gui.print(table.concat(values, '\t'))
  else
    local f, err = loadstring(text)
    if not f then error(err) end
    setfenv(f, self.state.env)()
  end
  return true
end

-- Adeptsense.
_m.lua.sense.syntax.type_assignments['^(_m%.textadept%.debugger)%.new'] = '%1'

-- Key commands.
keys.lua[keys.LANGUAGE_MODULE_PREFIX].d = {
  d = debugger.start,
  q = debugger.stop,
  c = debugger.continue,
  n = debugger.step_over,
  s = debugger.step_into,
  o = debugger.step_out,
  i = debugger.inspect,
  l = debugger.call_stack,
  b = debugger.toggle_breakpoint,
  B = debugger.delete_breakpoint,
  w = debugger.set_watch,
  W = debugger.delete_watch
}

-- Context menu.
local L = locale.localize
local SEPARATOR = { 'separator' }
_m.lua.context_menu = {
  { L('gtk-undo'), buffer.undo },
  { L('gtk-redo'), buffer.redo },
  SEPARATOR,
  { L('gtk-cut'), buffer.cut },
  { L('gtk-copy'), buffer.copy },
  { L('gtk-paste'), buffer.paste },
  { L('gtk-delete'), buffer.clear },
  SEPARATOR,
  { L('gtk-select-all'), buffer.select_all },
  SEPARATOR,
  { title = 'De_bug',
    { 'Start _Debugging', debugger.start },
    { 'Sto_p Debugging', debugger.stop },
    SEPARATOR,
    { 'Debug _Continue', debugger.continue },
    { 'Debug Step _Over', debugger.step_over },
    { 'Debug Step _Into', debugger.step_into },
    { 'Debug Step Ou_t', debugger.step_out },
    SEPARATOR,
    { 'Debug I_nspect', debugger.inspect },
    { 'Debug Call Stac_k...', debugger.call_stack },
    SEPARATOR,
    { 'Toggle _Breakpoint', debugger.toggle_breakpoint },
    { '_Delete Breakpoint...', debugger.delete_breakpoint },
    { 'Set _Watch Expression', debugger.set_watch },
    { 'D_elete Watch Expression...', debugger.delete_watch },
  }
}
