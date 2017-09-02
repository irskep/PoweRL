//
//  PowerComponent.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import GameplayKit


class PowerComponent: GKComponent {
  var power: CGFloat = 0
  var maxPower: CGFloat = 0
  var isBattery: Bool = false
  var isFull: Bool { return power >= maxPower }
  var neverChanges: Bool = false

  convenience init(power: CGFloat, isBattery: Bool, maxPower: CGFloat? = nil, neverChanges: Bool = false) {
    self.init()
    self.power = power
    self.maxPower = maxPower ?? power
    self.isBattery = isBattery
    self.neverChanges = neverChanges
  }

  func getFractionRemaining() -> CGFloat { return power / maxPower }

  func getPowerRequired(toMove distance: CGFloat) -> CGFloat {
    return (self.entity?.massC?.weight ?? 0) * 0.02
  }

  func canUse(_ amount: CGFloat) -> Bool {
    return power >= amount
  }

  func use(_ amount: CGFloat) -> Bool {
    if !canUse(amount) { return false }
    if !neverChanges {
      power -= amount
    }
    return true
  }

  func charge(_ amount: CGFloat) {
    power = max(min(maxPower, power + amount), 0)
  }

  func discharge() -> CGFloat {
    guard !neverChanges else { return power }
    let p = power
    power = 0
    return p
  }
}
