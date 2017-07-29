//
//  Rules.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import GameplayKit
import SpriteKit


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
