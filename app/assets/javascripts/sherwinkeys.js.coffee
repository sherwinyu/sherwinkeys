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

Ember.Handlebars.helper 'timeAgo', (value, options) ->
  elapsedTime = moment( moment().diff value).utc()
  formatString = "s[s]"
  if elapsedTime.minutes() > 0
    formatString += "m[m] "
  time = elapsedTime.format formatString
  "#{time} ago"
  # escaped = Handlebars.Utils.escapeExpression(value)
  # new Handlebars.SafeString('<span class="highlight">' + escaped + '</span>');
  #
Ember.Handlebars.helper 'timeDiff', (value, now, options) ->
  elapsedTime = moment( moment().diff value).utc()
  formatString = ""
  if elapsedTime.minutes() > 0
    formatString += "m[m] "
  formatString+= "s[s]"
  time = elapsedTime.format formatString
  "#{time} ago"
  # escaped = Handlebars.Utils.escapeExpression(value)
  # new Handlebars.SafeString('<span class="highlight">' + escaped + '</span>');

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

