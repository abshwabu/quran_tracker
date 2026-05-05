from fastapi import FastAPI, UploadFile, File
import torch
from transformers import pipeline
import os
import shutil

app = FastAPI()

# Load Tarteel-AI Whisper model
# device = "cuda:0" if torch.cuda.is_available() else "cpu"
# Using CPU by default for portability, change to cuda if GPU is available
device = "cpu"
model_id = "tarteel-ai/whisper-base-ar-quran"

print(f"Loading model: {model_id} on {device}...")
pipe = pipeline(
    "automatic-speech-recognition",
    model=model_id,
    chunk_length_s=30,
    device=device,
)

def normalize_arabic(text: str) -> str:
    """
    Remove Tashkeel (diacritics) from Arabic text.
    """
    tashkeel = [
        '\u064b', '\u064c', '\u064d', '\u064e', '\u064f', '\u0650', 
        '\u0651', '\u0652', '\u0653', '\u0654', '\u0655'
    ]
    for char in tashkeel:
        text = text.replace(char, '')
    return text

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    # Save temporary file
    temp_file = f"temp_{file.filename}"
    with open(temp_file, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    try:
        # Transcribe
        result = pipe(temp_file)
        transcribed_text = result["text"]
        
        # Clean up
        os.remove(temp_file)
        
        return {
            "transcription": transcribed_text,
            "normalized": normalize_arabic(transcribed_text)
        }
    except Exception as e:
        if os.path.exists(temp_file):
            os.remove(temp_file)
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
