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
    private var healthStore = HKHealthStore()
    
    @Published var isJumping = false
    @Published var count = 0
    @Published var weight: Double = 0
    @Published var calorie: Double = 0
    
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
                if let weight = self?.weight, let count = self?.count/*, let startDate = self?.startDate*/ {
                    // 方案一：
                    // 假设以一位体重60千克的人以正常跳绳速度（MET=11.8）来计算，
                    // 套公式：每分钟燃烧的千卡路里=（ MET x 体重（千克）x 3.5）÷200，一小时（60分钟）
                    // 消耗的热量就是（11.8 x 60 x 3.5）÷200 x 60=743.4千卡路里。
                    // self?.calorie = 11.8 * weight * 3.5 / 200 * (Date().timeIntervalSince(startDate) / 60)
                    //
                    // 方案二：
                    // 跳绳消耗的千卡路里 ≈ （跳绳次数 × 体重（公斤） × 跳绳系数） ÷ 1000
                    //
                    // 其中，跳绳系数是一个与跳绳强度和技巧有关的常数，通常在0.1到0.3之间。这个常数可以根据您的跳绳
                    // 水平进行调整，一般来说，跳绳技巧越高，常数越接近0.3。
                    self?.calorie = (Double(count) * weight * 0.2) / 1000
                }
            })
        }
    }
    
    func stop() {
        Task(priority: .userInitiated) {
            endDate = Date()
            isJumping = false
            let _ = try? await skippingRope?.training(.stop)
            dataUpdateCancellable = nil
            count = 0
            
            let duration = endDate.timeIntervalSince(startDate)
            let metadata: [String: Any] = [HKMetadataKeyIndoorWorkout: true]
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calorie)
            
            let workout = HKWorkout(activityType: .jumpRope, start: startDate, end: endDate, workoutEvents: nil, totalEnergyBurned: calorieQuantity, totalDistance: nil, metadata: metadata)
            do {
                try await healthStore.save([workout])
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func prepare() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: HKQuantityType(.bodyMass), predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            if let samples = samples as? [HKDiscreteQuantitySample],
               let quantity = samples.last?.mostRecentQuantity {
                DispatchQueue.main.sync {
                    self?.weight = quantity.doubleValue(for: .gramUnit(with: .kilo))
                }
            }
        }
        healthStore.execute(query)
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
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(), value: viewModel.isJumping)
            .onChange(of: viewModel.central.connectionStatus) { newValue in
                if newValue == .disconnected {
                    dismiss()
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                viewModel.prepare()
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
                Text(String(format: "%.2fCal", viewModel.calorie))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(value: Double(viewModel.calorie)))
                    .animation(.snappy, value: viewModel.calorie)
                    .monospacedDigit()
                Text("\(viewModel.count)")
                    .font(.system(size: 200, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(value: Double(viewModel.count)))
                    .animation(.snappy, value: viewModel.count)
                    .frame(height: 200)
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
                    viewModel.stop()
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
