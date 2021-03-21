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
