//
//  Components.swift
//  macOS
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit

// MARK: grid
func +(left: int2, right: int2) -> int2 {
  return int2(left.x + right.x, left.y + right.y)
}
extension int2 {
  init?(dict: [String: Any]) {
    guard let x = dict["x"] as? Int32, let y = dict["y"] as? Int32 else { return nil }
    self.init(x, y)
  }
  func toDict() -> [String: Any] {
    return ["x": self.x, "y": self.y]
  }
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

class InitialGridPositionComponent: GKComponent {
  var position: int2?
  convenience init(position: int2) {
    self.init()
    self.position = position
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

  convenience init?(graph: GKGridGraph<GridNode>, dict: [String: Any]) {
    guard let intDict = dict["gridPosition"] as? [String: Any], let gridPosition = int2(dict: intDict) else { return nil }
    self.init()
    self.gridNode = graph.node(atGridPosition: gridPosition)
  }

  func toDict() -> [String: Any] {
    guard let gridNode = gridNode else { return [:] }
    return ["gridPosition": gridNode.gridPosition.toDict()]
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

// MARK: sprites

class SpriteSystem: GKComponentSystem<SpriteComponent> {
  weak var scene: MapScene?
  required init(scene: MapScene?) {
    self.scene = scene
    super.init(componentClass: SpriteComponent.self)
  }

  override func addComponent(_ component: SpriteComponent) {
    super.addComponent(component)
    guard let entity = component.entity else { return }

    if let scene = scene,
      let gridComponent: GridNodeComponent = entity.get(),
      let gridPosition = gridComponent.gridNode?.gridPosition
    {
      component.sprite.position = scene.spritePoint(forPosition: gridPosition)
      scene.mapContainerNode.addChild(component.sprite)
      scene.setMapNodeTransform(component.sprite)
    }
  }

  override func removeComponent(_ component: SpriteComponent) {
    if component.shouldAnimateAway {
      component.animateAway(completion: { [weak component] in component?.sprite.removeFromParent() })
    } else {
      component.sprite.removeFromParent()
    }
    super.removeComponent(component)
  }
}

class SpriteComponent: GKComponent {
  var shouldAnimateAway = true
  var sprite: SKNode!

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
      y: CGFloat(direction.y) * sprite.frame.size.height / 4)
    let actionOut = SKAction.move(to: sprite.position + vector, duration: MOVE_TIME / 2)
    let actionIn = SKAction.move(to: sprite.position, duration: MOVE_TIME / 2)
    sprite.run(SKAction.sequence([actionOut, actionIn]), completion: { completion?() })
  }
}

// MARK: mass

class MassComponent: GKComponent {
  var weight: CGFloat = 0

  convenience init(weight: CGFloat) {
    self.init()
    self.weight = weight
  }
}

// MARK: health

class HealthComponent: GKComponent {
  var health: CGFloat = 0
  var maxHealth: CGFloat = 0
  var isDead: Bool { return health <= 0 }

  convenience init(health: CGFloat, maxHealth: CGFloat? = nil) {
    self.init()
    self.health = health
    self.maxHealth = maxHealth ?? health
  }

  convenience init?(dict: [String: Any]) {
    guard let health = dict["health"] as? CGFloat, let maxHealth = dict["maxHealth"] as? CGFloat else { return nil }
    self.init()
    self.health = health
    self.maxHealth = maxHealth
  }

  func toDict() -> [String: Any] {
    return ["health": health, "maxHealth": maxHealth]
  }

  func getFractionRemaining() -> CGFloat { return health / maxHealth }

  func hit(_ amount: CGFloat) {
    health = max(0, health - amount)

    if self.entity?.component(ofType: PlayerComponent.self) != nil { return }

    if let sprite = self.entity?.sprite as? SKLabelNode {
      sprite.colorBlendFactor = 1 - getFractionRemaining()
    } else if let sprite = self.entity?.sprite as? SKSpriteNode {
      sprite.colorBlendFactor = 1 - getFractionRemaining()

      if let spriteTypeC = self.entity?.component(ofType: SpriteTypeComponent.self) {
        spriteTypeC.colorBlendFactor = sprite.colorBlendFactor
      }
    }
  }

  func heal(_ amount: CGFloat) {
    health = min(maxHealth, health + amount)
    // this never happens for enemies so don't worry about updating visuals (we never change the player's color, only the player heals)
  }
}

// MARK: pickup

class PickupConsumableComponent: GKComponent {
  var isPickedUp = false
}

// MARK: map space

class TakesUpSpaceComponent: GKComponent { }

// MARK: special player stuff

class PlayerComponent: GKComponent { }

// MARK: special exit stuff

class ExitComponent: GKComponent { }

// MARK: special wall stuff

class WallComponent: GKComponent { }

// MARK: ammo

class AmmoComponent: GKComponent {
  var value: Int = 1
  var damage: CGFloat = 20

  convenience init(value: Int, damage: CGFloat) {
    self.init()
    self.value = value
    self.damage = damage
  }

  convenience init?(dict: [String: Any]) {
    guard let value = dict["value"] as? Int, let damage = dict["damage"] as? CGFloat else { return nil }
    self.init()
    self.value = value
    self.damage = damage
  }

  func toDict() -> [String: Any] {
    return ["value": value, "damage": damage]
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

  convenience init?(dict: [String: Any]) {
    guard let value = dict["value"] as? CGFloat else { return nil }
    self.init()
    self.value = value
  }

  func toDict() -> [String: Any] {
    return ["value": value]
  }
}

// MARK: AI

class MoveTowardPlayerComponent: GKComponent {
  var vectors: [int2] = []
  var pathfinding: Bool = false

  convenience init(vectors: [int2], pathfinding: Bool = false) {
    self.init()
    self.vectors = vectors
    self.pathfinding = pathfinding
  }

  func getClosest(to target: int2, inGraph graph: GKGridGraph<GridNode>) -> GridNode? {
    if pathfinding {
      return getClosestByPathfinding(to: target, inGraph: graph)
    } else {
      return getClosestByProximity(to: target, inGraph: graph)
    }
  }

  private func _isNodeOk(_ node: GridNode) -> Bool {
    return node.entities.filter({ (e: GKEntity) -> Bool in return e.component(ofType: TakesUpSpaceComponent.self) != nil && e.component(ofType: PlayerComponent.self) == nil }).isEmpty
  }

  func getClosestByProximity(to target: int2, inGraph graph: GKGridGraph<GridNode>) -> GridNode? {
    guard let myPos = self.entity?.gridNode?.gridPosition else { return nil }
    var bestDist: CGFloat = 1000
    var bestNode: GridNode? = nil

    for v in vectors {
      let nextPos: int2 = myPos + v
      if graph.node(atGridPosition: nextPos) == nil {
        continue
      }
      let node = graph.node(atGridPosition: nextPos)!
      if !_isNodeOk(node) { continue }
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

  func getClosestByPathfinding(to target: int2, inGraph graph: GKGridGraph<GridNode>) -> GridNode? {
    guard let myNode = self.entity?.gridNode else { return nil }
    guard let theirNode = graph.node(atGridPosition: target) else { return nil }
    let nodes = graph.findPath(from: myNode, to: theirNode)
    guard let node = nodes.dropFirst().first as? GridNode else { return getClosestByProximity(to: target, inGraph: graph) }
    if _isNodeOk(node) {
      return node
    } else {
      return getClosestByProximity(to: target, inGraph: graph)
    }
  }
}

// MARK: speed

class SpeedLimiterComponent: GKComponent {
  var bucketSize: Int = 2
  var stepCost: Int = 1
  var bucketLeft: Int = 2

  convenience init(bucketSize: Int, stepCost: Int, bucketLeft: Int) {
    self.init()
    self.bucketSize = bucketSize
    self.stepCost = stepCost
    self.bucketLeft = bucketLeft
  }

  convenience init?(dict: [String: Any]) {
    guard let bucketSize = dict["bucketSize"] as? Int, let stepCost = dict["stepCost"] as? Int, let bucketLeft = dict["bucketLeft"] as? Int else { return nil }
    self.init()
    self.bucketSize = bucketSize
    self.stepCost = stepCost
    self.bucketLeft = bucketLeft
  }

  func toDict() -> [String: Any] {
    return ["bucketSize": bucketSize, "stepCost": stepCost, "bucketLeft": bucketLeft]
  }

  func tryToStep() -> Bool {
    if bucketLeft >= bucketSize {
      bucketLeft -= stepCost
      refillIfZero()
      return true
    } else {
      bucketLeft -= stepCost
      refillIfZero()
      return false
    }
  }

  func refillIfZero() {
    if bucketLeft <= 0 {
      bucketLeft = bucketSize
    }
  }
}

// MARK: turtle

class TurtleAnimationComponent: GKComponent {
  func updateSprite() {
    guard
      let entity = self.entity,
      let sprite = entity.sprite as? SKSpriteNode,
      let speedC: SpeedLimiterComponent = entity.get() else { return }
    sprite.texture = Assets16.get(speedC.bucketLeft == 2 ? .mobTurtle1 : .mobTurtle2)
  }
}

class TurtleAnimationSystem: GKComponentSystem<TurtleAnimationComponent> {
  override required init() {
    super.init(componentClass: TurtleAnimationComponent.self)
  }

  override func addComponent(_ component: TurtleAnimationComponent) {
    super.addComponent(component)
    component.updateSprite()
  }

  func update() {
    for c in components {
      c.updateSprite()
    }
  }
}

// MARK: scoring

class PointValueComponent: GKComponent {
  var points: Int = 1
}

// MARK: power

class PowerComponent: GKComponent {
  var power: CGFloat = 0
  var maxPower: CGFloat = 0
  var isBattery: Bool = false
  var isFull: Bool { return power >= maxPower }
  var neverChanges: Bool = false

  convenience init(power: CGFloat, isBattery: Bool, maxPower: CGFloat? = nil, neverChanges: Bool = false) {
    self.init()
    self.power = power
    self.maxPower = maxPower ?? power
    self.isBattery = isBattery
    self.neverChanges = neverChanges
  }

  convenience init?(dict: [String: Any]) {
    guard let power = dict["power"] as? CGFloat, let maxPower = dict["maxPower"] as? CGFloat, let isBattery = dict["isBattery"] as? Bool, let neverChanges = dict["neverChanges"] as? Bool else { return nil }
    self.init()
    self.power = power
    self.maxPower = maxPower
    self.isBattery = isBattery
    self.neverChanges = neverChanges
  }

  func toDict() -> [String: Any] {
    return ["power": power, "maxPower": maxPower, "isBattery": isBattery, "neverChanges": neverChanges]
  }

  func getFractionRemaining() -> CGFloat { return power / maxPower }

  func getPowerRequired(toMove distance: CGFloat) -> CGFloat {
    return (self.entity?.massC?.weight ?? 0) * 0.02
  }

  func canUse(_ amount: CGFloat) -> Bool {
    return power >= amount
  }

  func use(_ amount: CGFloat) -> Bool {
    if !canUse(amount) { return false }
    if !neverChanges {
      power -= amount
    }
    return true
  }

  func charge(_ amount: CGFloat) {
    power = max(min(maxPower, power + amount), 0)
  }

  func discharge() -> CGFloat {
    guard !neverChanges else { return power }
    let p = power
    power = 0
    return p
  }
}

// Mob spec

class MobSpecComponent: GKComponent {
  let spec: MobSpec
  required init(spec: MobSpec) {
    self.spec = spec
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  convenience init?(dict: [String: Any]) {
    guard let spec = MobSpec(dict: dict) else { return nil }
    self.init(spec: spec)
  }

  func toDict() -> [String: Any] {
    return spec.toDict()
  }
}

// Generic sprite type

class SpriteTypeComponent: GKComponent {
  let asset: _Assets16
  let z: CGFloat
  let shouldAnimateAway: Bool
  var colorBlendFactor: CGFloat
  required init(asset: _Assets16, z: CGFloat, shouldAnimateAway: Bool = true, colorBlendFactor: CGFloat = 0) {
    self.asset = asset
    self.z = z
    self.shouldAnimateAway = shouldAnimateAway
    self.colorBlendFactor = colorBlendFactor
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  convenience init?(dict: [String: Any]) {
    guard
      let z = dict["z"] as? CGFloat,
      let colorBlendFactor = dict["colorBlendFactor"] as? CGFloat,
      let shouldAnimateAway = dict["shouldAnimateAway"] as? Bool,
      let assetString = dict["asset"] as? String,
      let asset = _Assets16(rawValue: assetString) else { return nil }
    self.init(asset: asset, z: z, shouldAnimateAway: shouldAnimateAway, colorBlendFactor: colorBlendFactor)
  }

  func toDict() -> [String: Any] {
    return ["asset": asset.rawValue, "z": z, "shouldAnimateAway": shouldAnimateAway, "colorBlendFactor": colorBlendFactor]
  }
}
