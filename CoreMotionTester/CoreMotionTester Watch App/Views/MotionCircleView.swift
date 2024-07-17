//
//  MotionCircleView.swift
//  CoreMotionTester Watch App
//
//  Created by Dylan Suzuki on 6/25/24.
//

import SwiftUI
import CoreMotion

struct MotionCircleView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    
    var mainCircle: Circle = Circle()
    @State var circleX: CGFloat = 0
    @State var circleY: CGFloat = 0
    var motionManager: CMMotionManager = CMMotionManager()
    @State var clapped: Bool = false
    @State var clapReset = 2.0
    @State var ignoreNext: Bool = false
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                //WorkoutMetricsView()
                VStack{ //VStack and HStack so that 0, 0 defaults to the top right
                    HStack{
                        mainCircle
                            .fill(.purple)
                            .frame(width: 25, height: 25)
                            .position(x: circleX, y: circleY)
                    Spacer()
                    }
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .navigationTitle("CoreMotion Tester")
            .onAppear(perform: {
                circleX = (geometry.size.width / 2)
                circleY = (geometry.size.height / 2)
                
//                if (!workoutManager.running){
//                    workoutManager.startWorkout(workoutType: .cardioDance)
//                }
                
                motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                    guard error == nil else { return }
                    guard let accelerometerData = data else { return }
                    
                    circleX = max(min(circleX + accelerometerData.acceleration.x, geometry.size.width), 0)
                    circleY = max(min(circleY - accelerometerData.acceleration.y, geometry.size.height), 0)
                    
                    print("Z: \(accelerometerData.acceleration.z)")
                    if (accelerometerData.acceleration.z < -5.0){
                        if (!clapped && !ignoreNext){
                            print("detected clap")
                            clapped = true
                            ignoreNext = true
                        } else if (!ignoreNext){
                            print("double clap")
                            clapped = false
                            clapReset = 2.0
                            ignoreNext = true
                        } else {
                            print("Ignoring false positive clap")
                            ignoreNext = false
                        }
                    } else {
                        ignoreNext = false
                    }
                    if (clapped && (clapReset >= 0.0)){
                        clapReset = clapReset - motionManager.accelerometerUpdateInterval
                    } else if (clapped){
                        clapped = false
                        clapReset = 2.0
                        print("reset clap")
                    }
                }
            })
        }.ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar { //Custom back button so that we can stop the workout on disconnect
            ToolbarItem(placement: .topBarLeading, content: {
                Button{
                    if (workoutManager.running){
                        workoutManager.endWorkout()
                        workoutManager.showingSummaryView = false
                    }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            })
        }
    }
}

#Preview {
    MotionCircleView()
}
