#!/usr/bin/env xcrun --sdk macosx swift

//
//  GeneratePaths.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 05/08/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation

// From JSONEncoder.swift in the github.com/apple/swift repo
fileprivate func _convertFromSnakeCase(_ stringKey: String) -> String {
    guard !stringKey.isEmpty else { return stringKey }

    // Find the first non-underscore character
    guard let firstNonUnderscore = stringKey.index(where: { $0 != "_" }) else {
        // Reached the end without finding an _
        return stringKey
    }

    // Find the last non-underscore character
    var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
    while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
        stringKey.formIndex(before: &lastNonUnderscore);
    }

    let keyRange = firstNonUnderscore...lastNonUnderscore
    let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
    let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex

    var components = stringKey[keyRange].split(separator: "_")
    let joinedString : String
    if components.count == 1 {
        // No underscores in key, leave the word as is - maybe already camel cased
        joinedString = String(stringKey[keyRange])
    } else {
        joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
    }

    // Do a cheap isEmpty check before creating and appending potentially empty strings
    let result : String
    if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
        result = joinedString
    } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
        // Both leading and trailing underscores
        result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
    } else if (!leadingUnderscoreRange.isEmpty) {
        // Just leading
        result = String(stringKey[leadingUnderscoreRange]) + joinedString
    } else {
        // Just trailing
        result = joinedString + String(stringKey[trailingUnderscoreRange])
    }
    return result
}


func singular(_ name: String) -> String {
    if name.last == "s" {
        return String(name.dropLast())
    }
    return name
}

struct Tree: Decodable {
    enum TreeType {
        case concreteType
        case phantomType(childNodes: [String: Tree])
    }

    private struct CodingKeys : CodingKey {
        let stringValue: String
        let intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    var typeName: String
    var isCollection: Bool
    var type: TreeType

    init(typeName: String, isCollection: Bool, type: TreeType) {
        self.typeName = typeName
        self.isCollection = isCollection
        self.type = type
    }

    var pathTypePostfix: String {
        return isCollection ? ".Collection" : ""
    }

    func outputMember(_ name: String) -> String {
        let properCasedName = _convertFromSnakeCase(name)
        var result: [String] = []
        result.append("""
            var \(properCasedName): Path<\(typeName)>\(pathTypePostfix) {
                return Path.append(self, \"\(name)\")
            }
        """)

        if isCollection {
            result.append("""
                // Convenience
                func \(singular(properCasedName))(_ key: String) -> Path<\(typeName)> {
                    return \(properCasedName).child(key)
                }
            """)
        }
        return result.joined(separator: "\n\n")
    }

    func outputEnum() -> String? {
        // Only output enums for phantom types - and not for the root
        guard case .phantomType = type else { return nil }
        guard typeName != "Root" else { return nil }

        return "enum \(typeName) {}"
    }

    func outputExtension() -> String? {
        guard case .phantomType(let subTypes) = type else { return nil }
        let ext = "extension Path where Element == \(typeName) {\n"
        let extClose = "\n}\n"

        let members = subTypes.map { $0.value.outputMember($0.key)}.joined(separator: "\n\n")
        return ext + members + extClose
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self.init(typeName: try container.decode(String.self), isCollection: false, type: .concreteType)
        } catch {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var childNodes: [String: Tree] = [:]
            for key in container.allKeys {
                var value = try container.decode(Tree.self, forKey: key)
                value.isCollection = (key.stringValue.starts(with: "<") && key.stringValue.reversed().starts(with: ">"))
                if value.isCollection {
                    self = value
                    return
                }
                // Phantom types are born without a type name. Use their key in singular form as their name
                if case .phantomType = value.type {
                    value.typeName = singular(key.stringValue).capitalized
                }
                childNodes[key.stringValue] = value
            }
            self.init(typeName: "", isCollection: false, type: .phantomType(childNodes: childNodes))
        }
    }
}

func flatten(tree: Tree) -> [Tree] {
    switch tree.type {
    case .concreteType:
        return []
    case .phantomType(let childNodes):
        return [tree] + childNodes.values.flatMap (flatten(tree:))
    }
}

func run() {
    guard CommandLine.arguments.count > 1 else {
        print("Usage: GeneratePaths.swift <filename.json>")
        return
    }
    let filename = CommandLine.arguments[1]
    let fileManager = FileManager.default
    let cwd = fileManager.currentDirectoryPath
    let fileURL: URL
    if filename.starts(with: "/") {
        fileURL = URL(fileURLWithPath: filename)
    } else {
        fileURL = URL(fileURLWithPath: "\(cwd)/\(filename)")
    }
    guard fileManager.fileExists(atPath: fileURL.path) else {
        print("File not found: \(filename)")
        return
    }
    guard let data = try? Data(contentsOf: fileURL) else {
        print("Could not read contents of file: \(filename)")
        return
    }
    let decoder = JSONDecoder()
    guard var tree = try? decoder.decode(Tree.self, from: data) else {
        print("Could not parse file as json: \(filename)")
        return
    }
    tree.typeName = "Root"

    let phantoms = flatten(tree: tree)

    let enums = phantoms.compactMap { $0.outputEnum() }
    let extensions = phantoms.compactMap { $0.outputExtension() }
    print("import SwiftyFirebase\n")
    print(enums.joined(separator: "\n"))
    print("")
    print(extensions.joined(separator: "\n"))
}

run()
