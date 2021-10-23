//
//  ContentView.swift
//  PostHogExample
//
//  Created by Leonard Mehlig on 20.03.21.
//

import SwiftUI
import PostHog

struct ContentView: View {
    @EnvironmentObject var tracker: Tracker

    var body: some View {
        ForEach(Array(tracker.featureFlags), id: \.key) {
            Text("\($0.key): \($0.value.description)")
        }
        Button("Send Event") {
            tracker.capture(event: Event("Click"))
        }
        .padding()
        .onAppear {
            tracker.screen(name: "test")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
