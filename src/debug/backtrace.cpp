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

    $Id: backtrace.cpp 990 2008-07-13 21:06:25Z Ghack $
*/

#include <ghack.h>
#include <stdio.h>

static const char *gh_function_names_arr[GH_FUNCTION_MAX_DEPTH];
static const char *gh_function_files_arr[GH_FUNCTION_MAX_DEPTH];
static uint16 gh_function_lines_arr[GH_FUNCTION_MAX_DEPTH];
static const char gh_indent[] = "            CRASH SOON !!! ......................................................................................................................................................................................................................................................................................................................................................................................................................................................................";

int gh_function_indent_depth;

//
// Record a frame at the current depth, if there is room.
//
void gh_function_push (const char *file, const char *name, uint16 line)
{
    const int depth = gh_function_indent_depth;

    if ((depth >= 0) && (depth < GH_FUNCTION_MAX_DEPTH)) {
        gh_function_files_arr[depth] = file;
        gh_function_names_arr[depth] = name;
        gh_function_lines_arr[depth] = line;
    }
}

static inline int gh_depth_recorded (void)
{
    if (gh_function_indent_depth > GH_FUNCTION_MAX_DEPTH) {
        return (GH_FUNCTION_MAX_DEPTH);
    }
    return (gh_function_indent_depth);
}

static inline const char *gh_indent_show (int depth)
{
    if (depth > (int)sizeof(gh_indent) - 1) {
        depth = sizeof(gh_indent) - 1;
    }
    return (&gh_indent[sizeof(gh_indent) - depth]);
}

void gh_backtrace_init (void)
{
}

void gh_backtrace (void)
{
    fprintf(stderr, "backtrace:\n");

    for (int depth=0; depth < gh_depth_recorded(); depth++) {
        fprintf(stderr,
                "%30s:%-3d %*s%s()\n",
                gh_function_files_arr[depth],
                gh_function_lines_arr[depth],
                depth,
                gh_indent_show(depth),
                gh_function_names_arr[depth]);
    }
    fflush(stderr);

    fprintf(stdout, "backtrace:\n");

    for (int depth=0; depth < gh_depth_recorded(); depth++) {
        fprintf(stdout,
                "%30s:%-3d %*s%s()\n",
                gh_function_files_arr[depth],
                gh_function_lines_arr[depth],
                depth,
                gh_indent_show(depth),
                gh_function_names_arr[depth]);
    }
    fflush(stdout);
}

void gh_function_trace (void)
{
    int depth = gh_function_indent_depth - 1;

    if ((depth < 0) || (depth >= GH_FUNCTION_MAX_DEPTH)) {
        return;
    }

    printf("%30s:%-3d %*s%s()\n",
           gh_function_files_arr[depth],
           gh_function_lines_arr[depth],
           depth,
           gh_indent_show(depth),
           gh_function_names_arr[depth]);
}
