//
//  SkippingRopeApp.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI
import BlueCentralKit

@main
struct SkippingRopeApp: App {
    
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
            }
            .environmentObject(router)
        }
    }
}

final class Router: ObservableObject {
    @Published var path = NavigationPath()
}
