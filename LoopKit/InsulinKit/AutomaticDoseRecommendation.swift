//
//  AutomaticDoseRecommendation.swift
//  LoopKit
//
//  Created by Pete Schwamb on 1/16/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation

public struct AutomaticDoseRecommendation: Equatable {
    public let basalAdjustment: TempBasalRecommendation?
    public let bolusUnits: Double?

    /// The name of the policy that produced this recommendation, used downstream
    /// to attribute enacted doses (Apple Health metadata, dosing-decision logs).
    /// `nil` indicates the recommendation was produced before policy attribution
    /// was wired up, or by a path that intentionally elides the tag.
    public let policyIdentifier: String?

    public init(basalAdjustment: TempBasalRecommendation?, bolusUnits: Double? = nil, policyIdentifier: String? = nil) {
        self.basalAdjustment = basalAdjustment
        self.bolusUnits = bolusUnits
        self.policyIdentifier = policyIdentifier
    }
}

public extension AutomaticDoseRecommendation {
    /// Return a copy of this recommendation tagged with the given policy
    /// identifier. Used by `LoopDataManager` to stamp the result of whichever
    /// strategy branch produced it.
    func stampingPolicy(_ identifier: String?) -> AutomaticDoseRecommendation {
        return AutomaticDoseRecommendation(
            basalAdjustment: basalAdjustment,
            bolusUnits: bolusUnits,
            policyIdentifier: identifier
        )
    }
}

extension AutomaticDoseRecommendation: Codable {}
