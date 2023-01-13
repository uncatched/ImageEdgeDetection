//
//  EdgeDetectionFilter.swift
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

import Foundation
import Metal
import MetalKit
import CoreGraphics

struct EdgeDetectionFilter {
  private let textureLoader: MTKTextureLoader
  private var device: MTLDevice
  private let computePipeline: MTLComputePipelineState
  private let threadsCount: Int = 16

  init(type: EdgeDetectionFilterType, device: MTLDevice) throws {
    self.device = device
    self.textureLoader = MTKTextureLoader(device: device)
    guard let library = device.makeDefaultLibrary() else {
      throw EdgeDetectionError.failedToLoadLibrary
    }

    guard let function = library.makeFunction(name: type.rawValue) else {
      throw EdgeDetectionError.failedToMakeFunction(name: type.rawValue)
    }

    self.computePipeline = try device.makeComputePipelineState(function: function)
  }

  func filter(_ cgImage: CGImage) async throws -> EdgeDetectionResult? {
    let start = DispatchTime.now()
    let inputTexture = try await textureLoader.newTexture(cgImage: cgImage)

    let width = inputTexture.width
    let height = inputTexture.height

    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm_srgb,
      width: width,
      height: height,
      mipmapped: false
    )
    textureDescriptor.usage = [.shaderRead, .shaderWrite]

    guard
      let outputTexture = device.makeTexture(descriptor: textureDescriptor),
      let commandQueue = device.makeCommandQueue(),
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else {
      return nil
    }

    commandEncoder.setComputePipelineState(computePipeline)
    commandEncoder.setTexture(inputTexture, index: 0)
    commandEncoder.setTexture(outputTexture, index: 1)

    let threadsPerThreadGroup = MTLSize(width: threadsCount, height: threadsCount, depth: 1)
    let threadgroupsPerGrid = MTLSize(width: width / threadsCount + 1, height: height / threadsCount + 1, depth: 1)
    commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)

    commandEncoder.endEncoding()
    return await withCheckedContinuation { continuation in
      commandBuffer.addCompletedHandler { [outputTexture] _ in
        guard let ciImg = CIImage(mtlTexture: outputTexture)?.oriented(.downMirrored) else {
          continuation.resume(returning: nil)
          return
        }
        let renderedOutput = Renderer.context.createCGImage(ciImg, from: ciImg.extent)
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        guard let renderedOutput else { return }
        continuation.resume(returning: EdgeDetectionResult(image: renderedOutput, time: timeInterval))
      }
      commandBuffer.commit()
    }
  }
}

