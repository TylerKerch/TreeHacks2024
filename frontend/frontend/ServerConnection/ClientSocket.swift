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
        setupSocket()
    }
    
    func setupSocket() {
        var request = URLRequest(url: URL(string: "ws://localhost:8080/ws")!)
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
                print(genericResponse.type)
                switch genericResponse.type {
                case "CLEAR":
                    // RECEIVED A JSON MESSAGE TO CLEAR BOXES
                    print("CLEAR BOXES")
                    screenPainter.clearHighlights()
                case "DRAW":
                    let drawResponse = try JSONDecoder().decode(SocketModels.DrawBoxesResponse.self, from: data)
                    print(drawResponse.boundingBoxes[0].text)
                    var i = 1
                    for box in drawResponse.boundingBoxes {
                        screenPainter.addOverlay(x: box.x, y: box.y, height: box.height, width: box.width, number: i, caption: box.text)
                        i += 1
                    }
                case "SPEAK":
                    let speakResponse = try JSONDecoder().decode(SocketModels.TextSpeechResponse.self, from: data)
                    print(speakResponse.payload)
                    textSpeaker.readText(s: speakResponse.payload)
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
    
    func sendPacket(type: String, s: String) {
        let request = SocketModels.ClientPacket(type: type, payload: s)
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
