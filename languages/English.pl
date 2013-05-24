#############################################
## Language: English
#############################################

# Lanuage
$L{'language'} = "English";

##-------------------------------------------
## Generic status updates
##-------------------------------------------

$L{'done'} = "Done";
$L{'error'} = "Error";
$L{'table'} = "Table";
$L{'alldone'} = "All done";
$L{'downloadschema'} = "Downloading schema... ";
$L{'restart_init'} = "Please restart init.pl";
$L{'invalid'} = "Invalid input";

##-------------------------------------------
## init.pl
##-------------------------------------------

# Language changed
$L{'langchanged'} = "Language changed. Please restart init.pl\n";

# Welcome message
$L{'init_welcome'} =
"Welcome to mbzdb v1.0\n\n";

$L{'init_firstboot'} =
"*** Before proceeding create the database you wish to use. ***\n\n".
"Values in square brackets indicate defaults, if you are unsure if\n".
"the values are correct you may simply hit enter to continue.\n".
"You may exit at any time and your options will be saved.\n".
"Use a single space as an answer to tell it to set the value to nothing.\n\n";

# init action
$L{'init_action'} =
"Options provide more information after selection, before they start\n".
"[1] Full Install (does everything for you, requires big download)\n".
"[2] Install/Update database schematic\n".
"[3] Load raw tables (requires big download ~1GB)\n".
"[4] Load raw tables (don't download, load from 'mbdump/')\n".
"[5] Apply table indexing\n".
"[6] Apply table foreign keys\n".
"[7] Initialise plugins\n".
"[8] NOOP\n\n".
"Option: ";

# action descriptions
$L{'init_actionfull'} =
"A full install will install the database schematic, download the raw\n".
"database dumps (~1GB), load them in, apply all the table indexing and\n".
"then initialise the plugins.\n\n".
"Please configure settings.pl with the plugins you wish to use.\n\n".
"Ready to proceed? (it may take over 24 hours for this script to fully\n".
"complete) (y/n): ";

$L{'init_actionschema'} =
"Requires internet connection. Downloads latest database schematic and installs\n".
"or updates any changes... ready to proceed? (y/n): ";

$L{'init_actionraw1'} =
"Requires internet connection. Downloads latest raw database dump (~1GB)... ready\n".
"to proceed? (y/n): ";

$L{'init_actionraw2'} =
"If you have already downloaded the database dump, uncompress them and put the\n".
"table files into the 'mbdump/' folder. If using MySQL, load the data after\n".
"applying the index because it is faster..... ready to proceed? (y/n): ";

$L{'init_actionindex'} =
"The most time consuming option. This will apply indexing to your already loaded\n".
"database. If using PostgreSQL, apply the index after you load the raw data because\n".
"it is faster.... if you cancel, you can safely return by running this again.\n".
"Ready to proceed? (y/n): ";

$L{'init_actionfk'} =
"One of the most time consuming option. This will apply foreign keys to your already loaded\n".
"database. If you cancel, you can safely return by running this again.\n".
"Ready to proceed? (y/n): ";

$L{'init_actionplugininit'} =
"Run this last but before you start the replications. Make sure you edit settings.pl\n".
"with the active plugins you wish to initialise in \@g_active_plugins.\n\n".
"Plugins to be initialised are: " . join(',', @g_active_plugins) . "\n\n".
"Ready to proceed? (y/n): ";

$L{'init_noop'} =
"Runs a NOOP command\n\n".
"Ready to proceed?  (y/n): ";

return 1;
