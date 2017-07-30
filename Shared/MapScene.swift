//
//  MapScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/28/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

extension CGPoint {
  init(_ position: int2) {
    self.init(x: CGFloat(position.x), y: CGFloat(position.y))
  }
}

class GridSprite: SKSpriteNode {
  let label: SKLabelNode
  let cover: SKSpriteNode
  var text: String? {
    get { return label.text }
    set { label.text = newValue }
  }
  var backgroundColor: SKColor? {
    get { return cover.color }
    set { cover.color = newValue ?? SKColor.black }
  }
  required init(node: SKLabelNode, size: CGSize) {
    label = node
    cover = SKSpriteNode(texture: nil, color: SKColor.black, size: size - CGSize(width: 1, height: 1))
    super.init(texture: nil, color: SKColor.darkGray, size: size)
    addChild(cover)
    addChild(label)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class MeterNode: SKSpriteNode {
  var getter: () -> CGFloat = { return 0 }
  var targetScale: CGFloat = 1

  convenience init(color: SKColor, width: CGFloat, height: CGFloat, y: CGFloat, getter: @escaping () -> CGFloat) {
    self.init()
    self.getter = getter
    self.color = color
    self.size = CGSize(width: width, height: height)
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
  var game: GameModel!
  var bgMusic: AVAudioPlayer!

  lazy var tileSize: CGFloat = { return self.frame.size.height / CGFloat(self.game.mapSize.y) }()
  lazy var fontSize: CGFloat = { return (36.0 / 314) * self.frame.size.height }()
  var margin: CGFloat { return (16.0 / 314.0) * self.frame.size.height }
  var pixel: CGFloat { return tileSize / 64 }

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

  func addHUDLabel(text: String, y: CGFloat) {
    let label = SKLabelNode(fontNamed: "Menlo")
    label.fontSize = self.fontSize / 3
    label.color = SKColor.white
    label.verticalAlignmentMode = .top
    label.text = text
    label.position = CGPoint(x: self.hudSize.width / 2, y: y)
    self.addChild(label)
  }

  lazy var powerMeterNode: MeterNode = {
    return MeterNode(
      color: SKColor.cyan,
      width: self.hudSize.width,
      height: self.margin,
      y: self.hudSize.height - self.margin * 5,
      getter: { self.game.player.powerC?.getFractionRemaining() ?? 0 })
  }()

  lazy var mapContainerNode: SKSpriteNode = {
    let mapContainerNode = SKSpriteNode(color: SKColor.black, size: self.mapSizeVisual)
    mapContainerNode.position = CGPoint(x: self.frame.size.width - self.mapSizeVisual.width, y: 0)
    mapContainerNode.anchorPoint = CGPoint.zero
    return mapContainerNode
  }()

  var hudSize: CGSize { return CGSize(
    width: self.frame.size.width - self.mapSizeVisual.width,
    height: self.frame.size.height) }

  lazy var hudContainerNode: SKSpriteNode = {
    let node = SKSpriteNode(
      color: SKColor.darkGray,
      size: self.hudSize)
    node.anchorPoint = CGPoint.zero
    return node
  }()

  lazy var levelNumberLabel: SKLabelNode = {
    let label = SKLabelNode(fontNamed: "Menlo")
    label.fontSize = self.fontSize / 2
    label.color = SKColor.white
    label.verticalAlignmentMode = .top
    label.position = CGPoint(x: self.hudSize.width / 2, y: self.hudSize.height - self.margin)
    return label
  }()

  lazy var healthMeterNode: MeterNode = {
    return MeterNode(
      color: SKColor.red,
      width: self.hudSize.width,
      height: self.margin,
      y: self.hudSize.height - self.margin * 3,
      getter: { self.game.player.healthC?.getFractionRemaining() ?? 0 })
  }()

  class func create(from mapScene: MapScene) -> MapScene {
    let scene: MapScene = MapScene.create()
    scene.game = GameModel(difficulty: mapScene.game.difficulty + 1, player: mapScene.game.player)
    scene.bgMusic = mapScene.bgMusic
    return scene
  }

  override func setup() {
    if game == nil { game = GameModel(difficulty: 1, player: nil) }
    super.setup()
    scaleMode = .aspectFit
    self.anchorPoint = CGPoint.zero

    self.addChild(mapContainerNode)
    self.addChild(hudContainerNode)
    hudContainerNode.addChild(levelNumberLabel)
    hudContainerNode.addChild(healthMeterNode)
    hudContainerNode.addChild(powerMeterNode)
    self.addHUDLabel(text: "Health", y: healthMeterNode.position.y - self.pixel * 2)
    self.addHUDLabel(text: "Power", y: powerMeterNode.position.y - self.pixel * 2)
    self.addHUDLabel(text: "Arrow keys move.", y: self.margin * 3)
    self.addHUDLabel(text: "Click shoots.", y: self.margin * 2)

    levelNumberLabel.text = "Level \(self.game.difficulty)"

    for x in 0..<game.mapSize.x {
      for y in 0..<game.mapSize.y {
        let node = GridSprite(node: self.createLabelNode(" ", SKColor.lightGray), size: CGSize(width: self.tileSize, height: self.tileSize))
        node.position = self.visualPoint(forPosition: int2(x, y))
        self.mapContainerNode.addChild(node)
        self.gridNodes[CGPoint(x: CGFloat(x), y: CGFloat(y))] = node
      }
    }

    game.start(scene: self)
    // migrate all previous scenes' crossover sprites to current font size in case the user
    // resized the window
    (game.player.sprite as! SKLabelNode).fontSize = self.fontSize
    self.updateVisuals(instant: true)

    if bgMusic == nil, let musicURL = Bundle.main.url(forResource: "1", withExtension: "mp3") {
      bgMusic = try? AVAudioPlayer(contentsOf: musicURL)
      bgMusic.volume = 0.5
      bgMusic.numberOfLoops = -1
      bgMusic.enableRate = true
      bgMusic.rate = 1
//      bgMusic.play()
    }

    Player.shared.get("up1", useCache: false).play()
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

    let power: Float = Float(game.player.powerC?.getFractionRemaining() ?? 1)
    if power > 0.5 {
      bgMusic?.rate = 1
    } else if power > 0.25 {
      bgMusic?.rate = 0.9
    } else {
      bgMusic?.rate = 0.8
    }
  }

  func evaluatePossibleTransitions() {
    if let playerPower = game.player.powerC?.power, playerPower <= 0 {
      bgMusic?.stop()
      self.gameOver()
    } else if let playerHealth = game.player.healthC?.health, playerHealth <= 0 {
      self.gameOver()
    } else if game.player.gridNode == game.exit.component(ofType: GridNodeComponent.self)?.gridNode {
      game.end()
      self.view?.presentScene(MapScene.create(from: self), transition: SKTransition.crossFade(withDuration: 0.5))
    }
  }

  func gameOver() {
    game.end()
    self.view?.presentScene(DeathScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }
}
