import asyncio
import websockets
from GraphGenerator import random_points_from_xs, generate_curve_data, format_to_json
from DataReadPlot import load_touch_history, plot_points

class ServerState:
    def __init__(self):
        self.current_ws = None
        # 取消程序启动时生成图形数据
        self.stored_graph = None
        self.stored_messages = []

    def initialize_graph_data(self):
        x_values = [0, 2, 4, 6, 8, 10]
        points = random_points_from_xs(x_values)
        curve_data = generate_curve_data(points, extreme_prob=0.5, slope_range=(-3, 3))
        return curve_data

state = ServerState()

async def handle_connection(websocket, path):
    state.current_ws = websocket
    print("Client connected:", websocket.remote_address)
    try:
        async for message in websocket:
            print("Received from client:", message)
            state.stored_messages = load_touch_history(message)
    except websockets.ConnectionClosed:
        print("Client disconnected")
    finally:
        state.current_ws = None

async def interactive_input():
    print("Enter command")
    while True:
        command = await asyncio.to_thread(input, "Wait for Monitoring: ")
        if state.current_ws is None:
            print("No client connected!")
            continue

        if command == "1":
            # 每次收到命令 "1" 时重新生成随机图形数据并发送
            state.stored_graph = state.initialize_graph_data()
            await state.current_ws.send(format_to_json(state.stored_graph))
            print("Sent prepared data:")
        elif command == "2":
            await state.current_ws.send("START")
        elif command == "3":
            await state.current_ws.send("END")
        elif command == "4":
            # 根据存储的图形和消息进行绘图
            plot_points(state.stored_graph, state.stored_messages)
        else:
            print("Invalid command")

async def main():
    server = await websockets.serve(handle_connection, "127.0.0.1", 8765)
    print("WebSocket server started at ws://127.0.0.1:8765")
    await interactive_input()

if __name__ == '__main__':
    asyncio.run(main())