//
//  CGPoint+Utils.swift
//  JSScan
//
//  Created by Julian Schiavo on 7/1/2019.
//  Copyright © 2019 Julian Schiavo. All rights reserved.
//

// Portions of this code are used under the MIT License and come from WeScan (https://github.com/wetransfer/wescan)

import Foundation

extension CGPoint {
    /// Returns the same `CGPoint` in the cartesian coordinate system.
    ///
    /// - Parameters:
    ///   - height: The height of the bounds this points belong to, in the current coordinate system.
    /// - Returns: The same point in the cartesian coordinate system.
    func cartesian(withHeight height: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: height - y)
    }
    
    /// Returns the distance between two points
    func distanceTo(point: CGPoint) -> CGFloat {
        return hypot((self.x - point.x), (self.y - point.y))
    }
}

