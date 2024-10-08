Curls to use the LLM api/generate route

## Directly to OLLAMA (example)

```
curl -X POST "http://localhost:11434/api/generate" \
-H "Content-Type: application/json" \
-d '{
  "model": "llama3.2:1b",
  "prompt": "Tell me how you can be my life autopilot and help me in various ways.",
  "temperature": 0.7,
  "max_tokens": 150,
  "top_p": 1.0,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "stream": false
}'
```

## Proxy to OPENAI (working)
```
curl -X POST "http://localhost:8000/openai/generate-text/" \
-H "Content-Type: application/json" \
-d '{
  "api_url": "https://api.openai.com/v1",
  "model": "gpt-4o-mini",
  "system_prompt": "You are the embodiment of an autopilot for someone’s life - your AI companion: a source for augmented memory, human interpreting workers, advocator, and much more.",
  "prompt": "Tell me how you can be my life autopilot and help me in various ways.",
  "temperature": 0.7,
  "max_tokens": 150,
  "top_p": 1.0,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "n": 1
}'
```

## Proxy to Local Ollama (error)
```
curl -X POST "http://localhost:8000/openai/generate-text/" \
-H "Content-Type: application/json" \
-d '{
  "api_url": "http://localhost:11434/v1",
  "model": "llama3.2:1b",
  "system_prompt": "You are the embodiment of an autopilot for someone’s life - your AI companion: a source for augmented memory, human interpreting workers, advocator, and much more.",
  "prompt": "Tell me how you can be my life autopilot and help me in various ways.",
  "temperature": 0.7,
  "max_tokens": 150,
  "top_p": 1.0,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "n": 1
}'
```