//
//  GameScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/15/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

class GameScene: PixelatedScene {
  fileprivate var label : SKLabelNode?
  fileprivate var spinnyNode : SKShapeNode?

  class func create() -> GameScene { return GameScene(fileNamed: "GameScene")! }

  override func motionAccept() {
    self.view?.presentScene(MapScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  override func motionIndicate(point: CGPoint) {
    guard
      let startNode = self.childNode(withName: "//start") as? SKLabelNode,
      let helpNode = self.childNode(withName: "//help") as? SKLabelNode
      else { return }
    if startNode.frame.contains(point) {
      self.motionAccept()
      return
    } else if helpNode.frame.contains(point) {
      self.view?.presentScene(HelpScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
    }
  }

  override func setup() {
    super.setup()

    let gameName = "Power-Q"
    (self.childNode(withName: "//logo1") as? SKLabelNode)?.text = gameName
    (self.childNode(withName: "//logo2") as? SKLabelNode)?.text = gameName
  }
}
