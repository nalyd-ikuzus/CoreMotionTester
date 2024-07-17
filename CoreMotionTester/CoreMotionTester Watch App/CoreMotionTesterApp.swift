//
//  CoreMotionTesterApp.swift
//  CoreMotionTester Watch App
//
//  Created by Dylan Suzuki on 5/31/24.
//

import SwiftUI

@main
struct CoreMotionTester_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WorkoutManager())
        }
    }
}
