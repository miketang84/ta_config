--require 'textadept'
require 'textadept.adeptsense'
require 'textadept.bookmarks'
require 'textadept.command_entry'
require 'textadept.editing'
require 'textadept.find'
require 'textadept.filter_through'
require 'textadept.mime_types'
require 'textadept.run'
require 'textadept.session'
require 'textadept.snapopen'
require 'textadept.snippets'
-- These need to be loaded last.
require 'textadept.keys'


require 'textadept.file_browser'
require 'hypertext.commands'
-- require 'lua.debugger'

_m.textadept.editing.AUTOPAIR = false
_m.textadept.editing.STRIP_WHITESPACE_ON_SAVE = false

function goto_nearest_occurrence(reverse)
	local buffer = buffer
	local s, e = buffer.selection_start, buffer.selection_end
	if s == e then
			s, e = buffer:word_start_position(s), buffer:word_end_position(s)
	end
	local word = buffer:text_range(s, e)
	if word == '' then return end
	buffer.search_flags = _SCINTILLA.constants.SCFIND_WHOLEWORD
			+ _SCINTILLA.constants.SCFIND_MATCHCASE
	if reverse then
		buffer.target_start = s - 1
		buffer.target_end = 0
	else
		buffer.target_start = e + 1
		buffer.target_end = buffer.length
	end
	if buffer:search_in_target(word) == -1 then
		if reverse then
			buffer.target_start = buffer.length
			buffer.target_end = e + 1
		else
			buffer.target_start = 0
			buffer.target_end = s - 1
		end
		if buffer:search_in_target(word) == -1 then return end
	end
	buffer:set_sel(buffer.target_start, buffer.target_end)
end



--function openTerminalHere()
--        terminalString = "gnome-terminal"
--        pathString = "~"
--        if buffer.filename then
--                pathString = buffer.filename:match(".+/") or '~'
--        end
--        io.popen(terminalString.." --working-directory="..pathString.." &")
--end
--
--keys.cT = {openTerminalHere}

--function kill_line()
--	_m.textadept.editing.select_line()
--	buffer:delete_back()
--	buffer:delete_back()
--	buffer:word_right()
--end

function move_somedown(lines)
	for i=1, lines do
		buffer:line_down()
	end
end

function move_someup(lines)
	for i=1, lines do
		buffer:line_up()
	end
end
------------------------------------------------------------------------------------
-- Keys Binding
------------------------------------------------------------------------------------
keys['ck'] =  {buffer.line_cut, buffer}
keys['cj'] =  {buffer.line_delete, buffer} 
keys['cw']  = buffer.close
keys['c\b'] =  {buffer.del_word_left, buffer}
keys['cd']  = {buffer.del_word_right, buffer}
keys['a\b'] =  {buffer.del_word_left, buffer}
keys['ad'] =  {buffer.del_word_right, buffer}
keys['cy'] = _m.textadept.editing.select_line
keys['cp'] = _m.textadept.editing.select_paragraph
keys['ce'] = _m.textadept.editing.select_enclosed
keys['ci'] = _m.textadept.editing.select_indented_block
keys.cg = _m.textadept.editing.match_brace
keys.cG= { _m.textadept.editing.match_brace, 'select' }


-- view
keys['cH']  = { view.split, view, false }
keys['cV']  = { view.split, view}
keys['cN']  = { gui.goto_view, 1, false }
keys['cP']  = { gui.goto_view, -1, false }
keys['cW']  = { view.unsplit, view }

-- cursor movement
keys['al']  = {buffer.char_right, buffer}
keys['ah']  = {buffer.char_left, buffer}
keys['aj']  = {buffer.line_down, buffer}
keys['ak']  = {buffer.line_up, buffer}
keys['af']  = {buffer.word_right, buffer}
keys['ab']  = {buffer.word_left, buffer}
keys['aJ']  = {move_somedown, 20}
keys['aK']  = {move_someup, 20}
keys['av']  = {buffer.page_down, buffer}
keys['az']  = {buffer.page_up, buffer}
keys['am'] = {goto_nearest_occurrence, false}
keys['aM'] = {goto_nearest_occurrence, true}
keys['aa'] = { buffer.vc_home, buffer}
keys['ae'] = { buffer.line_end, buffer}	
keys['aq'] = { buffer.document_start, buffer}
keys['aw'] = { buffer.document_end, buffer}	
keys['ac'] = { view.goto_buffer, view, 1, false }   
keys['ax'] = { view.goto_buffer, view, -1, false }	
keys['au'] = { _m.textadept.editing.goto_line }	


-- programming about
keys['cm'] =  _m.textadept.editing.block_comment
keys['c\\'] =  _m.textadept.adeptsense.complete_symbol

-- miscs
-- keys['ao'] = { _m.textadept.file_browser.init,  '.'}	
