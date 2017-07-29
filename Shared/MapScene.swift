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
  required init(node: SKLabelNode) {
    label = node
    super.init(texture: nil, color: SKColor.black, size: CGSize.zero)
    addChild(label)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

protocol MapScening {
  var tileSize: CGFloat { get }
  var fontSize: CGFloat { get }
  func gridSprite(at position: int2) -> GridSprite?
  func createLabelNode(_ text: String) -> SKLabelNode
  func visualPoint(forPosition position: int2) -> CGPoint
}

class MapScene: AbstractScene, MapScening {
  lazy var tileSize: CGFloat = { return frame.size.height / mapSize.height }()
  lazy var fontSize: CGFloat = { return (36.0 / 314) * self.frame.size.height }()

  var gridNodes: [CGPoint: GridSprite] = [:]
  var mapSizeVisual: CGSize { return CGSize(width: mapSize.width * tileSize, height: mapSize.height * tileSize) }

  lazy var mapContainerNode: SKSpriteNode = {
    let mapContainerNode = SKSpriteNode(color: SKColor.black, size: self.mapSizeVisual)
    mapContainerNode.position = CGPoint(x: self.frame.size.width - self.mapSizeVisual.width, y: 0)
    mapContainerNode.anchorPoint = CGPoint.zero
    return mapContainerNode
  }()

  lazy var hudContainerNode: SKSpriteNode = {
    let hudContainerNode = SKSpriteNode(color: SKColor.darkGray, size: CGSize(width: self.frame.size.width - self.mapSizeVisual.width, height: self.frame.size.height))
    hudContainerNode.anchorPoint = CGPoint.zero
    return hudContainerNode
  }()

  lazy var game: GameModel = { return GameModel() }()

  var mapSize: CGSize { return CGSize(width: game.gridGraph.gridWidth, height: game.gridGraph.gridHeight)}

  override func setup() {
    super.setup()
    self.anchorPoint = CGPoint.zero

    self.addChild(mapContainerNode)
    self.addChild(hudContainerNode)

    mapSize.iterateSteps(by: .columns) {
      point in
      let node = GridSprite(node: self.createLabelNode(" "))
      node.position = self.visualPoint(forPosition: int2(Int32(point.x), Int32(point.y)))
      node.size = CGSize(width: self.tileSize, height: self.tileSize)
      self.mapContainerNode.addChild(node)
      self.gridNodes[point] = node
    }

    game.start(scene: self)
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
  }

  func createLabelNode(_ text: String) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "Menlo")
    node.fontColor = SKColor.white
    node.verticalAlignmentMode = .center
    node.fontSize = self.fontSize
    node.text = text
    return node
  }

  func gridSprite(at position: int2) -> GridSprite? {
    return gridNodes[CGPoint(position)]
  }

  func visualPoint(forPosition position: int2) -> CGPoint {
    let point = CGPoint(position)
    let rawPoint = point * self.tileSize + CGPoint(x: self.tileSize / 2, y: self.tileSize / 2)
    return CGPoint(x: rawPoint.x, y: self.mapSizeVisual.height - rawPoint.y)
  }
}
