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

    func append<T>(_ args: String ...) -> Path<T> {
        return Path<T>(components + args)
    }

    func append<T>(_ args: String ...) -> CollectionPath<T> {
        return CollectionPath<T>(components + args)
    }

//    func append<T>(_ arg: String) -> Path<T> {
//        return append([arg])
//    }

    init(_ components: [String]) {
        self.components = components
    }

    var rendered: String {
        return components.joined(separator: "/")
    }
}

// So the path is generic over the 'Element' which is where we use both Phantom types AND actual model types.
// For now we cannot construct a Path outside of the scope of this file.

public struct CollectionPath<Element> {
    private var components: [String]

    public func child(_ key: String) -> Path<Element> {
        return append([key])
    }

    func append<T>(_ args: [String]) -> Path<T> {
        return Path<T>(components + args)
    }

    func append<T>(_ arg: String) -> Path<T> {
        return append([arg])
    }

    init(_ components: [String]) {
        self.components = components
    }

    var rendered: String {
        return components.joined(separator: "/")
    }
}

//// Now, we cannot extend the Path type to be constrained to a generic type, so we need to wrap it in a protocol.
//// You need to ask smarter people to me as to why this can't be represented. I don't know if it's a limitation in Swift, or if there is some logical existential reason why this can't be done. But let's add a protocol so that we _can_ represent it in Swift:
//public protocol CollectionPathProtocol {
//    associatedtype ElementType
//}
//
//// Our CollectionPath generic type can now be made to conform to this protocol:
//extension CollectionPath: CollectionPathProtocol {
//    public typealias ElementType = Element
//}

//extension CollectionPath {
//    public func child(_ key: String) -> Path<Element> {
//        return append([key])
//    }
//}

//// And finally we can model collection/child relationships on the Path
//extension Path where Element: CollectionPathProtocol {
//    public func child(_ key: String) -> Path<Element.ElementType> {
//        return append(key)
//    }
//}
