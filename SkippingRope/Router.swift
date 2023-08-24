//
//  Router.swift
//  SkippingRope
//
//  Created by 卫 on 2023/8/24.
//

import SwiftUI

final class Router: ObservableObject {
    @Published var path = NavigationPath()
}

enum RouterDestination {
    case ready
    case jump
}
