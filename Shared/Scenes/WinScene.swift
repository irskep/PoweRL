//
//  WinScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/30/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

class WinScene: AbstractScene {
  override func motionAccept() {
    self.view?.presentScene(MapScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  override func motionIndicate(point: CGPoint) {
    self.motionAccept()
  }

  override func setup() {
    super.setup()
    Player.shared.get("win").play()
  }
}

