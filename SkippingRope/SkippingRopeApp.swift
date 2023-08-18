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
    
    @StateObject private var router = Router()
    private var healthStore = HKHealthStore()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
            }
            .environmentObject(router)
            .task {
                guard HKHealthStore.isHealthDataAvailable() else {
                    return
                }
                do {
                    try await healthStore.requestAuthorization(toShare: [.workoutType()], read: [HKQuantityType(.bodyMass)])
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
}

final class Router: ObservableObject {
    @Published var path = NavigationPath()
}
