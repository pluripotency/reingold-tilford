
frame = (children, width, height, style="background-color: cornflowerblue")->
  m 'svg',
    x: 0
    y: 0
    width: width
    height: height
    style: style
  , children

rect = (x, y, stroke='white', width=50, height=20)->
  x_top = x-width/2
  y_top = y-height/2
  m 'rect',
    rx: 5
    x: x_top
    y: y_top
    width: width
    height: height
    stroke: stroke
    fill: 'darkblue'
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

get_root_position = (node)->
  if node.parent?
    get_root_position(node.parent)
  else
    [node.x, node.y]

textbox = (node, text, stroke, width=50, height=30)->
  x = node.x
  y = node.y
  [x0, y0] = get_root_position(node)
  m 'g',
    transform: "translate(#{x} #{y})"
  , [
      rect 0, 0, stroke, width, height
      text_svg 0, 0, text
      m 'animateTransform',
        attributeName: 'transform'
        type: 'translate'
        from: "#{x0} #{y0}"
        to: "#{x} #{y}"
        begin: "0s"
        dur: "500ms"
        repeatCount: 1
    ]

diag_v = (start_node, end_node, target_height=30)->
  start_x = start_node.x
  start_y = start_node.y
  [x0, y0] = get_root_position(start_node)
  end_x = end_node.x
  end_y = end_node.y
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
    stroke: 'white'
    fill: 'transparent'
    'stroke-width': 1.5
  , [
      m 'animate',
        attributeName: "d"
        from: "M#{x0},#{y0} C#{x0},#{y0} #{x0},#{y0} #{x0},#{y0}"
        to: "#{move_to_start} #{first} #{second} #{third}"
        dur: '500ms'
        repeatCount: 1
    ]
