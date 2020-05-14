class Node
  constructor: (@data)->
    @depth = 0
    @parent = null

  eachBefore: (callback)=>
    nodes = [ @ ]
    while node = nodes.pop()
      callback(node)
      if children = node.children
        i = children.length - 1
        while i >= 0
          nodes.push children[i]
          --i
    @

hierarchy = (data) ->
  root = new Node(data)
  nodes = [ root ]
  while node = nodes.pop()
    if (children = node.data.children) and (n = children.length)
      node.children = new Array(n)
      i = n - 1
      while i >= 0
        nodes.push child = node.children[i] = new Node(children[i])
        child.parent = node
        child.depth = node.depth + 1
        --i
  root


defaultSeparation = (a, b) -> if a.parent == b.parent then 1 else 1.5

#radialSeparation = (a, b)-> if a.parent == b.parent then 1/a.depth else 2/a.depth
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
  @a = @    # ancestor
  @z = 0    # prelim
  @m = 0    # mod
  @c = 0    # change
  @s = 0    # shift
  @t = null # thread
  @i = i    # number

treeRoot = (root) ->
  tree = new TreeNode(root, 0)
  nodes = [ tree ]
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
    if children = node.children
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
    if children = node.children
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

# Node-link tree diagram using the Reingold-Tilford "tidy" algorithm

class TreeLayout
  constructor: (tree_data)->
    @root = hierarchy(tree_data)
    @separation = defaultSeparation
    t = treeRoot @root
    # Compute the layout using Buchheim et al.’s algorithm.
    t.eachAfter @firstWalk
    t.parent.m = -t.z
    t.eachBefore @secondWalk

# Computes a preliminary x-coordinate for v. Before that, FIRST WALK is
# applied recursively to the children of v, as well as the function
# APPORTION. After spacing out the children by calling EXECUTE SHIFTS, the
# node v is placed to the midpoint of its outermost children.
  firstWalk: (v)=>
    children = v.children
    siblings = v.parent.children
    w = if v.i then siblings[v.i - 1] else null
    if children
      executeShifts v
      midpoint = (children[0].z + children[children.length - 1].z) / 2
      if w
        v.z = w.z + @separation(v._, w._)
        v.m = v.z - midpoint
      else
        v.z = midpoint
    else if w
      v.z = w.z + @separation(v._, w._)
    v.parent.A = apportion(v, w, v.parent.A or siblings[0])

# Computes all real x-coordinates by summing up the modifiers recursively.
  secondWalk: (v)=>
    v._.x = v.z + v.parent.m
    v.m += v.parent.m

# If a fixed node size is specified, scale x and y.
  size: (size_x, size_y)=>
    left = @root
    right = @root
    bottom = @root
    @root.eachBefore (node) ->
      if node.x < left.x
        left = node
      if node.x > right.x
        right = node
      if node.depth > bottom.depth
        bottom = node
    s = if left == right then 1 else @separation(left, right) / 2
    tx = s - (left.x)
    kx = size_x / (right.x + s + tx)
    ky = size_y / (bottom.depth or 1)
    @root.eachBefore (node) ->
      node.x = (node.x + tx) * kx
      node.y = node.depth * ky
    @root

