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
  lazy var spriteSystem: SpriteSystem = { return SpriteSystem(scene: self.scene) }()
  lazy var mobMoveSystem: GKComponentSystem = { return GKComponentSystem(componentClass: MoveTowardPlayerComponent.self) }()
  lazy var turtleAnimSystem: TurtleAnimationSystem = { return TurtleAnimationSystem() }()
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
  var playerTemplate: GKEntity?
  var initialMapState: MapState?
  var exit: GKEntity!
  var entities = Set<GKEntity>()
  lazy var random: GKRandomSource = { GKRandomSource.sharedRandom() }()

  func register(entity: GKEntity) {
    for system in componentSystems {
      system.addComponent(foundIn: entity)
    }

    entities.insert(entity)
  }

  func delete(entity: GKEntity) {
    for system in componentSystems {
      system.removeComponent(foundIn: entity)
    }
    entities.remove(entity)
  }

  func getTargetingLaserPoints(to gridPos: int2) -> [int2] {
    guard let startOfLine = player.gridNode?.gridPosition else { return [] }

    var resultsForward: [int2] = []
    for p in bresenham2(CGPoint(startOfLine), CGPoint(gridPos)) {
      if startOfLine == p {
        continue
      }
      if gridGraph.node(atGridPosition: p) == nil {
        break
      }
      let node = gridGraph.node(atGridPosition: p)!
      resultsForward.append(p)
      if !node.entities.filter({ $0.component(ofType: TakesUpSpaceComponent.self) != nil }).isEmpty {
        // Include last point so player can see
        break
      }
    }

    // run bresenham backward for a slightly different result, so that the
    // game is more liberal about finding a path to shoot from A to B.
    var resultsBackward: [int2] = []
    for p in bresenham2(CGPoint(gridPos), CGPoint(startOfLine)) {
      if startOfLine == p {
        continue
      }
      if gridPos == p {
        resultsBackward.append(p)
        continue
      }
      if gridGraph.node(atGridPosition: p) == nil {
        resultsBackward = []
        break
      }
      let node = gridGraph.node(atGridPosition: p)!
      if !node.entities.filter({ $0.component(ofType: TakesUpSpaceComponent.self) != nil }).isEmpty {
        resultsBackward = []
        break
      }
      resultsBackward.append(p)
    }

    if resultsForward.count > resultsBackward.count {
      return resultsForward
    } else if resultsBackward.count > 0 {
      return resultsBackward.reversed()
    } else {
      return []
    }
  }

  init(difficulty: Int, player: GKEntity?, score: Int) {
    self.difficulty = difficulty
    self.playerTemplate = player
    self.score = score
  }

  init(mapState: MapState) {
    self.difficulty = mapState.difficulty
    self.score = mapState.score
    self.playerTemplate = nil
    self.initialMapState = mapState
  }

  func start(scene: MapScene) {
    self.scene = scene
    self.reset()
    if let initialMapState = initialMapState {
      initialMapState.apply(toGame: self)
    } else {
      let mapState = MapGenerator.generate(difficulty: difficulty, score: self.score, size: self.mapSize, playerTemplate: playerTemplate, random: self.random)
      self.scene?.upsertSave(id: "continuous", dict: mapState.toDict())
      mapState.apply(toGame: self)
    }
    isAcceptingInput = true
  }

  func startEndingLevel() {
    print("starting end of \(self.difficulty)")
  }

  func finishEndingLevel() {
    print("finishing end of \(self.difficulty)")
    for g in gridSystem.components {
      g.gridNode?.removeAllEntities()
    }
    while let e = self.entities.first {
      self.delete(entity: e)
    }
    for sc in spriteSystem.components {
      sc.sprite = nil
    }
    guard let mcn = scene?.mapContainerNode else { return }
    while !mcn.children.isEmpty {
      mcn.children.last!.removeFromParent()
    }
    self.player = nil
    self.exit = nil
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

  func executeTurn(completion: OptionalCallback = nil, autotransition: Bool = true) {
    print("------------")
    ruleSystem.state["game"] = self
    ruleSystem.reset()
    ruleSystem.evaluate()
    ruleSystem.state["game"] = nil

    var didMove = false
    var attacks: [(GKEntity, GridNode)] = []
    for component in mobMoveSystem.components {
      let command = getEntityCommand(game: self, moveComponent: component)
      switch command {
      case .wait: continue
      case .move(let entity, let gridNode):
        // just move it now so the AI doesn't try to move another entity there
        self.move(entity: entity, toGridNode: gridNode)
        didMove = true
      case .attack(let entity, let gridNode): attacks.append((entity, gridNode))
      }
    }
    turtleAnimSystem.update()
    guard !attacks.isEmpty || didMove else {
      isAcceptingInput = true
      if autotransition { _ = scene?.evaluatePossibleTransitions() }
      return
    }

    var actions: [SKAction] = []
    if (didMove) {
      SKAction.wait(forDuration: MOVE_TIME)
    }

    for (entity, node) in attacks {
      let delta = int2(node.gridPosition.x - entity.gridNode!.gridPosition.x, node.gridPosition.y - entity.gridNode!.gridPosition.y)
      if let sprite = entity.sprite as? SKSpriteNode, let bumpDamageC = entity.component(ofType: BumpDamageComponent.self) {
        actions.append(SKAction.wait(forDuration: MOVE_TIME))
        actions.append(SKAction.customAction(withDuration: 0, actionBlock: {
          _, _ in
          self.scene?.flashMessage("-\(Int(bumpDamageC.value)) hp")
          Player.shared.play("hit1", useCache: false)
          sprite.run(sprite.nudge(delta, amt: 0.5, t: MOVE_TIME * 2))
        }))
        actions.append(SKAction.wait(forDuration: MOVE_TIME * 2))
        actions.append(SKAction.customAction(withDuration: 0, actionBlock: {
          _, _ in
          self.player.healthC?.hit(bumpDamageC.value)
          if self.scene?.evaluatePossibleTransitions() == true {
            self.scene?.removeAction(forKey: "executeTurn")
          }
        }))
      }
    }
    actions.append(
      SKAction.customAction(withDuration: 0, actionBlock: { _, _ in self.isAcceptingInput = true }))
    let sequenceAction = SKAction.sequence(actions)
    self.scene?.run(sequenceAction, withKey: "executeTurn")
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
      Player.shared.play("hit2", useCache: false)
      scene?.flashMessage("No ammo")
      return
    }
    ammoC.add(value: -1)
    Player.shared.play("fire_begin", useCache: false)

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
      Player.shared.play("fire_end", useCache: false)
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
    self.isAcceptingInput = false
    let finish = { self.isAcceptingInput = true; completion?() }
    guard let nextGridNode = gridGraph.node(atGridPosition: nextPos) else {
      self.bump(delta, completion: finish)
      return
    }
    if player.gridNode != gridGraph.node(atGridPosition: pos) {
      print("Player grid node is fucked up")
      player.gridNode = gridGraph.node(atGridPosition: pos)
    }
    guard player.gridNode?.connectedNodes.contains(nextGridNode) == true else {
      self.bump(delta, completion: finish)
      return
    }
    let entitiesToDamage = nextGridNode.entities.filter({
      return $0.healthC != nil &&
             $0.component(ofType: TakesUpSpaceComponent.self) != nil
    })
    if entitiesToDamage.isEmpty {
      movePlayer(toGridNode: nextGridNode, completion: finish)
    } else {
      let amt = player.component(ofType: BumpDamageComponent.self)?.value ?? 0
      var isEnemyDead = false
      for e in entitiesToDamage {
        self.damageEnemy(entity: e, amt: amt)
        if e.healthC?.isDead == true {
          isEnemyDead = true
        }
      }
      self.bump(delta, entity: player, sound: isEnemyDead ? "kill" : "bump", completion: {
        self.executeTurn(completion: finish)
      })
    }
  }

  func movePlayer(toGridNode gridNode: GridNode, completion: OptionalCallback = nil) {
    guard let entity = player else { fatalError() }
    guard entity.powerC?.use(entity.powerC?.getPowerRequired(toMove: 1) ?? 0) == true else {
      scene?.gameOver(reason: .power)
      return
    }

    self.move(entity: entity, toGridNode: gridNode) {
      completion?()
      _ = self.scene?.evaluatePossibleTransitions()
    }
    // autotransition=false because the above block checks for transitions, and it runs simultaneously
    // with enemy movements
    self.executeTurn(completion: completion, autotransition: false)
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

  func bump(_ delta: int2, entity: GKEntity? = nil, sound: String = "bump", completion: OptionalCallback) {
    let entity: GKEntity = entity ?? self.player
    isAcceptingInput = false
    if entity == self.player {
      Player.shared.play(sound, useCache: false)
    }
    entity.component(ofType: SpriteComponent.self)?.nudge(delta) {
      self.isAcceptingInput = true
      completion?()
    }
  }

  func move(entity: GKEntity, toGridNode gridNode: GridNode, completion: OptionalCallback = nil) {
    guard let scene = scene else { fatalError() }

    entity.gridNode = gridNode

    let action = SKAction.move(to: scene.spritePoint(forPosition: gridNode.gridPosition), duration: MOVE_TIME)
    action.timingMode = .easeIn
    entity.sprite?.run(action) {
      completion?()
    }
  }
}

// MARK: Utilities

extension GameModel {
  func getIsReachable(_ a: GridNode?, _ b: GridNode?) -> Bool {
    guard let a = a, let b = b else { return false }
    return gridGraph.findPath(from: a, to: b).count > 0
  }
}
