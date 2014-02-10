#= require ./store
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./components
#= require_tree ./templates
#= require_tree ./routes
#= require ./router
#= require_self
#= require ./helpers

Sk.KeyEvent = Ember.Object.extend

Sk.EmberTesting =
  init: ->
    Sk.TestView.create().append()

# abstract key logic for assign and unassign
# @param key [String] of the form
Sk.getKeys = (key) ->
  keys = undefined
  key = key.replace(/\s/g, "")
  keys = key.split(",")
  keys[keys.length - 2] += ","  if (keys[keys.length - 1]) is ""
  keys

