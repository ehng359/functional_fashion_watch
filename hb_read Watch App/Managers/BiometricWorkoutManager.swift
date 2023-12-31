//
//  BiometricWKBDelegate.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 8/18/23.
//

import Foundation
import HealthKit

class BiometricWorkoutManager : NSObject, ObservableObject {
    let healthstore : HKHealthStore = HKHealthStore()
    var session : HKWorkoutSession?
    var builder : HKLiveWorkoutBuilder?
    
    @Published var running : Bool = false
    @Published var workout : HKWorkout?
    
    func startSession() -> Void {
        let config = HKWorkoutConfiguration()
        config.activityType = .mindAndBody
        config.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthstore, configuration: config)
            builder = session!.associatedWorkoutBuilder()
        } catch {
            print("Error building workout session with given configurations.")
        }
        let predicate = HKQuery.predicateForObjects(from: HKSource.default())
        builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthstore, workoutConfiguration: config)
        builder!.dataSource!.enableCollection(for: HKQuantityType(.respiratoryRate), predicate: predicate)
        builder!.shouldCollectWorkoutEvents = true
        
        session!.delegate = self
        builder!.delegate = self
        
        session!.startActivity(with: .now)
        builder!.beginCollection(withStart: .now) { (success, error) in
            guard success else {
                print("Error has occured in collecting activity information.")
                return
            }
            print("Live session started successfully")
        }
    }
    
    func endSession () -> Void {
        if let session = session, let builder = builder {
            session.end()
            builder.endCollection(withEnd: .now) { _, _ in
                self.session = nil
                self.builder = nil
            }
            print("Successfully ended live session.")
        } else {
            session = nil
            builder = nil
        }
    }
    
    func requestAuthorization() -> Void {
        let biometric_info =
            Set([
                HKQuantityType(.respiratoryRate),
            ])
        healthstore.requestAuthorization(toShare: biometric_info, read: biometric_info) {(success, error) in
            if !success {
                print("Error has occurred")
            }
        }
    }
}

extension BiometricWorkoutManager : HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
            print("State switched to running.")
        }
        
        if toState == .ended {
            print("State switch to ended.")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
    
    
}

extension BiometricWorkoutManager : HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
}
