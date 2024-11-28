//
//  RealtimeInputAudioBufferAppend.swift
//  
//
//  Created by Lou Zell on 10/30/24.
//

import Foundation

public struct RealtimeInputAudioBufferAppend: Encodable {
    public let type = "input_audio_buffer.append"

    /// base64 encoded PCM16 data
    public let audio: String
}
