//
//  Date+Extensions.swift
//  V_ROOT_IOT
//
//  Created by Alex Vihlayew on 2/17/18.
//  Copyright © 2018 Alex Vihlayew. All rights reserved.
//

import Foundation

extension Date {
    
    func stringRepresentation() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: self)
    }
    
}
