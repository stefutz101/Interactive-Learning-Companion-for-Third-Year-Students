import os
import json

def merge_json_files(input_directory, output_file):
    merged_data = []

    # Iterate over all files in the specified directory
    for filename in os.listdir(input_directory):
        if filename.endswith('.json'):
            file_path = os.path.join(input_directory, filename)
            
            # Read the JSON file
            with open(file_path, 'r', encoding='utf-8') as file:
                data = json.load(file)
                
                # Ensure the data is a list
                if isinstance(data, list):
                    merged_data.extend(data)
                else:
                    merged_data.append(data)
    
    # Write the merged data to the output file
    with open(output_file, 'w', encoding='utf-8') as output_file:
        json.dump(merged_data, output_file, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    input_directory = '.'  # Current directory
    output_file = 'db-course+synthetic_text_to_sql_dataset.json'
    
    # Check if the output file exists in the input directory and delete it
    output_file_path = os.path.join(input_directory, output_file)
    if os.path.exists(output_file_path):
        os.remove(output_file_path)
        print(f"{output_file} already exists and has been deleted.")
    
    merge_json_files(input_directory, output_file)
    print(f"JSON files merged into {output_file}")