//
//  Geom.swift
//  macOS
//
//  Created by Steve Johnson on 7/28/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import CoreGraphics

enum ColumnarAxis {
  case rows
  case columns
}

extension CGPoint: Hashable {
  public var hashValue: Int {
    // iOS Swift Game Development Cookbook
    // https://books.google.se/books?id=QQY_CQAAQBAJ&pg=PA304&lpg=PA304&dq=swift+CGpoint+hashvalue&source=bl&ots=1hp2Fph274&sig=LvT36RXAmNcr8Ethwrmpt1ynMjY&hl=sv&sa=X&ved=0CCoQ6AEwAWoVChMIu9mc4IrnxgIVxXxyCh3CSwSU#v=onepage&q=swift%20CGpoint%20hashvalue&f=false
    return x.hashValue << 32 ^ y.hashValue
  }
}

extension CGRect {
  func iterateSteps(by axis: ColumnarAxis, step: CGFloat = 1, body: @escaping (CGPoint) -> Void) {
    var x = origin.x
    var y = origin.y
    switch axis {
    case .columns:
      while x < origin.x + size.width {
        y = origin.y
        while y < origin.y + size.height {
          body(CGPoint(x: x, y: y))
          y += step
        }
        x += step
      }
    case .rows:
      while y < origin.y + size.height {
        while x < origin.x + size.width {
          body(CGPoint(x: x, y: y))
          x += step
        }
        y += step
      }
    }
  }
}

extension CGSize {
  func iterateSteps(by axis: ColumnarAxis, step: CGFloat = 1, body: @escaping (CGPoint) -> Void) {
    CGRect(origin: CGPoint.zero, size: self).iterateSteps(by: axis, step: step, body: body)
  }
}

func *(_ a: CGPoint, _ b: Int) -> CGPoint {
  return CGPoint(x: a.x * CGFloat(b), y: a.y * CGFloat(b))
}

func += ( rect: inout CGRect, size: CGSize) {
  rect.size += size
}
func -= ( rect: inout CGRect, size: CGSize) {
  rect.size -= size
}
func *= ( rect: inout CGRect, size: CGSize) {
  rect.size *= size
}
func /= ( rect: inout CGRect, size: CGSize) {
  rect.size /= size
}
func += ( rect: inout CGRect, origin: CGPoint) {
  rect.origin += origin
}
func -= ( rect: inout CGRect, origin: CGPoint) {
  rect.origin -= origin
}
func *= ( rect: inout CGRect, origin: CGPoint) {
  rect.origin *= origin
}
func /= ( rect: inout CGRect, origin: CGPoint) {
  rect.origin /= origin
}


/** CGSize+OperatorsAdditions */
func += ( size: inout CGSize, right: CGFloat) {
  size.width += right
  size.height += right
}
func -= ( size: inout CGSize, right: CGFloat) {
  size.width -= right
  size.height -= right
}
func *= ( size: inout CGSize, right: CGFloat) {
  size.width *= right
  size.height *= right
}
func /= ( size: inout CGSize, right: CGFloat) {
  size.width /= right
  size.height /= right
}

func += ( left: inout CGSize, right: CGSize) {
  left.width += right.width
  left.height += right.height
}
func -= ( left: inout CGSize, right: CGSize) {
  left.width -= right.width
  left.height -= right.height
}
func *= ( left: inout CGSize, right: CGSize) {
  left.width *= right.width
  left.height *= right.height
}
func /= ( left: inout CGSize, right: CGSize) {
  left.width /= right.width
  left.height /= right.height
}

func + (size: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: size.width + right, height: size.height + right)
}
func - (size: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: size.width - right, height: size.height - right)
}
func * (size: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: size.width * right, height: size.height * right)
}
func / (size: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: size.width / right, height: size.height / right)
}

func + (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(width: left.width + right.width, height: left.height + right.height)
}
func - (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(width: left.width - right.width, height: left.height - right.height)
}
func * (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(width: left.width * right.width, height: left.height * right.height)
}
func / (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(width: left.width / right.width, height: left.height / right.height)
}



/** CGPoint+OperatorsAdditions */
func += ( point: inout CGPoint, right: CGFloat) {
  point.x += right
  point.y += right
}
func -= ( point: inout CGPoint, right: CGFloat) {
  point.x -= right
  point.y -= right
}
func *= ( point: inout CGPoint, right: CGFloat) {
  point.x *= right
  point.y *= right
}
func /= ( point: inout CGPoint, right: CGFloat) {
  point.x /= right
  point.y /= right
}

func += ( left: inout CGPoint, right: CGPoint) {
  left.x += right.x
  left.y += right.y
}
func -= ( left: inout CGPoint, right: CGPoint) {
  left.x -= right.x
  left.y -= right.y
}
func *= ( left: inout CGPoint, right: CGPoint) {
  left.x *= right.x
  left.y *= right.y
}
func /= ( left: inout CGPoint, right: CGPoint) {
  left.x /= right.x
  left.y /= right.y
}

func + (point: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: point.x + right, y: point.y + right)
}
func - (point: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: point.x - right, y: point.y - right)
}
func * (point: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * right, y: point.y * right)
}
func / (point: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / right, y: point.y / right)
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func - (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
func * (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x * right.x, y: left.y * right.y)
}
func / (left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x / right.x, y: left.y / right.y)
}
