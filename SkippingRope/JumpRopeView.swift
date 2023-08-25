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
    @State private var isJumping = false
    @Namespace private var namespace
    
    private let application = UIApplication.shared
    
    var body: some View {
        
        Color.clear
            .overlay {
                if verticalSizeClass == .regular {
                    buildRegular()
                } else {
                    buildCompact()
                }
            }
            .animation(.snappy(), value: isJumping)
            .padding(.horizontal)
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.prepare() }
            .onAppear { application.isIdleTimerDisabled = true }
            .onDisappear { application.isIdleTimerDisabled = false }
            .onChange(of: viewModel.central.connectionStatus) { _, newValue in
                if newValue == .disconnected {
                    router.path = .init()
                }
            }
    }
    
    @ViewBuilder func buildRegular() -> some View {
        
        let layout = if isJumping {
            AnyLayout(VStackLayout(spacing: 100))
        } else {
            AnyLayout(ZStackLayout())
        }
        
        layout {
            DataView(count: viewModel.count, time: viewModel.time)
                .offset(x: isJumping ? 0 : -200, y: isJumping ? 0 : -100)
                .scaleEffect(x: isJumping ? 1 : 5, y: isJumping ? 1 : 5)
                .blur(radius: isJumping ? 0 : 50)
                .opacity(isJumping ? 1 : 0)
            
            Button {
                Task {
                    isJumping.toggle()
                    if isJumping {
                        await viewModel.start()
                    } else {
                        await viewModel.stop()
                    }
                }
            } label: {
                Circle()
                    .fill(isJumping ? Color.red : Color.accentColor)
                    .containerShape(Circle())
                    .frame(width: isJumping ? 100 : 180)
                    .overlay {
                        Text(isJumping ? "STOP" : "START")
                            .font(.system(size: isJumping ? 24 : 40, weight: .semibold, design: .rounded))
                            .matchedGeometryEffect(id: "Text", in: namespace)
                            .foregroundColor(.white)
                    }
                    .matchedGeometryEffect(id: "Button", in: namespace)
                    .animation(.snappy, value: isJumping)
            }
        }
    }
    
    @ViewBuilder func buildCompact() -> some View {
        GeometryReader(content: { geometry in
            let layout = if isJumping {
                AnyLayout(HStackLayout(spacing: 40))
            } else {
                AnyLayout(ZStackLayout())
            }
            layout {
                DataView(count: viewModel.count, time: viewModel.time)
                    .frame(width: geometry.size.width * 0.65)
                    .offset(x: isJumping ? 0 : -100, y: isJumping ? 0 : -200)
                    .scaleEffect(x: isJumping ? 1 : 5, y: isJumping ? 1 : 5)
                    .blur(radius: isJumping ? 0 : 50)
                    .opacity(isJumping ? 1 : 0)
                    .offset(x: -20)
                Button {
                    Task {
                        isJumping.toggle()
                        if isJumping {
                            await viewModel.start()
                        } else {
                            await viewModel.stop()
                        }
                    }
                } label: {
                    Circle()
                        .fill(isJumping ? Color.red : Color.accentColor)
                        .containerShape(Circle())
                        .frame(width: isJumping ? 100 : 180)
                        .overlay {
                            Text(isJumping ? "STOP" : "START")
                                .font(.system(size: isJumping ? 24 : 40, weight: .semibold, design: .rounded))
                                .matchedGeometryEffect(id: "Text", in: namespace)
                                .foregroundColor(.white)
                        }
                        .matchedGeometryEffect(id: "Button", in: namespace)
                        .animation(.snappy, value: isJumping)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
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

#Preview {
    JumpRopeView()
}
