//
//  SignalStrengthView.swift
//  BlueCentralExample
//
//  Created by iya on 2023/3/31.
//

import SwiftUI

struct SignalStrengthView: View {
    // 信号强度，介于-127到0之间
    var rssi: Int
    
    let signalBarCount = 4
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Color.clear
                .background {
                    GeometryReader { geometry in
                        let size  = geometry.frame(in: .global)
                        let spacing = size.width / CGFloat(signalBarCount * 2) / 1.5
                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(0..<signalBarCount, id: \.self) { idx in
                                 Capsule(style: .continuous)
                                    .fill(color(at: idx))
                                    .frame(height: size.height * CGFloat(idx + 1) / CGFloat(signalBarCount))
                            }
                        }
                        .animation(.default, value: rssi)
                    }
                }
                .frame(width: 24, height: 20)
        }
    }
    
    private func color(at index: Int) -> Color {
        let strengthPerSegment = normalizedRssi * Double(signalBarCount)
        let filledSegments = Int(strengthPerSegment * Double(signalBarCount)) + 1
        
        if index < filledSegments {
            if normalizedRssi < 0.083 {
                return Color(uiColor: .systemRed)
            } else if normalizedRssi < 0.167 {
                return Color(uiColor: .systemOrange)
            } else {
                return Color(uiColor: .systemGreen)
            }
        } else {
            return Color(uiColor: .systemFill)
        }
    }
    
    private var normalizedRssi: Double {
        let min_dbm: Double = -90
        let max_dbm: Double = 30
        return (Double(rssi) - min_dbm) / (max_dbm - min_dbm)
    }
}



struct SignalStrengthView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(1...10, id: \.self) { idx in
                SignalStrengthView(rssi: -89)
            }
        }
//            .border(.black)
    }
}

