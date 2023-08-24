//
//  JumpRopeView.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI

struct JumpRopeView: View {
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var router: Router
    @State private var viewModel = JumpRopeViewMode()
    
    var body: some View {
        Color.clear
            .overlay {
                if verticalSizeClass == .regular {
                    VStack(spacing: 100) {
                        DataView(count: viewModel.count, time: viewModel.time)
                        StopButtonView {
                            viewModel.stop()
                            router.path.removeLast()
                        }
                    }
                } else {
                    GeometryReader(content: { geometry in
                        HStack {
                            DataView(count: viewModel.count, time: viewModel.time)
                                .frame(width: geometry.size.width * 0.65)
                            Spacer()
                            StopButtonView {
                                viewModel.stop()
                                router.path.removeLast()
                            }
                            .padding(.trailing)
                            Spacer()
                        }
                        .frame(height: geometry.size.height)
                    })
                }
            }
            .padding(.horizontal)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: viewModel.central.connectionStatus) { _, newValue in
                if newValue == .disconnected {
                    router.path = .init()
                }
            }
            .task {
                UIApplication.shared.isIdleTimerDisabled = true
                await viewModel.prepare()
                viewModel.start()
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
}

struct DataView: View {
    
    let count: Int
    let time: Double
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("C")
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                    VStack(alignment: .trailing, spacing: 0) {
                        Label(
                            title: {
                                Text(Duration.seconds(time), format: .time(pattern: .minuteSecond))
                                    .font(.system(size: 24, weight: .semibold))
                                    .contentTransition(.numericText(value: Double(time)))
                                    .animation(.snappy, value: time)
                                    .monospacedDigit()
                            },
                            icon: {
                                Image(systemName: "deskclock")
                                    .bold()
                            }
                        )
                        Text("ount")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .kerning(8)
                    }
                }
            }
            
            Text("\(count)")
                .font(.system(size: 200, weight: .semibold, design: .rounded))
                .contentTransition(.numericText(value: Double(count)))
                .animation(.snappy, value: count)
                .frame(height: 200)
                .foregroundColor(Color.accentColor)
                .minimumScaleFactor(0.5)
                .monospacedDigit()
        }
    }
}

struct StopButtonView: View {
    
    let action: () -> Void
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .containerShape(Circle())
            .frame(width: 100)
            .overlay {
                Text("STOP")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .onTapGesture(perform: action)
    }
}

struct JumpRopeView_Previews: PreviewProvider {
    static var previews: some View {
        JumpRopeView()
    }
}
