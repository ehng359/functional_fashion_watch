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
// Note, cannot use variables of property wrappers inside of a view.
let safeWidth = WKInterfaceDevice.current().screenBounds.width * 0.8

struct BiometricReadView: View {
    @State private var hbValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .heartRate)
        }
    }
    @State var hrvTotalCount : Double = 0
    @State var hrvRunningSummation : Double = 0
    @State var prevRRInterval : Double = 0
    
    @State var rrValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .respiratoryRate)
        }
    }
    
    @State var rhrValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .restingHeartRate)
        }
    }
    
    // Query Information
    @State var healthStore : HKHealthStore
    @State var workoutDelegate : BiometricWorkoutManager
    
    @State var settings : Bool = false
    @State var queryHasSent : Bool = false
    @State var jsonResponse : [String : Any] = [:]
    @State var timeOfSample : String = ""
    @State var selectedVAType = "None"
    let vaTypes = ["None", "Grid", "Line", "Form"]
    @State var selectedActivityType = "None"
    let activityTypes = ["None", "Family/Friends", "Entertainment", "Exercising", "Work/Study", "Public", "Sleeping"]
    
    @State var recording : Bool = false
    @State var recordingStr : String = "Start Recording"
    
    @State var address : String = "https://biometrics.uclalemur.com"
    @State var email : String = ""
    
    @State var vaGridCoord : CGPoint = CGPoint(x: 0, y: 0)
    @State var valence : CGFloat = 0
    @State var resetLocation : Bool = false
    
    // Form information
    @State var formValence = 0.00
    @State var formArousal = 0.00
    
    init() {
        healthStore = HKHealthStore()
        workoutDelegate = BiometricWorkoutManager()

        let biometric_info =
            Set([
                HKQuantityType(.heartRate),
                HKQuantityType(.restingHeartRate),
                HKQuantityType(.respiratoryRate),
                HKQuantityType.workoutType()
            ])
        healthStore.requestAuthorization(toShare: biometric_info, read: biometric_info) {(success, error) in
            if !success {
                print("Error has occurred")
            }
        }
        workoutDelegate.requestAuthorization()
    }
    
    var body: some View {
        ZStack {
            List{
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
                    .offset(y: -WKInterfaceDevice.current().screenBounds.width * 0.10)
                    HStack{
                        Text("♥")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("\(hbValue)")
                            .fontWeight(.bold)
                            .font(.system(size: 50))
                        VStack {
                            Text("BPM")
                                .foregroundStyle(.red)
                        }
                    }
                    .offset(y: -WKInterfaceDevice.current().screenBounds.width * 0.10)
                }
                .listItemTint(.clear)
                .frame(height: safeWidth)
                
                switch(selectedVAType) {
                case "Grid":
                    VAGrid(
                        location: Binding<CGPoint>(get: { vaGridCoord }, set: { vaGridCoord = $0 }),
                        reset: Binding<Bool>(get: { resetLocation }, set: { resetLocation = $0 })
                    )
                    .frame(width: safeWidth, height: safeWidth)
                    .listItemTint(.clear)
                case "Line":
                    VALine(
                        valence: Binding<CGFloat>(get: { vaGridCoord.x }, set: { vaGridCoord.x = $0 }),
                        reset: Binding<Bool>(get: { resetLocation }, set: { resetLocation = $0 })
                    )
                    .frame(width: safeWidth, height: safeWidth)
                    .listItemTint(.clear)
                case "Form":
                    HStack {
                        Text("Valence: ")
                            .offset(x: WKInterfaceDevice.current().screenBounds.width * 0.1)
                        Spacer()
                        TextField("Valence", value: $formValence, format: .number)
                            .onSubmit {
                                if formValence > 1 {
                                    formValence = 1
                                } else if formValence < 0 {
                                    formValence = 0
                                }
                            }
                            .offset(x: WKInterfaceDevice.current().screenBounds.width * 0.1)
                            .foregroundColor(.black)
                    }
                    .background(.primary)
                    .foregroundColor(.secondary)
                    .frame(width: safeWidth, height:  WKInterfaceDevice.current().screenBounds.width * 0.15)
                    .cornerRadius(10)
                    .listItemTint(.clear)
                    
                    HStack {
                        Text("Arousal: ")
                            .offset(x: WKInterfaceDevice.current().screenBounds.width * 0.1)
                        Spacer()
                        TextField("Arousal", value: $formArousal, format: .number)
                            .onSubmit {
                                if formArousal > 1 {
                                    formArousal = 1
                                } else if formArousal < 0 {
                                    formArousal = 0
                                }
                            }
                            .offset(x: WKInterfaceDevice.current().screenBounds.width * 0.1)
                            .foregroundColor(.black)
                    }
                    .background(.primary)
                    .foregroundColor(.secondary)
                    .frame(width: safeWidth, height:  WKInterfaceDevice.current().screenBounds.width * 0.15)
                    .cornerRadius(10)
                    .listItemTint(.clear)
                    
                    Button("Submit") {
                        vaGridCoord.x = formValence
                        vaGridCoord.y = formArousal
                        formValence = 0
                        formArousal = 0
                    }
                    .frame(width: safeWidth, height: WKInterfaceDevice.current().screenBounds.width * 0.15)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .cornerRadius(10)
                    .listItemTint(.clear)
                case _:
                    Rectangle()
                        .overlay {
                        Text("No choice selected. Change in the settings.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.black)
                        }
                        .cornerRadius(5)
                        .frame(width: safeWidth, height: safeWidth)
                        .listItemTint(.clear)
                }
            }
            .listStyle(.plain)
            .frame(width: safeWidth * 1.1, height: safeWidth)
            
            if !settings {
                Button("\(recordingStr)", action: changeRecording)
                    .frame(height: WKInterfaceDevice.current().screenBounds.width * 0.2)
                    .background(.black)
                    .cornerRadius(13.0)
                    .foregroundColor(.white)
                    .offset(y: WKInterfaceDevice.current().screenBounds.width * 0.5)
            }
                            
            if settings {
                List {
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
                    .listItemTint(.clear)
                    
                    TextField("Address (Required)", text: $address)
                        .background(Color.primary)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        .foregroundColor(.black)
                        .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.9, alignment: .center)

                    VStack {
                        Text("Confirmation:")
                            .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.9, alignment: .leading)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        if address == "" {
                            Text("https://example.com")
                                .frame(minWidth: 0, maxWidth: .infinity)
                        } else {
                            Text("\(address)")
                                .foregroundColor(Color.gray)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }
                    }
                    .listItemTint(.clear)
                    
                    TextField("Email", text: $email)
                        .background(Color.primary)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        .foregroundColor(.black)
                        .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.9, alignment: .center)

                    VStack {
                        Text("Confirmation:")
                            .frame(width: WKInterfaceDevice.current().screenBounds.width, alignment: .leading)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        if email == "" {
                            Text("JohnDoe@gmail.com")
                                .frame(minWidth: 0, maxWidth: .infinity)
                        } else {
                            Text("\(email)")
                                .foregroundColor(Color.gray)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }
                    }
                    .listItemTint(.clear)
                    
                    Picker("VA Display Type", selection: $selectedVAType){
                        ForEach(vaTypes, id: \.self) {str in
                            Text(str)
                        }
                    }
                    .frame(width: safeWidth,
                           height: WKInterfaceDevice.current().screenBounds.height * 0.3)
                    
                    Picker("Activity Type", selection: $selectedActivityType){
                        ForEach(activityTypes, id: \.self) {str in
                            Text(str)
                        }
                    }
                    .frame(width: safeWidth,
                           height: WKInterfaceDevice.current().screenBounds.height * 0.3)
                }
                .background(Color.black)
                .frame(width: WKInterfaceDevice.current().screenBounds.width)
                .listStyle(.carousel)
            }
        }
        .padding()
        .onAppear(perform: getBiometrics)
    }
}

// All necessary functions to get the BiometricReadView to work.
extension BiometricReadView {
    /// Changes views to display the settings view.
    func changeSettings () -> Void {
        settings = !settings
    }
    
    /// Initiates a recording session which allows for recordings to remain active or stops a recording session, depending on the self.recording state.
    func changeRecording () -> Void {
        if recording {
            recordingStr = "Start Recording"
            sendHTTPRequest(forRequestType: .PUT, forBiometricType: .heartRate)
            recording = !recording
            
            workoutDelegate.endSession()
            return
        }
        if (address != "") {
            recordingStr = "Stop Recording"
            recording = !recording
            workoutDelegate.startSession()
        } else {
            print("No address has been inputted. Recording was not initiated.")
        }
    }
    
    /// Computes the ongoing HRV value
    func computeRunningHRV(_ heartBeat : Int) -> Int? {
        var hrv : Int
        if (heartBeat != 0) {
            hrvTotalCount += 1
            let RRInterval = 1.0/(Double(heartBeat)/60000.0)
            if hrvTotalCount > 1.0 {
                let rrDiff = RRInterval - prevRRInterval
                hrvRunningSummation += rrDiff * rrDiff
                let RMSSD = sqrt((1.0/(hrvTotalCount - 1.0)) * (hrvRunningSummation))
                hrv = Int(RMSSD)
                return hrv
            }
            prevRRInterval = RRInterval
        }
        return nil
    }
    
    /// Functionally generates a change to particular the associated Biometric values held by the BiometricReadView.
    func updateBiometricState (withType type : BiometricType, withValue newValue : Int, withTime time : String) -> Void {
        timeOfSample = time
        switch(type){
        case .heartRate:
            hbValue = newValue
            return
        case .respiratoryRate:
            rrValue = newValue
            return
        case .restingHeartRate:
            rhrValue = newValue
            return
        case _:
            return
        }
    }
    
    /// Sends a generic HTTP Request to a hosted server to publish recorded values.
    func sendHTTPRequest (forRequestType requestType : RequestType, forBiometricType biometricType : BiometricType) -> Void {
        if address != "" && recording == true   {
            print("Currently making \(requestType.rawValue) request")
            
            guard let url = URL(string: address) else {
                print("Error creating URL object")
                return
            }
            
            var request = URLRequest(url: url)
            print("Secured URL: \(address == "https://biometrics.uclalemur.com" ? "DEFAULT" : address)")
            
            request.httpMethod = requestType.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let coordChosen = (vaGridCoord.x != 0 || vaGridCoord.y != 0)
            let body : [String: AnyHashable] = requestType == .POST ? [
                "id" : WKInterfaceDevice.current().identifierForVendor!.uuidString,
                "date" : timeOfSample,
                "heartBeat": biometricType == .heartRate ? hbValue : NSNull(),
                "respiratoryRate": biometricType == .respiratoryRate ? rrValue : NSNull(),
                "heartBeatVar" : biometricType == .heartRate ? computeRunningHRV(hbValue) : NSNull(),
                "restingHeartRate" : biometricType == .restingHeartRate ? rhrValue : NSNull(),
                "valence" : coordChosen ? vaGridCoord.x : NSNull(),
                "arousal" : coordChosen ? vaGridCoord.y : NSNull(),
                "activity" : selectedActivityType
            ] : [
                "id" : WKInterfaceDevice.current().identifierForVendor!.uuidString,
                "email" : email
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
                        let response = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]
                        if requestType == .PUT {
                            jsonResponse = response!
                            let content = jsonResponse["JSON_Content"] as! [[String:AnyHashable]]
                            print(jsonResponse["JSON_Content"]!)
                            print(content)
                        }
                        if coordChosen {
                            vaGridCoord = CGPoint(x:0, y:0)
                            resetLocation = true
                        }
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
    
    /// Initiates queries to constantly retrieve HealthKit values and instantiates the HKWorkoutSession to maintain activity status on the application.
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
             Heart-rate variability (ms) - samples every ~5 seconds (live estimation)
             Respiratory rate (BPM) - samples every ~10 minutes, requires 'Sleep Mode'
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
            healthStore.execute(rhrQuery)
            healthStore.execute(rrQuery)
            healthStore.execute(hrQuery)
            
            queryHasSent = true
        }
    }
}

// All necessary enumerations to indicate differences in values being updated within the view.
enum BiometricType {
    case heartRate
    case restingHeartRate
    case heartRateVar
    case respiratoryRate
    case none
}

enum RequestType : String {
    case PUT = "PUT"
    case POST = "POST"
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricReadView()
    }
}
