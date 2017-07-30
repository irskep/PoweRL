//
//  MapGenerator.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit


struct MobSpec {
  let char: String
  let health: CGFloat
  let moves: [int2]
}


class MapGenerator {
  class func generate(scene: MapScene, game: GameModel, n: Int = 0) {
    let area: Int = game.gridGraph.gridWidth * game.gridGraph.gridHeight
    let getAreaFraction = { (frac: CGFloat) -> Int in return Int(CGFloat(area) * frac) }
    let numBatteries = 2
    let numAmmos = 2
    let numHealthPacks = 1
    // 25% of cells are walls
    let numWalls = getAreaFraction(0.25)
    // 10% + difficulty * 2% are power drains
    let numDrains = getAreaFraction(0.1 + 0.02 * CGFloat(game.difficulty))

    let numEnemies = game.difficulty

    var shuffledGridNodes = game.random.arrayByShufflingObjects(in: game.gridGraph.nodes ?? []) as! [GridNode]

    let getSomeNodes = { (n: Int) -> [GridNode] in
      let val = Array(shuffledGridNodes[0..<min(shuffledGridNodes.count, n)])
      shuffledGridNodes = Array(shuffledGridNodes.dropFirst(n))
      return val
    }

    for wallNode in getSomeNodes(numWalls) {
      game.gridGraph.remove([wallNode])
      let wall = GKEntity()
      wall.addComponent(GridNodeComponent(gridNode: wallNode))
      let sprite = SKSpriteNode(imageNamed: "wall")
      sprite.setScale(scene.tileScale)
      wall.addComponent(SpriteComponent(sprite: sprite))
      game.register(entity: wall)
    }

    let playerPosition = shuffledGridNodes[0].gridPosition
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(1))
    if game.player == nil {
      game.player = game.createActor("@", color: SKColor.white, weight: 100, power: 100, point: playerPosition)
      game.player.component(ofType: SpriteComponent.self)!.shouldAnimateAway = false
      game.player.addComponent(AmmoComponent(value: 0, damage: 40))
      game.player.addComponent(TakesUpSpaceComponent())
      game.player.addComponent(PlayerComponent())
      game.player.addComponent(HealthComponent(health: 100))
      game.player.addComponent(BumpDamageComponent(value: 20))
      game.player.gridNode = game.gridGraph.node(atGridPosition: playerPosition)
    } else {
      game.player.gridNode = game.gridGraph.node(atGridPosition: playerPosition)
    }

    game.exit = game.createExit(point: shuffledGridNodes[0].gridPosition)
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(1))

    for batteryGridNode in getSomeNodes(numBatteries) {
      let batteryEntity = game.createActor("+", color: SKColor.cyan, weight: 1, power: 20, point: batteryGridNode.gridPosition)
      batteryEntity.addComponent(PickupConsumableComponent())
      batteryEntity.powerC?.isBattery = true
      game.register(entity: batteryEntity)
    }

    let ammoNodes = getSomeNodes(numAmmos)
    for ammoNode in ammoNodes {
      let ammo = GKEntity()
      let value = game.random.nextInt(upperBound: 2) + 1
      var char = ""
      for _ in 0..<value { char += "•" }
      ammo.addComponent(GridNodeComponent(gridNode: ammoNode))
      ammo.addComponent(SpriteComponent(sprite: scene.createLabelNode(char, SKColor.purple)))
      ammo.addComponent(PickupConsumableComponent())
      ammo.addComponent(AmmoComponent(value: 2, damage: 40))
      game.register(entity: ammo)
    }

    let healthNodes = getSomeNodes(numHealthPacks)
    for healthNode in healthNodes {
      let health = GKEntity()
      health.addComponent(GridNodeComponent(gridNode: healthNode))
      health.addComponent(SpriteComponent(sprite: scene.createLabelNode("+", SKColor.red)))
      health.addComponent(PickupConsumableComponent())
      health.addComponent(HealthComponent(health: 50))
      game.register(entity: health)
    }

    var mobSpecs: [MobSpec] = [
      MobSpec(char: "🦋", health: 40, moves: [
        int2(-1, -1),
        int2(1, 1),
        int2(-1, 1),
        int2(1, -1),
      ]),
      MobSpec(char: "🐢", health: 40, moves: [
        int2(-1, 0),
        int2(1, 0),
        int2(0, 1),
        int2(0, -1),
        ]),
    ]
    if game.difficulty > 3 {
      mobSpecs.append(MobSpec(char: "🐇", health: 40, moves: [
        int2(-1, -2),
        int2(1, -2),
        int2(-1, 2),
        int2(1, 2),
        int2(-2, -1),
        int2(2, -1),
        int2(-2, 1),
        int2(2, 1),
      ]))
    }
    for mobNode in getSomeNodes(numEnemies) {
      let mob = GKEntity()
      let spec = mobSpecs[game.random.nextInt(upperBound: mobSpecs.count)]
      mob.addComponent(GridNodeComponent(gridNode: mobNode))
      let spriteC = SpriteComponent(sprite: scene.createLabelNode(spec.char, SKColor.red))
      spriteC.shouldAnimateAway = true
      mob.addComponent(spriteC)
      mob.addComponent(HealthComponent(health: spec.health))
      mob.addComponent(MoveTowardPlayerComponent(vectors: spec.moves))
      mob.addComponent(BumpDamageComponent(value: 20))
      mob.addComponent(TakesUpSpaceComponent())
      if spec.char == "🐢" {
        mob.addComponent(SpeedLimiterComponent(bucketSize: 2, stepCost: 1))
      }
      mob.sprite?.zPosition = 1
      (mob.sprite as? SKLabelNode)?.color = SKColor.red
      game.register(entity: mob)
    }

    for drainNode in getSomeNodes(numDrains) {
      let drain = GKEntity()
      drain.addComponent(GridSpriteComponent(scene, drainNode, "-", SKColor.black, SKColor.red.blended(withFraction: 0.8, of: SKColor.black)))
      drain.addComponent(PowerComponent(power: -7, isBattery: true))
      drain.addComponent(GridNodeComponent(gridNode: drainNode))
      drain.addComponent(PickupConsumableComponent())
      game.register(entity: drain)
    }
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(numDrains))

    game.register(entity: game.player)
    game.register(entity: game.exit)

    if !game.getIsReachable(game.player.gridNode, game.exit.gridNode) {
      game.reset()
      MapGenerator.generate(scene: scene, game: game, n: n + 1)
      return
    }
    game.gridGraph.remove([game.exit.gridNode!])
    let nodesThatMustBeReachable: [GridNode] = ammoNodes + healthNodes
    if nodesThatMustBeReachable.first(where: { !game.getIsReachable(game.player.gridNode, $0) }) != nil {
      game.reset()
      MapGenerator.generate(scene: scene, game: game, n: n + 1)
    }
    game.gridGraph.add([game.exit.gridNode!])
    game.gridGraph.connectToAdjacentNodes(node: game.exit.gridNode!)
  }
}
