//
//  GameScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/15/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

class GameScene: AbstractScene {
  fileprivate var label : SKLabelNode?
  fileprivate var spinnyNode : SKShapeNode?

  class func create() -> GameScene { return GameScene(fileNamed: "GameScene")! }

  override func motionAccept() {
    self.view?.presentScene(MapScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  override func motionIndicate(point: CGPoint) {
    self.motionAccept()
  }

  override func setup() {
    super.setup()

    scaleMode = .aspectFit

    for child in children {
      (child as? SKSpriteNode)?.texture?.filteringMode = .nearest
      for grandchild in child.children {
        (grandchild as? SKSpriteNode)?.texture?.filteringMode = .nearest
      }
    }
    #if os(iOS)
      let scale = UIScreen.main.bounds.size.height / (414 * 1.5)
      for child in self.children {
        child.position *= scale
        child.setScale(scale)
      }
    #endif

    let gameName = "Power-Q"
    (self.childNode(withName: "//logo1") as? SKLabelNode)?.text = gameName
    (self.childNode(withName: "//logo2") as? SKLabelNode)?.text = gameName

    #if os(iOS)
      (self.childNode(withName: "//clicktoshoot") as? SKLabelNode)?.text = "Tap to shoot"
    #endif
  }
}
