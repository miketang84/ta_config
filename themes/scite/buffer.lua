-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- SciTE editor theme for Textadept.

local buffer = buffer

-- Folding.
buffer.property['fold'] = '1'
buffer.property['fold.by.indentation'] = '1'
buffer.property['fold.line.comments'] = '0'

-- Tabs and Indentation.
buffer.tab_width = 4
buffer.use_tabs = true
buffer.indent = 4
buffer.tab_indents = true
buffer.back_space_un_indents = true
