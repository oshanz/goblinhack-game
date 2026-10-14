/*
    goblinhack.
    Copyright (C) 1999-2010 Neil McGill

    This game is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This game is distributed in the hope that it will be fun,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this game; if not, write to the Free
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Neil McGill

    $Id: main.cpp 848 2008-04-30 14:38:59Z goblinhack $
*/

#include <ghack.h>
#include <gh_game.h>
#include <signal.h>
#include <unistd.h>
#include <gh_thing.h>
#include <gh_room.h>
#include <gh_zip.h>
#include <gh_surface.h>
#include <hacklib.h>
#include <gh_audio.h>
#include <gh_music.h>
#include <gh_sdl.h>

#if defined __linux__
#include <unistd.h>     /* Symbolic Constants */
#include <sys/types.h>  /* Primitive System Data Types */ 
#include <errno.h>      /* Errors */
#include <stdio.h>      /* Input/Output */
#include <sys/wait.h>   /* Wait for Process Termination */
#include <stdlib.h>     /* General Utilities */
#endif

//
// The auto-updater used to download an installer over plain HTTP and run it
// with no verification. That is a remote code execution risk (MITM / DNS
// spoofing), so it is disabled. Get new versions from the official release
// channels instead.
//
void gh_main_installer (void)
{
}
