Sk.KeyEventsController = Ember.ArrayController.extend
  init: ->
    @_super()
    @set 'content', Keygex.events
  reversedContent: (->
    @get('content').toArray().reverse()
  ).property 'content.@each'
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

