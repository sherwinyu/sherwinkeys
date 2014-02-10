#= require jquery
#= require handlebars
#= require ember
#= require ember-data
#= require ./lib/sherwinkeys
#
#= require_self
#= require sherwinkeys
#
#= require pages

# for more details see: http://emberjs.com/guides/application/
window.Sherwinkeys = Ember.Application.create()
window.Sk = window.Sherwinkeys

#= require_tree .
