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
    
    //Circle variables
    @State var circleActive: Bool = false //toggle this to enable or disable the circle
    var mainCircle: Circle = Circle()
    @State var circleX: CGFloat = 0
    @State var circleY: CGFloat = 0
    var motionManager: CMMotionManager = CMMotionManager()
    
    //Clapping variables
    @State var clapped: Bool = false
    @State var clapReset = 2.0
    @State var ignoreNext: Bool = false
    
    //Arm Swinging variables
    @State var swingThreshhold: Bool = false
    
    //Arm Position variables
    enum armPositionType {
        case up, sideways, down, unknown
    }
    @State var averageBuffer: [Double] //This variable will hold the values to average
    @State var rollingAverage: Double = 0.0 //This variable will hold the actual average
    @State var bufferIndex: Int = 0 //This variable will indicate the oldest data point, and therefore the next one to replace
    @State var bufferSize: Int = 25 //This variable determines the size of the rolling average - higher means smoother but adds more latency
    @State var bufferCount: Int = 0 //This variable represents the effective size of the array (how many values are actually significant) and will allow us to get an accurate average before the buffer is entirely filled
    @State var lastPosition: armPositionType = .unknown //This variable will allow us to implement hysteresis by only sending "new" events when the armPosition changes
    
    @State var currentXAccel: Double = 0.0
    @State var peakXAccel: Double = 0.0
    
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                VStack{
                    Spacer()
                    Text("X: \(String(format: "%.2f", currentXAccel))")
                        .font(.title2)
                    Text("Avg: \(String(format: "%.2f", rollingAverage))")
                        .font(.title2)
                    Button{peakXAccel = 0.0} label: {Text("Peak: \(String(format: "%.2f", peakXAccel))").font(.title2)}
                    Text("Pos: \(lastPosition)")
                        .font(.title2)
                    Spacer()
                }
                if(circleActive){
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
            }
            .onChange(of: lastPosition) { oldValue, newValue in
                print("Arm Position: \(newValue)")
            }
            .sensoryFeedback(.increase, trigger: lastPosition)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .navigationTitle("CoreMotion Tester")
            .onAppear(perform: {
                circleX = (geometry.size.width / 2)
                circleY = (geometry.size.height / 2)
                
                if (!workoutManager.running){
                    workoutManager.startWorkout(workoutType: .cardioDance)
                }
                //Initialize motionManager
                averageBuffer = [Double](repeating: 0.0, count: bufferSize)
                if (motionManager.isAccelerometerAvailable){
                    motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                        guard error == nil else { return }
                        guard let accelerometerData = data else { return }
                        
                        //MARK: circle movement code
                        circleX = max(min(circleX + accelerometerData.acceleration.x, geometry.size.width), 0)
                        circleY = max(min(circleY - accelerometerData.acceleration.y, geometry.size.height), 0)
                        
                        //print(accelerometerData.acceleration)
                        currentXAccel = accelerometerData.acceleration.x
                        peakXAccel = max(abs(currentXAccel), abs(peakXAccel))
                            //Add reset button
                            //Look for coreMotion interrupts
                            //Make this an easter egg screen in the enlighted app
                        
                        //MARK: Arm Position detection code
                            //updating the rolling average
                        averageBuffer[bufferIndex] = accelerometerData.acceleration.x
                        bufferIndex = (bufferIndex + 1) % bufferSize //Updating the circular index
                        if (bufferCount < bufferSize){ //Ensuring the effective count is still accurate
                            bufferCount += 1
                        }
                            //Averaging the array
                        rollingAverage = averageBuffer.reduce(0.0, {x, y in
                            x + y
                        }) / Double(bufferCount)
                            //Sensing position
                        if(rollingAverage < 1.0 && rollingAverage > 0.75){
                            lastPosition = .up
                        } else if(rollingAverage < 0.4 && rollingAverage > -0.4){
                            lastPosition = .sideways
                        } else if(rollingAverage < -0.75 && rollingAverage > -1.0){
                            lastPosition = .down
                        }
                        
                        //print("x: \(rollingAverage)")
                        
                        //MARK: Arm Swing detection code
                        //print("X: \(accelerometerData.acceleration.x)")
                        if (abs(accelerometerData.acceleration.x) > 3.0 && !swingThreshhold){
                            print("Arm Swing gesture detected")
                            swingThreshhold = true
                        } else if (abs(accelerometerData.acceleration.x) < 0.5 && swingThreshhold){
                            print("Arm Swing reset")
                            swingThreshhold = false
                        }
                        
                        //MARK: Clap Detection Code
                        //print("Z: \(accelerometerData.acceleration.z)")
                        if (accelerometerData.acceleration.z < -5.0 && abs(accelerometerData.acceleration.y) < 5){
                            if (!clapped && !ignoreNext){
                                print("detected clap gesture")
                                clapped = true
                                ignoreNext = true
                            } else if (!ignoreNext){
                                print("double clap gesture")
                                clapped = false
                                clapReset = 2.0
                                ignoreNext = true
                            } else {
                                print("Ignoring false positive clap gesture")
                                //ignoreNext = false
                            }
                        } else {
                            ignoreNext = false
                        }
                        if (clapped && (clapReset >= 0.0)){
                            clapReset = clapReset - motionManager.accelerometerUpdateInterval
                        } else if (clapped){
                            clapped = false
                            clapReset = 2.0
                            print("reset clap gesture")
                        }
                    }
                } else {
                    print("accelerometer unavailable")
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
    MotionCircleView( averageBuffer: [Double]())
}
