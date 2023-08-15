//
//  ContentView.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI
import BlueCentralKit
import Foundation
import CoreBluetooth
import ActivityIndicatorView

class ViewModel: ObservableObject {
    
    @Published var discoveries: [DeviceDiscovery] = []
    @Published var connectingDiscovery: DeviceDiscovery?
}

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "PoweredOff"
        case .poweredOn: return "PoweredOn"
        @unknown default:
            fatalError()
        }
    }
}


struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    @State private var error: Error?
    @State private var showErrorDialog = false
    @State private var scanning = false
    @State private var indicatorVisiable = true
    
    @StateObject var central: BlueCentral = .shared
    @EnvironmentObject var router: Router
    
    var body: some View {
        Color.clear
            .overlay {
                if central.cbState != .poweredOn {
                    VStack {
                        Text("Bluetooth State")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                        Text(central.cbState.description)
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.orange)
                    }
                } else {
                    if central.connectionStatus == .connecting {
                        VStack {
                            ActivityIndicatorView(isVisible: $indicatorVisiable, type: .flickeringDots(count: 8))
                                .frame(width: 64, height: 64)
                                .foregroundColor(.accentColor)
                            Text("Connecting...")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                        }
                    } else if viewModel.discoveries.isEmpty {
                        if scanning {
                            VStack {
                                ActivityIndicatorView(isVisible: $indicatorVisiable, type: .flickeringDots(count: 8))
                                    .frame(width: 64, height: 64)
                                    .foregroundColor(.accentColor)
                                Text("Scanning...")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                            }
                        } else {
                            Button("Scan For New Devices") {
                                scanning = true
                            }
                            .font(.system(size: 24, design: .rounded))
                            .buttonStyle(.borderedProminent)
                            .tint(Color.green)
                        }
                    } else {
                        List {
                            ForEach(viewModel.discoveries, id: \.self) { discovery in
                                let state = connectionState(discovery)
                                DeviceRowView(deviceDiscovery: discovery, connectionState: state, rssi: discovery.scanDiscovery.rssi)
                                    .onTapGesture {
                                        Task {
                                            await connect(to: discovery)
                                        }
                                    }
                            }
                        }
                        .backgroundStyle(Color.clear)
                    }
                }
            }
            .animation(.default, value: viewModel.discoveries)
            .onChange(of: scanning) { newValue in
                scan(newValue)
            }
            .onChange(of: central.cbState, perform: { _ in
                viewModel.discoveries = []
            })
            .navigationDestination(for: String.self, destination: { _ in
                JumpRopeView()
            })
            .onAppear {
                if central.connectionStatus == .disconnected {
                    scanning = true
                }
            }
    }
    
    private func connectionState(_ discovery: DeviceDiscovery) -> DeviceConnectionStatus {
        if let connectingDiscovery = viewModel.connectingDiscovery, connectingDiscovery == discovery {
            return .connecting
        }
        if let device = central.device, device.scanDiscovery == discovery.device.scanDiscovery {
            return .connected
        }
        return .disconnected
    }
    
    private func scan(_ startOrEnd: Bool) {
        if startOrEnd {
            if central.isScanning { return }
            central.scan { allDeviceDiscoveries in
                self.viewModel.discoveries = allDeviceDiscoveries.sorted(by: {$0.scanDiscovery.rssi > $1.scanDiscovery.rssi})
            } stopped: { error in
                if scanning == true {
                    scanning = false
                }
            }
        } else {
            if central.isScanning {
                central.stopScanning()
            }
        }
    }
    
    private func connect(to discovery: DeviceDiscovery) async {
        do {
            scanning = false
            // 当前设备为已连接的设备则，直接进入详情页面。否则，先断开连接，再连接新设备。
            if central.connectionStatus == .connecting || viewModel.connectingDiscovery != nil {
                return
            }
            if let device = central.device, discovery.device.mac == device.mac {
                router.path.append("Jump")
                return
            }
            if central.connectionStatus == .connected {
                try await central.disconnect()
            }
            viewModel.connectingDiscovery = discovery
            try await central.connect(discovery: discovery)
            viewModel.connectingDiscovery = nil
            router.path.append("Jump")
        } catch {
            self.error = error
            showErrorDialog = true
            viewModel.connectingDiscovery = nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
