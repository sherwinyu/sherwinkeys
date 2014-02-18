#     Keygex.js
#     (c) Sherwin Yu 2014

((global) ->

  # cross-browser shim for adding events
  addEvent = (object, event, method) ->
    if object.addEventListener
      object.addEventListener event, method, false
    else if object.attachEvent
      object.attachEvent "on" + event, ->
        method window.event
        return

    return

  ##
  # mapping of special keycodes to their corresponding keys
  #
  # everything in this dictionary cannot use keypress events
  # so it has to be here to map to the correct keycodes for
  # keyup/keydown events
  # @type [Object<Keycode::Integer, String::keyname>]
  _codeToKeyMap = []

  setupKeyMaps = ->
    # Add in the f keys programmatically
    for i in [1...20]
      _codeToKeyMap[111 + i] = 'f' + i

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


      # Special keys
      106: '*'
      107: '+'
      109: '-'
      110: '/'
      186: ';'
      187: '='
      188: ','
      189: '-'
      190: '.'
      191: '/'
      192: '`'
      219: '['
      220: '\\'
      221: ']'
      222: '\''
  setupKeyMaps()

  ##
  # @param e [Event]
  # @return string::KeyName
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

    # if it is not in the special map
    # with keydown and keyup events the character seems to always
    # come in as an uppercase character whether you are pressing shift
    # or not.  we should make sure it is always lowercase for comparisons
    String.fromCharCode(e.which).toLowerCase()

  ##
  # Simple array of all KeyEvents, logged from front
  # @type Array<KeyEvent>
  _keyEvents = []

  ##
  # Generates a KeyEvent object from a browser event object, containing the code,
  # normalized-name, event type (up / down / press), and timestamp.
  # @param e [Event]
  # @return KeyEvent
  eventToKeyEvent = (e) ->
    keyCode = e.which
    keyName = _characterFromEvent(e)
    keyEvent =
      keyCode: e.which
      type: e.type.substring(3)
      keyName: keyName
      originalEvent: e
      timestamp: new Date()

  ##
  # Checks whether at least one second has passed since any user input. If so,
  # inserts a time gap event.
  # Called by `recordEvent`
  _checkTimeGap = ->
    return unless _keyEvents[0]?
    oldTs =  _keyEvents[_keyEvents.length - 1].timestamp
    diffSeconds = moment().diff(oldTs) / 1000
    if diffSeconds > 1
      _insertTimeGap(diffSeconds)

  _insertTimeGap = (duration) ->
    timeEvent =
      string: "    #{duration}s    "
      type: "gap"
      timestamp: new Date()
      duration: duration
    _keyEvents.pushObject timeEvent
    hooks.keyEventAdded timeEvent

  ##
  # @param keyEvents [Array<KeyEvent>]
  # @return string - a textual representation (to be matched against a Keygex)
  keyEventsToText = (keyEvents) ->
    # TODO(syu): OPTIMIZE -- this is horribly inefficient.
    # We're doing a filter and then a join on every input event.
    # Should probably just keep the text-stream in-memory and build on it.
    text = keyEvents.filter( (ke) -> ke.type != "gap").map((ke) -> keyEventToStringLiteral(ke)).join ''
    console.log text
    return text

  ##
  # @param cur [KeyEvent] the key event to compare
  # @return bool True `cur` is a duplicate of the most recent event
  _detectKeyDownDuplicate = (cur) ->
    return false unless _keyEvents.length
    return false if cur.type != "down"
    # Note we need to limit to keyDown events because keyPress events will be stuck in as well

    # A KeyDown event is considered a "duplicate" if:
    #   The most recent key event with the same keyName as the current keydown event
    #   is a keydown or a keypress.

    # First, find the most recent key event with the same keyname
    idx = _keyEvents.length - 1
    while idx > 0 && (last = _keyEvents[idx]).keyName != cur.keyName
      idx -= 1
    # It's possible we hit the beginning of keyEvents and didn't find anything; in that case,
    # the current keydown event is not a duplicate.
    return false unless last && last.keyName == cur.keyName

    # Finally, if the most-recent event with the same name has a type of 'down' or 'press',
    # then the current keydown event is a duplicate.
    return last.type in ["down", "press"]

  downKeys = []

  ##
  #
  _updateDownKeys = (keyEvent) ->
    if keyEvent.type == "down" && downKeys.indexOf(keyEvent.keyName) ==  -1
      downKeys.pushObject keyEvent.keyName
      hooks.downKeyAdded keyEvent.keyName, keyEvent
    if keyEvent.type == "up"
      downKeys.removeObject keyEvent.keyName
      hooks.downKeyRemoved keyEvent.keyName, keyEvent

  ##
  # Hooks that are called when the following events happen
  # @type [Object<hook name, callback function>]
  hooks =
    downKeyAdded: (keyEvent) -> false
    downKeyRemoved: (keyEvent) -> false
    downKeysCleared: ->
    keygexAdded: (keygex) -> false
    keyEventAdded: (keyEvent) -> false
    keyEventsCleared: -> false

  recordEvent = (e)->
    _checkTimeGap()
    keyEvent = eventToKeyEvent(e)
    _updateDownKeys(keyEvent)

    # Filter out duplicate (repeated) keydown events
    if _detectKeyDownDuplicate(keyEvent)
      return

    # Create the key event
    keyEvent.timestamp = new Date()
    keyEvent.string = keyEventToStringLiteral(keyEvent)
    _keyEvents.push keyEvent
    hooks.keyEventAdded keyEvent

    _fireKeygexCallbacks()

  ##
  # Fire all relevant callbacks for registered keygexes.
  _fireKeygexCallbacks = ->
    for keygex in _keygexes
      # Check if the keygex's regexp matches the textual representation of the keyevents
      if keyEventsToText(_keyEvents.filter (ke) -> ke.type in ["down", "up"]).match keygex.regex
        keygex.callback.call(keygex.that, keygex, _keyEvents[_keyEvents.length - 1])

  ##
  # @param keygexString [String] A valid keygex string. See documentation for valid strings
  # @param that [Object] the object to be used as `this` for the callback
  # @param data [Object] any additional data that will be attached to the keygex object.
  # @param callback [Function] callback function invoked when
  #   Callback function takes the following params:
  #     - `keygex` the keygex object, containing the `originalShortcut`, the compiled `regex`, and the
  #     user specified `data`
  #     - `keyEvent` the event that completed the keygex (the last event in the keygex string)
  # @return [Keygex] the newly added keygex object
  bind = (keygexString, that, data, callback) ->
    keygexString = keygexString.replace /\s+/g, ""

    # Convert the keygex string to a comiled regex
    ast = Keygex.parser.parse(keygexString)
    regexTokens = astToRegexTokens(ast)
    regex = new RegExp regexTokens.join("")  + "$"

    keygex =
      originalShortcut: keygexString
      regex: regex
      that: that
      data: data
      callback: callback
    _keygexes.push keygex
    hooks.keygexAdded(keygex)
    return keygex

  ##
  # @return [Array<String: keyname>]
  astToKeysUsed = (ast)  ->
    collect = []
    # If it's a sequence, we don't need to do anything, since astToRegexTokens on a sequence
    # node already inserts the
    if ast.tag == "Seq"
      # x = 5 # do nothing
      collect = collect.concat astToKeysUsed(ast.rest)
    else # Otherwise, it's a multi event, wrapped event, or basic event
      for own k, v of ast
        if v instanceof Object and !(v instanceof Array)
          collect = collect.concat astToKeysUsed(v)
        if v instanceof Array
          v.forEach (element) ->
            collect = collect.concat astToKeysUsed(element) if element instanceof Object
        if k == "event"
          collect.push v

    unique = []
    collect.forEach (keyName) ->
      if unique.indexOf(keyName) == -1
        unique.push keyName
    return unique


  astToRegexTokens = (ast, tokens) ->
    if ast.event?
      return [ literalToken(ast.event) ]

    if ast.tag && ast.tag == "Seq"
      before = astToRegexTokens(ast.first)
      # if it's not a sequence, then we need to close out"
      # unless ast.first.tag == "Seq"
      # ALWAYS close out
      keys = astToKeysUsed(ast.first)
      beforeUp = simulToken(keys, "up")
      before = before.concat beforeUp


      # Don't end-ups on the after sequence
      after = astToRegexTokens(ast.rest)
      return before.concat after

    if ast.tag && ast.tag == "multi"
      modKeyNames = ast.events.map( (e) -> e.event )
      return [ simulToken(modKeyNames) ]

    if ast.outer && ast.inner
      outer = astToRegexTokens(ast.outer)
      inner = astToRegexTokens(ast.inner)
      return outer.concat inner

  literalToken = (keyName, type="down") ->
    keyEvent =
      keyName: keyName
      type: type
    literalString = keyEventToStringLiteral(keyEvent)
    tokenify literalString

  tokenify = (string) ->
    "(?:#{string})"

  _keygexes = []

  keygexTemplate =
    originalShortcut: "a+b"
    compiled: "(?:a-down)(?:b-down)(?:b-up)(?:b-down)"
    regex: /(?:a-down)(?:b-down)(?:b-up)(?:b-down)$/
    that: window
    data: null
    callback: -> console.log 'invoked'

  ##
  # Returns a mass token that reflects order-independent pressing
  # of the keys in `mods`
  simulToken = (keyNames, type="down") ->
    # keyNames: ['ctrl', 'shift', 'alt', 'a']

    # TODO(syu): don't need to tokenify just yet
    tokens = keyNames.map( (key) -> literalToken(key, type))
    # tokens: (ctrl-down), (shift-down), (alt-down), (a-down)

    anyKeyAlternation = tokens. join '|'
    # anyModAlternation: (ctrl-down)|(shift-down)|(alt-down)|(a-down)

    anyKeyToken = tokenify anyKeyAlternation
    simulKeyToken = anyKeyToken + "{#{keyNames.length}}"
    # repeatedAnyMod: ((ctrl-down)|(shift-down)|(alt-down)|(a-down)){4}

    # TODO optimize -- don't need to tknfy here either
    tokenify simulKeyToken

  ##
  # returns a string literal (for regex tokens) representation of a string
  # Any "event token" that is the same must return the same event-to-string literal representation
  # Note that we surround the entire string
  # @param event [KeyEvent]
  # @return string
  keyEventToStringLiteral = (ke) ->
    "#{ke.keyName}-#{ke.type}"

  ##
  # Clears the key events log
  resetState = ->
    return unless _keyEvents.length
    lastTs = _keyEvents[_keyEvents.length - 1].timestamp
    if moment().diff(lastTs) > 1500
      downKeys = []
      _keyEvents = []
      hooks.keyEventsCleared()
      hooks.downKeysCleared()


  addEvent document, "keydown", recordEvent
  addEvent document, "keypress", recordEvent
  addEvent document, "keyup", recordEvent
  addEvent window, "blur", ->
    utils.delayed resetState, 3000
  addEvent window, "focus", resetState

  global.Keygex ||= {}
  global.Keygex.cfe = _characterFromEvent
  global.Keygex.kett = keyEventsToText
  global.Keygex.events = _keyEvents
  global.Keygex.keygexes = _keygexes
  global.Keygex.bind = bind
  global.Keygex.downKeys = downKeys
  global.Keygex.hooks = hooks
  module.exports = key  if typeof module isnt "undefined"
  return
) @
