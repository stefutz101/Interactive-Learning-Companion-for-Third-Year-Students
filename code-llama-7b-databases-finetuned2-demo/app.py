from fastapi import FastAPI, HTTPException, Request, File, UploadFile, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
import json
from typing import List, Optional
import os

from scripts.predictor import create_pipe, predict

pipe = create_pipe()

class PredictionRequest (BaseModel):
    # email: Optional[EmailStr] = None
    context: str    
    prompt: str  
    tokenize: bool = False
    add_generation_prompt: bool = True
    max_new_tokens: int = 256
    do_sample: bool = True
    temperature: float = 0.7
    top_k: int = 50
    top_p: float = 0.95

    def create_pipe(self):
        return create_pipe()
    
class PredictionBatchRequest (BaseModel):
    # email: Optional[EmailStr] = None
    json_file: UploadFile = File(...)
    tokenize: bool = False
    add_generation_prompt: bool = True
    max_new_tokens: int = 256
    do_sample: bool = True
    temperature: float = 0.7
    top_k: int = 50
    top_p: float = 0.95

    def create_pipe(self):
        return create_pipe()

class Prediction (BaseModel):
    content: str

app = FastAPI(
    title="Code-llama-7b-databases-finetuned2-DEMO API",
    description="Rest API for serving LLM model predictions",
    version="1.0.0",
)

# Configure your email server
# conf = ConnectionConfig(
#     MAIL_USERNAME = os.getenv('MAIL_USERNAME'),
#     MAIL_PASSWORD = os.getenv('MAIL_PASSWORD'),
#     MAIL_FROM = os.getenv('MAIL_FROM'),
#     MAIL_PORT = int(os.getenv('MAIL_PORT', '587')),
#     MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com'),
#     MAIL_STARTTLS = os.getenv("MAIL_STARTTLS", 'True').lower() in ('true', '1', 't'),
#     MAIL_SSL_TLS = os.getenv("MAIL_SSL_TLS", 'False').lower() in ('true', '1', 't'),
#     USE_CREDENTIALS = os.getenv("USE_CREDENTIALS", 'True').lower() in ('true', '1', 't'),
#     VALIDATE_CERTS = os.getenv("VALIDATE_CERTS", 'True').lower() in ('true', '1', 't')
# )

# Add middleware for handling Cross-Origin Resource Sharing (CORS)
app.add_middleware(
    CORSMiddleware,
    # allow_origins specifies which origins are allowed to access the resource.
    # "*" means any origin is allowed. In production, replace this with a list of trusted domains.
    allow_origins=["*"],
    # allow_credentials specifies whether the browser should include credentials (cookies, authorization headers, etc.)
    # with requests. Set to True to allow credentials to be sent.
    allow_credentials=True,
    # allow_methods specifies which HTTP methods are allowed when accessing the resource.
    # "*" means all HTTP methods (GET, POST, PUT, DELETE, etc.) are allowed.
    allow_methods=["*"],
    # allow_headers specifies which HTTP headers can be used when making the actual request.
    # "*" means all headers are allowed.
    allow_headers=["*"],
)

@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)  # Process the request and get the response
    response.headers["X-Content-Type-Options"] = "nosniff"  # Prevent MIME type sniffing
    response.headers["Content-Security-Policy"] = "frame-ancestors 'self' huggingface.co"  # Prevent clickjacking
    response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"  # Enforce HTTPS
    response.headers["X-XSS-Protection"] = "1; mode=block"  # Enable XSS filter in browsers

    return response  # Return the response with the added security headers

@app.get("/heartbeat")
async def heartbeat():
    return {"status": "healthy"}

@app.post("/predict", response_model=List[Prediction], status_code=200)
async def make_prediction(request: PredictionRequest):
    try:
        # pipe = request.create_pipe()
        
        predictions = []
        
        prediction = predict(
            context=request.context,    
            prompt=request.prompt,
            pipe=pipe,
            tokenize=request.tokenize,
            add_generation_prompt=request.add_generation_prompt,
            max_new_tokens=request.max_new_tokens,
            do_sample=request.do_sample,
            temperature=request.temperature,
            top_k=request.top_k,
            top_p=request.top_p
        )

        # # If the user provided an email, send the prediction result via email
        # if request.email:
        #     await send_email(request.email, content)

        predictions.append(Prediction(content=prediction))
        
        return predictions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.post("/predict_batch", response_model=List[Prediction], status_code=200)
async def make_batch_prediction(request: PredictionBatchRequest = Depends()):
    try:
        if not request.json_file:
            raise HTTPException(status_code=400, detail="No JSON file provided.")
        
        content = await request.json_file.read()
        data = json.loads(content)
        
        if not isinstance(data, list):
            raise HTTPException(status_code=400, detail="Invalid JSON format. Expected a list of JSON objects.")
        
        # pipe = request.create_pipe()
        predictions = []
        
        for item in data:
            try:
                context = item.get('context', 'Provide an answer to the following question:')
                prompt = item['prompt']

                prediction = predict(
                    context=context,
                    prompt=prompt,
                    pipe=pipe,
                    tokenize=request.tokenize,
                    add_generation_prompt=request.add_generation_prompt,
                    max_new_tokens=request.max_new_tokens,
                    do_sample=request.do_sample,
                    temperature=request.temperature,
                    top_k=request.top_k,
                    top_p=request.top_p
                )

                predictions.append(Prediction(content=prediction))
            except KeyError:
                raise HTTPException(status_code=400, detail="Each JSON object must contain at least a 'prompt' field.")
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))
            
        # # If the user provided an email, send the prediction result via email
        # if request.email:
        #     await send_email(request.email, content)
        
        return predictions
    
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON file.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
# # Function to send email
# async def send_email(email: str, content: List[dict]):
#     # Construct the email body by iterating through the list of content objects
#     email_body = "<h1>Your AI Generated Answers</h1>"
#     for item in content:
#         instruction = item.get('instruction', 'Provide an answer to the following question:')
#         input_text = item['input']
#         output_text = item['output']
        
#         email_body += f"""
#         <h2>Instruction:</h2>
#         <p>{instruction}</p>
#         <h2>Input:</h2>
#         <p>{input_text}</p>
#         <h2>Output:</h2>
#         <p>{output_text}</p>
#         <hr>
#         """
    
#     message = MessageSchema(
#         subject="Your AI Generated Answers",
#         recipients=[email],
#         html=email_body,
#         subtype="html"
#     )

#     fm = FastMail(conf)
#     await fm.send_message(message)


# # Ensure your email configuration works
# @app.get("/test-email")
# async def test_email():
#     try:
#         await send_email(os.getenv('TEST_EMAIL'), [{
#                "instruction": "This is a test instruction.",
#                "input": "This is a test input.",
#                "output": "This is a test output.",
#            }])
#            
#         return {"message": "Test email sent successfully"}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
    
app.mount("/", StaticFiles(directory="static", html=True), name="static")

@app.get("/")
def index() -> FileResponse:
    return FileResponse(path="/app/static/index.html", media_type="text/html")