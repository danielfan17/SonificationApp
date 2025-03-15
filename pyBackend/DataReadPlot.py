import json
import matplotlib.pyplot as plt

def load_touch_history(json_str):
    """
    从 JSON 字符串中解析原始触摸数据 (rawTouchData)，并将其归一化到 [0, 10] 区间。
    假设 rawX 在 [16, 380]，rawY 在 [16, 320]。
    如果你的实际 lineChartView 大小不一致，请根据实际情况调整 x_min_raw, x_max_raw, y_min_raw, y_max_raw。
    """
    
    # 原始数据范围（根据 lineChartView 的实际大小或你期望的坐标范围）
    x_min_raw, x_max_raw = 16, 380
    y_min_raw, y_max_raw = 320, 16
    
    # 归一化目标范围
    norm_x_min, norm_x_max = 0, 10
    norm_y_min, norm_y_max = 0, 10

    # 归一化函数：映射 [in_min, in_max] -> [out_min, out_max]
    normalize = lambda val, in_min, in_max, out_min, out_max: (
        (val - in_min) / (in_max - in_min) * (out_max - out_min) + out_min
    )

    # 解析 JSON 字符串
    data = json.loads(json_str)
    touch_data = data.get("rawTouchData", [])
    
    # 归一化后的结果
    points = []
    
    # 将原始坐标转换为 [0, 10] 区间
    for point in touch_data:
        raw_x = float(point.get("rawX", 0))
        raw_y = float(point.get("rawY", 0))
        
        norm_x = normalize(raw_x, x_min_raw, x_max_raw, norm_x_min, norm_x_max)
        norm_y = normalize(raw_y, y_min_raw, y_max_raw, norm_y_min, norm_y_max)
        
        points.append((norm_x, norm_y))
    
    return points

def plot_points(task_graph, touch_history):
    """
    同时绘制两组数据：
    - task_graph：以单一颜色绘制散点图（传统方式）。
    - touch_history：用颜色梯度表示时间顺序绘制散点图。
    """
    # 提取 task_graph 的 x 和 y 坐标
    task_x = [p[0] for p in task_graph]
    task_y = [p[1] for p in task_graph]
    
    # 提取 touch_history 的 x 和 y 坐标，并生成表示时间顺序的列表
    touch_x = [p[0] for p in touch_history]
    touch_y = [p[1] for p in touch_history]
    touch_order = list(range(len(touch_history)))
    
    plt.figure(figsize=(8, 8))
    
    # 绘制 task_graph，用单一颜色（如蓝色）
    plt.scatter(task_x, task_y, color='blue', label='Task Graph', alpha=0.8)
    
    # 绘制 touch_history，用颜色梯度表示时间顺序
    sc = plt.scatter(touch_x, touch_y, c=touch_order, cmap='viridis', label='Touch History', alpha=0.8)
    plt.colorbar(sc, label='Touch Order')
    
    plt.xlabel("Normalized X")
    plt.ylabel("Normalized Y")
    plt.title("Task Graph and Touch History")
    # 留出额外空间，防止数据超出映射范围
    plt.xlim(-1, 11)
    plt.ylim(-1, 11)
    plt.grid(True)
    plt.legend()
    plt.show()