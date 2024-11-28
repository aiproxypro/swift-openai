//
//  RealtimeSession.swift
//
//
//  Created by Lou Zell on 11/28/24.
//

import Foundation

private var kMicrophoneSampleVendor: MicrophoneSampleVendor?

@RealtimeActor
public class RealtimeSession {
    var disconnected = false
    var receivedSessionUpdated = false
    let webSocketTask: URLSessionWebSocketTask

    init(webSocketTask: URLSessionWebSocketTask) {
        self.webSocketTask = webSocketTask
    }

    func connect(usingConfiguration configuration: RealtimeSessionUpdate.SessionConfiguration) async throws {
        self.webSocketTask.resume()
        try await self.send(RealtimeSessionUpdate(session: configuration))
    }

    /// Disconnect is exposed as a public method to allow users of the library to close the ws connection.
    public func disconnect() {
        self.webSocketTask.cancel()
        self.disconnected = true
        InternalAudioPlayer.interruptPlayback()
    }


    func send(_ encodable: Encodable) async throws {
        let messageData = URLSessionWebSocketTask.Message.data(try encodable.serialize())
        try await self.webSocketTask.send(messageData)
    }

    func receiveMessage() {
        self.webSocketTask.receive { result in
            switch result {
            case .failure(let error as NSError):
                self.didReceiveWebSocketError(error)
            case .success(let message):
                self.didReceiveWebSocketMessage(message)
            }
        }
    }

    func startSendingAudio() throws {
        kMicrophoneSampleVendor = try MicrophoneSampleVendor()
        kMicrophoneSampleVendor?.start(onSample: { sampleBuffer in
            guard !self.disconnected else {
                kMicrophoneSampleVendor?.stop()
                return
            }
            guard self.receivedSessionUpdated else {
                return
            }
            do {
                if let audioData = AudioUtils.base64EncodedPCMData(from: sampleBuffer) {
                    try await self.send(RealtimeInputAudioBufferAppend(audio: audioData))
                }
            } catch {
                aiproxyLogger.warning("Could not send PCM16 audio data to openai")
            }
        })
    }

    private func didReceiveWebSocketError(_ error: NSError) {
        if (error.code == 57) {
            aiproxyLogger.info("Received ws disconnect")
            self.disconnect()
        } else {
            aiproxyLogger.error("Received ws error: \(error.localizedDescription)")
        }
    }

    private func didReceiveWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        let callCommonReceiveHandler: (Data) -> Void = { data in
            do {
                try self.commonReceiveHandler(data)
            } catch {
                aiproxyLogger.error("Could not exec commonRecieveHandler: \(error.localizedDescription)")
            }
        }
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8) {
                callCommonReceiveHandler(data)
            }
        case .data(let data):
            callCommonReceiveHandler(data)
        @unknown default:
            aiproxyLogger.warning("Received an unknown websocket message format")
        }
    }

    private func commonReceiveHandler(_ data: Data) throws {
        let deserialized = try JSONSerialization.jsonObject(with: data)
        guard let json = deserialized as? [String: Any] else {
            throw AIProxyError.assertion("Could not convert realtime response into generic dict")
        }

        guard let messageType = json["type"] as? String else {
            throw AIProxyError.assertion("Could not get received realtime message type")
        }
        print("Received: \(messageType)")

        switch messageType {
        case "response.audio.delta":
            if let b64Str = json["delta"] as? String {
                InternalAudioPlayer.playPCM16Audio(from: b64Str)
            }
        case "session.updated":
            self.receivedSessionUpdated = true
        case "input_audio_buffer.speech_started":
            InternalAudioPlayer.interruptPlayback()
        default:
            break
        }

        if messageType == "error" {
            let errorBody = String(describing: json["error"] as? [String: Any])
            print("Received error from websocket: \(errorBody)")
            self.disconnect()
        } else {
            if !self.disconnected {
                self.receiveMessage()
            }
        }
    }
}
