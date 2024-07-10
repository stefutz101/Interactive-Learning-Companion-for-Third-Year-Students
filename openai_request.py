import os
import json
from openai import OpenAI
from openai.types import CreateEmbeddingResponse, Embedding

# Set your OpenAI API key
client = OpenAI(
    # This is the default and can be omitted
    api_key='',
)

def read_chunks(file_path):
    with open(file_path, 'r', encoding="utf8") as file:
        chunks = file.read().split('\n\n\n\n')

        for chunk in chunks:
            yield chunk

# https://stackoverflow.com/questions/75774873/openai-api-error-this-is-a-chat-model-and-not-supported-in-the-v1-completions
# https://github.com/openai/openai-python/blob/main/api.md
# https://github.com/openai/openai-python/blob/main/src/openai/types/create_embedding_response.py
# https://platform.openai.com/docs/models/model-endpoint-compatibility
# https://openai.com/api/pricing


def generate_response(prompt):
    response = client.chat.completions.create(
        model="gpt-3.5-turbo-0125",  # text-davinci-002
        messages=[
            {
                "role": "user",
                "content": prompt,
            },
        ],
    )
    return response.choices[0].message.content

def process_file(file_path, prompt):
    responses = []
    print(f"Processing file: {file_path}")

    for chunk in enumerate(read_chunks(file_path)):
        prompt_with_chunk = f"{prompt}{chunk}"
        response = generate_response(prompt_with_chunk)

        """ 
        print(f"Response for Chunk:")
        print(response)
        print("=" * 20)  
        """

        response = json.dumps(response)
        if isinstance(response, dict):
            first_key = next(iter(response.keys()))
            if isinstance(response[first_key], list):
                for entry in response[first_key]:
                    responses.append(entry)
        elif isinstance(response, list) and len(response) > 1:
            for entry in response:
                responses.append(entry)
        else:
            responses.append(response)

    # Save responses to a JSON file
    file_name = os.path.splitext(os.path.basename(file_path))[0] + "_responses.json"
    with open(file_name, 'w') as json_file:
        json.dump(responses, json_file)

def process_files_in_directory(directory_path, prompt):
    txt_files = [file for file in os.listdir(directory_path) if file.endswith(".txt")]
    list_to_remove = ['db-course-14.txt', 'db-course-02-04.txt', 'db-course-10.txt', 'db-course-12.txt', 'db-course-11.txt', 'db-course-07-08.txt', 'db-course-01.txt', 'db-course-05-06.txt', 'db-course-13.txt']

    txt_files = list(set(txt_files) - set(list_to_remove))

    for txt_file in txt_files:
        file_path = os.path.join(directory_path, txt_file)
        process_file(file_path, prompt)
        exit()

prompt = '''
    Given the following text chunk, your role is to analyze the text and generate multiple JSON entries. Each entry should follow the format below:

    {"instruction": "Provide an answer to the following question:", "input": "What is the main idea presented in the text?", "output": "The main idea presented in the text is..."}

    Instructions:

    1. Read the provided text chunk carefully.
    2. Generate a question based on the content of the text. The question should aim to extract key information or insights from the text.
    3. Provide an answer to the generated question by reformulating the text into a concise and clear response.
    4. Repeat the process to generate as many JSON entries as possible, each with a unique question and corresponding answer.
    5. Aim to cover various aspects or points discussed in the text by generating a diverse set of questions and answers.
    6. If there are multiple JSON entries, a plain JSON object(without any keywords) will be returned instead of individual entries.

    Text Chunk:


'''

def main():
    directory_path = "train\\DB1\\PDFs\\"
    process_files_in_directory(directory_path, prompt)

if __name__ == "__main__":
    main()
