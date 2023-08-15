//
//  DeviceRowView.swift
//  BlueCentralExample
//
//  Created by iya on 2023/4/1.
//

import SwiftUI
import BlueCentralKit

enum DeviceConnectionStatus {
    case connected
    case connecting
    case disconnected
}

struct DeviceRowView: View {
    
    let deviceDiscovery: DeviceDiscovery
    let connectionState: DeviceConnectionStatus
    let rssi: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: deviceDiscovery.device is SkippingRope ? "figure.jumprope" : "questionmark.app.dashed")
                        .foregroundColor(.accentColor)
                    Text(deviceDiscovery.device.name)
                }
                .font(.system(.title3, weight: .medium))
                VStack(alignment: .leading, spacing: 4) {
                    Text(deviceDiscovery.device.model.productName)
                    Text(deviceDiscovery.device.model.name)
                }
                .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 16) {
                SignalStrengthView(rssi: rssi)
                if connectionState == .connecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.accentColor)
                } else if connectionState == .connected {
                    Text("已连接")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                        .padding(4)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor)
                        }
                }
                Text(deviceDiscovery.device.mac)
                    .font(.footnote)
            }
        }
        .contentShape(Rectangle())
    }
}
