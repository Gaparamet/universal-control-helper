import Foundation
import Network
import os
import UniversalControlCore

private let netLog = Logger(subsystem: "co.409.uch", category: "net")

protocol RelayTransport: AnyObject {
    var statusDidChange: ((ConnectionStatus) -> Void)? { get set }
    func start()
    func stop()
}

/// TCP parameters with keepalive so half-open connections (sleep, Wi-Fi change)
/// are detected within roughly idle + interval * count seconds.
private func makeRelayParameters(connectionTimeout: Int? = nil) -> NWParameters {
    let tcp = NWProtocolTCP.Options()
    tcp.enableKeepalive = true
    tcp.keepaliveIdle = 5
    tcp.keepaliveInterval = 2
    tcp.keepaliveCount = 3
    tcp.noDelay = true
    if let connectionTimeout {
        tcp.connectionTimeout = connectionTimeout
    }
    return NWParameters(tls: nil, tcp: tcp)
}

/// Thread-safe run generation. `start()`/`stop()` bump it synchronously on the
/// caller's thread so that work already queued for an older generation (status
/// reports, retries, handlers) is dropped even before teardown runs on `queue`.
private final class GenerationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func bump() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }

    func isCurrent(_ generation: Int?) -> Bool {
        guard let generation else { return false }
        lock.lock()
        defer { lock.unlock() }
        return value == generation
    }
}

final class SourceClient: RelayTransport {
    var statusDidChange: ((ConnectionStatus) -> Void)?
    var authenticationDidComplete: ((Int) -> Void)?

    private static let authTimeout: TimeInterval = 3
    private static let initialRetryDelay: TimeInterval = 1
    private static let maximumRetryDelay: TimeInterval = 5
    private static let rejectionsBeforeMismatch = 2

    private let queue = DispatchQueue(label: "io.yoonsungji.universalcontrolhelper.source-network")
    private let tokenProvider: () -> String
    private let generations = GenerationCounter()

    // All state below is confined to `queue`.
    private var runningGeneration: Int?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var framer = LineFramer()
    private var authenticated = false
    private var peerProtocolVersion = 1
    private var availableEndpoints: [NWEndpoint] = []
    private var endpointIndex = 0
    private var retryDelay = SourceClient.initialRetryDelay
    private var retryWorkItem: DispatchWorkItem?
    private var authTimeoutWorkItem: DispatchWorkItem?
    /// Per-attempt flags.
    private var helloSent = false
    private var cancelledLocally = false
    private var attemptErrorReported = false
    /// Attempts in a row where the peer closed after `hello` and before `helloAck`.
    private var consecutivePeerRejections = 0

    init(tokenProvider: @escaping () -> String) {
        self.tokenProvider = tokenProvider
    }

    func start() {
        let generation = generations.bump()
        queue.async { [self] in
            tearDown()
            guard generations.isCurrent(generation) else { return }
            runningGeneration = generation
            beginBrowsing()
        }
    }

    func stop() {
        _ = generations.bump()
        queue.async { [self] in tearDown() }
    }

    func synchronizeInputSource(_ inputSource: InputSourceState) {
        queue.async { [weak self] in
            guard let self, self.isRunning, self.authenticated, let connection = self.connection else { return }
            // Legacy peers already receive the physical Caps Lock toggle. Sending the
            // observed state as another legacy toggle would cancel the first one.
            guard RelayProtocol.supportsExplicitInputSourceState(self.peerProtocolVersion) else {
                return
            }
            self.send(.setInputSource(inputSource, token: self.tokenProvider()), over: connection)
        }
    }

    func toggleInputSource() {
        queue.async { [weak self] in
            guard let self, self.isRunning, self.authenticated, let connection = self.connection else { return }
            self.send(.toggleInputSource(token: self.tokenProvider()), over: connection)
        }
    }

    // MARK: - Queue-confined implementation

    private var isRunning: Bool {
        generations.isCurrent(runningGeneration)
    }

    private func tearDown() {
        if runningGeneration != nil {
            netLog.notice("source: stopping")
        }
        runningGeneration = nil
        retryWorkItem?.cancel()
        retryWorkItem = nil
        authTimeoutWorkItem?.cancel()
        authTimeoutWorkItem = nil
        browser?.cancel()
        browser = nil
        let oldConnection = connection
        connection = nil
        oldConnection?.cancel()
        authenticated = false
        peerProtocolVersion = 1
        framer = LineFramer()
        availableEndpoints = []
        endpointIndex = 0
        retryDelay = Self.initialRetryDelay
        helloSent = false
        cancelledLocally = false
        attemptErrorReported = false
        consecutivePeerRejections = 0
    }

    private func beginBrowsing() {
        netLog.notice("source: starting browser")
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_uniinputfix._tcp", domain: nil)
        let browser = NWBrowser(for: descriptor, using: .tcp)
        browser.stateUpdateHandler = { [weak self, weak browser] state in
            guard let self, let browser, self.isRunning, self.browser === browser else { return }
            netLog.notice("source: browser state \(String(describing: state), privacy: .public)")
            switch state {
            case .ready:
                self.report(.searchingTarget)
            case .waiting(let error):
                // Typically Local Network permission denied; keep the browser alive so it
                // recovers on its own once permission is granted.
                self.report(.searchError(error.localizedDescription))
            case .failed(let error):
                self.report(.searchError(error.localizedDescription))
            case .cancelled:
                break
            default:
                break
            }
        }
        browser.browseResultsChangedHandler = { [weak self, weak browser] results, _ in
            guard let self, let browser, self.isRunning, self.browser === browser else { return }
            self.availableEndpoints = results.map(\.endpoint)
            self.endpointIndex = 0
            self.retryDelay = Self.initialRetryDelay
            netLog.notice("source: browse results changed, \(self.availableEndpoints.count, privacy: .public) endpoint(s)")
            self.connectIfNeeded()
        }
        self.browser = browser
        browser.start(queue: queue)
    }

    private var showsStickyMismatch: Bool {
        consecutivePeerRejections >= Self.rejectionsBeforeMismatch
    }

    private func connect(to endpoint: NWEndpoint) {
        helloSent = false
        cancelledLocally = false
        attemptErrorReported = false
        netLog.notice("source: connecting to \(endpoint.debugDescription, privacy: .public) (index \(self.endpointIndex, privacy: .public) of \(self.availableEndpoints.count, privacy: .public))")
        if !showsStickyMismatch {
            report(.connectingTarget)
        }
        let connection = NWConnection(to: endpoint, using: makeRelayParameters(connectionTimeout: 5))
        self.connection = connection
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection, self.isRunning, self.connection === connection else { return }
            netLog.notice("source: connection state \(String(describing: state), privacy: .public)")
            switch state {
            case .ready:
                if !self.showsStickyMismatch {
                    self.report(.authenticating)
                }
                self.send(.hello(token: self.tokenProvider()), over: connection)
                self.helloSent = true
                self.scheduleAuthTimeout(for: connection)
                self.receive(on: connection)
            case .waiting(let error):
                // Without this the connection would sit in .waiting forever and,
                // because `connection != nil`, no further attempt would be made.
                self.report(.connectionError(error.localizedDescription))
                self.attemptErrorReported = true
                self.cancelledLocally = true
                connection.cancel()
            case .failed(let error):
                self.report(.connectionError(error.localizedDescription))
                self.attemptErrorReported = true
                self.disconnect(connection)
            case .cancelled:
                self.disconnect(connection)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func scheduleAuthTimeout(for connection: NWConnection) {
        authTimeoutWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self, weak connection] in
            guard let self, let connection, self.isRunning,
                  self.connection === connection, !self.authenticated else { return }
            netLog.notice("source: auth timeout, no helloAck within \(Self.authTimeout, privacy: .public)s; cancelling")
            self.cancelledLocally = true
            connection.cancel()
        }
        authTimeoutWorkItem = item
        queue.asyncAfter(deadline: .now() + Self.authTimeout, execute: item)
    }

    private func connectIfNeeded() {
        guard isRunning, connection == nil, !availableEndpoints.isEmpty else { return }
        retryWorkItem?.cancel()
        retryWorkItem = nil
        if endpointIndex >= availableEndpoints.count {
            endpointIndex = 0
        }
        connect(to: availableEndpoints[endpointIndex])
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16 * 1024) { [weak self, weak connection] data, _, complete, error in
            guard let self, let connection, self.isRunning, self.connection === connection else { return }
            if let data, !data.isEmpty {
                do {
                    for frame in try self.framer.append(data) {
                        let message = try RelayCodec.decode(frame)
                        if message.kind == .helloAck, message.token == self.tokenProvider() {
                            self.didAuthenticate(protocolVersion: message.protocolVersion ?? 1)
                        }
                    }
                } catch {
                    netLog.notice("source: invalid response, cancelling connection")
                    self.report(.invalidResponse)
                    self.attemptErrorReported = true
                    self.cancelledLocally = true
                    connection.cancel()
                    return
                }
            }
            if complete || error != nil {
                let peerRejected = self.helloSent && !self.authenticated && !self.cancelledLocally
                netLog.notice("source: connection closed (complete: \(complete, privacy: .public), error: \(error?.localizedDescription ?? "none", privacy: .public), closedBeforeAck: \(peerRejected, privacy: .public))")
                self.disconnect(connection, peerClosedBeforeAck: peerRejected)
                return
            }
            self.receive(on: connection)
        }
    }

    private func didAuthenticate(protocolVersion: Int) {
        guard !authenticated else { return }
        authenticated = true
        peerProtocolVersion = protocolVersion
        consecutivePeerRejections = 0
        retryDelay = Self.initialRetryDelay
        authTimeoutWorkItem?.cancel()
        authTimeoutWorkItem = nil
        netLog.notice("source: authenticated, peer protocol v\(protocolVersion, privacy: .public)")
        report(.connectedSyncing)
        let generation = runningGeneration
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generations.isCurrent(generation) else { return }
            self.authenticationDidComplete?(protocolVersion)
        }
    }

    private func send(_ message: RelayMessage, over connection: NWConnection) {
        guard let data = try? RelayCodec.encodeLine(message) else { return }
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            guard let self, let error, self.isRunning else { return }
            self.report(.sendError(error.localizedDescription))
        })
    }

    private func disconnect(_ candidate: NWConnection, peerClosedBeforeAck: Bool = false) {
        guard connection === candidate else { return }
        authTimeoutWorkItem?.cancel()
        authTimeoutWorkItem = nil
        let wasAuthenticated = authenticated
        connection = nil
        candidate.cancel()
        authenticated = false
        peerProtocolVersion = 1
        framer = LineFramer()
        guard isRunning else { return }

        if peerClosedBeforeAck {
            consecutivePeerRejections += 1
        } else if !wasAuthenticated {
            consecutivePeerRejections = 0
        }

        if showsStickyMismatch {
            netLog.notice("source: peer closed before helloAck \(self.consecutivePeerRejections, privacy: .public) times in a row; reporting pairing code mismatch")
            report(.pairingCodeMismatch)
        } else if !attemptErrorReported {
            report(.disconnectedSearching)
        }

        if !wasAuthenticated, !availableEndpoints.isEmpty {
            endpointIndex = (endpointIndex + 1) % availableEndpoints.count
        }
        scheduleRetry()
    }

    private func scheduleRetry() {
        retryWorkItem?.cancel()
        let delay = retryDelay
        retryDelay = min(retryDelay * 2, Self.maximumRetryDelay)
        let nextEndpoint = availableEndpoints.isEmpty
            ? "none"
            : availableEndpoints[endpointIndex % availableEndpoints.count].debugDescription
        netLog.notice("source: retrying in \(delay, privacy: .public)s with endpoint \(nextEndpoint, privacy: .public)")
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.isRunning else { return }
            self.retryWorkItem = nil
            self.connectIfNeeded()
        }
        retryWorkItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func report(_ status: ConnectionStatus) {
        let generation = runningGeneration
        guard generations.isCurrent(generation) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generations.isCurrent(generation) else { return }
            self.statusDidChange?(status)
        }
    }
}

final class TargetServer: RelayTransport {
    var statusDidChange: ((ConnectionStatus) -> Void)?
    var messageReceived: ((RelayMessage) -> Void)?

    private let queue = DispatchQueue(label: "io.yoonsungji.universalcontrolhelper.target-network")
    private let tokenProvider: () -> String
    private let generations = GenerationCounter()

    // All state below is confined to `queue`.
    private var runningGeneration: Int?
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private var framers: [ObjectIdentifier: LineFramer] = [:]
    private var authenticatedConnections: Set<ObjectIdentifier> = []
    /// Connections this server rejected itself; their teardown must not overwrite
    /// the rejection status with `.disconnectedWaiting`.
    private var rejectedConnections: Set<ObjectIdentifier> = []

    init(tokenProvider: @escaping () -> String) {
        self.tokenProvider = tokenProvider
    }

    func start() {
        let generation = generations.bump()
        queue.async { [self] in
            tearDown()
            guard generations.isCurrent(generation) else { return }
            runningGeneration = generation
            beginListening()
        }
    }

    func stop() {
        _ = generations.bump()
        queue.async { [self] in tearDown() }
    }

    // MARK: - Queue-confined implementation

    private var isRunning: Bool {
        generations.isCurrent(runningGeneration)
    }

    private func tearDown() {
        if runningGeneration != nil {
            netLog.notice("target: stopping")
        }
        runningGeneration = nil
        listener?.cancel()
        listener = nil
        let oldConnections = Array(connections.values)
        connections.removeAll()
        framers.removeAll()
        authenticatedConnections.removeAll()
        rejectedConnections.removeAll()
        oldConnections.forEach { $0.cancel() }
    }

    private func beginListening() {
        do {
            let listener = try NWListener(using: makeRelayParameters(), on: .any)
            listener.service = NWListener.Service(
                name: Host.current().localizedName ?? "Universal Control Helper",
                type: "_uniinputfix._tcp"
            )
            listener.stateUpdateHandler = { [weak self, weak listener] state in
                guard let self, let listener, self.isRunning, self.listener === listener else { return }
                netLog.notice("target: listener state \(String(describing: state), privacy: .public)")
                switch state {
                case .ready:
                    self.report(.readyWaitingForSource)
                case .waiting(let error):
                    self.report(.listenError(error.localizedDescription))
                case .failed(let error):
                    self.report(.listenError(error.localizedDescription))
                case .cancelled:
                    break
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                guard let self, self.isRunning else {
                    connection.cancel()
                    return
                }
                self.accept(connection)
            }
            self.listener = listener
            netLog.notice("target: starting listener")
            listener.start(queue: queue)
        } catch {
            netLog.notice("target: listener creation failed: \(error.localizedDescription, privacy: .public)")
            report(.listenError(error.localizedDescription))
        }
    }

    private func accept(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        connections[id] = connection
        framers[id] = LineFramer()
        netLog.notice("target: accepted connection from \(connection.endpoint.debugDescription, privacy: .public)")
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection, self.isRunning,
                  self.connections[ObjectIdentifier(connection)] === connection else { return }
            netLog.notice("target: connection state \(String(describing: state), privacy: .public)")
            switch state {
            case .ready:
                if self.authenticatedConnections.isEmpty {
                    self.report(.sourceConnectedAwaitingAuth)
                }
                self.receive(on: connection)
            case .waiting:
                connection.cancel()
            case .failed, .cancelled:
                self.remove(connection)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func reject(_ connection: NWConnection, status: ConnectionStatus, reason: String) {
        let id = ObjectIdentifier(connection)
        rejectedConnections.insert(id)
        authenticatedConnections.remove(id)
        netLog.notice("target: rejecting connection: \(reason, privacy: .public)")
        report(status)
        connection.cancel()
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16 * 1024) { [weak self, weak connection] data, _, complete, error in
            guard let self, let connection, self.isRunning else { return }
            let id = ObjectIdentifier(connection)
            guard self.connections[id] === connection, !self.rejectedConnections.contains(id) else { return }
            if let data, !data.isEmpty {
                do {
                    var framer = self.framers[id] ?? LineFramer()
                    let frames = try framer.append(data)
                    self.framers[id] = framer
                    for frame in frames {
                        let message = try RelayCodec.decode(frame)
                        guard message.token == self.tokenProvider() else {
                            self.reject(connection, status: .pairingCodeMismatch, reason: "pairing code mismatch")
                            return
                        }
                        if message.kind == .hello {
                            self.authenticatedConnections.insert(id)
                            self.send(.helloAck(token: self.tokenProvider()), over: connection)
                            netLog.notice("target: source authenticated")
                            self.report(.connectedSyncing)
                        } else {
                            guard self.authenticatedConnections.contains(id) else {
                                self.reject(connection, status: .blockedUnauthenticated, reason: "message before hello")
                                return
                            }
                            DispatchQueue.main.async { [weak self] in self?.messageReceived?(message) }
                        }
                    }
                } catch {
                    self.reject(connection, status: .blockedInvalidData, reason: "invalid data")
                    return
                }
            }
            if complete || error != nil {
                netLog.notice("target: connection closed (complete: \(complete, privacy: .public), error: \(error?.localizedDescription ?? "none", privacy: .public))")
                self.remove(connection)
                return
            }
            self.receive(on: connection)
        }
    }

    private func send(_ message: RelayMessage, over connection: NWConnection) {
        guard let data = try? RelayCodec.encodeLine(message) else { return }
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    private func remove(_ connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        guard connections[id] === connection else { return }
        connections.removeValue(forKey: id)
        framers.removeValue(forKey: id)
        authenticatedConnections.remove(id)
        let wasRejected = rejectedConnections.remove(id) != nil
        connection.cancel()
        guard isRunning, !wasRejected else { return }
        if authenticatedConnections.isEmpty {
            report(.disconnectedWaiting)
        } else {
            report(.connectedSyncing)
        }
    }

    private func report(_ status: ConnectionStatus) {
        let generation = runningGeneration
        guard generations.isCurrent(generation) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generations.isCurrent(generation) else { return }
            self.statusDidChange?(status)
        }
    }
}
