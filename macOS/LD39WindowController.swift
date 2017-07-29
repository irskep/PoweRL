//
//  LD39WindowController.swift
//  macOS
//
//  Created by Steve Johnson on 7/28/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import Cocoa

class LD39WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.aspectRatio = CGSize(width: 746, height: 414)
  }
}
