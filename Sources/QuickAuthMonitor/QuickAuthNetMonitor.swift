//
//  QuickAuthNetMonitor.swift
//  QuickAuth
//
//  Created by Mirsad Arslanovic on 2/25/24.
//

import Combine
import Foundation
import Network

public protocol QuickAuthNetMonitorProtocol {
    var isConnected: PassthroughSubject<Bool, Never> { get }
}

public class QuickAuthNetMonitor: QuickAuthNetMonitorProtocol {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.QuickAuth.network-monitor")
    public var isConnected: PassthroughSubject<Bool, Never> = .init()

    public init() {
        setupObservers()
    }

    private func setupObservers() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected.send(path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}
