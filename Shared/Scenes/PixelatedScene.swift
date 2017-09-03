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

class OrientationAwareAbstractScene: AbstractScene {
  var hasSetup = false

  var isLandscape: Bool { return self.frame.size.isLandscape }

  override func didMove(to view: SKView) {
    super.didMove(to: view)
    if frame.size.isLandscape {
      layoutForLandscape()
    } else {
      layoutForPortrait()
    }
  }

  override func setup() {
    super.setup()
    hasSetup = true
  }

  override func didChangeSize(_ oldSize: CGSize) {
    if !hasSetup { return }
    if frame.size.isLandscape {
      self.layoutForLandscape()
    } else {
      self.layoutForPortrait()
    }
  }

  func layoutForLandscape() {
    // override
  }

  func layoutForPortrait() {
    // override
  }

  func transformMotion(_ m: Motion) -> Motion {
    if isLandscape {
      return m
    } else {
      switch m {
      case .down: return .left
      case .left: return .up
      case .up: return .right
      case .right: return .down
      }
    }
  }
}

class PixelatedScene: OrientationAwareAbstractScene {
  var positionCache: [String: CGPoint] = [:]
  var scaleCache: [String: CGFloat] = [:]

  func restorePositionAndScale() {
    self.visitAll({
      guard let name = $0.name, !name.isEmpty else { return }
      $0.position = self.positionCache[name] ?? $0.position
      $0.xScale = self.scaleCache[name] ?? $0.xScale
      $0.yScale = self.scaleCache[name] ?? $0.xScale
    })
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
  }

  override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    guard let height = self.view?.bounds.size.height else {
      return
    }
    let scale = height / 621
    for child in self.children {
      child.position *= scale
      child.setScale(scale)
    }
  }

  func fixScale() {
    guard let height = self.view?.bounds.size.height else {
      return
    }
    let scale = height / 621
    for child in self.children {
      child.position *= scale
      child.setScale(scale)
    }
  }

  override func layoutForLandscape() {
    fixScale()
    restorePositionAndScale()
  }

  override func layoutForPortrait() {
    fixScale()
  }
}
