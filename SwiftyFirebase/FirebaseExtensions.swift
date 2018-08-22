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
import RxSwift

public typealias DecodeResult<T> = Result<T, DecodeError>

public enum DecodeError: Error {
    case noValuePresent
    case conversionError(Error)
    case internalError(Error)
}

extension DataSnapshot {
    func decoded<T>() -> DecodeResult<T> where T: Decodable {
        guard exists(), let value = value else {
            return Result.failure(DecodeError.noValuePresent)
        }
        let decoder = StructureDecoder()
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
                               with block: @escaping (DecodeResult<T>) -> Void)
        where T: Decodable {
            observeSingleEvent(of: type, with: { snap in
                block(snap.decoded())
            }, withCancel: { error in
                block(.failure(.internalError(error)))
            })
    }

    func observe<T>(eventType: DataEventType,
                    with block:  @escaping (DecodeResult<T>) -> Void) -> UInt
        where T: Decodable {
            return observe(eventType, with: { snap in
                block(snap.decoded())
            }, withCancel: { error in
                block(.failure(.internalError(error)))
            })
    }
}

public extension DatabaseReference {
    func setValue<T>(_ value: T) throws where T: Encodable {
        let encoder = StructureEncoder()
        self.setValue(try encoder.encode(value))
    }
}

extension DecodeResult {
    // A small convenience to re-wrap a `DecodeResult` as a `SingleEvent`
    var asSingleEvent: SingleEvent<Value> {
        switch self {
        case .success(let v):
            return .success(v)
        case .failure(let e):
            return .error(e)
        }
    }
}

extension Reactive where Base: DatabaseQuery {
    func observeSingleEvent<T>(of type: DataEventType) -> Single<T> where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(of: type, with: { (result: DecodeResult<T>) in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    func observe<T>(eventType: DataEventType) -> Observable<DecodeResult<T>> where T: Decodable {
        return Observable.create { observer in
            let handle = self.base.observe(eventType: eventType, with: { (result: DecodeResult<T>) in
                observer.onNext(result)
            })
            return Disposables.create {
                self.base.removeObserver(withHandle: handle)
            }
        }
    }
}
