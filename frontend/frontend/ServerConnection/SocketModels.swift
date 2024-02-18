//
//  SocketModels.swift
//  frontend
//
//  Created by Sarvesh Phoenix on 2/17/24.
//

import Foundation

class SocketModels {
    
    // REQUESTS
    
    struct ClientPacket: Encodable {
        let type: String
        let payload: String

        enum CodingKeys: String, CodingKey {
            case type = "type"
            case payload = "payload"
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
    
    struct SelectedBoundingBox: Decodable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let type: String
        let detection_id: String
        let similarity: Double
        let text: String
    }
    
    struct GeneralBoundingBox: Decodable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let type: String
        let detection_id: String
    }

    struct SelectBoxResponse: Decodable {
        let type: String
        let payload: SelectedBoundingBox
        
        enum CodingKeys: String, CodingKey {
            case type
            case payload
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            
            let payloadString = try container.decode(String.self, forKey: .payload)
            guard let payloadData = payloadString.data(using: .utf8) else {
                throw DecodingError.dataCorruptedError(forKey: .payload, in: container, debugDescription: "Payload string could not be converted to Data")
            }
            
            payload = try JSONDecoder().decode(SelectedBoundingBox.self, from: payloadData)
        }
    }
    
    struct StoreBoxesResponse: Decodable {
        let type: String
        let payload: [GeneralBoundingBox]

        enum CodingKeys: String, CodingKey {
            case type
            case payload
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)

            // Decode the payload string
            let payloadString = try container.decode(String.self, forKey: .payload)
            guard let payloadData = payloadString.data(using: .utf8) else {
                throw DecodingError.dataCorruptedError(forKey: .payload, in: container, debugDescription: "Payload string could not be converted to Data")
            }

            // Decode the Data into an array of GeneralBoundingBox
            payload = try JSONDecoder().decode([GeneralBoundingBox].self, from: payloadData)
        }
    }
    
    struct TextSpeechResponse: Decodable {
        let type: String
        let payload: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case payload = "payload"
        }
    }
    
}
