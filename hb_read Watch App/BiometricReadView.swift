//
//  ContentView.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 7/3/23.
//

import SwiftUI
import Foundation
import HealthKit
import Accelerate
import Charts

// Make sure to add
// Heart-rate variability, Respiratory rate, Resting Heart-rate
// Note, cannot use variables of property wrappers inside of a view.
let SAFE_WIDTH = WKInterfaceDevice.current().screenBounds.width * 0.8
let PICKER_HEIGHT = WKInterfaceDevice.current().screenBounds.height * 0.3
let MARGIN_OFFSET_WIDTH = WKInterfaceDevice.current().screenBounds.width * 0.1
let MARGIN_OFFSET_HEIGHT = WKInterfaceDevice.current().screenBounds.height * 0.1
let FORM_COMPONENTS_HEIGHT = WKInterfaceDevice.current().screenBounds.width * 0.15
let TEXT_FIELD_WIDTH = WKInterfaceDevice.current().screenBounds.width * 0.9
let SETTINGS_BUTTON_SIDE_LENGTH = WKInterfaceDevice.current().screenBounds.height * 0.175

func dynamicFontSize(size fontSize : CGFloat) -> CGFloat {
    let ratio = WKInterfaceDevice.current().screenBounds.width / 198
    return ratio * fontSize
}

struct BiometricReadView: View {
    @State private var hbValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .heartRate)
        }
    }
    
    @State var hrvValue : Int = 0 {
        didSet {
//            sendHTTPRequest(forRequestType: .POST, forBiometricType: .heartRateVar)
        }
    }
    
    @State var rrValue : Int = 0 {
        didSet {
//            sendHTTPRequest(forRequestType: .POST, forBiometricType: .respiratoryRate)
        }
    }
    
    @State var rhrValue : Int = 0 {
        didSet {
            sendHTTPRequest(forRequestType: .POST, forBiometricType: .restingHeartRate)
        }
    }
    
    @State var ecgGraph : [ECGData] = []
    @State var showGraph : Bool = false
    
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
    
    @State var address : String = "https://biometrics.uclalemur.com"
    @State var email : String = ""
    @State var defaultEmailAddresses : [String] = ["", "alexiseblock@g.ucla.edu", "ehng359@g.ucla.edu"]
    
    @State var recording : Bool = false
    @State var recordingStr : String = "Start Recording"
    
    @State var vaGridCoord : CGPoint = CGPoint(x: 0, y: 0)
    @State var valence : CGFloat = 0
    @State var resetLocation : Bool = false
    
    // Form information
    @State var formValence = 0.00
    @State var formArousal = 0.00
    
    @ObservedObject var notifDelegate = NotificationManager()
    
    init() {
        healthStore = HKHealthStore()
        workoutDelegate = BiometricWorkoutManager()

        let to_share_info =
            Set([
                HKQuantityType(.heartRate),
                HKQuantityType(.restingHeartRate),
                HKQuantityType(.respiratoryRate),
            ])
        
        let to_read_info =
            Set([
                HKQuantityType(.heartRate),
                HKQuantityType(.restingHeartRate),
                HKQuantityType(.respiratoryRate),
                HKQuantityType.electrocardiogramType()
            ])
        healthStore.requestAuthorization(toShare: to_share_info, read: to_read_info) {(success, error) in
            if !success {
                print("Error has occurred")
            }
        }
        workoutDelegate.requestAuthorization()
        notifDelegate.requestAuthorization()
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    VStack {
                        HStack {
                            Spacer(minLength: 5)
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .overlay(content: {
                                    Text("...")
                                        .offset(y:-3)
                                })
                                .frame(width: SETTINGS_BUTTON_SIDE_LENGTH, height: SETTINGS_BUTTON_SIDE_LENGTH)
                                .onTapGesture(perform: changeSettings)
                        }
                        Spacer()
                        HStack{
                            Text("♥")
                                .font(.system(size: dynamicFontSize(size: 50)))
                                .foregroundColor(.red)
                            Text("\(hbValue)")
                                .fontWeight(.bold)
                                .font(.system(size: dynamicFontSize(size: 50)))
                                .fixedSize(horizontal: true, vertical: false)
                                .background(.clear)
                            Text("BPM")
                                .foregroundStyle(.red)
                        }
                        .frame(width: TEXT_FIELD_WIDTH, alignment: .center)
                        .offset(x: -MARGIN_OFFSET_WIDTH, y: -MARGIN_OFFSET_HEIGHT)
                        Spacer()
                    }
                    .listItemTint(.clear)
                    .frame(height: SAFE_WIDTH)
                    
                    switch(selectedVAType) {
                    case "Grid":
                        VAGrid(
                            location: Binding<CGPoint>(get: { vaGridCoord }, set: { vaGridCoord = $0 }),
                            reset: Binding<Bool>(get: { resetLocation }, set: { resetLocation = $0 })
                        )
                        .frame(width: SAFE_WIDTH, height: SAFE_WIDTH)
                        .listItemTint(.clear)
                        .id(0)
                    case "Line":
                        VALine(
                            valence: Binding<CGFloat>(get: { vaGridCoord.x }, set: { vaGridCoord.x = $0 }),
                            reset: Binding<Bool>(get: { resetLocation }, set: { resetLocation = $0 })
                        )
                        .frame(width: SAFE_WIDTH, height: SAFE_WIDTH)
                        .listItemTint(.clear)
                        .id(0)
                    case "Form":
                        HStack {
                            Text("Valence: ")
                                .offset(x: MARGIN_OFFSET_WIDTH)
                            Spacer()
                            TextField("Valence", value: $formValence, format: .number)
                                .onSubmit {
                                    if formValence > 1 {
                                        formValence = 1
                                    } else if formValence < 0 {
                                        formValence = 0
                                    }
                                }
                                .offset(x: MARGIN_OFFSET_WIDTH)
                                .foregroundColor(.black)
                        }
                        .background(.primary)
                        .foregroundColor(.secondary)
                        .frame(width: SAFE_WIDTH, height:  FORM_COMPONENTS_HEIGHT)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        
                        HStack {
                            Text("Arousal: ")
                                .offset(x: MARGIN_OFFSET_WIDTH)
                            Spacer()
                            TextField("Arousal", value: $formArousal, format: .number)
                                .onSubmit {
                                    if formArousal > 1 {
                                        formArousal = 1
                                    } else if formArousal < 0 {
                                        formArousal = 0
                                    }
                                }
                                .offset(x: MARGIN_OFFSET_WIDTH)
                                .foregroundColor(.black)
                        }
                        .background(.primary)
                        .foregroundColor(.secondary)
                        .frame(width: SAFE_WIDTH, height:  FORM_COMPONENTS_HEIGHT)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        
                        Button("Submit") {
                            vaGridCoord.x = formValence
                            vaGridCoord.y = formArousal
                            formValence = 0
                            formArousal = 0
                        }
                        .frame(width: SAFE_WIDTH, height: FORM_COMPONENTS_HEIGHT)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        .id(0)
                    case _:
                        Rectangle()
                            .overlay {
                                Text("No choice selected. Change in the settings.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.black)
                            }
                            .cornerRadius(5)
                            .frame(width: SAFE_WIDTH, height: SAFE_WIDTH)
                            .listItemTint(.clear)
                            .id(0)
                    }
                    
                    if showGraph {
                        Chart(ecgGraph, id: \.time) {
                            LineMark(
                                x: .value("Time", $0.time),
                                y: .value("Voltage", $0.voltage)
                            )
                            .foregroundStyle(by: .value("type", $0.type))
                        }
                        .scrollDisabled(false)
                        .chartXScale(domain: 0...3)
                        .chartXAxisLabel("Time (s)")
                        .chartYAxisLabel("Voltage (mV)")
                        .frame(width: SAFE_WIDTH, height: SAFE_WIDTH)
                        .listItemTint(.clear)
                    }
                }
                .listStyle(.plain)
                .frame(width: SAFE_WIDTH * 1.1, height: SAFE_WIDTH)
                .onReceive(notifDelegate.$hasNotified) { hasNotified in
                    if hasNotified {
                        notifDelegate.hasNotified = false
                        proxy.scrollTo(0)
                    }
                }
            }
            
            
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
                            .font(.system(size: dynamicFontSize(size: 30)))
                        Spacer()
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .overlay(content: {
                                Text("X")
                            })
                            .frame(width: SETTINGS_BUTTON_SIDE_LENGTH, height: SETTINGS_BUTTON_SIDE_LENGTH)
                            .onTapGesture(perform: changeSettings)
                    }
                    .listItemTint(.clear)
                    
                    TextField("Address (Required)", text: $address)
                        .background(Color.primary)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        .foregroundColor(.black)
                        .frame(width: TEXT_FIELD_WIDTH, alignment: .center)

                    VStack {
                        Text("Confirmation:")
                            .frame(width: TEXT_FIELD_WIDTH, alignment: .leading)
                            .font(.system(size: dynamicFontSize(size: 16)))
                            .fontWeight(.bold)
                        if address == "" {
                            Text("https://example.com")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 12))
                        } else {
                            Text("\(address)")
                                .foregroundColor(Color.gray)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 12))
                        }
                    }
                    .listItemTint(.clear)
                    
                    TextField("Email", text: $email)
                        .background(Color.primary)
                        .cornerRadius(10)
                        .listItemTint(.clear)
                        .foregroundColor(.black)
                        .frame(width: TEXT_FIELD_WIDTH, alignment: .center)

                    VStack {
                        Text("Confirmation:")
                            .frame(width: WKInterfaceDevice.current().screenBounds.width, alignment: .leading)
                            .font(.system(size: dynamicFontSize(size: 16)))
                            .fontWeight(.bold)
                        if email == "" {
                            Text("JohnDoe@gmail.com")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 12))
                        } else {
                            Text("\(email)")
                                .foregroundColor(Color.gray)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.system(size: 12))
                        }
                    }
                    .listItemTint(.clear)
                    
                    Picker("Default Email Address", selection: $email){
                        ForEach(defaultEmailAddresses, id: \.self) {str in
                            if str != "" {
                                Text(str)
                            } else {
                                Text("No email selected.")
                            }
                        }
                    }
                    .frame(width: SAFE_WIDTH,
                           height: PICKER_HEIGHT)
                    .onChange(of: email, perform: {_ in
                        if defaultEmailAddresses.count == 4 {
                            _ = defaultEmailAddresses.popLast()
                        }
                        if !defaultEmailAddresses.contains(email) {
                            defaultEmailAddresses.append(email)
                        }
                    })
                
                    Picker("VA Display Type", selection: $selectedVAType){
                        ForEach(vaTypes, id: \.self) {str in
                            Text(str)
                        }
                    }
                    .frame(width: SAFE_WIDTH,
                           height: PICKER_HEIGHT)

                    Picker("Activity Type", selection: $selectedActivityType){
                        ForEach(activityTypes, id: \.self) {str in
                            Text(str)
                        }
                    }
                    .frame(width: SAFE_WIDTH,
                           height: PICKER_HEIGHT)
                }
                .background(Color.black)
                .frame(width: WKInterfaceDevice.current().screenBounds.width)
                .listStyle(.carousel)
            }
        }
        .padding(EdgeInsets(top: MARGIN_OFFSET_HEIGHT, leading: MARGIN_OFFSET_WIDTH, bottom: MARGIN_OFFSET_HEIGHT, trailing: MARGIN_OFFSET_WIDTH))
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
    
    /// Functionally generates a change to particular the associated Biometric values held by the BiometricReadView.
    func updateBiometricState (withType type : BiometricType, withValue newValue : Int, withTime time : String) -> Void {
        timeOfSample = time
        switch(type){
        case .heartRate:
            hbValue = newValue
//        case .heartRateVar:
//            hrvValue = newValue
//        case .respiratoryRate:
//            rrValue = newValue
        case .restingHeartRate:
            rhrValue = newValue
        case _:
            return
        }
    }
    
    func handleResponse (for response : [String: Any], forRequestType requestType: RequestType, forBiometricType biometricType : BiometricType) {
        
        switch((requestType, biometricType)){
        case (.POST, .ecg):
            print("response", response)
            if let hrv = response["hrv"] as? Double{
                hrvValue = Int(hrv)
            }
            if let rr = response["rr"] as? Int {
                rrValue = rr
            }
            notifDelegate.generateRequest()
        case _:
            return
        }
    }
    
    /// Sends a generic HTTP Request to a hosted server to publish recorded values.
    func sendHTTPRequest (forRequestType requestType : RequestType, forBiometricType biometricType : BiometricType) -> Void {
        if address != "" && recording == true   {
//            print("Currently making \(requestType.rawValue) request")
            
            let endpoint = address + (biometricType == .ecg ? "/process_ecg/" : "")
            guard let url = URL(string: endpoint) else {
                print("Error creating URL object")
                return
            }
            
            var request = URLRequest(url: url)
//            print("Secured URL: \(address == "https://biometrics.uclalemur.com" ? "DEFAULT" : address)")
            
            request.httpMethod = requestType.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let coordChosen = (vaGridCoord.x != 0 || vaGridCoord.y != 0)
            let id = WKInterfaceDevice.current().identifierForVendor!.uuidString
            
            var body : [String: AnyHashable]
            switch (requestType, biometricType){
            case (.POST, .ecg):
                do {
                    let ecgData = try JSONEncoder().encode(ecgGraph)
                    if let stringifiedData = String(data: ecgData, encoding: .utf8) {
                        body = [
                            "id": id,
                            "ecgData": stringifiedData
                        ]
                    } else {
                        return
                    }
                } catch {
                    print("Error in ECG Graph Structure.")
                    return
                }
            case (.PUT, _):
                body = [
                    "id" : id,
                    "email" : email
                ]
            case (.POST, _):
                body = [
                    "id" : id,
                    "date" : timeOfSample,
                    "heartBeat": biometricType == .heartRate ? hbValue : NSNull(),
                    "respiratoryRate": rrValue != 0 ? rrValue : NSNull(),
                    "heartBeatVar" : hrvValue != 0 ? hrvValue : NSNull(),
                    "restingHeartRate" : biometricType == .restingHeartRate ? rhrValue : NSNull(),
                    "valence" : coordChosen ? vaGridCoord.x : NSNull(),
                    "arousal" : coordChosen ? vaGridCoord.y : NSNull(),
                    "activity" : selectedActivityType
                ]
                print("Heart-beat variation: \(hrvValue)")
                rrValue = 0
            }
            
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
                        if let response = response {
                            handleResponse(for: response, forRequestType: requestType, forBiometricType: biometricType)
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
            
            let hrvUpdateHandler = decideHandler(.heartRateVar)
            let hrvQuery = HKAnchoredObjectQuery(
                type: HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: hrvUpdateHandler
            )
            hrvQuery.updateHandler = hrvUpdateHandler
            
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
            
            let ecgQuery = HKAnchoredObjectQuery(
                type: HKQuantityType.electrocardiogramType(),
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: { query, samples, deletedObjects, queryAnchor, error in
                    return
                }
            )
            
            ecgQuery.updateHandler = { query, samples, deletedObjects, queryAnchor, error in
                guard let ecgSample = samples!.last as? HKElectrocardiogram else { return }
                ecgGraph = []
                let voltageQuery = HKElectrocardiogramQuery(ecgSample) { (query, result) in
                    switch(result) {
                    case .measurement(let measurement):
                        if let voltageQuantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                            ecgGraph.append(ECGData(type: "Raw", time: measurement.timeSinceSampleStart, voltage: voltageQuantity.doubleValue(for: .voltUnit(with: .milli ))))
                        }
                    case .done:
                        DispatchQueue.global(qos: .background).async {
                            sendHTTPRequest(forRequestType: .POST, forBiometricType: .ecg)
                        }
                    case .error(let error):
                        // Handle the error here.
                        print(error)
                    case _:
                        print("Result was of unknown type.")
                    }
                }
                
                healthStore.execute(voltageQuery)
            }
            
            print("Executing Query")
            healthStore.execute(rhrQuery)
//            healthStore.execute(hrvQuery)
//            healthStore.execute(rrQuery)
            healthStore.execute(hrQuery)
            healthStore.execute(ecgQuery)
            
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
    case ecg
    case none
}

enum RequestType : String {
    case PUT = "PUT"
    case POST = "POST"
}

struct ECGData : Codable {
    var type : String
    var time : Double
    var voltage : Double
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricReadView()
    }
}
