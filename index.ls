#angular.module \main, <[ngDraggable]>
#  ..controller \main, <[$scope]> ++ ($scope, $firebaseArray) ->
angular.module \main, <[firebase ngDraggable]>
  ..controller \main, <[$scope $firebaseArray]> ++ ($scope, $firebaseArray) ->
    ref = new Firebase(\https://aidraw.firebaseio.com/layers)
    layers = $firebaseArray(ref)
    $scope.layerid = -1
    $scope.orders = -1
    $scope.opacity = 0.5
    $scope.preview = -> $scope.opacity = if $scope.opacity == 0.5 => 1 else 0.5
    layers.$watch -> 
      $scope.layers = layers
      if !$scope.nodes => $scope.nodes = $scope.layers.0
      $scope.layerid = Math.max.apply null, layers.map(->it.lid or -1)
      $scope.orders = Math.max.apply null, layers.map(->it.order or -1)
      for i from 0 til $scope.layers.length
        l = $scope.layers[i]
        if !(l.order?) => 
          l.order = ++$scope.orders
          $scope.layers.$save i
        if !(l.lid?) => 
          l.lid = ++$scope.layerid
          $scope.layers.$save i
      if $scope.nodes => 
        idx = $scope.layers.$indexFor $scope.nodes.$id
        if idx < 0 =>
          order = $scope.nodes
          min = dis: -1, idx: -1
          for idx from 0 til $scope.layers.length =>
            dis = Math.abs(order - $scope.layers[idx].order)
            if min.dis == -1 or dis < min.dis and dis > 0 => min <<< {dis, idx}
          $scope.layer.set min.idx
        else $scope.layer.set $scope.nodes

      else $scope.layer.set 0


      build!
    $scope.$watch 'nodes' -> $scope.range.update $scope.nodes
    [w,h,padding] = [1024, 600, 60]
    $scope.chosen = null
    $scope.layers = (if layers? => layers else [])
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
      (layer) <- $scope.layer.add
      idx = $scope.layers.$indexFor layer
      layer.is-closed = true
      layer.points = ret
      $scope.layers.$save idx
      $scope.layer.set layer
      build!

    $scope.addsquare = ->
      [mx,my,r] = [1024/2,600/2,50]
      ret = [
        {anchor: [mx - r, my - r], ctrl1: [0,0], ctrl2: [0,0]}
        {anchor: [mx + r, my - r], ctrl1: [0,0], ctrl2: [0,0]}
        {anchor: [mx + r, my + r], ctrl1: [0,0], ctrl2: [0,0]}
        {anchor: [mx - r, my + r], ctrl1: [0,0], ctrl2: [0,0]}
      ]
      (layer) <- $scope.layer.add
      layer.is-closed = true
      layer.points = ret
    $scope.reorder = (s, d, e)->
      #$scope.layers.filter(->it.order == s)
      #s2 = $scope.layers[s].order
      s = $scope.layers.filter(-> it.lid == s).0.order
      des = null
      des-idx = -1
      for i from 0 til $scope.layers.length
        l = $scope.layers[i]
        if l.order == s => 
          des = l
          des-idx = i
        if l.order > s => 
          l.order--
          $scope.layers.$save i
      for i from 0 til $scope.layers.length
        l = $scope.layers[i]
        if l.order >= d =>
          l.order++
          $scope.layers.$save i
      des.order = d
      $scope.layers.$save des-idx
    $scope.layer = do
      clone: ->
        ret = {} <<< $scope.nodes{stroke,fill,is-closed}
        ret.points = [{
          anchor: it.anchor.slice!, ctrl1: it.ctrl1.slice!, ctrl2: it.ctrl2.slice!
        } for it in $scope.nodes.[]points]
        ret.order = ++$scope.orders
        ret.lid = ++$scope.layerid
        ret.offset = {} <<< $scope.nodes.offset
        ret.offset.x += Math.random! * 50 + 20
        ret.offset.y += Math.random! * 50 + 20
        $scope.layers.$add ret .then (ref) ->
          $scope.layer.set $scope.layers[$scope.layers.$indexFor(ref.key!)]
      add: (cb=null,active=true) -> 
        ret = {points:[],stroke:\#000000,fill:\#eeeeee, order: ++$scope.orders, lid: ++$scope.layerid}
        $scope.layers.$add ret .then (ref) -> 
          idx = $scope.layers.$indexFor ref.key!
          obj = $scope.layers[idx]
          if active => $scope.layer.set obj
          if cb => cb obj

      remove: -> 
        if $scope.layers.length <=1 => return
        order = @target.order
        <~ $scope.layers.$remove @target .then

        min = dis: -1, idx: -1
        for idx from 0 til $scope.layers.length =>
          dis = Math.abs(order - $scope.layers[idx].order)
          if min.dis == -1 or dis < min.dis and dis > 0 => min <<< {dis, idx}
        @target = $scope.layers[min.idx]
        @set @target

      set: -> 
        if typeof(it) == typeof(0) => @target = $scope.layers[it]
        else => @target = it
        $scope.nodes = @target
        $scope.range.update $scope.nodes
        $scope.path = ""
        build!
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
      $scope.range.update $scope.nodes
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
        if (node.attr(\range)) => $scope.range.idx = parseInt(node.attr(\range))
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

      remap: ([x,y], os) ->
        rg = $scope.range
        dx2 = rg.xd - rg.xc
        dy2 = rg.yd - rg.yc
        dx1 = rg.xb - rg.xa
        dy1 = rg.yb - rg.ya
        if dx1 != 0 => x = (( os.x + x - rg.xa ) * dx2 / dx1) + rg.xc - os.x
        if dy1 != 0 => y = (( os.y + y - rg.ya ) * dy2 / dy1) + rg.yc - os.y
        [x,y]
      move: (e) -> 
        if !$scope.nodes => return
        [x,y] = [ e.offsetX, e.offsetY ]
        [x,y] = @map [x,y]
        if $scope.range.idx =>
          idx = $scope.range.idx
          rg = $scope.range
          rx = [rg.xc, rg.xd]
          ry = [rg.yc, rg.yd]
          xp = if idx % 2 => 0 else 1
          yp = if parseInt((idx - 1) / 2) => 1 else 0
          rx[xp] = x
          ry[yp] = y
          if rx.1 <= rx.0 + 10 => rx.1 = rx.0 + 11
          if ry.1 <= ry.0 + 10 => ry.1 = ry.0 + 11
          [rg.xc, rg.xd, rg.yc, rg.yd] = [rx.0, rx.1, ry.0, ry.1]

          os = $scope.nodes.offset
          for p in $scope.nodes.points =>
            p.ctrl1 = @remap([p.ctrl1.0 + p.anchor.0, p.ctrl1.1 + p.anchor.1], os)
            p.ctrl2 = @remap([p.ctrl2.0 + p.anchor.0, p.ctrl2.1 + p.anchor.1], os)
            p.anchor = @remap(p.anchor, os)
            p.ctrl1 = [p.ctrl1.0 - p.anchor.0, p.ctrl1.1 - p.anchor.1]
            p.ctrl2 = [p.ctrl2.0 - p.anchor.0, p.ctrl2.1 - p.anchor.1]
          [rg.xa, rg.xb, rg.ya, rg.yb] = [rg.xc, rg.xd, rg.yc, rg.yd]
          build!
          return
        if $scope.dragpath.active =>
          $scope.nodes.offset = {x: x - $scope.dragpath.ptr.0, y: y - $scope.dragpath.ptr.1}
          $scope.range.update $scope.nodes
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
        $scope.range.idx = 0
        $scope.dragpath.active = false
        $scope.idx = null
        $scope.ctrl = null
        $scope.layers.$save $scope.layers.indexOf($scope.nodes)
        $scope.range.update $scope.nodes
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
      $scope.layers.$save $scope.layers.indexOf($scope.nodes)

    $scope.range = do
      idx: 0
      xa: 10
      ya: 10
      xb: 100
      yb: 100

      xc: 10
      yc: 10
      xd: 100
      yd: 100
      show: false
      update: (node) ->
        if !node =>
          @show = false
          return
        if node.[]points.length =>
          @show = true
          ps = node.points
          os = node.{}offset
          rg = $scope.range
          [rg.xa, rg.xb, rg.ya, rg.yb] = [
            ps.0.anchor.0,
            ps.0.anchor.0, 
            ps.0.anchor.1,
            ps.0.anchor.1
          ]
          for i from 0 til ps.length  =>
            a = ps[i].anchor
            if a.0 < rg.xa => rg.xa = a.0
            if a.0 > rg.xb => rg.xb = a.0
            if a.1 < rg.ya => rg.ya = a.1
            if a.1 > rg.yb => rg.yb = a.1
          rg.xa += os.x or 0
          rg.xb += os.x or 0
          rg.ya += os.y or 0
          rg.yb += os.y or 0
          rg.xa -= 5
          rg.ya -= 5
          rg.xb += 5
          rg.yb += 5
          [rg.xc, rg.xd, rg.yc, rg.yd] = [rg.xa, rg.xb, rg.ya, rg.yb]
    $('[data-toggle="tooltip"]').tooltip!
