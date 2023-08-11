//
//  VAGrid.swift
//  TestView Watch App
//
//  Created by Edward Ng on 8/7/23.
//

import Foundation
import SwiftUI

struct VAGrid : View {
    @Binding var location : CGPoint
    @Binding var reset : Bool
    
    @State var nLocation : CGPoint = CGPoint(x:0, y:0)
    @State var pointWasChosen : Bool = false
    @State var geometry : GeometryProxy?
    
    var tapGesture : some Gesture {
        SpatialTapGesture()
            .onEnded {event in
                var newLocation = event.location
                let width = geometry!.size.width/2
                nLocation = CGPoint(x: event.location.x - width, y: event.location.y - width)
                
                // Translating + Reflection
                newLocation.x -= width
                newLocation.y -= width
                newLocation.y *= -1
                
                // Normalizing values
                newLocation.x /= width
                newLocation.y /= width
                // Getting proper precision
                newLocation.x = (newLocation.x * 1000).rounded() / 1000
                newLocation.y = (newLocation.y * 1000).rounded() / 1000
                
                if newLocation.x < -1 || newLocation.x > 1 || newLocation.y > 1 || newLocation.y < -1 {
                    return
                }
                
                location = newLocation
                print(location)
            }
    }
    
    var dragGesture : some Gesture {
        DragGesture()
            .onChanged() { event in
                let width = geometry!.size.width/2
                nLocation = CGPoint(x: event.location.x - width, y: event.location.y - width)
                if nLocation.x > width {
                    nLocation.x = width
                } else if nLocation.x < -width {
                    nLocation.x = -width
                }
                
                if nLocation.y > width {
                    nLocation.y = width
                } else if nLocation.y < -width{
                    nLocation.y = -width
                }
            }
    }
    
    var body : some View {
        GeometryReader { geometry in
            ZStack {
                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach((0..<4)){_ in
                        GridRow() {
                            Rectangle()
                            Rectangle()
                            Rectangle()
                            Rectangle()
                        }
                    }
                }
                    .gesture(tapGesture)
                    .gesture(dragGesture)
                Circle()
                    .position(x: nLocation.x, y: nLocation.y)
                    .frame(width: 5, height: 5)
                    .foregroundColor(Color.black)
                Text("High Arousal")
                    .foregroundColor(.black)
                    .offset(x: geometry.size.width * 0.24, y:geometry.size.height * -0.45)
                    .font(.system(size: 12))
                Text("Low Arousal")
                    .foregroundColor(.black)
                    .offset(x: geometry.size.width * 0.24, y:geometry.size.height * 0.45)
                    .font(.system(size: 12))
                Text("Positive")
                    .foregroundColor(.black)
                    .offset(x: geometry.size.width * 0.33, y:geometry.size.height * 0.05)
                    .font(.system(size: 12))
                Text("Negative")
                    .foregroundColor(.black)
                    .offset(x: geometry.size.width * -0.33, y:geometry.size.height * 0.05)
                    .font(.system(size: 12))
            }
            .onAppear(perform: {
                self.geometry = geometry
            })
            .onChange(of: reset) {_ in
                reset = false
                nLocation.x = 0
                nLocation.y = 0
            }
            .background(Color.mint)
        }
    }
}
