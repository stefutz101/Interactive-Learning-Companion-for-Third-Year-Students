import json

# Function to process and modify the dataset
def process_dataset(input_file, output_file):
    with open(input_file, 'r') as f:
        data = json.load(f)

    # Remove specified columns from each entry
    processed_data = []
    for entry in data:
        processed_entry = {'instruction': entry['sql_context'], 'input': entry['sql_prompt'], 'output': entry['sql_explanation'] + " " + entry['sql']}
        processed_data.append(processed_entry)

    # Save the processed data to a new JSON file
    with open(output_file, 'w') as f:
        json.dump(processed_data, f, indent=2)

    print(f"Processed data saved to {output_file}")

# Example usage:
if __name__ == "__main__":
    input_file = "synthetic_text_to_sql_dataset.json"  # Replace with your input JSON file path
    output_file = "synthetic_text_to_sql_dataset_cleared.json"  # Replace with your desired output JSON file path

    process_dataset(input_file, output_file)
