--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2010 Brian Schott (Sir Alaran)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

---
-- Snippets for the html module.
module('_m.hypertext.snippets', package.seeall)

local snippets = _G.snippets

if type(snippets) == 'table' then
	snippets.hypertext = {
	a = [[<a href="%1(#)"/>%0</a>]],
	abbr = [[<abbr>%0</abbr>]],
	acronym = [[<acronym title="%1">%0</acronym>]],
	address = [[<address>%0</address>]],
	area = [[<area shape="%1(default, rect, circle, poly)" coords="%2" href="%3" alt="%4"/>]],
	b = [[<b>%0</b>]],
	base = [[<base %1(target, href)="%2"/>]],
	baset = [[<base target="%1"/>]],
	baseh = [[<base href="%1"/>]],
	bdo = [[<bdo dir="%1(ltr, rtl)">%0</bdo>]],
	big = [[<big>%0</big>]],
	blockquote = [[<blockquote>%0</blockquote>]],
	body = [[<body>
	%0
</body>]],
	br = [[<br/>]],
	button = [[<button type="%1(button, reset, submit)">%0</button>]],
	caption = [[<caption>%0</caption>]],
	cdata = "<![CDATA[%0]]>",
	cite = [[<cite>%0</cite>]],
	code = [[<code>%0</code>]],
	col = [[<col align="%1(left, right, center, justify, or char)"/>]],
	colgroup = [[<colgroup>%0</colgroup>]],
	dd = [[<dd>%0</dd>]],
	del = [[<del>%0</del>]],
	dfn = [[<dfn>%0</dfn>]],
	div = [[<div>
	%0
</div>]],
	dl = [[<dl>%0</dl>]],
	dt = [[<dt>%0</dt>]],
	em = [[<em>%0</em>]],
	fieldset = [[<fieldset>
	<legend>%1</legend>
	%0
</fieldset>]],
	form = [[<form>
	%0
</form>]],
	frame = [[<frame src="%1"/>]],
	frameset = [[<frameset>
	<frame src="%1"/>
	%0
</frameset>]],
	h1 = [[<h1>%0</h1>]],
	h2 = [[<h2>%0</h2>]],
	h3 = [[<h3>%0</h3>]],
	h4 = [[<h4>%0</h4>]],
	h5 = [[<h5>%0</h5>]],
	h6 = [[<h6>%0</h6>]],
	head = [[<head>
	%0
</head>]],
	hr= [[<hr/>]],
	html = [[<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html lang="%1(en-US)">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=%2(UTF-8)"/>
	</head>
	<body>
		%0
	</body>
</html>]],
	i = [[<i>%0</i>]],
	iframe = [[<iframe src="%1" width="%2" height="%3">
	%0
</iframe>]],
	img = [[<img src="%1" width="%2" height="%3" alt="%4(%1)"/>]],
	input = [[<input type="%1" value="%2"/>]],
	ins = [[<ins>%0</ins>]],
	kbd = [[<kbd>%0</kbd>]],
	label = [[<label for="%1">%0</label>]],
	legend = [[<legend>%0</legend>]],
	li = [[<li>%0</li>]],
	link = [[<link rel="%1(stylesheet)" type="%2(text/css)" href="%3(stylesheet.css)"/>]],
	map = [[<map name="%1">%0</map>]],
	meta = [[<meta name="%1" content="%2"/>]],
	metah = [[<meta http-equiv="%1" content="%2"/>]],
	noframes = [[<noframes>%0</noframes>]],
	noscript = [[<noscript>%0</noscript>]],
	object = [[<object>%0</object>]],
	ol = [[<ol>
	<li>%0</li>
</ol>]],
	optgroup = [[<optgroup label="%1">
	<option value="%2">%0</option>
</optgroup>]],
	option = [[<option>%0</option>]],
	p = [[<p>%0</p>]],
	param = [[<param name="%1" value="%2"/>]],
	pre = [[<pre>%0</pre>]],
	q = [[<q>%0</q>]],
	samp = [[<samp>%0</samp>]],
	script = [[<script type="%1(text/javascript)">
	%0
</script>]],
	select = [[<select>
	<optgroup label="%1">
		<option value="%2">%0</option>
	</optgroup>
</select>]],
	small = [[<small>%0</small>]],
	span = [[<span %1()="%2">%0</span>]],
	strong = [[<strong>%0</strong>]],
	style = [[<style type="%1(text/css)">
	%0
</style>]],
	sub = [[<sub>%0</sub>]],
	sup = [[<sup>%0</sup>]],
	table = [[<table border="%1(1)">
	<thead>
		<tr></tr>
	</thead>
	<tbody>
		<tr>%0</tr>
	</tbody>
</table>]],
	tbody = [[<tbody>
	<tr>%0</tr>
</tbody>]],
	td = [[<td>%0</td>]],
	textarea = [[<textarea rows="%1" cols="%2">
	%0
</textarea>]],
	tfoot = [[<tfoot>
	<tr>%0</tr>
</tfoot>]],
	th = [[<th>%0</th>]],
	thead = [[<thead>
	<tr>%0</tr>
</thead>]],
	title = [[<title>%0</title>]],
	tr = [[<tr>
	<td>%0</td>
</tr>]],
	tt = [[<tt>%0</tt>]],
	ul = [[<ul>
	<li>%0</li>
</ul>]],
	var = [[<var>%0</var>]],
	xhtml = [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html lang="%1(en-US)" xml:lang="%1" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=%2(UTF-8)"/>
	</head>
	<body>
		%0
	</body>
</html>]],
	lorem = [[<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed elit
enim, sagittis at facilisis vitae, tempus sit amet felis. Cras elementum magna
ac sapien venenatis molestie. Suspendisse sit amet urna sem, vitae rutrum
urna. Mauris rutrum nulla vel magna egestas ornare. Maecenas eget enim est,
vitae molestie ligula. Sed vel fermentum ante. Aenean pharetra nisi nec mi
ultrices porta. Nullam porttitor urna sit amet quam placerat imperdiet. Ut
viverra dictum mauris, sollicitudin elementum magna placerat id. Proin
pharetra, quam in sollicitudin facilisis, mi purus pharetra ipsum, sed gravida
sapien lectus eu metus.</p>
<p>Suspendisse scelerisque erat vitae mauris ultricies tristique quis vel
turpis. Etiam rhoncus iaculis condimentum. Nullam vitae dui vel eros volutpat
tempor ac et massa. Fusce ullamcorper consectetur justo et pellentesque. Morbi
nisi dolor, viverra ut feugiat vel, venenatis nec nisi. Nullam et nulla magna,
sit amet faucibus enim. Aenean in massa quis sem fermentum sodales. Nam diam
orci, pulvinar non tempus sed, ullamcorper in felis. Morbi ac odio justo,
gravida tempor elit. Suspendisse at metus arcu. Pellentesque libero diam,
sodales nec vehicula sit amet, sodales vitae neque. Pellentesque habitant
morbi tristique senectus et netus et malesuada fames ac turpis egestas.</p>
<p>Cras blandit eleifend mi, id condimentum elit vehicula ac. Mauris nisl
quam, laoreet eget condimentum vitae, vulputate nec augue. Aliquam at odio
velit. Aliquam fermentum auctor elementum. Quisque sagittis tortor non velit
imperdiet mollis sit amet vel libero. Pellentesque semper viverra arcu, vitae
consequat lorem ullamcorper non. Duis vitae sagittis massa. Nunc fermentum
consequat dui, vitae rutrum diam fringilla in. Suspendisse potenti. Aenean
iaculis mauris ac tortor convallis rutrum. Morbi convallis scelerisque
feugiat. Sed laoreet vestibulum ante sed ullamcorper. Pellentesque ut quam ac
diam tempus dignissim. Maecenas tincidunt pulvinar magna vel consectetur.
Donec odio mi, vehicula et bibendum sed, pellentesque sed eros.</p>
<p>Vestibulum risus lectus, vestibulum in scelerisque eu, lobortis quis risus.
Aenean congue felis nec arcu ornare dapibus. Morbi sed odio justo, et placerat
orci. Praesent viverra, diam ut congue volutpat, sem libero placerat elit, eu
viverra purus orci at lacus. Nullam vel purus sapien. Class aptent taciti
sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nunc
ullamcorper auctor tortor nec tincidunt. Vivamus nec ipsum leo, vel ornare
nisi. Curabitur odio metus, ultricies eu pellentesque id, tempor eu enim.
Morbi iaculis vestibulum venenatis. Vivamus vitae augue quis nisi semper
fringilla a vulputate diam. Cras a est nisi. Ut iaculis bibendum sem, ut
iaculis odio tincidunt nec. Aliquam eget leo diam. Pellentesque at congue
tortor. Fusce convallis ornare lacus nec lobortis. Nullam non odio vitae nisi
vulputate tristique vel non quam. Mauris feugiat mi dignissim felis laoreet
pharetra. Cras molestie odio at velit rhoncus consequat. Sed suscipit
condimentum dui eu dictum.</p>
<p>Nullam pretium nunc arcu, ac scelerisque nulla. Sed pharetra feugiat
pulvinar. Nulla posuere ligula ipsum. Donec arcu lectus, congue eget
scelerisque eu, egestas a augue. Cras vel nisl enim. Aliquam erat volutpat.
Integer auctor consectetur elit sed dignissim. Duis posuere pulvinar mauris,
id condimentum nulla pharetra vitae. Donec pellentesque mauris ut nisl
facilisis id pellentesque ipsum volutpat. Nulla facilisi. Nunc blandit porta
lectus at luctus. Aenean interdum mi nec dolor aliquet facilisis. Quisque in
dolor elit, vel tempor tortor.</p>]],
  }
end
