//
//  VALine.swift
//  hb_read Watch App
//
//  Created by Edward Ng on 8/11/23.
//

import Foundation
import SwiftUI

let sliderWidth = WKInterfaceDevice.current().screenBounds.width * 0.7
let sliderHeight = WKInterfaceDevice.current().screenBounds.width * 0.025
let dragComponentRadius = WKInterfaceDevice.current().screenBounds.width * 0.09

struct VALine : View {
    @Binding var valence : CGFloat
    @Binding var reset : Bool
    @State var isDragging : Bool = false
    @State var position : CGFloat = sliderWidth/2

    var dragGesture : some Gesture {
        DragGesture()
            .onChanged() { event in
                isDragging = true
                let newValue = position + event.translation.width
                if newValue > sliderWidth {
                    position = sliderWidth
                    return
                } else if newValue < 0 {
                    position = 0
                    return
                }
                position = newValue
                valence = 2 * position/sliderWidth - 1
            }
            .onEnded() { event in
                valence = 2 * position/sliderWidth - 1
                isDragging = false
            }
    }

    var body : some View {
        Rectangle()
            .frame(width: sliderWidth, height: sliderHeight)
            .cornerRadius(25)
            .overlay {
                ZStack {
                    Text("Valence")
                        .position(x: WKInterfaceDevice.current().screenBounds.width * 0.2, y: -WKInterfaceDevice.current().screenBounds.height/4)
                        .fontWeight(.bold)
                        .font(.system(size: 28))
                    Circle()
                        .frame(width: dragComponentRadius, height: dragComponentRadius)
                        .foregroundColor(.blue)
                        .gesture(dragGesture)
                        .position(x: position, y: sliderHeight/2)
                    Text("\(valence)")
                        .offset(y: 15)
                }
                .offset(y: 7)
            }
            .onChange(of: reset) {_ in
                reset = false
                if !isDragging {
                    valence = 0
                    position = sliderWidth/2
                }
            }
    }
}
