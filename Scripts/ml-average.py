import os
import csv
import pandas as pd
from datetime import datetime

def process_csv_files(folder_path):
    # 获取文件夹下所有的csv文件
    csv_files = [file for file in os.listdir(folder_path) if file.endswith('.csv')]
    
    # 用于存放每个文件的平均值和时间差
    file_averages = {}
    time_diffs = {}
    
    for file in csv_files:
        file_path = os.path.join(folder_path, file)
        file_name = os.path.splitext(file)[0]  # 提取文件名，去除扩展名
        
        # 用于存放每列的平均值
        column_averages = {}
        time_values = []
        
        # 读取csv文件
        with open(file_path, 'r') as csv_file:
            reader = csv.reader(csv_file)
            header = next(reader)  # 读取标题行
            for i, col_name in enumerate(header):
                if col_name not in column_averages:
                    column_averages[col_name] = []
            for row in reader:
                time_values.append(row[0])  # 提取时间列的值
                for i, value in enumerate(row[1:]):  # 从第二列开始
                    # 计算每列的平均值
                    try:
                        column_averages[header[i + 1]].append(float(value))
                    except ValueError:
                        pass
        
        # 计算每列的平均值
        for key in column_averages.keys():
            values = column_averages[key]
            if values:
                column_averages[key] = sum(values) / len(values)
            else:
                column_averages[key] = None
        
        # 计算时间差
        start_time = datetime.strptime(time_values[0], '%Y-%m-%d %H:%M:%S')
        end_time = datetime.strptime(time_values[-2], '%Y-%m-%d %H:%M:%S')
        time_diff = end_time - start_time
        time_diffs[file_name] = time_diff
        
        # 保存该文件的平均值
        file_averages[file_name] = column_averages
    
    # 将结果写入Excel文件
    result_file = 'averages.xlsx'
    with pd.ExcelWriter(result_file, engine='openpyxl') as writer:  # 设置引擎为openpyxl
        # 在ExcelWriter中创建一个空的工作表
        writer.book.create_sheet(index=0, title='Sheet1')
        
        # 创建DataFrame
        df_list = []
        for key in file_averages.keys():
            df = pd.DataFrame({'File': [key], 'Time Difference': [time_diffs[key].total_seconds()], **file_averages[key]})
            df_list.append(df)
        df = pd.concat(df_list, ignore_index=True)
        
        # 将DataFrame写入工作表
        df.to_excel(writer, sheet_name='Sheet1', index=False)

    print(f"结果已经导出到 {result_file} 文件中。")

# 测试
folder_path = input("请输入CSV文件所在文件夹的路径：")
process_csv_files(folder_path)
