
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

textbox = (x, y, text, stroke='white', width=50, height=20)->
  [
    rect x, y, stroke, width, height
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

