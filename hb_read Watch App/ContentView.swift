//
//  ContentView.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 7/3/23.
//

import SwiftUI
import HealthKit

// Make sure to add
// Heart-rate variability, Respiratory rate, Resting Heart-rate

struct ContentView: View {
    @State private var hbValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .heartRate)
        }
    }
    @State var rhrValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .restingHeartRate)
        }
    }
    @State var hrVarValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .heartRateVar)
        }
    }
    @State var rrValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .respiratoryRate)
        }
    }
    
    @State var healthStore : HKHealthStore
    @State var settings : Bool = false
    @State var queryHasSent : Bool = false
    @State var timeOfSample : String = ""
    
    @State var recording : Bool = false
    @State var recordingStr : String = "Start Recording"
    
    @State var address : String = ""
    
    enum BiometricType {
        case heartRate
        case restingHeartRate
        case heartRateVar
        case respiratoryRate
    }
    
    enum RequestType : String {
        case PUT = "PUT"
        case POST = "POST"
    }
    
    init() {
        healthStore = HKHealthStore()
        
        let biometric_info =
            Set([
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
            ])
        healthStore.requestAuthorization(toShare: biometric_info, read: biometric_info) {(success, error) in
            if !success {
                print("Error has occurred")
            }
        }
    }
    
    func changeSettings () -> Void {
        settings = !settings
    }
    
    func changeRecording () -> Void {
        if recording {
            recordingStr = "Start Recording"
            recording = !recording
            return
        }
        recordingStr = "Stop Recording"
        recording = !recording
    }
    
    func updateBiometricState (withType type : BiometricType, withValue newValue : Int, withTime time : String) -> Void {
        timeOfSample = time
        switch(type){
        case .heartRate:
            print("HR")
            hbValue = newValue
            return
        case .heartRateVar:
            print("HRVAR")
            hrVarValue = newValue
            return
        case .respiratoryRate:
            print("RR")
            rrValue = newValue
            return
        case .restingHeartRate:
            print("RHR")
            rhrValue = newValue
            return
        }
    }
    
    func sendHTTPRequest (forRequestType requestType : RequestType, forBiometricType biometricType : BiometricType) -> Void {
        if address != "" && recording == true{
            print("Currently making \(requestType.rawValue) request")
            
            guard let url = URL(string: address) else {
                print("Error creating URL object")
                return
            }
            
            var request = URLRequest(url: url)
            print("Secured URL")
            
            request.httpMethod = requestType.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body : [String: AnyHashable] = [
                "date" : timeOfSample,
                "heartBeat": biometricType == .heartRate ? hbValue : NSNull(),
                "respiratoryRate": biometricType == .respiratoryRate ? rrValue : NSNull(),
                "heartBeatVar" : biometricType == .heartRateVar ? hrVarValue : NSNull(),
                "restingHeartRate" : biometricType == .restingHeartRate ? rhrValue : NSNull(),
            ]
            
            
            do {
                let requestBody = try JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
                request.httpBody = requestBody
            } catch {
                print("Error turning body into JSON serializable data.")
                return
            }
            
            let session = URLSession.shared
            let task = session.dataTask(with: request) {data, _, error in
                if error == nil && data != nil{
                    do {
                        let response = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyHashable]
                        print(response!)
                    } catch {
                        print("Error occured when parsing response data")
                        return
                    }
                } else {
                    print("Error occured with data structure")
                    return
                }
                
            }
            task.resume()
            print("Finished \(requestType.rawValue) request")
        }
    }
    
    private func getBiometrics () {
        // Predicate for filtering out a query
        if !queryHasSent {
            let predicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
            
            // A query that provides continuous, long-term monitoring of changes for the value that we want to observe changes within
            let decideHandler : (BiometricType) -> (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { type in
                
                var unitMeasurement : HKUnit
                if type == .heartRate || type == .restingHeartRate || type == .respiratoryRate {
                    unitMeasurement = HKUnit(from: "count/min")
                } else {
                    unitMeasurement = HKUnit(from: "ms")
                }
                
                let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
                    query, samples, deletedObjects, queryAnchor, error in
                    
                    var prevHR : Double = 0.0
                    guard let samples = samples as? [HKQuantitySample] else {
                        return
                    }
                    
                    let lastSample = samples.last
                    
                    if lastSample != nil  {
                        prevHR = lastSample!.quantity.doubleValue(for: unitMeasurement)
                        
                        print("\(Int(prevHR))")
                        updateBiometricState(withType: type, withValue: Int(prevHR), withTime: lastSample!.endDate.description)
                    }
                }
                
                return updateHandler
            }
            
            /*
             Note: the other iterations of anchored object query with queryDescriptors
             simple compiles all recorded values at particular time intervals into a
             single array of values.
             
             Heart-rate (BPS) - sample every ~5 seconds
             Respiratory rate (BPM) - samples every ~10 minutes, requires 'Sleep Mode'
             Heart-rate variability (ms) - samples every 3 to 5 hours
             */
            
            let hrUpdateHandler = decideHandler(.heartRate)
            let hrQuery = HKAnchoredObjectQuery(
                type: HKObjectType.quantityType(forIdentifier: .heartRate)!,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: hrUpdateHandler
            )
            hrQuery.updateHandler = hrUpdateHandler
            
            let rrUpdateHandler = decideHandler(.respiratoryRate)
            let rrQuery = HKAnchoredObjectQuery(
                type: HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: rrUpdateHandler
            )
            rrQuery.updateHandler = rrUpdateHandler
            
            let hrVarUpdateHandler = decideHandler(.heartRateVar)
            let hrVarQuery = HKAnchoredObjectQuery(
                type: HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: hrVarUpdateHandler
            )
            hrVarQuery.updateHandler = hrVarUpdateHandler
            
            let rhrUpdateHandler = decideHandler(.restingHeartRate)
            let rhrQuery = HKAnchoredObjectQuery(
                type: HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: rhrUpdateHandler
            )
            rhrQuery.updateHandler = rhrUpdateHandler
            
            print("Executing Query")
            healthStore.execute(hrQuery)
            healthStore.execute(hrVarQuery)
            healthStore.execute(rhrQuery)
            healthStore.execute(rrQuery)
            
            queryHasSent = true
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer(minLength: 5)
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .overlay(content: {
                            Text("...")
                                .offset(y:-3)
                        })
                        .frame(width: 40, height: 40)
                        .onTapGesture(perform: changeSettings)
                }
                HStack{
                    Text("♥")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("\(hbValue)")
                        .fontWeight(.bold)
                        .font(.system(size: 50))
                    // Temporary value before implementation of health store
                    VStack {
                        Text("BPM")
                            .foregroundStyle(.red)
                    }
                }
                Button("\(recordingStr)", action: changeRecording)
                    
            }
            if settings {
                VStack {
                    Rectangle().fill(Color.black)
                        .overlay(content: {
                            VStack{
                                HStack{
                                    Text("Settings")
                                        .fontWeight(.bold)
                                        .font(.system(size: 30))
                                    Spacer()
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(content: {
                                            Text("X")
                                        })
                                        .frame(width: 40, height: 40)
                                        .onTapGesture(perform: changeSettings)
                                }
                                TextField("Address (Required)", text: $address)
                            }.offset(y: -29)
                        })
                }
            }
        }
        .padding()
        .onAppear(perform: getBiometrics)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
