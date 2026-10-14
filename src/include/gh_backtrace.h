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

    $Id: gh_backtrace.h 618 2008-01-01 12:50:13Z goblinhack $
*/

#ifndef _GH_BACKTRACE_H_
#define _GH_BACKTRACE_H_

#define GH_FUNCTION_MAX_DEPTH 1024

extern int gh_function_indent_depth;
extern void gh_function_trace(void);
extern void gh_function_push(const char *file, const char *name, uint16 line);

#define GH_FUNCTION()                                           \
        gh_function destroyed_on_exit(__FILE__,                 \
                                      __FUNCTION__,             \
                                      __LINE__);                \
                                                                \
        if (gh_global::trace_mode) {                            \
            gh_function_trace();                                \
        }

//
// Frames beyond GH_FUNCTION_MAX_DEPTH are counted but not recorded, so deep
// recursion cannot overrun the trace arrays.
//
class gh_function {
public:
    gh_inline gh_function (const char *file,
                           const char *name,
                           uint16 line) {
        gh_function_push(file, name, line);
        gh_function_indent_depth++;
    }

    gh_inline ~gh_function () {
        gh_function_indent_depth--;
    }
};

extern void gh_backtrace_init(void);
extern void gh_backtrace(void);

#endif /* _GH_BACKTRACE_H_ */
