//
//  Entities.swift
//  macOS
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import GameplayKit
import SpriteKit

extension GKEntity {
  func get<T: GKComponent>() -> T? {
    return component(ofType: T.self)
  }

  var powerC: PowerComponent? { return self.component(ofType: PowerComponent.self) }
  var healthC: HealthComponent? { return self.component(ofType: HealthComponent.self) }
  var massC: MassComponent? { return self.component(ofType: MassComponent.self) }

  var gridNode: GridNode? {
    get {
      let gridNodeComponent: GridNodeComponent? = self.get()
      return gridNodeComponent?.gridNode
    }
    set {
      let gridNodeComponent: GridNodeComponent? = self.get()
      gridNodeComponent?.gridNode = newValue
    }
  }

  var position: int2? { get { return gridNode?.gridPosition } }

  var sprite: SKNode? {
    get {
      let spriteComponent: SpriteComponent? = self.get()
      return spriteComponent!.sprite
    }
  }
}
