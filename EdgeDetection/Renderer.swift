//
//  Renderer.swift
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

import Foundation
import Metal
import CoreGraphics
import CoreImage

public enum Renderer {
  public static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
  public static let systemDefaultDevice = MTLCreateSystemDefaultDevice()!
  public static let context: CIContext = {
    CIContext(
      mtlDevice: systemDefaultDevice,
      options: [
        CIContextOption.workingColorSpace: colorSpace,
        CIContextOption.workingFormat: CIFormat.RGBA8,
      ]
    )
  }()
}
