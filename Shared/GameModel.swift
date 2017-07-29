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


class BatteryPickupRule: GKRule {

  required override init() {
    super.init()
    self.salience = 1
  }

  override func evaluatePredicate(in system: GKRuleSystem) -> Bool {
    guard
      let game = system.state["game"] as? GameModel,
      let entities = game.player.gridNode?.entities,
      let actors = entities.filter({ $0 as? Actor != nil }) as? [Actor]
      else { return false }
    let batteries = actors.filter({ $0.powerC.isBattery })
    if batteries.isEmpty { return false }
    system.state["batteriesToPickup"] = batteries
    return true
  }

  override func performAction(in system: GKRuleSystem) {
    guard
      let game = system.state["game"] as? GameModel,
      let batteries = system.state["batteriesToPickup"] as? [Actor] else { return }
    system.state["batteriesToPickup"] = nil
    for battery in batteries {
      if game.player.powerC.isFull {
        return
      }
      game.player.powerC.charge(battery.powerC.discharge())
      game.delete(entity: battery)
    }
  }
}


private func createRuleSystem(_ game: GameModel) -> GKRuleSystem {
  let rs = GKRuleSystem()
  rs.state["game"] = game
  rs.add(BatteryPickupRule())
  return rs
}


class GameModel {
  var isAcceptingInput: Bool = true
  weak var scene: MapScene?
  lazy var ruleSystem: GKRuleSystem = { createRuleSystem(self) }()

  lazy var gridSystem: GKComponentSystem = { return GKComponentSystem(componentClass: GridNodeComponent.self) }()
  lazy var spriteSystem: GKComponentSystem = { return GKComponentSystem(componentClass: SpriteComponent.self) }()
  lazy var componentSystems: [GKComponentSystem] = { return [self.gridSystem, self.spriteSystem] }()
  var player: Actor!
  var exit: GKEntity!
  lazy var random: GKRandomSource = { GKRandomSource.sharedRandom() }()

  lazy var gridGraph: GKGridGraph<GridNode> = {
    let graph = GKGridGraph<GridNode>(
      fromGridStartingAt: int2(0, 0),
      width: 8,
      height: 6,
      diagonalsAllowed: true,
      nodeClass: GridNode.self)
    return graph
  }()

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
  }

  init(player: Actor?) {
    self.player = player
  }

  func delete(entity: GKEntity) {
    print("delete \(entity)")
    if let spriteComponent: SpriteComponent = entity.get() {
      spriteComponent.sprite.removeFromParent()
    }


    if let gridComponent: GridNodeComponent = entity.get() {
      gridComponent.gridNode?.remove(entity)
    }

    for system in componentSystems {
      system.removeComponent(foundIn: entity)
    }
  }

  func createActor(_ character: String, weight: CGFloat, power: CGFloat, point: int2) -> Actor {
    guard let scene = scene else { fatalError() }
    let entity = Actor()
    entity.addComponent(GridNodeComponent(gridNode: gridGraph.node(atGridPosition: point)))
    entity.addComponent(SpriteComponent(sprite: scene.createLabelNode(character)))
    entity.addComponent(PowerComponent(power: power, isBattery: false))
    entity.addComponent(MassComponent(weight: weight))
    entity.gridNode?.add(entity)
    return entity
  }

  func createExit(point: int2) -> GKEntity {
    guard let scene = scene else { fatalError() }
    let entity = GKEntity()
    let gnc = GridNodeComponent(gridNode: gridGraph.node(atGridPosition: point))
    entity.addComponent(gnc)
    entity.addComponent(SpriteComponent(sprite: scene.createLabelNode(">")))
    return entity
  }

  func start(scene: MapScene) {
    self.scene = scene

    MapGenerator.generate(scene: scene, game: self)
  }

  func end() {
    self.delete(entity: player)
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

  func movePlayer(by delta: int2, completion: OptionalCallback = nil) {
    guard isAcceptingInput else { return }
    guard let pos = player.position else { fatalError() }
    let nextPos = pos + delta
    guard let nextGridNode = gridGraph.node(atGridPosition: nextPos) else { return }
    guard player.gridNode?.connectedNodes.contains(nextGridNode) == true else { return }
    moveEntity(player, toGridNode: nextGridNode, completion: completion)
  }

  func moveEntity(_ entity: Actor, toGridNode gridNode: GridNode, completion: OptionalCallback = nil) {
    guard let scene = scene else { fatalError() }
    guard entity.powerC.use(entity.powerC.getPowerRequired(toMove: 1)) else { return }
    isAcceptingInput = false

    entity.gridNode = gridNode

    let action = SKAction.move(to: scene.visualPoint(forPosition: gridNode.gridPosition), duration: MOVE_TIME)
    action.timingMode = .easeIn
    entity.sprite.run(action) {
      self.isAcceptingInput = true
      self.executeTurn()
      completion?()
    }
  }
}
