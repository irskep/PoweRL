//
//  PixelatedScene.swift
//  LD39
//
//  Created by Steve Johnson on 8/13/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

class PixelatedScene: AbstractScene {

  override func setup() {
    super.setup()

    scaleMode = .aspectFit

    var visitor: ((SKNode) -> ())!
    let visit = {
      (child: SKNode) in
      (child as? SKSpriteNode)?.texture?.filteringMode = .nearest
      child.children.forEach(visitor)
    }
    visitor = visit
    children.forEach(visit)
    #if os(iOS)
      let scale = UIScreen.main.bounds.size.height / (414 * 1.5)
      for child in self.children {
        child.position *= scale
        child.setScale(scale)
      }
    #endif
  }
}
