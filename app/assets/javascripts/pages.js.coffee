window.Sk = Sherwinkeys

Sherwinkeys.TestPage = {}

Sk.TestPage.ping = (str) ->
  console.log str


Sherwinkeys.TestPage.init = ->
  document.testform.t.value += ""
  lines = 0
  if document.addEventListener
    document.addEventListener "keydown", keydown, false
    document.addEventListener "keypress", keypress, false
    document.addEventListener "keyup", keyup, false
    document.addEventListener "textInput", textinput, false
  else if document.attachEvent
    document.attachEvent "onkeydown", keydown
    document.attachEvent "onkeypress", keypress
    document.attachEvent "onkeyup", keyup
    document.attachEvent "ontextInput", textinput
  else
    document.onkeydown = keydown
    document.onkeypress = keypress
    document.onkeyup = keyup
    document.ontextinput = textinput # probably doesn't work
  return
showmesg = (t) ->
  old = document.testform.t.value
  if lines >= maxlines
    i = old.indexOf("\n")
    old = old.substr(i + 1)  if i >= 0
  else
    lines++
  document.testform.t.value = old + t + "\n"
  return
keyval = (n) ->
  return "undefined"  unless n?
  s = pad(3, n)
  s += " (" + String.fromCharCode(n) + ")"  if n >= 32 and n < 127
  s += " "  while s.length < 9
  s
keymesg = (w, e) ->
  row = 0
  head = [
    w
    "        "
  ]
  if document.testform.classic.checked
    showmesg head[row] + " keyCode=" + keyval(e.keyCode) + " which=" + keyval(e.which) + " charCode=" + keyval(e.charCode)
    row = 1
  if document.testform.modifiers.checked
    showmesg head[row] + " shiftKey=" + pad(5, e.shiftKey) + " ctrlKey=" + pad(5, e.ctrlKey) + " altKey=" + pad(5, e.altKey) + " metaKey=" + pad(5, e.metaKey)
    row = 1
  if document.testform.dom3.checked
    showmesg head[row] + " key=" + e.key + " char=" + e.char + " location=" + e.location + " repeat=" + e.repeat
    row = 1
  if document.testform.olddom3.checked
    showmesg head[row] + " keyIdentifier=" + pad(8, e.keyIdentifier) + " keyLocation=" + e.keyLocation
    row = 1
  showmesg head[row]  if row is 0
  return
pad = (n, s) ->
  s += ""
  s += " "  while s.length < n
  s
suppressdefault = (e, flag) ->
  if flag
    e.preventDefault()  if e.preventDefault
    e.stopPropagation()  if e.stopPropagation
  not flag

keydown = (e) ->
  e = event  unless e
  keymesg "keydown ", e
  suppressdefault e, document.testform.keydown.checked

keyup = (e) ->
  e = event  unless e
  keymesg "keyup   ", e
  suppressdefault e, document.testform.keyup.checked
keypress = (e) ->
  e = event  unless e
  keymesg "keypress", e
  suppressdefault e, document.testform.keypress.checked
textinput = (e) ->
  e = event  unless e

  #showmesg('textInput  data=' + e.data);
  showmesg "textInput data=" + e.data
  suppressdefault e, document.testform.textinput.checked
lines = 0
maxlines = 24

$(document).ready ->
  if $('#testform').length
    Sherwinkeys.TestPage.init()
  if $('#ember-testing').length
    Sherwinkeys.EmberTesting.init()
