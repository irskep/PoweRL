//
//  GameModel.swift
//  macOS
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import GameplayKit
import SpriteKit


let MOVE_TIME: TimeInterval = 0.15


class GridNodeSharingRule: GKRule {
  func getIsEntityRelevant(_ e: GKEntity) -> Bool {
    return false
  }

  func performAction(inGame game: GameModel, withEntities entities: [GKEntity]) {
  }

  override func evaluatePredicate(in system: GKRuleSystem) -> Bool {
    print("Run \(String(describing: type(of: self)))")
    guard
      let game = system.state["game"] as? GameModel,
      let entities = game.player.gridNode?.entities
      else { return false }
    let wantedEntities: [GKEntity] = entities.filter(self.getIsEntityRelevant)
    guard !wantedEntities.isEmpty else { return false }
    system.state[String(describing: type(of: self))] = wantedEntities
    return true
  }

  override func performAction(in system: GKRuleSystem) {
    guard
      let game = system.state["game"] as? GameModel,
      let entities = system.state[String(describing: type(of: self))] as? [GKEntity] else { return }
    system.state[String(describing: type(of: self))] = nil
    self.performAction(inGame: game, withEntities: entities)
  }
}


class BatteryChargeRule: GridNodeSharingRule {
  required override init() {
    super.init()
    self.salience = 1000
  }

  override func getIsEntityRelevant(_ e: GKEntity) -> Bool {
    return e.powerC?.isBattery == true
  }

  override func performAction(inGame game: GameModel, withEntities entities: [GKEntity]) {
    for battery in entities {
      if game.player.powerC?.isFull == true {
        return
      }
      game.player.powerC?.charge(battery.powerC?.discharge() ?? 0)
      if let pickupC = battery.component(ofType: PickupConsumableComponent.self) {
        pickupC.isPickedUp = true
      }
    }
  }
}


class ConsumablePickupRule: GridNodeSharingRule {
  required override init() {
    super.init()
    self.salience = 999
  }

  override func getIsEntityRelevant(_ e: GKEntity) -> Bool {
    return e.isPickupConsumable
  }

  override func performAction(inGame game: GameModel, withEntities entities: [GKEntity]) {
    for e in entities {
      if let pickupC = e.component(ofType: PickupConsumableComponent.self), pickupC.isPickedUp {
        game.delete(entity: e)
      }
    }
  }
}


private func createRuleSystem(_ game: GameModel) -> GKRuleSystem {
  let rs = GKRuleSystem()
  rs.state["game"] = game
  rs.add(BatteryChargeRule())
  rs.add(ConsumablePickupRule())
  return rs
}


class GameModel {
  var difficulty: Int = 1
  var isAcceptingInput: Bool = true

  var mapSize: int2 = int2(8, 6)
  weak var scene: MapScene?
  lazy var ruleSystem: GKRuleSystem = { createRuleSystem(self) }()

  lazy var gridSystem: GridSystem = { return GridSystem() }()
  lazy var spriteSystem: SpriteSystem = { return SpriteSystem() }()
  lazy var gridSpriteSystem: GridSpriteSystem = { return GridSpriteSystem() }()
  lazy var componentSystems: [GKComponentSystem] = { return [self.gridSystem, self.spriteSystem, self.gridSpriteSystem] as! [GKComponentSystem] }()
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
      spriteComponent.sprite.position = scene.visualPoint(forPosition: gridPosition)
      scene.mapContainerNode.addChild(spriteComponent.sprite)
    }

    entities.insert(entity)
  }

  init(difficulty: Int, player: GKEntity?) {
    self.difficulty = difficulty
    self.player = player
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
    self.player.sprite?.zPosition = 1
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
      diagonalsAllowed: true,
      nodeClass: GridNode.self)
  }

  func update(deltaTime: TimeInterval) {
    componentSystems.forEach({ $0.update(deltaTime: deltaTime) })
  }

  func executeTurn() {
    print("------------")
    ruleSystem.state["game"] = self
    ruleSystem.reset()
    ruleSystem.evaluate()
    ruleSystem.state["game"] = nil
    scene?.evaluatePossibleTransitions()
  }
}

// MARK: Actions

extension GameModel {
  func movePlayer(by delta: int2, completion: OptionalCallback = nil) {
    guard isAcceptingInput else { return }
    guard let pos = player.position else { fatalError() }
    let nextPos = pos + delta
    guard let nextGridNode = gridGraph.node(atGridPosition: nextPos) else { return }
    guard player.gridNode?.connectedNodes.contains(nextGridNode) == true else { return }
    moveEntity(player, toGridNode: nextGridNode, completion: completion)
  }

  func moveEntity(_ entity: GKEntity, toGridNode gridNode: GridNode, completion: OptionalCallback = nil) {
    guard let scene = scene else { fatalError() }
    guard entity.powerC?.use(entity.powerC?.getPowerRequired(toMove: 1) ?? 0) == true else { return }
    isAcceptingInput = false

    entity.gridNode = gridNode

    let action = SKAction.move(to: scene.visualPoint(forPosition: gridNode.gridPosition), duration: MOVE_TIME)
    action.timingMode = .easeIn
    entity.sprite?.run(action) {
      self.isAcceptingInput = true
      self.executeTurn()
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

// MARK: Factories

extension GameModel {
  func createActor(_ character: String, color: SKColor, weight: CGFloat, power: CGFloat, point: int2) -> GKEntity {
    guard let scene = scene else { fatalError() }
    let entity = GKEntity()
    entity.addComponent(GridNodeComponent(gridNode: gridGraph.node(atGridPosition: point)))
    entity.addComponent(SpriteComponent(sprite: scene.createLabelNode(character, color)))
    entity.addComponent(PowerComponent(power: power, isBattery: false))
    entity.addComponent(MassComponent(weight: weight))
    return entity
  }

  func createExit(point: int2) -> GKEntity {
    guard let scene = scene else { fatalError() }
    let entity = GKEntity()
    let gnc = GridNodeComponent(gridNode: gridGraph.node(atGridPosition: point))
    entity.addComponent(gnc)
    entity.addComponent(SpriteComponent(sprite: scene.createLabelNode(">", SKColor.green)))
    return entity
  }
}
