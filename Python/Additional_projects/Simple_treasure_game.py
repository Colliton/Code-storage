"""
Chamber of Fortune – Text-Based Treasure Game

A fantasy-themed mini-game in which the player explores a mysterious chamber
through five forward steps. At each step, there's a chance to find a chest 
of varying color and value — or nothing at all.

Chest colors are ranked by rarity: green (common), orange (uncommon), purple (rare), and gold (very rare).
The gold reward increases quadratically with rarity. The player’s goal is to collect
as much gold as possible before the game ends.

Game mechanics:
1. The player has 5 steps to make.
2. At each step, the game randomly determines if a chest or nothing is found.
3. If a chest is found, its color is determined randomly based on rarity.
4. The corresponding reward is added to the player's total gold.

Chest reward scheme:
- Green:   1² × 1000 = 1000 gold
- Orange:  2² × 1000 = 4000 gold
- Purple:  3² × 1000 = 9000 gold
- Gold:    4² × 1000 = 16000 gold

Dependencies:
- random
- enum

Output:
- Step-by-step messages guiding the player through the chamber
- Total gold acquired at the end of the game

✨ Story intro (in-game):
You enter a mysterious chamber where every step forward could uncover treasure...
or nothing at all. You have 5 steps to make — how much gold will you collect
before the chamber closes forever?
"""


import random
from enum import Enum

# Define possible events during a step
class Event(Enum):
    CHEST = 'Chest'
    EMPTY = 'Empty'

event_probability = {
    Event.CHEST: 0.6,
    Event.EMPTY: 0.4
}
event_list = list(event_probability.keys())
event_weights = list(event_probability.values())

# Define chest colors (English)
class Colour(Enum):
    GREEN = 'green'
    ORANGE = 'orange'
    PURPLE = 'purple'
    GOLD = 'gold'

chest_color_probability = {
    Colour.GREEN: 0.75,
    Colour.ORANGE: 0.20,
    Colour.PURPLE: 0.04,
    Colour.GOLD: 0.01
}
chest_colors = list(chest_color_probability.keys())
chest_weights = list(chest_color_probability.values())

# Assign gold rewards based on chest rarity
rewards_for_chests = {
    color: (i + 1) ** 2 * 1000
    for i, color in enumerate(chest_colors)
}

# Game state
steps_remaining = 5
gold_acquired = 0

# Intro
print("🌟 Welcome to the **Chamber of Fortune**! 🌟")
print("You have 5 steps to take through this mysterious place.")
print("At each step, you might find a treasure chest... or nothing at all.\n")

# Game loop
while steps_remaining > 0:
    player_input = input("➡️ Do you want to move forward? (yes/no): ").strip().lower()

    if player_input == "yes":
        print("\nYou move forward...")
        drawn_event = random.choices(event_list, weights=event_weights)[0]

        if drawn_event == Event.CHEST:
            print("You found a CHEST!")
            drawn_color = random.choices(chest_colors, weights=chest_weights)[0]
            print(f"The chest color is: **{drawn_color.value.capitalize()}**")
            reward = rewards_for_chests[drawn_color]
            print(f"You receive 💰 {reward} gold!")
            gold_acquired += reward
        else:
            print("Nothing here. Just shadows and silence...")

        steps_remaining -= 1

    elif player_input == "no":
        print("There is no turning back. The chamber demands your decision.")
        continue
    else:
        print("Please type 'yes' or 'no'.")
        continue

# Final message
print("\n🏁 The chamber seals behind you...")
print(f"✨ You leave with a total of **{gold_acquired} gold**. ✨")
print("Thanks for playing Chamber of Fortune!")
