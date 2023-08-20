//
//  JumpRopeView.swift
//  SkippingRope
//
//  Created by xxx on 2023/8/15.
//

import SwiftUI

struct JumpRopeView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel = JumpRopeViewMode()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        Color.clear
            .overlay {
                GeometryReader { geometry in
                    ZStack {
                        if verticalSizeClass == .regular {
                            Color.clear
                                .overlay {
                                    countView
                                        .offset(y: viewModel.isJumping ? geometry.size.height * -0.1 : 0)
                                        .frame(height: geometry.size.height)
                                        .opacity(viewModel.isJumping ? 1 : 0)
                                }
                            button
                                .offset(y: viewModel.isJumping ? geometry.size.height * 0.25 : 0)
                            
                        } else {
                            Color.clear
                                .overlay {
                                    countView
                                        .offset(x: viewModel.isJumping ? geometry.size.width * -0.14 : 0)
                                        .frame(height: geometry.size.height)
                                        .opacity(viewModel.isJumping ? 1 : 0)
                                }
                            button
                                .offset(x: viewModel.isJumping ? geometry.size.width * 0.25 : 0)
                        }
                    }
                }
                .padding()
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(), value: viewModel.isJumping)
            .onChange(of: viewModel.central.connectionStatus) { newValue in
                if newValue == .disconnected {
                    dismiss()
                }
            }
            .task {
                UIApplication.shared.isIdleTimerDisabled = true
                await viewModel.prepare()
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
    
    private var countView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing) {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("C")
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                    VStack(alignment: .trailing, spacing: 0) {
                        Label(
                            title: {
                                if #available(iOS 17.0, *) {
                                    Text(Duration.seconds(viewModel.time), format: .time(pattern: .minuteSecond))
                                        .font(.system(size: 24, weight: .semibold))
                                        .contentTransition(.numericText(value: Double(viewModel.time)))
                                        .animation(.snappy, value: viewModel.time)
                                        .monospacedDigit()
                                } else {
                                    Text(String(format: "%.f", viewModel.time))
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .monospacedDigit()
                                }
                            },
                            icon: {
                                Image(systemName: "deskclock")
                                    .bold()
                            }
                        )
                        
                        Text("ount")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .kerning(10)
                    }
                }
            }
            
            
            if #available(iOS 17.0, *) {
               
                Text("\(viewModel.count)")
                    .font(.system(size: 200, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(value: Double(viewModel.count)))
                    .animation(.snappy, value: viewModel.count)
                    .frame(height: 200)
                    .foregroundColor(Color.accentColor)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            } else {
                Text("\(viewModel.count)")
                    .font(.system(size: 180, weight: .semibold, design: .rounded))
                    .frame(height: 180)
                    .foregroundColor(Color.accentColor)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            }
        }
        //.border(.cyan)
    }
    
    private var button: some View {
        Circle()
            .fill(viewModel.isJumping ? Color.red : Color.accentColor)
            .containerShape(Circle())
            .frame(width: viewModel.isJumping ? 100 : 180)
            .overlay {
                Text(viewModel.isJumping ? "STOP" : "START")
                    .font(.system(size: viewModel.isJumping ? 24 : 40, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                if viewModel.isJumping {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            }
            //.border(.cyan)
    }
}

struct JumpRopeView_Previews: PreviewProvider {
    static var previews: some View {
        JumpRopeView()
    }
}
