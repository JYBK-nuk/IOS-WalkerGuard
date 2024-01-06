//
//  Service.swift
//  WalkerGuard2
//

import Foundation
import SwiftUI
import Starscream

class Plates :Encodable{
    var time = 0.0
    var plate = [String]()
    var position = [[Int]]()
}

class Service: WebSocketDelegate {
    var detectHistory = [Plates]()
    var socket: WebSocket
    var isConnected = false
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            // test
            sendPlates()
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            print("error: \(error?.localizedDescription ?? "")")
            isConnected = false
        case .peerClosed:
            break
        }
    }
    
    init() {
        var request = URLRequest(url: URL(string: "ws://192.168.1.131:80/event")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    func addPlates(images:[UIImage], positions:[[Int]]){
        let plate = Plates()
        plate.time = Date().timeIntervalSince1970
        plate.plate = [String]()
        for image in images{
            let data = image.jpegData(compressionQuality: 0.5)
            let base64 = data?.base64EncodedString()
            plate.plate.append(base64!)
        }
        
        plate.position = positions
        detectHistory.append(plate)
        
        if detectHistory.count > 1000{
            detectHistory.removeFirst()
        }
    }
    
    func sendPlates(){
        if isConnected {
            let encoder = JSONEncoder()
            let data = try! encoder.encode(detectHistory)
            socket.write(string: String(data: data, encoding: .utf8)!)
            detectHistory.removeAll()
        }
    }
}
