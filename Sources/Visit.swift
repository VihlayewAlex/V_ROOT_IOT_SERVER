//
//  Visit.swift
//  PerfectTemplatePackageDescription
//
//  Created by Alex Vihlayew on 2/17/18.
//

import Foundation

struct Visit {
    
    let uid: String
    let number: Int
    let timestamp: UInt64
    let photoUIDs: [String]
    let previewPhotoUID: String
    
}

extension Visit {
    
    func toJsonDict() -> [String: Any] {
        return ["uid": uid,
                "number": number,
                "timestamp": timestamp,
                "previewPhotoUID": previewPhotoUID]
    }
    
    func toExtendedJsonDict() -> [String: Any] {
        return ["uid": uid,
                "number": number,
                "timestamp": timestamp,
                "photoUIDs": photoUIDs]
    }
    
}
