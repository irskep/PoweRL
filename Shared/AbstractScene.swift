//
//  AbstractScene.swift
//  LD39
//
//  Created by Steve Johnson on 7/28/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

typealias OptionalCallback = (() -> ())?

enum Motion {
  case up
  case down
  case left
  case right

  static var all: [Motion] { return [.up, .down, .left, .right] }

  var vector: int2 {
    switch self {
    case .up: return int2(0, -1)
    case .down: return int2(0, 1)
    case .left: return int2(-1, 0)
    case .right: return int2(1, 0)
    }
  }
}

class SuperAbstractScene: SKScene {

  class func create() -> Self {
    return self._create()
  }

  private class func _create<T>() -> T {
    print(String(describing: T.self))
    guard let scene = SKScene(fileNamed: String(describing: T.self)) as? T else { abort() }
    return scene
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func didMove(to view: SKView) {
    self.setup()
  }

  func setup() {
    scaleMode = .aspectFit
  }

  func motionAccept() {
  }

  func motion(_ m: Motion) {
  }

  func motionIndicate(point: CGPoint) {
  }

  func motionLook(point: CGPoint) {
  }

  func isHolding(m: Motion) -> Bool {
    return false
  }
}

#if os(iOS) || os(tvOS)
  // Touch-based event handling
  class AbstractScene: SuperAbstractScene {

    let swipeRightGR = UISwipeGestureRecognizer()
    let swipeLeftGR = UISwipeGestureRecognizer()
    let swipeUpGR = UISwipeGestureRecognizer()
    let swipeDownGR = UISwipeGestureRecognizer()
    let tapGR = UITapGestureRecognizer()

    override func setup() {
      guard let view = self.view else { return }
      swipeRightGR.addTarget(self, action: #selector(AbstractScene.motionRight) )
      swipeRightGR.direction = .right
      view.addGestureRecognizer(swipeRightGR)

      swipeLeftGR.addTarget(self, action: #selector(AbstractScene.motionLeft) )
      swipeLeftGR.direction = .left
      view.addGestureRecognizer(swipeLeftGR)


      swipeUpGR.addTarget(self, action: #selector(AbstractScene.motionUp) )
      swipeUpGR.direction = .up
      view.addGestureRecognizer(swipeUpGR)

      swipeDownGR.addTarget(self, action: #selector(AbstractScene.motionDown) )
      swipeDownGR.direction = .down
      view.addGestureRecognizer(swipeDownGR)

      tapGR.addTarget(self, action:#selector(AbstractScene.tapped(_:) ))
      tapGR.numberOfTouchesRequired = 1
      tapGR.numberOfTapsRequired = 1
      view.addGestureRecognizer(tapGR)
    }

    @objc func tapped(_ sender:UITapGestureRecognizer) {
      guard let view = self.view else { return }
      self.motionIndicate(point: view.convert(sender.location(in: view), to: self))
    }

    @objc func motionUp() {
      self.motion(.up)
    }

    @objc func motionDown() {
      self.motion(.down)
    }

    @objc func motionLeft() {
      self.motion(.left)
    }

    @objc func motionRight() {
      self.motion(.right)
    }
  }
#endif

#if os(OSX)
  import Carbon.HIToolbox
  class KeyStateHandler {
    var heldKeys = Set<Int>()
    var heldSymbols = Set<String>()
  }

  // Mouse-based event handling
  class AbstractScene: SuperAbstractScene {
    private let ksh = KeyStateHandler()

    override func setup() {
      super.setup()
    }

    override func mouseDown(with event: NSEvent) {
      self.motionIndicate(point: event.location(in: self))
    }

    override func mouseDragged(with event: NSEvent) {
    }

    override func mouseUp(with event: NSEvent) {
    }

    override func mouseMoved(with event: NSEvent) {
      self.motionLook(point: event.location(in: self))
    }

    override func keyDown(with event: NSEvent) {
      switch Int(event.keyCode) {
      case kVK_LeftArrow where !ksh.heldSymbols.contains("left"):
        ksh.heldSymbols.insert("left")
        self.motion(.left)
      case kVK_RightArrow where !ksh.heldSymbols.contains("right"):
        ksh.heldSymbols.insert("right")
        self.motion(.right)
      case kVK_UpArrow where !ksh.heldSymbols.contains("up"):
        ksh.heldSymbols.insert("up")
        self.motion(.up)
      case kVK_DownArrow where !ksh.heldSymbols.contains("down"):
        ksh.heldSymbols.insert("down")
        self.motion(.down)
      default: break
      }
      for char in event.charactersIgnoringModifiers?.utf16.map({ Int($0) }) ?? [] {
        ksh.heldKeys.insert(char)
        if char == NSCarriageReturnCharacter {
          self.motionAccept()
        }
      }
    }

    override func keyUp(with event: NSEvent) {
      switch Int(event.keyCode) {
      case kVK_LeftArrow:
        ksh.heldSymbols.remove("left")
      case kVK_RightArrow:
        ksh.heldSymbols.remove("right")
      case kVK_UpArrow:
        ksh.heldSymbols.remove("up")
      case kVK_DownArrow:
        ksh.heldSymbols.remove("down")
      default: break
      }
    }

    override func isHolding(m: Motion) -> Bool {
      return ksh.heldSymbols.contains(String(describing: m))
    }
  }
#endif

