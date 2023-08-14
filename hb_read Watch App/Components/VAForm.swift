//
//  VAForm.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 8/11/23.
//

import Foundation
import SwiftUI

struct VAForm : View {
    @Binding var valence : CGFloat
    @State var formValence = 0.00
    
    @Binding var arousal : CGFloat
    @State var formArousal = 0.00
    
    @Binding var reset : Bool
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Valence: ")
                    Spacer()
                    TextField("Valence", value: $formValence, format: .number)
                        .onSubmit {
                            if formValence > 1 {
                                formValence = 1
                            } else if formValence < 0 {
                                formValence = 0
                            }
                        }
                }
                .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.8, height:  WKInterfaceDevice.current().screenBounds.width * 0.15)
                HStack {
                    Text("Arousal: ")
                    Spacer()
                    TextField("Arousal", value: $formArousal, format: .number)
                        .onSubmit {
                            if formArousal > 1 {
                                formArousal = 1
                            } else if formArousal < 0 {
                                formArousal = 0
                            }
                        }
                }
                .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.8, height:  WKInterfaceDevice.current().screenBounds.width * 0.15)
            }
            Button("Submit") {
                valence = formValence
                arousal = formArousal
                formValence = 0
                formArousal = 0
            }
        }
    }
}
