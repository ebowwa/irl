# backend/routers/post/Hume/prosody.py
from fastapi import APIRouter, HTTPException, File, UploadFile, Form
from pydantic import BaseModel
from typing import Optional, List
from .client import hume_client  # Correctly importing the client instance
import tempfile
import os

router = APIRouter()

class URLRequest(BaseModel):
    urls: List[str]


@router.post("/hume/prosody/")
async def upload_file_or_url(file: Optional[UploadFile] = File(None), urls: Optional[str] = Form(None)):
    if file:
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
                contents = await file.read()
                temp_file.write(contents)
                temp_file_path = temp_file.name

            response = hume_client.request_user_expression_measurement([temp_file_path])
            
            os.unlink(temp_file_path)  # Delete the temporary file
            
            if "error" in response:
                raise HTTPException(status_code=400, detail=str(response["error"]))
            
            return response
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
    elif urls:
        try:
            url_list = urls.split(",")
            response = hume_client.request_user_expression_measurement(url_list)
            
            if "error" in response:
                raise HTTPException(status_code=400, detail=str(response["error"]))
            
            return response
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
    else:
        
        raise HTTPException(status_code=400, detail="Either file or URLs must be provided.")

       
@router.get("/hume/jobs/")
async def list_jobs(limit: Optional[int] = 10, status: Optional[str] = None, sort_by: Optional[str] = "created", 
                    direction: Optional[str] = "desc", created_before: Optional[int] = None, created_after: Optional[int] = None):
    """
    List jobs with optional filters.
    """
    try:
        jobs = hume_client.list_jobs(limit=limit, status=status, sort_by=sort_by, direction=direction,
                                     created_before=created_before, created_after=created_after)
        
        if "error" in jobs:
            raise HTTPException(status_code=400, detail=jobs["error"])

        return jobs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/hume/jobs/{job_id}")
async def get_job_details(job_id: str):
    """
    Retrieve job details by job ID.
    """
    try:
        job_details = hume_client.get_job_details(job_id)
        
        if "error" in job_details:
            raise HTTPException(status_code=400, detail=job_details["error"])

        return job_details
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/hume/jobs/{job_id}/predictions")
async def get_job_predictions(job_id: str):
    """
    Retrieve predictions for a completed job by job ID.
    """
    try:
        predictions = hume_client.get_job_predictions(job_id)
        
        if "error" in predictions:
            raise HTTPException(status_code=400, detail=predictions["error"])

        return predictions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/hume/jobs/{job_id}/artifacts")
async def get_job_artifacts(job_id: str):
    """
    Retrieve artifacts for a completed job by job ID.
    """
    try:
        artifacts = hume_client.get_job_artifacts(job_id)
        
        if "error" in artifacts:
            raise HTTPException(status_code=400, detail=artifacts["error"])

        return artifacts
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
