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

  func setSize(newSize: CGSize) {
    let oldScale = xScale
    xScale = 1
    size = newSize
    xScale = oldScale
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
  private weak var view: SKView?

  private let fontSize: CGFloat = 8
  private let margin: CGFloat = 4
  private var width: CGFloat { return self.frame.size.width }
  private var height: CGFloat { return self.frame.size.height }

  private func _y(_ n: CGFloat) -> CGFloat { return floor(self.height) - self.margin * n }

  lazy var levelNumberLabel: PixelyLabelNode = { return PixelyLabelNode(view: view) }()

  lazy var scoreIcon: SKSpriteNode = { return SKSpriteNode(imageNamed: "score").pixelized().withZ(1).withAnchor(0, 1) }()
  lazy var scoreLabel: PixelyLabelNode = { return PixelyLabelNode(view: view).withAnchor(0, 1) }()

  lazy var healthIcon: SKSpriteNode = {
    return SKSpriteNode(imageNamed: "icon-health").pixelized().withZ(1).withAnchor(0, 1)
  }()
  lazy var healthMeterNode: MeterNode = {
    return MeterNode(
      imageName: "health",
      color: SKColor.red,
      position: CGPoint(x: 9, y: _y(3)),
      size: CGSize(width: self.width - 10, height: 8),
      getter: { self.game.player.healthC?.getFractionRemaining() ?? 0 }).withZ(2)
  }()

  lazy var powerIcon: SKSpriteNode = {
    return SKSpriteNode(imageNamed: "icon-battery").pixelized().withZ(1).withAnchor(0, 1)
  }()
  lazy var powerMeterNode: MeterNode = {
    return MeterNode(
      imageName: "power",
      color: SKColor.cyan,
      position: CGPoint(x: 9, y: _y(5) - 1),
      size: CGSize(width: self.width - 10, height: 8),
      getter: { self.game.player.powerC?.getFractionRemaining() ?? 0 }).withZ(2)
  }()

  lazy var ammoIcon: SKSpriteNode = {
    return SKSpriteNode(imageNamed: "icon-ammo").pixelized().withZ(1).withAnchor(0, 1)
  }()

  lazy var ammoLabel: PixelyLabelNode = {
    let label = PixelyLabelNode(view: self.view).withAnchor(0, 1)
    label.color = SKColor(red: 218 / 255, green: 1, blue: 0, alpha: 1)
    return label
  }()

  lazy var musicIcon: SKSpriteNode = {
    return SKSpriteNode(imageNamed: "icon-music-on").pixelized().withZ(1).withAnchor(0, 0)
  }()

  lazy var line: SKSpriteNode = {
    return PWRSpriteNode(
      texture: nil, color: SKColor.lightGray, size: CGSize(width: 1, height: self.height)
    ).withAnchor(0, 0).withZ(1001)
  }()

  required init(view: SKView?, game: GameModel, size: CGSize) {
    self.view = view
    self.game = game

    super.init(texture: nil, color: SKColor.clear, size: size)

    scoreLabel.color = SKColor.green

    self.addChild(line)
    self.addChild(levelNumberLabel)
    self.addChild(scoreIcon)
    self.addChild(scoreLabel)
    self.addChild(healthMeterNode)
    self.addChild(powerMeterNode)
    self.addChild(healthIcon)
    self.addChild(powerIcon)
    self.addChild(ammoIcon)
    self.addChild(ammoLabel)
    self.addChild(musicIcon)
  }

  func layoutForLandscape() {
    var y: CGFloat = 0
    levelNumberLabel.position = CGPoint(x: self.frame.size.width / 2, y: _y(y) - 1)
    levelNumberLabel.anchorPoint = CGPoint(x: 0.5, y: 1)

    y += 2
    scoreIcon.position = CGPoint(x: 9, y: _y(y) - 1)
    scoreLabel.position = CGPoint(x: scoreIcon.position.x + 20, y: scoreIcon.position.y + 1)

    y += 2
    healthIcon.position = CGPoint(x: 0, y: _y(y))
    healthMeterNode.position = CGPoint(x: 9, y: _y(y))

    y += 2
    powerIcon.position = CGPoint(x: 0, y: _y(y) - 1)
    powerMeterNode.position = CGPoint(x: 9, y: _y(y) - 1)

    y += 2
    ammoIcon.position = CGPoint(x: 0, y: _y(y) - 1)
    ammoLabel.position = CGPoint(x: 8, y: _y(y) - 2)
    musicIcon.position = CGPoint(x: 1, y: 1)
    line.size = CGSize(width: 1, height: self.height)
    line.position = CGPoint(x: self.width - 1, y: 0)

    for meter in [healthMeterNode, powerMeterNode] {
      meter.setSize(newSize: CGSize(width: self.width - 10, height: 8))
    }

    self.addGrid()
  }

  func layoutForPortrait() {
    levelNumberLabel.position = CGPoint(x: 1, y: 1)
    levelNumberLabel.anchorPoint = CGPoint(x: 0, y: 0)
    
    ammoIcon.position = CGPoint(x: 43, y: self.height - 2)
    ammoLabel.position = CGPoint(x: 51, y: self.height - 3)

    healthIcon.position = CGPoint(x: 0, y: self.height - 2)
    healthMeterNode.position = CGPoint(x: 9, y: self.height - 2)
    powerIcon.position = CGPoint(x: 0, y: self.height - 11)
    powerMeterNode.position = CGPoint(x: 9, y: self.height - 11)
    
    scoreIcon.position = CGPoint(x: 1, y: self.height - 24)
    scoreLabel.position = CGPoint(x: scoreIcon.position.x + 20, y: scoreIcon.position.y + 1)

    musicIcon.position = CGPoint(x: width - 9, y: 1)

    line.size = CGSize(width: self.width, height: 1)
    line.position = CGPoint(x: 0, y: self.height - 1)

    for meter in [healthMeterNode, powerMeterNode] {
      meter.setSize(newSize: CGSize(width: 32, height: 8))
    }

    addGrid()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var gridsAdded = Set<CGPoint>()
  private func addGrid() {

    let flavorParent = SKNode()
    flavorParent.zPosition = -1
    self.addChild(flavorParent)
    var x: CGFloat = 0
    let tex = Assets16.get(.bgHUD)
    tex.filteringMode = .nearest
    while x < size.width {
      var y: CGFloat = 0
      while y < size.height {
        let p = CGPoint(x: x, y: y)
        if !gridsAdded.contains(p) {
          let child = SKSpriteNode(texture: tex)
          child.size = tex.size()
          child.position = p
          child.anchorPoint = CGPoint.zero
          flavorParent.addChild(child)
          gridsAdded.insert(p)
        }
        y += tex.size().height
      }
      x += tex.size().width
    }
  }

  func update(instant: Bool) {
    powerMeterNode.update(instant: instant)
    healthMeterNode.update(instant: instant)
    scoreLabel.text = "\(game.score)"
    ammoLabel.text = "\(game.player.ammoC?.value ?? 0)"
  }

  func motionIndicate(_ point: CGPoint) {
    if musicIcon.frame.contains(point) {
      (scene as? MapScene)?.motionToggleMusic()
    }
  }
}
