React = require('react')

merge = require('xtend')

LayoutMixin = require('./mixin')

Layout = React.createClass
  displayName: 'Layout',
  mixins: [
    LayoutMixin,
  ]
  statics:
    hasReactLayout: true

  getDefaultProps: ->
    component: React.DOM.div

  render: ->
    {component, style} = @props

    extraProps = {}
    extraProps.style = merge(style or {}, @getLocalLayout())

    extraProps.children = @applyLayoutToChildren(@props.children)

    component(merge(@props, extraProps))

module.exports = Layout
