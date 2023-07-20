//
//  health_kit.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 7/10/23.
//

import Foundation
import HealthKit

func healthKitInit() {
    // Create a constant set (not mutable) which allows us to gather the information for the heartbeat rate
    let heart_beat_info = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .heartRate)!])
    
    
}
