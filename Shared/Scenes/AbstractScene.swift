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
    case .up: return int2(0, 1)
    case .down: return int2(0, -1)
    case .left: return int2(-1, 0)
    case .right: return int2(1, 0)
    }
  }
}

class SuperAbstractScene: SKScene {

  override func didMove(to view: SKView) {
    view.showsFPS = false
    view.showsNodeCount = false
    view.showsDrawCount = false
    self.setup()
  }

  func visitAll(_ fn: @escaping (SKNode) -> ()) {
    var visitor: ((SKNode) -> ())!
    let visit = {
      (child: SKNode) in
      fn(child)
      child.children.forEach(visitor)
    }
    visitor = visit
    children.forEach(visit)
  }

  func setup() {
    scaleMode = .aspectFit
  }

  func motionAccept() {
  }

  func motion(_ m: Motion) {
  }

  var isTouch: Bool { return false }

  func motionIndicate(point: CGPoint) {
  }

  func motionLook(point: CGPoint) {
  }

  func isHolding(m: Motion) -> Bool {
    return false
  }

  func motionToggleMusic() {
  }

  func getSavePath(id: String) -> URL? {
    #if os(iOS) || os(tvOS)
      let dir: FileManager.SearchPathDirectory = .documentDirectory
    #else
      let dir: FileManager.SearchPathDirectory = .applicationSupportDirectory
    #endif
    guard let docsPath = FileManager.default.urls(for: dir, in: .userDomainMask).first else { return nil }
    return docsPath.appendingPathComponent("\(id).json")
  }

  func upsertSave(id: String, dict: [String: Any]) {
    guard let myURL = getSavePath(id: id) else { return }
    print("Saving to \(myURL.path)")
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) else { return }
    try? data.write(to: myURL)
  }

  func loadSave(id: String) -> [String: Any]? {
    guard let myURL = getSavePath(id: id) else { return nil }
    print("Loading from \(myURL.path)")
    guard let data = try? Data(contentsOf: myURL) else {
      return nil

    }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
      return nil
    }
    return json as? [String: Any]
  }

  func getSaveExists(id: String) -> Bool {
    guard let myURL = getSavePath(id: id) else { return false }
    return FileManager.default.fileExists(atPath: myURL.path)
  }

  func deleteSave(id: String) {
    guard let myURL = getSavePath(id: id) else { return }
    if FileManager.default.fileExists(atPath: myURL.path) {
      try? FileManager.default.removeItem(at: myURL)
    }
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

    override var isTouch: Bool { return true }

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
        if char == Int("m".utf16.map({ Int($0) })[0]) {
          self.motionToggleMusic()
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

