<p align="center">
<img src="https://github.com/MiSTer-devel/Arcade-Athena_MiSTer/blob/main/docs/Athena_flyer.png"/>
</p>

# openFPGA-Athena

A port of Athena (and Fighting Golf) to the Analogue Pocket. Original code from the [MisTer port](github.com/MiSTer-devel/Arcade-Athena_MiSTer)



## OVERVIEW 

### Athena

Athena is a side scroller where Athena runs through worlds picking up objects and killing enemies. She starts with just a kick, but soon collects a club, an axe, swords and other weapons. She can also collect object which increase her jumps, let her break rocks with her head etc. 

Health is shown on the left side of the screen and decreases every time you are hit. If you see some hearts floating about, they will restore health. On the right hand side is hit strength, the better weapons you have, the stronger your blows are. 

### Figthing Golf

Fighting golf is a pretty simple golf game. Each hole has its own par and some suggestions as to how to beat it. 

To strike the ball hit the A button as the strength meter goes through the value you want. Select a club with the B button,  modify the direction you are goign to hit with left and right and add some spin with up and down. When on the green adjust your aim for the lie of the land and then don't over-, or under-hit


## PLATFORM

Analogue Pocket



## BUILDING

    `git clone git@githum.com:rolandking/openFPGA-Athena.git --recursive`

or clone the repo and do 

    `git submodule init`
    `git submodule update`

the quartus project file is at `src/fpga/ap_core.apf`


## ROMS

ROMs are not included, please provide your own. MRA files are linked from the main mister source if you want to build your own. 


## CONTROLS

`A`      - take a shot

`B`      - change club

`select` - add a coin

`start`  - start the game

various options can be set (lives, difficulty) and persist across restarts

The high score tables are saved in the Pocket's `Save` directory

Opening the menu pauses the game


## CREDITS

Thank you to the RndMnkIII for the original game ports.
