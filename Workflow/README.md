Workflow is a program designed to allow mass flashing of EEPROMs. The way the program works is by taking an input file, crunching it (Workflow DOES require `crunch` be installed. This will be fixed in the future.), and then sending it to a secondary machine for flashing.

The primary computer need only invoke:

`workflow <filename> [<quantity>]`

The primary computer must be attached to a singular transposer, which has a computer case and a container (chests work well) adjacent to it. The two computers must also be linked via a tunnel/linked card (Will be adjusted in the future).

The secondary computer must have it's tunnel/link card set to have the wakeup message as "wakeup" and must run the `flasher.lua` file on startup. TIP: You can flash `flasher.lua` to an EEPROM and this will work as well.

TODO:
 - Remove hard dependency on `crunch`
 - Allow normal network cards (and wireless cards) to be used instead of tunnel/link cards.
 - Allow the secondary computer to remain on, and accept a quantity, and send status back to the primary machine. Would decrease the number of times the code has to be sent over network.
