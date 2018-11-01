//
//  FirebaseExtensions.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 26/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation
@_exported import FireSwift_DecodeResult
@_exported import FireSwift_Paths
import FireSwift_StructureCoding
import FirebaseDatabase

// A small wrapper so that we prevent the user from calling collection observation with .value
public enum CollectionEventType {
    case childAdded, childChanged, childRemoved
    public var firebaseEventType: DataEventType {
        switch self {
        case .childAdded:
            return .childAdded
        case .childChanged:
            return .childChanged
        case .childRemoved:
            return .childRemoved
        }
    }
}

extension DataSnapshot {
    func decoded<T>(using decoder: StructureDecoder = .init()) -> DecodeResult<T> where T: Decodable {
        guard exists(), let value = value else {
            return .failure(.noValuePresent)
        }
        do {
            let d = try decoder.decode(T.self, from: value)
            return .success(d)
        } catch {
            return .failure(.conversionError(error))
        }
    }
}

public extension DatabaseQuery {
    func observeSingleEvent<T>(of type: DataEventType,
                               using decoder: StructureDecoder = .init(),
                               with block: @escaping (DecodeResult<T>) -> Void)
        where T: Decodable {
            observeSingleEvent(of: type, with: { snap in
                block(snap.decoded(using: decoder))
            }, withCancel: { error in
                block(.failure(.internalError(error)))
            })
    }

    func observe<T>(eventType: DataEventType,
                    using decoder: StructureDecoder = .init(),
                    with block: @escaping (DecodeResult<T>) -> Void) -> UInt
        where T: Decodable {
            return observe(eventType, with: { snap in
                block(snap.decoded(using: decoder))
            }, withCancel: { error in
                block(.failure(.internalError(error)))
            })
    }
}

public extension DatabaseReference {
    func setValue<T>(_ value: T, using encoder: StructureEncoder = .init()) throws where T: Encodable {
        self.setValue(try encoder.encode(value))
    }
}

public extension Database {

    func observeSingleEvent<T>(at path: Path<T>,
                               using decoder: StructureDecoder = .init(),
                               with block: @escaping (DecodeResult<T>) -> Void)
        where T: Decodable {
            return self[path].observeSingleEvent(of: .value,
                                                 using: decoder,
                                                 with: block)
    }

    func observe<T>(at path: Path<T>,
                    using decoder: StructureDecoder = .init(),
                    with block: @escaping (DecodeResult<T>) -> Void) -> UInt
        where T: Decodable {
            return self[path].observe(eventType: .value,
                                      using: decoder,
                                      with: block)
    }

    // MARK: Observing Collection Paths
    public func observeSingleEvent<T>(of type: CollectionEventType,
                                      at path: Path<T>.Collection,
                                      using decoder: StructureDecoder = .init(),
                                      with block: @escaping (DecodeResult<T>) -> Void)
        where T: Decodable {
            return self[path].observeSingleEvent(of: type.firebaseEventType,
                                                 using: decoder,
                                                 with: block)
    }

    public func observe<T>(eventType type: CollectionEventType,
                           at path: Path<T>.Collection,
                           using decoder: StructureDecoder = .init(),
                           with block: @escaping (DecodeResult<T>) -> Void) -> UInt
        where T: Decodable {
            return self[path].observe(eventType: type.firebaseEventType,
                                      using: decoder,
                                      with: block)
    }

    // MARK: Adding and Setting
    public func setValue<T>(at path: Path<T>, value: T, using encoder: StructureEncoder = .init()) throws where T: Encodable {
        try self[path].setValue(value, using: encoder)
    }

    public func addValue<T>(at path: Path<T>.Collection, value: T, using encoder: StructureEncoder = .init()) throws where T: Encodable {
        let childRef = self[path].childByAutoId()
        try childRef.setValue(value, using: encoder)
    }

    subscript<T>(path: Path<T>) -> DatabaseReference {
        return reference().child(path.rendered)
    }

    subscript<T>(path: Path<T>.Collection) -> DatabaseReference {
        return reference().child(path.rendered)
    }
}
