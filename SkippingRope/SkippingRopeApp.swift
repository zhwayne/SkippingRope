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
            .environment(\.healthStore, healthStore)
            .task {
                guard HKHealthStore.isHealthDataAvailable() else {
                    return
                }
                if healthStore.authorizationStatus(for: .workoutType()) == .notDetermined {
                    do {
                        try await healthStore.requestAuthorization(toShare: [.workoutType()], read: [.workoutType()])
                    } catch {
                        debugPrint(error)
                    }
                }
            }
        }
    }
}

extension EnvironmentValues {
    
    private struct HealthStoreKey: EnvironmentKey {
        static let defaultValue: HKHealthStore = HKHealthStore()
    }
    
    var healthStore: HKHealthStore {
        get { self[HealthStoreKey.self] }
        set { self[HealthStoreKey.self] = newValue }
    }
}

final class Router: ObservableObject {
    @Published var path = NavigationPath()
}
