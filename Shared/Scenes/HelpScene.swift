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

    scaleMode = .aspectFit

    #if os(iOS)
      (self.childNode(withName: "//clicktoshoot") as? SKLabelNode)?.text = "Tap 2x to shoot"
      (self.childNode(withName: "//howtomove") as? SKLabelNode)?.text = "Swipe to move"
    #endif

    visitAll {
      guard let node = $0 as? SKSpriteNode, let asset = _Assets16(rawValue: node.name ?? "n/a")
        else { return }
      node.texture = Assets16.get(asset)
    }
  }

  override func layoutForPortrait() {
    super.layoutForPortrait()
    let isExtraSkinny = (self.view?.bounds.aspectRatioPortrait ?? 0) > 1.8
    if let logo1 = self.childNode(withName: "//logo1") {
      logo1.setScale(0.35)
      logo1.position = CGPoint(x: 0, y: 200)
    }
    if let logo2 = self.childNode(withName: "//logo2") {
      logo2.setScale(0.35)
      logo2.position = CGPoint(x: 8, y: 200 - 8)
    }
    if let content = self.childNode(withName: "//content") {
      content.setScale(isExtraSkinny ? 0.4 : 0.5)
    }
  }
}
