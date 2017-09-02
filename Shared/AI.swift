//
//  AI.swift
//  LD39
//
//  Created by Steve Johnson on 8/22/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import GameplayKit

enum EntityCommand {
  case wait
  case move(GKEntity, GridNode)
  case attack(GKEntity, GridNode)
}

func getEntityCommand(game: GameModel, moveComponent: GKComponent) -> EntityCommand {
  guard
    let playerNode = game.player?.gridNode,
    let aiC = moveComponent as? MoveTowardPlayerComponent,
    let entity = aiC.entity,
    let nextNode = aiC.getClosest(to: playerNode.gridPosition, inGraph: game.gridGraph)
    else { return .wait }
  if let speedLimiter = entity.component(ofType: SpeedLimiterComponent.self) {
    if !speedLimiter.tryToStep() {
      return .wait
    }
  }
  if let currentNode = entity.gridNode, let sprite = entity.sprite {
    if nextNode.gridPosition.x > currentNode.gridPosition.x && sprite.xScale < 0 {
      // ok
    } else if nextNode.gridPosition.x < currentNode.gridPosition.x && sprite.xScale > 0 {
      // ok
    } else {
      // need to flip
      sprite.xScale *= -1
    }
  }
  if nextNode == playerNode {
    return .attack(entity, nextNode)
  } else {
    return .move(entity, nextNode)
  }
}
