//
//  SamplePathUsage.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import Foundation

// MARK: Modelling the actual Firebase RTDB hierarchy

struct Message: Codable {
    var header: String
    var body: String
    init(header: String, body: String) {
        self.header = header
        self.body = body
    }
}

struct Configuration: Codable {
    // Our actual Configuration entity
    var welcomeMessage: String
    init(welcomeMessage: String) {
        self.welcomeMessage = welcomeMessage
    }
}

enum Chatroom {}

extension Path where Element == Root {
    var chatrooms: Path<Chatroom>.Collection {
        return Path.append(self, "chatrooms")
    }

    // Convenience
    func chatroom(_ key: String) -> Path<Chatroom> {
        return chatrooms.child(key)
    }

    var configuration: Path<Configuration> {
        return Path.append(self, "configuration")
    }

}

extension Path where Element == Chatroom {
    var messages: Path<Message>.Collection {
        return Path.append(self, "messages")
    }

    // Convenience
    func message(_ key: String) -> Path<Message> {
        return messages.child(key)
    }

    var name: Path<String> {
        return Path.append(self, "name")
    }

}

func example() throws {
    var ref: DatabaseReference! // Just showing the API, we do not have an actual initialized Firebase project
    let s = FirebaseService(ref: ref)

    let firechatPath = Path().chatroom("firechat")

    let config = Configuration(welcomeMessage: "Hello, World!")
    try s.setValue(at: Path().configuration, value: config)

    _ = s.observe(eventType: .childAdded, at: firechatPath.messages) { result in
        guard let message = result.value else { return }
        print("New message received:", message)
    }

    _ = s.observe(at: Path().configuration, with: { result in
        guard let config = result.value else { return }
        print("Configuration changed:", config)
    })

    let message = Message(header: "Firebase", body: "Firebase is awesome!")
    try s.addValue(at: firechatPath.messages, value: message)

}
