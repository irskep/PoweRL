//
//  HighScoreModel.swift
//  LD39
//
//  Created by Steve Johnson on 8/31/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation


class HighScoreModel {
    static var shared = { return HighScoreModel("high_scores") }()

    private let k: String

    init(_ k: String) {
        self.k = k
    }

    var scores: [Int] {
        return (UserDefaults.standard.array(forKey: k) as? [Int]) ?? []
    }

    func addScore(_ i: Int) -> Bool {
        let scores = self.scores
        guard i > (scores.last ?? 0) else { return false }
        let newScores = (scores + [i]).sorted().prefix(upTo: 100)
        UserDefaults.standard.set(newScores, forKey: k)
        return true
    }
}
