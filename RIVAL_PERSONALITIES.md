# Carrom: Eight Rival CPU Personalities

## Controls
The left stats panel displays the current rival's portrait, full name, alias,
short biography, and head-to-head match results. PREV/NEXT change opponents.
In portrait mobile mode, use GAME MENU > YOUR RIVAL to switch opponents.
Changing opponents deliberately starts a fresh match. The selected rival and
results are stored in user://carrom_board_settings.cfg under [rivals].

All eight rivals can be used at Casual, Standard, and Expert. The original
physics, Queen, scoring, and difficulty-based accuracy remain unchanged.

## Roster
1. Diego 'Kickflip' Solis - Skateboarder - banks and rebounds
2. Viktor 'Velvet Knuckles' Markovic - Gangster - controlled shots and defense
3. Aiko 'Feedback' Sato - Rocker - combinations and multi-pockets
4. Rowan 'Static' Vale - Punk - risky banks and unusual angles
5. Nia 'Sprint' Okafor - Athlete - clean direct shots
6. Leila 'Velour' Rahman - Model - delicate touch and positioning
7. Malik 'Verse' Baptiste - Rapper - chain reactions and double pockets
8. Hana 'Ghostwire' Park - Hacker - positional and defensive play

## Implementation
Physics candidate generation reserves differing proportions of direct,
bank, combo, and safety simulations per rival. Their post-simulation scores
apply small shot-style and positional preferences. Successful pockets, Fouls,
Queen cover, and match results dominate those preferences. Each difficulty
retains its own original candidate budget and mechanical aiming drift.
Results are tracked separately for Classic and Duboo.

PNG portraits were resized from the user's 1254px images to web-friendly
640px assets while retaining the eight original characters and their order.

## Note
Static integration checks performed. Godot editor runtime could not be
executed in this environment; test the project in Godot before publishing.
