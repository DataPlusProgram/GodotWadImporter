# Godot Wad Importer

![](https://user-images.githubusercontent.com/62811101/167262974-9a93db20-e4ca-45b1-a012-e222ed06cc65.png)

This is a Godot plugin that allows the importing of Doom WAD maps into Godot.

Video Demonstration here: https://www.youtube.com/watch?v=E-L27FucTN0

It is the successor from my previous WAD importer https://github.com/DataPlusProgram/GodWad

It currently only supports the base Doom format and not UMDF.

Linetypes(doors,lifts,etc..) are supported for the base Doom format but Hexen based linetypes are not supported.

If you wnat a body to interact with objects add a "interactPressed" bool to the body which is true when the interaction button is pressed and false when its not pressed.

If you have a .pk3 file you will have to first extract the WAD out if it mannually. If Godot ever supports loading .zip from GDScript I will add support for it.



## Usage
* Enable "Godot WAD Loader" in Project -> Plugins and reload your project.
* Drage the WAD_Loader.tscn into your scene.
* Click on the "WadLoader" node in the scene tree.
* Change the length of the "Wads" array in Script Variables to 1.
* Click on the folder icon and open the desired WAD file.
* Click "Load Wad" on the top bar
* Chose the map you want to import from the dropdown menu.
* Click "create map"
  
![howto](https://user-images.githubusercontent.com/62811101/166899791-9e22999e-2afd-4209-b7d2-97840fab0aae.gif)

## To Disk Option  

Enabling to To Disk option will save the all the assets in the WAD file (sounds,textures,etc...) to a "wadFiles" directory in your project.
This has several advantages such as being able to edit the .png textures directly and having the change show up in your map. It also avoids saving the assets directly into .tscn file which leads to a lot of replicated data.

Currently the To Disk option is unstable. The reason for this is that Godot doesn't expose any of it's asset importing functionality to GDScript. Beacuse of this I have to create a thread which waits for the editor to invoke the import process, after which the plugin takes the imported assets and builds the map.

Unfortunatley due to either an error in my code or Godots threaded instability doing this will often lead to a crash. The good news is that if you try it enough it will eventually complete and is less likely to crash for subseqent maps since most of the assets between maps are shared and won't need to be reimported for the next map. 

When using the plugin initially I recommoned not enabling "To Disk" do to its instability.


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
