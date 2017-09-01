//
//  GameViewController.swift
//  macOS
//
//  Created by Steve Johnson on 7/15/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Present the scene
    let skView = self.view as! SKView
    skView.presentScene(GameScene.create())
//    skView.presentScene(MapScene.create())
//    skView.presentScene(DeathScene.create(reason: .health, score: 99))
//    skView.presentScene(WinScene.create(score: 99))

    skView.ignoresSiblingOrder = true
  }

}

