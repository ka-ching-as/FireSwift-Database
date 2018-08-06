//
//  SamplePaths.swift
//  SwiftyFirebase
//
//  Created by Morten Bek Ditlevsen on 29/07/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import Foundation

enum Root {}
enum Account {}

struct Product: Codable {
    let name: String
    let price: Decimal
}

struct Config: Codable {
    let value: Int
}

extension Path where Element == Root {
    init() {
        self.init([])
    }
}

extension Path where Element == Root {
    var products: CollectionPath<Product> {
        return append("products")
    }

    var accounts: CollectionPath<Account> {
        return append("accounts")
    }
}

extension Path where Element == Account {
    var products: CollectionPath<Product> {
        return append("products")
    }

    var config: Path<Config> {
        return append("config")
    }
}

/*
 {
    products: { key: Product },
    accounts: {
      key: {
        products: { key: Product },
        config: Config
      }
    }
 }


 */


// Now we have a Path that can be created:
let rootPath = Path()
let product = rootPath.products.child("sko")
let accountSpecificProduct = rootPath.accounts.child("account").products.child("product")
