//
//  ContentView.swift
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var viewModel: ContentViewModel

  var body: some View {
    VStack {
      Picker("", selection: $viewModel.selectedFilter) {
        ForEach(viewModel.availableFilters, id: \.self) {
          Text($0.rawValue)
            .tag($0)
        }
      }

      switch viewModel.state {
      case .idle:
        Spacer()
      case .processing:
        Spacer()
        ProgressView()
        Spacer()
      case let .result(filteringResult):
        Spacer()
        VStack(spacing: 16) {
          Image(uiImage: UIImage(cgImage: viewModel.sourceImage))
            .resizable()
            .aspectRatio(contentMode: .fit)

          Text("Time: \(filteringResult.time)")

          Image(uiImage: UIImage(cgImage: filteringResult.image))
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
        Spacer()
      }
    }
    .padding()
  }
}
