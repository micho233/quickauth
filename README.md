# QuickAuth

QuickAuth is simple OAuth2 authentication library designed for Swift applications. It handles all authorized and non-authorized network requests, leveraging access and refresh tokens for authentication. QuickAuth emphasizes security by avoiding the storage of sensitive information on the library side, instead delegating this responsibility to the client application. Importantly, QuickAuth is built on the Combine framework, offering a modern approach to asynchronous programming in Swift.

## Features

- Handles OAuth2 authentication and re-authentication automatically
- Supports both data fetching and file downloading.
- Customizable logging through the application side
- Secure token handling without storing sensitive information in the library

## Installation

## Quick Start

### Setting Up Your QuickAuth

First, initialize QuickAuth in your application, typically in your AppDelegate or SceneDelegate:

```swift
QuickAuth.shared.setDataSource(dataSource: NetworkManager.shared)
QuickAuth.shared.setDelegate(delegate: NetworkManager.shared)
```
### Implementing QuickAuthDataSource and QuickAuthDelegate

Implement QuickAuthDatasourceProtocol and QuickAuthDelegate in your network manager or equivalent class to handle token management and logging:

```swift
class NetworkManager: QuickAuthDatasourceProtocol, QuickAuthDelegate {
    static let shared = NetworkManager()
    private let tokenService = TokenService()

    func getReauthRequest() throws -> Request {
        // Implement your reauth request
    }

    func getTokenService() -> any QuickAuthAccessServiceProtocol {
        return tokenService
    }

    func log(message: String) {
        // Implement logging
    }
}
```

### Making Requests

Below is an example of how IdentityRequest might be implemented. This enum includes cases for login, reauthentication, and fetching account details, showcasing how to handle both authenticated and non-authenticated requests.

```swift 
enum IdentityRequest: Request {
    case login(model: LoginDataModel)
    case reauth(model: RefreshTokenDataModel)
    case myAccount

    var host: String {
        return "https://example.com"
    }

    var path: String {
        switch self {
        case .login:
            return "/auth/o/token/"
        case .reauth:
            return "/auth/o/token/"
        case .myAccount:
            return "/my/account"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .reauth:
            return .post
        case .myAccount:
            return .get
        }
    }

    var headers: HTTPHeaders? {
        // Example: Return nil or specific headers as needed
        return nil
    }

    var body: BodyEncoder? {
        switch self {
        case .login(let model), .reauth(let model):
            return BodyEncoder(value: model)
        case .myAccount:
            return nil
        }
    }

    var contentType: ContentType {
        switch self {
        case .login, .reauth:
            return .formData
        case .myAccount:
            return .json
        }
    }

    var authorized: Bool {
        switch self {
        case .login:
            return false
        case .reauth, .myAccount:
            return true
        }
    }
}
```

Use the execute and download functions to make API requests. For example, to log in:

```swift
let loginModel = LoginDataModel(username: "user@example.com", password: "password123")
QuickAuth.shared.execute(IdentityRequest.login(model: loginModel))
    .sink(receiveCompletion: { completion in
        // Handle completion
    }, receiveValue: { response in
        // Handle successful response
    })
    .store(in: &cancellables)
```

### Future Documentation and Examples

We are continuously working to improve QuickAuth and its documentation. More detailed guides, including advanced usage, best practices, and comprehensive example projects, will be added in the future. These updates will aim to help you better understand how to integrate QuickAuth into your applications seamlessly and leverage its full potential.
