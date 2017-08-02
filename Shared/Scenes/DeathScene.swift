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

class DeathScene: AbstractScene {
  override func motionAccept() {
    self.view?.presentScene(MapScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  override func motionIndicate(point: CGPoint) {
    self.motionAccept()
  }

  override func setup() {
    super.setup()
    Player.shared.get("gameover").play()
  }
}

