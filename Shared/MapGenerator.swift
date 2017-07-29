//
//  MapGenerator.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation


class MapGenerator {
  class func generate(scene: MapScene, game: GameModel) {
    let numWalls = Int(CGFloat(game.gridGraph.gridWidth * game.gridGraph.gridHeight) * 0.2)

    let shuffledGridNodes = game.random.arrayByShufflingObjects(in: game.gridGraph.nodes ?? []) as! [GridNode]
    let walls = Array(shuffledGridNodes[0..<numWalls])
    game.gridGraph.remove(walls)
    for wall in walls {
      scene.gridSprite(at: wall.gridPosition)?.text = "#"
    }

    let playerPosition = shuffledGridNodes[numWalls].gridPosition
    if game.player == nil {
      game.player = game.createActor("@", weight: 100, power: 100, point: playerPosition)
    } else {
      game.player.gridNode = game.gridGraph.node(atGridPosition: playerPosition)
    }

    for batteryGridNode in shuffledGridNodes[numWalls+1..<numWalls+(numWalls/2)] {
      let batteryEntity = game.createActor("=", weight: 1, power: 10, point: batteryGridNode.gridPosition)
      batteryEntity.powerC.isBattery = true
      game.register(entity: batteryEntity)
    }
    game.register(entity: game.player)

    game.exit = game.createExit(point: shuffledGridNodes.last!.gridPosition)
    game.register(entity: game.exit)
  }
}
