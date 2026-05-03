#!/usr/bin/env python3
"""
Script to generate example sentences for Swedish words in testWords.json

This script can work in two modes:
1. Template-based: Creates simple sentences using common Swedish patterns
2. AI-based: Uses OpenAI API to generate more natural sentences (requires API key)

Usage:
    python3 generate_sentences.py [--use-ai] [--api-key YOUR_KEY]
"""

import json
import sys
import argparse
from typing import Dict, List, Optional

# Common Swedish sentence templates
SENTENCE_TEMPLATES = [
    "Jag ser {word}.",
    "Det är {word}.",
    "Jag har {word}.",
    "Jag vill ha {word}.",
    "Jag gillar {word}.",
    "Jag behöver {word}.",
    "Jag köper {word}.",
    "Jag äter {word}.",
    "Jag dricker {word}.",
    "Jag läser om {word}.",
    "Jag tänker på {word}.",
    "Jag pratar om {word}.",
    "Jag arbetar med {word}.",
    "Jag reser till {word}.",
    "Jag bor i {word}.",
    "Jag går till {word}.",
    "Jag kommer från {word}.",
    "Jag träffar {word}.",
    "Jag hjälper {word}.",
    "Jag lär mig {word}.",
    "Det finns {word}.",
    "Det blir {word}.",
    "Det var {word}.",
    "Det kan vara {word}.",
    "Det måste vara {word}.",
    "Det ska vara {word}.",
    "Det borde vara {word}.",
    "Det verkar vara {word}.",
    "Det låter som {word}.",
    "Det ser ut som {word}.",
    "Jag är {word}.",
    "Du är {word}.",
    "Han är {word}.",
    "Hon är {word}.",
    "Vi är {word}.",
    "De är {word}.",
    "Jag kan {word}.",
    "Jag måste {word}.",
    "Jag vill {word}.",
    "Jag ska {word}.",
    "Jag borde {word}.",
    "Jag brukar {word}.",
    "Jag försöker {word}.",
    "Jag börjar {word}.",
    "Jag slutar {word}.",
    "Jag fortsätter {word}.",
    "Jag hoppas på {word}.",
    "Jag väntar på {word}.",
    "Jag letar efter {word}.",
    "Jag söker efter {word}.",
    "Jag hittar {word}.",
    "Jag tar {word}.",
    "Jag ger {word}.",
    "Jag får {word}.",
    "Jag ser {word}.",
    "Jag hör {word}.",
    "Jag känner {word}.",
    "Jag smakar {word}.",
    "Jag luktar {word}.",
    "Jag tänker på {word}.",
    "Jag minns {word}.",
    "Jag glömmer {word}.",
    "Jag förstår {word}.",
    "Jag lär mig {word}.",
    "Jag undervisar {word}.",
    "Jag lär ut {word}.",
    "Jag studerar {word}.",
    "Jag övar {word}.",
    "Jag tränar {word}.",
    "Jag spelar {word}.",
    "Jag sjunger {word}.",
    "Jag dansar {word}.",
    "Jag springer {word}.",
    "Jag går {word}.",
    "Jag cyklar {word}.",
    "Jag kör {word}.",
    "Jag flyger {word}.",
    "Jag simmar {word}.",
    "Jag hoppar {word}.",
    "Jag klättrar {word}.",
    "Jag faller {word}.",
    "Jag stiger {word}.",
    "Jag sitter {word}.",
    "Jag står {word}.",
    "Jag ligger {word}.",
    "Jag sover {word}.",
    "Jag vaknar {word}.",
    "Jag äter {word}.",
    "Jag dricker {word}.",
    "Jag lagar {word}.",
    "Jag bakar {word}.",
    "Jag steker {word}.",
    "Jag kokar {word}.",
    "Jag serverar {word}.",
    "Jag beställer {word}.",
    "Jag betalar {word}.",
    "Jag köper {word}.",
    "Jag säljer {word}.",
    "Jag byter {word}.",
    "Jag lånar {word}.",
    "Jag ger tillbaka {word}.",
    "Jag behåller {word}.",
    "Jag förlorar {word}.",
    "Jag vinner {word}.",
    "Jag hittar {word}.",
    "Jag tappar {word}.",
    "Jag hittar {word} igen.",
    "Jag letar efter {word}.",
    "Jag söker efter {word}.",
    "Jag hittar {word}.",
    "Jag försöker hitta {word}.",
    "Jag kan hitta {word}.",
    "Jag måste hitta {word}.",
    "Jag vill hitta {word}.",
    "Jag ska hitta {word}.",
    "Jag borde hitta {word}.",
    "Jag brukar hitta {word}.",
    "Jag försöker hitta {word}.",
    "Jag börjar hitta {word}.",
    "Jag slutar hitta {word}.",
    "Jag fortsätter hitta {word}.",
    "Jag hoppas hitta {word}.",
    "Jag väntar på att hitta {word}.",
    "Jag letar efter {word}.",
    "Jag söker efter {word}.",
    "Jag hittar {word}.",
    "Jag försöker hitta {word}.",
    "Jag kan hitta {word}.",
    "Jag måste hitta {word}.",
    "Jag vill hitta {word}.",
    "Jag ska hitta {word}.",
    "Jag borde hitta {word}.",
    "Jag brukar hitta {word}.",
    "Jag försöker hitta {word}.",
    "Jag börjar hitta {word}.",
    "Jag slutar hitta {word}.",
    "Jag fortsätter hitta {word}.",
    "Jag hoppas hitta {word}.",
    "Jag väntar på att hitta {word}.",
]

def generate_template_sentence(word: str, english: str) -> str:
    """Generate a simple sentence using templates with smarter selection."""
    import random
    
    word_lower = word.lower()
    english_lower = english.lower().strip()
    
    # Check order: Verbs FIRST (before adjectives), then adjectives, then others
    
    # 1. VERBS - Check first to avoid misclassification
    verb_keywords = ['save', 'book', 'answer', 'repeat', 'wish', 'do', 'say', 'go', 'see', 
                    'know', 'take', 'give', 'find', 'come', 'become', 'leave', 'live', 
                    'begin', 'stop', 'talk', 'hear', 'play', 'work', 'read', 'write', 
                    'buy', 'sell', 'eat', 'drink', 'sleep', 'wake', 'wash', 'open', 
                    'close', 'call', 'visit', 'travel', 'fly', 'drive', 'run', 'jump', 
                    'swim', 'bike', 'wait', 'try', 'need', 'think', 'believe', 
                    'understand', 'learn', 'help']
    
    is_verb = (english_lower.startswith('to ') or 
              any(english_lower == kw or english_lower.startswith(kw + ' ') or 
                  english_lower.startswith(kw + '(') for kw in verb_keywords))
    
    if is_verb:
        templates = [
            "Jag kan {word}.",
            "Jag måste {word}.",
            "Jag vill {word}.",
            "Jag ska {word}.",
            "Jag borde {word}.",
            "Jag brukar {word}.",
            "Jag försöker {word}.",
            "Jag börjar {word}.",
        ]
        template = random.choice(templates)
    
    # 2. ADJECTIVES - Check after verbs
    elif any(english_lower == kw or 
             english_lower.startswith(kw + ' ') or 
             english_lower.startswith(kw + '/') or
             english_lower.startswith(kw + '(')
             for kw in ['good', 'bad', 'big', 'small', 'hot', 'cold', 'new', 'old', 'young', 
                       'rich', 'poor', 'happy', 'sad', 'tired', 'beautiful', 'ugly', 'fast', 
                       'slow', 'high', 'low', 'wide', 'narrow', 'deep', 'shallow', 'heavy', 
                       'light', 'dark', 'clean', 'dirty', 'empty', 'open', 'closed', 'red', 
                       'blue', 'green', 'yellow', 'white', 'black', 'gray', 'pink', 'purple', 
                       'simple', 'difficult', 'important', 'safe', 'dangerous', 'free', 
                       'expensive', 'cheap', 'quiet', 'loud', 'soft', 'hard', 'wet', 'dry', 
                       'cool', 'sweet', 'sour', 'salty', 'tasty', 'clear', 'true', 'false', 
                       'right', 'wrong', 'brave', 'afraid', 'friendly', 'kind', 'mean', 'wise', 
                       'stupid', 'clever', 'patient', 'impatient', 'hungry', 'awake', 'sleepy', 
                       'healthy', 'sick', 'strong', 'weak', 'tall', 'short', 'nice', 'just', 'only']):
        # For adjectives, use proper subject + är (is) construction
        # Avoid nonsensical combinations - prefer personal subjects for personal adjectives
        personal_adjectives = ['hungry', 'tired', 'happy', 'sad', 'rich', 'poor', 'young', 'old', 'sick', 'healthy', 'afraid', 'brave']
        is_personal_adj = any(adj in english_lower for adj in personal_adjectives)
        
        if is_personal_adj:
            # Use personal subjects for personal adjectives
            templates = [
                "Jag är {word}.",
                "Du är {word}.",
                "Han är {word}.",
                "Hon är {word}.",
            ]
        else:
            # For other adjectives, can use "Det är" for things
            templates = [
                "Jag är {word}.",
                "Du är {word}.",
                "Det är {word}.",
                "Det var {word}.",
            ]
        template = random.choice(templates)
    
    # 3. Time/place words (now, today, here, there, etc.) - these are adverbs
    elif english_lower in ['now', 'today', 'yesterday', 'tomorrow', 'here', 'there', 'when', 'where', 'why', 'how']:
        if word_lower == 'nu':
            templates = ["Jag gör det nu.", "Det är nu.", "Nu är det dags.", "Nu kommer jag."]
        elif word_lower == 'idag':
            templates = ["Jag gör det idag.", "Det är idag.", "Idag är det bra väder.", "Idag kommer jag."]
        elif word_lower == 'igår':
            templates = ["Jag gjorde det igår.", "Det var igår.", "Igår var det bra väder.", "Igår kom jag."]
        elif word_lower == 'imorgon':
            templates = ["Jag gör det imorgon.", "Det blir imorgon.", "Imorgon kommer jag.", "Imorgon är det bra väder."]
        elif word_lower == 'här':
            templates = ["Jag är här.", "Det är här.", "Här är det bra.", "Kom hit här."]
        elif word_lower == 'där':
            templates = ["Jag är där.", "Det är där.", "Där är det bra.", "Gå dit där."]
        else:
            templates = ["Jag gör det {word}.", "Det är {word}.", "{word} är bra."]
        template = random.choice(templates)
    
    # Pronouns (I, you, he, she, we, they, it) - use as subject, not object
    elif english_lower in ['i', 'you', 'he', 'she', 'we', 'they', 'it']:
        # For pronouns, use them as subjects, not objects
        if word_lower == 'jag':
            templates = ["Jag är här.", "Jag kommer.", "Jag går.", "Jag ser dig."]
        elif word_lower == 'du':
            templates = ["Du är här.", "Du kommer.", "Du går.", "Jag ser dig."]
        elif word_lower == 'han':
            templates = ["Han är här.", "Han kommer.", "Han går.", "Jag ser honom."]
        elif word_lower == 'hon':
            templates = ["Hon är här.", "Hon kommer.", "Hon går.", "Jag ser henne."]
        elif word_lower == 'vi':
            templates = ["Vi är här.", "Vi kommer.", "Vi går.", "Jag ser oss."]
        elif word_lower == 'de':
            templates = ["De är här.", "De kommer.", "De går.", "Jag ser dem."]
        elif word_lower == 'det':
            templates = ["Det är här.", "Det finns.", "Det blir bra.", "Jag ser det."]
        else:
            templates = ["{word} är här.", "{word} kommer.", "{word} går."]
        template = random.choice(templates)
    
    # Nouns (objects, people, places) - use more natural patterns
    else:
        # Check if it's a place/location
        if any(keyword in english_lower for keyword in ['city', 'town', 'place', 'country', 'street', 'road', 'restaurant', 'shop', 'store', 'hotel', 'beach', 'forest', 'mountain', 'lake', 'sea']):
            templates = [
                "Jag bor i {word}.",
                "Jag reser till {word}.",
                "Jag kommer från {word}.",
                "Jag går till {word}.",
                "Det finns {word}.",
            ]
        elif 'house' in english_lower or 'home' in english_lower:
            templates = [
                "Jag bor i {word}.",
                "Jag ser {word}.",
                "Jag går hem till {word}.",
                "Det finns {word}.",
            ]
        # Check if it's food/drink
        elif any(keyword in english_lower for keyword in ['food', 'meal', 'breakfast', 'dinner', 'water', 'milk', 'coffee', 'tea', 'bread', 'butter', 'cheese', 'egg', 'meat', 'chicken', 'fish', 'vegetable', 'fruit', 'apple', 'banana', 'orange']):
            templates = [
                "Jag äter {word}.",
                "Jag dricker {word}.",
                "Jag köper {word}.",
                "Jag gillar {word}.",
                "Jag behöver {word}.",
            ]
        # Check if it's a person
        elif any(keyword in english_lower for keyword in ['person', 'woman', 'man', 'child', 'boy', 'girl', 'baby', 'adult', 'family', 'mom', 'dad', 'brother', 'sister', 'friend', 'neighbor', 'teacher', 'student', 'doctor']):
            templates = [
                "Jag träffar {word}.",
                "Jag ser {word}.",
                "Jag hjälper {word}.",
                "Jag pratar med {word}.",
            ]
        # Check if it's clothing
        elif any(keyword in english_lower for keyword in ['clothes', 'shirt', 'pants', 'skirt', 'dress', 'shoes', 'hat', 'jacket', 'coat']):
            templates = [
                "Jag har {word}.",
                "Jag köper {word}.",
                "Jag bär {word}.",
                "Jag behöver {word}.",
            ]
        # Default for other nouns
        else:
            templates = [
                "Jag ser {word}.",
                "Jag har {word}.",
                "Jag vill ha {word}.",
                "Jag gillar {word}.",
                "Jag behöver {word}.",
                "Jag köper {word}.",
                "Jag tänker på {word}.",
                "Jag pratar om {word}.",
                "Det finns {word}.",
            ]
        template = random.choice(templates)
    
    # Try to format the template with the word
    try:
        sentence = template.format(word=word_lower)
        # Capitalize first letter
        sentence = sentence[0].upper() + sentence[1:] if len(sentence) > 1 else sentence.upper()
        return sentence
    except:
        # Fallback: simple sentence
        return f"Jag ser {word_lower}."

def generate_ai_sentence(word: str, english: str, api_key: Optional[str] = None) -> str:
    """Generate a sentence using OpenAI API."""
    try:
        import openai
        
        if not api_key:
            print(f"⚠️  No API key provided, using template for '{word}'")
            return generate_template_sentence(word, english)
        
        openai.api_key = api_key
        
        prompt = f"Create a simple, short Swedish sentence using the word '{word}' (which means '{english}' in English). The sentence should be natural, easy to understand, and help someone learn the word. Only return the sentence, nothing else."
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful Swedish language teacher."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=50,
            temperature=0.7
        )
        
        sentence = response.choices[0].message.content.strip()
        # Remove quotes if present
        sentence = sentence.strip('"').strip("'")
        return sentence
        
    except ImportError:
        print("⚠️  OpenAI library not installed. Install with: pip install openai")
        return generate_template_sentence(word, english)
    except Exception as e:
        print(f"⚠️  Error generating AI sentence for '{word}': {e}")
        return generate_template_sentence(word, english)

def process_json_file(input_file: str, output_file: str, use_ai: bool = False, api_key: Optional[str] = None):
    """Process the JSON file and add sentences."""
    print(f"📖 Reading {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"✅ Found {len(data)} words")
    
    # Count how many already have sentences
    existing_sentences = sum(1 for item in data if item.get('sentence'))
    print(f"📝 {existing_sentences} words already have sentences")
    
    # Process words
    updated_count = 0
    for i, item in enumerate(data):
        if not item.get('sentence'):
            word = item.get('swedish', '')
            english = item.get('english', '')
            
            if use_ai:
                sentence = generate_ai_sentence(word, english, api_key)
            else:
                sentence = generate_template_sentence(word, english)
            
            item['sentence'] = sentence
            updated_count += 1
            
            if (i + 1) % 100 == 0:
                print(f"⏳ Processed {i + 1}/{len(data)} words...")
    
    print(f"✅ Generated {updated_count} new sentences")
    
    # Write back to file
    print(f"💾 Writing to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✅ Done!")

def main():
    parser = argparse.ArgumentParser(description='Generate sentences for Swedish words')
    parser.add_argument('--input', default='testWords.json', help='Input JSON file')
    parser.add_argument('--output', default='testWords.json', help='Output JSON file')
    parser.add_argument('--use-ai', action='store_true', help='Use OpenAI API (requires --api-key)')
    parser.add_argument('--api-key', help='OpenAI API key (required if --use-ai)')
    
    args = parser.parse_args()
    
    if args.use_ai and not args.api_key:
        print("❌ Error: --api-key is required when using --use-ai")
        sys.exit(1)
    
    process_json_file(args.input, args.output, args.use_ai, args.api_key)

if __name__ == '__main__':
    main()
