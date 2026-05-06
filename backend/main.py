from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, GenerationConfig
import os
import shutil
import librosa
import re
import traceback

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Upgrade to Medium model for highest accuracy
# Model size: ~1.5GB. Memory requirement: ~3GB RAM.
device = "cuda:0" if torch.cuda.is_available() else "cpu"
model_id = "Habib-HF/tarbiyah-ai-whisper-medium-merged"

print(f"Loading high-accuracy model: {model_id} on {device}...")
try:
    # Use low_cpu_mem_usage and float32 for CPU compatibility
    # If on GPU, we could use float16 for even better performance
    model = AutoModelForSpeechSeq2Seq.from_pretrained(
        model_id, 
        torch_dtype=torch.float32, 
        low_cpu_mem_usage=True, 
        use_safetensors=True
    )
    model.to(device)
    processor = AutoProcessor.from_pretrained(model_id)

    # Create generation settings manually
    print("Loading generation config...")
    try:
        gen_config = GenerationConfig.from_pretrained(model_id)
    except Exception:
        print("Generation config not found, creating from defaults...")
        gen_config = GenerationConfig.from_model_config(model.config)

    # Maximize accuracy settings
    gen_config.update(
        language="arabic",
        task="transcribe",
        return_timestamps=False,
        num_beams=5,             # High precision
        do_sample=False,          # Deterministic
        begin_suppress_tokens=None, # Allow all tokens for better Quranic capture
    )
    print("Model loaded successfully.")
except Exception as e:
    print(f"FAILED to load medium model: {e}")
    traceback.print_exc()
    # Fallback plan: The server will start but /transcribe will fail with a clear error
    model = None
    processor = None

def normalize_arabic(text: str, strip_harakat: bool = True) -> str:
    """
    Normalize Arabic text. 
    """
    if not text:
        return ""

    # 1. Strip ornamental Quranic marks (always)
    ornamental = re.compile(r'[\u0670\u06D6-\u06ED]')
    text = ornamental.sub('', text)

    if strip_harakat:
        # Remove all basic diacritics
        tashkeel_pattern = re.compile(r'[\u064B-\u065F]')
        text = tashkeel_pattern.sub('', text)

    # 2. Normalize Alif forms
    text = re.sub(r'[أإآٱ]', 'ا', text)
    # 3. Normalize Teh Marbuta to Heh
    text = text.replace('ة', 'ه')
    # 4. Normalize Ya forms
    text = re.sub(r'[ىی]', 'ي', text)
    # 5. Normalize Kaf forms
    text = text.replace('ک', 'ك')

    # 6. Remove non-Arabic characters
    if strip_harakat:
        text = re.sub(r'[^\u0621-\u064A\s]', '', text)
    else:
        text = re.sub(r'[^\u0621-\u064A\u064B-\u0652\s]', '', text)
    
    # 7. Condense spaces
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    if model is None or processor is None:
        raise HTTPException(status_code=503, detail="Model failed to load on server start. Check RAM limits.")

    # Save temporary file
    temp_file = f"temp_{file.filename}"
    with open(temp_file, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    try:
        print(f"Processing file: {temp_file}")
        audio, _ = librosa.load(temp_file, sr=16000)
        
        input_features = processor(audio, sampling_rate=16000, return_tensors="pt").input_features
        input_features = input_features.to(device)

        print("Generating transcription with Medium model...")
        with torch.no_grad():
            predicted_ids = model.generate(
                input_features, 
                generation_config=gen_config
            )
        
        transcribed_text = processor.batch_decode(predicted_ids, skip_special_tokens=True)[0]
        print(f"Transcription complete.")
        
        os.remove(temp_file)
        
        return {
            "transcription": transcribed_text,
            "normalized": normalize_arabic(transcribed_text, strip_harakat=True),
            "diacritized": normalize_arabic(transcribed_text, strip_harakat=False)
        }
    except Exception as e:
        print(f"Error during transcription: {str(e)}")
        traceback.print_exc()
        if os.path.exists(temp_file):
            os.remove(temp_file)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
