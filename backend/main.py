from fastapi import FastAPI, UploadFile, File, HTTPException
import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, GenerationConfig
import os
import shutil
import librosa
import re
import traceback

app = FastAPI()

# Load Tarteel-AI Whisper model
device = "cuda:0" if torch.cuda.is_available() else "cpu"
model_id = "tarteel-ai/whisper-base-ar-quran"

print(f"Loading model: {model_id} on {device}...")
model = AutoModelForSpeechSeq2Seq.from_pretrained(
    model_id, torch_dtype=torch.float32, low_cpu_mem_usage=True, use_safetensors=True
)
model.to(device)

processor = AutoProcessor.from_pretrained(model_id)

# Create generation settings manually since the model lacks a generation_config.json
try:
    print("Loading generation config...")
    gen_config = GenerationConfig.from_pretrained(model_id)
except Exception:
    print("Generation config not found on Hub, creating from model config...")
    gen_config = GenerationConfig.from_model_config(model.config)

gen_config.update(
    language="arabic",
    task="transcribe",
    return_timestamps=False
)

def normalize_arabic(text: str) -> str:
    """
    Normalize Arabic text by removing diacritics and standardizing characters.
    Matches the logic in the Flutter app for consistency.
    """
    if not text:
        return ""

    # 1. Remove all diacritics (Tashkeel)
    tashkeel_pattern = re.compile(r'[\u064B-\u065F\u0670\u06D6-\u06ED]')
    text = tashkeel_pattern.sub('', text)

    # 2. Normalize Alif forms
    text = re.sub(r'[أإآٱ]', 'ا', text)

    # 3. Normalize Teh Marbuta to Heh
    text = text.replace('ة', 'ه')

    # 4. Normalize Ya forms (Alif Maksura, Persian Ya to Standard Ya)
    text = re.sub(r'[ىی]', 'ي', text)

    # 5. Normalize Kaf forms (Persian Kaf to Standard Kaf)
    text = text.replace('ک', 'ك')

    # 6. Remove any remaining non-Arabic-letter characters (except spaces)
    text = re.sub(r'[^\u0621-\u064A\s]', '', text)
    
    # 7. Condense multiple spaces into one
    text = re.sub(r'\s+', ' ', text)
    
    return text.strip()

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    # Save temporary file
    temp_file = f"temp_{file.filename}"
    with open(temp_file, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    try:
        print(f"Processing file: {temp_file}")
        # Load and preprocess audio
        audio, _ = librosa.load(temp_file, sr=16000)
        print(f"Audio loaded, length: {len(audio)}")
        
        input_features = processor(audio, sampling_rate=16000, return_tensors="pt").input_features
        input_features = input_features.to(device)

        print("Generating transcription...")
        with torch.no_grad():
            predicted_ids = model.generate(
                input_features, 
                generation_config=gen_config
            )
        
        transcribed_text = processor.batch_decode(predicted_ids, skip_special_tokens=True)[0]
        print(f"Transcription complete: {transcribed_text}")
        
        # Clean up
        os.remove(temp_file)
        
        return {
            "transcription": transcribed_text,
            "normalized": normalize_arabic(transcribed_text)
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
