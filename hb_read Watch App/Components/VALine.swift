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
    
    var tapGesture : some Gesture {
        SpatialTapGesture()
            .onEnded() { event in
                position = event.location.x
                print(position)
                if position > sliderWidth {
                    position = sliderWidth
                } else if position < 0 {
                    position = 0
                }
                valence = 2 * position/sliderWidth - 1
            }
    }

    var dragGesture : some Gesture {
        DragGesture()
            .onChanged() { event in
                isDragging = true
                let newValue = position + event.translation.width
                if newValue > sliderWidth {
                    position = sliderWidth
                } else if newValue < 0 {
                    position = 0
                } else {
                    position = newValue
                }
                valence = 2 * position/sliderWidth - 1
                print(safeWidth/2)
                print(position)
            }
            .onEnded() { event in
                valence = 2 * position/sliderWidth - 1
                isDragging = false
            }
    }

    var body : some View {
        Rectangle()
            .frame(width: safeWidth, height: safeWidth)
            .overlay {
                ZStack {
                    Text("Valence")
                        .position(x: WKInterfaceDevice.current().screenBounds.width * 0.2, y: WKInterfaceDevice.current().screenBounds.height * 0.05)
                        .fontWeight(.bold)
                        .font(.system(size: 28))

                    Rectangle()
                        .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.75, height: sliderHeight)
                        .position(x: safeWidth/2, y: safeWidth/2)
                        .cornerRadius(25)
                        .offset(x: -WKInterfaceDevice.current().screenBounds.width * 0.035 )


                    Circle()
                        .frame(width: dragComponentRadius, height: dragComponentRadius)
                        .foregroundColor(.blue)
                        .gesture(dragGesture)
                        .position(x: position, y: safeWidth/2)
                    Text("\(valence)")
                        .offset(y: 15)

                }
                .foregroundColor(.white)
                .offset(x: WKInterfaceDevice.current().screenBounds.width * 0.035 )
            }
            .onChange(of: reset) {_ in
                reset = false
                if !isDragging {
                    valence = 0
                    position = sliderWidth/2
                }
            }
            .gesture(tapGesture)
            .foregroundColor(.black)
    }
}
