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
import HealthKit

@MainActor
class JumpRopeViewMode: ObservableObject {
    
    let central: BlueCentral = .shared
    
    private var skippingRope: SkippingRope? { central.device as? SkippingRope }
    
    @Published var isJumping = false
    @Published var count = 0
    
    private var startDate = Date()
    private var endDate = Date()
    
    private var dataUpdateCancellable: AnyCancellable?
    
    func start() {
        Task(priority: .userInitiated) {
            isJumping = true
            startDate = Date()
            let _ = try? await skippingRope?.setSystemType(.ylcmd)
            let _ = try? await skippingRope?.setMode(.freedom)
            let _ = try? await skippingRope?.training(.start)
            dataUpdateCancellable = skippingRope?.dataUpadte.sink(receiveValue: { [weak self] trainingData in
                self?.count = Int(trainingData.count)
            })
        }
    }
    
    func stop(healthStore: HKHealthStore) {
        Task(priority: .userInitiated) {
            endDate = Date()
            isJumping = false
            let _ = try? await skippingRope?.training(.stop)
            dataUpdateCancellable = nil
            count = 0
            
            // 假设以一位体重60千克的人以正常跳绳速度（MET=11.8）来计算，
            // 套公式：每分钟燃烧的千卡路里=（ MET x 体重（千克）x 3.5）÷200，一小时（60分钟）
            // 消耗的热量就是（11.8 x 60 x 3.5）÷200 x 60=743.4千卡路里。
            let duration = endDate.timeIntervalSince(startDate)
            let kilocalorie = 11.8 * 65 * 3.5 / 200 * (duration / 60)
            let metadata: [String: Any] = [HKMetadataKeyIndoorWorkout: true]
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: kilocalorie)
            
            let workout = HKWorkout(activityType: .jumpRope, start: startDate, end: endDate, workoutEvents: nil, totalEnergyBurned: calorieQuantity, totalDistance: nil, metadata: metadata)
            do {
                try await healthStore.save([workout])
            } catch {
                debugPrint(error)
            }
        }
    }
}

struct JumpRopeView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel = JumpRopeViewMode()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.healthStore) private var healthStore
    
    var body: some View {
        Color.clear
            .overlay {
                GeometryReader { geometry in
                    ZStack {
                        if verticalSizeClass == .regular {
                            Color.clear
                                .overlay {
                                    countView
                                        .offset(y: viewModel.isJumping ? geometry.size.height * -0.1 : 0)
                                        .frame(height: geometry.size.height)
                                        .opacity(viewModel.isJumping ? 1 : 0)
                                }
                            button
                                .offset(y: viewModel.isJumping ? geometry.size.height * 0.33 : 0)
                            
                        } else {
                            Color.clear
                                .overlay {
                                    countView
                                        .offset(x: viewModel.isJumping ? geometry.size.width * -0.14 : 0)
                                        .frame(height: geometry.size.height)
                                        .opacity(viewModel.isJumping ? 1 : 0)
                                }
                            button
                                .offset(x: viewModel.isJumping ? geometry.size.width * 0.25 : 0)
                        }
                    }
                }
                .padding()
            }
            .applyIf(verticalSizeClass == .compact) {
                $0.ignoresSafeArea()
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
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("C")
                Text("ount")
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .font(.system(size: 56, weight: .semibold, design: .rounded))
            
            if #available(iOS 17.0, *) {
                Text("\(viewModel.count)")
                    .contentTransition(.numericText(value: Double(viewModel.count)))
                    .font(.system(size: 200, weight: .semibold, design: .rounded))
                    .frame(height: 200)
                    .animation(.snappy, value: viewModel.count)
                    .foregroundColor(Color.accentColor)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            } else {
                Text("\(viewModel.count)")
                    .font(.system(size: 200, weight: .semibold, design: .rounded))
                    .frame(height: 200)
                    .foregroundColor(Color.accentColor)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            }
        }
        //.border(.cyan)
    }
    
    private var button: some View {
        Circle()
            .fill(viewModel.isJumping ? Color.red : Color.accentColor)
            .containerShape(Circle())
            .frame(width: viewModel.isJumping ? 100 : 180)
            .overlay {
                Text(viewModel.isJumping ? "STOP" : "START")
                    .font(.system(size: viewModel.isJumping ? 24 : 40, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                if viewModel.isJumping {
                    viewModel.stop(healthStore: healthStore)
                } else {
                    viewModel.start()
                }
            }
            //.border(.cyan)
    }
}

struct JumpRopeView_Previews: PreviewProvider {
    static var previews: some View {
        JumpRopeView()
    }
}
