//
//  QuickAuth.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 1/27/24.
//

import Combine
import Foundation

public protocol QuickAuthProtocol {
    func execute<R: Decodable, T: Request>(_ endpoint: T) -> AnyPublisher<R, Error>
    func download<T: Request>(_ endpoint: T) -> AnyPublisher<Data, Error>
    func setDataSource(dataSource: QuickAuthDatasourceProtocol)
    func setDelegate(delegate: QuickAuthDelegate)
}

typealias Response = HTTPURLResponse
typealias ResponseError = HTTPURLResponseError

public final class QuickAuth: NSObject, URLSessionDelegate, QuickAuthProtocol {
    // MARK: Constants

    public static let shared = QuickAuth()

    // MARK: Variables

    private let queue = DispatchQueue(label: "Autenticator.\(UUID().uuidString)")
    private var refreshPublisher: AnyPublisher<QuickAuthAccessProtocol?, Error>?
    private weak var dataSource: QuickAuthDatasourceProtocol?
    private weak var delegate: QuickAuthDelegate?
    private var cancellables = Set<AnyCancellable>()
    private let logFormatter = QuickAuthLogFormatter()

    private lazy var configuration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.urlCache = URLCache.shared
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return configuration
    }()

    private lazy var session = URLSession(configuration: configuration,
                                          delegate: self,
                                          delegateQueue: nil)

    override init() {
        super.init()
    }

    public func setDataSource(dataSource: QuickAuthDatasourceProtocol) {
        self.dataSource = dataSource
    }
    
    public func setDelegate(delegate: QuickAuthDelegate) {
        self.delegate = delegate
    }

    public func execute<R: Decodable, T: Request>(_ endpoint: T) -> AnyPublisher<R, Error> {
        do {
            try stopExecutionForUnitTests()
            if endpoint.authorized {
                return getTokenOrRefresh(force: false)
                    .tryMap { token -> URLRequest in
                        try endpoint.getRequest(token: token)
                    }
                    .flatMap { [weak self] request in
                        self?.publisher(for: request) ?? Fail(error: NetworkError.selfNotFound).eraseToAnyPublisher()
                    }
                    .handleEvents(receiveCompletion: { [weak self] _ in
                        self?.queue.sync {
                            self?.refreshPublisher = nil
                        }
                    })
                    .eraseToAnyPublisher()
            } else {
                let request = try endpoint.getRequest()
                return publisher(for: request)
                    .eraseToAnyPublisher()
            }
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    public func download<T: Request>(_ endpoint: T) -> AnyPublisher<Data, Error> {
        do {
            try stopExecutionForUnitTests()
            if endpoint.authorized {
                return getTokenOrRefresh(force: false)
                    .tryMap { token -> URLRequest in
                        try endpoint.getRequest(token: token)
                    }
                    .flatMap { [weak self] request in
                        self?.downloadPublisher(for: request) ?? Fail(error: NetworkError.selfNotFound)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            } else {
                let request = try endpoint.getRequest()
                return downloadPublisher(for: request)
                    .eraseToAnyPublisher()
            }
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func downloadPublisher(for request: URLRequest) -> AnyPublisher<Data, Error> {
        willSendRequest(request: request)

        return session.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                error.isNoInternetConnectionError ? NetworkError.noInternetConnection : error
            }
            .tryMap { [weak self] result in
                guard let self = self,
                      let response = result.response as? Response else {
                    throw ResponseError(status: .unableToDecode)
                }

                self.didReceiveResponse(result, for: request)

                if response.statusCode != 200 {
                    throw ResponseError(status: .badRequest)
                }

                return result.data
            }
            .retry(2)
            .eraseToAnyPublisher()
    }

    private func publisher<R: Decodable>(for request: URLRequest) -> AnyPublisher<R, Error> {
        willSendRequest(request: request)

        return session.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                error.isNoInternetConnectionError ? NetworkError.noInternetConnection : error
            }
            .tryMap { [weak self] result in
                guard let self = self,
                      let response = result.response as? Response else {
                    throw ResponseError(status: .unableToDecode)
                }

                self.didReceiveResponse(result, for: request)

                try self.errorHandling(response: response, output: result)

                var data = result.data

                if R.Type.self == Bool.Type.self {
                    let status = response.status == .success
                    data = Data(status.string.utf8)
                }

                do {
                    return try JSONDecoder().decode(R.self, from: data)
                } catch {
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

    private func stopExecutionForUnitTests() throws {
        #if DEBUG
            let isUnitTest = ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
            if isUnitTest {
                fatalError("API Call during unit testing!!")
            }
        #endif
    }

    func willSendRequest(request: URLRequest) {
        delegate?.log(message: logFormatter.formatRequest(request))
    }

    func didReceiveResponse(_ response: QuickAuthLogFormatter.NetworkResponse, for request: URLRequest) {
        delegate?.log(message: logFormatter.formatResponse(response, for: request))
    }

    public func urlSession(_: URLSession,
                    didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return (URLSession.AuthChallengeDisposition.useCredential,
                URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

extension QuickAuth {
    private func getTokenOrRefresh(force: Bool) -> AnyPublisher<QuickAuthAccessProtocol?, Error> {
        return queue.sync { [weak self] in
            guard let self else { return Fail(error: NetworkError.selfNotFound).eraseToAnyPublisher() }
            if let publisher = self.refreshPublisher {
                return publisher
            }

            guard let tokenService = self.dataSource?.getTokenService(),
                  let token = try? tokenService.getToken() else {
                return Fail(error: NetworkError.noDataSource).eraseToAnyPublisher()
            }

            if token.isExpired || force {
                let publisher = self.refresh()
                    .share()
                    .map { $0 as QuickAuthAccessProtocol? }
                    .eraseToAnyPublisher()
                self.refreshPublisher = publisher
                return publisher
            } else {
                return Just(token)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
    }

    private func refresh() -> AnyPublisher<QuickAuthAccessProtocol?, Error> {
        guard let endpoint = try? dataSource?.getReauthRequest() else {
            return Fail(error: NetworkError.refreshRequestNotFound).eraseToAnyPublisher()
        }

        guard let request = try? endpoint.getRequest(),
              let tokenService = dataSource?.getTokenService() else {
            return Fail(error: NetworkError.noDataSource).eraseToAnyPublisher()
        }

        typealias Response = HTTPURLResponse
        typealias ResponseError = HTTPURLResponseError

        willSendRequest(request: request)

        return session.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                error.isNoInternetConnectionError ? NetworkError.noInternetConnection : error
            }
            .tryMap { [weak self] result in
                guard let self = self,
                      let response = result.response as? Response else {
                    throw ResponseError(status: .unableToDecode)
                }

                self.didReceiveResponse(result, for: request)

                if response.status != .success {
                    if let error = try? JSONDecoder().decode(ResponseError.self, from: result.data) {
                        throw error
                    }
                    throw ResponseError(status: response.status)
                }
                do {
                    var token = try tokenService.decode(data: result.data)
                    token.setCreatedDate()
                    try tokenService.save(token: token)
                    return token
                } catch {
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

    private func errorHandling(response: Response, output: URLSession.DataTaskPublisher.Output) throws {
        switch response.status {
        case .success, .redirect:
            return
        case .unauthorized:
            throw NetworkError.unauthorized
        default:
            if let error = try? JSONDecoder().decode(ResponseError.self, from: output.data) {
                throw error
            }
            throw ResponseError(status: response.status)
        }
    }
}
