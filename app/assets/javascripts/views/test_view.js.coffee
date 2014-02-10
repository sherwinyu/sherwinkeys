Sk.KeyEventsController = Ember.ArrayController.extend
  init: ->
    @_super()
    @set 'content', Keygex.events

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

