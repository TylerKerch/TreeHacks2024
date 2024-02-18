//
//  WebSocket.swift
//  frontend
//
//  Created by Sarvesh Phoenix on 2/17/24.
//

import Foundation
import Starscream

class ClientSocket: WebSocketDelegate {
    
    var socket: WebSocket!
    var screenPainter: ScreenPainter!
    var textSpeaker: TextSpeaker!
    
    init(painter: ScreenPainter, speaker: TextSpeaker) {
        screenPainter = painter
        textSpeaker = speaker
    }
    
    struct UIBoxesRequest: Encodable {
        let imageBase64: String
        let query: String

        enum CodingKeys: String, CodingKey {
            case imageBase64 = "image"
        }
    }
    struct UIBoxesResponse: Decodable {
        let boundingBoxes: [BoundingBox]
            
        enum CodingKeys: String, CodingKey {
            case boundingBoxes = "boxes"
        }
        
        struct BoundingBox: Decodable {
            let x: Int
            let y: Int
            let width: Int
            let height: Int
            let text: String
        }
    }
    
    struct ImageDescriptionRequest: Encodable {
        
    }
    
    init() {
        var request = URLRequest(url: URL(string: "http://localhost:8080")!) // Switch to ws potentially
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
        
            print("Received text: \(string)")
            if let data = string.data(using: .utf8) {
                do {
                    let response = try JSONDecoder().decode(UIBoxesResponse.self, from: data)
                    var i = 1
                    for box in response.boundingBoxes {
                        screenPainter.addOverlay(x: box.x, y: box.y, height: box.height, width: box.width, number: i, caption: box.text)
                        i += 1
                    }
                    
                    textSpeaker.readText(s: "You have \(response.boundingBoxes.count) options.")
                    for box in response.boundingBoxes {
                        textSpeaker.readText(s: box.text)
                    }
                } catch {
                    print("Error parsing UIBoxesResponse: \(error)")
                }
            }
        
        case .binary(let data):
            print("Received data: \(data)")
        case .ping(_), .pong(_), .viabilityChanged(_), .reconnectSuggested(_), .cancelled:
            break
        case .error(let error):
            handleError(error)
        default:
            break
        }
    }
    
    func sendUIBoxesRequest(imageBase64: String, query: String) {
        let request = UIBoxesRequest(imageBase64: imageBase64, query: query)
        do {
            let requestData = try JSONEncoder().encode(request)
            let requestString = String(data: requestData, encoding: .utf8)!
            socket.write(string: requestString)
        } catch {
            print("Error encoding UIBoxesRequest: \(error)")
        }
    }
    
    func handleError(_ error: Error?) {
        if let e = error {
            print("WebSocket encountered an error: \(e)")
        }
    }
    
}
