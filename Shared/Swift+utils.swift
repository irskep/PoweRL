//
//  Swift+utils.swift
//  iOS
//
//  Created by Steve Johnson on 8/6/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit


class PWRSpriteNode: SKSpriteNode {
  @IBInspectable
  var asset16Name: String? {
    didSet {
      if let val = asset16Name, let asset = _Assets16(rawValue: val) {
        self.texture = Assets16.get(asset)
      }
    }
  }

  convenience init(_ t: _Assets16) {
    self.init(texture: Assets16.get(t))
  }

  required override init(texture: SKTexture?, color: SKColor, size: CGSize) {
    super.init(texture: texture, color: color, size: size)
    self.texture?.filteringMode = .nearest
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.texture?.filteringMode = .nearest
  }
}


class PixelyLabelNode: SKSpriteNode {
  lazy var backingLabel: SKLabelNode = {
    let label = SKLabelNode(fontNamed: "Coolville")
    label.fontSize = 10
    label.color = self.color
    label.verticalAlignmentMode = .top
    return label
  }()

  weak var view: SKView?

  required init(view: SKView?, text: String = "", color: SKColor = SKColor.white) {
    self.text = text
    self.view = view
    super.init(texture: nil, color: color, size: CGSize.zero)

    if !text.isEmpty {
      self._updateTexture()
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func _updateTexture() {
    backingLabel.text = text
    backingLabel.fontColor = color
    self.texture = self.view?.texture(from: backingLabel)
    if let tex = self.texture {
      tex.filteringMode = .nearest
      self.size = tex.size()
    }
  }

  var text: String {
    didSet { self._updateTexture() }
  }

  override var color: SKColor {
    didSet { self._updateTexture() }
  }
}


extension UserDefaults {
  static var pwr_isMusicEnabled: Bool {
    // store inverted so default is true
    get { return !UserDefaults.standard.bool(forKey: "isMusicDisabled") }
    set { UserDefaults.standard.set(!newValue, forKey: "isMusicDisabled") }
  }
}

extension CGSize {
  var point: CGPoint { return CGPoint(x: width, y: height) }
}

extension CGPoint {
  init(_ position: int2) {
    self.init(x: CGFloat(position.x), y: CGFloat(position.y))
  }
}

extension int2 {
  init(_ point: CGPoint) {
    self.init(Int32(point.x), Int32(point.y))
  }
}

extension SKTexture {
  func pixelized() -> SKTexture {
    self.filteringMode = .nearest
    return self
  }
}

extension SKSpriteNode {
  func pixelized() -> SKSpriteNode {
    self.texture?.filteringMode = .nearest
    return self
  }

  func scaled(_ s: CGFloat) -> Self {
    self.setScale(s)
    return self
  }

  func withZ(_ z: CGFloat) -> Self {
    self.zPosition = z
    return self
  }

  func withAnchor(_ x: CGFloat, _ y: CGFloat) -> Self {
    self.anchorPoint = CGPoint(x: x, y: y)
    return self
  }

  func nudge(_ direction: int2, amt: CGFloat = 0.5, t: TimeInterval = MOVE_TIME) -> SKAction {
    let vector = CGPoint(
      x: CGFloat(direction.x) * frame.size.width * amt,
      y: CGFloat(direction.y) * frame.size.height * amt)
    let actionOut = SKAction.move(to: position + vector, duration: t / 2)
    let actionIn = SKAction.move(to: position, duration: t / 2)
    return SKAction.sequence([actionOut, actionIn])
  }
}

extension int2 {
  func manhattanDistanceTo(_ other: int2) -> Int {
    return abs(Int(self.x) - Int(other.x)) + abs(Int(self.y) - Int(other.y))
  }
}
