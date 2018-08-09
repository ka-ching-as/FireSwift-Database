//
//  SamplePathUsage.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import Foundation

func example() throws {
    var ref: DatabaseReference! // Just showing the API, we do not have an actual initialized Firebase project
    let s = FirebaseService(ref: ref)

    let firechatPath = Path().chatroom("firechat")

    let config = Configuration(welcomeMessage: "Hello, World!")
    try s.setValue(at: Path().configuration, value: config)

    _ = s.observe(eventType: .childAdded, at: firechatPath.messages) { result in
        guard let message = result.value else { return }
        print("New message received:", message)
    }

    _ = s.observe(at: Path().configuration, with: { result in
        guard let config = result.value else { return }
        print("Configuration changed:", config)
    })

    let message = Message(header: "Firebase", body: "Firebase is awesome!")
    try s.addValue(at: firechatPath.messages, value: message)

}
