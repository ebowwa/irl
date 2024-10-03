# I/O Notes for `backend/routers/post/embeddings/index.py`

This document outlines the input and output specifications for the embedding generation routes defined in the `backend/routers/post/embeddings/index.py` module. The routes leverage OpenAI's embedding models to generate vector representations of input text.

## Overview

The module provides two primary API endpoints:

- **POST `/small`**: Generates embeddings using the `text-embedding-3-small` model.
- **POST `/large`**: Generates embeddings using the `text-embedding-3-large` model.

Both endpoints accept the same input structure and return similar outputs, differing only in the model used for embedding generation.

---

## Common Data Models

### Request Model: `EmbeddingInput`

Defines the structure of the request body for both endpoints.

| Field       | Type    | Required | Description                                                 |
|-------------|---------|----------|-------------------------------------------------------------|
| `input_text`| `string`| Yes      | The text input for which the embedding is to be generated.  |
| `normalize` | `boolean`| No     | Indicates whether to normalize the embedding vector. Defaults to `false`. |

**Example:**

```json
{
  "input_text": "OpenAI's models are powerful tools for NLP tasks.",
  "normalize": true
}
```

### Response Model

Both endpoints return a JSON object containing the embedding vector and associated metadata.

| Field      | Type                  | Description                                                                 |
|------------|-----------------------|-----------------------------------------------------------------------------|
| `embedding`| `array of numbers`    | The generated embedding vector for the input text.                         |
| `metadata` | `object`              | Additional information about the embedding and input text.                 |

#### Metadata Fields

| Field            | Type     | Description                                                      |
|------------------|----------|------------------------------------------------------------------|
| `model`          | `string` | The name of the model used to generate the embedding.            |
| `dimensions`     | `integer`| The dimensionality of the embedding vector.                      |
| `token_count`    | `integer`| Estimated number of tokens in the input text for the model.       |
| `input_char_count`| `integer`| The number of characters in the input text.                      |
| `normalized`     | `boolean`| Indicates whether the embedding vector was normalized.            |

**Example:**

```json
{
  "embedding": [0.12, -0.34, 0.56, ...],
  "metadata": {
    "model": "text-embedding-3-small",
    "dimensions": 768,
    "token_count": 10,
    "input_char_count":  fifty,
    "normalized": true
  }
}
```

---

## API Endpoints

### 1. POST `/small`

Generates an embedding using the `text-embedding-3-small` model.

#### Request

- **Method**: `POST`
- **URL**: `/small`
- **Headers**:
  - `Content-Type: application/json`
- **Body**: JSON adhering to the `EmbeddingInput` model.

**Example Request:**

```http
POST /small HTTP/1.1
Host: your-api-domain.com
Content-Type: application/json

{
  "input_text": "Machine learning is fascinating.",
  "normalize": true
}
```

#### Response

- **Success (200 OK)**: Returns the embedding and metadata.
  
  **Example:**

  ```json
  {
    "embedding": [0.01, -0.02, 0.03, ..., 0.04],
    "metadata": {
      "model": "text-embedding-3-small",
      "dimensions": 768,
      "token_count": 5,
      "input_char_count":  thirty,
      "normalized": true
    }
  }
  ```

- **Error (500 Internal Server Error)**: Returns an error message if embedding generation fails.
  
  **Example:**

  ```json
  {
    "detail": "Failed to connect to OpenAI API."
  }
  ```

---

### 2. POST `/large`

Generates an embedding using the `text-embedding-3-large` model.

#### Request

- **Method**: `POST`
- **URL**: `/large`
- **Headers**:
  - `Content-Type: application/json`
- **Body**: JSON adhering to the `EmbeddingInput` model.

**Example Request:**

```http
POST /large HTTP/1.1
Host: your-api-domain.com
Content-Type: application/json

{
  "input_text": "Deep learning techniques have revolutionized AI.",
  "normalize": false
}
```

#### Response

- **Success (200 OK)**: Returns the embedding and metadata.
  
  **Example:**

  ```json
  {
    "embedding": [0.15, -0.25, 0.35, ..., 0.45],
    "metadata": {
      "model": "text-embedding-3-large",
      "dimensions": 1536,
      "token_count": 7,
      "input_char_count":  sixty,
      "normalized": false
    }
  }
  ```

- **Error (500 Internal Server Error)**: Returns an error message if embedding generation fails.
  
  **Example:**

  ```json
  {
    "detail": "Invalid API key provided."
  }
  ```

---

## Error Handling

Both endpoints may return a `500 Internal Server Error` in cases such as:

- Invalid or missing OpenAI API key.
- Issues connecting to the OpenAI API.
- Unexpected errors during embedding generation.

**Error Response Structure:**

```json
{
  "detail": "Detailed error message explaining the failure."
}
```

---

## Additional Notes

- **Normalization**: When the `normalize` field is set to `true`, the embedding vector is normalized using the L2 norm, resulting in a unit vector. This is useful for applications requiring cosine similarity calculations.

- **Token Estimation**: The `token_count` in metadata provides an estimate of the number of tokens in the input text based on the model's tokenizer. This can help in understanding API usage and potential costs.

- **Environment Variables**: Ensure that the `OPENAI_API_KEY` environment variable is correctly set, as it is required for authenticating requests to the OpenAI API.

- **Model Dimensions**:
  - `text-embedding-3-small`: 768 dimensions.
  - `text-embedding-3-large`: 1536 dimensions.

---

## Usage Examples

### Generating a Small Embedding

**Request:**

```http
POST /small HTTP/1.1
Host: your-api-domain.com
Content-Type: application/json

{
  "input_text": "Artificial intelligence is transforming industries.",
  "normalize": true
}
```

**Response:**

```json
{
  "embedding": [0.05, -0.10, 0.15, ..., 0.20],
  "metadata": {
    "model": "text-embedding-3-small",
    "dimensions": 768,
    "token_count": 6,
    "input_char_count":  fifty,
    "normalized": true
  }
}
```

### Generating a Large Embedding

**Request:**

```http
POST /large HTTP/1.1
Host: your-api-domain.com
Content-Type: application/json

{
  "input_text": "Natural language processing enables machines to understand human language.",
  "normalize": false
}
```

**Response:**

```json
{
  "embedding": [0.10, -0.20, 0.30, ..., 0.40],
  "metadata": {
    "model": "text-embedding-3-large",
    "dimensions": 1536,
    "token_count": 8,
    "input_char_count":  eighty,
    "normalized": false
  }
}
```

---

## Summary

This module provides straightforward endpoints to generate text embeddings using OpenAI's small and large embedding models. By adhering to the defined request and response structures, clients can seamlessly integrate embedding generation into their applications, leveraging the provided metadata for enhanced functionality and analytics.