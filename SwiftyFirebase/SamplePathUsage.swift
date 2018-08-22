//
//  SamplePathUsage.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import Foundation
import RxSwift

protocol ViewModelInputs {
    func add(message: Message)
    func update(configuration: Configuration)
}

protocol ViewModelOutputs {
    var newMessages: Observable<Message> { get }
    var configuration: Observable<Configuration> { get }
}

protocol ViewModelType {
    var inputs: ViewModelInputs { get }
    var outputs: ViewModelOutputs { get }
}

class ViewModel: ViewModelType, ViewModelOutputs, ViewModelInputs {
    var inputs: ViewModelInputs { return self }
    var outputs: ViewModelOutputs { return self }

    private let configurationPath = Path().configuration
    private let firechatPath = Path().chatroom("firechat").messages

    lazy var newMessages: Observable<Message> = s.observe(eventType: .childAdded, at: firechatPath).filtered()
    lazy var configuration: Observable<Configuration> = s.observe(at: configurationPath).filtered()

    func add(message: Message) {
        try? s.addValue(at: firechatPath, value: message)
    }

    func update(configuration: Configuration) {
        try? s.setValue(at: configurationPath, value: configuration)
    }

    private let s: FirebaseService
    init(service: FirebaseService) {
        self.s = service
    }
}
