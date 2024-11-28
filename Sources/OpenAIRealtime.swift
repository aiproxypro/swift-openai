//
//  OpenAIRealtime.swift
//
//
//  Created by Lou Zell on 11/27/24.
//

import Foundation

open class OpenAIRealtime {

    /// This is the entrypoint that we expect customers to use.
    public static func aiproxyService(
        partialKey: String,
        serviceURL: String?,
        clientID: String? = nil
    ) -> OpenAIRealtime {
        return OpenAIRealtime(
            partialKey: partialKey,
            serviceURL: serviceURL,
            clientID: clientID
        )
    }

    private let partialKey: String
    private let serviceURL: String?
    private let clientID: String?

    init(
        partialKey: String,
        serviceURL: String?,
        clientID: String?
    ) {
        self.partialKey = partialKey
        self.serviceURL = serviceURL
        self.clientID = clientID
    }

    @RealtimeActor
    public func startRealtimeSession(
        _ sessionConfiguration: RealtimeSessionUpdate.SessionConfiguration,
        firstSpeaker: RealtimeSpeaker = .ai
    ) async throws -> RealtimeSession {

        let request = try await AIProxyURLRequest.createWS(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL!,
            proxyPath: "/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01",
            clientID: self.clientID
        )

        let urlSession = AIProxyURLSession.create()
        let webSocketTask = urlSession.webSocketTask(with: request)
        let rtSession = RealtimeSession(webSocketTask: webSocketTask)
        try await rtSession.connect(usingConfiguration: sessionConfiguration)

        if (firstSpeaker == .ai) {
            try await rtSession.send(RealtimeResponseCreate())
        }
        try rtSession.startSendingAudio()

        Task {
            rtSession.receiveMessage()
        }
        return rtSession
    }
}
