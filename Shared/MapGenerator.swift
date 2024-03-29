//
//  MapGenerator.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit

let mobSpecs: [MobSpec] = [
  MobSpec(char: .mobButterfly, health: 40, isSlow: false, pathfinds: false, minDifficulty: 0, moves: [
    int2(-1, -1),
    int2(1, 1),
    int2(-1, 1),
    int2(1, -1),
    ]),
  MobSpec(char: .mobTurtle1, health: 40, isSlow: true, pathfinds: true, minDifficulty: 0, moves: [
    int2(-1, 0),
    int2(1, 0),
    int2(0, 1),
    int2(0, -1),
    ]),
  MobSpec(char: .mobRabbit, health: 40, isSlow: false, pathfinds: false, minDifficulty: 3, moves: [
    int2(-1, -2),
    int2(1, -2),
    int2(-1, 2),
    int2(1, 2),
    int2(-2, -1),
    int2(2, -1),
    int2(-2, 1),
    int2(2, 1),
    ]),
]


func make2dArray<T>(cols: Int, rows: Int, val: T) -> Array<Array<T>> {
  var outer: [[T]] = []
  for _ in 0..<cols {
    var inner: [T] = []
    for _ in 0..<rows {
      inner.append(val)
    }
    outer.append(inner)
  }
  return outer
}
extension int2: Hashable {
  public var hashValue: Int {
    return CGPoint(x: CGFloat(x), y: CGFloat(y)).hashValue
  }
}
func isEverythingReachable(size: int2, entities: [GKEntity]) -> Bool {
  var grid = make2dArray(cols: Int(size.x), rows: Int(size.y), val: true)
  let get: (int2) -> Bool = {
    if $0.x < 0 || Int($0.x) >= grid.count { return false }
    if $0.y < 0 || Int($0.y) >= grid[0].count { return false }
    return grid[Int($0.x)][Int($0.y)]
  }

  var maybePlayerPos: int2? = nil
  for e in entities {
    if let p = e.component(ofType: InitialGridPositionComponent.self)?.position {
      if e.component(ofType: WallComponent.self) != nil || e.component(ofType: ExitComponent.self) != nil {
        grid[Int(p.x)][Int(p.y)] = false
      }

      if e.component(ofType: PlayerComponent.self) != nil {
        maybePlayerPos = p
      }
    }
  }
  guard let playerPos = maybePlayerPos else {
    return false
  }

  var unvisitedNodes = Set<int2>()
  for x in 0..<size.x { for y in 0..<size.y { unvisitedNodes.insert(int2(x: x, y: y)) } }
  var stack: Array<int2> = [playerPos]

  while let pos = stack.popLast() {
    if !unvisitedNodes.contains(pos) { continue }
    unvisitedNodes.remove(pos)

    if !get(pos) { continue }
    for neighbor in [pos + int2(-1, 0), pos + int2(1, 0), pos + int2(0, -1), pos + int2(0, 1)] {
      stack.append(neighbor)
    }
  }

  return unvisitedNodes.isEmpty
}


func setupMob(entity: GKEntity, spec: MobSpec, random: GKRandomSource) {
  entity.addComponent(HealthComponent(health: spec.health))
  entity.addComponent(BumpDamageComponent(value: 20))
  entity.addComponent(TakesUpSpaceComponent())
  entity.addComponent(PointValueComponent())
  if spec.isSlow {
    entity.addComponent(SpeedLimiterComponent(
      bucketSize: 2,
      stepCost: 1,
      bucketLeft: random.nextInt(upperBound: 2) + 1))
  }
  entity.addComponent(MoveTowardPlayerComponent(vectors: spec.moves, pathfinding: spec.pathfinds))
  if spec.char == .mobTurtle1 {
    entity.addComponent(TurtleAnimationComponent())
  }
}


func addSprite(toEntity entity: GKEntity) {
  if let specC = entity.component(ofType: MobSpecComponent.self) {
    let sprite = PWRSpriteNode(specC.spec.char).withZ(Z.mob)
    let spriteC = SpriteComponent(sprite: sprite)
    sprite.color = SKColor.red
    spriteC.shouldAnimateAway = true
    entity.addComponent(spriteC)
  } else if let spriteTypeC = entity.component(ofType: SpriteTypeComponent.self) {
    let sprite = PWRSpriteNode(spriteTypeC.asset).withZ(spriteTypeC.z)
    let c = SpriteComponent(sprite: sprite)
    c.shouldAnimateAway = spriteTypeC.shouldAnimateAway
    entity.addComponent(c)
  }
}


func addGridNode(toEntity entity: GKEntity, inGame game: GameModel) {
  guard
    let posC = entity.component(ofType: InitialGridPositionComponent.self),
    let position = posC.position,
    let gridNode = game.gridGraph.node(atGridPosition: position)
    else { return }
  entity.removeComponent(ofType: InitialGridPositionComponent.self)
  entity.addComponent(GridNodeComponent(gridNode: gridNode))
}


class MapState {
  var entities: [GKEntity] = []
  var difficulty: Int
  var score: Int

  init(difficulty: Int, score: Int, entities: [GKEntity]) {
    self.entities = entities
    self.difficulty = difficulty
    self.score = score
  }

  func apply(toGame game: GameModel) {
    game.difficulty = difficulty
    game.score = score
    for entity in entities {
      if let spec = entity.component(ofType: MobSpecComponent.self)?.spec {
        setupMob(entity: entity, spec: spec, random: game.random)
      }

      addSprite(toEntity: entity)
      addGridNode(toEntity: entity, inGame: game)
      if entity.component(ofType: WallComponent.self) != nil, let gridNode = entity.gridNode {
        game.gridGraph.remove([gridNode])
      }

      // this also does a bunch of stuff
      game.register(entity: entity)

      if entity.component(ofType: PlayerComponent.self) != nil {
        game.player = entity
      }
      if entity.component(ofType: ExitComponent.self) != nil {
        game.exit = entity
      }
    }
  }
}


class MapGenerator {
  class func generate(difficulty: Int, score: Int, size: int2, playerTemplate: GKEntity?, random: GKRandomSource, n: Int = 0) -> MapState {
    assert(n < 20)
    let area: Int32 = size.x * size.y
    let getAreaFraction = { (frac: CGFloat) -> Int in return Int(CGFloat(area) * frac) }
    let numBatteries = 2
    let numAmmos = 2
    let numHealthPacks = 1
    // 25% of cells are walls
    let numWalls = getAreaFraction(0.25)
    // 10% + difficulty * 1.5% are power drains
    let numDrains = getAreaFraction(0.1 + 0.015 * CGFloat(difficulty))

    let numEnemies = difficulty

    var shuffledGridPositions: [int2] = []
    for x in 0..<size.x {
      for y in 0..<size.y {
        shuffledGridPositions.append(int2(x: x, y: y))
      }
    }
    shuffledGridPositions = random.arrayByShufflingObjects(in: shuffledGridPositions) as! [int2]

    let getSomePositions = { (n: Int, verboten: Set<int2>) -> [int2] in
      let val = Array(shuffledGridPositions[0..<min(shuffledGridPositions.count, n)])
        .filter({ !verboten.contains($0) })
      shuffledGridPositions = Array(shuffledGridPositions.dropFirst(n))
      return val
    }

    let getBestPosition = { (n: Int, getScore: (int2) -> Int) -> int2 in
      var maxScore: Int = getScore(shuffledGridPositions[0])
      var bestNode = shuffledGridPositions[0]
      for node in shuffledGridPositions {
        let score = getScore(node)
        if score > maxScore {
          maxScore = score
          bestNode = node
        }
      }
      shuffledGridPositions = Array(shuffledGridPositions.filter({ $0 != bestNode }))
      return bestNode
    }

    var allEntities: [GKEntity] = []

    allEntities += getSomePositions(numWalls, Set()).map({
      let wall = GKEntity()
      wall.addComponent(WallComponent())
      wall.addComponent(InitialGridPositionComponent(position: $0))
      wall.addComponent(SpriteTypeComponent(asset: .bgWall, z: Z.wall))
      return wall
    })

    let playerPosition = getSomePositions(1, Set())[0]
    let player = GKEntity()
    player.addComponent(SpriteTypeComponent(asset: .player, z: Z.player))
    player.addComponent(InitialGridPositionComponent(position: playerPosition))
    player.addComponent(TakesUpSpaceComponent())
    player.addComponent(PlayerComponent())
    player.addComponent(BumpDamageComponent(value: 20))
    player.addComponent(PowerComponent(power: playerTemplate?.powerC?.power ?? 100, isBattery: false, maxPower: 100))
    player.addComponent(MassComponent(weight: playerTemplate?.massC?.weight ?? 100))
    player.addComponent(AmmoComponent(value: playerTemplate?.ammoC?.value ?? 0, damage: 40))
    player.addComponent(HealthComponent(health: playerTemplate?.healthC?.health ?? 100, maxHealth: 100))
    allEntities += [player]

    let exit = GKEntity()
    exit.addComponent(ExitComponent())
    exit.addComponent(InitialGridPositionComponent(position: getBestPosition(1, { $0.manhattanDistanceTo(playerPosition) })))
    exit.addComponent(SpriteTypeComponent(asset: .exit, z: Z.pickup))
    allEntities += [exit]

    if !isEverythingReachable(size: size, entities: allEntities) {
//      print("Regenerating map due to reachability issue")
      return MapGenerator.generate(difficulty: difficulty, score: score, size: size, playerTemplate: playerTemplate, random: random, n: n + 1)
    }

    allEntities += getSomePositions(numBatteries, Set()).map({
      let battery = GKEntity()
      battery.addComponent(InitialGridPositionComponent(position: $0))
      battery.addComponent(SpriteTypeComponent(asset: .powerupBattery, z: Z.pickup, shouldAnimateAway: false))
      battery.addComponent(PowerComponent(power: 25, isBattery: true))
      battery.addComponent(PickupConsumableComponent())
      return battery
    })

    allEntities += getSomePositions(numAmmos, Set()).map({
      let ammo = GKEntity()
      let value = random.nextInt(upperBound: 2) + 1
      ammo.addComponent(InitialGridPositionComponent(position: $0))
      ammo.addComponent(SpriteTypeComponent(asset: value == 1 ? .ammo1 : .ammo2, z: Z.pickup))
      ammo.addComponent(PickupConsumableComponent())
      ammo.addComponent(AmmoComponent(value: value, damage: 40))
      return ammo
    })

    allEntities += getSomePositions(numHealthPacks, Set()).map({
      let health = GKEntity()
      health.addComponent(InitialGridPositionComponent(position: $0))
      health.addComponent(SpriteTypeComponent(asset: .powerupHealth, z: Z.pickup))
      health.addComponent(PickupConsumableComponent())
      health.addComponent(HealthComponent(health: 50))
      return health
    })

    var iters = 0
    var i = 0
    while i < numEnemies {
      iters += 1
      if iters > 1000 {
//        print("Regenerating map due to enemy placement issue")
        return MapGenerator.generate(difficulty: difficulty, score: score, size: size, playerTemplate: playerTemplate, random: random, n: n + 1)
      }
      let specsForThisLevel = mobSpecs.filter({ $0.minDifficulty <= difficulty })
      let spec = specsForThisLevel[random.nextInt(upperBound: specsForThisLevel.count)]
      let verbotenPositions = Set<int2>(spec.moves.map({ playerPosition &- $0 }))
      if let pos = getSomePositions(1, verbotenPositions).first {
        let mob = GKEntity()
        mob.addComponent(MobSpecComponent(spec: spec))
        mob.addComponent(InitialGridPositionComponent(position: pos))
        allEntities += [mob]
        i += 1
      }
    }

    allEntities += getSomePositions(numDrains, Set()).map({
      let drain = GKEntity()
      drain.addComponent(SpriteTypeComponent(asset: .bgDrain, z: Z.wall))
      drain.addComponent(PowerComponent(power: -7, isBattery: true))
      drain.addComponent(InitialGridPositionComponent(position: $0))
      drain.addComponent(PickupConsumableComponent())
      return drain
    })

    return MapState(difficulty: difficulty, score: score, entities: allEntities)
  }
}
