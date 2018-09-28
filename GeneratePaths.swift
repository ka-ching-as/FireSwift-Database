#!/usr/bin/swift

//
//  GeneratePaths.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 05/08/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation

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

func phantomTypeName(for name: String) -> String {
    return singular(name).capitalized
}

enum TreeType: Decodable {
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


    case concreteType(typeName: String, isCollection: Bool)
    case phantomType(typeName: String, childNodes: [String: TreeType], isCollection: Bool)
 
    var isCollection: Bool {
        switch self {
        case .concreteType(_, let isCollection), .phantomType(_, _, let isCollection):
            return isCollection
        }
    }

    var pathTypePostfix: String {
        return isCollection ? ".Collection" : ""
    }

    var typeName: String {
        switch self {
        case .concreteType(let typeName, _), .phantomType(let typeName, _, _):
            return typeName
        }
    }

    func outputSubThingie(_ name: String) {
        let properCasedName = _convertFromSnakeCase(name)
        print("""
            var \(properCasedName): Path<\(typeName)>\(pathTypePostfix) {
                return Path.append(self, \"\(name)\")
            }

        """)

        if isCollection {
            print("""
                // Convenience
                func \(singular(properCasedName))(_ key: String) -> Path<\(typeName)> {
                    return \(properCasedName).child(key)
                }

            """)
        }
    }

    func outputEnum() {
        switch self {
        case .phantomType(let typeName, _, _):
            print("enum \(typeName) {}")
        case .concreteType:
            ()
        }
    }

    func output() {
        switch self {
        case .concreteType(let type):
            ()

        case .phantomType(let typeName, let subTypes, _):
            print("extension Path where Element == \(typeName) {")
            defer { print("}\n")}

            for (key, subType) in subTypes {
                subType.outputSubThingie(key)
            }
        }
    }

    func asCollection() -> TreeType {
        switch self {
        case .concreteType(let typeName, _):
            return .concreteType(typeName: typeName, isCollection: true)
        case .phantomType(let typeName, let childNodes, _):
            return .phantomType(typeName: typeName, childNodes: childNodes, isCollection: true)
        }
    }

    func withPhantomName(for path: String) -> TreeType {
        switch self {
        case .concreteType:
            return self
        case .phantomType(_, let childNodes, let isCollection):
            return .phantomType(typeName: phantomTypeName(for: path), childNodes: childNodes, isCollection: isCollection)
        }
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self = .concreteType(typeName: try container.decode(String.self), isCollection: false)
        } catch {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var childNodes: [String: TreeType] = [:]
            for key in container.allKeys {

                let value = try container.decode(TreeType.self, forKey: key)
                let isCollection = (key.stringValue.starts(with: "<") && key.stringValue.reversed().starts(with: ">"))
                if isCollection {
                    self = value.asCollection()
                    return
                }
                childNodes[key.stringValue] = value.withPhantomName(for: key.stringValue)
            }
            self = .phantomType(typeName: "", childNodes: childNodes, isCollection: false)
        }
    }
}

func phantomTypes(for tree: TreeType) -> [TreeType] {
    switch tree {
    case .concreteType:
        return []
    case .phantomType(_, let childNodes, _):
        return [tree] + childNodes.values.flatMap (phantomTypes(for:))
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
    guard let tree = try? decoder.decode(TreeType.self, from: data).withPhantomName(for: "Root") else {
        print("Could not parse file as json: \(filename)")
        return
    }

    let phantoms = phantomTypes(for: tree)
    for phantomType in phantoms {
        guard phantomType.typeName != "Root" else { continue }
        phantomType.outputEnum()
    }
    print("")

    for phantomType in phantoms {
        phantomType.output()
    }
}

run()
