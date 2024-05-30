import os
import xml.etree.ElementTree as ET
import pandas as pd

def process_xml(xml_file):
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    data = {}
    
    # Extract file name without extension
    file_name = os.path.basename(xml_file).split('.')[0]
    
    # Find all <result> elements
    results = root.findall(".//result")
    for result in results:
        for child in result:
            # Ignore non-numeric values and empty tags
            if child.text is not None and child.text.strip().replace('.', '', 1).isdigit():
                key = child.tag
                value = float(child.text)
                # Add to data dictionary if not already present
                if key not in data:
                    data[key] = value
                else:
                    # If key already exists, update only if the new value is larger
                    if value > data[key]:
                        data[key] = value
    
    # Add file name as the first column
    data["File Name"] = file_name
    
    return data

def xml_files_in_directory(directory):
    xml_files = []
    # Iterate through all files in the directory
    for file in os.listdir(directory):
        if file.endswith(".xml"):
            xml_files.append(os.path.join(directory, file))
    return xml_files

def xml_to_excel(directory, output_file):
    all_data = []
    # Get a list of XML files in the directory
    xml_files = xml_files_in_directory(directory)
    
    # Process each XML file
    for xml_file in xml_files:
        data = process_xml(xml_file)
        all_data.append(data)
    
    # Convert data to DataFrame
    df = pd.DataFrame(all_data)
    
    # Reorder columns to have "File Name" as the first column
    df = df[['File Name'] + [col for col in df.columns if col != 'File Name']]
    
    # Write DataFrame to Excel
    df.to_excel(output_file, index=False)

# Example usage:
directory = input("请输入XML文件所在的目录：")
output_file = "output.xlsx"
xml_to_excel(directory, output_file)
