import json
import websocket
import threading
import time
import subprocess
import os
import sys
import ctypes
import tkinter as tk
import tkinter.messagebox
import tkinter.simpledialog

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def run_as_admin():
    if not is_admin():
        print("请以管理员权限运行脚本")
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
        sys.exit()

def run_ptat_service():
    os.chdir("C:\\Program Files\\Intel Corporation\\Intel(R)PTAT")
    args = ["PTATService.exe", "-ui"]
    subprocess.Popen(args, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
    print("PTATService.exe 正在以管理员权限启动...")

def send_commands(ws):
    user_documents_path = os.path.join(os.path.expanduser("~"), "Documents")
    
    commands = [
        {
            "Command": "LoadWorkspace",
            "params": {
                "Args": f"{user_documents_path}\\iPTAT\\workspace\\DefaultWorkSpace.json,USERCHECKED,MONITORCHECKED,CUSTOMVIEWCHECKED,GRAPHCHECKED,ALERTSCHECKED"
            }
        },
        {"Command": "MonitorView"},
        {"Command": "GetMonitorData"},
        {"Command": "MonitorView"},
        {"Command": "StartMonitor"}
        # Add more commands if needed
    ]

    for command in commands:
        ws.send(json.dumps(command))

def process_messages(ws, exit_event, clear_avg_event, root, current_value_label, avg_value_label):
    count = 0
    total_304 = 0
    total_306 = 0
    total_307 = 0
    value_304 = 0
    value_306 = 0
    value_307 = 0

    while not exit_event.is_set():
        try:
            message = ws.recv()
            data = json.loads(message)

            if data.get("Command") == "StartMonitor":
                status = data.get("CommandStatus", {}).get("Status")
                if status == "Success" and "Data" in data:
                    count += 1
                    for item in data.get("Data"):
                        key = item["Key"]
                        value = float(item["Value"])

                        if key == 304:
                            total_304 += value
                            value_304 = value
                        elif key == 306:
                            total_306 += value
                            value_306 = value
                        elif key == 307:
                            total_307 += value
                            value_307 = value

                    if count > 0:
                        avg_304 = total_304 / count
                        avg_306 = total_306 / count
                        avg_307 = total_307 / count

                        current_value_label.config(text=f"实时\nIA Power:        {value_304:.6f}\nRest of Package: {value_306:.6f}\nPackage Power:   {value_307:.6f}")
                        avg_value_label.config(text=f"平均\nIA Power:        {avg_304:.6f}\nRest of Package: {avg_306:.6f}\nPackage Power:   {avg_307:.6f}\n距上次清空: {count:.1f}秒")

                        # Check if clear_avg_event is set (Clear Average button pressed)
                        if clear_avg_event.is_set():
                            clear_avg_event.clear()
                            total_304 = 0
                            total_306 = 0
                            total_307 = 0
                            count = 0
                            avg_str = f"IA Power: {avg_304:.6f}\nRest of Package: {avg_306:.6f}\nPackage Power: {avg_307:.6f}"
                            root.clipboard_clear()
                            root.clipboard_append(avg_str)
                            root.update()

        except websocket.WebSocketConnectionClosedException:
            print("\nWebSocket connection closed. Reconnecting...")
            break

def clear_avg_data(clear_avg_event):
    clear_avg_event.set()

def main():
    run_as_admin()

    uri = "ws://localhost:64900/echo"  # 替换成你实际的 WebSocket 服务器地址
    
    # Run PTATService.exe with administrator privileges
    run_ptat_service()

    time.sleep(10)  # Give some time for PTATService.exe to start (adjust as needed)
    
    ws = websocket.create_connection(uri)

    print("连接已建立")

    exit_event = threading.Event()
    clear_avg_event = threading.Event()

    root = tk.Tk()
    root.title("Power Information")
    root.geometry("+0+0")  # Place the GUI in the top-left corner
    root.overrideredirect(True)  # Hide window borders
    root.attributes("-alpha", 0.6)  # Set transparent background

    # Font settings
    font_settings = ("黑体", 10, "bold")

    current_value_label = tk.Label(root, text="", font=font_settings, fg="red", justify="left")
    current_value_label.pack(side="top", pady=5)

    avg_value_label = tk.Label(root, text="", font=font_settings, fg="red", justify="left")
    avg_value_label.pack(side="top", pady=5)

    clear_avg_button = tk.Button(root, text="清空平均值", command=lambda: clear_avg_data(clear_avg_event), font=font_settings)
    clear_avg_button.pack(side="bottom", pady=10)

    threading.Thread(target=send_commands, args=(ws,), daemon=True).start()

    process_thread = threading.Thread(target=process_messages, args=(ws, exit_event, clear_avg_event, root, current_value_label, avg_value_label), daemon=True)
    process_thread.start()

    try:
        root.mainloop()
    except KeyboardInterrupt:
        print("\nExiting...")

    exit_event.set()
    process_thread.join()
    ws.close()

if __name__ == "__main__":
    main()
