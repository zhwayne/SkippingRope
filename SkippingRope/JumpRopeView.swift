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
    
    func start() async throws {
        if let skippingRope {
            try await skippingRope.setSystemType(.none)
            try await skippingRope.setMode(.freedom)
            try await skippingRope.training(.start)
            
            dataUpdateCancellable = skippingRope.dataUpadte.sink(receiveValue: { [weak self] trainingData in
                self?.count = Int(trainingData.count)
            })
        }
    }
}

struct JumpRopeView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel = JumpRopeViewMode()
    
    var body: some View {
        Color.clear
            .overlay {
                if !viewModel.isJumping {
                    
                    Button {
                        
                        Task {
                            do {
                                try await viewModel.start()
                                viewModel.isJumping = true
                            } catch {
                                viewModel.isJumping = false
                            }
                        }
                        
                    } label: {
                        Circle().fill(Color.accentColor)
                            .frame(width: 150)
                            .overlay {
                                Text("START")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                    }
                    
                } else {
                    VStack {
                        HStack(spacing: 0) {
                            Text("C")
                            Text("ount")
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        Text("\(viewModel.count)")
                            .contentTransition(.numericText(countsDown: true))
                            .font(.system(size: 150, weight: .semibold, design: .rounded))
                            .animation(.linear, value: viewModel.count)
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: viewModel.central.connectionStatus) { newValue in
                if newValue == .disconnected {
                    dismiss()
                }
            }
    }
}

struct JumpRopeView_Previews: PreviewProvider {
    static var previews: some View {
        JumpRopeView()
    }
}
