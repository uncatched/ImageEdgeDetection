//
//  EdgeDetectionError.swift
//  EdgeDetection
//
//  Created by Denys Litvinskyi on 13.01.2023.
//

import Foundation

enum EdgeDetectionError: LocalizedError {
  case failedToLoadLibrary
  case failedToMakeFunction(name: String)

  var errorDescription: String? {
    switch self {
    case .failedToLoadLibrary:
      return "Failed to load library"
    case let .failedToMakeFunction(name):
      return "Failed to make a function: \(name)"
    }
  }
}
