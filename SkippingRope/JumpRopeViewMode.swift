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

@MainActor
class JumpRopeViewMode: ObservableObject {
    
    let central: BlueCentral = .shared
    
    private var skippingRope: SkippingRope? { central.device as? SkippingRope }
    private var healthStore = HKHealthStore()
    
    @Published var isJumping = false
    @Published var count = 0
    @Published var time: Double = 0
    @Published var weight: Double = 0
    @Published var kilocalorie: Double = 0
    
    private var startDate = Date()
    private var endDate = Date()
    
    private var timerCancellable: AnyCancellable?
    private var timeoutTask: DispatchWorkItem?
    
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
                
                if let weight = self?.weight, let time = self?.time, let startDate = self?.startDate {
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
            dataUpdateCancellable?.cancel()
            dataUpdateCancellable = nil
            timerCancellable?.cancel()
            timerCancellable = nil
            count = 0
            
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
    
    private func resetTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                self?.time += 0.1
            })
    }
}
