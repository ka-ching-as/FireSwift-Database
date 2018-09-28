//
//  Paths.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation

// So from the Objc.io talk, we learn about a way of representing filesystem paths that can point to either files or directories.
// Internally, these are represented as an array of path elements. Let's do that too:
public struct Path<Element> {
    private var components: [String]

    fileprivate init(_ components: [String]) {
        self.components = components
    }

    public var rendered: String {
        return components.joined(separator: "/")
    }

    static func append<T>(_ p: Path, _ args: String ...) -> Path<T> {
        return Path<T>(p.components + args)
    }

    static func append<T>(_ p: Path, _ args: String ...) -> Path<T>.Collection {
        return Path<T>.Collection(p.components + args)
    }

    public struct Collection {
        private var components: [String]

        public func child(_ key: String) -> Path<Element> {
            return Path<Element>(components + [key])
        }

        fileprivate init(_ components: [String]) {
            self.components = components
        }

        public var rendered: String {
            return components.joined(separator: "/")
        }
    }
}

public enum Root {}

extension Path where Element == Root {
    public init() {
        self.init([])
    }
}
