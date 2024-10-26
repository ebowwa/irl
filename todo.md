# IMMEDIATE TODO: 
- str:task("refactor the `is speaking` to be something more reusable i.e. `i want to call it at times, have it running at time, and have this done in this framework and probably also maybe from the client.`")
- str:question("`how long is the average pause in speak for people say in like a conversation`") 
- str:categories(ui, design), note:"`i imagine this app will focus on conversation and information - the information will be primarily through text but additional media will be incorporated as well.`"
-str:note, reflection:"`my handling of the audio with the build openaudiostandard allows for using the iphone how the friend was imagined to be :)`"
- the connection and handling between the api for the gemini `ws` does work; as of now I think this can be done, 1.) websocket is discontinued as its a fasade anyway.., we then use the /chat directly and 2.) send the audio and messages(if applied)(we also allow for preseting messages to send with conent) 
- we need two initate who instances for gemini live view 
1. transcribe/diarize/translate(maybe-might be too much of a workload for 8b)
2. the api route is a chat so a second api call to take the info from the chat &OR actual audio
- if just from text chan include other ollama/openai models
    - if ollama THEN can claim privacy 
- views for the above mentioned ollama
- eventually(not MVP) images - can be done with same api..