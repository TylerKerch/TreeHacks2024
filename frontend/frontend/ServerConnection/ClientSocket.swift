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
    
    init() {
        var request = URLRequest(url: URL(string: "ws://localhost:8080")!)
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
            guard let data = string.data(using: .utf8) else { return }
            do {
                let genericResponse = try JSONDecoder().decode(SocketModels.GenericResponse.self, from: data)
                switch genericResponse.type {
                case "CLEAR":
                    let clearResponse = try JSONDecoder().decode(SocketModels.ClearBoxesResponse.self, from: data)
                    screenPainter.clearHighlights()
                case "DRAW":
                    let drawResponse = try JSONDecoder().decode(SocketModels.DrawBoxesResponse.self, from: data)
                    var i = 1
                    for box in drawResponse.boundingBoxes {
                        screenPainter.addOverlay(x: box.x, y: box.y, height: box.height, width: box.width, number: i, caption: box.text)
                        i += 1
                    }
                case "SPEAK":
                    let speakResponse = try JSONDecoder().decode(SocketModels.TextSpeechResponse.self, from: data)
                    textSpeaker.readText(s: speakResponse.message)
                default:
                    print("Unknown type")
                }
            } catch {
                print("Error decoding JSON: \(error)")
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
    
    func sendScreenshotRequest(image: String) {
        let request = SocketModels.ScreenshotRequest(type: "IMAGE", image: image)
        do {
            let requestData = try JSONEncoder().encode(request)
            let requestString = String(data: requestData, encoding: .utf8)!
            if(socket != nil) {
                socket.write(string: requestString)
            } else {
                print("Socket hasn't been constructed properly")
            }
        } catch {
            print("Error encoding QueryRequest: \(error)")
        }
    }
    
    func sendQueryRequest(query: String) {
        let request = SocketModels.QueryRequest(type: "QUERY", query: query)
        do {
            let requestData = try JSONEncoder().encode(request)
            let requestString = String(data: requestData, encoding: .utf8)!
            if(socket != nil) {
                socket.write(string: requestString)
            } else {
                print("Socket hasn't been constructed properly")
            }
        } catch {
            print("Error encoding QueryRequest: \(error)")
        }
    }
    
    func handleError(_ error: Error?) {
        if let e = error {
            print("WebSocket encountered an error: \(e)")
        }
    }
    
}
