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
  showKeyPress: true
  showKeyDown: true
  showKeyUp: true
  init: ->
    @_super()
    @set 'content', Keygex.events

  reversedContent: (->
    @get('content').toArray().reverse()
  ).property 'content.@each'

  filteredContent: (->
    allow =
      keypress: @get('showKeyPress')
      keydown: @get('showKeyDown')
      keyup: @get('showKeyUp')

    @get('content').filter (event) ->
        return allow[event.type]


  ).property 'showKeyPress', 'showKeyDown', 'showKeyUp', 'content.@each'
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

Sk.KeyEventView = Ember.View.extend
  templateName: "key_event"
  classNames: ['key-event']
  didInsertElement: ->
    ts = @get('context.timestamp')
    if moment(ts).isAfter( moment().subtract(2, 'seconds') )
      @$().addClass 'highlight'
