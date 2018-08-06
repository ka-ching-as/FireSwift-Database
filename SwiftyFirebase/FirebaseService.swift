//
//  FirebaseService.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import Foundation

public class FirebaseService {
    private let rootRef: DatabaseReference
    public init(ref: DatabaseReference) {
        self.rootRef = ref.root
    }

    func observeSingleEvent<T>(of type: DataEventType,
                               at path: Path<T>,
                               with block: @escaping (DecodeResult<T>) -> Void)
        where T: Decodable {
            let ref = rootRef.child(path.rendered)
            ref.observeSingleEvent(of: type) { snap in
                block(snap.decoded())
            }
    }

    func observe<T>(eventType: DataEventType,
                    at path: Path<T>,
                    with block:  @escaping (DecodeResult<T>) -> Void) -> UInt
        where T: Decodable {
            let ref = rootRef.child(path.rendered)
            return ref.observe(eventType, with: { snap in
                block(snap.decoded())
            })
    }
}
