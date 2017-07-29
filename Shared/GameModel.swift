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


class GameModel {
  var isAcceptingInput: Bool = true
  weak var scene: MapScene?

  lazy var gridSystem: GKComponentSystem = { return GKComponentSystem(componentClass: GridNodeComponent.self) }()
  lazy var spriteSystem: GKComponentSystem = { return GKComponentSystem(componentClass: SpriteComponent.self) }()
  lazy var componentSystems: [GKComponentSystem] = { return [gridSystem, spriteSystem] }()
  var player: Actor!
  lazy var random: GKRandomSource = { GKRandomSource.sharedRandom() }()
  var numWalls: Int {
    return Int(CGFloat(gridGraph.gridWidth * gridGraph.gridHeight) * 0.2)
  }

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

  func createActor(_ character: String, point: int2) -> Actor {
    guard let scene = scene else { fatalError() }
    let entity = Actor()
    entity.addComponent(GridNodeComponent(gridNode: gridGraph.node(atGridPosition: point)))
    entity.addComponent(SpriteComponent(sprite: scene.createLabelNode(character)))
    return entity
  }

  func start(scene: MapScene) {
    self.scene = scene

    let shuffledGridNodes = random.arrayByShufflingObjects(in: gridGraph.nodes ?? []) as! [GridNode]
    let walls = Array(shuffledGridNodes[0..<numWalls])
    gridGraph.remove(walls)
    for wall in walls {
      scene.gridSprite(at: wall.gridPosition)?.text = "#"
    }
    player = createActor("@", point: shuffledGridNodes.last!.gridPosition)
    register(entity: player)
  }

  func update(deltaTime: TimeInterval) {
    componentSystems.forEach({ $0.update(deltaTime: deltaTime) })
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
    isAcceptingInput = false
    entity.gridNode = gridNode
    let action = SKAction.move(to: scene.visualPoint(forPosition: gridNode.gridPosition), duration: MOVE_TIME)
    action.timingMode = .easeIn
    entity.sprite.run(action) {
      self.isAcceptingInput = true
      completion?()
    }
  }
}
