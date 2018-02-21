//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import Foundation
import PerfectHTTP
import PerfectHTTPServer
import PerfectNotifications


// your app id. we use this as the configuration name, but they do not have to match
let notificationsAppId = "vihlayew.V-ROOT-IOT-SB"
let notificationsTestId = "vihlayew.V-ROOT-IOT-SB"

let apnsKeyIdentifier = "2S7VZLT4V3"
let apnsTeamIdentifier = "ZJ2X3L2QM5"
let apnsPrivateKeyFilePath = "/Users/alexvihlayew/Desktop/AuthKey_2S7VZLT4V3.p8"


// MARK: - POST

func uploadPhotoHandler(request: HTTPRequest, response: HTTPResponse) {
    guard let photoBytes = request.postBodyBytes else { return }
    response.setHeader(.contentType, value: "application/json")
    let photoData = Data(bytes: photoBytes)
    let photoUID = StorageService.shared.addPhoto(photoData)
    let uidDict = ["uid": photoUID]
    do {
        try response.setBody(json: uidDict)
    } catch {
        response.status = .internalServerError
        print(error.localizedDescription)
    }
    response.completed()
}

func addVisitHandler(request: HTTPRequest, response: HTTPResponse) {
    print("addVisitHandler")
    print("Query params:", request.queryParams)
    print("Body string:", request.postBodyString)
    guard let timestampString = request.queryParams.first(where: { (key, value) -> Bool in key == "timestamp" })?.1,
        let timestamp = UInt64(timestampString),
        let photoUIDsString = request.queryParams.first(where: { (key, value) -> Bool in key == "photoUIDs" })?.1 else {
        response.status = .badRequest
        response.completed()
        return
    }
    print(photoUIDsString)
    let photoUIDs = photoUIDsString.dropFirst().dropLast().split(separator: ",").map({ (substring) in
        return String(substring)
    })
    print(photoUIDs)
    guard let previewUID = photoUIDs.first else {
        response.status = .badRequest
        response.completed()
        return
    }
    let visit = Visit(uid: UUID().uuidString, number: StorageService.shared.visitsCount, timestamp: timestamp, photoUIDs: photoUIDs, previewPhotoUID: previewUID)
    StorageService.shared.addVisit(visit)
    let successDict = ["success": true]
    do {
        try response.setBody(json: successDict)
    } catch {
        response.status = .internalServerError
        print(error.localizedDescription)
    }
    response.completed()
    push(visit)
}

// MARK: - GET

func visitsHandler(request: HTTPRequest, response: HTTPResponse) {
    response.setHeader(.contentType, value: "application/json")
    let visitsArray: [[String: Any]] = StorageService.shared.getVisits().reduce([], { (result, nextVisit) -> [[String: Any]] in
        return result + [nextVisit.toJsonDict()]
    })
    let visitsDict = ["visits": visitsArray]
    do {
        try response.setBody(json: visitsDict)
    } catch {
        response.status = .internalServerError
        print(error.localizedDescription)
    }
    response.completed()
}

func visitHandler(request: HTTPRequest, response: HTTPResponse) {
    guard let visitUID = request.queryParams.first(where: { (key, value) -> Bool in key == "uid" })?.1,
        let visit = StorageService.shared.getVisits().first(where: { (visit) in
            return visit.uid == visitUID
        }) else {
            response.status = .badRequest
            response.completed()
            return
    }
    response.setHeader(.contentType, value: "application/json")
    do {
        try response.setBody(json: visit.toExtendedJsonDict())
    } catch {
        response.status = .internalServerError
        print(error.localizedDescription)
    }
    response.completed()
}

func downloadPhotoHandler(request: HTTPRequest, response: HTTPResponse) {
    print("downloadPhotoHandler")
    print("Query params:", request.queryParams)
    print("Body string:", request.postBodyString)
    guard let photoUID = request.queryParams.first(where: { (key, value) -> Bool in key == "uid" })?.1,
        let photo = StorageService.shared.getPhoto(by: photoUID) else {
        response.status = .badRequest
        response.completed()
        return
    }
    response.setHeader(.contentType, value: MimeType.forExtension("png"))
    response.setHeader(.contentLength, value: "\(photo.data.count)")
    let photoBytes = [UInt8](photo.data)
    response.setBody(bytes: photoBytes)
    response.completed()
}

func push(_ visit: Visit) {
    // iOS
    let deviceIds: [String] = ["2AF8790976139638B2CC087B6DADC36EC81F0DF3A622046EBFCEDCC0A7A21C9C"]
    let n = NotificationPusher(apnsTopic: notificationsTestId)
    n.pushAPNS(
        configurationName: notificationsTestId,
        deviceTokens: deviceIds,
        notificationItems: [.alertBody("You had a new visitor at " + Date(timeIntervalSince1970: TimeInterval(visit.timestamp)).stringRepresentation()), .sound("default")]) { responses in
            print("\(responses)")
    }
    
    // Android
    var request = URLRequest(url: URL(string: "https://fcm.googleapis.com/fcm/send")!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("key=AAAAzHAqWSo:APA91bH4ffI33eJ2FXFjRd6lQ4ufvMd3xWVr2nCyAdiPDQB07s9-kaIrFAaaX-jWckVGIqIFO4RfwqSqqTDwntmW_AoJK4mM0u9ZPb1SlntonmR02qaXCVTLA0EZrVGDW1x_jN6AH43z", forHTTPHeaderField: "Authorization")
    request.httpBody = { () -> Data? in
        let body: [String: Any] = [
            "to": "/topics/foo-bar",
            "notification" : [
                "body" : ("You had a new visitor at " + Date(timeIntervalSince1970: TimeInterval(visit.timestamp)).stringRepresentation()),
                "title" : "Alfred app",
                "content_available" : true,
                "priority" : "high"
            ]
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            return data
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }()
    URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        if let error = error {
            print(error.localizedDescription)
        }
    }).resume()
}


// Configuration data for an example server.
// This example configuration shows how to launch a server
// using a configuration dictionary.


let confData = [
	"servers": [
		// Configuration data for one server which:
		//	* Serves the hello world message at <host>:<port>/
		//	* Serves static files out of the "./webroot"
		//		directory (which must be located in the current working directory).
		//	* Performs content compression on outgoing data when appropriate.
		[
			"name":"localhost",
			"port":9191,
			"routes":[
				["method":"post", "uri":"/uploadPhoto", "handler":uploadPhotoHandler],
                ["method":"post", "uri":"/addVisit", "handler":addVisitHandler],
                ["method":"get", "uri":"/visits", "handler":visitsHandler],
                ["method":"get", "uri":"/visit", "handler":visitHandler],
                ["method":"get", "uri":"/downloadPhoto", "handler":downloadPhotoHandler],
				["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
				 "documentRoot":"./webroot",
				 "allowResponseFilters":true]
			],
			"filters":[
				[
				"type":"response",
				"priority":"high",
				"name":PerfectHTTPServer.HTTPFilter.contentCompression,
				]
			]
		]
	]
]

NotificationPusher.addConfigurationAPNS(
    name: notificationsTestId,
    production: false, // should be false when running pre-release app in debugger
    keyId: apnsKeyIdentifier,
    teamId: apnsTeamIdentifier,
    privateKeyPath: apnsPrivateKeyFilePath)

do {
	// Launch the servers based on the configuration data.
	try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}

