//
//  WorkoutSessionView.swift
//  CoreMotionTester Watch App
//
//  Created by Dylan Suzuki on 7/2/24.
//

import SwiftUI

struct WorkoutSessionView: View {
    @State private var selection: Tab = .metrics
    
    enum Tab {
        case controls, metrics, nowPlaying
    }
    var body: some View {
        TabView(selection: $selection, content: {
            Text("Controls").tag(Tab.controls)
            Text("Metrics").tag(Tab.metrics)
            Text("Now Playing").tag(Tab.nowPlaying)
        })
    }
}

#Preview {
    WorkoutSessionView()
}
