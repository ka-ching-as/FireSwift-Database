//
//  Paths.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation
import FirebaseDatabase

// So from the Objc.io talk, we learn about a way of representing filesystem paths that can point to either files or directories.
// Internally, these are represented as an array of path elements. Let's do that too:
public struct Path<Element> {
    public struct Collection {
        private var components: [String]

        public func child(_ key: String) -> Path<Element> {
            return append(key)
        }

        fileprivate func append<T>(_ args: String ...) -> Path<T> {
            return Path<T>(components + args)
        }

        fileprivate init(_ components: [String]) {
            self.components = components
        }

        public var rendered: String {
            return components.joined(separator: "/")
        }
    }

    private var components: [String]

    fileprivate func append<T>(_ args: String ...) -> Path<T> {
        return Path<T>(components + args)
    }

    fileprivate func append<T>(_ args: String ...) -> Path<T>.Collection {
        return Path<T>.Collection(components + args)
    }

    fileprivate init(_ components: [String]) {
        self.components = components
    }

    public var rendered: String {
        return components.joined(separator: "/")
    }
}


// MARK: Modelling the actual Firebase RTDB hierarchy

enum Root {}
enum ChatRoom {}

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

extension Path where Element == Root {
    init() {
        self.init([])
    }
}

extension Path where Element == Root {
    var chatrooms: Path<ChatRoom>.Collection {
        return append("chatrooms")
    }

    // Convenience
    func chatroom(_ key: String) -> Path<ChatRoom> {
        return chatrooms.child(key)
    }

    var configuration: Path<Configuration> {
        return append("configuration")
    }
}

extension Path where Element == ChatRoom {
    var name: Path<String> {
        return append("name")
    }
    
    var messages: Path<Message>.Collection {
        return append("messages")
    }

    // Convenience
    func message(_ key: String) -> Path<Message> {
        return messages.child(key)
    }
}
