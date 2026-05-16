//
//  HKQuantitySample+InsulinKit.swift
//  InsulinKit
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import HealthKit


/// Defines the scheduled basal insulin rate during the time of the basal delivery sample
let MetadataKeyScheduledBasalRate = "com.loopkit.InsulinKit.MetadataKeyScheduledBasalRate"

/// Defines the programmed rate for a temporary basal dose
let MetadataKeyProgrammedTempBasalRate = "com.loopkit.InsulinKit.MetadataKeyProgrammedTempBasalRate"

/// A crude determination of whether a sample was written by LoopKit, in the case of multiple LoopKit-enabled app versions on the same phone.
let MetadataKeyHasLoopKitOrigin = "HasLoopKitOrigin"

/// Defines the insulin curve type to use to evaluate the dose's activity
let MetadataKeyInsulinType = "com.loopkit.InsulinKit.MetadataKeyInsulinType"

/// Flag indicated whether this dose was manually entered
let MetadataKeyManuallyEntered = "com.loopkit.InsulinKit.MetadataKeyManuallyEntered"

/// Flag indicating whether this dose was issued automatically or if a user issued it manually.
let MetadataKeyAutomaticallyIssued = "com.loopkit.InsulinKit.MetadataKeyAutomaticallyIssued"

/// Flag indicating whether this dose is a suspend
let MetadataKeyIsSuspend = "com.loopkit.InsulinKit.MetadataKeyIsSuspend"

/// Identifier of the dosing policy that recommended this dose (e.g.
/// "Automatic Bolus", "Temp Basal Only", "LLM Policy (experimental)"). Stamped
/// by `LoopDataManager` after a successful automatic enactment.
let MetadataKeyPolicyIdentifier = "com.loopkit.InsulinKit.MetadataKeyPolicyIdentifier"

/// Name of the fallback algorithm when the selected policy delegated dose
/// computation (e.g. LLM call failed → "Temp Basal Only").
let MetadataKeyPolicyFallbackAlgorithm = "com.loopkit.InsulinKit.MetadataKeyPolicyFallbackAlgorithm"

/// Free-text rationale (LLM bullets or full failure description).
let MetadataKeyPolicyRationale = "com.loopkit.InsulinKit.MetadataKeyPolicyRationale"

/// JSON snapshot of the inputs the policy consumed.
let MetadataKeyPolicyInputBlob = "com.loopkit.InsulinKit.MetadataKeyPolicyInputBlob"

extension HKQuantitySample {
    convenience init?(type: HKQuantityType, unit: HKUnit, dose: DoseEntry, device: HKDevice?, provenanceIdentifier: String, syncVersion: Int = 1) {
        let units = dose.unitsInDeliverableIncrements

        guard let syncIdentifier = dose.syncIdentifier else {
            return nil
        }

        var metadata: [String: Any] = [
            HKMetadataKeySyncVersion: syncVersion,
            HKMetadataKeySyncIdentifier: syncIdentifier,
            MetadataKeyHasLoopKitOrigin: true,
            MetadataKeyManuallyEntered: dose.manuallyEntered
        ]
        
        switch dose.type {
        case .basal, .tempBasal, .suspend:
            // Ignore 0-duration basal entries
            guard dose.endDate.timeIntervalSince(dose.startDate) > .ulpOfOne else {
                return nil
            }

            metadata[HKMetadataKeyInsulinDeliveryReason] = HKInsulinDeliveryReason.basal.rawValue

            if let basalRate = dose.scheduledBasalRate {
                metadata[MetadataKeyScheduledBasalRate] = basalRate
            }

            if dose.type == .tempBasal {
                metadata[MetadataKeyProgrammedTempBasalRate] = HKQuantity(unit: .internationalUnitsPerHour, doubleValue: dose.unitsPerHour)
            }

            metadata[MetadataKeyIsSuspend] = dose.type == .suspend
        case .bolus:
            // Ignore 0-unit bolus entries
            guard units > .ulpOfOne else {
                return nil
            }

            metadata[HKMetadataKeyInsulinDeliveryReason] = HKInsulinDeliveryReason.bolus.rawValue
        case .resume:
            return nil
        }
        
        if let insulinType = dose.insulinType {
            metadata[MetadataKeyInsulinType] = insulinType.healthKitRepresentation
        }
        
        if let automatic = dose.automatic {
            metadata[MetadataKeyAutomaticallyIssued] = automatic
        }

        if let policyIdentifier = dose.policyIdentifier {
            metadata[MetadataKeyPolicyIdentifier] = policyIdentifier
        }

        if let policyFallbackAlgorithm = dose.policyFallbackAlgorithm {
            metadata[MetadataKeyPolicyFallbackAlgorithm] = policyFallbackAlgorithm
        }

        if let policyRationale = dose.policyRationale {
            metadata[MetadataKeyPolicyRationale] = policyRationale
        }

        if let policyInputBlob = dose.policyInputBlob {
            metadata[MetadataKeyPolicyInputBlob] = policyInputBlob
        }

        self.init(
            type: type,
            quantity: HKQuantity(unit: unit, doubleValue: units),
            start: dose.startDate,
            end: dose.endDate,
            device: device,
            metadata: metadata
        )
    }

    var hasLoopKitOrigin: Bool {
        guard let hasLoopKitOrigin = metadata?[MetadataKeyHasLoopKitOrigin] as? Bool else {
            return false
        }

        return hasLoopKitOrigin
    }

    var insulinDeliveryReason: HKInsulinDeliveryReason? {
        guard let reason = metadata?[HKMetadataKeyInsulinDeliveryReason] as? HKInsulinDeliveryReason.RawValue else {
            return nil
        }

        return HKInsulinDeliveryReason(rawValue: reason)
    }

    var scheduledBasalRate: HKQuantity? {
        return metadata?[MetadataKeyScheduledBasalRate] as? HKQuantity
    }

    var programmedTempBasalRate: HKQuantity? {
        return metadata?[MetadataKeyProgrammedTempBasalRate] as? HKQuantity
    }

    var isSuspend: Bool {
        return metadata?[MetadataKeyIsSuspend] as? Bool ?? false
    }

    var manuallyEntered: Bool {
        return metadata?[MetadataKeyManuallyEntered] as? Bool ?? false
    }
    
    var automaticallyIssued: Bool? {
        return metadata?[MetadataKeyAutomaticallyIssued] as? Bool
    }

    var policyIdentifier: String? {
        return metadata?[MetadataKeyPolicyIdentifier] as? String
    }

    var policyFallbackAlgorithm: String? {
        return metadata?[MetadataKeyPolicyFallbackAlgorithm] as? String
    }

    var policyRationale: String? {
        return metadata?[MetadataKeyPolicyRationale] as? String
    }

    var policyInputBlob: String? {
        return metadata?[MetadataKeyPolicyInputBlob] as? String
    }

    var insulinType: InsulinType? {
        guard let rawType = metadata?[MetadataKeyInsulinType] as? String else {
            return nil
        }
        
        return InsulinType(healthKitRepresentation: rawType)
    }

    /// Returns a DoseEntry representation of the sample.
    /// Doses are not normalized, nor should they be assumed reconciled.
    var dose: DoseEntry? {
        guard let reason = insulinDeliveryReason else {
            return nil
        }

        let type: DoseType

        switch reason {
        case .basal:
            if isSuspend {
                type = .suspend
            } else if programmedTempBasalRate != nil {
                type = .tempBasal
            } else {
                type = .basal
            }

            // We can't properly trust non-LoopKit-provided basal insulin
            guard hasLoopKitOrigin else {
                return nil
            }
        case .bolus:
            type = .bolus
        @unknown default:
            return nil
        }

        let value: Double
        let unit: DoseUnit
        let deliveredUnits: Double?
        
        if let programmedRate = programmedTempBasalRate {
            value = programmedRate.doubleValue(for: .internationalUnitsPerHour)
            unit = .unitsPerHour
            deliveredUnits = quantity.doubleValue(for: .internationalUnit())
        } else {
            value = quantity.doubleValue(for: .internationalUnit())
            unit = .units
            deliveredUnits = nil
        }

        return DoseEntry(
            type: type,
            startDate: startDate,
            endDate: endDate,
            value: value,
            unit: unit,
            deliveredUnits: deliveredUnits,
            description: nil,
            syncIdentifier: syncIdentifier,
            scheduledBasalRate: scheduledBasalRate,
            insulinType: insulinType,
            automatic: automaticallyIssued,
            manuallyEntered: manuallyEntered,
            policyIdentifier: policyIdentifier,
            policyFallbackAlgorithm: policyFallbackAlgorithm,
            policyRationale: policyRationale,
            policyInputBlob: policyInputBlob
        )
    }
}

enum InsulinTypeHealthKitRepresentation: String {
    case novolog = "Novolog"
    case humalog = "Humalog"
    case apidra = "Apidra"
    case fiasp = "Fiasp"
    case lyumjev = "Lyumjev"
    case afrezza = "Afrezza"
}

extension InsulinType {
    var healthKitRepresentation: String {
        switch self {
        case .novolog:
            return InsulinTypeHealthKitRepresentation.novolog.rawValue
        case .humalog:
            return InsulinTypeHealthKitRepresentation.humalog.rawValue
        case .apidra:
            return InsulinTypeHealthKitRepresentation.apidra.rawValue
        case .fiasp:
            return InsulinTypeHealthKitRepresentation.fiasp.rawValue
        case .lyumjev:
            return InsulinTypeHealthKitRepresentation.lyumjev.rawValue
        case .afrezza:
            return InsulinTypeHealthKitRepresentation.afrezza.rawValue
        }
    }
    
    init?(healthKitRepresentation: String) {
        switch healthKitRepresentation {
        case InsulinTypeHealthKitRepresentation.novolog.rawValue:
            self = .novolog
        case InsulinTypeHealthKitRepresentation.humalog.rawValue:
            self = .humalog
        case InsulinTypeHealthKitRepresentation.apidra.rawValue:
            self = .apidra
        case InsulinTypeHealthKitRepresentation.fiasp.rawValue:
            self = .fiasp
        case InsulinTypeHealthKitRepresentation.lyumjev.rawValue:
            self = .lyumjev
        case InsulinTypeHealthKitRepresentation.afrezza.rawValue:
            self = .afrezza
        default:
            return nil
        }
    }
}
