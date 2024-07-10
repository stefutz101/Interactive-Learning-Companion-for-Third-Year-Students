import torch
from peft import AutoPeftModelForCausalLM
from transformers import AutoTokenizer, pipeline

MODEL_NAME = "stefutz101/code-llama-7b-databases-finetuned2"

def create_model(model_name: str = MODEL_NAME) -> AutoPeftModelForCausalLM:
    return AutoPeftModelForCausalLM.from_pretrained(
        MODEL_NAME,
        device_map="auto",
        torch_dtype=torch.float16,
        offload_folder="offload/"
    )

def create_tokenizer (model_name: str = MODEL_NAME) -> AutoTokenizer:
    return AutoTokenizer.from_pretrained(MODEL_NAME)

def create_pipe() -> pipeline:
    return pipeline("text-generation", model=create_model(MODEL_NAME), tokenizer=create_tokenizer(MODEL_NAME))

def predict(
    context: str,    
    prompt: str,   
    pipe: pipeline,
    tokenize: bool = False,
    add_generation_prompt: bool = True,
    max_new_tokens: int = 256,
    do_sample: bool = True,
    temperature: float = 0.7,
    top_k: int = 50,
    top_p: float = 0.95,
) -> str:
    message = [{'content': "You are an virtual assistent that will answer to the students and their questions about Database 1 module. The Stundets will ask you questions in English and you will answer to their questions based on the provided SCHEMA.\nSCHEMA:\n" + context,'role': 'system'}, {'content': prompt, 'role': 'user'}]

    prompt = pipe.tokenizer.apply_chat_template(message, tokenize=tokenize, add_generation_prompt=add_generation_prompt)
    outputs = pipe(prompt, max_new_tokens=max_new_tokens, do_sample=do_sample, temperature=temperature, top_k=top_k, top_p=top_p, eos_token_id=pipe.tokenizer.eos_token_id, pad_token_id=pipe.tokenizer.pad_token_id)
    predicted_answer = outputs[0]['generated_text'][len(prompt):].strip()
    return predicted_answer