//
//  DeathScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

enum DeathReason: String {
  case health = "health"
  case power = "power"
}
class DeathScene: PixelatedScene {
  var deathReason: DeathReason = .health
  class func create(reason: DeathReason, score: Int) -> DeathScene {
    let scene = DeathScene(fileNamed: "DeathScene")!
    scene.deathReason = reason
    scene.score = score
    return scene
  }

  var score: Int {
    get { return 0 }
    set {
      (childNode(withName: "//score") as? SKLabelNode)?.text = "Score: \(newValue)"
      _ = HighScoreModel.shared.addScore(newValue)
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
    (childNode(withName: "//graphic") as? SKSpriteNode)?.texture = SKTexture(imageNamed: "lose-\(deathReason.rawValue)").pixelized()
    Player.shared.play("gameover")
  }

  override func layoutForPortrait() {
    super.layoutForPortrait()
    let isExtraSkinny = (self.view?.bounds.aspectRatioPortrait ?? 0) > 1.8
    childNode(withName: "//text")?.setScale(isExtraSkinny ? 0.3 : 0.5)
    childNode(withName: "//score")?.setScale(isExtraSkinny ? 0.3 : 0.5)
  }
}

