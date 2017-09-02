//
//  Serialization.swift
//  LD39
//
//  Created by Steve Johnson on 9/2/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import GameplayKit
import SpriteKit


protocol Dictable: class {
  func toDict() -> [String: Any]
}
protocol Reconstructable: class { }


extension GKEntity: Dictable {
  convenience init?(dict: [String: Any]) {
    guard let componentDicts = dict["components"] as? [[String: Any]] else {
      return nil
    }
    self.init()

    for cd in componentDicts {
      if let c = self.parse(componentDict: cd) {
        self.addComponent(c)
      } else {
        print("Can't parse component: \(cd)")
        assert(false)
        return nil
      }
    }
  }

  func parse(componentDict dict: [String: Any]) -> GKComponent? {
    guard let name = dict["name"] as? String else { return nil }

    switch name {
    case "PickupConsumableComponent": return PickupConsumableComponent()
    case "TakesUpSpaceComponent": return TakesUpSpaceComponent()
    case "PlayerComponent": return PlayerComponent()
    case "ExitComponent": return ExitComponent()
    case "WallComponent": return WallComponent()
    case "TurtleAnimationComponent": return TurtleAnimationComponent()
    case "PointValueComponent": return PointValueComponent()
    default: break  // see switch below for cases that require innerDict
    }

    guard let innerDict = dict["value"] as? [String: Any] else { return nil }
    switch name {
    case "InitialGridPositionComponent": return InitialGridPositionComponent(dict: innerDict)
    case "MassComponent": return MassComponent(dict: innerDict)
    case "HealthComponent": return HealthComponent(dict: innerDict)
    case "AmmoComponent": return AmmoComponent(dict: innerDict)
    case "BumpDamageComponent": return BumpDamageComponent(dict: innerDict)
    case "SpeedLimiterComponent": return SpeedLimiterComponent(dict: innerDict)
    case "PowerComponent": return PowerComponent(dict: innerDict)
    case "MobSpecComponent": return MobSpecComponent(dict: innerDict)
    case "SpriteTypeComponent": return SpriteTypeComponent(dict: innerDict)
    default: return nil
    }
  }

  func toDict() -> [String: Any] {
    return [
      "components": self.components.flatMap({ (component) -> Any? in
        let name = "\(type(of: component))"
        if (component as? Reconstructable) != nil {
          return ["name": name]
        } else if let dictable = component as? Dictable {
          return ["name": name, "value": dictable.toDict()]
        } else {
          print("skipping", name)
          return nil
        }
      })
    ]
  }
}


extension MapState: Dictable {
  convenience init?(dict: [String: Any]) {
    guard let entityDicts = dict["entities"] as? [[String: Any]] else {
      return nil
    }
    self.init(entities: entityDicts.flatMap({ return GKEntity(dict: $0) }))
  }

  func toDict() -> [String: Any] {
    return ["entities": self.entities.map({ $0.toDict() })]
  }

  func json() -> String {
    let dict = self.toDict()
    let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    return String(data: data, encoding: .utf8)!
  }
}
