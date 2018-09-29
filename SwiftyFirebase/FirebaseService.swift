//
//  FirebaseService.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import Foundation
import Result
import RxSwift

// A small wrapper so that we prevent the user from calling collection observation with .value
public enum CollectionEventType {
    case childAdded, childChanged, childRemoved
    var firebaseEventType: DataEventType {
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

public class FirebaseService {
    private let rootRef: DatabaseReference
    public init(ref: DatabaseReference) {
        self.rootRef = ref.root
    }

    // MARK: Observing Paths
    public func observeSingleEvent<T>(at path: Path<T>) -> Single<T>
        where T: Decodable {
            let ref = rootRef.child(path.rendered)
            return ref.rx.observeSingleEvent(of: .value)
    }

    public func observe<T>(at path: Path<T>) -> Observable<DecodeResult<T>>
        where T: Decodable {
            let ref = rootRef.child(path.rendered)
            return ref.rx.observe(eventType: .value)
    }

    // MARK: Observing Collection Paths
    public func observeSingleEvent<T>(of type: CollectionEventType,
                               at path: Path<T>) -> Single<T>
        where T: Decodable {
            let ref = rootRef.child(path.rendered)
            return ref.rx.observeSingleEvent(of: type.firebaseEventType)
    }

    public func observe<T>(eventType type: CollectionEventType,
                    at path: Path<T>.Collection) -> Observable<DecodeResult<T>>
        where T: Decodable {
            let ref = rootRef.child(path.rendered)
            return ref.rx.observe(eventType: type.firebaseEventType)
    }

    // MARK: Adding and Setting
    public func setValue<T>(at path: Path<T>, value: T) throws where T: Encodable {
        let ref = rootRef.child(path.rendered)
        try ref.setValue(value)
    }

    public func addValue<T>(at path: Path<T>.Collection, value: T) throws where T: Encodable {
        let ref = rootRef.child(path.rendered)
        let childRef = ref.childByAutoId()
        try childRef.setValue(value)
    }
}

protocol ResultProtocol {
    associatedtype WrappedType
    associatedtype ErrorType
    var value: WrappedType? { get }
    var error: ErrorType? { get }
}

extension Result: ResultProtocol {
    typealias WrappedType = Value
    typealias ErrorType = Error
}

extension Observable where Element: ResultProtocol {
    func filtered() -> Observable<Element.WrappedType> {
        return self.filter { $0.value != nil }.map { $0.value! }
    }

    func filtered(handler: @escaping (Element.ErrorType) -> Void) -> Observable<Element.WrappedType> {
        return self
            .do(onNext: { result in
                guard let error = result.error else { return }
                handler(error)
            })
            .filter { $0.value != nil }
            .map { $0.value! }
    }
}
