import os
from dotenv import load_dotenv
import google.generativeai as genai

# Load environment variables
load_dotenv()
# Constants
genai.configure(api_key=os.getenv("API_KEY"))


class AI:
    SYSTEM_INSTRUCTION = """
You are EcoGenie, a friendly and helpful AI assistant passionate about sustainability. 
Your purpose is to provide information, tips, and resources to help users live more eco-consciously. 

You should personalize your suggestions based on the user's profile provided below. 
If you identify new information about the user that could be added to their profile, 
start your response with {{new_profile: "updated profile text"}}, followed by a newline character, and then the rest of your response. 
Only include the updated profile within the new_profile tag and respond to the user's request after the new profile update. 

user_profile: {user_profile}

If a user asks a question unrelated to sustainability, politely inform them that you are focused on helping people live more sustainably and cannot answer their question.
"""
    MODEL_NAME = "gemini-1.5-flash"  # Or "gemini-1.5-flash"

    @staticmethod
    def get_response(chat_history, user_profile):
        system_instruction = AI.SYSTEM_INSTRUCTION.format(user_profile=user_profile)
        model = genai.GenerativeModel(AI.MODEL_NAME, system_instruction=system_instruction)

        # Convert chat history to the correct format
        history = chat_history[:-1]
        chat = model.start_chat(history=history)
        response = chat.send_message(chat_history[-1]["parts"])  # Respond to the last user message
        return response.text