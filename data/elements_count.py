import os
import json

def count_elements_in_json_files(directory):
    # Iterate over all files in the specified directory
    for filename in os.listdir(directory):
        if filename.endswith('.json'):
            file_path = os.path.join(directory, filename)
            
            # Read the JSON file
            with open(file_path, 'r', encoding='utf-8') as file:
                data = json.load(file)
                
                # Check if the data is a list and count the elements
                if isinstance(data, list):
                    element_count = len(data)
                else:
                    element_count = 1  # If the file contains a single JSON object
            
            print(f"{filename}: {element_count} elements")

if __name__ == "__main__":
    directory = '.'  # Current directory
    count_elements_in_json_files(directory)