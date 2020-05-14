
getCurrentCanvas = ->
  w: window.innerWidth
  h: window.innerHeight
  offset_y: 40

resizeTimer = false
resizeHandler = ()->
  if resizeTimer != false
    clearTimeout resizeTimer
  resizeTimer = setTimeout ->
    m.startComputation()
    vm.create()
    m.endComputation()
  , 500

if window.navigator?.userAgent?
  userAgent = window.navigator.userAgent
  if userAgent.indexOf('iPhone')>=0 or userAgent.indexOf('iPad')>=0 or userAgent.indexOf('android')>=0
    window.addEventListener 'orientationchange', resizeHandler
  else
    window.addEventListener 'resize', resizeHandler

create_layer_node = (node, node_list, diag_list)->
  len = node_list.length
  if node.data.name?
    tb = textbox(node, node.data.name, 'red')
  else
    tb = textbox(node, len)
  node_list.push tb
  if node.children?
    node.children.map (child, i)->
      diag_list.push diag_v(node, child)
      create_layer_node child, node_list, diag_list

vm =
  create: ()->
    canvas = getCurrentCanvas()
    w = canvas.w
    h = canvas.h
    off_y = canvas.offset_y
    calculated_tree = new TreeLayout(tree_data)
    fit_size = calculated_tree.size(w, h, off_y)
    node_list = []
    diag_list = []
    create_layer_node(fit_size, node_list, diag_list)
    compute_list = [
      text_svg 20, 30, 'Reingold Tilford Tree Layout', 'font-size: 3em;', null
      node_list...
      diag_list...
    ]
    frame compute_list, w, h

view =
  view: (ctrl, args)-> vm.create()

m.mount document.getElementById('contents'), m.component view
