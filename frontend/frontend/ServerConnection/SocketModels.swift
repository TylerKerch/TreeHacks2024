//
//  SocketModels.swift
//  frontend
//
//  Created by Sarvesh Phoenix on 2/17/24.
//

import Foundation

class SocketModels {
    
    // REQUESTS
    
    struct ScreenshotRequest: Encodable {
        let type: String
        let image: String

        enum CodingKeys: String, CodingKey {
            case type = "type"
            case image = "payload"
        }
    }
    
    struct QueryRequest: Encodable {
        let type: String
        let query: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case query = "payload"
        }
    }
    
    // RESPONSES
    
    struct GenericResponse: Decodable {
        let type: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
        }
    }
    
    struct ClearBoxesResponse: Decodable {
        let type: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
        }
    }
    
    struct DrawBoxesResponse: Decodable {
        let type: String
        let boundingBoxes: [BoundingBox]
            
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case boundingBoxes = "boxes"
        }
        
        struct BoundingBox: Decodable {
            let type: String
            let x: Int
            let y: Int
            let width: Int
            let height: Int
            let text: String
        }
    }
    
    struct TextSpeechResponse: Decodable {
        let type: String
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case message = "message"
        }
    }
    
}
