//
//  JumpRopeViewMode.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/19.
//

import SwiftUI
import BlueCentralKit
import Foundation
import CoreBluetooth
import Combine
import HealthKit
import Observation

@Observable
@MainActor
class JumpRopeViewMode {
    
    var isJumping = false
    var count = 0
    var time: Double = 0
    var weight: Double = 65 // 体重默认 65kg
    var kilocalorie: Double = 0
    
    private var skippingRope: SkippingRope? { central.device as? SkippingRope }
    @ObservationIgnored private(set) var central: BlueCentral = .shared
    @ObservationIgnored private var healthStore = HKHealthStore()
    @ObservationIgnored private var startDate = Date()
    @ObservationIgnored private var endDate = Date()
    @ObservationIgnored private var timerCancellable: AnyCancellable?
    @ObservationIgnored private var timeoutTask: DispatchWorkItem?
    @ObservationIgnored private var dataUpdateCancellable: AnyCancellable?
    @ObservationIgnored private var workoutEvents = [HKWorkoutEvent]()
    
    func start() {
        Task(priority: .userInitiated) {
            workoutEvents = []
            isJumping = true
            startDate = Date()
            let _ = try? await skippingRope?.training(.start)
            let _ = try? await skippingRope?.training(.startConfirm)
                        
            dataUpdateCancellable = skippingRope?.dataUpadte.sink(receiveValue: { [weak self] trainingData in
                self?.count = Int(trainingData.count)
                
                if self?.timerCancellable == nil {
                    self?.resetTimer()
                }
                self?.timeoutTask?.cancel()
                self?.timeoutTask = DispatchWorkItem {
                    self?.timerCancellable?.cancel()
                    self?.timerCancellable = nil
                }
                if let item = self?.timeoutTask {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: item)
                }
                
                if let weight = self?.weight, let time = self?.time {
                    // 假设以一位体重60千克的人以正常跳绳速度（MET=11.8）来计算，
                    // 套公式：每分钟燃烧的千卡路里=（ MET x 体重（千克）x 3.5）÷200，一小时（60分钟）
                    // 消耗的热量就是（11.8 x 60 x 3.5）÷200 x 60 = 743.4千卡路里。
                    self?.kilocalorie = 11.8 * weight * 3.5 / 200 * (time / 60)
                }
            })
        }
    }
    
    func stop() {
        Task(priority: .userInitiated) {
            endDate = Date()
            isJumping = false
            let _ = try? await skippingRope?.training(.stop)
            
            defer {
                dataUpdateCancellable?.cancel()
                dataUpdateCancellable = nil
                timerCancellable?.cancel()
                timerCancellable = nil
                time = 0
                count = 0
                kilocalorie = 0
                workoutEvents = []
            }
            
            // 只保留 1分钟以上的数据
            guard time > 60 else { return }
            
            let metadata: [String: Any] = [HKMetadataKeyIndoorWorkout: true]
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: kilocalorie)
            
            let workout = HKWorkout(
                activityType: .jumpRope,
                start: startDate,
                end: endDate,
                duration: time,
                totalEnergyBurned: calorieQuantity,
                totalDistance: nil,
                metadata: metadata
            )
            do {
                try await healthStore.save([workout])
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func prepare() async {
        // 设置跳绳
        let _ = try? await skippingRope?.setMode(.freedom)
        let _ = try? await skippingRope?.setSystemType(.ylcmd)
        
        // 查询最新的体重
        healthStore.execute(
            HKSampleQuery(
                sampleType: HKQuantityType(.bodyMass),
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { [weak self] _, samples, _ in
                if let samples = samples as? [HKDiscreteQuantitySample],
                   let quantity = samples.last?.mostRecentQuantity {
                    DispatchQueue.main.sync {
                        self?.weight = quantity.doubleValue(for: .gramUnit(with: .kilo))
                    }
                }
            }
        )
    }
    
    private func resetTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                self?.time += 0.1
            })
    }
}
