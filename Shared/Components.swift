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
    sprite.text = " "
    sprite.label.color = SKColor.white
    sprite.backgroundColor = SKColor.black
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

  func animateAway() {
    let labelFade = SKAction.fadeAlpha(to: 0, duration: MOVE_TIME)
    let colorFade = SKAction.colorize(with: SKColor.black, colorBlendFactor: 1, duration: MOVE_TIME)

    guard let pos = node?.gridPosition, let sprite = scene?.gridSprite(at: pos) else { return }
    sprite.cover.run(colorFade)
    sprite.label.run(
      labelFade,
      completion: {
        sprite.label.text = " "
        sprite.label.color = SKColor.white
      })
  }
}


class SpriteSystem: GKComponentSystem<SpriteComponent> {
  override init() {
    super.init(componentClass: SpriteComponent.self)
  }

  override func removeComponent(_ component: SpriteComponent) {
    if component.shouldAnimateAway {
      component.animateAway(completion: { component.sprite.removeFromParent() })
    } else {
      component.sprite.removeFromParent()
    }
    super.removeComponent(component)
  }
}

class SpriteComponent: GKComponent {
  var shouldAnimateAway = true
  var sprite: SKNode

  required init(sprite: SKNode) {
    self.sprite = sprite
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func animateAway(completion: OptionalCallback) {
    guard shouldAnimateAway else { return }
    sprite.run(SKAction.fadeAlpha(to: 0, duration: MOVE_TIME), completion: { completion?() })
  }

  func nudge(_ direction: int2, completion: OptionalCallback) {
    let vector = CGPoint(
      x: CGFloat(direction.x) * sprite.frame.size.width / 4,
      y: -1 * CGFloat(direction.y) * sprite.frame.size.height / 4)
    let actionOut = SKAction.move(to: sprite.position + vector, duration: MOVE_TIME / 2)
    let actionIn = SKAction.move(to: sprite.position, duration: MOVE_TIME / 2)
    sprite.run(SKAction.sequence([actionOut, actionIn]), completion: { completion?() })
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

    if let sprite = self.entity?.sprite as? SKLabelNode {
      sprite.colorBlendFactor = 1 - getFractionRemaining()
    }
  }

  func heal(_ amount: CGFloat) {
    health = min(maxHealth, health + amount)

    if let sprite = self.entity?.sprite as? SKLabelNode {
      sprite.colorBlendFactor = 1 - getFractionRemaining()
    }
  }
}

class PickupConsumableComponent: GKComponent {
  var isPickedUp = false
}

class TakesUpSpaceComponent: GKComponent { }
class PlayerComponent: GKComponent { }

class AmmoComponent: GKComponent {
  var value: Int = 1

  convenience init(value: Int) {
    self.init()
    self.value = value
  }

  func add(value v: Int) {
    self.value += v
  }

  func empty() -> Int {
    let v = value
    self.value = 0
    return v
  }

  func transfer(from ammo: AmmoComponent) {
    self.add(value: ammo.empty())
  }
}

class BumpDamageComponent: GKComponent {
  var value: CGFloat = 20

  convenience init(value: CGFloat) {
    self.init()
    self.value = value
  }
}

class MoveTowardPlayerComponent: GKComponent {
  var vectors: [int2] = []

  convenience init(vectors: [int2]) {
    self.init()
    self.vectors = vectors
  }

  func getClosest(to target: int2, inGraph graph: GKGridGraph<GridNode>) -> GridNode? {
    guard let myPos = self.entity?.gridNode?.gridPosition else { return nil }
    var bestDist: CGFloat = 1000
    var bestNode: GridNode? = nil

    for v in vectors {
      let nextPos: int2 = myPos + v
      if graph.node(atGridPosition: nextPos) == nil {
        continue
      }
      let node = graph.node(atGridPosition: nextPos)!
      if node.entities.filter({ (e: GKEntity) -> Bool in return e.component(ofType: TakesUpSpaceComponent.self) != nil && e.component(ofType: PlayerComponent.self) == nil }).count > 0 {
        continue
      }
      let dx = CGFloat(nextPos.x - target.x)
      let dy = CGFloat(nextPos.y - target.y)
      let dist = sqrt(dx * dx + dy * dy)
      if dist < bestDist {
        bestDist = dist
        bestNode = node
      }
    }
    return bestNode
  }
}
