//
//  Bresenham.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

typealias intPoint = (x:Int, y:Int)

func internalBresenham(_ p1: intPoint, _ p2: intPoint, _ steep: Bool) -> [intPoint] {
  let dX = p2.x - p1.x
  let dY = p2.y - p1.y

  var points:[intPoint] = []

  let yStep           = (dY >= 0) ? 1 : -1
  let slope           = abs(Float(dY)/Float(dX))
  var error:Float     = 0
  var x               = p1.x
  var y               = p1.y

  points.append(steep ? (y, x) : (x, y))
  while x <= p2.x {
    x += 1
    error += slope
    if (error >= 0.5) {
      y += yStep
      error -= 1
    }
    points.append(steep ? (y, x) : (x, y))
  }

  return points
}

//Was just for tests
func iround(_ v: CGFloat) -> Int {
  return Int(v)
}

func bresenham(_ P1: CGPoint, _ P2: CGPoint) -> [intPoint] {

  var p1 = intPoint(iround(P1.x), iround(P1.y))
  var p2 = intPoint(iround(P2.x), iround(P2.y))

  //We need to handle the different octants differently
  let steep = abs(p2.y-p1.y) > abs(p2.x-p1.x)
  if steep {
    //Swizzle stuff around
    p1 = intPoint(x: p1.y, y: p1.x)
    p2 = intPoint(x: p2.y, y: p2.x)
  }
  if p2.x < p1.x {
    let tmp = p1
    p1 = p2
    p2 = tmp
  }

  return internalBresenham(p1, p2, steep)
}
