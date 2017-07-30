//
//  UIColor+compat.swift
//  LD39
//
//  Created by Steve Johnson on 7/29/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import SpriteKit

#if os(iOS) || os(tvOS)
  private func lerp(from a: CGFloat, to b: CGFloat, alpha: CGFloat) -> CGFloat {
    return (1 - alpha) * a + alpha * b
  }
  extension UIColor {
    private func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
      var r: CGFloat = 0
      var g: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0

      getRed(&r, green: &g, blue: &b, alpha: &a)

      return (r, g, b, a)
    }

    func blended(withFraction fraction: CGFloat, of color: UIColor) -> UIColor? {
      let fromComponents = components()

      let toComponents = color.components()

      let redAmount = lerp(from: fromComponents.red,
                           to: toComponents.red,
                           alpha: fraction)
      let greenAmount = lerp(from: fromComponents.green,
                             to: toComponents.green,
                             alpha: fraction)
      let blueAmount = lerp(from: fromComponents.blue,
                            to: toComponents.blue,
                            alpha: fraction)


      let color = UIColor(red: redAmount,
                          green: greenAmount,
                          blue: blueAmount,
                          alpha: 1)

      return color
    }
  }
#endif
