import UIKit
import Charts

public class DataRecorder {
    // 原先基于 entry 的数据
    public var recordedData: [TimeInterval: (x: CGFloat, y: CGFloat)] = [:]
    // 新增：用于记录手指的原始触摸位置
    public var rawTouchData: [TimeInterval: (x: CGFloat, y: CGFloat)] = [:]
    
    public var startTime: CFTimeInterval?
    
    public init() { }
    
    // 开始录制：清空旧数据并设置起始时间
    public func startRecording() {
        recordedData.removeAll()
        rawTouchData.removeAll()
        startTime = CACurrentMediaTime()
    }
    
    public func stopRecording() {
        // 此处无需额外操作
    }
    
    // 记录基于图表 entry 的数据
    public func recordData(entry: ChartDataEntry) {
        guard let start = startTime else { return }
        let timestamp = CACurrentMediaTime() - start
        recordedData[timestamp] = (x: CGFloat(entry.x), y: CGFloat(entry.y))
    }
    
    // 记录手指的原始位置（在 chart 或其他坐标系中）
    public func recordRawPoint(x: CGFloat, y: CGFloat) {
        guard let start = startTime else { return }
        let timestamp = CACurrentMediaTime() - start
        rawTouchData[timestamp] = (x, y)
    }
    
    // 将记录的数据转换为 JSON 字符串（按时间升序）
    // 这里演示把 entry 数据和 rawTouch 数据都放进 JSON
    // 如果你只想传 entry 数据，或者只想传 rawTouch 数据，可自行调整
    public func formattedJSONData() -> String? {
        let sortedEntryKeys = recordedData.keys.sorted()
        let sortedRawKeys = rawTouchData.keys.sorted()
        
        // 构造 dragData 数组
//        var dragArray: [String] = []
//        for time in sortedEntryKeys {
//            guard let point = recordedData[time] else { continue }
//            let timeStr = String(format: "%.2f", time)
//            let xStr = String(format: "%.2f", point.x)
//            let yStr = String(format: "%.2f", point.y)
//            let entryJSON = "{\"time\":\"\(timeStr)\",\"x\":\"\(xStr)\",\"y\":\"\(yStr)\"}"
//            dragArray.append(entryJSON)
//        }
        
        // 构造 rawTouchData 数组
        var rawArray: [String] = []
        for time in sortedRawKeys {
            guard let point = rawTouchData[time] else { continue }
            let timeStr = String(format: "%.2f", time)
            let xStr = String(format: "%.2f", point.x)
            let yStr = String(format: "%.2f", point.y)
            let rawJSON = "{\"time\":\"\(timeStr)\",\"rawX\":\"\(xStr)\",\"rawY\":\"\(yStr)\"}"
            rawArray.append(rawJSON)
        }
        
        let jsonString = """
        {
          "rawTouchData": [\(rawArray.joined(separator: ","))]
        }
        """
        
//
//        let jsonString = """
//        {
//          "dragData": [\(dragArray.joined(separator: ","))],
//          "rawTouchData": [\(rawArray.joined(separator: ","))]
//        }
//        """
        
        return jsonString
    }
}

public class DataRecorderManager {
    public static let shared = DataRecorderManager()
    public let dataRecorder = DataRecorder()
    
    private init() { }
    
    public func startRecording() {
        dataRecorder.startRecording()
    }
    
    public func stopRecording() {
        dataRecorder.stopRecording()
    }
    
    public func formattedJSONData() -> String? {
        return dataRecorder.formattedJSONData()
    }
}
