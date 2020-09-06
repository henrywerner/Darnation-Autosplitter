//Damnation Autosplitter
//by Quaintt

state("DamnGame")
{
    bool isLoad : 0x00A034D0, 0x8;                  //Also returns true during cinematics. Suboptimal.
    bool isLoadScreen: "DamnGame.exe", 0x00DE0258, 0xA00, 0x7D0;
    bool isGreyLoad : 0x0000000;
    bool isOnTitle : 0x0000000;
    byte4 cinematic: "binkw32.dll", 0x17723B07;     // FFFFFFFF = none, 28B7DF0A = final cutscene?, code seems random everytime
    bool inCinematicAlt: "binkw32.dll", 0x1771D6B7; //Roughly 0.02 sec delay (1-2 frames). Suboptimal. 
    int cinematicTimer: "binkw32.dll", 0x1771D6B3;  //seconds elapsed since cutscene started playing
    byte actNumber : 0x01B6BF28, 0x15;              //Value is in hex to ascii: 31 = '1' ... 37 = '7'
    string2 actPrefix : 0x01B6BF28, 0x14;           //First two chars of current act's base map. Read from the file name of the map's default checkpoint.

    string2 act1_DefaultCkp : 0x01B6BF28, 0x82;
    string2 act2_DefaultCkp : 0x01B6BF28, 0x79;
    string2 act3_DefaultCkp : 0x01B6BF28, 0x7F;
    string2 act4_DefaultCkp : 0x01B6BF28, 0x82;
    string2 act5_DefaultCkp : 0x01B6BF28, 0x7F;
    string2 act6_DefaultCkp : 0x01B6BF28, 0x6A;


    // Turns out the game writes/stores all level checkpoint data for the current Act in \Documents\my games\Damnation\DamnGame\Checkpoints\default_checkpoint.dsav
    // By using the actPrefix pointer as a base, we can offset the pointer to look for specific checkpoints and level triggers... it's just going to need separate pointers for every split :(

    // Update: Each level has it's own slightly different version of default_checkpoint which is stored at \Program Files (x86)\Steam\steamapps\common\Damnation\DamnGame\Checkpoints
    // It will still need a pointer for each level, but I should be able to just look for keywords that are exclusive to that level's file (e.g. "W3A2_Skies_Main")
    // The ideal way would be to find a section that changes between every act, then just do a not equals to split on level change.
    // The WarCheckpoint at the top of the file is changes each level. The numbers aren't fully unique, but this might not be a problem.

    // The WarCheckpoint Number jumps around for each act, but not for each level. Options are to either keep a large net string value or to have seperate pointers / pointer offsets for each act.

    byte act2_LevelStartup : "DamnGame.exe", 0x01B6BF28, 0xC73; 
            /* 
            Returns 1 when the player has started Mines.
            If level select is used to skip to skies, the pointer points to the right file but the wrong area. Might not be the case if Mines level is played through, but I would need to test.
            Could be solved by changing the pointer to include the string, then just checking if the pointer == "SeqEvent_LevelStartup_0".
            */
    byte act2_CheckpointActivated_1 : "DamnGame.exe", 0x01B6BF28, 0x6CE3;
            /*
            One out of 26 checkpoints in Act 2. The first one is CheckpointActivated_0, making this one the second checkpoint.
            Wasn't able to trigger this value in testing, so I have no idea which checkpoint this is linked to.
            Similar to the LevelStartup, the pointer becomes incorrect if level select is used to skip the Mines section.
            */
}

startup 
{
    // All Act/Level names are based the on game's files. I don't know why "W3" is "Act 2", ask Blue Omega. 
    settings.Add("W1", true, "Act 1 - Prologue");
    settings.Add("W3", true, "Act 2 - Rescue");
    settings.Add("W4", true, "Act 3 - The Battle Begins");
    settings.Add("W5", true, "Act 4 - Interlude");
    settings.Add("W6", true, "Act 5 - City by the Sea");
    settings.Add("W7", true, "Act 6 - Showdown");
    settings.Add("IgnoreCutscenes", false, "Lore Mode: Pause game timer durring cinematics."); //TODO: add option for ig cutscenes

    //settings.CurrentDefaultParent = "W1";

    settings.CurrentDefaultParent = "W3";
        settings.Add("3_1", false, "Mines"); 
        settings.Add("3_2", false, "Skies");
        settings.Add("3_3", false, "Steam Engine");

    settings.CurrentDefaultParent = "W4";
        settings.Add("4_1", false, "Spire Side");
        settings.Add("4_2", false, "Top");
        settings.Add("4_3", false, "Secrets");
        settings.Add("4_4", false, "Selena Fight");
        settings.Add("4_5", false, "Convoy");

    settings.CurrentDefaultParent = "W5";
        settings.Add("5_1", false, "Convoy Chase");
        settings.Add("5_2", false, "Mesa Base");
        settings.Add("5_3", false, "Mountain Paths");

    settings.CurrentDefaultParent = "W6";
        settings.Add("6_1", false, "Wall");
        settings.Add("6_2", false, "Governor");
        settings.Add("6_3", false, "City");
        settings.Add("6_4", false, "Waterworks");

    settings.CurrentDefaultParent = "W7";
        settings.Add("7_1", false, "Driving to PSI");
        settings.Add("7_2", false, "Shaft");
        settings.Add("7_3", false, "Factory");
        settings.Add("7_4", false, "Tower");
        settings.Add("7_5", false, "Prescott");
}

init //Retriggers on game relaunch
{
	vars.isLoading = false;
    vars.sectionNumber = 1;

    // Messing around with writting functions
    /*
    vars.UpdatePointers = (Action)(() => {

    }
    
    vars.UpdateLevelPointers = (Func<string>)((defaultCkp) => {
        vars.Example = memory.ReadString(modules.First().BaseAddress + 0x01B6BF28, 2);
    }
    */
}

update
{
	vars.isLoading = false;
    
    //TODO: Fix glitch where game time pauses during cinematic if you alt tab in the loading screen 
	if ((current.isLoad && (!current.inCinematicAlt || settings["IgnoreCutscenes"])) || current.isLoadScreen) //This is in update{} to add support for a "|| isGreyLoad". If that's not needed, move this to into isLoading{}.
	{
		vars.isLoading = true;
	}
}

start
{
    //return (!old.inCinematicAlt && current.inCinematicAlt);
    return (old.isLoadScreen && !current.isLoadScreen && current.actPrefix == "W1"); //Doesn't work 20% of the time :(
}

split
{
    /* 
    //revised sudo code
        if (old.actNumber < current.actNumber) {
            vars.sectionNumber = 1;   //reset section counter
            return true;
        }
        
        else if (vars.split < vars.totalSplits && old.section != current.section) {     //Checking for a section change might be easier than checking if sec# increased.
            if (settings[current.actNumber + "_" + (vars.sectionNumber++)]) {           //I think this counts as a normal vars++ call.
                return true;
            }
        }
    */

    if (old.actNumber < current.actNumber) {
        vars.sectionNumber = 1;             //reset section counter
        if (settings[old.actPrefix]) {
            return true;
        }
    } 
    
    else if (old.act2_DefaultCkp != current.act2_DefaultCkp && current.actPrefix == "W3") {
        vars.sectionNumber++;
        string subsplit = string.Concat("3_", vars.sectionNumber);
        if (settings[subsplit]) {
            return true;
        }
    }

    else if (old.act3_DefaultCkp != current.act3_DefaultCkp && current.actPrefix == "W4") {
        vars.sectionNumber++;
        string subsplit = string.Concat("4_", vars.sectionNumber);
        if (settings[subsplit]) {
            return true;
        }
    }

    else if (old.act4_DefaultCkp != current.act4_DefaultCkp && current.actPrefix == "W5") {
        vars.sectionNumber++;
        string subsplit = string.Concat("5_", vars.sectionNumber);
        if (settings[subsplit]) {
            return true;
        }
    }
    
    // ASL doesn't support switch statements?

}

reset
{

}

isLoading
{
	return vars.isLoading;
}

exit
{
    timer.IsGameTimePaused = true;
    //TODO: Test if game crash breaks actNumber logic
}