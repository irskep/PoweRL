//
//  HelpScene.swift
//  LD39
//
//  Created by Steve Johnson on 8/13/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

class HelpScene: PixelatedScene {
  class func create() -> HelpScene { return HelpScene(fileNamed: "HelpScene")! }

  override func motionAccept() {
    self.view?.presentScene(GameScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  override func motionIndicate(point: CGPoint) {
    self.motionAccept()
  }

  override func setup() {
    super.setup()


    #if os(iOS)
      (self.childNode(withName: "//clicktoshoot") as? SKLabelNode)?.text = "Tap to shoot"
      (self.childNode(withName: "//howtomove") as? SKLabelNode)?.text = "Swipe to move"
    #endif
  }
}
