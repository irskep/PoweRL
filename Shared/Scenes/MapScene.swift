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

extension int2 {
  init(_ point: CGPoint) {
    self.init(Int32(point.x), Int32(point.y))
  }
}

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

protocol MapScening {
  var tileSize: CGFloat { get }
  var fontSize: CGFloat { get }
  func gridSprite(at position: int2) -> SKSpriteNode?
  func createLabelNode(_ text: String, _ color: SKColor) -> SKLabelNode
  func visualPoint(forPosition position: int2) -> CGPoint
}

class MapScene: AbstractScene, MapScening {
  var game: GameModel!
  var bgMusic: AVAudioPlayer!

  lazy var tileSize: CGFloat = { return self.frame.size.height / CGFloat(self.game.mapSize.y) }()
  var tileScale: CGFloat { return tileSize / 16 }
  lazy var fontSize: CGFloat = { return (24.0 / 314) * self.frame.size.height }()
  var margin: CGFloat { return (16.0 / 314.0) * self.frame.size.height }
  var pixel: CGFloat { return tileSize / 64 }

  var gridNodes: [CGPoint: SKSpriteNode] = [:]
  var mapSizeVisual: CGSize { return CGSize(width: CGFloat(game.mapSize.x) * tileSize, height: CGFloat(game.mapSize.y) * tileSize) }

  func createLabelNode(_ text: String, _ color: SKColor) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "Coolville")
    node.fontColor = color
    node.verticalAlignmentMode = .center
    node.fontSize = self.fontSize
    node.text = text
    return node
  }

  @discardableResult
  func addHUDLabel(text: String, y: CGFloat) -> SKLabelNode {
    let label = SKLabelNode(fontNamed: "Coolville")
    label.fontSize = self.fontSize
    label.color = SKColor.white
    label.verticalAlignmentMode = .top
    label.text = text
    label.position = CGPoint(x: self.hudSize.width / 2, y: y)
    self.addChild(label)
    return label
  }

  lazy var healthIcon: SKSpriteNode = {
    let node = SKSpriteNode(imageNamed: "icon-health").pixelized().scaled(self.tileScale).withZ(1)
    node.position = CGPoint(x: 0, y: self.hudSize.height - self.margin * 4)
    node.anchorPoint = CGPoint(x: 0, y: 1)
    return node
  }()
  lazy var healthMeterNode: MeterNode = {
    return MeterNode(
      imageName: "health",
      color: SKColor.red,
      position: CGPoint(x: 8 * self.tileScale, y: self.hudSize.height - self.margin * 4),
      size: CGSize(width: self.hudSize.width - 8 * self.tileScale, height: self.tileScale * 8),
      getter: { self.game.player.healthC?.getFractionRemaining() ?? 0 }).withZ(2)
  }()

  lazy var powerIcon: SKSpriteNode = {
    let node = SKSpriteNode(imageNamed: "icon-battery").pixelized().scaled(self.tileScale).withZ(1)
    node.position = CGPoint(x: 0, y: self.hudSize.height - self.margin * 6)
    node.anchorPoint = CGPoint(x: 0, y: 1)
    return node
  }()
  lazy var powerMeterNode: MeterNode = {
    return MeterNode(
      imageName: "power",
      color: SKColor.cyan,
      position: CGPoint(x: 8 * self.tileScale, y: self.hudSize.height - self.margin * 6),
      size: CGSize(width: self.hudSize.width - 8 * self.tileScale, height: self.tileScale * 8),
      getter: { self.game.player.powerC?.getFractionRemaining() ?? 0 }).withZ(2)
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
      color: SKColor.clear,
      size: self.hudSize)
    node.anchorPoint = CGPoint.zero

    let flavorParent = SKNode()
    flavorParent.zPosition = -1
    node.addChild(flavorParent)
    var x: CGFloat = 0
    let tex = SKTexture(imageNamed: "hud-bg")
    tex.filteringMode = .nearest
    while x < hudSize.width {
      var y: CGFloat = 0
      while y < hudSize.height {
        let child = SKSpriteNode(texture: tex)
        child.size = tex.size() * self.tileScale / 2
        child.position = CGPoint(x: x, y: y)
        child.anchorPoint = CGPoint.zero
        flavorParent.addChild(child)
        y += tex.size().height * self.tileScale / 2
      }
      x += tex.size().width * self.tileScale / 2
    }

    let line = SKShapeNode(rect: CGRect(x: node.frame.size.width - 1, y: 0, width: 1, height: node.frame.size.height))
    line.strokeColor = SKColor.lightGray
    line.zPosition = 1000
    node.addChild(line)
    return node
  }()

  lazy var levelNumberLabel: SKLabelNode = {
    let label = SKLabelNode(fontNamed: "Coolville")
    label.fontSize = self.fontSize
    label.color = SKColor.white
    label.verticalAlignmentMode = .top
    label.position = CGPoint(x: self.hudSize.width / 2, y: self.hudSize.height - self.margin)
    return label
  }()

  var ammoLabel: SKLabelNode!

  lazy var hoverIndicatorSprites: [SKSpriteNode] = {
    return Array((0..<30).map({
      _ in
      let node = SKSpriteNode(color: SKColor.yellow, size: CGSize(width: self.tileSize, height: self.tileSize))
      node.alpha = 0.2
      node.isHidden = true
      node.zPosition = Z.player
      return node
    }))
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
    hudContainerNode.addChild(healthIcon)
    hudContainerNode.addChild(powerIcon)
    self.ammoLabel = self.addHUDLabel(text: "Ammo: 0", y: powerMeterNode.position.y - self.margin * 3)

    hoverIndicatorSprites.forEach(mapContainerNode.addChild)

    levelNumberLabel.text = "Level \(self.game.difficulty)"

    for x in 0..<game.mapSize.x {
      for y in 0..<game.mapSize.y {
        let node = SKSpriteNode(imageNamed: "ground1").pixelized().scaled(self.tileScale)
        node.position = self.visualPoint(forPosition: int2(x, y))
        node.zPosition = 0
        self.mapContainerNode.addChild(node)
        self.gridNodes[CGPoint(x: CGFloat(x), y: CGFloat(y))] = node
      }
    }

    game.start(scene: self)
    self.updateVisuals(instant: true)

    let screenCover = SKSpriteNode(color: SKColor.black, size: mapContainerNode.frame.size)
    screenCover.anchorPoint = CGPoint.zero
    screenCover.zPosition = 3000
    mapContainerNode.addChild(screenCover)
    screenCover.run(SKAction.fadeOut(withDuration: MOVE_TIME), completion: {
      screenCover.removeFromParent()
    })

    if bgMusic == nil, let musicURL = Bundle.main.url(forResource: "1", withExtension: "mp3") {
      bgMusic = try? AVAudioPlayer(contentsOf: musicURL)
      bgMusic.volume = 0.5
      bgMusic.numberOfLoops = -1
      bgMusic.enableRate = true
      bgMusic.rate = 1
      bgMusic.play()
    }

    Player.shared.get("up1", useCache: false).play()
    
  }

  func gridSprite(at position: int2) -> SKSpriteNode? {
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

  override func motionToggleMusic() {
    if bgMusic?.isPlaying == true {
      bgMusic?.pause()
    } else {
      bgMusic?.play()
    }
  }

  private var _lastTargetedPoint: int2? = nil
  private func _hideTargetingLaser() {
    for s in hoverIndicatorSprites { s.isHidden = true }
  }
  func eventPointToGrid(point: CGPoint) -> int2? {
    var visualPointInMap = self.convert(point, to: mapContainerNode)
    visualPointInMap.y = mapContainerNode.frame.size.height - visualPointInMap.y
    let gridPos = int2(Int32(visualPointInMap.x / tileSize), Int32(visualPointInMap.y / tileSize))
    guard gridPos.x >= 0 && gridPos.y >= 0 && gridPos.x < game.gridGraph.gridWidth && gridPos.y < game.gridGraph.gridHeight else { return nil }
    return gridPos
  }
  override func motionLook(point: CGPoint) {
    guard let gridPos = eventPointToGrid(point: point) else {
      if _lastTargetedPoint != nil {
        _lastTargetedPoint = nil
        _hideTargetingLaser()
      }
      return
    }
    _hideTargetingLaser()
    for (i, p) in game.getTargetingLaserPoints(to: gridPos).enumerated() {
      if let s = gridSprite(at: p) {
        hoverIndicatorSprites[i].position = s.position
        hoverIndicatorSprites[i].isHidden = false
      }
    }
    _lastTargetedPoint = gridPos
  }

  var lastPointIndicated: int2? = nil
  override func motionIndicate(point: CGPoint) {
    guard let gridPos = eventPointToGrid(point: point) else { return }
    let path = game.getTargetingLaserPoints(to: gridPos)
    guard !path.isEmpty else { return }

    if isTouch {
      if lastPointIndicated == gridPos {
        game.shoot(target: path.last!, path: path)
        lastPointIndicated = nil
      } else {
        lastPointIndicated = gridPos
        self.motionLook(point: point)
      }
    } else {
      game.shoot(target: path.last!, path: path)
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
    healthMeterNode.update(instant: instant)
    ammoLabel.text = "Ammo: \(game.player.ammoC?.value ?? 0)"

    let power: Float = Float(game.player.powerC?.getFractionRemaining() ?? 1)
    if power > 0.3 {
      bgMusic?.rate = 1
    } else {
      bgMusic?.rate = 0.9
    }
  }

  func evaluatePossibleTransitions() {  // aka 'turnDidEnd'
    _hideTargetingLaser()

    if let playerPower = game.player.powerC?.power, playerPower <= 0 {
      self.gameOver()
    } else if let playerHealth = game.player.healthC?.health, playerHealth <= 0 {
      self.gameOver()
    } else if game.player.gridNode == game.exit.component(ofType: GridNodeComponent.self)?.gridNode {
      game.end()

      if game.difficulty > 7 {
        bgMusic?.stop()
        self.view?.presentScene(WinScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
      } else {
        self.view?.presentScene(MapScene.create(from: self), transition: SKTransition.crossFade(withDuration: 0.5))
      }
    }
  }

  func gameOver() {
    bgMusic?.stop()
    game.end()
    self.view?.presentScene(DeathScene.create(), transition: SKTransition.crossFade(withDuration: 0.5))
  }

  func flashMessage(_ text: String, color: SKColor = SKColor.red) {
    let node = createLabelNode(text, color.blended(withFraction: 0.2, of: SKColor.white)!)
    node.verticalAlignmentMode = .center
    node.position = CGPoint(x: mapSizeVisual.width / 2, y: mapSizeVisual.height / 2)
    node.zPosition = 2000
    mapContainerNode.addChild(node)
    node.run(
      SKAction.group([
        SKAction.fadeOut(withDuration: 1),
        SKAction.moveBy(x: 0, y: tileSize * 3, duration: 1)
      ]),
      completion: { node.removeFromParent() })
  }

  #if os(OSX)
  var trackingArea: NSTrackingArea?
  override func didMove(to view: SKView) {
    let trackingArea = NSTrackingArea(rect: view.frame, options: [.activeInKeyWindow, .mouseMoved], owner: self, userInfo: nil)
    view.addTrackingArea(trackingArea)
    self.trackingArea = trackingArea
    super.didMove(to: view)

    NotificationCenter.default.addObserver(self, selector: #selector(MapScene.resetTrackingArea), name: NSWindow.didResizeNotification, object: nil)
  }

  @objc func resetTrackingArea() {
    guard let oldTrackingArea = self.trackingArea, let view = self.view else { return }
    view.removeTrackingArea(oldTrackingArea)
    let trackingArea = NSTrackingArea(rect: view.frame, options: [.activeInKeyWindow, .mouseMoved], owner: self, userInfo: nil)
    view.addTrackingArea(trackingArea)
    self.trackingArea = trackingArea
  }

  override func willMove(from view: SKView) {
    view.removeTrackingArea(trackingArea!)
    NotificationCenter.default.removeObserver(self)
    super.willMove(from: view)
  }
  #endif
}
