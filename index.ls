#angular.module \main, <[ngDraggable]>
#  ..controller \main, <[$scope]> ++ ($scope, $firebaseArray) ->
angular.module \main, <[firebase ngDraggable]>
  ..controller \main, <[$scope $firebaseArray]> ++ ($scope, $firebaseArray) ->
    ref = new Firebase(\https://aidraw.firebaseio.com/layers)
    layers = $firebaseArray(ref)
    layers.$watch -> 
      if !$scope.nodes => $scope.nodes = $scope.layers.0
      build!

    [w,h,padding] = [1024, 600, 60]
    $scope.chosen = null
    $scope.layers = (if layers? => layers else [])
    #if $scope.layers.length == 0 => 
    #  $scope.layers.$add({points:[],stroke:\#000000,fill:\none})
      #$scope.layers.push {points:[],stroke:\#000000,fill:\none}
    $scope.set-close = -> 
      $scope.nodes.is-closed = !!!$scope.nodes.is-closed
      build!
    bcr = 4 * ( Math.sqrt(2) - 1 ) / 3
    $scope.addcircle = ->
      [mx,my,r] = [1024/2,600/2,50]
      ret = []
      for a from 0 til 6.28 by 6.28 / 4 => ret.push do
        anchor: [mx + r * Math.cos(a), my + r * Math.sin(a)]
        ctrl1: [
          Math.cos(a - 6.28 / 4) * r * bcr
          Math.sin(a - 6.28 / 4) * r * bcr
        ]
        ctrl2: [
          -Math.cos(a - 6.28 / 4) * r * bcr
          -Math.sin(a - 6.28 / 4) * r * bcr
        ]
      layer = $scope.layer.add!
      layer.is-closed = true
      layer.points = ret

    $scope.addsquare = ->
      [mx,my,r] = [1024/2,600/2,50]
      ret = [
        {anchor: [mx - r, my - r], ctrl1: [0,0], ctrl2: [0,0]}
        {anchor: [mx + r, my - r], ctrl1: [0,0], ctrl2: [0,0]}
        {anchor: [mx + r, my + r], ctrl1: [0,0], ctrl2: [0,0]}
        {anchor: [mx - r, my + r], ctrl1: [0,0], ctrl2: [0,0]}
      ]
      layer = $scope.layer.add!
      layer.is-closed = true
      layer.points = ret
    $scope.reorder = (s, d, e)->
      layer = $scope.layers.splice(s,1).0
      if d <= $scope.layers.length => $scope.layers.splice d, 0, layer
      else $scope.layers.push layer
    $scope.layer = do
      add: -> 
        ret = {points:[],stroke:\#000000,fill:\none}
        $scope.layers.$add ret
        $scope.layers.$save!
        ret
      remove: -> 
        if $scope.layers.length <=1 => return
        idx = $scope.layers.indexOf(@target)
        $scope.layers.$remove idx
        #$scope.layers.splice(idx,1)
        @target = $scope.layers[idx - 1 >? 0]
        @set(idx - 1 >? 0)
        $scope.layers.$save!
      set: -> 
        if typeof(it) == typeof(0) => @target = $scope.layers[it]
        else => @target = it
        $scope.nodes = @target
        build!
        $scope.path = ""
      target: $scope.layers.0
      buildall: ->
        for layer in $scope.layers =>
          points = layer.points or []
          if points.length == 0 => continue
          ret = getpath points, layer.is-closed
          layer.path = ret

    $scope.remove = -> 
      if typeof($scope.chosen)==typeof(1) and $scope.chosen < $scope.nodes.points.length =>
        #$scope.nodes.$remove $scope.chosen
        $scope.nodes.points.splice($scope.chosen,1)
        $scope.chosen = undefined
      else
        #$scope.nodes.$remove 0
        $scope.nodes.points.splice 0,1
      build!
    $scope.random = ->
      random!
      build!
    random = (key) ->
      ret = {}
      if typeof(key) != "undefined" =>
        ret.anchor = [
          padding + ( w - padding * 2 ) * ( key % 2),
          padding + key * 50
        ]
      else ret.anchor = [Math.random!*( w - padding * 2) + padding ,Math.random!*( h - padding * 2 ) + padding]
      ret.ctrl1 = [Math.random!*100 - 50, Math.random!*100 - 50]
      ret.ctrl2 = [Math.random!*100 - 50, Math.random!*100 - 50]
      #$scope.nodes.$add ret
      $scope.nodes.[]points.push ret
      $scope.layers.$save $scope.layers.indexOf($scope.nodes)
    #if $scope.nodes.length == 0 => for i from 0 til 6 => random i
    build = ->
      if !$scope.nodes or !$scope.nodes.points or $scope.nodes.points.length == 0 => return
      ret = getpath $scope.nodes.points, $scope.nodes.is-closed
      $scope.path = ret
      $scope.layer.buildall!
    getpath = (points, is-closed = false) ->
      ret = "M#{points.0.anchor.0} #{points.0.anchor.1}"
      last = points.0
      if is-closed => points = points ++ [points.0]
      for i from 1 til points.length =>
        item = points[i]
        c1x = last.anchor.0 + last.ctrl2.0
        c1y = last.anchor.1 + last.ctrl2.1
        c2x = item.anchor.0 + item.ctrl1.0
        c2y = item.anchor.1 + item.ctrl1.1
        ret += "C#{c1x} #{c1y} #{c2x} #{c2y} #{item.anchor.0} #{item.anchor.1}"
        last = item
      return ret
    $scope.$watch 'nodes', -> build!
    $scope.dragpath = {}
    $scope.ptrctrl = do
      down: (e) -> 
        node = $(e.target)
        if (node.attr(\class) or "").split(' ').indexOf(\ctrl) >= 0 =>
          $scope.ctrl = node.attr \ctrl
        while node
          if node.attr(\idx) => break
          if (node.attr(\class) or "").split(' ').indexOf(\activepath) >=0 => break
          node = $(node.parent!)
          if node.0.nodeName in <[BODY SVG]> => break

        if (node.attr(\class) or "").split(' ').indexOf(\activepath) >=0 => 
          $scope.dragpath.active = true
          $scope.dragpath.ptr = @map [e.offsetX, e.offsetY]
          $scope.dragpath.ptr.0 -= ($scope.nodes.{}offset.x or 0)
          $scope.dragpath.ptr.1 -= ($scope.nodes.{}offset.y or 0)
        else if node.attr(\idx) => $scope.idx = $scope.chosen = parseInt(that)

      map: ([x,y]) ->
        [w,h] = [ $(\svg).width!, $(\svg).height! ]
        [aw,ah] = [w,h]
        if w/h > 1024/600 => w = h * 1024 / 600
        else if w/h < 1024/600 => h = w * 600 / 1024
        [dx,dy] = [(aw - w)/2, (ah - h)/2]
        x = ( (x - dx) / w ) * 1024
        y = ( (y - dy) / h ) * 600
        [x,y]

      move: (e) -> 
        if !$scope.nodes => return
        [x,y] = [ e.offsetX, e.offsetY ]
        [x,y] = @map [x,y]
        if $scope.dragpath.active =>
          $scope.nodes.offset = {x: x - $scope.dragpath.ptr.0, y: y - $scope.dragpath.ptr.1}
          return
        if $scope.nodes.offset =>
          [x,y] = [x - ($scope.nodes.offset.x or 0), y - ($scope.nodes.offset.y or 0)]
        item = $scope.nodes.[]points[$scope.idx]
        if item and !$scope.ctrl =>
          item.anchor.0 = x
          item.anchor.1 = y
          build!
        if item and $scope.ctrl =>
          item["ctrl#{$scope.ctrl}"].0 = x - item.anchor.0
          item["ctrl#{$scope.ctrl}"].1 = y - item.anchor.1
          build!
        #$scope.layers.$save $scope.idx
      mup:  (e) -> 
        $scope.dragpath.active = false
        $scope.idx = null
        $scope.ctrl = null
      keydown: (e) ->
        keycode = e.keyCode or e.which
        if keycode == 8 => 
          e.prevent-default!
          $scope.remove!
      keypress: (e) ->
    ldColorPicker.init!
    $scope.color = do
      set-target: -> @target = it
      fill: \none
      stroke: \black
    $(\#fillbtn).0._ldcpnode._ldcp.on \change, (color) -> 
      #$("\##{$scope.color.target}btn").css({color:it})
      #$scope.$apply -> $scope.color[$scope.color.target] = color
      $scope.$apply -> if $scope.nodes and $scope.nodes[$scope.color.target] =>
        $scope.nodes[$scope.color.target] = color
