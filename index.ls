angular.module \main, <[firebase]>
  ..controller \main, <[$scope $firebaseArray]> ++ ($scope, $firebaseArray) ->
    ref = new Firebase(\https://aidraw.firebaseio.com/points)
    list = $firebaseArray(ref)
    list.$watch -> build!

    [w,h,padding] = [1024, 600, 60]
    $scope.chosen = null
    $scope.nodes = list
    $scope.remove = -> 
      if typeof($scope.chosen)==typeof(1) and $scope.chosen < $scope.nodes.length =>
        $scope.nodes.$remove $scope.chosen
        #$scope.nodes.splice($scope.chosen,1)
        $scope.chosen = undefined
      else
        $scope.nodes.$remove 0
        #$scope.nodes.splice 0,1
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
      $scope.nodes.$add ret
      #$scope.nodes.push ret
    #if $scope.nodes.length == 0 => for i from 0 til 6 => random i
    build = ->
      if $scope.nodes.length == 0 => return
      ret = "M#{$scope.nodes.0.anchor.0} #{$scope.nodes.0.anchor.1}"
      last = $scope.nodes.0
      for i from 1 til $scope.nodes.length =>
        item = $scope.nodes[i]
        c1x = last.anchor.0 + last.ctrl2.0
        c1y = last.anchor.1 + last.ctrl2.1
        c2x = item.anchor.0 + item.ctrl1.0
        c2y = item.anchor.1 + item.ctrl1.1
        ret += "C#{c1x} #{c1y} #{c2x} #{c2y} #{item.anchor.0} #{item.anchor.1}"
        last = item
      $scope.path = ret
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
        item = $scope.nodes[$scope.idx]
        if item and !$scope.ctrl =>
          item.anchor.0 = e.offsetX
          item.anchor.1 = e.offsetY
          build!
        if item and $scope.ctrl =>
          item["ctrl#{$scope.ctrl}"].0 = e.offsetX - item.anchor.0
          item["ctrl#{$scope.ctrl}"].1 = e.offsetY - item.anchor.1
          build!
        $scope.nodes.$save $scope.idx
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
      $scope.$apply -> $scope.color[$scope.color.target] = color
