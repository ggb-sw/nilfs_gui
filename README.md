# Readme for NilFs_Gui.rb

## Overview

This is a simple GUI to help quickly recover data from snapshots stored on a [NILFS](http://nilfs.sourceforge.net/en/) filesystem.

## Capabilities

* It can convert a regular checkpoint to a snapshot, or a snapshot back to a regular checkpoint.
* It can `mount` or `umount` a snapshot on a directory.

## Dependencies

* It only runs on Linux (it uses Linux system commands).  It was tested under Ubuntu 12.04.
* It was written in Ruby/TK, and so requires Ruby with TK installed to run.
* Ofcourse it requires that NILFS be installed.
* It uses `gksu`, so that must be installed.

All of the above is straight out of the Ubuntu repositories, and so there should not be any need to install anything from outside of the repositories.

## Known limitations

* This is early code, so anything can go wrong.
* You can mount on a directory, but the directory has to pre-exist.  The application does not create the directory itself.
* There are no scrollbars yet on the lists (or search capabilities), so if you have lots and lots of checkpoints on your `nilfs` filesystem, it may get tedious.

## Installation and running

The application is just a single ruby script (it is that simple).

  1. Just download the script.
  2. Ensure all the dependencies are installed.
  3. Mark the script as executable (if it is not already so).  If you don't wish to do this, then you will have to run the ruby interpreter to execute the script.
  4. Run the script.

All as simple as that.

# Licence

This software is provided free of charge, and without any guarantee of anything.

The software may be freely distributed, copied, and used, by anybody, subject to the following conditions.

  1. The copyright remains with the author (George G. Bolgar)
  2. The software may not be modified in any way.
  3. The software must be distributed with this README file.
  4. The software may not be sold, or otherwise distributed for financial gain.

     4.1 The software may be distributed alongside other software that is for sale, so long as no attempt is made to prevent or limit the software from being used separately from the other software, and no attempt is made to limit the recipient of the software from freely redistributing this software separately from the other software.
