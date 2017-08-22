//
//  GameModel.swift
//  macOS
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import GameplayKit
import SpriteKit


let MOVE_TIME: TimeInterval = 0.1


private func pluralize(_ n: Int, _ s: String, _ p: String) -> String {
  if n == 1 {
    return "1 \(s)"
  } else {
    return "\(n) \(p)"
  }
}


private func createRuleSystem(_ game: GameModel) -> GKRuleSystem {
  let rs = GKRuleSystem()
  rs.state["game"] = game
  rs.add(BatteryChargeRule())
  rs.add(AmmoTransferRule())
  rs.add(ConsumableHealthTransferRule())
  rs.add(ConsumablePickupRule())
  return rs
}


class GameModel {
  var difficulty: Int = 1
  var score: Int = 0
  var isAcceptingInput: Bool = true

  var mapSize: int2 = int2(8, 6)
  weak var scene: MapScene?
  lazy var ruleSystem: GKRuleSystem = { createRuleSystem(self) }()

  lazy var gridSystem: GridSystem = { return GridSystem() }()
  lazy var spriteSystem: SpriteSystem = { return SpriteSystem() }()
  lazy var mobMoveSystem: GKComponentSystem = { return GKComponentSystem(componentClass: MoveTowardPlayerComponent.self) }()
  lazy var turtleAnimSystem: GKComponentSystem = { return GKComponentSystem(componentClass: TurtleAnimationComponent.self) }()
  lazy var componentSystems: [GKComponentSystem] = {
    return [
      self.gridSystem,
      self.spriteSystem,
      self.mobMoveSystem,
      self.turtleAnimSystem,
      ] as! [GKComponentSystem]
  }()
  var gridGraph: GKGridGraph<GridNode>!
  var player: GKEntity!
  var exit: GKEntity!
  var entities = Set<GKEntity>()
  lazy var random: GKRandomSource = { GKRandomSource.sharedRandom() }()

  func register(entity: GKEntity) {
    guard let scene = scene else { fatalError() }
    for system in componentSystems {
      system.addComponent(foundIn: entity)
    }

    if let spriteComponent: SpriteComponent = entity.get(),
      let gridComponent: GridNodeComponent = entity.get(),
      let gridPosition = gridComponent.gridNode?.gridPosition
      {
      spriteComponent.sprite.position = scene.spritePoint(forPosition: gridPosition)
      scene.mapContainerNode.addChild(spriteComponent.sprite)
      scene.setMapNodeTransform(spriteComponent.sprite)
    }
    if let turtleC: TurtleAnimationComponent = entity.get() {
      turtleC.updateSprite()
    }

    entities.insert(entity)
  }

  init(difficulty: Int, player: GKEntity?, score: Int) {
    self.difficulty = difficulty
    self.player = player
    self.score = score
  }

  func delete(entity: GKEntity) {
    print("delete \(entity)")
    for system in componentSystems {
      system.removeComponent(foundIn: entity)
    }
    entities.remove(entity)
  }

  func start(scene: MapScene) {
    self.scene = scene
    self.reset()
    MapGenerator.generate(scene: scene, game: self)
    isAcceptingInput = true
  }

  func end() {
    self.delete(entity: player)
  }

  func reset() {
    for e in entities {
      for system in componentSystems {
        system.removeComponent(foundIn: e)
      }
    }
    self.entities = Set<GKEntity>()
    gridGraph = GKGridGraph<GridNode>(
      fromGridStartingAt: int2(0, 0),
      width: mapSize.x,
      height: mapSize.y,
      diagonalsAllowed: false,
      nodeClass: GridNode.self)
  }

  func update(deltaTime: TimeInterval) {
    componentSystems.forEach({ $0.update(deltaTime: deltaTime) })
  }

  func executeTurn(autotransition: Bool = true) {
    guard let playerNode = player.gridNode else { return }
    print("------------")
    ruleSystem.state["game"] = self
    ruleSystem.reset()
    ruleSystem.evaluate()
    ruleSystem.state["game"] = nil
    for component in mobMoveSystem.components {
      if let nextNode = (component as? MoveTowardPlayerComponent)?.getClosest(to: playerNode.gridPosition, inGraph: gridGraph) {
        if let speedLimiter = component.entity?.component(ofType: SpeedLimiterComponent.self) {
          if !speedLimiter.tryToStep() {
            continue
          }
        }
        if let currentNode = component.entity?.gridNode, let sprite = component.entity?.sprite {
          if nextNode.gridPosition.x > currentNode.gridPosition.x && sprite.xScale < 0 {
            // face left
            sprite.xScale *= -1
          } else if nextNode.gridPosition.x < currentNode.gridPosition.x && sprite.xScale > 0 {
            // face right
            sprite.xScale *= -1
          }
        }
        if nextNode == player.gridNode {
          self.damagePlayer(withEntity: component.entity!)
        } else {
          self.move(entity: component.entity!, toGridNode: nextNode)
        }
      }
    }
    for component in turtleAnimSystem.components {
      (component as? TurtleAnimationComponent)?.updateSprite()
    }
    if autotransition {
      scene?.evaluatePossibleTransitions()
    }
  }

  func getTargetingLaserPoints(to gridPos: int2) -> [int2] {
    guard let startOfLine = player.gridNode?.gridPosition else { return [] }
    var results: [int2] = []
    for p in bresenham2(CGPoint(startOfLine), CGPoint(gridPos)) {
      if startOfLine == p {
        continue
      }
      if gridGraph.node(atGridPosition: p) == nil {
        break
      }
      let node = gridGraph.node(atGridPosition: p)!
      results.append(p)
      if !node.entities.filter({ $0.component(ofType: TakesUpSpaceComponent.self) != nil }).isEmpty {
        // Include last point so player can see
        break
      }
    }
    return results
  }
}

// MARK: Actions

extension GameModel {
  func shoot(target: int2, path: [int2]) {
    guard isAcceptingInput else { return }
    guard let node = gridGraph.node(atGridPosition: target) else { return }
    guard let ammoC = player.ammoC else { return }
    let entitiesToShoot = node.entities.filter({ $0.healthC != nil })
    guard !entitiesToShoot.isEmpty else { return }
    guard ammoC.value > 0 else {
      Player.shared.get("hit2", useCache: false).play()
      scene?.flashMessage("No ammo")
      return
    }
    ammoC.add(value: -1)

    let bulletSprite = PWRSpriteNode(.ammo1).withZ(Z.player)
    bulletSprite.position = player.sprite!.position
    scene?.setMapNodeTransform(bulletSprite)

    var actions = path.map({
      return SKAction.move(
        to: scene!.spritePoint(forPosition: $0),
        duration: MOVE_TIME / 2)
    })
    actions.append(SKAction.fadeOut(withDuration: MOVE_TIME / 2))
    scene!.mapContainerNode.addChild(bulletSprite)
    isAcceptingInput = false
    bulletSprite.run(SKAction.sequence(actions), completion: {
      bulletSprite.removeFromParent()
      for e in entitiesToShoot {
        self.damageEnemy(entity: e, amt: ammoC.damage)
      }
      Player.shared.get("hit3", useCache: false).play()
      self.isAcceptingInput = true
      self.executeTurn()
    })
  }

  func movePlayer(by delta: int2, completion: OptionalCallback = nil) {
    guard isAcceptingInput else { return }
    guard let pos = player.position else {
      print("Trying to move player but it has no position, wat???")
      return
    }
    let nextPos = pos + delta
    guard let nextGridNode = gridGraph.node(atGridPosition: nextPos) else {
      self.bump(delta, completion: completion)
      return
    }
    if player.gridNode != gridGraph.node(atGridPosition: pos) {
      print("Player grid node is fucked up")
      player.gridNode = gridGraph.node(atGridPosition: pos)
    }
    guard player.gridNode?.connectedNodes.contains(nextGridNode) == true else {
        self.bump(delta, completion: completion)
        return
    }
    let entitiesToDamage = nextGridNode.entities.filter({
      return $0.healthC != nil &&
             $0.component(ofType: TakesUpSpaceComponent.self) != nil
    })
    if entitiesToDamage.isEmpty {
      movePlayer(toGridNode: nextGridNode, completion: completion)
    } else {
      let amt = player.component(ofType: BumpDamageComponent.self)?.value ?? 0
      for e in entitiesToDamage {
        self.damageEnemy(entity: e, amt: amt)
      }
      self.bump(delta, entity: player, completion: {
        self.executeTurn()
        completion?()
      })
    }
  }

  func damageEnemy(entity: GKEntity, amt: CGFloat) {
    entity.healthC?.hit(amt)
    if entity.healthC?.isDead == true {
      if let ptsC = entity.component(ofType: PointValueComponent.self) {
        self.score += ptsC.points
        scene?.flashMessage("+\(pluralize(ptsC.points, "point", "points"))", color: SKColor.green)
      }
      self.delete(entity: entity)
    }
  }

  func bump(_ delta: int2, entity: GKEntity? = nil, completion: OptionalCallback) {
    let entity: GKEntity = entity ?? self.player
    isAcceptingInput = false
    if entity == self.player {
      Player.shared.get("bump", useCache: false).play()
    }
    entity.component(ofType: SpriteComponent.self)!.nudge(delta) {
      self.isAcceptingInput = true
      completion?()
    }
  }

  func move(entity: GKEntity, toGridNode gridNode: GridNode, completion: OptionalCallback = nil) {
    guard let scene = scene else { fatalError() }

    isAcceptingInput = false
    entity.gridNode = gridNode

    let action = SKAction.move(to: scene.spritePoint(forPosition: gridNode.gridPosition), duration: MOVE_TIME)
    action.timingMode = .easeIn
    entity.sprite?.run(action) {
      self.isAcceptingInput = true
      completion?()
    }
  }

  func damagePlayer(withEntity entity: GKEntity) {
    guard
      let bumpDamageC = entity.component(ofType: BumpDamageComponent.self),
      let playerPos = player.gridNode?.gridPosition,
      let entityPos = entity.gridNode?.gridPosition
      else { return }
    player.healthC?.hit(bumpDamageC.value)
    scene?.flashMessage("-\(Int(bumpDamageC.value)) hp")
    Player.shared.get("hit1", useCache: false).play()
    self.bump(int2(playerPos.x - entityPos.x, playerPos.y - entityPos.y), entity: entity, completion: nil)
    scene?.evaluatePossibleTransitions()
  }

  func movePlayer(toGridNode gridNode: GridNode, completion: OptionalCallback = nil) {
    guard let entity = player else { fatalError() }
    guard entity.powerC?.use(entity.powerC?.getPowerRequired(toMove: 1) ?? 0) == true else {
      scene?.gameOver(reason: .power)
      return
    }

    self.move(entity: entity, toGridNode: gridNode) {
      completion?()
      self.scene?.evaluatePossibleTransitions()
    }
    self.executeTurn(autotransition: false)
  }
}

// MARK: Utilities

extension GameModel {
  func getIsReachable(_ a: GridNode?, _ b: GridNode?) -> Bool {
    guard let a = a, let b = b else { return false }
    return gridGraph.findPath(from: a, to: b).count > 0
  }
}
