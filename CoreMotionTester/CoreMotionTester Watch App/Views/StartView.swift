//
//  StartView.swift
//  CoreMotionTester Watch App
//
//  Created by Dylan Suzuki on 7/2/24.
//

import SwiftUI
import HealthKit

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    NavigationLink("Start", destination: MotionCircleView())
                }
            }
        }.navigationTitle("Start Page")
            .onAppear(perform: {
                workoutManager.requestAuth()
            })
    }
}

#Preview {
    StartView()
}
