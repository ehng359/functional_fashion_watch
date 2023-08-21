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
        config.activityType = .running
        config.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthstore, configuration: config)
            builder = session!.associatedWorkoutBuilder()
        } catch {
            print("Error building workout session with given configurations.")
        }
        builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthstore, workoutConfiguration: config)
        builder!.dataSource!.enableCollection(for: HKQuantityType(.respiratoryRate), predicate: nil)
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
        session!.end()
        builder!.endCollection(withEnd: .now) { (success, error) in
            guard success else {
                print("Error ending workout builder.")
                return
            }
            self.builder!.finishWorkout(completion: {workout, error in
                guard let error = error else {
                    self.workout = workout
                    return
                }

                return print("Error occured in finishing workout. \(error)")
            })
            print("Successfully ended live session.")
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
            endSession()
            print("State switch to ended.")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
    
    
}

extension BiometricWorkoutManager : HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            let statistics = workoutBuilder.statistics(for: quantityType)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("Builder: Event collected.")
    }
    
}
