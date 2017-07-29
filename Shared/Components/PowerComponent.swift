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

  convenience init(power: CGFloat, isBattery: Bool) {
    self.init()
    self.power = power
    self.maxPower = power
    self.isBattery = isBattery
  }

  func getFractionRemaining() -> CGFloat { return power / maxPower }

  func getPowerRequired(toMove distance: CGFloat) -> CGFloat {
    return (self.entity?.massC?.weight ?? 0) * 0.01
  }

  func canUse(_ amount: CGFloat) -> Bool {
    return power >= amount
  }

  func use(_ amount: CGFloat) -> Bool {
    if !canUse(amount) { return false }
    power -= amount
    return true
  }

  func charge(_ amount: CGFloat) {
    power = max(min(maxPower, power + amount), 0)
  }

  func discharge() -> CGFloat {
    let p = power
    power = 0
    return p
  }
}
