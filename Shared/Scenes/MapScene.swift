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

class MapScene: AbstractScene {
  var game: GameModel!
  var bgMusic: AVAudioPlayer!
  var isDead = false

  let tileSize = CGSize(width: 16, height: 16)
  lazy var mapPixelSize: CGSize = {
    return CGSize(
      width: CGFloat(game.mapSize.x) * tileSize.width,
      height: CGFloat(game.mapSize.y) * tileSize.height)
  }()

  var screenScale: CGFloat {
    return self.frame.size.height / self.mapPixelSize.height
  }

  var screenPixelSize: CGSize {
    return CGSize(width: self.frame.size.width / self.screenScale, height: self.mapPixelSize.height)
  }

  let root = SKNode()

  var gridNodes: [CGPoint: SKSpriteNode] = [:]

  var hudSize: CGSize { return self.screenPixelSize - CGSize(width: self.mapPixelSize.width, height: 0) }

  lazy var hudContainerNode: HUDNode = {
    return HUDNode(view: self.view, game: self.game, size: self.hudSize)
  }()

  lazy var mapContainerNode: SKSpriteNode = {
    let mapContainerNode = SKSpriteNode(color: SKColor.black, size: self.mapPixelSize)
    mapContainerNode.position = CGPoint(x: self.hudSize.width, y: 0)
    mapContainerNode.anchorPoint = CGPoint.zero
    return mapContainerNode
  }()

  lazy var hoverIndicatorSprites: [SKSpriteNode] = {
    return Array((0..<30).map({
      _ in
      let node = SKSpriteNode(color: SKColor.yellow, size: self.tileSize)
      node.alpha = 0.2
      node.isHidden = true
      node.zPosition = Z.player
      node.anchorPoint = CGPoint.zero
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
    self.addChild(root)
    root.addChild(mapContainerNode)
    root.addChild(hudContainerNode)
    root.setScale(screenScale)

    hoverIndicatorSprites.forEach(mapContainerNode.addChild)

    hudContainerNode.levelNumberLabel.text = "Level \(self.game.difficulty)"

    for x in 0..<game.mapSize.x {
      for y in 0..<game.mapSize.y {
        let node = SKSpriteNode(imageNamed: "ground1").pixelized()
        node.position = self.visualPoint(forPosition: int2(x, y))
        node.anchorPoint = CGPoint.zero
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
      if UserDefaults.pwr_isMusicEnabled {
        bgMusic.play()
      }
      self.hudContainerNode.musicIcon.texture = SKTexture(imageNamed: UserDefaults.pwr_isMusicEnabled ? "icon-music-on" : "icon-music-off").pixelized()
    }

    Player.shared.get("up1", useCache: false).play()
    print(screenPixelSize)
  }

  func gridSprite(at position: int2) -> SKSpriteNode? {
    return gridNodes[CGPoint(position)]
  }

  func visualPoint(forPosition position: int2) -> CGPoint {
    return CGPoint(position) * self.tileSize.point
  }

  override func motion(_ m: Motion) {
    guard !isDead else { return }
    game.movePlayer(by: m.vector) {
      [weak self] in self?._moveAgain(m)
    }
  }

  private func _moveAgain(_ m: Motion) {
    guard !isDead else { return }
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
      UserDefaults.pwr_isMusicEnabled = false
    } else {
      bgMusic?.play()
      UserDefaults.pwr_isMusicEnabled = true
    }
    self.hudContainerNode.musicIcon.texture = SKTexture(imageNamed: UserDefaults.pwr_isMusicEnabled ? "icon-music-on" : "icon-music-off").pixelized()
  }

  private var _lastTargetedPoint: int2? = nil
  private func _hideTargetingLaser() {
    for s in hoverIndicatorSprites { s.isHidden = true }
  }
  func eventPointToGrid(point: CGPoint) -> int2? {
    let visualPointInMap = self.convert(point, to: mapContainerNode)
    let gridPos = int2(
      Int32(visualPointInMap.x / tileSize.width),
      Int32(visualPointInMap.y / tileSize.height))
    guard gridPos.x >= 0 && gridPos.y >= 0 && gridPos.x < game.gridGraph.gridWidth && gridPos.y < game.gridGraph.gridHeight else { return nil }
    return gridPos
  }

  override func motionLook(point: CGPoint) {
    guard !isDead else { return }
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
    guard !isDead else { return }
    if let gridPos = eventPointToGrid(point: point) {
      self.handleGridIndicate(point: point, gridPos: gridPos)
    } else {
      hudContainerNode.motionIndicate(self.convert(point, to: hudContainerNode))
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
    hudContainerNode.update(instant: instant)

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
      self.isDead = true
      self.gameOver()
    } else if let playerHealth = game.player.healthC?.health, playerHealth <= 0 {
      self.isDead = true
      self.gameOver()
    } else if game.player.gridNode == game.exit.component(ofType: GridNodeComponent.self)?.gridNode {
      self.isDead = true
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
    let node = PixelyLabelNode(view: view, text: text, color: color.blended(withFraction: 0.2, of: SKColor.white)!)

    let position = game.player?.gridNode?.gridPosition

    if let position = position {
      node.position = visualPoint(forPosition: position) + tileSize.point / 2
    } else {
      node.position = CGPoint(x: mapPixelSize.width / 2, y: mapPixelSize.height / 2)
    }
    node.zPosition = 2000
    mapContainerNode.addChild(node)

    if let position = position, position.y > (game.gridGraph?.gridHeight ?? 0) - 2 {
      node.position -= CGPoint(x: 0, y: tileSize.height) / 2
      node.run(
        SKAction.group([
          SKAction.fadeOut(withDuration: 1),
          SKAction.moveBy(x: 0, y: -tileSize.height * 3, duration: 1)
          ]),
        completion: { node.removeFromParent() })
    } else {
      node.position += CGPoint(x: 0, y: tileSize.height) / 2
      node.run(
        SKAction.group([
          SKAction.fadeOut(withDuration: 1),
          SKAction.moveBy(x: 0, y: tileSize.height * 3, duration: 1)
          ]),
        completion: { node.removeFromParent() })
    }
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
