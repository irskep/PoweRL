//
//  WinScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/30/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

class WinScene: PixelatedScene {
  class func create(score: Int) -> WinScene {
    let scene = WinScene(fileNamed: "WinScene")!
    scene.score = score
    return scene
  }

  var score: Int {
    get { return 0 }
    set {
      (childNode(withName: "//score") as? SKLabelNode)?.text = "Score: \(newValue)"
      HighScoreModel.shared.addScore(newValue)
    }
  }
  
  override func motionAccept() {
    self.view?.presentScene(GameScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  override func motionIndicate(point: CGPoint) {
    self.motionAccept()
  }

  override func setup() {
    super.setup()
    Player.shared.get("win").play()
    (childNode(withName: "//robot") as? SKSpriteNode)?.texture = Assets16.get(.player)
  }

  override func layoutForPortrait() {
    super.layoutForPortrait()
    childNode(withName: "//text")?.setScale(0.5)
    childNode(withName: "//score")?.setScale(0.5)
  }
}

