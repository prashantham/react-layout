
React = require('react/addons')

merge = clone = require('xtend')

DIMENSIONS = ['height','width']

LayoutMixin = 
  contextTypes: 
    layoutContext: React.PropTypes.object,
 
  childContextTypes: 
    layoutContext: React.PropTypes.object,

  getChildContext: ->   
    layoutContext: @getLayoutContext(),
  
  getLayoutContext: ->
    @props.layoutContext or @context.layoutContext

  # get layout for this node, assuming appropriate calculations were done by parent
  getLocalLayout: ->
    local = {}
    layoutContext = @getLayoutContext()
    guardLayoutContext(layoutContext)

    def = getLayoutDef(this)
    return local unless def
    DIMENSIONS.forEach (dim) ->
      local[dim] = layoutContext[dim] if def[dim]
    local

  applyLayoutToChildren: (children) ->
    parentLayout = @getLayoutContext()
    guardLayoutContext(parentLayout)

    # first pass calculations for each dimension
    precalc = DIMENSIONS.reduce((precalc, dim) ->
      precalc[dim] =
        fixedSum: 0
        flexChildren: 0
      precalc
    , {})
    React.Children.forEach children, (child) ->
      return unless child
      def = getLayoutDef(child)
      return unless def
      DIMENSIONS.forEach (dim) ->
        if layoutIsFixed(def[dim])
          precalc[dim].fixedSum += def[dim]
        else if layoutIsFlex(def[dim])
          precalc[dim].flexChildren++
       
    # calc and apply layout to each child
    React.Children.map children, (child) ->
      # only apply to component-like objects (which have props)
      return child unless child?.props
      # skip children with refs (because they can't safely be cloned)
      return child if child.props.ref?
      # 'layout' here refers to the calculated layout for the child,
      # which will inform that child's layoutContext 
      # (and any of its children which inherit it)
      layout = clone(parentLayout)
      def = getLayoutDef(child)
      if def
        DIMENSIONS.forEach (dim) ->
          if layoutIsFixed(def[dim])
            layout[dim] = def[dim]
          else if layoutIsFlex(def[dim])
            flexSizeForDimension = (parentLayout[dim] - precalc[dim].fixedSum) / precalc[dim].flexChildren
            layout[dim] = flexSizeForDimension

      React.addons.cloneWithProps child, layoutContext: layout

getLayoutDef = (component) ->
  return unless component.props?.layoutHeight or component.props?.layoutWidth
  height: component.props.layoutHeight
  width: component.props.layoutWidth

guardLayoutContext = (layoutContext) ->
  assert(layoutContext,'layoutContext')
  assert(layoutContext.height,'layoutContext.height')
  assert(layoutContext.width,'layoutContext.width')

layoutIsFixed = (value) -> typeof value is 'number'

layoutIsFlex = (value) -> value is 'flex'

layoutIsInherited = (value) -> value is 'inherit'

assert = (value, name) -> throw new Error("missing #{name}") unless value?

module.exports = LayoutMixin

