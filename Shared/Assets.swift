//
//  Assets.swift
//  LD39
//
//  Created by Steve Johnson on 8/18/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit


protocol AssetClass {
  var x: CGFloat { get }
  var y: CGFloat { get }
}


class AssetBin<T: AssetClass> {
  let texture: SKTexture
  let size: CGFloat
  init(name: String, size: CGFloat) {
    self.texture = SKTexture(imageNamed: name)
    self.size = size
  }

  private func _tex(_ x: CGFloat, _ y: CGFloat) -> SKTexture {
    let texSize = self.texture.size()
    return SKTexture(
      rect: CGRect(
        origin: CGPoint(x: x * self.size / texSize.width, y: y * self.size / texSize.height),
        size: CGSize(width: size / texSize.width, height: size / texSize.height)),
      in: self.texture)
  }

  func get(_ t: T) -> SKTexture {
    return _tex(t.x, t.y)
  }
}

enum _Assets16: AssetClass {
  case ammo1, ammo2, powerupBattery, powerupHealth
  case bgHUD, bgGround, bgWall, bgDrain
  case mobButterfly, mobRabbit, mobTurtle1, mobTurtle2
  case player, exit

  var coord: (CGFloat, CGFloat) {
    switch self {
    case .ammo1: return (0, 3)
    case .ammo2: return (1, 3)
    case .powerupBattery: return (2, 3)
    case .powerupHealth: return (3, 3)
    case .bgHUD: return (0, 2)
    case .bgGround: return (1, 2)
    case .bgWall: return (2, 2)
    case .bgDrain: return (3, 2)
    case .mobButterfly: return (0, 1)
    case .mobRabbit: return (1, 1)
    case .mobTurtle1: return (2, 1)
    case .mobTurtle2: return (3, 1)
    case .player: return (0, 0)
    case .exit: return (1, 0)
    }
  }

  var x: CGFloat { return self.coord.0 }
  var y: CGFloat { return self.coord.1 }
}
let Assets16 = AssetBin<_Assets16>(name: "spritesheet-16", size: 16)
