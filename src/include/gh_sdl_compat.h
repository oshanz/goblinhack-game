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
*/

//
// Glue between the SDL 1.2 era names used throughout the game and SDL2.
//
#ifndef _GH_SDL_COMPAT_H_
#define _GH_SDL_COMPAT_H_

#include <SDL.h>

typedef SDL_Keysym SDL_keysym;
typedef Uint16 SDLMod;

//
// Video flags understood by gh_surface (SDL 1.2 had SDL_OPENGL etc.)
//
enum {
    GH_VIDEO_OPENGL = (1 << 0),
    GH_VIDEO_FULLSCREEN = (1 << 1),
    GH_VIDEO_NOFRAME = (1 << 2),
};

//
// The one and only window and its GL context
//
extern SDL_Window *gh_sdl_window;
extern SDL_GLContext gh_sdl_glcontext;

static inline void gh_sdl_swap_buffers (void)
{
    SDL_GL_SwapWindow(gh_sdl_window);
}

//
// Relative mouse mode replaces SDL_WM_GrabInput
//
static inline void gh_sdl_grab_input (bool on)
{
    SDL_SetRelativeMouseMode(on ? SDL_TRUE : SDL_FALSE);
}

#endif /* _GH_SDL_COMPAT_H_ */
