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
  let char: _Assets16
  let health: CGFloat
  let isSlow: Bool
  let pathfinds: Bool
  let moves: [int2]
}

struct Z {
  static let floor: CGFloat = 0
  static let wall: CGFloat = 100
  static let pickup: CGFloat = 200
  static let mob: CGFloat = 300
  static let player: CGFloat = 4000
}


func isEverythingReachable(graph: GKGridGraph<GridNode>, start: GridNode, canMovePast: (GridNode) -> Bool) -> Bool {
  var unvisitedNodes = Set<GridNode>(graph.nodes as! [GridNode])
  var stack: Array<GridNode> = [start]

  while let node = stack.popLast() {
    if !unvisitedNodes.contains(node) { continue }
    unvisitedNodes.remove(node)

    if !canMovePast(node) { continue }
    for neighbor in node.connectedNodes as! [GridNode] {
      stack.append(neighbor)
    }
  }

  return unvisitedNodes.isEmpty
}


class MapGenerator {
  class func generate(scene: MapScene, game: GameModel, n: Int = 0, playerTemplate: GKEntity?) {
    let area: Int = game.gridGraph.gridWidth * game.gridGraph.gridHeight
    let getAreaFraction = { (frac: CGFloat) -> Int in return Int(CGFloat(area) * frac) }
    let numBatteries = 2
    let numAmmos = 2
    let numHealthPacks = 1
    // 25% of cells are walls
    let numWalls = getAreaFraction(0.25)
    // 10% + difficulty * 1.5% are power drains
    let numDrains = getAreaFraction(0.1 + 0.015 * CGFloat(game.difficulty))

    let numEnemies = game.difficulty

    var shuffledGridNodes = game.random.arrayByShufflingObjects(in: game.gridGraph.nodes ?? []) as! [GridNode]

    let getSomeNodes = { (n: Int) -> [GridNode] in
      let val = Array(shuffledGridNodes[0..<min(shuffledGridNodes.count, n)])
      shuffledGridNodes = Array(shuffledGridNodes.dropFirst(n))
      return val
    }

    let getNodeWithScore = { (n: Int, getScore: (GridNode) -> Int) -> GridNode in
      var maxScore: Int = getScore(shuffledGridNodes[0])
      var bestNode = shuffledGridNodes[0]
      for node in shuffledGridNodes {
        let score = getScore(node)
        if score > maxScore {
          maxScore = score
          bestNode = node
        }
      }
      shuffledGridNodes = Array(shuffledGridNodes.filter({ $0 != bestNode }))
      return bestNode
    }

    for wallNode in getSomeNodes(numWalls) {
      game.gridGraph.remove([wallNode])
      let wall = GKEntity()
      wall.addComponent(GridNodeComponent(gridNode: wallNode))
      let sprite = PWRSpriteNode(.bgWall).withZ(Z.wall)
      wall.addComponent(SpriteComponent(sprite: sprite))
      game.register(entity: wall)
    }

    if game.player != nil { game.player = nil }
    if game.exit != nil { game.exit = nil }
    let playerNode = getSomeNodes(1)[0]
    game.player = GKEntity()
    let sprite = PWRSpriteNode(.player).withZ(Z.player)
    sprite.zPosition = Z.player
    game.player.addComponent(GridNodeComponent(gridNode: playerNode))
    game.player.addComponent(SpriteComponent(sprite: sprite))
    game.player.component(ofType: SpriteComponent.self)!.shouldAnimateAway = false
    game.player.addComponent(TakesUpSpaceComponent())
    game.player.addComponent(PlayerComponent())
    game.player.addComponent(BumpDamageComponent(value: 20))
    game.player.addComponent(PowerComponent(power: playerTemplate?.powerC?.power ?? 100, isBattery: false, maxPower: 100))
    game.player.addComponent(MassComponent(weight: playerTemplate?.massC?.weight ?? 100))
    game.player.addComponent(AmmoComponent(value: playerTemplate?.ammoC?.value ?? 0, damage: 40))
    game.player.addComponent(HealthComponent(health: playerTemplate?.healthC?.health ?? 100, maxHealth: 100))

    game.exit = GKEntity()
    game.exit.addComponent(GridNodeComponent(gridNode: getNodeWithScore(1, { $0.gridPosition.manhattanDistanceTo(playerNode.gridPosition) })))
    game.exit.addComponent(SpriteComponent(sprite: PWRSpriteNode(.exit).withZ(Z.pickup)))


    if !isEverythingReachable(graph: game.gridGraph, start: game.player.gridNode!, canMovePast: {$0 != game.exit.gridNode}) {
      print("Regenerating map due to reachability issue")
      game.reset()
      MapGenerator.generate(scene: scene, game: game, n: n + 1, playerTemplate: playerTemplate)
      return
    }

    for batteryGridNode in getSomeNodes(numBatteries) {
      let battery = GKEntity()
      battery.addComponent(GridNodeComponent(gridNode: game.gridGraph.node(atGridPosition: batteryGridNode.gridPosition)))
      battery.addComponent(SpriteComponent(sprite: PWRSpriteNode(.powerupBattery).withZ(Z.pickup)))
      battery.addComponent(PowerComponent(power: 25, isBattery: true))
      battery.addComponent(PickupConsumableComponent())
      game.register(entity: battery)
    }

    let ammoNodes = getSomeNodes(numAmmos)
    for ammoNode in ammoNodes {
      let ammo = GKEntity()
      let value = game.random.nextInt(upperBound: 2) + 1
      ammo.addComponent(GridNodeComponent(gridNode: ammoNode))
      ammo.addComponent(SpriteComponent(sprite: PWRSpriteNode(value == 1 ? .ammo1 : .ammo2).withZ(Z.pickup)))
      ammo.addComponent(PickupConsumableComponent())
      ammo.addComponent(AmmoComponent(value: 2, damage: 40))
      game.register(entity: ammo)
    }

    let healthNodes = getSomeNodes(numHealthPacks)
    for healthNode in healthNodes {
      let health = GKEntity()
      health.addComponent(GridNodeComponent(gridNode: healthNode))
      health.addComponent(SpriteComponent(sprite: PWRSpriteNode(.powerupHealth).withZ(Z.pickup)))
      health.addComponent(PickupConsumableComponent())
      health.addComponent(HealthComponent(health: 50))
      game.register(entity: health)
    }

    var mobSpecs: [MobSpec] = [
      MobSpec(char: .mobButterfly, health: 40, isSlow: false, pathfinds: false, moves: [
        int2(-1, -1),
        int2(1, 1),
        int2(-1, 1),
        int2(1, -1),
      ]),
      MobSpec(char: .mobTurtle1, health: 40, isSlow: true, pathfinds: true, moves: [
        int2(-1, 0),
        int2(1, 0),
        int2(0, 1),
        int2(0, -1),
        ]),
    ]
    if game.difficulty > 3 {
      mobSpecs.append(MobSpec(char: .mobRabbit, health: 40, isSlow: false, pathfinds: false, moves: [
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
      mob.addComponent(HealthComponent(health: spec.health))
      mob.addComponent(BumpDamageComponent(value: 20))
      mob.addComponent(TakesUpSpaceComponent())
      mob.addComponent(PointValueComponent())
      if spec.isSlow {
        mob.addComponent(SpeedLimiterComponent(
          bucketSize: 2,
          stepCost: 1,
          bucketLeft: game.random.nextInt(upperBound: 2) + 1))
      } else {
        mob.addComponent(MoveTowardPlayerComponent(vectors: spec.moves))
      }
      if spec.pathfinds {
        mob.addComponent(MoveTowardPlayerComponent(vectors: spec.moves, pathfinding: true))
      }
      if spec.char == .mobTurtle1 {
        mob.addComponent(TurtleAnimationComponent())
      }
      let sprite = PWRSpriteNode(spec.char).withZ(Z.mob)
      let spriteC = SpriteComponent(sprite: sprite)
      sprite.color = SKColor.red
      spriteC.shouldAnimateAway = true
      mob.addComponent(spriteC)
      (mob.sprite as? SKLabelNode)?.color = SKColor.red
      game.register(entity: mob)
    }

    for drainNode in getSomeNodes(numDrains) {
      let drain = GKEntity()
      drain.addComponent(SpriteComponent(sprite: PWRSpriteNode(.bgDrain).withZ(Z.wall)))
      drain.addComponent(PowerComponent(power: -7, isBattery: true))
      drain.addComponent(GridNodeComponent(gridNode: drainNode))
      drain.addComponent(PickupConsumableComponent())
      game.register(entity: drain)
    }
    shuffledGridNodes = Array(shuffledGridNodes.dropFirst(numDrains))

    game.register(entity: game.player)
    game.register(entity: game.exit)
  }
}
