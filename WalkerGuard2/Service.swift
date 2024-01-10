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
    var prevTime=DispatchTime.now()
    var decoder = JSONDecoder()
    var encoder = JSONEncoder()
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
             if let data = string.data(using: .utf8) {
                 do {
                     let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                     if let time = json?["time"] as? Double {
                         let closestPlates = findClosestPlates(to: time)
                         let data = try! encoder.encode(closestPlates)
                            socket.write(string: String(data: data, encoding: .utf8)!)
                         
                     }
                 } catch {
                     print("Failed to parse JSON: \(error)")
                 }
             }
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
    
    func reconnect(){
        socket.disconnect()
        socket.connect()
    }
    func checkPrvTime1s()->Bool{
        let currentTime = DispatchTime.now()
        let timeInterval = DispatchTimeInterval.seconds(1)
        let targetTime = prevTime + timeInterval
        return currentTime >= targetTime
    }
    func addPlates(images:[UIImage], positions:[[Int]]){
        if images.count == 0{
            return
        }
        let plate = Plates()
        plate.time = Date().timeIntervalSince1970
        plate.plate = [String]()
        for image in images{
            let data = image.jpegData(compressionQuality: 1)
            let base64 = data?.base64EncodedString()
            plate.plate.append(base64!)
        }
        
        plate.position = positions
        detectHistory.append(plate)
        
        if detectHistory.count > 60{
            detectHistory.removeFirst()
        }
        prevTime = DispatchTime.now()
    }
    
    func sendAllTimePlates(){
        if isConnected {
            let data = try! encoder.encode(detectHistory)
            socket.write(string: String(data: data, encoding: .utf8)!)
            detectHistory.removeAll()
        }
    }
    
    func findClosestPlates(to time: Double) -> Plates? {
        var closestPlates: Plates?
        var closestTimeDifference = Double.infinity

        for plates in detectHistory {
            let timeDifference = abs(time - plates.time)
            if timeDifference < closestTimeDifference {
                closestPlates = plates
                closestTimeDifference = timeDifference
            }
        }

        return closestPlates
    }
    
    func sendNewestPlate(){
        if isConnected {
            let data = try! encoder.encode(detectHistory.last)
            socket.write(string: String(data: data, encoding: .utf8)!)
        }
    }
    
    func setInitPosition(image:UIImage){
        let url = URL(string: "http://192.168.1.131/initPlateCam/plate")
        var request = URLRequest(url: url!)

        // 設置request的HTTP方法為POST
        request.httpMethod = "POST"

        // 設置request的Content-Type為multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 建立要上傳的資料body
        let httpBody = NSMutableData()

        // 加入圖片資料
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            httpBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            httpBody.append(imageData)
            httpBody.append("\r\n".data(using: .utf8)!)
        }

        // 加入結束標示
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // 設置request的HTTP body
        request.httpBody = httpBody as Data

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                // 若有接收到伺服器回傳的資料，可以在這裡處理
                let responseString = String(data: data, encoding: .utf8)
                print("Response: \(String(describing: responseString))")
            }
        }

        task.resume()
        print("setInitPosition")
    }
}
