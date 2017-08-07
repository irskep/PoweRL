//
//  Swift+utils.swift
//  iOS
//
//  Created by Steve Johnson on 8/6/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import GameplayKit


extension UserDefaults {
  static var pwr_isMusicEnabled: Bool {
    // store inverted so default is true
    get { return !UserDefaults.standard.bool(forKey: "isMusicDisabled") }
    set { UserDefaults.standard.set(!newValue, forKey: "isMusicDisabled") }
  }
}

extension CGSize {
  var point: CGPoint { return CGPoint(x: width, y: height) }
}

extension CGPoint {
  init(_ position: int2) {
    self.init(x: CGFloat(position.x), y: CGFloat(position.y))
  }
}

extension int2 {
  init(_ point: CGPoint) {
    self.init(Int32(point.x), Int32(point.y))
  }
}

extension SKSpriteNode {
  func pixelized() -> SKSpriteNode {
    self.texture?.filteringMode = .nearest
    return self
  }

  func scaled(_ s: CGFloat) -> Self {
    self.setScale(s)
    return self
  }

  func withZ(_ z: CGFloat) -> Self {
    self.zPosition = z
    return self
  }
}

extension int2 {
  func manhattanDistanceTo(_ other: int2) -> Int {
    return abs(Int(self.x) - Int(other.x)) + abs(Int(self.y) - Int(other.y))
  }
}
