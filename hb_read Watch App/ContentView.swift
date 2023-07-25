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
    @State private var hasRequested : Bool = false
//    @State private var value : Int = 0
    @State private var value : Int = 0 {
        didSet {
            // Handle some kind of POST/PUT to a server/database
            if address != "" && recording == true{
                print("Currently making PUT request")
                
                guard let url = URL(string: address) else {
                    print("Error creating URL object")
                    return
                }
                
                var request = URLRequest(url: url)
                print("Secured URL")
                
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body : [String: AnyHashable] = [
                    "heartBeat": value
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
                            print(response)
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
                hasRequested = true
                print("Finished PUT request")
            }
        }
    }
    @State var healthStore : HKHealthStore
    @State var settings : Bool = false
    @State var recording : Bool = false
    @State var address : String = ""
    let hrValue = HKUnit(from:"count/min")
    
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
    
    private func getHB () {
        // Predicate for filtering out a query
        let predicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        // A query that provides continuous, long-term monitoring of changes for the value that we want to observe changes within
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            var prevHR : Double = 0.0
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            let lastSample = samples.last
            
            if lastSample != nil  {
                prevHR = lastSample!.quantity.doubleValue(for: hrValue)
                value = Int(prevHR)
            }
        }
        
        /*
            Note: the other iteration of anchored object query with queryDescriptors
            simple compiles all recorded values at particular time intervals into a
            single array of values.
         
            Heart-rate (BPS) - sample every ~5 seconds
            Respiratory rate (BPM) - samples every ~10 minutes
            Heart-rate variability (ms) - samples every 3 to 5 hours
         */
        let heartRateQuery = HKAnchoredObjectQuery(
            type: HKObjectType.quantityType(forIdentifier: .heartRate)!,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler
        )
        
        heartRateQuery.updateHandler = updateHandler
        print("Executing Query")
        healthStore.execute(heartRateQuery)
        
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
                    Text("\(value)")
                        .fontWeight(.bold)
                        .font(.system(size: 50))
                    // Temporary value before implementation of health store
                    VStack {
                        Text("BPM")
                            .foregroundStyle(.red)
                    }
                }
            }.offset(y: -20)
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
        .onAppear(perform: getHB)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
