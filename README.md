# FireSwift-Database
A framework containing extensions to the Firebase Realtime Database enabling the use of `Codable` Swift types.

## Usage

In the following example, assume that we have a type `Configuration` that conforms to `Codable`.

Instead of 
```
let handle = ref.observe(.value) { snapshot in
     // Check if snapshot exists
     // Custom parsing of snapshot value
     // Error handling
}
```
you can use the `Decodable` types directly with the Firebase API:

```
let handle = ref.observe(eventType: .value) { (result: DecodeResult<Configuration>) in
    if let configuration = result.value {
        // configuration is of type Configuration
    } else {
        // Error handling
    }
}
```

And similarly for `Encodable` values.
Instead of:
```
let configuration: Configuration = ...
// Custom serialization of configuration to `Any`
ref.setValue(configValue)
```
you can now just do:
```
let configuration: Configuration = ...
ref.setValue(configuration)
```

This abstraction is already pretty powerful, but we can do even better.

The library contains a generic `Path` abstraction that can be used to model a type-safe alternative to the stringly-typed paths used to build Firebase `Reference`s. 

And even further you can use the generic type parameter of the `Path` to 'bind' to the type of the `Codable` parameters.

The examples above can be improved by defining a 'schema' for your firebase structure as follows:
```
// Define the schema of your firebase structure:
extension Path where Element == Root {
    var configuration: Path<Configuration> {
        return Path.append(self, "configuration")
    }
}
```

Using this, the type of the `result` can be inferred from the type of the `configPath`: 
```
let configPath = Path().configuration
let handle = database.observe(at: configPath) { result in
    if let configuration = result.value {
        // configuration is of type Configuration
    } else {
        // Error handling
    }
}
```
or
```
let configuration: Configuration = ...
database.setValue(at: configPath, value: configuration)
```

And you can do even more. The `Path` type can be used to distinguish between paths to values and paths to collections of values.

A collection path could look as follows:
```
extension Path where Element == Root {
    var users: Path<User>.Collection {
        return Path.append(self, "users")
    }
}
```
Using collection paths we can restrict ourselves from writing a single value to override the entire collection and instead only allow _adding_ values:
```
let usersPath = Path().users
let user: User = ...
database.addValue(to: usersPath, value: user)
```
Similarly we can restrict ourselves from observing a `.value` on a collection, but only allow observing the `.childAdded`,  `.childRemoved` and `.childChanged` events.
```
let handle = database.observe(eventType: .childAdded, at: usersPath) { result in
    if let user = result.value {
        // user is of type User
    } else {
        // Error handling
    }}
```

Collection paths have a `child(_ key: String)` method that returns a path to an element of the collection type.

If you enjoy these concepts, I can recommend looking into `RxSwift` for which I have also created the `RxFireSwift-Database` framework. This unlocks even cooler abstractions. :-)


## Installation

### Using [Carthage](https://github.com/Carthage/Carthage)

**Tested with `carthage version`: `0.31.0`**

Add this to `Cartfile`

```
github "ka-ching/FireSwift-Database" ~> 0.1
```

```bash
$ carthage update
```

### Automatic code generation

The repo contains a small, experimental Swift-script for generating the `Path` schema definitions from a json-file defining the schema.

Consider the following example schema:
```
{
  "configuration": "Configuration",
  "chatrooms" : {
    "<chatroomId>": {
      "messages": {
        "<messageId>": "Message"
      },
      "name": "String"
    }
  }
}
```

This will define `Paths` from the root of the structure and down to the leaf nodes which must correspond to names of model types in your code.

A json key that is wrapped in angle bracket means that the data at this point in the tree is part of a collection.

As you will notice, there is no entity defining a chatroom. For the sake of the above schema there is no model type corresponding to a chatroom, but rather you need to create a path to a chatroom in order to get to the messages of the chatroom.

This concept is modelled using phantom types. The code generator will generate an enum named `Chatroom` with no values. This means that the `Chatroom` can never be instantiated, but it can still be used as a generic restriction in our code.

With the code generated from the schema above, you can generate paths like:
```
let firechatMessagePath = Path().chatrooms.child("firechat").messages
```
The type of the `firechatMessagePath` variable is `Path<Message>.Collection`. In other words, a path to a collection of messages.

The full code generated from the above json is provided here as an example:
```
import FireSwift_Database

enum Chatroom {}

extension Path where Element == Root {
    var configuration: Path<Configuration> {
        return Path.append(self, "configuration")
    }

    var chatrooms: Path<Chatroom>.Collection {
        return Path.append(self, "chatrooms")
    }

    // Convenience
    func chatroom(_ key: String) -> Path<Chatroom> {
        return chatrooms.child(key)
    }
}

extension Path where Element == Chatroom {
    var messages: Path<Message>.Collection {
        return Path.append(self, "messages")
    }

    // Convenience
    func message(_ key: String) -> Path<Message> {
        return messages.child(key)
    }

    var name: Path<String> {
        return Path.append(self, "name")
    }
}
```

Add automatic `Path` code generation to an Xcode scheme. Just add a new "Run Script Phase" with something in the line of:

```bash
cd $PROJECT_DIR
./Carthage/Checkouts/FireSwift-Database/GeneratePaths.swift UseSwiftyFirebase/Resources/chatrooms.json > UseSwiftyFirebase/Generated/ChatroomPaths.swift
```

If you add this phase before the `Compile Sources` step, you will always be using up-to-date paths generated by the latest version of the scheme defined in the .json input file.

## TODO

- [ ] A
- [ ] B

## License

[Apache licensed.](LICENSE)

## About

FireSwift-Database is maintained by Ka-ching.

