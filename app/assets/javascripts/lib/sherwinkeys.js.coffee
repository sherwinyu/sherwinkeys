#     sherwinkeys.js
#     (c) Sherwin Yu 2014
((global) ->
  # cross-browser events
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

  # Add in the f keys programmatically
  for i in [1...20]
    _codeToKeyMap[111 + i] = 'f' + i

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

  _keyEvents = []

  eventToKeyEvent = (e) ->
    keyCode = e.which
    keyName = _characterFromEvent(e)
    keyEvent =
      keyCode: e.which
      type: e.type.substring(3)
      keyName: keyName
      originalEvent: e
      timestamp: new Date()

  checkTimeGap = ->
    return unless _keyEvents[0]?
    oldTs =  _keyEvents[_keyEvents.length - 1].timestamp
    diffSeconds = moment().diff(oldTs) / 1000
    if diffSeconds > 1
      insertTimeGap(diffSeconds)

  insertTimeGap = (duration) ->
    timeEvent =
      string: "   #{duration}s   "
      type: "gap"
      timestamp: new Date()
      duration: duration
    _keyEvents.pushObject timeEvent

  ##
  # @param keyEvents [Array<KeyEvent>]
  # @return string - a textual representation (to be matched against a Keygex)
  keyEventsToText = (keyEvents) ->
    # OPTIMIZE
    text = keyEvents.filter( (ke) -> ke.type != "gap").map((ke) -> keyEventToStringLiteral(ke)).join ''
    console.log text
    return text

  ##
  # @param cur [KeyEvent] the key event to compare
  # @return bool True `keyEvent` is a duplicate of the most recent event
  detectKeyDownDuplicate = (cur) ->
    # ans = (cur.type == "down" && downKeys.indexOf(cur.keyName) > -1)
    # console.log "cur.type", cur.type, "downKeys.indexOf(cur.keyName)", downKeys.indexOf(cur.keyName)
    # return ans
    return false unless _keyEvents.length
    return false if cur.type != "down"
    # Note we need to limit to keyDown events because keyPress events will be stuck in as well

    # find the last keyEvent with same type as cur
    idx = _keyEvents.length - 1
    while idx > 0 && (last = _keyEvents[idx]).keyName != cur.keyName
      idx -= 1
    # it's possible we hit the beginning and didn't find anything, so make sure that last and cur
    # have same keyName
    return false unless last && last.keyName == cur.keyName



    # current key event is a duplicate-down if last was a 'down' or 'press'
    return last.type in ["down", "press"]


    # while (last = _keyEvents[idx]).keyName = cur.keyName &&
    # idx -= 1
    # keyDownEvents = _keyEvents.filter( (ke) -> ke.type == "down") # TODO OPTIMIZE
    # last = keyDownEvents[keyDownEvents.last.length - 1]
    # last.type == "down" && cur.type =="down" && last.keyName == cur.keyName

  downKeys = []
  updateDownKeys = (keyEvent) ->
    if keyEvent.type == "down" && downKeys.indexOf(keyEvent.keyName) ==  -1
      downKeys.pushObject keyEvent.keyName
    if keyEvent.type == "up"
      downKeys.removeObject keyEvent.keyName

  recordEvent = (e)->
    checkTimeGap()
    keyEvent = eventToKeyEvent(e)
    updateDownKeys(keyEvent)

    # filter dupe keydowns
    if detectKeyDownDuplicate(keyEvent)
      console.log "rejectin cuz of dupe"
      return

    keyEvent.timestamp = new Date()
    keyEvent.string = keyEventToStringLiteral(keyEvent)

    _keyEvents.pushObject keyEvent

    checkCallbacks()

  checkCallbacks = ->
    for keygex in _keygexes
      if keyEventsToText(_keyEvents.filter (ke) -> ke.type in ["down", "up"]).match keygex.regex
        keygex.callback.call(keygex.that, keygex, _keyEvents[_keyEvents.length - 1])

  ##
  # @param combo [string]
  #   of the form:
  #   [key] + [x]
  bind = (string, that, data, callback) ->
    string = string.replace /\s+/g, ""
    ast = Keygex.parser.parse(string)
    regexTokens = astToRegexTokens(ast)
    console.log regexTokens
    regex = new RegExp regexTokens.join("")  + "$"

    keygex =
      originalShortcut: string
      regex: regex
      that: that
      data: data
      callback: callback

    _keygexes.pushObject keygex
    return keygex

  ##
  # @return [Array<String: keyname>]
  astToKeysUsed = (ast, collect=[]) ->
    for own k, v of ast
      if v instanceof Object
        collect.concat astToKeysUsed(v)
      if k == "event"
        collect.push v

    unique = []
    collect.forEach (keyName) ->
      if unique.indexOf(keyName) == -1
        unique.push keyName
    return unique


  astToRegexTokens = (ast, tokens) ->
    if ast.event?
      return [

        literalToken(ast.event)
      ]

    if ast.tag && ast.tag == "Seq"
      before = astToRegexTokens(ast.first)
      if ast.first.tag? != "Seq"
        before = before.concat astToKeysUsed(ast.first).map( (keyName) -> literalToken(keyName, "up") )

      after = astToRegexTokens(ast.rest)
      if ast.rest.tag? != "Seq"
        after = after.concat astToKeysUsed(ast.rest).map( (keyName) -> literalToken(keyName, "up") )

      return before.concat after


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
  #
  modsToken = (mods, type="down") ->
    # mods: ['ctrl', 'shift', 'alt', 'a']
    #
    tokens = mods.map( (mod) -> literalToken(mod, type))
    # tokens: (ctrl-down), (shift-down), (alt-down), (a-down)

    anyModAlternation = tokens. join '|'
    # anyModAlternation: (ctrl-down)|(shift-down)|(alt-down)|(a-down)

    anyModToken = tokenify anyModAlternation
    repeatedAnyMod = anyModToken + "{#{mods.length}}"
    # repeatedAnyMod: ((ctrl-down)|(shift-down)|(alt-down)|(a-down)){4}

    tokenify repeatedAnyMod

  ## language

  ##
  # @param combos [Array<string>]
  # @param hits [Array<string>]
  bindCombo = (mods, hit, that, data, callback) ->
    # arrayify the parametesr
    mods = [].concat mods

    modsDown = modsToken(mods)
    hitDown = literalToken(hit)

    compiled = modsDown + hitDown + "$"

    # modDown = literalToken(mod)
    # modUp = literalToken(mod, "up")
    # hit = literalToken(hit) + literalToken(hit, "up")
    # compiled = modDown + hit + modUp + "$"
    regex = new RegExp(compiled)
    keygex =
      originalShortcut: "#{mods}+#{hit}"
      regex: regex
      that: that
      data: data
      callback: callback

    _keygexes.pushObject keygex
    return keygex














  ##
  # returns a string literal (for regex tokens) representation of a string
  # Any "event token" that is the same must return the same event-to-string literal representation
  # Note that we surround the entire string
  # @param event [KeyEvent]
  # @return string
  keyEventToStringLiteral = (ke) ->
    "#{ke.keyName}-#{ke.type}"


  resetState = ->
    return unless _keyEvents.length
    lastTs = _keyEvents[_keyEvents.length - 1].timestamp
    if moment().diff(lastTs) > 1500
      downKeys.clear()
      _keyEvents.clear()


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
  module.exports = key  if typeof module isnt "undefined"
  return
) @
