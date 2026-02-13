//
//  SearchManager.swift
//  MOMENTUM Planner
//
//  Search manager for finding and highlighting entries
//

import Foundation
import SwiftUI
import Combine

struct SearchResult: Identifiable {
    let id = UUID()
    let entry: Entry
    let date: Date
    let matchRanges: [Range<String.Index>]
}

class SearchManager: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var currentIndex: Int = 0

    func search(query: String, in entries: [Entry]) {
        guard !query.isEmpty else {
            results = []
            currentIndex = 0
            return
        }

        let lowercasedQuery = query.lowercased()
        var searchResults: [SearchResult] = []

        for entry in entries {
            let content = entry.content.lowercased()
            var ranges: [Range<String.Index>] = []
            var searchStartIndex = content.startIndex

            while searchStartIndex < content.endIndex,
                  let range = content.range(of: lowercasedQuery, range: searchStartIndex..<content.endIndex) {
                ranges.append(range)
                searchStartIndex = range.upperBound
            }

            if !ranges.isEmpty {
                searchResults.append(SearchResult(
                    entry: entry,
                    date: entry.targetDate,
                    matchRanges: ranges
                ))
            }
        }

        results = searchResults
        currentIndex = results.isEmpty ? 0 : 0
    }

    func nextResult() {
        guard !results.isEmpty else { return }
        currentIndex = (currentIndex + 1) % results.count
    }

    func previousResult() {
        guard !results.isEmpty else { return }
        currentIndex = (currentIndex - 1 + results.count) % results.count
    }

    var currentResult: SearchResult? {
        guard !results.isEmpty, currentIndex < results.count else { return nil }
        return results[currentIndex]
    }
}
