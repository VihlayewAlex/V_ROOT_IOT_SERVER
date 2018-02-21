//
//  StorageService.swift
//  PerfectTemplatePackageDescription
//
//  Created by Alex Vihlayew on 2/17/18.
//

import Foundation

class StorageService {
    
    static let shared = StorageService()
    private init() { }
    
    private var photos = [Photo]()
    private var visits = [Visit]()
    
    var visitsCount: Int {
        return visits.count
    }
    
    func addPhoto(_ photoData: Data) -> String {
        let photoUUID = UUID().uuidString
        let photo = Photo(uid: photoUUID, data: photoData)
        photos.append(photo)
        print("Added new photo")
        return photoUUID
    }
    
    func addVisit(_ visit: Visit) {
        visits.append(visit)
        print("Added new visit")
    }
    
    func getVisits() -> [Visit] {
        return visits.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.timestamp > rhs.timestamp
        })
    }
    
    func getPhoto(by uid: String) -> Photo? {
        return photos.first(where: { (photo) -> Bool in
            photo.uid == uid
        })
    }
    
}
