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

    /// The name of the user-selected policy that originated this
    /// recommendation. `nil` for recs produced before attribution was wired
    /// up, or by paths that intentionally elide the tag (emergency cancels).
    public let policyIdentifier: String?

    /// When the originally-selected policy delegated dose computation to a
    /// backup algorithm (e.g. LLM call failed and Temp Basal Only ran), this
    /// records the fallback algorithm's name. `nil` for clean runs.
    public let policyFallbackAlgorithm: String?

    /// Free-text reasoning the policy attached to its recommendation (LLM
    /// rationale, or a full failure description on a fallback path).
    public let policyRationale: String?

    /// JSON snapshot of the inputs the policy actually consumed. Excludes the
    /// full predicted-glucose trajectory to keep the blob small.
    public let policyInputBlob: String?

    public init(
        basalAdjustment: TempBasalRecommendation?,
        bolusUnits: Double? = nil,
        policyIdentifier: String? = nil,
        policyFallbackAlgorithm: String? = nil,
        policyRationale: String? = nil,
        policyInputBlob: String? = nil
    ) {
        self.basalAdjustment = basalAdjustment
        self.bolusUnits = bolusUnits
        self.policyIdentifier = policyIdentifier
        self.policyFallbackAlgorithm = policyFallbackAlgorithm
        self.policyRationale = policyRationale
        self.policyInputBlob = policyInputBlob
    }
}

public extension AutomaticDoseRecommendation {
    /// Return a copy of this recommendation tagged with the supplied policy
    /// provenance fields. Used by `LoopDataManager` to stamp the stock-strategy
    /// recommendations that don't stamp themselves.
    func stampingPolicy(
        identifier: String?,
        fallbackAlgorithm: String? = nil,
        rationale: String? = nil,
        inputBlob: String? = nil
    ) -> AutomaticDoseRecommendation {
        return AutomaticDoseRecommendation(
            basalAdjustment: basalAdjustment,
            bolusUnits: bolusUnits,
            policyIdentifier: identifier,
            policyFallbackAlgorithm: fallbackAlgorithm,
            policyRationale: rationale,
            policyInputBlob: inputBlob
        )
    }
}

extension AutomaticDoseRecommendation: Codable {}
