//
//  ContentView.swift
//  SplitTest
//
//  Created by Leonard Mehlig on 26.03.21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            Text("Hello, world!")
                .padding()

            NavigationLink(
                destination: Main(),
                isActive: .constant(true),
                label: {
                    EmptyView()
                })
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct Main: View {
    var body: some View {
        Color.red
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
