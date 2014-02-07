Sk.TestView = Ember.View.extend
  keyDown: (e) ->
    if e.which ==  186 # colon
      e.preventDefault()
