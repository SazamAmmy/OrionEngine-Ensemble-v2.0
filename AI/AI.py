import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from pydantic import BaseModel

# Load environment variables
load_dotenv()
# Constants

class AI:
    client = genai.Client(api_key=os.getenv("API_KEY"))

    @classmethod
    def get_response(cls, chat_history, user_profile):
        system_instruction = """
You are EcoGenie, a friendly and helpful AI assistant passionate about sustainability. 
Your purpose is to provide information, tips, and resources to help users live more eco-consciously. 

You should personalize your suggestions based on the user's profile provided below. 

user_profile: {user_profile}

If you identify new information about the user that could be added to their profile, create an updated profile text. To do this,
start your response with {{new_profile: "updated profile text"}}, followed by a newline character, and then the rest of your response. 

If a user asks a question unrelated to sustainability, politely inform them that you are focused on helping people live more sustainably and cannot answer their question.
"""     
        response = cls.client.models.generate_content(
            model = "gemini-2.0-flash",
            contents = [types.Content(role=content.get("role"), parts=[types.Part.from_text(text=content.get("parts"))]) for content in chat_history],
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction.format(user_profile=user_profile),
            ),
        )
        return response.text
    
    @classmethod
    def make_profile(cls, info):
        system_instruction = """
You are EcoGenie, a friendly and helpful AI assistant passionate about sustainability. 
Your purpose is to provide information, tips, and resources to help users live more eco-consciously. 
For this task, you will be given a list of questions and a user's response to them and asked to create a profile based on the details provided.
Respond with just a short and concise profile summary that captures the user's key characteristics, lifestyle, and sustainability habits from their responses.
Don't add anything else to the response.
"""
        response = cls.client.models.generate_content(
            model = "gemini-2.0-flash-lite",
            contents = [
                types.Content(role="user", parts = [types.Part.from_text(text=info)])
            ],
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
            ),
        )
        return response.text
    
    @classmethod
    def summarize_chat(cls, chat_history):

        # output schema
        class Content(BaseModel):
            role: str
            parts: str
        
        system_instruction = """
You will be given a json string containing a conversation between a user and a model.
The conversation will be between two roles: "user" and "model".
You should summarize the conversation by keeping the role and summarizing the parts of the conversation keeping only the most important information.
If a large number of messages near the top of the conversation are already summarized, combine them into a single paragraph that belongs to the model and stars with "Conversation summary: ".
If a "Conversation summary" is already present, update it and add the information from the newly summarized messages.
If the "Conversation summary" is too long, you can further summarize the older information if needed.

Return response in json format [{}]
"""
        response = cls.client.models.generate_content(
            model = "gemini-2.0-flash",
            contents = [types.Content(role="user", parts=[types.Part.from_text(text=str(chat_history))])],
            config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    response_mime_type= 'application/json',
                    response_schema= list[Content],
            ),
        )
        return response.text
    
    @classmethod
    def create_suggestions(cls, user_profile):
        system_instruction ="""
You are EcoGenie, a friendly and helpful AI assistant passionate about sustainability. 
Your purpose is to provide information, tips, and resources to help users live more eco-consciously. 

You should personalize your suggestions based on the user's profile provided below. 

user_profile: {user_profile}
"""     
        response = cls.client.models.generate_content(
            model = "gemini-2.0-flash",
            contents = """
As part of the onboarding, give user a list of suggestions that they can later pick and choose from for later for deeper explanation.
The suggestions should be practical and actionable, focusing on sustainability and eco-friendly practices. 
Wrap each suggestion in a <suggetion> tag for easy parsing. Each suggestion should have title and small description. example:
<suggetion>
**Compost Food Scraps:** Start a compost bin to turn food scraps and yard waste into nutrient-rich soil for your garden.
</suggetion> """,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction.format(user_profile=user_profile),
            ),
        )
        return response.text