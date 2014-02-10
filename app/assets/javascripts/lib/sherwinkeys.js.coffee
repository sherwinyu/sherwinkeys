#     sherwinkeys.js
#     (c) Sherwin Yu 2014
((global) ->

  updateModifierKey = (event) ->
    for k of _mods
      event[modifierMap[k]]
    return

  # handle keydown event
  dispatch = (event) ->
    key = undefined
    handler = undefined
    k = undefined
    i = undefined
    modifiersMatch = undefined
    scope = undefined
    key = event.keyCode
    _downKeys.push key  if index(_downKeys, key) is -1

    # if a modifier key, set the key.<modifierkeyname> property to true and return
    key = 91  if key is 93 or key is 224 # right command on webkit, command on Gecko
    if key of _mods
      _mods[key] = true

      # set assignKey (e.g. key.shift) to true
      for k of _MODIFIERS
        assignKey[k] = true if _MODIFIERS[k] == key
      return
    updateModifierKey event

    # see if we need to ignore the keypress (filter() can can be overridden)
    # by default ignore key presses if a select, textarea, or input is focused
    return  unless assignKey.filter.call(this, event)

    # abort if no potentially matching shortcuts found
    return  unless key of _handlers
    scope = getScope()

    # for each potential shortcut
    i = 0
    while i < _handlers[key].length
      handler = _handlers[key][i]

      # see if it's in the current scope
      if handler.scope is scope or handler.scope is "all"

        # check if modifiers match if any
        modifiersMatch = handler.mods.length > 0
        for k of _mods
          continue

        # call the handler and stop the event if neccessary
        if (handler.mods.length is 0 and not _mods[16] and not _mods[18] and not _mods[17] and not _mods[91]) or modifiersMatch
          if handler.method(event, handler) is false
            if event.preventDefault
              event.preventDefault()
            else
              event.returnValue = false
            event.stopPropagation()  if event.stopPropagation
            event.cancelBubble = true  if event.cancelBubble
      i++
    return


  # parse and assign shortcut
  assignKey = (key, scope, method) ->
    keys = undefined
    mods = undefined
    keys = getKeys(key)

    # arg shift
    if method is `undefined`
      method = scope
      scope = "all"

    # for each shortcut
    i = 0

    while i < keys.length

      # set modifier keys if any
      mods = []
      key = keys[i].split("+")
      if key.length > 1
        mods = getMods(key)
        key = [key[key.length - 1]]

      # convert to keycode and...
      key = key[0]
      key = code(key)

      # ...store handler

      # default initialize the handler. Still stored based on the key
      _handlers[key] = []  unless key of _handlers
      _handlers[key].push
        shortcut: keys[i] # the String representation
        scope: scope
        method: method
        key: keys[i]
        mods: mods

      i++

  # cross-browser events
  addEvent = (object, event, method) ->
    if object.addEventListener
      object.addEventListener event, method, false
    else if object.attachEvent
      object.attachEvent "on" + event, ->
        method window.event
        return

    return

  _handlers = {}
  _mods =
    16: false
    18: false
    17: false
    91: false

  _scope = "all"
  _MODIFIERS =
    "⇧": 16
    shift: 16
    "⌥": 18
    alt: 18
    option: 18
    "⌃": 17
    ctrl: 17
    control: 17
    "⌘": 91
    command: 91

  ##
  # mapping of special keycodes to their corresponding keys
  #
  # everything in this dictionary cannot use keypress events
  # so it has to be here to map to the correct keycodes for
  # keyup/keydown events
  # @type [Object<Keycode::Integer, String::keyname>]
  _codeToKeyMap =
    8: 'backspace'
    9: 'tab'
    13: 'enter'
    16: 'shift'
    17: 'ctrl'
    18: 'alt'
    20: 'capslock'
    27: 'esc'
    32: 'space'
    33: 'pageup'
    34: 'pagedown'
    35: 'end'
    36: 'home'
    37: 'left'
    38: 'up'
    39: 'right'
    40: 'down'
    45: 'ins'
    46: 'del'
    91: 'meta'
    93: 'meta'
    224: 'meta'


  _keyToCodeMap =
    backspace: 8
    tab: 9
    clear: 12
    enter: 13
    return: 13
    esc: 27
    escape: 27
    space: 32
    left: 37
    up: 38
    right: 39
    down: 40
    del: 46
    delete: 46
    home: 36
    end: 35
    pageup: 33
    pagedown: 34
    ",": 188
    ".": 190
    "/": 191
    "`": 192
    "-": 189
    "=": 187
    ";": 186
    "'": 222
    "[": 219
    "]": 221
    "\\": 220

  code = (x) ->
    _MAP[x] or x.toUpperCase().charCodeAt(0)

  _characterFromEvent = (e) ->
    # for keypress events we should return the character as is
    if e.type == "keypress"
      character = String.fromCharCode(e.which)

      # if the shift key is not pressed then it is safe to assume
      # that we want the character to be lowercase.  this means if
      # you accidentally have caps lock on then your key bindings
      # will continue to work
      #
      # the only side effect that might not be desired is if you
      # bind something like 'A' cause you want to trigger an
      # event when capital A is pressed caps lock will no longer
      # trigger the event.  shift+a will though.
      character = character.toLowerCase()  unless e.shiftKey
      return character

    # for non keypress events the special maps are needed
    return _codeToKeyMap[e.which] if _codeToKeyMap[e.which]

    # TODO(syu): add this ftnlity back in
    # return _KEYCODE_MAP[e.which]  if _KEYCODE_MAP[e.which]

    # if it is not in the special map
    # with keydown and keyup events the character seems to always
    # come in as an uppercase character whether you are pressing shift
    # or not.  we should make sure it is always lowercase for comparisons
    String.fromCharCode(e.which).toLowerCase()

  _events = []

  recordEvent = (e)->
    keyCode = e.which
    keyName = _characterFromEvent(e)
    _events.pushObject
      keyCode: e.which
      type: e.type
      keyName: keyName
      originalEvent: e
      timestamp: new Date()

  for k of _MODIFIERS
    continue

  addEvent document, "keydown", recordEvent
  addEvent document, "keypress", recordEvent
  addEvent document, "keyup", recordEvent

  # set window.key and window.key.set/get/deleteScope, and the default filter
  # global.key = assignKey
  # global.key.setScope = setScope
  # global.key.getScope = getScope
  # global.key.deleteScope = deleteScope
  # global.key.filter = filter
  # global.key.isPressed = isPressed
  # global.key.getPressedKeyCodes = getPressedKeyCodes
  # global.key.noConflict = noConflict
  # global.key.unbind = unbindKey
  global.Keygex ||= {}
  global.Keygex.cfe = _characterFromEvent
  global.Keygex.events = _events
  module.exports = key  if typeof module isnt "undefined"
  return
) @
