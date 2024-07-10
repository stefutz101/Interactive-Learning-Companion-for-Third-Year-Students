import json
from datasets import load_dataset

# Load the dataset from the Hugging Face repository
dataset = load_dataset("gretelai/synthetic_text_to_sql")  # Replace "squad" with your dataset name

# Shuffle all rows of the dataset
dataset = dataset.shuffle()

# Extract the first 12500 entries
subset_dataset = dataset['train'].select(range(5989))

# Convert the subset dataset to a list of dictionaries
subset_data = subset_dataset.to_json("./synthetic_text_to_sql_dataset.json")
