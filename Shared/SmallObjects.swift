//
//  SmallObjects.swift
//  LD39
//
//  Created by Steve Johnson on 9/2/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit


struct MobSpec {
  let char: _Assets16
  let health: CGFloat
  let isSlow: Bool
  let pathfinds: Bool
  let moves: [int2]
}
extension MobSpec {
  init?(dict: [String: Any]) {
    guard
      let charString = dict["char"] as? String,
      let char = _Assets16(rawValue: charString),
      let health = dict["health"] as? CGFloat,
      let isSlow = dict["isSlow"] as? Bool,
      let pathfinds = dict["pathfinds"] as? Bool,
      let movesList = dict["moves"] as? [[String: Any]]
      else {
        return nil
    }
    let moves = movesList.flatMap({ int2(dict: $0) })
    guard moves.count == movesList.count else { return nil }
    self.init(char: char, health: health, isSlow: isSlow, pathfinds: pathfinds, moves: moves)
  }

  func toDict() -> [String: Any] {
    return [
      "char": char.rawValue,
      "health": health,
      "isSlow": isSlow,
      "pathfinds": pathfinds,
      "moves": moves.map({ $0.toDict() }),
    ]
  }
}


struct Z {
  static let floor: CGFloat = 0
  static let wall: CGFloat = 100
  static let pickup: CGFloat = 200
  static let mob: CGFloat = 300
  static let player: CGFloat = 4000
}


class GridNode: GKGridGraphNode {
  var entities = Set<GKEntity>()

  func add(_ entity: GKEntity) {
    entities.insert(entity)
  }

  func remove(_ entity: GKEntity) {
    entities.remove(entity)
  }

  func removeAllEntities() {
    self.entities = Set()
  }
}
