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
            print("Currently making PUT request")
            
            guard let url = URL(string: "http://192.168.8.131:8000/") else {
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
    @State var healthStore : HKHealthStore
    let hrValue = HKUnit(from:"count/min")
    
    init() {
        healthStore = HKHealthStore()
        
        let heart_beat_info = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])
        healthStore.requestAuthorization(toShare: heart_beat_info, read: heart_beat_info) {(success, error) in
            if !success {
                print("Error has occurred")
            }
        }
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
            
            prevHR = samples.last!.quantity.doubleValue(for: hrValue)
            value = Int(prevHR)
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        print("Executing Query")
        healthStore.execute(query)
    }
    
    var body: some View {
        HStack {
            Text("♥")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("\(value)")
                .fontWeight(.bold)
                .font(.system(size: 50))// Temporary value before implementation of health store
            VStack {
                Text("BPM")
                    .foregroundColor(.red)
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
