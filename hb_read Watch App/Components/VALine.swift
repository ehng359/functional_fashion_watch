//
//  VALine.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 8/11/23.
//

import Foundation
import SwiftUI

let sliderWidth = WKInterfaceDevice.current().screenBounds.width * 0.7
let sliderHeight = WKInterfaceDevice.current().screenBounds.width * 0.05
let dragComponentRadius = WKInterfaceDevice.current().screenBounds.width * 0.09

struct VALine : View {
    @Binding var valence : CGFloat
    @State var position : CGFloat = sliderWidth/2

    var dragGesture : some Gesture {
        DragGesture()
            .onChanged() { event in
                print(event.translation.width)
                let newValue = position + event.translation.width
                if newValue > sliderWidth {
                    position = sliderWidth
                    return
                } else if newValue < 0 {
                    position = 0
                    return
                }
                position = newValue
            }
            .onEnded() { event in
                valence = position/sliderWidth
            }
    }

    var body : some View {
        Rectangle()
            .frame(width: sliderWidth, height: sliderHeight)
            .cornerRadius(25)
            .overlay {
                Circle()
                    .frame(width: dragComponentRadius, height: dragComponentRadius)
                    .foregroundColor(.blue)
                    .gesture(dragGesture)
                    .position(x: position, y: sliderHeight/2)
            }
    }
}
