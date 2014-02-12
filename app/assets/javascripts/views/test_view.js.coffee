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
    ), 250
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
    Keygex.bind ["shift", "alt", "ctrl"], "b", window, ->
      console.log "HIT"
    Keygex.bind ["z", "x", "c", "v"], "b", window, ->
      console.log "HIT"
  ).on "didInsertElement"


Sk.KeyEventView = Ember.View.extend
  templateName: "key_event"
  classNames: ['key-event']
  classNameBindings: ['controller.type']

  didInsertElement: ->
    ts = @get('context.timestamp')
    if moment(ts).isAfter( moment().subtract(2, 'seconds') )
      @$().addClass 'highlight'
