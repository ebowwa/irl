from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import zipfile
import shutil
from pathlib import Path
import os

# 1. Initialize Router
router = APIRouter()

# 2. Define ZipHandler for file operations
class ZipHandler:
    def __init__(self, upload_dir="uploads", extract_dir="extracted"):
        # 2.1. Set directories for uploads and extraction
        self.upload_dir = Path(upload_dir)
        self.extract_dir = Path(extract_dir)
        # 2.2. Ensure directories exist
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        self.extract_dir.mkdir(parents=True, exist_ok=True)
    
    def save_zip_file(self, file: UploadFile) -> Path:
        # 2.3. Save the uploaded file to the upload directory
        file_path = self.upload_dir / file.filename
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        return file_path

    def unzip_file(self, file_path: Path) -> Path:
        # 2.4. Unzip the file into the extraction directory
        extract_path = self.extract_dir / file_path.stem
        with zipfile.ZipFile(file_path, "r") as zip_ref:
            zip_ref.extractall(extract_path)
        return extract_path
    
    def clean_up(self, file_path: Path):
        # 2.5. Delete the original ZIP file after extraction
        if file_path.exists():
            os.remove(file_path)
    
    def handle_upload(self, file: UploadFile):
        # 2.6. Orchestrate save, unzip, and cleanup
        file_path = self.save_zip_file(file)
        extracted_path = self.unzip_file(file_path)
        self.clean_up(file_path)
        return extracted_path

# 3. Instantiate the ZipHandler
zip_handler = ZipHandler()

# 4. Define FastAPI route for uploading audio ZIP
@router.post("/upload-audio-zip/")
async def upload_audio_zip(file: UploadFile = File(...)):
    # 4.1. Verify file type
    if file.content_type != "application/zip":
        raise HTTPException(status_code=400, detail="Only ZIP files are supported.")
    
    try:
        # 4.2. Use ZipHandler to save and unzip the file
        extracted_path = zip_handler.handle_upload(file)
        # 4.3. List extracted files for verification
        extracted_files = [str(path) for path in extracted_path.glob("**/*") if path.is_file()]
        
        return JSONResponse(content={
            "message": "File uploaded and extracted successfully.",
            "extracted_files": extracted_files
        })
    
    except Exception as e:
        # 4.4. Return error details if extraction fails
        raise HTTPException(status_code=500, detail=str(e))

# This router can now be included in your main FastAPI app as follows:
# from your_module_name import router
# app.include_router(router)
