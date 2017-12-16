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

extension CGRect {
  var aspectRatioPortrait: CGFloat { return height / width }
  var aspectRatioLandscape: CGFloat { return width / height }
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
    
    scaleMode = .aspectFit

    if UserDefaults.pwr_isMusicEnabled {
      MusicPlayer.shared.prepare(track: "loading")
      MusicPlayer.shared.play()
    }

    let gameName = "Power-Q"
    self.label(named: "logo1")?.text = gameName
    self.label(named: "logo2")?.text = gameName

    (self.childNode(withName: "//robot") as? SKSpriteNode)?.texture = Assets16.get(.player)
    if HighScoreModel.shared.scores.count > 0 {
      let highScore = HighScoreModel.shared.scores.first ?? 0
      (self.childNode(withName: "//score") as? SKLabelNode)?.text = "High Score: \(highScore)"
    } else {
      (self.childNode(withName: "//score") as? SKLabelNode)?.text = ""
    }

    if self.getSaveExists(id: "continuous"), let dict = self.loadSave(id: "continuous"), let mapState = MapState(dict: dict) {
      self.view?.presentScene(MapScene.create(mapState: mapState), transition: SKTransition.crossFade(withDuration: 0.5))
    }
  }

  override func layoutForPortrait() {
    super.layoutForPortrait()
    let isExtraSkinny = (self.view?.bounds.aspectRatioPortrait ?? 0) > 1.8

    if let logo1 = self.childNode(withName: "//logo1") {
      logo1.setScale(isExtraSkinny ? 0.25 : 0.35)
      logo1.position = CGPoint(x: 0, y: 200)
    }
    if let logo2 = self.childNode(withName: "//logo2") {
      logo2.setScale(isExtraSkinny ? 0.25 : 0.35)
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

      if let score = self.childNode(withName: "//score") as? SKLabelNode {
        score.position = start.position + CGPoint(x: 0, y: -40)
        score.setScale(0.7)
      }
    }
  }
}
