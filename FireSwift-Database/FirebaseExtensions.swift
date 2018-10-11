//
//  FirebaseExtensions.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 26/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Result

public typealias DecodeResult<T> = Result<T, DecodeError>

public enum DecodeError: Error {
    case noValuePresent
    case conversionError(Error)
    case internalError(Error)
}

extension DataSnapshot {
    func decoded<T>(using decoder: StructureDecoder = .init()) -> DecodeResult<T> where T: Decodable {
        guard exists(), let value = value else {
            return Result.failure(DecodeError.noValuePresent)
        }
        do {
            let d = try decoder.decode(T.self, from: value)
            return Result.success(d)
        } catch {
            return Result.failure(DecodeError.conversionError(error))
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
                    with block:  @escaping (DecodeResult<T>) -> Void) -> UInt
        where T: Decodable {
            let decoder = StructureDecoder()
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
    subscript<T>(path: Path<T>) -> DatabaseReference {
        return reference().child(path.rendered)
    }

    subscript<T>(path: Path<T>.Collection) -> DatabaseReference {
        return reference().child(path.rendered)
    }
}
