# IMMEDIATE TODO:

- **Task**: Refactor the `is speaking` functionality to be reusable within the framework. The goal is to:
    - **Allow it to be called** when necessary, such as for specific actions or user interactions.
    - **Have it run at times**, continuously monitoring audio when needed (e.g., background or live detection).
    - Ensure that this functionality can be controlled **from the client side as well**, likely exposing an API or callable method that can be triggered externally or by events in the app.

## Immediate Considerations

- **Question**: Investigate the **average pause length** in speech for people during conversations:
    - **Pause per word**: Typically around **100-500 milliseconds**. This represents micro-pauses between individual words or phrases during natural speech.
    - **Pause per speaker**: These are slightly longer pauses, occurring when one speaker finishes and another begins, usually in the range of **0.2 to 1 second**.
    - **Pause in the overall conversation**: When there's a larger gap or shift in the conversation, pauses usually exceed **1 second**, which can indicate a topic change or end of dialogue.
    - The application should be flexible enough to handle these varying pause durations and integrate them into the **speech detection system**, making decisions about when the conversation has ended or requires action (e.g., stopping recording or switching modes).

### Contextual Variations in Pause Detection

1. **Adaptive Pause Thresholds**: 
    - Different contexts may require **varying pause thresholds**. For instance, formal settings might allow for longer, more deliberate pauses, while casual conversations often involve shorter pauses.
    - Consider an **adaptive threshold** mechanism or **user customization** for pause settings, allowing adjustments for fast-paced vs. slow-paced discussions.

2. **Intent-Based Actions During Pauses**:
    - **Active Listening Triggers**: For significant pauses (e.g., overall dialogue pause > 1 second), the system could prompt the user or automatically initiate actions, like **topic suggestion**, **summary generation**, or **quick responses** in chat scenarios.
    - **Contextual Pause Analysis**: Using longer pauses to detect shifts in emotional tone or hesitation could provide insights, allowing tailored system responses (e.g., providing options to clarify, confirm, or elaborate).

### Running Classifiers

- **Running Classifiers**: You may also want to run **classifiers** to categorize speech or actions during a conversation (e.g., detecting tone, emotional state, or speaker type). This could involve grouping conversations or speech segments by various classifiers.
    - **Hierarchical Classifiers**: Consider a **layered classification** system for more efficient processing:
        - **Primary Classifiers** for basics like speaker turn, language, or topic shifts.
        - **Secondary Classifiers** could focus on tone, intent, or sentiment within those categories, concentrating resources on high-value segments and reducing redundant processing.

    - **Classifier Location Trade-Off**:
        - **On-device** processing might offer **privacy** and **lower latency** but with limited model size and power.
        - **Backend** processing allows **scalability** and more complex models, with trade-offs in latency and privacy.
        - **Dynamic Resource Allocation**: Implement a **load-balancing mechanism** that decides whether classifiers should run on-device or on the backend, based on device resources, network status, and priority.

### Advanced Detection & Prediction Capabilities

5. **Predictive Model for Pauses and Speaker Intent**:
    - Using predictive models to recognize patterns in speech delivery could improve **intent prediction** (e.g., gauging whether a speaker is ending a sentence or continuing).
    - **Predictive State Switching**: Based on pause length patterns and classifier output, predictive switching could dynamically adjust the app’s modes, such as transitioning from live streaming to a paused state.

6. **Customized Feedback Loop**:
    - **Personalization of Classifier Responses**: Consider a **feedback loop** for fine-tuning classifier responses to user preferences based on historical data and user-defined categories.
    - **User-Defined Groupings**: Allow users to set preferences for certain categories or tags (e.g., tone, topic), and adjust classifier priorities to reflect these preferences, enhancing the user experience.

- **Categories**: UI, Design
    - **Note**: The app's **core focus** will revolve around conversation and information, with text as the primary form of interaction. However, additional **media** such as images, audio clips, and possibly video will be incorporated as **enhancements** over time. The challenge here is ensuring that media elements are **layered** into the UI in a non-intrusive way, ensuring **smooth transitions** between text and other formats.

- **Reflection**: Current handling of audio using **OpenAudioStandard** allows the iPhone to function in a way that mirrors the **original vision of the Friend device**. This proves effective for **real-time audio processing**, enabling seamless integration into the system while keeping it efficient. This supports flexibility in handling live conversations and background audio.

- **Gemini API/WebSocket Handling**:
    - The **WebSocket connection** for Gemini was determined to be unnecessary, acting only as a **facade**. As a result:
        1. The system will now rely on the **/chat API** directly for sending audio data and possibly text-based messages.
        2. There will be **pre-set messages** that can be queued up and sent with the content, optimizing the interaction and allowing for specific intents to be handled (e.g., automatic replies or system-generated interactions).
        
    - **Two instances of Gemini** are required to handle the workload:
        1. **Instance 1**: Dedicated to **Transcription, Diarization, and Translation** services.
            - These functions will be continuously available but there are concerns about overloading the system, particularly when using **8b**. Managing load and performance here is crucial.
        2. **Instance 2**: Handles the **chat API** interaction, taking both the **transcribed text** or **direct audio input** and sending it through for **conversational AI processing**.
            - If text-only input is used, the **option to integrate models like OpenAI or Ollama** is available.
            - If **Ollama models** are used, the app can make privacy claims since Ollama models run locally, ensuring data security and privacy.
            - Additionally, views for **Ollama-specific interactions** should be designed, ensuring a smooth user experience when switching between AI models.

- **Future Consideration (Not part of MVP)**:
    - Eventually, support for **images** will be added using the same API structure. The addition of images will serve as another mode of interaction, but the focus for now is on **text and audio** processing. Images could be handled by the same processing backend to ensure consistency and efficiency.

- **Debugging and Error Handling**:
    - Add detailed **debug messages** for when the `AudioEngineManager` stops recording, particularly in scenarios where the system stops or fails to start recording. These messages will help in troubleshooting:
        - Add a message like **"Audio engine is not running"** when it stops recording or fails to start.
        - Additional messages like **"Stopping recording..."** and **"Not currently recording"** can offer more context in error logs.
    - These messages should be available in the logs and potentially surfaced in the UI if necessary, especially for developers or advanced users trying to troubleshoot issues.
