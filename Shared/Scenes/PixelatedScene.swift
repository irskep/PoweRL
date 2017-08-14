//
//  PixelatedScene.swift
//  LD39
//
//  Created by Steve Johnson on 8/13/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

extension CGSize {
  var isLandscape: Bool { return width > height }
}

class PixelatedScene: AbstractScene {
  var positionCache: [String: CGPoint] = [:]
  var scaleCache: [String: CGFloat] = [:]
  var hasSetup = false

  func restorePositionAndScale() {
    self.visitAll({
      guard let name = $0.name, !name.isEmpty else { return }
      $0.position = self.positionCache[name] ?? $0.position
      $0.xScale = self.scaleCache[name] ?? $0.xScale
      $0.yScale = self.scaleCache[name] ?? $0.xScale
    })
  }

  override func didMove(to view: SKView) {
    super.didMove(to: view)
    if !frame.size.isLandscape {
      layoutForPortrait()
    }
  }

  override func setup() {
    super.setup()

    scaleMode = .fill

    self.visitAll({
      ($0 as? SKSpriteNode)?.texture?.filteringMode = .nearest
      guard let name = $0.name, !name.isEmpty else { return }
      self.positionCache[name] = $0.position
      self.scaleCache[name] = $0.xScale
    })

    fixScale()

    hasSetup = true
  }

  override func didChangeSize(_ oldSize: CGSize) {
    if !hasSetup { return }
    if frame.size.isLandscape {
      restorePositionAndScale()
      fixScale()
    } else {
      self.layoutForPortrait()
      fixScale()
    }
  }

  func fixScale() {
    #if os(iOS)
      let scale = UIScreen.main.bounds.size.height / (414 * 1.5)
      for child in self.children {
        child.position *= scale
        child.setScale(scale)
      }
    #endif
  }

  func layoutForPortrait() {
    // override
  }
}
