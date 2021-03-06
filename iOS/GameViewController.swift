//
//  GameViewController.swift
//  LD39
//
//  Created by Steve Johnson on 7/15/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)

    let scene: GameScene = GameScene.create()

    // Present the scene
    let skView = self.view as! SKView
    skView.presentScene(scene)

    skView.ignoresSiblingOrder = true
  }

  override var shouldAutorotate: Bool {
    return true
  }

  override func prefersHomeIndicatorAutoHidden() -> Bool {
    return true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    (self.view as! SKView).scene?.size = self.view.bounds.size

    // hax: correct transforms on nodes
    ((self.view as? SKView)?.scene as? OrientationAwareAbstractScene)?.didChangeSize(self.view.bounds.size)
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return .allButUpsideDown
    } else {
      return .all
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }
}
