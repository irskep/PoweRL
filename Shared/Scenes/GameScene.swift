//
//  GameScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/15/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

extension SKScene {
  func label(named: String) -> SKLabelNode? {
    return self.childNode(withName: "//\(named)") as? SKLabelNode
  }
}

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
    let point = self.convert(point, to: children.first!)
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
    self.label(named: "logo1")?.text = gameName
    self.label(named: "logo2")?.text = gameName

    (self.childNode(withName: "//robot") as? SKSpriteNode)?.texture = Assets16.get(.player).pixelized()
  }

  override func layoutForPortrait() {
    super.layoutForPortrait()
    if let logo1 = self.childNode(withName: "//logo1") {
      logo1.setScale(0.35)
      logo1.position = CGPoint(x: 0, y: 200)
    }
    if let logo2 = self.childNode(withName: "//logo2") {
      logo2.setScale(0.35)
      logo2.position = CGPoint(x: 8, y: 200 - 8)
    }
    if let robot = self.childNode(withName: "//robot") {
      robot.position = CGPoint(x: 0, y: 50)
      robot.setScale(0.5)
    }
    if let help = self.childNode(withName: "//help") {
      help.position = CGPoint(x: 0, y: -100)
      help.setScale(0.5)
    }
    if let start = self.childNode(withName: "//start") {
      start.position = CGPoint(x: 0, y: start.position.y)
      start.setScale(0.5)
    }
  }
}
