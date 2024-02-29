//
//  HKQuantitySample.swift
//  CarbKit
//
//  Created by Nathan Racklyeft on 1/10/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import HealthKit


let LegacyMetadataKeyAbsorptionTime = "com.loudnate.CarbKit.HKMetadataKey.AbsorptionTimeMinutes"
let MetadataKeyAbsorptionTime = "com.loopkit.AbsorptionTime"
let MetadataKeyUserCreatedDate = "com.loopkit.CarbKit.HKMetadataKey.UserCreatedDate"
let MetadataKeyUserUpdatedDate = "com.loopkit.CarbKit.HKMetadataKey.UserUpdatedDate"
let MetadataKeyAbsorptionPredictedGrams = "com.interoperable.PredictedCarbAbsorptionGrams"
let MetadataKeyAbsorptionTimes = "com.interoperable.PredictedCarbAbsorptionTimesMinutes"

extension HKQuantitySample {
    public var foodType: String? {
        return metadata?[HKMetadataKeyFoodType] as? String
    }

    public var absorptionTime: TimeInterval? {
        if let interval = metadata?[MetadataKeyAbsorptionTime] as? TimeInterval ?? metadata?[LegacyMetadataKeyAbsorptionTime] as? TimeInterval{
            return interval
        }
        else if let data = absorptionData{
            guard let maxMins = data.keys.max() else { return nil }
            let interval = TimeInterval(minutes: Double(maxMins))
            return interval
        }
        return nil
    }

    public var absorptionData: [Int: Double]? {
        let valuesString = metadata?[MetadataKeyAbsorptionPredictedGrams] as? String
        let timesString = metadata?[MetadataKeyAbsorptionTimes] as? String

        let values = valuesString?.split(separator: ",").map({ s in Double(s) ?? 0.0})
        let times = timesString?.split(separator: ",").map({ s in Int(s) ?? 0 })
        guard times?.count == values?.count else{
            return nil
        }
        guard let times = times, let values = values, Set(times).count == times.count else{
            return nil
        }

        return Dictionary(uniqueKeysWithValues: zip(times, values))
    }
    
    public var absorptionDataBlob: Data? {
        return try? JSONEncoder().encode(absorptionData)
    }
    
    public var createdByCurrentApp: Bool {
        return sourceRevision.source == HKSource.default()
    }

    public var userCreatedDate: Date? {
        return metadata?[MetadataKeyUserCreatedDate] as? Date
    }

    public var userUpdatedDate: Date? {
        return metadata?[MetadataKeyUserUpdatedDate] as? Date
    }
}
