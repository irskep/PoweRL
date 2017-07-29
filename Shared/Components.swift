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
  var entities = Set<GKEntity>()

  func add(_ entity: GKEntity) {
    entities.insert(entity)
  }

  func remove(_ entity: GKEntity) {
    entities.remove(entity)
  }
}
func +(left: int2, right: int2) -> int2 {
  return int2(left.x + right.x, left.y + right.y)
}


class GridSystem: GKComponentSystem<GridNodeComponent> {
  override init() {
    super.init(componentClass: GridNodeComponent.self)
  }

  override func addComponent(_ component: GridNodeComponent) {
    super.addComponent(component)
    if let e = component.entity { component.gridNode?.add(e) }
  }

  override func removeComponent(_ component: GridNodeComponent) {
    super.removeComponent(component)
    if let e = component.entity { component.gridNode?.remove(e) }
  }
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

  override func didAddToEntity() {
    guard let entity = entity else { return }
    _gridNode?.add(entity)
  }

  override func willRemoveFromEntity() {
    guard let entity = entity else { return }
    _gridNode?.remove(entity)
  }
}

class GridSpriteSystem: GKComponentSystem<GridSpriteComponent> {
  override init() {
    super.init(componentClass: GridSpriteComponent.self)
  }

  override func addComponent(_ component: GridSpriteComponent) {
    super.addComponent(component)
    guard let pos = component.node?.gridPosition, let sprite = component.scene?.gridSprite(at: pos) else { return }
    sprite.text = component.text
    sprite.label.color = component.color ?? SKColor.white
    sprite.backgroundColor = component.bkColor
  }

  override func removeComponent(_ component: GridSpriteComponent) {
    super.removeComponent(component)
    guard let pos = component.node?.gridPosition, let sprite = component.scene?.gridSprite(at: pos) else { return }
    sprite.text = nil
    sprite.label.color = SKColor.white
    sprite.backgroundColor = nil
  }
}

class GridSpriteComponent: GKComponent {
  weak var scene: MapScene?
  weak var node: GridNode?
  var text: String?
  var color: SKColor?
  var bkColor: SKColor?

  convenience init(_ scene: MapScene, _ node: GridNode, _ text: String, _ color: SKColor, _ bkColor: SKColor? = nil) {
    self.init()
    self.scene = scene
    self.node = node
    self.text = text
    self.color = color
    self.bkColor = bkColor
  }
}


class SpriteSystem: GKComponentSystem<SpriteComponent> {
  override init() {
    super.init(componentClass: SpriteComponent.self)
  }

  override func removeComponent(_ component: SpriteComponent) {
    component.sprite.removeFromParent()
    super.removeComponent(component)
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

class PickupConsumableComponent: GKComponent {
  var isPickedUp = false
}
