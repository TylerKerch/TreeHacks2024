//
//  WebSocket.swift
//  frontend
//
//  Created by Sarvesh Phoenix on 2/17/24.
//

import AppKit
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
        
//            print("Received text: \(string)")
            guard let data = string.data(using: .utf8) else { return }
            do {
                let genericResponse = try JSONDecoder().decode(SocketModels.GenericResponse.self, from: data)
                print(genericResponse.type)
                switch genericResponse.type {
                case "CLEAR":
                    // RECEIVED A JSON MESSAGE TO CLEAR BOXES
                    print("CLEAR BOXES")
                    screenPainter.clearHighlights()
                case "SELECT":
                    print(data)
                    let drawResponse = try JSONDecoder().decode(SocketModels.SelectBoxResponse.self, from: data)
//                    print(drawResponse.boundingBox.text)
                    var i = 1
                    let box = drawResponse.payload
                    let x = box.x / 2
                    let y = box.y / 2
                    let width = box.width / 2
                    let height = box.height / 2
                    screenPainter.addOverlay(x: x-width/2, y: y-height/2, height: height, width: width, number: i, caption: box.text)
                    i += 1
                case "BOXES":
                    if let jsonStr = String(data: data, encoding: .utf8) {
                        print("Fetched JSON String: \(jsonStr)")
                    }
                    let drawResponse = try JSONDecoder().decode(SocketModels.StoreBoxesResponse.self, from: data)
                    var i = 1
                    let boxes = drawResponse.payload
                    print("BOXES")
                    for box in boxes {
                        let x = box.x / 2
                        let y = box.y / 2
                        let width = box.width / 2
                        let height = box.height / 2
                        let newX = x - width / 2
                        let screenHeight = NSScreen.main?.frame.height ?? 1120
                        let newY = screenHeight - y - 50 - height * 1.5
                        let detection_id = box.detection_id
                        screenPainter.addOverlay(x: newX, y: newY, height: height + 50, width: width, number: i, caption: "")
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
