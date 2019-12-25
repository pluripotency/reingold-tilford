computeHeight = (node)->
  height = 0
  node.height = height
  while node.parent? and node.height < height
    node = node.parent
    height++
    node.height = height

class Node
  constructor: (data)->
    @data = data
    @depth = @height = 0
    @parent = null

  eachAfter: (callback)=>
    node = this
    nodes = [ node ]
    next = []
    while node = nodes.pop()
      next.push(node)
      children = node.children
      if children
        i = 0
        n = children.length
        while i < n
          nodes.push children[i]
          ++i
    while node = next.pop()
      callback node
    this

  eachBefore: (callback)=>
    node = this
    nodes = [ node ]
    children = undefined
    i = undefined
    while node = nodes.pop()
      callback(node)
      children = node.children
      if children
        i = children.length - 1
        while i >= 0
          nodes.push children[i]
          --i
    this

hierarchy = (data, children) ->
  root = new Node(data)
  valued = +data.value and (root.value = data.value)
  node = undefined
  nodes = [ root ]
  child = undefined
  childs = undefined
  i = undefined
  n = undefined
  while node = nodes.pop()
    if valued
      node.value = +node.data.value
    if (childs = node.data.children) and (n = childs.length)
      node.children = new Array(n)
      i = n - 1
      while i >= 0
        nodes.push child = node.children[i] = new Node(childs[i])
        child.parent = node
        child.depth = node.depth + 1
        --i
  root.eachBefore computeHeight



defaultSeparation = (a, b) -> if a.parent == b.parent then 1 else 2

# function radialSeparation(a, b) {
#   return (a.parent === b.parent ? 1 : 2) / a.depth;
# }
# This function is used to traverse the left contour of a subtree (or
# subforest). It returns the successor of v on this contour. This successor is
# either given by the leftmost child of v or by the thread of v. The function
# returns null if and only if v is on the highest level of its subtree.

nextLeft = (v) -> if v.children? then v.children[0] else v.t

# This function works analogously to nextLeft.

nextRight = (v) -> if v.children? then v.children[v.children.length - 1] else v.t

# Shifts the current subtree rooted at w+. This is done by increasing
# prelim(w+) and mod(w+) by shift.

moveSubtree = (wm, wp, shift) ->
  change = shift / (wp.i - (wm.i))
  wp.c -= change
  wp.s += shift
  wm.c += change
  wp.z += shift
  wp.m += shift

# All other shifts, applied to the smaller subtrees between w- and w+, are
# performed by this function. To prepare the shifts, we have to adjust
# change(w+), shift(w+), and change(w-).

executeShifts = (v) ->
  shift = 0
  change = 0
  children = v.children
  i = children.length
  w = undefined
  while --i >= 0
    w = children[i]
    w.z += shift
    w.m += shift
    shift += w.s + (change += w.c)

# If vi-’s ancestor is a sibling of v, returns vi-’s ancestor. Otherwise,
# returns the specified (default) ancestor.

nextAncestor = (vim, v, ancestor) -> if vim.a.parent == v.parent then vim.a else ancestor

TreeNode = (node, i) ->
  @_ = node
  @parent = null
  @children = null
  @A = null # default ancestor
  @a = this # ancestor
  @z = 0    # prelim
  @m = 0    # mod
  @c = 0    # change
  @s = 0    # shift
  @t = null # thread
  @i = i    # number

treeRoot = (root) ->
  tree = new TreeNode(root, 0)
  node = undefined
  nodes = [ tree ]
  child = undefined
  children = undefined
  i = undefined
  n = undefined
  while node = nodes.pop()
    if children = node._.children
      node.children = new Array(n = children.length)
      i = n - 1
      while i >= 0
        nodes.push child = node.children[i] = new TreeNode(children[i], i)
        child.parent = node
        --i
  (tree.parent = new TreeNode(null, 0)).children = [ tree ]
  tree

TreeNode::eachAfter = (callback) ->
  nodes = [@]
  next = []
  while node = nodes.pop()
    next.push(node)
    children = node.children
    if children
      i = 0
      n = children.length
      while i < n
        nodes.push children[i]
        ++i
  while node = next.pop()
    callback node
  @

TreeNode::eachBefore = (callback) ->
  nodes = [@]
  while node = nodes.pop()
    callback(node)
    children = node.children
    if children
      i = children.length - 1
      while i >= 0
        nodes.push children[i]
        --i
  @


apportion = (v, w, ancestor)->
  separation = defaultSeparation
  if w
    vip = v
    vop = v
    vim = w
    vom = vip.parent.children[0]
    sip = vip.m
    sop = vop.m
    sim = vim.m
    som = vom.m
    shift = null
    func = ()->
      vom = nextLeft(vom)
      vop = nextRight(vop)
      vop.a = v
      shift = vim.z + sim - vip.z - sip + separation(vim._, vip._)
      if shift > 0
        moveSubtree(nextAncestor(vim, v, ancestor), v, shift)
        sip += shift
        sop += shift
      sim += vim.m
      sip += vip.m
      som += vom.m
      sop += vop.m
      return
    func() while (vim = nextRight(vim); vip = nextLeft(vip); vim and vip)

    if (vim and !nextRight(vop)) 
      vop.t = vim
      vop.m += sim - sop

    if (vip and !nextLeft(vom)) 
      vom.t = vip
      vom.m += sip - som
      ancestor = v
  ancestor


#```
#function apportion(v, w, ancestor) {
#  var separation = defaultSeparation
#  if (w) {
#    var vip = v,
#        vop = v,
#        vim = w,
#        vom = vip.parent.children[0],
#        sip = vip.m,
#        sop = vop.m,
#        sim = vim.m,
#        som = vom.m,
#        shift;
#    while (vim = nextRight(vim), vip = nextLeft(vip), vim && vip) {
#      vom = nextLeft(vom);
#      vop = nextRight(vop);
#      vop.a = v;
#      shift = vim.z + sim - vip.z - sip + separation(vim._, vip._);
#      if (shift > 0) {
#        moveSubtree(nextAncestor(vim, v, ancestor), v, shift);
#        sip += shift;
#        sop += shift;
#      }
#      sim += vim.m;
#      sip += vip.m;
#      som += vom.m;
#      sop += vop.m;
#    }
#    if (vim && !nextRight(vop)) {
#      vop.t = vim;
#      vop.m += sim - sop;
#    }
#    if (vip && !nextLeft(vom)) {
#      vom.t = vip;
#      vom.m += sip - som;
#      ancestor = v;
#    }
#  }
#  return ancestor;
#}
#```

# Node-link tree diagram using the Reingold-Tilford "tidy" algorithm

tree_layout = ->
  separation = defaultSeparation
  dx = 1
  dy = 1
  nodeSize = null

  tree = (root) ->
    t = treeRoot(root)
    # Compute the layout using Buchheim et al.’s algorithm.
    t.eachAfter(firstWalk)
    t.parent.m = -t.z
    t.eachBefore secondWalk
    # If a fixed node size is specified, scale x and y.
    if nodeSize
      root.eachBefore sizeNode
    else
      left = root
      right = root
      bottom = root
      root.eachBefore (node) ->
        if node.x < left.x
          left = node
        if node.x > right.x
          right = node
        if node.depth > bottom.depth
          bottom = node
      s = if left == right then 1 else separation(left, right) / 2
      tx = s - (left.x)
      kx = dx / (right.x + s + tx)
      ky = dy / (bottom.depth or 1)
      root.eachBefore (node) ->
        node.x = (node.x + tx) * kx
        node.y = node.depth * ky
    root

  # Computes a preliminary x-coordinate for v. Before that, FIRST WALK is
  # applied recursively to the children of v, as well as the function
  # APPORTION. After spacing out the children by calling EXECUTE SHIFTS, the
  # node v is placed to the midpoint of its outermost children.

  firstWalk = (v) ->
    children = v.children
    siblings = v.parent.children
    w = if v.i then siblings[v.i - 1] else null
    if children
      executeShifts v
      midpoint = (children[0].z + children[children.length - 1].z) / 2
      if w
        v.z = w.z + separation(v._, w._)
        v.m = v.z - midpoint
      else
        v.z = midpoint
    else if w
      v.z = w.z + separation(v._, w._)
    v.parent.A = apportion(v, w, v.parent.A or siblings[0])

  # Computes all real x-coordinates by summing up the modifiers recursively.

  secondWalk = (v) ->
    v._.x = v.z + v.parent.m
    v.m += v.parent.m

  # The core of the algorithm. Here, a new subtree is combined with the
  # previous subtrees. Threads are used to traverse the inside and outside
  # contours of the left and right subtree up to the highest common level. The
  # vertices used for the traversals are vi+, vi-, vo-, and vo+, where the
  # superscript o means outside and i means inside, the subscript - means left
  # subtree and + means right subtree. For summing up the modifiers along the
  # contour, we use respective variables si+, si-, so-, and so+. Whenever two
  # nodes of the inside contours conflict, we compute the left one of the
  # greatest uncommon ancestors using the function ANCESTOR and call MOVE
  # SUBTREE to shift the subtree and prepare the shifts of smaller subtrees.
  # Finally, we add a new thread (if necessary).


  sizeNode = (node) ->
    node.x *= dx
    node.y = node.depth * dy

  tree.separation = (x) ->
    if arguments.length
      separation = x
      tree
    else
      separation

  tree.size = (x) ->
    if arguments.length
      nodeSize = false
      dx = +x[0]
      dy = +x[1]
      tree
    else if nodeSize then null else [
        dx
        dy
      ]

  tree.nodeSize = (x) ->
    if arguments.length
      nodeSize = true
      dx = +x[0]
      dy = +x[1]
      tree
    else if nodeSize
      [
        dx
        dy
      ]
    else null

  tree


frame = (children, width=100, height=60, style="background-color: cornflowerblue")->
  m 'svg',
    x: 0
    y: 0
    width: width
    height: height
    style: style
  , children

rect = (x, y, width=50, height=20)->
  x_top = x-width/2
  y_top = y-height/2
  m 'rect',
    rx: 5
    x: x_top
    y: y_top
    width: width
    height: height
    stroke: 'white'
    fill: 'darkslategray'
    'stroke-width': 2

text_svg = (x, y, text, style="font-size: 1em;", anchor='middle')->
  m 'text',
      x: x
      y: y
      'text-anchor': anchor
      'dominant-baseline': 'central'
      fill: 'white'
      style: style
    , text

textbox = (x, y, text, width=50, height=20)->
  [
    rect x, y, width, height
    text_svg x, y, text
  ]

diag_v = (start_x, start_y, end_x, end_y, target_height=20)->
  if start_y < end_y
    start_y = start_y+target_height/2
    end_y = end_y-target_height/2
  else
    start_y = start_y-target_height/2
    end_y = end_y+target_height/2
  move_to_start = "M#{start_x},#{start_y}"
  first = "C#{start_x},#{(end_y-start_y)/2+start_y}"
  second = "#{end_x},#{(end_y-start_y)/2+start_y}"
  third = "#{end_x},#{end_y}"
  m 'path',
    d: "#{move_to_start} #{first} #{second} #{third}"
    stroke: 'yellowgreen'
    fill: 'transparent'
    'stroke-width': 1.5

tree_data =
  children: [
    children: [
      children: []
    ,
      children: [
        children: []
      ,
        children: []
      ,
        children: []
      ]
    ,
      children: [
        children: []
      ,
        children: []
      ,
        children: []
      ,
        children: []
      ,
        children: []
      ]
    ,
      children: []
    ]
  ,
    children: [
      children: [
        children: []
      ,
        children: []
      ]

    ]
  ,
    children: [
      children: []
    ,
      children: []
    ]
  ]
root = hierarchy(tree_data)

getCurrentCanvas = ->
  mar = [
    0 # top
    0 # left
    0 # right
    4 # bottom
  ]
  #mar = [
  #  10 # top
  #  5 # left
  #  5 # right
  #  10 # bottom
  #]
  win_w = window.innerWidth
  win_h = window.innerHeight
  w = win_w - mar[1] - mar[2]
  h = win_h - mar[0] - mar[3]
  {
    margin: mar
    win_w: win_w
    win_h: win_h
    w: w
    h: h
    offset_y: 20
  }

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


create_layer_node = (node, node_list, name, offset_y)->
  node_list.push textbox(node.x, node.y+offset_y, name)
  len = node_list.length
  if node.children?
    node.children.map (child, i)->
      node_list.push diag_v(node.x, node.y+offset_y, child.x, child.y+offset_y)
      create_layer_node child, node_list, len+i, offset_y

vm =
  create: ()->
    canvas = getCurrentCanvas()
    w = canvas.w
    h = canvas.h
    off_y = canvas.offset_y
    created = tree_layout().size([w, h-off_y*2])(root)
    node_list = [
      text_svg 10, 20, 'Reingold Tilford Tree Layout', 'font-size: 1.2em;', null
    ]
    create_layer_node(created, node_list, 1, off_y)
    frame node_list, w, h

TreeLayout =
  controller: (args)->
    vm
  view: (ctrl, args)->
    m 'div', ctrl.create()

m.mount document.getElementById('contents'), m.component TreeLayout
