//
//  GERenderNode.swift
//  GameEngine
//
//  Created by Anthony Green on 1/16/16.
//  Copyright © 2016 Tony Green. All rights reserved.
//

import Foundation
import GLKit
import Metal
import QuartzCore

typealias GERenderNodes = [GERenderNode]

public class GERenderNode: GENode {
  var device: MTLDevice!
  
  //not sure might create a texture class to handle this stuff
  var texture: MTLTexture?
  
  var vertices: Vertices! {
    didSet {
      self.vertexCount = self.vertices.count
    }
  }
  private var vertexCount: Int = 0
  private var vertexBuffer: MTLBuffer!
  
  private var sharedUniformBuffer: MTLBuffer!
  private var uniformBufferQueue: BufferQueue!
  
  public var isVisible = true
  
  override init() {}
  init(vertices: Vertices) {
    self.vertices = vertices
    self.vertexCount = self.vertices.count
  }
  
  func setupBuffers() {
    let vertexData = self.vertices.flatMap { $0.data }
    let vertexDataSize = vertexData.count * sizeofValue(vertexData[0])
    self.vertexBuffer = self.device.newBufferWithBytes(vertexData, length: vertexDataSize, options: [])

    self.uniformBufferQueue = BufferQueue(device: self.device, dataSize: FloatSize * self.modelMatrix.data.count)
  }
  
  private func decompose(matrix: GLKMatrix4) -> GLKMatrix4 {
    let parentRotScale = GLKMatrix4GetMatrix3(matrix)
    let selfRotScale = GLKMatrix4GetMatrix3(self.modelMatrix)
    let rotScale = parentRotScale * selfRotScale
    
    let parentTranslate = GLKMatrix4GetColumn(matrix, 3)
    let selfTranslate = GLKMatrix4GetColumn(self.modelMatrix, 3)
    let translate = parentTranslate + selfTranslate
   
    let firstColumn = GLKVector4MakeWithVector3(GLKMatrix3GetColumn(rotScale, 0), translate.x)
    let secondColumn = GLKVector4MakeWithVector3(GLKMatrix3GetColumn(rotScale, 1), translate.y)
    let thirdColumn = GLKVector4MakeWithVector3(GLKMatrix3GetColumn(rotScale, 2), self.z)
    let fourthColumn = GLKVector4(v: (0.0, 0.0, 0.0, 1.0))
    
    return GLKMatrix4MakeWithRows(firstColumn, secondColumn, thirdColumn, fourthColumn)
  }
  
  func draw(commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder, sampler: MTLSamplerState? = nil) {
    renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0)
    
    var parentMatrix = GLKMatrix4Identity
    if let parent = self.getSuperParent() {
      parentMatrix = parent.modelMatrix
    }
    
    let uniformMatrix = self.camera.multiplyMatrices(self.decompose(parentMatrix))
    let offset = self.uniformBufferQueue.next(commandBuffer, data: uniformMatrix.data)
    renderEncoder.setVertexBuffer(self.uniformBufferQueue.buffer, offset: offset, atIndex: 1)
    
    if let texture = self.texture, sampler = sampler {
      renderEncoder.setFragmentTexture(texture, atIndex: 0)
      renderEncoder.setFragmentSamplerState(sampler, atIndex: 0)
    }
    
    renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: self.vertexCount)   
  }
}