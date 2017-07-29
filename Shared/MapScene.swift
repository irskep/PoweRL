//
//  MapScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/28/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit

extension CGPoint {
  init(_ position: int2) {
    self.init(x: CGFloat(position.x), y: CGFloat(position.y))
  }
}

class GridSprite: SKSpriteNode {
  let label: SKLabelNode
  var text: String? {
    get { return label.text }
    set { label.text = newValue }
  }
  required init(node: SKLabelNode, size: CGSize) {
    label = node
    super.init(texture: nil, color: SKColor.darkGray, size: size)
    let blackCover = SKSpriteNode(texture: nil, color: SKColor.black, size: size - CGSize(width: 1, height: 1))
    addChild(blackCover)
    addChild(label)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class MeterNode: SKSpriteNode {
  var getter: () -> CGFloat = { return 0 }
  var targetScale: CGFloat = 1

  convenience init(color: SKColor, width: CGFloat, y: CGFloat, getter: @escaping () -> CGFloat) {
    self.init()
    self.getter = getter
    self.color = color
    self.size = CGSize(width: width, height: 16)
    self.anchorPoint = CGPoint(x: 0, y: 1)
    self.position = CGPoint(x: 0, y: y)
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

protocol MapScening {
  var tileSize: CGFloat { get }
  var fontSize: CGFloat { get }
  func gridSprite(at position: int2) -> GridSprite?
  func createLabelNode(_ text: String, _ color: SKColor) -> SKLabelNode
  func visualPoint(forPosition position: int2) -> CGPoint
}

class MapScene: AbstractScene, MapScening {
  lazy var tileSize: CGFloat = { return self.frame.size.height / CGFloat(self.game.mapSize.y) }()
  lazy var fontSize: CGFloat = { return (36.0 / 314) * self.frame.size.height }()

  var gridNodes: [CGPoint: GridSprite] = [:]
  var mapSizeVisual: CGSize { return CGSize(width: CGFloat(game.mapSize.x) * tileSize, height: CGFloat(game.mapSize.y) * tileSize) }

  func createLabelNode(_ text: String, _ color: SKColor) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "Menlo")
    node.fontColor = color
    node.verticalAlignmentMode = .center
    node.fontSize = self.fontSize
    node.text = text
    return node
  }

  lazy var mapContainerNode: SKSpriteNode = {
    let mapContainerNode = SKSpriteNode(color: SKColor.black, size: self.mapSizeVisual)
    mapContainerNode.position = CGPoint(x: self.frame.size.width - self.mapSizeVisual.width, y: 0)
    mapContainerNode.anchorPoint = CGPoint.zero
    return mapContainerNode
  }()

  lazy var hudContainerNode: SKSpriteNode = {
    let node = SKSpriteNode(
      color: SKColor.darkGray,
      size: CGSize(
        width: self.frame.size.width - self.mapSizeVisual.width,
        height: self.frame.size.height))
    node.anchorPoint = CGPoint.zero
    return node
  }()

  lazy var healthMeterNode: MeterNode = {
    return MeterNode(
      color: SKColor.red,
      width: self.hudContainerNode.size.width,
      y: self.hudContainerNode.size.height - 16,
      getter: { self.game.player.healthC?.getFractionRemaining() ?? 0 })
  }()

  lazy var powerMeterNode: MeterNode = {
    return MeterNode(
      color: SKColor.cyan,
      width: self.hudContainerNode.size.width,
      y: self.hudContainerNode.size.height - 48,
      getter: { self.game.player.powerC?.getFractionRemaining() ?? 0 })
  }()

  var game: GameModel!

  class func create(player: GKEntity) -> MapScene {
    let scene: MapScene = MapScene.create()
    scene.game = GameModel(player: player)
    return scene
  }

  override func setup() {
    if game == nil { game = GameModel(player: nil) }
    super.setup()
    self.anchorPoint = CGPoint.zero

    self.addChild(mapContainerNode)
    self.addChild(hudContainerNode)
    hudContainerNode.addChild(healthMeterNode)
    hudContainerNode.addChild(powerMeterNode)

    for x in 0..<game.mapSize.x {
      for y in 0..<game.mapSize.y {
        let node = GridSprite(node: self.createLabelNode(" ", SKColor.lightGray), size: CGSize(width: self.tileSize, height: self.tileSize))
        node.position = self.visualPoint(forPosition: int2(x, y))
        self.mapContainerNode.addChild(node)
        self.gridNodes[CGPoint(x: CGFloat(x), y: CGFloat(y))] = node
      }
    }

    game.start(scene: self)
    self.updateVisuals(instant: true)
  }

  func gridSprite(at position: int2) -> GridSprite? {
    return gridNodes[CGPoint(position)]
  }

  func visualPoint(forPosition position: int2) -> CGPoint {
    let point = CGPoint(position)
    let rawPoint = point * self.tileSize + CGPoint(x: self.tileSize / 2, y: self.tileSize / 2)
    return CGPoint(x: rawPoint.x, y: self.mapSizeVisual.height - rawPoint.y)
  }

  override func motion(_ m: Motion) {
    game.movePlayer(by: m.vector) {
      [weak self] in self?._moveAgain(m)
    }
  }

  private func _moveAgain(_ m: Motion) {
    if isHolding(m: m) == true {
      motion(m)
      return
    }
    for m in Motion.all {
      if isHolding(m: m) == true {
        motion(m)
        return
      }
    }
  }

  var lastTime: TimeInterval? = nil
  override func update(_ currentTime: TimeInterval) {
    guard let lastTime = lastTime else {
      self.lastTime = currentTime
      return
    }
    game.update(deltaTime: currentTime - lastTime)
    self.lastTime = currentTime

    updateVisuals()
  }

  func updateVisuals(instant: Bool = false) {
    powerMeterNode.update(instant: instant)
  }

  func evaluatePossibleTransitions() {
    if let playerPower = game.player.powerC?.power, playerPower <= 0 {
      game.end()
      self.view?.presentScene(DeathScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
    } else if let playerHealth = game.player.healthC?.health, playerHealth <= 0 {
      game.end()
      self.view?.presentScene(DeathScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
    } else if game.player.gridNode == game.exit.component(ofType: GridNodeComponent.self)?.gridNode {
      game.end()
      self.view?.presentScene(MapScene.create(player: game.player), transition: SKTransition.crossFade(withDuration: 0.5))
    }
  }
}