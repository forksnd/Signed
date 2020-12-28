//
//  Variables.swift
//  Signed
//
//  Created by Markus Moenig on 18/12/20.
//

import Foundation

class VariableContainer
{
    var variables           : [String:BaseVariable] = [:]

    /// Get the given variable
    func getVariableValue(_ name: String, parameters: [BaseVariable] = []) -> BaseVariable?
    {
        return variables[name]
    }
}

class BaseVariable {
    
    enum VariableType {
        case Invalid, Bool, Text, Int, Float, Float2, Float3, Float4
    }
    
    var context     : ExpressionContext? = nil    
    var name        : String = ""
    
    // How many components does this variable have
    var components  : Int = 1
    
    // If this variable is a reference to another variable
    var reference   : BaseVariable? = nil
    var qualifiers  : [Int] = []
    
    init(_ name: String, components: Int = 1)
    {
        self.name = name
        self.components = components
    }
    
    /// Returns the variable type
    func getType() -> VariableType {
        return .Invalid
    }
    
    /// Return the typeName of the variable as a String, i.e. "Float1"
    func getTypeName() -> String {
        return "Invalid"
    }
    
    /// Return the variable in a readable form, like Float3<0, 1, 2>
    func toString() -> String {
        return ""
    }
    
    /// Creates a variables based on it's type, the context and it's string parameters, this is used to construct variables from text input
    static func createType(_ typeName: String, container: VariableContainer, parameters: String, error: inout CompileError) -> BaseVariable?
    {
        if typeName == "Float1" {
            return Float1(container: container, parameters: parameters, error: &error)
        } else
        if typeName == "Float2" {
            return Float3(container: container, parameters: parameters, error: &error)
        } else
        if typeName == "Float3" {
            return Float3(container: container, parameters: parameters, error: &error)
        } else
        if typeName == "Float4" {
            return Float4(container: container, parameters: parameters, error: &error)
        }
        return nil
    }
    
    /// Subscript stub
    subscript(index: Int) -> Float {
        get {
            return 0
        }
        set(v) {
        }
    }
}

final class Float4 : BaseVariable
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1
    var w           : Float = 1

    init(_ name: String = "", _ x: Float = 1,_ y: Float = 1,_ z: Float = 1,_ w: Float = 1)
    {
        super.init(name, components: 4)
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1,_ w: Float = 1)
    {
        super.init("", components: 4)
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    
    var expressions : Int = 0
    var context1    : ExpressionContext? = nil
    var context2    : ExpressionContext? = nil
    var context3    : ExpressionContext? = nil
    var context4    : ExpressionContext? = nil

    /// From text
    init(_ name: String = "", container: VariableContainer, parameters: String, error: inout CompileError)
    {
        super.init(name, components: 4)
        
        let array = parameters.split(separator: ",")
        
        if array.count == 0 {
            expressions = 0
            let exp = ExpressionContext()
            exp.parse(expression: parameters, container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f4 = exp.executeForFloat4() {
                        x = f4.x
                        y = f4.y
                        z = f4.z
                        z = f4.z
                    }
                } else {
                    self.context = exp
                }
            }
        } else
        if array.count == 4 {
            expressions = 4

            var exp = ExpressionContext()
            exp.parse(expression: array[0].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        x = f1.x
                    }
                } else {
                    self.context1 = exp
                }
            }
            
            exp = ExpressionContext()
            exp.parse(expression: array[1].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        y = f1.x
                    }
                } else {
                    self.context2 = exp
                }
            }
            
            exp = ExpressionContext()
            exp.parse(expression: array[2].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        z = f1.x
                    }
                } else {
                    self.context3 = exp
                }
            }
            
            exp = ExpressionContext()
            exp.parse(expression: array[3].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        w = f1.x
                    }
                } else {
                    self.context4 = exp
                }
            }
        } else {
            error.error = "A Float4 value cannot be constructed from \(array.count) parameters"
        }
    }
    
    override func getType() -> VariableType {
        return .Float4
    }
    
    override func getTypeName() -> String {
        return "Float4"
    }
    
    @inlinable func toSIMD() -> SIMD4<Float>
    {
        // One big expression for all 3 components
        if expressions == 0 {
            if let ref = reference {
                return SIMD4<Float>(ref[qualifiers[0]], ref[qualifiers[1]], ref[qualifiers[2]], ref[qualifiers[3]])
            } else
            if let context = context {
                if let f4 = context.executeForFloat4() {
                    return SIMD4<Float>(f4.x, f4.y, f4.z, f4.w)
                }
            }
        } else
        if expressions == 4 {
            var rc = SIMD4<Float>(x,y,z, w)
            
            if let context = context1 {
                if let f1 = context.executeForFloat1() {
                    rc.x = f1.x
                }
            }
            if let context = context2 {
                if let f1 = context.executeForFloat1() {
                    rc.y = f1.x
                }
            }
            if let context = context3 {
                if let f1 = context.executeForFloat1() {
                    rc.z = f1.x
                }
            }
            if let context = context4 {
                if let f1 = context.executeForFloat1() {
                    rc.w = f1.x
                }
            }
            
            return rc
        }
        return SIMD4<Float>(x, y, z, w)
    }
    
    @inlinable override subscript(index: Int) -> Float {
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
        set(v) {
            if index == 1 {
                y = Float(v)
            } else
            if index == 2 {
                z = Float(v)
            } else
            if index == 3 {
                w = Float(v)
            } else {
                x = Float(v)
            }
        }
    }
}

final class Float3 : BaseVariable
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1

    init(_ name: String = "", _ x: Float = 1,_ y: Float = 1,_ z: Float = 1)
    {
        super.init(name, components: 3)
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1)
    {
        super.init("", components: 3)
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ o: Float3)
    {
        super.init("", components: 3)
        self.x = o.x
        self.y = o.y
        self.z = o.z
    }
    
    var expressions : Int = 0
    var context1    : ExpressionContext? = nil
    var context2    : ExpressionContext? = nil
    var context3    : ExpressionContext? = nil

    /// From text
    init(_ name: String = "", container: VariableContainer, parameters: String, error: inout CompileError)
    {
        super.init(name, components: 3)
        
        let array = parameters.split(separator: ",")
        
        if array.count == 0 {
            expressions = 0
            let exp = ExpressionContext()
            exp.parse(expression: parameters, container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f3 = exp.executeForFloat3() {
                        x = f3.x
                        y = f3.y
                        z = f3.z
                    }
                } else {
                    self.context = exp
                }
            }
        } else
        if array.count == 3 {
            expressions = 3

            var exp = ExpressionContext()
            exp.parse(expression: array[0].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        x = f1.x
                    }
                } else {
                    self.context1 = exp
                }
            }
            
            exp = ExpressionContext()
            exp.parse(expression: array[1].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        y = f1.x
                    }
                } else {
                    self.context2 = exp
                }
            }
            
            exp = ExpressionContext()
            exp.parse(expression: array[2].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        z = f1.x
                    }
                } else {
                    self.context3 = exp
                }
            }
        } else {
            error.error = "A Float3 value cannot be constructed from \(array.count) parameters"
        }
    }
    
    override func getType() -> VariableType {
        return .Float3
    }
    
    override func getTypeName() -> String {
        return "Float3"
    }
    
    @inlinable func toSIMD() -> SIMD3<Float>
    {
        // One big expression for all 3 components
        if expressions == 0 {
            if let ref = reference {
                return SIMD3<Float>(ref[qualifiers[0]], ref[qualifiers[1]], ref[qualifiers[2]])
            } else
            if let context = context {
                if let f3 = context.executeForFloat3() {
                    return SIMD3<Float>(f3.x, f3.y, f3.z)
                }
            }
        } else
        if expressions == 3 {
            var rc = SIMD3<Float>(x,y,z)
            
            if let context = context1 {
                if let f1 = context.executeForFloat1() {
                    rc.x = f1.x
                }
            }
            if let context = context2 {
                if let f1 = context.executeForFloat1() {
                    rc.y = f1.x
                }
            }
            if let context = context3 {
                if let f1 = context.executeForFloat1() {
                    rc.z = f1.x
                }
            }
            
            return rc
        }
        return SIMD3<Float>(x, y, z)
    }
    
    @inlinable func fromSIMD(_ v: float3)
    {
        x = v.x
        y = v.y
        z = v.z
    }
    
    @inlinable override subscript(index: Int) -> Float {
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
        set(v) {
            if index == 1 {
                y = Float(v)
            } else
            if index == 2 {
                z = Float(z)
            } else {
                x = Float(x)
            }
        }
    }
}

final class Float2 : BaseVariable
{
    var x           : Float = 0
    var y           : Float = 0

    init(_ name: String = "", _ x: Float = 1,_ y: Float = 1)
    {
        super.init(name, components: 2)
        self.x = x
        self.y = y
    }
    
    init(_ x: Float = 0,_ y: Float = 0)
    {
        super.init("", components: 2)
        self.x = x
        self.y = y
    }
    
    var expressions : Int = 0
    var context1    : ExpressionContext? = nil
    var context2    : ExpressionContext? = nil

    /// From text
    init(_ name: String = "", container: VariableContainer, parameters: String, error: inout CompileError)
    {
        super.init(name, components: 2)
        
        let array = parameters.split(separator: ",")
        
        if array.count == 0 {
            expressions = 0
            let exp = ExpressionContext()
            exp.parse(expression: parameters, container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f2 = exp.executeForFloat2() {
                        x = f2.x
                        y = f2.y
                    }
                } else {
                    self.context = exp
                }
            }
        } else
        if array.count == 2 {
            expressions = 2

            var exp = ExpressionContext()
            exp.parse(expression: array[0].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        x = f1.x
                    }
                } else {
                    self.context1 = exp
                }
            }
            
            exp = ExpressionContext()
            exp.parse(expression: array[1].trimmingCharacters(in: .whitespaces), container: container, error: &error)
            if error.error == nil {
                if exp.resultType == .Constant {
                    if let f1 = exp.executeForFloat1() {
                        y = f1.x
                    }
                } else {
                    self.context2 = exp
                }
            }
        } else {
            error.error = "A Float2 value cannot be constructed from \(array.count) parameters"
        }
    }
    
    override func getType() -> VariableType {
        return .Float2
    }
    
    override func getTypeName() -> String {
        return "Float2"
    }
    
    @inlinable func toSIMD() -> SIMD2<Float>
    {
        // One big expression for all 2 components
        if expressions == 0 {
            if let ref = reference {
                return SIMD2<Float>(ref[qualifiers[0]], ref[qualifiers[1]])
            } else
            if let context = context {
                if let f2 = context.executeForFloat2() {
                    return SIMD2<Float>(f2.x, f2.y)
                }
            }
        } else
        if expressions == 3 {
            var rc = SIMD2<Float>(x,y)
            
            if let context = context1 {
                if let f1 = context.executeForFloat1() {
                    rc.x = f1.x
                }
            }
            if let context = context2 {
                if let f1 = context.executeForFloat1() {
                    rc.y = f1.x
                }
            }
            
            return rc
        }
        return SIMD2<Float>(x, y)
    }
    
    @inlinable override subscript(index: Int) -> Float {
        get {
            if index == 1 {
                return y
            } else {
                return x
            }
        }
        set(v) {
            if index == 1 {
                y = Float(v)
            } else {
                x = Float(v)
            }
        }
    }
}

final class Float1 : BaseVariable
{
    var x           : Float = 0

    init(_ name: String = "", _ x: Float = 1)
    {
        super.init(name)
        self.x = x
    }
    
    init(_ x: Float = 0)
    {
        super.init("")
        self.x = x
    }
    
    /// From text
    init(_ name: String = "", container: VariableContainer, parameters: String, error: inout CompileError)
    {
        super.init(name)
        let exp = ExpressionContext()
        exp.parse(expression: parameters, container: container, error: &error)
        if error.error == nil {
            if exp.resultType == .Constant {
                if let f1 = exp.executeForFloat1() {
                    x = f1.x
                }
            } else {
                self.context = exp
            }
        }
    }
    
    @inlinable func toSIMD() -> Float
    {
        if let ref = reference {
            return ref[qualifiers[0]]
        } else
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
    
    @inlinable override subscript(index: Int) -> Float {
        get {
            return x
        }
        set(v) {
            x = Float(v)
        }
    }
}

final class Int1 : BaseVariable
{
    var x           : Int = 0

    init(_ name: String = "", _ x: Int = 1)
    {
        super.init(name)
        self.x = x
    }
    
    init(_ x: Int = 0)
    {
        super.init("")
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

final class Bool1 : BaseVariable
{
    var x           : Bool = false

    init(_ name: String = "", _ x: Bool = false)
    {
        super.init(name)
        self.x = x
    }
    
    init(_ x: Bool = false)
    {
        super.init("")
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

final class Text1 : BaseVariable
{
    var text: String = ""

    init(_ name: String,_ text: String = "")
    {
        super.init(name)
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
