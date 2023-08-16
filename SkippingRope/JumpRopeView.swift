//
//  JumpRopeView.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI
import BlueCentralKit
import Foundation
import CoreBluetooth
import Combine

@MainActor
class JumpRopeViewMode: ObservableObject {
    
    let central: BlueCentral = .shared
    
    private var skippingRope: SkippingRope? { central.device as? SkippingRope }
    
    @Published var isJumping = false
    @Published var count = 0
    
    private var dataUpdateCancellable: AnyCancellable?
    
    func start() {
        Task {
            do {
                isJumping = true
                try await skippingRope?.setSystemType(.ylcmd)
                try await skippingRope?.setMode(.freedom)
                try await skippingRope?.training(.start)
                
                dataUpdateCancellable = skippingRope?.dataUpadte.sink(receiveValue: { [weak self] trainingData in
                    self?.count = Int(trainingData.count)
                })
            } catch { }
        }
    }
    
    func stop() {
        Task {
            do {
                isJumping = false
                try await skippingRope?.training(.stop)
                dataUpdateCancellable = nil
                count = 0
            } catch { }
        }
    }
}

struct JumpRopeView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel = JumpRopeViewMode()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        Color.clear
            .overlay {
                GeometryReader { geometry in
                    ZStack {
                        if verticalSizeClass == .regular {
                            Color.clear
                                .overlay {
                                    countView
                                        .offset(y: viewModel.isJumping ? geometry.size.height * -0.175 : 0)
                                        .frame(height: geometry.size.height)
                                        .opacity(viewModel.isJumping ? 1 : 0)
                                }
                            button
                                .offset(y: viewModel.isJumping ? geometry.size.height * 0.215 : 0)
                            
                        } else {
                            Color.clear
                                .overlay {
                                    countView
                                        .offset(x: viewModel.isJumping ? geometry.size.width * -0.2 : 0, y: 20)
                                        .frame(height: geometry.size.height)
                                        .frame(maxWidth: geometry.size.width * 0.5)
                                        .opacity(viewModel.isJumping ? 1 : 0)
                                }
                            button
                                .offset(x: viewModel.isJumping ? geometry.size.width * 0.25 : 0)
                        }
                    }
                }
                
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(), value: viewModel.isJumping)
            .onChange(of: viewModel.central.connectionStatus) { newValue in
                if newValue == .disconnected {
                    dismiss()
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
    
    private var countView: some View {
        VStack {
            HStack(spacing: 0) {
                Text("C")
                Text("ount")
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .font(.system(size: 56, weight: .semibold, design: .rounded))
            
            Text("\(viewModel.count)")
                .contentTransition(.numericText(countsDown: true))
                .font(.system(size: 200, weight: .semibold, design: .rounded))
                .animation(.linear, value: viewModel.count)
                .foregroundColor(Color.accentColor)
                .minimumScaleFactor(0.5)
        }
    }
    
    private var button: some View {
        Circle()
            .fill(viewModel.isJumping ? Color.red : Color.accentColor)
            .containerShape(.circle)
            .frame(width: viewModel.isJumping ? 120 : 200)
            .overlay {
                Text(viewModel.isJumping ? "STOP" : "START")
                    .font(.system(size: viewModel.isJumping ? 32 : 48, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                if viewModel.isJumping {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            }
    }
}

struct JumpRopeView_Previews: PreviewProvider {
    static var previews: some View {
        JumpRopeView()
    }
}
