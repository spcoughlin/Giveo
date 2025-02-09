//
//  MotionManager.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 30.0  // 30 FPS, for example
    
    // Published properties to drive your shiny effect
    @Published var xAccel: CGFloat = 0.0
    @Published var yAccel: CGFloat = 0.0
    
    init() {
        // Check if the accelerometer is available
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = updateInterval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data else { return }
                self.xAccel = CGFloat(data.acceleration.x)
                self.yAccel = CGFloat(data.acceleration.y)
            }
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}
