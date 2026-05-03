#!/usr/bin/env python3
"""
Script to fix bad sentences in testWords.json
Replaces nonsensical sentences with natural, real-life Swedish sentences.
"""

import json
import random
from typing import Dict, List, Optional

def generate_natural_sentence(word: str, english: str) -> tuple[str, str]:
    """Generate a natural Swedish sentence and its English translation."""
    word_lower = word.lower()
    english_lower = english.lower().strip()
    
    # Check for specific Swedish words that need special handling FIRST
    word_specific_map = {
        'beställa': ('Jag beställer mat.', 'I order food.'),
        'hade': ('Jag hade det.', 'I had it.'),
        'jättekul': ('Det var jättekul!', 'It was lots of fun!'),
        'mörkblå': ('Det är mörkblått.', 'It is dark blue.'),
        'ljusblå': ('Det är ljusblått.', 'It is light blue.'),
        'dessa': ('Dessa är bra.', 'These are good.'),
        'upptäck': ('Jag gör en upptäckt.', 'I make a discovery.'),
    }
    
    if word_lower in word_specific_map:
        return word_specific_map[word_lower]
    
    # ADJECTIVES - Use "är" (is/are) construction
    adjective_map = {
        'hungry': ('Jag är hungrig.', 'I am hungry.'),
        'beautiful': ('Det är vackert.', 'It is beautiful.'),
        'good': ('Det är bra.', 'It is good.'),
        'bad': ('Det är dåligt.', 'It is bad.'),
        'big': ('Det är stort.', 'It is big.'),
        'small': ('Det är litet.', 'It is small.'),
        'fast': ('Det är snabbt.', 'It is fast.'),
        'slow': ('Det är långsamt.', 'It is slow.'),
        'hot': ('Det är varmt.', 'It is hot.'),
        'cold': ('Det är kallt.', 'It is cold.'),
        'new': ('Det är nytt.', 'It is new.'),
        'old': ('Det är gammalt.', 'It is old.'),
        'young': ('Jag är ung.', 'I am young.'),
        'rich': ('Han är rik.', 'He is rich.'),
        'poor': ('Hon är fattig.', 'She is poor.'),
        'happy': ('Jag är glad.', 'I am happy.'),
        'sad': ('Jag är ledsen.', 'I am sad.'),
        'tired': ('Jag är trött.', 'I am tired.'),
        'awake': ('Jag är vaken.', 'I am awake.'),
        'sleepy': ('Jag är sömnig.', 'I am sleepy.'),
        'healthy': ('Jag är frisk.', 'I am healthy.'),
        'sick': ('Jag är sjuk.', 'I am sick.'),
        'strong': ('Jag är stark.', 'I am strong.'),
        'weak': ('Jag är svag.', 'I am weak.'),
        'tall': ('Han är lång.', 'He is tall.'),
        'short': ('Hon är kort.', 'She is short.'),
        'ugly': ('Det är fult.', 'It is ugly.'),
        'expensive': ('Det är dyrt.', 'It is expensive.'),
        'cheap': ('Det är billigt.', 'It is cheap.'),
        'soft': ('Det är mjukt.', 'It is soft.'),
        'hard': ('Det är hårt.', 'It is hard.'),
        'different': ('Det är olika.', 'It is different.'),
        'comfortable': ('Det är bekvämt.', 'It is comfortable.'),
        'colorful': ('Det är färgglatt.', 'It is colorful.'),
        'dark': ('Det är mörkt.', 'It is dark.'),
        'light': ('Det är ljust.', 'It is light.'),
    }
    
    # Check exact match first
    if english_lower in adjective_map:
        return adjective_map[english_lower]
    
    # Check if it's an adjective by checking common patterns
    if any(adj in english_lower for adj in ['good', 'bad', 'big', 'small', 'hot', 'cold', 'new', 'old', 'young', 
                                            'rich', 'poor', 'happy', 'sad', 'tired', 'beautiful', 'ugly', 'fast', 
                                            'slow', 'high', 'low', 'wide', 'narrow', 'deep', 'shallow', 'heavy', 
                                            'light', 'dark', 'clean', 'dirty', 'empty', 'open', 'closed', 'red', 
                                            'blue', 'green', 'yellow', 'white', 'black', 'gray', 'pink', 'purple', 
                                            'simple', 'difficult', 'important', 'safe', 'dangerous', 'free', 
                                            'expensive', 'cheap', 'quiet', 'loud', 'soft', 'hard', 'wet', 'dry', 
                                            'cool', 'sweet', 'sour', 'salty', 'tasty', 'clear', 'true', 'false', 
                                            'right', 'wrong', 'brave', 'afraid', 'friendly', 'kind', 'mean', 'wise', 
                                            'stupid', 'clever', 'patient', 'impatient', 'hungry', 'awake', 'sleepy', 
                                            'healthy', 'sick', 'strong', 'weak', 'tall', 'short', 'nice']):
        # Personal adjectives
        personal_adj = ['hungry', 'tired', 'happy', 'sad', 'rich', 'poor', 'young', 'old', 'sick', 'healthy', 
                       'afraid', 'brave', 'strong', 'weak', 'tall', 'short']
        if any(adj in english_lower for adj in personal_adj):
            templates = [
                ('Jag är {word}.', 'I am {word}.'),
                ('Du är {word}.', 'You are {word}.'),
                ('Han är {word}.', 'He is {word}.'),
                ('Hon är {word}.', 'She is {word}.'),
            ]
        else:
            templates = [
                ('Det är {word}.', 'It is {word}.'),
                ('Det var {word}.', 'It was {word}.'),
                ('Det blir {word}.', 'It becomes {word}.'),
            ]
        sv_template, en_template = random.choice(templates)
        return (sv_template.format(word=word), en_template.format(word=english))
    
    # VERBS - Use modal verbs or simple present
    verb_map = {
        'to save': ('Jag sparar pengar.', 'I save money.'),
        'to book': ('Jag bokar ett bord.', 'I book a table.'),
        'to answer': ('Jag svarar på frågan.', 'I answer the question.'),
        'to repeat': ('Jag upprepar meningen.', 'I repeat the sentence.'),
        'to wish': ('Jag önskar dig lycka till.', 'I wish you good luck.'),
        'to order': ('Jag beställer mat.', 'I order food.'),
        'to think': ('Jag tänker på dig.', 'I think about you.'),
        'to check': ('Jag kollar tiden.', 'I check the time.'),
        'to take care of': ('Jag tar hand om dig.', 'I take care of you.'),
    }
    
    if english_lower.startswith('to '):
        verb_key = english_lower
        if verb_key in verb_map:
            return verb_map[verb_key]
        # Generic verb templates
        verb_base = english_lower.replace('to ', '')
        templates = [
            ('Jag kan {word}.', f'I can {verb_base}.'),
            ('Jag måste {word}.', f'I must {verb_base}.'),
            ('Jag vill {word}.', f'I want to {verb_base}.'),
            ('Jag ska {word}.', f'I will {verb_base}.'),
        ]
        sv_template, en_template = random.choice(templates)
        return (sv_template.format(word=word), en_template.format(word=verb_base))
    
    # TIME/PLACE WORDS (adverbs)
    time_place_map = {
        'now': ('Jag gör det nu.', 'I do it now.'),
        'today': ('Jag gör det idag.', 'I do it today.'),
        'yesterday': ('Jag gjorde det igår.', 'I did it yesterday.'),
        'tomorrow': ('Jag gör det imorgon.', 'I will do it tomorrow.'),
        'here': ('Jag är här.', 'I am here.'),
        'there': ('Jag är där.', 'I am there.'),
        'when': ('När kommer du?', 'When are you coming?'),
        'where': ('Var är du?', 'Where are you?'),
        'how': ('Hur gör man det?', 'How do you do it?'),
    }
    
    if english_lower in time_place_map:
        return time_place_map[english_lower]
    
    # NOUNS - Use appropriate verbs based on noun type
    noun_templates = {
        # Quality/abstract concepts
        'quality': ('Det är bra kvalitet.', 'It is good quality.'),
        'pain': ('Jag har smärta.', 'I have pain.'),
        'pleasure': ('Det är en nöje.', 'It is a pleasure.'),
        'mood': ('Jag är på gott humör.', 'I am in a good mood.'),
        'offer': ('Det är ett bra erbjudande.', 'It is a good offer.'),
        
        # Clothing
        'jacket': ('Jag har en jacka.', 'I have a jacket.'),
        'pants': ('Jag har byxor.', 'I have pants.'),
        'hat': ('Jag har en mössa.', 'I have a hat.'),
        'underwear': ('Jag har trosor.', 'I have underwear.'),
        'underpants': ('Jag har kalsonger.', 'I have underpants.'),
        'skirt': ('Jag har en kjol.', 'I have a skirt.'),
        'tie': ('Jag har en slips.', 'I have a tie.'),
        'shoes': ('Jag har skor.', 'I have shoes.'),
        'bra': ('Jag har en bh.', 'I have a bra.'),
        'blazer': ('Jag har en kavaj.', 'I have a blazer.'),
        'shirt': ('Jag har en skjorta.', 'I have a shirt.'),
        'sweater': ('Jag har en tröja.', 'I have a sweater.'),
        'socks': ('Jag har strumpor.', 'I have socks.'),
        'tank top': ('Jag har ett linne.', 'I have a tank top.'),
        'coat': ('Jag har en kappa.', 'I have a coat.'),
        'dress': ('Jag har en klänning.', 'I have a dress.'),
        'cardigan': ('Jag har en kofta.', 'I have a cardigan.'),
        'hoodie': ('Jag har en luvtröja.', 'I have a hoodie.'),
        'pair': ('Jag har ett par skor.', 'I have a pair of shoes.'),
        'button': ('Jag trycker på knappen.', 'I press the button.'),
        'zipper': ('Jag öppnar dragkedjan.', 'I open the zipper.'),
        
        # Places
        'earth': ('Jorden är vacker.', 'The earth is beautiful.'),
        'department store': ('Jag går till varuhuset.', 'I go to the department store.'),
        'furniture': ('Jag köper möbler.', 'I buy furniture.'),
        
        # Other nouns
        'lesson': ('Jag har en lektion.', 'I have a lesson.'),
        'start': ('Jag börjar nu.', 'I start now.'),
        'instead': ('Jag gör det istället.', 'I do it instead.'),
        'wood': ('Det är gjort av trä.', 'It is made of wood.'),
        'steel': ('Det är gjort av stål.', 'It is made of steel.'),
        'of': ('Det är en del av det.', 'It is part of it.'),
        'what is': ('Vad är det?', 'What is it?'),
        'sounds': ('Det låter bra.', 'It sounds good.'),
        'it will be': ('Det blir bra.', 'It will be good.'),
        'both': ('Båda är bra.', 'Both are good.'),
        'think': ('Jag funderar på det.', 'I think about it.'),
        'of course': ('Självklart gör jag det.', 'Of course I do it.'),
        'check': ('Jag kollar det.', 'I check it.'),
        'discovery': ('Jag gör en upptäckt.', 'I make a discovery.'),
        'travel': ('Jag reser till Sverige.', 'I travel to Sweden.'),
        'we will': ('Vi ska göra det.', 'We will do it.'),
        'boring': ('Det är tråkigt.', 'It is boring.'),
        'these': ('Dessa är bra.', 'These are good.'),
        'had': ('Jag hade det.', 'I had it.'),
        'lots of fun': ('Det var jättekul!', 'It was lots of fun!'),
        'dark blue': ('Det är mörkblått.', 'It is dark blue.'),
        'light blue': ('Det är ljusblått.', 'It is light blue.'),
        'discover': ('Jag gör en upptäckt.', 'I make a discovery.'),
    }
    
    # Check exact match
    if english_lower in noun_templates:
        return noun_templates[english_lower]
    
    # Check if it's clothing
    if any(kw in english_lower for kw in ['jacket', 'pants', 'skirt', 'dress', 'shoes', 'hat', 'cap', 'tie', 
                                         'bra', 'blazer', 'sweater', 'socks', 'tank top', 'coat', 'cardigan', 
                                         'hoodie', 'shirt', 'underwear', 'underpants']):
        templates = [
            ('Jag har en {word}.', f'I have a {english}.'),
            ('Jag köper en {word}.', f'I buy a {english}.'),
            ('Jag bär en {word}.', f'I wear a {english}.'),
        ]
        sv_template, en_template = random.choice(templates)
        return (sv_template.format(word=word), en_template.format(word=english))
    
    # Check if it's food/drink
    if any(kw in english_lower for kw in ['food', 'meal', 'breakfast', 'dinner', 'water', 'milk', 'coffee', 
                                         'tea', 'bread', 'butter', 'cheese', 'egg', 'meat', 'chicken', 'fish', 
                                         'vegetable', 'fruit', 'apple', 'banana', 'orange']):
        templates = [
            ('Jag äter {word}.', f'I eat {english}.'),
            ('Jag dricker {word}.', f'I drink {english}.'),
            ('Jag köper {word}.', f'I buy {english}.'),
        ]
        sv_template, en_template = random.choice(templates)
        return (sv_template.format(word=word), en_template.format(word=english))
    
    # Check if it's a place
    if any(kw in english_lower for kw in ['city', 'town', 'place', 'country', 'street', 'road', 'restaurant', 
                                         'shop', 'store', 'hotel', 'beach', 'forest', 'mountain', 'lake', 'sea']):
        templates = [
            ('Jag bor i {word}.', f'I live in {english}.'),
            ('Jag reser till {word}.', f'I travel to {english}.'),
            ('Jag går till {word}.', f'I go to {english}.'),
        ]
        sv_template, en_template = random.choice(templates)
        return (sv_template.format(word=word), en_template.format(word=english))
    
    # Default for other nouns
    templates = [
        ('Jag ser {word}.', f'I see {english}.'),
        ('Jag har {word}.', f'I have {english}.'),
        ('Jag vill ha {word}.', f'I want {english}.'),
        ('Jag gillar {word}.', f'I like {english}.'),
        ('Det finns {word}.', f'There is {english}.'),
    ]
    sv_template, en_template = random.choice(templates)
    return (sv_template.format(word=word), en_template.format(word=english))

def fix_all_sentences(input_file: str, output_file: str):
    """Fix all bad sentences in the JSON file."""
    print(f"📖 Reading {input_file}...")
    
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"✅ Found {len(data)} words")
    
    fixed_count = 0
    for i, item in enumerate(data):
        word = item.get('swedish', '')
        english = item.get('english', '')
        
        # Generate new sentence
        sv_sentence, en_sentence = generate_natural_sentence(word, english)
        
        # Update example field with "Ex: " prefix
        if 'example' not in item:
            item['example'] = {}
        
        item['example']['sv'] = f"Ex: {sv_sentence}"
        item['example']['en'] = f"Ex: {en_sentence}"
        
        fixed_count += 1
        
        if (i + 1) % 100 == 0:
            print(f"⏳ Processed {i + 1}/{len(data)} words...")
    
    print(f"✅ Fixed {fixed_count} sentences")
    
    # Write back to file
    print(f"💾 Writing to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✅ Done!")

if __name__ == '__main__':
    fix_all_sentences('testWords.json', 'testWords.json')
