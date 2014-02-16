Sk.Clock = Ember.Object.extend
  # in ms
  _elapsedTime: 0,
  _start: new Date()
  pulse: Ember.computed.oneWay('_elapsedTime').readOnly()

  secondsElapsed: (->
    @get('_elapsedTime') / 1000
  ).property('_elapsedTime').readOnly()

  tick: (->
    Ember.run.later (=>
      ms = moment().diff @_start
      @set('_elapsedTime', ms)
    ), 2000
  ).observes('_elapsedTime').on('init')

Sk.KeyEventsController = Ember.ArrayController.extend
  clock : Sk.Clock.create()
  showKeyPress: false
  showKeyDown: true
  showKeyUp: true
  showGaps: true
  downKeys: null

  init: ->
    @_super()
    @set 'content', Keygex.events
    @set 'downKeys', Keygex.downKeys

  reversedContent: (->
    @get('content').toArray().reverse()
  ).property 'content.@each'

  filteredContent: (->
    allow =
      press: @get('showKeyPress')
      down: @get('showKeyDown')
      up: @get('showKeyUp')
      gap: @get 'showGaps'

    @get('reversedContent').filter (event) ->
        return allow[event.type]


  ).property 'showKeyPress', 'showKeyDown', 'showKeyUp', 'showGaps', 'reversedContent'
  actions:
    clear: ->
      @get('content').clear()



Sk.TestView = Ember.View.extend
  templateName: "test"
  keyDown: (e) ->
    if e.which ==  186 # colon
      console.log "colon"
    if e.which ==  65 # a
      console.log "a"

Sk.KeyEventsView = Ember.View.extend
  templateName : "key_events"
  actions:
    clear: ->
      debugger
  initBindings: (->
  ).on "didInsertElement"


Sk.KeyEventView = Ember.View.extend
  templateName: "key_event"
  classNames: ['key-event']
  classNameBindings: ['controller.type']

  didInsertElement: ->
    ts = @get('context.timestamp')
    if moment(ts).isAfter( moment().subtract(0.5, 'seconds') )
      @$().addClass 'highlight'

Sk.KeygexesView = Ember.View.extend
  templateName: "keygexes"
  classNames: ['keygexes']

Sk.KeygexesController = Ember.ArrayController.extend
  addKeygex: (input) ->

    # hit = mods.pop()
    connector = Ember.Object.create()
    Keygex.bind input, connector, connector, (keygex) ->
      keygex.data.set "activated", true
      utils.delayed( 1000, -> keygex.data.set "activated", false )

  init: ->
    @set('content', Keygex.keygexes)
    @addKeygex("a_b_c")
    # @addKeygex "
    # ["shift", "alt", "ctrl"], "b", window, ->

Sk.KeygexView = Ember.View.extend
  classNames: 'keygex'
  classNameBindings: ['controller.content.data.activated:activated']
