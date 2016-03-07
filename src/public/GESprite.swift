//
//  GESprite.swift
//  MKTest
//
//  Created by Anthony Green on 12/30/15.
//  Copyright © 2015 Anthony Green. All rights reserved.
//

import Foundation
import Metal
import MetalKit

public class GESprite: GENode, Renderable {
  let imageName: String!

  var vertices: Vertices
  var rects: Quads!
  var texture: MTLTexture? = nil
  var vertexBuffer: MTLBuffer!
  var sharedUniformBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var uniformBufferQueue: BufferQueue!

  public var isVisible = true

  init(imageName: String) {
    self.imageName = imageName

    self.vertices = Vertices()

    super.init()
  }
  
  func loadTexture(device: MTLDevice) {
    let textureLoader = MTKTextureLoader(device: device)

    let (imageData, size) = GESprite.imageLoader(imageName)

    self.vertices = SpriteVertex.rectVertices(size)
    self.rects = [Quad(ll: vertices[0], ul: vertices[2], ur: vertices[5], lr: vertices[1])]
    self.size = size
    
    //image.CGImage is discolored for some reason
    //self.texture = try! textureLoader.newTextureWithCGImage(image.CGImage!, options: nil)

    //don't load anything weird I guess
    self.texture = try! textureLoader.newTextureWithData(imageData, options: nil)
  }

  //TODO: allow setting size in node class
  private static let errorImageName = "Test2"
  private static func imageLoader(imageName: String) -> (imageData: NSData, size: CGSize) {
    if let image = UIImage(named: imageName),
    let imageData = UIImagePNGRepresentation(image)
    {
      return (imageData, image.size)
    }

    let path = NSBundle.mainBundle().URLForResource(self.errorImageName, withExtension: "png")!
    let image = UIImage(data: NSData(contentsOfURL: path)!)!
    return (UIImagePNGRepresentation(image)!, image.size)
  }

  override func updateWithDelta(delta: CFTimeInterval) {
    super.updateWithDelta(delta)
  }
}
