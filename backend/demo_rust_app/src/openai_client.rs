use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;
use tokio::runtime::Runtime;

/// Struct representing the request body to send to the OpenAI API.
/// 
/// # Fields
/// 
/// * `model`: The model ID used for generating a response, e.g., "gpt-4o-mini".
/// * `messages`: A vector containing conversation history with `Message` structs, such as system/user input.
/// * `max_tokens`: The maximum number of tokens to generate in the completion.
/// * `temperature`: A value to control randomness. Higher values make output more random.
#[derive(Serialize)]
struct OpenAIRequest {
    model: String,
    messages: Vec<Message>,
    max_tokens: u32,
    temperature: f64,
}

/// Struct representing a single message in a conversation.
/// 
/// # Fields
/// 
/// * `role`: The role of the message author. Can be "system", "user", or "assistant".
/// * `content`: The content of the message.
#[derive(Serialize)]
struct Message {
    role: String,
    content: String,
}

/// Struct representing the response from the OpenAI API.
/// 
/// # Fields
/// 
/// * `choices`: A vector of `Choice` structs representing different response choices from the API.
#[derive(Deserialize)]
struct OpenAIResponse {
    choices: Vec<Choice>,
}

/// Struct representing a choice from the OpenAI response.
/// 
/// # Fields
/// 
/// * `message`: A `MessageResponse` that contains the actual content returned by the model.
#[derive(Deserialize)]
struct Choice {
    message: MessageResponse,
}

/// Struct representing the content of the response from the model.
/// 
/// # Fields
/// 
/// * `content`: The generated text from the model.
#[derive(Deserialize)]
struct MessageResponse {
    content: String,
}

/// Sends an asynchronous request to the OpenAI API with the provided prompt.
///
/// # Arguments
///
/// * `prompt`: A string slice that holds the prompt to send to the OpenAI API.
///
/// # Returns
///
/// Returns a `Result<String, Box<dyn std::error::Error>>` containing the response text from the model,
/// or an error if something went wrong during the request.
///
/// # Errors
///
/// Returns an error if the environment variable `OPENAI_API_KEY` is missing, the request fails,
/// or the response cannot be parsed.
pub async fn send_openai_request(prompt: &str) -> Result<String, Box<dyn std::error::Error>> {
    // Retrieve the OpenAI API key from environment variables.
    let api_key = env::var("OPENAI_API_KEY").expect("Missing OPENAI_API_KEY in environment");

    // Create an HTTP client instance.
    let client = Client::new();
    
    // Prepare the request body for the OpenAI API.
    let request_body = OpenAIRequest {
        model: "gpt-4o-mini".to_string(), // Model ID to use for generation.
        messages: vec![
            // System message defines the assistant's behavior.
            Message { role: "system".to_string(), content: "You are a helpful assistant.".to_string() },
            // User's prompt message.
            Message { role: "user".to_string(), content: prompt.to_string() },
        ],
        max_tokens: 1000,  // Limit the response length to 1000 tokens.
        temperature: 0.7,  // Temperature for randomness in response generation.
    };

    // Send the POST request to the OpenAI API.
    let response = client
        .post("https://api.openai.com/v1/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))  // Pass the API key in the Authorization header.
        .json(&request_body)  // Send the request body as JSON.
        .send()
        .await?  // Await the response from the API.
        .json::<OpenAIResponse>()  // Parse the response body as JSON.
        .await?;

    // Extract the content of the first choice from the API response.
    let response_text = response
        .choices
        .first()
        .map(|choice| choice.message.content.clone())  // Map the first choice to its content.
        .unwrap_or_else(|| "No response from API".to_string());  // Default message if no response.

    // Return the extracted response text.
    Ok(response_text)
}

/// Sends a synchronous request to the OpenAI API by blocking on the async request.
///
/// # Arguments
///
/// * `prompt`: A string slice that holds the prompt to send to the OpenAI API.
///
/// # Returns
///
/// Returns a `Result<String, Box<dyn std::error::Error>>` containing the response text from the model,
/// or an error if something goes wrong during the request.
///
/// # Errors
///
/// Returns an error if the request fails or the async runtime cannot be created.
pub fn send_sync_request(prompt: &str) -> Result<String, Box<dyn std::error::Error>> {
    // Create a new Tokio runtime to block on the async request.
    let rt = Runtime::new()?;
    // Block the current thread until the async request completes and return the result.
    rt.block_on(send_openai_request(prompt))
}
