//
//  ContentViewModel.swift
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

import Combine
import UIKit

final class ContentViewModel: ObservableObject {
  enum State {
    case idle
    case processing
    case result(EdgeDetectionResult)
  }

  @Published private(set) var state: State = .idle
  @Published var selectedFilter: EdgeDetectionFilterType = .sobel

  let availableFilters: [EdgeDetectionFilterType] = EdgeDetectionFilterType.allCases
  private var cancellables: Set<AnyCancellable> = []

  var sourceImage: CGImage {
    let imageURL = Bundle.main.url(forResource: "image", withExtension: ".png")!
    let image = UIImage(data: try! Data(contentsOf: imageURL))!.cgImage!
    return image
  }


  init() {
    observeSelectedFilterChanges()
  }

  private func observeSelectedFilterChanges() {
    $selectedFilter
      .sink { [weak self] newValue in
        self?.state = .processing
        self?.processFilter(type: newValue)
      }
      .store(in: &cancellables)
  }

  private func processFilter(type: EdgeDetectionFilterType) {
    do {
      let filter = try EdgeDetectionFilter(type: type, device: Renderer.systemDefaultDevice)
      Task {
        guard let result = try await filter.filter(sourceImage) else { return }
        await updateState(with: result)
      }
    } catch {
      print(error)
    }
  }

  @MainActor
  private func updateState(with result: EdgeDetectionResult) {
    state = .result(result)
  }
}
