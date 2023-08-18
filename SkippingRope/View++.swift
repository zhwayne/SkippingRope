//
//  View++.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/16.
//

import SwiftUI

extension View {
    
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, @ViewBuilder apply: (Self) -> T) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
}
