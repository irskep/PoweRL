//
//  Components.swift
//  macOS
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit


class GridNode: GKGridGraphNode {
  var entities: [GKEntity] = []

  func add(_ entity: GKEntity) {
    entities.append(entity)
  }

  func remove(_ entity: GKEntity) {
    entities = entities.filter({ $0 != entity })
  }
}
func +(left: int2, right: int2) -> int2 {
  return int2(left.x + right.x, left.y + right.y)
}

class GridNodeComponent: GKComponent {
  private var _gridNode: GridNode?
  var gridNode: GridNode? {
    get { return _gridNode }
    set {
      if let e = self.entity {
        _gridNode?.remove(e)
        newValue?.add(e)
      }
      _gridNode = newValue
    }
  }

  convenience init(gridNode: GridNode?) {
    self.init()
    self.gridNode = gridNode
  }
}

class SpriteComponent: GKComponent {
  var sprite: SKNode

  required init(sprite: SKNode) {
    self.sprite = sprite
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class MassComponent: GKComponent {
  var weight: CGFloat = 0

  convenience init(weight: CGFloat) {
    self.init()
    self.weight = weight
  }
}

class HealthComponent: GKComponent {
  var health: CGFloat = 0
  var maxHealth: CGFloat = 0
  var isDead: Bool { return health <= 0 }

  convenience init(health: CGFloat) {
    self.init()
    self.health = health
    self.maxHealth = health
  }

  func getFractionRemaining() -> CGFloat { return health / maxHealth }

  func hit(_ amount: CGFloat) {
    health = max(0, health - amount)
  }

  func heal(_ amount: CGFloat) {
    health = min(maxHealth, health + amount)
  }
}

class PowerComponent: GKComponent {
  var power: CGFloat = 0
  var maxPower: CGFloat = 0
  var isBattery: Bool = false
  var isFull: Bool { return power >= maxPower }

  convenience init(power: CGFloat, isBattery: Bool) {
    self.init()
    self.power = power
    self.maxPower = power
    self.isBattery = isBattery
  }

  func getFractionRemaining() -> CGFloat { return power / maxPower }

  func getPowerRequired(toMove distance: CGFloat) -> CGFloat {
    return ((self.entity as? Actor)?.massC.weight ?? 0) * 0.01
  }

  func canUse(_ amount: CGFloat) -> Bool {
    return power >= amount
  }

  func use(_ amount: CGFloat) -> Bool {
    if !canUse(amount) { return false }
    power -= amount
    return true
  }

  func charge(_ amount: CGFloat) {
    power = min(maxPower, power + amount)
  }

  func discharge() -> CGFloat {
    let p = power
    power = 0
    return p
  }
}
