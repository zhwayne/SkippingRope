//
//  ContentView.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI
import Combine
import CoreBluetooth
import BlueCentralKit
import ActivityIndicatorView

@MainActor class ViewModel: ObservableObject {
    
    @Published var central: BlueCentral = .shared
    @Published var discoveries: [DeviceDiscovery] = []
    @Published var connectingDiscovery: DeviceDiscovery?
    
    @Published var error: Error?
    @Published var showErrorDialog = false
    @Published var scanning = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $scanning.eraseToAnyPublisher()
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.scan(newValue)
            }
            .store(in: &cancellables)
        
        central.$cbState.eraseToAnyPublisher()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func connectionState(_ discovery: DeviceDiscovery) -> DeviceConnectionStatus {
        if connectingDiscovery == discovery {
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
            central.scan(deviceModels: [.skippingRopeQ3], throttling: .throttleRSSIDelta(0)) { [weak self] allDeviceDiscoveries in
                self?.discoveries = allDeviceDiscoveries
            } stopped: { [weak self] error in
                if self?.scanning == true {
                    self?.scanning = false
                }
            }
        } else {
            if central.isScanning {
                central.stopScanning()
            }
        }
    }
    
    func connect(to discovery: DeviceDiscovery) async {
        do {
            scanning = false
            // 当前设备为已连接的设备则，直接进入详情页面。否则，先断开连接，再连接新设备。
            if central.connectionStatus == .connecting || connectingDiscovery != nil {
                return
            }
            if let device = central.device, discovery.device.mac == device.mac {
                return
            }
            if central.connectionStatus == .connected {
                try await central.disconnect()
            }
            connectingDiscovery = discovery
            try await central.connect(discovery: discovery)
            connectingDiscovery = nil
        } catch {
            self.error = error
            showErrorDialog = true
            connectingDiscovery = nil
        }
    }
}

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default:
            fatalError()
        }
    }
}


struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    @Environment(\.verticalSizeClass) private var sizeClass

    @EnvironmentObject var router: Router
    
    var body: some View {
        Color.clear
            .overlay {
                let cbState = viewModel.central.cbState
                if cbState == .unknown {
                    WaitingView()
                } else if cbState != .poweredOn {
                    StateView(cbState: cbState)
                } else if viewModel.central.connectionStatus == .connecting {
                    ConnectingView()
                } else if viewModel.discoveries.isEmpty {
                    if viewModel.scanning {
                        ScanningView()
                    } else {
                        let layout = sizeClass == .compact ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
                        layout {
                            ScanButtonView {
                                viewModel.scanning = true
                            }
                        }
                    }
                } else {
                    DeviceListView()
                }
            }
            .environmentObject(viewModel)
            .animation(.default, value: viewModel.discoveries)
            .onChange(of: viewModel.central.cbState, perform: { _ in
                viewModel.discoveries = []
            })
            .onAppear {
                if viewModel.central.connectionStatus == .disconnected {
                    viewModel.scanning = true
                }
            }
    }
}

struct ScanButtonView: View {
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var action: () -> Void
    
    var body: some View {
        Image(systemName: "sparkles.tv")
            .resizable()
            .foregroundStyle(Color.accentColor.opacity(0.8))
            .frame(width: 80, height: 80)
            .padding(.bottom)
        Button(action: action) {
            HStack {
                Spacer()
                Text("Scan for New Devices")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding()
                Spacer()
            }
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .padding(.horizontal)
        .applyIf(verticalSizeClass == .compact) {
            $0.frame(width: 400)
        }
    }
}

struct WaitingView: View {
    var body: some View {
        VStack {
            ActivityIndicatorView(isVisible: .constant(true), type: .flickeringDots(count: 8))
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            Text("Waiting...")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
        }
    }
}

struct StateView: View {
    var cbState: CBManagerState
    var body: some View {
        VStack {
            Text("Bluetooth State")
                .font(.system(size: 24, weight: .medium, design: .rounded))
            Text(cbState.description)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(Color.orange)
        }
    }
}

struct ConnectingView: View {
    var body: some View {
        VStack {
            ActivityIndicatorView(isVisible: .constant(true), type: .flickeringDots(count: 8))
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            Text("Connecting...")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
        }
    }
}

struct ScanningView: View {
    var body: some View {
        VStack {
            ActivityIndicatorView(isVisible: .constant(true), type: .flickeringDots(count: 8))
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            Text("Scanning...")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
        }
    }
}

struct DeviceListView: View {
    
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var router: Router
    
    var body: some View {
        List {
            ForEach(viewModel.discoveries, id: \.self) { discovery in
                let state = viewModel.connectionState(discovery)
                DeviceRowView(deviceDiscovery: discovery, connectionState: state, rssi: discovery.scanDiscovery.rssi)
                    .onTapGesture {
                        Task(priority: .userInitiated) {
                            await viewModel.connect(to: discovery)
                            router.path.append("Jump")
                        }
                    }
            }
        }
        .backgroundStyle(Color.clear)
        .navigationDestination(for: String.self, destination: { _ in
            JumpRopeView()
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
