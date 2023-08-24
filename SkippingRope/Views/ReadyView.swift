//
//  ReadyView.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/23.
//

import SwiftUI

struct ReadyView: View {
    
    @EnvironmentObject  var router: Router
    
    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .containerShape(Circle())
            .frame(width: 180)
            .overlay {
                Text("START")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                router.path.append(RouterDestination.jump)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
}

struct ReadyView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyView()
    }
}
