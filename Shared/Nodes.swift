//
//  Nodes.swift
//  iOS
//
//  Created by Steve Johnson on 8/6/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import SpriteKit


class MeterNode: SKSpriteNode {
  var getter: () -> CGFloat = { return 0 }
  var targetScale: CGFloat = 1

  convenience init(imageName: String?, color: SKColor, position: CGPoint, size: CGSize, getter: @escaping () -> CGFloat) {
    if let imageName = imageName {
      self.init(imageNamed: imageName)
    } else {
      self.init()
    }
    self.texture?.filteringMode = .nearest
    self.getter = getter
    self.color = color
    self.size = size
    self.anchorPoint = CGPoint(x: 0, y: 1)
    self.position = position
  }

  func update(instant: Bool) {
    let frac = getter()
    guard frac != targetScale else { return }
    guard !instant else {
      self.xScale = frac
      return
    }
    let action = SKAction.scaleX(to: frac, duration: MOVE_TIME)
    action.timingMode = .easeInEaseOut
    targetScale = frac
    self.run(action)
  }
}


class HUDNode: SKSpriteNode {
  private let game: GameModel

  private let fontSize: CGFloat = 8
  private let margin: CGFloat = 4
  private var width: CGFloat { return self.frame.size.width }
  private var height: CGFloat { return self.frame.size.height }

  private func _y(_ n: CGFloat) -> CGFloat { return floor(self.height) - self.margin * n }


  lazy var levelNumberLabel: SKLabelNode = {
    let label = SKLabelNode(fontNamed: "Coolville")
    label.fontSize = self.fontSize
    label.color = SKColor.white
    label.verticalAlignmentMode = .top
    label.position = CGPoint(x: self.frame.size.width / 2, y: _y(1))
    return label
  }()

  lazy var healthIcon: SKSpriteNode = {
    let node = SKSpriteNode(imageNamed: "icon-health").pixelized().withZ(1)
    node.position = CGPoint(x: 0, y: _y(3))
    node.anchorPoint = CGPoint(x: 0, y: 1)
    return node
  }()

  lazy var healthMeterNode: MeterNode = {
    return MeterNode(
      imageName: "health",
      color: SKColor.red,
      position: CGPoint(x: 8, y: _y(3)),
      size: CGSize(width: self.width - 9, height: 8),
      getter: { self.game.player.healthC?.getFractionRemaining() ?? 0 }).withZ(2)
  }()

  lazy var powerIcon: SKSpriteNode = {
    let node = SKSpriteNode(imageNamed: "icon-battery").pixelized().withZ(1)
    node.position = CGPoint(x: 0, y: _y(5) - 1)
    node.anchorPoint = CGPoint(x: 0, y: 1)
    return node
  }()
  lazy var powerMeterNode: MeterNode = {
    return MeterNode(
      imageName: "power",
      color: SKColor.cyan,
      position: CGPoint(x: 8, y: _y(5) - 1),
      size: CGSize(width: self.width - 9, height: 8),
      getter: { self.game.player.powerC?.getFractionRemaining() ?? 0 }).withZ(2)
  }()

  lazy var ammoLabel: SKLabelNode = {
    let label = SKLabelNode(fontNamed: "Coolville")
    label.fontSize = self.fontSize
    label.color = SKColor.white
    label.verticalAlignmentMode = .top
    label.text = "Ammo: 0"
    label.position = CGPoint(x: self.frame.size.width / 2, y: _y(8))
    return label
  }()

  lazy var line: SKSpriteNode = {
    print(self.frame)
    let line = PWRSpriteNode(texture: nil, color: SKColor.lightGray, size: CGSize(width: 1, height: self.height))
    line.position = CGPoint(x: self.width - 1, y: 0)
    line.zPosition = 1001
    return line
  }()

  required init(game: GameModel, size: CGSize) {
    self.game = game

    super.init(texture: nil, color: SKColor.clear, size: size)

    self.addGrid()

    self.addChild(line)
    self.addChild(levelNumberLabel)
    self.addChild(healthMeterNode)
    self.addChild(powerMeterNode)
    self.addChild(healthIcon)
    self.addChild(powerIcon)
    self.addChild(ammoLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func addGrid() {

    let flavorParent = SKNode()
    flavorParent.zPosition = -1
    self.addChild(flavorParent)
    var x: CGFloat = 0
    let tex = SKTexture(imageNamed: "hud-bg")
    tex.filteringMode = .nearest
    while x < size.width {
      var y: CGFloat = 0
      while y < size.height {
        let child = SKSpriteNode(texture: tex)
        child.size = tex.size()
        child.position = CGPoint(x: x, y: y)
        child.anchorPoint = CGPoint.zero
        flavorParent.addChild(child)
        y += tex.size().height
      }
      x += tex.size().width
    }
  }

  func update(instant: Bool) {
    powerMeterNode.update(instant: instant)
    healthMeterNode.update(instant: instant)
    ammoLabel.text = "Ammo: \(game.player.ammoC?.value ?? 0)"
  }
}
