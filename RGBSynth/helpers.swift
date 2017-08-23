//
//  helpers.swift
//  SimpleVideoFilter
//
//  Created by Tom Power on 20/03/2017.
//  Copyright © 2017 Sunset Lake Software LLC. All rights reserved.
//

import Foundation

/// Linear interpolation. For any two values a and b return a linear interpolation with parameter `param`.
///
/// ````
/// lerp(0, 100, 0.5) = 50
/// lerp(100, 200, 0.5) = 150
/// lerp(500, 1000, 0.33) = 665
/// ````
///
/// - parameter a:     first value
/// - parameter b:     second value
/// - parameter param: parameter between 0 and 1 for interpolation
///
/// - returns: The interpolated value
public func lerp(_ a: Double, _ b: Double, at: Double) -> Double {
    return a + (b - a) * at
}

/// Linear mapping. Maps a value in the source range [min, max] to a value in the target range [toMin, toMax] using linear interpolation.
///
/// ````
/// map(10, 0, 20, 0, 200) = 100
/// map(10, 0, 100, 200, 300) = 210
/// map(10, 0, 20, 200, 300) = 250
/// ````
///
/// - parameter val:   Source value
/// - parameter min:   Source range lower bound
/// - parameter max:   Source range upper bound
/// - parameter toMin: Target range lower bound
/// - parameter toMax: Target range upper bound
///
/// - returns: The mapped value.
public func map(_ val: Double, min: Double, max: Double, toMin: Double, toMax: Double) -> Double {
    let param = (val - min)/(max -  min)
    return lerp(toMin, toMax, at: param)
}

