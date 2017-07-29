//
//  MapGenerator.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit


class MapGenerator {
  class func generate(scene: MapScene, game: GameModel, n: Int = 0) {
    let area: Int = game.gridGraph.gridWidth * game.gridGraph.gridHeight
    let getAreaFraction = { (frac: CGFloat) -> Int in return Int(CGFloat(area) * frac) }
    let numBatteries = 3
    // 20% of cells are walls
    let numWalls = getAreaFraction(0.2)
    // 10% + difficulty * 5% are power drains
    let numDrains = getAreaFraction(0.1 + 0.05 * CGFloat(game.difficulty))

    var shuffledGridNodes = game.random.arrayByShufflingObjects(in: game.gridGraph.nodes ?? []) as! [GridNode]

    for wallNode in Array(shuffledGridNodes[0..<numWalls]) {
      game.gridGraph.remove([wallNode])
      let wall = GKEntity()
      wall.addComponent(GridSpriteComponent(scene, wallNode, "#", SKColor.lightGray))
      game.register(entity: wall)
    }
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(numWalls))

    let playerPosition = shuffledGridNodes[0].gridPosition
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(1))
    if game.player == nil {
      game.player = game.createActor("@", color: SKColor.white, weight: 100, power: 100, point: playerPosition)
    } else {
      game.player.gridNode = game.gridGraph.node(atGridPosition: playerPosition)
    }

    for batteryGridNode in shuffledGridNodes[0..<numBatteries] {
      let batteryEntity = game.createActor("=", color: SKColor.cyan, weight: 1, power: 10, point: batteryGridNode.gridPosition)
      batteryEntity.addComponent(PickupConsumableComponent())
      batteryEntity.powerC?.isBattery = true
      game.register(entity: batteryEntity)
    }
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(numBatteries))

    for drainNode in shuffledGridNodes[0..<numDrains] {
      let drain = GKEntity()
      drain.addComponent(GridSpriteComponent(scene, drainNode, "-", SKColor.black, SKColor.red.blended(withFraction: 0.8, of: SKColor.black)))
      drain.addComponent(PowerComponent(power: -5, isBattery: true))
      drain.addComponent(GridNodeComponent(gridNode: drainNode))
      game.register(entity: drain)
    }
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(numDrains))

    game.register(entity: game.player)
    game.exit = game.createExit(point: shuffledGridNodes.last!.gridPosition)
    game.register(entity: game.exit)

    if !game.getIsReachable(game.player.gridNode, game.exit.gridNode) {
      print("Exit unreachable. Regenerating.")
      game.reset()
      MapGenerator.generate(scene: scene, game: game, n: n + 1)
    }
  }
}
