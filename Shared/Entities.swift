//
//  Entities.swift
//  macOS
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import GameplayKit
import SpriteKit


class GridNode: GKGridGraphNode {

}
func +(left: int2, right: int2) -> int2 {
  return int2(left.x + right.x, left.y + right.y)
}

class GridNodeComponent: GKComponent {
  var gridNode: GridNode?

  required init(gridNode: GridNode?) {
    self.gridNode = gridNode
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class SpriteComponent: GKComponent {
  var sprite: SKNode

  required init(sprite: SKNode) {
    self.sprite = sprite
    super.init()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension GKEntity {
  func get<T: GKComponent>() -> T? {
    return component(ofType: T.self)
  }
}

class Actor: GKEntity {
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

  var sprite: SKNode {
    get {
      let spriteComponent: SpriteComponent? = self.get()
      return spriteComponent!.sprite
    }
  }
}
