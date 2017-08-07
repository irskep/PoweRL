//
//  BitmapFont.swift
//  LD39
//
//  Created by Steve Johnson on 8/6/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import SpriteKit


class BitmapFont {
  let texture: SKTexture
  let glyphSize: CGSize

  init(imageNamed imageName: String, glyphSize: CGSize) {
    self.glyphSize = glyphSize
    self.texture = SKTexture(imageNamed: imageName)
  }
}
