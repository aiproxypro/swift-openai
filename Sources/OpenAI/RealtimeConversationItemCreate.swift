//
//  RealtimeConversationItemCreate.swift
//
//
//  Created by Lou Zell on 10/12/24.
//

import Foundation

public struct RealtimeConversationItemCreate: Encodable {
    public let type = "conversation.item.create"
    public let item: Item
}

// MARK: - ConversationItemCreate.Item
public extension RealtimeConversationItemCreate {
    struct Item: Encodable {
        let type = "message"
        let role: String
        let content: [Content]
    }
}

// MARK: - ConversationItemCreate.Item.Content
public extension RealtimeConversationItemCreate.Item {
    struct Content: Encodable {
        let type = "input_text"
        let text: String
    }
}
