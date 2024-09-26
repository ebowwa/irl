mod openai_client;

// use std::env;
use dotenv::dotenv;
use std::io::{self, Write};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Load environment variables from a .env file
    dotenv().ok();

    // Get user prompt from input
    print!("Enter your prompt: ");
    io::stdout().flush()?; // Ensure the prompt is printed
    let mut prompt = String::new();
    io::stdin().read_line(&mut prompt)?;
    let prompt = prompt.trim(); // Clean up input

    // Call OpenAI API
    match openai_client::send_sync_request(prompt) {
        Ok(response) => {
            println!("Response from GPT-4o Mini: {}", response);
        }
        Err(e) => {
            println!("Error calling GPT-4o Mini API: {}", e);
        }
    }

    Ok(())
}
