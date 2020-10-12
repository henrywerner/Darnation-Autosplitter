# Darnation Autosplitter
A LiveSplit autosplitter for use in speedrunning the video game *Damnation (2009)*. The script uses pointers to read information the game is storing in main memory, then uses this information to accurately time the user's playthrough. 


### Memory pointers used in the script
| Pointer        | Purpose                                                               | Notes                                |
|----------------|-----------------------------------------------------------------------|--------------------------------------|
| isLoad         | Returns true during (all?) game loads.                                | Also returns true during cinematics  |
| isLoadScreen   | Determines if one of the game's "Now Loading" video files is playing. |                                      |
| inCinematicAlt | Determines if a pre-rendered cinematic is playing.                    | Delayed by 0.02 seconds (1-2 frames) |
| actNumber      | Returns byte equivalent to the current campaign act.                  | Returns the number's ascii value     |
| actPrefix      | Reads the first two characters of current act's world map.            |                                      |


### Options & Features
The script allows for the option to enable/disable individual splits for each of the 6 acts and their respective levels. There is the additional option to enable "Lore Mode", which pauses the game-timer during pre-rendered cinematics.
