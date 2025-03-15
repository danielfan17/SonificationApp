import UIKit
import AVFoundation
import Charts

class ViewController: UIViewController {
    var audioManager: AudioManager!
    var lineChartView: LineChartView!
    
    // UI 元素用于连接服务器
    var connectionTextField: UITextField!
    var connectButton: UIButton!
    var disconnectButton: UIButton!
    
    // WebSocketModel 实例
    var webSocketModel: WebSocketModel!
    
    // PanGestureHandler 实例
    var panGestureHandler: PanGestureHandler!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化音频管理器
        audioManager = AudioManager()
        
        // 创建并配置图表视图
        lineChartView = ChartManager.getLineChartView(for: self)
        view.addSubview(lineChartView)
        
        // 设置拖动手势（传入 DataRecorder）
        setupPanGesture()
        
        // 设置连接相关的 UI
        setupConnectionUI()
        
        // 初始化 WebSocketModel
        webSocketModel = WebSocketModel()
        
        // 当收到 "points" 数据时，更新图表
        webSocketModel.onPointsReceived = { [weak self] points in
            guard let self = self else { return }
            ChartManager.updateLineChartView(self.lineChartView, with: points)
        }
    }
    
    func setupPanGesture() {
        // 传入 DataRecorderManager.shared.dataRecorder 以满足 PanGestureHandler 的构造参数
        panGestureHandler = PanGestureHandler(
            audioManager: audioManager,
            lineChartView: lineChartView,
            dataRecorder: DataRecorderManager.shared.dataRecorder
        )
        
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: panGestureHandler,
            action: #selector(PanGestureHandler.handlePan(_:))
        )
        lineChartView.addGestureRecognizer(panGestureRecognizer)
    }
    
    func setupConnectionUI() {
        let bottomPadding: CGFloat = 20
        let elementHeight: CGFloat = 40
        let spacing: CGFloat = 10
        let viewWidth = view.bounds.width
        let textFieldWidth = viewWidth - 40
        
        connectionTextField = UITextField(frame: CGRect(
            x: 20,
            y: view.bounds.height - bottomPadding - elementHeight * 2 - spacing,
            width: textFieldWidth,
            height: elementHeight
        ))
        connectionTextField.borderStyle = .roundedRect
        connectionTextField.placeholder = "Enter IP:Port (e.g., 192.168.1.100:8765)"
        connectionTextField.autocapitalizationType = .none
        connectionTextField.autocorrectionType = .no
        connectionTextField.backgroundColor = .white
        view.addSubview(connectionTextField)
        
        connectButton = UIButton(type: .system)
        connectButton.frame = CGRect(
            x: 20,
            y: connectionTextField.frame.maxY + spacing,
            width: (textFieldWidth - spacing) / 2,
            height: elementHeight
        )
        connectButton.setTitle("Connect", for: .normal)
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        view.addSubview(connectButton)
        
        disconnectButton = UIButton(type: .system)
        disconnectButton.frame = CGRect(
            x: connectButton.frame.maxX + spacing,
            y: connectionTextField.frame.maxY + spacing,
            width: (textFieldWidth - spacing) / 2,
            height: elementHeight
        )
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        view.addSubview(disconnectButton)
    }
    
    // MARK: - WebSocket Actions
    
    @objc func connectTapped() {
        guard let connectionString = connectionTextField.text, !connectionString.isEmpty else {
            print("Connection string is empty")
            return
        }
        webSocketModel.connect(urlString: connectionString) { success in
            if success {
                print("Connected successfully to \(connectionString)")
            } else {
                print("Failed to connect to \(connectionString)")
            }
        }
    }
    
    @objc func disconnectTapped() {
        print("Disconnect tapped - disconnecting from server")
        webSocketModel.disconnect()
    }
}
