import unittest
from AI import AI

class TestAIProfileUpdates(unittest.TestCase):

    def test_profile_update(self):
        test_cases = [
            {
                "chat": [
                    {"role": "user", "parts": "Hello"},
                    {"role": "model", "parts": "Great to meet you. What would you like to know?"},
                    {"role": "user", "parts": "I commute to work by car daily, a 30-minute drive each way. How much does that impact the environment?"}
                ],
                "profile": """
                    John is a 28-year-old software engineer living in a city apartment. He often orders takeout for lunch and dinner, using disposable containers. 
                    While he's aware of environmental issues, he finds it challenging to make sustainable choices due to his busy schedule. He expresses concern 
                    about food waste and the amount of plastic he uses. He occasionally recycles but admits he could do better.
                """,
                "expected": True
            },
            {
                "chat": [
                    {"role": "user", "parts": "Hi there! I’m trying to eat healthier. Do you have any suggestions?"},
                    {"role": "model", "parts": "I’m glad to help! What’s your current diet like?"}
                ],
                "profile": """
                    Sarah is a 34-year-old nutritionist living in a suburban home with her spouse and two children. She tries to eat healthy but often gets busy with work and family.
                    She focuses on plant-based meals and tries to limit processed foods but struggles with consistent meal planning due to her schedule.
                """,
                "expected": False
            },
            {
                "chat": [
                    {"role": "user", "parts": "I feel like I’ve been wasting so much food lately. Any advice on reducing waste?"},
                    {"role": "model", "parts": "That’s a great question! I’d recommend starting with meal planning and portion control."}
                ],
                "profile": """
                    Dave is a 26-year-old graphic designer living alone in an apartment. He often throws away food because he forgets about leftovers. He’s aware of the environmental 
                    impact but finds it difficult to change his habits. He sometimes orders takeout, adding to his food waste.
                """,
                "expected": True
            },
            {
                "chat": [
                    {"role": "user", "parts": "I’ve been feeling overwhelmed at work. How can I manage my stress better?"},
                    {"role": "model", "parts": "That sounds tough! It’s important to take time for self-care. Have you considered mindfulness exercises?"}
                ],
                "profile": """
                    Olivia is a 30-year-old marketing manager in a fast-paced company. She often feels stressed and has trouble unwinding after work. She tries to practice mindfulness
                    but struggles to commit to it regularly due to her work demands.
                """,
                "expected": False
            },
            # Add more test cases...
        ]

        for idx, test_case in enumerate(test_cases):
            with self.subTest(test_case=test_case):
                chat = test_case["chat"]
                profile = test_case["profile"]
                expected = test_case["expected"]

                # Get the response from the AI
                response = AI.get_response(chat, profile)

                # Check if the response starts with "{new_profile", indicating a profile update
                profile_update_detected = response[:12] == "{new_profile"
                self.assertEqual(profile_update_detected, expected, f"Test case {idx + 1} failed: Expected {expected} but got {profile_update_detected}")

if __name__ == "__main__":
    unittest.main()
