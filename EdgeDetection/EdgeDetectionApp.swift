//
//  EdgeDetectionApp.swift
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

import SwiftUI

@main
struct EdgeDetectionApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView(viewModel: ContentViewModel())
        }
    }
}
