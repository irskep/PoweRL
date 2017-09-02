//
//  MapScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/28/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit
import GameplayKit

class MapScene: OrientationAwareAbstractScene {
  class func create() -> MapScene { return MapScene(fileNamed: "MapScene")! }

  // MARK: vars
  
  var game: GameModel!
  let root = SKNode()
  var isDead = false

  var adjustedSize: CGSize { return isLandscape ? frame.size : CGSize(width: frame.size.height, height: frame.size.width) }
  let tileSize = CGSize(width: 16, height: 16)
  var mapPixelSize: CGSize {
    return CGSize(
      width: CGFloat(game.mapSize.x) * tileSize.width,
      height: CGFloat(game.mapSize.y) * tileSize.height)
  }
  var screenScale: CGFloat { return self.adjustedSize.height / self.mapPixelSize.height }
  var screenPixelSize: CGSize {
    return CGSize(width: self.adjustedSize.width / self.screenScale, height: self.mapPixelSize.height)
  }

  var gridNodes: [CGPoint: PWRSpriteNode] = [:]
  var hudSize: CGSize { return self.screenPixelSize - CGSize(width: self.mapPixelSize.width, height: 0) }
  lazy var hudNode: HUDNode = {
    return HUDNode(view: self.view, game: self.game, size: self.hudSize)
  }()

  lazy var mapContainerNode: SKSpriteNode = {
    let mapContainerNode = SKSpriteNode(color: SKColor.black, size: self.mapPixelSize)
    mapContainerNode.anchorPoint = CGPoint.zero
//    let mapFrame = SKSpriteNode(color: SKColor.red, size: mapContainerNode.size + CGSize(width: 2, height: 2))
//    mapFrame.anchorPoint = CGPoint.zero
//    mapContainerNode.addChild(mapFrame)
//    mapFrame.position = CGPoint(x: -1, y: -1)
    return mapContainerNode
  }()

  lazy var hoverIndicatorSprites: [PWRSpriteNode] = { self._createHoverIndicatorSprites() }()

  // MARK: init

  class func create(from mapScene: MapScene) -> MapScene {
    let scene: MapScene = MapScene.create()
    scene.game = GameModel(difficulty: mapScene.game.difficulty + 1, player: mapScene.game.player, score: mapScene.game.score)
    return scene
  }

  override func setup() {
    if game == nil { game = GameModel(difficulty: 1, player: nil, score: 0) }
    super.setup()
//    if let filter = CIFilter(name: "CIColorMonochrome") {
//      // colorblind test
//      self.shouldEnableEffects = true
//      filter.setDefaults()
//      filter.setValue(CIColor(color: SKColor.white), forKey: kCIInputColorKey)
//      self.filter = filter
//    }
    scaleMode = .aspectFit

    self.anchorPoint = CGPoint.zero
    self.addChild(root)
    root.addChild(mapContainerNode)
    root.addChild(hudNode)
    root.setScale(screenScale)

    hoverIndicatorSprites.forEach(mapContainerNode.addChild)

    for x in 0..<game.mapSize.x {
      for y in 0..<game.mapSize.y {
        let node = PWRSpriteNode(.bgGround)
        node.position = self.spritePoint(forPosition: int2(x, y))
        node.zPosition = 0
        self.mapContainerNode.addChild(node)
        self.gridNodes[CGPoint(x: CGFloat(x), y: CGFloat(y))] = node
      }
    }

    game.start(scene: self)
    self.updateVisuals(instant: true)

    let screenCover = SKSpriteNode(color: SKColor.black, size: mapContainerNode.frame.size * 2)
    screenCover.position = mapContainerNode.frame.size.point / 2
    screenCover.zPosition = Z.player - 1
    mapContainerNode.addChild(screenCover)
    screenCover.run(SKAction.fadeOut(withDuration: MOVE_TIME), completion: {
      screenCover.removeFromParent()
    })

    MusicPlayer.shared.prepare(track: "1")
    MusicPlayer.shared.play()
    _updateMusicTexture()

    Player.shared.get("up1", useCache: false).play()
  }

  private func _updateMusicTexture() {
    self.hudNode.musicIcon.texture = SKTexture(imageNamed: UserDefaults.pwr_isMusicEnabled ? "icon-music-on" : "icon-music-off").pixelized()
  }

  override func layoutForLandscape() {
    super.layoutForLandscape()
    mapContainerNode.position = CGPoint(x: self.hudSize.width, y: 0)
    mapContainerNode.zRotation = 0
    mapContainerNode.anchorPoint = CGPoint.zero
    hudNode.size = hudSize
    hudNode.layoutForLandscape()
    for c in game.spriteSystem.components {
      self.setMapNodeTransform(c.sprite)
    }
    for g in gridNodes.values {
      self.setMapNodeTransform(g)
    }
    for s in hoverIndicatorSprites {
      self.setMapNodeTransform(s)
    }
  }

  override func layoutForPortrait() {
    super.layoutForPortrait()
    mapContainerNode.position = CGPoint(x: mapPixelSize.height, y: self.hudSize.width)
    mapContainerNode.zRotation = CGFloat.pi / 2
    mapContainerNode.anchorPoint = CGPoint.zero
    hudNode.size = CGSize(width: screenPixelSize.height, height: hudSize.width)
    hudNode.layoutForPortrait()
    for c in game.spriteSystem.components {
      self.setMapNodeTransform(c.sprite)
    }
    for g in gridNodes.values {
      self.setMapNodeTransform(g)
    }
    for s in hoverIndicatorSprites {
      self.setMapNodeTransform(s)
    }
  }

  // MARK: input

  func visualPoint(forPosition position: int2) -> CGPoint {
    return CGPoint(position) * self.tileSize.point
  }

  func spritePoint(forPosition position: int2) -> CGPoint {
    if isLandscape {
      return visualPoint(forPosition: position) + tileSize.point / 2
    } else {
      return visualPoint(forPosition: position) + tileSize.point / 2
    }
  }

  override func motion(_ m: Motion) {
    guard !isDead else { return }
    let m = self.transformMotion(m)
    game.movePlayer(by: m.vector) {
      [weak self] in self?._moveAgain(m)
    }
  }

  private func _moveAgain(_ m: Motion) {
    // just disable this dumb feature
//    guard !isDead else { return }
//    if isHolding(m: m) == true {
//      motion(m)
//      return
//    }
//    for m in Motion.all {
//      if isHolding(m: m) == true {
//        motion(m)
//        return
//      }
//    }
  }

  override func motionToggleMusic() {
    MusicPlayer.shared.toggleMusicSetting()
    _updateMusicTexture()
  }

  private var _lastTargetedPoint: int2? = nil
  private func _hideTargetingLaser() {
    for s in hoverIndicatorSprites { s.isHidden = true }
  }
  func eventPointToGrid(point: CGPoint) -> int2? {
    let gridPos: int2
    if isLandscape {
      let visualPointInMap = self.convert(point, to: mapContainerNode)
      gridPos = int2(
        Int32(visualPointInMap.x / tileSize.width),
        Int32(visualPointInMap.y / tileSize.height))
    } else {
      let visualPointInMapInvertedY = self.convert(point, to: hudNode) - CGPoint(x: 0, y: hudSize.width)
      let visualPointInMap = CGPoint(x: mapContainerNode.frame.size.width - visualPointInMapInvertedY.x, y: visualPointInMapInvertedY.y)
      gridPos = int2(
        Int32(visualPointInMap.y / tileSize.width),
        Int32(visualPointInMap.x / tileSize.height))
    }
    guard gridPos.x >= 0 && gridPos.y >= 0 && gridPos.x < game.gridGraph.gridWidth && gridPos.y < game.gridGraph.gridHeight else { return nil }
    return gridPos
  }

  override func motionLook(point: CGPoint) {
    guard !isDead else { return }
    guard let gridPos = eventPointToGrid(point: point), let ammoLeft = game.player.ammoC?.value, ammoLeft > 0 else {
      if _lastTargetedPoint != nil {
        _lastTargetedPoint = nil
        _hideTargetingLaser()
      }
      return
    }
    _hideTargetingLaser()
    for (i, p) in game.getTargetingLaserPoints(to: gridPos).enumerated() {
      hoverIndicatorSprites[i].position = self.spritePoint(forPosition: p)
      hoverIndicatorSprites[i].isHidden = false
    }
    _lastTargetedPoint = gridPos
  }

  var lastPointIndicated: int2? = nil
  override func motionIndicate(point: CGPoint) {
    guard !isDead else { return }
    if let gridPos = eventPointToGrid(point: point) {
      self.handleGridIndicate(point: point, gridPos: gridPos)
    } else {
      hudNode.motionIndicate(self.convert(point, to: hudNode))
    }
  }

  func handleGridIndicate(point: CGPoint, gridPos: int2) {
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

  // MARK: update()

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
    hudNode.update(instant: instant)

    let power: Float = Float(game.player.powerC?.getFractionRemaining() ?? 1)
    if power > 0.15 {
      MusicPlayer.shared.player?.rate = 1
    } else {
      MusicPlayer.shared.player?.rate = 0.9
    }
  }

  func evaluatePossibleTransitions() -> Bool {  // aka 'turnDidEnd'
    _hideTargetingLaser()

    if let playerPower = game.player.powerC?.power, playerPower <= 0 {
      self.isDead = true
      self.gameOver(reason: .power)
      return true
    } else if let playerHealth = game.player.healthC?.health, playerHealth <= 0 {
      self.isDead = true
      self.gameOver(reason: .health)
      return true
    } else if game.player.gridNode == game.exit.component(ofType: GridNodeComponent.self)?.gridNode {
      self.isDead = true
      game.startEndingLevel()

      let nextScene: SKScene
      if game.difficulty > 7 {
        MusicPlayer.shared.prepare(track: nil)
        nextScene = WinScene.create(score: game.score)
      } else {
        nextScene = MapScene.create(from: self)

      }
      self.view?.presentScene(nextScene, transition: SKTransition.crossFade(withDuration: 0.5))
      return true
    }
    return false
  }

  func gameOver(reason: DeathReason) {
    MusicPlayer.shared.prepare(track: nil)
    game.startEndingLevel()
    self.view?.presentScene(DeathScene.create(reason: reason, score: game.score), transition: SKTransition.crossFade(withDuration: 3))
  }

  // MARK: utils

  func setMapNodeTransform(_ node: SKNode) {
    if isLandscape && node.zRotation != 0 {
      node.zRotation = 0
    } else if !isLandscape && node.zRotation == 0 {
      node.zRotation = -CGFloat.pi / 2
    }
  }

  func flashMessage(_ text: String, color: SKColor = SKColor.red) {
    let node = PixelyLabelNode(view: view, text: text, color: color.blended(withFraction: 0.2, of: SKColor.white)!)

    let position = game.player?.gridNode?.gridPosition

    if let position = position {
      node.position = spritePoint(forPosition: position)
    } else {
      node.position = CGPoint(x: mapPixelSize.width / 2, y: mapPixelSize.height / 2)
    }
    node.position = self.convert(node.position, from: mapContainerNode)
    node.setScale(self.screenScale)
    node.zPosition = 2000
    self.addChild(node)

    let tileScreenSize = tileSize.width * screenScale

    let options: [(CGPoint, (CGPoint) -> Bool)] = [
      (CGPoint(x: 0, y: 1), { $0.y < self.frame.size.height - tileScreenSize * 2 }),
      (CGPoint(x: 0, y: -1), { _ in return true }),
    ]

    for (option, predicate) in options {
      let end = node.position + (option * tileScreenSize * 2)
      if predicate(end) {
        node.position += option * tileScreenSize
        node.run(
          SKAction.group([
            SKAction.fadeOut(withDuration: 1),
            SKAction.move(to: end, duration: 1)
            ]),
          completion: { node.removeFromParent() })
        break
      }
    }
  }

  // MARK: mouse input

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
    self.game?.finishEndingLevel()
    super.willMove(from: view)
  }
  #endif
}

extension MapScene {
  func _createHoverIndicatorSprites() -> [PWRSpriteNode] {
    return Array((0..<30).map({
      _ in
      let node = PWRSpriteNode(color: SKColor.yellow, size: self.tileSize)
      node.alpha = 0.2
      node.isHidden = true
      node.zPosition = Z.player
      return node
    }))
  }
}
