//
//  SignedPBSDF.swift
//  Signed
//
//  Created by Markus Moenig on 15/1/21.
//

import Foundation
import simd

/// GraphPrincipledPathNode
final class GraphPrincipledPathNode : GraphNode
{
    // Disney BSDF Implementation based on https://github.com/knightcrawler25/GLSL-PathTracer
    
    /*
     * MIT License
     *
     * Copyright(c) 2019-2021 Asif Ali
     *
     * Permission is hereby granted, free of charge, to any person obtaining a copy
     * of this softwareand associated documentation files(the "Software"), to deal
     * in the Software without restriction, including without limitation the rights
     * to use, copy, modify, merge, publish, distribute, sublicense, and /or sell
     * copies of the Software, and to permit persons to whom the Software is
     * furnished to do so, subject to the following conditions :
     *
     * The above copyright notice and this permission notice shall be included in all
     * copies or substantial portions of the Software.
     *
     * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
     * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
     * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
     * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
     * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
     * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
     * SOFTWARE.
     */
    
    struct Ray
    {
        var origin          = float3(0,0,0)
        var direction       = float3(0,0,0)
    }
    
    struct Material
    {
        var albedo          = float3(0,0,0)
        var specular        : Float = 0
        var emission        = float3(0,0,0)
        var anisotropic     : Float = 0
        var metallic        : Float = 0
        var roughness       : Float = 0
        var subsurface      : Float = 0
        var specularTint    : Float = 0
        var sheen           : Float = 0
        var sheenTint       : Float = 0
        var clearcoat       : Float = 0
        var clearcoatGloss  : Float = 0
        var transmission    : Float = 0
        var ior             : Float = 0
        var extinction      = float3(0,0,0)
    }
    
    struct State
    {
        var depth           : Int = 0
        var eta             : Float = 0
        var hitDist         : Float = 0
        var fhp             = float3(0,0,0)
        var normal          = float3(0,0,0)
        var ffnormal        = float3(0,0,0)
        var tangent         = float3(0,0,0)
        var bitangent       = float3(0,0,0)
        
        var isEmitter       = false
        var specularBounce  = false

        var texCoord        = float2(0,0)
        var bary            = float3(0,0,0)
        
        //ivec3 triID;
        //int matID;
        var mat             = Material()
    }
    
    struct Light
    {
        var position            = float3(0,0,0)
        var emission            = float3(0,0,0)
        var u                   = float3(0,0,0)
        var v                   = float3(0,0,0)
        var radiusAreaType      = float3(0,0,0)
    }
    
    struct BsdfSampleRec
    {
        var bsdfDir             = float3(0,0,0)
        var pdf                 : Float = 0
    }

    struct LightSampleRec
    {
        var surfacePos          = float3(0,0,0)
        var normal              = float3(0,0,0)
        var emission            = float3(0,0,0)
        var pdf                 : Float = 0
    }
    
    init(_ options: [String:Any] = [:])
    {
        super.init(.Render, .None, options)
        name = "renderPrincipledBSDF"
        givenName = "Principled BSDF Pathtracer"
        renderType = .PathTracer
        leaves = []
    }
    
    override func verifyOptions(context: GraphContext, error: inout CompileError) {
    }
    
    @discardableResult @inlinable public override func execute(context: GraphContext) -> Result
    {
        /*
        let v = -context.rayDirection.toSIMD()
        let n = context.normal.toSIMD()
        //let l = normalize(float3(0.6, 0.7, -0.7))
        let l = normalize(float3(5, 10, -10))
        let h = normalize(v + l)
        let r = normalize(simd_reflect(context.rayDirection.toSIMD(), n))*/
        
        var r = Ray(origin: context.rayOrigin.toSIMD(), direction: context.rayDirection.toSIMD())
        
        var radiance = float3(0, 0, 0)
        var throughput = float3(1, 1, 1)
        
        var state = State()
        var lightSampleRec = LightSampleRec()
        var bsdfSampleRec = BsdfSampleRec()
        
        var maxDepth: Int = 1
        
        for depth in 0..<maxDepth
        {
            var lightPdf : Float = 1.0
            state.depth = depth
            
            context.rayOrigin.fromSIMD(r.origin)
            context.rayDirection.fromSIMD(r.direction)
            
            let hit = context.hit()
            if hit.0 == Float.greatestFiniteMagnitude {
                
                // Sky
                if let skyNode = context.skyNode {
                    skyNode.execute(context: context)
                    radiance += context.outColor.toSIMD3() * throughput
                }
                
                context.outColor!.x = pow(radiance.x, 1.0 / 2.2)
                context.outColor!.y = pow(radiance.y, 1.0 / 2.2)
                context.outColor!.z = pow(radiance.z, 1.0 / 2.2)
                
                return .Success
            }
            
            if let material = hit.1 {
                context.executeMaterial(material)
            }
            
            radiance += state.mat.emission * throughput;

            //GetNormalsAndTexCoord(state, r);
            //GetMaterialsAndTextures(state, r);
            
            /*
    #ifdef LIGHTS
            if (state.isEmitter)
            {
                radiance += EmitterSample(r, state, lightSampleRec, bsdfSampleRec) * throughput;
                break;
            }
    #endif
    */
            
            radiance += DirectLight(r, state) * throughput
        }
    
        context.outColor!.x = pow(radiance.x, 1.0 / 2.2)
        context.outColor!.y = pow(radiance.y, 1.0 / 2.2)
        context.outColor!.z = pow(radiance.z, 1.0 / 2.2)

        return .Success
    }
    
    func DirectLight(_ r: Ray,_ state: State) -> float3
    {
        var L = float3(0, 0, 0)

        return L
    }
    
    //-----------------------------------------------------------------------
    func DisneyPdf(_ ray: Ray,_ state: inout State,_ bsdfDir: float3) -> Float
    //-----------------------------------------------------------------------
    {
        let N = state.ffnormal
        let V = -ray.direction
        let L = bsdfDir
        var H = float3(0,0,0)

        let specularAlpha = max(0.001, state.mat.roughness)

        // Transmission
        if (dot(N, L) <= 0.0)
        {
            /*
            H = -simd_normalize(L + V * state.eta)
            L = -L

            let NDotH = abs(dot(N, H))
            let VDotH = abs(dot(V, H))
            let LDotH = abs(dot(L, H))

            let pdfGTR2 = GTR2(NDotH, specularAlpha) * NDotH
            let F = DielectricFresnel(LDotH, state.eta)
            let denomSqrt = LDotH + VDotH * state.eta*/
            //return pdfGTR2 * (1.0 - F) * VDotH / (denomSqrt * denomSqrt);
            return 1.0
        }

        // Reflection
        //var brdfPdf     : Float = 0.0
        var bsdfPdf     : Float = 0.0

        H = normalize(L + V)

        let NDotH = abs(dot(N, H))
        
        let clearcoatAlpha = simd_mix(0.1, 0.001, state.mat.clearcoatGloss)

        let diffuseRatio = 0.5 * (1.0 - state.mat.metallic)
        let specularRatio = 1.0 - diffuseRatio

        let aspect = sqrt(1.0 - state.mat.anisotropic * 0.9)
        let ax = max(0.001, state.mat.roughness / aspect)
        let ay = max(0.001, state.mat.roughness * aspect)

        // PDFs for brdf
        let pdfGTR2_aniso = GTR2_aniso(NDotH, dot(H, state.tangent), dot(H, state.bitangent), ax, ay) * NDotH
        let pdfGTR1 = GTR1(NDotH, clearcoatAlpha) * NDotH
        let ratio = 1.0 / (1.0 + state.mat.clearcoat)
        let pdfSpec = simd_mix(pdfGTR1, pdfGTR2_aniso, ratio) / (4.0 * abs(dot(V, H)))
        let pdfDiff = abs(dot(L, N)) * (1.0 / Float.pi)
        let brdfPdf = diffuseRatio * pdfDiff + specularRatio * pdfSpec

        // PDFs for bsdf
        let pdfGTR2 = GTR2(NDotH, specularAlpha) * NDotH
        let F = DielectricFresnel(abs(dot(L, H)), state.eta);
        bsdfPdf = pdfGTR2 * F / (4.0 * abs(dot(V, H)));

        return simd_mix(brdfPdf, bsdfPdf, state.mat.transmission);
    }
    
    
    //-----------------------------------------------------------------------
    func DisneyPdf(_ ray: Ray,_ state: inout State) -> float3
    //-----------------------------------------------------------------------
    {
        let N : float3 = state.ffnormal
        let V = -ray.direction
        state.specularBounce = false

        var dir = float3(0,0,0)

        let r1 = rand()
        let r2 = rand()

        // BSDF
        if (rand() < state.mat.transmission)
        {
            var H : float3 = ImportanceSampleGGX(state.mat.roughness, r1, r2)
            H = state.tangent * H.x
            H += state.bitangent * H.y
            H += N * H.z

            let theta = abs(dot(N, V))
            let cos2t = 1.0 - state.eta * state.eta * (1.0 - theta * theta)

            let F = DielectricFresnel(theta, state.eta)

            if cos2t < 0.0 || rand() < F {
                dir = normalize(simd_reflect(-V, H))
            } else {
                dir = normalize(simd_refract(-V, H, state.eta))
                state.specularBounce = true
            }
        }
        // BRDF
        else
        {
            let diffuseRatio = 0.5 * (1.0 - state.mat.metallic)

            if rand() < diffuseRatio {
                var H = CosineSampleHemisphere(r1, r2)
                H = state.tangent * H.x
                H += state.bitangent * H.y
                H += N * H.z
                dir = H
            } else {
                var H = ImportanceSampleGGX(state.mat.roughness, r1, r2)
                H = state.tangent * H.x
                H += state.bitangent * H.y
                H += N * H.z
                dir = simd_reflect(-V, H)
            }
        }
        return dir
    }
    
    //-----------------------------------------------------------------------
    func DisneyEval(_ ray: Ray,_ state: inout State,_ bsdfDir: float3) -> float3
    //-----------------------------------------------------------------------
    {
        let N = state.ffnormal
        let V = -ray.direction
        var L = bsdfDir
        var H = normalize(L + V)

        var brdf = float3(0, 0, 0)
        var bsdf = float3(0, 0, 0)

        let NDotL = dot(N, L)
        let NDotV = dot(N, V)
        let NDotH = dot(N, H)
        //let VDotH = dot(V, H)
        let LDotH = dot(L, H)

        if (state.mat.transmission > 0.0)
        {
            var transmittance = float3(1, 1, 1)
            let extinction = float3(log(state.mat.extinction.x), log(state.mat.extinction.y), log(state.mat.extinction.z))

            if (dot(state.normal, state.ffnormal) < 0.0) {
                transmittance.x = exp(extinction.x * state.hitDist)
                transmittance.y = exp(extinction.y * state.hitDist)
                transmittance.z = exp(extinction.z * state.hitDist)
            }

            let a = max(0.001, state.mat.roughness)
            
            if (dot(N, L) <= 0.0)
            {
                H = -normalize(L + V * state.eta)
                L = -L

                //let LDotH = dot(L, H)
                //let VDotH = dot(V, H)
                //let NDotH = dot(N, H)
                let NDotL = dot(N, L)
                //let NDotV = dot(N, V)

                //let F = DielectricFresnel(abs(LDotH), state.eta)
                //let D = GTR2(NDotH, a);
                //let G = SmithG_GGX(NDotL, a) * SmithG_GGX(NDotV, a)

                //let denomSqrt = LDotH + VDotH * state.eta
                // TODO: Fix issue with shading normals: https://blog.yiningkarlli.com/2015/01/consistent-normal-interpolation.html
                // bsdf = state.mat.albedo * transmittance * (1.0 - F) * G * D * VDotH * LDotH * 4.0 / (denomSqrt * denomSqrt);
                bsdf = state.mat.albedo / NDotL
            } else {
                let F = DielectricFresnel(abs(LDotH), state.eta)
                let D = GTR2(NDotH, a)
                let G = SmithG_GGX(NDotL, a) * SmithG_GGX(NDotV, a)
                bsdf = state.mat.albedo * transmittance * F * G * D
            }
        }

        if (state.mat.transmission < 1.0 && NDotL > 0.0 && NDotV > 0.0)
        {
            let Cdlin = state.mat.albedo
            let Cdlum = 0.3 * Cdlin.x + 0.6 * Cdlin.y + 0.1 * Cdlin.z // luminance approx.

            let Ctint = Cdlum > 0.0 ? Cdlin / Cdlum : float3(1,1,1) // normalize lum. to isolate hue+sat
            let Cspec0 = simd_mix(state.mat.specular * 0.08 * simd_mix(float3(1,1,1), Ctint, float3(state.mat.specularTint, state.mat.specularTint, state.mat.specularTint)), Cdlin, float3(state.mat.metallic, state.mat.metallic, state.mat.metallic))
            let Csheen = simd_mix(float3(1,1,1), Ctint, float3(state.mat.sheenTint, state.mat.sheenTint, state.mat.sheenTint))

            // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
            // and mix in diffuse retro-reflection based on roughness
            let FL = SchlickFresnel(NDotL)
            let FV = SchlickFresnel(NDotV)
            let Fd90 = 0.5 + 2.0 * LDotH * LDotH * state.mat.roughness
            let Fd = simd_mix(1.0, Fd90, FL) * simd_mix(1.0, Fd90, FV)

            // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
            // 1.25 scale is used to (roughly) preserve albedo
            // Fss90 used to "flatten" retroreflection based on roughness
            let Fss90 = LDotH * LDotH * state.mat.roughness
            let Fss = simd_mix(1.0, Fss90, FL) * simd_mix(1.0, Fss90, FV)
            let ss = 1.25 * (Fss * (1.0 / (NDotL + NDotV) - 0.5) + 0.5)

            // specular
            let aspect = sqrt(1.0 - state.mat.anisotropic * 0.9)
            let ax = max(0.001, state.mat.roughness / aspect)
            let ay = max(0.001, state.mat.roughness * aspect)
            let Ds = GTR2_aniso(NDotH, dot(H, state.tangent), dot(H, state.bitangent), ax, ay)
            let FH = SchlickFresnel(LDotH)
            let Fs = simd_mix(Cspec0, float3(1,1,1), float3(FH, FH, FH))
            var Gs = SmithG_GGX_aniso(NDotL, dot(L, state.tangent), dot(L, state.bitangent), ax, ay)
            Gs *= SmithG_GGX_aniso(NDotV, dot(V, state.tangent), dot(V, state.bitangent), ax, ay)

            // sheen
            let Fsheen = FH * state.mat.sheen * Csheen

            // clearcoat (ior = 1.5 -> F0 = 0.04)
            let Dr = GTR1(NDotH, simd_mix(0.1, 0.001, state.mat.clearcoatGloss))
            let Fr = simd_mix(0.04, 1.0, FH)
            let Gr = SmithG_GGX(NDotL, 0.25) * SmithG_GGX(NDotV, 0.25)

            brdf = ((1.0 / Float.pi) * simd_mix(Fd, ss, state.mat.subsurface) * Cdlin + Fsheen) * (1.0 - state.mat.metallic)
            brdf += Gs * Fs * Ds + 0.25 * state.mat.clearcoat * Gr * Fr * Dr
        }

        return simd_mix(brdf, bsdf, float3(state.mat.transmission, state.mat.transmission, state.mat.transmission))
    }

    func rand() -> Float
    {
        return Float.random(in: 0...1)
    }
    
    //-----------------------------------------------------------------------
    func ImportanceSampleGGX(_ rgh: Float,_ r1: Float,_ r2: Float) -> float3
    //-----------------------------------------------------------------------
    {
        let a = max(0.001, rgh)

        let phi = r1 * 2.0 * Float.pi

        let cosTheta = sqrt((1.0 - r2) / (1.0 + (a * a - 1.0) * r2))
        let sinTheta = simd_clamp(sqrt(1.0 - (cosTheta * cosTheta)), 0.0, 1.0);
        let sinPhi = sin(phi)
        let cosPhi = cos(phi)

        return float3(sinTheta * cosPhi, sinTheta * sinPhi, cosTheta)
    }
    
    //-----------------------------------------------------------------------
    func SchlickFresnel(_ u: Float) -> Float
    //-----------------------------------------------------------------------
    {
        let m = simd_clamp(1.0 - u, 0.0, 1.0)
        let m2 = m * m
        return m2 * m2*m // pow(m,5)
    }
    
    //-----------------------------------------------------------------------
    func DielectricFresnel(_ theta: Float,_ eta: Float) -> Float
    //-----------------------------------------------------------------------
    {
        var R0 = (eta - 1.0) / (eta + 1.0)
        R0 *= R0
        return R0 + (1.0 - R0) * SchlickFresnel(theta)
    }
    
    //-----------------------------------------------------------------------
    func GTR1(_ NDotH: Float,_ a: Float) -> Float
    //-----------------------------------------------------------------------
    {
        if a >= 1.0 { return (1.0 / Float.pi) }
        let a2 = a * a
        let t = 1.0 + (a2 - 1.0) * NDotH * NDotH
        return (a2 - 1.0) / (Float.pi * log(a2) * t)
    }

    //-----------------------------------------------------------------------
    func GTR2(_ NDotH: Float,_ a: Float) -> Float
    //-----------------------------------------------------------------------
    {
        let a2 = a * a
        let t = 1.0 + (a2 - 1.0)*NDotH*NDotH
        return a2 / (Float.pi * t*t)
    }

    //-----------------------------------------------------------------------
    func GTR2_aniso(_ NDotH: Float,_ HDotX: Float,_ HDotY: Float,_ ax: Float,_ ay: Float) -> Float
    //-----------------------------------------------------------------------
    {
        let a = HDotX / ax
        let b = HDotY / ay
        let c = a * a + b * b + NDotH * NDotH
        return 1.0 / (Float.pi * ax * ay * c * c)
    }
    
    //-----------------------------------------------------------------------
    func SmithG_GGX(_ NDotV: Float,_ alphaG: Float) -> Float
    //-----------------------------------------------------------------------
    {
        let a = alphaG * alphaG
        let b = NDotV * NDotV
        return 1.0 / (NDotV + sqrt(a + b - a * b))
    }

    //-----------------------------------------------------------------------
    func SmithG_GGX_aniso(_ NDotV: Float,_ VDotX: Float,_ VDotY: Float,_ ax: Float,_ ay: Float) -> Float
    //-----------------------------------------------------------------------
    {
        let a = VDotX * ax
        let b = VDotY * ay
        let c = NDotV
        return 1.0 / (NDotV + sqrt(a*a + b*b + c*c))
    }

    //-----------------------------------------------------------------------
    func CosineSampleHemisphere(_ u1: Float,_ u2: Float) -> float3
    //-----------------------------------------------------------------------
    {
        var dir = float3(0,0,0)
        let r = sqrt(u1)
        let phi = 2.0 * Float.pi * u2
        dir.x = r * cos(phi)
        dir.y = r * sin(phi)
        dir.z = sqrt(max(0.0, 1.0 - dir.x*dir.x - dir.y*dir.y))

        return dir
    }
    
    //-----------------------------------------------------------------------
    func UniformSampleSphere(_ u1: Float,_ u2: Float) -> float3
    //-----------------------------------------------------------------------
    {
        let z = 1.0 - 2.0 * u1
        let r = sqrt(max(0.0, 1.0 - z * z))
        let phi = 2.0 * Float.pi * u2
        let x = r * cos(phi)
        let y = r * sin(phi)

        return float3(x, y, z)
    }
    
    //-----------------------------------------------------------------------
    func powerHeuristic(_ a: Float,_ b: Float) -> Float
    //-----------------------------------------------------------------------
    {
        let t = a * a
        return t / (b*b + t)
    }
    
    override func getHelp() -> String
    {
        return "A CPU based path tracer for Disney's Principled BSDF."
    }
    
    override func getOptions() -> [GraphOption]
    {
        let options = [
            GraphOption(Int1(1), "Anti-Aliasing", "The anti-aliasing performed by the renderer. Higher values produce more samples and better quality.")
        ]
        return options
    }
}
