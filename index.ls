angular.module \main, <[firebase]>
  ..controller \main, <[$scope $firebaseArray]> ++ ($scope, $firebaseArray) ->
    #ref = new Firebase(\https://aidraw.firebaseio.com/layers)
    #layers = $firebaseArray(ref)
    #layers.$watch -> build!
    #list = []
    #if layers.length == 0 => layers.$add(list)

    [w,h,padding] = [1024, 600, 60]
    $scope.chosen = null
    $scope.layers = [{points:[],stroke:\#000000,fill:\none}]
    $scope.nodes = $scope.layers.0
    $scope.layer = do
      add: -> $scope.layers.push {points:[],stroke:\#000000,fill:\none}
      remove: -> 
        if $scope.layers.length <=1 => return
        idx = $scope.layers.indexOf(@target)
        $scope.layers.splice(idx,1)
        @target = $scope.layers[idx - 1 >? 0]
        @set(idx - 1 >? 0)
      set: -> 
        if typeof(it) == typeof(0) => @target = $scope.layers[it]
        else => @target = it
        $scope.nodes = @target
      target: $scope.layers.0
      buildall: ->
        for layer in $scope.layers =>
          points = layer.points
          if points.length == 0 => continue
          ret = getpath points
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
      $scope.nodes.points.push ret
    #if $scope.nodes.length == 0 => for i from 0 til 6 => random i
    build = ->
      if $scope.nodes.points.length == 0 => return
      ret = getpath $scope.nodes.points
      $scope.path = ret
      $scope.layer.buildall!
    getpath = (points) ->
      ret = "M#{points.0.anchor.0} #{points.0.anchor.1}"
      last = points.0
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
    $scope.ptrctrl = do
      down: (e) -> 
        node = $(e.target)
        if (node.attr(\class) or "").split(' ').indexOf(\ctrl) >= 0 =>
          $scope.ctrl = node.attr \ctrl
        while node
          if node.attr(\idx) => break
          node = $(node.parent!)
          if node.0.nodeName in <[BODY SVG]> => break
        if node.attr(\idx) => $scope.idx = $scope.chosen = parseInt(that)
      move: (e) -> 
        [x,y] = [ e.offsetX, e.offsetY ]
        [w,h] = [ $(\svg).width!, $(\svg).height! ]
        [aw,ah] = [w,h]
        if w/h > 1024/600 => w = h * 1024 / 600
        else if w/h < 1024/600 => h = w * 600 / 1024
        [dx,dy] = [(aw - w)/2, (ah - h)/2]
        x = ( (x - dx) / w ) * 1024
        y = ( (y - dy) / h ) * 600
        item = $scope.nodes.points[$scope.idx]
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
      console.log $scope.color.target, color
      #$scope.$apply -> $scope.color[$scope.color.target] = color
      $scope.$apply -> 
        $scope.nodes[$scope.color.target] = color
