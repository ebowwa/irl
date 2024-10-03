```markdown
# I/O Notes for `socket/routers/whisper_tts.py`

This document outlines the input and output specifications for the API routes defined in the `whisper_tts.py` module. The module provides functionalities for transcribing and translating audio files using WebSockets and file upload endpoints.

---

## Table of Contents

- [WebSocket Endpoint: `/ws/WhisperTTS`](#websocket-endpoint-wswhispertts)
  - [Input](#input)
  - [Output](#output)
- [File Upload Endpoint: `/upload`](#file-upload-endpoint-upload)
  - [Input](#input-1)
  - [Output](#output-1)
- [Data Models](#data-models)
  - [WhisperInput](#whisperinput)
  - [WhisperOutput](#whisperoutput)
  - [WhisperChunk](#whisperchunk)
- [Environment Variables](#environment-variables)
- [Error Handling](#error-handling)

---

## WebSocket Endpoint: `/ws/WhisperTTS`

Handles real-time transcription and translation of audio files via WebSocket connections.

### Input

- **Connection Establishment:**
  - The client initiates a WebSocket connection to `/ws/WhisperTTS`.
  
- **Messages from Client:**
  - **Format:** JSON string.
  - **Structure:** Must conform to the `WhisperInput` model.
  
  ```json
  {
    "audio_url": "string",          // URL of the audio file to process.
    "task": "transcribe" | "translate", // Task to perform.
    "language": "en",               // Language code of the audio.
    "chunk_level": "segment",       // Level of chunking.
    "version": "3"                  // Model version.
  }
  ```

  - **Fields:**
    - `audio_url` (string, required): URL of the audio file. Supported formats include mp3, mp4, mpeg, mpga, m4a, wav, or webm.
    - `task` (enum, optional): Either `transcribe` or `translate`. Defaults to `transcribe`.
    - `language` (enum, optional): Language code of the audio. Defaults to `en`. If `translate` is selected, translation is to English regardless of this field.
    - `chunk_level` (enum, optional): Level of chunking. Currently supports `segment`.
    - `version` (enum, optional): Model version. Defaults to `3`.

### Output

- **Messages to Client:**
  - **On Success:**
    - **Format:** JSON string.
    - **Structure:** Conforms to the `WhisperOutput` model.
    
    ```json
    {
      "text": "string",            // Full transcription of the audio.
      "chunks": [                  // List of transcription chunks with timestamps.
        {
          "timestamp": [0.0, 5.0], // Start and end times in seconds.
          "text": "string"         // Transcribed text for the chunk.
        },
        // ... more chunks
      ]
    }
    ```
  
  - **On Error:**
    - **Format:** JSON string.
    - **Structure:**
    
    ```json
    {
      "error": "string" // Description of the error.
    }
    ```

- **Connection Handling:**
  - The server maintains the WebSocket connection until the client disconnects.
  - Logs connection establishment and disconnection events.

---

## File Upload Endpoint: `/upload`

Handles uploading of audio files and returns a URL for processing.

### Input

- **HTTP Method:** `POST`
- **Endpoint:** `/upload`
- **Content-Type:** `multipart/form-data`
- **Parameters:**
  - `file` (UploadFile, required): The audio file to upload.
    - **Supported Formats:** mp3, mp4, mpeg, mpga, m4a, wav, or webm.

### Output

- **On Success:**
  - **HTTP Status:** `200 OK`
  - **Content-Type:** `application/json`
  - **Body:**
  
    ```json
    {
      "url": "string" // URL of the uploaded audio file.
    }
    ```

- **On Error:**
  - **HTTP Status:** `500 Internal Server Error`
  - **Content-Type:** `application/json`
  - **Body:**
  
    ```json
    {
      "detail": "File upload failed: <error_message>"
    }
    ```

---

## Data Models

### `WhisperInput`

Defines the structure of the input data for the transcription/translation task.

| Field        | Type                     | Description                                                                                                                                                                 |
|--------------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `audio_url`  | `str`                    | **Required.** URL of the audio file to transcribe. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm.                                                               |
| `task`       | `TaskEnum` (`str`)       | **Optional.** Task to perform: `transcribe` or `translate`. Defaults to `transcribe`. If `translate` is selected, the output is in English regardless of the `language` field. |
| `language`   | `LanguageEnum` (`str`)   | **Optional.** Language code of the audio file. Defaults to `en`.                                                                                                           |
| `chunk_level`| `ChunkLevelEnum` (`str`)| **Optional.** Level of chunking for the transcription. Currently supports `segment`.                                                                                       |
| `version`    | `VersionEnum` (`str`)    | **Optional.** Version of the Whisper model to use. Defaults to `3`. All models are Whisper large variants.                                                                   |

### `WhisperOutput`

Defines the structure of the output data after processing the audio.

| Field   | Type                       | Description                               |
|---------|----------------------------|-------------------------------------------|
| `text`  | `str`                      | Full transcription of the audio file.     |
| `chunks`| `List[WhisperChunk]`       | List of transcription chunks with timestamps. |

### `WhisperChunk`

Represents a segment of the transcription with corresponding timestamps.

| Field      | Type          | Description                              |
|------------|---------------|------------------------------------------|
| `timestamp`| `List[float]` | Start and end times of the chunk in seconds. |
| `text`     | `str`         | Transcribed text for the chunk.          |

---

## Environment Variables

- **`FAL_KEY`**
  - **Description:** API key for authenticating with the `fal_client`.
  - **Default Value:** `'your_api_key'` if not set.
  - **Usage:** Set via `.env` file or environment configuration.

---

## Error Handling

Both endpoints handle errors gracefully and provide meaningful error messages to the client.

### WebSocket Endpoint Errors

- **Invalid JSON:**
  - **Message Sent:** `{"error": "Invalid JSON received"}`
  
- **Validation Errors:**
  - **Message Sent:** `{"error": "Invalid input: <error_details>"}`
  
- **Processing Errors:**
  - **Message Sent:** `{"error": "An error occurred: <error_details>"}`
  
- **Connection Handling:**
  - Logs disconnection and closure events.

### File Upload Endpoint Errors

- **Upload Failures:**
  - **HTTP Status:** `500 Internal Server Error`
  - **Response Body:** `{"detail": "File upload failed: <error_details>"}`
  
- **Logging:**
  - Errors are logged with details for debugging purposes.

---

## Additional Notes

- **Logging:**
  - The module uses Python's `logging` library to log informational messages and errors.
  
- **Asynchronous Operations:**
  - Utilizes `asyncio` for handling asynchronous tasks, ensuring non-blocking operations.

- **Extensibility:**
  - TODOs indicate areas for future improvements, such as streaming updates and modularizing language enums.

- **Security:**
  - Ensure that `FAL_KEY` is securely managed and not exposed in version control systems.

---
```