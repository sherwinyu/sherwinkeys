Sk.KeyEventsController = Ember.ArrayController.extend
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
  controller: Sk.KeyEventsController.create()

Sk.KeyEventsView = Ember.View.extend
  templateName : "key_events"

Sk.KeyEventView = Ember.View.extend
  classNames: ['key-event']

