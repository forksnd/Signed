//
//  RenderPipeline.swift
//  Signed
//
//  Created by Markus Moenig on 26/6/21.
//

import MetalKit

/// Holds all the textures and metadata needed to render
class RenderKit {
    
    
    init(maxSamples: Int32) {
        self.maxSamples = maxSamples
    }
    
    var sampleTexture   : MTLTexture? = nil
    var outputTexture   : MTLTexture? = nil
    
    var samples         : Int32 = 0
    var maxSamples      : Int32

    func isValid() -> Bool {
        return sampleTexture != nil && outputTexture != nil
    }
}

class RenderPipeline
{
    var view            : MTKView
    var device          : MTLDevice

    var commandQueue    : MTLCommandQueue!
    var commandBuffer   : MTLCommandBuffer!
    
    var model           : Model
    
    var renderSize      = SIMD2<Int>()
        
    var maxSamples      : Int = 10000
    
    var depth           : Int = 0
    var maxDepth        : Int = 4
        
    var semaphore       : DispatchSemaphore
        
    var renderStates    : RenderStates
    
    var needsRestart    : Bool = true
        
    /// The queue for shape icons
    var iconQueue       : [SignedCommand] = []
    
    /// The queue for material icons
    var materialIconQueue   : [MaterialEntity] = []
    
    /// The main render kit
    var mainRenderKit   : RenderKit
    
    /// The icon render kit
    var iconRenderKit   : RenderKit
    
    var iconBuilder     : SignedBuilder
        
    init(_ view: MTKView,_ model: Model)
    {
        self.view = view
        self.model = model
        
        device = view.device!
        semaphore = DispatchSemaphore(value: 1)
        
        renderStates = RenderStates(device)
        
        mainRenderKit = RenderKit(maxSamples: 200)
        iconRenderKit = RenderKit(maxSamples: 40)
        
        model.modeler = ModelerPipeline(view, model)

        if let modeler = model.modeler {
            iconRenderKit.sampleTexture = modeler.allocateTexture2D(width: ModelerPipeline.IconSize, height: ModelerPipeline.IconSize)
            iconRenderKit.outputTexture = modeler.allocateTexture2D(width: ModelerPipeline.IconSize, height: ModelerPipeline.IconSize)
            
            modeler.mainKit.renderKits = [mainRenderKit]
            modeler.mainKit.currentRenderKit = mainRenderKit
            modeler.iconKit.renderKits = [iconRenderKit]
            modeler.iconKit.currentRenderKit = iconRenderKit
        }
        
        iconBuilder = SignedBuilder(model)
    }
    
    /// Restarts the path tracer
    func restart()
    {
        needsRestart = true
        view.isPaused = false
    }
    
    /// Resumes the renderer
    func resume()
    {
        view.isPaused = false
    }
    
    /// Restarts the renderer
    func performRestart(_ started: Bool = false, clear: Bool = false)
    {        
        _ = checkMainKitTextures()
        
        if started == false {
            startCompute()
        }
        
        //if clear {
        //    clearTexture(mainKit.outputTexture!)
        //}
        
        if started == false {
            stopCompute()
        }
    
        mainRenderKit.samples = 0
    }
    
    /// Render a single sample
    func renderSample()
    {
        if let mainKit = model.modeler?.mainKit {
            if mainKit.pipeline.isEmpty == false {
                if mainKit.gpuIsWorking == false {
                    model.modeler?.executeNext(kit: mainKit)
                    restart()
                }
                //return
            }
        }
        
        startCompute()

        if checkMainKitTextures() {
            performRestart(true, clear: true)
            needsRestart = false
        } else
        if needsRestart {
            performRestart(true, clear: false)
            needsRestart = false
        }
                        
        if let mainKit = model.modeler?.mainKit {
            
            if let renderKit = mainKit.currentRenderKit {
                if renderKit.samples < renderKit.maxSamples {
                    runRender(mainKit)
                    
                    if let renderKit = mainKit.currentRenderKit {
                        model.modeler?.accumulate(renderKit: renderKit)
                        renderKit.samples += 1
                    }
                }
            }

            //commandBuffer?.addCompletedHandler { cb in
                //print("Rendering Time:", (cb.gpuEndTime - cb.gpuStartTime) * 1000)
                //mainKit.samples += 1
            //}
        }
        
        stopCompute()//(waitUntilCompleted: true)
        
        // Render a shape icon sample ? These icons don't use Lua or public modules and are just based on their single SignedCommand
        
        if let icon = iconQueue.first {
            //startRendering(SIMD2<Int>(ModelerPipeline.IconSize, ModelerPipeline.IconSize))
            startCompute()
                    
            if let iconKit = model.modeler?.iconKit, iconKit.isValid(),
               let renderKit = iconKit.currentRenderKit {
                
                if renderKit.samples == 0 {
                    clearTexture(renderKit.outputTexture!)
                }
                
                runRender(iconKit)
                
                model.modeler?.accumulate(renderKit: renderKit)
                renderKit.samples += 1
                
                if renderKit.samples == renderKit.maxSamples {
                    iconQueue.removeFirst()
                    
                    icon.icon = model.modeler?.kitToImage(iconKit)
                    model.iconFinished.send(icon.id)
                    
                    // Init the next one to render
                    renderKit.samples = 0
                    installNextShapeIconCmd(iconQueue.first)
                    
                    iconKit.status = .ready
                }
            }
            
            stopCompute()
        } /*else
        /// Render a material icon ?
        if let material = materialIconQueue.first, model.modulesAreAvailable {
            startCompute()

            if let iconKit = model.modeler?.iconKit, iconKit.isValid() {
                
                if iconKit.status == .ready {
                    if let data = material.code {
                        if let value = String(data: data, encoding: .utf8) {
                            self.model.modeler?.clear(iconKit)
                            iconBuilder.build(code: value, kit: iconKit)
                        }
                    }
                } else if iconKit.status == .running {
                    if iconKit.pipeline.isEmpty {
                        iconKit.status = .rendering
                    } else {
                        if iconKit.gpuIsWorking == false {
                            model.modeler?.executeNext(kit: iconKit)
                        }
                    }
                } else if iconKit.status == .rendering {
                    
                    if iconKit.samples == 0 {
                        clearTexture(iconKit.outputTexture!)
                    }
                    
                    runRender(iconKit)
                    
                    model.modeler?.accumulate(texture: iconKit.sampleTexture!, targetTexture: iconKit.outputTexture!, samples: iconKit.samples)
                    iconKit.samples += 1
                    
                    if iconKit.samples == ModelerPipeline.IconSamples {
                        materialIconQueue.removeFirst()
                        
                        let icon = model.modeler?.kitToImage(iconKit)
                        self.model.materialIcons[material.id!] = icon
                        self.model.iconFinished.send(material.id!)                        
                        
                        // Init the next one to render
                        iconKit.samples = 0
                        iconKit.status = .ready
                    }
                }
            }
            
            stopCompute()
        } */else {
            if let mainKit = model.modeler?.mainKit {
                /*
                if mainKit.pipeline.isEmpty && mainKit.samples >= 200 && iconQueue.isEmpty /*&& materialIconQueue.isEmpty*/ {
                    view.isPaused = true
                    print("paused")
                }*/
           }
        }
    }
    
    /// Installs the next shape icon command
    func installNextShapeIconCmd(_ cmd: SignedCommand?) {
        if let cmd = cmd {
            model.iconCmd = cmd//.copy()!
            model.modeler?.clear(model.modeler?.iconKit)

            //model.iconCmd.action = .None
            //model.modeler?.executeCommand(cmd, model.modeler?.iconKit, clearFirst: true)
            //model.iconCmd.material.data.set("Emission", float3(1,0.2,0.2))
        } else {
            //model.iconCmd = cmd//.copy()!
            model.iconCmd.action = .None
        }
    }
    
    /// Starts compute operation
    func startCompute()
    {
        if commandQueue == nil {
            commandQueue = device.makeCommandQueue()
        }
        commandBuffer = commandQueue.makeCommandBuffer()
    }
    
    /// Stops compute operation
    func stopCompute(syncTexture: MTLTexture? = nil, waitUntilCompleted: Bool = false)
    {
        #if os(OSX)
        if let texture = syncTexture {
            let blitEncoder = commandBuffer!.makeBlitCommandEncoder()!
            blitEncoder.synchronize(texture: texture, slice: 0, level: 0)
            blitEncoder.endEncoding()
        }
        #endif
        commandBuffer?.commit()
        if waitUntilCompleted {
            commandBuffer?.waitUntilCompleted()
        }
        commandBuffer = nil
    }
    
    func runRender(_ kit: ModelerKit) {
        if let computeEncoder = commandBuffer?.makeComputeCommandEncoder() {
            if let state = renderStates.getComputeState(stateName: "render") {
                
                computeEncoder.setComputePipelineState( state )
                
                var renderUniforms = createRenderUniform(kit: kit)
                computeEncoder.setBytes(&renderUniforms, length: MemoryLayout<RenderUniform>.stride, index: 0)
                
                if kit.role == .main {
                    var modelerUniform = ModelerUniform()
                    modelerUniform.actionType = 0
                    computeEncoder.setBytes(&modelerUniform, length: MemoryLayout<ModelerUniform>.stride, index: 1)
                } else {
                    var modelerUniform = model.modeler?.createModelerUniform(model.modeler?.mainKit === kit ? model.editingCmd : model.iconCmd, forPreview: true)
                    computeEncoder.setBytes(&modelerUniform, length: MemoryLayout<ModelerUniform>.stride, index: 1)
                }
                
                computeEncoder.setTexture(kit.modelTexture, index: 2)
                computeEncoder.setTexture(kit.colorTexture, index: 3)
                computeEncoder.setTexture(kit.materialTexture1, index: 4)
                computeEncoder.setTexture(kit.materialTexture2, index: 5)
                computeEncoder.setTexture(kit.materialTexture3, index: 6)
                computeEncoder.setTexture(kit.materialTexture4, index: 7)
                
                if let renderKit = kit.currentRenderKit {
                    computeEncoder.setTexture(renderKit.sampleTexture, index: 8)
                    calculateThreadGroups(state, computeEncoder, renderKit.sampleTexture!)
                }
            }
            computeEncoder.endEncoding()
        }
    }
    
    /// Create a uniform buffer containing general information about the current project
    func createRenderUniform(kit: ModelerKit) -> RenderUniform
    {
        var renderUniform = RenderUniform()
        
        if kit.role == .main {

            if model.builder.inProgress == true {
                renderUniform.randomVector = float3(0.5, 0.5, 0.5)
                renderUniform.noShadows = 1;
            } else {
                renderUniform.randomVector = float3(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                renderUniform.noShadows = 0;
            }

            
            if kit.content == .project {
                renderUniform.cameraOrigin = model.project.camera.getPosition()
                renderUniform.cameraLookAt = model.project.camera.getLookAt()
                renderUniform.cameraFov = model.project.camera.getFov()
            } else
            if kit.content == .material {
                renderUniform.cameraOrigin = float3(0,0,-1)
                renderUniform.cameraLookAt = float3(0,0,0)
                renderUniform.cameraFov = 80
            }
            
            renderUniform.scale = 1//model.project.getWorldScale()
            
            renderUniform.maxDepth = 6;
            renderUniform.backgroundColor = float4(0.02, 0.02, 0.02, 1);

            if let rendererData = model.project.dataGroups.getGroup("Renderer") {
                renderUniform.backgroundColor = rendererData.getFloat4("Background")
                renderUniform.maxDepth = Int32(rendererData.getInt("Reflections", 6))
            }
            
            renderUniform.numOfLights = 1

            /*
            renderUniform.lights.0.position = float3(0,1,0)
            renderUniform.lights.0.emission = float3(10,10,10)
            renderUniform.lights.0.params.x = 1
            renderUniform.lights.0.params.y = 4.0 * Float.pi * 1 * 1;//light.radius * light.radius;
            renderUniform.lights.0.params.z = 1
             */
            /*
            type Quad
            position -2.04973 5 -8
            v1 2.040 5 -8
            v2 -2.04973 5 -7.5
            emission 5 5 5*/
            
            //let v1 = float3(2, 0, 0)
            //let v2 = float3(0, 0, 2)
            
            //let v1 = float3(1, 1, 1)
            //let v2 = float3(1, 1, 1)

            /*
            renderUniform.lights.0.position = float3(-1, 1, -1)
            renderUniform.lights.0.emission = float3(10, 10, 10)
            renderUniform.lights.0.u = v1// - renderUniform.lights.0.position
            renderUniform.lights.0.v = v2// - renderUniform.lights.0.position
            renderUniform.lights.0.params.x = 1
            renderUniform.lights.0.params.y = length(cross(renderUniform.lights.0.u, renderUniform.lights.0.v));
            renderUniform.lights.0.params.z = 0 */
            
            renderUniform.lights.0.position = float3(0, 1000, -1000)
            renderUniform.lights.0.emission = float3(4, 4, 4)
            renderUniform.lights.0.params.z = 2
        } else {
            
            renderUniform.randomVector = float3(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))

            renderUniform.cameraOrigin = float3(0, -0.012, -0.07)
            renderUniform.cameraLookAt = float3(0, -0.012, 0)
            renderUniform.cameraFov = 80
            renderUniform.scale = 1
            
            renderUniform.maxDepth = 2;

            renderUniform.noShadows = 1;
            renderUniform.backgroundColor = float4(0.35, 0.35, 0.35, 1)
            
            renderUniform.numOfLights = 1

            /*
            renderUniform.lights.0.position = float3(0,1.5,0)
            renderUniform.lights.0.emission = float3(10,10,10)
            renderUniform.lights.0.params.x = 1
            renderUniform.lights.0.params.y = 4.0 * Float.pi * 1 * 1;//light.radius * light.radius;
            renderUniform.lights.0.params.z = 1*/
            
            //let v1 = float3(2, 0, 0)
            //let v2 = float3(0, 0, 2)
            
            //let v1 = float3(1, 1, 1)
            //let v2 = float3(1, 1, 1)

            /*
            renderUniform.lights.0.position = float3(-1, 1, -1)
            renderUniform.lights.0.emission = float3(10, 10, 10)
            renderUniform.lights.0.u = v1// - renderUniform.lights.0.position
            renderUniform.lights.0.v = v2// - renderUniform.lights.0.position
            renderUniform.lights.0.params.x = 1
            renderUniform.lights.0.params.y = length(cross(renderUniform.lights.0.u, renderUniform.lights.0.v));
            renderUniform.lights.0.params.z = 0
            */
            
            renderUniform.lights.0.position = float3(0, 0, -1)
            renderUniform.lights.0.emission = float3(4, 4, 4)
            renderUniform.lights.0.params.z = 2
        }
                
        /*
        if (strcmp(light_type, "Quad") == 0)
         {
             light.type = LightType::RectLight;
             light.u = v1 - light.position;
             light.v = v2 - light.position;
             light.area = Vec3::Length(Vec3::Cross(light.u, light.v));
         }
         else if (strcmp(light_type, "Sphere") == 0)
         {
             light.type = LightType::SphereLight;
             light.area = 4.0f * PI * light.radius * light.radius;
         }*/
        
        return renderUniform
    }
    
    /// Check and allocate all textures, returns true if the textures had to be changed / reallocated
    func checkMainKitTextures() -> Bool
    {
        var resChanged = false

            
        // Get the renderSize
        if let rSize = self.model.renderSize {
            renderSize.x = rSize.x
            renderSize.y = rSize.y
        } else {
            renderSize.x = Int(self.view.frame.width)
            renderSize.y = Int(self.view.frame.height)
        }

        func checkTexture(_ texture: MTLTexture?) -> MTLTexture? {
            if texture == nil || texture!.width != renderSize.x || texture!.height != renderSize.y {
                //if let texture = texture {
                    //texture.setPurgeableState(.empty)
                //}
                resChanged = true
                let texture = allocateTexture2D(width: renderSize.x, height: renderSize.y)
                if let texture = texture {
                    clearTexture(texture)
                    resume()
                } else {
                    print("error allocating texture")
                }
                return texture
            } else {
                return texture
            }
        }

        mainRenderKit.sampleTexture = checkTexture(mainRenderKit.sampleTexture)
        mainRenderKit.outputTexture = checkTexture(mainRenderKit.outputTexture)
        
        if resChanged {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.model.updateUI.send()
            }
        }

        return resChanged
    }
    
    /// Updates the view once
    func updateOnce()
    {
        #if os(OSX)
        let nsrect : NSRect = NSRect(x:0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.setNeedsDisplay(nsrect)
        #else
        self.view.setNeedsDisplay()
        #endif
    }
    
    /// Allocate a texture of the given size
    func allocateTexture2D(width: Int, height: Int, format: MTLPixelFormat = .rgba16Float) -> MTLTexture?
    {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = format
        textureDescriptor.width = width == 0 ? 1 : width
        textureDescriptor.height = height == 0 ? 1 : height
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        return device.makeTexture(descriptor: textureDescriptor)
    }
    
    /// Clears the texture
    func clearTexture(_ texture: MTLTexture,_ color: float4 = SIMD4<Float>(0,0,0,1))
    {
        let renderPassDescriptor = MTLRenderPassDescriptor()

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.x), Double(color.y), Double(color.z), Double(color.w))
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
    
    /// Compute the threads and thread groups for the given state and texture
    func calculateThreadGroups(_ state: MTLComputePipelineState, _ encoder: MTLComputeCommandEncoder,_ texture: MTLTexture)
    {
        
        let w = state.threadExecutionWidth//limitThreads ? 1 : state.threadExecutionWidth
        let h = state.maxTotalThreadsPerThreadgroup / w//limitThreads ? 1 : state.maxTotalThreadsPerThreadgroup / w
        let d = 1//
        let threadsPerThreadgroup = MTLSizeMake(w, h, d)
        
        let threadgroupsPerGrid = MTLSize(width: (texture.width + w - 1) / w, height: (texture.height + h - 1) / h, depth: (texture.depth + d - 1) / d)
        
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
