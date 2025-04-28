import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from pydantic import BaseModel
import pandas as pd
import numpy as np

# Load environment variables
load_dotenv()

class AI:
    client = genai.Client(api_key=os.getenv("API_KEY"))

    # Load the product embeddings
    products = pd.read_csv("./AI/scraper/products_with_embeddings.csv")

    # Convert the embeddings from string to list of floats
    products["embedding"] = products["embedding"].apply(lambda x: np.fromstring(x[1:-1], sep=",").astype(float))

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
    def AI_home_response(cls, user_profile):
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
The suggestions should be practical and actionable, focusing on sustainability and eco-friendly practices. Each suggestion should have title and small description. example:

**Compost Food Scraps:** Start a compost bin to turn food scraps and yard waste into nutrient-rich soil for your garden.
 
only response the list of suggestions and nothing else. Do not add anything else to the response.""",
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction.format(user_profile=user_profile),
            ),
        )
        return response.text
    
    @classmethod
    def get_products(cls, query, start=0, count=20):
        system_instruction = """
You are EcoGenie, a friendly and helpful AI assistant passionate about sustainability.
Your purpose is to provide information, tips, and resources to help users live more eco-consciously.

You will be given a query about what the user is looking for. Products are stored in an embedding database. 
Each products had a description like this: Wooden Styling Comb. Brand: Eco Living. Categories: Haircare, Brushes & Combs. Tags: Natural, Plastic Free, Biodegradable, Sustainable. A beautiful beech wood comb with rounded teeth. Natural or wooden bristles are gentle to the hair structure and avoid damage, would suit thick or curly hair.
This description was embedded and stored in the database.
The products can belong to multiple of the following categories: ['Haircare', 'Brushes & Combs', 'Kitchen', 'Kitchen Essentials', 'Bathroom', 'Toothbrushes', 'Mama & Baby', 'Baby Bottles', 'Skincare', 'Eye Creams', 'Soap Bars', 'Facial Cleansing Soap Bars', 'Food & Drink', 'Tea', 'All Shampoo', 'Shampoo Bars', 'Body Oil', 'Deodorants', 'Deodorant Tins', 'For The Home', 'Makeup', 'Complexion', 'Foundations', 'On-The-Go', 'Produce Bags', 'Glitter', 'Glitter Sets', 'Gifts', 'Gift Sets', 'Skincare Accessories', 'All Conditioners', 'Conditioner Liquid', 'Pets Supplies', 'Dog Treats', 'Deodorant Sticks', 'Facial Serums', 'Toys & Books', "Children's Books", 'Suncream', 'Gardening', 'Face Masks', 'Shampoo Liquid', 'Stationery', 'Gift Wrap', 'Eyes', 'Eyeshadows', 'Shampoo Cubes', 'Nuts & Seeds', 'Seeds', 'Dish Cloths & Towels', 'Hair Treatments & Masks', 'Safety Razors', 'Poop Bags', 'Flour & Baking', 'Flours & Baking', 'Loose Tea', 'Kids Toothbrushes', 'Chocolate', 'All Drinking Bottles', 'Glass Bottles', 'Pacifiers & Rattles', 'Nuts', 'Herbs & Spices', 'Deodorant Glass Jars', 'Greeting Cards', 'Coffee', 'Drinking Cups', 'Kitchen Utensils', 'Single Safety Razors', 'Hand & Body Soap Bars', 'Straws', 'Bread Bags', 'Candles', 'Incense Sticks', 'All Kitchen Cleaning', 'Soap Pouches', 'Chocolate & Sweets', 'Cleaning Brushes', 'Dish Brushes', 'Cloths & Rounds', 'Cotton Rounds', 'Bathroom Cleaning', 'All Laundry', 'Laundry Accessories', 'On-The-Go Essentials', 'Household Cleaning', 'Soap Dishes', 'Tealights', 'All Lunch Boxes', 'Stainless Steel Lunch Boxes', 'Safety Razor Kits', 'Baby Wipes', 'Dish Sponges', 'Bath Bombs', 'Cotton Swabs', 'Eco-Friendly Kits', 'Vitamins', 'Pens & Pencils', 'Pens', 'Deodorant Bars', 'New Arrivals', 'Bowl Covers', 'Unpaper Towels', 'Face Creams', 'Lips', 'Lipsticks', 'Makeup Accessories', 'Makeup Brushes', 'Foot & Hand Creams', 'Toys', 'Garden Essentials', 'Makeup Palettes', 'Essential Oils', 'Legumes', 'Beans', 'String & Twine', 'Perfume & Cologne', 'Liquid Soaps', 'Body Wash', 'Face Scrubs', 'Safety Razor Accessories', 'Books', 'All Moisturisers', 'Menstrual Products', 'Menstrual Pads', 'Brows', 'Balms', 'Single Toothbrushes', 'Cotton Bags', 'Storage Baskets', 'Dental Floss', 'Makeup Pencils', 'Coffee Cups', 'Insulated Coffee Cups', 'Dried Fruit', 'Mouthwash', 'Oil Pulling Mouthwash', 'Condiments', 'Mayonnaise', 'Silicone Coffee Cups', 'Sponges', 'Toothpaste', 'Toothpaste Tablets', 'Garden Tools', 'Concealers', 'Straw Cleaning Brushes', 'Travel Utensils', 'Bath Mats', 'Toothpowders', 'Hair Styling', 'Cheeks', 'Blush & Bronzers', 'Wax Wraps', 'Wax Wrap Refresher Blocks', 'Kids Bottles', 'Body Butters', 'All Food Storage', 'Laundry Bar & Powders', 'Garden Kits', 'Bowls & Cutlery', 'Body Brushes', 'Bath Salts', 'Oils', 'Pasta, Rice & Grains', 'Rice, Grains & Cous Cous', 'Bottle Brushes', 'Hot Water Bottles', 'Hair Ties', 'Wet Bags', 'Beeswax Wraps', 'Wax Melts', 'First Aid', 'Bamboo Plasters', 'Dry Shampoo', 'Dog Shampoo', 'Bin Bags', 'Pasta & Spaghetti', 'Soda Free Deodorants', 'Multipack Toothbrushes', 'Baby Skincare', 'Baby Bowls & Utensils', 'Lip Balms', 'Laundry & Dryer Eggs', 'Dryer Eggs', 'Lunch Bags', 'Sandwich Bags', 'Hair Rinse', 'Net Bags', 'Body Wash Liquids', 'Salt', 'Highlighters', 'Natural Toothpaste', 'Period Pants', 'Laundry Liquid', 'Shaving Soap', 'Wheat Bags', 'Stainless Steel Bottles', 'Ground Coffee', 'Facial Cleansers', 'Mascaras', 'Drinkware', 'Baby Bibs', 'Organic Soap Bars', "Men's Haircare", 'Beard Care', 'Household Essentials', 'Laundry Sheets', 'Shaving Brushes', 'Glass Coffee Cups', 'Festival Essentials', 'Turkish Towels', 'Paw Salves', 'Instant Coffee', 'Hand Sanitiser', 'Shaving Accessories', 'Notepads', 'Makeup Removers', 'Tea Bags', 'Lip Scrubs', 'Conditioner Bars', 'Nails', 'Nail Polish Removers', 'Shaving Bars', 'Incense Holders', 'Chewing Gum', "Men's Skincare", 'Eyeliners', 'Cereal & Beverages', 'Cereals', 'Nut Butter', 'Peas', 'Facial Toners', 'Baby Bath Mats', 'Deodorant Refills', 'Body Scrubs', 'Toothbrush Cases', 'Finishing Powders', 'Coffee Accessories', 'Body Wash Bars & Cubes', 'Mouthwash Tablets', 'Rubber Gloves', 'Food Bags', 'Stainless Steel Straws', 'Clothing Accessories', 'Nail Polish', 'Dog Toys', 'Dish Soap', 'Washing Up', 'Shampoo Powder', 'Nail Brushes', 'DIY Cleaning Supplies', 'Organic', 'Kitchen & Home', 'Toothbrush Heads', 'Primers', 'Dog Bowls', 'Crisps', 'Cocktail Mixes', 'Bamboo Flannels', 'Tea Accessories', 'Tongue Scrapers', 'Nail Care', 'Sugar', 'Food Containers', 'Dishwasher Tablets', 'All Dental Care', 'Baby Balms', 'Laundry Eggs', 'Wash Powder', 'Tomato Ketchup', 'Gluten-Free Pasta', 'Aftersun', 'Baby Cloth Wipes', 'Baby Pacifiers', 'Christmas', 'Stocking Fillers', 'Room Sprays', 'Toilet Roll', 'Hair Wax & Clay', 'Silicone Lunch Boxes', 'Bags & Luggage', 'Coffee Capsules', 'Body Wash Foam Powder', 'Cloth Nappies', 'Cleaning Powders', 'Makeup Remover Oil', 'Crystal Deodorants', 'Vegan Wax Wraps', 'Toiletry Bags', 'Gift Vouchers', 'Menstrual Cups', 'Vinegar', 'Glue', 'Cold Cups']

Based on this, paraphrase the user's query in a way that will return the most relevant products. The products are recommended based on the dot product of the query and the product description embeddings.
"""
        # Paraphrasing the query
        response = cls.client.models.generate_content(
            model = "gemini-2.0-flash-lite",
            contents = query,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
            ),
        )
        
        # Embedding the paraphrased query
        response = cls.client.models.embed_content(
            model="text-embedding-004",
            contents=[response.text],
            config=types.EmbedContentConfig(task_type="RETRIEVAL_QUERY"))

        embedded_query = response.embeddings[0].values

        product_embeddings = cls.products
        # Finding the most similar products using dot product
        dot_product = np.dot(np.stack(cls.products["embedding"]), embedded_query)

        # Sorting the products based on similarity
        sorted_indices = np.argsort(dot_product)[::-1]

        # Getting the top 30 products
        products_to_return = cls.products.iloc[sorted_indices[start:start + count]]

        products_to_return = products_to_return[["title", "brand", "description", "image-link", "site-link"]].to_dict(orient="records")
        return products_to_return