//
//  FirebaseRxExtensions.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 30/09/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import Foundation
import RxSwift

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
