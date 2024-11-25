- supabase or even just local sqlite for the `system_instruction` (currently "prompt_text") & `response_schema`

- `prompt_text` needs to be renamed and replaced in the api call as the `system_instruction`

### EXAMPLE OF `system_instruction` with only audio input and no additional prompting or user message. NOTE: notice the task and structured response, this request only handles the structure, not chat or otherwise, it has no persistant state, but all information can be used how we see and execute fittingly. 

```
"""
Google AI Python SDK

"""

import os
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

def upload_to_gemini(path, mime_type=None):
  """Uploads the given file to Gemini.

  See https://ai.google.dev/gemini-api/docs/prompting_with_media
  """
  file = genai.upload_file(path, mime_type=mime_type)
  print(f"Uploaded file '{file.display_name}' as: {file.uri}")
  return file

# Create the model
generation_config = {
  "temperature": 1,
  "top_p": 0.95,
  "top_k": 40,
  "max_output_tokens": 8192,
  "response_schema": content.Schema(
    type = content.Type.OBJECT,
    enum = [],
    required = ["conversation_analysis"],
    properties = {
      "conversation_analysis": content.Schema(
        type = content.Type.ARRAY,
        description = "List of analyzed turns in the conversation.",
        items = content.Schema(
          type = content.Type.OBJECT,
          enum = [],
          required = ["speaker", "text", "tone_analysis", "confidence", "summary"],
          properties = {
            "speaker": content.Schema(
              type = content.Type.STRING,
              description = "Name or identifier of the speaker.",
            ),
            "text": content.Schema(
              type = content.Type.STRING,
              description = "The spoken text of the speaker.",
            ),
            "tone_analysis": content.Schema(
              type = content.Type.OBJECT,
              description = "Analysis of the speaker's tone and associated details.",
              enum = [],
              required = ["tone", "indicators"],
              properties = {
                "tone": content.Schema(
                  type = content.Type.STRING,
                  description = "The dominant tone identified (e.g., 'confident', 'defensive').",
                ),
                "indicators": content.Schema(
                  type = content.Type.ARRAY,
                  description = "Supporting details for the identified tone.",
                  items = content.Schema(
                    type = content.Type.STRING,
                  ),
                ),
              },
            ),
            "confidence": content.Schema(
              type = content.Type.NUMBER,
              description = "Confidence score for the tone detection (0% - 100%).",
            ),
            "red_flags": content.Schema(
              type = content.Type.ARRAY,
              description = "List of potential red flags detected during the turn, if any.",
              items = content.Schema(
                type = content.Type.OBJECT,
                enum = [],
                required = ["description", "evidence"],
                properties = {
                  "description": content.Schema(
                    type = content.Type.STRING,
                    description = "Description of the red flag (e.g., 'Potential deception detected').",
                  ),
                  "evidence": content.Schema(
                    type = content.Type.ARRAY,
                    description = "Supporting evidence for the red flag.",
                    items = content.Schema(
                      type = content.Type.STRING,
                    ),
                  ),
                },
              ),
            ),
            "summary": content.Schema(
              type = content.Type.STRING,
              description = "Concise summary of the speaker's contribution to the conversation.",
            ),
          },
        ),
      ),
    },
  ),
  "response_mime_type": "application/json",
}

model = genai.GenerativeModel(
  model_name="gemini-1.5-flash",
  generation_config=generation_config,
  system_instruction="Analyze a conversation between multiple participants. For each speaker, provide:\\n\\n1. Their spoken text.\\n2. A tone analysis with categories like 'confident', 'defensive', 'hopeful', etc., along with supporting indicators (e.g., voice pitch, rhythm).\\n3. A confidence percentage for the tone detection (0% - 100%).\\n4. Highlight any potential red flags, such as signs of deception or tension, including supporting evidence (e.g., micro-expressions, pitch elevation).\\n5. Generate concise, contextual summaries of the exchange, noting key points like negotiation stances or emotional support.\\n\\nEnsure all outputs are logically structured and clearly presented in JSON format.\"",
)

# TODO Make these files available on the local file system
# You may need to update the file paths
files = [
  upload_to_gemini("Recorded Audio October 27, 2024 - 5:28PM.ogg", mime_type="audio/ogg"),
]

chat_session = model.start_chat(
  history=[
    {
      "role": "user",
      "parts": [
        files[0],
      ],
    },
    {
      "role": "model",
      "parts": [
        "```json\n{\"conversation_analysis\": [{\"confidence\": 90, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains the difference between TCP and UDP protocols, emphasizing the three-way handshake in TCP for reliable data transmission.\", \"text\": \"Alright, so you have your local machine and you have your server. In a TCP protocol, you have to ensure that all the things that go that you uh show in your local, like all the data, it's sent back correctly. Like think about uh rendering rendering an article, right? You want the article to be sent back direct.\", \"tone_analysis\": {\"indicators\": [\"clear explanations\", \"confident tone\"], \"tone\": \"confident\"}}, {\"confidence\": 85, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 inquires about the specifics of data transmission in TCP, questioning the method of sending data (bits) and the nature of the connection (active or request-based).\", \"text\": \"So how does it send it? Does it send it like bits? Does it send it like?\", \"tone_analysis\": {\"indicators\": [\"curious intonation\", \"questioning rhythm\"], \"tone\": \"curious\"}}, {\"confidence\": 95, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains that TCP sends data in bits but prioritizes establishing a connection with the local machine before transmission.\", \"text\": \"So it okay, good question. It sends uh yes, bits, but before it can send it, it has to ensure a connection with the local uh machine.\", \"tone_analysis\": {\"indicators\": [\"calm and clear response\", \"steady pace\"], \"tone\": \"calm\"}}, {\"confidence\": 80, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 compares TCP with other protocols (HTTP, POST) and probes the differences between TCP and UDP, particularly concerning connection types.\", \"text\": \"How does it so how does it differ from like just like um so uh is this like an active connection or is it just like requests? Okay, so UDP Is it like post or is it like websocket?\", \"tone_analysis\": {\"indicators\": [\"inquisitive phrasing\", \"rapid-fire questions\"], \"tone\": \"inquisitive\"}}, {\"confidence\": 92, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 clarifies that TCP uses a request-response method, unlike UDP, and further explains the three-way handshake mechanism in TCP for reliable communication.\", \"text\": \"It's a request. So it's a request. So it's like a post. Why not just use like HTTP? So is why not what is the difference between the protocols between TCP and then UDP? So so okay, so so essentially, it's just like a socket then? Okay, so let me just explain the difference between the two and then you'll understand what makes TCP and UDP different. And yes, HTTP and HTTPS fall under TCP. So under TCP you do a three-way handshake. Three-way handshake means hey, hey back, boom, right? Like hey, I acknowledge. Hey, acknowledge a hey, acknowledge a hey back.\", \"tone_analysis\": {\"indicators\": [\"thorough explanation\", \"confident delivery\"], \"tone\": \"confident\"}}, {\"confidence\": 75, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 seeks clarification on the parent-child relationship within the TCP protocol and the role of HTTP.\", \"text\": \"Which is the child? Which is the parent relationship?\", \"tone_analysis\": {\"indicators\": [\"slightly confused tone\"], \"tone\": \"confused\"}}, {\"confidence\": 98, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains the three-way handshake in detail, highlighting its purpose for ensuring reliable data transmission of articles or metadata.\", \"text\": \"So the reason that we do this three-way handshake is because we want to send this article or the metadata and data for the article correctly, so that you you you view the article correctly. In a UDP, think of a soccer game, right? In a UDP there is no three-way handshake. There is no like uh request. UDP just goes boom boom boom boom boom. It doesn't care the ordering.\", \"tone_analysis\": {\"indicators\": [\"detailed explanation\", \"patient tone\"], \"tone\": \"patient\"}}, {\"confidence\": 88, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 observes that UDP doesn't wait for a response, prompting further discussion about real-time applications.\", \"text\": \"It's not looking for any response back.\", \"tone_analysis\": {\"indicators\": [\"observational tone\", \"calm pace\"], \"tone\": \"observational\"}}, {\"confidence\": 96, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains why UDP is suitable for real-time applications like live soccer games or video games, where speed is prioritized over reliability.\", \"text\": \"It doesn't exactly. Why? Because in a uh live soccer game or when you're playing video games with your buddies, everything's quick. Everything's like it happens real time.\", \"tone_analysis\": {\"indicators\": [\"clear reasoning\", \"confident tone\"], \"tone\": \"confident\"}}, {\"confidence\": 78, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 explores the application of these concepts within high-level frameworks like Next.js, questioning the feasibility and compatibility.\", \"text\": \"So you can do this with something so high level is Next.js? I'm sorry. You can like I suppose yes, but Next.js right, is a framework. It's very high level and abstract, right? Where like a lot of this has been abstracted away, right?\", \"tone_analysis\": {\"indicators\": [\"tentative questions\", \"hesitant tone\"], \"tone\": \"tentative\"}}, {\"confidence\": 90, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains that Next.js is a high-level framework, abstracting away many low-level details, and clarifies the distinction between frameworks and libraries.\", \"text\": \"So configuring, you know, I'm I'm wrong, sorry. You cut me off. But maybe it was correct. What is Next.js? Next.js is like a framework, right? Uh it's like FastAPI. It's like FastAPI but for like JavaScript, but in TypeScript, right? For what's what is Next.js specifically specify or um servers?\", \"tone_analysis\": {\"indicators\": [\"confident and clear explanation\", \"calm delivery\"], \"tone\": \"confident\"}}, {\"confidence\": 70, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 probes the layer of the ISO model where Next.js operates, demonstrating a lack of complete understanding of the concept.\", \"text\": \"What aspect of the the ISO layer, right? Does Next.js work on? What is the ISO layer? I don't define it, define it.\", \"tone_analysis\": {\"indicators\": [\"uncertain tone\", \"hesitant questioning\"], \"tone\": \"uncertain\"}}, {\"confidence\": 97, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 defines the ISO layer model, elaborating on its seven layers from physical wires to applications, illustrating the model's hierarchical structure.\", \"text\": \"All right, so the ISO layer breaks down the entire communication into seven different layers, right? Like at the very bare bones, you've got little freaking wires, right? Like you need wires, you need electricity to go into the computer to break it into bits. That's the first layer, right? All the way down to the seventh layer, it's basically applications. Second layer is uh hoppers, right? So what is the network? What is the internet? It's a bunch of like fiber optic cables, routers, routers right, redirecting data to this router to that other router. So basically, it goes through here, it goes to the this is local, it goes to the internet, which looks something like like that, let's say. And then it goes to the server, right?\", \"tone_analysis\": {\"indicators\": [\"detailed and clear explanation\", \"confident tone\", \"animated delivery\"], \"tone\": \"confident\"}}, {\"confidence\": 82, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 asks how the system determines the specific server to which data should be routed, raising a question about IP routing.\", \"text\": \"Let's say you want to go to this specific server, how does it know to do that? Or let's say this is my machine, my computer, and this is your computer. How does it know?\", \"tone_analysis\": {\"indicators\": [\"inquisitive tone\", \"logical line of questioning\"], \"tone\": \"inquisitive\"}}, {\"confidence\": 93, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains the role of IP routing (IPv4, IPv6) in directing data to the correct server, locating this functionality within the ISO model.\", \"text\": \"IP routing machine. Exactly, routing with IPv4, IPv6. Exactly. So this is that somewhere here in the um ISO layer. So I'm asking where in this ISO layer is uh Next.js?\", \"tone_analysis\": {\"indicators\": [\"clear explanation\", \"confident tone\"], \"tone\": \"confident\"}}, {\"confidence\": 72, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 attempts to pinpoint the location of Next.js within the ISO model's layers, indicating uncertainty.\", \"text\": \"Where is it? Is it V6, right? No. Is it at V4?\", \"tone_analysis\": {\"indicators\": [\"hesitant tone\", \"uncertain questioning\"], \"tone\": \"uncertain\"}}, {\"confidence\": 91, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 clarifies that Next.js operates at a higher level (application layer), emphasizing its role as a framework rather than a low-level networking component.\", \"text\": \"Next.js is just a framework. It's just a It's what I said. It's just a framework. It's just a JavaScript framework. Okay, so so it's essentially like a library but like it's not a library, it's a framework, right? It's like I guess you can think about it as a library. Kind of. It's like but not a bundler, like but not a bundler, cause that's definitionally useless. But it's part of the uh application layer. So what I'm basically saying is that you need to go a little bit more um like high level, like abstract, right?\", \"tone_analysis\": {\"indicators\": [\"confident explanation\", \"patient tone\"], \"tone\": \"confident\"}}, {\"confidence\": 85, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 reflects on the higher-level abstraction of Next.js and questions the possibility of low-level configuration within the framework.\", \"text\": \"You actually need to go lower level in order to like optimize this right here to configure this, right? But like is that possible within the framework or would you like within the Next.js framework? Nevermind, nevermind. I'm probably mistaken. Is this something you can just code in JavaScript?\", \"tone_analysis\": {\"indicators\": [\"reflective tone\", \"self-correcting\"], \"tone\": \"reflective\"}}, {\"confidence\": 94, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 explains that while some things can be done in Javascript, lower-level networking tasks are better suited to languages like C++ or Assembly language.\", \"text\": \"Can you put this in JavaScript? Is it networking or is it JavaScript? Okay, actually, you can't. You can do a lot of things in JavaScript. That's a bad question. If you'd want to do it in C++. Yeah, that's some trash. optimal language. Or if you were like really good with uh assembly language, which fuck assembly. Well, like alien at that point. No, binary. Does anybody know can nobody speak binary? It takes too long. They used to. It takes too long. They used to have like these punches.\", \"tone_analysis\": {\"indicators\": [\"confident and clear explanation\", \"slightly frustrated tone\"], \"tone\": \"confident\"}}, {\"confidence\": 80, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 comments on the impracticality of using binary for modern programming due to time constraints, although acknowledging historical methods.\", \"text\": \"They would have like smaller strings. There's no way. I like it would take too long. No dude, they punched holes on a card. And a non-punched hole would be um a one. A punched hole would be zero. That's how they used to do it.\", \"tone_analysis\": {\"indicators\": [\"calm and informative tone\"], \"tone\": \"informative\"}}, {\"confidence\": 92, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 summarizes the limitations of JavaScript for low-level networking tasks and directly answers the initial question regarding framework compatibility.\", \"text\": \"So, I mean really I mean, like the options are so smaller at that point, right? But to answer your question, sorry, to answer your question, no you cannot do this just through a framework alone.\", \"tone_analysis\": {\"indicators\": [\"direct and clear answer\", \"confident tone\"], \"tone\": \"confident\"}}, {\"confidence\": 76, \"speaker\": \"Speaker2\", \"summary\": \"Speaker2 clarifies their question regarding compatibility and expresses satisfaction with the resolved query.\", \"text\": \"I was just wondering if you could is it compatible with the framework? But I think it answered the question is resolved.\", \"tone_analysis\": {\"indicators\": [\"clarification\", \"calm tone\"], \"tone\": \"calm\"}}, {\"confidence\": 89, \"speaker\": \"Speaker1\", \"summary\": \"Speaker1 confirms compatibility indirectly and concludes by mentioning the involvement of the ISO layer and the need for lower-level considerations when hosting.\", \"text\": \"Compatible? Yes, yes, yes. It's all part of the ISO layer, like you just have to do whatever. Well, well hosting within their within their network, right? Within their I don't know, never mind. I don't know how to articulate it. Let's see what AI says about this. Yeah, I guess so.\", \"tone_analysis\": {\"indicators\": [\"confident affirmation\", \"concluding remarks\"], \"tone\": \"confident\"}}]}\n```",
      ],
    },
  ]
)

response = chat_session.send_message("INSERT_INPUT_HERE")

print(response.text)
```

Note: this example above, is just an example, to follow or use as reference.

- what if i intend to do further structured async requests to an object like a user submitted audio file