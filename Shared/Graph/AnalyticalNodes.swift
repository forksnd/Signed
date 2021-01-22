//
//  GraphAnalyticalNodes.swift
//  Signed
//
//  Created by Markus Moenig on 16/12/20.
//

import Foundation
import simd

/// Analytical  Ground Plane
final class GraphAnalyticalGroundPlaneNode : GraphDistanceNode
{
    init(_ options: [String:Any] = [:])
    {
        super.init(.Utility, .Analytical, options)
        name = "analyticalGroundPlane"
    }
    
    override func verifyOptions(context: GraphContext, error: inout CompileError) {
    }
    
    @discardableResult @inlinable public override func execute(context: GraphContext) -> Result
    {

        return .Success
    }
    
    /// Returns the metal code for this node
    override func generateMetalCode(context: GraphContext) -> [String: String]
    {
        var codeMap : [String:String] = [:]
        
        codeMap["analytical"] =
        """

        float groundT = (0.0 - rayOrigin.y) / rayDir.y;
        if (groundT > 0.0) {
            analyticalMap = float4(groundT, 0, -1, \(context.getMaterialIndex()));
            analyticalNormal = float3(0,1,0);
        }

        """
                
        return codeMap
    }
    
    override func getHelp() -> String
    {
        return "Creates a ground plane."
    }
    
    override func getOptions() -> [GraphOption]
    {
        let options = [
            GraphOption(Float3(0,1,0), "Normal", "The normal defines the orientation of the plane.")
        ]
        return options + GraphDistanceNode.getSDFOptions()
    }
}

/// Analytical Dome
final class GraphAnalyticalDomeNode : GraphDistanceNode
{
    var radius      : Float1 = Float1(20)

    init(_ options: [String:Any] = [:])
    {
        super.init(.Utility, .Analytical, options)
        name = "analyticalDome"
    }
    
    override func verifyOptions(context: GraphContext, error: inout CompileError) {
        verifyTranslationOptions(context: context, error: &error)
        if let value = extractFloat1Value(options, container: context, error: &error, name: "radius", isOptional: true) {
            radius = value
        }
    }
    
    @discardableResult @inlinable public override func execute(context: GraphContext) -> Result
    {
        let camOrigin = context.rayOrigin.toSIMD()
        let camDir = context.rayDirection.toSIMD()
        
        let center = position.toSIMD()
        let radius = self.radius.toSIMD()
        
        let L = camOrigin - center
        let B = dot(camDir, L)
        let C = dot(L,L) - radius * radius
        let det = B * B - C
        let I = sqrt(det) - B
        let hitP = camOrigin + camDir * I
        
        
        if I > 0 && I < context.analyticalDist {
            context.analyticalNormal = -normalize(hitP - center)
            context.analyticalDist = I
            context.analyticalMaterial = context.activeMaterial
        }

        let groundT : Float = (0.0 - camOrigin.y) / camDir.y
        if groundT > 0.0 && groundT < I {
            if groundT < context.analyticalDist {
                context.analyticalDist = groundT
                context.analyticalNormal = float3(0,1,0)
                context.analyticalMaterial = context.activeMaterial
            }
        }
        
        return .Success
    }
    
    override func getHelp() -> String
    {
        return "Creates a ground plane."
    }
    
    override func getOptions() -> [GraphOption]
    {
        let options = [
            GraphOption(Float3(0,1,0), "Normal", "The normal defines the orientation of the plane.")
        ]
        return options + GraphDistanceNode.getSDFOptions()
    }
}

