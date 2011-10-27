-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize
local events = events

---
-- Language debugging support for the textadept module.
module('_m.textadept.debugger', package.seeall)

-- Markdown:
-- ## Overview
--
-- The debugger interface allows Textadept to communicate with a debugger for
-- stepping through code graphically. It supports many common actions such as
-- setting breakpoints and watch expressions, continuing, and stepping into,
-- over, and out of functions. More actions can be added for specific debugger
-- instances. This document provides the information necessary in order to
-- implement a new debugger for a language. For illustrative purposes, a
-- debugger for C/C++ that uses the GNU Debugger (gdb) will be created.
--
-- ## Implementing a Debugger
--
-- Debugger instances exist per-languge and are typically defined in a
-- [language-specific module](../manual/7_Modules.html#language_specific).
-- First check to see if the module for your language has a debugger. If not,
-- you will need to implement one. The language modules included with Textadept
-- have debuggers so they can be used for reference. If your language uses a
-- debugger like gdb, you can copy and modify C/C++'s debugger, saving some time
-- and effort.
--
-- #### Introduction
--
-- Open the languge-specific module for editing and create a new instance of a
-- debugger.
--
--     $> # from either _HOME or _USERHOME:
--     $> cd modules/cpp/
--     $> textadept init.lua
--
--     debugger = _m.textadept.debugger.new('cpp')
--
-- Where 'cpp' is replaced by your language's name.
--
-- #### Syntax Options
--
-- The syntax of different languages varies so the debugger must be configured
-- for your language in order to function properly.
--
-- ##### symbol_chars
--
-- In addition to the usual `[%w_%.]` symbol characters, C/C++ also allows
-- symbols to contain `->`.
--
--     debugger.symbol_chars = '[%w_%.%->]'
--
-- #### Debugger Functions
--
-- The debugger interface provides the framework for a debugger, but the
-- instance-specific functions still have to be defined.
--
-- ##### handle_start
--
-- ##### handle_set_breakpoint
--
-- ##### handle_delete_breakpoint
--
-- ##### handle_set_watch
--
-- ##### handle_delete_watch
--
-- ##### handle_stop
--
-- ##### handle_continue
--
-- ##### handle_step_into
--
-- ##### handle_step_over
--
-- ##### handle_step_out
--
-- ##### handle_inspect
--
-- ##### handle_command
--
-- ##### Other Functions
--
-- It is your responsibility to handle any errors that occur and stop the
-- debugger (`debugger:stop()`) if necessary to avoid unexpected behavior.
--
-- #### Summary
--
-- The above method of setting syntax options and defining debugger functions is
-- sufficient for most language debuggers. The rest of this document is devoted
-- to more complex techniques.
--
-- ## Settings
--
-- * `MARK_BREAKPOINT_COLOR` [number]: The color used for a breakpoint line in
--   `0xBBGGRR` format.
-- * `MARK_BREAKPOINT_ALPHA` [number]: The alpha used for a breakpoint line. The
--   default is `128`.
-- * `MARK_DEBUGLINE_COLOR` [number]: The color used for the current debug line
--   in `0xBBGGRR` format.
-- * `MARK_DEBUGLINE_ALPHA` [number]: The alpha used for the current debug line.
--   The default is `128`.

-- Settings.
MARK_BREAKPOINT_COLOR = 0x6D6DD9
MARK_BREAKPOINT_ALPHA = 128
MARK_DEBUGLINE_COLOR = 0x6DD96D
MARK_DEBUGLINE_ALPHA = 128
-- End settings.

local debuggers = {}

local MARK_BREAKPOINT = _SCINTILLA.next_marker_number()
local MARK_DEBUGLINE = _SCINTILLA.next_marker_number()

-- Gets the debugger for the current language, if any.
-- This is necessary for menu items and key commands assigned to generic
-- debugger functions without regard to the current language.
-- @return debugger or `nil`
local function get_debugger()
  local m = _m[buffer:get_lexer()]
  return m and m.debugger
end

---
-- Sets a breakpoint on the given line of the current file.
-- The debugger will break when that point in execution is reached.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param file The file to set the breakpoint in. Defaults to the current file.
-- @param line The line number to break on. Line numbers start at 1.
function set_breakpoint(debugger, file, line)
  debugger = debugger or get_debugger()
  if not debugger or not line then return end
  if not file then file = buffer.filename end
  if debugger.debugging then
    if not debugger:handle_set_breakpoint(file, line) then return end
  end
  if not debugger.breakpoints[file] then debugger.breakpoints[file] = {} end
  debugger.breakpoints[file][line] = true
  if file == buffer.filename then
    buffer:marker_add(line - 1, MARK_BREAKPOINT)
  end
end

---
-- Called to add a breakpoint to the debugger.
-- This method should be replaced with your own that is specific to the debugger
-- instance. You do not have to modify the `debugger.breakpoints` table; you
-- only have to add the breakpoint to the debugger instance.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param file The file to add the breakpoint to.
-- @param line The line number to add the breakpoint at. Line numbers start at
--   1.
-- @return `true` if successful; `false` otherwise
function handle_set_breakpoint(debugger, file, line) return true end

-- Returns a sorted list of breakpoints for a filtered list.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param file Optional file to list breakpoints from. Otherwise lists all
--   breakpoints in all files.
local function get_breakpoints(debugger, file)
  local breakpoints = {}
  if not file then
    for file, file_breakpoints in pairs(debugger.breakpoints) do
      for line, breakpoint in pairs(file_breakpoints) do
        if breakpoint then breakpoints[#breakpoints + 1] = file..':'..line end
      end
    end
  else
    for line, breakpoint in pairs(debugger.breakpoints[file] or {}) do
      if breakpoint then breakpoints[#breakpoints + 1] = file..':'..line end
    end
  end
  table.sort(breakpoints)
  return breakpoints
end

---
-- Deletes a breakpoint on the given line of the current file.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param file The file to delete the breakpoint from. Defaults to the current
--   file.
-- @param line The line number to break on. Line numbers start at 1.
function delete_breakpoint(debugger, file, line)
  debugger = debugger or get_debugger()
  if not debugger then return end
  if not file or not line then
    local result = gui.filteredlist('Delete Breakpoint', 'Breakpoint:',
                                    get_breakpoints(debugger, file), false,
                                    '--select-multiple')
    if not result then return end
    for breakpoint in result:gmatch('[^\n]+') do
      file, line = breakpoint:match('^(.+):(%d+)$')
      line = tonumber(line)
      debugger:delete_breakpoint(file, line)
    end
    return
  end
  if debugger.breakpoints[file] then
    if debugger.debugging then debugger:handle_delete_breakpoint() end
    debugger.breakpoints[file][line] = nil
  end
  if file == buffer.filename then
    buffer:marker_delete(line - 1, MARK_BREAKPOINT)
  end
end

---
-- Toggles a breakpoint on the given line of the current file.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param file The file to toggle the breakpoint in. Defaults to the current
--   file.
-- @param line The line number to toggle the break on. Defaults to the current
--   line. Line numbers start at 1.
function toggle_breakpoint(debugger, file, line)
  debugger = debugger or get_debugger()
  if not debugger then return end
  if not file then file = buffer.filename end
  if not line then line = buffer:line_from_position(buffer.current_pos) + 1 end
  if debugger.breakpoints[file] and debugger.breakpoints[file][line] then
    delete_breakpoint(debugger, file, line)
  else
    set_breakpoint(debugger, file, line)
  end
end

---
-- Called to delete a breakpoint from the debugger.
-- This method should be replaced with your own that is specific to the debugger
-- instance. You do not have to modify the `debugger.breakpoints` table; you
-- only have to remove the breakpoint from the debugger instance.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param file The file to delete the breakpoint from.
-- @param line The line number to delete the breakpoint at. Line numbers start
--   at 1.
function handle_delete_breakpoint(debugger, file, line) end

---
-- Sets a watch expression.
-- The debugger will break when the expression evaluates to `true`.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param expr The expression to watch. If `nil`, prompts the user for one.
-- @return watch expression ID number
function set_watch(debugger, expr)
  debugger = debugger or get_debugger()
  if not debugger then return end
  if not expr then
    local out = gui.dialog('standard-inputbox',
                           '--title', 'Set Watch',
                           '--text', 'Expression:',
                           '--no-newline')
    local response, value = out:match('^([^\n]+)\n(.-)$')
    if response ~= '1' or value == '' then return end
    expr = value
  end
  if debugger.debugging and not debugger:handle_set_watch(expr) then return end
  debugger.watches[#debugger.watches + 1] = expr
  debugger.watches[expr] = #debugger.watches
  return #debugger.watches
end

---
-- Called to add a watch expression to the debugger.
-- This method should be replaced with your own that is specific to the debugger
-- instance. You do not have to modify the `debugger.watches` table; you only
-- have to add the watch to the debugger instance.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param expr The expression to watch.
-- @return `true` if successful; `false` otherwise
function handle_set_watch(debugger, expr) return true end

---
-- Deletes a watch expression.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param i The ID number of the watch expression. If `nil`, prompts the user
--   for one.
function delete_watch(debugger, i)
  debugger = debugger or get_debugger()
  if not debugger then return end
  if not i then
    local w = {}
    for i, watch in ipairs(debugger.watches) do w[i] = watch end
    i = gui.filteredlist('Delete Watch', 'Expression:', w, true)
    if not i then return end
    i = i + 1
  end
  if debugger.watches[i] then
    if debugger.debugging then debugger:handle_delete_watch(i) end
    debugger.watches[debugger.watches[i]] = nil
    table.remove(debugger.watches, i)
  end
end

---
-- Called to delete a watch from the debugger.
-- This method should be replaced with your own that is specific to the debugger
-- instance. You do not have to modify the `debugger.watches` table; you only
-- have to remove the watch from the debugger instance.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param i The ID number of the watch expression.
function handle_delete_watch(debugger, i) end

---
-- Start the debugger.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `handle_start()`.
-- @see handle_start
function start(debugger, ...)
  debugger = debugger or get_debugger()
  if not debugger or debugger.debugging then return end
  debugger.debugging = true
  local ok, err = pcall(debugger.handle_start, debugger, ...)
  if not ok then
    debugger:stop()
    error(err)
  end
  -- Load breakpoints and watches.
  for file, breakpoints in pairs(debugger.breakpoints) do
    if type(breakpoints) == 'table' then
      for line, breakpoint in pairs(breakpoints) do
        if breakpoint then debugger:handle_set_breakpoint(file, line) end
      end
    end
  end
  for _, expr in ipairs(debugger.watches) do debugger:handle_set_watch(expr) end
  debugger:continue() -- start executing immediately
end

---
-- Called when starting the debugger.
-- This method should be replaced with your own that is specific to the debugger
-- instance. `debugger:stop()` is called automatically if an error occurs.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `start()`.
function handle_start(debugger, ...) end

---
-- Stop the debugger.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `handle_stop()`.
-- @see handle_stop
function stop(debugger, ...)
  debugger = debugger or get_debugger()
  if not debugger or not debugger.debugging then return end
  debugger.debugging = false
  pcall(debugger.handle_stop, debugger, ...)
  buffer:marker_delete_all(MARK_DEBUGLINE)
  if debugger.state and debugger.state.error then
    buffer:annotation_clear_all()
  end
  debugger.state = nil
end

---
-- Called when stopping the debugger.
-- This method should be replaced with your own that is specific to the debugger
-- instance.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `stop()`.
function handle_stop(debugger, ...) end

-- Perform a debugger function.
-- If an error occurs, the debugger is stopped.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param f The string function name.
-- @param ... Any additional parameters to pass to the function.
local function perform(debugger, f, ...)
  debugger = debugger or get_debugger()
  if not debugger or not debugger.debugging then return end
  local ok, err = pcall(debugger[f], debugger, ...)
  if not ok then
    debugger:stop()
    error(err)
  end
end

---
-- Continue debugger execution until the next breakpoint.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `handle_continue()`.
-- @see handle_continue
function continue(debugger, ...) perform(debugger, 'handle_continue', ...) end

---
-- Called when continuing execution until the next breakpoint.
-- This method should be replaced with your own that is specific to the debugger
-- instance. `debugger:stop()` is called automatically if an error occurs.
-- Call `debugger:update_state()` after handling the continue.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `continue()`.
-- @see update_state
function handle_continue(debugger, ...) end

---
-- Continue debugger execution by one line, stepping into functions.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `handle_step_into()`.
-- @see handle_step_into
function step_into(debugger, ...) perform(debugger, 'handle_step_into', ...) end

---
-- Called when continuing execution by one line, stepping into functions.
-- This method should be replaced with your own that is specific to the debugger
-- instance. `debugger:stop()` is called automatically if an error occurs.
-- Call `debugger:update_state()` after handling the step into.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `step_into()`.
-- @see update_state
function handle_step_into(debugger, ...) end

---
-- Continue debugger execution by one line, stepping over functions.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `handle_step_over()`.
-- @see handle_step_over
function step_over(debugger, ...) perform(debugger, 'handle_step_over', ...) end

---
-- Called when continuing execution by one line, stepping over functions.
-- This method should be replaced with your own that is specific to the debugger
-- instance. `debugger:stop()` is called automatically if an error occurs.
-- Call `debugger:update_state()` after handling the step over.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `step_over()`.
-- @see update_state
function handle_step_over(debugger, ...) end

---
-- Continue debugger execution, stepping out of the current function.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `handle_step_out()`.
-- @see handle_step_out
function step_out(debugger, ...) perform(debugger, 'handle_step_out', ...) end

---
-- Called when continuing execution, stepping out of the current function.
-- This method should be replaced with your own that is specific to the debugger
-- instance. `debugger:stop()` is called automatically if an error occurs.
-- Call `debugger:update_state()` after handling the step out.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `step_out()1.
-- @see update_state
function handle_step_out(debugger, ...) end

---
-- Updates the debugger's state and marks the current debug line.
-- This method should be called whenever the debugger's state has changed,
-- typically in the set of `handle_*` functions.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param state A table with at least two fields: `file` and `line`, indicating
-- the debugger's current position. It will be assigned to the `debugger.state`
-- field and may also contain other information useful to the debugger
-- implementation. If an `error` field is present, the error message is shown in
-- an annotation. If state is `nil` or not a table, `debugger:stop()` is called.
-- @see state
function update_state(debugger, state)
  debugger.state = state
  if type(state) ~= 'table' then
    debugger:stop()
    if state then error(state) end
    return
  end
  buffer:marker_delete_all(MARK_DEBUGLINE)
  local file = state.file:iconv('UTF-8', _CHARSET)
  if state.file ~= buffer.filename then io.open_file(file) end
  buffer:marker_add(state.line - 1, MARK_DEBUGLINE)
  buffer:goto_line(state.line - 1)
  if state.error then
    buffer:annotation_set_text(state.line - 1, state.error)
    buffer.annotation_style[state.line - 1] = 8 -- error style number
  end
end

---
-- Show the current call stack in a dropdown box in order to move between
-- frames.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param ... Any additional parameters passed to `get_call_stack()`.
-- @see get_call_stack
-- @see set_stack
function call_stack(debugger, ...)
  debugger = debugger or get_debugger()
  if not debugger or not debugger.debugging then return end
  local stack, pos = debugger:get_call_stack(...)
  local out = gui.dialog('standard-dropdown',
                         '--title', 'Call Stack',
                         '--items', stack,
                         '--selected', pos or 0)
  local response, level = out:match('^(%d+)\n(%d+)')
  if response == '1' then debugger:set_stack(tonumber(level)) end
end

---
-- Called when showing the current call stack.
-- This method should be replaced with your own that is specific to the debugger
-- instance. It is your responsibility to handle any errors that occur and stop
-- the debugger if necessary to avoid unexpected behavior.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param ... Any additional parameters passed from `call_stack()`.
-- @return a table of string stack positions and a number indicating the current
--   stack position. The number defaults to `0`, the first table value.
function get_call_stack(debugger, ...) end

---
-- Called when changing stack frames.
-- This method should be replaced with your own that is specific to the debugger
-- instance. It is your responsibility to handle any errors that occur and stop
-- the debugger if necessary to avoid unexpected behavior.
-- Call `debugger:update_state()` after changing stack frames.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param level The level of the stack frame to change to.
function set_stack(debugger, level) end

---
-- Inspects a symbol at the given position.
-- Symbols can have any character in the `debugger.symbol_chars` pattern and
-- must have a style defined in the `debugger.inspect_styles` table.
-- @param debugger The debugger returned by `debugger.new()`. Defaults to the
--   debugger for the current language.
-- @param pos The buffer position to inspect at.
-- @see handle_inspect
function inspect(debugger, pos)
  local buffer = buffer
  debugger = debugger or get_debugger()
  if not pos then pos = buffer.current_pos end
  if debugger and debugger.debugging and pos > 0 and
     debugger.inspect_styles[buffer:get_style_name(buffer.style_at[pos])] then
    local s = buffer:position_from_line(buffer:line_from_position(pos))
    local e = buffer:word_end_position(pos, true)
    local line = buffer:text_range(s, e)
    debugger:handle_inspect(line:match(debugger.symbol_chars..'+$'), pos)
  end
end

---
-- Called when inspecting a symbol during a debug session.
-- This method should be replaced with your own that is specific to the debugger
-- instance. Usually a call tip is displayed with the symbol's value.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param symbol The symbol being inspected.
-- @param position The buffer position at inspection. This is useful for
--   displaying a call tip.
-- @see buffer.call_tip_show
function handle_inspect(debugger, symbol, position) end

---
-- Called when a command in the command entry is entered during a debug session.
-- This method should be replaced with your own that is specific to the debugger
-- instance. It is your responsibility to handle any errors that occur and stop
-- the debugger if necessary to avoid unexpected behavior.
-- If you want, call `gui.command_entry.focus()` to hide the command entry while
-- it still has focus.
-- @param debugger The debugger returned by `debugger.new()`.
-- @param text The command text.
-- @return `true` if the command was consumed
function handle_command(debugger, text) end

---
-- Creates a new debugger for the given lexer language.
-- Only one debugger can exist per language.
-- @param lang The lexer language to create a debugger for.
-- @return debugger
-- @usage local debugger = _m.textadept.debugger.new('lua')
function new(lang)
  local debugger = debuggers[lang]
  if debugger then
    if debugger.debugging then error('Debugger running') end
    debugger.breakpoints = nil
    debugger.watches = nil
  end

  debugger = setmetatable({
    lexer = lang,
    debugging = false,
    symbol_chars = '[%w_%.]',

---
-- The set of breakpoints for the debugger.
-- Each key is a filename that contains a table of line numbers with boolean
-- values indicating whether or not breakpoints are set on those lines. When
-- the debugger reaches a line that has a breakpoint, it breaks.
-- @class table
-- @name breakpoints
breakpoints = {},

---
-- The set of watches for the debugger.
-- This table contains a list of watch expressions and also watch expression
-- keys with values indicating the index of that expression in the table.
-- @class table
-- @name watches
watches = {},

---
-- The current state of the debugger.
-- It is guaranteed to contain `file` and `line` fields, but can also contain
-- other fields useful to the debugger implementation.
-- @class table
-- @name state
-- @field file The file (encoded in _CHARSET, not UTF-8) the debugger is in.
-- @field line The line the debugger is on.
-- @field error If an error occured in the program being debugged, this is an
--   error message that will be displayed as an annotation.
-- @see update_state
state = {},

---
-- The styles a symbol can have in order to determine and show the symbol's
-- value during a debug session.
-- Each key is a style name with a boolean value indicating whether or not the
-- style can contain a symbol. The default contains the `identifier` style.
-- @field identifier Identifiers contain symbols.
inspect_styles = { identifier = true },

    super = setmetatable({}, { __index = _M })
  }, { __index = _M })

  debuggers[lang] = debugger
  return debugger
end

-- Sets view properties for debug markers.
local function set_marker_properties()
  local buffer = buffer
  buffer:marker_set_back(MARK_BREAKPOINT, MARK_BREAKPOINT_COLOR)
  buffer:marker_set_alpha(MARK_BREAKPOINT, MARK_BREAKPOINT_ALPHA)
  buffer:marker_set_back(MARK_DEBUGLINE, MARK_DEBUGLINE_COLOR)
  buffer:marker_set_alpha(MARK_DEBUGLINE, MARK_DEBUGLINE_ALPHA)
end
if buffer then set_marker_properties() end
events.connect(events.VIEW_NEW, set_marker_properties)

-- Set breakpoint on margin-click.
events.connect(events.MARGIN_CLICK, function(margin, position, modifiers)
  if margin == 1 and modifiers == 0 then
    toggle_breakpoint(nil, nil, buffer:line_from_position(position) + 1)
  end
end)

-- Update breakpoints after switching buffers.
events.connect(events.BUFFER_AFTER_SWITCH, function()
  local debugger = get_debugger()
  if not debugger then return end
  local file = buffer.filename
  if not debugger.breakpoints[file] then return end
  local buffer = buffer
  -- Delete markers for breakpoints that have been removed.
  local line = buffer:marker_next(0, 2^MARK_BREAKPOINT)
  while line >= 0 do
    if not debugger.breakpoints[file][line + 1] then
      buffer:marker_delete(line, MARK_BREAKPOINT)
    end
    line = buffer:marker_next(line + 1, 2^MARK_BREAKPOINT)
  end
  -- Add markers for breakpoints that have been added.
  for line, v in pairs(debugger.breakpoints[file]) do
    if v and buffer:marker_next(line - 1, 2^MARK_BREAKPOINT) ~= line - 1 then
      buffer:marker_add(line - 1, MARK_BREAKPOINT)
    end
  end
end)

-- Inspect symbols and show call tips during mouse dwell events.
events.connect(events.DWELL_START, function(pos) inspect(nil, pos) end)
events.connect(events.DWELL_END, buffer.call_tip_cancel)

-- Handle command entry commands.
events.connect(events.COMMAND_ENTRY_COMMAND, function(text)
  local debugger = get_debugger()
  if debugger and debugger.debugging and debugger:handle_command(text) then
    return true
  end
end, 1) -- place before command_entry.lua's handler (if necessary)
