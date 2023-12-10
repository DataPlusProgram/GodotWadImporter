# Godot Wad Importer

![](https://user-images.githubusercontent.com/62811101/167262974-9a93db20-e4ca-45b1-a012-e222ed06cc65.png)

This is a Godot plugin that allows the importing of Doom WAD maps into Godot.

Video Demonstration here: https://www.youtube.com/watch?v=8Gr4nZPxadQ

It is the successor from my previous WAD importer https://github.com/DataPlusProgram/GodWad

Linetypes(doors,lifts,etc..) are supported for the base Doom format but Hexen based linetypes are not supported.

If you wnat a body to interact with objects add a "interactPressed" bool to the body which is true when the interaction button is pressed and false when its not pressed.

If you have a .pk3 file you will have to first extract the WAD out if it mannually.


## Character Controller
There is a provided character controller for testing purposes

![](https://i.giphy.com/media/dRsq8BVZ2lUapFyGJk/giphy.webp)

The character controller generated dynamically by the pluging by clicking the "Create Character Controller" button



| Action        |  Description  |
| ------------- |:-------------:|
| ui_up         | move forward  |
| ui_down       | move backward |
| ui_left       | move left     |
| ui_right      | move right    |
| shoot         | shoot weapon  |
| interact      | actvate doors, buttons, etc|
| jump          | jump          |
| weaponSwitchCategory0...5| Switch between weapon categories |
