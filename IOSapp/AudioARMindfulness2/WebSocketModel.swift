import Foundation
import UIKit  // 用于访问 UIApplication 和 UI 相关接口

class WebSocketModel {
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    var isConnected: Bool = false
    
    // 当接收到 points 数据时回调更新图表
    var onPointsReceived: (([[Double]]) -> Void)?
    
    func connect(urlString: String, completion: ((Bool) -> Void)? = nil) {
        var finalURLString = urlString
        if !finalURLString.lowercased().hasPrefix("ws://") {
            finalURLString = "ws://" + finalURLString
        }
        guard let url = URL(string: finalURLString) else {
            print("Invalid URL")
            completion?(false)
            return
        }
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        listenForMessages()
        completion?(true)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        print("WebSocket disconnected.")
    }
    
    func send(message: String, completion: ((Error?) -> Void)? = nil) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(wsMessage, completionHandler: { error in
            completion?(error)
        })
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self.isConnected = false
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text message: \(text)")
                    self.handleReceivedText(text)
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    print("Received unknown message")
                }
                self.listenForMessages()
            }
        }
    }
    
    /// 处理接收到的文本消息：
    /// - "START"：启动录制（调用 DataRecorderManager.shared.startRecording()）
    /// - "END"：停止录制，发送记录数据后重置录制数据（即清空 timer 和数据）
    /// - 如果消息为 JSON 格式且包含 "points" 数组，则调用 onPointsReceived 回调更新图表，并重置录制数据
    /// - 其它消息直接打印
    private func handleReceivedText(_ text: String) {
        if text == "START" {
            print("Received START command")
            DispatchQueue.main.async {
                DataRecorderManager.shared.startRecording()
            }
            return
        }
        
        if text == "END" {
            print("Received END command")
            DispatchQueue.main.async {
                DataRecorderManager.shared.stopRecording()
                if let jsonString = DataRecorderManager.shared.formattedJSONData() {
                    self.send(message: jsonString) { error in
                        if let error = error {
                            print("Error sending recorded data: \(error)")
                        } else {
                            print("Recorded data sent successfully")
                        }
                    }
                }
                // 重置录制数据，准备下一次记录
                DataRecorderManager.shared.dataRecorder.recordedData.removeAll()
                DataRecorderManager.shared.dataRecorder.startTime = nil
            }
            return
        }
        
        // 尝试解析 JSON 数据（例如包含 "points" 数组的消息）
        if let data = text.data(using: .utf8) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let pointsArray = jsonObject["points"] as? [[Double]] {
                    print("Received points: \(pointsArray)")
                    DispatchQueue.main.async {
                        self.onPointsReceived?(pointsArray)
                        // 重置录制数据，准备下一次记录
                        DataRecorderManager.shared.dataRecorder.recordedData.removeAll()
                        DataRecorderManager.shared.dataRecorder.startTime = nil
                    }
                    return
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        
        print("Received message: \(text)")
    }
    
    /// 将 DataRecorder 中的记录数据转换为 JSON 并发送回服务器
    func sendRecordedData() {
        if let jsonString = DataRecorderManager.shared.formattedJSONData() {
            send(message: jsonString) { error in
                if let error = error {
                    print("Error sending recorded data: \(error)")
                } else {
                    print("Recorded data sent successfully")
                }
            }
        } else {
            print("No recorded data to send")
        }
    }
}
