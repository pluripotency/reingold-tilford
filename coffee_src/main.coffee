
getCurrentCanvas = ->
  w: window.innerWidth
  h: window.innerHeight
  offset_y: 20

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

create_layer_node = (node, node_list, diag_list, offset_y)->
  len = node_list.length
  if node.data.name?
    tb = textbox(node.x, node.y+offset_y, node.data.name, 'red')
  else
    tb = textbox(node.x, node.y+offset_y, len)
  node_list.push tb
  if node.children?
    node.children.map (child, i)->
      diag_list.push diag_v(node.x, node.y+offset_y, child.x, child.y+offset_y)
      create_layer_node child, node_list, diag_list, offset_y

vm =
  create: ()->
    canvas = getCurrentCanvas()
    w = canvas.w
    h = canvas.h
    off_y = canvas.offset_y
    calculated_tree = new TreeLayout(tree_data)
    fit_size = calculated_tree.size(w, h-off_y*2)
    node_list = []
    diag_list = []
    create_layer_node(fit_size, node_list, diag_list, off_y)
    compute_list = [
      text_svg 10, 20, 'Reingold Tilford Tree Layout', 'font-size: 1.2em;', null
      node_list...
      diag_list...
    ]
    frame compute_list, w, h

view =
  view: (ctrl, args)-> vm.create()

m.mount document.getElementById('contents'), m.component view
