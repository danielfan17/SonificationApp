//
//  ChartManager.swift
//  AudioARMindfulness2
//
//  Created by Katherine Chen on 9/3/24.
//

import UIKit
import Charts

class ChartManager {
    
    /// Create and configure an empty LineChartView (no data initially).
    static func getLineChartView(for viewController: UIViewController) -> LineChartView {
        let lineChartView = LineChartView()
        
        // Positioning and sizing
        let chartHeight: CGFloat = viewController.view.bounds.height / 2
        let topPadding: CGFloat = 100
        lineChartView.frame = CGRect(
            x: 0,
            y: topPadding,
            width: viewController.view.bounds.width,
            height: chartHeight - topPadding
        )
        lineChartView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        
        // Basic appearance
        viewController.view.backgroundColor = .white
        lineChartView.setScaleEnabled(false)
        lineChartView.xAxis.labelTextColor = .black
        lineChartView.leftAxis.labelTextColor = .black
        lineChartView.rightAxis.labelTextColor = .black
        lineChartView.legend.textColor = .black
        
        // Initialize with empty data
        lineChartView.data = LineChartData()
        
        return lineChartView
    }
    
    /// Update an existing LineChartView with new points data.
    /// points is expected to be an array of [x, y] pairs, e.g. [[1.0, 2.0], [3.0, 4.0]].
    static func updateLineChartView(_ lineChartView: LineChartView, with points: [[Double]]) {
        // Transform [[Double]] into [ChartDataEntry]
        let entries: [ChartDataEntry] = points.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return ChartDataEntry(x: pair[0], y: pair[1])
        }
        
        // Create a LineChartDataSet
        let dataSet = LineChartDataSet(entries: entries, label: "WebSocket Data")
        dataSet.colors = [NSUIColor.blue]
        dataSet.circleColors = [NSUIColor.red]
        dataSet.mode = .cubicBezier
        dataSet.lineWidth = 2.0
        dataSet.circleRadius = 4.0
        dataSet.drawValuesEnabled = false
        
        // Set the new data for the chart
        let chartData = LineChartData(dataSet: dataSet)
        lineChartView.data = chartData
        
        // Refresh the chart view
        lineChartView.notifyDataSetChanged()
    }
}
