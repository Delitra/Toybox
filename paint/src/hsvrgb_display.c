// SK's Paint: HSV/RGB Selector Display
// Copyright (c) 2009 sk89q <http://sk89q.therisenrealm.com>
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 
// $Id$

#define SCREEN_WIDTH 12
#define SCREEN_HEIGHT 12
#define V_SEL_WIDTH 1

#include "lib/clib.c"
//#include "lib/cstr.c"      //Include this for strcmp, strcpy, etc
#include "lib/cmath.c"     //Include this for sin, cos, floor, etc
//#include "lib/conlib.c"    //Include this for graphic console output (cout,putchar)

draw_rainbow() {
    int x, y, hi, p, q, t, v, r, g, b;
    int h, s, v, f;
    
    for (x = 0; x < (SCREEN_WIDTH - V_SEL_WIDTH); x++) {
        for (y = 0; y < SCREEN_HEIGHT; y++) {
            h = 360 * (x / (SCREEN_WIDTH - V_SEL_WIDTH));
            s = y / SCREEN_HEIGHT;
            v = 1;
            hi = floor(h / 60) % 6;
            f = h / 60 - floor(h / 60);
            p = floor(255 * v * (1 - s));
            q = floor(255 * v * (1 - f * s));
            t = floor(255 * v * (1 - (1 - f) * s));
            v = floor(255 * v);
            switch (hi) {
                case 0:
                    r = v;
                    g = t;
                    b = p;
                    break;
                case 1:
                    r = q;
                    g = v;
                    b = p;
                    break;
                case 2:
                    r = p;
                    g = v;
                    b = t;
                    break;
                case 3:
                    r = p;
                    g = q;
                    b = v;
                    break;
                case 4:
                    r = t;
                    g = p;
                    b = v;
                    break;
                case 5:
                    r = v;
                    g = p;
                    b = q;
            }
            hispeed[y * SCREEN_WIDTH + x] = r*65536 + g*256 + b;
        }
    }
}

draw_slider(h, s) int h, s; {
}

main() {
    hispeed[1048569] = 2;
    
    while (true) {
        draw_rainbow();
    }
}
