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
    guard
      let game = system.state["game"] as? GameModel,
      let entities = game.player.gridNode?.entities
      else { return false }
    let wantedEntities: [GKEntity] = entities.filter({ $0 != game.player && self.getIsEntityRelevant($0) })
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
      let amt = battery.powerC?.discharge() ?? 0
      game.player.powerC?.charge(amt)
      if amt > 0 {
        Player.shared.get("up2", useCache: false).play()
        game.scene?.flashMessage("+\(Int(amt)) power", color: SKColor.cyan)
      } else {
        Player.shared.get("down", useCache: false).play()
        game.scene?.flashMessage("\(Int(amt)) power")
      }
      if let pickupC = battery.component(ofType: PickupConsumableComponent.self) {
        pickupC.isPickedUp = true
      }
    }
  }
}


class AmmoTransferRule: GridNodeSharingRule {
  required override init() {
    super.init()
    self.salience = 1001
  }

  override func getIsEntityRelevant(_ e: GKEntity) -> Bool {
    if let ammoVal = e.ammoC?.value { return ammoVal > 0 } else { return false }
  }

  override func performAction(inGame game: GameModel, withEntities entities: [GKEntity]) {
    for ammo in entities.flatMap({ $0.ammoC }) {
      let amt = ammo.value
      game.player.ammoC?.transfer(from: ammo)
      Player.shared.get("up3", useCache: false).play()
      game.scene?.flashMessage("+\(amt) ammo", color: SKColor(red: 218 / 255, green: 1, blue: 0, alpha: 1))
      if let pickupC = ammo.entity?.component(ofType: PickupConsumableComponent.self) {
        pickupC.isPickedUp = true
      }
    }
  }
}


class ConsumableHealthTransferRule: GridNodeSharingRule {
  required override init() {
    super.init()
    self.salience = 1002
  }

  override func getIsEntityRelevant(_ e: GKEntity) -> Bool {
    if let healthVal = e.healthC?.health { return healthVal > 0 } else { return false }
  }

  override func performAction(inGame game: GameModel, withEntities entities: [GKEntity]) {
    for health in entities.flatMap({ $0.healthC }) {
      if let pickupC = health.entity?.component(ofType: PickupConsumableComponent.self) {
        pickupC.isPickedUp = true
      } else {
        continue  // ignore
      }
      game.player.healthC?.heal(health.health)
      Player.shared.get("select2", useCache: false).play()
      game.scene?.flashMessage("+\(Int(health.health)) health", color: SKColor.green)
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
