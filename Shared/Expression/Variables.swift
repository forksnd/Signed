//
//  Variables.swift
//  Signed
//
//  Created by Markus Moenig on 18/12/20.
//

import Foundation

class VariableContainer {
    
    enum VariableType {
        case Invalid, Bool, Text, Int, Float, Float2, Float3, Float4
    }
    
    var context : ExpressionContext? = nil
    
    func getType() -> VariableType {
        return .Invalid
    }
    
    func getTypeName() -> String {
        return ""
    }
    
    func toString() -> String {
        return ""
    }
}

class Float4 : VariableContainer
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1
    var w           : Float = 1

    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1,_ w: Float = 1)
    {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    override func getType() -> VariableType {
        return .Float4
    }
    
    override func getTypeName() -> String {
        return "Float4"
    }
    
    @inlinable func toSIMD() -> SIMD4<Float>
    {
        return SIMD4<Float>(x, y, z, w)
    }
    
    subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else
            if index == 2 {
                return z
            } else
            if index == 3 {
                return w
            } else {
                return x
            }
        }
    }
}

class Float3 : VariableContainer
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1

    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1)
    {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ o: Float3)
    {
        self.x = o.x
        self.y = o.y
        self.z = o.z
    }
    
    override func getType() -> VariableType {
        return .Float3
    }
    
    override func getTypeName() -> String {
        return "Float3"
    }
    
    @inlinable func toSIMD() -> SIMD3<Float>
    {
        return SIMD3<Float>(x, y, z)
    }
    
    subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else
            if index == 2 {
                return z
            } else {
                return x
            }
        }
    }
}

class Float2 : VariableContainer
{
    var x           : Float = 0
    var y           : Float = 0

    init(_ x: Float = 0,_ y: Float = 0)
    {
        self.x = x
        self.y = y
    }
    
    override func getType() -> VariableType {
        return .Float2
    }
    
    override func getTypeName() -> String {
        return "Float2"
    }
    
    @inlinable func toSIMD() -> SIMD2<Float>
    {
        return SIMD2<Float>(x, y)
    }
    
    subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else {
                return x
            }
        }
    }
}

class Float1 : VariableContainer
{
    var x           : Float = 0

    init(_ x: Float = 0)
    {
        self.x = x
    }
    
    @inlinable func toSIMD() -> Float
    {
        if let context = context {
            if let f1 = context.executeForFloat1() {
                return f1.x
            }
        }
        return x
    }
    
    override func getType() -> VariableType {
        return .Float
    }
    
    override func getTypeName() -> String {
        return "Float"
    }
    
    override func toString() -> String {
        return String(x)
    }
}

class Int1 : VariableContainer
{
    var x           : Int = 0

    init(_ x: Int = 0)
    {
        self.x = x
    }
    
    @inlinable func toSIMD() -> Int
    {
        return x
    }
    
    override func getTypeName() -> String {
        return "Int"
    }
}

class Bool1 : VariableContainer
{
    var x           : Bool = false

    init(_ x: Bool = false)
    {
        self.x = x
    }
    
    @inlinable func toSIMD() -> Bool
    {
        return x
    }
    
    override func getType() -> VariableType {
        return .Bool
    }
    
    override func getTypeName() -> String {
        return "Bool"
    }
}

class Text1 : VariableContainer
{
    var text: String = ""

    init(_ text: String = "")
    {
        self.text = text
    }
    
    @inlinable func toSIMD() -> String
    {
        return text
    }
    
    override func getTypeName() -> String {
        return "Text"
    }
}
