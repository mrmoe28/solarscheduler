import Foundation

// Global safe value function
func safeValue(_ value: Double) -> Double {
    if value.isNaN || value.isInfinite {
        return 0.0
    }
    return value
}

extension Double {
    /// Returns a safe value, replacing NaN or infinite values with 0.0
    var safeValue: Double {
        if isNaN || isInfinite {
            return 0.0
        }
        return self
    }
    
    /// Safe division that returns 0.0 if the result would be NaN or infinite
    static func safeDivide(_ numerator: Double, _ denominator: Double) -> Double {
        guard denominator != 0.0 else { return 0.0 }
        let result = numerator / denominator
        return result.safeValue
    }
}

extension Float {
    /// Returns a safe value, replacing NaN or infinite values with 0.0
    var safeValue: Float {
        if isNaN || isInfinite {
            return 0.0
        }
        return self
    }
    
    /// Safe division that returns 0.0 if the result would be NaN or infinite
    static func safeDivide(_ numerator: Float, _ denominator: Float) -> Float {
        guard denominator != 0.0 else { return 0.0 }
        let result = numerator / denominator
        return result.safeValue
    }
}

extension CGFloat {
    /// Returns a safe value, replacing NaN or infinite values with 0.0
    var safeValue: CGFloat {
        if isNaN || isInfinite {
            return 0.0
        }
        return self
    }
    
    /// Safe division that returns 0.0 if the result would be NaN or infinite
    static func safeDivide(_ numerator: CGFloat, _ denominator: CGFloat) -> CGFloat {
        guard denominator != 0.0 else { return 0.0 }
        let result = numerator / denominator
        return result.safeValue
    }
}

extension Int {
    /// Safe conversion to Double
    var safeDouble: Double {
        return Double(self).safeValue
    }
    
    /// Safe conversion to Float
    var safeFloat: Float {
        return Float(self).safeValue
    }
    
    /// Safe conversion to CGFloat
    var safeCGFloat: CGFloat {
        return CGFloat(self).safeValue
    }
}