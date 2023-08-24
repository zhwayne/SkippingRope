//
//  SkippingRopeApp.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI
import HealthKit
import BlueCentralKit

@main
struct SkippingRopeApp: App {
    
    @StateObject var router = Router()
    private var healthStore = HKHealthStore()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
            }
            .environmentObject(router)
            .task { await requestAuthorization() }
        }
    }
    
    private func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            let toShare: Set<HKSampleType> = [.workoutType()]
            let read: Set<HKSampleType> = [HKQuantityType(.bodyMass)]
            try await healthStore.requestAuthorization(toShare: toShare, read: read)
        } catch {
            debugPrint(error)
        }
    }
}
