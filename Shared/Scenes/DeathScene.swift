//
//  DeathScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import AVFoundation

class Player {
  
  static var shared = { Player() }()

  var cache: [String: AVAudioPlayer] = [:]

  func get(_ name: String, useCache: Bool = true) -> AVAudioPlayer {
    if useCache && cache[name] != nil { return cache[name]! }

    let player = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: name, withExtension: "mp3")!)
    player.volume = 0.5
    cache[name] = player
    return player
  }
}

enum DeathReason: String {
  case health = "health"
  case power = "power"
}
class DeathScene: PixelatedScene {
  var deathReason: DeathReason = .health
  class func create(reason: DeathReason) -> DeathScene {
    let scene = DeathScene(fileNamed: "DeathScene")!
    scene.deathReason = reason
    return scene
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
    Player.shared.get("gameover").play()
  }
}

