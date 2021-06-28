//
//  RenderView.swift
//  Signed
//
//  Created by Markus Moenig on 26/6/21.
//

import SwiftUI
import MetalKit

public class STKView        : MTKView
{
    //var core                : Core!

    var keysDown            : [Float] = []
    
    var mouseIsDown         : Bool = false
    var mousePos            = float2(0, 0)
    
    var hasTap              : Bool = false
    var hasDoubleTap        : Bool = false
    
    var buttonDown          : String? = nil
    var swipeDirection      : String? = nil

    var commandIsDown       : Bool = false
    var shiftIsDown         : Bool = false
    
    var renderer            : RenderPipeline? = nil
    var drawables           : MetalDrawables? = nil
    
    func reset()
    {
        keysDown = []
        mouseIsDown = false
        hasTap  = false
        hasDoubleTap  = false
        buttonDown = nil
        swipeDirection = nil
    }
    
    func update()
    {
        renderer?.render()
        if drawables?.encodeStart(float4(0,0,0,0)) != nil {
            
            if let texture = renderer?.finalTexture {
                drawables?.drawBox(position: float2(0,0), size: float2(Float(texture.width), Float(texture.height)), rounding: 0, borderSize: 0, onion: 0, fillColor: float4(0,0,0,1), borderColor: float4(0,0,0,0), texture: texture)
            }
            
            drawables?.encodeEnd()
        }
    }
    
    /// Setup the view
    func platformInit(_ model: Model, command: SignedCommand? = nil)
    {
        renderer = RenderPipeline(self, model)
        drawables = MetalDrawables(self)
        model.renderer = renderer
        
        #if os(OSX)
        layer?.isOpaque = false
        #endif
    }
    
    #if os(OSX)

    override public var acceptsFirstResponder: Bool { return true }

    #endif
}

#if os(OSX)
struct RenderView: NSViewRepresentable {

    var model               : Model
    var command             : SignedCommand? = nil
    var trackingArea        : NSTrackingArea?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<RenderView>) -> MTKView {
        let stkView = STKView(frame: NSMakeRect(0, 0, 100, 100))
        
        stkView.delegate = context.coordinator
        stkView.preferredFramesPerSecond = 60
        stkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            stkView.device = metalDevice
        }
        stkView.framebufferOnly = false
        stkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        stkView.drawableSize = stkView.frame.size
        stkView.isPaused = true
        
        stkView.platformInit(model, command: command)

        return stkView
    }
    
    func updateNSView(_ view: MTKView, context: NSViewRepresentableContext<RenderView>) {
        if let stkView = view as? STKView {
            stkView.update()
        }
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: RenderView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: RenderView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            if let stkView = view as? STKView {
                stkView.update()
            }
        }
        
        func draw(in view: MTKView) {
            if let stkView = view as? STKView {
                stkView.update()
            }
        }
    }
}
#else
struct RenderView: UIViewRepresentable {
    typealias UIViewType = MTKView

    var model               : Model
    var component           : SignedComponent? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<RenderView>) -> MTKView {
        let stkView = STKView()
        
        stkView.delegate = context.coordinator
        stkView.preferredFramesPerSecond = 60
        stkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            stkView.device = metalDevice
        }
        stkView.framebufferOnly = false
        stkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        stkView.drawableSize = stkView.frame.size
        stkView.isPaused = true
        
        stkView.platformInit(model, component: component)

        return stkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<RenderView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: RenderView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: RenderView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            if let stkView = view as? STKView {
                stkView.update()
            }
        }
    }
}
#endif
