import UIKit
import Charts

class PanGestureHandler: NSObject {
    var isDragging = false
    var prevNumberOfTouches: Int = 0
    var prevCoordinate: ChartDataEntry?
    
    // 限流：每50毫秒处理一次事件
    var lastUpdateTime: TimeInterval = 0
    let updateInterval: TimeInterval = 0.05
    
    let audioManager: AudioManager
    let lineChartView: LineChartView
    // 使用 DataRecorder 记录数据
    var dataRecorder: DataRecorder

    init(audioManager: AudioManager,
         lineChartView: LineChartView,
         dataRecorder: DataRecorder) {
        self.audioManager = audioManager
        self.lineChartView = lineChartView
        self.dataRecorder = dataRecorder
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // 如果没有 startTime，说明还没 START 录制
        guard dataRecorder.startTime != nil else { return }
        
        // 如果没有触摸点，则停止处理并停止音频
        guard recognizer.numberOfTouches > 0 else {
            isDragging = false
            audioManager.stopAudio()
            return
        }
        
        let currentTime = CACurrentMediaTime()
        // 限流：只有超过指定时间间隔时才处理事件
        guard currentTime - lastUpdateTime > updateInterval else { return }
        lastUpdateTime = currentTime
        
        let touchLocation = recognizer.location(ofTouch: 0, in: lineChartView)
        
        switch recognizer.state {
        case .began:
            isDragging = true
            audioManager.startAudio()
            
        case .changed:
            // 1) 先记录手指的实际触摸位置（不改变音频逻辑）
            dataRecorder.recordRawPoint(x: touchLocation.x, y: touchLocation.y)
            
            // 2) split tap 检测
            if prevNumberOfTouches == 1 && recognizer.numberOfTouches == 2 {
                handleSplitTap()
            }
            
            // 3) 原有基于 entry 的逻辑，用于音频播放
            let xValue = lineChartView.valueForTouchPoint(point: touchLocation, axis: .left).x
            if let dataSet = lineChartView.data?.dataSets.first,
               let entry = dataSet.entryForXValue(xValue, closestToY: Double.nan) {
                audioManager.sonifyDataPoint(entry.y)
//                dataRecorder.recordData(entry: entry)
                
                prevNumberOfTouches = recognizer.numberOfTouches
                prevCoordinate = entry
            }
            
        case .ended, .cancelled:
            isDragging = false
            audioManager.stopAudio()
            
        default:
            break
        }
    }
    
    @objc func handleSplitTap() {
        guard let entry = prevCoordinate else { return }
        print("split-tap detected at \(entry.x), \(entry.y)")
        // 可在此添加额外逻辑，如记录 split tap 数据
    }
}
